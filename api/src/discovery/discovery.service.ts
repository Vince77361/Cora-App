import { Injectable, Logger } from '@nestjs/common';
import { Campaign, SwipeDecision, UserRole } from '@prisma/client';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { startOfKstDay } from '../common/kst';
import { CreatorsService } from '../creators/creators.service';
import { NotificationsService } from '../notifications/notifications.service';
import { StoresService } from '../stores/stores.service';
import { BrandProposal, draftTerms } from '../terms/draft-terms';
import { TermsService } from '../terms/terms.service';
import { UsersService } from '../users/users.service';
import { VisibilityService } from '../visibility/visibility.service';
import {
  DecisionResultModel,
  UndoneDecisionModel,
} from './dto/decision-result.model';
import { PassReasonDto } from './dto/pass-reason.dto';
import { BrandProposalDto, PutDecisionDto } from './dto/put-decision.dto';
import {
  DecisionKey,
  DiscoveryRepository,
  isUniqueViolation,
} from './discovery.repository';
import {
  DecisionInput,
  NOTE_MAX,
  planDecisionWrite,
  proposalProblem,
} from './discovery-rules';

// 한 결정이 낸 결과. 서로 관심이 이번 결정으로 새로 생겼을 때만 알림을 보낸다.
interface Outcome {
  matched: boolean;
  collaborationId: string | null;
  createdNow: boolean;
}

const NOT_MATCHED: Outcome = {
  matched: false,
  collaborationId: null,
  createdNow: false,
};

const pairLockKey = (campaignId: string, creatorId: string): string =>
  `discovery:${campaignId}:${creatorId}`;

function alreadyMatched(): AppError {
  return new AppError(
    'CONFLICT',
    '이미 서로 관심이 닿아서 결정을 바꿀 수 없어요.',
  );
}

// 관심·넘김·보류와 서로 관심. 넘김과 넘긴 이유는 본인에게만 쓰이고 상대에게 가는 응답과 알림에 들어가지 않는다.
@Injectable()
export class DiscoveryService {
  private readonly logger = new Logger(DiscoveryService.name);

  constructor(
    private readonly users: UsersService,
    private readonly brands: BrandsService,
    private readonly campaigns: CampaignsService,
    private readonly creators: CreatorsService,
    private readonly stores: StoresService,
    private readonly visibility: VisibilityService,
    private readonly notifications: NotificationsService,
    private readonly terms: TermsService,
    private readonly collaborations: CollaborationsRepository,
    private readonly repository: DiscoveryRepository,
    private readonly clock: Clock,
  ) {}

  async decide(
    userId: string,
    input: PutDecisionDto,
  ): Promise<DecisionResultModel> {
    const role = await this.users.getRole(userId);
    if (role === 'BRAND') return this.brandDecide(userId, input);
    if (role === 'CREATOR') return this.creatorDecide(userId, input);
    throw new AppError(
      'FORBIDDEN',
      '브랜드나 크리에이터 계정만 관심을 보낼 수 있어요.',
    );
  }

  // 가게 카드는 오른쪽(지원)이 2번의 applyToStore이고, 넘김만 여기서 저장한다.
  async passStore(userId: string, storeId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
    const [store] = await this.stores.findPublishedCards([storeId], userId);
    if (!store) throw new AppError('NOT_FOUND', '가게를 찾을 수 없어요.');
    const key: DecisionKey = {
      actorId: userId,
      targetKind: 'STORE',
      targetId: store.summary.id,
      campaignId: null,
    };
    const now = this.clock.now();
    await this.repository.transaction(async (tx) => {
      await this.repository.lock(`discovery-store:${userId}:${storeId}`, tx);
      const existing = await this.repository.findDecision(key, tx);
      const write = planDecisionWrite(existing, { decision: 'PASS' });
      if (write.kind === 'create') {
        await this.repository.createDecision(key, write.data, now, tx);
      } else if (write.kind === 'update' && existing) {
        await this.repository.updateDecision(existing.id, write.data, now, tx);
      }
    });
  }

