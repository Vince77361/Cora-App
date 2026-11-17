import { Injectable, Logger } from '@nestjs/common';
import {
  CancelRequest,
  Campaign,
  Collaboration,
  TermsVersion,
} from '@prisma/client';
import { BrandProfileModel } from '../brands/dto/brand-profile.model';
import { BrandsService } from '../brands/brands.service';
import { budgetLeft } from '../campaigns/campaign-budget';
import { CampaignsService } from '../campaigns/campaigns.service';
import { Clock } from '../common/clock';
import { readSnapshot } from '../contracts/contract-snapshot';
import { AppError } from '../common/errors/app-error';
import { ConversationsService } from '../conversations/conversations.service';
import { CreatorsService } from '../creators/creators.service';
import { JobRunContext, JobScheduler } from '../jobs/job-scheduler';
import { postingsForFullRefund } from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OffersService } from '../offers/offers.service';
import { PaymentsService } from '../payments/payments.service';
import { PayoutAccountsService } from '../payout-accounts/payout-accounts.service';
import { RefundsService } from '../settlements/refunds.service';
import { SettlementsRepository } from '../settlements/settlements.repository';
import { StoresService } from '../stores/stores.service';
import { isMyTurn, termsMaxCash } from '../terms/terms-rules';
import { TermsService } from '../terms/terms.service';
import { hasViewPay, readTerms } from '../stores/reward-terms';
import { CancelRequestsRepository } from './cancel-requests.repository';
import {
  brandProgress,
  nextActionFor,
  preContractStages,
} from './collaboration-stage';
import { submissionDeadlineJobKeys } from './collaboration-jobs';
import { CollaborationsRepository } from './collaborations.repository';
import {
  buildSteps,
  COLLABORATION_DONE_STAGES,
  liveAmounts,
  payoutStatusOf,
  viewReportStatusOf,
} from './collaboration-view';
import { CollaborationScope } from './dto/collaboration-query.dto';
import { CollaborationModel } from './dto/collaboration.model';
import { DropChoice } from './dto/drop-collaboration.dto';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DAY_MS = 24 * 60 * 60 * 1000;
// 사장님 취소 요청의 유효 기간.
export const CANCEL_REQUEST_DAYS = 3;

export const cancelRequestJobKey = (requestId: string): string =>
  `cancel-request:${requestId}`;
// 취소 환급 재시도 작업의 키. 환급 행의 중복 방지 키와 같은 글자지만 서로 다른 곳(작업 큐, 환급 표)의 키다.
export const cancelRefundKey = (collaborationId: string): string =>
  `cancel-refund:${collaborationId}`;

type CancelOutcome = 'cancelled' | 'not-funded' | 'request-closed';

interface Context {
  now: Date;
  funded: Map<string, { escrow: number; fee: number }>;
  views: Map<string, number>;
  settlements: Awaited<ReturnType<SettlementsRepository['settlementsFor']>>;
  payouts: Awaited<ReturnType<SettlementsRepository['latestPayoutsFor']>>;
  pending: Map<string, CancelRequest>;
  stores: Map<string, Awaited<ReturnType<StoresService['getOfferCard']>>>;
  creators: Map<string, Awaited<ReturnType<CreatorsService['getSummary']>>>;
  brands: Map<string, Awaited<ReturnType<BrandsService['findProfiles']>>>;
  accounts: Map<string, boolean>;
  // 브랜드 계약 칸의 재료. 목록 전체에 한 번씩만 읽는다(행마다 읽지 않는다).
  campaigns: Map<string, { campaign: Campaign; brand: BrandProfileModel }>;
  latestTerms: Map<string, TermsVersion>;
  conversationIds: Map<string, string>;
  contractProgress: Map<string, 'AWAITING_BRAND' | 'CONCLUDED'>;
  // 브랜드 계약마다 체결된 계약의 조건 사본(성과 추가·고정 제작비). 정산 값은 이 사본에서 읽는다.
  concludedTerms: Map<string, ReturnType<typeof readSnapshot>>;
  // 캠페인마다, 확보액을 세는 브랜드 협업들의 확보액. 그 캠페인의 브랜드가 보는 행에서만 채운다.
  securedByCampaign: Map<string, number[]>;
}

// 협업을 당사자에게 보여 주고(목록·상세), 결제 뒤에 그만두는(크리에이터의 취소, 사장님의 취소 요청과 동의) 서비스.
// 돈이 움직이는 쪽(장부·환급 행)은 단계 전이와 한 트랜잭션이고, PG 환급·작업 취소·알림은 커밋 뒤에 한다.
@Injectable()
export class CollaborationsService {
  private readonly logger = new Logger(CollaborationsService.name);

