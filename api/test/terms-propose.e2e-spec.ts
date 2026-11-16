import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { PushPort } from '../src/integrations/push/push.port';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakePushPort } from './support/fake-push.port';
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
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    push = app.get<FakePushPort>(PushPort);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(NOON);
    push.sent.length = 0;
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
});
