import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { OTHER } from './support/fake-token-verifier';

// user-a는 브랜드, user-b는 크리에이터다. 두 번째 후보는 DB에 바로 만든다.
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
  fee: 350000,
  productProvided: false,
  performance: { ratePer1000: 2000, cap: 60000 },
};
const NOON = new Date('2026-11-11T03:00:00.000Z');

interface Side {
  creatorId: string;
  name: string;
  shortName: string;
  photoUrl: string | null;
  state: string;
  collaborationId: string | null;
  format: string;
  pieces: number;
  productProvided: boolean;
  fee: number | null;
  feeBand: string;
  perfRate: number | null;
  perfCap: number | null;
  usageRights: string;
  startDate: string | null;
  faceOk: boolean;
}
interface CompareBody {
  sides: [Side, Side];
  differs: string[];
}

describe('candidate comparison', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;

  const setRole = (auth: Record<string, string>, role: string) =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const decide = (auth: Record<string, string>, body: object) =>
    request(server).put('/discovery/decisions').set(auth).send(body);
  const brandDecide = (
    creatorId: string,
    decision: string,
    extra: Record<string, unknown> = {},
  ) =>
    decide(authBrand, {
      targetKind: 'CREATOR',
      targetId: creatorId,
      decision,
      ...extra,
    }).expect(200);
  const compare = (a: string, b: string, auth = authBrand) =>
    request(server).get('/discovery/compare').query({ a, b }).set(auth);

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

  async function seedCreator(
    displayName: string,
    feeBand: 'W200K' | 'W300K' | 'W400K' | 'W500K_PLUS' = 'W400K',
    faceOk = false,
  ): Promise<string> {
    const id = randomUUID();
    await prisma.user.create({ data: { id, role: 'CREATOR' } });
    await prisma.creatorProfile.create({
      data: { userId: id, displayName, ...REGION },
    });
    await prisma.creatorPrinciples.create({
      data: {
        creatorId: id,
        fields: ['ACCESSORY'],
        blockedIndustries: [],
        faceOk,
        scriptOk: true,
        honestReview: true,
        feeBand,
        trialDays: 'ANY',
      },
    });
    return id;
  }

  // 하루 한 컵(user-b)과 서로 관심을 만든다.
  async function matchOther(campaignId: string): Promise<string> {
    await decide(authCreator, {
      targetKind: 'CAMPAIGN',
      targetId: campaignId,
      decision: 'LIKE',
    }).expect(200);
    const res = await brandDecide(OTHER, 'LIKE');
    return (res.body as { collaborationId: string }).collaborationId;
  }

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
    await request(server)
      .get('/discovery/compare')
      .query({ a: randomUUID(), b: randomUUID() })
      .expect(401);
  });

  it('compares two saved candidates and marks the rows that differ', async () => {
    const campaignId = await makeBoth();
    const collaborationId = await matchOther(campaignId);
    const other = await seedCreator('서윤의 작은 취향');
    await brandDecide(other, 'LIKE', { proposal: PROPOSAL });

    const res = await compare(OTHER, other).expect(200);
    const body = res.body as CompareBody;
    expect(body.sides[0]).toEqual({
      creatorId: OTHER,
      name: '하루 한 컵',
      shortName: '하루 한 컵',
      photoUrl: null,
      state: 'MUTUAL',
      collaborationId,
      format: 'REELS',
      pieces: 1,
      productProvided: true,
      fee: 300000,
      feeBand: 'W300K',
      perfRate: null,
      perfCap: null,
      usageRights: 'REPOST_ONLY',
      startDate: '2026-11-20',
      faceOk: true,
    });
    expect(body.sides[1]).toEqual({
      creatorId: other,
      name: '서윤의 작은 취향',
      shortName: '서윤',
      photoUrl: null,
      state: 'WAITING',
      collaborationId: null,
      format: 'REELS',
      pieces: 1,
      productProvided: false,
      fee: 350000,
      feeBand: 'W400K',
      // 단가는 상한과 같은 출처(내 제안)에서 오고, 다시 열 때 저장된 값을 지키는 데 쓴다.
      perfRate: 2000,
      perfCap: 60000,
      usageRights: 'REPOST_ONLY',
      startDate: null,
      faceOk: false,
    });
    expect(body.differs).toEqual([
      'BENEFIT',
      'FEE',
      'PERF_CAP',
      'START',
      'FACE',
    ]);
  });

  it('falls back to the campaign values and the fee band for candidates without a proposal', async () => {
    await makeBoth();
    const held = await seedCreator('모아 스튜디오', 'W400K', true);
    const plain = await seedCreator('느긋한 하루', 'W500K_PLUS', true);
    await brandDecide(held, 'HOLD');
    await brandDecide(plain, 'LIKE');
    const body = (await compare(held, plain).expect(200)).body as CompareBody;
    expect(body.sides.map((s) => s.state)).toEqual(['HELD', 'WAITING']);
    for (const side of body.sides) {
      expect(side).toMatchObject({
        fee: null,
        productProvided: true,
        perfRate: null,
        perfCap: null,
        usageRights: 'REPOST_ONLY',
        startDate: null,
        pieces: 1,
        format: 'REELS',
        faceOk: true,
      });
    }
    // 금액이 없으면 희망 제작비 구간으로 견준다.
    expect(body.differs).toEqual(['FEE']);
  });

  it('keeps the order of the request and does not depend on it', async () => {
    const campaignId = await makeBoth();
    await matchOther(campaignId);
    const other = await seedCreator('서윤의 작은 취향');
    await brandDecide(other, 'HOLD');
    const ab = (await compare(OTHER, other).expect(200)).body as CompareBody;
    const ba = (await compare(other, OTHER).expect(200)).body as CompareBody;
    expect(ab.sides.map((s) => s.creatorId)).toEqual([OTHER, other]);
    expect(ba.sides.map((s) => s.creatorId)).toEqual([other, OTHER]);
    expect(ba.differs).toEqual(ab.differs);
  });

  it('never includes follower counts, the budget or a pass in the comparison', async () => {
    const campaignId = await makeBoth();
    await matchOther(campaignId);
    await prisma.instagramConnection.create({
      data: {
        creatorId: OTHER,
        handle: 'haru_cup',
        followers: 12400,
        refreshedAt: NOON,
      },
    });
    const other = await seedCreator('서윤의 작은 취향');
    await brandDecide(other, 'LIKE', { proposal: PROPOSAL });
    const res = await compare(OTHER, other).expect(200);
    const text = JSON.stringify(res.body);
    expect(text).not.toMatch(/follower/i);
    expect(text).not.toContain('12400');
    expect(text).not.toContain('budget');
    expect(text).not.toContain('PASS');
    expect(text).not.toContain('passReason');
  });

  it('returns 404 when comparing a candidate I have not saved', async () => {
    const campaignId = await makeBoth();
    await matchOther(campaignId);
    const unsaved = await seedCreator('저장 안 한 사람');
    await compare(OTHER, unsaved).expect(404);
    await compare(OTHER, randomUUID()).expect(404);
  });

  it('returns 404 for a candidate I passed, one who avoids my industry and one without principles', async () => {
    const campaignId = await makeBoth();
    await matchOther(campaignId);
    const passed = await seedCreator('넘긴 사람');
    await brandDecide(passed, 'LIKE');
    await brandDecide(passed, 'PASS');
    await compare(OTHER, passed).expect(404);

    const hidden = await seedCreator('피하는 사람');
    await brandDecide(hidden, 'HOLD');
    await compare(OTHER, hidden).expect(200);
    await prisma.creatorPrinciples.update({
      where: { creatorId: hidden },
      data: { blockedIndustries: ['ALCOHOL'] },
    });
    await prisma.brandProfile.updateMany({ data: { industry: 'ALCOHOL' } });
    await compare(OTHER, hidden).expect(404);
    await prisma.brandProfile.updateMany({ data: { industry: 'ACCESSORY' } });
    await prisma.creatorPrinciples.deleteMany({ where: { creatorId: hidden } });
    await compare(OTHER, hidden).expect(404);
  });

  it('only counts decisions made in my active campaign', async () => {
    await makeBoth();
    const other = await seedCreator('서윤의 작은 취향');
    await brandDecide(other, 'HOLD');
    const campaign = await prisma.campaign.findFirstOrThrow();
    await brandDecide(OTHER, 'HOLD');
    await request(server)
      .post(`/campaigns/${campaign.id}/close`)
      .set(authBrand)
      .expect(200);
    // 마감한 뒤에는 진행 중인 캠페인이 없어 비교할 수 없다.
    await compare(OTHER, other).expect(409);
  });

  it('is for brands only and needs two different valid ids', async () => {
    await makeBoth();
    await compare(OTHER, randomUUID(), authCreator).expect(403);
    await compare(OTHER, OTHER).expect(400);
    await request(server)
      .get('/discovery/compare')
      .query({ a: 'x', b: 'y' })
      .set(authBrand)
      .expect(400);
    await request(server)
      .get('/discovery/compare')
      .query({ a: OTHER })
      .set(authBrand)
      .expect(400);
  });
});
