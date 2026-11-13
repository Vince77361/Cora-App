import { Collaboration, Settlement, ViewEvidence } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { JobScheduler } from '../jobs/job-scheduler';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
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
  evidence: ViewEvidence | null = null;
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
  findEvidence() {
    return Promise.resolve(this.evidence);
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

function captureRow(): ViewEvidence {
  return {
    id: 'e-1',
    collaborationId: COLLAB,
    filePath: `evidence/${CREATOR}/55555555-5555-4555-8555-555555555555.jpg`,
    statedViews: 9800,
    submittedById: CREATOR,
    confirmedAt: null,
    confirmedBy: null,
    createdAt: NOW,
    updatedAt: NOW,
    deletedAt: null,
  };
}

describe('ViewReportService', () => {
  let repository: FakeRepository;
  let collaborations: FakeCollaborations;
  let storage: FakeStoragePort;
  let service: ViewReportService;

  beforeEach(() => {
    repository = new FakeRepository();
    collaborations = new FakeCollaborations();
    storage = new FakeStoragePort();
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
      null as unknown as OperatorAlertPort,
      storage,
      // 경로 검사(assertOwnedPath)는 진짜 규칙을 쓰고, 나머지 의존성은 쓰지 않는다.
      new UploadsService(null as never, storage, null as never),
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
          evidenceSource: 'CONNECTED_ACCOUNT',
        },
      ]);
    });

    it('calculates from the stated capture views without an auto confirm time', async () => {
      repository.snapshots = [{ dayIndex: 7, views: null }];
      await expect(
        service.createCalculation(COLLAB, { statedViews: 10000 }),
      ).resolves.toBe('created');
      expect(repository.created[0]).toMatchObject({
        finalViews: 10000,
        viewPayAmount: 20000,
        payoutAmount: 50000,
        refundAmount: 40000,
        status: 'UNCONFIRMED',
        evidenceSource: 'CAPTURE',
        confirmDueAt: null,
      });
    });

    it('does nothing when a calculation already exists once the lock is held', async () => {
      // 겹쳐 돈 두 번째 실행은 잠금을 잡은 채 INSERT로 가지 않고 되돌린다(이의·확인과의 교착 방지).
      repository.settlement = settlement();
      await expect(service.createCalculation(COLLAB)).resolves.toBe('exists');
      expect(repository.created).toEqual([]);
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

    it('shows a capture submitted before the calculation as pending', async () => {
      repository.evidence = captureRow();
      const view = await service.get(STORE, COLLAB);
      expect(view).toMatchObject({
        status: 'COUNTING',
        source: 'CAPTURE_PENDING',
      });
    });

    it('keeps the connected account as the source when a calculation from it exists despite a capture', async () => {
      repository.evidence = captureRow();
      repository.settlement = settlement();
      expect((await service.get(STORE, COLLAB)).source).toBe(
        'CONNECTED_ACCOUNT',
      );
      repository.settlement = settlement({
        status: 'CONFIRMED',
        settledAt: NOW,
      });
      collaborations.row = collaboration({ stage: 'SETTLED' });
      expect((await service.get(STORE, COLLAB)).source).toBe(
        'CONNECTED_ACCOUNT',
      );
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

  describe('get with dispute and capture', () => {
    it('lets either party dispute an unconfirmed calculation while counting', async () => {
      repository.settlement = settlement();
      expect((await service.get(STORE, COLLAB)).canDispute).toBe(true);
      expect((await service.get(CREATOR, COLLAB)).canDispute).toBe(true);
    });

    it('lets them dispute a capture based calculation too', async () => {
      repository.settlement = settlement({ evidenceSource: 'CAPTURE' });
      expect((await service.get(STORE, COLLAB)).canDispute).toBe(true);
    });

    it('does not let anyone dispute a disputed, confirmed or missing calculation', async () => {
      expect((await service.get(STORE, COLLAB)).canDispute).toBe(false);
      repository.settlement = settlement({ status: 'DISPUTED' });
      collaborations.row = collaboration({ stage: 'HALTED' });
      expect((await service.get(STORE, COLLAB)).canDispute).toBe(false);
      repository.settlement = settlement({ status: 'CONFIRMED' });
      collaborations.row = collaboration({ stage: 'SETTLED' });
      expect((await service.get(STORE, COLLAB)).canDispute).toBe(false);
    });

    it('signs the capture url for ten minutes and shows what the creator stated', async () => {
      repository.settlement = settlement({ evidenceSource: 'CAPTURE' });
      repository.evidence = {
        id: 'e-1',
        collaborationId: COLLAB,
        filePath: `evidence/${CREATOR}/55555555-5555-4555-8555-555555555555.jpg`,
        statedViews: 9800,
        submittedById: CREATOR,
        confirmedAt: null,
        confirmedBy: null,
        createdAt: NOW,
        updatedAt: NOW,
        deletedAt: null,
      };
      const view = await service.get(STORE, COLLAB);
      expect(view.evidence?.statedViews).toBe(9800);
      expect(view.evidence?.imageUrl).toContain('signed');
      expect(storage.signedReads).toEqual([
        { path: repository.evidence.filePath, ttlSeconds: 600 },
      ]);
    });

    it('still opens the report with a missing image url when signing fails', async () => {
      repository.settlement = settlement({ evidenceSource: 'CAPTURE' });
      repository.evidence = {
        id: 'e-1',
        collaborationId: COLLAB,
        filePath: `evidence/${CREATOR}/55555555-5555-4555-8555-555555555555.jpg`,
        statedViews: 9800,
        submittedById: CREATOR,
        confirmedAt: null,
        confirmedBy: null,
        createdAt: NOW,
        updatedAt: NOW,
        deletedAt: null,
      };
      storage.failSigning = true;
      const view = await service.get(STORE, COLLAB);
      expect(view.evidence).toEqual({ imageUrl: null, statedViews: 9800 });
      expect(view.status).toBe('UNCONFIRMED');
    });

    it('lets only the creator upload a capture, and only when the last three days could not be read', async () => {
      // 기간이 끝났으니(NOW = 종료 시각) 7일째를 읽어 보려 한 줄이 있어야 한다.
      repository.snapshots = [
        { dayIndex: 1, views: null },
        { dayIndex: 2, views: null },
        { dayIndex: 3, views: null },
        { dayIndex: 7, views: null },
      ];
      expect((await service.get(CREATOR, COLLAB)).canUploadEvidence).toBe(true);
      expect((await service.get(STORE, COLLAB)).canUploadEvidence).toBe(false);
      // 기간이 끝났어도 7일째를 읽어 보기 전에는 받지 않는다.
      repository.snapshots = [
        { dayIndex: 1, views: null },
        { dayIndex: 2, views: null },
        { dayIndex: 3, views: null },
      ];
      expect((await service.get(CREATOR, COLLAB)).canUploadEvidence).toBe(
        false,
      );
      // 측정 기간이 아직 남았다면 읽은 날이 끼어 있을 때 요청되지 않는다(기간이 끝나면 5~7일을 따로 본다).
      collaborations.row = collaboration({
        countingEndsAt: new Date(NOW.getTime() + 3 * 24 * HOUR),
      });
      repository.snapshots = [
        { dayIndex: 1, views: null },
        { dayIndex: 2, views: 100 },
        { dayIndex: 3, views: null },
      ];
      expect((await service.get(CREATOR, COLLAB)).canUploadEvidence).toBe(
        false,
      );
    });
  });

  describe('dispute', () => {
    it('refuses someone who is not part of the collaboration with 404', async () => {
      repository.settlement = settlement();
      await expect(
        service.dispute(OTHER, COLLAB, '조회수가 달라요'),
      ).rejects.toMatchObject({ code: 'NOT_FOUND' });
    });

    it('refuses an empty or over-long reason', async () => {
      repository.settlement = settlement();
      await expect(service.dispute(STORE, COLLAB, '   ')).rejects.toMatchObject(
        { code: 'VALIDATION_FAILED' },
      );
      await expect(
        service.dispute(STORE, COLLAB, 'a'.repeat(201)),
      ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    });

    it('refuses with 409 when there is nothing to dispute', async () => {
      await expect(
        service.dispute(STORE, COLLAB, '조회수가 달라요'),
      ).rejects.toMatchObject({ code: 'CONFLICT' });
      repository.settlement = settlement({ status: 'CONFIRMED' });
      await expect(
        service.dispute(STORE, COLLAB, '조회수가 달라요'),
      ).rejects.toMatchObject({ code: 'CONFLICT' });
    });
  });

  describe('submitEvidence', () => {
    const own = `evidence/${CREATOR}/55555555-5555-4555-8555-555555555555.jpg`;

    it('refuses the owner with 403', async () => {
      await expect(
        service.submitEvidence(STORE, COLLAB, { path: own, views: 100 }),
      ).rejects.toMatchObject({ code: 'FORBIDDEN' });
    });

    it('refuses a path under another user with 403', async () => {
      await expect(
        service.submitEvidence(CREATOR, COLLAB, {
          path: `evidence/${OTHER}/55555555-5555-4555-8555-555555555555.jpg`,
          views: 100,
        }),
      ).rejects.toMatchObject({ code: 'FORBIDDEN' });
      await expect(
        service.submitEvidence(CREATOR, COLLAB, {
          path: `stores/${CREATOR}/55555555-5555-4555-8555-555555555555.jpg`,
          views: 100,
        }),
      ).rejects.toMatchObject({ code: 'FORBIDDEN' });
    });

    it('refuses a capture path that was never uploaded', async () => {
      await expect(
        service.submitEvidence(CREATOR, COLLAB, { path: own, views: 100 }),
      ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    });

    it('refuses views that are not whole numbers', async () => {
      await expect(
        service.submitEvidence(CREATOR, COLLAB, { path: own, views: -1 }),
      ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
      await expect(
        service.submitEvidence(CREATOR, COLLAB, { path: own, views: 1.5 }),
      ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    });
  });
});
