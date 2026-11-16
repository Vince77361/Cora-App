import { Injectable } from '@nestjs/common';
import { SwipeDecision } from '@prisma/client';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { StoragePort } from '../integrations/storage/storage.port';
import { PrinciplesService } from '../principles/principles.service';
import { TermsService } from '../terms/terms.service';
import { UsersService } from '../users/users.service';
import { VisibilityService } from '../visibility/visibility.service';
import { DiscoveryRepository } from './discovery.repository';
import { InterestCardModel, ProposalModel } from './dto/interest-card.model';
import { InterestTab, inTab, interestState, shortName } from './interest-rules';

const dateOnly = (value: Date): string => value.toISOString().slice(0, 10);

// 03의 관심·보류 목록과 크리에이터의 "받은 제안". 내가 저장한(관심 + 보류) 것만 읽는다.
// 넘긴 것은 읽지도 않고, 상대의 넘김은 어떤 응답에도 들어가지 않는다.
// 응답은 값을 하나씩 골라 담는다(캠페인 예산과 넘김 기록이 새지 않게 Prisma 행을 펼치지 않는다).
@Injectable()
export class InterestsService {
  constructor(
    private readonly users: UsersService,
    private readonly brands: BrandsService,
    private readonly campaigns: CampaignsService,
    private readonly creators: CreatorsService,
    private readonly principles: PrinciplesService,
    private readonly visibility: VisibilityService,
    private readonly terms: TermsService,
    private readonly repository: DiscoveryRepository,
    private readonly storage: StoragePort,
  ) {}

  async list(userId: string, tab: InterestTab): Promise<InterestCardModel[]> {
    const role = await this.users.getRole(userId);
    if (role === 'BRAND') return this.listForBrand(userId, tab);
    if (role === 'CREATOR') return this.listForCreator(userId, tab);
    throw new AppError('FORBIDDEN', '브랜드나 크리에이터 계정만 쓸 수 있어요.');
  }

  // 브랜드: 진행 중인 캠페인에서 내가 저장한 크리에이터. 보이지 않게 된 크리에이터(피하는 업종)는 빠진다.
  private async listForBrand(
    userId: string,
    tab: InterestTab,
  ): Promise<InterestCardModel[]> {
    const campaign = await this.campaigns.requireMyActive(userId);
    const brand = await this.brands.requireProfile(userId);
    const rows = await this.repository.listSavedDecisions(
      userId,
      'CREATOR',
      campaign.id,
    );
    const ids = rows.map((row) => row.targetId);
    const [visibleIds, sources, principles, matches] = await Promise.all([
      this.visibility.filterCreators(ids, {
        userId,
        kind: 'BRAND',
        industry: brand.industry,
      }),
      this.creators.findCardSources(ids),
      this.principles.findMany(ids),
      this.repository.listMatchesOfCampaign(campaign.id),
    ]);
    const visible = new Set(visibleIds);
    const sourceById = new Map(sources.map((s) => [s.userId, s]));
    const collaborationOf = new Map(
      matches.map((m) => [m.creatorId, m.collaborationId]),
    );
    const latest = await this.terms.latestMany([...collaborationOf.values()]);

    return rows.flatMap((row): InterestCardModel[] => {
      const source = sourceById.get(row.targetId);
      const p = principles.get(row.targetId);
      if (!source || !p || !visible.has(row.targetId)) return [];
      const collaborationId = collaborationOf.get(row.targetId) ?? null;
      const state = interestState(row.decision, collaborationId !== null);
      if (!state || !inTab(state, tab)) return [];
      const terms = collaborationId ? latest.get(collaborationId) : undefined;
      return [
        {
          targetKind: 'CREATOR',
          targetId: source.userId,
          name: source.displayName,
          shortName: shortName(source.displayName),
          headline: source.headline,
          photoUrl: source.photoUrl,
          state,
          // 서로 관심이면 최신 판본의 제작비, 아니면 내가 만든 제안의 금액. 둘 다 없으면 앱이 feeBand를 보여 준다.
          feeLabel: terms ? terms.fee : row.proposedFee,
          feeBand: p.feeBand,
          startFrom: terms ? dateOnly(terms.startDate) : null,
          hasProposal: row.proposedFee !== null,
          collaborationId,
        },
      ];
    });
  }

