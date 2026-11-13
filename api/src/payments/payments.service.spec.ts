import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Collaboration, Payment } from '@prisma/client';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeJobScheduler } from '../../test/support/fake-job-scheduler';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { FakePaymentAdapter } from '../integrations/payment/fake-payment.adapter';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { JobHandlerRegistry } from '../jobs/job-handler-registry';
import { Posting } from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import {
  NotificationsService,
  NotifyInput,
} from '../notifications/notifications.service';
import { OffersService } from '../offers/offers.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { PaymentsRepository } from './payments.repository';
import {
  LATE_APPROVAL_SUBJECT,
  PaymentsService,
  RECHECK_MAX_ATTEMPTS,
} from './payments.service';

const OWNER = '11111111-1111-4111-8111-111111111111';
const CREATOR = '22222222-2222-4222-8222-222222222222';
const COLLAB = '33333333-3333-4333-8333-333333333333';
const OFFER = '44444444-4444-4444-8444-444444444444';
const PAYMENT = '55555555-5555-4555-8555-555555555555';
const SECOND_PAYMENT = '66666666-6666-4666-8666-666666666666';
// 한국 시간 2026-12-01 12:00.
const T0 = new Date('2026-12-01T03:00:00.000Z');
const MINUTE = 60 * 1000;
const DAY = 24 * 60 * MINUTE;

class Rolled<R> extends Error {
  constructor(readonly result: R) {
    super('rolled back');
  }
}

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 트랜잭션 되돌리기와 조건부 갱신(SQL)은 e2e가 실제 DB로 확인한다.
class FakePaymentsRepository extends PaymentsRepository {
  rows: Payment[] = [];
  constructor() {
    super(null as never);
  }
  findById(id: string) {
    return Promise.resolve(this.rows.find((p) => p.id === id) ?? null);
  }
  replacePending(input: Parameters<PaymentsRepository['replacePending']>[0]) {
    for (const p of this.rows) {
      if (p.collaborationId === input.collaborationId && p.status === 'PENDING')
        p.status = 'CANCELLED';
    }
    const row = payment({ id: `pay-${this.rows.length + 1}`, ...input });
    this.rows.push(row);
    return Promise.resolve(row);
  }
  // 되돌리면 트랜잭션 안에서 바꾼 결제 행도 되돌아와야 실제 DB와 같다.
  async transaction<T, R>(
    run: (tx: never, rollback: (result: R) => never) => Promise<T>,
  ): Promise<T | R> {
    const before = this.rows.map((row) => ({ ...row }));
    try {
      return await run(null as never, (result: R): never => {
        throw new Rolled(result);
      });
    } catch (error) {
      this.rows.splice(0, this.rows.length, ...before);
      if (error instanceof Rolled) return error.result as R;
      throw error;
    }
  }
  markApproved(id: string, pgTransactionId: string, approvedAt: Date) {
    const row = this.rows.find(
      (p) =>
        p.id === id && (p.status === 'PENDING' || p.status === 'CANCELLED'),
    );
    if (row) {
      row.status = 'APPROVED';
      row.pgTransactionId = pgTransactionId;
      row.approvedAt = approvedAt;
    }
    return Promise.resolve(!!row);
  }
  markFailed(id: string) {
    const row = this.rows.find((p) => p.id === id && p.status === 'PENDING');
    if (row) row.status = 'FAILED';
    return Promise.resolve(!!row);
  }
}

class FakeCollaborationsRepository extends CollaborationsRepository {
  row: Collaboration = collaboration();
  constructor() {
    super(null as never);
  }
  findById(id: string) {
    return Promise.resolve(id === this.row.id ? { ...this.row } : null);
  }
  advance(
    id: string,
    from: Collaboration['stage'],
    to: Collaboration['stage'],
    patch: Parameters<CollaborationsRepository['advance']>[3] = {},
  ) {
    if (id !== this.row.id || this.row.stage !== from) {
      return Promise.resolve(false);
    }
    this.row = { ...this.row, ...patch, stage: to };
    return Promise.resolve(true);
  }
}

class FakeOperatorAlert extends OperatorAlertPort {
  readonly alerts: { subject: string; body: string }[] = [];
  fails = false;
  alert(input: { subject: string; body: string }) {
    if (this.fails) return Promise.reject(new Error('alert down'));
    this.alerts.push(input);
    return Promise.resolve();
  }
}

