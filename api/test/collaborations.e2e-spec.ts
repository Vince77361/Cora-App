import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import {
  CollaborationStage,
  ContentFormat,
  PrismaClient,
  RewardType,
} from '@prisma/client';
import request from 'supertest';
import { scheduleSubmissionDeadlineJobs } from '../src/collaborations/collaboration-jobs';
import { Clock } from '../src/common/clock';
import { FakePaymentAdapter } from '../src/integrations/payment/fake-payment.adapter';
import { PaymentPort } from '../src/integrations/payment/payment.port';
import { PushPort } from '../src/integrations/push/push.port';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { assertBalanced } from '../src/ledger/ledger-postings';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { OTHER, USER_A } from './support/fake-token-verifier';

// user-a는 크리에이터, user-b는 사장님이다.
const creatorAuth = { Authorization: 'Bearer user-a' };
const ownerAuth = { Authorization: 'Bearer user-b' };
// 한국 시간 낮 12시(화): 방해 금지 시간이 아니라 푸시가 나간다.
const T0 = new Date('2026-12-01T03:00:00.000Z');
const MINUTE = 60 * 1000;
const DAY = 24 * 60 * MINUTE;
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const REELS_URL = 'https://www.instagram.com/reel/C8abc123/';
// 제출 7일 뒤(2026-12-08 화)에 정산되면 지급일은 다음 주 수요일 2026-12-16 10:00 KST다.
const PAYDAY = new Date('2026-12-16T01:00:00.000Z');

interface StepBody {
  key: string;
  state: string;
  at: string | null;
}
interface CollaborationBody {
  id: string;
  kind: string;
  stage: string;
  role: string;
  counterpart: { name: string; photoUrl: string | null };
  store: { id: string; name: string } | null;
  terms: Record<string, unknown>;
  steps: StepBody[];
  escrowAmount: number;
  submitDueAt: string | null;
  submittedUrl: string | null;
  countingEndsAt: string | null;
  currentViews: number | null;
  earnedSoFar: number | null;
  expectedRefund: number | null;
  settlement: {
    finalViews: number | null;
    payoutAmount: number;
    refundAmount: number;
  } | null;
  payoutStatus: string;
  payoutScheduledFor: string | null;
  cancelRequest: {
    id: string;
    requestedByMe: boolean;
    expiresAt: string;
  } | null;
  canCancel: boolean;
  canRequestCancel: boolean;
}

interface Seeded {
  ownerId: string;
  storeId: string;
  creatorId: string;
  offerId: string;
  collaborationId: string;
}

// 시나리오 하나가 원격 DB에 여러 번 쓰므로 기본 5초로는 모자란다.
jest.setTimeout(30000);

