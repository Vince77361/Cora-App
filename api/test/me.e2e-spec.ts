import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { OTHER, USER_A } from './support/fake-token-verifier';

// 아래 테스트는 앞 테스트가 저장한 역할을 이어받으므로 순서에 의존한다.
// 그래서 테스트마다가 아니라 시작할 때 한 번만 테이블을 비운다.
describe('me', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  const auth = { Authorization: 'Bearer user-a' };

  beforeAll(async () => {
    prisma = new PrismaClient();
    await truncateTestDb(prisma);
    app = await createTestApp();
    server = httpOf(app);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects a request with no token', async () => {
    const res = await request(server).get('/me').expect(401);
    expect((res.body as { error: { code: string } }).error.code).toBe(
      'UNAUTHENTICATED',
    );
  });

  it('rejects an expired token', async () => {
    await request(server)
      .get('/me')
      .set('Authorization', 'Bearer expired')
      .expect(401);
  });

  it('rejects a malformed authorization header', async () => {
    await request(server)
      .get('/me')
      .set('Authorization', 'Basic user-a')
      .expect(401);
  });

  it('creates the user on first call with a null role', async () => {
    const res = await request(server).get('/me').set(auth).expect(200);
    expect(res.body).toEqual({ id: USER_A, role: null });
  });

  it('saves the chosen role', async () => {
    await request(server)
      .patch('/me/role')
      .set(auth)
      .send({ role: 'STORE' })
      .expect(200, { id: USER_A, role: 'STORE' });
    await request(server)
      .get('/me')
      .set(auth)
      .expect(200, { id: USER_A, role: 'STORE' });
  });

  it('lets the user change role later', async () => {
    await request(server)
      .patch('/me/role')
      .set(auth)
      .send({ role: 'CREATOR' })
      .expect(200, { id: USER_A, role: 'CREATOR' });
  });

  it('rejects an unknown role and leaves the stored role unchanged', async () => {
    const res = await request(server)
      .patch('/me/role')
      .set(auth)
      .send({ role: 'ADMIN' })
      .expect(400);
    expect((res.body as { error: { code: string } }).error.code).toBe(
      'VALIDATION_FAILED',
    );
    await request(server)
      .get('/me')
      .set(auth)
      .expect(200, { id: USER_A, role: 'CREATOR' });
  });

  it('rejects fields that are not in the DTO', async () => {
    await request(server)
      .patch('/me/role')
      .set(auth)
      .send({ role: 'STORE', id: OTHER })
      .expect(400);
  });

  it('still serves /health without a token', async () => {
    await request(server).get('/health').expect(200);
  });
});
