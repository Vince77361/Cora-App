import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { StoragePort } from '../src/integrations/storage/storage.port';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeStoragePort } from './support/fake-storage.port';
import { OTHER, USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const BRAND = {
  name: '느린결',
  tagline: '느린 결, 일상의 주얼리',
  industry: 'ACCESSORY',
};

describe('brand profile', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;

  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const put = (body: Record<string, unknown>) =>
    request(server).put('/brands/me').set(auth).send(body);
  const get = () => request(server).get('/brands/me').set(auth);
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
    await request(server).get('/brands/me').expect(401);
    await request(server).put('/brands/me').expect(401);
  });

  it('only lets brands read or write the brand profile', async () => {
    await setRole('CREATOR');
    expect(codeOf(await get().expect(403))).toBe('FORBIDDEN');
    expect(codeOf(await put(BRAND).expect(403))).toBe('FORBIDDEN');
    expect(await prisma.brandProfile.count()).toBe(0);
  });

  it('returns 404 before the brand has a profile', async () => {
    await setRole('BRAND');
    expect(codeOf(await get().expect(404))).toBe('NOT_FOUND');
  });

  it('saves the profile and returns it with a null photo', async () => {
    await setRole('BRAND');
    const res = await put(BRAND).expect(200);
    const expected = { userId: USER_A, ...BRAND, photoUrl: null };
    expect(res.body).toEqual(expected);
    expect((await get().expect(200)).body).toEqual(expected);
  });

  it('replaces the whole profile on a second save without a second row', async () => {
    await setRole('BRAND');
    await put(BRAND).expect(200);
    const res = await put({ name: '새 이름', industry: 'LIVING' }).expect(200);
    expect(res.body).toEqual({
      userId: USER_A,
      name: '새 이름',
      tagline: null,
      industry: 'LIVING',
      photoUrl: null,
    });
    expect(await prisma.brandProfile.count()).toBe(1);
  });

  it('accepts a sensitive industry because the brand may be one', async () => {
    await setRole('BRAND');
    await put({ ...BRAND, industry: 'ALCOHOL' }).expect(200);
  });

  it('rejects an invalid name, tagline or industry', async () => {
    await setRole('BRAND');
    for (const bad of [
      { ...BRAND, name: '' },
      { ...BRAND, name: '   ' },
      { ...BRAND, name: 'a'.repeat(31) },
      { ...BRAND, tagline: 'a'.repeat(41) },
      { ...BRAND, industry: 'SPACE' },
      { name: BRAND.name },
      { ...BRAND, userId: OTHER },
    ]) {
      expect(codeOf(await put(bad).expect(400))).toBe('VALIDATION_FAILED');
    }
    expect(await prisma.brandProfile.count()).toBe(0);
  });

  it('turns a blank tagline into null', async () => {
    await setRole('BRAND');
    const res = await put({ ...BRAND, tagline: '  ' }).expect(200);
    expect((res.body as { tagline: string | null }).tagline).toBeNull();
  });

  it('accepts a photo uploaded for BRAND_PHOTO and returns its public url', async () => {
    await setRole('BRAND');
    const upload = await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send({
        purpose: 'BRAND_PHOTO',
        contentType: 'image/png',
        sizeBytes: 100,
      })
      .expect(201);
    const { path } = upload.body as { path: string };
    expect(path.startsWith(`brands/${USER_A}/`)).toBe(true);
    const res = await put({ ...BRAND, photoPath: path }).expect(200);
    expect((res.body as { photoUrl: string }).photoUrl).toBe(
      app.get<FakeStoragePort>(StoragePort).publicUrl(path),
    );
  });

  it("refuses somebody else's photo path and a path of another purpose", async () => {
    await setRole('BRAND');
    const uuid = '3f0d1c52-4b6e-4f5b-9d8e-0a1b2c3d4e5f';
    for (const photoPath of [
      `brands/${OTHER}/${uuid}.jpg`,
      `creators/${USER_A}/${uuid}.jpg`,
      `brands/${USER_A}/../${OTHER}/${uuid}.jpg`,
      `brands/${USER_A}/x.jpg`,
    ]) {
      expect(codeOf(await put({ ...BRAND, photoPath }).expect(403))).toBe(
        'FORBIDDEN',
      );
    }
    expect(await prisma.brandProfile.count()).toBe(0);
  });
});
