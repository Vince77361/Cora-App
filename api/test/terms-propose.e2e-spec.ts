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
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const CAMPAIGN = {
  headline: '나만의 아침 루틴 속 작은 포인트',
  fee: 300000,
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
const PERFORMANCE = { ratePer1000: 2000, cap: 60000 };

interface TermsBody {
  version: number;
  proposedBy: string;
  title: string;
  fee: number;
  performance: { ratePer1000: number; cap: number } | null;
  maxCash: number;
  startDate: string;
  format: string;
  pieces: number;
  productProvided: boolean;
  revisionScope: string;
  usageRights: string;
  payoutDays: number;
  brandConfirmed: boolean;
  creatorConfirmed: boolean;
  changedFields: string[];
  previousMaxCash: number | null;
  createdAt: string;
}
interface LatestBody {
  terms: TermsBody;
  myTurn: boolean;
  mine: boolean;
  needsInstagram: boolean;
}

describe('proposing a new terms version (proposeReward)', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let push: FakePushPort;
  let realtime: FakeRealtimePublisher;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const messageOf = (res: request.Response) =>
    (res.body as { error: { message: string } }).error.message;
  const setRole = (auth: Record<string, string>, role: string) =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const decide = (auth: Record<string, string>, body: object) =>
    request(server).put('/discovery/decisions').set(auth).send(body);
  const propose = (
    auth: Record<string, string>,
    id: string,
    body: Record<string, unknown>,
  ) => request(server).post(`/collaborations/${id}/terms`).set(auth).send(body);
  const confirm = (auth: Record<string, string>, id: string, version: number) =>
    request(server)
      .post(`/collaborations/${id}/terms/${version}/confirm`)
      .set(auth);
  const latestOf = async (auth: Record<string, string>, id: string) =>
    (
      await request(server)
        .get(`/collaborations/${id}/terms/latest`)
        .set(auth)
        .expect(200)
    ).body as LatestBody;
  const stageOf = async (id: string) =>
    (await prisma.collaboration.findUniqueOrThrow({ where: { id } })).stage;
  const same = (over: Record<string, unknown> = {}) => ({
    baseVersion: 1,
    fee: 300000,
    productProvided: true,
    performance: null,
    ...over,
  });

  async function makeBoth(
    campaign: Record<string, unknown> = {},
  ): Promise<string> {
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
      .send({ ...CAMPAIGN, ...campaign })
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

  // 서로 관심을 만들어 협업 id를 돌려준다.
  async function matchUp(campaignId: string): Promise<string> {
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

  const connectInstagram = () =>
    prisma.instagramConnection.create({
      data: {
        creatorId: OTHER,
        handle: 'haru_cup',
        followers: 12400,
        refreshedAt: NOON,
      },
    });

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
      .post(`/collaborations/${randomUUID()}/terms`)
      .send(same())
      .expect(401);
  });

  describe('the next version', () => {
    it('creates the next version with only money and benefit changed and marks the proposer confirmed', async () => {
      const id = await matchUp(await makeBoth());
      const res = await propose(
        authBrand,
        id,
        same({ fee: 450000, productProvided: false, performance: PERFORMANCE }),
      ).expect(201);
      const body = res.body as TermsBody;
      expect(body).toMatchObject({
        version: 2,
        proposedBy: 'BRAND',
        title: '아침 한 컵',
        fee: 450000,
        productProvided: false,
        performance: PERFORMANCE,
        startDate: '2026-11-20',
        format: 'REELS',
        pieces: 1,
        revisionScope: 'GUIDE_1',
        usageRights: 'REPOST_ONLY',
        payoutDays: 7,
        brandConfirmed: true,
        creatorConfirmed: false,
      });
      expect(await stageOf(id)).toBe('NEGOTIATING');
      expect(await prisma.termsVersion.count()).toBe(2);
      // 판본은 만들기만 한다: 1번은 그대로다.
      const v1 = await prisma.termsVersion.findFirstOrThrow({
        where: { version: 1 },
      });
      expect(v1).toMatchObject({
        fee: 300000,
        brandConfirmedAt: null,
        creatorConfirmedAt: null,
      });
    });

    it('reads an explicit null performance as no bonus and an absent one the same', async () => {
      const id = await matchUp(await makeBoth());
      await propose(
        authBrand,
        id,
        same({ fee: 450000, performance: PERFORMANCE }),
      ).expect(201);
      // 명시적 null은 "성과 추가 없음"이라는 값이다(앞 판본의 성과 추가를 끈다).
      const off = await propose(
        authCreator,
        id,
        same({ baseVersion: 2, fee: 450000, performance: null }),
      ).expect(201);
      expect((off.body as TermsBody).performance).toBeNull();
      expect((off.body as TermsBody).version).toBe(3);
      // 안 보낸 칸도 같다.
      const absent = await propose(authBrand, id, {
        baseVersion: 3,
        fee: 460000,
        productProvided: true,
      }).expect(201);
      expect((absent.body as TermsBody).performance).toBeNull();
    });

    it('lets the creator propose too and reads whose turn it is', async () => {
      const id = await matchUp(await makeBoth());
      await connectInstagram();
      const res = await propose(
        authCreator,
        id,
        same({ fee: 350000, performance: PERFORMANCE }),
      ).expect(201);
      expect(res.body).toMatchObject({
        version: 2,
        proposedBy: 'CREATOR',
        brandConfirmed: false,
        creatorConfirmed: true,
      });
      const creatorView = await latestOf(authCreator, id);
      expect(creatorView).toMatchObject({ mine: true, myTurn: false });
      const brandView = await latestOf(authBrand, id);
      expect(brandView).toMatchObject({ mine: false, myTurn: true });
    });

    it('clears the earlier confirmation when a new version is proposed after an agreement', async () => {
      const id = await matchUp(await makeBoth());
      await confirm(authBrand, id, 1).expect(200);
      await confirm(authCreator, id, 1).expect(200);
      expect(await stageOf(id)).toBe('AGREED');

      const res = await propose(authCreator, id, same({ fee: 280000 })).expect(
        201,
      );
      expect(res.body).toMatchObject({
        version: 2,
        creatorConfirmed: true,
        brandConfirmed: false,
      });
      // 합의가 취소되고 협의 단계로 돌아간다.
      expect(await stageOf(id)).toBe('NEGOTIATING');
      // 이전 판본의 수락은 새 판본에 이어지지 않는다: 상대가 새 판본을 수락해야 다시 합의된다.
      await confirm(authBrand, id, 2).expect(200);
      expect(await stageOf(id)).toBe('AGREED');
    });

    it('adds the performance cap to the maximum cash burden', async () => {
      const id = await matchUp(await makeBoth());
      const res = await propose(
        authBrand,
        id,
        same({ fee: 400000, performance: PERFORMANCE }),
      ).expect(201);
      expect((res.body as TermsBody).maxCash).toBe(460000);
      const plain = await propose(
        authBrand,
        id,
        same({ baseVersion: 2, fee: 400000, productProvided: false }),
      ).expect(201);
      expect((plain.body as TermsBody).maxCash).toBe(400000);
    });

    it('keeps the latest version reading for both sides after a proposal', async () => {
      const id = await matchUp(await makeBoth());
      await propose(authBrand, id, same({ fee: 320000 })).expect(201);
      expect((await latestOf(authCreator, id)).terms.version).toBe(2);
      expect((await latestOf(authBrand, id)).terms.fee).toBe(320000);
    });
  });

  describe('races and stale versions', () => {
    it('accepts only one of two proposals sent on the same base version', async () => {
      const id = await matchUp(await makeBoth());
      await connectInstagram();
      const [a, b] = await Promise.all([
        propose(authBrand, id, same({ fee: 400000 })),
        propose(authCreator, id, same({ fee: 250000 })),
      ]);
      expect([a.status, b.status].sort()).toEqual([201, 409]);
      const loser = a.status === 409 ? a : b;
      expect(codeOf(loser)).toBe('STALE_VERSION');
      expect(JSON.stringify(loser.body)).toContain('"latestVersion":2');
      expect(await prisma.termsVersion.count()).toBe(2);
    });

    it('refuses a proposal on an older base version with STALE_VERSION and the latest version', async () => {
      const id = await matchUp(await makeBoth());
      await propose(authBrand, id, same({ fee: 400000 })).expect(201);
      const res = await propose(authCreator, id, same({ fee: 250000 })).expect(
        409,
      );
      expect(codeOf(res)).toBe('STALE_VERSION');
      expect(JSON.stringify(res.body)).toContain('"latestVersion":2');
      expect(await prisma.termsVersion.count()).toBe(2);
    });

    it('does not leave a half-agreed state when a confirmation and a proposal race', async () => {
      const id = await matchUp(await makeBoth());
      await confirm(authBrand, id, 1).expect(200);
      const [c, p] = await Promise.all([
        confirm(authCreator, id, 1),
        propose(authBrand, id, same({ fee: 400000 })),
      ]);
      expect([200, 201, 409]).toContain(c.status);
      expect([200, 201, 409]).toContain(p.status);
      const rows = await prisma.termsVersion.findMany({
        orderBy: { version: 'desc' },
      });
      const latest = rows[0];
      const agreed = (await stageOf(id)) === 'AGREED';
      // 합의된 상태라면 최신 판본을 양쪽이 모두 수락한 것이어야 한다.
      if (agreed) {
        expect(latest.brandConfirmedAt).not.toBeNull();
        expect(latest.creatorConfirmedAt).not.toBeNull();
      }
    });
  });

  describe('what is refused', () => {
    it('rejects a proposal that changes nothing', async () => {
      const id = await matchUp(await makeBoth());
      const res = await propose(authBrand, id, same()).expect(400);
      expect(codeOf(res)).toBe('VALIDATION_FAILED');
      expect(messageOf(res)).toBe('바꾼 조건이 없어요.');
      expect(await prisma.termsVersion.count()).toBe(1);
    });

    it('rejects amounts outside the policy and a bonus on a blog campaign', async () => {
      const id = await matchUp(await makeBoth());
      await propose(authBrand, id, same({ fee: 455000 })).expect(400);
      await propose(authBrand, id, same({ fee: 5000 })).expect(400);
      await propose(
        authBrand,
        id,
        same({ performance: { ratePer1000: 2200, cap: 60000 } }),
      ).expect(400);
      await propose(
        authBrand,
        id,
        same({ performance: { ratePer1000: 2000, cap: 65000 } }),
      ).expect(400);
      await propose(authBrand, id, { baseVersion: 1, fee: 300000 }).expect(400);
      expect(await prisma.termsVersion.count()).toBe(1);
    });

    it('rejects a performance bonus on a blog campaign', async () => {
      const id = await matchUp(await makeBoth({ format: 'BLOG' }));
      const res = await propose(
        authBrand,
        id,
        same({ performance: PERFORMANCE }),
      ).expect(400);
      expect(codeOf(res)).toBe('VALIDATION_FAILED');
    });

    it('refuses a creator turning on a performance bonus without instagram', async () => {
      const id = await matchUp(await makeBoth());
      const res = await propose(
        authCreator,
        id,
        same({ fee: 350000, performance: PERFORMANCE }),
      ).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(messageOf(res)).toBe('인스타그램을 연동하면 수락할 수 있어요.');
      expect(await prisma.termsVersion.count()).toBe(1);
      // 성과 추가가 없는 제안은 연동 없이도 된다.
      await propose(authCreator, id, same({ fee: 350000 })).expect(201);
    });

    it('lets a brand turn on a performance bonus without any instagram connection', async () => {
      const id = await matchUp(await makeBoth());
      await propose(authBrand, id, same({ performance: PERFORMANCE })).expect(
        201,
      );
    });

    it('returns 404 to someone who is not a party and for an unknown collaboration', async () => {
      const id = await matchUp(await makeBoth());
      await request(server)
        .post(`/collaborations/${randomUUID()}/terms`)
        .set(authBrand)
        .send(same())
        .expect(404);
      await request(server)
        .post('/collaborations/not-a-uuid/terms')
        .set(authBrand)
        .send(same())
        .expect(404);
      expect(await prisma.termsVersion.count()).toBe(1);
      expect(await stageOf(id)).toBe('MATCHED');
    });

    it('refuses a proposal after the brand has paid (past the agreement stages)', async () => {
      const id = await matchUp(await makeBoth());
      await prisma.collaboration.update({
        where: { id },
        data: { stage: 'CONTRACTED' },
      });
      const res = await propose(authBrand, id, same({ fee: 400000 })).expect(
        409,
      );
      expect(codeOf(res)).toBe('CONFLICT');
      expect(await prisma.termsVersion.count()).toBe(1);
    });

    it('refuses a store offer collaboration', async () => {
      await makeBoth();
      const offerCollab = await prisma.collaboration.create({
        data: {
          kind: 'STORE_OFFER',
          stage: 'AWAITING_PAYMENT',
          commissionerId: USER_A,
          creatorId: OTHER,
          settlementMethod: 'NONE',
          terms: {},
        },
      });
      await propose(authBrand, offerCollab.id, same()).expect(404);
    });
  });

  describe('the notification', () => {
    it('tells the other side with the version number and the particles', async () => {
      const id = await matchUp(await makeBoth());
      await propose(authBrand, id, same({ fee: 400000 })).expect(201);
      const creatorGot = (
        (
          await request(server)
            .get('/notifications')
            .set(authCreator)
            .expect(200)
        ).body as {
          items: {
            text: string;
            tab: string;
            target: { kind: string; id: string };
          }[];
        }
      ).items.filter((i) => i.text.includes('제안'));
      expect(creatorGot).toHaveLength(1);
      expect(creatorGot[0]).toMatchObject({
        text: '느린결이 조건 버전 2를 제안했어요.',
        tab: 'COLLABORATION',
        target: { kind: 'TERMS', id },
      });
      // 제안한 쪽에는 알리지 않는다.
      const brandGot = (
        (await request(server).get('/notifications').set(authBrand).expect(200))
          .body as { items: { text: string }[] }
      ).items.filter((i) => i.text.includes('제안했어요'));
      expect(brandGot).toHaveLength(0);
    });

    it('cannot be switched off', async () => {
      const id = await matchUp(await makeBoth());
      push.sent.length = 0;
      await propose(authCreator, id, same({ fee: 280000 })).expect(201);
      expect(push.sent.map((p) => p.userId)).toEqual([USER_A]);
    });
  });
  // --- 5번 계획 Task 6: 모든 항목을 바꾸는 수정 제안, 안내 줄, 결제 잠금 ---
  describe('the full terms edit', () => {
    interface Line {
      kind: string;
      text: string | null;
      mine: boolean;
    }
    const roomOf = async (collaborationId: string) =>
      (
        await prisma.conversation.findUniqueOrThrow({
          where: { collaborationId },
        })
      ).id;
    const linesOf = async (
      auth: Record<string, string>,
      collaborationId: string,
    ): Promise<string[]> =>
      (
        (
          await request(server)
            .get(`/conversations/${await roomOf(collaborationId)}/messages`)
            .set(auth)
            .expect(200)
        ).body as Line[]
      )
        .filter((m) => m.kind === 'SYSTEM')
        .map((m) => m.text ?? '');
    const insertContract = (collaborationId: string, version = 1) =>
      prisma.contract.create({
        data: {
          collaborationId,
          status: 'AWAITING_BRAND',
          termsVersion: version,
          termsSnapshot: {},
          creatorConsentedAt: NOON,
          creatorConsentTexts: ['a', 'b', 'c'],
          brandConsentTexts: [],
        },
      });
    const insertPayment = (
      collaborationId: string,
      status: 'PENDING' | 'APPROVED',
      requestedAt: Date,
    ) =>
      prisma.payment.create({
        data: {
          collaborationId,
          amountEscrow: 300000,
          amountFee: 30000,
          feeRate: 10,
          method: 'CARD',
          status,
          requestedAt,
        },
      });
    const minutes = (n: number) => new Date(NOON.getTime() + n * 60_000);
    const listTerms = async (auth: Record<string, string>, id: string) =>
      (
        await request(server)
          .get(`/collaborations/${id}/terms`)
          .set(auth)
          .expect(200)
      ).body as {
        versions: TermsBody[] & { changedFields: string[] }[];
        agreement: string;
        editable: boolean;
      };

    it('lists the changed fields and both max cash values of a new version', async () => {
      const id = await matchUp(await makeBoth());
      const res = await propose(
        authBrand,
        id,
        same({
          fee: 350000,
          startDate: '2026-11-25',
          performance: PERFORMANCE,
        }),
      ).expect(201);
      expect(res.body).toMatchObject({
        version: 2,
        changedFields: ['FEE', 'PERFORMANCE', 'START_DATE'],
        maxCash: 410000,
        previousMaxCash: 300000,
        startDate: '2026-11-25',
        createdAt: NOON.toISOString(),
      });
    });

    it('changes every item at once and leaves an absent item as it was', async () => {
      const id = await matchUp(await makeBoth());
      const res = await propose(authBrand, id, {
        baseVersion: 1,
        title: '새 제목',
        startDate: '2026-12-01',
        format: 'SHORTS',
        pieces: 3,
        productProvided: false,
        revisionScope: 'DRAFT_2',
        usageRights: 'ADS_TOO',
        payoutDays: 14,
      }).expect(201);
      expect(res.body).toMatchObject({
        version: 2,
        title: '새 제목',
        fee: 300000,
        startDate: '2026-12-01',
        format: 'SHORTS',
        pieces: 3,
        productProvided: false,
        revisionScope: 'DRAFT_2',
        usageRights: 'ADS_TOO',
        payoutDays: 14,
        performance: null,
        changedFields: [
          'TITLE',
          'START_DATE',
          'DELIVERABLE',
          'PRODUCT',
          'REVISION',
          'USAGE',
          'PAYOUT',
        ],
      });
    });

    it('reads a null item as left out, the way the generated app client sends unused items', async () => {
      const id = await matchUp(await makeBoth());
      const res = await propose(authBrand, id, {
        baseVersion: 1,
        fee: 350000,
        productProvided: null,
        performance: null,
        title: null,
        startDate: null,
        format: null,
        pieces: null,
        revisionScope: null,
        usageRights: null,
        payoutDays: null,
      }).expect(201);
      expect(res.body).toMatchObject({
        version: 2,
        fee: 350000,
        title: '아침 한 컵',
        startDate: '2026-11-20',
        format: 'REELS',
        pieces: 1,
        productProvided: true,
        payoutDays: 7,
        changedFields: ['FEE'],
      });
    });

    it('keeps the performance bonus when it is left out and drops it only for null', async () => {
      const id = await matchUp(await makeBoth());
      await propose(
        authBrand,
        id,
        same({ fee: 350000, performance: PERFORMANCE }),
      ).expect(201);
      const kept = await propose(authCreator, id, {
        baseVersion: 2,
        title: '아침 한 컵 2',
      });
      // 성과 추가를 새로 켜지 않고 그대로 두는 제안이어도 결과 판본에 릴스의 성과 추가가 있으면 연동 검사가 걸린다.
      expect(kept.status).toBe(409);
      await connectInstagram();
      const ok = await propose(authCreator, id, {
        baseVersion: 2,
        title: '아침 한 컵 2',
      }).expect(201);
      expect((ok.body as TermsBody).performance).toEqual(PERFORMANCE);
      const off = await propose(authBrand, id, {
        baseVersion: 3,
        performance: null,
      }).expect(201);
      expect(off.body).toMatchObject({
        performance: null,
        changedFields: ['PERFORMANCE'],
        maxCash: 350000,
        previousMaxCash: 410000,
      });
    });

    it('rejects values outside the limits', async () => {
      const id = await matchUp(await makeBoth());
      const bad = (body: Record<string, unknown>) =>
        propose(authBrand, id, { baseVersion: 1, ...body }).expect(400);
      await bad({ title: '가'.repeat(41) });
      await bad({ title: '   ' });
      await bad({ pieces: 4 });
      await bad({ pieces: 0 });
      await bad({ payoutDays: 10 });
      await bad({ startDate: '2026-11-10' });
      await bad({ startDate: '2026-02-30' });
      await bad({ format: 'PODCAST' });
      await bad({ fee: 455000 });
      expect(await prisma.termsVersion.count()).toBe(1);
      // 시작일은 오늘(한국 날짜)도 된다.
      await propose(authBrand, id, {
        baseVersion: 1,
        startDate: '2026-11-11',
      }).expect(201);
    });

    it('rejects a performance bonus on a blog post with the blog message, also when only the format changes', async () => {
      const id = await matchUp(await makeBoth());
      const withBonus = await propose(
        authBrand,
        id,
        same({ performance: PERFORMANCE }),
      ).expect(201);
      expect((withBonus.body as TermsBody).version).toBe(2);
      const res = await propose(authBrand, id, {
        baseVersion: 2,
        format: 'BLOG',
      }).expect(400);
      expect(messageOf(res)).toBe('블로그 글은 조회수를 셀 수 없어요.');
      // 성과 추가를 함께 끄면 블로그로 바꿀 수 있다.
      await propose(authBrand, id, {
        baseVersion: 2,
        format: 'BLOG',
        performance: null,
      }).expect(201);
    });

    it('requires a linked instagram account when a creator changes the format to reels on a version with a performance bonus', async () => {
      const id = await matchUp(await makeBoth({ format: 'SHORTS' }));
      await propose(authBrand, id, same({ performance: PERFORMANCE })).expect(
        201,
      );
      // 쇼츠에서 바꾸는 제안은 검사하지 않는다.
      const res = await propose(authCreator, id, {
        baseVersion: 2,
        format: 'REELS',
      }).expect(409);
      expect(messageOf(res)).toBe('인스타그램을 연동하면 수락할 수 있어요.');
      await propose(authCreator, id, {
        baseVersion: 2,
        title: '쇼츠 제목',
      }).expect(201);
      // 카드뉴스도 같다. 연동하면 통과한다.
      await propose(authBrand, id, { baseVersion: 3, fee: 310000 }).expect(201);
      await propose(authCreator, id, {
        baseVersion: 4,
        format: 'CARD_NEWS',
      }).expect(409);
      await connectInstagram();
      await propose(authCreator, id, {
        baseVersion: 4,
        format: 'CARD_NEWS',
      }).expect(201);
    });

    it('creates the same kind of version from the reward-only call and the full proposal call', async () => {
      const id = await matchUp(await makeBoth());
      await propose(
        authBrand,
        id,
        same({ fee: 400000, productProvided: false, performance: PERFORMANCE }),
      ).expect(201);
      // 아무것도 바꾸지 않은 전체 본문도 "바꾼 조건이 없어요."다.
      const full = {
        baseVersion: 2,
        fee: 400000,
        productProvided: false,
        performance: PERFORMANCE,
        title: '아침 한 컵',
        startDate: '2026-11-20',
        format: 'REELS',
        pieces: 1,
        revisionScope: 'GUIDE_1',
        usageRights: 'REPOST_ONLY',
        payoutDays: 7,
      };
      expect(messageOf(await propose(authBrand, id, full).expect(400))).toBe(
        '바꾼 조건이 없어요.',
      );
      const second = await propose(authBrand, id, {
        ...full,
        fee: 410000,
      }).expect(201);
      expect((second.body as TermsBody).changedFields).toEqual(['FEE']);
      const rows = await prisma.termsVersion.findMany({
        where: { version: { in: [2, 3] } },
        orderBy: { version: 'asc' },
      });
      const shape = (r: (typeof rows)[number]) => ({
        ...r,
        id: undefined,
        version: undefined,
        fee: undefined,
        createdAt: undefined,
        updatedAt: undefined,
      });
      // 두 길이 만든 판본은 제작비와 번호 말고는 같은 모양이다(같은 서비스 함수).
      expect(shape(rows[1])).toEqual(shape(rows[0]));
    });

    it('voids the creator consent when a new version is proposed', async () => {
      const id = await matchUp(await makeBoth());
      await confirm(authBrand, id, 1).expect(200);
      await confirm(authCreator, id, 1).expect(200);
      const contract = await insertContract(id);
      await propose(authBrand, id, same({ fee: 400000 })).expect(201);
      expect(
        await prisma.contract.findUniqueOrThrow({ where: { id: contract.id } }),
      ).toMatchObject({ status: 'VOIDED', voidReason: 'NEW_TERMS' });
      expect(await stageOf(id)).toBe('NEGOTIATING');
      // 안내 줄은 동의 취소가 먼저, 그다음 제안이다.
      expect((await linesOf(authCreator, id)).slice(-2)).toEqual([
        '조건이 바뀌어 계약 동의가 취소됐어요.',
        '느린결님이 조건 버전 2를 제안했어요.',
      ]);
    });

    it('leaves a concluded contract alone', async () => {
      const id = await matchUp(await makeBoth());
      const contract = await insertContract(id);
      await prisma.contract.update({
        where: { id: contract.id },
        data: { status: 'CONCLUDED', concludedAt: NOON },
      });
      await prisma.collaboration.update({
        where: { id },
        data: { stage: 'CONTRACTED' },
      });
      await propose(authBrand, id, same({ fee: 400000 })).expect(409);
      expect(
        (
          await prisma.contract.findUniqueOrThrow({
            where: { id: contract.id },
          })
        ).status,
      ).toBe('CONCLUDED');
    });

    it('refuses a proposal while the brand payment is pending and allows it once the lock has passed', async () => {
      const id = await matchUp(await makeBoth());
      await confirm(authBrand, id, 1).expect(200);
      await confirm(authCreator, id, 1).expect(200);
      await insertPayment(id, 'PENDING', NOON);
      clock.set(minutes(59));
      const res = await propose(authCreator, id, same({ fee: 280000 })).expect(
        409,
      );
      expect(codeOf(res)).toBe('CONFLICT');
      expect(messageOf(res)).toBe(
        '브랜드가 결제를 진행하고 있어요. 잠시 뒤 다시 시도해 주세요.',
      );
      expect(await prisma.termsVersion.count()).toBe(1);
      expect(await stageOf(id)).toBe('AGREED');
      expect((await listTerms(authCreator, id)).editable).toBe(false);
      // 61분 뒤에는 열려 있던 결제를 없는 것으로 본다.
      clock.set(minutes(61));
      expect((await listTerms(authCreator, id)).editable).toBe(true);
      await propose(authCreator, id, same({ fee: 280000 })).expect(201);
    });

    it('does not lock on a payment that is not pending', async () => {
      const id = await matchUp(await makeBoth());
      await insertPayment(id, 'APPROVED', NOON);
      await propose(authBrand, id, same({ fee: 400000 })).expect(201);
    });

    it('does not count confirmations of an older version toward agreement', async () => {
      const id = await matchUp(await makeBoth());
      await confirm(authBrand, id, 1).expect(200);
      await propose(authCreator, id, same({ fee: 280000 })).expect(201);
      // 브랜드의 판본 1 확인과 크리에이터의 판본 2 제안은 서로 다른 판본이라 합의가 아니다.
      expect(await stageOf(id)).toBe('NEGOTIATING');
      const view = await listTerms(authBrand, id);
      expect(view.agreement).toBe('WAITING_BRAND');
      const stale = await confirm(authCreator, id, 1).expect(409);
      expect(codeOf(stale)).toBe('STALE_VERSION');
      expect(await stageOf(id)).toBe('NEGOTIATING');
    });

    it('still returns STALE_VERSION when confirming version 2 once version 3 exists', async () => {
      const id = await matchUp(await makeBoth());
      await propose(authBrand, id, same({ fee: 280000 })).expect(201);
      await propose(
        authBrand,
        id,
        same({ baseVersion: 2, fee: 270000 }),
      ).expect(201);
      const before = await prisma.termsVersion.findFirstOrThrow({
        where: { version: 2 },
      });
      const res = await confirm(authCreator, id, 2).expect(409);
      expect(codeOf(res)).toBe('STALE_VERSION');
      expect(JSON.stringify(res.body)).toContain('"latestVersion":3');
      const after = await prisma.termsVersion.findFirstOrThrow({
        where: { version: 2 },
      });
      expect(after.creatorConfirmedAt).toEqual(before.creatorConfirmedAt);
    });

    it('never agrees the older version when a confirmation and a proposal cross', async () => {
      const id = await matchUp(await makeBoth());
      await confirm(authBrand, id, 1).expect(200);
      await Promise.all([
        confirm(authCreator, id, 1),
        propose(authBrand, id, same({ fee: 400000 })),
      ]);
      // 어느 쪽이 먼저든 새 판본이 있고, 새 판본은 브랜드만 확인했으므로 합의가 아니다.
      expect(await prisma.termsVersion.count()).toBe(2);
      expect(await stageOf(id)).toBe('NEGOTIATING');
    });
  });

  describe('the terms history', () => {
    const history = async (auth: Record<string, string>, id: string) =>
      (
        await request(server)
          .get(`/collaborations/${id}/terms`)
          .set(auth)
          .expect(200)
      ).body as {
        versions: (TermsBody & {
          changedFields: string[];
          previousMaxCash: number | null;
        })[];
        agreement: string;
        editable: boolean;
      };

    it('lists the versions newest first with what changed and whom it is waiting for', async () => {
      const id = await matchUp(await makeBoth());
      let view = await history(authBrand, id);
      expect(view.versions.map((v) => v.version)).toEqual([1]);
      expect(view).toMatchObject({ agreement: 'NONE', editable: true });
      expect(view.versions[0]).toMatchObject({
        changedFields: [],
        previousMaxCash: null,
      });

      await propose(authBrand, id, same({ fee: 350000 })).expect(201);
      view = await history(authCreator, id);
      expect(view.versions.map((v) => v.version)).toEqual([2, 1]);
      expect(view.versions[0]).toMatchObject({
        changedFields: ['FEE'],
        previousMaxCash: 300000,
        maxCash: 350000,
      });
      expect(view.versions[1].changedFields).toEqual([]);
      expect(view.agreement).toBe('WAITING_CREATOR');

      await confirm(authCreator, id, 2).expect(200);
      expect((await history(authBrand, id)).agreement).toBe('AGREED');
      await propose(
        authCreator,
        id,
        same({ baseVersion: 2, fee: 340000 }),
      ).expect(201);
      expect((await history(authBrand, id)).agreement).toBe('WAITING_BRAND');
    });

    it('is not editable once the contract is concluded or after the negotiation was dropped', async () => {
      const id = await matchUp(await makeBoth());
      await prisma.collaboration.update({
        where: { id },
        data: { stage: 'CONTRACTED' },
      });
      expect((await history(authBrand, id)).editable).toBe(false);
    });

    it('returns 404 to someone who is not a party', async () => {
      await matchUp(await makeBoth());
      await request(server)
        .get(`/collaborations/${randomUUID()}/terms`)
        .set(authBrand)
        .expect(404);
      await request(server)
        .get('/collaborations/not-a-uuid/terms')
        .set(authBrand)
        .expect(404);
      await request(server)
        .get(`/collaborations/${randomUUID()}/terms`)
        .expect(401);
    });

    it('also reads latest with the changed fields of that version', async () => {
      const id = await matchUp(await makeBoth());
      await propose(authBrand, id, same({ fee: 350000 })).expect(201);
      expect((await latestOf(authCreator, id)).terms).toMatchObject({
        changedFields: ['FEE'],
        previousMaxCash: 300000,
      });
    });
  });

  describe('system lines and conversation updates', () => {
    interface Line {
      kind: string;
      text: string | null;
    }
    const systemLines = async (auth: Record<string, string>, id: string) => {
      const room = await prisma.conversation.findUniqueOrThrow({
        where: { collaborationId: id },
      });
      return (
        (
          await request(server)
            .get(`/conversations/${room.id}/messages`)
            .set(auth)
            .expect(200)
        ).body as Line[]
      )
        .filter((m) => m.kind === 'SYSTEM')
        .map((m) => m.text ?? '');
    };
    const updates = (userId: string, reason: string) =>
      realtime
        .receivedBy(userId, 'conversation.updated')
        .filter((e) => (e.payload as { reason: string }).reason === reason);

    it('writes a proposal line worded for each reader and pushes it live to both', async () => {
      const id = await matchUp(await makeBoth());
      realtime.sent.length = 0;
      await propose(authBrand, id, same({ fee: 400000 })).expect(201);
      await flushMessages(app);
      expect((await systemLines(authCreator, id)).pop()).toBe(
        '느린결님이 조건 버전 2를 제안했어요.',
      );
      expect((await systemLines(authBrand, id)).pop()).toBe(
        '조건 버전 2를 제안했어요.',
      );
      expect(realtime.receivedBy(OTHER, 'message.created')).toHaveLength(1);
      expect(realtime.receivedBy(USER_A, 'message.created')).toHaveLength(1);
      expect(updates(OTHER, 'TERMS')).toHaveLength(1);
      expect(updates(USER_A, 'TERMS')).toHaveLength(1);
    });

    it('writes a line for one confirmation and a single agreement line for both', async () => {
      const id = await matchUp(await makeBoth());
      realtime.sent.length = 0;
      await confirm(authBrand, id, 1).expect(200);
      expect((await systemLines(authCreator, id)).pop()).toBe(
        '느린결님이 조건 버전 1을 확인했어요.',
      );
      expect(updates(OTHER, 'TERMS')).toHaveLength(1);
      const before = (await systemLines(authCreator, id)).length;
      await confirm(authCreator, id, 1).expect(200);
      const lines = await systemLines(authBrand, id);
      expect(lines).toHaveLength(before + 1);
      expect(lines.pop()).toBe('양쪽이 조건 버전 1을 확인했어요.');
      expect(updates(USER_A, 'TERMS')).toHaveLength(2);
    });

    it('does not repeat the line or the update when the same version is confirmed again', async () => {
      const id = await matchUp(await makeBoth());
      await confirm(authBrand, id, 1).expect(200);
      const count = (await systemLines(authBrand, id)).length;
      realtime.sent.length = 0;
      await confirm(authBrand, id, 1).expect(200);
      expect(await systemLines(authBrand, id)).toHaveLength(count);
      expect(realtime.sent).toHaveLength(0);
    });

    it('sends the terms notification but no message push for the system line', async () => {
      const id = await matchUp(await makeBoth());
      push.sent.length = 0;
      await propose(authBrand, id, same({ fee: 400000 })).expect(201);
      await confirm(authCreator, id, 2).expect(200);
      await flushMessages(app);
      // 제안과 확인 각각 알림 하나씩만 나간다(안내 줄의 대화 메시지 푸시는 없다).
      expect(push.sent.map((p) => p.userId)).toEqual([OTHER, USER_A]);
    });

    it('does not write a line or update when the proposal is refused', async () => {
      const id = await matchUp(await makeBoth());
      const lines = (await systemLines(authBrand, id)).length;
      realtime.sent.length = 0;
      await propose(authBrand, id, same()).expect(400);
      await propose(
        authBrand,
        id,
        same({ baseVersion: 7, fee: 400000 }),
      ).expect(409);
      expect(await systemLines(authBrand, id)).toHaveLength(lines);
      expect(realtime.sent).toHaveLength(0);
    });
  });
});
