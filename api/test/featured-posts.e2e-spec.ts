import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { StoragePort } from '../src/integrations/storage/storage.port';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeStoragePort } from './support/fake-storage.port';
import { OTHER, USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const authB = { Authorization: 'Bearer user-b' };

describe('featured posts', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let storage: FakeStoragePort;

  const setRole = (
    headers: Record<string, string>,
    role: 'STORE' | 'CREATOR' | 'BRAND',
  ) =>
    request(server).patch('/me/role').set(headers).send({ role }).expect(200);
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;

  // 앱이 하는 대로: POST /uploads/photos로 경로를 받고(PUT은 가짜 저장소가 올린 것으로 본다) 그 경로를 저장 요청에 담는다.
  async function uploadPath(headers = auth): Promise<string> {
    const res = await request(server)
      .post('/uploads/photos')
      .set(headers)
      .send({
        purpose: 'FEATURED_POST',
        contentType: 'image/jpeg',
        sizeBytes: 1000,
      })
      .expect(201);
    return (res.body as { path: string }).path;
  }
  async function gallery(caption: string, headers = auth) {
    return {
      source: 'GALLERY',
      kind: 'PHOTO',
      mediaPath: await uploadPath(headers),
      caption,
    };
  }
  const put = (items: unknown[], headers = auth) =>
    request(server)
      .put('/creators/me/featured-posts')
      .set(headers)
      .send({ items });

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    storage = app.get<FakeStoragePort>(StoragePort);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    await setRole(auth, 'CREATOR');
    await setRole(authB, 'CREATOR');
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects a request with no token', async () => {
    await request(server).get('/creators/me/featured-posts').expect(401);
    await request(server)
      .put('/creators/me/featured-posts')
      .send({ items: [] })
      .expect(401);
  });

  it('issues FEATURED_POST upload paths under featured-posts/<user id>/ only for creators', async () => {
    const path = await uploadPath();
    expect(path.startsWith(`featured-posts/${USER_A}/`)).toBe(true);
    expect(storage.uploadUrlBuckets.at(-1)).toBe('photos');
    await setRole(auth, 'STORE');
    await request(server)
      .post('/uploads/photos')
      .set(auth)
      .send({
        purpose: 'FEATURED_POST',
        contentType: 'image/jpeg',
        sizeBytes: 1000,
      })
      .expect(403);
  });

  it('lets a creator put and get the list in order', async () => {
    expect(
      (
        await request(server)
          .get('/creators/me/featured-posts')
          .set(auth)
          .expect(200)
      ).body,
    ).toEqual([]);

    const saved = await put([
      await gallery('하나'),
      await gallery('둘'),
    ]).expect(200);
    const body = saved.body as {
      id: string;
      position: number;
      caption: string;
      photoUrl: string;
    }[];
    expect(body.map((p) => [p.position, p.caption])).toEqual([
      [1, '하나'],
      [2, '둘'],
    ]);
    expect(body[0].photoUrl).toMatch(
      /^https:\/\/fake-storage\.test\/public\/featured-posts\//,
    );
    const got = await request(server)
      .get('/creators/me/featured-posts')
      .set(auth)
      .expect(200);
    expect(got.body).toEqual(body);

    // 둘째를 앞으로 보내고 첫째를 빼면 둘째가 1번이다. 빈 틈은 생기지 않는다.
    const moved = await put([{ id: body[1].id }]).expect(200);
    expect(
      (moved.body as { id: string; position: number }[]).map((p) => [
        p.id,
        p.position,
      ]),
    ).toEqual([[body[1].id, 1]]);
    expect(
      await prisma.featuredPost.count({ where: { deletedAt: null } }),
    ).toBe(1);
    expect(await prisma.featuredPost.count()).toBe(2);
  });

  it('rejects a fifth post with 400', async () => {
    const five = [
      await gallery('1'),
      await gallery('2'),
      await gallery('3'),
      await gallery('4'),
      await gallery('5'),
    ];
    const res = await put(five).expect(400);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
    await put(five.slice(0, 4)).expect(200);
  });

  it('rejects a caption over 40 characters, a gallery video and a gallery post without a caption', async () => {
    await put([await gallery('가'.repeat(41))]).expect(400);
    await put([{ ...(await gallery('영상')), kind: 'VIDEO' }]).expect(400);
    await put([await gallery('   ')]).expect(400);
    await put([{ source: 'GALLERY' }]).expect(400);
    expect(await prisma.featuredPost.count()).toBe(0);
  });

  it('keeps the same instagram media id from being featured twice', async () => {
    const insta = async () => ({
      source: 'INSTAGRAM',
      kind: 'PHOTO',
      mediaPath: await uploadPath(),
      caption: '인스타 글',
      instagramMediaId: 'fake-post-1',
    });
    await put([await insta(), await insta()]).expect(400);
    await put([await insta()]).expect(200);
    // 빼면 다시 가져올 수 있다.
    await put([]).expect(200);
    await put([await insta()]).expect(200);
  });

  it('forbids stores and brands', async () => {
    await setRole(auth, 'STORE');
    expect(
      codeOf(
        await request(server)
          .get('/creators/me/featured-posts')
          .set(auth)
          .expect(403),
      ),
    ).toBe('FORBIDDEN');
    await put([]).expect(403);
    await setRole(auth, 'BRAND');
    await put([]).expect(403);
  });

  it("rejects another creator's upload path with 400", async () => {
    const foreign = await uploadPath(authB);
    expect(foreign.startsWith(`featured-posts/${OTHER}/`)).toBe(true);
    const res = await put([
      {
        source: 'GALLERY',
        kind: 'PHOTO',
        mediaPath: foreign,
        caption: '남의 사진',
      },
    ]).expect(400);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
    // 다른 폴더(카드 사진)의 내 경로도 못 쓴다.
    await put([
      {
        source: 'GALLERY',
        kind: 'PHOTO',
        mediaPath: `creator-cards/${USER_A}/${randomUUID()}.jpg`,
        caption: '다른 폴더',
      },
    ]).expect(400);
    expect(await prisma.featuredPost.count()).toBe(0);
  });

  it("returns 404 for another creator's post id", async () => {
    const theirs = await put([await gallery('남의 것', authB)], authB).expect(
      200,
    );
    const id = (theirs.body as { id: string }[])[0].id;
    const res = await put([{ id }]).expect(404);
    expect(codeOf(res)).toBe('NOT_FOUND');
    // 남의 게시물은 그대로다.
    expect(
      await prisma.featuredPost.count({
        where: { creatorId: OTHER, deletedAt: null },
      }),
    ).toBe(1);
  });

  it('rejects an unknown body shape', async () => {
    await request(server)
      .put('/creators/me/featured-posts')
      .set(auth)
      .send({})
      .expect(400);
    await put([{ id: 'not-a-uuid' }]).expect(400);
  });

  it('shows the first post on the profile card copy used by hearts', async () => {
    await request(server)
      .put('/creators/me')
      .set(auth)
      .send({ displayName: '민지', regionSido: '서울특별시' })
      .expect(200);
    await put([await gallery('첫 장')]).expect(200);
    const profile = await request(server)
      .get('/creators/me')
      .set(auth)
      .expect(200);
    expect(profile.body).toMatchObject({ cardHeadline: '첫 장' });
  });
});
