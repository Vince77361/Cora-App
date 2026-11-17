import { Injectable, Logger } from '@nestjs/common';
import {
  Collaboration,
  CollaborationStage,
  Prisma,
  TermsVersion,
} from '@prisma/client';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import {
  canTransition,
  negotiableStages,
} from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { NotificationsService } from '../notifications/notifications.service';
import { needsInstagram } from '../offers/offer-rules';
import { PrinciplesService } from '../principles/principles.service';
import { matchScore } from '../recommendations/match-score';
import { BrandProposal } from './draft-terms';
import { ProposeRewardDto } from './dto/propose-reward.dto';
import { TermsLatestModel, TermsVersionModel } from './dto/terms-version.model';
import { nextTermsValues, proposalProblem, sameReward } from './proposal-rules';
import {
  isMyTurn,
  principleFieldLabels,
  termsNotice,
  toTermsVersionModel,
} from './terms-rules';
import { TermsRepository } from './terms.repository';
import { TermsService } from './terms.service';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const INSTAGRAM_REQUIRED_MESSAGE = '인스타그램을 연동하면 수락할 수 있어요.';

// 브랜드 계약의 조건 판본을 당사자에게 보여 주고 확인받는 서비스(06 화면).
// 확인은 협업 행을 잠근 트랜잭션 안에서 조건부로 한 번만 반영한다: 같은 판본을 양쪽이 동시에 눌러도,
// 확인과 새 판본이 동시에 와도 "서로 다른 판본에 합의한" 상태가 생기지 않는다.
@Injectable()
export class NegotiationService {
  private readonly logger = new Logger(NegotiationService.name);

  constructor(
    private readonly collaborations: CollaborationsRepository,
    private readonly repository: TermsRepository,
    private readonly terms: TermsService,
    private readonly campaigns: CampaignsService,
    private readonly brands: BrandsService,
    private readonly creators: CreatorsService,
    private readonly principles: PrinciplesService,
    private readonly notifications: NotificationsService,
    private readonly clock: Clock,
  ) {}

  async getLatest(
    userId: string,
    collaborationId: string,
  ): Promise<TermsLatestModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const latest = await this.terms.latest(collaboration.id);
    const campaign = collaboration.campaignId
      ? await this.campaigns.getById(collaboration.campaignId)
      : null;
    if (!latest || !campaign) throw this.notFound();

