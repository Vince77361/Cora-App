import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import {
  CollaborationStage,
  FeeBand,
  IndustryCategory,
  NotRequired,
  PrismaClient,
  ProductTrialDays,
} from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { RecommendationsRepository } from '../src/recommendations/recommendations.repository';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { createOffer } from './helpers/create-offer';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { OTHER, USER_A } from './support/fake-token-verifier';

// user-a는 브랜드(또는 크리에이터), user-b는 크리에이터로 로그인한다. 나머지 사람은 DB에 바로 만든다.
const authA = { Authorization: 'Bearer user-a' };
const authB = { Authorization: 'Bearer user-b' };
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

interface CreatorCard {
  creatorId: string;
  displayName: string;
  instagramHandle: string | null;
  headline: string | null;
  photoUrl: string | null;
  feeBand: string;
  tags: string[];
  reasons: string[];
  theyLikedMe: boolean;
}
interface CreatorList {
  day: string;
  total: number;
  cards: CreatorCard[];
}
interface MixedCard {
  kind: 'CAMPAIGN' | 'STORE';
  campaignId?: string;
  brandName?: string;
  brandTagline?: string | null;
  photoUrl?: string | null;
  headline: string;
  fee?: number;
  productProvided?: boolean;
  tags: string[];
  reasons?: string[];
  store?: { id: string; name: string; regionSido: string | null };
  otherSido?: string | null;
  rewardLine?: string;
}
interface MixedList {
  day: string;
  total: number;
  cards: MixedCard[];
}

