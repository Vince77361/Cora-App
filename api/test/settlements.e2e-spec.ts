import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import {
  CollaborationStage,
  ContentFormat,
  PrismaClient,
  RewardType,
} from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { AppError } from '../src/common/errors/app-error';
import { FakePaymentAdapter } from '../src/integrations/payment/fake-payment.adapter';
import { PaymentPort } from '../src/integrations/payment/payment.port';
import { FakePayoutAdapter } from '../src/integrations/payout/fake-payout.adapter';
import { PayoutPort } from '../src/integrations/payout/payout.port';
import { assertBalanced } from '../src/ledger/ledger-postings';
import { PayoutAccountsService } from '../src/payout-accounts/payout-accounts.service';
import { RefundsService } from '../src/settlements/refunds.service';
import { OperatorAlertPort } from '../src/integrations/operator-alert/operator-alert.port';
import {
  ViewCountPort,
  ViewCountUnavailableError,
} from '../src/integrations/view-count/view-count.port';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { PushPort } from '../src/integrations/push/push.port';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
// 한국 시간 낮 12시(화): 방해 금지 시간이 아니라 푸시가 나간다.
const T0 = new Date('2026-12-01T03:00:00.000Z');
const MINUTE = 60 * 1000;
const DAY = 24 * 60 * MINUTE;
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const REELS_URL = 'https://www.instagram.com/reel/C8abc123/';

interface Seeded {
  ownerId: string;
  storeId: string;
  creatorId: string;
  offerId: string;
  collaborationId: string;
}

// 협업 하나를 제출·정산까지 돌리는 시나리오가 원격 DB에 여러 번 쓰므로 기본 5초로는 모자란다.
jest.setTimeout(30000);

