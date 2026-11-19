import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { IndustryCategory, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { VisibilityService } from '../src/visibility/visibility.service';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { createOffer } from './helpers/create-offer';
import { truncateTestDb } from './helpers/truncate-test-db';
import { USER_A } from './support/fake-token-verifier';

// 로그인할 수 있는 사용자는 user-a(USER_A)와 user-b(OTHER)뿐이다. 나머지는 DB에 바로 만든다.
const auth = { Authorization: 'Bearer user-a' };
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const PROFILE = { displayName: '하루 한 컵', contentFocus: '카페', ...REGION };
const PRINCIPLES = {
  fields: ['FOOD_CAFE'],
  blockedIndustries: ['ALCOHOL'],
  faceOk: true,
  scriptOk: true,
  honestReview: true,
  feeBand: 'W300K',
  trialDays: 'ANY',
};
const OFFER_BODY = { format: 'REELS', reward: { voucher: {} } };

describe('visibility', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const putPrinciples = (over: Record<string, unknown> = {}) =>
    request(server)
      .put('/creators/me/principles')
      .set(auth)
      .send({ ...PRINCIPLES, ...over })
      .expect(200);

  // user-a를 크리에이터로 만들고, 술(ALCOHOL)을 피하는 협업 원칙을 정한다.
  async function becomeCreatorAvoidingAlcohol(): Promise<void> {
    await setRole('CREATOR');
    await request(server)
      .put('/creators/me')
      .set(auth)
      .send(PROFILE)
      .expect(200);
    await putPrinciples();
  }

  // 공개된 가게를 DB에 바로 만든다. ownerId를 주면 그 사용자의 가게다.
  async function seedStore(
    industry: IndustryCategory,
    ownerId?: string,
  ): Promise<{ id: string; ownerId: string }> {
    const owner = ownerId ?? randomUUID();
    await prisma.user.upsert({
      where: { id: owner },
      create: { id: owner, role: 'STORE' },
      update: {},
    });
    const store = await prisma.store.create({
      data: {
        ownerId: owner,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name: `${industry} 가게`,
        industry,
        ...REGION,
        defaultFormat: 'REELS',
        defaultVoucherName: '식사권',
        defaultVoucherValue: 40000,
        defaultVoucherPeople: 2,
        publishedAt: new Date(),
      },
    });
    return { id: store.id, ownerId: owner };
  }

  // 활동 프로필이 있는 다른 크리에이터. blocked를 주면 협업 원칙도 함께 만든다.
  async function seedCreator(
    name: string,
    blocked?: IndustryCategory[],
  ): Promise<string> {
    const userId = randomUUID();
    await prisma.user.create({ data: { id: userId, role: 'CREATOR' } });
    await prisma.creatorProfile.create({
      data: { userId, displayName: name, ...REGION },
    });
    if (blocked) {
      await prisma.creatorPrinciples.create({
        data: {
          creatorId: userId,
          fields: ['FOOD_CAFE'],
          blockedIndustries: blocked,
          faceOk: true,
          scriptOk: true,
          honestReview: true,
          feeBand: 'W300K',
          trialDays: 'ANY',
        },
      });
    }
    return userId;
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  describe('a creator who avoids alcohol', () => {
    beforeEach(becomeCreatorAvoidingAlcohol);

    it('hides an alcohol store from the list and returns 404 for its detail', async () => {
      const alcohol = await seedStore('ALCOHOL');
      const cafe = await seedStore('FOOD_CAFE');
      const list = await request(server).get('/stores').set(auth).expect(200);
      expect((list.body as { id: string }[]).map((s) => s.id)).toEqual([
        cafe.id,
      ]);
      const hidden = await request(server)
        .get(`/stores/${alcohol.id}`)
        .set(auth)
        .expect(404);
      expect(codeOf(hidden)).toBe('NOT_FOUND');
      await request(server).get(`/stores/${cafe.id}`).set(auth).expect(200);
    });

    it('hides a store whose owner blocked the creator, or whom the creator blocked, and refuses applications and proposals to it', async () => {
      const store = await seedStore('FOOD_CAFE');
      for (const [blockerId, blockedId] of [
        [store.ownerId, USER_A],
        [USER_A, store.ownerId],
      ]) {
        await prisma.block.deleteMany();
        await prisma.block.create({ data: { blockerId, blockedId } });
        const list = await request(server).get('/stores').set(auth).expect(200);
        expect(list.body as unknown[]).toEqual([]);
        await request(server).get(`/stores/${store.id}`).set(auth).expect(404);
        await request(server)
          .post(`/stores/${store.id}/applications`)
          .set(auth)
          .send()
          .expect(404);
        await request(server)
          .post(`/stores/${store.id}/proposals`)
          .set(auth)
          .send(OFFER_BODY)
          .expect(404);
      }
      expect(await prisma.application.count()).toBe(0);
      expect(await prisma.offer.count()).toBe(0);
    });

    it('applies a newly added blocked industry immediately', async () => {
      const gambling = await seedStore('GAMBLING');
      const seen = () =>
        request(server)
          .get('/stores')
          .set(auth)
          .expect(200)
          .then((res) => (res.body as { id: string }[]).map((s) => s.id));
      expect(await seen()).toEqual([gambling.id]);
      await putPrinciples({ blockedIndustries: ['ALCOHOL', 'GAMBLING'] });
      expect(await seen()).toEqual([]);
      await request(server).get(`/stores/${gambling.id}`).set(auth).expect(404);
      await putPrinciples({ blockedIndustries: [] });
      expect(await seen()).toEqual([gambling.id]);
    });

    it('returns 404 when applying to a store of an avoided industry', async () => {
      const alcohol = await seedStore('ALCOHOL');
      const res = await request(server)
        .post(`/stores/${alcohol.id}/applications`)
        .set(auth)
        .send()
        .expect(404);
      expect(codeOf(res)).toBe('NOT_FOUND');
      expect(await prisma.application.count()).toBe(0);
    });

    it('returns 404 when proposing to a store of an avoided industry', async () => {
      const alcohol = await seedStore('ALCOHOL');
      const res = await request(server)
        .post(`/stores/${alcohol.id}/proposals`)
        .set(auth)
        .send(OFFER_BODY)
        .expect(404);
      expect(codeOf(res)).toBe('NOT_FOUND');
      expect(await prisma.offer.count()).toBe(0);
      expect(await prisma.application.count()).toBe(0);
      const cafe = await seedStore('FOOD_CAFE');
      await request(server)
        .post(`/stores/${cafe.id}/proposals`)
        .set(auth)
        .send(OFFER_BODY)
        .expect(201);
    });

    it('keeps an offer received before the creator started avoiding the industry', async () => {
      const alcohol = await seedStore('ALCOHOL');
      const creatorId = USER_A;
      await createOffer(prisma, {
        storeId: alcohol.id,
        creatorId,
        format: 'REELS',
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        status: 'SENT',
        expiresAt: new Date(Date.now() + 7 * 24 * 3600 * 1000),
      });
      const res = await request(server)
        .get('/offers/received?tab=new')
        .set(auth)
        .expect(200);
      expect(res.body as unknown[]).toHaveLength(1);
    });
  });

  describe('a store owner', () => {
    let storeId: string;

    beforeEach(async () => {
      await setRole('STORE');
      storeId = (await seedStore('ALCOHOL', USER_A)).id;
    });

    it('returns 404 when offering to a creator who avoids the store industry', async () => {
      const avoiding = await seedCreator('술 피함', ['ALCOHOL']);
      const res = await request(server)
        .post('/offers')
        .set(auth)
        .send({ creatorId: avoiding, ...OFFER_BODY })
        .expect(404);
      expect(codeOf(res)).toBe('NOT_FOUND');
      expect(await prisma.offer.count()).toBe(0);
      expect(await prisma.application.count()).toBe(0);
    });

    it('returns 404 when offering to a creator who blocked the store owner, or whom the store owner blocked', async () => {
      const creator = await seedCreator('차단 관계', []);
      for (const [blockerId, blockedId] of [
        [creator, USER_A],
        [USER_A, creator],
      ]) {
        await prisma.block.deleteMany();
        await prisma.block.create({ data: { blockerId, blockedId } });
        const res = await request(server)
          .post('/offers')
          .set(auth)
          .send({ creatorId: creator, ...OFFER_BODY })
          .expect(404);
        expect(codeOf(res)).toBe('NOT_FOUND');
      }
      expect(await prisma.offer.count()).toBe(0);
      expect(await prisma.application.count()).toBe(0);
    });

    it('can offer to a creator with no principles or one who avoids another industry', async () => {
      const none = await seedCreator('원칙 없음');
      const other = await seedCreator('도박 피함', ['GAMBLING']);
      for (const creatorId of [none, other]) {
        await request(server)
          .post('/offers')
          .set(auth)
          .send({ creatorId, ...OFFER_BODY })
          .expect(201);
      }
    });

    it('drops applicants who avoid the store industry from the list and the recommendations', async () => {
      const avoiding = await seedCreator('술 피함', ['ALCOHOL']);
      const fine = await seedCreator('괜찮음', ['GAMBLING']);
      const none = await seedCreator('원칙 없음');
      for (const creatorId of [avoiding, fine, none]) {
        await prisma.application.create({
          data: { storeId, creatorId, status: 'APPLIED' },
        });
      }
      const list = await request(server)
        .get('/stores/me/applications')
        .set(auth)
        .expect(200);
      expect(
        (list.body as { creator: { displayName: string } }[])
          .map((a) => a.creator.displayName)
          .sort(),
      ).toEqual(['괜찮음', '원칙 없음']);
      const picks = await request(server)
        .get('/stores/me/applications/recommended')
        .set(auth)
        .expect(200);
      const body = picks.body as {
        totalNew: number;
        items: { creator: { displayName: string } }[];
      };
      expect(body.items.map((i) => i.creator.displayName).sort()).toEqual([
        '괜찮음',
        '원칙 없음',
      ]);
      expect(body.totalNew).toBe(2);
      // 사장님 홈의 새 지원 수도 같은 기준이다.
      const home = await request(server)
        .get('/stores/me/summary')
        .set(auth)
        .expect(200);
      expect((home.body as { newApplications: number }).newApplications).toBe(
        2,
      );
    });

    it('drops an applicant from the list as soon as they start avoiding the industry', async () => {
      const creator = await seedCreator('나중에 피함', ['GAMBLING']);
      await prisma.application.create({
        data: { storeId, creatorId: creator, status: 'APPLIED' },
      });
      const names = () =>
        request(server)
          .get('/stores/me/applications')
          .set(auth)
          .expect(200)
          .then((res) =>
            (res.body as { creator: { displayName: string } }[]).map(
              (a) => a.creator.displayName,
            ),
          );
      expect(await names()).toEqual(['나중에 피함']);
      await prisma.creatorPrinciples.updateMany({
        where: { creatorId: creator },
        data: { blockedIndustries: ['GAMBLING', 'ALCOHOL'] },
      });
      expect(await names()).toEqual([]);
    });
  });

  describe('VisibilityService', () => {
    let visibility: VisibilityService;
    beforeEach(() => {
      visibility = app.get(VisibilityService);
    });

    it('hides a creator without principles from brands but not from stores', async () => {
      const noPrinciples = await seedCreator('원칙 없음');
      const withPrinciples = await seedCreator('원칙 있음', []);
      const brand = {
        userId: randomUUID(),
        kind: 'BRAND' as const,
        industry: 'BEAUTY' as const,
      };
      const store = { ...brand, kind: 'STORE' as const };
      expect(await visibility.creatorVisibleTo(noPrinciples, brand)).toBe(
        false,
      );
      expect(await visibility.creatorVisibleTo(withPrinciples, brand)).toBe(
        true,
      );
      expect(await visibility.creatorVisibleTo(noPrinciples, store)).toBe(true);
      expect(
        await visibility.filterCreators([noPrinciples, withPrinciples], brand),
      ).toEqual([withPrinciples]);
      expect(
        await visibility.filterCreators([noPrinciples, withPrinciples], store),
      ).toEqual([noPrinciples, withPrinciples]);
    });

    it('hides a creator from a viewer whose industry they avoid and from themselves', async () => {
      const avoiding = await seedCreator('술 피함', ['ALCOHOL']);
      const viewer = (kind: 'STORE' | 'BRAND', industry: IndustryCategory) => ({
        userId: randomUUID(),
        kind,
        industry,
      });
      expect(
        await visibility.creatorVisibleTo(avoiding, viewer('STORE', 'ALCOHOL')),
      ).toBe(false);
      expect(
        await visibility.creatorVisibleTo(avoiding, viewer('BRAND', 'ALCOHOL')),
      ).toBe(false);
      expect(
        await visibility.creatorVisibleTo(avoiding, viewer('STORE', 'LOAN')),
      ).toBe(true);
      expect(
        await visibility.creatorVisibleTo(avoiding, {
          userId: avoiding,
          kind: 'STORE',
          industry: 'LOAN',
        }),
      ).toBe(false);
    });

    it('hides a blocked creator from the viewer whichever side blocked', async () => {
      const blockedByViewer = await seedCreator('내가 차단', []);
      const blockedViewer = await seedCreator('나를 차단', []);
      const stays = await seedCreator('그대로', []);
      const viewer = {
        userId: randomUUID(),
        kind: 'BRAND' as const,
        industry: 'BEAUTY' as const,
      };
      await prisma.user.create({ data: { id: viewer.userId, role: 'BRAND' } });
      await prisma.block.createMany({
        data: [
          { blockerId: viewer.userId, blockedId: blockedByViewer },
          { blockerId: blockedViewer, blockedId: viewer.userId },
        ],
      });
      expect(await visibility.creatorVisibleTo(blockedByViewer, viewer)).toBe(
        false,
      );
      expect(await visibility.creatorVisibleTo(blockedViewer, viewer)).toBe(
        false,
      );
      expect(
        await visibility.filterCreators(
          [blockedByViewer, stays, blockedViewer],
          viewer,
        ),
      ).toEqual([stays]);
      // 다른 사람에게는 그대로 보인다.
      expect(
        await visibility.filterCreators([blockedByViewer, blockedViewer], {
          ...viewer,
          userId: randomUUID(),
        }),
      ).toEqual([blockedByViewer, blockedViewer]);
    });

    it('hides a blocked commissioner from the creator whichever side blocked', async () => {
      const creator = await seedCreator('크리에이터', []);
      const blockedByCreator = {
        ownerId: randomUUID(),
        industry: 'BEAUTY' as const,
      };
      const blockedCreator = { ...blockedByCreator, ownerId: randomUUID() };
      const stays = { ...blockedByCreator, ownerId: randomUUID() };
      for (const target of [blockedByCreator, blockedCreator, stays]) {
        await prisma.user.create({
          data: { id: target.ownerId, role: 'BRAND' },
        });
      }
      await prisma.block.createMany({
        data: [
          { blockerId: creator, blockedId: blockedByCreator.ownerId },
          { blockerId: blockedCreator.ownerId, blockedId: creator },
        ],
      });
      expect(
        await visibility.commissionerVisibleTo(blockedByCreator, creator),
      ).toBe(false);
      expect(
        await visibility.commissionerVisibleTo(blockedCreator, creator),
      ).toBe(false);
      expect(
        await visibility.filterCommissioners(
          [blockedByCreator, stays, blockedCreator],
          creator,
        ),
      ).toEqual([stays]);
    });

    it('stops hiding a creator once the block row is removed', async () => {
      const creator = await seedCreator('크리에이터', []);
      const viewer = {
        userId: randomUUID(),
        kind: 'STORE' as const,
        industry: 'BEAUTY' as const,
      };
      await prisma.user.create({ data: { id: viewer.userId, role: 'STORE' } });
      const block = await prisma.block.create({
        data: { blockerId: viewer.userId, blockedId: creator },
      });
      expect(await visibility.creatorVisibleTo(creator, viewer)).toBe(false);
      await prisma.block.update({
        where: { id: block.id },
        data: { deletedAt: new Date() },
      });
      expect(await visibility.creatorVisibleTo(creator, viewer)).toBe(true);
    });

    it('says whether a commissioner is visible to a creator', async () => {
      const avoiding = await seedCreator('술 피함', ['ALCOHOL']);
      const none = await seedCreator('원칙 없음');
      const target = (industry: IndustryCategory) => ({
        ownerId: randomUUID(),
        industry,
      });
      expect(
        await visibility.commissionerVisibleTo(target('ALCOHOL'), avoiding),
      ).toBe(false);
      expect(
        await visibility.commissionerVisibleTo(target('BEAUTY'), avoiding),
      ).toBe(true);
      expect(
        await visibility.commissionerVisibleTo(target('ALCOHOL'), none),
      ).toBe(true);
    });
  });
});
