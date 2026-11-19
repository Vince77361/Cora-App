import { Store, SwipeDecision } from '@prisma/client';
import { FakeVisibility } from '../../test/support/fake-visibility';
import { ApplicationsService } from '../applications/applications.service';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import type { CreatorSummaryModel } from '../creators/dto/creator-profile.model';
import type { FeaturedPostModel } from '../creators/dto/featured-post.model';
import { FeaturedPostsService } from '../creators/featured-posts.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { DiscoveryRepository } from './discovery.repository';
import { StoreInterestsService } from './store-interests.service';

const OWNER = '00000000-0000-4000-8000-000000000001';
const OTHER_OWNER = '00000000-0000-4000-8000-000000000002';
const STORE_ID = '00000000-0000-4000-8000-0000000000aa';
const A = '00000000-0000-4000-8000-0000000000a1';
const B = '00000000-0000-4000-8000-0000000000b1';
const C = '00000000-0000-4000-8000-0000000000c1';
const D = '00000000-0000-4000-8000-0000000000d1';

class FakeRepository extends DiscoveryRepository {
  readonly rows: SwipeDecision[] = [];
  private seq = 0;

  constructor() {
    super(null as never);
  }

  add(
    actorId: string,
    targetId: string,
    decision: 'LIKE' | 'HOLD' | 'PASS',
    over: Partial<SwipeDecision> = {},
  ): void {
    this.seq += 1;
    this.rows.push({
      id: `d-${this.seq}`,
      actorId,
      targetKind: 'CREATOR',
      targetId,
      campaignId: null,
      decision,
      updatedAt: new Date(Date.UTC(2026, 10, 19, 0, this.seq)),
      deletedAt: null,
      ...over,
    } as SwipeDecision);
  }

  // 실제 저장소처럼 내 결정 가운데 LIKE·HOLD만, 최근 결정이 앞이다.
  listSavedDecisions(actorId: string): Promise<SwipeDecision[]> {
    return Promise.resolve(
      this.rows
        .filter(
          (r) =>
            r.actorId === actorId &&
            r.targetKind === 'CREATOR' &&
            r.decision !== 'PASS' &&
            !r.deletedAt,
        )
        .sort((a, b) => b.updatedAt.getTime() - a.updatedAt.getTime()),
    );
  }
}

function summary(id: string, name: string): CreatorSummaryModel {
  return {
    userId: id,
    displayName: name,
    contentFocus: '맛집 릴스',
    photoUrl: null,
    regionSido: '서울특별시',
    regionSigungu: '성동구',
    instagramConnected: true,
    followers: 12000,
  };
}

function build(role: string | null = 'STORE') {
  const repository = new FakeRepository();
  const visibility = new FakeVisibility();
  const applicants = new Set<string>();
  const summaries = new Map<string, CreatorSummaryModel>([
    [A, summary(A, '서윤의 작은 취향')],
    [B, summary(B, '하루 한 컵')],
    [C, summary(C, '셋째')],
  ]);
  // 크리에이터별 대표 게시물 목록(1번이 앞). 없는 사람은 빈 목록이다.
  const posts = new Map<string, Partial<FeaturedPostModel>[]>();
  const postReads: string[][] = [];
  const service = new StoreInterestsService(
    { getRole: () => Promise.resolve(role) } as unknown as UsersService,
    {
      requireMyStore: () =>
        Promise.resolve({
          id: STORE_ID,
          ownerId: OWNER,
          industry: 'FOOD_CAFE',
        } as Store),
    } as unknown as StoresService,
    {
      getSummaries: (ids: string[]) =>
        Promise.resolve(
          new Map(
            ids.flatMap((id) => {
              const found = summaries.get(id);
              return found ? [[id, found] as const] : [];
            }),
          ),
        ),
    } as unknown as CreatorsService,
    {
      listForCreators: (ids: string[]) => {
        postReads.push(ids);
        return Promise.resolve(
          new Map(ids.map((id) => [id, posts.get(id) ?? []])),
        );
      },
    } as unknown as FeaturedPostsService,
    visibility,
    {
      listLiveCreatorIds: () => Promise.resolve(applicants),
    } as unknown as ApplicationsService,
    repository,
  );
  return {
    service,
    repository,
    visibility,
    applicants,
    summaries,
    posts,
    postReads,
  };
}

