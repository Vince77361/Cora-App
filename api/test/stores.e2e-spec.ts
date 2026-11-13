import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { StoragePort } from '../src/integrations/storage/storage.port';
import { createOffer } from './helpers/create-offer';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeStoragePort } from './support/fake-storage.port';
import { OTHER, USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const COVER = `stores/${USER_A}/33333333-3333-4333-8333-333333333333.jpg`;
const LINKS = [
  { kind: 'NAVER_MAP', url: 'https://map.naver.com/p/entry/place/1' },
  { kind: 'INSTAGRAM', url: 'https://www.instagram.com/hangeureut' },
];

interface StoreBody {
  id: string;
  status: string;
  onboardingStep: string;
  name: string | null;
  category: string | null;
  industry: string;
  neighborhood: string | null;
  regionSido: string | null;
  regionSigungu: string | null;
  coverPhotoUrl: string | null;
  signatureMenu: string | null;
  hours: string | null;
  seats: string | null;
  bestShootingTime: string | null;
  intro: string | null;
  defaultTerms: Record<string, unknown> | null;
  sourceLinks: { kind: string; url: string; summary: string | null }[];
}

describe('stores', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let storage: FakeStoragePort;
  let clock: FakeClock;

  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const analyze = (links: unknown = LINKS) =>
    request(server).post('/stores/me/analyze').set(auth).send({ links });
  const putTerms = (over: Record<string, unknown> = {}) =>
    request(server)
      .put('/stores/me/default-terms')
      .set(auth)
      .send({ format: 'REELS', reward: { voucher: {} }, ...over });
  const publish = () =>
    request(server).post('/stores/me/publish').set(auth).send();
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const storeOf = (res: request.Response) =>
    (res.body as { store: StoreBody }).store;

  // 내 가게를 분석부터 공개까지 만든다.
  async function publishMine(): Promise<StoreBody> {
    await analyze().expect(200);
    await putTerms().expect(200);
    return (await publish().expect(200)).body as StoreBody;
  }

  // 다른 사람의 가게를 DB에 바로 만든다(테스트용 로그인 사용자는 한 명뿐이다).
  async function seedStore(
    over: Partial<{
      status: 'DRAFT' | 'PUBLISHED';
      name: string;
      regionSido: string | null;
      regionSigungu: string | null;
      publishedAt: Date | null;
    }> = {},
  ): Promise<string> {
    const ownerId = randomUUID();
    await prisma.user.create({ data: { id: ownerId, role: 'STORE' } });
    const published = (over.status ?? 'PUBLISHED') === 'PUBLISHED';
    const store = await prisma.store.create({
      data: {
        ownerId,
        status: over.status ?? 'PUBLISHED',
        onboardingStep: published ? 'DONE' : 'PAGE',
        name: over.name ?? '남의 가게',
        regionSido:
          over.regionSido === undefined ? '서울특별시' : over.regionSido,
        regionSigungu: over.regionSigungu ?? null,
        defaultFormat: 'REELS',
        defaultVoucherName: '식사권',
        defaultVoucherValue: 40000,
        defaultVoucherPeople: 2,
        publishedAt: published ? (over.publishedAt ?? new Date()) : null,
      },
    });
    return store.id;
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    storage = app.get<FakeStoragePort>(StoragePort);
    clock = app.get<FakeClock>(Clock);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    storage.uploaded.length = 0;
    clock.set(new Date('2026-11-11T03:00:00.000Z'));
    await setRole('STORE');
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).get('/stores/me').expect(401);
    await request(server).post('/stores/me/analyze').send({}).expect(401);
    await request(server).get('/stores').expect(401);
    await request(server).get(`/stores/${randomUUID()}`).expect(401);
  });

  it('creates a draft store from links', async () => {
    const res = await analyze().expect(200);
    const body = res.body as { store: StoreBody; analysisFailed: boolean };
    expect(body.analysisFailed).toBe(false);
    expect(body.store).toMatchObject({
      status: 'DRAFT',
      onboardingStep: 'PAGE',
      name: '한그릇 라멘',
      category: '라멘집',
      industry: 'FOOD_CAFE',
      neighborhood: '성수동',
      regionSido: '서울특별시',
      regionSigungu: '성동구',
      signatureMenu: '돈코츠 라멘 11,000원',
      hours: '11:30 – 21:00',
      seats: '18석, 바 좌석',
      bestShootingTime: '오후 3시 – 5시',
      defaultTerms: null,
      sourceLinks: [
        {
          kind: 'NAVER_MAP',
          url: LINKS[0].url,
          summary: '사진 12장, 메뉴 8개 찾음',
        },
        {
          kind: 'INSTAGRAM',
          url: LINKS[1].url,
          summary: '게시물 9개 찾음',
        },
      ],
    });
    expect(body.store.coverPhotoUrl).toMatch(
      new RegExp(`^https://fake-storage.test/public/stores/${USER_A}/`),
    );
    const mine = await request(server).get('/stores/me').set(auth).expect(200);
    expect(mine.body).toEqual(body.store);
  });

  it('copies the cover photo into storage', async () => {
    await analyze().expect(200);
    expect(storage.uploaded).toHaveLength(1);
    const [file] = storage.uploaded;
    expect(file.path).toMatch(
      new RegExp(`^stores/${USER_A}/[0-9a-f-]{36}\\.jpg$`),
    );
    expect(file.contentType).toBe('image/jpeg');
    expect(file.bytes.subarray(0, 3)).toEqual(Buffer.from([0xff, 0xd8, 0xff]));
  });

  it('overwrites the draft when analyzed again and keeps one store', async () => {
    await analyze().expect(200);
    await putTerms().expect(200);
    await request(server)
      .patch('/stores/me')
      .set(auth)
      .send({ name: '고친 이름' })
      .expect(200);
    const again = storeOf(await analyze([LINKS[1]]).expect(200));
    expect(again.name).toBe('한그릇 라멘');
    expect(again.sourceLinks).toHaveLength(1);
    // 기본 조건은 그대로다.
    expect(again.defaultTerms).not.toBeNull();
    expect(await prisma.store.count()).toBe(1);
  });

  it('keeps one store when two analyses run at once', async () => {
    const results = await Promise.all([analyze(), analyze()]);
    for (const res of results) expect(res.status).toBe(200);
    expect(await prisma.store.count()).toBe(1);
  });

  it('falls back to an empty store when analysis fails', async () => {
    const res = await analyze([
      { kind: 'INSTAGRAM', url: 'https://www.instagram.com/fail-case' },
    ]).expect(200);
    const body = res.body as { store: StoreBody; analysisFailed: boolean };
    expect(body.analysisFailed).toBe(true);
    expect(body.store).toMatchObject({
      status: 'DRAFT',
      onboardingStep: 'PAGE',
      name: null,
      industry: 'FOOD_CAFE',
      coverPhotoUrl: null,
      sourceLinks: [
        {
          kind: 'INSTAGRAM',
          url: 'https://www.instagram.com/fail-case',
          summary: null,
        },
      ],
    });
    expect(storage.uploaded).toHaveLength(0);
  });

  it('rejects a naver link on the wrong host', async () => {
    const res = await analyze([
      { kind: 'NAVER_MAP', url: 'https://www.naver.com/' },
    ]).expect(400);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
    await analyze([
      { kind: 'NAVER_MAP', url: 'http://map.naver.com/p/1' },
    ]).expect(400);
    await analyze([
      { kind: 'NAVER_MAP', url: 'https://map.naver.com.evil.com/p/1' },
    ]).expect(400);
    await analyze([
      { kind: 'CATCHTABLE', url: 'https://map.naver.com/p/1' },
    ]).expect(400);
    expect(await prisma.store.count()).toBe(0);
  });

  it('rejects duplicate link kinds', async () => {
    await analyze([
      { kind: 'INSTAGRAM', url: 'https://instagram.com/a' },
      { kind: 'INSTAGRAM', url: 'https://instagram.com/b' },
    ]).expect(400);
  });

  it('rejects an empty list, more than three links and unknown fields', async () => {
    await analyze([]).expect(400);
    await analyze([
      ...LINKS,
      { kind: 'CATCHTABLE', url: 'https://app.catchtable.co.kr/1' },
      { kind: 'NAVER_MAP', url: 'https://naver.me/1' },
    ]).expect(400);
    await analyze([{ ...LINKS[0], extra: 1 }]).expect(400);
    await analyze('nope').expect(400);
    await analyze([{ kind: 'FACEBOOK', url: 'https://facebook.com/a' }]).expect(
      400,
    );
  });

  it('rejects analyze after publishing', async () => {
    await publishMine();
    const res = await analyze().expect(409);
    expect(codeOf(res)).toBe('CONFLICT');
  });

  it('requires the STORE role', async () => {
    await setRole('CREATOR');
    const res = await analyze().expect(403);
    expect(codeOf(res)).toBe('FORBIDDEN');
    await request(server).patch('/stores/me').set(auth).send({}).expect(403);
    await putTerms().expect(403);
    await publish().expect(403);
    await request(server)
      .post('/stores/me/onboarding-step')
      .set(auth)
      .send({ step: 'DRAFTS' })
      .expect(403);
  });

  it('returns 404 for my store before it exists', async () => {
    const res = await request(server).get('/stores/me').set(auth).expect(404);
    expect(codeOf(res)).toBe('NOT_FOUND');
    await request(server)
      .patch('/stores/me')
      .set(auth)
      .send({ name: 'x' })
      .expect(404);
    await publish().expect(404);
  });

  describe('update', () => {
    beforeEach(async () => {
      await analyze().expect(200);
    });
    const patch = (body: Record<string, unknown>) =>
      request(server).patch('/stores/me').set(auth).send(body);

    it('edits fields, trims text and turns blank text into null', async () => {
      const res = await patch({
        name: '  새 이름 ',
        hours: '   ',
        industry: 'BEAUTY',
        regionSido: '부산광역시',
        regionSigungu: '해운대구',
        coverPhotoPath: COVER,
      }).expect(200);
      expect(res.body).toMatchObject({
        name: '새 이름',
        hours: null,
        industry: 'BEAUTY',
        regionSido: '부산광역시',
        regionSigungu: '해운대구',
        coverPhotoUrl: `https://fake-storage.test/public/${COVER}`,
        seats: '18석, 바 좌석',
      });
    });

    it('rejects invalid values', async () => {
      await patch({ name: '' }).expect(400);
      await patch({ name: '   ' }).expect(400);
      await patch({ name: 'a'.repeat(31) }).expect(400);
      await patch({ name: 'a'.repeat(30) }).expect(200);
      await patch({ intro: 'a'.repeat(301) }).expect(400);
      await patch({ intro: 'a'.repeat(300) }).expect(200);
      await patch({ signatureMenu: 'a'.repeat(51) }).expect(400);
      await patch({ seats: 'a'.repeat(51) }).expect(400);
      await patch({ regionSido: '서울' }).expect(400);
      await patch({ industry: 'CASINO' }).expect(400);
      await patch({ status: 'PUBLISHED' }).expect(400);
      await patch({ ownerId: OTHER }).expect(400);
    });

    it('rejects a cover photo path under another user', async () => {
      const res = await patch({
        coverPhotoPath: COVER.replace(USER_A, OTHER),
      }).expect(403);
      expect(codeOf(res)).toBe('FORBIDDEN');
    });
  });

  describe('onboarding step', () => {
    const advance = (step: string) =>
      request(server)
        .post('/stores/me/onboarding-step')
        .set(auth)
        .send({ step });

    it('only moves forward', async () => {
      await analyze().expect(200);
      expect((await advance('DRAFTS').expect(200)).body).toMatchObject({
        onboardingStep: 'DRAFTS',
      });
      expect((await advance('TERMS').expect(200)).body).toMatchObject({
        onboardingStep: 'TERMS',
      });
      expect((await advance('DRAFTS').expect(200)).body).toMatchObject({
        onboardingStep: 'TERMS',
      });
    });

    it('rejects other steps', async () => {
      await analyze().expect(200);
      await advance('PAGE').expect(400);
      await advance('DONE').expect(400);
    });
  });

  describe('default terms', () => {
    beforeEach(async () => {
      await analyze().expect(200);
    });

    it('saves the default terms as three reward elements', async () => {
      const res = await putTerms({
        reward: { voucher: {}, perView: {} },
      }).expect(200);
      expect((res.body as StoreBody).defaultTerms).toEqual({
        format: 'REELS',
        pieces: 1,
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        fixedCash: 0,
        viewRatePerThousand: 2000,
        perViewCap: 60000,
        usageRights: 'STORE_REPOST_3M',
        maxCashBurden: 60000,
        settlementMethod: 'PER_VIEW',
      });
      const perView = await putTerms({
        reward: { perView: { ratePerThousand: 3000, cap: 100000 } },
        usageRights: 'STORE_REPOST_6M',
      }).expect(200);
      expect((perView.body as StoreBody).defaultTerms).toMatchObject({
        voucherName: null,
        voucherValue: null,
        voucherPeople: null,
        viewRatePerThousand: 3000,
        perViewCap: 100000,
        usageRights: 'STORE_REPOST_6M',
      });
    });

    it('fills 2000 won per thousand and a 60000 cap when view pay is on without values', async () => {
      const res = await putTerms({ reward: { perView: {} } }).expect(200);
      expect((res.body as StoreBody).defaultTerms).toMatchObject({
        viewRatePerThousand: 2000,
        perViewCap: 60000,
      });
    });

    it('returns the maximum cash burden with the default terms', async () => {
      const both = await putTerms({
        reward: { voucher: {}, perView: { cap: 80000 } },
      }).expect(200);
      expect((both.body as StoreBody).defaultTerms).toMatchObject({
        maxCashBurden: 80000,
        settlementMethod: 'PER_VIEW',
      });
      const voucherOnly = await putTerms().expect(200);
      expect((voucherOnly.body as StoreBody).defaultTerms).toMatchObject({
        maxCashBurden: 0,
        settlementMethod: 'NONE',
      });
      // 저장한 값이 다시 읽혀도 같다.
      const mine = await request(server)
        .get('/stores/me')
        .set(auth)
        .expect(200);
      expect((mine.body as StoreBody).defaultTerms).toMatchObject({
        maxCashBurden: 0,
      });
    });

    it('rejects invalid terms', async () => {
      const blog = await putTerms({
        format: 'BLOG',
        reward: { perView: {} },
      }).expect(400);
      expect(codeOf(blog)).toBe('VALIDATION_FAILED');
      await putTerms({ reward: { voucher: { name: '' } } }).expect(400);
      await putTerms({ reward: { voucher: { name: 'a'.repeat(21) } } }).expect(
        400,
      );
      await putTerms({ reward: { voucher: { value: 999 } } }).expect(400);
      await putTerms({ reward: { voucher: { value: 1000001 } } }).expect(400);
      await putTerms({ reward: { voucher: { value: 1000 } } }).expect(200);
      await putTerms({ reward: { voucher: { people: 0 } } }).expect(400);
      await putTerms({ format: 'PODCAST' }).expect(400);
      // 범위와 단위: 단가 1,000~5,000원(500원 단위), 상한 10,000~300,000원(10,000원 단위).
      await putTerms({ reward: { perView: { ratePerThousand: 50 } } }).expect(
        400,
      );
      await putTerms({
        reward: { perView: { ratePerThousand: 5500 } },
      }).expect(400);
      await putTerms({
        reward: { perView: { ratePerThousand: 1250 } },
      }).expect(400);
      await putTerms({ reward: { perView: { cap: 5000 } } }).expect(400);
      await putTerms({ reward: { perView: { cap: 15000 } } }).expect(400);
      await putTerms({ reward: { perView: { cap: 310000 } } }).expect(400);
      await putTerms({
        reward: { perView: { ratePerThousand: 1500, cap: 300000 } },
      }).expect(200);
      // 보상이 하나도 없거나 옛 모양으로 보내면 받지 않는다.
      await putTerms({ reward: {} }).expect(400);
      await putTerms({ rewardType: 'BOTH', reward: undefined }).expect(400);
    });

    it('saves fixed cash as part of the default terms and rejects it outside the range', async () => {
      const ok = await putTerms({
        reward: { voucher: {}, fixedCash: 30000 },
      }).expect(200);
      expect((ok.body as StoreBody).defaultTerms).toMatchObject({
        fixedCash: 30000,
        maxCashBurden: 30000,
        settlementMethod: 'FIXED',
      });
      for (const fixedCash of [5000, 35000, 1010000]) {
        const res = await putTerms({
          reward: { voucher: {}, fixedCash },
        }).expect(400);
        expect(codeOf(res)).toBe('VALIDATION_FAILED');
      }
    });
  });

  describe('publish', () => {
    it('rejects publishing without default terms', async () => {
      await analyze().expect(200);
      const res = await publish().expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
    });

    it('rejects publishing without a name', async () => {
      await analyze([
        { kind: 'INSTAGRAM', url: 'https://instagram.com/fail' },
      ]).expect(200);
      await putTerms().expect(200);
      await request(server)
        .patch('/stores/me')
        .set(auth)
        .send({ regionSido: '서울특별시' })
        .expect(200);
      await publish().expect(409);
    });

    it('rejects publishing without a region', async () => {
      await analyze([
        { kind: 'INSTAGRAM', url: 'https://instagram.com/fail' },
      ]).expect(200);
      await putTerms().expect(200);
      await request(server)
        .patch('/stores/me')
        .set(auth)
        .send({ name: '이름만 있는 가게' })
        .expect(200);
      const res = await publish().expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      await request(server)
        .patch('/stores/me')
        .set(auth)
        .send({ regionSido: '경기도' })
        .expect(200);
      await publish().expect(200);
    });

    it('publishes once name and terms exist', async () => {
      const store = await publishMine();
      expect(store).toMatchObject({
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
      });
      const row = await prisma.store.findUniqueOrThrow({
        where: { id: store.id },
      });
      expect(row.publishedAt).toEqual(new Date('2026-11-11T03:00:00.000Z'));
      // 두 번째는 아무것도 바꾸지 않는다.
      clock.advance(3_600_000);
      await publish().expect(200);
      const again = await prisma.store.findUniqueOrThrow({
        where: { id: store.id },
      });
      expect(again.publishedAt).toEqual(row.publishedAt);
    });

    it('still lets the owner edit after publishing', async () => {
      await publishMine();
      const res = await request(server)
        .patch('/stores/me')
        .set(auth)
        .send({ intro: '공개 뒤에 고친 소개' })
        .expect(200);
      expect((res.body as StoreBody).intro).toBe('공개 뒤에 고친 소개');
      await putTerms({ reward: { perView: {} } }).expect(200);
    });
  });

  describe('public list and detail', () => {
    it('lists only published stores and excludes my own', async () => {
      const older = await seedStore({
        name: '오래된 가게',
        publishedAt: new Date('2026-11-01T00:00:00.000Z'),
      });
      const newer = await seedStore({
        name: '새 가게',
        publishedAt: new Date('2026-11-05T00:00:00.000Z'),
      });
      await seedStore({ status: 'DRAFT', name: '등록 중' });
      await publishMine();

      const res = await request(server).get('/stores').set(auth).expect(200);
      const list = res.body as {
        id: string;
        name: string;
        defaultTerms: Record<string, unknown>;
      }[];
      expect(list.map((s) => s.id)).toEqual([newer, older]);
      expect(list[0]).toEqual({
        id: newer,
        name: '새 가게',
        category: null,
        industry: 'FOOD_CAFE',
        neighborhood: null,
        regionSido: '서울특별시',
        regionSigungu: null,
        coverPhotoUrl: null,
        defaultTerms: {
          format: 'REELS',
          pieces: 1,
          voucherName: '식사권',
          voucherValue: 40000,
          voucherPeople: 2,
          fixedCash: 0,
          viewRatePerThousand: null,
          perViewCap: null,
          usageRights: 'STORE_REPOST_3M',
          maxCashBurden: 0,
          settlementMethod: 'NONE',
        },
      });
    });

    it('lists stores in my district first, then my province', async () => {
      const otherProvince = await seedStore({
        regionSido: '부산광역시',
        regionSigungu: '마포구',
        publishedAt: new Date('2026-11-09T00:00:00.000Z'),
      });
      const sameProvince = await seedStore({
        regionSido: '서울특별시',
        regionSigungu: '강남구',
        publishedAt: new Date('2026-11-08T00:00:00.000Z'),
      });
      const sameDistrictOld = await seedStore({
        regionSido: '서울특별시',
        regionSigungu: '마포구',
        publishedAt: new Date('2026-11-01T00:00:00.000Z'),
      });
      const sameDistrictNew = await seedStore({
        regionSido: '서울특별시',
        regionSigungu: '마포구',
        publishedAt: new Date('2026-11-02T00:00:00.000Z'),
      });
      const sameProvinceNoDistrict = await seedStore({
        regionSido: '서울특별시',
        regionSigungu: null,
        publishedAt: new Date('2026-11-07T00:00:00.000Z'),
      });
      await setRole('CREATOR');
      await request(server)
        .put('/creators/me')
        .set(auth)
        .send({
          displayName: '민지',
          regionSido: '서울특별시',
          regionSigungu: '마포구',
        })
        .expect(200);

      const res = await request(server).get('/stores').set(auth).expect(200);
      expect((res.body as { id: string }[]).map((s) => s.id)).toEqual([
        sameDistrictNew,
        sameDistrictOld,
        sameProvince,
        sameProvinceNoDistrict,
        otherProvince,
      ]);
    });

    it('lists by recency only when I have no creator profile', async () => {
      const a = await seedStore({
        publishedAt: new Date('2026-11-01T00:00:00Z'),
      });
      const b = await seedStore({
        regionSido: '부산광역시',
        publishedAt: new Date('2026-11-02T00:00:00Z'),
      });
      const res = await request(server).get('/stores').set(auth).expect(200);
      expect((res.body as { id: string }[]).map((s) => s.id)).toEqual([b, a]);
    });

    it('hides a draft store from other users', async () => {
      const draft = await seedStore({ status: 'DRAFT' });
      const res = await request(server)
        .get(`/stores/${draft}`)
        .set(auth)
        .expect(404);
      expect(codeOf(res)).toBe('NOT_FOUND');
    });

    it('hides my own draft from the public detail', async () => {
      const mine = storeOf(await analyze().expect(200));
      await request(server).get(`/stores/${mine.id}`).set(auth).expect(404);
    });

    it('returns 404 for an unknown or malformed id and a deleted store', async () => {
      await request(server)
        .get(`/stores/${randomUUID()}`)
        .set(auth)
        .expect(404);
      await request(server).get('/stores/not-a-uuid').set(auth).expect(404);
      const gone = await seedStore();
      await prisma.store.update({
        where: { id: gone },
        data: { deletedAt: new Date() },
      });
      await request(server).get(`/stores/${gone}`).set(auth).expect(404);
      const list = await request(server).get('/stores').set(auth).expect(200);
      expect(list.body).toEqual([]);
    });

    it('shows the published detail, including mine', async () => {
      const other = await seedStore({ name: '남의 가게' });
      const res = await request(server)
        .get(`/stores/${other}`)
        .set(auth)
        .expect(200);
      expect(res.body).toMatchObject({
        id: other,
        name: '남의 가게',
        defaultTerms: { format: 'REELS' },
        signatureMenu: null,
        hours: null,
        seats: null,
        bestShootingTime: null,
        intro: null,
        myApplicationStatus: 'NONE',
      });
      const mine = await publishMine();
      const preview = await request(server)
        .get(`/stores/${mine.id}`)
        .set(auth)
        .expect(200);
      expect(preview.body).toMatchObject({
        id: mine.id,
        name: '한그릇 라멘',
        signatureMenu: '돈코츠 라멘 11,000원',
        myApplicationStatus: 'NONE',
      });
    });

    it('does not leak source links or the owner id', async () => {
      const mine = await publishMine();
      const res = await request(server)
        .get(`/stores/${mine.id}`)
        .set(auth)
        .expect(200);
      expect(res.body).not.toHaveProperty('sourceLinks');
      expect(res.body).not.toHaveProperty('ownerId');
      expect(res.body).not.toHaveProperty('status');
    });

    it('shows my application status on the detail', async () => {
      // 지원 기능(6번 작업)이 생기기 전까지는 항상 NONE이다.
      const other = await seedStore();
      const res = await request(server).get(`/stores/${other}`).set(auth);
      expect(
        (res.body as { myApplicationStatus: string }).myApplicationStatus,
      ).toBe('NONE');
    });

    describe('my open offer', () => {
      interface OpenOfferBody {
        myOpenOffer: {
          id: string;
          latestVersion: number;
          myTurn: boolean;
        } | null;
      }
      const openOffer = async (storeId: string) =>
        (
          (
            await request(server)
              .get(`/stores/${storeId}`)
              .set(auth)
              .expect(200)
          ).body as OpenOfferBody
        ).myOpenOffer;
      const seedOffer = async (
        storeId: string,
        over: Partial<{
          status: 'SENT' | 'ACCEPTED' | 'DECLINED' | 'EXPIRED';
          turn: 'STORE' | 'CREATOR';
          expiresAt: Date;
          closedAt: Date;
          creatorId: string;
        }> = {},
      ) => {
        await prisma.creatorProfile.upsert({
          where: { userId: USER_A },
          create: {
            userId: USER_A,
            displayName: '하루 한 컵',
            regionSido: '서울특별시',
          },
          update: {},
        });
        return createOffer(prisma, {
          storeId,
          creatorId: over.creatorId ?? USER_A,
          status: over.status ?? 'SENT',
          turn: over.turn ?? 'CREATOR',
          expiresAt:
            over.expiresAt ?? new Date(clock.now().getTime() + 86400000),
          closedAt: over.closedAt,
          voucherName: '식사권',
          voucherValue: 40000,
          voucherPeople: 2,
        });
      };

      it('is null when there is no open offer and tells whose turn it is otherwise', async () => {
        const store = await seedStore();
        expect(await openOffer(store)).toBeNull();
        const offer = await seedOffer(store, { turn: 'CREATOR' });
        expect(await openOffer(store)).toEqual({
          id: offer.id,
          latestVersion: 1,
          myTurn: true,
        });
        await prisma.offer.update({
          where: { id: offer.id },
          data: { turn: 'STORE', latestVersion: 2 },
        });
        expect(await openOffer(store)).toEqual({
          id: offer.id,
          latestVersion: 2,
          myTurn: false,
        });
      });

      it('shows an accepted offer as not my turn and hides ended ones', async () => {
        const store = await seedStore();
        const accepted = await seedOffer(store, { status: 'ACCEPTED' });
        expect(await openOffer(store)).toEqual({
          id: accepted.id,
          latestVersion: 1,
          myTurn: false,
        });
        // 협업이 끝나 닫힌 오퍼는 열린 것이 아니다.
        await prisma.offer.update({
          where: { id: accepted.id },
          data: { closedAt: clock.now() },
        });
        expect(await openOffer(store)).toBeNull();
      });

      it('hides an offer past its deadline and offers of other stores or people', async () => {
        const store = await seedStore();
        const elsewhere = await seedStore({ name: '다른 가게' });
        await seedOffer(store, {
          expiresAt: new Date(clock.now().getTime() - 1000),
        });
        await seedOffer(elsewhere);
        const stranger = randomUUID();
        await prisma.user.create({ data: { id: stranger, role: 'CREATOR' } });
        await seedOffer(store, { creatorId: stranger });
        expect(await openOffer(store)).toBeNull();
        expect(await openOffer(elsewhere)).not.toBeNull();
      });
    });
  });
});
