import { Injectable } from '@nestjs/common';
import { Campaign, UserRole } from '@prisma/client';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { kstDateString, startOfKstDay } from '../common/kst';
import { CreatorsService } from '../creators/creators.service';
import { CreatorCardSource } from '../creators/dto/creator-card-source';
import { PrinciplesModel } from '../principles/dto/principles.model';
import { PrinciplesService } from '../principles/principles.service';
import { StoreCardSource } from '../stores/dto/store-card-source';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { VisibilityService } from '../visibility/visibility.service';
import { campaignFacts, toCampaignCard, toCreatorCard } from './card-models';
import { principleTags, storeHeadline, storeRewardLine } from './card-text';
import {
  DAILY_CARD_COUNT,
  decidedTargetIds,
  lapsedOfferStoreIds,
  openOfferStoreIds,
  PREVIEW_CARD_COUNT,
  rankCandidates,
  RankInput,
  settledTargetIds,
} from './candidate-rules';
import {
  CampaignCardModel,
  PreviewCardModel,
  StoreCardModel,
} from './dto/recommendation-cards.model';
import {
  CampaignRecommendationsModel,
  CreatorRecommendationsModel,
  PreviewCardsModel,
} from './dto/recommendations.model';
import {
  CampaignFacts,
  matchScore,
  regionMatch,
  storeScore,
} from './match-score';
import {
  RecommendationsRepository,
  StoredItem,
} from './recommendations.repository';

const STORE_TAGS = ['소상공인', '팔로워무관'];

type CreatorViewer = Parameters<VisibilityService['filterCreators']>[1];
type CreatorSummary = NonNullable<
  Awaited<ReturnType<CreatorsService['getSummary']>>
>;

@Injectable()
export class RecommendationsService {
  constructor(
    private readonly users: UsersService,
    private readonly brands: BrandsService,
    private readonly campaigns: CampaignsService,
    private readonly creators: CreatorsService,
    private readonly stores: StoresService,
    private readonly principles: PrinciplesService,
    private readonly visibility: VisibilityService,
    private readonly collaborations: CollaborationsRepository,
    private readonly repository: RecommendationsRepository,
    private readonly clock: Clock,
  ) {}

  // 브랜드의 오늘 크리에이터 추천. 진행 중인 캠페인마다 목록이 따로 있다.
  async listCreators(userId: string): Promise<CreatorRecommendationsModel> {
    await this.assertRole(userId, 'BRAND', '브랜드 계정만 쓸 수 있어요.');
    const campaign = await this.campaigns.requireMyActive(userId);
    const brand = await this.brands.requireProfile(userId);
    const now = this.clock.now();
    const day = kstDateString(now);
    const facts: CampaignFacts = {
      industry: brand.industry,
      fee: campaign.fee,
      notRequired: campaign.notRequired,
      trialDays: campaign.trialDays,
    };
    const viewer: CreatorViewer = {
      userId,
      kind: 'BRAND',
      industry: brand.industry,
    };

    const stored = await this.repository.findList(
      userId,
      'BRAND',
      campaign.id,
      day,
    );
    const items =
      stored ??
      (await this.saveIfAny(
        userId,
        'BRAND',
        campaign.id,
        day,
        await this.buildCreatorList(userId, campaign, facts, viewer),
      ));

    // 저장된 목록은 줄 때마다 다시 거른다: 만든 뒤에 피하는 업종이 바뀌거나 탈퇴해도 바로 빠진다.
    const ids = items.map((item) => item.id);
    const [sources, principles, visibleIds, decisions] = await Promise.all([
      this.creators.findCardSources(ids),
      this.principles.findMany(ids),
      this.visibility.filterCreators(ids, viewer),
      this.repository.listDecisions(userId, 'CREATOR', campaign.id),
    ]);
    const sourceById = new Map(sources.map((s) => [s.userId, s]));
    const visible = new Set(visibleIds);
    const valid = ids.flatMap((id) => {
      const source = sourceById.get(id);
      const p = principles.get(id);
      return source && p && visible.has(id) ? [{ source, p }] : [];
    });
    const decided = decidedTargetIds(decisions, startOfKstDay(now));
    return {
      day,
      total: valid.length,
      cards: valid
        .filter(({ source }) => !decided.has(source.userId))
        .map(({ source, p }) => toCreatorCard(source, p, facts)),
    };
  }

