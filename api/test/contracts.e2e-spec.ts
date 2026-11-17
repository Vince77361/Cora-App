import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { PushPort } from '../src/integrations/push/push.port';
import { RealtimePublisher } from '../src/realtime/realtime-publisher';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { flushMessages } from './helpers/flush-messages';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
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
const NOON = new Date('2026-11-11T03:00:00.000Z');

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

describe('brand contract consent and payment', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let push: FakePushPort;
  let realtime: FakeRealtimePublisher;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
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
  const contractOf = async (auth: Record<string, string>, id: string) =>
    (await getContract(auth, id).expect(200)).body as ContractBody;
  const roomIdOf = async (collaborationId: string) =>
    (
      await prisma.conversation.findUniqueOrThrow({
        where: { collaborationId },
      })
    ).id;
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

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp([], { fakeRealtime: true });
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    push = app.get<FakePushPort>(PushPort);
    realtime = app.get<FakeRealtimePublisher>(RealtimePublisher);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(NOON);
    push.sent.length = 0;
    realtime.sent.length = 0;
  });
  afterAll(async () => {
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

    it('moves to AWAITING_CREATOR once both sides confirmed and to AWAITING_BRAND after the creator consented', async () => {
      const id = await agreed();
      expect(await contractOf(authBrand, id)).toMatchObject({
        status: 'AWAITING_CREATOR',
      });
      await creatorConsented(id);
      expect(await contractOf(authBrand, id)).toMatchObject({
        status: 'AWAITING_BRAND',
      });
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
});