function collaboration(over: Partial<Collaboration> = {}): Collaboration {
  return {
    id: COLLAB,
    kind: 'STORE_OFFER',
    stage: 'AWAITING_PAYMENT',
    commissionerId: OWNER,
    creatorId: CREATOR,
    offerId: OFFER,
    storeId: 'store-1',
    terms: {
      format: 'REELS',
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      fixedCash: 0,
      viewRatePerThousand: 2000,
      perViewCap: 100000,
      usageRights: 'STORE_REPOST_3M',
    },
    settlementMethod: 'PER_VIEW',
    fundedAt: null,
    submitDueAt: null,
    submittedUrl: null,
    submittedAt: null,
    countingEndsAt: null,
    haltedReason: null,
    stageBeforeHalt: null,
    createdAt: T0,
    updatedAt: T0,
    deletedAt: null,
    ...over,
  };
}

function payment(over: Partial<Payment> = {}): Payment {
  return {
    id: PAYMENT,
    collaborationId: COLLAB,
    amountEscrow: 100000,
    amountFee: 10000,
    feeRate: 10,
    method: 'CARD',
    status: 'PENDING',
    pgTransactionId: null,
    requestedAt: T0,
    approvedAt: null,
    createdAt: T0,
    updatedAt: T0,
    deletedAt: null,
    ...over,
  };
}

function build(feeRate = 10) {
  const payments = new FakePaymentsRepository();
  const collaborations = new FakeCollaborationsRepository();
  const clock = new FakeClock(T0);
  const scheduler = new FakeJobScheduler(new JobHandlerRegistry());
  const alerts = new FakeOperatorAlert();
  const pg = new FakePaymentAdapter(undefined);
  const ledgerPosts: { key: string; postings: Posting[] }[] = [];
  const notified: NotifyInput[] = [];
  const cancelledDueJobs: string[] = [];
  const state = {
    clearPaymentDue: true,
    offerAccepted: true,
    notifyFails: false,
  };
  const offers = {
    expireUnpaid: () => Promise.resolve(),
    clearPaymentDue: () => Promise.resolve(state.clearPaymentDue),
    lockAcceptedForPayment: () => Promise.resolve(state.offerAccepted),
    cancelPaymentDueJob: (offerId: string) => {
      cancelledDueJobs.push(offerId);
      return Promise.resolve();
    },
  } as unknown as OffersService;
  const ledger = {
    post: (_c: string, postings: Posting[], key: string) => {
      ledgerPosts.push({ key, postings });
      return Promise.resolve('posted' as const);
    },
  } as unknown as LedgerService;
  const notifications = {
    notify: (input: NotifyInput) => {
      if (state.notifyFails) return Promise.reject(new Error('inbox down'));
      // 실제 notify처럼 같은 중복 방지 키의 두 번째 알림은 만들지 않는다.
      if (notified.some((n) => n.dedupeKey === input.dedupeKey)) {
        return Promise.resolve();
      }
      notified.push(input);
      return Promise.resolve();
    },
  } as unknown as NotificationsService;
  const users = {
    getRole: (id: string) =>
      Promise.resolve(id === OWNER ? 'STORE' : 'CREATOR'),
  } as unknown as UsersService;
  const stores = {
    getOfferCard: () =>
      Promise.resolve({
        coverPhotoPath: 'stores/cover.jpg',
        summary: { name: '하루 한 컵' },
      }),
  } as unknown as StoresService;
  const creators = {
    getSummary: () =>
      Promise.resolve({ displayName: '모카', photoUrl: 'https://img/mocha' }),
  } as unknown as CreatorsService;
  const service = new PaymentsService(
    payments,
    collaborations,
    offers,
    ledger,
    notifications,
    scheduler,
    users,
    stores,
    creators,
    pg,
    alerts,
    new ConfigService({ FEE_RATE_STORE_OFFER: feeRate }),
    clock,
  );
  return {
    service,
    payments,
    collaborations,
    clock,
    scheduler,
    alerts,
    pg,
    ledgerPosts,
    notified,
    cancelledDueJobs,
    state,
  };
}

