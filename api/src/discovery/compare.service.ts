import { Injectable } from '@nestjs/common';
import { Campaign, SwipeDecision, TermsVersion } from '@prisma/client';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { PrinciplesService } from '../principles/principles.service';
import { DRAFT_PIECES, DRAFT_USAGE_RIGHTS } from '../terms/draft-terms';
import { TermsService } from '../terms/terms.service';
import { UsersService } from '../users/users.service';
import { VisibilityService } from '../visibility/visibility.service';
import { compareDiff, CompareValues } from './compare-rules';
import { DiscoveryRepository } from './discovery.repository';
import { CompareModel, CompareSideModel } from './dto/compare.model';
import { interestState, shortName } from './interest-rules';

const dateOnly = (value: Date): string => value.toISOString().slice(0, 10);

// 04 후보 비교: 이 캠페인에서 내가 저장한(관심 또는 보류) 두 크리에이터를 같은 결과물 기준으로 견준다.
// 응답에 팔로워 수와 넘김은 없고, 캠페인 예산도 없다.
@Injectable()
export class CompareService {
  constructor(
    private readonly users: UsersService,
    private readonly brands: BrandsService,
    private readonly campaigns: CampaignsService,
    private readonly creators: CreatorsService,
    private readonly principles: PrinciplesService,
    private readonly visibility: VisibilityService,
    private readonly terms: TermsService,
    private readonly repository: DiscoveryRepository,
  ) {}

  async compare(userId: string, a: string, b: string): Promise<CompareModel> {
    if ((await this.users.getRole(userId)) !== 'BRAND') {
      throw new AppError('FORBIDDEN', '브랜드 계정만 쓸 수 있어요.');
    }
    if (a === b) {
      throw new AppError(
        'VALIDATION_FAILED',
        '서로 다른 두 후보를 골라 주세요.',
      );
    }
    const campaign = await this.campaigns.requireMyActive(userId);
    const brand = await this.brands.requireProfile(userId);
    const saved = await this.repository.listSavedDecisions(
      userId,
      'CREATOR',
      campaign.id,
      [a, b],
    );
    const rowOf = new Map(saved.map((row) => [row.targetId, row]));
    const visible = new Set(
      await this.visibility.filterCreators([a, b], {
        userId,
        kind: 'BRAND',
        industry: brand.industry,
      }),
    );
    // 저장하지 않았거나 보이지 않는 후보는 없는 것과 같다.
    if (![a, b].every((id) => rowOf.has(id) && visible.has(id))) {
      throw new AppError('NOT_FOUND', '비교할 후보를 찾을 수 없어요.');
    }
    const [sources, principles, matches] = await Promise.all([
      this.creators.findCardSources([a, b]),
      this.principles.findMany([a, b]),
      this.repository.listMatchesOfCampaign(campaign.id),
    ]);
    const sourceOf = new Map(sources.map((s) => [s.userId, s]));
    const collaborationOf = new Map(
      matches.map((m) => [m.creatorId, m.collaborationId]),
    );
    const latest = await this.terms.latestMany(
      [a, b].flatMap((id) => collaborationOf.get(id) ?? []),
    );

    const sides = [a, b].map((id): CompareSideModel => {
      const source = sourceOf.get(id);
      const p = principles.get(id);
      const row = rowOf.get(id);
      if (!source || !p || !row) {
        throw new AppError('NOT_FOUND', '비교할 후보를 찾을 수 없어요.');
      }
      const collaborationId = collaborationOf.get(id) ?? null;
      const state = interestState(row.decision, collaborationId !== null);
      if (!state) {
        throw new AppError('NOT_FOUND', '비교할 후보를 찾을 수 없어요.');
      }
      const values = this.valuesOf(
        campaign,
        row,
        collaborationId ? latest.get(collaborationId) : undefined,
        { feeBand: p.feeBand, faceOk: p.faceOk },
      );
      return {
        creatorId: source.userId,
        name: source.displayName,
        shortName: shortName(source.displayName),
        photoUrl: source.photoUrl,
        state,
        collaborationId,
        ...values,
      };
    });
    return {
      sides: [sides[0], sides[1]],
      differs: compareDiff(sides[0], sides[1]),
    };
  }

  // 설계 04의 표: 서로 관심이면 최신 판본, 아니면 내 제안(proposed*), 그것도 없으면 캠페인 값
  // (제작비와 촬영 가능일은 모르므로 null, 사용권은 버전 1의 기본값).
  private valuesOf(
    campaign: Campaign,
    row: SwipeDecision,
    terms: TermsVersion | undefined,
    creator: { feeBand: CompareValues['feeBand']; faceOk: boolean },
  ): CompareValues {
    if (terms) {
      return {
        format: terms.format,
        pieces: terms.pieces,
        productProvided: terms.productProvided,
        fee: terms.fee,
        feeBand: creator.feeBand,
        perfCap: terms.perfCap,
        usageRights: terms.usageRights,
        startDate: dateOnly(terms.startDate),
        faceOk: creator.faceOk,
      };
    }
    return {
      format: campaign.format,
      pieces: DRAFT_PIECES,
      productProvided: row.proposedProductProvided ?? campaign.productProvided,
      fee: row.proposedFee,
      feeBand: creator.feeBand,
      perfCap: row.proposedPerfCap,
      usageRights: DRAFT_USAGE_RIGHTS,
      startDate: null,
      faceOk: creator.faceOk,
    };
  }
}
