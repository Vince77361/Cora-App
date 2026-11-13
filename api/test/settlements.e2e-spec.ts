import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import {
  CollaborationStage,
  ContentFormat,
  PrismaClient,
} from '@prisma/client';
import request from 'supertest';
import { scheduleSubmissionDeadlineJobs } from '../src/collaborations/collaboration-jobs';
import { Clock } from '../src/common/clock';
import { AppError } from '../src/common/errors/app-error';
import { FakePaymentAdapter } from '../src/integrations/payment/fake-payment.adapter';
import { PaymentPort } from '../src/integrations/payment/payment.port';
import { FakePayoutAdapter } from '../src/integrations/payout/fake-payout.adapter';
import { PayoutPort } from '../src/integrations/payout/payout.port';
import { assertBalanced } from '../src/ledger/ledger-postings';
import { PayoutAccountsService } from '../src/payout-accounts/payout-accounts.service';
import { NotificationsService } from '../src/notifications/notifications.service';
import { RefundsService } from '../src/settlements/refunds.service';
import { SettlementsService } from '../src/settlements/settlements.service';
import { ViewReportService } from '../src/settlements/view-report.service';
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
import { createOffer } from './helpers/create-offer';

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
  const settlementOf = (id: string) =>
    prisma.settlement.findUniqueOrThrow({ where: { collaborationId: id } });
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
  // 사장님이 "자료 확인했어요"를 누른 것과 같다(서비스를 바로 부른다. HTTP 쪽은 view-report e2e가 본다).
  const confirmAsOwner = (collaborationId: string) =>
    app
      .get(ViewReportService)
      .confirm(collaborationId, 'COMMISSIONER', `settle:${collaborationId}`, {
        onlySource: 'CONNECTED_ACCOUNT',
      });
  // 제출하고 7일을 지나 정산까지 돌린다: 7일째 계산이 만들어지고(조회수 수당이 있을 때), 같은 시각에 사장님이 확인한다.
  async function submitAndSettle(
    s: Seeded,
    views: number | string,
  ): Promise<void> {
    await submit(s.collaborationId, `${REELS_URL}?views=${views}`).expect(200);
    clock.set(new Date(T0.getTime() + 7 * DAY));
    await scheduler.runDue(clock.now());
    await confirmAsOwner(s.collaborationId);
  }
  const settleJob = (id: string) =>
    ({ name: 'settle', payload: { collaborationId: id } }) as const;
  const pushTo = (userId: string) =>
    push.sent.filter((p) => p.userId === userId);

  // 조회수 수당의 단가는 옛 협업과 같은 금액이 나오도록 기본을 10,000원(1,000회당)으로 둔다. 새 범위의 단가는 시나리오가 준다.
  // 크리에이터는 로그인한 USER_A다. 사장님은 따로 만든다. 협업은 보관이 시작된(FUNDED) 상태로 DB에 바로 만들고,
  // 장부와 결제도 결제 승인 직후와 같게 채운다(상한 = 에스크로, 수수료 10%).
  async function seed(
    over: {
      stage?: CollaborationStage;
      format?: ContentFormat;
      // FIXED_ONLY는 고정 현금만 있는 보상이다(식사권도 조회수 수당도 없다).
      rewardType?: 'VOUCHER' | 'PER_VIEW' | 'BOTH' | 'FIXED_ONLY';
      fixedCash?: number;
      ratePerThousand?: number;
      perViewCap?: number;
      connected?: boolean;
      // 조건 사본을 옛 모양(rewardType, 건당 금액)으로 넣는다. 이전이 빠뜨린 줄을 흉내 낸다.
      legacyCopy?: boolean;
      // 결제로 보관한 금액. 기본은 조건의 상한이다(어긋난 보관액을 만들 때만 준다).
      paidEscrow?: number;
      // 가게가 넣은 인스타그램 링크. 평소 조회수를 읽을 계정이다(기본은 링크 없음).
      instagram?: string;
    } = {},
  ): Promise<Seeded> {
    const rewardType = over.rewardType ?? 'BOTH';
    const perView = rewardType === 'PER_VIEW' || rewardType === 'BOTH';
    const fixedCash = over.fixedCash ?? 0;
    const ratePerThousand = over.ratePerThousand ?? 10000;
    const perViewCap = over.perViewCap ?? 100000;
    // 보관액 = 최대 현금 부담 = 고정 현금 + 조회수 수당 상한.
    const escrow = over.paidEscrow ?? fixedCash + (perView ? perViewCap : 0);
    const settlementMethod =
      fixedCash > 0 && perView
        ? 'FIXED_AND_PER_VIEW'
        : fixedCash > 0
          ? 'FIXED'
          : perView
            ? 'PER_VIEW'
            : 'NONE';
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
        publishedAt: T0,
        ...(over.instagram
          ? {
              sourceLinks: {
                create: { kind: 'INSTAGRAM', url: over.instagram },
              },
            }
          : {}),
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
    const hasVoucher = rewardType === 'VOUCHER' || rewardType === 'BOTH';
    const columns = {
      format: over.format ?? 'REELS',
      voucherName: hasVoucher ? '식사권' : null,
      voucherValue: hasVoucher ? 40000 : null,
      voucherPeople: hasVoucher ? 2 : null,
      fixedCash,
      viewRatePerThousand: perView ? ratePerThousand : null,
      perViewCap: perView ? perViewCap : null,
      usageRights: 'STORE_REPOST_3M' as const,
    };
    const terms = over.legacyCopy
      ? {
          format: columns.format,
          rewardType,
          voucherName: hasVoucher ? '2인 식사권' : null,
          voucherValue: columns.voucherValue,
          perViewAmount: perView ? ratePerThousand / 1000 : null,
          perViewCap: columns.perViewCap,
        }
      : { ...columns, pieces: 1 };
    const offer = await createOffer(prisma, {
      storeId: store.id,
      creatorId: USER_A,
      ...columns,
      status: 'ACCEPTED',
      expiresAt: new Date(T0.getTime() + 7 * DAY),
      createdAt: T0,
      acceptedAt: T0,
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
        settlementMethod,
        fundedAt: T0,
        submitDueAt: new Date(T0.getTime() + 14 * DAY),
      },
    });
    if (escrow > 0) {
      const fee = Math.floor(escrow / 10);
      const payment = await prisma.payment.create({
        data: {
          collaborationId: collaboration.id,
          amountEscrow: escrow,
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
          ['PG_IN', 'ESCROW', escrow, 'PAYMENT_ESCROW'],
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
    // 결제 뒤(또는 식사권만 있는 오퍼를 수락한 뒤)의 사후 단계가 올려 둔 제출 기한 작업.
    await scheduleSubmissionDeadlineJobs(
      scheduler,
      collaboration.id,
      new Date(T0.getTime() + 14 * DAY),
      T0,
    );
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
      // 응답은 협업 모델이다(원장 판단 R8).
      expect(res.body).toMatchObject({
        id: s.collaborationId,
        stage: 'COUNTING',
        role: 'CREATOR',
        submittedUrl: REELS_URL,
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

    it('keeps the voucher only path settling on submission', async () => {
      const s = await seed({ rewardType: 'VOUCHER' });
      const res = await submit(s.collaborationId, REELS_URL).expect(200);
      expect(res.body).toMatchObject({
        id: s.collaborationId,
        stage: 'SETTLED',
        payoutStatus: 'NONE',
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

    it('counts no views for a fixed cash only collaboration', async () => {
      // 연동된 인스타그램 계정 없이도 제출된다(조회수를 읽지 않는다).
      const s = await seed({ rewardType: 'FIXED_ONLY', fixedCash: 30000 });
      const res = await submit(s.collaborationId, REELS_URL).expect(200);
      expect(res.body).toMatchObject({ stage: 'COUNTING' });
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'COUNTING',
        settlementMethod: 'FIXED',
        submittedAt: T0,
        countingEndsAt: new Date(T0.getTime() + 7 * DAY),
      });
      // 스냅샷 작업 없이 정산 작업만 측정 기간이 끝나는 날에 올라간다.
      expect(
        scheduler.pending().filter((j) => j.name === 'view-snapshot'),
      ).toEqual([]);
      const settle = scheduler.pending().filter((j) => j.name === 'settle');
      expect(settle).toHaveLength(1);
      expect(settle[0].runAt).toEqual(new Date(T0.getTime() + 7 * DAY));
      await scheduler.runDue(new Date(T0.getTime() + 6 * DAY));
      expect(await snapshotsOf(s.collaborationId)).toEqual([]);
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

    it('asks for a capture after three unreadable days in a row instead of halting', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=unavailable`).expect(
        200,
      );
      await scheduler.runDue(T0);
      clock.set(new Date(T0.getTime() + DAY));
      await scheduler.runDue(clock.now());
      // 이틀 읽지 못했다: 아직 요청하지 않는다.
      expect(
        await prisma.notification.count({
          where: { kind: 'VIEW_EVIDENCE_REQUESTED' },
        }),
      ).toBe(0);

      clock.set(new Date(T0.getTime() + 2 * DAY));
      await scheduler.runDue(clock.now());
      // 멈추지 않고 크리에이터에게 캡처를 요청한다.
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(
        await prisma.notification.findMany({
          where: { kind: 'VIEW_EVIDENCE_REQUESTED' },
        }),
      ).toMatchObject([
        {
          userId: s.creatorId,
          dedupeKey: `evidence-request:${s.collaborationId}`,
        },
      ]);
      expect(alert).not.toHaveBeenCalled();
      expect(jobKeys()).toContain(`settle:${s.collaborationId}`);
      expect(await prisma.settlement.count()).toBe(0);
    });

    it('halts and alerts the operator three days after the period ends when no capture came', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=unavailable`).expect(
        200,
      );
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      // 0원으로 정산하지도 멈추지도 않고 캡처를 기다린다.
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(await prisma.settlement.count()).toBe(0);
      expect(jobKeys()).toContain(`evidence-halt:${s.collaborationId}`);
      expect(alert).not.toHaveBeenCalled();

      clock.set(new Date(T0.getTime() + 10 * DAY));
      await scheduler.runDue(clock.now());
      const row = await collaborationOf(s.collaborationId);
      expect(row).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'COUNTING',
        haltedReason: 'VIEW_COUNT_UNAVAILABLE',
      });
      // 0원으로 정산하지 않는다: 정산 작업은 취소되고 정산도 없다.
      expect(jobKeys()).not.toContain(`settle:${s.collaborationId}`);
      expect(jobKeys()).not.toContain(`evidence-halt:${s.collaborationId}`);
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

    it('settles 12500 views as 25000 paid and 35000 refunded', async () => {
      // 캔버스 F4의 숫자: 1,000회당 2,000원, 상한 60,000원.
      const s = await seed({ ratePerThousand: 2000, perViewCap: 60000 });
      await submitAndSettle(s, 12500);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('SETTLED');
      expect(
        await prisma.settlement.findUniqueOrThrow({
          where: { collaborationId: s.collaborationId },
        }),
      ).toMatchObject({
        finalViews: 12500,
        payoutAmount: 25000,
        refundAmount: 35000,
      });
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await accountOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(25000);
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(35000);
      expect(await accountOf(s.collaborationId, 'FEE_REVENUE')).toBe(6000);
      expect(await prisma.payout.findMany()).toMatchObject([{ amount: 25000 }]);
      expect(await prisma.refund.findMany()).toMatchObject([{ amount: 35000 }]);
    });

    it('settles fixed cash plus view pay and refunds only the unused cap', async () => {
      // 고정 현금 30,000원 + 조회수 수당 상한 60,000원: 보관 90,000원 + 수수료 9,000원.
      const s = await seed({
        rewardType: 'PER_VIEW',
        fixedCash: 30000,
        ratePerThousand: 2000,
        perViewCap: 60000,
      });
      await submitAndSettle(s, 12500);
      expect(
        await prisma.settlement.findUniqueOrThrow({
          where: { collaborationId: s.collaborationId },
        }),
      ).toMatchObject({
        finalViews: 12500,
        payoutAmount: 55000,
        refundAmount: 35000,
      });
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await accountOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(55000);
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(35000);
      expect(await accountOf(s.collaborationId, 'FEE_REVENUE')).toBe(9000);
      expect(await prisma.payout.findMany()).toMatchObject([{ amount: 55000 }]);
      expect(await prisma.refund.findMany()).toMatchObject([{ amount: 35000 }]);
    });

    it('does not settle a fixed cash only collaboration before the period ends', async () => {
      const s = await seed({ rewardType: 'FIXED_ONLY', fixedCash: 30000 });
      await submit(s.collaborationId, REELS_URL).expect(200);
      clock.set(new Date(T0.getTime() + 7 * DAY - MINUTE));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(await prisma.settlement.count()).toBe(0);
      expect(await prisma.payout.count()).toBe(0);
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(30000);
    });

    it('settles a fixed cash only collaboration on the day the period ends', async () => {
      const s = await seed({ rewardType: 'FIXED_ONLY', fixedCash: 30000 });
      await submitAndSettle(s, 'ignored');
      expect((await collaborationOf(s.collaborationId)).stage).toBe('SETTLED');
      // 조회수를 읽지 않아 finalViews가 없고, 3일 실패 규칙에 걸리지도 않는다.
      expect(
        await prisma.settlement.findUniqueOrThrow({
          where: { collaborationId: s.collaborationId },
        }),
      ).toMatchObject({
        finalViews: null,
        payoutAmount: 30000,
        refundAmount: 0,
        settledAt: new Date(T0.getTime() + 7 * DAY),
      });
      expect(await snapshotsOf(s.collaborationId)).toEqual([]);
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await accountOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(30000);
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(0);
      expect(await accountOf(s.collaborationId, 'FEE_REVENUE')).toBe(3000);
      expect(await prisma.payout.findMany()).toMatchObject([{ amount: 30000 }]);
      // 환급할 돈이 없으니 PG 환급도 없다.
      expect(pg.refunds).toHaveLength(0);
      expect(alert).not.toHaveBeenCalled();
      expect(
        await prisma.notification.count({
          where: { kind: 'SETTLEMENT_CONFIRMED' },
        }),
      ).toBe(1);
    });

    it('caps the view pay at the cap of the terms', async () => {
      const s = await seed({ ratePerThousand: 2000, perViewCap: 60000 });
      await submitAndSettle(s, 9999999);
      expect(
        await prisma.settlement.findUniqueOrThrow({
          where: { collaborationId: s.collaborationId },
        }),
      ).toMatchObject({ payoutAmount: 60000, refundAmount: 0 });
    });

    it('settles a legacy collaboration with the same amounts as before', async () => {
      // 조건 사본을 옛 모양(건당 10원)으로 넣는다: 4320회 → 43200 / 56800.
      const s = await seed({ legacyCopy: true });
      await submitAndSettle(s, 4320);
      expect(
        await prisma.settlement.findUniqueOrThrow({
          where: { collaborationId: s.collaborationId },
        }),
      ).toMatchObject({
        finalViews: 4320,
        payoutAmount: 43200,
        refundAmount: 56800,
      });
      expect(await accountOf(s.collaborationId, 'CREATOR_PAYABLE')).toBe(43200);
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(56800);
    });

    it('refuses to settle when the escrow balance differs from the copied burden', async () => {
      // 보관액(90,000)이 조건의 최대 현금 부담(100,000)과 다르면 확인할 때 돈을 움직이지 않고 되돌린다(계산은 확인 전 그대로다).
      const s = await seed({ paidEscrow: 90000 });
      await submit(s.collaborationId, `${REELS_URL}?views=4320`).expect(200);
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      const before = await ledgerOf(s.collaborationId);
      await expect(confirmAsOwner(s.collaborationId)).rejects.toThrow(
        '최대 현금 부담',
      );
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(await settlementOf(s.collaborationId)).toMatchObject({
        status: 'UNCONFIRMED',
        settledAt: null,
        confirmedBy: null,
      });
      expect(await prisma.payout.count()).toBe(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(await ledgerOf(s.collaborationId)).toHaveLength(before.length);
    });

    it('notifies the settlement once with the canvas text', async () => {
      const s = await seed();
      await submitAndSettle(s, 4320);
      // 계산이 만들어질 때의 알림(확인 요청)이 먼저, 확인 뒤의 정산 알림이 나중이다.
      expect(pushTo(s.creatorId).map((p) => p.body)).toEqual([
        '조회수 집계가 끝났어요. 계산을 확인해 보세요.',
        '정산 43,200원이 다음 주 수요일에 들어와요.',
      ]);
      expect(
        pushTo(s.ownerId)
          .map((p) => p.body)
          .filter((b) => b.startsWith('조회수 집계')),
      ).toEqual([
        '조회수 집계가 끝났어요. 자료를 확인해 주세요.',
        '조회수 집계가 끝났어요. 56,800원을 돌려드려요.',
      ]);
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

    it('sends the owner to the result screen from the settlement notice', async () => {
      const s = await seed();
      await submitAndSettle(s, 4320);
      expect(
        await prisma.notification.findMany({
          where: { kind: 'SETTLEMENT_REFUNDED' },
        }),
      ).toMatchObject([
        { targetKind: 'STORE_RESULT', targetId: s.collaborationId },
      ]);
    });

    it('says only that the settlement is over for a fixed cash only collaboration', async () => {
      const s = await seed({ rewardType: 'FIXED_ONLY', fixedCash: 30000 });
      await submitAndSettle(s, 'ignored');
      expect(
        pushTo(s.ownerId)
          .map((p) => p.body)
          .filter((b) => !b.includes('올렸어요')),
      ).toEqual(['정산이 끝났어요.']);
      expect(
        await prisma.notification.findMany({
          where: { kind: 'SETTLEMENT_REFUNDED' },
        }),
      ).toMatchObject([
        { targetKind: 'STORE_RESULT', targetId: s.collaborationId },
      ]);
    });

    it('sends no settlement notice to the owner of a voucher only collaboration', async () => {
      const s = await seed({ rewardType: 'VOUCHER' });
      await submit(s.collaborationId, REELS_URL).expect(200);
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(s.collaborationId)).stage).toBe('SETTLED');
      expect(
        await prisma.notification.count({
          where: { kind: 'SETTLEMENT_REFUNDED' },
        }),
      ).toBe(0);
    });

    describe('usual views of the store account', () => {
      it('saves the usual views and a 3.1 multiplier once when the collaboration settles', async () => {
        const s = await seed({
          ratePerThousand: 2000,
          perViewCap: 60000,
          instagram: 'https://www.instagram.com/haru_cup/',
        });
        const read = jest.spyOn(app.get(ViewCountPort), 'readAccountAverage');
        await submitAndSettle(s, 12500);
        // 12500 / 4000 = 3.125 → 31
        expect(await settlementOf(s.collaborationId)).toMatchObject({
          finalViews: 12500,
          usualViews: 4000,
          multiplierTenths: 31,
          usualReadAt: new Date(T0.getTime() + 7 * DAY),
        });
        expect(read).toHaveBeenCalledTimes(1);
        expect(read).toHaveBeenCalledWith('haru_cup');
        // 같은 작업이 다시 돌아도 다시 읽지 않는다.
        const job = settleJob(s.collaborationId);
        await scheduler.registry.run(job.name, job.payload);
        expect(read).toHaveBeenCalledTimes(1);
      });

      it('does not read the usual views again when the first read failed', async () => {
        const s = await seed({
          instagram: 'https://www.instagram.com/unavailable_store/',
        });
        const read = jest.spyOn(app.get(ViewCountPort), 'readAccountAverage');
        await submitAndSettle(s, 4320);
        const row = await settlementOf(s.collaborationId);
        expect(row).toMatchObject({ usualViews: null, multiplierTenths: null });
        expect(row.usualReadAt).not.toBeNull();
        const job = settleJob(s.collaborationId);
        await scheduler.registry.run(job.name, job.payload);
        expect(read).toHaveBeenCalledTimes(1);
      });

      it('leaves the comparison empty for a store without an instagram link', async () => {
        const s = await seed();
        const read = jest.spyOn(app.get(ViewCountPort), 'readAccountAverage');
        await submitAndSettle(s, 4320);
        const row = await settlementOf(s.collaborationId);
        expect(row).toMatchObject({ usualViews: null, multiplierTenths: null });
        expect(row.usualReadAt).not.toBeNull();
        expect(read).not.toHaveBeenCalled();
      });

      it('leaves the multiplier empty when the usual views are zero', async () => {
        const s = await seed({
          instagram: 'https://www.instagram.com/haru_cup/',
        });
        jest
          .spyOn(app.get(ViewCountPort), 'readAccountAverage')
          .mockResolvedValue(0);
        await submitAndSettle(s, 4320);
        expect(await settlementOf(s.collaborationId)).toMatchObject({
          usualViews: null,
          multiplierTenths: null,
        });
      });

      it('fails the confirmation steps on an unexpected error and fills the usual views on the retry', async () => {
        const s = await seed({
          ratePerThousand: 2000,
          perViewCap: 60000,
          instagram: 'https://www.instagram.com/haru_cup/',
        });
        // ViewCountUnavailableError만 "못 읽음"으로 삼킨다. 그 밖의 오류는 던져 다시 돌게 한다(돈은 이미 옮겨졌다).
        jest
          .spyOn(app.get(ViewCountPort), 'readAccountAverage')
          .mockRejectedValueOnce(new Error('boom'));
        await submit(s.collaborationId, `${REELS_URL}?views=12500`).expect(200);
        clock.set(new Date(T0.getTime() + 7 * DAY));
        await scheduler.runDue(clock.now());
        clock.set(new Date(T0.getTime() + 9 * DAY));
        const ran = await scheduler.runDue(clock.now(), {
          allowFailures: true,
        });
        expect(
          ran.some(
            (j) =>
              j.name === 'settlement-auto-confirm' && j.status === 'failed',
          ),
        ).toBe(true);
        expect((await settlementOf(s.collaborationId)).usualReadAt).toBeNull();
        // 큐가 같은 작업을 다시 돌리면 이미 확인된 정산의 남은 단계를 이어서 한다.
        await scheduler.registry.run('settlement-auto-confirm', {
          collaborationId: s.collaborationId,
        });
        expect(await settlementOf(s.collaborationId)).toMatchObject({
          usualViews: 4000,
          multiplierTenths: 31,
        });
      });

      it('does not read the usual views for a fixed cash only collaboration', async () => {
        const s = await seed({
          rewardType: 'FIXED_ONLY',
          fixedCash: 30000,
          instagram: 'https://www.instagram.com/haru_cup/',
        });
        const read = jest.spyOn(app.get(ViewCountPort), 'readAccountAverage');
        await submitAndSettle(s, 'ignored');
        expect(read).not.toHaveBeenCalled();
        expect((await settlementOf(s.collaborationId)).usualReadAt).toBeNull();
      });
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
      // 돌려줄 돈이 0원이어도 G1로 가는 길이 이 알림뿐이라 금액 문장 없는 알림이 나간다.
      expect(
        await prisma.notification.findMany({
          where: { kind: 'SETTLEMENT_REFUNDED' },
        }),
      ).toMatchObject([
        {
          targetKind: 'STORE_RESULT',
          targetId: s.collaborationId,
          dedupeKey: `settle-refund:${s.collaborationId}`,
        },
      ]);
      expect(
        pushTo(s.ownerId)
          .map((p) => p.body)
          .filter((b) => b.startsWith('조회수 집계')),
      ).toEqual([
        '조회수 집계가 끝났어요. 자료를 확인해 주세요.',
        '조회수 집계가 끝났어요.',
      ]);
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
      await scheduler.runDue(clock.now());
      await expect(confirmAsOwner(s.collaborationId)).rejects.toThrow(
        'process died',
      );
      // 정산은 커밋됐고 환급은 아직 나가지 않았다.
      expect((await collaborationOf(s.collaborationId)).stage).toBe('SETTLED');
      expect(await prisma.refund.findMany()).toMatchObject([
        { amount: 56800, status: 'PENDING' },
      ]);
      expect(pg.refunds).toHaveLength(0);

      // 큐가 자동 확인 작업을 때가 되어 돌리면 이미 확인된 정산의 남은 단계를 이어서 한다.
      clock.set(new Date(T0.getTime() + 9 * DAY));
      await scheduler.runDue(clock.now());
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
      await confirmAsOwner(s.collaborationId);
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

    it('waits for a capture instead of settling when no snapshot is readable at settlement time', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=unavailable`).expect(
        200,
      );
      const job = settleJob(s.collaborationId);
      await scheduler.registry.run(job.name, job.payload);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(await prisma.settlement.count()).toBe(0);
      expect(await prisma.payout.count()).toBe(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(alert).not.toHaveBeenCalled();
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(100000);

      // 캡처가 오지 않으면 기한에 멈춘다.
      await scheduler.registry.run('evidence-missing-halt', {
        collaborationId: s.collaborationId,
      });
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'COUNTING',
        haltedReason: 'VIEW_COUNT_UNAVAILABLE',
      });
      expect(await prisma.settlement.count()).toBe(0);
      expect(alert).toHaveBeenCalledTimes(1);
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(100000);
    });

    it('keeps every collaboration ledger balanced after each scenario', async () => {
      // 옛 금액(단가 10,000원, 상한 100,000원), 새 기본값(2,000원, 60,000원), 고정 현금만, 고정 현금 + 조회수 수당 모두.
      // burden은 최대 현금 부담이다.
      for (const [over, burden] of [
        [{}, 100000],
        [{ ratePerThousand: 2000, perViewCap: 60000 }, 60000],
        [{ rewardType: 'FIXED_ONLY', fixedCash: 30000 }, 30000],
        [
          {
            rewardType: 'PER_VIEW',
            fixedCash: 30000,
            ratePerThousand: 2000,
            perViewCap: 60000,
          },
          90000,
        ],
      ] as const) {
        for (const views of [0, 4320, 12500, 9999999]) {
          const s = await seed(over);
          await submitAndSettle(s, views);
          const entries = await ledgerOf(s.collaborationId);
          assertBalanced(entries);
          expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(0);
          // 낸 돈 전부(최대 현금 부담 + 수수료)가 지급 예정, 환급, 수수료로 남김없이 나뉜다.
          const total =
            (await accountOf(s.collaborationId, 'CREATOR_PAYABLE')) +
            (await accountOf(s.collaborationId, 'STORE_REFUND')) +
            (await accountOf(s.collaborationId, 'FEE_REVENUE'));
          expect(total).toBe(burden + Math.floor(burden / 10));
          scheduler.jobs.length = 0;
          clock.set(T0);
        }
      }
      // 시나리오 열여섯 개가 원격 DB에 줄지어 쓴다. 판본·오퍼 닫기 쿼리가 더해져 기본 30초로는 모자란다.
    }, 120000);
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
    });
  });
  describe('unsubmitted refund', () => {
    const DUE = new Date(T0.getTime() + 14 * DAY);

    it('refunds cap and fee 14 days after funding when nothing was submitted', async () => {
      const s = await seed();
      clock.set(DUE);
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(s.collaborationId)).stage).toBe('REFUNDED');
      // 장부: 에스크로와 수수료 수익이 모두 환급 계정으로 간다.
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(110000);
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await accountOf(s.collaborationId, 'FEE_REVENUE')).toBe(0);
      expect(await prisma.refund.findMany()).toMatchObject([
        { amount: 110000, status: 'DONE' },
      ]);
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0]).toMatchObject({
        pgTransactionId: `tx-${s.collaborationId}`,
        amount: 110000,
      });
      expect(await prisma.payout.count()).toBe(0);
      // 사장님에게는 환급 문구, 크리에이터에게는 종료 문구.
      expect(pushTo(s.ownerId).map((p) => p.body)).toEqual([
        '기한 안에 콘텐츠가 올라오지 않아 110,000원을 돌려드려요.',
      ]);
      expect(pushTo(s.creatorId).map((p) => p.body)).toContain(
        '제출 기한이 지나 협업이 종료됐어요.',
      );
      const rows = await prisma.notification.findMany({
        where: { kind: { in: ['UNSUBMITTED_REFUNDED', 'UNSUBMITTED_ENDED'] } },
      });
      expect(rows.map((r) => r.dedupeKey)).toEqual([
        `unsubmitted:${s.collaborationId}`,
        `unsubmitted:${s.collaborationId}`,
      ]);
    });

    it('does not refund when a link was submitted on day 13', async () => {
      const s = await seed();
      clock.set(new Date(T0.getTime() + 13 * DAY));
      await submit(s.collaborationId, `${REELS_URL}?views=100`).expect(200);
      clock.set(DUE);
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(await prisma.refund.count()).toBe(0);
      expect(pg.refunds).toHaveLength(0);
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(0);
      // 취소가 실패해 작업이 남아 있어도 처리기가 단계를 보고 아무 일도 하지 않는다.
      await scheduler.registry.run('refund-unsubmitted', {
        collaborationId: s.collaborationId,
      });
      expect(await prisma.refund.count()).toBe(0);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
    });

    it('does not refund twice when the job runs twice', async () => {
      const s = await seed();
      clock.set(DUE);
      await scheduler.runDue(clock.now());
      const entries = (await ledgerOf(s.collaborationId)).length;
      const payload = { collaborationId: s.collaborationId };
      await scheduler.registry.run('refund-unsubmitted', payload);
      await scheduler.registry.run('refund-unsubmitted', payload);
      expect(await prisma.refund.count()).toBe(1);
      expect(pg.refunds).toHaveLength(1);
      expect((await ledgerOf(s.collaborationId)).length).toBe(entries);
      expect(
        await prisma.notification.count({
          where: {
            kind: { in: ['UNSUBMITTED_REFUNDED', 'UNSUBMITTED_ENDED'] },
          },
        }),
      ).toBe(2);
    });

    it('finishes the refund and the notices when the job died after the stage moved', async () => {
      const s = await seed();
      jest
        .spyOn(app.get(RefundsService), 'execute')
        .mockRejectedValueOnce(new Error('process died'));
      clock.set(DUE);
      await scheduler.runDue(clock.now(), { allowFailures: true });
      expect((await collaborationOf(s.collaborationId)).stage).toBe('REFUNDED');
      expect(await prisma.refund.findMany()).toMatchObject([
        { amount: 110000, status: 'PENDING' },
      ]);
      expect(pg.refunds).toHaveLength(0);

      await scheduler.registry.run('refund-unsubmitted', {
        collaborationId: s.collaborationId,
      });
      expect(await prisma.refund.findMany()).toMatchObject([
        { status: 'DONE' },
      ]);
      expect(pg.refunds).toHaveLength(1);
      expect(
        await prisma.notification.count({
          where: {
            kind: { in: ['UNSUBMITTED_REFUNDED', 'UNSUBMITTED_ENDED'] },
          },
        }),
      ).toBe(2);
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(110000);
    });

    it('ends a voucher-only collaboration without money', async () => {
      const s = await seed({ rewardType: 'VOUCHER' });
      clock.set(DUE);
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(s.collaborationId)).stage).toBe('REFUNDED');
      expect(await prisma.ledgerEntry.count()).toBe(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(pg.refunds).toHaveLength(0);
      // 양쪽 모두 종료 문구뿐이고 금액 문구는 없다. 크리에이터는 기한 전에 도는 기한 알림 둘도 받았다.
      expect(pushTo(s.ownerId).map((p) => p.body)).toEqual([
        '제출 기한이 지나 협업이 종료됐어요.',
      ]);
      expect(pushTo(s.creatorId).map((p) => p.body)).toEqual([
        '콘텐츠 제출 기한이 3일 남았어요.',
        '콘텐츠 제출 기한이 1일 남았어요.',
        '제출 기한이 지나 협업이 종료됐어요.',
      ]);
      expect(
        await prisma.notification.count({
          where: { kind: 'UNSUBMITTED_REFUNDED' },
        }),
      ).toBe(0);
      // 다시 돌아도 알림은 그대로다(종료 둘, 기한 알림 둘 + 제출 알림 없음).
      await scheduler.registry.run('refund-unsubmitted', {
        collaborationId: s.collaborationId,
      });
      expect(await prisma.notification.count()).toBe(4);
    });

    it('leaves a halted or settled collaboration alone', async () => {
      const s = await seed();
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: { stage: 'HALTED', stageBeforeHalt: 'FUNDED' },
      });
      clock.set(DUE);
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(s.collaborationId)).stage).toBe('HALTED');
      expect(await prisma.refund.count()).toBe(0);
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(100000);
    });

    it('does not touch a collaboration that an operator already refunded', async () => {
      const s = await seed();
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: { stage: 'REFUNDED' },
      });
      await scheduler.registry.run('refund-unsubmitted', {
        collaborationId: s.collaborationId,
      });
      expect(await prisma.refund.count()).toBe(0);
      expect(pg.refunds).toHaveLength(0);
    });
  });

  describe('submit reminders', () => {
    // 제출 기한은 2026-12-15 12:00 KST다. 알림은 3일 전(12-12)과 하루 전(12-14) 날의 10:00 KST에 간다.
    const THREE_DAYS = new Date('2026-12-12T01:00:00.000Z');
    const ONE_DAY = new Date('2026-12-14T01:00:00.000Z');

    it('reminds the creator 3 days and 1 day before the due date', async () => {
      const s = await seed();
      clock.set(new Date(THREE_DAYS.getTime() - MINUTE));
      await scheduler.runDue(clock.now());
      expect(pushTo(s.creatorId)).toHaveLength(0);

      clock.set(THREE_DAYS);
      await scheduler.runDue(clock.now());
      expect(pushTo(s.creatorId).map((p) => p.body)).toEqual([
        '콘텐츠 제출 기한이 3일 남았어요.',
      ]);

      clock.set(ONE_DAY);
      await scheduler.runDue(clock.now());
      expect(pushTo(s.creatorId).map((p) => p.body)).toEqual([
        '콘텐츠 제출 기한이 3일 남았어요.',
        '콘텐츠 제출 기한이 1일 남았어요.',
      ]);
      const rows = await prisma.notification.findMany({
        where: { kind: 'SUBMIT_REMINDER' },
        orderBy: { createdAt: 'asc' },
      });
      expect(rows.map((r) => r.dedupeKey)).toEqual([
        `reminder:${s.collaborationId}:3`,
        `reminder:${s.collaborationId}:1`,
      ]);
      expect(rows[0]).toMatchObject({
        userId: s.creatorId,
        targetKind: 'COLLABORATION',
        targetId: s.collaborationId,
      });
    });

    it('sends one reminder when the job runs twice', async () => {
      const s = await seed();
      clock.set(THREE_DAYS);
      await scheduler.runDue(clock.now());
      await scheduler.registry.run('submit-reminder', {
        collaborationId: s.collaborationId,
        daysLeft: 3,
      });
      expect(
        await prisma.notification.count({ where: { kind: 'SUBMIT_REMINDER' } }),
      ).toBe(1);
    });

    it('does not remind a creator who already submitted', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=100`).expect(200);
      clock.set(ONE_DAY);
      await scheduler.runDue(clock.now());
      // 작업이 남아 있어도 단계가 FUNDED가 아니면 보내지 않는다.
      await scheduler.registry.run('submit-reminder', {
        collaborationId: s.collaborationId,
        daysLeft: 1,
      });
      expect(
        await prisma.notification.count({ where: { kind: 'SUBMIT_REMINDER' } }),
      ).toBe(0);
    });
  });
  describe('fix round 1', () => {
    const settlePayload = (id: string) => ({ collaborationId: id });

    it('waits for a capture instead of settling on day 4 when days 5 to 7 are unreadable and settle runs before the day 7 snapshot', async () => {
      const s = await seed();
      jest
        .spyOn(app.get(ViewCountPort), 'read')
        .mockResolvedValueOnce(100)
        .mockResolvedValueOnce(200)
        .mockResolvedValueOnce(300)
        .mockResolvedValueOnce(400)
        .mockResolvedValueOnce(500)
        .mockRejectedValue(new ViewCountUnavailableError());
      await submit(s.collaborationId, REELS_URL).expect(200);
      // 0~6일의 작업을 돌린다(5, 6일은 읽지 못한다).
      clock.set(new Date(T0.getTime() + 6 * DAY));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(alert).not.toHaveBeenCalled();

      // 7일째: 정산 작업이 7일째 스냅샷 작업보다 먼저 돈다. 4일째 값으로 정산하지 않고 캡처를 기다린다.
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.registry.run('settle', settlePayload(s.collaborationId));
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(await prisma.settlement.count()).toBe(0);
      expect(await prisma.payout.count()).toBe(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(100000);
      expect(
        await prisma.notification.count({
          where: { kind: 'VIEW_EVIDENCE_REQUESTED' },
        }),
      ).toBe(1);
      expect(alert).not.toHaveBeenCalled();

      // 기한(기간이 끝난 뒤 3일)에 멈춘다. 뒤늦게 도는 7일째 작업과 남은 작업은 취소돼 경보가 더 나가지 않는다.
      clock.set(new Date(T0.getTime() + 10 * DAY));
      await scheduler.runDue(clock.now());
      expect(await collaborationOf(s.collaborationId)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'COUNTING',
        haltedReason: 'VIEW_COUNT_UNAVAILABLE',
      });
      expect(alert).toHaveBeenCalledTimes(1);
      await scheduler.runDue(clock.now());
      expect(alert).toHaveBeenCalledTimes(1);
      expect(
        await prisma.notification.count({
          where: { kind: 'COLLABORATION_HALTED' },
        }),
      ).toBe(2);
    });

    it('finishes the halt on a retried evidence deadline job when the halt notice failed', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=unavailable`).expect(
        200,
      );
      await scheduler.registry.run('settle', settlePayload(s.collaborationId));
      const payload = { collaborationId: s.collaborationId };
      jest
        .spyOn(app.get(NotificationsService), 'notify')
        .mockRejectedValueOnce(new Error('inbox down'));
      await expect(
        scheduler.registry.run('evidence-missing-halt', payload),
      ).rejects.toThrow('inbox down');
      expect((await collaborationOf(s.collaborationId)).stage).toBe('HALTED');
      expect(
        await prisma.notification.count({
          where: { kind: 'COLLABORATION_HALTED' },
        }),
      ).toBe(0);

      await scheduler.registry.run('evidence-missing-halt', payload);
      expect(
        await prisma.notification.count({
          where: { kind: 'COLLABORATION_HALTED' },
        }),
      ).toBe(2);
      expect(await prisma.settlement.count()).toBe(0);
    });

    it('sends no false alarm when the halt loses the race to another transition', async () => {
      const s = await seed();
      await submit(s.collaborationId, REELS_URL).expect(200);
      // 정산이 먼저 이겨 협업이 이미 COUNTING이 아니다: 읽어 둔 낡은 협업 객체로 멈추려 한다.
      const stale = await collaborationOf(s.collaborationId);
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: { stage: 'SETTLED' },
      });
      await app.get(SettlementsService).halt(stale);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('SETTLED');
      expect(alert).not.toHaveBeenCalled();
      expect(await prisma.notification.count()).toBe(1);
    });

    it('rejects a submission at or after the due time and accepts one just before it', async () => {
      const s = await seed();
      const due = new Date(T0.getTime() + 14 * DAY);
      clock.set(due);
      const res = await submit(s.collaborationId, REELS_URL).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
      clock.set(new Date(due.getTime() + DAY));
      await submit(s.collaborationId, REELS_URL).expect(409);

      clock.set(new Date(due.getTime() - 1));
      await submit(s.collaborationId, REELS_URL).expect(200);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
    });

    it('does not announce an unsubmitted end that another path already made for a voucher-only collaboration', async () => {
      const s = await seed({ rewardType: 'VOUCHER' });
      await prisma.collaboration.update({
        where: { id: s.collaborationId },
        data: { stage: 'REFUNDED' },
      });
      await scheduler.registry.run('refund-unsubmitted', {
        collaborationId: s.collaborationId,
      });
      expect(await prisma.notification.count()).toBe(0);
    });

    it('refunds through the payment that started the escrow even when another approved payment is older', async () => {
      const s = await seed();
      // 뒤늦게 승인돼 협업에 반영되지 못한 다른 결제. 승인 시각이 더 이르다.
      await prisma.payment.create({
        data: {
          collaborationId: s.collaborationId,
          amountEscrow: 100000,
          amountFee: 10000,
          feeRate: 10,
          method: 'CARD',
          status: 'APPROVED',
          pgTransactionId: 'tx-late',
          requestedAt: new Date(T0.getTime() - 2 * DAY),
          approvedAt: new Date(T0.getTime() - DAY),
        },
      });
      clock.set(new Date(T0.getTime() + 14 * DAY));
      await scheduler.runDue(clock.now());
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0].pgTransactionId).toBe(`tx-${s.collaborationId}`);
    });

    describe('when the PG refund fails', () => {
      it('alerts the operator only on the final attempt, keeps the refund pending and finishes on a later retry', async () => {
        const s = await seed();
        const refund = jest
          .spyOn(pg, 'refund')
          .mockRejectedValue(new Error('pg down'));
        await submit(s.collaborationId, `${REELS_URL}?views=4320`).expect(200);
        clock.set(new Date(T0.getTime() + 7 * DAY));
        await scheduler.runDue(clock.now());
        clock.set(new Date(T0.getTime() + 9 * DAY));
        // 환급은 확인 완료의 뒷단계라 자동 확인 작업이 한다(7일째 작업은 계산만 만든다).
        const payload = settlePayload(s.collaborationId);
        const run = (finalAttempt: boolean) =>
          scheduler.registry.run('settlement-auto-confirm', payload, {
            finalAttempt,
          });

        // 마지막이 아닌 시도: 던지고, 행은 PENDING, 운영자 알림 없음. 크리에이터 정산 알림은 이미 나갔다.
        await expect(run(false)).rejects.toThrow('pg down');
        expect(alert).not.toHaveBeenCalled();
        expect(await prisma.refund.findMany()).toMatchObject([
          { amount: 56800, status: 'PENDING' },
        ]);
        expect(
          await prisma.notification.count({
            where: { kind: 'SETTLEMENT_CONFIRMED' },
          }),
        ).toBe(1);
        expect(
          await prisma.notification.count({
            where: { kind: 'SETTLEMENT_REFUNDED' },
          }),
        ).toBe(0);

        // 마지막 시도: 운영자에게 한 번 알린다.
        await expect(run(true)).rejects.toThrow('pg down');
        expect(alert).toHaveBeenCalledTimes(1);
        expect(alert).toHaveBeenCalledWith(
          expect.objectContaining({
            subject: '환급을 보내지 못했어요. 확인해 주세요.',
          }),
        );

        // 나중 재시도(예: 운영자가 PG를 고친 뒤)는 같은 행으로 환급을 마친다.
        refund.mockRestore();
        await run(true);
        expect(await prisma.refund.findMany()).toMatchObject([
          { status: 'DONE' },
        ]);
        expect(pg.refunds).toHaveLength(1);
        expect(
          await prisma.notification.count({
            where: { kind: 'SETTLEMENT_REFUNDED' },
          }),
        ).toBe(1);
        expect(
          await prisma.notification.count({
            where: { kind: 'SETTLEMENT_CONFIRMED' },
          }),
        ).toBe(1);
        expect(alert).toHaveBeenCalledTimes(1);
      });

      it('does the same for an unsubmitted refund', async () => {
        const s = await seed();
        jest.spyOn(pg, 'refund').mockRejectedValueOnce(new Error('pg down'));
        const payload = { collaborationId: s.collaborationId };
        await expect(
          scheduler.registry.run('refund-unsubmitted', payload, {
            finalAttempt: false,
          }),
        ).rejects.toThrow('pg down');
        expect(alert).not.toHaveBeenCalled();
        expect(await prisma.refund.findMany()).toMatchObject([
          { amount: 110000, status: 'PENDING' },
        ]);
        await scheduler.registry.run('refund-unsubmitted', payload);
        expect(await prisma.refund.findMany()).toMatchObject([
          { status: 'DONE' },
        ]);
        expect(pg.refunds).toHaveLength(1);
        expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(110000);
      });
    });
  });
  describe('follow-up round (R43)', () => {
    const settlePayload = (id: string) => ({ collaborationId: id });

    it('completes the halt on a rerun when the operator alert fails on the first run', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=unavailable`).expect(
        200,
      );
      await scheduler.registry.run('settle', settlePayload(s.collaborationId));
      const payload = { collaborationId: s.collaborationId };
      alert.mockRejectedValueOnce(new Error('mail down'));
      await expect(
        scheduler.registry.run('evidence-missing-halt', payload),
      ).rejects.toThrow('mail down');
      // 알림이 실패했으므로 협업은 멈췄지만 다시 돌 작업은 그대로 남아 있다.
      expect((await collaborationOf(s.collaborationId)).stage).toBe('HALTED');
      expect(jobKeys()).toContain(`settle:${s.collaborationId}`);
      expect(jobKeys()).toContain(`evidence-halt:${s.collaborationId}`);
      expect(
        await prisma.notification.count({
          where: { kind: 'COLLABORATION_HALTED' },
        }),
      ).toBe(0);

      await scheduler.registry.run('evidence-missing-halt', payload);
      expect(alert).toHaveBeenCalledTimes(2);
      expect(
        await prisma.notification.count({
          where: { kind: 'COLLABORATION_HALTED' },
        }),
      ).toBe(2);
      expect(jobKeys().filter((k) => k.startsWith('view-snapshot'))).toEqual(
        [],
      );
      expect(jobKeys()).not.toContain(`settle:${s.collaborationId}`);
      expect(jobKeys()).not.toContain(`evidence-halt:${s.collaborationId}`);
    });

    it('keeps the remaining jobs when the inbox is down so a rerun can still notify', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=unavailable`).expect(
        200,
      );
      await scheduler.registry.run('settle', settlePayload(s.collaborationId));
      const payload = { collaborationId: s.collaborationId };
      jest
        .spyOn(app.get(NotificationsService), 'notify')
        .mockRejectedValueOnce(new Error('inbox down'));
      await expect(
        scheduler.registry.run('evidence-missing-halt', payload),
      ).rejects.toThrow('inbox down');
      expect(jobKeys()).toContain(`settle:${s.collaborationId}`);
      await scheduler.registry.run('evidence-missing-halt', payload);
      expect(
        await prisma.notification.count({
          where: { kind: 'COLLABORATION_HALTED' },
        }),
      ).toBe(2);
      expect(jobKeys()).not.toContain(`settle:${s.collaborationId}`);
    });

    it('waits for a capture instead of settling on day 4 when day 5 is unreadable, day 6 has no row and day 7 is unreadable', async () => {
      const s = await seed();
      jest
        .spyOn(app.get(ViewCountPort), 'read')
        .mockResolvedValueOnce(100)
        .mockResolvedValueOnce(200)
        .mockResolvedValueOnce(300)
        .mockResolvedValueOnce(400)
        .mockResolvedValueOnce(500)
        .mockRejectedValue(new ViewCountUnavailableError());
      await submit(s.collaborationId, REELS_URL).expect(200);
      // 6일째 작업이 시도를 다 쓰고 죽었다고 보고 지운다.
      await scheduler.cancel(`view-snapshot:${s.collaborationId}:6`);
      clock.set(new Date(T0.getTime() + 5 * DAY));
      await scheduler.runDue(clock.now());
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.registry.run('settle', settlePayload(s.collaborationId));

      const days = (await snapshotsOf(s.collaborationId)).map((r) => [
        r.dayIndex,
        r.views,
      ]);
      expect(days).toEqual([
        [0, 100],
        [1, 200],
        [2, 300],
        [3, 400],
        [4, 500],
        [5, null],
        [7, null],
      ]);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(jobKeys()).toContain(`evidence-halt:${s.collaborationId}`);
      expect(await prisma.settlement.count()).toBe(0);
      expect(await prisma.payout.count()).toBe(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(alert).not.toHaveBeenCalled();
    });

    it('still settles on the day 7 count when days 5 and 6 have no row but day 7 is readable', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=4320`).expect(200);
      await scheduler.cancel(`view-snapshot:${s.collaborationId}:5`);
      await scheduler.cancel(`view-snapshot:${s.collaborationId}:6`);
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      expect(await prisma.settlement.findMany()).toMatchObject([
        { finalViews: 4320, payoutAmount: 43200 },
      ]);
    });

    it('records a day as unreadable instead of throwing on the final attempt of an unexpected read error', async () => {
      const s = await seed();
      await submit(s.collaborationId, REELS_URL).expect(200);
      jest
        .spyOn(app.get(ViewCountPort), 'read')
        .mockRejectedValue(new Error('socket hang up'));
      const payload = { collaborationId: s.collaborationId, dayIndex: 0 };
      // 마지막이 아닌 시도는 던져 큐가 다시 시도하게 하고, 줄을 남기지 않는다.
      await expect(
        scheduler.registry.run('view-snapshot', payload, {
          finalAttempt: false,
        }),
      ).rejects.toThrow('socket hang up');
      expect(await snapshotsOf(s.collaborationId)).toHaveLength(0);
      // 마지막 시도는 읽지 못한 날(null)로 기록한다. 0이 아니다.
      await scheduler.registry.run('view-snapshot', payload, {
        finalAttempt: true,
      });
      const rows = await snapshotsOf(s.collaborationId);
      expect(rows.map((r) => [r.dayIndex, r.views])).toEqual([[0, null]]);
    });
  });
});