describe('recommendations', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  // 만든 순서대로 가입 시각이 늦어지게 해서 "최근 가입 순"이 만든 순서의 거꾸로가 되게 한다.
  let joined = 0;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const setRole = (auth: Record<string, string>, role: string) =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const creatorList = async (auth = authA) =>
    (
      await request(server)
        .get('/recommendations/creators')
        .set(auth)
        .expect(200)
    ).body as CreatorList;
  const campaignList = async (auth = authB) =>
    (
      await request(server)
        .get('/recommendations/campaigns')
        .set(auth)
        .expect(200)
    ).body as MixedList;
  const idsOf = (list: CreatorList) => list.cards.map((c) => c.creatorId);

  // user-a를 브랜드로 만들고 진행 중인 캠페인을 낸다.
  async function makeBrand(
    industry: IndustryCategory = 'ACCESSORY',
    campaign: Record<string, unknown> = {},
  ): Promise<string> {
    await setRole(authA, 'BRAND');
    await request(server)
      .put('/brands/me')
      .set(authA)
      .send({ name: '느린결', tagline: '천천히 쓰는 물건', industry })
      .expect(200);
    const res = await request(server)
      .post('/campaigns')
      .set(authA)
      .send({ ...CAMPAIGN, ...campaign })
      .expect(201);
    return (res.body as { id: string }).id;
  }

  // user-b를 크리에이터로 만든다.
  async function makeCreatorB(
    principles: Record<string, unknown> | null = {},
  ): Promise<void> {
    await setRole(authB, 'CREATOR');
    await request(server)
      .put('/creators/me')
      .set(authB)
      .send({ displayName: '하루 한 컵', ...REGION })
      .expect(200);
    if (principles) {
      await request(server)
        .put('/creators/me/principles')
        .set(authB)
        .send({ ...PRINCIPLES, ...principles })
        .expect(200);
    }
  }

  async function seedCreator(
    name: string,
    o: {
      principles?: Partial<typeof PRINCIPLES> | null;
      deleted?: boolean;
      handle?: string;
    } = {},
  ): Promise<string> {
    const userId = randomUUID();
    joined += 1;
    await prisma.user.create({
      data: {
        id: userId,
        role: 'CREATOR',
        createdAt: new Date(Date.UTC(2026, 9, 1, 0, joined)),
        deletedAt: o.deleted ? new Date('2026-11-01T00:00:00Z') : null,
      },
    });
    await prisma.creatorProfile.create({
      data: {
        userId,
        displayName: name,
        instagramHandle: o.handle ?? `${name}_ig`,
        cardHeadline: `${name}의 한 줄`,
        ...REGION,
      },
    });
    if (o.principles !== null) {
      const p = { ...PRINCIPLES, ...o.principles };
      await prisma.creatorPrinciples.create({
        data: {
          creatorId: userId,
          fields: p.fields as IndustryCategory[],
          blockedIndustries: p.blockedIndustries as IndustryCategory[],
          faceOk: p.faceOk,
          scriptOk: p.scriptOk,
          honestReview: p.honestReview,
          feeBand: p.feeBand as FeeBand,
          trialDays: p.trialDays as ProductTrialDays,
        },
      });
    }
    return userId;
  }

  async function seedBrandCampaign(
    name: string,
    industry: IndustryCategory,
    o: {
      fee?: number;
      notRequired?: NotRequired[];
      status?: 'ACTIVE' | 'CLOSED';
      createdAt?: Date;
    } = {},
  ): Promise<{ brandId: string; campaignId: string }> {
    const brandId = randomUUID();
    await prisma.user.create({ data: { id: brandId, role: 'BRAND' } });
    await prisma.brandProfile.create({
      data: { userId: brandId, name, tagline: `${name}의 소개`, industry },
    });
    const campaign = await prisma.campaign.create({
      data: {
        brandId,
        status: o.status ?? 'ACTIVE',
        headline: `${name} 캠페인`,
        fee: o.fee ?? 300000,
        budget: 5000000,
        productProvided: true,
        format: 'REELS',
        startFrom: new Date('2026-11-20T00:00:00Z'),
        trialDays: 'D7',
        mustInclude: [],
        notRequired: o.notRequired ?? [],
        ...(o.createdAt ? { createdAt: o.createdAt } : {}),
      },
    });
    return { brandId, campaignId: campaign.id };
  }

  async function seedStore(
    name: string,
    o: {
      industry?: IndustryCategory;
      sido?: string;
      sigungu?: string;
      intro?: string | null;
      voucher?: boolean;
      perView?: boolean;
      fixedCash?: number;
      publishedAt?: Date;
    } = {},
  ): Promise<{ id: string; ownerId: string }> {
    const ownerId = randomUUID();
    await prisma.user.create({ data: { id: ownerId, role: 'STORE' } });
    const store = await prisma.store.create({
      data: {
        ownerId,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name,
        industry: o.industry ?? 'FOOD_CAFE',
        regionSido: o.sido ?? REGION.regionSido,
        regionSigungu: o.sigungu ?? REGION.regionSigungu,
        intro:
          o.intro === undefined
            ? `${name}은 작은 가게예요. 두 번째 문장.`
            : o.intro,
        defaultFormat: 'REELS',
        defaultVoucherName: o.voucher === false ? null : '식사권',
        defaultVoucherValue: o.voucher === false ? null : 40000,
        defaultVoucherPeople: o.voucher === false ? null : 2,
        defaultFixedCash: o.fixedCash ?? 0,
        defaultViewRatePerThousand: o.perView === false ? null : 2000,
        defaultPerViewCap: o.perView === false ? null : 100000,
        publishedAt: o.publishedAt ?? new Date('2026-11-01T00:00:00Z'),
      },
    });
    return { id: store.id, ownerId };
  }

  // 브랜드(user-a)가 캠페인에서 크리에이터에게 내린 결정을 DB에 바로 넣는다(결정 API는 5번 작업에서 생긴다).
  const brandDecision = (
    campaignId: string,
    creatorId: string,
    decision: 'LIKE' | 'PASS' | 'HOLD',
    updatedAt?: Date,
  ) =>
    prisma.swipeDecision.create({
      data: {
        actorId: USER_A,
        targetKind: 'CREATOR',
        targetId: creatorId,
        campaignId,
        decision,
        ...(decision === 'PASS' ? { passReason: 'MOOD' as const } : {}),
        ...(updatedAt ? { updatedAt } : {}),
      },
    });

  const seedCollaboration = (
    commissionerId: string,
    creatorId: string,
    stage: CollaborationStage,
    campaignId: string | null,
  ) =>
    prisma.collaboration.create({
      data: {
        kind: 'BRAND_CONTRACT',
        stage,
        commissionerId,
        creatorId,
        campaignId,
        terms: {},
        settlementMethod: 'FIXED',
      },
    });

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    // 한국 시간 2026-11-11 12:00. 그날의 시작은 2026-11-10T15:00Z다.
    clock.set(new Date('2026-11-11T03:00:00.000Z'));
    joined = 0;
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).get('/recommendations/creators').expect(401);
    await request(server).get('/recommendations/campaigns').expect(401);
    await request(server).get('/recommendations/preview').expect(401);
  });

  describe('saving the list of the day', () => {
    it('keeps the list that was saved first and hands it to the late writer', async () => {
      const repository = app.get(RecommendationsRepository);
      const first = [{ kind: 'CREATOR' as const, id: randomUUID() }];
      const second = [{ kind: 'CREATOR' as const, id: randomUUID() }];
      await prisma.user.create({ data: { id: USER_A, role: 'BRAND' } });
      const [a, b] = await Promise.all([
        repository.saveList(USER_A, 'BRAND', null, '2026-11-11', first),
        repository.saveList(USER_A, 'BRAND', null, '2026-11-11', second),
      ]);
      expect(a).toEqual(b);
      expect(await prisma.dailyRecommendation.count()).toBe(1);
      expect(
        await repository.findList(USER_A, 'BRAND', null, '2026-11-11'),
      ).toEqual(a);
    });
  });

  describe('creators for a brand', () => {
    it('refuses creator recommendations to a creator and to a user without a role', async () => {
      await makeCreatorB();
      expect(
        codeOf(
          await request(server)
            .get('/recommendations/creators')
            .set(authB)
            .expect(403),
        ),
      ).toBe('FORBIDDEN');
      expect(
        codeOf(
          await request(server)
            .get('/recommendations/creators')
            .set(authA)
            .expect(403),
        ),
      ).toBe('FORBIDDEN');
    });

    it('refuses creator recommendations without an active campaign', async () => {
      await setRole(authA, 'BRAND');
      await request(server)
        .put('/brands/me')
        .set(authA)
        .send({ name: '느린결', industry: 'ACCESSORY' })
        .expect(200);
      expect(
        codeOf(
          await request(server)
            .get('/recommendations/creators')
            .set(authA)
            .expect(409),
        ),
      ).toBe('CONFLICT');
    });

    it('returns an empty list with total 0 when nobody qualifies, and does not freeze it for the day', async () => {
      await makeBrand();
      expect(await creatorList()).toEqual({
        day: '2026-11-11',
        total: 0,
        cards: [],
      });
      expect(await prisma.dailyRecommendation.count()).toBe(0);
      // 나중에 가입한 크리에이터가 같은 날에도 바로 나온다.
      const late = await seedCreator('늦게 온 사람');
      expect(idsOf(await creatorList())).toEqual([late]);
    });

    it('builds at most 10 cards and keeps the list for the day', async () => {
      const campaignId = await makeBrand();
      for (let i = 1; i <= 12; i += 1) await seedCreator(`c${i}`);
      const first = await creatorList();
      expect(first.total).toBe(10);
      expect(first.cards).toHaveLength(10);
      expect(first.day).toBe('2026-11-11');
      // 점수가 같으면 최근 가입 순이다(c12가 가장 늦게 가입).
      expect(first.cards[0].displayName).toBe('c12');

      await seedCreator('after');
      const second = await creatorList();
      expect(idsOf(second)).toEqual(idsOf(first));
      const rows = await prisma.dailyRecommendation.findMany();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        userId: USER_A,
        scope: 'BRAND',
        campaignId,
      });
    });

    it('orders by overlap score and shows why each card fits', async () => {
      await makeBrand('ACCESSORY', { notRequired: ['FACE'] });
      const best = await seedCreator('best', {
        principles: { faceOk: false, scriptOk: true, trialDays: 'ANY' },
      });
      const weak = await seedCreator('weak', {
        principles: {
          fields: ['BEAUTY'],
          faceOk: false,
          scriptOk: false,
          feeBand: 'W500K_PLUS',
          trialDays: 'D14',
        },
      });
      const list = await creatorList();
      expect(idsOf(list)).toEqual([best, weak]);
      expect(list.cards[0].reasons).toEqual([
        'FIELD',
        'FACE',
        'SCRIPT',
        'FEE',
        'TRIAL',
      ]);
      expect(list.cards[1].reasons).toEqual(['FACE']);
    });

    it('builds creator cards from principles and the profile', async () => {
      await makeBrand();
      await seedCreator('card', {
        handle: 'card_ig',
        principles: { faceOk: false, honestReview: true, feeBand: 'W400K' },
      });
      const [{ creatorId, reasons, ...card }] = (await creatorList()).cards;
      expect(creatorId).toEqual(expect.any(String));
      expect(reasons).toEqual(expect.any(Array));
      expect(card).toEqual({
        displayName: 'card',
        instagramHandle: 'card_ig',
        headline: 'card의 한 줄',
        photoUrl: null,
        feeBand: 'W400K',
        tags: ['얼굴출연없음', '솔직후기', '액세서리·주얼리'],
        theyLikedMe: false,
      });
    });

    it('puts creators who already liked this campaign first without revealing it', async () => {
      const campaignId = await makeBrand();
      const strong = await seedCreator('strong');
      const liker = await seedCreator('liker', {
        principles: {
          fields: ['BEAUTY'],
          faceOk: false,
          scriptOk: false,
          feeBand: 'W500K_PLUS',
          trialDays: 'D14',
        },
      });
      await prisma.swipeDecision.create({
        data: {
          actorId: liker,
          targetKind: 'CAMPAIGN',
          targetId: campaignId,
          campaignId,
          decision: 'LIKE',
        },
      });
      const res = await request(server)
        .get('/recommendations/creators')
        .set(authA)
        .expect(200);
      const list = res.body as CreatorList;
      expect(idsOf(list)).toEqual([liker, strong]);
      expect(list.cards.every((c) => c.theyLikedMe === false)).toBe(true);
      expect(res.text).not.toContain('"theyLikedMe":true');
    });

    it('omits cards I already decided on but keeps them in the total', async () => {
      const campaignId = await makeBrand();
      const liked = await seedCreator('liked');
      const passed = await seedCreator('passed');
      const heldToday = await seedCreator('held-today');
      const heldBefore = await seedCreator('held-before');
      const open = await seedCreator('open');
      const first = await creatorList();
      expect(first.total).toBe(5);

      await brandDecision(campaignId, liked, 'LIKE');
      await brandDecision(campaignId, passed, 'PASS');
      // 결정 시각은 DB가 정하는 실제 시각이라, 테스트의 가짜 시계에 맞춰 직접 적는다.
      await brandDecision(
        campaignId,
        heldToday,
        'HOLD',
        new Date('2026-11-11T02:00:00Z'),
      );
      // 어제 보류한 카드는 오늘 목록에 다시 나온 것이므로 오늘은 아직 결정하지 않은 카드다.
      await brandDecision(
        campaignId,
        heldBefore,
        'HOLD',
        new Date('2026-11-10T14:00:00Z'),
      );
      const res = await request(server)
        .get('/recommendations/creators')
        .set(authA)
        .expect(200);
      const list = res.body as CreatorList;
      expect(idsOf(list).sort()).toEqual([heldBefore, open].sort());
      expect(list.total).toBe(5);
      expect(res.text).not.toContain('passReason');
      expect(res.text).not.toContain('MOOD');
    });

    it('does not list a liked or passed creator again and lets a hold come back the next day', async () => {
      const campaignId = await makeBrand();
      const liked = await seedCreator('liked');
      const passed = await seedCreator('passed');
      const held = await seedCreator('held');
      const fresh = await seedCreator('fresh');
      await creatorList();
      await brandDecision(campaignId, liked, 'LIKE');
      await brandDecision(campaignId, passed, 'PASS');
      await brandDecision(
        campaignId,
        held,
        'HOLD',
        new Date('2026-11-11T02:00:00Z'),
      );

      clock.set(new Date('2026-11-12T03:00:00.000Z'));
      const tomorrow = await creatorList();
      expect(tomorrow.day).toBe('2026-11-12');
      expect(idsOf(tomorrow).sort()).toEqual([held, fresh].sort());
    });

    it('builds a new list after Korean midnight', async () => {
      await makeBrand();
      const early = await seedCreator('early');
      clock.set(new Date('2026-11-11T14:59:59.000Z'));
      const beforeMidnight = await creatorList();
      expect(beforeMidnight.day).toBe('2026-11-11');
      expect(idsOf(beforeMidnight)).toEqual([early]);

      const late = await seedCreator('late');
      // 같은 날(한국 시간 23:59:59)에는 목록이 그대로다.
      expect(idsOf(await creatorList())).toEqual([early]);

      clock.set(new Date('2026-11-11T15:00:00.000Z'));
      const afterMidnight = await creatorList();
      expect(afterMidnight.day).toBe('2026-11-12');
      expect(idsOf(afterMidnight).sort()).toEqual([early, late].sort());
      expect(await prisma.dailyRecommendation.count()).toBe(2);
    });

    it("drops a card from today's list once the creator blocks my industry", async () => {
      await makeBrand('ALCOHOL');
      const stays = await seedCreator('stays');
      const leaves = await seedCreator('leaves');
      expect((await creatorList()).total).toBe(2);

      await prisma.creatorPrinciples.update({
        where: { creatorId: leaves },
        data: { blockedIndustries: ['ALCOHOL'] },
      });
      const list = await creatorList();
      expect(idsOf(list)).toEqual([stays]);
      expect(list.total).toBe(1);
    });

    it('hides blocked users from recommendations in both directions', async () => {
      await makeBrand('ACCESSORY');
      const blockedByMe = await seedCreator('blocked-by-me');
      const blockedMe = await seedCreator('blocked-me');
      const stays = await seedCreator('stays');
      expect((await creatorList()).total).toBe(3);

      await prisma.block.createMany({
        data: [
          { blockerId: USER_A, blockedId: blockedByMe },
          { blockerId: blockedMe, blockedId: USER_A },
        ],
      });
      const list = await creatorList();
      expect(idsOf(list)).toEqual([stays]);
      expect(list.total).toBe(1);
    });

    it('leaves out creators without principles and withdrawn creators', async () => {
      await makeBrand();
      const shown = await seedCreator('shown');
      await seedCreator('no-principles', { principles: null });
      await seedCreator('withdrawn', { deleted: true });
      expect(idsOf(await creatorList())).toEqual([shown]);
    });

    it('excludes a counterpart I have an unfinished collaboration with, or dropped on this campaign', async () => {
      const campaignId = await makeBrand();
      const open = await seedCreator('open');
      const halted = await seedCreator('halted');
      const dropped = await seedCreator('dropped');
      const finished = await seedCreator('finished');
      const droppedElsewhere = await seedCreator('dropped-elsewhere');
      const other = await seedBrandCampaign('옛 캠페인', 'ACCESSORY', {
        status: 'CLOSED',
      });
      await seedCollaboration(USER_A, open, 'NEGOTIATING', campaignId);
      await seedCollaboration(USER_A, halted, 'HALTED', campaignId);
      await seedCollaboration(USER_A, dropped, 'DROPPED', campaignId);
      await seedCollaboration(USER_A, finished, 'SETTLED', null);
      // 다른 캠페인에서 그만둔 것은 이 캠페인의 추천을 막지 않는다.
      await seedCollaboration(
        USER_A,
        droppedElsewhere,
        'DROPPED',
        other.campaignId,
      );
      expect(idsOf(await creatorList()).sort()).toEqual(
        [finished, droppedElsewhere].sort(),
      );
    });

    it('makes one list when two requests arrive together', async () => {
      await makeBrand();
      for (let i = 1; i <= 4; i += 1) await seedCreator(`c${i}`);
      const [a, b] = await Promise.all([
        request(server).get('/recommendations/creators').set(authA),
        request(server).get('/recommendations/creators').set(authA),
      ]);
      expect(a.status).toBe(200);
      expect(b.status).toBe(200);
      expect(idsOf(a.body as CreatorList)).toEqual(
        idsOf(b.body as CreatorList),
      );
      expect(await prisma.dailyRecommendation.count()).toBe(1);
    });

    it('never puts the campaign budget or any decision on the response', async () => {
      const campaignId = await makeBrand();
      const id = await seedCreator('someone');
      await brandDecision(campaignId, id, 'PASS');
      await seedCreator('another');
      const res = await request(server)
        .get('/recommendations/creators')
        .set(authA)
        .expect(200);
      expect(res.text).not.toMatch(/budget|decision|passReason|PASS/);
    });
  });

  describe('campaigns and stores for a creator', () => {
    beforeEach(async () => {
      await makeCreatorB({ fields: ['ACCESSORY', 'FOOD_CAFE'] });
    });

    it('refuses campaign recommendations to a brand and to a user without a role', async () => {
      await request(server)
        .get('/recommendations/campaigns')
        .set(authA)
        .expect(403);
      await setRole(authA, 'BRAND');
      expect(
        codeOf(
          await request(server)
            .get('/recommendations/campaigns')
            .set(authA)
            .expect(403),
        ),
      ).toBe('FORBIDDEN');
    });

    it('returns an empty list with total 0 when nothing qualifies', async () => {
      expect(await campaignList()).toEqual({
        day: '2026-11-11',
        total: 0,
        cards: [],
      });
    });

    it('mixes stores into the creator list and marks another province', async () => {
      await seedBrandCampaign('느린결', 'ACCESSORY', {
        notRequired: ['FACE', 'FIXED_LINES', 'SCRIPT_READING'],
      });
      await seedStore('성수 라멘', {
        intro: '성수동 골목의 작은 라멘집이에요. 점심엔 줄이 길어요.',
      });
      await seedStore('부산 카페', {
        sido: '부산광역시',
        sigungu: '해운대구',
        voucher: true,
        perView: false,
        fixedCash: 30000,
      });
      const res = await request(server)
        .get('/recommendations/campaigns')
        .set(authB)
        .expect(200);
      const list = res.body as MixedList;
      expect(list.total).toBe(3);
      const campaign = list.cards.find((c) => c.kind === 'CAMPAIGN');
      const local = list.cards.find((c) => c.store?.name === '성수 라멘');
      const far = list.cards.find((c) => c.store?.name === '부산 카페');

      expect(campaign?.campaignId).toEqual(expect.any(String));
      expect({ ...campaign, campaignId: undefined }).toEqual({
        kind: 'CAMPAIGN',
        campaignId: undefined,
        brandName: '느린결',
        brandTagline: '느린결의 소개',
        photoUrl: null,
        headline: '느린결 캠페인',
        fee: 300000,
        productProvided: true,
        tags: ['얼굴출연없음', '정해진대사없음'],
        reasons: ['FIELD', 'FACE', 'SCRIPT', 'FEE', 'TRIAL'],
      });
      expect(local).toMatchObject({
        headline: '성수동 골목의 작은 라멘집이에요.',
        tags: ['소상공인', '팔로워무관'],
        otherSido: null,
        rewardLine: '식사권 + 조회수 수당',
      });
      expect(far).toMatchObject({
        otherSido: '부산광역시',
        rewardLine: '식사권 + 현금 30,000원',
      });
      expect(res.text).not.toMatch(/budget|instagram/i);
    });

    it('orders by score and puts a brand that already liked me first', async () => {
      const strong = await seedBrandCampaign('강한 캠페인', 'ACCESSORY');
      const weak = await seedBrandCampaign('약한 캠페인', 'DIGITAL', {
        fee: 100000,
      });
      // 약한 캠페인의 브랜드가 나에게 먼저 관심을 보냈다.
      await prisma.swipeDecision.create({
        data: {
          actorId: weak.brandId,
          targetKind: 'CREATOR',
          targetId: OTHER,
          campaignId: weak.campaignId,
          decision: 'LIKE',
        },
      });
      const list = await campaignList();
      expect(list.cards.map((c) => c.campaignId)).toEqual([
        weak.campaignId,
        strong.campaignId,
      ]);
    });

    it('builds at most 10 cards', async () => {
      for (let i = 1; i <= 12; i += 1) await seedStore(`가게${i}`);
      const list = await campaignList();
      expect(list.total).toBe(10);
      expect(list.cards).toHaveLength(10);
    });

    it('omits cards I already decided on and counterparts I already work with', async () => {
      const passed = await seedBrandCampaign('넘긴 브랜드', 'ACCESSORY');
      const working = await seedBrandCampaign('협업 중 브랜드', 'ACCESSORY');
      const kept = await seedBrandCampaign('남는 브랜드', 'ACCESSORY');
      const passedStore = await seedStore('넘긴 가게');
      const offerStore = await seedStore('오퍼 온 가게');
      const appliedStore = await seedStore('지원한 가게');
      const keptStore = await seedStore('남는 가게');
      await prisma.swipeDecision.create({
        data: {
          actorId: OTHER,
          targetKind: 'CAMPAIGN',
          targetId: passed.campaignId,
          campaignId: passed.campaignId,
          decision: 'PASS',
          passReason: 'FEE',
        },
      });
      await prisma.swipeDecision.create({
        data: {
          actorId: OTHER,
          targetKind: 'STORE',
          targetId: passedStore.id,
          decision: 'PASS',
        },
      });
      await seedCollaboration(
        working.brandId,
        OTHER,
        'MATCHED',
        working.campaignId,
      );
      await createOffer(prisma, {
        storeId: offerStore.id,
        creatorId: OTHER,
        status: 'SENT',
        expiresAt: new Date('2026-11-20T00:00:00Z'),
        voucherName: '식사권',
      });
      await prisma.application.create({
        data: { storeId: appliedStore.id, creatorId: OTHER, status: 'APPLIED' },
      });

      const res = await request(server)
        .get('/recommendations/campaigns')
        .set(authB)
        .expect(200);
      const list = res.body as MixedList;
      expect(list.cards.map((c) => c.campaignId ?? c.store?.id).sort()).toEqual(
        [kept.campaignId, keptStore.id].sort(),
      );
      expect(res.text).not.toMatch(/passReason|PASS/);
    });

    it('drops a store from the saved list once I apply to it, but not once the application is closed', async () => {
      const applied = await seedStore('지원할 가게');
      const closed = await seedStore('닫힌 지원의 가게');
      const kept = await seedStore('남는 가게');
      const before = await campaignList();
      expect(before.cards.map((c) => c.store?.id).sort()).toEqual(
        [applied.id, closed.id, kept.id].sort(),
      );

      await request(server)
        .post(`/stores/${applied.id}/applications`)
        .set(authB)
        .send()
        .expect(201);
      await prisma.application.create({
        data: { storeId: closed.id, creatorId: OTHER, status: 'CLOSED' },
      });

      const after = await campaignList();
      expect(after.cards.map((c) => c.store?.id).sort()).toEqual(
        [closed.id, kept.id].sort(),
      );

      // 지원을 거두면(CANCELLED) 다시 나온다.
      await request(server)
        .delete(`/stores/${applied.id}/applications/mine`)
        .set(authB)
        .expect(204);
      expect(
        (await campaignList()).cards.map((c) => c.store?.id).sort(),
      ).toEqual([applied.id, closed.id, kept.id].sort());
    });

    it('does not build a new list with a store I applied to', async () => {
      const applied = await seedStore('지원한 가게');
      const kept = await seedStore('남는 가게');
      await prisma.application.create({
        data: { storeId: applied.id, creatorId: OTHER, status: 'OFFERED' },
      });
      const list = await campaignList();
      expect(list.cards.map((c) => c.store?.id)).toEqual([kept.id]);
    });

    it('treats a SENT offer past its deadline as lapsed: it is not open and comes back first', async () => {
      const lapsed = await seedStore('저장은 SENT인 가게', {
        sigungu: '마포구',
      });
      await seedStore('가까운 가게');
      await createOffer(prisma, {
        storeId: lapsed.id,
        creatorId: OTHER,
        status: 'SENT',
        initiatedBy: 'STORE',
        expiresAt: new Date('2026-11-10T00:00:00Z'),
        voucherName: '식사권',
      });
      const list = await campaignList();
      expect(list.cards[0].store?.id).toBe(lapsed.id);
    });

    it('drops a store from the saved list when a live offer arrives, but keeps one whose offer already lapsed', async () => {
      const live = await seedStore('오퍼가 올 가게');
      const stale = await seedStore('기한이 지난 가게');
      await campaignList();
      await createOffer(prisma, {
        storeId: live.id,
        creatorId: OTHER,
        status: 'SENT',
        expiresAt: new Date('2026-11-20T00:00:00Z'),
        voucherName: '식사권',
      });
      await createOffer(prisma, {
        storeId: stale.id,
        creatorId: OTHER,
        status: 'SENT',
        expiresAt: new Date('2026-11-10T00:00:00Z'),
        voucherName: '식사권',
      });
      expect((await campaignList()).cards.map((c) => c.store?.id)).toEqual([
        stale.id,
      ]);
    });

    it('lets a store whose offer lapsed come back first', async () => {
      const lapsed = await seedStore('기한 지난 가게', { sigungu: '마포구' });
      await seedStore('가까운 가게');
      await createOffer(prisma, {
        storeId: lapsed.id,
        creatorId: OTHER,
        status: 'EXPIRED',
        expiresAt: new Date('2026-11-01T00:00:00Z'),
        voucherName: '식사권',
      });
      const list = await campaignList();
      expect(list.cards[0].store?.id).toBe(lapsed.id);
    });

    it('drops a campaign and a store from the list once I block their industry', async () => {
      await seedBrandCampaign('술 브랜드', 'ALCOHOL');
      const alcoholStore = await seedStore('술집', { industry: 'ALCOHOL' });
      await seedBrandCampaign('일반 브랜드', 'ACCESSORY');
      expect((await campaignList()).total).toBe(3);

      await request(server)
        .put('/creators/me/principles')
        .set(authB)
        .send({ ...PRINCIPLES, blockedIndustries: ['ALCOHOL'] })
        .expect(200);
      const list = await campaignList();
      expect(list.total).toBe(1);
      expect(list.cards.map((c) => c.brandName)).toEqual(['일반 브랜드']);
      expect(list.cards.some((c) => c.store?.id === alcoholStore.id)).toBe(
        false,
      );
    });

    it('hides blocked brands and stores from the creator list in both directions', async () => {
      const blockedBrand = await seedBrandCampaign('내가 차단', 'ACCESSORY');
      const blockingBrand = await seedBrandCampaign('나를 차단', 'ACCESSORY');
      await seedBrandCampaign('보이는 브랜드', 'ACCESSORY');
      const blockedStore = await seedStore('내가 차단한 가게');
      const blockingStore = await seedStore('나를 차단한 가게');
      expect((await campaignList()).total).toBe(5);

      await prisma.block.createMany({
        data: [
          { blockerId: OTHER, blockedId: blockedBrand.brandId },
          { blockerId: blockingBrand.brandId, blockedId: OTHER },
          { blockerId: OTHER, blockedId: blockedStore.ownerId },
          { blockerId: blockingStore.ownerId, blockedId: OTHER },
        ],
      });
      const list = await campaignList();
      expect(list.total).toBe(1);
      expect(list.cards.map((c) => c.brandName)).toEqual(['보이는 브랜드']);
    });

    it('still lists campaigns for a creator without principles, with no reasons', async () => {
      await prisma.creatorPrinciples.deleteMany();
      await seedBrandCampaign('브랜드', 'ACCESSORY');
      const list = await campaignList();
      expect(list.cards).toHaveLength(1);
      expect(list.cards[0].reasons).toEqual([]);
    });

    it('makes one list when two requests arrive together', async () => {
      await seedStore('가게1');
      await seedStore('가게2');
      const [a, b] = await Promise.all([
        request(server).get('/recommendations/campaigns').set(authB),
        request(server).get('/recommendations/campaigns').set(authB),
      ]);
      expect(a.status).toBe(200);
      expect(b.status).toBe(200);
      expect(a.body).toEqual(b.body);
      expect(await prisma.dailyRecommendation.count()).toBe(1);
    });

    it('builds a new list after Korean midnight', async () => {
      await seedStore('아침 가게');
      clock.set(new Date('2026-11-11T14:59:59.000Z'));
      expect((await campaignList()).total).toBe(1);
      await seedStore('밤 가게');
      expect((await campaignList()).total).toBe(1);
      clock.set(new Date('2026-11-11T15:00:00.000Z'));
      const next = await campaignList();
      expect(next.day).toBe('2026-11-12');
      expect(next.total).toBe(2);
    });
  });

  describe('preview for a user without a role', () => {
    const preview = async () =>
      (
        await request(server)
          .get('/recommendations/preview')
          .set(authA)
          .expect(200)
      ).body as {
        total: number;
        cards: {
          creatorId: string;
          displayName: string;
          headline: string | null;
          photoUrl: string | null;
          feeBand: string;
          tags: string[];
        }[];
      };

    it('gives preview cards to a signed-in user without a role', async () => {
      const older = await seedCreator('older');
      const newer = await seedCreator('newer');
      const body = await preview();
      expect(body.total).toBe(2);
      // 최근 가입 순.
      expect(body.cards.map((c) => c.creatorId)).toEqual([newer, older]);
    });

    it('leaves creators with any blocked industry out of the preview', async () => {
      const open = await seedCreator('open');
      await seedCreator('avoids-alcohol', {
        principles: { blockedIndustries: ['ALCOHOL'] },
      });
      await seedCreator('no-principles', { principles: null });
      await seedCreator('withdrawn', { deleted: true });
      expect((await preview()).cards.map((c) => c.creatorId)).toEqual([open]);
    });

    it('never puts the instagram handle or match reasons on a preview card', async () => {
      await seedCreator('someone', { handle: 'secret_handle' });
      const res = await request(server)
        .get('/recommendations/preview')
        .set(authA)
        .expect(200);
      expect(res.text).not.toMatch(
        /instagram|secret_handle|reasons|theyLikedMe/,
      );
      const [card] = (res.body as { cards: Record<string, unknown>[] }).cards;
      expect(Object.keys(card).sort()).toEqual(
        [
          'creatorId',
          'displayName',
          'feeBand',
          'headline',
          'photoUrl',
          'tags',
        ].sort(),
      );
    });

    it('shows at most 10 cards and stores nothing', async () => {
      for (let i = 1; i <= 12; i += 1) await seedCreator(`c${i}`);
      expect((await preview()).cards).toHaveLength(10);
      expect(await prisma.dailyRecommendation.count()).toBe(0);
    });

    it('refuses the preview for a user who already has a role', async () => {
      await setRole(authA, 'CREATOR');
      expect(
        codeOf(
          await request(server)
            .get('/recommendations/preview')
            .set(authA)
            .expect(403),
        ),
      ).toBe('FORBIDDEN');
    });
  });
});
