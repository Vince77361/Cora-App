import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { CollaborationStage, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { SecretBox } from '../src/common/crypto/secret-box';
import { InstagramService } from '../src/instagram/instagram.service';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };

interface ConnectionBody {
  handle: string;
  followers: number | null;
}
interface ProfileBody {
  instagramHandle: string | null;
  instagramConnected: boolean;
  followers: number | null;
}

describe('instagram', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;

  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const begin = () => request(server).post('/instagram/connect').set(auth);
  const complete = (code: unknown) =>
    request(server)
      .post('/instagram/connect/complete')
      .set(auth)
      .send({ code });
  const getConnection = () =>
    request(server).get('/instagram/connection').set(auth);
  const disconnect = () =>
    request(server).delete('/instagram/connection').set(auth);
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;

  async function seedUser(role: 'STORE' | 'CREATOR'): Promise<string> {
    const id = randomUUID();
    await prisma.user.create({ data: { id, role } });
    return id;
  }

  // USER_A(크리에이터)가 맡은 협업을 DB에 바로 만든다.
  async function seedCollaboration(
    stage: CollaborationStage,
    settlementMethod: 'PER_VIEW' | 'NONE' = 'PER_VIEW',
  ) {
    const commissionerId = await seedUser('STORE');
    return prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage,
        commissionerId,
        creatorId: USER_A,
        terms: { format: 'REELS', rewardType: 'PER_VIEW' },
        settlementMethod,
      },
    });
  }

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

  it('rejects requests with no token', async () => {
    await request(server).post('/instagram/connect').expect(401);
    await request(server)
      .post('/instagram/connect/complete')
      .send({ code: 'x' })
      .expect(401);
    await request(server).get('/instagram/connection').expect(401);
    await request(server).delete('/instagram/connection').expect(401);
  });

  it('is for creators only', async () => {
    await setRole('STORE');
    for (const res of [
      await begin(),
      await complete('haru_cafe'),
      await getConnection(),
      await disconnect(),
    ]) {
      expect(res.status).toBe(403);
      expect(codeOf(res)).toBe('FORBIDDEN');
    }
    expect(await prisma.instagramConnection.count()).toBe(0);
  });

  it('begins a connect with the fake deep link', async () => {
    const res = await begin().expect(200);
    expect(res.body).toEqual({ connectUrl: 'cora-dev://fake-instagram' });
  });

  it('returns 404 before connecting', async () => {
    const res = await getConnection().expect(404);
    expect(codeOf(res)).toBe('NOT_FOUND');
  });

  it('connects the typed handle and stores followers', async () => {
    const res = await complete('haru_cafe').expect(200);
    expect(res.body).toEqual({ handle: 'haru_cafe', followers: 2100 });
    const read = await getConnection().expect(200);
    expect(read.body as ConnectionBody).toEqual({
      handle: 'haru_cafe',
      followers: 2100,
    });
  });

  it('stores the token sealed, never in plain text', async () => {
    await complete('haru_cafe').expect(200);
    const row = await prisma.instagramConnection.findUniqueOrThrow({
      where: { creatorId: USER_A },
    });
    expect(row.tokenEnc).not.toBeNull();
    expect(row.tokenEnc).not.toContain('fake-instagram-token');
    const box = app.get(SecretBox);
    expect(box.open(row.tokenEnc!)).toBe('fake-instagram-token-haru_cafe');
  });

  it('overwrites the profile handle and shows the connection on the profile', async () => {
    await request(server)
      .put('/creators/me')
      .set(auth)
      .send({
        displayName: '민지',
        instagramHandle: 'typed_by_hand',
        ...REGION,
      })
      .expect(200);
    await complete('haru_cafe').expect(200);
    const res = await request(server).get('/creators/me').set(auth).expect(200);
    expect(res.body as ProfileBody).toMatchObject({
      instagramHandle: 'haru_cafe',
      instagramConnected: true,
      followers: 2100,
    });
    // 연결한 뒤 프로필을 고쳐도(아이디를 빼도) 연결 표시와 연결된 아이디는 그대로다.
    const saved = await request(server)
      .put('/creators/me')
      .set(auth)
      .send({ displayName: '민지', ...REGION })
      .expect(200);
    expect(saved.body as ProfileBody).toMatchObject({
      instagramHandle: 'haru_cafe',
      instagramConnected: true,
      followers: 2100,
    });
  });

  it('keeps the connected handle when the profile is saved with another handle', async () => {
    await complete('haru_cafe').expect(200);
    await request(server)
      .put('/creators/me')
      .set(auth)
      .send({
        displayName: '민지',
        instagramHandle: 'someone_else',
        ...REGION,
      })
      .expect(200);
    const res = await request(server).get('/creators/me').set(auth).expect(200);
    expect(res.body as ProfileBody).toMatchObject({
      instagramHandle: 'haru_cafe',
      instagramConnected: true,
    });
  });

  it('gives a profile created after connecting the connected handle', async () => {
    await complete('haru_cafe').expect(200);
    const created = await request(server)
      .put('/creators/me')
      .set(auth)
      .send({ displayName: '민지', ...REGION })
      .expect(200);
    expect(created.body as ProfileBody).toMatchObject({
      instagramHandle: 'haru_cafe',
      instagramConnected: true,
      followers: 2100,
    });
  });

  it('reports a creator without a connection as not connected', async () => {
    await request(server)
      .put('/creators/me')
      .set(auth)
      .send({ displayName: '민지', ...REGION })
      .expect(200);
    const res = await request(server).get('/creators/me').set(auth).expect(200);
    expect(res.body as ProfileBody).toMatchObject({
      instagramConnected: false,
      followers: null,
    });
  });

  it('rejects a handle already connected by another creator', async () => {
    const other = await seedUser('CREATOR');
    await prisma.instagramConnection.create({
      data: { creatorId: other, handle: 'haru_cafe', refreshedAt: new Date() },
    });
    const res = await complete('haru_cafe').expect(409);
    expect(codeOf(res)).toBe('CONFLICT');
    expect(await prisma.instagramConnection.count()).toBe(1);
  });

  it('lets the same creator connect again with another handle', async () => {
    await complete('haru_cafe').expect(200);
    await complete('haru_two').expect(200);
    const rows = await prisma.instagramConnection.findMany();
    expect(rows.map((r) => r.handle)).toEqual(['haru_two']);
  });

  it('rejects a missing or empty code', async () => {
    await complete(undefined).expect(400);
    await complete('   ').expect(400);
    await complete(123).expect(400);
  });

  it('disconnects and then reports no connection', async () => {
    await complete('haru_cafe').expect(200);
    await disconnect().expect(204);
    await getConnection().expect(404);
    expect(await prisma.instagramConnection.count()).toBe(0);
    // 풀린 아이디는 다른 크리에이터가 연결할 수 있다.
    const other = await seedUser('CREATOR');
    await expect(
      app.get(InstagramService).complete(other, 'haru_cafe'),
    ).resolves.toEqual({ handle: 'haru_cafe', followers: 2100 });
    // 이미 풀렸으면 다시 풀어도 204다.
    await disconnect().expect(204);
  });

  it('lowercases the handle and treats another letter case as the same account', async () => {
    const res = await complete('@Haru_Cafe').expect(200);
    expect((res.body as ConnectionBody).handle).toBe('haru_cafe');
    const other = await seedUser('CREATOR');
    await expect(
      app.get(InstagramService).complete(other, 'HARU_CAFE'),
    ).rejects.toMatchObject({ code: 'CONFLICT' });
  });

  it('rejects a handle in a bad format with 400', async () => {
    const res = await complete('haru cafe!').expect(400);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
    expect(await prisma.instagramConnection.count()).toBe(0);
  });

  it.each(['AWAITING_PAYMENT', 'FUNDED', 'COUNTING', 'HALTED'] as const)(
    'refuses to disconnect while a per-view collaboration is %s',
    async (stage) => {
      await complete('haru_cafe').expect(200);
      await seedCollaboration(stage);
      const res = await disconnect().expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      await getConnection().expect(200);
    },
  );

  it('lets the creator disconnect when no per-view collaboration is in progress', async () => {
    await complete('haru_cafe').expect(200);
    await seedCollaboration('SETTLED');
    await seedCollaboration('CANCELLED');
    // 식사권만 있는 협업은 FUNDED여도 조회수를 읽지 않는다.
    await seedCollaboration('FUNDED', 'NONE');
    await disconnect().expect(204);
  });

  it.each(['AWAITING_PAYMENT', 'COUNTING'] as const)(
    'refuses to switch to another handle while a per-view collaboration is %s',
    async (stage) => {
      await complete('haru_cafe').expect(200);
      await seedCollaboration(stage);
      const res = await complete('haru_two').expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect((await getConnection().expect(200)).body).toMatchObject({
        handle: 'haru_cafe',
      });
    },
  );

  it('lets the creator reconnect the same handle while a per-view collaboration is in progress', async () => {
    await complete('haru_cafe').expect(200);
    await seedCollaboration('COUNTING');
    const before = await prisma.instagramConnection.findUniqueOrThrow({
      where: { creatorId: USER_A },
    });
    await complete('haru_cafe').expect(200);
    const after = await prisma.instagramConnection.findUniqueOrThrow({
      where: { creatorId: USER_A },
    });
    // 토큰을 새로 봉했다(같은 아이디를 다시 연결하는 토큰 갱신).
    expect(after.tokenEnc).not.toBe(before.tokenEnc);
  });

  it('lets the creator switch handle when nothing is in progress', async () => {
    await complete('haru_cafe').expect(200);
    await seedCollaboration('SETTLED');
    await complete('haru_two').expect(200);
    expect((await getConnection().expect(200)).body).toMatchObject({
      handle: 'haru_two',
    });
  });
});
