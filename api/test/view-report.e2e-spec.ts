import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { CollaborationStage, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { scheduleSubmissionDeadlineJobs } from '../src/collaborations/collaboration-jobs';
import { Clock } from '../src/common/clock';
import { FakePaymentAdapter } from '../src/integrations/payment/fake-payment.adapter';
import { PaymentPort } from '../src/integrations/payment/payment.port';
import { OperatorAlertPort } from '../src/integrations/operator-alert/operator-alert.port';
import { StoragePort } from '../src/integrations/storage/storage.port';
import { FakePayoutAdapter } from '../src/integrations/payout/fake-payout.adapter';
import { PayoutPort } from '../src/integrations/payout/payout.port';
import { PushPort } from '../src/integrations/push/push.port';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { assertBalanced } from '../src/ledger/ledger-postings';
import { OpsRunner } from '../src/ops/ops.runner';
import { ViewReportService } from '../src/settlements/view-report.service';
import { createOffer } from './helpers/create-offer';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakeStoragePort } from './support/fake-storage.port';
import { FakePushPort } from './support/fake-push.port';
import { OTHER, USER_A } from './support/fake-token-verifier';

// user-a는 크리에이터, user-b(OTHER)는 가게 사장님이다.
const creator = { Authorization: 'Bearer user-a' };
const owner = { Authorization: 'Bearer user-b' };
// 한국 시간 낮 12시(화): 방해 금지 시간이 아니다.
const T0 = new Date('2026-12-01T03:00:00.000Z');
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const REELS_URL = 'https://www.instagram.com/reel/C8abc123/';
const WHO = ['--operator', '김운영', '--reason', '운영 확인 후 처리'];

interface Seeded {
  ownerId: string;
  creatorId: string;
  collaborationId: string;
}

jest.setTimeout(60000);

