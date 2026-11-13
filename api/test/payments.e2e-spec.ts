import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import {
  CollaborationStage,
  PaymentStatus,
  Prisma,
  PrismaClient,
  SettlementMethod,
} from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { FakePaymentAdapter } from '../src/integrations/payment/fake-payment.adapter';
import { OperatorAlertPort } from '../src/integrations/operator-alert/operator-alert.port';
import { PaymentPort } from '../src/integrations/payment/payment.port';
import { PushPort } from '../src/integrations/push/push.port';
import { JobHandlerRegistry } from '../src/jobs/job-handler-registry';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { NotificationsService } from '../src/notifications/notifications.service';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { USER_A } from './support/fake-token-verifier';
import { createOffer } from './helpers/create-offer';

const auth = { Authorization: 'Bearer user-a' };
// 한국 시간 낮 12시: 방해 금지 시간이 아니라 푸시가 나간다.
const T0 = new Date('2026-12-01T03:00:00.000Z');
const MINUTE = 60 * 1000;
const DAY = 24 * 60 * MINUTE;
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
// 새 기본 조건: 식사권 + 1,000회당 2,000원, 상한 60,000원(최대 현금 부담 60,000원, 수수료 6,000원).
const COLUMNS = {
  format: 'REELS',
  voucherName: '식사권',
  voucherValue: 40000,
  voucherPeople: 2,
  fixedCash: 0,
  viewRatePerThousand: 2000,
  perViewCap: 60000,
  usageRights: 'STORE_REPOST_3M',
} as const;
const TERMS = { ...COLUMNS, pieces: 1 } as const;

interface QuoteBody {
  escrow: number;
  fee: number;
  feeRate: number;
  total: number;
  orderName: string;
  creatorName: string;
  creatorPhotoUrl: string | null;
  format: string;
  pieces: number;
  voucherName: string | null;
}
interface CreatedBody {
  paymentId: string;
  checkoutUrl: string;
}
interface Seeded {
  ownerId: string;
  storeId: string;
  creatorId: string;
  offerId: string;
  collaborationId: string;
}