describe('settlements', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let scheduler: FakeJobScheduler;
  let push: FakePushPort;
  let alert: jest.SpyInstance;
  let pg: FakePaymentAdapter;
  let payoutPort: FakePayoutAdapter;

  const submit = (collaborationId: string, url: string) =>
    request(server)
      .post(`/collaborations/${collaborationId}/submission`)
      .set(auth)
      .send({ url });
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const messageOf = (res: request.Response) =>
    (res.body as { error: { message: string } }).error.message;
  const collaborationOf = (id: string) =>
    prisma.collaboration.findUniqueOrThrow({ where: { id } });
  const snapshotsOf = (id: string) =>
    prisma.viewSnapshot.findMany({
      where: { collaborationId: id },
      orderBy: { dayIndex: 'asc' },
    });
  const jobKeys = () => scheduler.pending().map((j) => j.jobKey);
  const ledgerOf = (id: string) =>
    prisma.ledgerEntry.findMany({
      where: { collaborationId: id },
      orderBy: { createdAt: 'asc' },
    });
  async function expectEveryLedgerBalanced(): Promise<void> {
    const rows = await prisma.ledgerEntry.findMany();
    const byCollaboration = new Map<string, typeof rows>();
    for (const row of rows) {
      byCollaboration.set(row.collaborationId, [
        ...(byCollaboration.get(row.collaborationId) ?? []),
        row,
      ]);
    }
    for (const entries of byCollaboration.values()) assertBalanced(entries);
  }
  const accountOf = (collaborationId: string, account: string) =>
    ledgerOf(collaborationId).then((rows) =>
      rows.reduce(
        (sum, r) =>
          sum +
          (r.creditAccount === account ? r.amount : 0) -
          (r.debitAccount === account ? r.amount : 0),
        0,
      ),
    );
  const registerAccount = (holderName = '김민지') =>
    request(server)
      .put('/payout-account')
      .set(auth)
      .send({ bankCode: '004', accountNumber: '110123456789', holderName })
      .expect(200);
  // 제출하고 7일을 지나 정산까지 돌린다.
  async function submitAndSettle(
    s: Seeded,
    views: number | string,
  ): Promise<void> {
    await submit(s.collaborationId, `${REELS_URL}?views=${views}`).expect(200);
    clock.set(new Date(T0.getTime() + 7 * DAY));
    await scheduler.runDue(clock.now());
  }
  const settleJob = (id: string) =>
    ({ name: 'settle', payload: { collaborationId: id } }) as const;
  const pushTo = (userId: string) =>
    push.sent.filter((p) => p.userId === userId);

  // 크리에이터는 로그인한 USER_A다. 사장님은 따로 만든다. 협업은 보관이 시작된(FUNDED) 상태로 DB에 바로 만들고,
  // 장부와 결제도 결제 승인 직후와 같게 채운다(상한 = 에스크로, 수수료 10%).
  async function seed(
    over: {
      stage?: CollaborationStage;
      format?: ContentFormat;
      rewardType?: RewardType;
      perViewAmount?: number;
      perViewCap?: number;
      connected?: boolean;
    } = {},
  ): Promise<Seeded> {
    const rewardType = over.rewardType ?? 'BOTH';
    const perView = rewardType !== 'VOUCHER';
    const perViewAmount = over.perViewAmount ?? 10;
    const perViewCap = over.perViewCap ?? 100000;
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
    if (perView && over.connected !== false) {
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
    }
    const terms = {
      format: over.format ?? 'REELS',
      rewardType,
      voucherName: rewardType === 'PER_VIEW' ? null : '2인 식사권',
      voucherValue: rewardType === 'PER_VIEW' ? null : 40000,
      perViewAmount: perView ? perViewAmount : null,
      perViewCap: perView ? perViewCap : null,
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
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: over.stage ?? 'FUNDED',
        commissionerId: ownerId,
        creatorId: USER_A,
        offerId: offer.id,
        storeId: store.id,
        terms,
        settlementMethod: perView ? 'PER_VIEW' : 'NONE',
        fundedAt: T0,
        submitDueAt: new Date(T0.getTime() + 14 * DAY),
      },
    });
    if (perView) {
      const fee = Math.floor(perViewCap / 10);
      const payment = await prisma.payment.create({
        data: {
          collaborationId: collaboration.id,
          amountEscrow: perViewCap,
          amountFee: fee,
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
          ['PG_IN', 'ESCROW', perViewCap, 'PAYMENT_ESCROW'],
          ['PG_IN', 'FEE_REVENUE', fee, 'PAYMENT_FEE'],
        ].map(([debitAccount, creditAccount, amount, reason]) => ({
          collaborationId: collaboration.id,
          batchId,
          debitAccount: debitAccount as 'PG_IN',
          creditAccount: creditAccount as 'ESCROW',
          amount: amount as number,
          reason: reason as string,
          idempotencyKey: `payment:${payment.id}`,
        })),
      });
    }
    // 결제 뒤 사후 단계가 올려 둔 제출 기한 작업.
    const due = new Date(T0.getTime() + 14 * DAY);
    await scheduler.schedule(
      'refund-unsubmitted',
      { collaborationId: collaboration.id },
      due,
      `refund-unsubmitted:${collaboration.id}`,
    );
    for (const daysLeft of [3, 1]) {
      await scheduler.schedule(
        'submit-reminder',
        { collaborationId: collaboration.id, daysLeft },
        new Date(due.getTime() - daysLeft * DAY),
        `submit-reminder:${collaboration.id}:${daysLeft}`,
      );
    }
    return {
      ownerId,
      storeId: store.id,
      creatorId: USER_A,
      offerId: offer.id,
      collaborationId: collaboration.id,
    };
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
    alert = jest
      .spyOn(app.get(OperatorAlertPort), 'alert')
      .mockResolvedValue(undefined);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    scheduler.jobs.length = 0;
    push.sent.length = 0;
    pg.refunds.length = 0;
    payoutPort.sent.length = 0;
    alert.mockClear();
    clock.set(T0);
  });
  afterEach(async () => {
    // 어떤 시나리오가 끝나도 모든 협업의 장부는 불변식을 지킨다.
    await expectEveryLedgerBalanced();
    jest.restoreAllMocks();
    alert = jest
      .spyOn(app.get(OperatorAlertPort), 'alert')
      .mockResolvedValue(undefined);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  describe('link submission', () => {
    it('rejects a request with no token', async () => {
      await request(server)
        .post(`/collaborations/${randomUUID()}/submission`)
        .send({ url: REELS_URL })
        .expect(401);
    });

    it('forbids a store account and hides other creators collaborations', async () => {
      const s = await seed();
      await prisma.user.update({
        where: { id: USER_A },
        data: { role: 'STORE' },
      });
      const forbidden = await submit(s.collaborationId, REELS_URL).expect(403);
      expect(codeOf(forbidden)).toBe('FORBIDDEN');

      await prisma.user.update({
        where: { id: USER_A },
        data: { role: 'CREATOR' },
      });
      // 다른 크리에이터의 협업은 없는 협업과 같다.
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: {
          creatorId: (
            await prisma.user.create({
              data: { id: randomUUID(), role: 'CREATOR' },
            })
          ).id,
        },
      });
      await submit(s.collaborationId, REELS_URL).expect(404);
      await submit(randomUUID(), REELS_URL).expect(404);
      await submit('not-a-uuid', REELS_URL).expect(404);
    });

    it('rejects a link that does not match the content format with 400', async () => {
      const s = await seed();
      const res = await submit(
        s.collaborationId,
        'https://www.youtube.com/shorts/abc123',
      ).expect(400);
      expect(messageOf(res)).toBe('링크 형식을 확인해 주세요.');
      await submit(s.collaborationId, 'http://instagram.com/reel/abc').expect(
        400,
      );
      await request(server)
        .post(`/collaborations/${s.collaborationId}/submission`)
        .set(auth)
        .send({})
        .expect(400);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
    });

    it('rejects a link that is not owned by the creator', async () => {
      const s = await seed();
      const res = await submit(
        s.collaborationId,
        'https://www.instagram.com/reel/notmine/',
      ).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(messageOf(res)).toBe('내 계정의 게시물만 제출할 수 있어요.');
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
    });

    it('asks the view count port with the connected instagram handle', async () => {
      const s = await seed();
      const owned = jest.spyOn(app.get(ViewCountPort), 'isOwnedBy');
      await submit(s.collaborationId, REELS_URL).expect(200);
      expect(owned).toHaveBeenCalledWith(REELS_URL, {
        instagramHandle: 'moca_daily',
      });
    });

    it('moves to COUNTING and schedules eight snapshots and a settlement', async () => {
      const s = await seed();
      const res = await submit(s.collaborationId, REELS_URL).expect(200);
      expect(res.body).toEqual({
        collaborationId: s.collaborationId,
        stage: 'COUNTING',
      });
      const row = await collaborationOf(s.collaborationId);
      expect(row).toMatchObject({
        stage: 'COUNTING',
        submittedUrl: REELS_URL,
        submittedAt: T0,
        countingEndsAt: new Date(T0.getTime() + 7 * DAY),
      });
      const snapshots = scheduler
        .pending()
        .filter((j) => j.name === 'view-snapshot')
        .sort((a, b) => a.runAt.getTime() - b.runAt.getTime());
      expect(snapshots).toHaveLength(8);
      snapshots.forEach((job, i) => {
        expect(job.jobKey).toBe(`view-snapshot:${s.collaborationId}:${i}`);
        expect(job.runAt).toEqual(new Date(T0.getTime() + i * DAY));
        expect(job.payload).toEqual({
          collaborationId: s.collaborationId,
          dayIndex: i,
        });
      });
      const settle = scheduler.pending().find((j) => j.name === 'settle');
      expect(settle?.jobKey).toBe(`settle:${s.collaborationId}`);
      expect(settle?.runAt).toEqual(new Date(T0.getTime() + 7 * DAY));
      // 제출했으니 미제출 환급과 기한 알림은 더 필요 없다.
      expect(
        jobKeys().filter((k) => k.startsWith('refund-unsubmitted')),
      ).toEqual([]);
      expect(jobKeys().filter((k) => k.startsWith('submit-reminder'))).toEqual(
        [],
      );
    });

    it('settles a voucher-only collaboration immediately on submission', async () => {
      const s = await seed({ rewardType: 'VOUCHER' });
      const res = await submit(s.collaborationId, REELS_URL).expect(200);
      expect(res.body).toEqual({
        collaborationId: s.collaborationId,
        stage: 'SETTLED',
      });
      const row = await collaborationOf(s.collaborationId);
      expect(row).toMatchObject({ stage: 'SETTLED', submittedUrl: REELS_URL });
      // 집계할 조회수도 보낼 돈도 없다.
      expect(
        scheduler.pending().filter((j) => j.name === 'view-snapshot'),
      ).toEqual([]);
      expect(await prisma.settlement.count()).toBe(0);
      expect(await prisma.ledgerEntry.count()).toBe(0);
      expect(jobKeys()).toEqual([]);
    });

    it('tells the store owner once that the content is up', async () => {
      const s = await seed();
      await submit(s.collaborationId, REELS_URL).expect(200);
      const owner = pushTo(s.ownerId);
      expect(owner.map((p) => p.body)).toEqual(['모카님이 콘텐츠를 올렸어요.']);
      const rows = await prisma.notification.findMany({
        where: { userId: s.ownerId },
      });
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        kind: 'CONTENT_SUBMITTED',
        dedupeKey: `submitted:${s.collaborationId}`,
        targetKind: 'COLLABORATION',
        targetId: s.collaborationId,
      });
    });

    it('rejects a second submission', async () => {
      const s = await seed();
      await submit(s.collaborationId, REELS_URL).expect(200);
      const res = await submit(s.collaborationId, REELS_URL).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      await submit(
        s.collaborationId,
        'https://www.instagram.com/reel/other/',
      ).expect(409);
      expect((await collaborationOf(s.collaborationId)).submittedUrl).toBe(
        REELS_URL,
      );
    });

    it('rejects a submission before the money is held', async () => {
      const s = await seed({ stage: 'AWAITING_PAYMENT' });
      const res = await submit(s.collaborationId, REELS_URL).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
    });

    it('goes back to FUNDED so the creator can try again when a job cannot be scheduled', async () => {
      const s = await seed();
      const original = scheduler.schedule.bind(scheduler);
      jest
        .spyOn(scheduler, 'schedule')
        .mockImplementationOnce(original)
        .mockRejectedValueOnce(new Error('redis down'));
      await submit(s.collaborationId, REELS_URL).expect(500);
      const row = await collaborationOf(s.collaborationId);
      expect(row).toMatchObject({
        stage: 'FUNDED',
        submittedUrl: null,
        submittedAt: null,
        countingEndsAt: null,
      });
      // 되돌리기 전에 올라간 조회수 작업은 남지 않는다.
      expect(
        scheduler.pending().filter((j) => j.name === 'view-snapshot'),
      ).toEqual([]);
      jest.restoreAllMocks();
      await submit(s.collaborationId, REELS_URL).expect(200);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
    });
  });

  describe('view snapshots', () => {
    it('stores the view count read on each day', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=4320`).expect(200);
      await scheduler.runDue(T0);
      let rows = await snapshotsOf(s.collaborationId);
      expect(rows.map((r) => [r.dayIndex, r.views])).toEqual([[0, 4320]]);
      expect(rows[0].takenAt).toEqual(T0);
      clock.set(new Date(T0.getTime() + DAY));
      await scheduler.runDue(clock.now());
      rows = await snapshotsOf(s.collaborationId);
      expect(rows.map((r) => r.dayIndex)).toEqual([0, 1]);
    });

    it('stores null and never zero when the count cannot be read', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=unavailable`).expect(
        200,
      );
      await scheduler.runDue(T0);
      const rows = await snapshotsOf(s.collaborationId);
      expect(rows.map((r) => [r.dayIndex, r.views])).toEqual([[0, null]]);
    });

    it('treats a creator without a connected instagram account as a read failure', async () => {
      const s = await seed();
      await prisma.instagramConnection.delete({ where: { creatorId: USER_A } });
      const read = jest.spyOn(app.get(ViewCountPort), 'read');
      await submit(s.collaborationId, REELS_URL).expect(200);
      await scheduler.runDue(T0);
      const rows = await snapshotsOf(s.collaborationId);
      expect(rows.map((r) => [r.dayIndex, r.views])).toEqual([[0, null]]);
      expect(read).not.toHaveBeenCalled();
    });

    it('does not take the same snapshot twice when the job runs twice', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=100`).expect(200);
      const read = jest.spyOn(app.get(ViewCountPort), 'read');
      await scheduler.runDue(T0);
      // 같은 작업이 다시 도는 것을 흉내 낸다(큐가 재시도한 경우).
      const [job] = scheduler.jobs.filter(
        (j) => j.jobKey === `view-snapshot:${s.collaborationId}:0`,
      );
      await scheduler.registry.run(job.name, job.payload);
      expect(await snapshotsOf(s.collaborationId)).toHaveLength(1);
      expect(read).toHaveBeenCalledTimes(1);
    });

    it('halts and alerts the operator after three unreadable days in a row', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=unavailable`).expect(
        200,
      );
      await scheduler.runDue(T0);
      clock.set(new Date(T0.getTime() + DAY));
      await scheduler.runDue(clock.now());
      // 이틀 읽지 못했다: 아직 멈추지 않는다.
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(alert).not.toHaveBeenCalled();

      clock.set(new Date(T0.getTime() + 2 * DAY));
      await scheduler.runDue(clock.now());
      const row = await collaborationOf(s.collaborationId);
      expect(row).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'COUNTING',
        haltedReason: 'VIEW_COUNT_UNAVAILABLE',
      });
      // 0원으로 정산하지 않는다: 정산 작업은 취소되고 정산도 없다.
      expect(jobKeys()).not.toContain(`settle:${s.collaborationId}`);
      expect(await prisma.settlement.count()).toBe(0);
      expect(
        await prisma.ledgerEntry.count({
          where: { creditAccount: 'CREATOR_PAYABLE' },
        }),
      ).toBe(0);
      expect(alert).toHaveBeenCalledTimes(1);

      // 양쪽에 한 번씩 알린다.
      for (const userId of [s.ownerId, s.creatorId]) {
        const rows = await prisma.notification.findMany({
          where: { userId, kind: 'COLLABORATION_HALTED' },
        });
        expect(rows).toHaveLength(1);
        expect(rows[0].dedupeKey).toBe(`halted:${s.collaborationId}`);
      }
      // 남은 날의 작업은 지워져 더 돌지 않는다.
      expect(jobKeys().filter((k) => k.startsWith('view-snapshot'))).toEqual(
        [],
      );
    });

    it('does not halt when a readable day breaks the run', async () => {
      const s = await seed();
      const read = jest
        .spyOn(app.get(ViewCountPort), 'read')
        .mockRejectedValueOnce(new ViewCountUnavailableError())
        .mockRejectedValueOnce(new ViewCountUnavailableError())
        .mockResolvedValueOnce(900)
        .mockRejectedValueOnce(new ViewCountUnavailableError());
      await submit(s.collaborationId, REELS_URL).expect(200);
      for (let day = 0; day <= 3; day += 1) {
        clock.set(new Date(T0.getTime() + day * DAY));
        await scheduler.runDue(clock.now());
      }
      expect(read).toHaveBeenCalledTimes(4);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(alert).not.toHaveBeenCalled();
      const rows = await snapshotsOf(s.collaborationId);
      expect(rows.map((r) => r.views)).toEqual([null, null, 900, null]);
    });

    it('does nothing for a collaboration that is no longer counting', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=100`).expect(200);
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: { stage: 'CANCELLED' },
      });
      await scheduler.runDue(T0);
      expect(await snapshotsOf(s.collaborationId)).toHaveLength(0);
    });
  });
  describe('settlement', () => {
    // 제출 7일 뒤 = 2026-12-08(화) 12:00 KST. 지급일은 다음 주 수요일 2026-12-16 10:00 KST다.
    const PAYDAY = new Date('2026-12-16T01:00:00.000Z');

    it('settles 4320 views as 43200 paid and 56800 refunded', async () => {
      const s = await seed();
      await submitAndSettle(s, 4320);
      const row = await collaborationOf(s.collaborationId);
      expect(row.stage).toBe('SETTLED');
      const settlement = await prisma.settlement.findUniqueOrThrow({
        where: { collaborationId: s.collaborationId },
      });
      expect(settlement).toMatchObject({
        finalViews: 4320,
        payoutAmount: 43200,
        refundAmount: 56800,
        settledAt: new Date(T0.getTime() + 7 * DAY),
      });
      // 장부: 에스크로가 지급 예정분과 환급분으로 나뉘어 비고, 수수료는 그대로 남는다.
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await accountOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(43200);
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(56800);
      expect(await accountOf(s.collaborationId, 'FEE_REVENUE')).toBe(10000);
      // 지급은 바로 보내지 않고 지급일에 보낸다. 환급은 바로 나간다.
      const payouts = await prisma.payout.findMany();
      expect(payouts).toHaveLength(1);
      expect(payouts[0]).toMatchObject({
        collaborationId: s.collaborationId,
        amount: 43200,
        status: 'PENDING',
        scheduledFor: PAYDAY,
      });
      expect(payoutPort.sent).toHaveLength(0);
      const refunds = await prisma.refund.findMany();
      expect(refunds).toHaveLength(1);
      expect(refunds[0]).toMatchObject({ amount: 56800, status: 'DONE' });
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0]).toMatchObject({
        pgTransactionId: `tx-${s.collaborationId}`,
        amount: 56800,
      });
      const job = jobKeys().filter((k) => k.startsWith('payout:'));
      expect(job).toEqual([`payout:${payouts[0].id}`]);
    });

    it('notifies the settlement once with the canvas text', async () => {
      const s = await seed();
      await submitAndSettle(s, 4320);
      expect(pushTo(s.creatorId).map((p) => p.body)).toEqual([
        '정산 43,200원이 다음 주 수요일에 들어와요.',
      ]);
      expect(
        pushTo(s.ownerId)
          .map((p) => p.body)
          .filter((b) => b.startsWith('조회수 집계')),
      ).toEqual(['조회수 집계가 끝났어요. 56,800원을 돌려드려요.']);
      const rows = await prisma.notification.findMany({
        where: {
          kind: { in: ['SETTLEMENT_CONFIRMED', 'SETTLEMENT_REFUNDED'] },
        },
      });
      expect(rows.map((r) => r.dedupeKey).sort()).toEqual([
        `settle-refund:${s.collaborationId}`,
        `settled:${s.collaborationId}`,
      ]);
    });

    it('pays nothing and refunds the full cap for zero views', async () => {
      const s = await seed();
      await submitAndSettle(s, 0);
      expect(await prisma.settlement.findMany()).toMatchObject([
        { finalViews: 0, payoutAmount: 0, refundAmount: 100000 },
      ]);
      expect(await prisma.payout.count()).toBe(0);
      expect(await prisma.refund.findMany()).toMatchObject([
        { amount: 100000, status: 'DONE' },
      ]);
      expect(await accountOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(0);
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(100000);
      // 0원 지급의 정산 알림은 보내지 않는다.
      expect(
        await prisma.notification.count({
          where: { kind: 'SETTLEMENT_CONFIRMED' },
        }),
      ).toBe(0);
      expect(
        await prisma.notification.count({
          where: { kind: 'SETTLEMENT_REFUNDED' },
        }),
      ).toBe(1);
    });

    it('caps the payout at the cap', async () => {
      const s = await seed();
      await submitAndSettle(s, 5000000);
      expect(await prisma.settlement.findMany()).toMatchObject([
        { finalViews: 5000000, payoutAmount: 100000, refundAmount: 0 },
      ]);
      expect(await prisma.refund.count()).toBe(0);
      expect(pg.refunds).toHaveLength(0);
      expect(await prisma.payout.findMany()).toMatchObject([
        { amount: 100000, status: 'PENDING' },
      ]);
      expect(
        await prisma.notification.count({
          where: { kind: 'SETTLEMENT_REFUNDED' },
        }),
      ).toBe(0);
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(0);
    });

    it('does not pay or refund twice when the settle job runs twice', async () => {
      const s = await seed();
      await submitAndSettle(s, 4320);
      const entries = (await ledgerOf(s.collaborationId)).length;
      const job = settleJob(s.collaborationId);
      await scheduler.registry.run(job.name, job.payload);
      await scheduler.registry.run(job.name, job.payload);
      expect(await prisma.settlement.count()).toBe(1);
      expect(await prisma.payout.count()).toBe(1);
      expect(await prisma.refund.count()).toBe(1);
      expect(pg.refunds).toHaveLength(1);
      expect((await ledgerOf(s.collaborationId)).length).toBe(entries);
      expect(
        await prisma.notification.count({
          where: {
            kind: { in: ['SETTLEMENT_CONFIRMED', 'SETTLEMENT_REFUNDED'] },
          },
        }),
      ).toBe(2);
      expect(jobKeys().filter((k) => k.startsWith('payout:'))).toHaveLength(1);
    });

    it('finishes the refund and the notices when the job died after the settlement committed', async () => {
      const s = await seed();
      const refunds = app.get(RefundsService);
      jest
        .spyOn(refunds, 'execute')
        .mockRejectedValueOnce(new Error('process died'));
      await submit(s.collaborationId, `${REELS_URL}?views=4320`).expect(200);
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now(), { allowFailures: true });
      // 정산은 커밋됐고 환급은 아직 나가지 않았다.
      expect((await collaborationOf(s.collaborationId)).stage).toBe('SETTLED');
      expect(await prisma.refund.findMany()).toMatchObject([
        { amount: 56800, status: 'PENDING' },
      ]);
      expect(pg.refunds).toHaveLength(0);

      // 큐가 같은 작업을 다시 돌린다.
      const job = settleJob(s.collaborationId);
      await scheduler.registry.run(job.name, job.payload);
      expect(await prisma.refund.findMany()).toMatchObject([
        { status: 'DONE' },
      ]);
      expect(pg.refunds).toHaveLength(1);
      expect(await prisma.payout.count()).toBe(1);
      expect(await prisma.settlement.count()).toBe(1);
      expect(
        await prisma.notification.count({
          where: { kind: 'SETTLEMENT_CONFIRMED' },
        }),
      ).toBe(1);
      expect(
        await prisma.notification.count({
          where: { kind: 'SETTLEMENT_REFUNDED' },
        }),
      ).toBe(1);
    });

    it('does nothing when the collaboration is not counting', async () => {
      const s = await seed();
      const job = settleJob(s.collaborationId);
      await scheduler.registry.run(job.name, job.payload);
      expect(await prisma.settlement.count()).toBe(0);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
      expect(
        await prisma.ledgerEntry.count({
          where: { creditAccount: 'CREATOR_PAYABLE' },
        }),
      ).toBe(0);
    });

    it('uses the last readable snapshot when day 7 cannot be read', async () => {
      const s = await seed();
      jest
        .spyOn(app.get(ViewCountPort), 'read')
        .mockResolvedValueOnce(100)
        .mockResolvedValueOnce(200)
        .mockResolvedValueOnce(300)
        .mockResolvedValueOnce(400)
        .mockResolvedValueOnce(500)
        .mockResolvedValueOnce(600)
        .mockResolvedValueOnce(700)
        .mockRejectedValue(new ViewCountUnavailableError());
      await submit(s.collaborationId, REELS_URL).expect(200);
      for (let day = 0; day <= 7; day += 1) {
        clock.set(new Date(T0.getTime() + day * DAY));
        await scheduler.runDue(clock.now());
      }
      expect((await collaborationOf(s.collaborationId)).stage).toBe('SETTLED');
      expect(await prisma.settlement.findMany()).toMatchObject([
        { finalViews: 700, payoutAmount: 7000, refundAmount: 93000 },
      ]);
    });

    it('takes the day 7 snapshot itself when its own job has not run yet', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=4320`).expect(200);
      await scheduler.cancel(`view-snapshot:${s.collaborationId}:7`);
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      const days = (await snapshotsOf(s.collaborationId)).map(
        (r) => r.dayIndex,
      );
      expect(days).toContain(7);
      expect(await prisma.settlement.findMany()).toMatchObject([
        { finalViews: 4320, payoutAmount: 43200 },
      ]);
    });

    it('halts instead of settling when no snapshot is readable at settlement time', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=unavailable`).expect(
        200,
      );
      const job = settleJob(s.collaborationId);
      await scheduler.registry.run(job.name, job.payload);
      const row = await collaborationOf(s.collaborationId);
      expect(row).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'COUNTING',
        haltedReason: 'VIEW_COUNT_UNAVAILABLE',
      });
      expect(await prisma.settlement.count()).toBe(0);
      expect(await prisma.payout.count()).toBe(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(alert).toHaveBeenCalledTimes(1);
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(100000);
    });

    it('keeps every collaboration ledger balanced after each scenario', async () => {
      for (const views of [0, 4320, 9999999]) {
        const s = await seed();
        await submitAndSettle(s, views);
        const entries = await ledgerOf(s.collaborationId);
        assertBalanced(entries);
        expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(0);
        // 낸 돈 전부(상한 + 수수료)가 지급 예정, 환급, 수수료로 남김없이 나뉜다.
        const total =
          (await accountOf(s.collaborationId, 'CREATOR_PAYABLE')) +
          (await accountOf(s.collaborationId, 'STORE_REFUND')) +
          (await accountOf(s.collaborationId, 'FEE_REVENUE'));
        expect(total).toBe(110000);
        scheduler.jobs.length = 0;
        clock.set(T0);
      }
    });
  });

  describe('payout', () => {
    const PAYDAY = new Date('2026-12-16T01:00:00.000Z');

    it('sends the payout on the payday and not before', async () => {
      const s = await seed();
      await registerAccount();
      await submitAndSettle(s, 4320);
      expect(payoutPort.sent).toHaveLength(0);

      // 지급일 10시 1분 전까지는 보내지 않는다.
      clock.set(new Date(PAYDAY.getTime() - MINUTE));
      await scheduler.runDue(clock.now());
      expect(payoutPort.sent).toHaveLength(0);
      expect((await prisma.payout.findFirstOrThrow()).status).toBe('PENDING');

      clock.set(PAYDAY);
      await scheduler.runDue(clock.now());
      expect(payoutPort.sent).toHaveLength(1);
      expect(payoutPort.sent[0]).toMatchObject({
        bankCode: '004',
        accountNumber: '110123456789',
        holderName: '김민지',
        amount: 43200,
      });
      const payout = await prisma.payout.findFirstOrThrow();
      expect(payout.status).toBe('DONE');
      expect(payout.externalId).toBe(`fake-payout-payout:${payout.id}`);
      expect(pushTo(s.creatorId).map((p) => p.body)).toContain(
        '43,200원이 지급됐어요.',
      );
      expect(
        await prisma.notification.findMany({ where: { kind: 'PAYOUT_DONE' } }),
      ).toMatchObject([{ dedupeKey: `payout-done:${payout.id}` }]);
    });

    it('does not send twice when the payout job runs twice', async () => {
      const s = await seed();
      await registerAccount();
      await submitAndSettle(s, 4320);
      clock.set(PAYDAY);
      await scheduler.runDue(clock.now());
      const payout = await prisma.payout.findFirstOrThrow();
      await scheduler.registry.run('payout-send', { payoutId: payout.id });
      await scheduler.registry.run('payout-send', { payoutId: payout.id });
      expect(payoutPort.sent).toHaveLength(1);
      expect(
        await prisma.notification.count({ where: { kind: 'PAYOUT_DONE' } }),
      ).toBe(1);
      expect(s.creatorId).toBe(USER_A);
    });

    it('sends the payout with the same key when the job died after sending', async () => {
      const s = await seed();
      await registerAccount();
      await submitAndSettle(s, 4320);
      const payout = await prisma.payout.findFirstOrThrow();
      // 송금은 나갔는데 DONE으로 바꾸기 전에 죽었다: 단계는 PENDING 그대로, 포트에는 기록이 있다.
      await payoutPort.send({
        bankCode: '004',
        accountNumber: '110123456789',
        holderName: '김민지',
        amount: 43200,
        idempotencyKey: `payout:${payout.id}`,
      });
      clock.set(PAYDAY);
      await scheduler.runDue(clock.now());
      expect(payoutPort.sent).toHaveLength(1);
      expect((await prisma.payout.findFirstOrThrow()).status).toBe('DONE');
    });

    it('waits without an account and sends on the next payday after registration', async () => {
      const s = await seed();
      await submitAndSettle(s, 4320);
      // 지급일이 왔지만 계좌가 없다: 그대로 두고 작업은 오류 없이 끝난다.
      clock.set(PAYDAY);
      await scheduler.runDue(clock.now());
      expect(payoutPort.sent).toHaveLength(0);
      expect((await prisma.payout.findFirstOrThrow()).status).toBe('PENDING');
      expect(alert).not.toHaveBeenCalled();

      // 목요일 12:00 KST에 계좌를 등록해도 바로 보내지 않는다. 그다음 수요일(12-23 10:00 KST)에 보낸다.
      clock.set(new Date('2026-12-17T03:00:00.000Z'));
      await registerAccount();
      expect(payoutPort.sent).toHaveLength(0);
      const moved = await prisma.payout.findFirstOrThrow();
      expect(moved.scheduledFor).toEqual(new Date('2026-12-23T01:00:00.000Z'));
      expect(moved.status).toBe('PENDING');

      clock.set(new Date('2026-12-23T00:59:00.000Z'));
      await scheduler.runDue(clock.now());
      expect(payoutPort.sent).toHaveLength(0);
      clock.set(new Date('2026-12-23T01:00:00.000Z'));
      await scheduler.runDue(clock.now());
      expect(payoutPort.sent).toHaveLength(1);
      expect((await prisma.payout.findFirstOrThrow()).status).toBe('DONE');
      expect(
        await prisma.notification.count({ where: { kind: 'PAYOUT_DONE' } }),
      ).toBe(1);
    });

    it('keeps the payday when the account is registered before it', async () => {
      const s = await seed();
      await submitAndSettle(s, 4320);
      clock.set(new Date('2026-12-09T03:00:00.000Z'));
      await registerAccount();
      const row = await prisma.payout.findFirstOrThrow();
      expect(row.scheduledFor).toEqual(PAYDAY);
      expect(payoutPort.sent).toHaveLength(0);
      clock.set(PAYDAY);
      await scheduler.runDue(clock.now());
      expect(payoutPort.sent).toHaveLength(1);
      expect(s.collaborationId).toBe(row.collaborationId);
    });

    it('leaves the payout pending and does not fail the job when the account key is unreadable', async () => {
      const s = await seed();
      await registerAccount();
      await submitAndSettle(s, 4320);
      jest
        .spyOn(app.get(PayoutAccountsService), 'getForPayout')
        .mockRejectedValue(
          new AppError(
            'INTERNAL',
            'PAYOUT_ACCOUNT_KEY가 없거나 올바르지 않아요.',
          ),
        );
      clock.set(PAYDAY);
      const ran = await scheduler.runDue(clock.now());
      expect(ran.filter((j) => j.status === 'failed')).toEqual([]);
      expect(payoutPort.sent).toHaveLength(0);
      expect((await prisma.payout.findFirstOrThrow()).status).toBe('PENDING');
      expect(s.collaborationId).toBeTruthy();
    });

    it('marks the payout failed and alerts the operator when the transfer fails', async () => {
      const s = await seed();
      await registerAccount('fail 김민지');
      await submitAndSettle(s, 4320);
      clock.set(PAYDAY);
      await scheduler.runDue(clock.now());
      expect((await prisma.payout.findFirstOrThrow()).status).toBe('FAILED');
      expect(alert).toHaveBeenCalledTimes(1);
      expect(
        await prisma.notification.count({ where: { kind: 'PAYOUT_DONE' } }),
      ).toBe(0);
      expect(s.creatorId).toBe(USER_A);
    });

    it('does not move payouts that are not yet due when an account is registered', async () => {
      const s = await seed();
      await submitAndSettle(s, 4320);
      clock.set(new Date('2026-12-10T03:00:00.000Z'));
      await registerAccount();
      expect((await prisma.payout.findFirstOrThrow()).scheduledFor).toEqual(
        PAYDAY,
      );
      expect(jobKeys().filter((k) => k.startsWith('payout:'))).toHaveLength(1);
      expect(s.ownerId).toBeTruthy();
    });
  });
});