  // 넘긴 이유는 PASS 결정이 있을 때만 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.
  async setPassReason(userId: string, input: PassReasonDto): Promise<void> {
    const role = await this.users.getRole(userId);
    let campaignId: string | null;
    if (role === 'BRAND' && input.targetKind === 'CREATOR') {
      campaignId = (await this.campaigns.requireMyActive(userId)).id;
    } else if (role === 'CREATOR' && input.targetKind === 'CAMPAIGN') {
      campaignId = input.targetId;
    } else if (role === 'CREATOR' && input.targetKind === 'STORE') {
      campaignId = null;
    } else if (role === 'BRAND' || role === 'CREATOR') {
      throw new AppError('VALIDATION_FAILED', '넘길 수 없는 대상이에요.');
    } else {
      throw new AppError(
        'FORBIDDEN',
        '브랜드나 크리에이터 계정만 쓸 수 있어요.',
      );
    }
    const existing = await this.repository.findDecision({
      actorId: userId,
      targetKind: input.targetKind,
      targetId: input.targetId,
      campaignId,
    });
    if (existing?.decision !== 'PASS') {
      throw new AppError('CONFLICT', '넘긴 카드에만 이유를 남길 수 있어요.');
    }
    await this.repository.setPassReason(
      existing.id,
      input.reason,
      existing.updatedAt,
    );
  }

  // 오늘(한국 날짜) 내가 가장 나중에 한 결정을 행째 지운다(넘긴 이유와 브랜드의 제안도 함께).
  // 오늘 한 결정이 없으면 null이고 아무것도 지우지 않는다. 서로 관심이 된 것은 되돌릴 수 없다.
  async undoLast(userId: string): Promise<UndoneDecisionModel | null> {
    const role = await this.users.getRole(userId);
    if (role !== 'BRAND' && role !== 'CREATOR') {
      throw new AppError(
        'FORBIDDEN',
        '브랜드나 크리에이터 계정만 쓸 수 있어요.',
      );
    }
    const last = await this.repository.findLastSince(
      userId,
      startOfKstDay(this.clock.now()),
    );
    if (!last) return null;
    const pair = this.pairOf(userId, last);
    return this.repository.transaction(async (tx) => {
      if (pair) await this.repository.lock(pairLockKey(...pair), tx);
      // 기다리는 사이에 다른 요청이 지웠거나 서로 관심이 닿았을 수 있어 잠근 뒤에 다시 본다.
      const current = await this.repository.findDecisionById(last.id, tx);
      if (!current) return null;
      if (pair && (await this.repository.findMatch(pair[0], pair[1], tx))) {
        throw alreadyMatched();
      }
      await this.repository.deleteDecision(current.id, tx);
      return { targetKind: current.targetKind, targetId: current.targetId };
    });
  }

  private async brandDecide(
    userId: string,
    input: PutDecisionDto,
  ): Promise<DecisionResultModel> {
    if (input.targetKind !== 'CREATOR') {
      throw new AppError(
        'VALIDATION_FAILED',
        '브랜드는 크리에이터에게만 관심을 보낼 수 있어요.',
      );
    }
    const campaign = await this.campaigns.requireMyActive(userId);
    const brand = await this.brands.requireProfile(userId);
    const note = this.cleanNote(input.note, NOTE_MAX.BRAND);
    const proposal = this.cleanProposal(input, campaign);
    const creatorId = input.targetId;
    // 보이지 않는 크리에이터(피하는 업종, 협업 원칙 없음, 탈퇴)는 없는 것과 같다.
    const visible =
      (await this.creators.getSummary(creatorId)) !== null &&
      (await this.visibility.creatorVisibleTo(creatorId, {
        userId,
        kind: 'BRAND',
        industry: brand.industry,
      }));
    if (!visible) {
      throw new AppError('NOT_FOUND', '크리에이터를 찾을 수 없어요.');
    }
    const card =
      input.decision === 'LIKE' && note
        ? await this.creators.getCardCopy(creatorId)
        : null;
    return this.saveAndMatch({
      side: 'BRAND',
      campaign,
      creatorId,
      key: {
        actorId: userId,
        targetKind: 'CREATOR',
        targetId: creatorId,
        campaignId: campaign.id,
      },
      input: { decision: input.decision, note, proposal, card },
    });
  }