describe('payments', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let scheduler: FakeJobScheduler;
  let push: FakePushPort;
  let pg: FakePaymentAdapter;
  let alert: jest.SpyInstance;

  const quote = (collaborationId: string) =>
    request(server)
      .get(`/collaborations/${collaborationId}/payment-quote`)
      .set(auth);
  const pay = (collaborationId: string, method = 'CARD') =>
    request(server)
      .post(`/collaborations/${collaborationId}/payments`)
      .set(auth)
      .send({ method });
  const statusOf = (paymentId: string) =>
    request(server).get(`/payments/${paymentId}`).set(auth);
  // PG가 서명해 보낸 통지를 그대로 흉내 낸다(웹훅은 로그인 없이 열려 있다).
  const webhook = (
    paymentId: string,
    status: 'APPROVED' | 'FAILED',
    signature?: string,
  ) => {
    const signed = pg.recordFakeResult({ paymentId, status });
    const req = request(server)
      .post('/webhooks/payments')
      .set('content-type', 'application/json');
    return (
      signature === undefined
        ? req.set('x-cora-signature', signed.signature)
        : req.set('x-cora-signature', signature)
    ).send(signed.rawBody);
  };
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;

  // 사장님(USER_A)의 공개된 가게, 크리에이터, 수락된 조회수 오퍼와 결제를 기다리는 협업을 DB에 바로 만든다.
  async function seed(
    over: {
      stage?: CollaborationStage;
      commissionerId?: string;
      paymentDueAt?: Date | null;
      // 이미 저장된 협업의 조건 사본(고정 현금처럼 아직 새로 만들 수 없는 값을 읽는 길을 확인할 때).
      copy?: Prisma.InputJsonObject;
      settlementMethod?: SettlementMethod;
    } = {},
  ): Promise<Seeded> {
    const ownerId = over.commissionerId ?? USER_A;
    await prisma.user.upsert({
      where: { id: ownerId },
      update: {},
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
    const creatorId = randomUUID();
    await prisma.user.create({ data: { id: creatorId, role: 'CREATOR' } });
    await prisma.creatorProfile.create({
      data: { userId: creatorId, displayName: '모카', ...REGION },
    });
    const due =
      over.paymentDueAt === undefined
        ? new Date(T0.getTime() + 3 * DAY)
        : over.paymentDueAt;
    const offer = await createOffer(prisma, {
      storeId: store.id,
      creatorId,
      ...COLUMNS,
      status: 'ACCEPTED',
      expiresAt: new Date(T0.getTime() + 7 * DAY),
      createdAt: T0,
      acceptedAt: T0,
      paymentDueAt: due,
    });
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: over.stage ?? 'AWAITING_PAYMENT',
        commissionerId: ownerId,
        creatorId,
        offerId: offer.id,
        storeId: store.id,
        terms: over.copy ?? TERMS,
        settlementMethod: over.settlementMethod ?? 'PER_VIEW',
      },
    });
    if (due) {
      await scheduler.schedule(
        'payment-due-expiry',
        { offerId: offer.id },
        due,
        `payment-due:${offer.id}`,
      );
    }
    return {
      ownerId,
      storeId: store.id,
      creatorId,
      offerId: offer.id,
      collaborationId: collaboration.id,
    };
  }

  async function startPayment(collaborationId: string): Promise<string> {
    const res = await pay(collaborationId).expect(201);
    return (res.body as CreatedBody).paymentId;
  }
  const ledgerOf = (collaborationId: string) =>
    prisma.ledgerEntry.findMany({
      where: { collaborationId },
      orderBy: { createdAt: 'asc' },
    });
  const collaborationOf = (id: string) =>
    prisma.collaboration.findUniqueOrThrow({ where: { id } });
  const paymentStatus = async (id: string): Promise<PaymentStatus> =>
    (await prisma.payment.findUniqueOrThrow({ where: { id } })).status;
  const jobOf = (jobKey: string) =>
    scheduler.pending().find((j) => j.jobKey === jobKey);

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    scheduler = app.get<FakeJobScheduler>(JobScheduler);
    push = app.get<FakePushPort>(PushPort);
    pg = app.get<FakePaymentAdapter>(PaymentPort);
    alert = jest
      .spyOn(app.get(OperatorAlertPort), 'alert')
      .mockResolvedValue(undefined);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    scheduler.jobs.length = 0;
    push.sent.length = 0;
    alert.mockClear();
    clock.set(T0);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token except the signed webhook', async () => {
    const id = randomUUID();
    await request(server)
      .get(`/collaborations/${id}/payment-quote`)
      .expect(401);
    await request(server)
      .post(`/collaborations/${id}/payments`)
      .send({ method: 'CARD' })
      .expect(401);
    await request(server).get(`/payments/${id}`).expect(401);
    // 웹훅은 토큰이 아니라 서명으로 막는다.
    await request(server).post('/webhooks/payments').send({}).expect(401);
  });

  describe('quote', () => {
    it('quotes the maximum cash burden plus a 10 percent fee', async () => {
      // 최대 현금 부담 60,000원 + 수수료 6,000원 = 66,000원.
      const s = await seed();
      const res = await quote(s.collaborationId).expect(200);
      expect(res.body).toEqual({
        escrow: 60000,
        fee: 6000,
        feeRate: 10,
        total: 66000,
        orderName: expect.any(String) as string,
        creatorName: '모카',
        creatorPhotoUrl: null,
        format: 'REELS',
        pieces: 1,
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        fixedCash: 0,
        perViewCap: 60000,
      });
      expect((res.body as QuoteBody).orderName.length).toBeGreaterThan(0);
    });

    it('quotes fixed cash plus the cap plus the fee', async () => {
      const s = await seed({ copy: { ...TERMS, fixedCash: 30000 } });
      expect((await quote(s.collaborationId).expect(200)).body).toMatchObject({
        escrow: 90000,
        fee: 9000,
        total: 99000,
        fixedCash: 30000,
        perViewCap: 60000,
      });
    });

    it('quotes fixed cash only without a view pay cap', async () => {
      const s = await seed({
        copy: {
          ...TERMS,
          voucherName: null,
          voucherValue: null,
          voucherPeople: null,
          viewRatePerThousand: null,
          perViewCap: null,
          fixedCash: 30000,
        },
        settlementMethod: 'FIXED',
      });
      expect((await quote(s.collaborationId).expect(200)).body).toMatchObject({
        escrow: 30000,
        fee: 3000,
        total: 33000,
        fixedCash: 30000,
        perViewCap: null,
      });
    });

    it('quotes a legacy copy with the same amounts as before', async () => {
      const s = await seed({
        copy: {
          format: 'REELS',
          rewardType: 'BOTH',
          voucherName: '2인 식사권',
          voucherValue: 40000,
          perViewAmount: 10,
          perViewCap: 100000,
        },
      });
      expect((await quote(s.collaborationId).expect(200)).body).toMatchObject({
        escrow: 100000,
        fee: 10000,
        total: 110000,
        voucherName: '식사권',
      });
    });

    it('lets only the store owner who commissioned the collaboration read it', async () => {
      // 남의 가게의 협업은 없는 협업과 같다.
      const other = await seed({ commissionerId: randomUUID() });
      // 로그인한 사람(USER_A)은 사장님이지만 이 협업을 맡긴 사람이 아니다.
      await prisma.user.create({ data: { id: USER_A, role: 'STORE' } });
      await quote(other.collaborationId).expect(404);
      await pay(other.collaborationId).expect(404);
      const paymentId = randomUUID();
      await statusOf(paymentId).expect(404);
      await quote('not-a-uuid').expect(404);
    });

    it('forbids a creator account', async () => {
      const s = await seed({ commissionerId: randomUUID() });
      await prisma.user.upsert({
        where: { id: USER_A },
        update: { role: 'CREATOR' },
        create: { id: USER_A, role: 'CREATOR' },
      });
      const res = await quote(s.collaborationId).expect(403);
      expect(codeOf(res)).toBe('FORBIDDEN');
      await pay(s.collaborationId).expect(403);
    });

    it('rejects a quote for a collaboration that is not awaiting payment', async () => {
      const s = await seed({ stage: 'FUNDED' });
      const res = await quote(s.collaborationId).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
    });

    it('expires an offer whose payment due time has passed and answers 409', async () => {
      const s = await seed();
      clock.set(new Date(T0.getTime() + 3 * DAY + 1));
      await quote(s.collaborationId).expect(409);
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'CANCELLED',
      );
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: s.offerId } }))
          .status,
      ).toBe('EXPIRED');
      await pay(s.collaborationId).expect(409);
    });
  });

  describe('creating a payment', () => {
    it('creates a pending payment with the checkout url and schedules a recheck in ten minutes', async () => {
      const s = await seed();
      const res = await pay(s.collaborationId, 'EASY_PAY').expect(201);
      const body = res.body as CreatedBody;
      expect(body.checkoutUrl).toBe(
        `cora-dev://fake-pay?paymentId=${body.paymentId}`,
      );
      const row = await prisma.payment.findUniqueOrThrow({
        where: { id: body.paymentId },
      });
      expect(row).toMatchObject({
        collaborationId: s.collaborationId,
        amountEscrow: 60000,
        amountFee: 6000,
        feeRate: 10,
        method: 'EASY_PAY',
        status: 'PENDING',
      });
      const recheck = jobOf(`payment-recheck:${body.paymentId}:1`);
      expect(recheck?.name).toBe('payment-recheck');
      expect(recheck?.runAt).toEqual(new Date(T0.getTime() + 10 * MINUTE));
      await statusOf(body.paymentId).expect(200, { status: 'PENDING' });
    });

    it('rejects a payment for a collaboration that is not awaiting payment', async () => {
      const s = await seed({ stage: 'FUNDED' });
      const res = await pay(s.collaborationId).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(await prisma.payment.count()).toBe(0);
    });

    it('rejects an unknown payment method', async () => {
      const s = await seed();
      await pay(s.collaborationId, 'CRYPTO').expect(400);
    });

    it('leaves exactly one pending payment when three creates arrive at the same time', async () => {
      const s = await seed();
      const results = await Promise.all([
        pay(s.collaborationId),
        pay(s.collaborationId),
        pay(s.collaborationId),
      ]);
      expect(results.map((r) => r.status)).toEqual([201, 201, 201]);
      const rows = await prisma.payment.findMany({
        where: { collaborationId: s.collaborationId },
      });
      expect(rows.filter((p) => p.status === 'PENDING')).toHaveLength(1);
      expect(rows.filter((p) => p.status === 'CANCELLED')).toHaveLength(2);
    });

    it('answers 409 and creates nothing when the owner cancels the offer first', async () => {
      const s = await seed();
      await request(server)
        .post(`/offers/${s.offerId}/cancel`)
        .set(auth)
        .send()
        .expect(200);
      await pay(s.collaborationId).expect(409);
      expect(await prisma.payment.count()).toBe(0);
    });

    it('replaces a pending payment when the owner starts again', async () => {
      const s = await seed();
      const first = await startPayment(s.collaborationId);
      const second = await startPayment(s.collaborationId);
      expect(second).not.toBe(first);
      expect(await paymentStatus(first)).toBe('CANCELLED');
      expect(await paymentStatus(second)).toBe('PENDING');
      await statusOf(first).expect(200, { status: 'CANCELLED' });
    });
  });

  describe('webhook', () => {
    it('funds exactly the quoted escrow', async () => {
      const s = await seed();
      const quoted = (await quote(s.collaborationId).expect(200))
        .body as QuoteBody;
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'APPROVED').expect(200);

      const ledger = await ledgerOf(s.collaborationId);
      const escrow = ledger
        .filter((e) => e.creditAccount === 'ESCROW')
        .reduce((sum, e) => sum + e.amount, 0);
      // 견적에 보인 금액이 그대로 보관되고, 그보다 큰 돈은 들어오지 않는다.
      expect(escrow).toBe(quoted.escrow);
      expect(escrow).toBe(60000);
      const payment = await prisma.payment.findUniqueOrThrow({
        where: { id: paymentId },
      });
      expect(payment.amountEscrow + payment.amountFee).toBe(quoted.total);
    });

    it('funds fixed cash plus the cap as the quoted escrow and keeps the fee apart', async () => {
      // 고정 현금 30,000원 + 상한 60,000원 = 보관 90,000원, 수수료 9,000원.
      const s = await seed({
        copy: { ...TERMS, fixedCash: 30000 },
        settlementMethod: 'FIXED_AND_PER_VIEW',
      });
      const quoted = (await quote(s.collaborationId).expect(200))
        .body as QuoteBody;
      expect(quoted).toMatchObject({ escrow: 90000, fee: 9000, total: 99000 });
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'APPROVED').expect(200);
      const ledger = await ledgerOf(s.collaborationId);
      const sum = (account: string) =>
        ledger
          .filter((e) => e.creditAccount === account)
          .reduce((total, e) => total + e.amount, 0);
      expect(sum('ESCROW')).toBe(90000);
      expect(sum('FEE_REVENUE')).toBe(9000);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
    });

    it('funds the collaboration on an approved webhook', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'APPROVED').expect(200);

      const collaboration = await collaborationOf(s.collaborationId);
      expect(collaboration.stage).toBe('FUNDED');
      expect(collaboration.fundedAt).toEqual(T0);
      expect(collaboration.submitDueAt).toEqual(
        new Date(T0.getTime() + 14 * DAY),
      );
      const payment = await prisma.payment.findUniqueOrThrow({
        where: { id: paymentId },
      });
      expect(payment.status).toBe('APPROVED');
      expect(payment.approvedAt).toEqual(T0);
      expect(payment.pgTransactionId).toBe(`fake-tx-${paymentId}`);
      await statusOf(paymentId).expect(200, { status: 'APPROVED' });

      const ledger = await ledgerOf(s.collaborationId);
      expect(
        ledger.map((e) => [e.debitAccount, e.creditAccount, e.amount]).sort(),
      ).toEqual([
        ['PG_IN', 'ESCROW', 60000],
        ['PG_IN', 'FEE_REVENUE', 6000],
      ]);
      expect(new Set(ledger.map((e) => e.idempotencyKey))).toEqual(
        new Set([`payment:${paymentId}`]),
      );
      // 결제 기한은 지워지고 오퍼는 수락 그대로다.
      const offer = await prisma.offer.findUniqueOrThrow({
        where: { id: s.offerId },
      });
      expect(offer.status).toBe('ACCEPTED');
      expect(offer.paymentDueAt).toBeNull();
    });

    it('tells the creator once with the store name and photo', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'APPROVED').expect(200);
      const rows = await prisma.notification.findMany({
        where: { userId: s.creatorId },
      });
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        kind: 'PAYMENT_FUNDED',
        role: 'CREATOR',
        actorUserId: s.ownerId,
        actorName: '하루 한 컵',
        targetKind: 'COLLABORATION',
        targetId: s.collaborationId,
        dedupeKey: `funded:${s.collaborationId}`,
      });
      expect(push.sent).toHaveLength(1);
      expect(push.sent[0]).toMatchObject({
        userId: s.creatorId,
        body: '하루 한 컵이 결제했어요. 방문하고 촬영해 주세요.',
      });
    });

    it('schedules the unsubmitted refund 14 days after funding', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'APPROVED').expect(200);
      const refund = jobOf(`refund-unsubmitted:${s.collaborationId}`);
      expect(refund).toMatchObject({
        name: 'refund-unsubmitted',
        payload: { collaborationId: s.collaborationId },
      });
      expect(refund?.runAt).toEqual(new Date(T0.getTime() + 14 * DAY));
    });

    it('schedules the submit reminders at 10:00 Korea time on the days 3 and 1 before the due date', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'APPROVED').expect(200);
      const three = jobOf(`submit-reminder:${s.collaborationId}:3`);
      const one = jobOf(`submit-reminder:${s.collaborationId}:1`);
      expect(three).toMatchObject({
        name: 'submit-reminder',
        payload: { collaborationId: s.collaborationId, daysLeft: 3 },
      });
      expect(one?.payload).toEqual({
        collaborationId: s.collaborationId,
        daysLeft: 1,
      });
      // 제출 기한은 12월 15일 12:00 KST다. 3일 전은 12일, 하루 전은 14일의 10:00 KST(=01:00Z).
      expect(three?.runAt).toEqual(new Date('2026-12-12T01:00:00.000Z'));
      expect(one?.runAt).toEqual(new Date('2026-12-14T01:00:00.000Z'));
    });

    it('cancels the payment due expiry job', async () => {
      const s = await seed();
      expect(jobOf(`payment-due:${s.offerId}`)).toBeDefined();
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'APPROVED').expect(200);
      expect(jobOf(`payment-due:${s.offerId}`)).toBeUndefined();
      // 기한이 지나도 결제한 협업은 그대로다.
      clock.set(new Date(T0.getTime() + 4 * DAY));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
    });

    it('ignores a second identical webhook', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      const signed = pg.recordFakeResult({ paymentId, status: 'APPROVED' });
      const send = () =>
        request(server)
          .post('/webhooks/payments')
          .set('content-type', 'application/json')
          .set('x-cora-signature', signed.signature)
          .send(signed.rawBody)
          .expect(200);
      await send();
      const afterFirst = await collaborationOf(s.collaborationId);
      clock.advance(5 * MINUTE);
      await send();

      expect(await ledgerOf(s.collaborationId)).toHaveLength(2);
      expect(await prisma.notification.count()).toBe(1);
      expect(push.sent).toHaveLength(1);
      const again = await collaborationOf(s.collaborationId);
      expect(again.fundedAt).toEqual(afterFirst.fundedAt);
      expect(again.submitDueAt).toEqual(afterFirst.submitDueAt);
      expect(
        scheduler.pending().filter((j) => j.name !== 'payment-recheck'),
      ).toHaveLength(3);
    });

    it('heals a crash between commit and notification when the notice is repeated', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      const signed = pg.recordFakeResult({ paymentId, status: 'APPROVED' });
      const send = () =>
        request(server)
          .post('/webhooks/payments')
          .set('content-type', 'application/json')
          .set('x-cora-signature', signed.signature)
          .send(signed.rawBody);
      await send().expect(200);
      // 커밋 뒤에 죽었다고 치고, 후속 단계가 남긴 것을 지운다.
      await prisma.notification.deleteMany();
      scheduler.jobs.length = 0;
      await send().expect(200);

      expect(await prisma.notification.count()).toBe(1);
      expect(jobOf(`refund-unsubmitted:${s.collaborationId}`)).toBeDefined();
      expect(jobOf(`submit-reminder:${s.collaborationId}:3`)).toBeDefined();
      // 장부와 단계는 그대로 한 번만 바뀌었다.
      expect(await ledgerOf(s.collaborationId)).toHaveLength(2);
      expect((await collaborationOf(s.collaborationId)).fundedAt).toEqual(T0);
    });

    it('rejects a webhook with a bad signature', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      const res = await webhook(paymentId, 'APPROVED', 'f'.repeat(64)).expect(
        401,
      );
      expect(codeOf(res)).toBe('UNAUTHENTICATED');
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'AWAITING_PAYMENT',
      );
      expect(await paymentStatus(paymentId)).toBe('PENDING');
      expect(await ledgerOf(s.collaborationId)).toHaveLength(0);
    });

    it('rejects a webhook with no signature header or a tampered body', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      const signed = pg.recordFakeResult({ paymentId, status: 'FAILED' });
      await request(server)
        .post('/webhooks/payments')
        .set('content-type', 'application/json')
        .send(signed.rawBody)
        .expect(401);
      await request(server)
        .post('/webhooks/payments')
        .set('content-type', 'application/json')
        .set('x-cora-signature', signed.signature)
        .send(signed.rawBody.replace('FAILED', 'APPROVED'))
        .expect(401);
      expect(await paymentStatus(paymentId)).toBe('PENDING');
    });

    it('leaves the collaboration awaiting payment on a failed webhook', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'FAILED').expect(200);
      expect(await paymentStatus(paymentId)).toBe('FAILED');
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'AWAITING_PAYMENT',
      );
      expect(await ledgerOf(s.collaborationId)).toHaveLength(0);
      expect(await prisma.notification.count()).toBe(0);
      // 결제 기한은 그대로라 다시 시도할 수 있다.
      const offer = await prisma.offer.findUniqueOrThrow({
        where: { id: s.offerId },
      });
      expect(offer.paymentDueAt).not.toBeNull();
      await pay(s.collaborationId).expect(201);
    });

    it('records a late approval without funding and alerts the operator', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      // 결제창이 열린 채 기한이 지나 협업이 끝났다.
      clock.set(new Date(T0.getTime() + 3 * DAY + 1));
      await scheduler.runDue(clock.now());
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'CANCELLED',
      );

      await webhook(paymentId, 'APPROVED').expect(200);
      expect(await paymentStatus(paymentId)).toBe('APPROVED');
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'CANCELLED',
      );
      expect(await ledgerOf(s.collaborationId)).toHaveLength(0);
      expect(await prisma.notification.count()).toBe(0);
      expect(alert).toHaveBeenCalledTimes(1);
      expect(alert).toHaveBeenCalledWith({
        subject:
          '협업에 반영하지 못한 결제가 승인됐어요. 운영 명령으로 환불해 주세요.',
        body: expect.stringContaining(paymentId) as string,
      });
      // 같은 통지가 또 와도 운영자에게 다시 알리지 않는다.
      await webhook(paymentId, 'APPROVED').expect(200);
      expect(alert).toHaveBeenCalledTimes(1);
    });

    // 계획의 "다시 시도" 흐름: 결제창을 닫고(결제가 완료되지 않았어요) 다시 결제하면 첫 결제는 취소로 바뀐다.
    // 그런데 첫 결제창에서 낸 돈의 승인이 뒤늦게 온다. 돈이 나갔으므로 보관이 시작돼야 한다.
    it('funds the collaboration when the approval arrives for a payment that a newer one replaced', async () => {
      const s = await seed();
      const first = await startPayment(s.collaborationId);
      const second = await startPayment(s.collaborationId);
      expect(await paymentStatus(first)).toBe('CANCELLED');
      await webhook(first, 'APPROVED').expect(200);

      expect(await paymentStatus(first)).toBe('APPROVED');
      expect(await paymentStatus(second)).toBe('PENDING');
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
      const ledger = await ledgerOf(s.collaborationId);
      expect(
        ledger.map((e) => [e.debitAccount, e.creditAccount, e.amount]).sort(),
      ).toEqual([
        ['PG_IN', 'ESCROW', 60000],
        ['PG_IN', 'FEE_REVENUE', 6000],
      ]);
      expect(new Set(ledger.map((e) => e.idempotencyKey))).toEqual(
        new Set([`payment:${first}`]),
      );
      expect(await prisma.notification.count()).toBe(1);
      expect(alert).not.toHaveBeenCalled();

      // 남은 두 번째 결제가 나중에 승인되면 이미 보관 중이라 늦은 승인이다: 장부는 늘지 않고 운영자에게 알린다.
      await webhook(second, 'APPROVED').expect(200);
      expect(await paymentStatus(second)).toBe('APPROVED');
      expect(await ledgerOf(s.collaborationId)).toHaveLength(2);
      expect(alert).toHaveBeenCalledTimes(1);
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
    });

    it('alerts the operator and does not fund when an approval arrives for a failed payment', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'FAILED').expect(200);
      await webhook(paymentId, 'APPROVED').expect(200);
      expect(await paymentStatus(paymentId)).toBe('FAILED');
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'AWAITING_PAYMENT',
      );
      expect(alert).toHaveBeenCalledTimes(1);
      expect(await ledgerOf(s.collaborationId)).toHaveLength(0);
    });

    it('accepts a notice for a payment it does not know without changing anything', async () => {
      await seed();
      await webhook(randomUUID(), 'APPROVED').expect(200);
      expect(await prisma.ledgerEntry.count()).toBe(0);
    });
  });

  describe('races', () => {
    it('funds once when the same notice arrives twice at the same time', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      const signed = pg.recordFakeResult({ paymentId, status: 'APPROVED' });
      const send = () =>
        request(server)
          .post('/webhooks/payments')
          .set('content-type', 'application/json')
          .set('x-cora-signature', signed.signature)
          .send(signed.rawBody);
      const results = await Promise.all([send(), send(), send()]);
      expect(results.map((r) => r.status)).toEqual([200, 200, 200]);

      expect(await ledgerOf(s.collaborationId)).toHaveLength(2);
      expect(await prisma.notification.count()).toBe(1);
      expect(push.sent).toHaveLength(1);
      expect((await collaborationOf(s.collaborationId)).fundedAt).toEqual(T0);
      expect(await paymentStatus(paymentId)).toBe('APPROVED');
    });

    // 오퍼 취소는 오퍼 → 협업 순으로, 결제 승인도 같은 순서로 잠근다. 어느 쪽이 이기든 반쯤 끝난 상태가 없어야 한다.
    it('ends consistently whichever of the owner cancel and the approval wins', async () => {
      const outcomes = new Set<string>();
      for (let round = 0; round < 6; round++) {
        await truncateTestDb(prisma);
        scheduler.jobs.length = 0;
        alert.mockClear();
        const s = await seed();
        const paymentId = await startPayment(s.collaborationId);
        const signed = pg.recordFakeResult({ paymentId, status: 'APPROVED' });
        const [cancelRes, hookRes] = await Promise.all([
          request(server).post(`/offers/${s.offerId}/cancel`).set(auth).send(),
          request(server)
            .post('/webhooks/payments')
            .set('content-type', 'application/json')
            .set('x-cora-signature', signed.signature)
            .send(signed.rawBody),
        ]);
        expect(hookRes.status).toBe(200);
        const collaboration = await collaborationOf(s.collaborationId);
        const offer = await prisma.offer.findUniqueOrThrow({
          where: { id: s.offerId },
        });
        const ledger = await ledgerOf(s.collaborationId);
        expect(await paymentStatus(paymentId)).toBe('APPROVED');
        if (cancelRes.status === 200) {
          outcomes.add('cancelled');
          expect(collaboration.stage).toBe('CANCELLED');
          expect(offer.status).toBe('CANCELLED');
          expect(ledger).toHaveLength(0);
          expect(alert).toHaveBeenCalledTimes(1);
        } else {
          outcomes.add('funded');
          expect(cancelRes.status).toBe(409);
          expect(collaboration.stage).toBe('FUNDED');
          expect(offer.status).toBe('ACCEPTED');
          expect(ledger).toHaveLength(2);
          expect(alert).not.toHaveBeenCalled();
        }
      }
      expect(outcomes.size).toBeGreaterThan(0);
    }, 30000);
  });

  describe('recheck', () => {
    it('picks up an approval the webhook missed when rechecked', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      // PG는 승인했지만 웹훅이 오지 않았다.
      pg.recordFakeResult({ paymentId, status: 'APPROVED' });
      clock.advance(10 * MINUTE);
      await scheduler.runDue(clock.now());

      expect(await paymentStatus(paymentId)).toBe('APPROVED');
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
      expect(await ledgerOf(s.collaborationId)).toHaveLength(2);
      expect(push.sent).toHaveLength(1);
      expect(
        (await prisma.payment.findUniqueOrThrow({ where: { id: paymentId } }))
          .pgTransactionId,
      ).toBe(`fake-tx-${paymentId}`);
    });

    it('keeps asking every ten minutes while pending and stops after the sixth try', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      for (let attempt = 1; attempt <= 6; attempt++) {
        clock.advance(10 * MINUTE);
        const ran = await scheduler.runDue(clock.now());
        expect(ran.map((j) => j.jobKey)).toEqual([
          `payment-recheck:${paymentId}:${attempt}`,
        ]);
      }
      expect(
        scheduler.pending().filter((j) => j.name === 'payment-recheck'),
      ).toHaveLength(0);
      expect(await paymentStatus(paymentId)).toBe('PENDING');
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'AWAITING_PAYMENT',
      );
    });

    it('finishes the steps after funding when the job that failed on the notification is run again', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      pg.recordFakeResult({ paymentId, status: 'APPROVED' });
      const registry = app.get(JobHandlerRegistry);
      const job = { paymentId, attempt: 1 };
      const notify = jest
        .spyOn(app.get(NotificationsService), 'notify')
        .mockRejectedValueOnce(new Error('inbox down'));
      try {
        // 승인은 커밋됐지만 알림이 실패해 작업이 던진다.
        await expect(registry.run('payment-recheck', job)).rejects.toThrow(
          'inbox down',
        );
        expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
        expect(await prisma.notification.count()).toBe(0);
        // 큐가 같은 작업을 다시 돌린다.
        await registry.run('payment-recheck', job);
      } finally {
        notify.mockRestore();
      }
      expect(await prisma.notification.count()).toBe(1);
      expect(push.sent).toHaveLength(1);
      expect(await ledgerOf(s.collaborationId)).toHaveLength(2);
      expect(
        scheduler
          .pending()
          .filter((j) => j.name !== 'payment-recheck')
          .map((j) => j.jobKey)
          .sort(),
      ).toEqual([
        `refund-unsubmitted:${s.collaborationId}`,
        `submit-reminder:${s.collaborationId}:1`,
        `submit-reminder:${s.collaborationId}:3`,
      ]);
    });

    it('does nothing for a payment that was already settled', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      await webhook(paymentId, 'APPROVED').expect(200);
      clock.advance(10 * MINUTE);
      await scheduler.runDue(clock.now());
      expect(await ledgerOf(s.collaborationId)).toHaveLength(2);
      expect(push.sent).toHaveLength(1);
    });

    it('leaves a failed result as failed', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      pg.recordFakeResult({ paymentId, status: 'FAILED' });
      clock.advance(10 * MINUTE);
      await scheduler.runDue(clock.now());
      expect(await paymentStatus(paymentId)).toBe('FAILED');
    });
  });

  describe('dev routes in the test app', () => {
    // AppModule이 실제 환경(NODE_ENV=test, PAYMENT_ADAPTER=fake)을 PaymentsDevModule에 넘기는지 확인한다.
    // 라우트가 없으면 404, 있으면 로그인이 없을 때 인증 가드가 401로 막는다.
    it('registers the dev routes through the real app wiring (401 without a token, not 404)', async () => {
      const id = randomUUID();
      await request(server)
        .post(`/dev/fake-payments/${id}/approve`)
        .expect(401);
      await request(server).post(`/dev/fake-payments/${id}/fail`).expect(401);
    });

    it('approves through the dev route without signing and funds the collaboration', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      const res = await request(server)
        .post(`/dev/fake-payments/${paymentId}/approve`)
        .set(auth)
        .send()
        .expect(200);
      expect(res.body).toEqual({ status: 'APPROVED' });
      expect((await collaborationOf(s.collaborationId)).stage).toBe('FUNDED');
      expect(push.sent).toHaveLength(1);
    });

    it('fails through the dev route', async () => {
      const s = await seed();
      const paymentId = await startPayment(s.collaborationId);
      const res = await request(server)
        .post(`/dev/fake-payments/${paymentId}/fail`)
        .set(auth)
        .send()
        .expect(200);
      expect(res.body).toEqual({ status: 'FAILED' });
      expect((await collaborationOf(s.collaborationId)).stage).toBe(
        'AWAITING_PAYMENT',
      );
    });

    it("does not let someone else settle another owner's payment", async () => {
      const s = await seed({ commissionerId: randomUUID() });
      const paymentRow = await prisma.payment.create({
        data: {
          collaborationId: s.collaborationId,
          amountEscrow: 100000,
          amountFee: 10000,
          feeRate: 10,
          method: 'CARD',
          requestedAt: T0,
        },
      });
      await prisma.user.create({ data: { id: USER_A, role: 'STORE' } });
      await request(server)
        .post(`/dev/fake-payments/${paymentRow.id}/approve`)
        .set(auth)
        .send()
        .expect(404);
      expect(await paymentStatus(paymentRow.id)).toBe('PENDING');
    });
  });
});