  // 크리에이터의 오늘 캠페인·가게 추천.
  async listCampaigns(userId: string): Promise<CampaignRecommendationsModel> {
    await this.assertRole(userId, 'CREATOR', '크리에이터 계정만 쓸 수 있어요.');
    const now = this.clock.now();
    const day = kstDateString(now);
    const [mine, principles] = await Promise.all([
      this.creators.getSummary(userId),
      this.principles.find(userId),
    ]);

    const stored = await this.repository.findList(userId, 'CREATOR', null, day);
    const items =
      stored ??
      (await this.saveIfAny(
        userId,
        'CREATOR',
        null,
        day,
        await this.buildCampaignList(userId, mine, principles, now),
      ));

    const campaignIds = idsOf(items, 'CAMPAIGN');
    const storeIds = idsOf(items, 'STORE');
    const [
      campaignRows,
      storeRows,
      campaignDecisions,
      storeDecisions,
      offerStates,
      liveApplicationStores,
    ] = await Promise.all([
      this.campaigns.listActiveWithBrand(campaignIds),
      this.stores.findPublishedCards(storeIds, userId),
      this.repository.listDecisions(userId, 'CAMPAIGN'),
      this.repository.listDecisions(userId, 'STORE'),
      this.repository.listOfferStates(userId),
      this.repository.listLiveApplicationStoreIds(userId),
    ]);
    // 가게는 findPublishedCards가 이미 거른다. 캠페인은 여기서 거른다.
    const visibleCampaigns = await this.visibility.filterCommissioners(
      campaignRows.map((row) => ({
        ownerId: row.brand.userId,
        industry: row.brand.industry,
        row,
      })),
      userId,
    );
    const campaignById = new Map(
      visibleCampaigns.map(({ row }) => [row.campaign.id, row]),
    );
    const storeById = new Map(storeRows.map((s) => [s.summary.id, s]));
    const startOfToday = startOfKstDay(now);
    const decidedCampaigns = decidedTargetIds(campaignDecisions, startOfToday);
    // 오늘 목록이 만들어진 뒤에 지원했거나 오퍼가 오간 가게도 이미 관계가 생긴 것이라 바로 뺀다.
    const relatedStores = new Set([
      ...openOfferStoreIds(offerStates, now),
      ...liveApplicationStores,
    ]);
    const decidedStores = decidedTargetIds(storeDecisions, startOfToday);

    const valid: {
      decided: boolean;
      card: CampaignCardModel | StoreCardModel;
    }[] = [];
    for (const item of items) {
      if (item.kind === 'CAMPAIGN') {
        const row = campaignById.get(item.id);
        if (!row) continue;
        valid.push({
          decided: decidedCampaigns.has(item.id),
          card: toCampaignCard(row.campaign, row.brand, principles),
        });
      } else if (item.kind === 'STORE') {
        const source = storeById.get(item.id);
        if (!source) continue;
        valid.push({
          decided: decidedStores.has(item.id) || relatedStores.has(item.id),
          card: toStoreCard(source, mine),
        });
      }
    }
    return {
      day,
      total: valid.length,
      cards: valid.filter((v) => !v.decided).map((v) => v.card),
    };
  }

  // 역할이 없는 사용자에게 보여 주는 읽기 전용 카드. 저장하지 않고 조회할 때마다 계산한다.
  // 보는 사람의 업종을 알 수 없어 피하는 업종 필터를 쓸 수 없으므로, 피하는 업종을 하나라도 고른 크리에이터는 내보내지 않는다.
  async listPreview(userId: string): Promise<PreviewCardsModel> {
    if ((await this.users.getRole(userId)) !== null) {
      throw new AppError('FORBIDDEN', '역할을 고르기 전에만 둘러볼 수 있어요.');
    }
    const pool = await this.creators.listCardSources();
    const principles = await this.principles.findMany(
      pool.map((c) => c.userId),
    );
    const cards = pool
      .flatMap((source) => {
        const p = principles.get(source.userId);
        return p && p.blockedIndustries.length === 0 ? [{ source, p }] : [];
      })
      .slice(0, PREVIEW_CARD_COUNT)
      .map(({ source, p }) => toPreviewCard(source, p));
    return { total: cards.length, cards };
  }

  // 추천할 사람이 한 명도 없으면 목록을 저장하지 않는다: 하루 동안 빈 목록에 묶이지 않고 새로 생긴 상대가 바로 나온다.
  private async saveIfAny(
    userId: string,
    scope: 'BRAND' | 'CREATOR',
    campaignId: string | null,
    day: string,
    items: StoredItem[],
  ): Promise<StoredItem[]> {
    if (items.length === 0) return [];
    return this.repository.saveList(userId, scope, campaignId, day, items);
  }

  private async buildCreatorList(
    userId: string,
    campaign: Campaign,
    facts: CampaignFacts,
    viewer: CreatorViewer,
  ): Promise<StoredItem[]> {
    const pool = await this.creators.listCardSources();
    const poolIds = pool.map((c) => c.userId);
    const [visibleIds, principles, decisions, open, dropped, likers] =
      await Promise.all([
        this.visibility.filterCreators(poolIds, viewer),
        this.principles.findMany(poolIds),
        this.repository.listDecisions(userId, 'CREATOR', campaign.id),
        this.collaborations.listOpenCreatorIds(userId, poolIds),
        this.collaborations.listDroppedCreatorIds(campaign.id, poolIds),
        this.repository.listCampaignLikerIds(campaign.id),
      ]);
    const visible = new Set(visibleIds);
    const settled = settledTargetIds(decisions);
    const candidates = pool.flatMap(
      (source): (RankInput & { id: string })[] => {
        const p = principles.get(source.userId);
        if (
          !p ||
          !visible.has(source.userId) ||
          settled.has(source.userId) ||
          open.has(source.userId) ||
          dropped.has(source.userId)
        ) {
          return [];
        }
        return [
          {
            id: source.userId,
            boosted: likers.has(source.userId),
            score: matchScore(p, facts).score,
            recency: source.joinedAt.getTime(),
          },
        ];
      },
    );
    return rankCandidates(candidates, DAILY_CARD_COUNT).map((c) => ({
      kind: 'CREATOR',
      id: c.id,
    }));
  }