  private async creatorDecide(
    userId: string,
    input: PutDecisionDto,
  ): Promise<DecisionResultModel> {
    if (input.targetKind !== 'CAMPAIGN') {
      throw new AppError(
        'VALIDATION_FAILED',
        '크리에이터는 캠페인에만 관심을 보낼 수 있어요.',
      );
    }
    if (input.proposal) {
      throw new AppError(
        'VALIDATION_FAILED',
        '조건 제안은 브랜드만 붙일 수 있어요.',
      );
    }
    const note = this.cleanNote(input.note, NOTE_MAX.CREATOR);
    const campaign = await this.campaigns.findActiveById(input.targetId);
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
      throw new AppError('NOT_FOUND', '캠페인을 찾을 수 없어요.');
    }
    await this.creators.requireProfile(userId);
    return this.saveAndMatch({
      side: 'CREATOR',
      campaign,
      creatorId: userId,
      key: {
        actorId: userId,
        targetKind: 'CAMPAIGN',
        targetId: campaign.id,
        campaignId: campaign.id,
      },
      input: { decision: input.decision, note },
    });
  }

  // 결정을 저장하고, 반대쪽에도 관심이 있으면 같은 트랜잭션에서 서로 관심을 만든다.
  // 같은 쌍의 결정은 잠금으로 한 줄로 서므로 동시에 서로 관심을 보내도 매칭, 협업, 버전 1은 한 번만 만들어진다
  // (유일 제약이 마지막 안전망이다).
  private async saveAndMatch(args: {
    side: 'BRAND' | 'CREATOR';
    campaign: Campaign;
    creatorId: string;
    key: DecisionKey;
    input: DecisionInput;
  }): Promise<DecisionResultModel> {
    const { side, campaign, creatorId, key, input } = args;
    const now = this.clock.now();
    let outcome: Outcome;
    try {
      outcome = await this.repository.transaction(async (tx) => {
        await this.repository.lock(pairLockKey(campaign.id, creatorId), tx);
        if (await this.repository.findMatch(campaign.id, creatorId, tx)) {
          throw alreadyMatched();
        }
        const existing = await this.repository.findDecision(key, tx);
        const write = planDecisionWrite(existing, input);
        let mine: SwipeDecision | null = existing;
        if (write.kind === 'create') {
          mine = await this.repository.createDecision(key, write.data, now, tx);
        } else if (write.kind === 'update' && existing) {
          mine = await this.repository.updateDecision(
            existing.id,
            write.data,
            now,
            tx,
          );
        }
        if (!mine || mine.decision !== 'LIKE') return NOT_MATCHED;

        const theirs = await this.repository.findDecision(
          side === 'BRAND'
            ? {
                actorId: creatorId,
                targetKind: 'CAMPAIGN',
                targetId: campaign.id,
                campaignId: campaign.id,
              }
            : {
                actorId: campaign.brandId,
                targetKind: 'CREATOR',
                targetId: creatorId,
                campaignId: campaign.id,
              },
          tx,
        );
        if (theirs?.decision !== 'LIKE') return NOT_MATCHED;
        const brandRow = side === 'BRAND' ? mine : theirs;
        const creatorRow = side === 'CREATOR' ? mine : theirs;
        return this.createMatch(
          campaign,
          creatorId,
          brandRow,
          creatorRow,
          now,
          tx,
        );
      });
    } catch (error) {
      // 유일 제약이 마지막 안전망이다: 같은 쌍의 서로 관심이 이미 만들어졌으면 그 결과를 돌려준다.
      if (!isUniqueViolation(error)) throw error;
      const match = await this.repository.findMatch(campaign.id, creatorId);
      if (!match) throw error;
      outcome = {
        matched: true,
        collaborationId: match.collaborationId,
        createdNow: false,
      };
    }
    if (outcome.createdNow && outcome.collaborationId) {
      await this.notifyMutual(campaign, creatorId, outcome.collaborationId);
    }
    return {
      decision: input.decision,
      matched: outcome.matched,
      collaborationId: outcome.collaborationId,
    };
  }

  // 서로 관심: matches 행, 협업(MATCHED, 정산 방식 FIXED, 맡기는 쪽은 브랜드), 조건 버전 1.
  // 크리에이터가 "조건부터 질문하기"로 먼저 만든 협업(INQUIRY)이 있으면 새로 만들지 않고 그것을 MATCHED로 올린다.
  private async createMatch(
    campaign: Campaign,
    creatorId: string,
    brandRow: SwipeDecision,
    creatorRow: SwipeDecision,
    now: Date,
    tx: Parameters<DiscoveryRepository['createMatch']>[1],
  ): Promise<Outcome> {
    let collaboration = await this.collaborations.findBrandContract(
      campaign.id,
      creatorId,
      tx,
    );
    if (!collaboration) {
      collaboration = await this.collaborations.create(
        {
          kind: 'BRAND_CONTRACT',
          stage: 'MATCHED',
          commissionerId: campaign.brandId,
          creatorId,
          offerId: null,
          storeId: null,
          campaignId: campaign.id,
          // 브랜드 협업의 조건은 terms_versions가 담는다. 가게 오퍼의 조건 사본 열은 비워 둔다.
          terms: {},
          settlementMethod: 'FIXED',
          fundedAt: null,
          submitDueAt: null,
          createdAt: now,
        },
        tx,
      );
    } else if (collaboration.stage === 'INQUIRY') {
      const moved = await this.collaborations.advance(
        collaboration.id,
        'INQUIRY',
        'MATCHED',
        {},
        tx,
      );
      if (!moved) throw alreadyMatched();
    } else {
      throw new AppError(
        'CONFLICT',
        '이 캠페인으로 이미 진행한 협업이 있어요.',
      );
    }
    await this.repository.createMatch(
      {
        campaignId: campaign.id,
        creatorId,
        collaborationId: collaboration.id,
        matchedAt: now,
      },
      tx,
    );
    if (!(await this.terms.latest(collaboration.id, tx))) {
      const card = await this.creators.getCardCopy(creatorId);
      const values = draftTerms(
        campaign,
        { cardHeadline: card?.headline ?? null },
        creatorRow.note,
        proposalOf(brandRow),
      );
      await this.terms.createVersion(collaboration.id, null, values, tx);
    }
    return {
      matched: true,
      collaborationId: collaboration.id,
      createdNow: true,
    };
  }

  // 커밋 뒤에 양쪽에 알린다. 알림이 실패해도 이미 저장된 서로 관심은 유효하다(원장 판단 R22).
  private async notifyMutual(
    campaign: Campaign,
    creatorId: string,
    collaborationId: string,
  ): Promise<void> {
    const target = { kind: 'MATCH' as const, id: collaborationId };
    const dedupeKey = `mutual-interest:${collaborationId}`;
    const send = async (
      userId: string,
      role: UserRole,
      actor: { userId: string; name: string; photoPath: string | null },
    ): Promise<void> => {
      try {
        await this.notifications.notify({
          userId,
          role,
          kind: 'MUTUAL_INTEREST',
          actor,
          target,
          dedupeKey,
        });
      } catch (error) {
        this.logger.warn(
          `서로 관심 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    };
    const [brandActor, creatorActor] = await Promise.all([
      this.brands.getActor(campaign.brandId).catch(() => null),
      this.creators.getActor(creatorId).catch(() => null),
    ]);
    await send(
      creatorId,
      'CREATOR',
      brandActor ?? {
        userId: campaign.brandId,
        name: '브랜드',
        photoPath: null,
      },
    );
    await send(
      campaign.brandId,
      'BRAND',
      creatorActor ?? {
        userId: creatorId,
        name: '크리에이터',
        photoPath: null,
      },
    );
  }

  // 되돌릴 결정이 가리키는 (캠페인, 크리에이터) 쌍. 가게 넘김은 쌍이 없다.
  private pairOf(
    userId: string,
    row: SwipeDecision,
  ): [campaignId: string, creatorId: string] | null {
    if (!row.campaignId) return null;
    if (row.targetKind === 'CREATOR') return [row.campaignId, row.targetId];
    if (row.targetKind === 'CAMPAIGN') return [row.campaignId, userId];
    return null;
  }

  // 글은 앞뒤 공백을 걷어 내고 빈 글은 null로 본다. 보내지 않았으면 undefined(저장된 글을 그대로 둔다).
  private cleanNote(
    value: string | undefined,
    max: number,
  ): string | null | undefined {
    if (value === undefined) return undefined;
    const text = value.trim();
    if (text.length > max) {
      throw new AppError(
        'VALIDATION_FAILED',
        `글은 ${max}자까지 쓸 수 있어요.`,
      );
    }
    return text === '' ? null : text;
  }

  // 제안은 관심에만 붙고, 범위와 단위는 정책 한 곳(proposalProblem)에서 본다.
  private cleanProposal(
    input: PutDecisionDto,
    campaign: Campaign,
  ): BrandProposal | undefined {
    if (!input.proposal) return undefined;
    if (input.decision !== 'LIKE') {
      throw new AppError(
        'VALIDATION_FAILED',
        '조건 제안은 관심을 보낼 때만 붙일 수 있어요.',
      );
    }
    const proposal = toProposal(input.proposal);
    const problem = proposalProblem(proposal, campaign.format);
    if (problem) throw new AppError('VALIDATION_FAILED', problem);
    return proposal;
  }
}

function toProposal(dto: BrandProposalDto): BrandProposal {
  return {
    fee: dto.fee,
    productProvided: dto.productProvided,
    performance: dto.performance
      ? { ratePer1000: dto.performance.ratePer1000, cap: dto.performance.cap }
      : null,
  };
}

// 저장된 결정 행의 제안 칸을 값으로 읽는다. 제작비가 없으면 제안이 없는 것이다.
function proposalOf(row: SwipeDecision): BrandProposal | null {
  if (row.proposedFee === null || row.proposedProductProvided === null) {
    return null;
  }
  return {
    fee: row.proposedFee,
    productProvided: row.proposedProductProvided,
    performance:
      row.proposedPerfRate !== null && row.proposedPerfCap !== null
        ? { ratePer1000: row.proposedPerfRate, cap: row.proposedPerfCap }
        : null,
  };
}
