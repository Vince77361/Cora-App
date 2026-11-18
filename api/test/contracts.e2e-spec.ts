import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { OperatorAlertPort } from '../src/integrations/operator-alert/operator-alert.port';
import { FakePaymentAdapter } from '../src/integrations/payment/fake-payment.adapter';
import { PaymentPort } from '../src/integrations/payment/payment.port';
import { PaymentsService } from '../src/payments/payments.service';
import { PushPort } from '../src/integrations/push/push.port';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { RealtimePublisher } from '../src/realtime/realtime-publisher';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { flushMessages } from './helpers/flush-messages';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { FakeRealtimePublisher } from './support/fake-realtime-publisher';
import { OTHER, USER_A } from './support/fake-token-verifier';

// user-a는 브랜드, user-b는 크리에이터다.
const authBrand = { Authorization: 'Bearer user-a' };
const authCreator = { Authorization: 'Bearer user-b' };
const authStranger = { Authorization: 'Bearer user-c' };
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const CAMPAIGN = {
  headline: '나만의 아침 루틴 속 작은 포인트',
  fee: 350000,
  budget: 1000000,
  productProvided: true,
  format: 'REELS',
  startFrom: '2026-11-20',
  trialDays: 'D7',
  mustInclude: ['제품 로고가 보이게'],
  notRequired: ['FACE'],
};
const PRINCIPLES = {
  fields: ['ACCESSORY'],
  blockedIndustries: [] as string[],
  faceOk: true,
  scriptOk: true,
  honestReview: true,
  feeBand: 'W300K',
  trialDays: 'ANY',
};
const PERFORMANCE = { ratePer1000: 2000, cap: 60000 };
const NOON = new Date('2026-11-11T03:00:00.000Z');
const MINUTE = 60_000;
const PAYING_MESSAGE = '결제를 진행하고 있어요. 잠시 뒤 다시 시도해 주세요.';
const DAY = 24 * 60 * MINUTE;

interface ContractBody {
  status: string;
  termsVersion: number | null;
  terms: {
    version: number;
    fee: number;
    maxCash: number;
    usageRights: string;
    performance: { ratePer1000: number; cap: number } | null;
  } | null;
  brandName: string;
  creatorName: string;
  myConsentTexts: string[];
  creatorConsentedAt: string | null;
  brandConsentedAt: string | null;
  concludedAt: string | null;
  quote: {
    escrow: number;
    fee: number;
    feeRate: number;
    total: number;
    fixedCash: number;
    perViewCap: number | null;
    orderName: string;
  } | null;
  voidedNotice: boolean;
}
interface PaymentCreated {
  paymentId: string;
  checkoutUrl: string;
}

