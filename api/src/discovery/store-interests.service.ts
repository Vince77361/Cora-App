import { Injectable } from '@nestjs/common';
import { ApplicationsService } from '../applications/applications.service';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { FeaturedPostsService } from '../creators/featured-posts.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { VisibilityService } from '../visibility/visibility.service';
import { DiscoveryRepository } from './discovery.repository';
import {
  STORE_INTEREST_TABS,
  StoreInterestCardModel,
} from './dto/store-interest.model';
import { shortName } from './interest-rules';

// 03 저장함의 사장님 쪽(저장 / 보낸 관심). 내 가게가 저장(HOLD)하거나 하트(LIKE)를 보낸 크리에이터만 읽는다.
// 넘긴 사람과 다른 가게의 결정은 읽지 않는다. 사장님의 서로 관심은 협업이 아니라 두 기록의 교집합이다:
// 내가 하트를 보냈고 그 크리에이터가 이 가게에 살아 있는 지원을 가졌다(설계 5.4).
@Injectable()
export class StoreInterestsService {
  constructor(
    private readonly users: UsersService,
    private readonly stores: StoresService,
    private readonly creators: CreatorsService,
    private readonly featuredPosts: FeaturedPostsService,
    private readonly visibility: VisibilityService,
    private readonly applications: ApplicationsService,
    private readonly repository: DiscoveryRepository,
  ) {}

  async list(
    userId: string,
    tab: (typeof STORE_INTEREST_TABS)[number],
  ): Promise<StoreInterestCardModel[]> {
    if ((await this.users.getRole(userId)) !== 'STORE') {
      throw new AppError('FORBIDDEN', '가게 계정만 쓸 수 있어요.');
    }
    const store = await this.stores.requireMyStore(userId);
    const wanted = tab === 'sent' ? 'LIKE' : 'HOLD';
    // 사장님의 결정은 모두 campaign_id가 없다. 혹시 있는 행은 브랜드의 것이라 읽지 않는다.
    const rows = (
      await this.repository.listSavedDecisions(userId, 'CREATOR')
    ).filter((row) => row.decision === wanted && row.campaignId === null);
    const ids = rows.map((row) => row.targetId);
    const [visibleIds, summaries, applicants] = await Promise.all([
      this.visibility.filterCreators(ids, {
        userId,
        kind: 'STORE',
        industry: store.industry,
      }),
      this.creators.getSummaries(ids),
      tab === 'sent'
        ? this.applications.listLiveCreatorIds(store.id)
        : Promise.resolve(new Set<string>()),
    ]);
    const visible = new Set(visibleIds);
    // 월드컵 카드는 대표 게시물 1번의 사진과 한 줄을 쓴다. 보이는 크리에이터만 한 번에 읽어 줄마다 읽지 않는다.
    const posts = await this.featuredPosts.listForCreators(
      ids.filter((id) => visible.has(id)),
    );
    return rows.flatMap((row): StoreInterestCardModel[] => {
      const summary = summaries.get(row.targetId);
      // 피하는 업종·차단·탈퇴로 보이지 않게 된 크리에이터는 없는 것과 같다.
      if (!summary || !visible.has(row.targetId)) return [];
      const first = posts.get(row.targetId)?.[0];
      return [
        {
          creatorId: summary.userId,
          name: summary.displayName,
          shortName: shortName(summary.displayName),
          contentFocus: summary.contentFocus,
          followers: summary.followers,
          photoUrl: summary.photoUrl,
          headline: first?.caption ?? null,
          representativePhotoUrl: first?.photoUrl ?? null,
          mutual: applicants.has(row.targetId),
        },
      ];
    });
  }
}