describe('collaborations', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let scheduler: FakeJobScheduler;
  let push: FakePushPort;
  let pg: FakePaymentAdapter;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const bodyOf = (res: request.Response) => res.body as CollaborationBody;
  const get = (id: string, auth = creatorAuth) =>
    request(server).get(`/collaborations/${id}`).set(auth);
  const list = (scope: string, auth = creatorAuth) =>
    request(server).get(`/collaborations?scope=${scope}`).set(auth);
  const cancel = (id: string, auth = creatorAuth) =>
    request(server).post(`/collaborations/${id}/cancel`).set(auth);
  const requestCancel = (id: string, auth = ownerAuth) =>
    request(server).post(`/collaborations/${id}/cancel-requests`).set(auth);
  const accept = (id: string, requestId: string, auth = creatorAuth) =>
    request(server)
      .post(`/collaborations/${id}/cancel-requests/${requestId}/accept`)
      .set(auth);
  const submit = (id: string, url: string) =>
    request(server)
      .post(`/collaborations/${id}/submission`)
      .set(creatorAuth)
      .send({ url });
  const registerAccount = () =>
    request(server)
      .put('/payout-account')
      .set(creatorAuth)
      .send({
        bankCode: '004',
        accountNumber: '110123456789',
        holderName: '김민지',
      })
      .expect(200);
  const collaborationOf = (id: string) =>
    prisma.collaboration.findUniqueOrThrow({ where: { id } });
  const jobKeys = () => scheduler.pending().map((j) => j.jobKey);
  const pushTo = (userId: string) =>
    push.sent.filter((p) => p.userId === userId);
  const ledgerOf = (id: string) =>
    prisma.ledgerEntry.findMany({ where: { collaborationId: id } });
  const accountOf = async (collaborationId: string, account: string) =>
    (await ledgerOf(collaborationId)).reduce(
      (sum, r) =>
        sum +
        (r.creditAccount === account ? r.amount : 0) -
        (r.debitAccount === account ? r.amount : 0),
      0,
    );
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

  // 크리에이터는 USER_A, 사장님은 OTHER다. 협업은 보관이 시작된(FUNDED) 상태로 DB에 바로 만들고,
  // 결제와 장부도 결제 승인 직후와 같게 채운다(상한 = 에스크로 100,000원, 수수료 10%).
  async function seed(
    over: {
      stage?: CollaborationStage;
      rewardType?: RewardType;
      perViewCap?: number;
      paymentDueAt?: Date;
    } = {},
  ): Promise<Seeded> {
    const rewardType = over.rewardType ?? 'BOTH';
    const perView = rewardType !== 'VOUCHER';
    const perViewCap = over.perViewCap ?? 100000;
    const awaiting = over.stage === 'AWAITING_PAYMENT';
    await prisma.user.create({ data: { id: OTHER, role: 'STORE' } });
    const store = await prisma.store.create({
      data: {
        ownerId: OTHER,
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
    if (perView) {
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
      format: 'REELS' as ContentFormat,
      rewardType,
      voucherName: rewardType === 'PER_VIEW' ? null : '2인 식사권',
      voucherValue: rewardType === 'PER_VIEW' ? null : 40000,
      perViewAmount: perView ? 10 : null,
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
        paymentDueAt: over.paymentDueAt ?? null,
      },
    });
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: over.stage ?? 'FUNDED',
        commissionerId: OTHER,
        creatorId: USER_A,
        offerId: offer.id,
        storeId: store.id,
        terms,
        settlementMethod: perView ? 'PER_VIEW' : 'NONE',
        createdAt: T0,
        fundedAt: awaiting ? null : T0,
        submitDueAt: awaiting ? null : new Date(T0.getTime() + 14 * DAY),
      },
    });
    if (perView && !awaiting) {
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
    if (!awaiting) {
      // 결제 뒤(또는 식사권만 있는 오퍼를 수락한 뒤)의 사후 단계가 올려 둔 제출 기한 작업.
      await scheduleSubmissionDeadlineJobs(
        scheduler,
        collaboration.id,
        new Date(T0.getTime() + 14 * DAY),
        T0,
      );
    }
    return {
      ownerId: OTHER,
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
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    scheduler.jobs.length = 0;
    push.sent.length = 0;
    pg.refunds.length = 0;
    clock.set(T0);
  });
  afterEach(async () => {
    // 어떤 시나리오가 끝나도 모든 협업의 장부는 불변식을 지킨다.
    await expectEveryLedgerBalanced();
    jest.restoreAllMocks();
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  describe('reading', () => {
    it('rejects requests with no token and bad ids', async () => {
      await request(server).get('/collaborations?scope=active').expect(401);
      await request(server).get(`/collaborations/${randomUUID()}`).expect(401);
      await request(server)
        .post(`/collaborations/${randomUUID()}/cancel`)
        .expect(401);
      await list('nope').expect(400);
      await list('').expect(400);
    });

    it('shows five steps with VISIT as NOW right after funding', async () => {
      const s = await seed();
      const res = await get(s.collaborationId).expect(200);
      const body = bodyOf(res);
      expect(body).toMatchObject({
        id: s.collaborationId,
        kind: 'STORE_OFFER',
        stage: 'FUNDED',
        role: 'CREATOR',
        escrowAmount: 100000,
        submitDueAt: new Date(T0.getTime() + 14 * DAY).toISOString(),
        submittedUrl: null,
        countingEndsAt: null,
        currentViews: null,
        earnedSoFar: null,
        expectedRefund: null,
        settlement: null,
        payoutStatus: 'NONE',
        payoutScheduledFor: null,
        cancelRequest: null,
        canCancel: true,
        canRequestCancel: false,
      });
      expect(body.steps.map((x) => [x.key, x.state])).toEqual([
        ['ACCEPTED', 'DONE'],
        ['PAID', 'DONE'],
        ['VISIT', 'NOW'],
        ['SUBMIT', 'TODO'],
        ['SETTLE', 'TODO'],
      ]);
      expect(body.steps[0].at).toBe(T0.toISOString());
      expect(body.steps[1].at).toBe(T0.toISOString());
      // 크리에이터에게는 가게가 상대다.
      expect(body.counterpart).toEqual({ name: '하루 한 컵', photoUrl: null });
      expect(body.store).toMatchObject({
        id: s.storeId,
        name: '하루 한 컵',
      });
      expect(body.terms).toEqual({
        format: 'REELS',
        rewardType: 'BOTH',
        voucherName: '2인 식사권',
        voucherValue: 40000,
        perViewAmount: 10,
        perViewCap: 100000,
      });
    });

    it('shows the owner the creator as the counterpart', async () => {
      const s = await seed();
      const body = bodyOf(await get(s.collaborationId, ownerAuth).expect(200));
      expect(body).toMatchObject({
        role: 'COMMISSIONER',
        canCancel: false,
        canRequestCancel: true,
        escrowAmount: 100000,
      });
      expect(body.counterpart).toEqual({ name: '모카', photoUrl: null });
    });

    it('treats PAID as done from the start for a voucher-only offer', async () => {
      const s = await seed({ rewardType: 'VOUCHER' });
      const body = bodyOf(await get(s.collaborationId).expect(200));
      expect(body.escrowAmount).toBe(0);
      expect(body.steps.map((x) => x.state)).toEqual([
        'DONE',
        'DONE',
        'NOW',
        'TODO',
        'TODO',
      ]);
      expect(body.payoutStatus).toBe('NONE');
    });

    it('shows earned so far to the creator and expected refund to the owner only', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=4320`).expect(200);
      await scheduler.runDue(clock.now());

      const creator = bodyOf(await get(s.collaborationId).expect(200));
      expect(creator).toMatchObject({
        stage: 'COUNTING',
        currentViews: 4320,
        earnedSoFar: 43200,
        expectedRefund: null,
        submittedUrl: `${REELS_URL}?views=4320`,
        countingEndsAt: new Date(T0.getTime() + 7 * DAY).toISOString(),
        canCancel: false,
      });
      expect(creator.steps.map((x) => x.state)).toEqual([
        'DONE',
        'DONE',
        'DONE',
        'DONE',
        'NOW',
      ]);
      const owner = bodyOf(await get(s.collaborationId, ownerAuth).expect(200));
      expect(owner).toMatchObject({
        currentViews: 4320,
        earnedSoFar: null,
        expectedRefund: 56800,
        canRequestCancel: false,
      });
    });

    it('returns the collaboration model from the submission endpoint', async () => {
      const s = await seed();
      const res = await submit(s.collaborationId, REELS_URL).expect(200);
      expect(bodyOf(res)).toMatchObject({
        id: s.collaborationId,
        stage: 'COUNTING',
        role: 'CREATOR',
        submittedUrl: REELS_URL,
      });
    });

    it('returns 404 for a collaboration I am not part of', async () => {
      const s = await seed();
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
      // 아직 사장님은 당사자다.
      await get(s.collaborationId, ownerAuth).expect(200);
      expect(codeOf(await get(s.collaborationId).expect(404))).toBe(
        'NOT_FOUND',
      );
      await cancel(s.collaborationId).expect(404);
      await request(server)
        .post(`/collaborations/${s.collaborationId}/cancel-requests`)
        .set(creatorAuth)
        .expect(404);
      await get(randomUUID()).expect(404);
      await get('not-a-uuid').expect(404);
      expect(await list('active')).toMatchObject({ body: [] });
    });

    it('lists only my collaborations by scope, newest first', async () => {
      const first = await seed();
      // 같은 크리에이터의 두 번째 협업(다른 가게).
      const secondOwner = await prisma.user.create({
        data: { id: randomUUID(), role: 'STORE' },
      });
      const secondStore = await prisma.store.create({
        data: {
          ownerId: secondOwner.id,
          status: 'PUBLISHED',
          onboardingStep: 'DONE',
          name: '두 번째 가게',
          ...REGION,
          defaultFormat: 'REELS',
          defaultRewardType: 'VOUCHER',
          publishedAt: T0,
        },
      });
      const terms = {
        format: 'REELS',
        rewardType: 'VOUCHER',
        voucherName: '커피 쿠폰',
        voucherValue: 5000,
        perViewAmount: null,
        perViewCap: null,
      };
      const make = (stage: CollaborationStage, createdAt: Date) =>
        prisma.collaboration.create({
          data: {
            kind: 'STORE_OFFER',
            stage,
            commissionerId: secondOwner.id,
            creatorId: USER_A,
            storeId: secondStore.id,
            terms,
            settlementMethod: 'NONE',
            createdAt,
          },
        });
      const done = await make('SETTLED', new Date(T0.getTime() + DAY));
      const cancelled = await make(
        'CANCELLED',
        new Date(T0.getTime() + 2 * DAY),
      );
      const halted = await make('HALTED', new Date(T0.getTime() + 3 * DAY));
      // 남의 협업은 보이지 않는다.
      const stranger = await prisma.user.create({
        data: { id: randomUUID(), role: 'CREATOR' },
      });
      await prisma.collaboration.create({
        data: {
          kind: 'STORE_OFFER',
          stage: 'FUNDED',
          commissionerId: secondOwner.id,
          creatorId: stranger.id,
          storeId: secondStore.id,
          terms,
          settlementMethod: 'NONE',
        },
      });

      const active = bodyOf2(await list('active').expect(200));
      expect(active.map((c) => c.id)).toEqual([
        halted.id,
        first.collaborationId,
      ]);
      expect(active.map((c) => c.stage)).toEqual(['HALTED', 'FUNDED']);
      const finished = bodyOf2(await list('done').expect(200));
      expect(finished.map((c) => c.id)).toEqual([cancelled.id, done.id]);
      // 사장님은 자기가 맡긴 협업만 본다.
      const owner = bodyOf2(await list('active', ownerAuth).expect(200));
      expect(owner.map((c) => c.id)).toEqual([first.collaborationId]);
    });

    it('expires an unpaid offer past its payment due date when read', async () => {
      const s = await seed({
        stage: 'AWAITING_PAYMENT',
        paymentDueAt: new Date(T0.getTime() - MINUTE),
      });
      const body = bodyOf(await get(s.collaborationId).expect(200));
      expect(body.stage).toBe('CANCELLED');
      expect(bodyOf2(await list('done').expect(200)).map((c) => c.id)).toEqual([
        s.collaborationId,
      ]);
    });

    function bodyOf2(res: request.Response): CollaborationBody[] {
      return res.body as CollaborationBody[];
    }
  });

  describe('payout status', () => {
    // 제출하고 7일을 지나 정산까지 돌린다(조회수 4,320회 → 지급 43,200원, 환급 56,800원).
    async function submitAndSettle(s: Seeded): Promise<void> {
      await submit(s.collaborationId, `${REELS_URL}?views=4320`).expect(200);
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
    }

    it('reports NEEDS_ACCOUNT when settled without a payout account', async () => {
      const s = await seed();
      await submitAndSettle(s);
      const creator = bodyOf(await get(s.collaborationId).expect(200));
      expect(creator).toMatchObject({
        stage: 'SETTLED',
        settlement: {
          finalViews: 4320,
          payoutAmount: 43200,
          refundAmount: 56800,
        },
        payoutStatus: 'NEEDS_ACCOUNT',
        payoutScheduledFor: null,
        currentViews: 4320,
        earnedSoFar: null,
        expectedRefund: null,
      });
      expect(creator.steps.every((x) => x.state === 'DONE')).toBe(true);
      // 사장님에게는 크리에이터의 계좌 사정을 드러내지 않는다.
      const owner = bodyOf(await get(s.collaborationId, ownerAuth).expect(200));
      expect(owner).toMatchObject({
        payoutStatus: 'PENDING',
        payoutScheduledFor: null,
      });
    });

    it('moves from PENDING with the payday to DONE after the transfer', async () => {
      const s = await seed();
      await registerAccount();
      await submitAndSettle(s);
      expect(bodyOf(await get(s.collaborationId).expect(200))).toMatchObject({
        payoutStatus: 'PENDING',
        payoutScheduledFor: PAYDAY.toISOString(),
      });
      clock.set(PAYDAY);
      await scheduler.runDue(clock.now());
      expect(bodyOf(await get(s.collaborationId).expect(200))).toMatchObject({
        payoutStatus: 'DONE',
        payoutScheduledFor: null,
      });
    });

    it('turns PENDING once the account is registered after settling', async () => {
      const s = await seed();
      await submitAndSettle(s);
      await registerAccount();
      expect(bodyOf(await get(s.collaborationId).expect(200))).toMatchObject({
        payoutStatus: 'PENDING',
        payoutScheduledFor: PAYDAY.toISOString(),
      });
    });

    it('reports NONE when the payout is 0 won', async () => {
      const s = await seed();
      await submit(s.collaborationId, `${REELS_URL}?views=0`).expect(200);
      clock.set(new Date(T0.getTime() + 7 * DAY));
      await scheduler.runDue(clock.now());
      expect(bodyOf(await get(s.collaborationId).expect(200))).toMatchObject({
        stage: 'SETTLED',
        settlement: { finalViews: 0, payoutAmount: 0, refundAmount: 100000 },
        payoutStatus: 'NONE',
      });
    });
  });

  describe('creator cancel', () => {
    it('lets the creator cancel a funded collaboration with a full refund including the fee', async () => {
      const s = await seed();
      const res = await cancel(s.collaborationId).expect(200);
      expect(bodyOf(res)).toMatchObject({
        id: s.collaborationId,
        stage: 'CANCELLED',
        canCancel: false,
        canRequestCancel: false,
      });
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'CANCELLED',
      );

      // 장부: 에스크로 10만 원과 수수료 1만 원이 모두 환급 계정으로.
      expect(await accountOf(s.collaborationId, 'ESCROW')).toBe(0);
      expect(await accountOf(s.collaborationId, 'FEE_REVENUE')).toBe(0);
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(110000);
      const keys = (await ledgerOf(s.collaborationId)).map(
        (r) => r.idempotencyKey,
      );
      expect(
        keys.filter((k) => k === `cancel:${s.collaborationId}`),
      ).toHaveLength(2);

      // 환급은 110,000원이 PG로 나갔다.
      const refunds = await prisma.refund.findMany();
      expect(refunds).toHaveLength(1);
      expect(refunds[0]).toMatchObject({
        amount: 110000,
        status: 'DONE',
        idempotencyKey: `cancel-refund:${s.collaborationId}`,
      });
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0]).toMatchObject({
        pgTransactionId: `tx-${s.collaborationId}`,
        amount: 110000,
      });

      // 기한 작업은 모두 지워진다.
      expect(
        jobKeys().filter((k) => k.startsWith('refund-unsubmitted')),
      ).toEqual([]);
      expect(jobKeys().filter((k) => k.startsWith('submit-reminder'))).toEqual(
        [],
      );

      // 사장님에게 한 번만 알린다.
      expect(pushTo(s.ownerId).map((p) => p.body)).toEqual([
        '모카님이 협업을 그만뒀어요. 110,000원을 돌려드려요.',
      ]);
      const rows = await prisma.notification.findMany({
        where: { userId: s.ownerId },
      });
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        kind: 'CREATOR_CANCELLED',
        dedupeKey: `cancelled:${s.collaborationId}`,
        targetKind: 'COLLABORATION',
        targetId: s.collaborationId,
        actorUserId: USER_A,
        actorName: '모카',
        params: { amount: 110000 },
      });
    });

    it('refuses to cancel twice and does not move money twice', async () => {
      const s = await seed();
      await cancel(s.collaborationId).expect(200);
      const second = await cancel(s.collaborationId).expect(409);
      expect(codeOf(second)).toBe('CONFLICT');
      expect(await prisma.refund.count()).toBe(1);
      expect(pg.refunds).toHaveLength(1);
      expect(await ledgerOf(s.collaborationId)).toHaveLength(4);
      expect(await prisma.notification.count()).toBe(1);
    });

    it('cancels a voucher-only collaboration without moving money', async () => {
      const s = await seed({ rewardType: 'VOUCHER' });
      await cancel(s.collaborationId).expect(200);
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'CANCELLED',
      );
      expect(await ledgerOf(s.collaborationId)).toHaveLength(0);
      expect(await prisma.refund.count()).toBe(0);
      expect(pg.refunds).toHaveLength(0);
      // 돈이 없으니 환급 문장 없이 그만뒀다는 소식만 간다.
      expect(pushTo(s.ownerId).map((p) => p.body)).toEqual([
        '모카님이 협업을 그만뒀어요.',
      ]);
      expect(
        jobKeys().filter((k) => k.startsWith('refund-unsubmitted')),
      ).toEqual([]);
    });

    it('refuses to cancel while counting', async () => {
      const s = await seed();
      await submit(s.collaborationId, REELS_URL).expect(200);
      const res = await cancel(s.collaborationId).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect((await collaborationOf(s.collaborationId)).stage).toBe('COUNTING');
      expect(await prisma.refund.count()).toBe(0);
    });

    it('refuses to cancel other stages', async () => {
      for (const stage of [
        'AWAITING_PAYMENT',
        'SETTLED',
        'REFUNDED',
      ] as const) {
        const s = await seed({ stage });
        await cancel(s.collaborationId).expect(409);
        await truncateTestDb(prisma);
      }
    });

    it('forbids the owner from cancelling alone', async () => {
      const s = await seed();
      const res = await cancel(s.collaborationId, ownerAuth).expect(403);
      expect(codeOf(res)).toBe('FORBIDDEN');
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
      expect(await prisma.refund.count()).toBe(0);
    });

    it('still cancels when the owner notification cannot be saved', async () => {
      const s = await seed();
      jest
        .spyOn(app.get(PushPort), 'send')
        .mockRejectedValue(new Error('push down'));
      await cancel(s.collaborationId).expect(200);
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'CANCELLED',
      );
    });
  });

  describe('owner cancel request', () => {
    it('lets the owner request a cancel and the creator accept it', async () => {
      const s = await seed();
      const created = await requestCancel(s.collaborationId).expect(201);
      const expiresAt = new Date(T0.getTime() + 3 * DAY);
      const request1 = bodyOf(created).cancelRequest;
      expect(request1).toEqual({
        id: expect.any(String) as string,
        requestedByMe: true,
        expiresAt: expiresAt.toISOString(),
      });
      expect(bodyOf(created)).toMatchObject({
        stage: 'FUNDED',
        canRequestCancel: false,
      });
      const row = await prisma.cancelRequest.findFirstOrThrow();
      expect(row).toMatchObject({
        id: request1?.id,
        collaborationId: s.collaborationId,
        requestedById: s.ownerId,
        status: 'PENDING',
        expiresAt,
      });

      // 3일 뒤 만료 작업과 크리에이터에게 가는 알림.
      const job = scheduler
        .pending()
        .find((j) => j.name === 'cancel-request-expiry');
      expect(job).toMatchObject({
        jobKey: `cancel-request:${row.id}`,
        runAt: expiresAt,
        payload: { cancelRequestId: row.id },
      });
      expect(pushTo(s.creatorId).map((p) => p.body)).toEqual([
        '하루 한 컵이 협업 취소를 요청했어요.',
      ]);
      expect(
        await prisma.notification.findFirstOrThrow({
          where: { userId: s.creatorId },
        }),
      ).toMatchObject({
        kind: 'CANCEL_REQUESTED',
        dedupeKey: `cancel-requested:${row.id}`,
        targetKind: 'COLLABORATION',
        targetId: s.collaborationId,
        actorUserId: s.ownerId,
      });

      // 크리에이터 쪽에서는 받은 요청으로 보인다.
      const creatorView = bodyOf(await get(s.collaborationId).expect(200));
      expect(creatorView.cancelRequest).toEqual({
        id: row.id,
        requestedByMe: false,
        expiresAt: expiresAt.toISOString(),
      });
      expect(creatorView.canCancel).toBe(true);

      // 크리에이터가 동의하면 크리에이터가 직접 그만둔 것과 같다.
      const accepted = await accept(s.collaborationId, row.id).expect(200);
      expect(bodyOf(accepted)).toMatchObject({
        stage: 'CANCELLED',
        cancelRequest: null,
      });
      expect(
        (
          await prisma.cancelRequest.findUniqueOrThrow({
            where: { id: row.id },
          })
        ).status,
      ).toBe('ACCEPTED');
      expect(await accountOf(s.collaborationId, 'STORE_REFUND')).toBe(110000);
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0].amount).toBe(110000);
      expect(pushTo(s.ownerId).map((p) => p.body)).toEqual([
        '모카님이 협업을 그만뒀어요. 110,000원을 돌려드려요.',
      ]);
      expect(
        jobKeys().filter((k) => k.startsWith('refund-unsubmitted')),
      ).toEqual([]);

      // 같은 동의를 다시 눌러도 아무 일도 없다.
      await accept(s.collaborationId, row.id).expect(409);
      expect(await prisma.refund.count()).toBe(1);
      expect(await ledgerOf(s.collaborationId)).toHaveLength(4);
    });

    it('refuses a second pending cancel request', async () => {
      const s = await seed();
      await requestCancel(s.collaborationId).expect(201);
      const second = await requestCancel(s.collaborationId).expect(409);
      expect(codeOf(second)).toBe('CONFLICT');
      expect(await prisma.cancelRequest.count()).toBe(1);
      expect(
        scheduler.pending().filter((j) => j.name === 'cancel-request-expiry'),
      ).toHaveLength(1);
      expect(
        await prisma.notification.count({
          where: { kind: 'CANCEL_REQUESTED' },
        }),
      ).toBe(1);
    });

    it('serializes simultaneous cancel requests into one', async () => {
      const s = await seed();
      const results = await Promise.all([
        requestCancel(s.collaborationId),
        requestCancel(s.collaborationId),
        requestCancel(s.collaborationId),
      ]);
      expect(results.map((r) => r.status).sort()).toEqual([201, 409, 409]);
      expect(await prisma.cancelRequest.count()).toBe(1);
    });

    it('forbids the creator from requesting and the owner from accepting', async () => {
      const s = await seed();
      const bad = await requestCancel(s.collaborationId, creatorAuth).expect(
        403,
      );
      expect(codeOf(bad)).toBe('FORBIDDEN');
      expect(await prisma.cancelRequest.count()).toBe(0);

      await requestCancel(s.collaborationId).expect(201);
      const row = await prisma.cancelRequest.findFirstOrThrow();
      await accept(s.collaborationId, row.id, ownerAuth).expect(403);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
    });

    it('refuses a request unless the collaboration is funded', async () => {
      const s = await seed();
      await submit(s.collaborationId, REELS_URL).expect(200);
      expect(codeOf(await requestCancel(s.collaborationId).expect(409))).toBe(
        'CONFLICT',
      );
      expect(await prisma.cancelRequest.count()).toBe(0);
    });

    it('returns 404 when accepting a request that is not on this collaboration', async () => {
      const s = await seed();
      await requestCancel(s.collaborationId).expect(201);
      await accept(s.collaborationId, randomUUID()).expect(404);
      await accept(s.collaborationId, 'not-a-uuid').expect(404);
      const other = await seed2(s);
      const row = await prisma.cancelRequest.findFirstOrThrow();
      await accept(other, row.id).expect(404);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
    });

    // 같은 가게·크리에이터의 두 번째 협업.
    async function seed2(s: Seeded): Promise<string> {
      const terms = (await collaborationOf(s.collaborationId)).terms;
      const row = await prisma.collaboration.create({
        data: {
          kind: 'STORE_OFFER',
          stage: 'FUNDED',
          commissionerId: s.ownerId,
          creatorId: s.creatorId,
          storeId: s.storeId,
          terms: terms as object,
          settlementMethod: 'NONE',
          fundedAt: T0,
        },
      });
      return row.id;
    }

    it('expires an unanswered cancel request after 3 days', async () => {
      const s = await seed();
      await requestCancel(s.collaborationId).expect(201);
      const row = await prisma.cancelRequest.findFirstOrThrow();

      // 3일이 되기 전에는 그대로다.
      clock.set(new Date(T0.getTime() + 3 * DAY - MINUTE));
      await scheduler.runDue(clock.now(), { allowFailures: false });
      expect(
        (
          await prisma.cancelRequest.findUniqueOrThrow({
            where: { id: row.id },
          })
        ).status,
      ).toBe('PENDING');

      clock.set(new Date(T0.getTime() + 3 * DAY));
      await scheduler.runDue(clock.now());
      expect(
        (
          await prisma.cancelRequest.findUniqueOrThrow({
            where: { id: row.id },
          })
        ).status,
      ).toBe('EXPIRED');
      // 협업은 그대로이고, 요청은 사라진 것으로 보이며, 사장님은 다시 보낼 수 있다.
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
      const creatorView = bodyOf(await get(s.collaborationId).expect(200));
      expect(creatorView.cancelRequest).toBeNull();
      expect(
        bodyOf(await get(s.collaborationId, ownerAuth).expect(200)),
      ).toMatchObject({ cancelRequest: null, canRequestCancel: true });
      // 만료된 요청에는 동의할 수 없다.
      await accept(s.collaborationId, row.id).expect(409);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
      await requestCancel(s.collaborationId).expect(201);
    });

    it('treats a request past its time as gone even before the expiry job runs', async () => {
      const s = await seed();
      await requestCancel(s.collaborationId).expect(201);
      const row = await prisma.cancelRequest.findFirstOrThrow();
      clock.set(new Date(T0.getTime() + 3 * DAY + MINUTE));
      expect(
        bodyOf(await get(s.collaborationId).expect(200)).cancelRequest,
      ).toBeNull();
      await accept(s.collaborationId, row.id).expect(409);
      // 새 요청은 낡은 요청을 정리하고 만들어진다.
      await requestCancel(s.collaborationId).expect(201);
      const rows = await prisma.cancelRequest.findMany({
        orderBy: { createdAt: 'asc' },
      });
      expect(rows.map((r) => r.status)).toEqual(['EXPIRED', 'PENDING']);
    });

    it('leaves an accepted request alone when its expiry job runs', async () => {
      const s = await seed();
      await requestCancel(s.collaborationId).expect(201);
      const row = await prisma.cancelRequest.findFirstOrThrow();
      await accept(s.collaborationId, row.id).expect(200);
      clock.set(new Date(T0.getTime() + 3 * DAY));
      await scheduler.runDue(clock.now());
      expect(
        (
          await prisma.cancelRequest.findUniqueOrThrow({
            where: { id: row.id },
          })
        ).status,
      ).toBe('ACCEPTED');
    });
  });
});