// 조회 자료 확인(F4): 7일째에는 계산만 만들고 장부를 옮기지 않으며, 사장님의 확인이나 48시간 뒤 자동 확인으로 정산한다.
describe('view report', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let scheduler: FakeJobScheduler;
  let push: FakePushPort;
  let pg: FakePaymentAdapter;
  let payoutPort: FakePayoutAdapter;
  let runner: OpsRunner;
  let storage: FakeStoragePort;
  let alert: jest.SpyInstance;

  const submit = (id: string, views: number | string = 12500) =>
    request(server)
      .post(`/collaborations/${id}/submission`)
      .set(creator)
      .send({ url: `${REELS_URL}?views=${views}` });
  const report = (id: string, as = owner) =>
    request(server).get(`/collaborations/${id}/view-report`).set(as);
  const confirm = (id: string, as = owner) =>
    request(server).post(`/collaborations/${id}/view-report/confirm`).set(as);
  const collaboration = (id: string, as = owner) =>
    request(server).get(`/collaborations/${id}`).set(as);
  const collaborationRow = (id: string) =>
    prisma.collaboration.findUniqueOrThrow({ where: { id } });
  const settlementOf = (id: string) =>
    prisma.settlement.findUniqueOrThrow({ where: { collaborationId: id } });
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
  const settleLines = async (id: string) =>
    (await ledgerOf(id)).filter((r) => r.idempotencyKey === `settle:${id}`);
  const notificationCount = (kind: string) =>
    prisma.notification.count({ where: { kind: kind as never } });
  const jobKeys = () => scheduler.pending().map((j) => j.jobKey);
  const dispute = (id: string, reason = '조회수가 실제와 달라요', as = owner) =>
    request(server)
      .post(`/collaborations/${id}/view-report/dispute`)
      .set(as)
      .send({ reason });
  const evidenceUpload = async (): Promise<string> => {
    const res = await request(server)
      .post('/uploads/photos')
      .set(creator)
      .send({
        purpose: 'VIEW_EVIDENCE',
        contentType: 'image/jpeg',
        sizeBytes: 2048,
      })
      .expect(201);
    return (res.body as { path: string }).path;
  };
  const sendEvidence = (
    id: string,
    path: string,
    views: number = 10000,
    as = creator,
  ) =>
    request(server)
      .post(`/collaborations/${id}/view-evidence`)
      .set(as)
      .send({ path, views });
  const reportBody = async (id: string, as = owner) =>
    (await report(id, as).expect(200)).body as {
      status: string;
      views: number | null;
      source: string;
      canConfirm: boolean;
      canDispute: boolean;
      canUploadEvidence: boolean;
      confirmDueAt: string | null;
      evidence: { imageUrl: string; statedViews: number } | null;
      calc: { payout: number; refund: number; viewPay: number } | null;
    };
  // 제출하고 조회수를 읽지 못하는 채로 지정한 날까지 매일 작업을 돌린다(0일부터 lastDay까지).
  async function submitUnreadableUntil(
    s: Seeded,
    lastDay: number,
  ): Promise<void> {
    await submit(s.collaborationId, 'unavailable').expect(200);
    for (let day = 0; day <= lastDay; day += 1) {
      clock.set(afterDays(day));
      await scheduler.runDue(clock.now());
    }
  }
  const afterDays = (days: number, hours = 0) =>
    new Date(T0.getTime() + days * DAY + hours * HOUR);

  // 제출하고 7일을 지나 계산까지 만든다(7일째 settle 작업).
  async function submitAndCalculate(
    s: Seeded,
    views: number | string = 12500,
  ): Promise<void> {
    await submit(s.collaborationId, views).expect(200);
    clock.set(afterDays(7));
    await scheduler.runDue(clock.now());
  }

  // 보관이 시작된 가게 오퍼 협업과 결제·장부를 DB에 바로 만든다. 기본은 1,000회당 2,000원, 상한 60,000원(수수료 10%).
  async function seed(
    over: {
      stage?: CollaborationStage;
      fixedCash?: number;
      viewPay?: boolean;
      ratePerThousand?: number;
      perViewCap?: number;
      ownerId?: string;
      creatorId?: string;
    } = {},
  ): Promise<Seeded> {
    const ownerId = over.ownerId ?? OTHER;
    const creatorId = over.creatorId ?? USER_A;
    const viewPay = over.viewPay !== false;
    const fixedCash = over.fixedCash ?? 0;
    const perViewCap = over.perViewCap ?? 60000;
    const escrow = fixedCash + (viewPay ? perViewCap : 0);
    const fee = Math.floor(escrow / 10);
    await prisma.user.upsert({
      where: { id: ownerId },
      update: { role: 'STORE' },
      create: { id: ownerId, role: 'STORE' },
    });
    const store = await prisma.store.create({
      data: {
        ownerId,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name: '하루 한 컵',
        neighborhood: '성수동',
        ...REGION,
        defaultFormat: 'REELS',
        publishedAt: T0,
      },
    });
    await prisma.user.upsert({
      where: { id: creatorId },
      update: { role: 'CREATOR' },
      create: { id: creatorId, role: 'CREATOR' },
    });
    await prisma.creatorProfile.upsert({
      where: { userId: creatorId },
      update: {},
      create: { userId: creatorId, displayName: '모카', ...REGION },
    });
    await prisma.instagramConnection.upsert({
      where: { creatorId },
      update: {},
      create: {
        creatorId,
        // 인스타그램 아이디는 계정마다 하나라 다른 크리에이터는 따로 만든다.
        handle:
          creatorId === USER_A ? 'moca_daily' : `moca_${creatorId.slice(0, 8)}`,
        followers: 1200,
        refreshedAt: T0,
      },
    });
    const columns = {
      format: 'REELS' as const,
      voucherName: null,
      voucherValue: null,
      voucherPeople: null,
      fixedCash,
      viewRatePerThousand: viewPay ? (over.ratePerThousand ?? 2000) : null,
      perViewCap: viewPay ? perViewCap : null,
      usageRights: 'STORE_REPOST_3M' as const,
    };
    const offer = await createOffer(prisma, {
      storeId: store.id,
      creatorId,
      ...columns,
      status: 'ACCEPTED',
      expiresAt: new Date(T0.getTime() + 7 * DAY),
      createdAt: T0,
      acceptedAt: T0,
    });
    const stage = over.stage ?? 'FUNDED';
    const counting = stage === 'COUNTING' || stage === 'HALTED';
    const row = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage,
        commissionerId: ownerId,
        creatorId,
        offerId: offer.id,
        storeId: store.id,
        terms: { ...columns, pieces: 1 },
        settlementMethod:
          fixedCash > 0 && viewPay
            ? 'FIXED_AND_PER_VIEW'
            : fixedCash > 0
              ? 'FIXED'
              : 'PER_VIEW',
        fundedAt: T0,
        submitDueAt: new Date(T0.getTime() + 14 * DAY),
        submittedUrl: counting ? REELS_URL : null,
        submittedAt: counting ? T0 : null,
        countingEndsAt: counting ? new Date(T0.getTime() + 7 * DAY) : null,
      },
    });
    const payment = await prisma.payment.create({
      data: {
        collaborationId: row.id,
        amountEscrow: escrow,
        amountFee: fee,
        feeRate: 10,
        method: 'CARD',
        status: 'APPROVED',
        pgTransactionId: `tx-${row.id}`,
        requestedAt: T0,
        approvedAt: T0,
      },
    });
    const batchId = randomUUID();
    await prisma.ledgerEntry.createMany({
      data: [
        ['ESCROW', escrow, 'PAYMENT_ESCROW'],
        ['FEE_REVENUE', fee, 'PAYMENT_FEE'],
      ].map(([credit, amount, reason]) => ({
        collaborationId: row.id,
        batchId,
        debitAccount: 'PG_IN' as const,
        creditAccount: credit as 'ESCROW',
        amount: amount as number,
        reason: reason as string,
        idempotencyKey: `payment:${payment.id}`,
      })),
    });
    if (stage === 'FUNDED') {
      await scheduleSubmissionDeadlineJobs(
        scheduler,
        row.id,
        new Date(T0.getTime() + 14 * DAY),
        T0,
      );
    }
    return { ownerId, creatorId, collaborationId: row.id };
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    scheduler = app.get<FakeJobScheduler>(JobScheduler);
    push = app.get<FakePushPort>(PushPort);
    pg = app.get<FakePaymentAdapter>(PaymentPort);
    payoutPort = app.get<FakePayoutAdapter>(PayoutPort);
    runner = app.get(OpsRunner);
    storage = app.get<FakeStoragePort>(StoragePort);
    alert = jest.spyOn(app.get(OperatorAlertPort), 'alert');
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    scheduler.jobs.length = 0;
    push.sent.length = 0;
    pg.refunds.length = 0;
    payoutPort.sent.length = 0;
    storage.signedReads.length = 0;
    storage.uploadUrlBuckets.length = 0;
    storage.uploadUrlPaths.length = 0;
    alert.mockClear();
    clock.set(T0);
  });
  afterEach(async () => {
    // 어떤 시나리오가 끝나도 모든 협업의 장부는 불변식을 지킨다.
    const rows = await prisma.ledgerEntry.findMany();
    const by = new Map<string, typeof rows>();
    for (const row of rows) {
      by.set(row.collaborationId, [
        ...(by.get(row.collaborationId) ?? []),
        row,
      ]);
    }
    for (const entries of by.values()) assertBalanced(entries);
  });
  afterAll(async () => {
    await prisma.$disconnect();
    await app.close();
  });

  describe('the calculation', () => {
    it('creates an unconfirmed calculation when the counting period ends', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'UNCONFIRMED',
        finalViews: 12500,
        payoutAmount: 25000,
        refundAmount: 35000,
        viewPayAmount: 25000,
        fixedCashAmount: 0,
        evidenceSource: 'CONNECTED_ACCOUNT',
        calculatedAt: afterDays(7),
        confirmDueAt: afterDays(7, 48),
        settledAt: null,
        confirmedAt: null,
        confirmedBy: null,
      });
    });

    it('splits fixed cash and view pay', async () => {
      const s = await seed({ fixedCash: 30000 });
      await submitAndCalculate(s);
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'UNCONFIRMED',
        payoutAmount: 55000,
        refundAmount: 35000,
        fixedCashAmount: 30000,
        viewPayAmount: 25000,
      });
    });

    it('moves no money before confirmation', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(60000);
      expect(await balanceOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(0);
      expect(await balanceOf(s.collaborationId, 'STORE_REFUND')).toBe(0);
      expect(await prisma.payout.count()).toBe(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(pg.refunds).toHaveLength(0);
    });

    it('asks the owner to confirm and tells the creator once', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      const requested = await prisma.notification.findMany({
        where: { kind: 'VIEW_REPORT_REQUESTED' },
      });
      expect(requested).toMatchObject([
        {
          userId: OTHER,
          role: 'STORE',
          targetKind: 'VIEW_REPORT',
          targetId: s.collaborationId,
        },
      ]);
      const ready = await prisma.notification.findMany({
        where: { kind: 'VIEW_REPORT_READY' },
      });
      expect(ready).toMatchObject([
        {
          userId: USER_A,
          role: 'CREATOR',
          targetKind: 'VIEW_REPORT',
          targetId: s.collaborationId,
        },
      ]);
      expect(jobKeys()).toContain(`auto-confirm:${s.collaborationId}`);
      expect(
        scheduler
          .pending()
          .find((j) => j.jobKey === `auto-confirm:${s.collaborationId}`)?.runAt,
      ).toEqual(afterDays(7, 48));

      // 정산 작업이 다시 돌아도 계산도 알림도 하나뿐이다.
      await scheduler.registry.run('settle', {
        collaborationId: s.collaborationId,
      });
      expect(await prisma.settlement.count()).toBe(1);
      expect(await notificationCount('VIEW_REPORT_REQUESTED')).toBe(1);
      expect(await notificationCount('VIEW_REPORT_READY')).toBe(1);
    });

    it('does not halt a collaboration that waits for confirmation when a late snapshot job finds nothing', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await prisma.viewSnapshot.updateMany({
        where: { collaborationId: s.collaborationId, dayIndex: { gte: 5 } },
        data: { views: null },
      });
      await scheduler.registry.run('view-snapshot', {
        collaborationId: s.collaborationId,
        dayIndex: 7,
      });
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      expect((await settlementOf(s.collaborationId)).status).toBe(
        'UNCONFIRMED',
      );
    });

    it('sends the settlement notices only after confirmation', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      expect(await notificationCount('SETTLEMENT_CONFIRMED')).toBe(0);
      expect(await notificationCount('SETTLEMENT_REFUNDED')).toBe(0);
      await confirm(s.collaborationId).expect(200);
      expect(await notificationCount('SETTLEMENT_CONFIRMED')).toBe(1);
      expect(await notificationCount('SETTLEMENT_REFUNDED')).toBe(1);
    });

    it('still confirms a fixed cash only collaboration in one step', async () => {
      const s = await seed({ viewPay: false, fixedCash: 30000 });
      await submit(s.collaborationId, 'ignored').expect(200);
      clock.set(afterDays(7));
      await scheduler.runDue(clock.now());
      expect((await collaborationRow(s.collaborationId)).stage).toBe('SETTLED');
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'CONFIRMED',
        confirmedBy: 'NOT_NEEDED',
        fixedCashAmount: 30000,
        viewPayAmount: 0,
        payoutAmount: 30000,
        settledAt: afterDays(7),
      });
      expect(await notificationCount('VIEW_REPORT_REQUESTED')).toBe(0);
      expect(jobKeys().some((k) => k.startsWith('auto-confirm:'))).toBe(false);
      await report(s.collaborationId).expect(404);
    });
  });

  describe('confirming', () => {
    it('settles when the owner confirms', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      clock.set(afterDays(7, 5));
      const res = await confirm(s.collaborationId).expect(200);
      expect(res.body).toMatchObject({
        status: 'CONFIRMED',
        canConfirm: false,
        confirmDueAt: null,
        calc: { payout: 25000, refund: 35000 },
      });
      expect((await collaborationRow(s.collaborationId)).stage).toBe('SETTLED');
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'CONFIRMED',
        confirmedBy: 'COMMISSIONER',
        confirmedAt: afterDays(7, 5),
        settledAt: afterDays(7, 5),
      });
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await balanceOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(25000);
      expect(await balanceOf(s.collaborationId, 'STORE_REFUND')).toBe(35000);
      expect(await prisma.payout.findMany()).toMatchObject([
        { amount: 25000, status: 'PENDING' },
      ]);
      expect(await prisma.refund.findMany()).toMatchObject([
        { amount: 35000, status: 'DONE' },
      ]);
      expect(pg.refunds).toHaveLength(1);
    });

    it('refuses a confirmation from the creator', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await confirm(s.collaborationId, creator).expect(403);
      expect((await settlementOf(s.collaborationId)).status).toBe(
        'UNCONFIRMED',
      );
    });

    it('refuses to confirm before there is a calculation', async () => {
      const s = await seed({ stage: 'COUNTING' });
      await confirm(s.collaborationId).expect(409);
      expect(await prisma.settlement.count()).toBe(0);
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
    });

    it('refuses to confirm twice', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await confirm(s.collaborationId).expect(200);
      await confirm(s.collaborationId).expect(409);
      expect(await prisma.payout.count()).toBe(1);
      expect(await prisma.refund.count()).toBe(1);
    });

    it('confirms by itself 48 hours after the calculation', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      clock.set(afterDays(7, 48));
      await scheduler.runDue(clock.now());
      expect((await collaborationRow(s.collaborationId)).stage).toBe('SETTLED');
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'CONFIRMED',
        confirmedBy: 'AUTO',
        settledAt: afterDays(7, 48),
      });
      expect(await balanceOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(25000);
      expect(await prisma.payout.count()).toBe(1);
      expect(await notificationCount('SETTLEMENT_CONFIRMED')).toBe(1);
    });

    it('does not confirm by itself at 47 hours', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      clock.set(afterDays(7, 47));
      await scheduler.runDue(clock.now());
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      expect((await settlementOf(s.collaborationId)).status).toBe(
        'UNCONFIRMED',
      );
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
      expect(jobKeys()).toContain(`auto-confirm:${s.collaborationId}`);
    });

    it('moves money once when the owner confirm and the auto confirm run together', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      clock.set(afterDays(7, 48));
      const [res] = await Promise.all([
        confirm(s.collaborationId),
        scheduler.runDue(clock.now()),
      ]);
      expect(res.status).toBe(200);
      expect((await collaborationRow(s.collaborationId)).stage).toBe('SETTLED');
      expect(await settleLines(s.collaborationId)).toHaveLength(2);
      expect(await balanceOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(25000);
      expect(await balanceOf(s.collaborationId, 'STORE_REFUND')).toBe(35000);
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await prisma.settlement.count()).toBe(1);
      expect(await prisma.payout.count()).toBe(1);
      expect(await prisma.refund.count()).toBe(1);
      expect(pg.refunds).toHaveLength(1);
      expect(await notificationCount('SETTLEMENT_CONFIRMED')).toBe(1);
      expect(await notificationCount('SETTLEMENT_REFUNDED')).toBe(1);
    });

    it('does nothing when the confirm job runs after the owner confirmed', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await confirm(s.collaborationId).expect(200);
      const lines = (await ledgerOf(s.collaborationId)).length;
      clock.set(afterDays(7, 48));
      await scheduler.runDue(clock.now());
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        confirmedBy: 'COMMISSIONER',
        settledAt: afterDays(7),
      });
      expect((await ledgerOf(s.collaborationId)).length).toBe(lines);
      expect(await prisma.payout.count()).toBe(1);
      expect(await prisma.refund.count()).toBe(1);
      expect(pg.refunds).toHaveLength(1);
      expect(await notificationCount('SETTLEMENT_CONFIRMED')).toBe(1);
      expect(await notificationCount('SETTLEMENT_REFUNDED')).toBe(1);
    });

    it('rolls the confirmation back when an operator halted the collaboration meanwhile', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: {
          stage: 'HALTED',
          stageBeforeHalt: 'COUNTING',
          haltedReason: 'OPERATOR_HALT',
        },
      });
      const outcome = await app
        .get(ViewReportService)
        .confirm(s.collaborationId, 'AUTO', `settle:${s.collaborationId}`);
      expect(outcome).toBe('lost');
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'UNCONFIRMED',
        settledAt: null,
        confirmedBy: null,
      });
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
      expect(await prisma.payout.count()).toBe(0);
      await confirm(s.collaborationId).expect(409);
    });

    it('does not confirm a calculation made from a capture by itself', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await prisma.settlement.update({
        where: { collaborationId: s.collaborationId },
        data: { evidenceSource: 'CAPTURE' },
      });
      await confirm(s.collaborationId).expect(409);
      clock.set(afterDays(7, 48));
      await scheduler.runDue(clock.now());
      expect((await settlementOf(s.collaborationId)).status).toBe(
        'UNCONFIRMED',
      );
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
    });
  });

  describe('reading the report', () => {
    it('shows the running views and no calculation while counting', async () => {
      const s = await seed();
      await submit(s.collaborationId, 3100).expect(200);
      clock.set(afterDays(3));
      await scheduler.runDue(clock.now());
      const res = await report(s.collaborationId).expect(200);
      expect(res.body).toMatchObject({
        status: 'COUNTING',
        views: 3100,
        postUrl: `${REELS_URL}?views=3100`,
        periodStart: T0.toISOString(),
        periodEnd: afterDays(7).toISOString(),
        source: 'CONNECTED_ACCOUNT',
        calc: null,
        confirmDueAt: null,
        canConfirm: false,
      });
    });

    it('shows the calculation to both sides and lets only the owner confirm', async () => {
      const s = await seed({ fixedCash: 30000 });
      await submitAndCalculate(s);
      const calc = {
        viewPay: 25000,
        ratePerThousand: 2000,
        cap: 60000,
        capApplied: false,
        fixedCash: 30000,
        refund: 35000,
        payout: 55000,
      };
      const mine = await report(s.collaborationId).expect(200);
      expect(mine.body).toMatchObject({
        status: 'UNCONFIRMED',
        views: 12500,
        calc,
        confirmDueAt: afterDays(7, 48).toISOString(),
        canConfirm: true,
      });
      const theirs = await report(s.collaborationId, creator).expect(200);
      expect(theirs.body).toMatchObject({
        status: 'UNCONFIRMED',
        calc,
        canConfirm: false,
      });
    });

    it('shows the cap as applied when the view pay hits it', async () => {
      const s = await seed();
      await submitAndCalculate(s, 90000);
      const res = await report(s.collaborationId).expect(200);
      expect(res.body).toMatchObject({
        views: 90000,
        calc: { viewPay: 60000, capApplied: true, refund: 0, payout: 60000 },
      });
    });

    it('keeps a collaboration stopped on unreadable views as counting without a calculation', async () => {
      const s = await seed({ stage: 'HALTED' });
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: {
          stageBeforeHalt: 'COUNTING',
          haltedReason: 'VIEW_COUNT_UNAVAILABLE',
        },
      });
      const res = await report(s.collaborationId).expect(200);
      expect(res.body).toMatchObject({
        status: 'COUNTING',
        views: null,
        calc: null,
        canConfirm: false,
      });
    });

    it('returns 404 for a view report of a collaboration I am not part of', async () => {
      const s = await seed({ ownerId: randomUUID(), creatorId: randomUUID() });
      await report(s.collaborationId, owner).expect(404);
      await report(s.collaborationId, creator).expect(404);
      await confirm(s.collaborationId, owner).expect(404);
      await report('not-a-uuid').expect(404);
    });

    it('returns 404 for a view report of a collaboration without view pay', async () => {
      const s = await seed({
        viewPay: false,
        fixedCash: 30000,
        stage: 'COUNTING',
      });
      await report(s.collaborationId).expect(404);
    });

    it('returns 404 before the link is submitted', async () => {
      const s = await seed();
      await report(s.collaborationId).expect(404);
    });

    it('reports the view report status on the collaboration', async () => {
      const s = await seed();
      const status = async (as = owner) =>
        (await collaboration(s.collaborationId, as).expect(200)).body as {
          viewReportStatus: string;
          settlement: unknown;
        };
      expect((await status()).viewReportStatus).toBe('NONE');
      await submit(s.collaborationId).expect(200);
      expect((await status()).viewReportStatus).toBe('COUNTING');
      clock.set(afterDays(7));
      await scheduler.runDue(clock.now());
      // 확인 전의 금액은 "정산"으로 보이지 않는다.
      expect(await status()).toMatchObject({
        viewReportStatus: 'UNCONFIRMED',
        settlement: null,
      });
      expect(await status(creator)).toMatchObject({
        viewReportStatus: 'UNCONFIRMED',
        settlement: null,
      });
      await confirm(s.collaborationId).expect(200);
      expect(await status()).toMatchObject({
        viewReportStatus: 'CONFIRMED',
        settlement: {
          finalViews: 12500,
          payoutAmount: 25000,
          refundAmount: 35000,
        },
      });
    });

    it('shows a held amount and no payout to the creator wallet before confirmation', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      const res = await request(server).get('/wallet').set(creator);
      expect(res.status).toBe(200);
      const body = res.body as {
        heldAmount: number;
        nextPayout: unknown;
        entries: { collaborationId: string; kind: string; amount: number }[];
      };
      expect(body.heldAmount).toBe(60000);
      expect(body.nextPayout).toBeNull();
      expect(
        body.entries.filter((e) => e.collaborationId === s.collaborationId),
      ).toMatchObject([{ kind: 'HELD', amount: 60000 }]);
    });
  });

  describe('disputing', () => {
    it('halts the collaboration and keeps the money when a party disputes', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      const res = await dispute(s.collaborationId).expect(200);
      expect(res.body).toMatchObject({
        status: 'DISPUTED',
        canConfirm: false,
        canDispute: false,
      });
      expect(await collaborationRow(s.collaborationId)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'COUNTING',
        haltedReason: 'SETTLEMENT_DISPUTED',
      });
      expect((await settlementOf(s.collaborationId)).status).toBe('DISPUTED');
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(60000);
      expect(await prisma.payout.count()).toBe(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(pg.refunds).toHaveLength(0);
      expect(
        await prisma.settlementDispute.findMany({
          where: { collaborationId: s.collaborationId },
        }),
      ).toMatchObject([
        {
          raisedById: s.ownerId,
          reason: '조회수가 실제와 달라요',
          resolvedAt: null,
          resolution: null,
        },
      ]);
    });

    it('lets the creator dispute too and tells the other side once', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await dispute(s.collaborationId, '낮게 읽힌 것 같아요', creator).expect(
        200,
      );
      const notices = await prisma.notification.findMany({
        where: { kind: 'VIEW_REPORT_DISPUTED' },
      });
      expect(notices).toMatchObject([
        {
          userId: s.ownerId,
          role: 'STORE',
          targetKind: 'VIEW_REPORT',
          targetId: s.collaborationId,
        },
      ]);
      expect((await reportBody(s.collaborationId)).status).toBe('DISPUTED');
    });

    it('cancels the auto confirm once disputed', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      expect(jobKeys()).toContain(`auto-confirm:${s.collaborationId}`);
      await dispute(s.collaborationId).expect(200);
      expect(jobKeys()).not.toContain(`auto-confirm:${s.collaborationId}`);
      clock.set(afterDays(7, 49));
      await scheduler.runDue(clock.now());
      expect((await settlementOf(s.collaborationId)).status).toBe('DISPUTED');
      expect((await collaborationRow(s.collaborationId)).stage).toBe('HALTED');
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
    });

    it('does nothing when an auto confirm job that was already running meets a disputed calculation', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await dispute(s.collaborationId).expect(200);
      await scheduler.registry.run('settlement-auto-confirm', {
        collaborationId: s.collaborationId,
      });
      expect((await settlementOf(s.collaborationId)).status).toBe('DISPUTED');
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
      expect(await notificationCount('SETTLEMENT_CONFIRMED')).toBe(0);
    });

    it('lets only one of a concurrent dispute and auto confirm win', async () => {
      for (let round = 0; round < 4; round += 1) {
        await truncateTestDb(prisma);
        scheduler.jobs.length = 0;
        clock.set(T0);
        const s = await seed();
        await submitAndCalculate(s);
        const [disputed] = await Promise.all([
          dispute(s.collaborationId),
          scheduler.registry.run('settlement-auto-confirm', {
            collaborationId: s.collaborationId,
          }),
        ]);
        const settlement = await settlementOf(s.collaborationId);
        const stage = (await collaborationRow(s.collaborationId)).stage;
        if (disputed.status === 200) {
          // 이의가 이겼다: 돈은 그대로 보관된다.
          expect(settlement.status).toBe('DISPUTED');
          expect(stage).toBe('HALTED');
          expect(await settleLines(s.collaborationId)).toHaveLength(0);
          expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(60000);
          expect(await prisma.payout.count()).toBe(0);
          expect(await prisma.refund.count()).toBe(0);
          expect(await prisma.settlementDispute.count()).toBe(1);
        } else {
          // 자동 확인이 이겼다: 이의는 409고 흔적이 없다. 돈은 한 번만 나간다.
          expect(disputed.status).toBe(409);
          expect(settlement.status).toBe('CONFIRMED');
          expect(stage).toBe('SETTLED');
          expect(await settleLines(s.collaborationId)).toHaveLength(2);
          expect(await prisma.payout.count()).toBe(1);
          expect(await prisma.refund.count()).toBe(1);
          expect(await prisma.settlementDispute.count()).toBe(0);
        }
      }
    });

    it('refuses a second dispute from the same person and a dispute after confirmation', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await dispute(s.collaborationId).expect(200);
      await dispute(s.collaborationId).expect(409);
      await dispute(s.collaborationId, '저도 이상해요', creator).expect(409);
      expect(await prisma.settlementDispute.count()).toBe(1);

      await truncateTestDb(prisma);
      scheduler.jobs.length = 0;
      clock.set(T0);
      const later = await seed();
      await submitAndCalculate(later);
      await confirm(later.collaborationId).expect(200);
      const res = await dispute(later.collaborationId).expect(409);
      expect((res.body as { error: { code: string } }).error.code).toBe(
        'CONFLICT',
      );
      expect((await settlementOf(later.collaborationId)).status).toBe(
        'CONFIRMED',
      );
      expect(await prisma.settlementDispute.count()).toBe(0);
    });

    it('refuses a dispute before there is a calculation', async () => {
      const s = await seed();
      await submit(s.collaborationId).expect(200);
      await dispute(s.collaborationId).expect(409);
    });

    it('alerts the operator without the dispute text', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      alert.mockClear();
      await dispute(s.collaborationId, '비밀 사유 글').expect(200);
      expect(alert).toHaveBeenCalledTimes(1);
      const [[sent]] = alert.mock.calls as [
        { subject: string; body: string },
      ][];
      expect(sent.subject).toBe(
        '조회 자료에 이의가 제기됐어요. 확인해 주세요.',
      );
      expect(sent.body).toContain(s.collaborationId);
      expect(JSON.stringify(sent)).not.toContain('비밀 사유 글');
    });

    it('answers 404 to someone outside the collaboration and 400 to a bad reason', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      const other = await seed({
        ownerId: '33333333-3333-4333-8333-333333333333',
        creatorId: '44444444-4444-4444-8444-444444444444',
      });
      await dispute(other.collaborationId).expect(404);
      await dispute(s.collaborationId, '').expect(400);
      await dispute(s.collaborationId, '   ').expect(400);
      await dispute(s.collaborationId, 'a'.repeat(201)).expect(400);
      expect((await settlementOf(s.collaborationId)).status).toBe(
        'UNCONFIRMED',
      );
    });
  });

  describe('capture', () => {
    it('asks the creator for a capture after three unreadable days instead of halting', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 2);
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      expect(await notificationCount('VIEW_EVIDENCE_REQUESTED')).toBe(1);
      expect(
        await prisma.notification.findMany({
          where: { kind: 'VIEW_EVIDENCE_REQUESTED' },
        }),
      ).toMatchObject([
        {
          userId: s.creatorId,
          role: 'CREATOR',
          targetKind: 'VIEW_REPORT',
          targetId: s.collaborationId,
        },
      ]);
      expect(alert).not.toHaveBeenCalled();
      // 더 읽지 못해도 알림은 한 건이다.
      clock.set(afterDays(3));
      await scheduler.runDue(clock.now());
      expect(await notificationCount('VIEW_EVIDENCE_REQUESTED')).toBe(1);
      expect(
        (await reportBody(s.collaborationId, creator)).canUploadEvidence,
      ).toBe(true);
      expect(
        (await reportBody(s.collaborationId, owner)).canUploadEvidence,
      ).toBe(false);
    });

    it('calculates from the capture when the period ends and waits for the operator', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 4);
      const path = await evidenceUpload();
      const sent = await sendEvidence(s.collaborationId, path, 10000).expect(
        200,
      );
      // 기간이 아직 남았으니 캡처만 받고 계산은 없다.
      expect(sent.body).toMatchObject({
        status: 'COUNTING',
        canUploadEvidence: false,
        evidence: { statedViews: 10000 },
      });
      expect(await prisma.settlement.count()).toBe(0);

      clock.set(afterDays(7));
      alert.mockClear();
      await scheduler.runDue(clock.now());
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'UNCONFIRMED',
        evidenceSource: 'CAPTURE',
        confirmDueAt: null,
        finalViews: 10000,
        viewPayAmount: 20000,
        payoutAmount: 20000,
        refundAmount: 40000,
      });
      expect(jobKeys()).not.toContain(`auto-confirm:${s.collaborationId}`);
      expect(jobKeys()).not.toContain(`evidence-halt:${s.collaborationId}`);
      expect(alert).toHaveBeenCalledTimes(1);
      expect((alert.mock.calls as [{ subject: string }][])[0][0].subject).toBe(
        '조회수 캡처가 제출됐어요. 확인해 주세요.',
      );
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      const view = await reportBody(s.collaborationId);
      expect(view).toMatchObject({
        status: 'UNCONFIRMED',
        source: 'CAPTURE_PENDING',
        canConfirm: false,
        canDispute: true,
        confirmDueAt: null,
        evidence: { statedViews: 10000 },
      });
      expect(view.evidence?.imageUrl).toContain(path);
    });

    it('calculates right away when the capture arrives after the period ended', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 7);
      expect(await prisma.settlement.count()).toBe(0);
      expect(jobKeys()).toContain(`evidence-halt:${s.collaborationId}`);
      clock.set(afterDays(8));
      alert.mockClear();
      const res = await sendEvidence(
        s.collaborationId,
        await evidenceUpload(),
        10000,
      ).expect(200);
      expect(res.body).toMatchObject({
        status: 'UNCONFIRMED',
        source: 'CAPTURE_PENDING',
      });
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        evidenceSource: 'CAPTURE',
        finalViews: 10000,
      });
      expect(jobKeys()).not.toContain(`evidence-halt:${s.collaborationId}`);
      expect(alert).toHaveBeenCalledTimes(1);
      // 기한(10일째)이 지나도 멈추지 않는다.
      clock.set(afterDays(11));
      await scheduler.runDue(clock.now());
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
    });

    it('does not confirm a capture based calculation by the owner or by time', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 7);
      await sendEvidence(s.collaborationId, await evidenceUpload()).expect(200);
      await confirm(s.collaborationId).expect(409);
      clock.set(afterDays(7, 49));
      await scheduler.runDue(clock.now());
      clock.set(afterDays(30));
      await scheduler.runDue(clock.now());
      expect((await settlementOf(s.collaborationId)).status).toBe(
        'UNCONFIRMED',
      );
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
      expect(await prisma.payout.count()).toBe(0);
    });

    it('halts three days after the period ends when no capture arrived', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 7);
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      expect(await prisma.settlement.count()).toBe(0);
      const job = scheduler
        .pending()
        .find((j) => j.jobKey === `evidence-halt:${s.collaborationId}`);
      expect(job?.name).toBe('evidence-missing-halt');
      expect(job?.runAt).toEqual(afterDays(10));
      clock.set(new Date(afterDays(10).getTime() - 1));
      await scheduler.runDue(clock.now());
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      clock.set(afterDays(10));
      alert.mockClear();
      await scheduler.runDue(clock.now());
      expect(await collaborationRow(s.collaborationId)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'COUNTING',
        haltedReason: 'VIEW_COUNT_UNAVAILABLE',
      });
      expect(alert).toHaveBeenCalledTimes(1);
      expect(await prisma.settlement.count()).toBe(0);
      expect(await balanceOf(s.collaborationId, 'ESCROW')).toBe(60000);
      expect(await notificationCount('COLLABORATION_HALTED')).toBe(2);
    });

    it('uses the connected account value when day seven can be read after all', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 3);
      expect(await notificationCount('VIEW_EVIDENCE_REQUESTED')).toBe(1);
      // 연결이 되살아나 4일째부터 읽힌다.
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: { submittedUrl: `${REELS_URL}?views=9000` },
      });
      for (let day = 4; day <= 7; day += 1) {
        clock.set(afterDays(day));
        await scheduler.runDue(clock.now());
      }
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'UNCONFIRMED',
        evidenceSource: 'CONNECTED_ACCOUNT',
        finalViews: 9000,
      });
      expect(jobKeys()).toContain(`auto-confirm:${s.collaborationId}`);
      expect(jobKeys()).not.toContain(`evidence-halt:${s.collaborationId}`);
      expect((await reportBody(s.collaborationId)).canConfirm).toBe(true);
    });

    it('refuses a capture from the owner and a capture path that is not mine', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 3);
      const mine = await evidenceUpload();
      await sendEvidence(s.collaborationId, mine, 100, owner).expect(403);
      const uuid = '55555555-5555-4555-8555-555555555555';
      for (const path of [
        `evidence/${s.ownerId}/${uuid}.jpg`,
        `creators/${s.creatorId}/${uuid}.jpg`,
        `evidence/${s.creatorId}/../${s.ownerId}/${uuid}.jpg`,
        `evidence/${s.creatorId}/${uuid}.gif`,
      ]) {
        const res = await sendEvidence(s.collaborationId, path, 100);
        expect([400, 403]).toContain(res.status);
      }
      expect(await prisma.viewEvidence.count()).toBe(0);
      await sendEvidence(s.collaborationId, mine, 100).expect(200);
    });

    it('refuses a capture when none was requested, a second one, and one after a calculation exists', async () => {
      const s = await seed();
      await submit(s.collaborationId, 5000).expect(200);
      const path = await evidenceUpload();
      // 읽을 수 있는 협업에는 캡처를 받지 않는다.
      await sendEvidence(s.collaborationId, path).expect(409);
      expect(await prisma.viewEvidence.count()).toBe(0);

      await truncateTestDb(prisma);
      scheduler.jobs.length = 0;
      clock.set(T0);
      const unreadable = await seed();
      await submitUnreadableUntil(unreadable, 3);
      await sendEvidence(unreadable.collaborationId, path).expect(200);
      await sendEvidence(unreadable.collaborationId, path).expect(409);
      expect(await prisma.viewEvidence.count()).toBe(1);

      await truncateTestDb(prisma);
      scheduler.jobs.length = 0;
      clock.set(T0);
      const settled = await seed();
      await submitAndCalculate(settled, 5000);
      await sendEvidence(settled.collaborationId, path).expect(409);
    });

    it('refuses views that are not a whole number of zero or more', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 3);
      const path = await evidenceUpload();
      await sendEvidence(s.collaborationId, path, -1).expect(400);
      await sendEvidence(s.collaborationId, path, 1.5).expect(400);
      await request(server)
        .post(`/collaborations/${s.collaborationId}/view-evidence`)
        .set(creator)
        .send({ path })
        .expect(400);
      expect(await prisma.viewEvidence.count()).toBe(0);
    });

    it('puts the capture in the private bucket and signs the read url only for the parties', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 3);
      const path = await evidenceUpload();
      expect(storage.uploadUrlBuckets).toEqual(['evidence']);
      expect(path.startsWith(`evidence/${s.creatorId}/`)).toBe(true);
      await sendEvidence(s.collaborationId, path).expect(200);
      for (const as of [creator, owner]) {
        const view = await reportBody(s.collaborationId, as);
        expect(view.evidence?.imageUrl).toContain('/signed/');
        expect(view.evidence?.imageUrl).toContain(path);
      }
      // 기한이 있는 주소(10분)이고, 공개 주소는 만들지 않는다.
      expect(storage.signedReads.every((r) => r.ttlSeconds === 600)).toBe(true);
      expect(storage.signedReads).toHaveLength(3);
      const stranger = await seed({
        ownerId: '33333333-3333-4333-8333-333333333333',
        creatorId: '44444444-4444-4444-8444-444444444444',
      });
      storage.signedReads.length = 0;
      await report(stranger.collaborationId).expect(404);
      await report(stranger.collaborationId, creator).expect(404);
      expect(storage.signedReads).toHaveLength(0);
    });

    it('does not show the capture to anyone outside the collaboration', async () => {
      const s = await seed();
      await submitUnreadableUntil(s, 3);
      await sendEvidence(s.collaborationId, await evidenceUpload()).expect(200);
      const text = JSON.stringify(
        (await report(s.collaborationId).expect(200)).body,
      );
      expect(text).not.toContain('submittedById');
      expect(text).not.toContain('filePath');
    });
  });

  describe('operator commands', () => {
    const ops = (...args: string[]) => runner.run([...args, ...WHO]);
    const text = (r: { output: string[] }) => r.output.join('\n');

    it('refuses to end an unconfirmed calculation outside the confirmation', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      const attempts = [
        ops(
          'force-payout',
          '--collaboration',
          s.collaborationId,
          '--amount',
          '1000',
        ),
        ops('force-refund', '--collaboration', s.collaborationId),
      ];
      for (const attempt of attempts) {
        const r = await attempt;
        expect(r.exitCode).toBe(1);
        expect(text(r)).toContain('resolve-dispute');
        expect(text(r)).toContain('confirm-evidence');
      }
      expect((await collaborationRow(s.collaborationId)).stage).toBe(
        'COUNTING',
      );
      expect(await settleLines(s.collaborationId)).toHaveLength(0);
      expect((await settlementOf(s.collaborationId)).status).toBe(
        'UNCONFIRMED',
      );
    });

    it('refuses to resume or settle a halted collaboration that has a disputed calculation', async () => {
      const s = await seed();
      await submitAndCalculate(s);
      await dispute(s.collaborationId).expect(200);
      for (const args of [
        ['resume', '--collaboration', s.collaborationId],
        [
          'force-payout',
          '--collaboration',
          s.collaborationId,
          '--amount',
          '1000',
        ],
        ['force-refund', '--collaboration', s.collaborationId],
      ]) {
        const r = await ops(...args);
        expect(r.exitCode).toBe(1);
        expect(text(r)).toContain('resolve-dispute');
      }
      expect((await collaborationRow(s.collaborationId)).stage).toBe('HALTED');
      expect(await prisma.payout.count()).toBe(0);
    });

    it('settles in one step with the operator as the confirmer when no calculation exists', async () => {
      const s = await seed({ stage: 'HALTED' });
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: {
          stageBeforeHalt: 'COUNTING',
          haltedReason: 'VIEW_COUNT_UNAVAILABLE',
        },
      });
      const r = await ops(
        'resume-settlement',
        '--collaboration',
        s.collaborationId,
        '--views',
        '12500',
      );
      expect(r.exitCode).toBe(0);
      expect((await collaborationRow(s.collaborationId)).stage).toBe('SETTLED');
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'CONFIRMED',
        confirmedBy: 'OPERATOR',
        payoutAmount: 25000,
        viewPayAmount: 25000,
        fixedCashAmount: 0,
      });
    });
  });
});