describe('StoreInterestsService', () => {
  it('lists saved and sent creators for the store only', async () => {
    const { service, repository } = build();
    repository.add(OWNER, A, 'HOLD');
    repository.add(OWNER, B, 'LIKE');
    repository.add(OWNER, C, 'PASS');
    repository.add(OTHER_OWNER, D, 'HOLD');
    repository.add(OTHER_OWNER, C, 'LIKE');
    // 브랜드가 캠페인에서 남긴 결정은 사장님 저장함에 섞이지 않는다.
    repository.add(OWNER, C, 'HOLD', { campaignId: 'campaign-1' });

    const saved = await service.list(OWNER, 'saved');
    const sent = await service.list(OWNER, 'sent');

    expect(saved.map((c) => c.creatorId)).toEqual([A]);
    expect(sent.map((c) => c.creatorId)).toEqual([B]);
  });

  it('fills the card fields and the short name', async () => {
    const { service, repository } = build();
    repository.add(OWNER, A, 'HOLD');

    expect(await service.list(OWNER, 'saved')).toEqual([
      {
        creatorId: A,
        name: '서윤의 작은 취향',
        shortName: '서윤',
        contentFocus: '맛집 릴스',
        followers: 12000,
        photoUrl: null,
        headline: null,
        representativePhotoUrl: null,
        mutual: false,
      },
    ]);
  });

  it('adds the first featured post line and photo without touching the profile photo', async () => {
    const { service, repository, summaries, posts } = build();
    summaries.set(A, {
      ...summary(A, '서윤의 작은 취향'),
      photoUrl: 'profile.jpg',
    });
    posts.set(A, [
      { position: 1, caption: '성수동 카페 릴스', photoUrl: 'first.jpg' },
      { position: 2, caption: '두 번째', photoUrl: 'second.jpg' },
    ]);
    repository.add(OWNER, A, 'HOLD');

    const [card] = await service.list(OWNER, 'saved');

    expect(card.headline).toBe('성수동 카페 릴스');
    expect(card.representativePhotoUrl).toBe('first.jpg');
    expect(card.photoUrl).toBe('profile.jpg');
  });

  it('keeps a null headline when the first post has no caption', async () => {
    const { service, repository, posts } = build();
    posts.set(A, [{ position: 1, caption: null, photoUrl: 'first.jpg' }]);
    repository.add(OWNER, A, 'HOLD');

    const [card] = await service.list(OWNER, 'saved');

    expect(card.headline).toBeNull();
    expect(card.representativePhotoUrl).toBe('first.jpg');
  });

  it('reads featured posts once for all visible creators', async () => {
    const { service, repository, postReads, visibility } = build();
    repository.add(OWNER, A, 'HOLD');
    repository.add(OWNER, B, 'HOLD');
    repository.add(OWNER, C, 'HOLD');
    visibility.hiddenCreators.add(C);

    await service.list(OWNER, 'saved');

    expect(postReads).toHaveLength(1);
    expect([...postReads[0]].sort()).toEqual([A, B].sort());
  });

  it('orders by the most recent decision first', async () => {
    const { service, repository } = build();
    repository.add(OWNER, A, 'LIKE');
    repository.add(OWNER, B, 'LIKE');

    expect((await service.list(OWNER, 'sent')).map((c) => c.creatorId)).toEqual(
      [B, A],
    );
  });

  it('marks a sent creator as mutual when the creator applied', async () => {
    const { service, repository, applicants } = build();
    repository.add(OWNER, A, 'LIKE');
    repository.add(OWNER, B, 'LIKE');
    applicants.add(B);

    const sent = await service.list(OWNER, 'sent');

    expect(sent.map((c) => [c.creatorId, c.mutual])).toEqual([
      [B, true],
      [A, false],
    ]);
  });

  it('never marks a saved creator as mutual', async () => {
    const { service, repository, applicants } = build();
    repository.add(OWNER, A, 'HOLD');
    applicants.add(A);

    expect((await service.list(OWNER, 'saved'))[0].mutual).toBe(false);
  });

  it('hides creators the store may not see', async () => {
    const { service, repository, visibility, summaries } = build();
    repository.add(OWNER, A, 'HOLD');
    repository.add(OWNER, B, 'HOLD');
    repository.add(OWNER, C, 'HOLD');
    visibility.hiddenCreators.add(A);
    // 프로필이 지워진 크리에이터도 뺀다.
    summaries.delete(B);

    expect(
      (await service.list(OWNER, 'saved')).map((c) => c.creatorId),
    ).toEqual([C]);
  });

  it('refuses anyone but a store owner', async () => {
    for (const role of ['BRAND', 'CREATOR', null]) {
      const { service } = build(role);
      await expect(service.list(OWNER, 'saved')).rejects.toBeInstanceOf(
        AppError,
      );
      await expect(service.list(OWNER, 'saved')).rejects.toMatchObject({
        code: 'FORBIDDEN',
      });
    }
  });
});
