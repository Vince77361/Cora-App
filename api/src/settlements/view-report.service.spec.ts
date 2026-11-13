import { Collaboration, Settlement } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { JobScheduler } from '../jobs/job-scheduler';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { UsersService } from '../users/users.service';
import { PayoutsService } from './payouts.service';
import { RefundsService } from './refunds.service';
import { SettlementFinishService } from './settlement-finish.service';
import { NewSettlement, SettlementsRepository } from './settlements.repository';
import { ViewReportService } from './view-report.service';

const STORE = '11111111-1111-4111-8111-111111111111';
const CREATOR = '22222222-2222-4222-8222-222222222222';
const OTHER = '33333333-3333-4333-8333-333333333333';
const COLLAB = '44444444-4444-4444-8444-444444444444';
const SUBMITTED = new Date('2026-12-01T03:00:00.000Z');
const ENDS = new Date('2026-12-08T03:00:00.000Z');
const NOW = new Date('2026-12-08T03:00:00.000Z');
const HOUR = 60 * 60 * 1000;

class FixedClock extends Clock {
  now(): Date {
    return new Date(NOW);
  }
}

class Abort<R> extends Error {
  constructor(readonly result: R) {
    super('rollback');
  }
}

class FakeRepository extends SettlementsRepository {
  settlement: Settlement | null = null;
  created: NewSettlement[] = [];
  latest = new Map<string, number>();
  snapshots: { dayIndex: number; views: number | null }[] = [
    { dayIndex: 7, views: 12500 },
  ];
  constructor() {
    super(null as never);
  }
  async transaction<T, R>(
    run: (tx: never, rollback: (result: R) => never) => Promise<T>,
  ): Promise<T | R> {
    try {
      return await run({} as never, (result: R): never => {
        throw new Abort(result);
      });
    } catch (error) {
      if (error instanceof Abort) return error.result as R;
      throw error;
    }
  }
  lockCollaboration() {
    return Promise.resolve(true);
  }
  findSettlement() {
    return Promise.resolve(this.settlement);
  }
  listSnapshots() {
    return Promise.resolve(this.snapshots as never);
  }
  latestViewsFor() {
    return Promise.resolve(this.latest);
  }
  createSettlement(row: NewSettlement) {
    this.created.push(row);
    return Promise.resolve(true);
  }
}

class FakeCollaborations extends CollaborationsRepository {
  row: Collaboration = collaboration();
  constructor() {
    super(null as never, null as never);
  }
  findById() {
    return Promise.resolve(this.row);
  }
}

class FakeUsers extends UsersService {
  constructor() {
    super(null as never);
  }
  getRole() {
    return Promise.resolve('STORE' as const);
  }
}

function collaboration(over: Partial<Collaboration> = {}): Collaboration {
  return {
    id: COLLAB,
    kind: 'STORE_OFFER',
    stage: 'COUNTING',
    commissionerId: STORE,
    creatorId: CREATOR,
    offerId: null,
    storeId: null,
    terms: {
      format: 'REELS',
      voucherName: null,
      voucherValue: null,
      voucherPeople: null,
      fixedCash: 30000,
      viewRatePerThousand: 2000,
      perViewCap: 60000,
    },
    settlementMethod: 'FIXED_AND_PER_VIEW',
    fundedAt: SUBMITTED,
    submitDueAt: null,
    submittedUrl: 'https://www.instagram.com/reel/C8abc123/',
    submittedAt: SUBMITTED,
    countingEndsAt: ENDS,
    haltedReason: null,
    stageBeforeHalt: null,
    createdAt: SUBMITTED,
    updatedAt: SUBMITTED,
    deletedAt: null,
    ...over,
  };
}