  private async buildCampaignList(
    userId: string,
    mine: CreatorSummary | null,
    principles: PrinciplesModel | null,
    now: Date,
  ): Promise<StoredItem[]> {
    const [campaignRows, storeRows] = await Promise.all([
      this.campaigns.listActiveWithBrand(),
      this.stores.listPublishedCards(userId),
    ]);
    const visibleCampaigns = await this.visibility.filterCommissioners(
      campaignRows.map((row) => ({
        ownerId: row.brand.userId,
        industry: row.brand.industry,
        row,
      })),
      userId,
    );
    const brandIds = visibleCampaigns.map((v) => v.ownerId);
    const [
      campaignDecisions,
      storeDecisions,
      openCommissioners,
      offerStates,
      liveApplicationStores,
      likedByCampaign,
    ] = await Promise.all([
      this.repository.listDecisions(userId, 'CAMPAIGN'),
      this.repository.listDecisions(userId, 'STORE'),
      this.collaborations.listOpenCommissionerIds(userId, [
        ...brandIds,
        ...storeRows.map((s) => s.ownerId),
      ]),
      this.repository.listOfferStates(userId),
      this.repository.listLiveApplicationStoreIds(userId),
      this.repository.listCampaignIdsThatLiked(userId, brandIds),
    ]);
    const settledCampaigns = settledTargetIds(campaignDecisions);
    const settledStores = settledTargetIds(storeDecisions);
    const openOfferStores = openOfferStoreIds(offerStates, now);
    const lapsedOfferStores = lapsedOfferStoreIds(offerStates, now);

    const candidates: (RankInput & StoredItem)[] = [];
    for (const { row } of visibleCampaigns) {
      const { campaign, brand } = row;
      if (
        settledCampaigns.has(campaign.id) ||
        openCommissioners.has(brand.userId)
      ) {
        continue;
      }
      candidates.push({
        kind: 'CAMPAIGN',
        id: campaign.id,
        boosted: likedByCampaign.has(campaign.id),
        score: principles
          ? matchScore(principles, campaignFacts(campaign, brand)).score
          : 0,
        recency: campaign.createdAt.getTime(),
      });
    }
    for (const source of storeRows) {
      const store = source.summary;
      if (
        settledStores.has(store.id) ||
        openCommissioners.has(source.ownerId) ||
        openOfferStores.has(store.id) ||
        liveApplicationStores.has(store.id)
      ) {
        continue;
      }
      candidates.push({
        kind: 'STORE',
        id: store.id,
        boosted: lapsedOfferStores.has(store.id),
        score: storeScore(
          principles,
          store,
          mine
            ? regionMatch(store, mine)
            : { sameSido: false, sameSigungu: false },
        ),
        recency: source.publishedAt?.getTime() ?? 0,
      });
    }
    return rankCandidates(candidates, DAILY_CARD_COUNT).map(({ kind, id }) => ({
      kind,
      id,
    }));
  }

  private async assertRole(
    userId: string,
    role: UserRole,
    message: string,
  ): Promise<void> {
    if ((await this.users.getRole(userId)) !== role) {
      throw new AppError('FORBIDDEN', message);
    }
  }
}

function idsOf(items: StoredItem[], kind: StoredItem['kind']): string[] {
  return items.filter((item) => item.kind === kind).map((item) => item.id);
}

function toStoreCard(
  source: StoreCardSource,
  mine: CreatorSummary | null,
): StoreCardModel {
  const store = source.summary;
  return {
    kind: 'STORE',
    store,
    headline: storeHeadline({
      intro: source.intro,
      recruitLine: source.recruitLine,
      industry: store.industry,
    }),
    tags: STORE_TAGS,
    otherSido:
      mine && store.regionSido && store.regionSido !== mine.regionSido
        ? store.regionSido
        : null,
    rewardLine: storeRewardLine(store.defaultTerms),
  };
}

function toPreviewCard(
  source: CreatorCardSource,
  p: PrinciplesModel,
): PreviewCardModel {
  return {
    creatorId: source.userId,
    displayName: source.displayName,
    headline: source.headline,
    photoUrl: source.photoUrl,
    feeBand: p.feeBand,
    tags: principleTags(p),
  };
}
