import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { StoragePort } from '../src/integrations/storage/storage.port';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeStoragePort } from './support/fake-storage.port';
import { USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const MB5 = 5 * 1024 * 1024;

describe('uploads', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let storage: FakeStoragePort;

  const body = (over: Record<string, unknown> = {}) => ({
    purpose: 'STORE_COVER',
    contentType: 'image/jpeg',
    sizeBytes: 1024,
    ...over,
  });
  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;

  beforeAll(async () => {
    prisma = new PrismaClient();
    await truncateTestDb(prisma);
    app = await createTestApp();
    server = httpOf(app);
    storage = app.get<FakeStoragePort>(StoragePort);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });
  beforeEach(() => {
    storage.uploadUrlPaths.length = 0;
  });

  it('rejects a request with no token', async () => {
    await request(server).post('/uploads/photos').send(body()).expect(401);
  });

  it('issues an upload url and a path under the caller id for a store cover', async () => {
    await setRole('STORE');
    const res = await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body())
      .expect(201);
    const { uploadUrl, path } = res.body as { uploadUrl: string; path: string };
    expect(path.startsWith(`stores/${USER_A}/`)).toBe(true);
    expect(path.endsWith('.jpg')).toBe(true);
    expect(uploadUrl).toContain(path);
    expect(Object.keys(res.body as object).sort()).toEqual([
      'path',
      'uploadUrl',
    ]);
  });

  it('rejects a content type that is not jpeg, png or heic', async () => {
    await setRole('STORE');
    const res = await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body({ contentType: 'image/gif' }))
      .expect(400);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
    expect(storage.uploadUrlPaths).toHaveLength(0);
  });

  it('rejects a file larger than 5MB and accepts exactly 5MB', async () => {
    await setRole('STORE');
    const big = await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body({ sizeBytes: MB5 + 1 }))
      .expect(400);
    expect(codeOf(big)).toBe('VALIDATION_FAILED');
    await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body({ sizeBytes: MB5 }))
      .expect(201);
  });

  it('rejects a non-integer size and an unknown purpose', async () => {
    await setRole('STORE');
    await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body({ sizeBytes: 1.5 }))
      .expect(400);
    await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body({ purpose: 'AVATAR' }))
      .expect(400);
  });

  it('rejects fields that are not in the DTO', async () => {
    await setRole('STORE');
    await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body({ path: 'stores/other/x.jpg' }))
      .expect(400);
  });

  it('requires the STORE role for a store cover', async () => {
    await setRole('CREATOR');
    const res = await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body())
      .expect(403);
    expect(codeOf(res)).toBe('FORBIDDEN');
    expect(storage.uploadUrlPaths).toHaveLength(0);
  });

  it('requires the CREATOR role for a creator photo', async () => {
    await setRole('STORE');
    const res = await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body({ purpose: 'CREATOR_PHOTO' }))
      .expect(403);
    expect(codeOf(res)).toBe('FORBIDDEN');
    await setRole('CREATOR');
    const ok = await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send(body({ purpose: 'CREATOR_PHOTO', contentType: 'image/heic' }))
      .expect(201);
    const path = (ok.body as { path: string }).path;
    expect(path.startsWith(`creators/${USER_A}/`)).toBe(true);
    expect(path.endsWith('.heic')).toBe(true);
  });
});

// 한도 상태는 앱(모듈)마다 따로이므로, 위 테스트와 섞이지 않게 새 앱으로 확인한다.
describe('uploads rate limit', () => {
  let app: INestApplication;
  let prisma: PrismaClient;

  beforeAll(async () => {
    prisma = new PrismaClient();
    await truncateTestDb(prisma);
    app = await createTestApp();
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('answers 429 RATE_LIMITED on the 31st request within an hour', async () => {
    const server = httpOf(app);
    await request(server)
      .patch('/me/role')
      .set(auth)
      .send({ role: 'STORE' })
      .expect(200);
    const send = () =>
      request(server).post('/uploads/photos').set(auth).send({
        purpose: 'STORE_COVER',
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      });
    for (let i = 0; i < 30; i++) await send().expect(201);
    const res = await send().expect(429);
    expect((res.body as { error: { code: string } }).error.code).toBe(
      'RATE_LIMITED',
    );
  });
});