  constructor(
    private readonly collaborations: CollaborationsRepository,
    private readonly cancelRequests: CancelRequestsRepository,
    private readonly settlements: SettlementsRepository,
    private readonly refunds: RefundsService,
    private readonly payments: PaymentsService,
    private readonly payoutAccounts: PayoutAccountsService,
    private readonly ledger: LedgerService,
    private readonly offers: OffersService,
    private readonly stores: StoresService,
    private readonly creators: CreatorsService,
    private readonly brands: BrandsService,
    private readonly terms: TermsService,
    private readonly campaigns: CampaignsService,
    private readonly notifications: NotificationsService,
    private readonly jobs: JobScheduler,
    private readonly clock: Clock,
    private readonly conversations: ConversationsService,
  ) {}

  async list(
    userId: string,
    scope: CollaborationScope,
  ): Promise<CollaborationModel[]> {
    // 진행 중에는 아직 서로 관심이 아닌 브랜드 협업(INQUIRY)을 주지 않는다.
    const stage =
      scope === 'done'
        ? { in: COLLABORATION_DONE_STAGES }
        : { notIn: [...COLLABORATION_DONE_STAGES, 'INQUIRY' as const] };
    let rows = await this.collaborations.listForParty(userId, stage);
    // 결제 기한이 지난 오퍼는 읽을 때 만료한다(작업이 아직 안 돌았어도 목록이 맞게).
    if (await this.expireUnpaid(rows)) {
      rows = await this.collaborations.listForParty(userId, stage);
    }
    return this.toModels(userId, rows);
  }

  async get(userId: string, id: string): Promise<CollaborationModel> {
    const row = await this.requireParty(userId, id);
    const [model] = await this.toModels(userId, [row]);
    return model;
  }

  // 계약 전 협의를 그만둔다(당사자 누구나). 단계가 DROPPED가 되고, 브랜드가 아직 결제하지 않은 계약은 무효가 된다.
  // 방은 열어 둔다. 상대에게는 이유도 누가 그만뒀는지도 알리지 않고 "이번에는 함께하기 어렵대요."만 안내 줄과 알림으로 간다.
  // 조건을 바꾸는 쪽과 같은 협업 잠금을 쓴다: 새 판본·확인과 엇갈려도 한 줄로 선다. 브랜드 결제창이 열려 있으면(60분) 막는다.
  async drop(
    userId: string,
    id: string,
    reason: DropChoice,
  ): Promise<CollaborationModel> {
    const collaboration = await this.requireParty(userId, id);
    const cannot = new AppError('CONFLICT', '지금은 협의를 그만둘 수 없어요.');
    if (!preContractStages.includes(collaboration.stage)) throw cannot;
    const now = this.clock.now();

    const { roomId, lineId, withdrawn } = await this.collaborations.transaction(
      async (tx) => {
        await this.collaborations.lock(collaboration.id, tx);
        const fresh = await this.collaborations.findById(collaboration.id, tx);
        if (!fresh || !preContractStages.includes(fresh.stage)) throw cannot;
        if (
          await this.collaborations.hasOpenBrandPayment(
            collaboration.id,
            now,
            tx,
          )
        ) {
          throw new AppError(
            'CONFLICT',
            '브랜드가 결제를 진행하고 있어요. 잠시 뒤 다시 시도해 주세요.',
          );
        }
        const dropped = await this.collaborations.advance(
          collaboration.id,
          fresh.stage,
          'DROPPED',
          { dropReason: reason, droppedById: userId },
          tx,
        );
        if (!dropped) throw cannot;
        await this.collaborations.voidPendingContract(
          collaboration.id,
          'DROPPED',
          now,
          tx,
        );
        // 아직 받은 사람이 수락하지 않은 메시지 요청이면 요청을 거둔다(거절과 같은 DECLINED). 그러면 받은 사람의 수락·거절은
        // 기존의 "이미 답한 요청" 409로 끝나고, 끝난 협업 위에 방이 열리지 않는다. 거둔 요청은 안내 줄도 알림도 남기지 않는다.
        const pending = await this.conversations.withdrawPendingRequest(
          collaboration.id,
          tx,
        );
        if (pending.withdrawn) {
          return { roomId: pending.roomId, lineId: null, withdrawn: true };
        }
        const line = pending.roomId
          ? await this.conversations.postSystem(
              pending.roomId,
              'DROPPED',
              { droppedById: userId },
              tx,
            )
          : null;
        return {
          roomId: pending.roomId,
          lineId: line?.id ?? null,
          withdrawn: false,
        };
      },
    );

    if (lineId) await this.conversations.publishCreated(lineId);
    if (roomId) await this.conversations.publishUpdated(roomId, 'STATUS');
    if (!withdrawn) await this.notifyDropped(collaboration, userId, roomId);
    return this.get(userId, id);
  }

