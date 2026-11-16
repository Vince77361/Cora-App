import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { PrinciplesService } from '../src/principles/principles.service';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';

const auth = { Authorization: 'Bearer user-a' };
const PRINCIPLES = {
  fields: ['FOOD_CAFE', 'BEAUTY'],
  blockedIndustries: ['ALCOHOL'],
  faceOk: true,
  scriptOk: false,
  honestReview: true,
  feeBand: 'W300K',
  trialDays: 'D7',
};

describe('creator principles', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;

  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const put = (body: Record<string, unknown>) =>
    request(server).put('/creators/me/principles').set(auth).send(body);
  const get = () => request(server).get('/creators/me/principles').set(auth);
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;

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

  it('rejects requests with no token', async () => {
    await request(server).get('/creators/me/principles').expect(401);
    await request(server).put('/creators/me/principles').expect(401);
  });

  it('only lets creators read or write principles', async () => {
    await setRole('STORE');
    expect(codeOf(await get().expect(403))).toBe('FORBIDDEN');
    expect(codeOf(await put(PRINCIPLES).expect(403))).toBe('FORBIDDEN');
    expect(await prisma.creatorPrinciples.count()).toBe(0);
  });

  it('returns 404 before the creator has set principles', async () => {
    await setRole('CREATOR');
    expect(codeOf(await get().expect(404))).toBe('NOT_FOUND');
  });

  it('saves principles and returns them', async () => {
    await setRole('CREATOR');
    const res = await put(PRINCIPLES).expect(200);
    expect(res.body).toEqual(PRINCIPLES);
    expect((await get().expect(200)).body).toEqual(PRINCIPLES);
  });

  it('replaces the whole principles on a second save without a second row', async () => {
    await setRole('CREATOR');
    await put(PRINCIPLES).expect(200);
    const next = {
      ...PRINCIPLES,
      fields: ['FASHION'],
      blockedIndustries: [],
      faceOk: false,
      feeBand: 'W500K_PLUS',
      trialDays: 'ANY',
    };
    expect((await put(next).expect(200)).body).toEqual(next);
    expect((await get().expect(200)).body).toEqual(next);
    expect(await prisma.creatorPrinciples.count()).toBe(1);
  });

  it('rejects a sensitive industry in fields and a general one in blockedIndustries', async () => {
    await setRole('CREATOR');
    const sensitiveField = await put({
      ...PRINCIPLES,
      fields: ['FOOD_CAFE', 'ALCOHOL'],
    }).expect(400);
    expect(codeOf(sensitiveField)).toBe('VALIDATION_FAILED');
    const generalBlocked = await put({
      ...PRINCIPLES,
      blockedIndustries: ['FASHION'],
    }).expect(400);
    expect(codeOf(generalBlocked)).toBe('VALIDATION_FAILED');
    expect(await prisma.creatorPrinciples.count()).toBe(0);
  });

  it('requires at least one field', async () => {
    await setRole('CREATOR');
    const res = await put({ ...PRINCIPLES, fields: [] }).expect(400);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
  });

  it('rejects repeated values, unknown values and missing columns', async () => {
    await setRole('CREATOR');
    await put({ ...PRINCIPLES, fields: ['BEAUTY', 'BEAUTY'] }).expect(400);
    await put({ ...PRINCIPLES, feeBand: 'W100K' }).expect(400);
    await put({ ...PRINCIPLES, trialDays: 'D30' }).expect(400);
    await put({ ...PRINCIPLES, faceOk: 'yes' }).expect(400);
    const { blockedIndustries, ...missing } = PRINCIPLES;
    void blockedIndustries;
    await put(missing).expect(400);
    expect(await prisma.creatorPrinciples.count()).toBe(0);
  });

  describe('updateFeeBand', () => {
    it('changes only the fee band', async () => {
      await setRole('CREATOR');
      await put(PRINCIPLES).expect(200);
      const creatorId = (await prisma.creatorPrinciples.findFirstOrThrow())
        .creatorId;
      const updated = await app
        .get(PrinciplesService)
        .updateFeeBand(creatorId, 'W500K_PLUS');
      expect(updated).toEqual({ ...PRINCIPLES, feeBand: 'W500K_PLUS' });
      expect((await get().expect(200)).body).toEqual({
        ...PRINCIPLES,
        feeBand: 'W500K_PLUS',
      });
    });

    it('returns 404 when the creator has no principles', async () => {
      await setRole('CREATOR');
      const creatorId = (await prisma.user.findFirstOrThrow()).id;
      await expect(
        app.get(PrinciplesService).updateFeeBand(creatorId, 'W200K'),
      ).rejects.toMatchObject({ code: 'NOT_FOUND' });
    });
  });
});
