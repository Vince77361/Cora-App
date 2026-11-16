import { Injectable } from '@nestjs/common';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { PrinciplesService } from '../principles/principles.service';
import { UsersService } from '../users/users.service';
import { VisibilityService } from '../visibility/visibility.service';
import { campaignFacts, toCampaignCard, toCreatorCard } from './card-models';
import {
  CampaignDetailModel,
  CreatorCardDetailModel,
  SavedDecision,
} from './dto/card-details.model';
import { RecommendationsRepository } from './recommendations.repository';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 카드를 눌러 읽는 상세(브랜드의 크리에이터 카드, 크리에이터의 캠페인 상세).
// 보이지 않는 것과 내가 넘긴 것은 없는 것과 같게 404다: 상세가 열리는 곳은 추천과 관심 목록뿐이라 넘긴 카드에는 닿지 않고,
// 넘김은 상세의 어느 칸에도 나오지 않는다.
@Injectable()
export class CardDetailsService {
  constructor(
    private readonly users: UsersService,
    private readonly brands: BrandsService,
    private readonly campaigns: CampaignsService,
    private readonly creators: CreatorsService,
    private readonly principles: PrinciplesService,
    private readonly visibility: VisibilityService,
    private readonly repository: RecommendationsRepository,
  ) {}

  async getCampaignDetail(
    userId: string,
    campaignId: string,
  ): Promise<CampaignDetailModel> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
    const campaign = UUID.test(campaignId)
      ? await this.campaigns.findActiveById(campaignId)
      : null;
    const brand = campaign
      ? (await this.brands.findProfiles([campaign.brandId])).get(
          campaign.brandId,
        )
      : undefined;
    if (
      !campaign ||
      !brand ||
      !(await this.visibility.commissionerVisibleTo(
        { ownerId: campaign.brandId, industry: brand.industry },
        userId,
      ))
    ) {
      throw this.notFound('캠페인');
    }
    const myDecision = await this.savedDecision(
      userId,
      'CAMPAIGN',
      campaign.id,
      campaign.id,
      '캠페인',
    );
    const principles = await this.principles.find(userId);
    const card = toCampaignCard(campaign, brand, principles);
    return {
      ...card,
      startFrom: campaign.startFrom.toISOString().slice(0, 10),
      trialDays: campaign.trialDays,
      mustInclude: campaign.mustInclude,
      notRequired: campaign.notRequired,
      overlapCount: card.reasons.length,
      myDecision,
    };
  }

  async getCreatorCard(
    userId: string,
    creatorId: string,
  ): Promise<CreatorCardDetailModel> {
    if ((await this.users.getRole(userId)) !== 'BRAND') {
      throw new AppError('FORBIDDEN', '브랜드 계정만 쓸 수 있어요.');
    }
    const campaign = await this.campaigns.requireMyActive(userId);
    const brand = await this.brands.requireProfile(userId);
    const visible =
      UUID.test(creatorId) &&
      (await this.visibility.creatorVisibleTo(creatorId, {
        userId,
        kind: 'BRAND',
        industry: brand.industry,
      }));
    const [source] = visible
      ? await this.creators.findCardSources([creatorId])
      : [];
    const principles = source ? await this.principles.find(creatorId) : null;
    if (!source || !principles) throw this.notFound('크리에이터');
    const myDecision = await this.savedDecision(
      userId,
      'CREATOR',
      creatorId,
      campaign.id,
      '크리에이터',
    );
    return {
      ...toCreatorCard(source, principles, campaignFacts(campaign, brand)),
      myDecision,
    };
  }

  // 내 결정. 넘긴 것이면 상대가 없는 것과 같게 404로 막는다.
  private async savedDecision(
    userId: string,
    targetKind: 'CREATOR' | 'CAMPAIGN',
    targetId: string,
    campaignId: string,
    label: string,
  ): Promise<SavedDecision | null> {
    const decision = await this.repository.findDecision(
      userId,
      targetKind,
      targetId,
      campaignId,
    );
    if (decision === 'PASS') throw this.notFound(label);
    return decision;
  }

  private notFound(label: string): AppError {
    return new AppError('NOT_FOUND', `${label}를 찾을 수 없어요.`);
  }
}
