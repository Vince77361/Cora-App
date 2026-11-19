import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { IndustryCategory, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { setCardPost } from './helpers/featured-posts';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { OTHER, USER_A } from './support/fake-token-verifier';

// user-a는 사장님이다. 크리에이터와 다른 가게는 DB에 바로 만든다.
const authA = { Authorization: 'Bearer user-a' };
const authB = { Authorization: 'Bearer user-b' };
const SEOUL = '서울특별시';

interface StoreCreatorCard {
  creatorId: string;
  displayName: string;
  contentFocus: string | null;
  followers: number | null;
  headline: string | null;
  photoUrl: string | null;
  posts: { id: string; position: number; caption: string | null }[];
  tags: string[];
}
interface StoreCreatorList {
  day: string;
  total: number;
  cards: StoreCreatorCard[];
}

describe('store discovery (전체 둘러보기)', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let joined = 0;
  let storeId: string;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const deck = async () =>
    (
      await request(server)
        .get('/recommendations/store-creators')
        .set(authA)
        .expect(200)
    ).body as StoreCreatorList;
  const idsOf = (list: StoreCreatorList) => list.cards.map((c) => c.creatorId);
  const decide = (
    targetId: string,
    decision: 'LIKE' | 'PASS' | 'HOLD',
    extra: Record<string, unknown> = {},
  ) =>
    request(server)
      .put('/discovery/decisions')
      .set(authA)
      .send({ targetKind: 'CREATOR', targetId, decision, ...extra });

  // user-a를 사장님으로 만들고 공개된 가게를 DB에 만든다(마포구).
  async function makeStore(
    industry: IndustryCategory = 'FOOD_CAFE',
  ): Promise<void> {
    await request(server)
      .patch('/me/role')
      .set(authA)
      .send({ role: 'STORE' })
      .expect(200);
    const store = await prisma.store.create({
      data: {
        ownerId: USER_A,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name: '한그릇 라멘',
        industry,
        regionSido: SEOUL,
        regionSigungu: '마포구',
        defaultFormat: 'REELS',
        publishedAt: new Date('2026-11-01T00:00:00Z'),
      },
    });
    storeId = store.id;
  }

  async function seedCreator(
    name: string,
    o: {
      sigungu?: string;
      sido?: string;
      blocked?: IndustryCategory[];
      principles?: boolean;
      post?: boolean;
    } = {},
  ): Promise<string> {
    const userId = randomUUID();
    joined += 1;
    await prisma.user.create({
      data: {
        id: userId,
        role: 'CREATOR',
        createdAt: new Date(Date.UTC(2026, 9, 1, 0, joined)),
      },
    });
    await prisma.creatorProfile.create({
      data: {
        userId,
        displayName: name,
        contentFocus: '맛집 릴스',
        regionSido: o.sido ?? SEOUL,
        regionSigungu: o.sigungu ?? '성동구',
      },
    });
    if (o.post !== false) {
      await setCardPost(prisma, userId, {
        caption: `${name}의 한 줄`,
        mediaPath: `featured-posts/${userId}/a.jpg`,
      });
    }
    if (o.principles !== false) {
      await prisma.creatorPrinciples.create({
        data: {
          creatorId: userId,
          fields: [],
          blockedIndustries: o.blocked ?? [],
          faceOk: false,
          scriptOk: true,
          honestReview: true,
          feeBand: 'W300K',
          trialDays: 'D7',
        },
      });
    }
    return userId;
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(new Date('2026-11-19T03:00:00.000Z'));
    joined = 0;
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).get('/recommendations/store-creators').expect(401);
  });

  it('serves the deck to store owners only', async () => {
    await request(server)
      .patch('/me/role')
      .set(authA)
      .send({ role: 'BRAND' })
      .expect(200);
    await request(server)
      .patch('/me/role')
      .set(authB)
      .send({ role: 'CREATOR' })
      .expect(200);

    const brand = await request(server)
      .get('/recommendations/store-creators')
      .set(authA)
      .expect(403);
    expect(codeOf(brand)).toBe('FORBIDDEN');
    await request(server)
      .get('/recommendations/store-creators')
      .set(authB)
      .expect(403);
  });

  it('lists applicants first, then the same district, then the same province, with the card fields', async () => {
    await makeStore();
    const far = await seedCreator('먼 사람', { sido: '부산광역시' });
    const province = await seedCreator('같은 시도', { sigungu: '강남구' });
    const district = await seedCreator('같은 구', { sigungu: '마포구' });
    const applicant = await seedCreator('지원한 사람', {
      sido: '제주특별자치도',
    });
    await prisma.application.create({
      data: { storeId, creatorId: applicant, status: 'APPLIED' },
    });

    const list = await deck();

    expect(list.day).toBe('2026-11-19');
    expect(idsOf(list)).toEqual([applicant, district, province, far]);
    expect(list.total).toBe(4);
    expect(list.cards[0]).toMatchObject({
      displayName: '지원한 사람',
      contentFocus: '맛집 릴스',
      followers: null,
      headline: '지원한 사람의 한 줄',
      tags: ['얼굴출연없음', '솔직후기'],
    });
    expect(list.cards[0].posts).toHaveLength(1);
    expect(list.cards[0].posts[0]).toMatchObject({
      position: 1,
      caption: '지원한 사람의 한 줄',
    });
    expect(list.cards[0].photoUrl).toEqual(expect.any(String));
  });

  it('skips creators who avoid the store industry, or have no featured post', async () => {
    await makeStore('ALCOHOL');
    await seedCreator('피하는 사람', { blocked: ['ALCOHOL'] });
    await seedCreator('게시물 없는 사람', { post: false });
    const shown = await seedCreator('원칙 없는 사람', { principles: false });

    const list = await deck();

    expect(idsOf(list)).toEqual([shown]);
    expect(list.cards[0].tags).toEqual([]);
  });

  it('keeps one list for the day and refills at midnight KST', async () => {
    await makeStore();
    const first = await seedCreator('첫째');
    expect(idsOf(await deck())).toEqual([first]);

    const late = await seedCreator('늦게 온 사람');
    expect(idsOf(await deck())).toEqual([first]);

    clock.set(new Date('2026-11-19T15:00:00.000Z'));
    const next = await deck();
    expect(next.day).toBe('2026-11-20');
    expect(idsOf(next)).toEqual([late, first]);
  });

  describe('decisions', () => {
    it('records a heart with campaign null and the first post copy and creates no match or collaboration', async () => {
      await makeStore();
      const creator = await seedCreator('하트 받는 사람');
      await prisma.application.create({
        data: { storeId, creatorId: creator, status: 'APPLIED' },
      });

      const res = await decide(creator, 'LIKE').expect(200);

      expect(res.body).toEqual({
        decision: 'LIKE',
        matched: false,
        collaborationId: null,
        conversationId: null,
      });
      const rows = await prisma.swipeDecision.findMany();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        actorId: USER_A,
        targetKind: 'CREATOR',
        targetId: creator,
        campaignId: null,
        decision: 'LIKE',
        note: null,
        contentTitle: '하트 받는 사람의 한 줄',
        contentPhotoPath: `featured-posts/${creator}/a.jpg`,
      });
      expect(await prisma.match.count()).toBe(0);
      expect(await prisma.collaboration.count()).toBe(0);
      expect(await prisma.conversation.count()).toBe(0);
      // 하트를 보낸 사람은 오늘 덱에서 빠진다.
      expect(idsOf(await deck())).toEqual([]);
    });

    it('replaces a saved decision with a heart and leaves one row', async () => {
      await makeStore();
      const creator = await seedCreator('저장했다가 하트');
      await decide(creator, 'HOLD').expect(200);

      await decide(creator, 'LIKE').expect(200);

      const rows = await prisma.swipeDecision.findMany();
      expect(rows).toHaveLength(1);
      expect(rows[0].decision).toBe('LIKE');
    });

    it('saves and passes without a copy and removes the creator from the deck', async () => {
      await makeStore();
      const saved = await seedCreator('저장');
      const passed = await seedCreator('넘김');
      const fresh = await seedCreator('새 사람');

      await decide(saved, 'HOLD').expect(200);
      await decide(passed, 'PASS').expect(200);

      const rows = await prisma.swipeDecision.findMany({
        orderBy: { createdAt: 'asc' },
      });
      expect(rows.map((r) => [r.decision, r.contentTitle])).toEqual([
        ['HOLD', null],
        ['PASS', null],
      ]);
      expect(idsOf(await deck())).toEqual([fresh]);
    });

    it("never reads another store's decisions", async () => {
      await makeStore();
      const creator = await seedCreator('다른 가게도 본 사람');
      const otherOwner = randomUUID();
      await prisma.user.create({ data: { id: otherOwner, role: 'STORE' } });
      await prisma.swipeDecision.create({
        data: {
          actorId: otherOwner,
          targetKind: 'CREATOR',
          targetId: creator,
          campaignId: null,
          decision: 'PASS',
        },
      });

      expect(idsOf(await deck())).toEqual([creator]);
      await decide(creator, 'LIKE').expect(200);
      expect(await prisma.swipeDecision.count()).toBe(2);
      // 되돌려도 내 결정만 지워진다.
      await request(server)
        .delete('/discovery/decisions/last')
        .set(authA)
        .expect(200);
      const rest = await prisma.swipeDecision.findMany();
      expect(rest).toHaveLength(1);
      expect(rest[0].actorId).toBe(otherOwner);
    });

    it('answers 404 for a creator the store may not see and 400 for anything but a creator', async () => {
      await makeStore('ALCOHOL');
      const hidden = await seedCreator('피하는 사람', { blocked: ['ALCOHOL'] });

      const res = await decide(hidden, 'LIKE').expect(404);
      expect(codeOf(res)).toBe('NOT_FOUND');
      expect(await prisma.swipeDecision.count()).toBe(0);

      await request(server)
        .put('/discovery/decisions')
        .set(authA)
        .send({
          targetKind: 'CAMPAIGN',
          targetId: randomUUID(),
          decision: 'LIKE',
        })
        .expect(400);
      const visible = await seedCreator('보이는 사람');
      await decide(visible, 'LIKE', { note: '같이 해요' }).expect(400);
    });

    it('lets the store pick a pass reason only on a passed creator', async () => {
      await makeStore();
      const creator = await seedCreator('넘김 이유');
      const reason = {
        targetKind: 'CREATOR',
        targetId: creator,
        reason: 'FEE',
      };
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authA)
        .send(reason)
        .expect(409);

      await decide(creator, 'PASS').expect(200);
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authA)
        .send(reason)
        .expect(204);

      expect((await prisma.swipeDecision.findFirstOrThrow()).passReason).toBe(
        'FEE',
      );
    });

    it('undoes the last decision and brings the card back', async () => {
      await makeStore();
      const creator = await seedCreator('되돌리기');
      await decide(creator, 'PASS').expect(200);
      expect(idsOf(await deck())).toEqual([]);

      const res = await request(server)
        .delete('/discovery/decisions/last')
        .set(authA)
        .expect(200);

      expect(res.body).toEqual({ targetKind: 'CREATOR', targetId: creator });
      expect(await prisma.swipeDecision.count()).toBe(0);
      expect(idsOf(await deck())).toEqual([creator]);
    });

    it('refuses to undo a heart on a creator who applied with 409', async () => {
      await makeStore();
      const creator = await seedCreator('서로 관심');
      await decide(creator, 'LIKE').expect(200);
      await prisma.application.create({
        data: { storeId, creatorId: creator, status: 'APPLIED' },
      });

      const res = await request(server)
        .delete('/discovery/decisions/last')
        .set(authA)
        .expect(409);

      expect(codeOf(res)).toBe('CONFLICT');
      expect(await prisma.swipeDecision.count()).toBe(1);
    });
  });

  describe('store interests (저장함)', () => {
    interface InterestCard {
      creatorId: string;
      name: string;
      shortName: string;
      contentFocus: string | null;
      followers: number | null;
      photoUrl: string | null;
      headline: string | null;
      representativePhotoUrl: string | null;
      mutual: boolean;
    }
    interface NotificationPage {
      items: {
        tab: string;
        text: string;
        target: { kind: string; id: string | null };
      }[];
    }
    const list = (tab: string, auth = authA) =>
      request(server).get(`/discovery/store-interests?tab=${tab}`).set(auth);
    const interestsOf = async (tab: string) =>
      (await list(tab).expect(200)).body as InterestCard[];
    const inbox = async (auth: { Authorization: string }) =>
      (
        (await request(server).get('/notifications').set(auth).expect(200))
          .body as NotificationPage
      ).items;
    const mutualCount = () =>
      prisma.notification.count({ where: { kind: 'MUTUAL_INTEREST' } });

    // user-b를 지원할 수 있는 크리에이터로 만든다.
    async function makeCreatorB(): Promise<string> {
      await request(server)
        .patch('/me/role')
        .set(authB)
        .send({ role: 'CREATOR' })
        .expect(200);
      await request(server)
        .put('/creators/me')
        .set(authB)
        .send({
          displayName: '하루 한 컵',
          contentFocus: '카페 릴스',
          regionSido: SEOUL,
          regionSigungu: '마포구',
        })
        .expect(200);
      return OTHER;
    }
    const applyB = () =>
      request(server).post(`/stores/${storeId}/applications`).set(authB).send();

    it('lists saved and sent creators for the store only', async () => {
      await makeStore();
      const saved = await seedCreator('저장한 사람');
      const sent = await seedCreator('하트 보낸 사람');
      const passed = await seedCreator('넘긴 사람');
      await decide(saved, 'HOLD').expect(200);
      await decide(sent, 'LIKE').expect(200);
      await decide(passed, 'PASS').expect(200);
      // 다른 가게의 결정은 읽히지 않는다.
      const other = randomUUID();
      await prisma.user.create({ data: { id: other, role: 'STORE' } });
      await prisma.swipeDecision.create({
        data: {
          actorId: other,
          targetKind: 'CREATOR',
          targetId: passed,
          decision: 'HOLD',
        },
      });

      expect((await interestsOf('saved')).map((c) => c.creatorId)).toEqual([
        saved,
      ]);
      expect(await interestsOf('sent')).toEqual([
        {
          creatorId: sent,
          name: '하트 보낸 사람',
          shortName: '하트 보낸 사람',
          contentFocus: '맛집 릴스',
          followers: null,
          photoUrl: null,
          headline: '하트 보낸 사람의 한 줄',
          representativePhotoUrl: expect.stringContaining(
            `featured-posts/${sent}/a.jpg`,
          ) as string,
          mutual: false,
        },
      ]);
      // 탭을 주지 않으면 저장 탭이다.
      const fallback = await request(server)
        .get('/discovery/store-interests')
        .set(authA)
        .expect(200);
      expect((fallback.body as InterestCard[]).map((c) => c.creatorId)).toEqual(
        [saved],
      );
    });

    it('moves a creator between the tabs when the decision changes', async () => {
      await makeStore();
      const creator = await seedCreator('마음 바꾼 사람');
      await decide(creator, 'HOLD').expect(200);
      await decide(creator, 'LIKE').expect(200);

      expect(await interestsOf('saved')).toEqual([]);
      expect((await interestsOf('sent')).map((c) => c.creatorId)).toEqual([
        creator,
      ]);
    });

    it('serves store owners only and rejects a bad tab', async () => {
      await request(server).get('/discovery/store-interests').expect(401);
      await request(server)
        .patch('/me/role')
        .set(authA)
        .send({ role: 'BRAND' })
        .expect(200);
      const res = await list('saved').expect(403);
      expect(codeOf(res)).toBe('FORBIDDEN');
      await request(server)
        .patch('/me/role')
        .set(authB)
        .send({ role: 'CREATOR' })
        .expect(200);
      await list('saved', authB).expect(403);
    });

    it('rejects an unknown tab with 400', async () => {
      await makeStore();
      await list('held').expect(400);
    });

    it('hides creators who avoid the store industry', async () => {
      await makeStore('ALCOHOL');
      const creator = await seedCreator('피하는 사람');
      await decide(creator, 'HOLD').expect(200);
      await prisma.creatorPrinciples.update({
        where: { creatorId: creator },
        data: { blockedIndustries: ['ALCOHOL'] },
      });

      expect(await interestsOf('saved')).toEqual([]);
    });

    it('notifies both sides once when a heart meets an existing application', async () => {
      await makeStore();
      const creator = await makeCreatorB();
      await applyB().expect(201);
      expect(await mutualCount()).toBe(0);

      // 고정 시계라 두 알림의 시각이 같으면 받은함 순서가 id 무작위로 갈린다. 하트를 지원보다 나중으로 둔다.
      clock.set(new Date('2026-11-19T03:05:00.000Z'));
      await decide(creator, 'LIKE').expect(200);
      // 하트를 다시 보내도 알림은 늘지 않는다.
      await decide(creator, 'LIKE').expect(200);

      expect(await mutualCount()).toBe(2);
      expect(await inbox(authA)).toEqual([
        expect.objectContaining({
          tab: 'MATCHING',
          text: '하루 한 컵과 서로 관심이 닿았어요.',
          target: { kind: 'STORE_INTERESTS', id: null },
        }),
        expect.anything(),
      ]);
      expect((await inbox(authB)).filter((n) => n.tab === 'MATCHING')).toEqual([
        expect.objectContaining({
          text: '한그릇 라멘과 서로 관심이 닿았어요.',
          target: { kind: 'STORE_DETAIL', id: storeId },
        }),
      ]);
      const sent = await interestsOf('sent');
      expect(sent.map((c) => [c.creatorId, c.mutual])).toEqual([
        [creator, true],
      ]);
    });

    it('notifies both sides once when an application meets an existing heart', async () => {
      await makeStore();
      const creator = await makeCreatorB();
      await decide(creator, 'LIKE').expect(200);
      expect(await mutualCount()).toBe(0);
      expect((await interestsOf('sent'))[0].mutual).toBe(false);

      await applyB().expect(201);
      // 지원을 취소했다가 다시 해도 알림은 늘지 않는다.
      await request(server)
        .delete(`/stores/${storeId}/applications/mine`)
        .set(authB)
        .expect(204);
      await applyB().expect(201);

      expect(await mutualCount()).toBe(2);
      expect((await interestsOf('sent'))[0].mutual).toBe(true);
    });

    it('never creates a match, collaboration or conversation', async () => {
      await makeStore();
      const creator = await makeCreatorB();
      await applyB().expect(201);
      await decide(creator, 'LIKE').expect(200);

      expect(await prisma.match.count()).toBe(0);
      expect(await prisma.collaboration.count()).toBe(0);
      expect(await prisma.conversation.count()).toBe(0);
    });

    it('does not notify for a save or when the creator has not applied', async () => {
      await makeStore();
      const creator = await makeCreatorB();
      await decide(creator, 'HOLD').expect(200);
      await applyB().expect(201);
      expect(await mutualCount()).toBe(0);
    });
  });
});
