import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import {
  CollaborationStage,
  Payment,
  PrismaClient,
  TransferStatus,
} from '@prisma/client';
import request from 'supertest';
import { scheduleSubmissionDeadlineJobs } from '../src/collaborations/collaboration-jobs';
import { Clock } from '../src/common/clock';
import { FakePaymentAdapter } from '../src/integrations/payment/fake-payment.adapter';
import { PaymentPort } from '../src/integrations/payment/payment.port';
import { FakePayoutAdapter } from '../src/integrations/payout/fake-payout.adapter';
import { PayoutPort } from '../src/integrations/payout/payout.port';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { assertBalanced } from '../src/ledger/ledger-postings';
import { LedgerService } from '../src/ledger/ledger.service';
import { PushPort } from '../src/integrations/push/push.port';
import { OpsRunner } from '../src/ops/ops.runner';
import { VIEW_COUNT_HALT_REASON } from '../src/settlements/job-keys';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
// 한국 시간 낮 12시(화): 방해 금지 시간이 아니다.
const T0 = new Date('2026-12-01T03:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const WHO = ['--operator', '김운영', '--reason', '운영 확인 후 처리'];

interface Seeded {
  collaborationId: string;
  paymentId: string;
  ownerId: string;
}

jest.setTimeout(60000);

// 운영 명령을 명령줄 그대로(OpsRunner.run) 실행해 DB·장부·작업 큐·포트의 결과를 확인한다.
describe('ops commands', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let clock: FakeClock;
  let scheduler: FakeJobScheduler;
  let push: FakePushPort;
  let pg: FakePaymentAdapter;
  let payoutPort: FakePayoutAdapter;
  let runner: OpsRunner;

  const ops = (...args: string[]) => runner.run(args);
  const withWho = (...args: string[]) => ops(...args, ...WHO);
  const collaborationOf = (id: string) =>
    prisma.collaboration.findUniqueOrThrow({ where: { id } });
  const audits = () =>
    prisma.opsAuditLog.findMany({ orderBy: { createdAt: 'asc' } });
  const ledgerOf = (id: string) =>
    prisma.ledgerEntry.findMany({ where: { collaborationId: id } });
  const balanceOf = async (id: string, account: string) =>
    (await ledgerOf(id)).reduce(
      (sum, r) =>
        sum +
        (r.creditAccount === account ? r.amount : 0) -
        (r.debitAccount === account ? r.amount : 0),
      0,
    );
  const jobKeys = () => scheduler.pending().map((j) => j.jobKey);
  const text = (r: { output: string[] }) => r.output.join('\n');

  async function expectEveryLedgerBalanced(): Promise<void> {
    const rows = await prisma.ledgerEntry.findMany();
    const by = new Map<string, typeof rows>();
    for (const row of rows) {
      by.set(row.collaborationId, [
        ...(by.get(row.collaborationId) ?? []),
        row,
      ]);
    }
    for (const entries of by.values()) assertBalanced(entries);
  }

  // 보관이 시작된 가게 오퍼 협업(상한 10만 원, 건당 10원, 수수료 1만 원)과 그 결제·장부를 DB에 바로 만든다.
  async function seed(stage: CollaborationStage = 'COUNTING'): Promise<Seeded> {
    const ownerId = randomUUID();
    await prisma.user.create({ data: { id: ownerId, role: 'STORE' } });
    const store = await prisma.store.create({
      data: {
        ownerId,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name: '하루 한 컵',
        neighborhood: '성수동',
        ...REGION,
        defaultFormat: 'REELS',
        defaultRewardType: 'BOTH',
        publishedAt: T0,
      },
    });
    await prisma.user.upsert({
      where: { id: USER_A },
      update: { role: 'CREATOR' },
      create: { id: USER_A, role: 'CREATOR' },
    });
    await prisma.creatorProfile.upsert({
      where: { userId: USER_A },
      update: {},
      create: { userId: USER_A, displayName: '모카', ...REGION },
    });
    await prisma.instagramConnection.upsert({
      where: { creatorId: USER_A },
      update: {},
      create: {
        creatorId: USER_A,
        handle: 'moca_daily',
        followers: 1200,
        refreshedAt: T0,
      },
    });
    const terms = {
      format: 'REELS' as const,
      rewardType: 'PER_VIEW' as const,
      voucherName: null,
      voucherValue: null,
      perViewAmount: 10,
      perViewCap: 100000,
    };
    const offer = await prisma.offer.create({
      data: {
        storeId: store.id,
        creatorId: USER_A,
        ...terms,
        status: 'ACCEPTED',
        expiresAt: new Date(T0.getTime() + 7 * DAY),
        createdAt: T0,
        acceptedAt: T0,
      },
    });
    const counting = stage === 'COUNTING' || stage === 'HALTED';
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage,
        commissionerId: ownerId,
        creatorId: USER_A,
        offerId: offer.id,
        storeId: store.id,
        terms,
        settlementMethod: 'PER_VIEW',
        fundedAt: T0,
        submitDueAt: new Date(T0.getTime() + 14 * DAY),
        submittedUrl: counting
          ? 'https://www.instagram.com/reel/C8abc123/'
          : null,
        submittedAt: counting ? T0 : null,
        countingEndsAt: counting ? new Date(T0.getTime() + 7 * DAY) : null,
      },
    });
    const payment = await prisma.payment.create({
      data: {
        collaborationId: collaboration.id,
        amountEscrow: 100000,
        amountFee: 10000,
        feeRate: 10,
        method: 'CARD',
        status: 'APPROVED',
        pgTransactionId: `tx-${collaboration.id}`,
        requestedAt: T0,
        approvedAt: T0,
      },
    });
    const batchId = randomUUID();
    await prisma.ledgerEntry.createMany({
      data: [
        ['ESCROW', 100000, 'PAYMENT_ESCROW'],
        ['FEE_REVENUE', 10000, 'PAYMENT_FEE'],
      ].map(([credit, amount, reason]) => ({
        collaborationId: collaboration.id,
        batchId,
        debitAccount: 'PG_IN' as const,
        creditAccount: credit as 'ESCROW',
        amount: amount as number,
        reason: reason as string,
        idempotencyKey: `payment:${payment.id}`,
      })),
    });
    return {
      collaborationId: collaboration.id,
      paymentId: payment.id,
      ownerId,
    };
  }

  const halted = (id: string, reason: string, before: CollaborationStage) =>
    prisma.collaboration.update({
      where: { id },
      data: { stage: 'HALTED', stageBeforeHalt: before, haltedReason: reason },
    });
  const registerAccount = (holderName = '김민지') =>
    request(httpOf(app))
      .put('/payout-account')
      .set(auth)
      .send({ bankCode: '004', accountNumber: '110123456789', holderName })
      .expect(200);

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    clock = app.get<FakeClock>(Clock);
    scheduler = app.get<FakeJobScheduler>(JobScheduler);
    push = app.get<FakePushPort>(PushPort);
    pg = app.get<FakePaymentAdapter>(PaymentPort);
    payoutPort = app.get<FakePayoutAdapter>(PayoutPort);
    runner = app.get(OpsRunner);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    scheduler.jobs.length = 0;
    push.sent.length = 0;
    pg.refunds.length = 0;
    payoutPort.sent.length = 0;
    clock.set(T0);
  });
  afterEach(async () => {
    // 어떤 명령이 끝나도(거절되어도) 모든 협업의 장부는 불변식을 지킨다.
    await expectEveryLedgerBalanced();
    jest.restoreAllMocks();
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  describe('input', () => {
    it('refuses a command without operator and reason before touching anything', async () => {
      const s = await seed();
      const noOperator = await ops(
        'halt',
        '--collaboration',
        s.collaborationId,
        '--reason',
        '확인',
      );
      expect(noOperator.exitCode).toBe(1);
      expect(text(noOperator)).toContain('--operator');
      const noReason = await ops(
        'halt',
        '--collaboration',
        s.collaborationId,
        '--operator',
        '김운영',
      );
      expect(noReason.exitCode).toBe(1);
      expect(text(noReason)).toContain('--reason');
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'COUNTING',
      });
      expect(await audits()).toHaveLength(0);
    });

    it('refuses unknown commands, bad ids and non-integer amounts', async () => {
      expect((await ops('erase-everything', ...WHO)).exitCode).toBe(1);
      expect((await withWho('halt', '--collaboration', 'abc')).exitCode).toBe(
        1,
      );
      const s = await seed();
      const bad = await withWho(
        'force-payout',
        '--collaboration',
        s.collaborationId,
        '--amount',
        '1.5',
      );
      expect(bad.exitCode).toBe(1);
      expect(
        (await withWho('halt', '--collaboration', randomUUID())).exitCode,
      ).toBe(1);
      expect(await audits()).toHaveLength(0);
    });
  });

  describe('halt and resume', () => {
    it('halts a counting collaboration and cancels its settle job', async () => {
      const s = await seed('COUNTING');
      const key = `settle:${s.collaborationId}`;
      await scheduler.schedule(
        'settle',
        { collaborationId: s.collaborationId },
        new Date(T0.getTime() + 7 * DAY),
        key,
      );
      const r = await withWho('halt', '--collaboration', s.collaborationId);
      expect(r.exitCode).toBe(0);
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'COUNTING',
      });
      expect(jobKeys()).not.toContain(key);
      const rows = await audits();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        command: 'halt',
        collaborationId: s.collaborationId,
        operator: '김운영',
        reason: '운영 확인 후 처리',
      });
      // 같은 명령을 또 실행해도 아무것도 바뀌지 않고 기록도 늘지 않는다.
      expect(
        (await withWho('halt', '--collaboration', s.collaborationId)).exitCode,
      ).toBe(1);
      expect(await audits()).toHaveLength(1);
      // 멈춘 협업의 돈은 그대로 보관 중이다.
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(100000);
    });

    it('refuses to halt a collaboration that holds no money', async () => {
      const s = await seed('AWAITING_PAYMENT');
      const r = await withWho('halt', '--collaboration', s.collaborationId);
      expect(r.exitCode).toBe(1);
      expect(await audits()).toHaveLength(0);
    });

    const jobAt = (name: string, key: string) =>
      scheduler.pending().find((j) => j.name === name && j.jobKey === key)
        ?.runAt;

    it('resumes a halted collaboration to its previous stage without settling early', async () => {
      const s = await seed('COUNTING');
      await withWho('halt', '--collaboration', s.collaborationId);
      const r = await withWho('resume', '--collaboration', s.collaborationId);
      expect(r.exitCode).toBe(0);
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'COUNTING',
        stageBeforeHalt: null,
        haltedReason: null,
      });
      // 집계 첫날에 재개: 정산은 원래 시각(7일째)이고 8번의 조회수 작업이 원래 시각으로 다시 올라간다.
      expect(jobAt('settle', `settle:${s.collaborationId}`)?.getTime()).toBe(
        T0.getTime() + 7 * DAY,
      );
      for (let day = 0; day <= 7; day += 1) {
        expect(
          jobAt(
            'view-snapshot',
            `view-snapshot:${s.collaborationId}:${day}`,
          )?.getTime(),
        ).toBe(T0.getTime() + day * DAY);
      }
      expect((await audits()).map((a) => a.command)).toEqual([
        'halt',
        'resume',
      ]);
    });

    it('resumes on day 4 by re-registering only the unrecorded snapshot days and settling on day 7', async () => {
      const s = await seed('COUNTING');
      await prisma.viewSnapshot.createMany({
        data: [0, 1, 2, 3].map((dayIndex) => ({
          collaborationId: s.collaborationId,
          dayIndex,
          views: 100 * (dayIndex + 1),
          takenAt: new Date(T0.getTime() + dayIndex * DAY),
        })),
      });
      await withWho('halt', '--collaboration', s.collaborationId);
      clock.set(new Date(T0.getTime() + 4 * DAY));
      await withWho('resume', '--collaboration', s.collaborationId);
      const snapshotKeys = scheduler
        .pending()
        .filter((j) => j.name === 'view-snapshot')
        .map((j) => j.jobKey)
        .sort();
      expect(snapshotKeys).toEqual(
        [4, 5, 6, 7].map((d) => `view-snapshot:${s.collaborationId}:${d}`),
      );
      expect(jobAt('settle', `settle:${s.collaborationId}`)?.getTime()).toBe(
        T0.getTime() + 7 * DAY,
      );
      // 아직 정산되지 않았다.
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'COUNTING',
      });
    });

    it('settles right away when a counting collaboration resumes after its settle time', async () => {
      const s = await seed('COUNTING');
      await withWho('halt', '--collaboration', s.collaborationId);
      clock.set(new Date(T0.getTime() + 8 * DAY));
      await withWho('resume', '--collaboration', s.collaborationId);
      expect(jobAt('settle', `settle:${s.collaborationId}`)?.getTime()).toBe(
        clock.now().getTime(),
      );
    });

    it('resumes a collaboration halted by a report the same way', async () => {
      const s = await seed('COUNTING');
      await halted(s.collaborationId, 'REPORT', 'COUNTING');
      const r = await withWho('resume', '--collaboration', s.collaborationId);
      expect(r.exitCode).toBe(0);
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'COUNTING',
      });
    });

    it('refuses to resume a collaboration that is not halted', async () => {
      const s = await seed('COUNTING');
      const r = await withWho('resume', '--collaboration', s.collaborationId);
      expect(r.exitCode).toBe(1);
      expect(await audits()).toHaveLength(0);
    });

    it('re-registers the submission deadline jobs when a funded collaboration resumes', async () => {
      const s = await seed('FUNDED');
      await scheduleSubmissionDeadlineJobs(
        scheduler,
        s.collaborationId,
        new Date(T0.getTime() + 14 * DAY),
        T0,
      );
      await withWho('halt', '--collaboration', s.collaborationId);
      expect(jobKeys().filter((k) => k.includes(s.collaborationId))).toEqual(
        [],
      );
      await withWho('resume', '--collaboration', s.collaborationId);
      expect(jobKeys().sort()).toEqual(
        [
          `refund-unsubmitted:${s.collaborationId}`,
          `submit-reminder:${s.collaborationId}:1`,
          `submit-reminder:${s.collaborationId}:3`,
        ].sort(),
      );
    });

    it('refunds right away when a collaboration resumes after its submission deadline', async () => {
      const s = await seed('FUNDED');
      await withWho('halt', '--collaboration', s.collaborationId);
      clock.set(new Date(T0.getTime() + 15 * DAY));
      await withWho('resume', '--collaboration', s.collaborationId);
      const due = scheduler
        .pending()
        .find((j) => j.name === 'refund-unsubmitted');
      expect(due).toBeDefined();
      await scheduler.runDue(clock.now());
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'REFUNDED',
      });
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0].amount).toBe(110000);
    });
  });

  describe('resume-settlement', () => {
    it('settles a view-count halt with the given views', async () => {
      const s = await seed('COUNTING');
      await halted(s.collaborationId, VIEW_COUNT_HALT_REASON, 'COUNTING');
      const r = await withWho(
        'resume-settlement',
        '--collaboration',
        s.collaborationId,
        '--views',
        '5000',
      );
      expect(r.exitCode).toBe(0);
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'SETTLED',
        haltedReason: null,
        stageBeforeHalt: null,
      });
      expect(
        await prisma.settlement.findFirstOrThrow({
          where: { collaborationId: s.collaborationId },
        }),
      ).toMatchObject({
        finalViews: 5000,
        payoutAmount: 50000,
        refundAmount: 50000,
      });
      expect(await prisma.payout.findMany()).toEqual([
        expect.objectContaining({ amount: 50000, status: 'PENDING' }),
      ]);
      expect(await prisma.refund.findMany()).toEqual([
        expect.objectContaining({ amount: 50000, status: 'DONE' }),
      ]);
      expect(pg.refunds).toHaveLength(1);
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await balanceOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(50000);
      expect(await balanceOf(s.collaborationId, 'STORE_REFUND')).toBe(50000);
      expect(push.sent.filter((p) => p.userId === USER_A)).toHaveLength(1);
      expect((await audits())[0]).toMatchObject({
        command: 'resume-settlement',
      });
      // 두 번 실행해도 지급·환급이 늘지 않는다.
      expect(
        (
          await withWho(
            'resume-settlement',
            '--collaboration',
            s.collaborationId,
            '--views',
            '5000',
          )
        ).exitCode,
      ).toBe(1);
      expect(await prisma.payout.count()).toBe(1);
      expect(await prisma.refund.count()).toBe(1);
    });

    it('caps the payout at the escrow and refuses a halt that was not a view-count halt', async () => {
      const s = await seed('COUNTING');
      await halted(s.collaborationId, 'OPERATOR_HALT', 'COUNTING');
      const refused = await withWho(
        'resume-settlement',
        '--collaboration',
        s.collaborationId,
        '--views',
        '5000',
      );
      expect(refused.exitCode).toBe(1);
      expect(await audits()).toHaveLength(0);

      await halted(s.collaborationId, VIEW_COUNT_HALT_REASON, 'COUNTING');
      await withWho(
        'resume-settlement',
        '--collaboration',
        s.collaborationId,
        '--views',
        '999999',
      );
      expect(await prisma.settlement.findFirstOrThrow()).toMatchObject({
        payoutAmount: 100000,
        refundAmount: 0,
      });
      expect(await prisma.refund.count()).toBe(0);
    });
  });

  describe('force-refund', () => {
    it('refunds cap and fee, ends the collaboration and writes an audit row', async () => {
      const s = await seed('COUNTING');
      await scheduler.schedule(
        'settle',
        { collaborationId: s.collaborationId },
        new Date(T0.getTime() + 7 * DAY),
        `settle:${s.collaborationId}`,
      );
      const r = await withWho(
        'force-refund',
        '--collaboration',
        s.collaborationId,
      );
      expect(r.exitCode).toBe(0);
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'REFUNDED',
      });
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await balanceOf(s.collaborationId, 'FEE_REVENUE')).toBe(0);
      expect(await balanceOf(s.collaborationId, 'STORE_REFUND')).toBe(110000);
      const refunds = await prisma.refund.findMany();
      expect(refunds).toEqual([
        expect.objectContaining({ amount: 110000, status: 'DONE' }),
      ]);
      expect(pg.refunds).toEqual([
        expect.objectContaining({
          amount: 110000,
          pgTransactionId: `tx-${s.collaborationId}`,
          idempotencyKey: `refund:${refunds[0].id}`,
        }),
      ]);
      expect(jobKeys()).toEqual([]);
      const rows = await audits();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        command: 'force-refund',
        operator: '김운영',
        reason: '운영 확인 후 처리',
        detail: expect.objectContaining({
          escrow: 100000,
          fee: 10000,
        }) as unknown,
      });
      // 두 번째 실행은 거절되고 환급은 한 번뿐이다.
      expect(
        (await withWho('force-refund', '--collaboration', s.collaborationId))
          .exitCode,
      ).toBe(1);
      expect(pg.refunds).toHaveLength(1);
      expect(await prisma.refund.count()).toBe(1);
    });

    it('refunds a halted collaboration and lets only one of two simultaneous commands win', async () => {
      const s = await seed('COUNTING');
      await withWho('halt', '--collaboration', s.collaborationId);
      const results = await Promise.all([
        withWho('force-refund', '--collaboration', s.collaborationId),
        withWho('force-refund', '--collaboration', s.collaborationId),
      ]);
      expect(results.map((r) => r.exitCode).sort()).toEqual([0, 1]);
      expect(await prisma.refund.count()).toBe(1);
      expect(await balanceOf(s.collaborationId, 'STORE_REFUND')).toBe(110000);
      expect(
        await prisma.opsAuditLog.count({ where: { command: 'force-refund' } }),
      ).toBe(1);
    });

    it('keeps the refund pending and tells the operator how to retry when the PG fails', async () => {
      const s = await seed('COUNTING');
      jest.spyOn(pg, 'refund').mockRejectedValueOnce(new Error('PG 연결 실패'));
      const r = await withWho(
        'force-refund',
        '--collaboration',
        s.collaborationId,
      );
      expect(r.exitCode).toBe(1);
      expect(text(r)).toMatch(/retry-refund --refund/);
      const refund = await prisma.refund.findFirstOrThrow();
      expect(refund.status).toBe('PENDING');
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'REFUNDED',
      });
      // retry-refund가 같은 키로 이어서 보낸다.
      const retried = await withWho('retry-refund', '--refund', refund.id);
      expect(retried.exitCode).toBe(0);
      expect(await prisma.refund.findFirstOrThrow()).toMatchObject({
        status: 'DONE',
      });
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0].idempotencyKey).toBe(`refund:${refund.id}`);
    });
  });

  describe('force-payout', () => {
    it('refuses a forced payout above the escrow balance', async () => {
      const s = await seed('COUNTING');
      const r = await withWho(
        'force-payout',
        '--collaboration',
        s.collaborationId,
        '--amount',
        '100001',
      );
      expect(r.exitCode).toBe(1);
      expect(text(r)).toContain('보관액');
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'COUNTING',
      });
      expect(await audits()).toHaveLength(0);
      expect(await prisma.payout.count()).toBe(0);
      expect(await ledgerOf(s.collaborationId)).toHaveLength(2);
    });

    it('pays within the escrow, refunds the rest and settles', async () => {
      const s = await seed('HALTED');
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: { stageBeforeHalt: 'COUNTING', haltedReason: 'OPERATOR_HALT' },
      });
      const r = await withWho(
        'force-payout',
        '--collaboration',
        s.collaborationId,
        '--amount',
        '30000',
      );
      expect(r.exitCode).toBe(0);
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'SETTLED',
        haltedReason: null,
      });
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await balanceOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(30000);
      expect(await balanceOf(s.collaborationId, 'STORE_REFUND')).toBe(70000);
      // 수수료는 정산처럼 수익으로 남는다.
      expect(await balanceOf(s.collaborationId, 'FEE_REVENUE')).toBe(10000);
      expect(await prisma.payout.findFirstOrThrow()).toMatchObject({
        amount: 30000,
        status: 'PENDING',
        idempotencyKey: `force-payout:${s.collaborationId}`,
      });
      expect(await prisma.refund.findFirstOrThrow()).toMatchObject({
        amount: 70000,
        status: 'DONE',
      });
      expect(await prisma.settlement.findFirstOrThrow()).toMatchObject({
        finalViews: null,
        payoutAmount: 30000,
        refundAmount: 70000,
      });
      expect(pg.refunds).toHaveLength(1);
      expect(push.sent.filter((p) => p.userId === USER_A)).toHaveLength(1);
      expect((await audits()).map((a) => a.command)).toEqual(['force-payout']);
      expect(
        (
          await withWho(
            'force-payout',
            '--collaboration',
            s.collaborationId,
            '--amount',
            '30000',
          )
        ).exitCode,
      ).toBe(1);
      expect(await prisma.payout.count()).toBe(1);
    });

    it('rejects a zero amount and points to force-refund', async () => {
      const s = await seed('COUNTING');
      const r = await withWho(
        'force-payout',
        '--collaboration',
        s.collaborationId,
        '--amount',
        '0',
      );
      expect(r.exitCode).toBe(1);
      expect(text(r)).toContain('force-refund');
    });
  });

  describe('retry-payout and retry-refund', () => {
    const failedPayout = async (
      collaborationId: string,
      status: TransferStatus = 'FAILED',
    ) =>
      prisma.payout.create({
        data: {
          collaborationId,
          amount: 50000,
          status,
          idempotencyKey: `settle-payout:${collaborationId}`,
          scheduledFor: new Date(T0.getTime() - DAY),
        },
      });

    it('sends a failed payout again with the same key and refuses one that is not failed', async () => {
      const s = await seed('SETTLED');
      await registerAccount();
      const payout = await failedPayout(s.collaborationId);
      const r = await withWho('retry-payout', '--payout', payout.id);
      expect(r.exitCode).toBe(0);
      expect(
        await prisma.payout.findUniqueOrThrow({ where: { id: payout.id } }),
      ).toMatchObject({ status: 'DONE' });
      expect(payoutPort.sent).toEqual([
        expect.objectContaining({
          amount: 50000,
          idempotencyKey: `payout:${payout.id}`,
        }),
      ]);
      expect((await audits())[0]).toMatchObject({
        command: 'retry-payout',
        collaborationId: s.collaborationId,
      });
      expect(
        (await withWho('retry-payout', '--payout', payout.id)).exitCode,
      ).toBe(1);
      expect(payoutPort.sent).toHaveLength(1);
    });

    it('marks the payout failed again and warns when the bank rejects it again', async () => {
      const s = await seed('SETTLED');
      await registerAccount('fail 김민지');
      const payout = await failedPayout(s.collaborationId);
      const r = await withWho('retry-payout', '--payout', payout.id);
      expect(r.exitCode).toBe(1);
      expect(text(r)).toContain('다시 실패');
      expect(
        await prisma.payout.findUniqueOrThrow({ where: { id: payout.id } }),
      ).toMatchObject({ status: 'FAILED' });
    });

    it('sends pending and failed refunds again with the same key and refuses a finished one', async () => {
      const s = await seed('REFUNDED');
      const refund = await prisma.refund.create({
        data: {
          collaborationId: s.collaborationId,
          amount: 50000,
          status: 'FAILED',
          idempotencyKey: `settle-refund:${s.collaborationId}`,
        },
      });
      const r = await withWho('retry-refund', '--refund', refund.id);
      expect(r.exitCode).toBe(0);
      expect(
        await prisma.refund.findUniqueOrThrow({ where: { id: refund.id } }),
      ).toMatchObject({ status: 'DONE' });
      expect(pg.refunds).toEqual([
        expect.objectContaining({
          amount: 50000,
          idempotencyKey: `refund:${refund.id}`,
        }),
      ]);
      expect(
        (await withWho('retry-refund', '--refund', refund.id)).exitCode,
      ).toBe(1);
      expect(pg.refunds).toHaveLength(1);
      expect((await audits()).map((a) => a.command)).toEqual(['retry-refund']);
    });
  });

  describe('refund-payment', () => {
    const secondPayment = (
      collaborationId: string,
      over: Partial<Payment> = {},
    ) =>
      prisma.payment.create({
        data: {
          collaborationId,
          amountEscrow: 100000,
          amountFee: 10000,
          feeRate: 10,
          method: 'CARD',
          status: 'APPROVED',
          pgTransactionId: `late-${randomUUID()}`,
          requestedAt: T0,
          approvedAt: new Date(T0.getTime() + 60 * 60 * 1000),
          ...over,
        },
      });

    it('refunds a late approved payment without touching the collaboration or its escrow', async () => {
      const s = await seed('COUNTING');
      const late = await secondPayment(s.collaborationId);
      const r = await withWho('refund-payment', '--payment', late.id);
      expect(r.exitCode).toBe(0);
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'COUNTING',
      });
      // 원래 보관액은 그대로이고, 이 결제의 돈은 들어왔다 바로 나갔다.
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(100000);
      expect(await balanceOf(s.collaborationId, 'FEE_REVENUE')).toBe(10000);
      expect(await balanceOf(s.collaborationId, 'STORE_REFUND')).toBe(110000);
      const keys = (await ledgerOf(s.collaborationId)).map(
        (l) => l.idempotencyKey,
      );
      expect(keys).toEqual(
        expect.arrayContaining([
          `payment:${late.id}`,
          `late-refund:${late.id}`,
        ]),
      );
      const refund = await prisma.refund.findFirstOrThrow();
      expect(refund).toMatchObject({
        amount: 110000,
        status: 'DONE',
        idempotencyKey: `late-refund:${late.id}`,
      });
      expect(pg.refunds).toEqual([
        expect.objectContaining({
          amount: 110000,
          pgTransactionId: late.pgTransactionId,
          idempotencyKey: `refund:${refund.id}`,
        }),
      ]);
      expect((await audits())[0]).toMatchObject({ command: 'refund-payment' });
      // 이미 환불한 결제는 다시 환불하지 않는다.
      expect(
        (await withWho('refund-payment', '--payment', late.id)).exitCode,
      ).toBe(1);
      expect(pg.refunds).toHaveLength(1);
    });

    it('refuses the payment that funded the collaboration and payments that are not approved', async () => {
      const s = await seed('COUNTING');
      const funding = await withWho('refund-payment', '--payment', s.paymentId);
      expect(funding.exitCode).toBe(1);
      expect(text(funding)).toContain('force-refund');
      const pending = await secondPayment(s.collaborationId, {
        status: 'PENDING',
        pgTransactionId: null,
        approvedAt: null,
      });
      expect(
        (await withWho('refund-payment', '--payment', pending.id)).exitCode,
      ).toBe(1);
      expect(await audits()).toHaveLength(0);
      expect(await prisma.refund.count()).toBe(0);
    });

    it('refunds an approved payment of a collaboration that already ended', async () => {
      const s = await seed('CANCELLED');
      await prisma.ledgerEntry.deleteMany();
      await prisma.payment.deleteMany();
      const late = await secondPayment(s.collaborationId);
      const r = await withWho('refund-payment', '--payment', late.id);
      expect(r.exitCode).toBe(0);
      expect(await balanceOf(s.collaborationId, 'STORE_REFUND')).toBe(110000);
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(0);
    });
  });

  describe('show', () => {
    it('prints stage, ledger balances and payments, payouts and refunds without account numbers or audit rows', async () => {
      const s = await seed('SETTLED');
      await registerAccount();
      const payout = await prisma.payout.create({
        data: {
          collaborationId: s.collaborationId,
          amount: 50000,
          status: 'FAILED',
          idempotencyKey: 'p1',
          scheduledFor: T0,
        },
      });
      const refund = await prisma.refund.create({
        data: {
          collaborationId: s.collaborationId,
          amount: 7,
          status: 'PENDING',
          idempotencyKey: 'r1',
        },
      });
      const r = await ops('show', '--collaboration', s.collaborationId);
      expect(r.exitCode).toBe(0);
      const out = text(r);
      expect(out).toContain('SETTLED');
      expect(out).toMatch(/ESCROW\s+100,000원/);
      expect(out).toMatch(/FEE_REVENUE\s+10,000원/);
      expect(out).toContain(`${s.paymentId} APPROVED`);
      expect(out).toContain('[보관을 시작시킨 결제]');
      expect(out).toContain(`${payout.id} FAILED 50,000원`);
      expect(out).toContain(`${refund.id} PENDING 7원`);
      expect(out).not.toContain('110123456789');
      expect(out).not.toContain('6789');
      expect(await audits()).toHaveLength(0);
      expect(
        (await ops('show', '--collaboration', randomUUID())).exitCode,
      ).toBe(1);
      // 읽기 전용이라 operator·reason을 받지 않는다.
      expect(
        (await ops('show', '--collaboration', s.collaborationId, ...WHO))
          .exitCode,
      ).toBe(1);
    });
  });

  describe('ledger check', () => {
    it('rolls every change back when the closing ledger check fails', async () => {
      const s = await seed('COUNTING');
      jest
        .spyOn(app.get(LedgerService), 'assertCollaborationBalanced')
        .mockRejectedValueOnce(new Error('장부 오류: 가짜 불일치'));
      await expect(
        withWho('force-refund', '--collaboration', s.collaborationId),
      ).rejects.toThrow('가짜 불일치');
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'COUNTING',
      });
      expect(await ledgerOf(s.collaborationId)).toHaveLength(2);
      expect(await prisma.refund.count()).toBe(0);
      expect(await audits()).toHaveLength(0);
      expect(pg.refunds).toHaveLength(0);
    });

    it('checks every collaboration and reports the ones that do not balance', async () => {
      const a = await seed('COUNTING');
      const b = await seed('COUNTING');
      const ledger = app.get(LedgerService);
      await expect(ledger.checkAll()).resolves.toEqual({
        checked: 2,
        failures: [],
      });
      // 운영자가 DB를 직접 고쳐 없는 돈을 내보낸 것처럼 에스크로 밖으로 줄을 하나 더하면 그 협업만 어긋난다.
      await prisma.ledgerEntry.create({
        data: {
          collaborationId: b.collaborationId,
          batchId: randomUUID(),
          debitAccount: 'ESCROW',
          creditAccount: 'STORE_REFUND',
          amount: 200000,
          reason: 'HAND_EDIT',
          idempotencyKey: 'hand-edit',
        },
      });
      const result = await ledger.checkAll();
      expect(result.checked).toBe(2);
      expect(result.failures).toHaveLength(1);
      expect(result.failures[0].collaborationId).toBe(b.collaborationId);
      expect(result.failures[0].collaborationId).not.toBe(a.collaborationId);
      // 이 시나리오의 afterEach 검산이 통과하도록 되돌린다.
      await prisma.ledgerEntry.deleteMany({
        where: { collaborationId: b.collaborationId },
      });
    });
  });
});
