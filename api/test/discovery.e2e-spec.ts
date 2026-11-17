import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { IndustryCategory, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { BrandsService } from '../src/brands/brands.service';
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

// user-a는 브랜드, user-b는 크리에이터다. 나머지 사람은 DB에 바로 만든다.
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
const PROPOSAL = {
  fee: 450000,
  productProvided: false,
  performance: { ratePer1000: 2000, cap: 60000 },
};
// 한국 시간 2026-11-11 12:00. 그날의 시작은 2026-11-10T15:00Z, 다음 날의 시작은 2026-11-11T15:00Z다.
const NOON = new Date('2026-11-11T03:00:00.000Z');
const NEXT_DAY = new Date('2026-11-11T15:01:00.000Z');

interface DecisionResult {
  decision: string;
  matched: boolean;
  collaborationId: string | null;
  conversationId: string | null;
}
interface CollaborationBody {
  id: string;
  kind: string;
  stage: string;
  role: string;
  terms: unknown;
  counterpart: { name: string };
}

describe('discovery decisions', () => {
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
  const put = (auth: Record<string, string>, body: Record<string, unknown>) =>
    request(server).put('/discovery/decisions').set(auth).send(body);
  const brandLike = (extra: Record<string, unknown> = {}) =>
    put(authBrand, {
      targetKind: 'CREATOR',
      targetId: OTHER,
      decision: 'LIKE',
      ...extra,
    });
  const creatorLike = (campaignId: string, extra = {}) =>
    put(authCreator, {
      targetKind: 'CAMPAIGN',
      targetId: campaignId,
      decision: 'LIKE',
      ...extra,
    });
  const resultOf = (res: request.Response) => res.body as DecisionResult;

  // user-a를 브랜드로 만들고 진행 중인 캠페인을 낸다.
  async function makeBrand(
    industry: IndustryCategory = 'ACCESSORY',
    campaign: Record<string, unknown> = {},
  ): Promise<string> {
    await setRole(authBrand, 'BRAND');
    await request(server)
      .put('/brands/me')
      .set(authBrand)
      .send({ name: '느린결', tagline: '천천히 쓰는 물건', industry })
      .expect(200);
    const res = await request(server)
      .post('/campaigns')
      .set(authBrand)
      .send({ ...CAMPAIGN, ...campaign })
      .expect(201);
    return (res.body as { id: string }).id;
  }

  // user-b를 크리에이터로 만든다. 원칙이 null이면 원칙 없이 둔다.
  async function makeCreator(
    principles: Record<string, unknown> | null = {},
  ): Promise<void> {
    await setRole(authCreator, 'CREATOR');
    await request(server)
      .put('/creators/me')
      .set(authCreator)
      .send({ displayName: '하루 한 컵', ...REGION })
      .expect(200);
    if (principles) {
      await request(server)
        .put('/creators/me/principles')
        .set(authCreator)
        .send({ ...PRINCIPLES, ...principles })
        .expect(200);
    }
  }

  const bothSides = async (industry: IndustryCategory = 'ACCESSORY') => {
    const campaignId = await makeBrand(industry);
    await makeCreator();
    return campaignId;
  };

  async function seedStore(name = '한그릇 라멘'): Promise<string> {
    const ownerId = randomUUID();
    await prisma.user.create({ data: { id: ownerId, role: 'STORE' } });
    const store = await prisma.store.create({
      data: {
        ownerId,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name,
        industry: 'FOOD_CAFE',
        ...REGION,
        intro: '작은 가게예요.',
        defaultFormat: 'REELS',
        defaultVoucherName: '식사권',
        defaultVoucherValue: 40000,
        defaultVoucherPeople: 2,
        defaultFixedCash: 0,
        publishedAt: new Date('2026-11-01T00:00:00Z'),
      },
    });
    return store.id;
  }

  const decisionRows = () => prisma.swipeDecision.findMany();

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
    await request(server).put('/discovery/decisions').send({}).expect(401);
    await request(server).put('/discovery/decisions/pass-reason').expect(401);
    await request(server).delete('/discovery/decisions/last').expect(401);
    await request(server)
      .put(`/discovery/store-passes/${randomUUID()}`)
      .expect(401);
  });

  describe('who may decide', () => {
    it('refuses a decision from a user without a role', async () => {
      const res = await put(authBrand, {
        targetKind: 'CREATOR',
        targetId: OTHER,
        decision: 'LIKE',
      }).expect(403);
      expect(codeOf(res)).toBe('FORBIDDEN');
      expect(await decisionRows()).toHaveLength(0);
    });

    it('refuses a brand deciding on a campaign and a creator deciding on a creator', async () => {
      const campaignId = await bothSides();
      await put(authBrand, {
        targetKind: 'CAMPAIGN',
        targetId: campaignId,
        decision: 'LIKE',
      }).expect(400);
      await put(authCreator, {
        targetKind: 'CREATOR',
        targetId: USER_A,
        decision: 'LIKE',
      }).expect(400);
    });

    it('asks a brand without an active campaign to make one first', async () => {
      await setRole(authBrand, 'BRAND');
      await request(server)
        .put('/brands/me')
        .set(authBrand)
        .send({ name: '느린결', industry: 'ACCESSORY' })
        .expect(200);
      await makeCreator();
      const res = await brandLike().expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
    });

    it('returns 404 when liking a creator who avoids my industry', async () => {
      await makeBrand('ALCOHOL');
      await makeCreator({ blockedIndustries: ['ALCOHOL'] });
      await brandLike().expect(404);
      expect(await decisionRows()).toHaveLength(0);
    });

    it('returns 404 when a brand likes a creator who has no principles', async () => {
      await makeBrand();
      await makeCreator(null);
      await brandLike().expect(404);
    });

    it('returns 404 when a creator likes a campaign of an industry they avoid or a closed one', async () => {
      const campaignId = await makeBrand('ALCOHOL');
      await makeCreator({ blockedIndustries: ['ALCOHOL'] });
      await creatorLike(campaignId).expect(404);
      await creatorLike(randomUUID()).expect(404);
    });
  });

  describe('like, pass and hold', () => {
    it('stores a like and reports no match when the other side has not liked', async () => {
      await bothSides();
      const res = await brandLike().expect(200);
      expect(resultOf(res)).toEqual({
        decision: 'LIKE',
        matched: false,
        collaborationId: null,
        conversationId: null,
      });
      const rows = await decisionRows();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        actorId: USER_A,
        targetKind: 'CREATOR',
        targetId: OTHER,
        decision: 'LIKE',
      });
      expect(await prisma.match.count()).toBe(0);
      expect(await prisma.collaboration.count()).toBe(0);
    });

    it('changes a pass into a like and the pass reason is cleared with it', async () => {
      await bothSides();
      await brandLike({ decision: 'PASS' }).expect(200);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authBrand)
        .send({ targetKind: 'CREATOR', targetId: OTHER, reason: 'FEE' })
        .expect(204);
      await brandLike().expect(200);
      const rows = await decisionRows();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({ decision: 'LIKE', passReason: null });
    });

    it('validates the length of the note by who sends it', async () => {
      const campaignId = await bothSides();
      await brandLike({ note: 'ㅁ'.repeat(101) }).expect(400);
      await brandLike({ note: 'ㅁ'.repeat(100) }).expect(200);
      await creatorLike(campaignId, { note: 'ㅁ'.repeat(41) }).expect(400);
      await creatorLike(campaignId, { note: 'ㅁ'.repeat(40) }).expect(200);
    });

    it('copies the creator card title and photo when a brand likes with a note', async () => {
      await bothSides();
      await prisma.creatorProfile.update({
        where: { userId: OTHER },
        data: {
          cardHeadline: '출근길 한 컵 이야기',
          cardPhotoPath: `creator-cards/${OTHER}/${randomUUID()}.jpg`,
        },
      });
      const card = await prisma.creatorProfile.findUniqueOrThrow({
        where: { userId: OTHER },
      });
      await brandLike({ note: '아침 사진이 좋았어요' }).expect(200);
      const [row] = await decisionRows();
      expect(row).toMatchObject({
        note: '아침 사진이 좋았어요',
        contentTitle: '출근길 한 컵 이야기',
        contentPhotoPath: card.cardPhotoPath,
      });
    });

    it('does not copy the card when the like carries no note', async () => {
      await bothSides();
      await prisma.creatorProfile.update({
        where: { userId: OTHER },
        data: { cardHeadline: '출근길 한 컵 이야기' },
      });
      await brandLike().expect(200);
      const [row] = await decisionRows();
      expect(row).toMatchObject({
        note: null,
        contentTitle: null,
        contentPhotoPath: null,
      });
    });
  });

  describe('the brand proposal on a like', () => {
    it('stores the proposal with the like', async () => {
      await bothSides();
      await brandLike({ proposal: PROPOSAL }).expect(200);
      const [row] = await decisionRows();
      expect(row).toMatchObject({
        proposedFee: 450000,
        proposedProductProvided: false,
        proposedPerfRate: 2000,
        proposedPerfCap: 60000,
      });
    });

    it('overwrites the proposal on an existing like without creating a second decision', async () => {
      await bothSides();
      await brandLike({ proposal: PROPOSAL }).expect(200);
      await brandLike({
        proposal: { fee: 500000, productProvided: true, performance: null },
      }).expect(200);
      const rows = await decisionRows();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        decision: 'LIKE',
        proposedFee: 500000,
        proposedProductProvided: true,
        proposedPerfRate: null,
        proposedPerfCap: null,
      });
    });

    it('keeps the stored proposal when a plain like is sent again', async () => {
      await bothSides();
      await brandLike({ proposal: PROPOSAL }).expect(200);
      await brandLike().expect(200);
      const [row] = await decisionRows();
      expect(row.proposedFee).toBe(450000);
      expect(row.proposedPerfCap).toBe(60000);
    });

    it('treats explicit nulls for the note and the proposal as not sent', async () => {
      const campaignId = await bothSides();
      // 생성된 클라이언트는 비운 선택 칸을 명시적 null로 보낸다.
      const first = await brandLike({ note: null, proposal: null }).expect(200);
      expect(resultOf(first).decision).toBe('LIKE');
      let [row] = await decisionRows();
      expect(row).toMatchObject({ note: null, proposedFee: null });

      // 저장된 글과 제안은 null을 다시 보내도 지워지거나 덮이지 않는다.
      await brandLike({ note: '좋았어요', proposal: PROPOSAL }).expect(200);
      await brandLike({ note: null, proposal: null }).expect(200);
      [row] = await decisionRows();
      expect(row).toMatchObject({
        note: '좋았어요',
        proposedFee: 450000,
        proposedPerfCap: 60000,
      });
      // 넘김과 보류에도 null 제안은 그냥 받는다.
      await brandLike({ decision: 'PASS', note: null, proposal: null }).expect(
        200,
      );
      // 크리에이터도 같다.
      await creatorLike(campaignId, { note: null, proposal: null }).expect(200);
      const creatorRow = (await decisionRows()).find(
        (r) => r.actorId === OTHER,
      );
      expect(creatorRow).toMatchObject({ decision: 'LIKE', note: null });
    });

    it('rejects a proposal from a creator', async () => {
      const campaignId = await bothSides();
      const res = await creatorLike(campaignId, {
        proposal: PROPOSAL,
      }).expect(400);
      expect(codeOf(res)).toBe('VALIDATION_FAILED');
      expect(await decisionRows()).toHaveLength(0);
    });

    it('rejects a proposal on a pass', async () => {
      await bothSides();
      await brandLike({ decision: 'PASS', proposal: PROPOSAL }).expect(400);
    });

    it('rejects a performance bonus on a blog campaign', async () => {
      await makeBrand('ACCESSORY', { format: 'BLOG' });
      await makeCreator();
      const res = await brandLike({ proposal: PROPOSAL }).expect(400);
      expect(codeOf(res)).toBe('VALIDATION_FAILED');
      // 성과 추가가 없는 제안은 블로그 글에도 붙일 수 있다.
      await brandLike({
        proposal: { fee: 450000, productProvided: false, performance: null },
      }).expect(200);
    });

    it('rejects amounts outside the policy ranges and steps', async () => {
      await bothSides();
      const bad = (proposal: Record<string, unknown>) =>
        brandLike({ proposal }).expect(400);
      const ok = { fee: 450000, productProvided: true };
      await bad({ ...ok, fee: 5000 });
      await bad({ ...ok, fee: 455000 });
      await bad({ ...ok, fee: 10010000 });
      await bad({ ...ok, performance: { ratePer1000: 2200, cap: 60000 } });
      await bad({ ...ok, performance: { ratePer1000: 500, cap: 60000 } });
      await bad({ ...ok, performance: { ratePer1000: 2000, cap: 65000 } });
      await bad({ ...ok, performance: { ratePer1000: 2000, cap: 310000 } });
      expect(await decisionRows()).toHaveLength(0);
    });
  });

  describe('mutual interest', () => {
    it('creates a match, a MATCHED collaboration and terms version 1 when the brand likes second', async () => {
      const campaignId = await bothSides();
      await creatorLike(campaignId, { note: '출근길 한 컵 이야기' }).expect(
        200,
      );
      const res = await brandLike().expect(200);
      const result = resultOf(res);
      expect(result).toMatchObject({ decision: 'LIKE', matched: true });

      const matches = await prisma.match.findMany();
      expect(matches).toHaveLength(1);
      expect(matches[0]).toMatchObject({
        campaignId,
        creatorId: OTHER,
        collaborationId: result.collaborationId,
        matchedAt: NOON,
      });
      const collaborations = await prisma.collaboration.findMany();
      expect(collaborations).toHaveLength(1);
      expect(collaborations[0]).toMatchObject({
        id: result.collaborationId,
        kind: 'BRAND_CONTRACT',
        stage: 'MATCHED',
        settlementMethod: 'FIXED',
        commissionerId: USER_A,
        creatorId: OTHER,
        campaignId,
        offerId: null,
        storeId: null,
        terms: {},
      });
      const versions = await prisma.termsVersion.findMany();
      expect(versions).toHaveLength(1);
      expect(versions[0]).toMatchObject({
        collaborationId: result.collaborationId,
        version: 1,
        proposedById: null,
        title: '출근길 한 컵 이야기',
        fee: 300000,
        format: 'REELS',
        pieces: 1,
        productProvided: true,
        revisionScope: 'GUIDE_1',
        usageRights: 'REPOST_ONLY',
        payoutDays: 7,
        perfRatePerThousand: null,
        perfCap: null,
        brandConfirmedAt: null,
        creatorConfirmedAt: null,
      });
    });

    it('creates the same result when the creator likes second', async () => {
      const campaignId = await bothSides();
      await brandLike().expect(200);
      const result = resultOf(await creatorLike(campaignId).expect(200));
      expect(result.matched).toBe(true);
      expect(result.collaborationId).not.toBeNull();
      expect(await prisma.match.count()).toBe(1);
      const [version] = await prisma.termsVersion.findMany();
      // 크리에이터가 글을 붙이지 않았으니 캠페인 한 줄이 제목이다.
      expect(version.title).toBe(CAMPAIGN.headline);
    });

    it('opens a conversation with both members on a mutual like', async () => {
      const campaignId = await bothSides();
      await creatorLike(campaignId).expect(200);
      const notYet = resultOf(await brandLike().expect(200));
      const rooms = await prisma.conversation.findMany({
        include: { members: true, messages: true },
      });
      expect(rooms).toHaveLength(1);
      const [room] = rooms;
      expect(notYet.conversationId).toBe(room.id);
      expect(room).toMatchObject({
        collaborationId: notYet.collaborationId,
        status: 'OPEN',
        requestedById: null,
        lastSeq: 1,
      });
      expect(room.members.map((m) => m.userId).sort()).toEqual(
        [USER_A, OTHER].sort(),
      );
      expect(room.messages).toHaveLength(1);
      expect(room.messages[0]).toMatchObject({
        seq: 1,
        kind: 'SYSTEM',
        senderId: null,
        systemCode: 'MATCHED',
      });
      // 같은 안내 줄이 읽는 사람마다 상대의 이름으로 보인다.
      const line = async (auth: Record<string, string>) =>
        (
          (
            await request(server)
              .get(`/conversations/${room.id}/messages`)
              .set(auth)
              .expect(200)
          ).body as { text: string }[]
        )[0].text;
      expect(await line(authBrand)).toBe(
        '하루 한 컵님과 서로 관심이 닿았어요. 조건 버전 1이 만들어졌어요.',
      );
      expect(await line(authCreator)).toBe(
        '느린결님과 서로 관심이 닿았어요. 조건 버전 1이 만들어졌어요.',
      );
      const head = (
        await request(server)
          .get(`/conversations/${room.id}`)
          .set(authCreator)
          .expect(200)
      ).body as { stage: string; terms: { version: number } };
      expect(head).toMatchObject({ stage: 'MATCHED', terms: { version: 1 } });
    });

    it('delivers the matched line to both members after the commit and not before a match', async () => {
      const campaignId = await bothSides();
      await creatorLike(campaignId).expect(200);
      expect(realtime.sent).toEqual([]);
      const matched = resultOf(await brandLike().expect(200));
      await flushMessages(app);
      for (const user of [USER_A, OTHER]) {
        const lines = realtime.receivedBy(user, 'message.created');
        expect(lines).toHaveLength(1);
        expect(lines[0].payload).toMatchObject({
          conversationId: matched.conversationId,
          message: { seq: 1, kind: 'SYSTEM', mine: false },
        });
        expect(
          realtime
            .receivedBy(user, 'conversation.updated')
            .map((e) => e.payload),
        ).toEqual([
          { conversationId: matched.conversationId, reason: 'STATUS' },
        ]);
      }
      // 안내 줄의 대화 메시지 푸시는 없다(서로 관심 알림만 간다).
      expect(push.sent.every((p) => p.title === '')).toBe(true);
    });

    it('does not open a conversation when there is no match', async () => {
      const campaignId = await bothSides();
      const result = resultOf(await creatorLike(campaignId).expect(200));
      expect(result.conversationId).toBeNull();
      expect(await prisma.conversation.count()).toBe(0);
    });

    it('drafts version 1 from the brand proposal when the like carried one', async () => {
      const campaignId = await bothSides();
      await brandLike({ proposal: PROPOSAL }).expect(200);
      await creatorLike(campaignId).expect(200);
      const [version] = await prisma.termsVersion.findMany();
      expect(version).toMatchObject({
        fee: 450000,
        productProvided: false,
        perfRatePerThousand: 2000,
        perfCap: 60000,
        pieces: 1,
        revisionScope: 'GUIDE_1',
      });
    });

    it('drops the performance bonus from version 1 when the campaign became a blog after the like', async () => {
      const campaignId = await bothSides();
      // 릴스일 때 성과 추가가 붙은 관심을 보낸 뒤 브랜드가 형식을 블로그로 바꾼다.
      await brandLike({ proposal: PROPOSAL }).expect(200);
      await request(server)
        .patch(`/campaigns/${campaignId}`)
        .set(authBrand)
        .send({ format: 'BLOG' })
        .expect(200);
      await creatorLike(campaignId).expect(200);
      const [version] = await prisma.termsVersion.findMany();
      expect(version).toMatchObject({
        format: 'BLOG',
        fee: 450000,
        productProvided: false,
        perfRatePerThousand: null,
        perfCap: null,
      });
    });

    it('leaves version 1 unconfirmed by both sides even when it came from a brand proposal', async () => {
      const campaignId = await bothSides();
      await brandLike({ proposal: PROPOSAL }).expect(200);
      await creatorLike(campaignId).expect(200);
      const [version] = await prisma.termsVersion.findMany();
      expect(version.proposedById).toBeNull();
      expect(version.brandConfirmedAt).toBeNull();
      expect(version.creatorConfirmedAt).toBeNull();
    });

    it('creates exactly one match when both likes arrive at the same time', async () => {
      const campaignId = await bothSides();
      const [a, b] = await Promise.all([
        brandLike({ proposal: PROPOSAL }),
        creatorLike(campaignId),
      ]);
      expect(a.status).toBe(200);
      expect(b.status).toBe(200);
      // 한쪽이 먼저 줄을 서고 나중 쪽이 서로 관심을 만든다.
      expect(
        [resultOf(a).matched, resultOf(b).matched].filter(Boolean),
      ).toHaveLength(1);
      expect(await prisma.match.count()).toBe(1);
      expect(await prisma.collaboration.count()).toBe(1);
      expect(await prisma.termsVersion.count()).toBe(1);
      expect(await decisionRows()).toHaveLength(2);
      // 알림도 양쪽에 한 번씩만 간다.
      expect(await prisma.notification.count()).toBe(2);
    });

    it('notifies both sides on a match', async () => {
      const campaignId = await bothSides();
      await brandLike().expect(200);
      expect(await prisma.notification.count()).toBe(0);
      const { collaborationId } = resultOf(
        await creatorLike(campaignId).expect(200),
      );

      const mine = await request(server)
        .get('/notifications')
        .set(authCreator)
        .expect(200);
      const theirs = await request(server)
        .get('/notifications')
        .set(authBrand)
        .expect(200);
      type Page = {
        items: {
          tab: string;
          text: string;
          target: { kind: string; id: string };
        }[];
      };
      expect((mine.body as Page).items).toEqual([
        expect.objectContaining({
          tab: 'MATCHING',
          text: '느린결과 서로 관심이 닿았어요.',
          target: { kind: 'MATCH', id: collaborationId },
        }),
      ]);
      expect((theirs.body as Page).items).toEqual([
        expect.objectContaining({
          tab: 'MATCHING',
          text: '하루 한 컵과 서로 관심이 닿았어요.',
          target: { kind: 'MATCH', id: collaborationId },
        }),
      ]);
      expect(push.sent.map((p) => p.userId).sort()).toEqual(
        [USER_A, OTHER].sort(),
      );
    });

    it('still succeeds when the notification cannot be saved', async () => {
      const campaignId = await bothSides();
      await brandLike().expect(200);
      push.fail = true;
      try {
        const result = resultOf(await creatorLike(campaignId).expect(200));
        expect(result.matched).toBe(true);
      } finally {
        push.fail = false;
      }
      expect(await prisma.match.count()).toBe(1);
    });

    it('keeps the match and falls back to default names when a name cannot be read', async () => {
      const campaignId = await bothSides();
      await brandLike().expect(200);
      const spy = jest
        .spyOn(app.get(BrandsService), 'getActor')
        .mockRejectedValue(new Error('read failed'));
      let conversationId: string | null;
      try {
        const result = resultOf(await creatorLike(campaignId).expect(200));
        expect(result.matched).toBe(true);
        conversationId = result.conversationId;
      } finally {
        spy.mockRestore();
      }
      expect(await prisma.match.count()).toBe(1);
      const lines = (
        await request(server)
          .get(`/conversations/${conversationId}/messages`)
          .set(authCreator)
          .expect(200)
      ).body as { text: string }[];
      expect(lines[0].text).toBe(
        '브랜드님과 서로 관심이 닿았어요. 조건 버전 1이 만들어졌어요.',
      );
    });

    it('refuses to change a decision after a match', async () => {
      const campaignId = await bothSides();
      await creatorLike(campaignId).expect(200);
      await brandLike().expect(200);
      const res = await brandLike({ decision: 'PASS' }).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      await creatorLike(campaignId, { decision: 'HOLD' }).expect(409);
      // 같은 관심을 다시 보내는 것도 바꾸는 것으로 본다.
      await brandLike().expect(409);
      const rows = await decisionRows();
      expect(rows.every((r) => r.decision === 'LIKE')).toBe(true);
    });

    it('promotes an inquiry collaboration to MATCHED instead of creating a second one', async () => {
      const campaignId = await bothSides();
      const inquiry = await prisma.collaboration.create({
        data: {
          kind: 'BRAND_CONTRACT',
          stage: 'INQUIRY',
          commissionerId: USER_A,
          creatorId: OTHER,
          campaignId,
          terms: {},
          settlementMethod: 'FIXED',
        },
      });
      await creatorLike(campaignId).expect(200);
      const result = resultOf(await brandLike().expect(200));
      expect(result).toMatchObject({
        matched: true,
        collaborationId: inquiry.id,
      });
      const rows = await prisma.collaboration.findMany();
      expect(rows).toHaveLength(1);
      expect(rows[0].stage).toBe('MATCHED');
      expect(await prisma.termsVersion.count()).toBe(1);
      // 문의로 먼저 생긴 협업도 방이 하나뿐이고 안내 줄이 남는다.
      const room = await prisma.conversation.findFirstOrThrow({
        where: { collaborationId: inquiry.id },
      });
      expect(result.conversationId).toBe(room.id);
      expect(await prisma.conversation.count()).toBe(1);
      expect(
        (
          await prisma.message.findMany({ where: { conversationId: room.id } })
        ).map((m) => m.systemCode),
      ).toEqual(['MATCHED']);
    });

    it('refuses a match when the pair already has a collaboration past the inquiry and keeps the like out', async () => {
      const campaignId = await bothSides();
      await prisma.collaboration.create({
        data: {
          kind: 'BRAND_CONTRACT',
          stage: 'DROPPED',
          commissionerId: USER_A,
          creatorId: OTHER,
          campaignId,
          terms: {},
          settlementMethod: 'FIXED',
        },
      });
      await creatorLike(campaignId).expect(200);
      const res = await brandLike().expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(await prisma.match.count()).toBe(0);
      // 브랜드의 관심은 같은 트랜잭션이라 남지 않는다.
      const rows = await decisionRows();
      expect(rows.map((r) => r.actorId)).toEqual([OTHER]);
    });

    it('shows the brand collaboration to both parties with kind and no terms copy', async () => {
      const campaignId = await bothSides();
      await creatorLike(campaignId).expect(200);
      const { collaborationId } = resultOf(await brandLike().expect(200));

      const asBrand = await request(server)
        .get('/collaborations?scope=active')
        .set(authBrand)
        .expect(200);
      const asCreator = await request(server)
        .get('/collaborations?scope=active')
        .set(authCreator)
        .expect(200);
      expect(asBrand.body as CollaborationBody[]).toEqual([
        expect.objectContaining({
          id: collaborationId,
          kind: 'BRAND_CONTRACT',
          stage: 'MATCHED',
          role: 'COMMISSIONER',
          terms: null,
          store: null,
        }),
      ]);
      expect(asCreator.body as CollaborationBody[]).toEqual([
        expect.objectContaining({
          id: collaborationId,
          kind: 'BRAND_CONTRACT',
          role: 'CREATOR',
          terms: null,
        }),
      ]);
      expect((asBrand.body as CollaborationBody[])[0].counterpart.name).toBe(
        '하루 한 컵',
      );
      expect((asCreator.body as CollaborationBody[])[0].counterpart.name).toBe(
        '느린결',
      );
      const detail = await request(server)
        .get(`/collaborations/${collaborationId}`)
        .set(authCreator)
        .expect(200);
      expect((detail.body as CollaborationBody).terms).toBeNull();
      // 지갑은 가게 오퍼의 돈만 보인다.
      await request(server).get('/wallet').set(authCreator).expect(200);
    });
  });

  describe('pass, pass reason and undo', () => {
    it('saves a pass reason for a creator pass and a campaign pass', async () => {
      const campaignId = await bothSides();
      await brandLike({ decision: 'PASS' }).expect(200);
      await creatorLike(campaignId, { decision: 'PASS' }).expect(200);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authBrand)
        .send({ targetKind: 'CREATOR', targetId: OTHER, reason: 'MOOD' })
        .expect(204);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authCreator)
        .send({ targetKind: 'CAMPAIGN', targetId: campaignId, reason: 'FEE' })
        .expect(204);
      const byActor = new Map(
        (await decisionRows()).map((r) => [r.actorId, r.passReason]),
      );
      expect(byActor.get(USER_A)).toBe('MOOD');
      expect(byActor.get(OTHER)).toBe('FEE');
    });

    it('saves a pass reason for a store pass', async () => {
      await makeCreator();
      const storeId = await seedStore();
      await request(server)
        .put(`/discovery/store-passes/${storeId}`)
        .set(authCreator)
        .expect(204);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authCreator)
        .send({ targetKind: 'STORE', targetId: storeId, reason: 'REGION' })
        .expect(204);
      const [row] = await decisionRows();
      expect(row).toMatchObject({
        actorId: OTHER,
        targetKind: 'STORE',
        targetId: storeId,
        campaignId: null,
        decision: 'PASS',
        passReason: 'REGION',
      });
    });

    it('refuses a pass reason when there is no pass', async () => {
      await bothSides();
      const target = { targetKind: 'CREATOR', targetId: OTHER, reason: 'MOOD' };
      const none = await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authBrand)
        .send(target)
        .expect(409);
      expect(codeOf(none)).toBe('CONFLICT');
      await brandLike().expect(200);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authBrand)
        .send(target)
        .expect(409);
    });

    it('refuses a pass reason for a kind that the role cannot pass', async () => {
      const campaignId = await bothSides();
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authBrand)
        .send({ targetKind: 'CAMPAIGN', targetId: campaignId, reason: 'MOOD' })
        .expect(400);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authCreator)
        .send({ targetKind: 'CREATOR', targetId: USER_A, reason: 'MOOD' })
        .expect(400);
    });

    it('returns 404 when passing a store that is not published or does not exist', async () => {
      await makeCreator();
      await request(server)
        .put(`/discovery/store-passes/${randomUUID()}`)
        .set(authCreator)
        .expect(404);
      await request(server)
        .put('/discovery/store-passes/not-a-uuid')
        .set(authCreator)
        .expect(400);
    });

    it('keeps the stored pass when the same store pass is sent twice', async () => {
      await makeCreator();
      const storeId = await seedStore();
      const send = () =>
        request(server)
          .put(`/discovery/store-passes/${storeId}`)
          .set(authCreator)
          .expect(204);
      await send();
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authCreator)
        .send({ targetKind: 'STORE', targetId: storeId, reason: 'REGION' })
        .expect(204);
      await send();
      const rows = await decisionRows();
      expect(rows).toHaveLength(1);
      expect(rows[0].passReason).toBe('REGION');
    });

    it('undoes my last decision of today', async () => {
      const campaignId = await bothSides();
      await brandLike({ decision: 'HOLD' }).expect(200);
      await creatorLike(campaignId).expect(200);
      clock.advance(60_000);
      await brandLike({ decision: 'PASS' }).expect(200);
      const res = await request(server)
        .delete('/discovery/decisions/last')
        .set(authBrand)
        .expect(200);
      expect(res.body).toEqual({ targetKind: 'CREATOR', targetId: OTHER });
      // 지운 것은 브랜드의 행 하나이고, 크리에이터의 결정은 그대로다.
      const rows = await decisionRows();
      expect(rows).toHaveLength(1);
      expect(rows[0].actorId).toBe(OTHER);
    });

    it('undoes a store pass', async () => {
      await makeCreator();
      const storeId = await seedStore();
      await request(server)
        .put(`/discovery/store-passes/${storeId}`)
        .set(authCreator)
        .expect(204);
      const res = await request(server)
        .delete('/discovery/decisions/last')
        .set(authCreator)
        .expect(200);
      expect(res.body).toEqual({ targetKind: 'STORE', targetId: storeId });
      expect(await decisionRows()).toHaveLength(0);
    });

    it('undo removes the pass together with its reason and a brand proposal', async () => {
      await bothSides();
      await brandLike({ proposal: PROPOSAL, note: '좋았어요' }).expect(200);
      await request(server)
        .delete('/discovery/decisions/last')
        .set(authBrand)
        .expect(200);
      expect(await decisionRows()).toHaveLength(0);
      await brandLike({ decision: 'PASS' }).expect(200);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authBrand)
        .send({ targetKind: 'CREATOR', targetId: OTHER, reason: 'FIELD' })
        .expect(204);
      await request(server)
        .delete('/discovery/decisions/last')
        .set(authBrand)
        .expect(200);
      expect(await decisionRows()).toHaveLength(0);
      // 지운 뒤에는 새로 결정할 수 있고 옛 이유가 남지 않는다.
      await brandLike({ decision: 'PASS' }).expect(200);
      expect((await decisionRows())[0].passReason).toBeNull();
    });

    it('undo returns an empty answer and deletes nothing when there is no decision today', async () => {
      await bothSides();
      const empty = await request(server)
        .delete('/discovery/decisions/last')
        .set(authBrand)
        .expect(200);
      expect(empty.text).toBe('');
    });

    it('undo returns an empty answer after Korean midnight and deletes nothing', async () => {
      await bothSides();
      await brandLike({ decision: 'PASS' }).expect(200);
      clock.set(NEXT_DAY);
      const res = await request(server)
        .delete('/discovery/decisions/last')
        .set(authBrand)
        .expect(200);
      expect(res.text).toBe('');
      expect(await decisionRows()).toHaveLength(1);
    });

    it('undoes my last decision but not a matched one', async () => {
      const campaignId = await bothSides();
      await creatorLike(campaignId).expect(200);
      await brandLike().expect(200);
      const res = await request(server)
        .delete('/discovery/decisions/last')
        .set(authBrand)
        .expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      await request(server)
        .delete('/discovery/decisions/last')
        .set(authCreator)
        .expect(409);
      expect(await decisionRows()).toHaveLength(2);
      expect(await prisma.match.count()).toBe(1);
    });

    it('refuses undo for a user without a role', async () => {
      await request(server)
        .delete('/discovery/decisions/last')
        .set(authBrand)
        .expect(403);
    });
  });

  describe('the hold of the day', () => {
    it('counts a hold saved again today as todays hold and hides it from the list of the day', async () => {
      await bothSides();
      await brandLike({ decision: 'HOLD' }).expect(200);
      const [first] = await decisionRows();
      expect(first.updatedAt).toEqual(NOON);

      // 다음 날 어제의 보류가 목록에 다시 나온다.
      clock.set(NEXT_DAY);
      const list = async () =>
        (
          (
            await request(server)
              .get('/recommendations/creators')
              .set(authBrand)
              .expect(200)
          ).body as { cards: { creatorId: string }[] }
        ).cards.map((c) => c.creatorId);
      expect(await list()).toEqual([OTHER]);

      // 같은 보류를 다시 저장하면 오늘의 결정이다: 시각만 Clock의 지금으로 갱신되고 다른 값은 그대로다.
      await brandLike({ decision: 'HOLD' }).expect(200);
      const rows = await decisionRows();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({ id: first.id, decision: 'HOLD' });
      expect(rows[0].updatedAt).toEqual(NEXT_DAY);
      expect(await list()).toEqual([]);
    });

    it('undoes the hold that was just saved again and not the pass made earlier today', async () => {
      await bothSides();
      const otherCreator = randomUUID();
      await prisma.user.create({ data: { id: otherCreator, role: 'CREATOR' } });
      await prisma.creatorProfile.create({
        data: {
          userId: otherCreator,
          displayName: '다른 크리에이터',
          ...REGION,
        },
      });
      await prisma.creatorPrinciples.create({
        data: {
          creatorId: otherCreator,
          fields: ['ACCESSORY'],
          blockedIndustries: [],
          faceOk: true,
          scriptOk: true,
          honestReview: true,
          feeBand: 'W300K',
          trialDays: 'ANY',
        },
      });
      // 어제 보류한 카드 Y.
      await brandLike({ decision: 'HOLD' }).expect(200);
      clock.set(NEXT_DAY);
      // 오늘 다른 카드 X를 이유와 함께 넘긴다.
      clock.advance(60_000);
      await put(authBrand, {
        targetKind: 'CREATOR',
        targetId: otherCreator,
        decision: 'PASS',
      }).expect(200);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authBrand)
        .send({ targetKind: 'CREATOR', targetId: otherCreator, reason: 'MOOD' })
        .expect(204);
      // Y를 다시 보류하고 바로 되돌린다.
      clock.advance(60_000);
      await brandLike({ decision: 'HOLD' }).expect(200);
      const res = await request(server)
        .delete('/discovery/decisions/last')
        .set(authBrand)
        .expect(200);
      expect(res.body).toEqual({ targetKind: 'CREATOR', targetId: OTHER });
      const rows = await decisionRows();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        targetId: otherCreator,
        decision: 'PASS',
        passReason: 'MOOD',
      });
    });

    it('stamps every decision write with the injected clock', async () => {
      await bothSides();
      await brandLike({ decision: 'HOLD' }).expect(200);
      clock.advance(60_000);
      await brandLike().expect(200);
      const [row] = await decisionRows();
      expect(row.decision).toBe('LIKE');
      expect(row.updatedAt).toEqual(new Date(NOON.getTime() + 60_000));
    });

    it('hides a hold made today from the list of the day', async () => {
      await bothSides();
      await brandLike({ decision: 'HOLD' }).expect(200);
      const list = await request(server)
        .get('/recommendations/creators')
        .set(authBrand)
        .expect(200);
      expect((list.body as { cards: unknown[] }).cards).toHaveLength(0);
    });
  });

  describe('what the other side can see', () => {
    it('never returns a pass or its reason to the other side', async () => {
      const campaignId = await bothSides();
      await brandLike({ decision: 'PASS' }).expect(200);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authBrand)
        .send({ targetKind: 'CREATOR', targetId: OTHER, reason: 'MOOD' })
        .expect(204);
      await creatorLike(campaignId, { decision: 'PASS' }).expect(200);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authCreator)
        .send({ targetKind: 'CAMPAIGN', targetId: campaignId, reason: 'FEE' })
        .expect(204);

      // 상대가 읽을 수 있는 응답 전체에 넘김과 이유가 없다.
      const paths: [string, Record<string, string>][] = [
        ['/recommendations/campaigns', authCreator],
        ['/recommendations/creators', authBrand],
        ['/collaborations?scope=active', authCreator],
        ['/collaborations?scope=active', authBrand],
        ['/notifications', authCreator],
        ['/notifications', authBrand],
        ['/campaigns/mine/active', authBrand],
        ['/creators/me', authCreator],
        ['/brands/me', authBrand],
      ];
      for (const [path, auth] of paths) {
        const res = await request(server).get(path).set(auth).expect(200);
        const text = JSON.stringify(res.body);
        expect(text).not.toMatch(/PASS|passReason|pass_reason/);
      }
      // 결정 응답 자체도 상대의 결정을 알리지 않는다.
      const brandRes = await brandLike({ decision: 'HOLD' }).expect(200);
      expect(JSON.stringify(brandRes.body)).not.toMatch(/PASS|passReason/);
    });

    it('does not tell the other side that I liked before the match', async () => {
      const campaignId = await bothSides();
      await brandLike({ proposal: PROPOSAL, note: '좋았어요' }).expect(200);
      const list = await request(server)
        .get('/recommendations/campaigns')
        .set(authCreator)
        .expect(200);
      expect(JSON.stringify(list.body)).not.toMatch(/proposal|좋았어요/);
      const own = await creatorLike(campaignId).expect(200);
      expect(resultOf(own).matched).toBe(true);
    });
  });
});