  // 상대에게 "이번에는 함께하기 어렵대요."를 알린다. 이름도 이유도 담지 않는다. 실패해도 그만둔 것은 유효하다(R22).
  private async notifyDropped(
    collaboration: Collaboration,
    droppedById: string,
    roomId: string | null,
  ): Promise<void> {
    const toCreator = collaboration.commissionerId === droppedById;
    try {
      await this.notifications.notify({
        userId: toCreator
          ? collaboration.creatorId
          : collaboration.commissionerId,
        role: toCreator ? 'CREATOR' : 'BRAND',
        kind: 'COLLABORATION_DROPPED',
        target: roomId
          ? { kind: 'CONVERSATION', id: roomId }
          : { kind: 'TERMS', id: collaboration.id },
        dedupeKey: `collaboration-dropped:${collaboration.id}`,
      });
    } catch (error) {
      this.logger.warn(
        `협의 그만둠 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 크리에이터가 링크를 제출하기 전(FUNDED)에 그만둔다. 수수료까지 전액 환급한다.
  async cancel(userId: string, id: string): Promise<CollaborationModel> {
    const collaboration = await this.requireParty(userId, id);
    if (collaboration.creatorId !== userId) {
      throw new AppError('FORBIDDEN', '크리에이터만 협업을 그만둘 수 있어요.');
    }
    this.assertFundedStoreOffer(
      collaboration,
      this.cannotCancel(collaboration),
    );
    await this.cancelFunded(collaboration, null);
    return this.get(userId, id);
  }

  // 사장님은 혼자 취소할 수 없다(크리에이터가 이미 방문했을 수 있어서). 취소를 요청하고, 3일 안에 답이 없으면 사라진다.
  async requestCancel(userId: string, id: string): Promise<CollaborationModel> {
    const collaboration = await this.requireParty(userId, id);
    if (collaboration.commissionerId !== userId) {
      throw new AppError('FORBIDDEN', '맡긴 쪽만 취소를 요청할 수 있어요.');
    }
    this.assertFundedStoreOffer(
      collaboration,
      new AppError('CONFLICT', '지금은 취소를 요청할 수 없는 협업이에요.'),
    );
    const now = this.clock.now();
    const expiresAt = new Date(now.getTime() + CANCEL_REQUEST_DAYS * DAY_MS);

    const created = await this.cancelRequests.transaction<
      CancelRequest,
      'not-funded' | 'already-requested'
    >(async (tx, rollback) => {
      await this.cancelRequests.lockCollaboration(collaboration.id, tx);
      const current = await this.collaborations.findById(collaboration.id, tx);
      if (current?.stage !== 'FUNDED') return rollback('not-funded');
      await this.cancelRequests.expireStale(collaboration.id, now, tx);
      if (await this.cancelRequests.findPending(collaboration.id, now, tx)) {
        return rollback('already-requested');
      }
      return this.cancelRequests.create(
        {
          collaborationId: collaboration.id,
          requestedById: userId,
          expiresAt,
        },
        tx,
      );
    });
    if (created === 'not-funded') {
      throw new AppError(
        'CONFLICT',
        '지금은 취소를 요청할 수 없는 협업이에요.',
      );
    }
    if (created === 'already-requested') {
      throw new AppError('CONFLICT', '이미 보낸 취소 요청이 있어요.');
    }

    await this.scheduleExpiry(created);
    await this.notifyCancelRequested(collaboration, created);
    return this.get(userId, id);
  }

  // 크리에이터가 사장님의 취소 요청에 동의한다. 직접 그만두는 것과 같은 처리이고, 요청은 같은 트랜잭션에서 ACCEPTED가 된다.
  async acceptCancel(
    userId: string,
    id: string,
    requestId: string,
  ): Promise<CollaborationModel> {
    const collaboration = await this.requireParty(userId, id);
    if (collaboration.creatorId !== userId) {
      throw new AppError(
        'FORBIDDEN',
        '크리에이터만 취소 요청에 동의할 수 있어요.',
      );
    }
    const request = UUID.test(requestId)
      ? await this.cancelRequests.findById(requestId)
      : null;
    if (!request || request.collaborationId !== collaboration.id) {
      throw new AppError('NOT_FOUND', '취소 요청을 찾을 수 없어요.');
    }
    this.assertFundedStoreOffer(
      collaboration,
      this.cannotCancel(collaboration),
    );
    await this.cancelFunded(collaboration, request.id);
    return this.get(userId, id);
  }

  // cancel-request-expiry 작업: 아직 답이 없는 요청만 EXPIRED로 바꾼다. 동의한 요청과 이미 만료된 요청은 그대로다.
  async expireCancelRequest(requestId: string): Promise<void> {
    await this.cancelRequests.expire(requestId);
  }

  // cancel-refund 작업: 취소로 만든 환급 행을 PG로 보낸다. 행이 없거나(식사권만 있음) 이미 DONE이면 아무 일도 하지 않는다.
  // 오류는 던져 큐가 다시 시도하게 하고, 운영자 경보는 마지막 시도에서만 RefundsService가 낸다.
  async retryCancelRefund(
    collaborationId: string,
    context?: JobRunContext,
  ): Promise<void> {
    const refund = await this.refunds.findByKey(
      cancelRefundKey(collaborationId),
    );
    if (refund) await this.refunds.execute(refund.id, context);
  }

  // FUNDED → CANCELLED. 단계, 장부(수수료까지 전액 환급), 환급 행, (동의라면) 요청의 ACCEPTED가 한 트랜잭션이다.
  // 커밋 뒤에 PG 환급, 제출 기한 작업 취소, 사장님 알림을 한다. 이미 저장된 취소는 그 단계가 실패해도 유효하다(원장 판단 R22).
  private async cancelFunded(
    collaboration: Collaboration,
    requestId: string | null,
  ): Promise<void> {
    const key = `cancel:${collaboration.id}`;
    const refundKey = cancelRefundKey(collaboration.id);
    // 식사권만 있는 오퍼는 낸 돈이 없다. 돈이 있는 협업의 결제를 못 찾으면 상태가 어긋난 것이라 던진다.
    let amounts: { escrow: number; fee: number } | null = null;
    if (collaboration.settlementMethod !== 'NONE') {
      amounts =
        (await this.payments.fundedAmounts([collaboration.id])).get(
          collaboration.id,
        ) ?? null;
      if (!amounts) {
        throw new Error('보관 중인 협업의 결제를 찾을 수 없어요.');
      }
    }
    const now = this.clock.now();

    const outcome = await this.cancelRequests.transaction<
      'cancelled',
      Exclude<CancelOutcome, 'cancelled'>
    >(async (tx, rollback) => {
      // 같은 협업의 취소·요청·동의를 한 줄로 세운다.
      await this.cancelRequests.lockCollaboration(collaboration.id, tx);
      if (
        requestId &&
        !(await this.cancelRequests.accept(
          requestId,
          collaboration.id,
          now,
          tx,
        ))
      ) {
        return rollback('request-closed');
      }
      if (
        !(await this.collaborations.advance(
          collaboration.id,
          'FUNDED',
          'CANCELLED',
          {},
          tx,
        ))
      ) {
        return rollback('not-funded');
      }
      if (amounts) {
        const posted = await this.ledger.post(
          collaboration.id,
          postingsForFullRefund(amounts),
          key,
          tx,
        );
        if (posted === 'duplicate') {
          // FUNDED인데 취소 장부가 이미 있다면 상태가 어긋난 것이다. 조용히 넘기지 않고 되돌려 드러낸다.
          throw new Error('보관 중인 협업에 취소 장부 줄이 이미 있어요.');
        }
        await this.refunds.request(
          collaboration.id,
          amounts.escrow + amounts.fee,
          refundKey,
          tx,
        );
      }
      return 'cancelled';
    });
    if (outcome === 'not-funded') throw this.cannotCancel(collaboration);
    if (outcome === 'request-closed') {
      throw new AppError('CONFLICT', '이미 끝난 취소 요청이에요.');
    }

    const refunded = amounts ? amounts.escrow + amounts.fee : 0;
    if (amounts) await this.refundAfterCommit(collaboration.id);
    await this.cancelDeadlineJobs(collaboration.id);
    await this.notifyCancelled(collaboration, refunded);
  }

  // 커밋 뒤의 PG 환급. 재시도 작업을 먼저 올려 두고 한 번 바로 시도한다(빠른 길).
  // 바로 시도가 실패해도 취소는 이미 커밋됐다: 작업이 큐의 규칙대로 다시 시도하고, 운영자 경보는 마지막 시도에서만 나간다.
  // 작업을 올리지 못했다면 이 시도가 마지막이라 실패 경보가 바로 나간다. 바로 성공하면 작업은 지운다.
  private async refundAfterCommit(collaborationId: string): Promise<void> {
    const key = cancelRefundKey(collaborationId);
    let scheduled = false;
    try {
      await this.jobs.schedule(
        'cancel-refund',
        { collaborationId },
        this.clock.now(),
        key,
      );
      scheduled = true;
    } catch (error) {
      this.logger.warn(
        `취소 환급 재시도 작업을 올리지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
    try {
      const refund = await this.refunds.findByKey(key);
      if (refund) {
        await this.refunds.execute(refund.id, { finalAttempt: !scheduled });
      }
    } catch (error) {
      this.logger.error(
        `취소 환급을 바로 보내지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
      return;
    }
    if (!scheduled) return;
    try {
      await this.jobs.cancel(key);
    } catch (error) {
      // 남아도 무해하다: 작업은 이미 DONE인 환급 행을 보고 아무 일도 하지 않는다.
      this.logger.warn(
        `취소 환급 재시도 작업을 지우지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 취소했으니 미제출 환급과 기한 알림은 필요 없다. 지우지 못해도 처리기가 단계를 보고 아무 일도 하지 않는다.
  private async cancelDeadlineJobs(collaborationId: string): Promise<void> {
    for (const key of submissionDeadlineJobKeys(collaborationId)) {
      try {
        await this.jobs.cancel(key);
      } catch (error) {
        this.logger.warn(
          `제출 기한 작업을 지우지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
  }

  private async scheduleExpiry(request: CancelRequest): Promise<void> {
    try {
      await this.jobs.schedule(
        'cancel-request-expiry',
        { cancelRequestId: request.id },
        request.expiresAt,
        cancelRequestJobKey(request.id),
      );
    } catch (error) {
      // 만료는 읽을 때도 시각으로 가려지므로(요청은 시각이 지나면 보이지도 동의할 수도 없다) 작업은 정리용이다.
      this.logger.warn(
        `취소 요청 만료 작업을 올리지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  private async notifyCancelled(
    collaboration: Collaboration,
    amount: number,
  ): Promise<void> {
    try {
      let actor: Awaited<ReturnType<CreatorsService['getActor']>> = null;
      try {
        actor = await this.creators.getActor(collaboration.creatorId);
      } catch {
        actor = null;
      }
      await this.notifications.notify({
        userId: collaboration.commissionerId,
        role: 'STORE',
        kind: 'CREATOR_CANCELLED',
        actor: actor ?? {
          userId: collaboration.creatorId,
          name: '크리에이터',
          photoPath: null,
        },
        params: { amount },
        target: { kind: 'COLLABORATION', id: collaboration.id },
        dedupeKey: `cancelled:${collaboration.id}`,
      });
    } catch (error) {
      this.logger.warn(
        `협업 그만둠 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  private async notifyCancelRequested(
    collaboration: Collaboration,
    request: CancelRequest,
  ): Promise<void> {
    try {
      const card = await this.storeCard(collaboration.storeId);
      await this.notifications.notify({
        userId: collaboration.creatorId,
        role: 'CREATOR',
        kind: 'CANCEL_REQUESTED',
        actor: {
          userId: collaboration.commissionerId,
          name: card?.summary.name ?? '가게',
          photoPath: card?.coverPhotoPath ?? null,
        },
        target: { kind: 'COLLABORATION', id: collaboration.id },
        dedupeKey: `cancel-requested:${request.id}`,
      });
    } catch (error) {
      this.logger.warn(
        `취소 요청 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 당사자가 아니면 없는 협업과 같게 404다. 당사자인지 먼저 보고, 그 뒤에야 읽을 때 만료를 한다
  // (당사자가 아닌 사람의 읽기가 오퍼나 협업을 바꾸지 않게).
  private async requireParty(
    userId: string,
    id: string,
  ): Promise<Collaboration> {
    let row = UUID.test(id) ? await this.collaborations.findById(id) : null;
    if (!row || (row.commissionerId !== userId && row.creatorId !== userId)) {
      throw new AppError('NOT_FOUND', '협업을 찾을 수 없어요.');
    }
    if (row.stage === 'AWAITING_PAYMENT' && (await this.expireUnpaid([row]))) {
      row = (await this.collaborations.findById(id)) ?? row;
    }
    return row;
  }

  // 단계가 FUNDED인 가게 오퍼만 그만두거나 취소를 요청할 수 있다. 링크를 제출한 뒤(COUNTING부터)는 안 된다.
  private assertFundedStoreOffer(
    collaboration: Collaboration,
    error: AppError,
  ): void {
    if (
      collaboration.kind !== 'STORE_OFFER' ||
      collaboration.stage !== 'FUNDED'
    ) {
      throw error;
    }
  }

  // 링크를 제출한 협업(집계 중이거나, 집계 중에 멈춘 협업)에는 그 사정을 알려 준다.
  // 제출 전(FUNDED)에 멈춘 협업에는 제출 이야기를 하지 않는다.
  private cannotCancel(collaboration: Collaboration): AppError {
    const submitted =
      collaboration.stage === 'COUNTING' ||
      (collaboration.stage === 'HALTED' &&
        (collaboration.submittedAt !== null ||
          collaboration.stageBeforeHalt === 'COUNTING'));
    return new AppError(
      'CONFLICT',
      submitted
        ? '링크를 제출한 뒤에는 협업을 그만둘 수 없어요.'
        : '지금은 협업을 그만둘 수 없어요.',
    );
  }

  // 결제 기한이 지난 오퍼를 만료로 저장한다(오퍼의 읽을 때 만료와 같은 길). 하나라도 시도했으면 true.
  private async expireUnpaid(rows: Collaboration[]): Promise<boolean> {
    const waiting = rows.filter(
      (row) => row.stage === 'AWAITING_PAYMENT' && row.offerId,
    );
    for (const row of waiting) await this.offers.expireUnpaid(row.offerId!);
    return waiting.length > 0;
  }

  private async toModels(
    userId: string,
    rows: Collaboration[],
  ): Promise<CollaborationModel[]> {
    if (rows.length === 0) return [];
    const ids = rows.map((row) => row.id);
    const now = this.clock.now();
    const [funded, views, settlements, payouts, pending] = await Promise.all([
      this.payments.fundedAmounts(ids),
      this.settlements.latestViewsFor(ids),
      this.settlements.settlementsFor(ids),
      this.settlements.latestPayoutsFor(ids),
      this.cancelRequests.mapPendingFor(ids, now),
    ]);
    const brandContext = await this.brandContext(userId, rows);
    const [conversationIds, contractProgress, concludedTerms] =
      await Promise.all([
        this.collaborations.mapConversationIds(ids),
        this.collaborations.mapContractProgress(ids),
        this.concludedTermsOf(rows),
      ]);
    const context: Context = {
      ...brandContext,
      conversationIds,
      contractProgress,
      concludedTerms,
      now,
      funded,
      views,
      settlements,
      payouts,
      pending,
      stores: new Map(),
      creators: new Map(),
      brands: new Map(),
      accounts: new Map(),
    };
    const models: CollaborationModel[] = [];
    for (const row of rows)
      models.push(await this.toModel(userId, row, context));
    return models;
  }

  private async toModel(
    userId: string,
    row: Collaboration,
    c: Context,
  ): Promise<CollaborationModel> {
    const role = row.creatorId === userId ? 'CREATOR' : 'COMMISSIONER';
    // 브랜드 계약의 조건은 협업 행이 아니라 조건 판본에 있다(행의 terms 열은 비어 있다). readTerms를 부르기 전에 가른다.
    if (row.kind === 'BRAND_CONTRACT') return this.toBrandModel(row, role, c);
    const terms = readTerms(row.terms);
    const settlement = c.settlements.get(row.id) ?? null;
    // 확인 전의 계산은 "정산"으로 보이지 않게 한다(돈은 아직 보관 중이다).
    const confirmed = settlement?.status === 'CONFIRMED' ? settlement : null;
    const payout = c.payouts.get(row.id) ?? null;
    const escrowAmount = c.funded.get(row.id)?.escrow ?? 0;
    const currentViews = c.views.get(row.id) ?? null;
    const live = liveAmounts({
      stage: row.stage,
      views: currentViews,
      terms,
    });

    const payoutView = await this.payoutViewOf(row, role, payout, c);

    const card = row.storeId
      ? await this.storeCardCached(row.storeId, c)
      : null;
    const counterpart =
      role === 'CREATOR'
        ? {
            name: card?.summary.name ?? '가게',
            photoUrl: card?.summary.coverPhotoUrl ?? null,
          }
        : await this.creatorCounterpart(row.creatorId, c);

    const pendingRequest =
      row.stage === 'FUNDED' ? c.pending.get(row.id) : null;
    const funded = row.kind === 'STORE_OFFER' && row.stage === 'FUNDED';
    return {
      id: row.id,
      kind: row.kind,
      stage: row.stage,
      role,
      counterpart,
      store: card?.summary ?? null,
      terms,
      steps: buildSteps({
        kind: row.kind,
        stage: row.stage,
        stageBeforeHalt: row.stageBeforeHalt,
        settlementMethod: row.settlementMethod,
        acceptedAt: row.createdAt,
        fundedAt: row.fundedAt,
        submittedAt: row.submittedAt,
        settledAt: confirmed?.settledAt ?? null,
      }).map((step) => ({
        key: step.key,
        state: step.state,
        at: step.at?.toISOString() ?? null,
      })),
      campaign: null,
      title: null,
      brandProgress: null,
      securedAmount: null,
      campaignBudgetLeft: null,
      nextAction: null,
      escrowAmount,
      submitDueAt: row.submitDueAt?.toISOString() ?? null,
      submittedUrl: row.submittedUrl,
      countingEndsAt: row.countingEndsAt?.toISOString() ?? null,
      currentViews,
      earnedSoFar: role === 'CREATOR' ? (live?.earned ?? null) : null,
      expectedRefund: role === 'COMMISSIONER' ? (live?.refund ?? null) : null,
      settlement: confirmed
        ? {
            finalViews: confirmed.finalViews,
            payoutAmount: confirmed.payoutAmount,
            refundAmount: confirmed.refundAmount,
          }
        : null,
      viewReportStatus: viewReportStatusOf({
        stage: row.stage,
        submitted: row.submittedUrl !== null,
        hasViewPay: hasViewPay(terms),
        settlementStatus: settlement?.status ?? null,
      }),
      payoutStatus: payoutView.status,
      payoutScheduledFor: payoutView.scheduledFor?.toISOString() ?? null,
      cancelRequest: pendingRequest
        ? {
            id: pendingRequest.id,
            requestedByMe: pendingRequest.requestedById === userId,
            expiresAt: pendingRequest.expiresAt.toISOString(),
          }
        : null,
      canCancel: funded && role === 'CREATOR',
      canRequestCancel: funded && role === 'COMMISSIONER' && !pendingRequest,
      conversationId: c.conversationIds.get(row.id) ?? null,
      contractStatus: c.contractProgress.get(row.id) ?? 'NONE',
      extraRevisionsAllowed: row.extraRevisionsAllowed,
    };
  }

  // 지급 계좌 사정(NEEDS_ACCOUNT, 지급일)은 크리에이터에게만 보인다. 사장님(브랜드)에게는 그냥 지급 대기다.
  private async payoutViewOf(
    row: Collaboration,
    role: CollaborationModel['role'],
    payout: Parameters<typeof payoutStatusOf>[0],
    c: Context,
  ): Promise<ReturnType<typeof payoutStatusOf>> {
    let payoutView = payoutStatusOf(payout, true);
    if (role === 'CREATOR') {
      if (payout?.status === 'PENDING') {
        payoutView = payoutStatusOf(payout, await this.hasAccount(row, c));
      }
    } else {
      payoutView = { ...payoutView, scheduledFor: null };
    }
    return payoutView;
  }

  // 브랜드 계약. 정산 칸(지급·정산 결과·조회 자료 확인 단계·집계 중 금액)은 체결된 계약의 조건 사본과 정산 행에서 채운다.
  // 취소 칸은 브랜드 계약에 없어 비어 있다. 단계 막대는 가게 오퍼의 다섯 칸이 아니라 brandProgress 여섯 단계가 맡아서 steps는 비어 있다.
  private async toBrandModel(
    row: Collaboration,
    role: CollaborationModel['role'],
    c: Context,
  ): Promise<CollaborationModel> {
    const isCreator = role === 'CREATOR';
    const counterpart = isCreator
      ? await this.brandCounterpart(row.commissionerId, c)
      : await this.creatorCounterpart(row.creatorId, c);
    const found = row.campaignId ? c.campaigns.get(row.campaignId) : undefined;
    const latest = c.latestTerms.get(row.id) ?? null;
    // 멈춘 협업은 멈추기 전 단계로 읽는다(멈춘 이유는 별개의 이야기다).
    const readStage = row.stage === 'HALTED' ? row.stageBeforeHalt : row.stage;
    const progress = readStage ? brandProgress(readStage) : null;
    // 정산 값: 가게 오퍼와 같은 규칙이다(확인 전의 계산은 정산으로 보이지 않고, 지급 계좌 사정은 크리에이터에게만 보인다).
    const concluded = c.concludedTerms.get(row.id) ?? null;
    const settlement = c.settlements.get(row.id) ?? null;
    const confirmed = settlement?.status === 'CONFIRMED' ? settlement : null;
    const payoutView = await this.payoutViewOf(
      row,
      role,
      c.payouts.get(row.id) ?? null,
      c,
    );
    const currentViews = c.views.get(row.id) ?? null;
    const live = concluded
      ? liveAmounts({
          kind: row.kind,
          stage: row.stage,
          views: currentViews,
          terms: {
            fixedCash: concluded.fee,
            viewRatePerThousand: concluded.performance?.ratePer1000 ?? null,
            perViewCap: concluded.performance?.cap ?? null,
          },
        })
      : null;
    return {
      id: row.id,
      kind: row.kind,
      stage: row.stage,
      role,
      counterpart,
      store: null,
      terms: null,
      steps: [],
      campaign: found
        ? {
            id: found.campaign.id,
            headline: found.campaign.headline,
            brandName: found.brand.name,
          }
        : null,
      title: latest?.title ?? null,
      brandProgress: progress,
      securedAmount: latest ? termsMaxCash(latest) : null,
      // 남은 예산은 그 캠페인의 브랜드에게만 내려 준다. 크리에이터의 응답에는 예산이 어떤 모양으로도 없다.
      campaignBudgetLeft:
        !isCreator && found && row.campaignId
          ? budgetLeft(
              found.campaign.budget,
              c.securedByCampaign.get(row.campaignId) ?? [],
            )
          : null,
      nextAction: nextActionFor(
        row.stage,
        latest ? isMyTurn(latest, isCreator) : false,
      ),
      escrowAmount: 0,
      submitDueAt: row.submitDueAt?.toISOString() ?? null,
      submittedUrl: row.submittedUrl,
      countingEndsAt: row.countingEndsAt?.toISOString() ?? null,
      currentViews: concluded?.performance ? currentViews : null,
      earnedSoFar: isCreator ? (live?.earned ?? null) : null,
      expectedRefund: !isCreator ? (live?.refund ?? null) : null,
      settlement: confirmed
        ? {
            finalViews: confirmed.finalViews,
            payoutAmount: confirmed.payoutAmount,
            refundAmount: confirmed.refundAmount,
          }
        : null,
      viewReportStatus: viewReportStatusOf({
        kind: row.kind,
        stage: row.stage,
        submitted: row.submittedUrl !== null,
        hasViewPay: !!concluded?.performance,
        settlementStatus: settlement?.status ?? null,
      }),
      payoutStatus: payoutView.status,
      payoutScheduledFor: payoutView.scheduledFor?.toISOString() ?? null,
      cancelRequest: null,
      canCancel: false,
      canRequestCancel: false,
      conversationId: c.conversationIds.get(row.id) ?? null,
      contractStatus: c.contractProgress.get(row.id) ?? 'NONE',
      extraRevisionsAllowed: row.extraRevisionsAllowed,
    };
  }

  // 체결된 브랜드 계약의 조건 사본을 한 번에 읽는다. 읽을 수 없는 사본(옛 모양, 값이 맞지 않음)은 그 협업의 정산 칸만 비우고 목록 전체는 막지 않는다.
  private async concludedTermsOf(
    rows: Collaboration[],
  ): Promise<Map<string, ReturnType<typeof readSnapshot>>> {
    const ids = rows
      .filter((r) => r.kind === 'BRAND_CONTRACT')
      .map((r) => r.id);
    const raw = await this.collaborations.mapConcludedSnapshots(ids);
    const parsed = new Map<string, ReturnType<typeof readSnapshot>>();
    for (const [id, json] of raw) {
      try {
        parsed.set(id, readSnapshot(json));
      } catch (error) {
        this.logger.warn(
          `협업의 계약 조건 사본을 읽지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
    return parsed;
  }

  // 브랜드 계약 칸의 재료를 목록 전체에 대해 한 번에 읽는다: 캠페인, 최신 판본, 그리고 보는 사람이 브랜드인 캠페인의 확보액들.
  // 쿼리 수는 행 수와 상관없이 일정하다(캠페인 한 번, 확보 대상 협업 한 번, 판본 한 번).
  private async brandContext(
    userId: string,
    rows: Collaboration[],
  ): Promise<Pick<Context, 'campaigns' | 'latestTerms' | 'securedByCampaign'>> {
    const brandRows = rows.filter((row) => row.kind === 'BRAND_CONTRACT');
    const unique = (ids: (string | null)[]) => [
      ...new Set(ids.filter((id): id is string => id !== null)),
    ];
    const campaignIds = unique(brandRows.map((row) => row.campaignId));
    const myCampaignIds = unique(
      brandRows
        .filter((row) => row.commissionerId === userId)
        .map((row) => row.campaignId),
    );
    const [campaigns, secured] = await Promise.all([
      campaignIds.length > 0
        ? this.campaigns.listWithBrand(campaignIds)
        : Promise.resolve([]),
      this.collaborations.listSecuredBrandContracts(myCampaignIds),
    ]);
    const latestTerms = await this.terms.latestMany(
      unique([...brandRows.map((row) => row.id), ...secured.map((r) => r.id)]),
    );
    const securedByCampaign = new Map<string, number[]>();
    for (const { id, campaignId } of secured) {
      const latest = latestTerms.get(id);
      if (!latest) continue;
      const list = securedByCampaign.get(campaignId) ?? [];
      list.push(termsMaxCash(latest));
      securedByCampaign.set(campaignId, list);
    }
    return {
      campaigns: new Map(campaigns.map((entry) => [entry.campaign.id, entry])),
      latestTerms,
      securedByCampaign,
    };
  }

  private async brandCounterpart(brandUserId: string, c: Context) {
    if (!c.brands.has(brandUserId)) {
      c.brands.set(brandUserId, await this.brands.findProfiles([brandUserId]));
    }
    const profile = c.brands.get(brandUserId)?.get(brandUserId);
    return {
      name: profile?.name ?? '브랜드',
      photoUrl: profile?.photoUrl ?? null,
    };
  }

  private async hasAccount(row: Collaboration, c: Context): Promise<boolean> {
    let has = c.accounts.get(row.creatorId);
    if (has === undefined) {
      has = await this.payoutAccounts.hasAccount(row.creatorId);
      c.accounts.set(row.creatorId, has);
    }
    return has;
  }

  private async storeCardCached(storeId: string, c: Context) {
    if (!c.stores.has(storeId)) {
      c.stores.set(storeId, await this.storeCard(storeId));
    }
    return c.stores.get(storeId) ?? null;
  }

  // 비공개로 바뀐 가게 같은 읽을 수 없는 경우는 카드 없이 간다(목록 전체가 500이 되지 않게).
  private async storeCard(storeId: string | null) {
    if (!storeId) return null;
    try {
      return await this.stores.getOfferCard(storeId);
    } catch (error) {
      this.logger.warn(
        `협업의 가게를 읽지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
      return null;
    }
  }

  private async creatorCounterpart(creatorId: string, c: Context) {
    if (!c.creators.has(creatorId)) {
      c.creators.set(creatorId, await this.creators.getSummary(creatorId));
    }
    const summary = c.creators.get(creatorId);
    return {
      name: summary?.displayName ?? '크리에이터',
      photoUrl: summary?.photoUrl ?? null,
    };
  }
}