describe('PaymentsService', () => {
  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
  });
  afterEach(() => jest.restoreAllMocks());

  describe('quote', () => {
    it('rounds the fee down so the ledger never holds more than the owner paid', async () => {
      const t = build(10);
      t.collaborations.row = collaboration({
        terms: {
          format: 'REELS',
          perViewCap: 33333,
          viewRatePerThousand: 2000,
          voucherName: null,
        },
      });
      const quote = await t.service.getQuote(OWNER, COLLAB);
      expect(quote).toMatchObject({
        escrow: 33333,
        fee: 3333,
        feeRate: 10,
        total: 36666,
        voucherName: null,
        creatorName: '모카',
        creatorPhotoUrl: 'https://img/mocha',
        pieces: 1,
      });
    });

    it('copies the configured fee rate and allows zero', async () => {
      const t = build(0);
      expect(await t.service.getQuote(OWNER, COLLAB)).toMatchObject({
        fee: 0,
        feeRate: 0,
        total: 100000,
      });
    });

    it('fails loudly when a collaboration awaiting payment has nothing to pay', async () => {
      const t = build();
      t.collaborations.row = collaboration({ terms: { format: 'REELS' } });
      await expect(t.service.getQuote(OWNER, COLLAB)).rejects.toThrow(
        '낼 돈이 없어요',
      );
    });

    it('quotes the maximum cash burden plus the fee for a new copy', async () => {
      const t = build(10);
      t.collaborations.row = collaboration({
        terms: {
          format: 'REELS',
          voucherName: '식사권',
          voucherValue: 40000,
          voucherPeople: 2,
          fixedCash: 0,
          viewRatePerThousand: 2000,
          perViewCap: 60000,
          usageRights: 'STORE_REPOST_3M',
        },
      });
      expect(await t.service.getQuote(OWNER, COLLAB)).toMatchObject({
        escrow: 60000,
        fee: 6000,
        total: 66000,
        fixedCash: 0,
        perViewCap: 60000,
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
      });
    });

    it('adds fixed cash to the burden for a copy that has one', async () => {
      const t = build(10);
      t.collaborations.row = collaboration({
        terms: {
          format: 'REELS',
          fixedCash: 30000,
          viewRatePerThousand: 2000,
          perViewCap: 60000,
        },
      });
      expect(await t.service.getQuote(OWNER, COLLAB)).toMatchObject({
        escrow: 90000,
        fee: 9000,
        total: 99000,
        fixedCash: 30000,
      });
    });

    it('quotes a legacy copy with the same amounts as before', async () => {
      const t = build(10);
      t.collaborations.row = collaboration({
        terms: {
          format: 'REELS',
          rewardType: 'BOTH',
          voucherName: '2인 식사권',
          voucherValue: 40000,
          perViewAmount: 10,
          perViewCap: 100000,
        },
      });
      expect(await t.service.getQuote(OWNER, COLLAB)).toMatchObject({
        escrow: 100000,
        fee: 10000,
        total: 110000,
        voucherName: '식사권',
        voucherPeople: 2,
      });
    });

    it('answers 404 to anyone but the commissioner and 403 to a non-store account', async () => {
      const t = build();
      t.collaborations.row = collaboration({ commissionerId: 'someone-else' });
      await expect(t.service.getQuote(OWNER, COLLAB)).rejects.toMatchObject({
        code: 'NOT_FOUND',
      });
      await expect(t.service.getQuote(CREATOR, COLLAB)).rejects.toMatchObject({
        code: 'FORBIDDEN',
      });
    });
  });

  describe('create', () => {
    it('cancels the earlier pending payment, creates a new one and schedules the first recheck', async () => {
      const t = build();
      const first = await t.service.create(OWNER, COLLAB, 'CARD');
      const second = await t.service.create(OWNER, COLLAB, 'TRANSFER');
      expect(t.payments.rows.map((p) => p.status)).toEqual([
        'CANCELLED',
        'PENDING',
      ]);
      expect(first.paymentId).not.toBe(second.paymentId);
      const job = t.scheduler.pending().find((j) => j.jobKey.endsWith(':1'));
      expect(job?.runAt).toEqual(new Date(T0.getTime() + 10 * MINUTE));
    });

    it('answers 409 when the offer or the collaboration changed after the first check', async () => {
      const t = build();
      t.state.offerAccepted = false;
      await expect(
        t.service.create(OWNER, COLLAB, 'CARD'),
      ).rejects.toMatchObject({ code: 'CONFLICT' });
      expect(t.payments.rows).toHaveLength(0);
    });

    it('refuses to create a payment when the collaboration was funded between the check and the write', async () => {
      const t = build();
      const funded = collaboration({ stage: 'FUNDED', fundedAt: T0 });
      const original = t.collaborations.findById.bind(t.collaborations);
      // 트랜잭션 밖의 확인은 아직 결제 대기, 트랜잭션 안의 재확인은 그사이 승인이 커밋된 뒤를 본다.
      jest
        .spyOn(t.collaborations, 'findById')
        .mockImplementation((id: string, tx?: unknown) =>
          tx === undefined
            ? original(id)
            : Promise.resolve(id === COLLAB ? { ...funded } : null),
        );
      const checkout = jest.spyOn(t.pg, 'createCheckout');
      await expect(
        t.service.create(OWNER, COLLAB, 'CARD'),
      ).rejects.toMatchObject({ code: 'CONFLICT' });
      expect(t.payments.rows).toHaveLength(0);
      expect(checkout).not.toHaveBeenCalled();
    });

    it('still creates the payment when the recheck job cannot be scheduled', async () => {
      const t = build();
      jest
        .spyOn(t.scheduler, 'schedule')
        .mockRejectedValue(new Error('redis down'));
      const created = await t.service.create(OWNER, COLLAB, 'CARD');
      expect(created.paymentId).toBeDefined();
    });
  });

  describe('applyResult', () => {
    const approved = (pgTransactionId: string | null = 'tx-1') => ({
      paymentId: PAYMENT,
      pgTransactionId,
      status: 'APPROVED' as const,
    });

    it('does nothing for a payment it does not know or an id that is not a uuid', async () => {
      const t = build();
      await t.service.applyResult(approved());
      await t.service.applyResult({ ...approved(), paymentId: 'nope' });
      expect(t.ledgerPosts).toHaveLength(0);
    });

    it('only marks the payment failed on a failed result', async () => {
      const t = build();
      t.payments.rows.push(payment());
      await t.service.applyResult({ ...approved(), status: 'FAILED' });
      expect(t.payments.rows[0].status).toBe('FAILED');
      expect(t.collaborations.row.stage).toBe('AWAITING_PAYMENT');
      expect(t.ledgerPosts).toHaveLength(0);
    });

    it('refuses an approval that carries no transaction id', async () => {
      const t = build();
      t.payments.rows.push(payment());
      await expect(t.service.applyResult(approved(null))).rejects.toThrow(
        '거래 번호',
      );
      expect(t.payments.rows[0].status).toBe('PENDING');
    });

    it('posts escrow and fee under a payment key and funds with a 14 day submit due date', async () => {
      const t = build();
      t.payments.rows.push(payment());
      await t.service.applyResult(approved());
      expect(t.ledgerPosts).toEqual([
        {
          key: `payment:${PAYMENT}`,
          postings: [
            expect.objectContaining({
              debit: 'PG_IN',
              credit: 'ESCROW',
              amount: 100000,
            }),
            expect.objectContaining({
              debit: 'PG_IN',
              credit: 'FEE_REVENUE',
              amount: 10000,
            }),
          ],
        },
      ]);
      expect(t.collaborations.row).toMatchObject({
        stage: 'FUNDED',
        fundedAt: T0,
        submitDueAt: new Date(T0.getTime() + 14 * DAY),
      });
      expect(t.cancelledDueJobs).toEqual([OFFER]);
    });

    it('records a late approval and alerts the operator without a ledger line when the collaboration ended', async () => {
      const t = build();
      t.collaborations.row = collaboration({ stage: 'CANCELLED' });
      t.payments.rows.push(payment());
      await t.service.applyResult(approved());
      expect(t.payments.rows[0].status).toBe('APPROVED');
      expect(t.collaborations.row.stage).toBe('CANCELLED');
      expect(t.ledgerPosts).toHaveLength(0);
      expect(t.alerts.alerts).toEqual([
        {
          subject:
            '협업에 반영하지 못한 결제가 승인됐어요. 운영 명령으로 환불해 주세요.',
          body: `결제 ID: ${PAYMENT}`,
        },
      ]);
    });

    it('funds the collaboration when a payment that was replaced by a newer one is approved', async () => {
      const t = build();
      t.payments.rows.push(payment({ status: 'CANCELLED' }));
      t.payments.rows.push(payment({ id: SECOND_PAYMENT, status: 'PENDING' }));
      await t.service.applyResult(approved());
      expect(t.payments.rows.map((p) => p.status)).toEqual([
        'APPROVED',
        'PENDING',
      ]);
      expect(t.collaborations.row.stage).toBe('FUNDED');
      expect(t.ledgerPosts.map((p) => p.key)).toEqual([`payment:${PAYMENT}`]);
      expect(t.alerts.alerts).toHaveLength(0);
      // 남은 대기 결제가 나중에 승인되면 이미 보관 중이라 늦은 승인이다: 장부는 그대로.
      await t.service.applyResult({
        paymentId: SECOND_PAYMENT,
        pgTransactionId: 'tx-2',
        status: 'APPROVED',
      });
      expect(t.ledgerPosts).toHaveLength(1);
      expect(t.alerts.alerts).toHaveLength(1);
    });

    it('alerts the operator, and does not fund, when an approval arrives for a failed payment', async () => {
      const t = build();
      t.payments.rows.push(payment({ status: 'FAILED' }));
      await t.service.applyResult(approved());
      expect(t.payments.rows[0].status).toBe('FAILED');
      expect(t.collaborations.row.stage).toBe('AWAITING_PAYMENT');
      expect(t.alerts.alerts).toHaveLength(1);
    });

    it('alerts before it records a late approval so a failed alert is sent again when the PG resends', async () => {
      const t = build();
      t.collaborations.row = collaboration({ stage: 'CANCELLED' });
      t.payments.rows.push(payment());
      t.alerts.fails = true;
      await expect(t.service.applyResult(approved())).rejects.toThrow('alert');
      expect(t.payments.rows[0].status).toBe('PENDING');
      t.alerts.fails = false;
      await t.service.applyResult(approved());
      expect(t.payments.rows[0].status).toBe('APPROVED');
      expect(t.alerts.alerts).toHaveLength(1);
    });

    it('treats an offer that is no longer accepted as a late approval too', async () => {
      const t = build();
      t.state.clearPaymentDue = false;
      t.payments.rows.push(payment());
      await t.service.applyResult(approved());
      expect(t.ledgerPosts).toHaveLength(0);
      expect(t.alerts.alerts).toHaveLength(1);
    });

    it('swallows a notification failure on the request path but lets a job see it', async () => {
      const t = build();
      t.payments.rows.push(payment());
      t.state.notifyFails = true;
      await expect(
        t.service.applyResult(approved(), { swallowNotifyErrors: true }),
      ).resolves.toBeUndefined();
      expect(t.collaborations.row.stage).toBe('FUNDED');
      // 재시도가 같은 결과를 다시 넣으면 알림이 이번에는 나간다.
      t.state.notifyFails = false;
      await t.service.applyResult(approved());
      expect(t.notified).toHaveLength(1);
      // 작업 처리기 쪽은 던진다.
      t.state.notifyFails = true;
      await expect(t.service.applyResult(approved())).rejects.toThrow('inbox');
    });

    it('notifies the creator with the store as the actor and a funded dedupe key', async () => {
      const t = build();
      t.payments.rows.push(payment());
      await t.service.applyResult(approved());
      expect(t.notified).toEqual([
        {
          userId: CREATOR,
          role: 'CREATOR',
          kind: 'PAYMENT_FUNDED',
          actor: {
            userId: OWNER,
            name: '하루 한 컵',
            photoPath: 'stores/cover.jpg',
          },
          target: { kind: 'COLLABORATION', id: COLLAB },
          dedupeKey: `funded:${COLLAB}`,
        },
      ]);
    });

    it('does not schedule a reminder whose time has already passed when it heals late', async () => {
      const t = build();
      // 제출 기한까지 이틀 남은 채로 늦게 고쳐진다: 3일 전 알림은 이미 지났다.
      const due = new Date(T0.getTime() + 2 * DAY);
      t.collaborations.row = collaboration({
        stage: 'FUNDED',
        submitDueAt: due,
      });
      t.payments.rows.push(payment({ status: 'APPROVED' }));
      await t.service.applyResult(approved());
      const keys = t.scheduler.pending().map((j) => j.jobKey);
      expect(keys).toContain(`refund-unsubmitted:${COLLAB}`);
      expect(keys).toContain(`submit-reminder:${COLLAB}:1`);
      expect(keys).not.toContain(`submit-reminder:${COLLAB}:3`);
    });

    it('leaves a collaboration that moved past FUNDED alone when the notice is repeated', async () => {
      const t = build();
      t.collaborations.row = collaboration({ stage: 'COUNTING' });
      t.payments.rows.push(payment({ status: 'APPROVED' }));
      await t.service.applyResult(approved());
      expect(t.scheduler.pending()).toHaveLength(0);
      expect(t.notified).toHaveLength(0);
    });
  });

  describe('recheck', () => {
    it('asks the PG again ten minutes later while pending, up to the sixth try', async () => {
      const t = build();
      t.payments.rows.push(payment());
      await t.service.recheck(PAYMENT, 1);
      expect(t.scheduler.pending().map((j) => j.jobKey)).toEqual([
        `payment-recheck:${PAYMENT}:2`,
      ]);
      t.scheduler.jobs.length = 0;
      await t.service.recheck(PAYMENT, RECHECK_MAX_ATTEMPTS);
      expect(t.scheduler.pending()).toHaveLength(0);
    });

    it('does not ask for a payment that has already failed', async () => {
      const t = build();
      t.payments.rows.push(payment({ status: 'FAILED' }));
      const spy = jest.spyOn(t.pg, 'fetchStatus');
      await t.service.recheck(PAYMENT, 1);
      expect(spy).not.toHaveBeenCalled();
    });

    it('asks the PG about a payment superseded by a newer one and funds the collaboration when it was approved', async () => {
      const t = build();
      // 결제창을 닫고 다시 결제해 첫 결제가 밀려났는데, 그 결제의 웹훅이 사라진 경우.
      t.payments.rows.push(payment({ status: 'CANCELLED' }));
      t.payments.rows.push(payment({ id: SECOND_PAYMENT, status: 'PENDING' }));
      t.pg.recordResult({ paymentId: PAYMENT, status: 'APPROVED' });
      await t.service.recheck(PAYMENT, 1);
      expect(t.payments.rows[0].status).toBe('APPROVED');
      expect(t.collaborations.row.stage).toBe('FUNDED');
      expect(t.ledgerPosts.map((p) => p.key)).toEqual([`payment:${PAYMENT}`]);
      expect(t.alerts.alerts).toHaveLength(0);
    });

    it('alerts the operator when a superseded payment turns out approved after another payment funded', async () => {
      const t = build();
      t.collaborations.row = collaboration({
        stage: 'FUNDED',
        fundedAt: T0,
        submitDueAt: new Date(T0.getTime() + 7 * DAY),
      });
      t.payments.rows.push(payment({ status: 'CANCELLED' }));
      t.pg.recordResult({ paymentId: PAYMENT, status: 'APPROVED' });
      await t.service.recheck(PAYMENT, 1);
      expect(t.ledgerPosts).toHaveLength(0);
      expect(t.alerts.alerts.map((a) => a.subject)).toEqual([
        LATE_APPROVAL_SUBJECT,
      ]);
    });

    it('finishes the steps after funding when a failed recheck job is run again', async () => {
      const t = build();
      t.payments.rows.push(payment());
      t.pg.recordResult({ paymentId: PAYMENT, status: 'APPROVED' });
      t.state.notifyFails = true;
      // 첫 실행: 승인은 커밋됐지만 알림이 실패해 작업이 던진다.
      await expect(t.service.recheck(PAYMENT, 1)).rejects.toThrow('inbox');
      expect(t.collaborations.row.stage).toBe('FUNDED');
      expect(t.notified).toHaveLength(0);
      // 큐가 같은 작업을 다시 돌린다: 결제는 이미 APPROVED지만 남은 단계를 마친다.
      t.state.notifyFails = false;
      await t.service.recheck(PAYMENT, 1);
      expect(t.notified).toHaveLength(1);
      expect(t.ledgerPosts).toHaveLength(1);
      expect(
        t.scheduler
          .pending()
          .map((j) => j.jobKey)
          .sort(),
      ).toEqual([
        `refund-unsubmitted:${COLLAB}`,
        `submit-reminder:${COLLAB}:1`,
        `submit-reminder:${COLLAB}:3`,
      ]);
      // 세 번째 실행은 아무것도 더하지 않는다.
      await t.service.recheck(PAYMENT, 1);
      expect(t.notified).toHaveLength(1);
    });

    it('passes the transaction id the PG reports on to the approval', async () => {
      const t = build();
      t.payments.rows.push(payment());
      t.pg.recordResult({
        paymentId: PAYMENT,
        status: 'APPROVED',
        pgTransactionId: 'tx-from-pg',
      });
      await t.service.recheck(PAYMENT, 1);
      expect(t.payments.rows[0]).toMatchObject({
        status: 'APPROVED',
        pgTransactionId: 'tx-from-pg',
      });
    });
  });

  it('turns an away payment lookup into a 404 for someone else', async () => {
    const t = build();
    t.payments.rows.push(payment());
    t.collaborations.row = collaboration({ commissionerId: 'someone-else' });
    await expect(t.service.getStatus(OWNER, PAYMENT)).rejects.toBeInstanceOf(
      AppError,
    );
  });
});