    const isCreator = collaboration.creatorId === userId;
    const [principles, creator, brands] = await Promise.all([
      this.principles.find(collaboration.creatorId),
      this.creators.getSummary(collaboration.creatorId),
      this.brands.findProfiles([collaboration.commissionerId]),
    ]);
    const brand = brands.get(collaboration.commissionerId);
    return {
      terms: toTermsVersionModel(latest, collaboration.commissionerId),
      notice: termsNotice(principles),
      fields: principleFieldLabels(principles),
      reasons:
        principles && brand
          ? matchScore(principles, {
              industry: brand.industry,
              fee: campaign.fee,
              notRequired: campaign.notRequired,
              trialDays: campaign.trialDays,
            }).reasons
          : [],
      trialDays: campaign.trialDays,
      followers: creator?.followers ?? null,
      myTurn: isMyTurn(latest, isCreator),
      mine: latest.proposedById === userId,
      needsInstagram:
        isCreator &&
        needsInstagram(
          { format: latest.format, perViewCap: latest.perfCap },
          creator?.instagramConnected ?? false,
        ),
    };
  }

  // 내 쪽 확인 시각을 조건부로 채운다. 협업이 MATCHED면 NEGOTIATING으로, 양쪽이 다 확인했으면 AGREED로 옮긴다.
  // 이미 확인한 판본을 다시 누르면 아무것도 바꾸지 않고 같은 판본을 돌려준다(알림도 다시 보내지 않는다).
  async confirm(
    userId: string,
    collaborationId: string,
    version: number,
  ): Promise<TermsVersionModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const isCreator = collaboration.creatorId === userId;
    // 연동 여부는 트랜잭션 밖에서 읽는다(판본을 읽은 뒤 연동이 바뀌어도 그 순간의 사실로 충분하다).
    const connected = isCreator
      ? ((await this.creators.getSummary(userId))?.instagramConnected ?? false)
      : true;
    const now = this.clock.now();

    const { row, applied } = await this.repository.transaction(async (tx) => {
      await this.repository.lockCollaboration(collaboration.id, tx);
      const fresh = await this.collaborations.findById(collaboration.id, tx);
      const latest = await this.terms.latest(collaboration.id, tx);
      if (!fresh || !latest || !negotiableStages.includes(fresh.stage)) {
        throw new AppError('CONFLICT', '지금은 조건을 확인할 수 없어요.');
      }
      if (latest.version !== version) {
        throw new AppError('STALE_VERSION', '이전 판본이라 수락할 수 없어요.', {
          latestVersion: latest.version,
        });
      }
      if (
        isCreator &&
        needsInstagram(
          { format: latest.format, perViewCap: latest.perfCap },
          connected,
        )
      ) {
        throw new AppError('CONFLICT', INSTAGRAM_REQUIRED_MESSAGE);
      }
      const applied = await this.repository.markConfirmed(
        collaboration.id,
        version,
        isCreator ? 'CREATOR' : 'BRAND',
        now,
        tx,
      );
      if (!applied) return { row: latest, applied };
      if (fresh.stage === 'MATCHED') {
        await this.advanceOrFail(
          collaboration.id,
          'MATCHED',
          'NEGOTIATING',
          tx,
        );
      }
      const after = (await this.terms.latest(collaboration.id, tx)) ?? latest;
      if (after.brandConfirmedAt && after.creatorConfirmedAt) {
        await this.advanceOrFail(collaboration.id, 'NEGOTIATING', 'AGREED', tx);
      }
      return { row: after, applied };
    });

    if (applied) await this.notifyConfirmed(collaboration, userId, row);
    return toTermsVersionModel(row, collaboration.commissionerId);
  }

  // 협업 중에 돈과 혜택(제작비, 제품 제공, 성과 추가)만 바꿔 새 판본을 낸다. 나머지 항목은 직전 판본에서 옮긴다.
  // 확인과 같은 잠금 안에서 한다: 같은 판본을 보고 두 쪽이 동시에 내면 하나만 다음 판본이 되고 나머지는 409 STALE_VERSION이다.
  // 낸 쪽은 "확인함", 상대는 "대기"이고 단계는 NEGOTIATING이다(합의돼 있었다면 합의가 취소된다).
  async proposeReward(
    userId: string,
    collaborationId: string,
    input: ProposeRewardDto,
  ): Promise<TermsVersionModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const isCreator = collaboration.creatorId === userId;
    const connected = isCreator
      ? ((await this.creators.getSummary(userId))?.instagramConnected ?? false)
      : true;
    const proposal: BrandProposal = {
      fee: input.fee,
      productProvided: input.productProvided,
      performance: input.performance
        ? {
            ratePer1000: input.performance.ratePer1000,
            cap: input.performance.cap,
          }
        : null,
    };
    const now = this.clock.now();

    const created = await this.repository.transaction(async (tx) => {
      await this.repository.lockCollaboration(collaboration.id, tx);
      const fresh = await this.collaborations.findById(collaboration.id, tx);
      const latest = await this.terms.latest(collaboration.id, tx);
      if (!fresh || !latest || !negotiableStages.includes(fresh.stage)) {
        throw new AppError('CONFLICT', '지금은 조건을 제안할 수 없어요.');
      }
      if (latest.version !== input.baseVersion) {
        throw new AppError('STALE_VERSION', '이전 판본이라 제안할 수 없어요.', {
          latestVersion: latest.version,
        });
      }
      const problem = proposalProblem(proposal, latest.format);
      if (problem) throw new AppError('VALIDATION_FAILED', problem);
      if (sameReward(latest, proposal)) {
        throw new AppError('VALIDATION_FAILED', '바꾼 조건이 없어요.');
      }
      if (
        isCreator &&
        proposal.performance !== null &&
        needsInstagram(
          { format: latest.format, perViewCap: proposal.performance.cap },
          connected,
        )
      ) {
        throw new AppError('CONFLICT', INSTAGRAM_REQUIRED_MESSAGE);
      }
      const row = await this.terms.createVersion(
        collaboration.id,
        userId,
        nextTermsValues(latest, proposal, isCreator ? 'CREATOR' : 'BRAND', now),
        tx,
      );
      if (fresh.stage !== 'NEGOTIATING') {
        // 단계 표가 원본이다: MATCHED와 AGREED만 협의로 옮길 수 있다.
        if (!canTransition('BRAND_CONTRACT', fresh.stage, 'NEGOTIATING')) {
          throw new AppError('CONFLICT', '지금은 조건을 제안할 수 없어요.');
        }
        await this.advanceOrFail(
          collaboration.id,
          fresh.stage,
          'NEGOTIATING',
          tx,
        );
      }
      return row;
    });

    await this.notifyProposed(collaboration, userId, created);
    return toTermsVersionModel(created, collaboration.commissionerId);
  }

  // 잠금 안이라 실패할 길이 없지만, 실패하면 확인만 남고 단계가 안 움직인 채 끝나므로 트랜잭션째 되돌린다.
  private async advanceOrFail(
    collaborationId: string,
    from: CollaborationStage,
    to: CollaborationStage,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    if (
      !(await this.collaborations.advance(collaborationId, from, to, {}, tx))
    ) {
      throw new AppError('CONFLICT', '지금은 조건을 확인할 수 없어요.');
    }
  }

  // 커밋 뒤에 상대에게 알린다. 실패해도 이미 저장된 확인은 유효하다(원장 판단 R22).
  private notifyConfirmed(
    collaboration: Collaboration,
    userId: string,
    row: TermsVersion,
  ): Promise<void> {
    return this.notifyCounterpart(
      collaboration,
      userId,
      row,
      'TERMS_CONFIRMED',
      'terms-confirmed',
    );
  }

  // 새 판본을 낸 것도 같은 모양으로 알린다(낸 쪽에는 알리지 않는다).
  private notifyProposed(
    collaboration: Collaboration,
    userId: string,
    row: TermsVersion,
  ): Promise<void> {
    return this.notifyCounterpart(
      collaboration,
      userId,
      row,
      'TERMS_PROPOSED',
      'terms-proposed',
    );
  }

  private async notifyCounterpart(
    collaboration: Collaboration,
    userId: string,
    row: TermsVersion,
    kind: 'TERMS_CONFIRMED' | 'TERMS_PROPOSED',
    dedupePrefix: string,
  ): Promise<void> {
    const byCreator = collaboration.creatorId === userId;
    try {
      const actor = (byCreator
        ? await this.creators.getActor(userId)
        : await this.brands.getActor(userId)) ?? {
        userId,
        name: byCreator ? '크리에이터' : '브랜드',
        photoPath: null,
      };
      await this.notifications.notify({
        userId: byCreator
          ? collaboration.commissionerId
          : collaboration.creatorId,
        role: byCreator ? 'BRAND' : 'CREATOR',
        kind,
        actor,
        params: { version: row.version },
        target: { kind: 'TERMS', id: collaboration.id },
        dedupeKey: `${dedupePrefix}:${collaboration.id}:${row.version}:${userId}`,
      });
    } catch (error) {
      this.logger.warn(
        `조건 알림을 남기지 못했어요(${kind}): ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 당사자가 아니거나 브랜드 계약이 아니면 없는 협업과 같게 404다.
  private async requireParty(
    userId: string,
    collaborationId: string,
  ): Promise<Collaboration> {
    const row = UUID.test(collaborationId)
      ? await this.collaborations.findById(collaborationId)
      : null;
    if (
      !row ||
      row.kind !== 'BRAND_CONTRACT' ||
      (row.commissionerId !== userId && row.creatorId !== userId)
    ) {
      throw new AppError('NOT_FOUND', '협업을 찾을 수 없어요.');
    }
    return row;
  }

  private notFound(): AppError {
    return new AppError('NOT_FOUND', '조건을 찾을 수 없어요.');
  }
}
