import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { IndustryCategory, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
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
const NOON = new Date('2026-11-11T03:00:00.000Z');

interface InterestCard {
  targetKind: string;
  targetId: string;
  name: string;
  shortName: string;
  headline: string | null;
  photoUrl: string | null;
  state: string;
  feeLabel: number | null;
  feeBand: string | null;
  startFrom: string | null;
  hasProposal: boolean;
  collaborationId: string | null;
}
interface ProposalBody {
  campaignId: string;
  brandName: string;
  note: string | null;
  contentTitle: string | null;
  contentPhotoUrl: string | null;
  fee: number;
  productProvided: boolean;
  performance: { ratePer1000: number; cap: number } | null;
  format: string;
}

describe('interests, received proposals and card details', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;

  const setRole = (auth: Record<string, string>, role: string) =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const put = (auth: Record<string, string>, body: Record<string, unknown>) =>
    request(server).put('/discovery/decisions').set(auth).send(body);
  const brandDecide = (
    creatorId: string,
    decision: string,
    extra: Record<string, unknown> = {},
  ) =>
    put(authBrand, {
      targetKind: 'CREATOR',
      targetId: creatorId,
      decision,
      ...extra,
    }).expect(200);
  const creatorDecide = (
    campaignId: string,
    decision: string,
    extra: Record<string, unknown> = {},
  ) =>
    put(authCreator, {
      targetKind: 'CAMPAIGN',
      targetId: campaignId,
      decision,
      ...extra,
    }).expect(200);
  const interests = async (auth: Record<string, string>, tab?: string) =>
    (
      await request(server)
        .get('/discovery/interests')
        .query(tab ? { tab } : {})
        .set(auth)
        .expect(200)
    ).body as InterestCard[];
  const received = async () =>
    (
      await request(server)
        .get('/discovery/received-proposals')
        .set(authCreator)
        .expect(200)
    ).body as ProposalBody[];

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

  async function makeCreator(
    principles: Record<string, unknown> | null = {},
    displayName = '하루 한 컵',
  ): Promise<void> {
    await setRole(authCreator, 'CREATOR');
    await request(server)
      .put('/creators/me')
      .set(authCreator)
      .send({ displayName, ...REGION })
      .expect(200);
    if (principles) {
      await request(server)
        .put('/creators/me/principles')
        .set(authCreator)
        .send({ ...PRINCIPLES, ...principles })
        .expect(200);
    }
  }

  // 요청으로는 로그인할 수 없는 두 번째 크리에이터를 DB에 바로 만든다.
  async function seedCreator(
    displayName: string,
    feeBand: 'W200K' | 'W300K' | 'W400K' | 'W500K_PLUS' = 'W400K',
  ): Promise<string> {
    const id = randomUUID();
    await prisma.user.create({ data: { id, role: 'CREATOR' } });
    await prisma.creatorProfile.create({
      data: {
        userId: id,
        displayName,
        cardHeadline: `${displayName}의 한 줄`,
        ...REGION,
      },
    });
    await prisma.creatorPrinciples.create({
      data: {
        creatorId: id,
        fields: ['ACCESSORY'],
        blockedIndustries: [],
        faceOk: false,
        scriptOk: true,
        honestReview: true,
        feeBand,
        trialDays: 'ANY',
      },
    });
    return id;
  }

  const bothSides = async (industry: IndustryCategory = 'ACCESSORY') => {
    const campaignId = await makeBrand(industry);
    await makeCreator();
    return campaignId;
  };

  const noPassLeak = (body: unknown) => {
    const text = JSON.stringify(body);
    expect(text).not.toContain('PASS');
    expect(text).not.toContain('passReason');
  };

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(NOON);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    const id = randomUUID();
    await request(server).get('/discovery/interests').expect(401);
    await request(server).get('/discovery/received-proposals').expect(401);
    await request(server).get(`/campaigns/${id}/detail`).expect(401);
    await request(server).get(`/creators/${id}/card`).expect(401);
  });

  describe('the interests list of a brand', () => {
    it('the saved tab returns my likes and holds, never passes', async () => {
      await makeBrand();
      const liked = await seedCreator('서윤의 작은 취향');
      const held = await seedCreator('모아 스튜디오');
      const passed = await seedCreator('지나간 사람');
      await brandDecide(liked, 'LIKE');
      clock.advance(1000);
      await brandDecide(held, 'HOLD');
      clock.advance(1000);
      await brandDecide(passed, 'PASS');
      await request(server)
        .put('/discovery/decisions/pass-reason')
        .set(authBrand)
        .send({ targetKind: 'CREATOR', targetId: passed, reason: 'FEE' })
        .expect(204);

      const saved = await interests(authBrand);
      expect(saved.map((c) => [c.targetId, c.state])).toEqual([
        [held, 'HELD'],
        [liked, 'WAITING'],
      ]);
      expect(await interests(authBrand, 'saved')).toEqual(saved);
      noPassLeak(saved);
      expect(saved.map((c) => c.targetId)).not.toContain(passed);
    });

    it('splits the tabs into mutual, sent and held', async () => {
      const campaignId = await bothSides();
      const waiting = await seedCreator('모아 스튜디오');
      const held = await seedCreator('느긋한 하루');
      await creatorDecide(campaignId, 'LIKE');
      await brandDecide(OTHER, 'LIKE');
      await brandDecide(waiting, 'LIKE');
      await brandDecide(held, 'HOLD');

      const ids = async (tab: string) =>
        (await interests(authBrand, tab)).map((c) => c.targetId);
      expect(await ids('mutual')).toEqual([OTHER]);
      expect(await ids('sent')).toEqual([waiting]);
      expect(await ids('held')).toEqual([held]);
      expect(await ids('saved')).toHaveLength(3);
      await request(server)
        .get('/discovery/interests?tab=all')
        .set(authBrand)
        .expect(400);
    });

    it('shows the latest terms of a mutual interest and my own proposal for a waiting one', async () => {
      const campaignId = await bothSides();
      const waiting = await seedCreator('서윤의 작은 취향', 'W500K_PLUS');
      const plain = await seedCreator('모아 스튜디오', 'W200K');
      await creatorDecide(campaignId, 'LIKE');
      const match = (await brandDecide(OTHER, 'LIKE', { proposal: PROPOSAL }))
        .body as { collaborationId: string };
      await brandDecide(waiting, 'LIKE', { proposal: PROPOSAL });
      await brandDecide(plain, 'LIKE');

      const byId = new Map(
        (await interests(authBrand)).map((c) => [c.targetId, c]),
      );
      expect(byId.get(OTHER)).toMatchObject({
        state: 'MUTUAL',
        feeLabel: 450000,
        startFrom: '2026-11-20',
        hasProposal: true,
        collaborationId: match.collaborationId,
        feeBand: 'W300K',
        shortName: '하루 한 컵',
        targetKind: 'CREATOR',
      });
      expect(byId.get(waiting)).toMatchObject({
        state: 'WAITING',
        feeLabel: 450000,
        startFrom: null,
        hasProposal: true,
        collaborationId: null,
        feeBand: 'W500K_PLUS',
        shortName: '서윤',
        headline: '서윤의 작은 취향의 한 줄',
      });
      expect(byId.get(plain)).toMatchObject({
        feeLabel: null,
        feeBand: 'W200K',
        hasProposal: false,
      });
    });

    it('follows a new terms version of a mutual interest', async () => {
      const campaignId = await bothSides();
      await creatorDecide(campaignId, 'LIKE');
      const collaborationId = (
        (await brandDecide(OTHER, 'LIKE')).body as { collaborationId: string }
      ).collaborationId;
      await prisma.termsVersion.create({
        data: {
          collaborationId,
          version: 2,
          proposedById: USER_A,
          title: '새 판본',
          fee: 380000,
          startDate: new Date('2026-12-01T00:00:00Z'),
          format: 'REELS',
          pieces: 1,
          productProvided: true,
          revisionScope: 'GUIDE_1',
          usageRights: 'REPOST_ONLY',
          payoutDays: 7,
        },
      });
      const [card] = await interests(authBrand, 'mutual');
      expect(card).toMatchObject({ feeLabel: 380000, startFrom: '2026-12-01' });
    });

    it('drops a creator who has come to avoid my industry', async () => {
      await bothSides();
      await brandDecide(OTHER, 'LIKE');
      expect(await interests(authBrand)).toHaveLength(1);
      await request(server)
        .put('/creators/me/principles')
        .set(authCreator)
        .send({ ...PRINCIPLES, blockedIndustries: ['ALCOHOL'] })
        .expect(200);
      await prisma.brandProfile.updateMany({ data: { industry: 'ALCOHOL' } });
      expect(await interests(authBrand)).toEqual([]);
    });

    it('is forbidden without a role and asks for a campaign first', async () => {
      await request(server)
        .get('/discovery/interests')
        .set(authBrand)
        .expect(403);
      await setRole(authBrand, 'BRAND');
      await request(server)
        .put('/brands/me')
        .set(authBrand)
        .send({ name: '느린결', industry: 'ACCESSORY' })
        .expect(200);
      await request(server)
        .get('/discovery/interests')
        .set(authBrand)
        .expect(409);
      await request(server)
        .get('/discovery/received-proposals')
        .set(authBrand)
        .expect(403);
    });
  });

  describe('the interests list of a creator', () => {
    it('lists the campaigns I liked or held and never the budget or a pass', async () => {
      const campaignId = await bothSides();
      await creatorDecide(campaignId, 'HOLD');
      let list = await interests(authCreator);
      expect(list).toEqual([
        {
          targetKind: 'CAMPAIGN',
          targetId: campaignId,
          name: '느린결',
          shortName: '느린결',
          headline: CAMPAIGN.headline,
          photoUrl: null,
          state: 'HELD',
          feeLabel: 300000,
          feeBand: null,
          startFrom: null,
          hasProposal: false,
          collaborationId: null,
        },
      ]);
      expect(JSON.stringify(list)).not.toContain('budget');
      expect(JSON.stringify(list)).not.toContain('1000000');

      await creatorDecide(campaignId, 'LIKE');
      list = await interests(authCreator, 'sent');
      expect(list.map((c) => c.state)).toEqual(['WAITING']);

      await creatorDecide(campaignId, 'PASS');
      expect(await interests(authCreator)).toEqual([]);
    });

    it('shows a mutual interest with the latest terms even after the campaign closed', async () => {
      const campaignId = await bothSides();
      await creatorDecide(campaignId, 'LIKE');
      await brandDecide(OTHER, 'LIKE', { proposal: PROPOSAL });
      await request(server)
        .post(`/campaigns/${campaignId}/close`)
        .set(authBrand)
        .expect(200);
      const [card] = await interests(authCreator, 'mutual');
      expect(card).toMatchObject({
        state: 'MUTUAL',
        feeLabel: 450000,
        startFrom: '2026-11-20',
      });
      expect(card.collaborationId).not.toBeNull();
    });

    it('drops a held campaign that has closed', async () => {
      const campaignId = await bothSides();
      await creatorDecide(campaignId, 'HOLD');
      await request(server)
        .post(`/campaigns/${campaignId}/close`)
        .set(authBrand)
        .expect(200);
      expect(await interests(authCreator)).toEqual([]);
    });

    it('drops a campaign of an industry I avoid', async () => {
      const campaignId = await bothSides();
      await creatorDecide(campaignId, 'HOLD');
      await request(server)
        .put('/creators/me/principles')
        .set(authCreator)
        .send({ ...PRINCIPLES, blockedIndustries: ['ALCOHOL'] })
        .expect(200);
      await prisma.brandProfile.updateMany({ data: { industry: 'ALCOHOL' } });
      expect(await interests(authCreator)).toEqual([]);
    });
  });

  describe('received proposals', () => {
    it('lists a noted like until the creator decides, with the content copy', async () => {
      const campaignId = await bothSides();
      await prisma.creatorProfile.update({
        where: { userId: OTHER },
        data: {
          cardHeadline: '아침 한 컵',
          cardPhotoPath: `creator-cards/${OTHER}/a.jpg`,
        },
      });
      await brandDecide(OTHER, 'LIKE', { note: '결이 좋아서요' });
      const [proposal] = await received();
      expect(proposal).toMatchObject({
        campaignId,
        brandName: '느린결',
        note: '결이 좋아서요',
        contentTitle: '아침 한 컵',
        fee: 300000,
        productProvided: true,
        performance: null,
        format: 'REELS',
      });
      expect(proposal.contentPhotoUrl).toContain('creator-cards');
      expect(JSON.stringify(proposal)).not.toContain('budget');

      await creatorDecide(campaignId, 'PASS');
      expect(await received()).toEqual([]);
    });

    it('lists a proposal-carrying like without a note with the proposed amounts and the performance', async () => {
      const campaignId = await bothSides();
      await brandDecide(OTHER, 'LIKE', { proposal: PROPOSAL });
      const [proposal] = await received();
      expect(proposal).toMatchObject({
        campaignId,
        note: null,
        contentTitle: null,
        contentPhotoUrl: null,
        fee: 450000,
        productProvided: false,
        performance: { ratePer1000: 2000, cap: 60000 },
      });
    });

    it('does not list a plain like, a hold, a pass or a like I already answered', async () => {
      const campaignId = await bothSides();
      await brandDecide(OTHER, 'LIKE');
      expect(await received()).toEqual([]);
      await brandDecide(OTHER, 'HOLD');
      expect(await received()).toEqual([]);
      await brandDecide(OTHER, 'PASS');
      expect(await received()).toEqual([]);
      await brandDecide(OTHER, 'LIKE', { note: '다시 관심' });
      expect(await received()).toHaveLength(1);
      // 내가 관심으로 답하면 서로 관심이 되어 받은 제안에서 빠진다.
      await creatorDecide(campaignId, 'LIKE');
      expect(await received()).toEqual([]);
    });

    it('keeps a proposal I held and drops it when the brand takes the like back', async () => {
      const campaignId = await bothSides();
      await brandDecide(OTHER, 'LIKE', { note: '결이 좋아서요' });
      await creatorDecide(campaignId, 'HOLD');
      expect(await received()).toHaveLength(1);
      await brandDecide(OTHER, 'PASS');
      expect(await received()).toEqual([]);
    });

    it('hides the proposal of a brand whose industry I avoid and a closed campaign', async () => {
      const campaignId = await bothSides();
      await brandDecide(OTHER, 'LIKE', { note: '결이 좋아서요' });
      await request(server)
        .put('/creators/me/principles')
        .set(authCreator)
        .send({ ...PRINCIPLES, blockedIndustries: ['ALCOHOL'] })
        .expect(200);
      expect(await received()).toHaveLength(1);
      await prisma.brandProfile.updateMany({ data: { industry: 'ALCOHOL' } });
      expect(await received()).toEqual([]);
      await prisma.brandProfile.updateMany({ data: { industry: 'ACCESSORY' } });
      await request(server)
        .post(`/campaigns/${campaignId}/close`)
        .set(authBrand)
        .expect(200);
      expect(await received()).toEqual([]);
    });

    it('is for creators only', async () => {
      await bothSides();
      await request(server)
        .get('/discovery/received-proposals')
        .set(authBrand)
        .expect(403);
    });
  });

  describe('the campaign detail', () => {
    it('returns the card with schedule, must-include, not-required and the overlap count, without the budget', async () => {
      const campaignId = await bothSides();
      const res = await request(server)
        .get(`/campaigns/${campaignId}/detail`)
        .set(authCreator)
        .expect(200);
      expect(res.body).toMatchObject({
        kind: 'CAMPAIGN',
        campaignId,
        brandName: '느린결',
        headline: CAMPAIGN.headline,
        fee: 300000,
        productProvided: true,
        startFrom: '2026-11-20',
        trialDays: 'D7',
        mustInclude: ['제품 로고가 보이게'],
        notRequired: ['FACE'],
        myDecision: null,
      });
      const body = res.body as { reasons: string[]; overlapCount: number };
      expect(body.overlapCount).toBe(body.reasons.length);
      expect(body.overlapCount).toBeGreaterThan(0);
      expect(JSON.stringify(res.body)).not.toContain('budget');
    });

    it('reports my like or hold and returns 404 once I passed it', async () => {
      const campaignId = await bothSides();
      const detail = (expectStatus: number) =>
        request(server)
          .get(`/campaigns/${campaignId}/detail`)
          .set(authCreator)
          .expect(expectStatus);
      await creatorDecide(campaignId, 'HOLD');
      expect(
        ((await detail(200)).body as { myDecision: string }).myDecision,
      ).toBe('HOLD');
      await creatorDecide(campaignId, 'LIKE');
      expect(
        ((await detail(200)).body as { myDecision: string }).myDecision,
      ).toBe('LIKE');
      await creatorDecide(campaignId, 'PASS');
      await detail(404);
    });

    it('returns 404 for a closed campaign, an industry I avoid, an unknown id and a brand', async () => {
      const campaignId = await bothSides();
      await request(server)
        .get(`/campaigns/${randomUUID()}/detail`)
        .set(authCreator)
        .expect(404);
      await request(server)
        .get(`/campaigns/${campaignId}/detail`)
        .set(authBrand)
        .expect(403);
      await request(server)
        .put('/creators/me/principles')
        .set(authCreator)
        .send({ ...PRINCIPLES, blockedIndustries: ['ALCOHOL'] })
        .expect(200);
      await prisma.brandProfile.updateMany({ data: { industry: 'ALCOHOL' } });
      await request(server)
        .get(`/campaigns/${campaignId}/detail`)
        .set(authCreator)
        .expect(404);
      await prisma.brandProfile.updateMany({ data: { industry: 'ACCESSORY' } });
      await request(server)
        .post(`/campaigns/${campaignId}/close`)
        .set(authBrand)
        .expect(200);
      await request(server)
        .get(`/campaigns/${campaignId}/detail`)
        .set(authCreator)
        .expect(404);
    });

    it('does not show the brand a pass of the creator and does not show the creator a pass of the brand', async () => {
      const campaignId = await bothSides();
      await brandDecide(OTHER, 'PASS');
      const res = await request(server)
        .get(`/campaigns/${campaignId}/detail`)
        .set(authCreator)
        .expect(200);
      expect((res.body as { myDecision: unknown }).myDecision).toBeNull();
      noPassLeak(res.body);
    });
  });

  describe('the creator card', () => {
    it('returns the card with my decision', async () => {
      await bothSides();
      const get = () =>
        request(server)
          .get(`/creators/${OTHER}/card`)
          .set(authBrand)
          .expect(200);
      let body = (await get()).body as Record<string, unknown>;
      expect(body).toMatchObject({
        creatorId: OTHER,
        displayName: '하루 한 컵',
        feeBand: 'W300K',
        theyLikedMe: false,
        myDecision: null,
      });
      expect(body.reasons).toEqual(expect.any(Array));
      await brandDecide(OTHER, 'HOLD');
      body = (await get()).body as Record<string, unknown>;
      expect(body.myDecision).toBe('HOLD');
      await brandDecide(OTHER, 'LIKE');
      expect(((await get()).body as { myDecision: string }).myDecision).toBe(
        'LIKE',
      );
    });

    it('returns 404 for a creator who avoids my industry, has no principles, is unknown or was passed', async () => {
      await makeBrand('ALCOHOL');
      await makeCreator({ blockedIndustries: ['ALCOHOL'] });
      await request(server)
        .get(`/creators/${OTHER}/card`)
        .set(authBrand)
        .expect(404);
      await request(server)
        .get(`/creators/${randomUUID()}/card`)
        .set(authBrand)
        .expect(404);
      await prisma.creatorPrinciples.deleteMany({});
      await request(server)
        .get(`/creators/${OTHER}/card`)
        .set(authBrand)
        .expect(404);
    });

    it('returns 404 for a creator I passed and never carries the pass', async () => {
      await bothSides();
      await brandDecide(OTHER, 'PASS');
      await request(server)
        .get(`/creators/${OTHER}/card`)
        .set(authBrand)
        .expect(404);
    });

    it('is for brands with an active campaign only', async () => {
      await bothSides();
      await request(server)
        .get(`/creators/${USER_A}/card`)
        .set(authCreator)
        .expect(403);
      await request(server)
        .get('/creators/not-a-uuid/card')
        .set(authBrand)
        .expect(400);
    });

    it('does not tell the brand that the creator passed the campaign', async () => {
      const campaignId = await bothSides();
      await creatorDecide(campaignId, 'PASS');
      const res = await request(server)
        .get(`/creators/${OTHER}/card`)
        .set(authBrand)
        .expect(200);
      expect((res.body as { myDecision: unknown }).myDecision).toBeNull();
      noPassLeak(res.body);
      expect(await interests(authBrand)).toEqual([]);
    });
  });
});