  // 크리에이터: 내가 저장한 캠페인. 마감한 캠페인은 서로 관심이 닿은 것만 남는다.
  private async listForCreator(
    userId: string,
    tab: InterestTab,
  ): Promise<InterestCardModel[]> {
    const rows = await this.repository.listSavedDecisions(userId, 'CAMPAIGN');
    const [entries, matches] = await Promise.all([
      this.campaigns.listWithBrand(rows.map((row) => row.targetId)),
      this.repository.listMatchesOfCreator(userId),
    ]);
    const visibleEntries = await this.visibility.filterCommissioners(
      entries.map((entry) => ({
        ownerId: entry.brand.userId,
        industry: entry.brand.industry,
        entry,
      })),
      userId,
    );
    const entryById = new Map(
      visibleEntries.map(({ entry }) => [entry.campaign.id, entry]),
    );
    const collaborationOf = new Map(
      matches.map((m) => [m.campaignId, m.collaborationId]),
    );
    const latest = await this.terms.latestMany([...collaborationOf.values()]);

    return rows.flatMap((row): InterestCardModel[] => {
      const entry = entryById.get(row.targetId);
      if (!entry) return [];
      const collaborationId = collaborationOf.get(row.targetId) ?? null;
      const state = interestState(row.decision, collaborationId !== null);
      if (!state || !inTab(state, tab)) return [];
      if (state !== 'MUTUAL' && entry.campaign.status !== 'ACTIVE') return [];
      const terms = collaborationId ? latest.get(collaborationId) : undefined;
      return [
        {
          targetKind: 'CAMPAIGN',
          targetId: entry.campaign.id,
          name: entry.brand.name,
          shortName: shortName(entry.brand.name),
          headline: entry.campaign.headline,
          photoUrl: entry.brand.photoUrl,
          state,
          feeLabel: terms ? terms.fee : entry.campaign.fee,
          feeBand: null,
          startFrom: terms ? dateOnly(terms.startDate) : null,
          hasProposal: false,
          collaborationId,
        },
      ];
    });
  }

  // 나에게 온 글이나 조건 제안이 붙은 관심 가운데 내가 아직 결정하지 않은 것.
  // 내가 관심을 보냈거나 넘긴 캠페인은 빠진다(보류는 결정이 아니라서 남는다). 제안이 붙어 있으면 금액과 혜택은 제안의 값이다.
  async listReceivedProposals(userId: string): Promise<ProposalModel[]> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
    const likes = await this.repository.listProposalLikesTo(userId);
    const campaignIds = likes.flatMap((like) =>
      like.campaignId ? [like.campaignId] : [],
    );
    const [entries, mine] = await Promise.all([
      this.campaigns.listActiveWithBrand(campaignIds),
      this.repository.listDecisionsOn(userId, 'CAMPAIGN', campaignIds),
    ]);
    const visibleEntries = await this.visibility.filterCommissioners(
      entries.map((entry) => ({
        ownerId: entry.brand.userId,
        industry: entry.brand.industry,
        entry,
      })),
      userId,
    );
    const entryById = new Map(
      visibleEntries.map(({ entry }) => [entry.campaign.id, entry]),
    );
    const settled = new Set(
      mine.filter((d) => d.decision !== 'HOLD').map((d) => d.targetId),
    );

    return likes.flatMap((like): ProposalModel[] => {
      const entry = like.campaignId ? entryById.get(like.campaignId) : null;
      if (!entry || settled.has(entry.campaign.id)) return [];
      return [this.toProposal(like, entry.campaign, entry.brand)];
    });
  }

  private toProposal(
    like: SwipeDecision,
    campaign: {
      id: string;
      fee: number;
      productProvided: boolean;
      format: ProposalModel['format'];
    },
    brand: { name: string; photoUrl: string | null },
  ): ProposalModel {
    return {
      campaignId: campaign.id,
      brandName: brand.name,
      brandPhotoUrl: brand.photoUrl,
      note: like.note,
      contentTitle: like.contentTitle,
      contentPhotoUrl: like.contentPhotoPath
        ? this.storage.publicUrl(like.contentPhotoPath)
        : null,
      fee: like.proposedFee ?? campaign.fee,
      productProvided: like.proposedProductProvided ?? campaign.productProvided,
      performance:
        like.proposedPerfRate !== null && like.proposedPerfCap !== null
          ? { ratePer1000: like.proposedPerfRate, cap: like.proposedPerfCap }
          : null,
      format: campaign.format,
    };
  }
}
