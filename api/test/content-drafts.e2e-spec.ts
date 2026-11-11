import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';

const auth = { Authorization: 'Bearer user-a' };
const LINKS = [
  { kind: 'NAVER_MAP', url: 'https://map.naver.com/p/entry/place/1' },
];

interface DraftBody {
  kind: string;
  bodyLabel: string;
  body: string;
  scenes: { label: string; text: string; usesPhoto: boolean }[];
  regenerationsLeftToday: number;
}

describe('content drafts', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;

  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const analyze = (links: unknown = LINKS) =>
    request(server).post('/stores/me/analyze').set(auth).send({ links });
  const list = () => request(server).get('/stores/me/content-drafts').set(auth);
  const regenerate = (kind: string) =>
    request(server)
      .post(`/stores/me/content-drafts/${kind}/regenerate`)
      .set(auth)
      .send();
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const draftsOf = (res: request.Response) => res.body as DraftBody[];

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    // 한국 시간 2026-11-11 12:00. 하루 경계 테스트는 시계를 직접 옮긴다.
    clock.set(new Date('2026-11-11T03:00:00.000Z'));
    await setRole('STORE');
    await analyze().expect(200);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).get('/stores/me/content-drafts').expect(401);
    await request(server)
      .post('/stores/me/content-drafts/BLOG/regenerate')
      .expect(401);
  });

  it('generates three drafts on first read', async () => {
    const res = await list().expect(200);
    const drafts = draftsOf(res);
    expect(drafts.map((d) => d.kind)).toEqual([
      'CARD_NEWS',
      'REELS_SCRIPT',
      'BLOG',
    ]);
    expect(drafts.every((d) => d.regenerationsLeftToday === 10)).toBe(true);
    expect(drafts[0]).toEqual({
      kind: 'CARD_NEWS',
      bodyLabel: '본문',
      body: '성수동 골목 안, 12시간 끓인 국물 한 그릇.\n오후 3시 이후엔 줄 없이 들어올 수 있어요.\n#성수라멘 #돈코츠',
      scenes: [
        { label: '1', text: '12시간 끓인\n국물 한 그릇', usesPhoto: true },
        {
          label: '2',
          text: '대표 메뉴\n돈코츠 라멘\n11,000원',
          usesPhoto: false,
        },
        { label: '3', text: '줄 없는 시간\n오후 3시 – 5시', usesPhoto: false },
      ],
      regenerationsLeftToday: 10,
    });
    expect(drafts[1].bodyLabel).toBe('촬영 순서');
    expect(drafts[2].bodyLabel).toBe('도입부');
    // 다시 읽어도 새로 만들지 않는다.
    const again = await list().expect(200);
    expect(again.body).toEqual(res.body);
    expect(await prisma.storeContentDraft.count()).toBe(3);
  });

  it('creates exactly three drafts when two first reads race', async () => {
    const results = await Promise.all([list(), list()]);
    for (const res of results) {
      expect(res.status).toBe(200);
      expect(draftsOf(res)).toHaveLength(3);
    }
    expect(await prisma.storeContentDraft.count()).toBe(3);
  });

  it('regenerates only the requested kind', async () => {
    await list().expect(200);
    const res = await regenerate('REELS_SCRIPT').expect(200);
    const draft = res.body as DraftBody;
    expect(draft.kind).toBe('REELS_SCRIPT');
    expect(draft.regenerationsLeftToday).toBe(9);
    // 가짜 구현은 다시 만들 때마다 장면 2와 3의 순서를 바꾼다.
    expect(draft.scenes.map((s) => s.label)).toEqual([
      '장면 1',
      '장면 3',
      '장면 2',
    ]);
    const rows = await prisma.storeContentDraft.findMany({
      orderBy: { kind: 'asc' },
    });
    expect(rows.map((r) => [r.kind, r.version])).toEqual([
      ['CARD_NEWS', 0],
      ['REELS_SCRIPT', 1],
      ['BLOG', 0],
    ]);
    const after = draftsOf(await list().expect(200));
    expect(after.map((d) => d.regenerationsLeftToday)).toEqual([10, 9, 10]);
    expect(after[0].scenes.map((s) => s.label)).toEqual(['1', '2', '3']);
    expect(after[1]).toEqual(draft);
  });

  it('can regenerate before the first read', async () => {
    const res = await regenerate('BLOG').expect(200);
    expect((res.body as DraftBody).regenerationsLeftToday).toBe(9);
    expect(await prisma.storeContentDraft.count()).toBe(3);
  });

  it('refuses the 11th regeneration of the day', async () => {
    for (let used = 1; used <= 10; used += 1) {
      const res = await regenerate('BLOG').expect(200);
      expect((res.body as DraftBody).regenerationsLeftToday).toBe(10 - used);
    }
    const res = await regenerate('BLOG').expect(429);
    expect(codeOf(res)).toBe('RATE_LIMITED');
    expect((res.body as { error: { message: string } }).error.message).toBe(
      '오늘은 더 만들 수 없어요.',
    );
    const row = await prisma.storeContentDraft.findFirstOrThrow({
      where: { kind: 'BLOG' },
    });
    expect(row.regenerationsOnDay).toBe(10);
    expect(row.version).toBe(10);
    // 한도는 종류마다 센다.
    await regenerate('CARD_NEWS').expect(200);
  });

  it('never lets concurrent regenerations pass the limit', async () => {
    await list().expect(200);
    const results = await Promise.all(
      Array.from({ length: 14 }, () => regenerate('REELS_SCRIPT')),
    );
    const statuses = results.map((r) => r.status);
    expect(statuses.filter((s) => s === 200)).toHaveLength(10);
    expect(statuses.filter((s) => s === 429)).toHaveLength(4);
    const row = await prisma.storeContentDraft.findFirstOrThrow({
      where: { kind: 'REELS_SCRIPT' },
    });
    expect(row.regenerationsOnDay).toBe(10);
    expect(row.version).toBe(10);
  });

  it('resets the count on the next Korean calendar day', async () => {
    // 한국 시간 2026-11-11 23:59. UTC로는 아직 같은 날 14:59다.
    clock.set(new Date('2026-11-11T14:59:00.000Z'));
    for (let i = 0; i < 10; i += 1) await regenerate('BLOG').expect(200);
    await regenerate('BLOG').expect(429);
    // 한국 시간 2026-11-12 00:00. UTC 날짜는 아직 11일이지만 한국은 12일이다.
    clock.set(new Date('2026-11-11T15:00:00.000Z'));
    const res = await regenerate('BLOG').expect(200);
    expect((res.body as DraftBody).regenerationsLeftToday).toBe(9);
    const listed = draftsOf(await list().expect(200));
    expect(listed.find((d) => d.kind === 'BLOG')?.regenerationsLeftToday).toBe(
      9,
    );
    // 읽기만 하는 다른 날에는 횟수가 다시 가득 찬다.
    clock.set(new Date('2026-11-13T00:00:00.000Z'));
    const later = draftsOf(await list().expect(200));
    expect(later.every((d) => d.regenerationsLeftToday === 10)).toBe(true);
  });

  it('keeps the drafts when the links are analyzed again', async () => {
    await list().expect(200);
    await regenerate('BLOG').expect(200);
    await analyze().expect(200);
    const after = draftsOf(await list().expect(200));
    expect(after.find((d) => d.kind === 'BLOG')?.regenerationsLeftToday).toBe(
      9,
    );
    expect(await prisma.storeContentDraft.count()).toBe(3);
  });

  it('asks for a store name when analysis found none', async () => {
    await analyze([
      { kind: 'INSTAGRAM', url: 'https://instagram.com/fail' },
    ]).expect(200);
    const res = await list().expect(409);
    expect(codeOf(res)).toBe('CONFLICT');
    expect((res.body as { error: { message: string } }).error.message).toBe(
      '가게 이름을 넣어 주세요.',
    );
    await regenerate('BLOG').expect(409);
    expect(await prisma.storeContentDraft.count()).toBe(0);
    // 이름을 고치면 만들어진다.
    await request(server)
      .patch('/stores/me')
      .set(auth)
      .send({ name: '고친 가게' })
      .expect(200);
    await list().expect(200);
  });

  it('requires the STORE role', async () => {
    await setRole('CREATOR');
    const res = await list().expect(403);
    expect(codeOf(res)).toBe('FORBIDDEN');
    await regenerate('BLOG').expect(403);
  });

  it('returns 404 when I have no store', async () => {
    await prisma.store.updateMany({ data: { deletedAt: new Date() } });
    const res = await list().expect(404);
    expect(codeOf(res)).toBe('NOT_FOUND');
    await regenerate('BLOG').expect(404);
  });

  it('rejects an unknown draft kind', async () => {
    const res = await regenerate('PODCAST').expect(400);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
    await regenerate('blog').expect(400);
  });
});
