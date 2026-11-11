import { Logger } from '@nestjs/common';
import { CancelRequest, Collaboration, Refund } from '@prisma/client';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeJobScheduler } from '../../test/support/fake-job-scheduler';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { JobHandlerRegistry } from '../jobs/job-handler-registry';
import { Posting } from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { NotifyInput } from '../notifications/notifications.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OffersService } from '../offers/offers.service';
import { PaymentsService } from '../payments/payments.service';
import { PayoutAccountsService } from '../payout-accounts/payout-accounts.service';
import { RefundsService } from '../settlements/refunds.service';
import { SettlementsRepository } from '../settlements/settlements.repository';
import { StoresService } from '../stores/stores.service';
import { CancelRequestsRepository } from './cancel-requests.repository';
import { CollaborationsRepository } from './collaborations.repository';
import { CollaborationsService } from './collaborations.service';

const OWNER = '11111111-1111-4111-8111-111111111111';
const CREATOR = '22222222-2222-4222-8222-222222222222';
const STRANGER = '99999999-9999-4999-8999-999999999999';
const COLLAB = '33333333-3333-4333-8333-333333333333';
const OFFER = '44444444-4444-4444-8444-444444444444';
const STORE = '55555555-5555-4555-8555-555555555555';
// 한국 시간 2026-12-01 12:00.
const T0 = new Date('2026-12-01T03:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;

class Rolled<R> extends Error {
  constructor(readonly result: R) {
    super('rolled back');
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
  listForParty() {
    return Promise.resolve([{ ...this.row }]);
  }
  advance(
    id: string,
    from: Collaboration['stage'],
    to: Collaboration['stage'],
  ) {
    if (id !== this.row.id || this.row.stage !== from) {
      return Promise.resolve(false);
    }
    this.row = { ...this.row, stage: to };
    return Promise.resolve(true);
  }
}

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 잠금과 조건부 갱신(SQL)은 e2e가 실제 DB로 확인한다.
class FakeCancelRequestsRepository extends CancelRequestsRepository {
  rows: CancelRequest[] = [];
  now: () => Date = () => T0;
  constructor() {
    super(null as never);
  }
  // 되돌리면 트랜잭션 안에서 바꾼 행도 되돌아와야 실제 DB와 같다.
  async transaction<T, R>(
    run: (tx: never, rollback: (result: R) => never) => Promise<T>,
  ): Promise<T | R> {
    const before = this.rows.map((row) => ({ ...row }));
    try {
      return await run(null as never, (result: R): never => {
        throw new Rolled(result);
      });
    } catch (error) {
      this.rows = before;
      if (error instanceof Rolled) return error.result as R;
      throw error;
    }
  }
  lockCollaboration() {
    return Promise.resolve();
  }
  findById(id: string) {
    return Promise.resolve(this.rows.find((r) => r.id === id) ?? null);
  }
  mapPendingFor(ids: string[], now: Date) {
    const map = new Map<string, CancelRequest>();
    for (const r of this.rows) {
      if (
        ids.includes(r.collaborationId) &&
        r.status === 'PENDING' &&
        r.expiresAt > now
      ) {
        map.set(r.collaborationId, r);
      }
    }
    return Promise.resolve(map);
  }
  findPending(collaborationId: string, now: Date) {
    return Promise.resolve(
      this.rows.find(
        (r) =>
          r.collaborationId === collaborationId &&
          r.status === 'PENDING' &&
          r.expiresAt > now,
      ) ?? null,
    );
  }
  expireStale(collaborationId: string, now: Date) {
    for (const r of this.rows) {
      if (
        r.collaborationId === collaborationId &&
        r.status === 'PENDING' &&
        r.expiresAt <= now
      ) {
        r.status = 'EXPIRED';
      }
    }
    return Promise.resolve();
  }
  create(data: {
    collaborationId: string;
    requestedById: string;
    expiresAt: Date;
  }) {
    const row: CancelRequest = {
      id: `66666666-6666-4666-8666-66666666666${this.rows.length}`,
      status: 'PENDING',
      createdAt: T0,
      updatedAt: T0,
      deletedAt: null,
      ...data,
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }
  accept(id: string, collaborationId: string, now: Date) {
    const row = this.rows.find(
      (r) =>
        r.id === id &&
        r.collaborationId === collaborationId &&
        r.status === 'PENDING' &&
        r.expiresAt > now,
    );
    if (row) row.status = 'ACCEPTED';
    return Promise.resolve(!!row);
  }
  expire(id: string) {
    const row = this.rows.find((r) => r.id === id && r.status === 'PENDING');
    if (row) row.status = 'EXPIRED';
    return Promise.resolve(!!row);
  }
}

class FakeSettlementsRepository extends SettlementsRepository {
  constructor() {
    super(null as never);
  }
  latestViewsFor() {
    return Promise.resolve(new Map<string, number>());
  }
  settlementsFor() {
    return Promise.resolve(new Map());
  }
  latestPayoutsFor() {
    return Promise.resolve(new Map());
  }
}

function collaboration(over: Partial<Collaboration> = {}): Collaboration {
  return {
    id: COLLAB,
    kind: 'STORE_OFFER',
    stage: 'FUNDED',
    commissionerId: OWNER,
    creatorId: CREATOR,
    offerId: OFFER,
    storeId: STORE,
    terms: {
      format: 'REELS',
      rewardType: 'BOTH',
      voucherName: '2인 식사권',
      voucherValue: 40000,
      perViewAmount: 10,
      perViewCap: 100000,
    },
    settlementMethod: 'PER_VIEW',
    fundedAt: T0,
    submitDueAt: new Date(T0.getTime() + 14 * DAY),
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

function build() {
  const collaborations = new FakeCollaborationsRepository();
  const requests = new FakeCancelRequestsRepository();
  const clock = new FakeClock(T0);
  const scheduler = new FakeJobScheduler(new JobHandlerRegistry());
  const ledgerPosts: { key: string; postings: Posting[] }[] = [];
  const refundRequests: { amount: number; key: string }[] = [];
  const executed: string[] = [];
  const notified: NotifyInput[] = [];
  const state = { funded: true, executeFails: false, notifyFails: false };

  const refunds = {
    request: (_id: string, amount: number, key: string) => {
      refundRequests.push({ amount, key });
      return Promise.resolve({ id: 'refund-1' } as Refund);
    },
    findByKey: (key: string) =>
      Promise.resolve(
        refundRequests.some((r) => r.key === key)
          ? ({ id: 'refund-1' } as Refund)
          : null,
      ),
    execute: (id: string) => {
      if (state.executeFails) return Promise.reject(new Error('pg down'));
      executed.push(id);
      return Promise.resolve();
    },
  } as unknown as RefundsService;
  const payments = {
    fundedAmounts: () =>
      Promise.resolve(
        state.funded
          ? new Map([[COLLAB, { escrow: 100000, fee: 10000 }]])
          : new Map(),
      ),
  } as unknown as PaymentsService;
  const ledger = {
    post: (_id: string, postings: Posting[], key: string) => {
      ledgerPosts.push({ key, postings });
      return Promise.resolve('posted' as const);
    },
  } as unknown as LedgerService;
  const notifications = {
    notify: (input: NotifyInput) => {
      if (state.notifyFails) return Promise.reject(new Error('notify down'));
      notified.push(input);
      return Promise.resolve();
    },
  } as unknown as NotificationsService;
  const stores = {
    getOfferCard: () =>
      Promise.resolve({
        ownerId: OWNER,
        coverPhotoPath: null,
        summary: { id: STORE, name: '하루 한 컵', coverPhotoUrl: null },
        intro: null,
        bestShootingTime: null,
      }),
  } as unknown as StoresService;
  const creators = {
    getActor: () =>
      Promise.resolve({ userId: CREATOR, name: '모카', photoPath: null }),
    getSummary: () => Promise.resolve({ displayName: '모카', photoUrl: null }),
  } as unknown as CreatorsService;
  const offers = {
    expireUnpaid: () => Promise.resolve(),
  } as unknown as OffersService;
  const accounts = {
    hasAccount: () => Promise.resolve(false),
  } as unknown as PayoutAccountsService;

  const service = new CollaborationsService(
    collaborations,
    requests,
    new FakeSettlementsRepository(),
    refunds,
    payments,
    accounts,
    ledger,
    offers,
    stores,
    creators,
    notifications,
    scheduler,
    clock,
  );
  return {
    service,
    collaborations,
    requests,
    clock,
    scheduler,
    ledgerPosts,
    refundRequests,
    executed,
    notified,
    state,
  };
}

const codeOf = async (promise: Promise<unknown>): Promise<string> => {
  try {
    await promise;
  } catch (error) {
    if (error instanceof AppError) return error.code;
    throw error;
  }
  return 'NO_ERROR';
};

describe('CollaborationsService', () => {
  afterEach(() => jest.restoreAllMocks());

  describe('cancel by the creator', () => {
    it('cancels with a full refund of escrow and fee, then notifies the owner', async () => {
      const t = build();
      const model = await t.service.cancel(CREATOR, COLLAB);

      expect(model.stage).toBe('CANCELLED');
      expect(t.ledgerPosts).toHaveLength(1);
      expect(t.ledgerPosts[0].key).toBe(`cancel:${COLLAB}`);
      expect(
        t.ledgerPosts[0].postings.map((p) => [p.debit, p.credit, p.amount]),
      ).toEqual([
        ['ESCROW', 'STORE_REFUND', 100000],
        ['FEE_REVENUE', 'STORE_REFUND', 10000],
      ]);
      expect(t.refundRequests).toEqual([
        { amount: 110000, key: `cancel-refund:${COLLAB}` },
      ]);
      expect(t.executed).toEqual(['refund-1']);
      expect(t.notified).toEqual([
        {
          userId: OWNER,
          role: 'STORE',
          kind: 'CREATOR_CANCELLED',
          actor: { userId: CREATOR, name: '모카', photoPath: null },
          params: { amount: 110000 },
          target: { kind: 'COLLABORATION', id: COLLAB },
          dedupeKey: `cancelled:${COLLAB}`,
        },
      ]);
    });

    it('cancels the deadline jobs with the same keys the funding path uses', async () => {
      const t = build();
      for (const key of [
        `refund-unsubmitted:${COLLAB}`,
        `submit-reminder:${COLLAB}:3`,
        `submit-reminder:${COLLAB}:1`,
      ]) {
        await t.scheduler.schedule(
          'submit-reminder',
          { collaborationId: COLLAB },
          new Date(T0.getTime() + DAY),
          key,
        );
      }
      await t.service.cancel(CREATOR, COLLAB);
      expect(t.scheduler.pending()).toEqual([]);
    });

    it('moves no money for a voucher-only offer and says nothing about a refund', async () => {
      const t = build();
      t.state.funded = false;
      t.collaborations.row = collaboration({ settlementMethod: 'NONE' });
      await t.service.cancel(CREATOR, COLLAB);
      expect(t.collaborations.row.stage).toBe('CANCELLED');
      expect(t.ledgerPosts).toEqual([]);
      expect(t.refundRequests).toEqual([]);
      expect(t.notified[0]).toMatchObject({
        kind: 'CREATOR_CANCELLED',
        params: { amount: 0 },
      });
    });

    it('refuses while counting and moves nothing', async () => {
      const t = build();
      t.collaborations.row = collaboration({ stage: 'COUNTING' });
      expect(await codeOf(t.service.cancel(CREATOR, COLLAB))).toBe('CONFLICT');
      expect(t.collaborations.row.stage).toBe('COUNTING');
      expect(t.ledgerPosts).toEqual([]);
      expect(t.notified).toEqual([]);
    });

    it('answers 403 to the owner and 404 to a stranger', async () => {
      const t = build();
      expect(await codeOf(t.service.cancel(OWNER, COLLAB))).toBe('FORBIDDEN');
      expect(await codeOf(t.service.cancel(STRANGER, COLLAB))).toBe(
        'NOT_FOUND',
      );
      expect(await codeOf(t.service.cancel(CREATOR, 'not-a-uuid'))).toBe(
        'NOT_FOUND',
      );
      expect(t.collaborations.row.stage).toBe('FUNDED');
    });

    it('does not move money twice when cancelled twice', async () => {
      const t = build();
      await t.service.cancel(CREATOR, COLLAB);
      expect(await codeOf(t.service.cancel(CREATOR, COLLAB))).toBe('CONFLICT');
      expect(t.ledgerPosts).toHaveLength(1);
      expect(t.refundRequests).toHaveLength(1);
      expect(t.notified).toHaveLength(1);
    });

    it('keeps the cancellation when the refund call or the notification fails', async () => {
      const t = build();
      jest.spyOn(Logger.prototype, 'error').mockImplementation();
      jest.spyOn(Logger.prototype, 'warn').mockImplementation();
      t.state.executeFails = true;
      t.state.notifyFails = true;
      const model = await t.service.cancel(CREATOR, COLLAB);
      expect(model.stage).toBe('CANCELLED');
      // 환급 행은 남아 운영 명령으로 다시 보낼 수 있다.
      expect(t.refundRequests).toHaveLength(1);
    });
  });

  describe('cancel requests', () => {
    it('lets the owner request for 3 days and schedules the expiry job', async () => {
      const t = build();
      const model = await t.service.requestCancel(OWNER, COLLAB);
      const expiresAt = new Date(T0.getTime() + 3 * DAY);
      expect(model.cancelRequest).toMatchObject({
        requestedByMe: true,
        expiresAt: expiresAt.toISOString(),
      });
      const request = t.requests.rows[0];
      expect(t.scheduler.pending()).toMatchObject([
        {
          name: 'cancel-request-expiry',
          jobKey: `cancel-request:${request.id}`,
          runAt: expiresAt,
          payload: { cancelRequestId: request.id },
        },
      ]);
      expect(t.notified).toEqual([
        {
          userId: CREATOR,
          role: 'CREATOR',
          kind: 'CANCEL_REQUESTED',
          actor: { userId: OWNER, name: '하루 한 컵', photoPath: null },
          target: { kind: 'COLLABORATION', id: COLLAB },
          dedupeKey: `cancel-requested:${request.id}`,
        },
      ]);
    });

    it('refuses a second pending request but allows one after the first expired', async () => {
      const t = build();
      await t.service.requestCancel(OWNER, COLLAB);
      expect(await codeOf(t.service.requestCancel(OWNER, COLLAB))).toBe(
        'CONFLICT',
      );
      t.clock.set(new Date(T0.getTime() + 3 * DAY));
      await t.service.requestCancel(OWNER, COLLAB);
      expect(t.requests.rows.map((r) => r.status)).toEqual([
        'EXPIRED',
        'PENDING',
      ]);
    });

    it('answers 403 to the creator and 409 once the link is submitted', async () => {
      const t = build();
      expect(await codeOf(t.service.requestCancel(CREATOR, COLLAB))).toBe(
        'FORBIDDEN',
      );
      t.collaborations.row = collaboration({ stage: 'COUNTING' });
      expect(await codeOf(t.service.requestCancel(OWNER, COLLAB))).toBe(
        'CONFLICT',
      );
      expect(t.requests.rows).toEqual([]);
    });

    it('lets the creator accept, which cancels like a direct cancel and marks the request ACCEPTED', async () => {
      const t = build();
      await t.service.requestCancel(OWNER, COLLAB);
      const request = t.requests.rows[0];
      expect(
        await codeOf(t.service.acceptCancel(OWNER, COLLAB, request.id)),
      ).toBe('FORBIDDEN');

      const model = await t.service.acceptCancel(CREATOR, COLLAB, request.id);
      expect(model.stage).toBe('CANCELLED');
      expect(t.requests.rows[0].status).toBe('ACCEPTED');
      expect(t.ledgerPosts[0].key).toBe(`cancel:${COLLAB}`);
      expect(t.refundRequests).toEqual([
        { amount: 110000, key: `cancel-refund:${COLLAB}` },
      ]);
      expect(t.notified.map((n) => [n.kind, n.userId, n.dedupeKey])).toEqual([
        ['CANCEL_REQUESTED', CREATOR, `cancel-requested:${request.id}`],
        ['CREATOR_CANCELLED', OWNER, `cancelled:${COLLAB}`],
      ]);
    });

    it('cannot accept an expired request or one from another collaboration', async () => {
      const t = build();
      await t.service.requestCancel(OWNER, COLLAB);
      const request = t.requests.rows[0];
      t.clock.set(new Date(T0.getTime() + 3 * DAY));
      expect(
        await codeOf(t.service.acceptCancel(CREATOR, COLLAB, request.id)),
      ).toBe('CONFLICT');
      expect(t.collaborations.row.stage).toBe('FUNDED');
      expect(t.ledgerPosts).toEqual([]);

      t.requests.rows[0] = {
        ...request,
        collaborationId: '77777777-7777-4777-8777-777777777777',
      };
      expect(
        await codeOf(t.service.acceptCancel(CREATOR, COLLAB, request.id)),
      ).toBe('NOT_FOUND');
    });

    it('expires only a pending request when the expiry job runs', async () => {
      const t = build();
      await t.service.requestCancel(OWNER, COLLAB);
      const request = t.requests.rows[0];
      await t.service.expireCancelRequest(request.id);
      expect(t.requests.rows[0].status).toBe('EXPIRED');

      t.requests.rows[0].status = 'ACCEPTED';
      await t.service.expireCancelRequest(request.id);
      expect(t.requests.rows[0].status).toBe('ACCEPTED');
    });
  });
});
