import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Collaboration, Payment, PaymentMethod } from '@prisma/client';
import { scheduleSubmissionDeadlineJobs } from '../collaborations/collaboration-jobs';
import { SUBMIT_DUE_DAYS } from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { PaymentPort } from '../integrations/payment/payment.port';
import { JobScheduler } from '../jobs/job-scheduler';
import { postingsForPaymentApproved } from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OffersService } from '../offers/offers.service';
import { feeFor } from '../settlements/settlement-math';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { PaymentCreatedModel } from './dto/payment-created.model';
import { PaymentQuoteModel } from './dto/payment-quote.model';
import { PaymentStatusModel } from './dto/payment-status.model';
import { PaymentsRepository } from './payments.repository';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MINUTE_MS = 60 * 1000;
const DAY_MS = 24 * 60 * MINUTE_MS;

// 결제창을 닫았거나 통지가 늦는 경우를 위해, 10분마다 최대 6번 PG에 직접 묻는다.
export const RECHECK_INTERVAL_MINUTES = 10;
export const RECHECK_MAX_ATTEMPTS = 6;

// 협업이 이미 끝났거나(만료·취소), 같은 협업의 다른 결제가 이미 보관을 시작해서 이 승인을 반영하지 못한 경우 모두.
export const LATE_APPROVAL_SUBJECT =
  '협업에 반영하지 못한 결제가 승인됐어요. 운영 명령으로 환불해 주세요.';
export const UNEXPECTED_APPROVAL_SUBJECT =
  '실패로 기록된 결제에 승인 통지가 왔어요. PG에서 확인하고 환불해 주세요.';

// PG가 알려 준 결제 결과. 직접 조회(fetchStatus)로 얻은 결과는 거래 번호가 없을 수 있다.
export interface PaymentResult {
  paymentId: string;
  pgTransactionId: string | null;
  status: 'APPROVED' | 'FAILED';
}

export interface ApplyResultOptions {
  // 요청을 받는 길(웹훅, 개발용 경로)은 이미 저장된 결제를 알림 때문에 오류로 돌려주지 않는다(원장 판단 R22).
  // 작업 처리기는 던져서 큐가 다시 시도하게 한다(기본).
  swallowNotifyErrors?: boolean;
}

type ApprovalOutcome = 'funded' | 'not-awaiting-payment' | 'already-handled';