describe('brand contract consent and payment', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let push: FakePushPort;
  let realtime: FakeRealtimePublisher;
  let scheduler: FakeJobScheduler;
  let pg: FakePaymentAdapter;
  let alert: jest.SpyInstance;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const messageOf = (res: request.Response) =>
    (res.body as { error: { message: string } }).error.message;
  const setRole = (auth: Record<string, string>, role: string) =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const decide = (auth: Record<string, string>, body: object) =>
    request(server).put('/discovery/decisions').set(auth).send(body);
  const confirm = (auth: Record<string, string>, id: string, version: number) =>
    request(server)
      .post(`/collaborations/${id}/terms/${version}/confirm`)
      .set(auth);
  const propose = (
    auth: Record<string, string>,
    id: string,
    body: Record<string, unknown>,
  ) => request(server).post(`/collaborations/${id}/terms`).set(auth).send(body);
  const getContract = (auth: Record<string, string>, id: string) =>
    request(server).get(`/collaborations/${id}/contract`).set(auth);
  const creatorConsent = (
    id: string,
    body: Record<string, unknown>,
    auth = authCreator,
  ) =>
    request(server)
      .post(`/collaborations/${id}/contract/creator-consent`)
      .set(auth)
      .send(body);
  const brandConsent = (
    id: string,
    body: Record<string, unknown>,
    auth = authBrand,
  ) =>
    request(server)
      .post(`/collaborations/${id}/contract/brand-consent`)
      .set(auth)
      .send(body);
  const approve = (paymentId: string) =>
    request(server)
      .post(`/dev/fake-payments/${paymentId}/approve`)
      .set(authBrand)
      .send();
  const contractOf = async (auth: Record<string, string>, id: string) =>
    (await getContract(auth, id).expect(200)).body as ContractBody;
  const collaborationOf = (id: string) =>
    prisma.collaboration.findUniqueOrThrow({ where: { id } });
  const roomIdOf = async (collaborationId: string) =>
    (
      await prisma.conversation.findUniqueOrThrow({
        where: { collaborationId },
      })
    ).id;
  const ledgerOf = (collaborationId: string) =>
    prisma.ledgerEntry.findMany({
      where: { collaborationId },
      orderBy: { createdAt: 'asc' },
    });
  const balanceOf = async (collaborationId: string) => {
    const entries = await ledgerOf(collaborationId);
    const sum: Record<string, number> = {};
    for (const e of entries) {
      sum[e.creditAccount] = (sum[e.creditAccount] ?? 0) + e.amount;
      sum[e.debitAccount] = (sum[e.debitAccount] ?? 0) - e.amount;
    }
    return sum;
  };
  const systemLines = async (
    auth: Record<string, string>,
    collaborationId: string,
  ) =>
    (
      (
        await request(server)
          .get(`/conversations/${await roomIdOf(collaborationId)}/messages`)
          .set(auth)
          .expect(200)
      ).body as { kind: string; text: string | null }[]
    )
      .filter((m) => m.kind === 'SYSTEM')
      .map((m) => m.text ?? '');
  const notificationTexts = async (auth: Record<string, string>) =>
    (
      (await request(server).get('/notifications').set(auth).expect(200))
        .body as { items: { text: string }[] }
    ).items.map((i) => i.text);

  async function makeBoth(): Promise<string> {
    await setRole(authBrand, 'BRAND');
    await request(server)
      .put('/brands/me')
      .set(authBrand)
      .send({
        name: '느린결',
        tagline: '천천히 쓰는 물건',
        industry: 'ACCESSORY',
      })
      .expect(200);
    const created = await request(server)
      .post('/campaigns')
      .set(authBrand)
      .send(CAMPAIGN)
      .expect(201);
    await setRole(authCreator, 'CREATOR');
    await request(server)
      .put('/creators/me')
      .set(authCreator)
      .send({ displayName: '하루 한 컵', ...REGION })
      .expect(200);
    await request(server)
      .put('/creators/me/principles')
      .set(authCreator)
      .send(PRINCIPLES)
      .expect(200);
    return (created.body as { id: string }).id;
  }

  // 서로 관심을 만들어 협업 id를 돌려준다(MATCHED, 판본 1: 제작비 350,000원).
  async function matchUp(): Promise<string> {
    const campaignId = await makeBoth();
    await decide(authCreator, {
      targetKind: 'CAMPAIGN',
      targetId: campaignId,
      decision: 'LIKE',
      note: '아침 한 컵',
    }).expect(200);
    const res = await decide(authBrand, {
      targetKind: 'CREATOR',
      targetId: OTHER,
      decision: 'LIKE',
    }).expect(200);
    return (res.body as { collaborationId: string }).collaborationId;
  }

  // 판본 1을 양쪽이 확인해 AGREED로 만든다.
  async function agreed(): Promise<string> {
    const id = await matchUp();
    await confirm(authBrand, id, 1).expect(200);
    await confirm(authCreator, id, 1).expect(200);
    return id;
  }

  // 브랜드가 성과 추가를 더한 판본 2를 내고 크리에이터가 확인해 AGREED로 만든다.
  async function agreedWithPerformance(): Promise<string> {
    const id = await matchUp();
    await prisma.instagramConnection.create({
      data: {
        creatorId: OTHER,
        handle: 'haru_cup',
        followers: 12400,
        refreshedAt: NOON,
      },
    });
    await propose(authBrand, id, {
      baseVersion: 1,
      fee: 350000,
      productProvided: true,
      performance: PERFORMANCE,
    }).expect(201);
    await confirm(authCreator, id, 2).expect(200);
    return id;
  }

  async function textsOf(
    auth: Record<string, string>,
    id: string,
  ): Promise<string[]> {
    return (await contractOf(auth, id)).myConsentTexts;
  }

  // 크리에이터가 동의한 상태(AWAITING_BRAND)까지 만든다.
  async function creatorConsented(id: string): Promise<void> {
    const version = (await contractOf(authCreator, id)).termsVersion;
    await creatorConsent(id, {
      termsVersion: version,
      accepted: await textsOf(authCreator, id),
    }).expect(200);
  }

  // 브랜드가 동의하며 결제를 시작한다. 결제 id를 돌려준다.
  async function brandPaying(
    id: string,
    method = 'CARD',
  ): Promise<{ paymentId: string; res: request.Response }> {
    const version = (await contractOf(authBrand, id)).termsVersion;
    const res = await brandConsent(id, {
      termsVersion: version,
      accepted: await textsOf(authBrand, id),
      method,
    }).expect(201);
    return { paymentId: (res.body as PaymentCreated).paymentId, res };
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp([], { fakeRealtime: true });
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    push = app.get<FakePushPort>(PushPort);
    realtime = app.get<FakeRealtimePublisher>(RealtimePublisher);
    scheduler = app.get<FakeJobScheduler>(JobScheduler);
    pg = app.get<FakePaymentAdapter>(PaymentPort);
    alert = jest
      .spyOn(app.get(OperatorAlertPort), 'alert')
      .mockResolvedValue(undefined);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(NOON);
    push.sent.length = 0;
    realtime.sent.length = 0;
    scheduler.jobs.length = 0;
    pg.refunds.length = 0;
    alert.mockClear();
  });
  afterAll(async () => {
    alert.mockRestore();
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server)
      .get(`/collaborations/${randomUUID()}/contract`)
      .expect(401);
    await request(server)
      .post(`/collaborations/${randomUUID()}/contract/creator-consent`)
      .send({})
      .expect(401);
  });

  describe('reading the contract', () => {
    it('previews the latest version and the consent lines before both sides confirmed', async () => {
      const id = await matchUp();
      const body = await contractOf(authCreator, id);
      expect(body).toMatchObject({
        status: 'NOT_READY',
        termsVersion: 1,
        brandName: '느린결',
        creatorName: '하루 한 컵',
        creatorConsentedAt: null,
        brandConsentedAt: null,
        concludedAt: null,
        quote: null,
        voidedNotice: false,
      });
      expect(body.myConsentTexts).toHaveLength(3);
      expect(body.myConsentTexts[0]).toBe('합의한 조건 버전 1을 확인했어요');
      expect(body.myConsentTexts[1]).toBe('광고 표시 의무를 지킬게요');
      expect((await contractOf(authBrand, id)).myConsentTexts[1]).toBe(
        '광고 표시를 요청할게요',
      );
    });

    it('moves to AWAITING_CREATOR once both sides confirmed and shows the brand a quote only after the creator consented', async () => {
      const id = await agreed();
      expect(await contractOf(authBrand, id)).toMatchObject({
        status: 'AWAITING_CREATOR',
        quote: null,
      });
      await creatorConsented(id);
      const brand = await contractOf(authBrand, id);
      expect(brand.status).toBe('AWAITING_BRAND');
      expect(brand.quote).toMatchObject({
        escrow: 350000,
        fee: 35000,
        feeRate: 10,
        total: 385000,
        fixedCash: 350000,
        perViewCap: null,
        orderName: '나만의 아침 루틴 속 작은 포인트 제작비',
      });
      expect((await contractOf(authCreator, id)).quote).toBeNull();
    });

    it('answers 404 to someone who is not a party and to an unknown collaboration', async () => {
      const id = await agreed();
      await getContract(authStranger, id).expect(404);
      await getContract(authCreator, randomUUID()).expect(404);
      await getContract(authCreator, 'not-a-uuid').expect(404);
    });
  });

  describe('creator consent', () => {
    it('lets the creator consent only to the agreed latest version with the exact texts', async () => {
      const id = await agreed();
      const texts = await textsOf(authCreator, id);
      // 문구가 다르거나 개수·순서가 다르면 400이다.
      for (const accepted of [
        [texts[0], texts[1], '다른 문구'],
        [texts[1], texts[0], texts[2]],
        [texts[0], texts[1]],
      ]) {
        const res = await creatorConsent(id, { termsVersion: 1, accepted });
        expect([400]).toContain(res.status);
        expect(codeOf(res)).toBe('VALIDATION_FAILED');
      }
      expect(await prisma.contract.count()).toBe(0);
      // 브랜드의 문구로는 크리에이터가 동의할 수 없다.
      const brandTexts = await textsOf(authBrand, id);
      await creatorConsent(id, {
        termsVersion: 1,
        accepted: brandTexts,
      }).expect(400);

      const res = await creatorConsent(id, {
        termsVersion: 1,
        accepted: texts,
      }).expect(200);
      expect(res.body).toMatchObject({
        status: 'AWAITING_BRAND',
        termsVersion: 1,
        creatorConsentedAt: NOON.toISOString(),
        brandConsentedAt: null,
      });
      const row = await prisma.contract.findFirstOrThrow({});
      expect(row).toMatchObject({
        collaborationId: id,
        status: 'AWAITING_BRAND',
        termsVersion: 1,
        creatorConsentTexts: texts,
        brandConsentTexts: [],
        paymentId: null,
        concludedAt: null,
      });
      // 조건 사본은 동의한 판본의 값이다.
      expect(row.termsSnapshot).toMatchObject({
        version: 1,
        fee: 350000,
        maxCash: 350000,
        performance: null,
      });
    });

    it('answers 403 to the brand, 409 before the terms are agreed, and STALE_VERSION for an older version', async () => {
      const id = await matchUp();
      const texts = await textsOf(authCreator, id);
      // 아직 합의 전이다.
      const early = await creatorConsent(id, {
        termsVersion: 1,
        accepted: texts,
      }).expect(409);
      expect(codeOf(early)).toBe('CONFLICT');

      await confirm(authBrand, id, 1).expect(200);
      await confirm(authCreator, id, 1).expect(200);
      const forbidden = await creatorConsent(
        id,
        { termsVersion: 1, accepted: texts },
        authBrand,
      ).expect(403);
      expect(codeOf(forbidden)).toBe('FORBIDDEN');
      await creatorConsent(
        id,
        { termsVersion: 1, accepted: texts },
        authStranger,
      ).expect(404);

      // 새 판본이 나오면 판본 1로 동의하는 것은 낡은 요청이다.
      await propose(authBrand, id, {
        baseVersion: 1,
        fee: 360000,
        productProvided: true,
        performance: null,
      }).expect(201);
      const stale = await creatorConsent(id, {
        termsVersion: 1,
        accepted: texts,
      }).expect(409);
      expect(codeOf(stale)).toBe('STALE_VERSION');
      expect(
        (stale.body as { error: { details: { latestVersion: number } } }).error
          .details,
      ).toEqual({ latestVersion: 2 });
      expect(await prisma.contract.count()).toBe(0);
    });

    it('leaves a system line, tells the brand once and does not repeat on the same consent again', async () => {
      const id = await agreed();
      await flushMessages(app);
      push.sent.length = 0;
      realtime.sent.length = 0;
      const texts = await textsOf(authCreator, id);
      await creatorConsent(id, { termsVersion: 1, accepted: texts }).expect(
        200,
      );
      await flushMessages(app);
      await creatorConsent(id, { termsVersion: 1, accepted: texts }).expect(
        200,
      );
      await flushMessages(app);

      expect(await prisma.contract.count()).toBe(1);
      expect((await systemLines(authBrand, id)).pop()).toBe(
        '하루 한 컵님이 계약에 동의했어요.',
      );
      expect(
        (await systemLines(authBrand, id)).filter((l) =>
          l.includes('계약에 동의'),
        ),
      ).toHaveLength(1);
      // 브랜드에게만, 한 번, 끌 수 없는 알림으로 간다(안내 줄의 대화 메시지 푸시는 없다).
      expect(push.sent.map((p) => p.userId)).toEqual([USER_A]);
      expect(await notificationTexts(authBrand)).toContain(
        '하루 한 컵님이 계약에 동의했어요.',
      );
      expect(realtime.receivedBy(USER_A, 'conversation.updated').length).toBe(
        1,
      );
    });

    it('creates one contract for two identical consents sent at once', async () => {
      const id = await agreed();
      const texts = await textsOf(authCreator, id);
      const results = await Promise.all([
        creatorConsent(id, { termsVersion: 1, accepted: texts }),
        creatorConsent(id, { termsVersion: 1, accepted: texts }),
      ]);
      expect(results.map((r) => r.status)).toEqual([200, 200]);
      expect(await prisma.contract.count()).toBe(1);
      expect(
        (await systemLines(authBrand, id)).filter((l) =>
          l.includes('계약에 동의'),
        ),
      ).toHaveLength(1);
    });

    it('voids the consent when a new version is proposed and shows the notice until the next consent', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const res = await propose(authBrand, id, {
        baseVersion: 1,
        fee: 360000,
        productProvided: true,
        performance: null,
      }).expect(201);
      expect((res.body as { version: number }).version).toBe(2);
      expect(await prisma.contract.findFirstOrThrow({})).toMatchObject({
        status: 'VOIDED',
        voidReason: 'NEW_TERMS',
      });
      expect(await contractOf(authCreator, id)).toMatchObject({
        status: 'NOT_READY',
        termsVersion: 2,
        voidedNotice: true,
      });
      // 브랜드는 결제를 시작한 적이 없어 취소된 "내 동의"가 없다.
      expect((await contractOf(authBrand, id)).voidedNotice).toBe(false);
      // 새 판본을 확인하고 다시 동의하면 띠가 사라지고 새 계약이 생긴다.
      await confirm(authCreator, id, 2).expect(200);
      await creatorConsented(id);
      expect(await contractOf(authCreator, id)).toMatchObject({
        status: 'AWAITING_BRAND',
        termsVersion: 2,
        voidedNotice: false,
      });
      expect(await prisma.contract.count()).toBe(2);
    });
  });

  describe('quote', () => {
    it('quotes the max cash plus a 10 percent service fee for the brand', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const res = await request(server)
        .get(`/collaborations/${id}/payment-quote`)
        .set(authBrand)
        .expect(200);
      expect(res.body).toMatchObject({
        escrow: 350000,
        fee: 35000,
        feeRate: 10,
        total: 385000,
        fixedCash: 350000,
        perViewCap: null,
        creatorName: '하루 한 컵',
        voucherName: null,
      });
    });

    it('quotes the max cash plus the fee when a performance bonus is agreed', async () => {
      const id = await agreedWithPerformance();
      await creatorConsented(id);
      const res = await request(server)
        .get(`/collaborations/${id}/payment-quote`)
        .set(authBrand)
        .expect(200);
      expect(res.body).toMatchObject({
        escrow: 410000,
        fee: 41000,
        total: 451000,
        fixedCash: 350000,
        perViewCap: 60000,
      });
      expect((await contractOf(authBrand, id)).quote).toMatchObject({
        escrow: 410000,
        fee: 41000,
        total: 451000,
      });
    });

    it('quotes before the creator consents from the agreed version, and refuses before the terms are agreed', async () => {
      const id = await matchUp();
      await request(server)
        .get(`/collaborations/${id}/payment-quote`)
        .set(authBrand)
        .expect(409);
      await confirm(authBrand, id, 1).expect(200);
      await confirm(authCreator, id, 1).expect(200);
      const res = await request(server)
        .get(`/collaborations/${id}/payment-quote`)
        .set(authBrand)
        .expect(200);
      expect(res.body).toMatchObject({ escrow: 350000, total: 385000 });
      // 크리에이터는 결제 견적을 볼 수 없고, 다른 브랜드는 없는 협업과 같게 404다.
      await request(server)
        .get(`/collaborations/${id}/payment-quote`)
        .set(authCreator)
        .expect(403);
      await request(server)
        .get(`/collaborations/${id}/payment-quote`)
        .set(authStranger)
        .expect(403);
    });
  });

  describe('brand consent', () => {
    it('refuses brand consent before the creator consents', async () => {
      const id = await agreed();
      const res = await brandConsent(id, {
        termsVersion: 1,
        accepted: await textsOf(authBrand, id),
        method: 'CARD',
      }).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(messageOf(res)).toBe('크리에이터의 동의를 기다리고 있어요.');
      expect(await prisma.payment.count()).toBe(0);
    });

    it('creates the payment from the contract snapshot and never from the request body', async () => {
      const id = await agreedWithPerformance();
      await creatorConsented(id);
      const texts = await textsOf(authBrand, id);
      // 금액·수수료 같은 칸은 받지 않는다(허용하지 않은 칸은 400).
      await brandConsent(id, {
        termsVersion: 2,
        accepted: texts,
        method: 'CARD',
        amount: 1000,
      }).expect(400);
      expect(await prisma.payment.count()).toBe(0);

      clock.advance(3 * MINUTE);
      const res = await brandConsent(id, {
        termsVersion: 2,
        accepted: texts,
        method: 'TRANSFER',
      }).expect(201);
      const created = res.body as PaymentCreated;
      expect(created.checkoutUrl).toContain(created.paymentId);
      const payment = await prisma.payment.findUniqueOrThrow({
        where: { id: created.paymentId },
      });
      expect(payment).toMatchObject({
        collaborationId: id,
        amountEscrow: 410000,
        amountFee: 41000,
        feeRate: 10,
        method: 'TRANSFER',
        status: 'PENDING',
        requestedAt: new Date(NOON.getTime() + 3 * MINUTE),
      });
      const contract = await prisma.contract.findFirstOrThrow({});
      expect(contract).toMatchObject({
        status: 'AWAITING_BRAND',
        paymentId: payment.id,
        brandConsentTexts: texts,
        brandConsentedAt: null,
      });
      // 결제 상태도 브랜드가 읽는다.
      const status = await request(server)
        .get(`/payments/${payment.id}`)
        .set(authBrand)
        .expect(200);
      expect(status.body).toEqual({ status: 'PENDING' });
      await request(server)
        .get(`/payments/${payment.id}`)
        .set(authCreator)
        .expect(403);
      expect(await contractOf(authBrand, id)).toMatchObject({
        status: 'PAYING',
      });
    });

    it('answers 400 for wrong texts, STALE_VERSION for a version that is not the latest, 403 for the creator and 409 on the store payment route', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const texts = await textsOf(authBrand, id);
      const wrong = await brandConsent(id, {
        termsVersion: 1,
        accepted: [texts[0], '광고 표시 의무를 지킬게요', texts[2]],
        method: 'CARD',
      }).expect(400);
      expect(codeOf(wrong)).toBe('VALIDATION_FAILED');
      await brandConsent(
        id,
        { termsVersion: 1, accepted: texts, method: 'CARD' },
        authCreator,
      ).expect(403);
      const stale = await brandConsent(id, {
        termsVersion: 2,
        accepted: texts,
        method: 'CARD',
      }).expect(409);
      expect(codeOf(stale)).toBe('STALE_VERSION');
      expect(await prisma.payment.count()).toBe(0);
      // 브랜드 계약에는 가게용 결제 만들기가 없다.
      const store = await request(server)
        .post(`/collaborations/${id}/payments`)
        .set(authBrand)
        .send({ method: 'CARD' })
        .expect(409);
      expect(codeOf(store)).toBe('CONFLICT');
      await request(server)
        .post(`/collaborations/${id}/payments`)
        .set(authStranger)
        .send({ method: 'CARD' })
        .expect(403);
    });

    it('returns STALE_VERSION when the brand consents to an older version', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const texts = await textsOf(authBrand, id);
      // 크리에이터의 동의가 취소되고 판본 2가 최신이다.
      await propose(authCreator, id, {
        baseVersion: 1,
        fee: 340000,
        productProvided: true,
        performance: null,
      }).expect(201);
      const stale = await brandConsent(id, {
        termsVersion: 1,
        accepted: texts,
        method: 'CARD',
      }).expect(409);
      expect(codeOf(stale)).toBe('STALE_VERSION');
      expect(
        (stale.body as { error: { details: { latestVersion: number } } }).error
          .details,
      ).toEqual({ latestVersion: 2 });
    });

    it('refuses a second brand consent while paying and holds terms changes for 60 minutes', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const first = await brandPaying(id);
      clock.advance(5 * MINUTE);
      const second = await brandConsent(id, {
        termsVersion: 1,
        accepted: await textsOf(authBrand, id),
        method: 'EASY_PAY',
      }).expect(409);
      expect(codeOf(second)).toBe('CONFLICT');
      expect(messageOf(second)).toBe(PAYING_MESSAGE);
      expect(
        (second.body as { error: { details: unknown } }).error.details,
      ).toEqual({ reason: 'PAYMENT_IN_PROGRESS' });
      // 새 결제도 없고 취소된 것도 없다. 계약은 첫 결제 그대로다.
      const rows = await prisma.payment.findMany();
      expect(rows.map((p) => [p.id, p.status])).toEqual([
        [first.paymentId, 'PENDING'],
      ]);
      expect((await prisma.contract.findFirstOrThrow({})).paymentId).toBe(
        first.paymentId,
      );
      expect((await contractOf(authBrand, id)).status).toBe('PAYING');

      // 결제창이 열린 동안에는 조건 수정 제안과 그만두기가 막힌다.
      await propose(authCreator, id, {
        baseVersion: 1,
        fee: 340000,
        productProvided: true,
        performance: null,
      }).expect(409);
      await request(server)
        .post(`/collaborations/${id}/drop`)
        .set(authCreator)
        .send({ reason: 'BUDGET' })
        .expect(409);
      // 요청한 지 60분이 지나면 풀린다.
      clock.advance(61 * MINUTE);
      await propose(authCreator, id, {
        baseVersion: 1,
        fee: 340000,
        productProvided: true,
        performance: null,
      }).expect(201);
    });

    it('lets the brand pay again once the 60 minute lock has passed and cancels only the expired payment', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const first = await brandPaying(id);
      // 경계: 요청한 지 정확히 60분이면 풀린다(잠금은 60분 "안"이다).
      clock.advance(59 * MINUTE);
      await brandConsent(id, {
        termsVersion: 1,
        accepted: await textsOf(authBrand, id),
        method: 'CARD',
      }).expect(409);
      clock.advance(MINUTE);
      const second = await brandPaying(id, 'EASY_PAY');
      const rows = await prisma.payment.findMany({
        orderBy: { requestedAt: 'asc' },
      });
      expect(rows.map((p) => [p.id, p.status])).toEqual([
        [first.paymentId, 'CANCELLED'],
        [second.paymentId, 'PENDING'],
      ]);
      expect((await prisma.contract.findFirstOrThrow({})).paymentId).toBe(
        second.paymentId,
      );
    });

    it('does not count a failed payment as paying', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const first = await brandPaying(id);
      await request(server)
        .post(`/dev/fake-payments/${first.paymentId}/fail`)
        .set(authBrand)
        .send()
        .expect(200);
      expect((await contractOf(authBrand, id)).status).toBe('AWAITING_BRAND');
      const second = await brandPaying(id);
      expect(
        (
          await prisma.payment.findMany({ orderBy: { requestedAt: 'asc' } })
        ).map((p) => [p.id, p.status]),
      ).toEqual([
        [first.paymentId, 'FAILED'],
        [second.paymentId, 'PENDING'],
      ]);
    });

    it('does not count a cancelled payment as paying', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const first = await brandPaying(id);
      await prisma.payment.update({
        where: { id: first.paymentId },
        data: { status: 'CANCELLED' },
      });
      expect((await contractOf(authBrand, id)).status).toBe('AWAITING_BRAND');
      const second = await brandPaying(id);
      expect(second.paymentId).not.toBe(first.paymentId);
      expect(await prisma.payment.count({ where: { status: 'PENDING' } })).toBe(
        1,
      );
    });

    it('answers 409 to three consents at the same time and leaves one pending payment', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const texts = await textsOf(authBrand, id);
      const results = await Promise.all(
        [0, 1, 2].map(() =>
          brandConsent(id, {
            termsVersion: 1,
            accepted: texts,
            method: 'CARD',
          }),
        ),
      );
      expect(results.map((r) => r.status).sort()).toEqual([201, 409, 409]);
      expect(await prisma.payment.count()).toBe(1);
      expect(await prisma.payment.count({ where: { status: 'PENDING' } })).toBe(
        1,
      );
    });
  });

  describe('payment in progress', () => {
    it('keeps showing the stored fee while paying even after the fee rate setting changed', async () => {
      const id = await agreed();
      await creatorConsented(id);
      await brandPaying(id);
      // 결제를 만든 뒤 수수료율이 15%로 바뀌었다: 결제 행(10%)의 금액이 그대로 보인다.
      const rate = jest
        .spyOn(app.get(PaymentsService), 'brandFeeRate')
        .mockReturnValue(15);
      try {
        const brand = await contractOf(authBrand, id);
        expect(brand.status).toBe('PAYING');
        expect(brand.quote).toMatchObject({
          escrow: 350000,
          fee: 35000,
          feeRate: 10,
          total: 385000,
        });
        // 견적 엔드포인트도 같은 값이다(결제 행의 보관액·수수료·합계).
        const quote = await request(server)
          .get(`/collaborations/${id}/payment-quote`)
          .set(authBrand)
          .expect(200);
        expect(quote.body).toMatchObject({
          escrow: 350000,
          fee: 35000,
          feeRate: 10,
          total: 385000,
        });
        // 결제창이 닫히면(60분) 결제 전으로 돌아가 지금 설정으로 계산한다.
        clock.advance(61 * MINUTE);
        expect((await contractOf(authBrand, id)).quote).toMatchObject({
          fee: 52500,
          feeRate: 15,
        });
        expect(
          (
            await request(server)
              .get(`/collaborations/${id}/payment-quote`)
              .set(authBrand)
              .expect(200)
          ).body,
        ).toMatchObject({ fee: 52500, feeRate: 15 });
      } finally {
        rate.mockRestore();
      }
    });

    it('marks the payment failed and frees the lock when the checkout cannot be opened', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const texts = await textsOf(authBrand, id);
      const checkout = jest
        .spyOn(pg, 'createCheckout')
        .mockRejectedValueOnce(new Error('pg down'));
      try {
        await brandConsent(id, {
          termsVersion: 1,
          accepted: texts,
          method: 'CARD',
        }).expect(500);
      } finally {
        checkout.mockRestore();
      }
      const payment = await prisma.payment.findFirstOrThrow({});
      expect(payment.status).toBe('FAILED');
      // 60분을 기다리지 않아도 조건 제안과 그만두기가 막히지 않는다.
      expect((await contractOf(authBrand, id)).status).toBe('AWAITING_BRAND');
      await propose(authCreator, id, {
        baseVersion: 1,
        fee: 340000,
        productProvided: true,
        performance: null,
      }).expect(201);
    });
  });

  describe('payment approval', () => {
    it('keeps AGREED and AWAITING_BRAND while the payment is pending or failed', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const { paymentId } = await brandPaying(id);
      expect((await collaborationOf(id)).stage).toBe('AGREED');
      expect(await prisma.contract.findFirstOrThrow({})).toMatchObject({
        status: 'AWAITING_BRAND',
      });
      await request(server)
        .post(`/dev/fake-payments/${paymentId}/fail`)
        .set(authBrand)
        .send()
        .expect(200);
      expect((await collaborationOf(id)).stage).toBe('AGREED');
      expect(await prisma.contract.findFirstOrThrow({})).toMatchObject({
        status: 'AWAITING_BRAND',
        concludedAt: null,
      });
      expect(await ledgerOf(id)).toHaveLength(0);
      // 실패한 뒤 다시 결제할 수 있다.
      const again = await brandPaying(id);
      expect(again.paymentId).not.toBe(paymentId);
    });

    it('concludes the contract and moves to CONTRACTED only when payment is approved', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const { paymentId } = await brandPaying(id);
      await flushMessages(app);
      push.sent.length = 0;
      realtime.sent.length = 0;
      clock.advance(7 * MINUTE);
      const now = clock.now();

      await approve(paymentId).expect(200);
      await flushMessages(app);

      expect(await collaborationOf(id)).toMatchObject({
        stage: 'CONTRACTED',
        fundedAt: now,
        contractedAt: now,
      });
      expect(
        await prisma.payment.findUniqueOrThrow({ where: { id: paymentId } }),
      ).toMatchObject({ status: 'APPROVED', approvedAt: now });
      expect(await prisma.contract.findFirstOrThrow({})).toMatchObject({
        status: 'CONCLUDED',
        paymentId,
        brandConsentedAt: now,
        concludedAt: now,
      });
      // 장부: 보관 350,000원, 수수료 35,000원.
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 350000,
        FEE_REVENUE: 35000,
        PG_IN: -385000,
      });
      // 계약 상태 화면.
      expect(await contractOf(authCreator, id)).toMatchObject({
        status: 'CONCLUDED',
        concludedAt: now.toISOString(),
        brandConsentedAt: now.toISOString(),
      });
      expect((await contractOf(authBrand, id)).quote).toBeNull();
      // 안내 줄과 방의 변경.
      expect((await systemLines(authCreator, id)).pop()).toBe(
        '계약이 체결됐어요.',
      );
      expect(realtime.receivedBy(OTHER, 'conversation.updated')).toHaveLength(
        1,
      );
      expect(realtime.receivedBy(USER_A, 'conversation.updated')).toHaveLength(
        1,
      );
      // 양쪽에 끌 수 없는 푸시가 한 번씩, 안내 줄의 대화 메시지 푸시는 없다.
      expect(push.sent.map((p) => p.userId).sort()).toEqual(
        [USER_A, OTHER].sort(),
      );
      expect(
        push.sent.every(
          (p) => p.body === '계약이 체결됐어요. 이제 제작을 시작할 수 있어요.',
        ),
      ).toBe(true);
      expect(await notificationTexts(authCreator)).toContain(
        '계약이 체결됐어요. 이제 제작을 시작할 수 있어요.',
      );
      // 계약 뒤에는 조건을 바꿀 수 없다.
      await propose(authBrand, id, {
        baseVersion: 1,
        fee: 360000,
        productProvided: true,
        performance: null,
      }).expect(409);
    });

    it('schedules the 60 day halt check at conclusion', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const { paymentId } = await brandPaying(id);
      clock.advance(2 * MINUTE);
      const now = clock.now();
      await approve(paymentId).expect(200);
      const jobs = scheduler.jobs.filter(
        (j) => j.jobKey === `brand-halt:${id}`,
      );
      expect(jobs).toHaveLength(1);
      expect(jobs[0]).toMatchObject({
        name: 'brand-halt-check',
        payload: { collaborationId: id },
        status: 'pending',
      });
      expect(jobs[0].runAt).toEqual(new Date(now.getTime() + 60 * DAY));
    });

    it('holds the max cash including the performance bonus cap', async () => {
      const id = await agreedWithPerformance();
      await creatorConsented(id);
      const { paymentId } = await brandPaying(id);
      await approve(paymentId).expect(200);
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 410000,
        FEE_REVENUE: 41000,
      });
      expect((await collaborationOf(id)).stage).toBe('CONTRACTED');
    });

    it('concludes once for two identical approvals', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const { paymentId } = await brandPaying(id);
      await flushMessages(app);
      push.sent.length = 0;

      // 동시에 두 번, 그 뒤 순서대로 한 번 더.
      const both = await Promise.all([approve(paymentId), approve(paymentId)]);
      expect(both.map((r) => r.status)).toEqual([200, 200]);
      await approve(paymentId).expect(200);
      await flushMessages(app);

      expect(
        await prisma.contract.count({ where: { status: 'CONCLUDED' } }),
      ).toBe(1);
      expect(await ledgerOf(id)).toHaveLength(2);
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 350000,
        FEE_REVENUE: 35000,
      });
      expect(
        (await systemLines(authBrand, id)).filter(
          (l) => l === '계약이 체결됐어요.',
        ),
      ).toHaveLength(1);
      expect(push.sent.map((p) => p.userId).sort()).toEqual(
        [USER_A, OTHER].sort(),
      );
      expect(
        scheduler.jobs.filter((j) => j.jobKey === `brand-halt:${id}`),
      ).toHaveLength(1);
      expect(pg.refunds).toHaveLength(0);
      expect(alert).not.toHaveBeenCalled();
    });

    it('concludes with the replaced payment and refunds the later one in full', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const first = await brandPaying(id);
      // 결제창을 연 채 60분이 지나 잠금이 풀린 뒤 다시 결제했다(첫 결제는 만료돼 취소로 바뀐다).
      clock.advance(61 * MINUTE);
      const second = await brandPaying(id);
      expect(
        (
          await prisma.payment.findUniqueOrThrow({
            where: { id: first.paymentId },
          })
        ).status,
      ).toBe('CANCELLED');
      // 첫 결제창이 열려 있다가 승인됐다: 같은 계약의 결제라 체결한다.
      await approve(first.paymentId).expect(200);
      expect((await collaborationOf(id)).stage).toBe('CONTRACTED');
      expect((await prisma.contract.findFirstOrThrow({})).paymentId).toBe(
        first.paymentId,
      );
      // 두 번째 결제는 이미 체결된 계약에 이중 결제라 전액 환급한다.
      await approve(second.paymentId).expect(200);
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 350000,
        FEE_REVENUE: 35000,
        STORE_REFUND: 385000,
      });
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0].amount).toBe(385000);
      expect(alert).toHaveBeenCalledTimes(1);
    });
  });

  describe('approval after the contract was voided', () => {
    // 결제창을 열어 둔 채 60분이 지나 조건이 바뀌었다(크리에이터의 동의 취소).
    async function voidedByNewTerms(): Promise<{
      id: string;
      paymentId: string;
    }> {
      const id = await agreed();
      await creatorConsented(id);
      const { paymentId } = await brandPaying(id);
      clock.advance(61 * MINUTE);
      await propose(authCreator, id, {
        baseVersion: 1,
        fee: 340000,
        productProvided: true,
        performance: null,
      }).expect(201);
      expect(await prisma.contract.findFirstOrThrow({})).toMatchObject({
        status: 'VOIDED',
        voidReason: 'NEW_TERMS',
      });
      return { id, paymentId };
    }

    it('refunds in full without a contract when approval arrives after the consent was voided', async () => {
      const { id, paymentId } = await voidedByNewTerms();
      await flushMessages(app);
      push.sent.length = 0;

      await approve(paymentId).expect(200);
      await flushMessages(app);

      // 계약도 협업 단계도 그대로이고 돈만 전액 돌아간다.
      expect((await collaborationOf(id)).stage).toBe('NEGOTIATING');
      expect(
        await prisma.contract.count({ where: { status: 'CONCLUDED' } }),
      ).toBe(0);
      expect(
        await prisma.payment.findUniqueOrThrow({ where: { id: paymentId } }),
      ).toMatchObject({ status: 'APPROVED' });
      // 장부는 균형이고 에스크로와 수수료 수익은 0, 환급 계정에 낸 돈 전부.
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 0,
        FEE_REVENUE: 0,
        STORE_REFUND: 385000,
        PG_IN: -385000,
      });
      const refund = await prisma.refund.findFirstOrThrow({});
      expect(refund).toMatchObject({
        collaborationId: id,
        amount: 385000,
        status: 'DONE',
        idempotencyKey: `late-refund:${paymentId}`,
      });
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0].amount).toBe(385000);
      // 운영자에게 알린다. 계약 체결 알림은 가지 않는다.
      expect(alert).toHaveBeenCalledTimes(1);
      expect((alert.mock.calls as unknown[][])[0][0]).toMatchObject({
        subject: '[Cora] 계약 없이 승인된 결제를 환급했어요',
      });
      expect(push.sent).toHaveLength(0);
      expect(
        scheduler.jobs.filter((j) => j.jobKey === `brand-halt:${id}`),
      ).toHaveLength(0);
      // 같은 승인이 또 와도 환급은 한 번이다.
      await approve(paymentId).expect(200);
      expect(pg.refunds).toHaveLength(1);
      expect(await ledgerOf(id)).toHaveLength(4);
    });

    it('still refunds in full when the late approval is for a payment that was cancelled after the contract was voided', async () => {
      const { id, paymentId } = await voidedByNewTerms();
      await prisma.payment.update({
        where: { id: paymentId },
        data: { status: 'CANCELLED' },
      });
      await approve(paymentId).expect(200);
      expect((await collaborationOf(id)).stage).toBe('NEGOTIATING');
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 0,
        FEE_REVENUE: 0,
        STORE_REFUND: 385000,
      });
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0].amount).toBe(385000);
    });

    it('still refunds in full when the late approval is for a cancelled payment of a dropped collaboration', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const { paymentId } = await brandPaying(id);
      clock.advance(61 * MINUTE);
      await request(server)
        .post(`/collaborations/${id}/drop`)
        .set(authCreator)
        .send({ reason: 'BUDGET' })
        .expect(200);
      await prisma.payment.update({
        where: { id: paymentId },
        data: { status: 'CANCELLED' },
      });
      await approve(paymentId).expect(200);
      expect((await collaborationOf(id)).stage).toBe('DROPPED');
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 0,
        FEE_REVENUE: 0,
        STORE_REFUND: 385000,
      });
      expect(pg.refunds).toHaveLength(1);
      expect(pg.refunds[0].amount).toBe(385000);
    });

    it('refunds an old payment even when a new contract for the same collaboration awaits payment', async () => {
      const { id, paymentId } = await voidedByNewTerms();
      // 판본 2를 확인해 다시 합의하고 크리에이터가 새로 동의한다.
      await confirm(authBrand, id, 2).expect(200);
      await creatorConsented(id);
      expect(
        await prisma.contract.count({ where: { status: 'AWAITING_BRAND' } }),
      ).toBe(1);

      await approve(paymentId).expect(200);
      // 옛 계약의 결제는 새 계약을 체결하지 않는다.
      expect((await collaborationOf(id)).stage).toBe('AGREED');
      expect(
        await prisma.contract.count({ where: { status: 'CONCLUDED' } }),
      ).toBe(0);
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 0,
        STORE_REFUND: 385000,
      });
      expect(pg.refunds).toHaveLength(1);
      // 새 계약은 새 결제로 체결할 수 있다.
      const next = await brandPaying(id);
      await approve(next.paymentId).expect(200);
      expect((await collaborationOf(id)).stage).toBe('CONTRACTED');
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 340000,
        FEE_REVENUE: 34000,
        STORE_REFUND: 385000,
      });
    });

    it('refunds in full when the collaboration was dropped by a block before the approval', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const { paymentId } = await brandPaying(id);
      // 결제창을 열어 둔 채 60분이 지나 잠금이 풀린 뒤 크리에이터가 브랜드를 차단했다(돈이 아직 보관 중이 아니라 차단된다).
      clock.advance(61 * MINUTE);
      await request(server)
        .post(`/conversations/${await roomIdOf(id)}/block`)
        .set(authCreator)
        .expect(200);
      expect((await collaborationOf(id)).stage).toBe('DROPPED');
      expect(await prisma.contract.findFirstOrThrow({})).toMatchObject({
        status: 'VOIDED',
        voidReason: 'BLOCKED',
      });

      await approve(paymentId).expect(200);
      expect((await collaborationOf(id)).stage).toBe('DROPPED');
      expect(await balanceOf(id)).toMatchObject({
        ESCROW: 0,
        FEE_REVENUE: 0,
        STORE_REFUND: 385000,
      });
      expect(pg.refunds).toHaveLength(1);
      expect(alert).toHaveBeenCalledTimes(1);
    });
  });

  describe('concurrency', () => {
    it('never deadlocks when an approval and a second payment are created at once', async () => {
      const id = await agreed();
      await creatorConsented(id);
      const first = await brandPaying(id);
      const texts = await textsOf(authBrand, id);
      const [approval, second] = await Promise.all([
        approve(first.paymentId),
        brandConsent(id, { termsVersion: 1, accepted: texts, method: 'CARD' }),
      ]);
      expect(approval.status).toBe(200);
      // 승인이 먼저면 계약이 이미 체결돼 409이고, 나중이면 결제 진행 중이라 409다. 어느 쪽이든 새 결제는 없다.
      expect(second.status).toBe(409);
      expect(await prisma.payment.count()).toBe(1);
      const stage = (await collaborationOf(id)).stage;
      expect(stage).toBe('CONTRACTED');
      expect(
        await prisma.contract.count({ where: { status: 'CONCLUDED' } }),
      ).toBe(1);
      const entries = await balanceOf(id);
      expect(entries.ESCROW).toBe(350000);
    });
  });
});
