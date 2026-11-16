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
const PERFORMANCE_PROPOSAL = {
  fee: 450000,
  productProvided: false,
  performance: { ratePer1000: 2000, cap: 60000 },
};
const NOON = new Date('2026-11-11T03:00:00.000Z');

interface TermsVersionBody {
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
  terms: TermsVersionBody;
  notice: string | null;
  reasons: string[];
  trialDays: string;
  followers: number | null;
  myTurn: boolean;
  mine: boolean;
  needsInstagram: boolean;
}
interface NotificationsBody {
  items: { text: string; tab: string; target: { kind: string; id: string } }[];
}

describe('terms version 1 and its confirmation', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let push: FakePushPort;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const setRole = (auth: Record<string, string>, role: string) =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const decide = (auth: Record<string, string>, body: object) =>
    request(server).put('/discovery/decisions').set(auth).send(body);
  const latest = (auth: Record<string, string>, id: string) =>
    request(server).get(`/collaborations/${id}/terms/latest`).set(auth);
  const confirm = (
    auth: Record<string, string>,
    id: string,
    version: number | string = 1,
  ) =>
    request(server)
      .post(`/collaborations/${id}/terms/${version}/confirm`)
      .set(auth);
  const latestOf = async (auth: Record<string, string>, id: string) =>
    (await latest(auth, id).expect(200)).body as LatestBody;
  const stageOf = async (id: string) =>
    (await prisma.collaboration.findUniqueOrThrow({ where: { id } })).stage;

  async function makeBoth(
    o: {
      campaign?: Record<string, unknown>;
      principles?: Record<string, unknown>;
    } = {},
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
    const campaign = await request(server)
      .post('/campaigns')
      .set(authBrand)
      .send({ ...CAMPAIGN, ...o.campaign })
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
      .send({ ...PRINCIPLES, ...o.principles })
      .expect(200);
    return (campaign.body as { id: string }).id;
  }

  // 서로 관심을 만들어 협업 id를 돌려준다.
  async function matchUp(
    campaignId: string,
    brandExtra: Record<string, unknown> = {},
    creatorExtra: Record<string, unknown> = {},
  ): Promise<string> {
    await decide(authCreator, {
      targetKind: 'CAMPAIGN',
      targetId: campaignId,
      decision: 'LIKE',
      ...creatorExtra,
    }).expect(200);
    const res = await decide(authBrand, {
      targetKind: 'CREATOR',
      targetId: OTHER,
      decision: 'LIKE',
      ...brandExtra,
    }).expect(200);
    return (res.body as { collaborationId: string }).collaborationId;
  }

  const connectInstagram = (followers: number | null = 12400) =>
    prisma.instagramConnection.create({
      data: {
        creatorId: OTHER,
        handle: 'haru_cup',
        followers,
        refreshedAt: NOON,
      },
    });

  const notificationsOf = async (auth: Record<string, string>) =>
    (await request(server).get('/notifications').set(auth).expect(200))
      .body as NotificationsBody;

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
    const id = randomUUID();
    await request(server).get(`/collaborations/${id}/terms/latest`).expect(401);
    await request(server)
      .post(`/collaborations/${id}/terms/1/confirm`)
      .expect(401);
  });

  describe('the latest version', () => {
    it('reads version 1 as a system draft that both sides still have to answer', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId, {}, { note: '출근길 한 컵 이야기' });

      for (const auth of [authBrand, authCreator]) {
        const body = await latestOf(auth, id);
        expect(body.terms).toEqual({
          version: 1,
          proposedBy: 'SYSTEM',
          title: '출근길 한 컵 이야기',
          fee: 300000,
          performance: null,
          maxCash: 300000,
          startDate: '2026-11-20',
          format: 'REELS',
          pieces: 1,
          productProvided: true,
          revisionScope: 'GUIDE_1',
          usageRights: 'REPOST_ONLY',
          payoutDays: 7,
          brandConfirmed: false,
          creatorConfirmed: false,
        });
        expect(body.myTurn).toBe(true);
        expect(body.mine).toBe(false);
        expect(body.needsInstagram).toBe(false);
        expect(body.trialDays).toBe('D7');
        expect(body.followers).toBeNull();
        expect(body.notice).toBeNull();
        // 캠페인 한 줄이 아니라 크리에이터가 쓴 글이 제목이다.
        expect(body.terms.title).not.toBe(CAMPAIGN.headline);
      }
    });

    it('gives the reasons the principles share with the campaign', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      const body = await latestOf(authBrand, id);
      expect(body.reasons).toEqual(
        expect.arrayContaining(['FIELD', 'FACE', 'SCRIPT', 'FEE', 'TRIAL']),
      );
    });

    it('builds the notice line from the creator principles', async () => {
      const cases: [{ faceOk: boolean; scriptOk: boolean }, string | null][] = [
        [
          { faceOk: false, scriptOk: false },
          '얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.',
        ],
        [{ faceOk: false, scriptOk: true }, '얼굴 출연은 진행하지 않아요.'],
        [
          { faceOk: true, scriptOk: false },
          '제품 설명문 낭독은 진행하지 않아요.',
        ],
        [{ faceOk: true, scriptOk: true }, null],
      ];
      for (const [principles, notice] of cases) {
        await truncateTestDb(prisma);
        const campaignId = await makeBoth({ principles });
        const id = await matchUp(campaignId);
        expect((await latestOf(authBrand, id)).notice).toBe(notice);
        expect((await latestOf(authCreator, id)).notice).toBe(notice);
      }
    }, 60_000);

    it('shows the followers of the connected account', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      await connectInstagram(12400);
      expect((await latestOf(authBrand, id)).followers).toBe(12400);
    });

    it('adds the performance cap to the maximum cash burden', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId, { proposal: PERFORMANCE_PROPOSAL });
      const { terms } = await latestOf(authBrand, id);
      expect(terms).toMatchObject({
        fee: 450000,
        productProvided: false,
        performance: { ratePer1000: 2000, cap: 60000 },
        maxCash: 510000,
        brandConfirmed: false,
        creatorConfirmed: false,
      });
    });

    it('asks only the creator for an instagram connection when a bonus is on a reels campaign', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId, { proposal: PERFORMANCE_PROPOSAL });
      expect((await latestOf(authCreator, id)).needsInstagram).toBe(true);
      expect((await latestOf(authBrand, id)).needsInstagram).toBe(false);
      await connectInstagram();
      expect((await latestOf(authCreator, id)).needsInstagram).toBe(false);
    });

    it('does not ask for instagram when the bonus is on a shorts campaign', async () => {
      const campaignId = await makeBoth({ campaign: { format: 'SHORTS' } });
      const id = await matchUp(campaignId, { proposal: PERFORMANCE_PROPOSAL });
      expect((await latestOf(authCreator, id)).needsInstagram).toBe(false);
    });

    it('flips myTurn and mine as people confirm', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      await confirm(authBrand, id).expect(200);
      const brandSide = await latestOf(authBrand, id);
      const creatorSide = await latestOf(authCreator, id);
      expect(brandSide.myTurn).toBe(false);
      expect(creatorSide.myTurn).toBe(true);
      expect(brandSide.mine).toBe(false);
    });

    it('returns 404 for terms of a collaboration I am not part of', async () => {
      await makeBoth();
      const brandId = randomUUID();
      const creatorId = randomUUID();
      await prisma.user.create({ data: { id: brandId, role: 'BRAND' } });
      await prisma.user.create({ data: { id: creatorId, role: 'CREATOR' } });
      const collaboration = await prisma.collaboration.create({
        data: {
          kind: 'BRAND_CONTRACT',
          stage: 'MATCHED',
          commissionerId: brandId,
          creatorId,
          terms: {},
          settlementMethod: 'FIXED',
        },
      });
      // user-a와 user-b는 이 협업의 당사자가 아니다.
      for (const auth of [authBrand, authCreator]) {
        expect((await latest(auth, collaboration.id)).status).toBe(404);
        expect((await confirm(auth, collaboration.id)).status).toBe(404);
      }
      await latest(authBrand, randomUUID()).expect(404);
      await latest(authBrand, 'not-a-uuid').expect(404);
    });

    it('returns 404 for a store offer collaboration', async () => {
      await makeBoth();
      const storeOwner = randomUUID();
      await prisma.user.create({ data: { id: storeOwner, role: 'STORE' } });
      const collaboration = await prisma.collaboration.create({
        data: {
          kind: 'STORE_OFFER',
          stage: 'FUNDED',
          commissionerId: storeOwner,
          creatorId: OTHER,
          terms: {},
          settlementMethod: 'FIXED',
        },
      });
      await latest(authCreator, collaboration.id).expect(404);
      await confirm(authCreator, collaboration.id).expect(404);
    });
  });

  describe('confirming a version', () => {
    it('moves MATCHED to NEGOTIATING on the first confirmation and to AGREED on the second', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      expect(await stageOf(id)).toBe('MATCHED');

      const first = await confirm(authBrand, id).expect(200);
      expect(first.body as TermsVersionBody).toMatchObject({
        version: 1,
        brandConfirmed: true,
        creatorConfirmed: false,
      });
      expect(await stageOf(id)).toBe('NEGOTIATING');

      const second = await confirm(authCreator, id).expect(200);
      expect(second.body as TermsVersionBody).toMatchObject({
        brandConfirmed: true,
        creatorConfirmed: true,
      });
      expect(await stageOf(id)).toBe('AGREED');
      const [row] = await prisma.termsVersion.findMany();
      expect(row.brandConfirmedAt).toEqual(NOON);
      expect(row.creatorConfirmedAt).toEqual(NOON);
    });

    it('lets the creator confirm first', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      await confirm(authCreator, id).expect(200);
      expect(await stageOf(id)).toBe('NEGOTIATING');
      await confirm(authBrand, id).expect(200);
      expect(await stageOf(id)).toBe('AGREED');
    });

    it('notifies the other side with the version number', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      push.sent.length = 0;
      await confirm(authBrand, id).expect(200);
      await confirm(authCreator, id).expect(200);

      const creatorGot = (await notificationsOf(authCreator)).items.filter(
        (i) => i.tab === 'COLLABORATION',
      );
      const brandGot = (await notificationsOf(authBrand)).items.filter(
        (i) => i.tab === 'COLLABORATION',
      );
      expect(creatorGot).toEqual([
        {
          ...creatorGot[0],
          text: '느린결이 조건 버전 1을 확인했어요.',
          target: { kind: 'TERMS', id },
        },
      ]);
      expect(brandGot).toEqual([
        {
          ...brandGot[0],
          text: '하루 한 컵이 조건 버전 1을 확인했어요.',
          target: { kind: 'TERMS', id },
        },
      ]);
      expect(push.sent.map((p) => p.userId)).toEqual([OTHER, USER_A]);
    });

    it('answers a repeated confirmation with the same version and sends no second notice', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      await confirm(authBrand, id).expect(200);
      const again = await confirm(authBrand, id).expect(200);
      expect((again.body as TermsVersionBody).brandConfirmed).toBe(true);
      expect(await stageOf(id)).toBe('NEGOTIATING');
      const got = (await notificationsOf(authCreator)).items.filter(
        (i) => i.tab === 'COLLABORATION',
      );
      expect(got).toHaveLength(1);
    });

    it('applies each confirmation once when both sides confirm at the same time', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      const [a, b, c] = await Promise.all([
        confirm(authBrand, id),
        confirm(authCreator, id),
        confirm(authBrand, id),
      ]);
      expect([a.status, b.status, c.status]).toEqual([200, 200, 200]);
      expect(await stageOf(id)).toBe('AGREED');
      const [row] = await prisma.termsVersion.findMany();
      expect(row.brandConfirmedAt).not.toBeNull();
      expect(row.creatorConfirmedAt).not.toBeNull();
      // 같은 쪽이 두 번 눌러도 알림은 한 번이다.
      const creatorGot = (await notificationsOf(authCreator)).items.filter(
        (i) => i.tab === 'COLLABORATION',
      );
      expect(creatorGot).toHaveLength(1);
    });

    it('refuses to confirm an older version with STALE_VERSION', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      // 새 판본은 5b의 제안 API가 만든다. 여기서는 저장소에 바로 넣는다.
      const [v1] = await prisma.termsVersion.findMany();
      await prisma.collaboration.update({
        where: { id },
        data: { stage: 'NEGOTIATING' },
      });
      await prisma.termsVersion.create({
        data: {
          collaborationId: id,
          version: 2,
          proposedById: USER_A,
          title: v1.title,
          fee: 350000,
          startDate: v1.startDate,
          format: v1.format,
          pieces: 1,
          productProvided: true,
          revisionScope: 'GUIDE_1',
          usageRights: 'REPOST_ONLY',
          payoutDays: 7,
          brandConfirmedAt: NOON,
        },
      });
      const res = await confirm(authCreator, id, 1).expect(409);
      expect(codeOf(res)).toBe('STALE_VERSION');
      expect(
        (res.body as { error: { details: unknown } }).error.details,
      ).toEqual({ latestVersion: 2 });
      // 옛 판본에는 아무 확인도 남지 않는다.
      expect(
        (await prisma.termsVersion.findMany()).every(
          (row) => row.creatorConfirmedAt === null,
        ),
      ).toBe(true);
      expect(await stageOf(id)).toBe('NEGOTIATING');

      const body = await latestOf(authCreator, id);
      expect(body.terms).toMatchObject({
        version: 2,
        proposedBy: 'BRAND',
        fee: 350000,
        brandConfirmed: true,
      });
      expect(body.mine).toBe(false);
      expect(body.myTurn).toBe(true);
      expect((await latestOf(authBrand, id)).mine).toBe(true);
      // 새 판본을 낸 쪽은 확인한 것이니, 상대가 그 판본을 확인하면 합의가 된다.
      await confirm(authCreator, id, 2).expect(200);
      expect(await stageOf(id)).toBe('AGREED');
    });

    it('refuses a version number that does not exist and one that is not a number', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      expect(codeOf(await confirm(authBrand, id, 3).expect(409))).toBe(
        'STALE_VERSION',
      );
      await confirm(authBrand, id, 'abc').expect(400);
      expect(await stageOf(id)).toBe('MATCHED');
    });

    it('refuses a creator confirming a performance bonus without instagram', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId, { proposal: PERFORMANCE_PROPOSAL });
      const res = await confirm(authCreator, id).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect((res.body as { error: { message: string } }).error.message).toBe(
        '인스타그램을 연동하면 수락할 수 있어요.',
      );
      const [row] = await prisma.termsVersion.findMany();
      expect(row.creatorConfirmedAt).toBeNull();
      expect(await stageOf(id)).toBe('MATCHED');

      // 브랜드의 확인은 막지 않고, 연동하면 크리에이터도 확인할 수 있다.
      await confirm(authBrand, id).expect(200);
      await connectInstagram();
      await confirm(authCreator, id).expect(200);
      expect(await stageOf(id)).toBe('AGREED');
    });

    it('refuses to confirm once the contract is past the agreement', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      await prisma.collaboration.update({
        where: { id },
        data: { stage: 'CONTRACTED' },
      });
      const res = await confirm(authBrand, id).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      const dropped = await prisma.collaboration.update({
        where: { id },
        data: { stage: 'DROPPED' },
      });
      await confirm(authCreator, dropped.id).expect(409);
    });

    it('still saves the confirmation when the notice cannot be sent', async () => {
      const campaignId = await makeBoth();
      const id = await matchUp(campaignId);
      push.fail = true;
      try {
        await confirm(authBrand, id).expect(200);
      } finally {
        push.fail = false;
      }
      expect(await stageOf(id)).toBe('NEGOTIATING');
    });
  });
});