const recheckJobKey = (paymentId: string, attempt: number) =>
  `payment-recheck:${paymentId}:${attempt}`;

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly payments: PaymentsRepository,
    private readonly collaborations: CollaborationsRepository,
    private readonly offers: OffersService,
    private readonly ledger: LedgerService,
    private readonly notifications: NotificationsService,
    private readonly jobs: JobScheduler,
    private readonly users: UsersService,
    private readonly stores: StoresService,
    private readonly creators: CreatorsService,
    private readonly paymentPort: PaymentPort,
    private readonly operatorAlert: OperatorAlertPort,
    private readonly config: ConfigService,
    private readonly clock: Clock,
  ) {}

  async getQuote(
    userId: string,
    collaborationId: string,
  ): Promise<PaymentQuoteModel> {
    const collaboration = await this.requirePayable(userId, collaborationId);
    return this.quoteOf(collaboration);
  }

  async create(
    userId: string,
    collaborationId: string,
    method: PaymentMethod,
  ): Promise<PaymentCreatedModel> {
    const collaboration = await this.requirePayable(userId, collaborationId);
    const quote = await this.quoteOf(collaboration);
    const now = this.clock.now();
    // 오퍼 행을 먼저 잠그고(승인과 같은 오퍼 → 결제 순서) 오퍼와 협업이 아직 결제를 기다리는지 다시 본다:
    // 위의 확인과 쓰기 사이에 취소·만료·승인이 끼어들거나, 같은 협업에 동시에 만드는 요청이 대기 결제를 둘 만들지 못하게.
    const created = await this.payments.transaction<Payment, 'not-payable'>(
      async (tx, rollback) => {
        if (
          collaboration.offerId &&
          !(await this.offers.lockAcceptedForPayment(collaboration.offerId, tx))
        ) {
          return rollback('not-payable');
        }
        const current = await this.collaborations.findById(collaborationId, tx);
        if (current?.stage !== 'AWAITING_PAYMENT') {
          return rollback('not-payable');
        }
        return this.payments.replacePending(
          {
            collaborationId,
            amountEscrow: quote.escrow,
            amountFee: quote.fee,
            feeRate: quote.feeRate,
            method,
            requestedAt: now,
          },
          tx,
        );
      },
    );
    if (created === 'not-payable') throw this.notPayable();
    const payment = created;
    const { checkoutUrl } = await this.paymentPort.createCheckout({
      paymentId: payment.id,
      amount: quote.total,
      method,
      orderName: quote.orderName,
    });
    // 재확인은 웹훅을 놓칠 때를 위한 안전망이다. 올리지 못해도 결제는 웹훅으로 완료된다.
    try {
      await this.scheduleRecheck(payment.id, 1, now);
    } catch (error) {
      this.logger.warn(
        `결제 재확인 작업을 올리지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
    return { paymentId: payment.id, checkoutUrl };
  }

  // 환급이 PG에 돌려보낼 결제. 정산·미제출 환급 같은 돈 처리가 쓴다(결제한 사람의 권한 확인 없음 — 서버 안의 호출 전용).
  async findFundingPayment(collaborationId: string): Promise<{
    id: string;
    pgTransactionId: string;
    amountEscrow: number;
    amountFee: number;
  } | null> {
    const payment = await this.payments.findFundingPayment(collaborationId);
    if (!payment?.pgTransactionId) return null;
    return {
      id: payment.id,
      pgTransactionId: payment.pgTransactionId,
      amountEscrow: payment.amountEscrow,
      amountFee: payment.amountFee,
    };
  }

  // 협업 여러 개가 보관을 시작할 때 낸 금액(에스크로와 수수료). 결제가 없는 협업은 맵에 없다.
  // 협업 조회 화면이 쓴다(서버 안의 호출 전용).
  async fundedAmounts(
    collaborationIds: string[],
  ): Promise<Map<string, { escrow: number; fee: number }>> {
    const rows = await this.payments.mapFundingPayments(collaborationIds);
    return new Map(
      [...rows].map(([id, payment]) => [
        id,
        { escrow: payment.amountEscrow, fee: payment.amountFee },
      ]),
    );
  }

  async getStatus(
    userId: string,
    paymentId: string,
  ): Promise<PaymentStatusModel> {
    const payment = await this.requireOwnedPayment(userId, paymentId);
    return { status: payment.status };
  }

  // 그 협업을 맡긴 사장님의 결제만 돌려준다. 남의 결제는 없는 결제와 같게 404.
  async requireOwnedPayment(
    userId: string,
    paymentId: string,
  ): Promise<Payment> {
    await this.assertStoreRole(userId);
    const payment = UUID.test(paymentId)
      ? await this.payments.findById(paymentId)
      : null;
    const collaboration = payment
      ? await this.collaborations.findById(payment.collaborationId)
      : null;
    if (!payment || collaboration?.commissionerId !== userId) {
      throw this.paymentNotFound();
    }
    return payment;
  }

  // PG의 통지(웹훅), 직접 조회(재확인), 개발용 가짜 결제창이 모두 지나는 하나의 길이다.
  // 같은 결과가 여러 번 와도 장부와 단계는 한 번만 바뀐다. 다만 이미 승인된 결제에 같은 통지가 또 오면
  // 커밋 뒤의 후속 단계(작업 등록·알림)를 다시 시도한다: 커밋과 알림 사이에 죽었어도 재시도가 고친다.
  async applyResult(
    result: PaymentResult,
    options: ApplyResultOptions = {},
  ): Promise<void> {
    const payment = UUID.test(result.paymentId)
      ? await this.payments.findById(result.paymentId)
      : null;
    if (!payment) {
      this.logger.warn('모르는 결제의 통지를 받았어요.');
      return;
    }
    if (result.status === 'FAILED') {
      await this.payments.markFailed(payment.id);
      return;
    }
    // 대기 중이거나 새 결제에 밀려 취소된 결제는 승인 트랜잭션을 탄다. 이미 승인됐거나 실패한 결제만 따로 본다.
    if (payment.status === 'APPROVED' || payment.status === 'FAILED') {
      await this.reactToSettledPayment(payment, options);
      return;
    }
    if (!result.pgTransactionId) {
      throw new Error('PG가 승인했는데 거래 번호가 없어요.');
    }
    await this.approve(payment, result.pgTransactionId, options);
  }

  // 작업 큐가 결제를 만든 10분 뒤부터 부른다. 아직 대기 중이면 PG에 직접 묻는다.
  // 개발 서버를 다시 띄우면 가짜 PG의 기록이 사라져 PENDING으로 돌아오는데, 이것은 "아직 모름"이지 실패가 아니다.
  async recheck(paymentId: string, attempt: number): Promise<void> {
    const payment = UUID.test(paymentId)
      ? await this.payments.findById(paymentId)
      : null;
    if (!payment) return;
    // 이미 승인됐다: 앞선 실행이 승인을 커밋한 뒤 남은 단계(작업 등록·알림)에서 던졌을 수 있다. 같은 통지가 또 온 것처럼
    // 다시 태워 남은 단계를 마친다(같은 키라 이미 된 일은 그대로다).
    if (payment.status === 'APPROVED') {
      await this.applyResult({
        paymentId: payment.id,
        pgTransactionId: payment.pgTransactionId,
        status: 'APPROVED',
      });
      return;
    }
    if (payment.status !== 'PENDING') return;
    const found = await this.paymentPort.fetchStatus(payment.id);
    if (found.status === 'PENDING') {
      if (attempt < RECHECK_MAX_ATTEMPTS) {
        await this.scheduleRecheck(payment.id, attempt + 1, this.clock.now());
      } else {
        this.logger.warn(
          `결제 재확인을 ${RECHECK_MAX_ATTEMPTS}번 했지만 아직 대기 중이라 멈춰요.`,
        );
      }
      return;
    }
    await this.applyResult({
      paymentId: payment.id,
      pgTransactionId: found.pgTransactionId,
      status: found.status,
    });
  }

  private async approve(
    payment: Payment,
    pgTransactionId: string,
    options: ApplyResultOptions,
  ): Promise<void> {
    const collaboration = await this.collaborations.findById(
      payment.collaborationId,
    );
    if (!collaboration) {
      this.logger.warn('결제의 협업을 찾을 수 없어요.');
      return;
    }
    const now = this.clock.now();
    // 잠그는 순서: 오퍼 → 결제 → 협업. 오퍼의 취소·만료가 오퍼 → 협업 순이라 같은 순서를 지켜 교착(40P01)을 피한다.
    // 협업 단계를 장부보다 먼저 옮긴다: 결제할 수 없는 협업이면 장부에 손도 대지 않고 앞 단계까지 되돌린다.
    // 어느 단계든 실패하면 전부 되돌린다(결제만 승인되고 장부가 없는 상태가 남지 않게).
    const outcome = await this.payments.transaction<
      'funded',
      Exclude<ApprovalOutcome, 'funded'>
    >(async (tx, rollback) => {
      if (
        collaboration.offerId &&
        !(await this.offers.clearPaymentDue(collaboration.offerId, tx))
      ) {
        // 오퍼가 이미 만료·취소됐다.
        return rollback('not-awaiting-payment');
      }
      if (
        !(await this.payments.markApproved(
          payment.id,
          pgTransactionId,
          now,
          tx,
        ))
      ) {
        // 같은 통지를 동시에 처리한 쪽이 먼저 바꿨거나, 그사이 결제가 취소됐다.
        return rollback('already-handled');
      }
      if (
        !(await this.collaborations.advance(
          collaboration.id,
          'AWAITING_PAYMENT',
          'FUNDED',
          {
            fundedAt: now,
            submitDueAt: new Date(now.getTime() + SUBMIT_DUE_DAYS * DAY_MS),
          },
          tx,
        ))
      ) {
        return rollback('not-awaiting-payment');
      }
      const posted = await this.ledger.post(
        collaboration.id,
        postingsForPaymentApproved({
          escrow: payment.amountEscrow,
          fee: payment.amountFee,
        }),
        `payment:${payment.id}`,
        tx,
      );
      if (posted === 'duplicate') {
        // 대기 중인 결제에 이미 장부 줄이 있다면 상태가 어긋난 것이다. 조용히 넘기지 않고 되돌려 드러낸다.
        throw new Error('대기 중인 결제의 장부 줄이 이미 있어요.');
      }
      return 'funded';
    });

    if (outcome === 'funded') {
      const funded = await this.collaborations.findById(collaboration.id);
      if (funded) await this.afterFunded(funded, options);
      return;
    }
    if (outcome === 'already-handled') {
      const fresh = await this.payments.findById(payment.id);
      if (fresh?.status === 'APPROVED' || fresh?.status === 'FAILED') {
        await this.reactToSettledPayment(fresh, options);
      }
      return;
    }
    await this.recordLateApproval(payment, pgTransactionId, now);
  }

  // 이 승인을 협업에 반영할 수 없다(협업이 이미 끝났거나, 같은 협업의 다른 결제가 이미 보관을 시작했다).
  // 돈은 PG에서 빠져나갔으므로 결제만 승인으로 기록하고, 단계와 장부는 건드리지 않은 채 운영자에게 환불을 부탁한다
  // (운영 명령은 10번 작업). 알림을 먼저 보낸다: 알림이 실패하면 결제가 아직 승인으로 기록되지 않아 PG가 다시 보낼 때
  // 신호가 다시 나간다(동시에 오면 두 번 갈 수 있지만 한 번도 안 가는 것보다 낫다).
  private async recordLateApproval(
    payment: Payment,
    pgTransactionId: string,
    now: Date,
  ): Promise<void> {
    await this.operatorAlert.alert({
      subject: LATE_APPROVAL_SUBJECT,
      body: `결제 ID: ${payment.id}`,
    });
    await this.payments.markApproved(payment.id, pgTransactionId, now);
  }

  // 이미 승인됐거나 실패한 결제에 승인 통지가 또 왔다.
  // 승인된 결제이고 협업이 아직 FUNDED면 후속 단계를 다시 시도한다(같은 키라 이미 된 일은 그대로다).
  // 실패로 기록된 결제에 승인이 오면 돈이 나간 것이므로 운영자에게 알린다.
  private async reactToSettledPayment(
    payment: Payment,
    options: ApplyResultOptions,
  ): Promise<void> {
    if (payment.status === 'APPROVED') {
      const collaboration = await this.collaborations.findById(
        payment.collaborationId,
      );
      if (collaboration?.stage === 'FUNDED') {
        await this.afterFunded(collaboration, options);
      }
      return;
    }
    await this.operatorAlert.alert({
      subject: UNEXPECTED_APPROVAL_SUBJECT,
      body: `결제 ID: ${payment.id}`,
    });
  }

  // 커밋 뒤의 후속 단계. 모두 같은 키라 다시 불러도 한 번만 일어난다.
  // 작업 등록이 실패하면 던진다: 미제출 환급이 빠지면 안 되므로 재시도가 고치게 한다.
  private async afterFunded(
    collaboration: Collaboration,
    options: ApplyResultOptions,
  ): Promise<void> {
    const dueAt = collaboration.submitDueAt;
    if (!dueAt) throw new Error('보관이 시작된 협업에 제출 기한이 없어요.');
    // 미제출 환급과 기한 알림. 식사권만 있는 오퍼의 수락도 같은 도우미로 같은 키의 작업을 올린다.
    await scheduleSubmissionDeadlineJobs(
      this.jobs,
      collaboration.id,
      dueAt,
      this.clock.now(),
    );
    if (collaboration.offerId) {
      await this.offers.cancelPaymentDueJob(collaboration.offerId);
    }
    await this.notifyFunded(collaboration, options);
  }

  private async notifyFunded(
    collaboration: Collaboration,
    options: ApplyResultOptions,
  ): Promise<void> {
    const send = async () => {
      const actor = await this.storeActor(collaboration);
      await this.notifications.notify({
        userId: collaboration.creatorId,
        role: 'CREATOR',
        kind: 'PAYMENT_FUNDED',
        actor,
        target: { kind: 'COLLABORATION', id: collaboration.id },
        dedupeKey: `funded:${collaboration.id}`,
      });
    };
    if (!options.swallowNotifyErrors) return send();
    try {
      await send();
    } catch (error) {
      this.logger.warn(
        `결제 완료 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 알림에 넣을 가게. 비공개로 바뀌었거나 읽지 못하면 기본 이름을 쓴다.
  private async storeActor(collaboration: Collaboration) {
    let card: Awaited<ReturnType<StoresService['getOfferCard']>> = null;
    try {
      card = collaboration.storeId
        ? await this.stores.getOfferCard(collaboration.storeId)
        : null;
    } catch (error) {
      this.logger.warn(
        `알림에 넣을 가게를 읽지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
    return {
      userId: collaboration.commissionerId,
      name: card?.summary.name ?? '가게',
      photoPath: card?.coverPhotoPath ?? null,
    };
  }

  private scheduleRecheck(
    paymentId: string,
    attempt: number,
    from: Date,
  ): Promise<void> {
    return this.jobs.schedule(
      'payment-recheck',
      { paymentId, attempt },
      new Date(from.getTime() + RECHECK_INTERVAL_MINUTES * MINUTE_MS),
      recheckJobKey(paymentId, attempt),
    );
  }

  // 사장님 계정이고 이 협업을 맡긴 사람이어야 한다. 남의 협업은 없는 협업과 같게 404.
  private async requireOwned(
    userId: string,
    collaborationId: string,
  ): Promise<Collaboration> {
    await this.assertStoreRole(userId);
    const collaboration = UUID.test(collaborationId)
      ? await this.collaborations.findById(collaborationId)
      : null;
    if (
      !collaboration ||
      collaboration.kind !== 'STORE_OFFER' ||
      collaboration.commissionerId !== userId
    ) {
      throw new AppError('NOT_FOUND', '협업을 찾을 수 없어요.');
    }
    return collaboration;
  }

  // 결제할 수 있는 협업이어야 한다. 결제 기한이 지난 오퍼는 먼저 만료로 저장해(읽을 때 만료와 같은 길) 협업을 끝낸다.
  private async requirePayable(
    userId: string,
    collaborationId: string,
  ): Promise<Collaboration> {
    const collaboration = await this.requireOwned(userId, collaborationId);
    if (collaboration.offerId) {
      await this.offers.expireUnpaid(collaboration.offerId);
    }
    const fresh = await this.collaborations.findById(collaboration.id);
    if (fresh?.stage !== 'AWAITING_PAYMENT') {
      throw this.notPayable();
    }
    return fresh;
  }

  private async quoteOf(
    collaboration: Collaboration,
  ): Promise<PaymentQuoteModel> {
    const terms = readTerms(collaboration.terms);
    const feeRate = this.feeRate();
    const fee = feeFor(terms.perViewCap, feeRate);
    const card = collaboration.storeId
      ? await this.stores.getOfferCard(collaboration.storeId)
      : null;
    const creator = await this.creators.getSummary(collaboration.creatorId);
    return {
      escrow: terms.perViewCap,
      fee,
      feeRate,
      total: terms.perViewCap + fee,
      orderName: `${card?.summary.name ?? '가게'} 콘텐츠 제작비`,
      creatorName: creator?.displayName ?? '크리에이터',
      creatorPhotoUrl: creator?.photoUrl ?? null,
      format: terms.format,
      // 오퍼는 지금 한 편짜리다(편 수를 고르는 화면이 없다).
      pieces: 1,
      voucherName: terms.voucherName,
    };
  }

  private feeRate(): number {
    const rate = Number(this.config.getOrThrow('FEE_RATE_STORE_OFFER'));
    if (!Number.isInteger(rate) || rate < 0 || rate > 100) {
      throw new Error(`수수료율이 올바르지 않아요: ${rate}`);
    }
    return rate;
  }

  private async assertStoreRole(userId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'STORE') {
      throw new AppError('FORBIDDEN', '가게 계정만 쓸 수 있어요.');
    }
  }

  private notPayable(): AppError {
    return new AppError('CONFLICT', '결제할 수 있는 협업이 아니에요.');
  }

  private paymentNotFound(): AppError {
    return new AppError('NOT_FOUND', '결제를 찾을 수 없어요.');
  }
}

// 협업에 사본으로 남은 수락 당시의 조건에서 결제에 필요한 것만 꺼낸다.
// 결제를 기다리는 협업에는 조회수 상한이 반드시 있다. 없으면 데이터가 어긋난 것이라 던진다.
function readTerms(terms: unknown): {
  format: PaymentQuoteModel['format'];
  perViewCap: number;
  voucherName: string | null;
} {
  const t = (terms ?? {}) as Record<string, unknown>;
  const cap = t.perViewCap;
  if (typeof cap !== 'number' || !Number.isInteger(cap) || cap <= 0) {
    throw new Error('결제를 기다리는 협업의 조건에 조회수 상한이 없어요.');
  }
  return {
    format: t.format as PaymentQuoteModel['format'],
    perViewCap: cap,
    voucherName: typeof t.voucherName === 'string' ? t.voucherName : null,
  };
}
