import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { OTHER, USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const PHOTO = `creators/${USER_A}/33333333-3333-4333-8333-333333333333.jpg`;

describe('creators', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;

  const body = (over: Record<string, unknown> = {}) => ({
    displayName: '민지',
    regionSido: '서울특별시',
    ...over,
  });
  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const put = (over: Record<string, unknown> = {}) =>
    request(server).put('/creators/me').set(auth).send(body(over));
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    await setRole('CREATOR');
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects a request with no token', async () => {
    await request(server).get('/creators/me').expect(401);
    await request(server).put('/creators/me').send(body()).expect(401);
  });

  it('returns 404 before a profile exists', async () => {
    const res = await request(server).get('/creators/me').set(auth).expect(404);
    expect(codeOf(res)).toBe('NOT_FOUND');
  });

  it('creates then updates the profile', async () => {
    const created = await put({
      contentFocus: '카페 릴스',
      instagramHandle: 'min.closet',
      regionSigungu: '마포구',
      photoPath: PHOTO,
    }).expect(200);
    expect(created.body).toEqual({
      userId: USER_A,
      displayName: '민지',
      contentFocus: '카페 릴스',
      instagramHandle: 'min.closet',
      photoUrl: `https://fake-storage.test/public/${PHOTO}`,
      regionSido: '서울특별시',
      regionSigungu: '마포구',
      instagramConnected: false,
      followers: null,
    });
    // 전체 교체라서 빠진 선택 항목은 null이 된다.
    const updated = await put({
      displayName: '민지2',
      regionSido: '부산광역시',
    }).expect(200);
    expect(updated.body).toEqual({
      userId: USER_A,
      displayName: '민지2',
      contentFocus: null,
      instagramHandle: null,
      photoUrl: null,
      regionSido: '부산광역시',
      regionSigungu: null,
      instagramConnected: false,
      followers: null,
    });
    const got = await request(server).get('/creators/me').set(auth).expect(200);
    expect(got.body).toEqual(updated.body);
    expect(await prisma.creatorProfile.count()).toBe(1);
  });

  it('requires the CREATOR role', async () => {
    await setRole('STORE');
    const res = await put().expect(403);
    expect(codeOf(res)).toBe('FORBIDDEN');
    await request(server).get('/creators/me').set(auth).expect(403);
  });

  it('rejects an empty display name', async () => {
    await put({ displayName: '' }).expect(400);
    await put({ displayName: '   ' }).expect(400);
    await put({ displayName: 'a'.repeat(21) }).expect(400);
    await put({ displayName: 'a'.repeat(20) }).expect(200);
  });

  it('strips a leading @ from the instagram handle', async () => {
    const res = await put({ instagramHandle: '@min.closet' }).expect(200);
    expect((res.body as { instagramHandle: string }).instagramHandle).toBe(
      'min.closet',
    );
  });

  it('rejects an invalid instagram handle', async () => {
    await put({ instagramHandle: 'min closet' }).expect(400);
    await put({ instagramHandle: '@@min' }).expect(400);
    await put({ instagramHandle: 'a'.repeat(31) }).expect(400);
    await put({ instagramHandle: 'a'.repeat(30) }).expect(200);
  });

  it('rejects a content focus longer than 30 characters', async () => {
    await put({ contentFocus: 'a'.repeat(31) }).expect(400);
  });

  it('rejects a photo path under another user id', async () => {
    const res = await put({ photoPath: PHOTO.replace(USER_A, OTHER) }).expect(
      403,
    );
    expect(codeOf(res)).toBe('FORBIDDEN');
    expect(await prisma.creatorProfile.count()).toBe(0);
  });

  it('rejects a region that is not in the sido list', async () => {
    await put({ regionSido: '서울' }).expect(400);
  });

  it('requires a region', async () => {
    await request(server)
      .put('/creators/me')
      .set(auth)
      .send({ displayName: '민지' })
      .expect(400);
  });

  it('rejects a sigungu longer than 20 characters and unknown fields', async () => {
    await put({ regionSigungu: 'a'.repeat(21) }).expect(400);
    await put({ userId: OTHER }).expect(400);
  });

  it('treats a soft-deleted profile as missing', async () => {
    await put().expect(200);
    await prisma.creatorProfile.updateMany({ data: { deletedAt: new Date() } });
    await request(server).get('/creators/me').set(auth).expect(404);
  });

  describe('series', () => {
    const create = (over: Record<string, unknown> = {}) =>
      request(server)
        .post('/creators/me/series')
        .set(auth)
        .send({ name: '오늘의 한 컵', format: 'REELS', ...over });
    const list = () => request(server).get('/creators/me/series').set(auth);
    interface SeriesBody {
      id: string;
      name: string;
      format: string;
      note: string | null;
    }

    it('rejects a request with no token', async () => {
      await request(server).get('/creators/me/series').expect(401);
      await request(server).post('/creators/me/series').send({}).expect(401);
    });

    it('creates a series and lists it in creation order', async () => {
      const first = await create({ note: '아침 카페 한 컵' }).expect(201);
      expect(first.body).toEqual({
        id: expect.any(String) as string,
        name: '오늘의 한 컵',
        format: 'REELS',
        note: '아침 카페 한 컵',
      });
      await create({ name: '두 번째', format: 'BLOG' }).expect(201);
      const res = await list().expect(200);
      expect((res.body as SeriesBody[]).map((s) => [s.name, s.note])).toEqual([
        ['오늘의 한 컵', '아침 카페 한 컵'],
        ['두 번째', null],
      ]);
    });

    it('refuses a sixth series', async () => {
      for (let i = 0; i < 5; i += 1)
        await create({ name: `시리즈 ${i}` }).expect(201);
      const res = await create({ name: '여섯째' }).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect((res.body as { error: { message: string } }).error.message).toBe(
        '시리즈는 5개까지 만들 수 있어요.',
      );
      expect(await prisma.creatorSeries.count()).toBe(5);
    });

    it('never goes over five series when requests arrive together', async () => {
      const results = await Promise.all(
        Array.from({ length: 8 }, (_, i) => create({ name: `동시 ${i}` })),
      );
      expect(results.filter((r) => r.status === 201)).toHaveLength(5);
      expect(results.filter((r) => r.status === 409)).toHaveLength(3);
      expect(await prisma.creatorSeries.count()).toBe(5);
    });

    it('rejects an empty or too long name, a long note and an unknown format', async () => {
      await create({ name: '   ' }).expect(400);
      await create({ name: '가'.repeat(21) }).expect(400);
      await create({ note: '가'.repeat(21) }).expect(400);
      await create({ format: 'PODCAST' }).expect(400);
      expect(await prisma.creatorSeries.count()).toBe(0);
    });

    it('lists only my own series and needs the creator role', async () => {
      await prisma.user.create({ data: { id: OTHER, role: 'CREATOR' } });
      await prisma.creatorSeries.create({
        data: { creatorId: OTHER, name: '남의 시리즈', format: 'REELS' },
      });
      await create().expect(201);
      const res = await list().expect(200);
      expect((res.body as SeriesBody[]).map((s) => s.name)).toEqual([
        '오늘의 한 컵',
      ]);
      await setRole('STORE');
      await list().expect(403);
      await create().expect(403);
    });
  });
});