function settlement(over: Partial<Settlement> = {}): Settlement {
  return {
    id: 's-1',
    collaborationId: COLLAB,
    finalViews: 12500,
    payoutAmount: 55000,
    refundAmount: 35000,
    settledAt: null,
    status: 'UNCONFIRMED',
    calculatedAt: NOW,
    confirmDueAt: new Date(NOW.getTime() + 48 * HOUR),
    confirmedAt: null,
    confirmedBy: null,
    evidenceSource: 'CONNECTED_ACCOUNT',
    fixedCashAmount: 30000,
    viewPayAmount: 25000,
    usualViews: null,
    multiplierTenths: null,
    usualReadAt: null,
    createdAt: NOW,
    updatedAt: NOW,
    deletedAt: null,
    ...over,
  };
}

describe('ViewReportService', () => {
  let repository: FakeRepository;
  let collaborations: FakeCollaborations;
  let service: ViewReportService;

  beforeEach(() => {
    repository = new FakeRepository();
    collaborations = new FakeCollaborations();
    service = new ViewReportService(
      repository,
      collaborations,
      null as unknown as LedgerService,
      null as unknown as PayoutsService,
      null as unknown as RefundsService,
      null as unknown as SettlementFinishService,
      null as unknown as NotificationsService,
      new FakeUsers(),
      null as unknown as JobScheduler,
      new FixedClock(),
    );
  });

  describe('createCalculation', () => {
    it('creates an unconfirmed row with the 48 hour due time and the split amounts', async () => {
      await expect(service.createCalculation(COLLAB)).resolves.toBe('created');
      expect(repository.created).toEqual([
        {
          collaborationId: COLLAB,
          finalViews: 12500,
          payoutAmount: 55000,
          refundAmount: 35000,
          fixedCashAmount: 30000,
          viewPayAmount: 25000,
          status: 'UNCONFIRMED',
          calculatedAt: NOW,
          confirmDueAt: new Date(NOW.getTime() + 48 * HOUR),
          settledAt: null,
          confirmedAt: null,
          confirmedBy: null,
        },
      ]);
    });

    it('does nothing when the collaboration is no longer counting', async () => {
      collaborations.row = collaboration({ stage: 'HALTED' });
      await expect(service.createCalculation(COLLAB)).resolves.toBe('gone');
      expect(repository.created).toEqual([]);
    });

    it('uses the last readable value when the last day could not be read', async () => {
      repository.snapshots = [
        { dayIndex: 6, views: 4000 },
        { dayIndex: 7, views: null },
      ];
      await service.createCalculation(COLLAB);
      expect(repository.created[0]).toMatchObject({
        finalViews: 4000,
        viewPayAmount: 8000,
        refundAmount: 52000,
      });
    });

    it('refuses to calculate when nothing was ever read', async () => {
      repository.snapshots = [{ dayIndex: 7, views: null }];
      await expect(service.createCalculation(COLLAB)).rejects.toThrow();
      expect(repository.created).toEqual([]);
    });

    it('refuses a collaboration without view pay', async () => {
      collaborations.row = collaboration({
        terms: { format: 'REELS', fixedCash: 30000 },
      });
      await expect(service.createCalculation(COLLAB)).rejects.toThrow();
    });
  });

  describe('get', () => {
    it('shows the running views and no calculation while counting', async () => {
      repository.latest.set(COLLAB, 3100);
      const view = await service.get(STORE, COLLAB);
      expect(view).toMatchObject({
        status: 'COUNTING',
        views: 3100,
        calc: null,
        confirmDueAt: null,
        canConfirm: false,
        source: 'CONNECTED_ACCOUNT',
        periodStart: SUBMITTED.toISOString(),
        periodEnd: ENDS.toISOString(),
      });
    });

    it('keeps a halted collaboration without a calculation as counting', async () => {
      collaborations.row = collaboration({
        stage: 'HALTED',
        haltedReason: 'VIEW_COUNT_UNAVAILABLE',
        stageBeforeHalt: 'COUNTING',
      });
      const view = await service.get(CREATOR, COLLAB);
      expect(view).toMatchObject({ status: 'COUNTING', calc: null });
    });

    it('shows the calculation and lets only the commissioner confirm', async () => {
      repository.settlement = settlement();
      const mine = await service.get(STORE, COLLAB);
      expect(mine).toMatchObject({
        status: 'UNCONFIRMED',
        views: 12500,
        canConfirm: true,
        confirmDueAt: new Date(NOW.getTime() + 48 * HOUR).toISOString(),
        calc: {
          viewPay: 25000,
          ratePerThousand: 2000,
          cap: 60000,
          capApplied: false,
          fixedCash: 30000,
          refund: 35000,
          payout: 55000,
        },
      });
      expect((await service.get(CREATOR, COLLAB)).canConfirm).toBe(false);
    });

    it('shows the cap as applied when the view pay hits it', async () => {
      repository.settlement = settlement({
        finalViews: 90000,
        viewPayAmount: 60000,
        payoutAmount: 90000,
        refundAmount: 0,
      });
      const view = await service.get(STORE, COLLAB);
      expect(view.calc).toMatchObject({
        viewPay: 60000,
        capApplied: true,
        refund: 0,
      });
    });

    it('does not let anyone confirm a capture based calculation', async () => {
      repository.settlement = settlement({ evidenceSource: 'CAPTURE' });
      const view = await service.get(STORE, COLLAB);
      expect(view).toMatchObject({
        source: 'CAPTURE_PENDING',
        canConfirm: false,
      });
    });

    it('reports a confirmed capture as confirmed', async () => {
      repository.settlement = settlement({
        evidenceSource: 'CAPTURE',
        status: 'CONFIRMED',
        settledAt: NOW,
      });
      collaborations.row = collaboration({ stage: 'SETTLED' });
      const view = await service.get(STORE, COLLAB);
      expect(view).toMatchObject({
        status: 'CONFIRMED',
        source: 'CAPTURE_CONFIRMED',
        confirmDueAt: null,
        canConfirm: false,
      });
    });

    it('returns 404 to someone who is not part of the collaboration', async () => {
      await expect(service.get(OTHER, COLLAB)).rejects.toMatchObject({
        code: 'NOT_FOUND',
      });
    });

    it('returns 404 without view pay or before the link is submitted', async () => {
      collaborations.row = collaboration({
        terms: { format: 'REELS', fixedCash: 30000 },
      });
      await expect(service.get(STORE, COLLAB)).rejects.toMatchObject({
        code: 'NOT_FOUND',
      });
      collaborations.row = collaboration({
        submittedUrl: null,
        submittedAt: null,
      });
      await expect(service.get(STORE, COLLAB)).rejects.toMatchObject({
        code: 'NOT_FOUND',
      });
    });

    it('returns 404 for a refunded collaboration that never had a calculation', async () => {
      collaborations.row = collaboration({ stage: 'REFUNDED' });
      await expect(service.get(STORE, COLLAB)).rejects.toMatchObject({
        code: 'NOT_FOUND',
      });
    });
  });

  describe('confirmByCommissioner', () => {
    it('refuses the creator with 403', async () => {
      repository.settlement = settlement();
      await expect(
        service.confirmByCommissioner(CREATOR, COLLAB),
      ).rejects.toMatchObject({ code: 'FORBIDDEN' });
    });

    it('refuses with 409 when there is nothing to confirm', async () => {
      await expect(
        service.confirmByCommissioner(STORE, COLLAB),
      ).rejects.toBeInstanceOf(AppError);
      await expect(
        service.confirmByCommissioner(STORE, COLLAB),
      ).rejects.toMatchObject({ code: 'CONFLICT' });
    });

    it('refuses with 409 for a capture based calculation', async () => {
      repository.settlement = settlement({ evidenceSource: 'CAPTURE' });
      await expect(
        service.confirmByCommissioner(STORE, COLLAB),
      ).rejects.toMatchObject({ code: 'CONFLICT' });
    });
  });
});
