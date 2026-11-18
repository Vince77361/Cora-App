import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { Clock } from '../../src/common/clock';
import { FeaturedPostsRepository } from '../../src/creators/featured-posts.repository';
import type { PrismaService } from '../../src/prisma/prisma.service';
import { FakeClock } from '../support/fake-clock';
import { prisma } from './setup-db';

const CREATOR = '77777777-7777-4777-8777-777777777771';
const CREATOR_2 = '77777777-7777-4777-8777-777777777772';
const MIGRATION = join(
  __dirname,
  '../../prisma/migrations/20261118174630_featured_posts/migration.sql',
);

function uniqueOn(...columns: string[]) {
  return { code: 'P2002', meta: { target: columns } };
}

beforeEach(async () => {
  await prisma.user.createMany({
    data: [
      { id: CREATOR, role: 'CREATOR' },
      { id: CREATOR_2, role: 'CREATOR' },
    ],
  });
});

function post(over: Record<string, unknown> = {}) {
  return {
    creatorId: CREATOR,
    position: 1,
    source: 'GALLERY' as const,
    kind: 'PHOTO' as const,
    mediaPath: `featured-posts/${CREATOR}/a.jpg`,
    caption: '한 줄',
    ...over,
  };
}

describe('featured_posts', () => {
  it('keeps the position unique per creator among live rows only', async () => {
    await prisma.featuredPost.create({ data: post() });
    await expect(
      prisma.featuredPost.create({ data: post() }),
    ).rejects.toMatchObject(uniqueOn('creator_id', 'position'));
    // 다른 크리에이터의 1번은 따로다.
    await prisma.featuredPost.create({ data: post({ creatorId: CREATOR_2 }) });
    // 지운 행은 자리를 비운다.
    await prisma.featuredPost.updateMany({
      where: { creatorId: CREATOR },
      data: { deletedAt: new Date() },
    });
    await prisma.featuredPost.create({ data: post() });
    await prisma.featuredPost.create({ data: post({ position: 2 }) });
    expect(
      await prisma.featuredPost.count({
        where: { creatorId: CREATOR, deletedAt: null },
      }),
    ).toBe(2);
  });

  it('allows an instagram media id once per creator among live rows', async () => {
    const insta = (over: Record<string, unknown> = {}) =>
      post({ source: 'INSTAGRAM', instagramMediaId: 'fake-post-1', ...over });
    await prisma.featuredPost.create({ data: insta() });
    await expect(
      prisma.featuredPost.create({ data: insta({ position: 2 }) }),
    ).rejects.toMatchObject(uniqueOn('creator_id', 'instagram_media_id'));
    // 다른 크리에이터는 같은 원본 ID를 가져올 수 있다.
    await prisma.featuredPost.create({
      data: insta({ creatorId: CREATOR_2 }),
    });
    // 지운 뒤에는 다시 가져올 수 있다.
    await prisma.featuredPost.updateMany({
      where: { creatorId: CREATOR },
      data: { deletedAt: new Date() },
    });
    await prisma.featuredPost.create({ data: insta() });
    // ID가 없는 게시물(사진첩)은 여럿이어도 된다.
    await prisma.featuredPost.create({ data: post({ position: 2 }) });
    await prisma.featuredPost.create({ data: post({ position: 3 }) });
  });

  it('refuses a position below one and a caption over 40 characters', async () => {
    await expect(
      prisma.featuredPost.create({ data: post({ position: 0 }) }),
    ).rejects.toThrow(/featured_posts_position_positive/);
    await expect(
      prisma.featuredPost.create({ data: post({ caption: '가'.repeat(41) }) }),
    ).rejects.toThrow(/featured_posts_caption_length/);
  });

  it('moves a profile with an old card photo to post number one (gallery photo)', async () => {
    const OLD_PHOTO = `creator-cards/${CREATOR}/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.jpg`;
    await prisma.creatorProfile.createMany({
      data: [
        {
          userId: CREATOR,
          displayName: '민지',
          regionSido: '서울특별시',
          cardHeadline: '  카페 릴스 전문  ',
          cardPhotoPath: OLD_PHOTO,
        },
        // 한 줄이 없는 카드 사진은 옮기지 않는다.
        {
          userId: CREATOR_2,
          displayName: '하나',
          regionSido: '서울특별시',
          cardPhotoPath: OLD_PHOTO,
        },
      ],
    });
    // 마이그레이션의 옮기는 문장만 다시 돌린다(테이블은 이미 있다).
    const sql = readFileSync(MIGRATION, 'utf8');
    await prisma.$executeRawUnsafe(sql.slice(sql.indexOf('INSERT INTO')));

    const rows = await prisma.featuredPost.findMany();
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({
      creatorId: CREATOR,
      position: 1,
      source: 'GALLERY',
      kind: 'PHOTO',
      mediaPath: OLD_PHOTO,
      caption: '카페 릴스 전문',
      thumbnailPath: null,
      instagramMediaId: null,
      deletedAt: null,
    });
    // 옛 열은 그대로 남는다.
    expect(
      (
        await prisma.creatorProfile.findFirstOrThrow({
          where: { userId: CREATOR },
        })
      ).cardPhotoPath,
    ).toBe(OLD_PHOTO);
  });

  it('turns on row level security with no policy', async () => {
    const [table] = await prisma.$queryRaw<
      { relrowsecurity: boolean }[]
    >`SELECT relrowsecurity FROM pg_class WHERE oid = to_regclass('featured_posts')`;
    expect(table.relrowsecurity).toBe(true);
    const policies = await prisma.$queryRaw<
      unknown[]
    >`SELECT 1 FROM pg_policies WHERE tablename = 'featured_posts' AND schemaname = current_schema()`;
    expect(policies).toHaveLength(0);
  });
});

describe('FeaturedPostsRepository.replace', () => {
  const repo = () =>
    new FeaturedPostsRepository(prisma as unknown as PrismaService);
  const draft = (name: string) => ({
    source: 'GALLERY' as const,
    kind: 'PHOTO' as const,
    mediaPath: `featured-posts/${CREATOR}/${name}.jpg`,
    thumbnailPath: null,
    caption: name,
    instagramMediaId: null,
  });
  const now: Clock = new FakeClock(new Date('2026-11-19T00:00:00Z'));

  it('swaps two kept posts without tripping the unique position', async () => {
    const [a, b] = await repo()
      .replace(
        CREATOR,
        [{ draft: draft('a') }, { draft: draft('b') }],
        now.now(),
      )
      .then((rows) => rows ?? []);
    const swapped = await repo().replace(
      CREATOR,
      [{ keepId: b.id }, { keepId: a.id }],
      now.now(),
    );
    expect(swapped?.map((r) => [r.id, r.position])).toEqual([
      [b.id, 1],
      [a.id, 2],
    ]);
  });

  it('returns null and changes nothing when a kept id is not live', async () => {
    await repo().replace(CREATOR, [{ draft: draft('a') }], now.now());
    const before = await prisma.featuredPost.findMany();
    const result = await repo().replace(
      CREATOR,
      [{ keepId: '99999999-9999-4999-8999-999999999999' }],
      now.now(),
    );
    expect(result).toBeNull();
    expect(await prisma.featuredPost.findMany()).toEqual(before);
  });

  it('soft deletes removed posts and frees an instagram id for the same save', async () => {
    const insta = (id: string) => ({
      ...draft(id),
      source: 'INSTAGRAM' as const,
      instagramMediaId: 'fake-post-1',
    });
    await repo().replace(CREATOR, [{ draft: insta('old') }], now.now());
    // 같은 저장 안에서 지우고 같은 원본 ID를 다시 넣을 수 있다.
    const saved = await repo().replace(
      CREATOR,
      [{ draft: insta('new') }],
      now.now(),
    );
    expect(saved).toHaveLength(1);
    const rows = await prisma.featuredPost.findMany({
      orderBy: { createdAt: 'asc' },
    });
    expect(rows).toHaveLength(2);
    expect(rows.filter((r) => r.deletedAt).map((r) => r.caption)).toEqual([
      'old',
    ]);
  });

  it('keeps positions 1..n within four when two saves arrive at once', async () => {
    const items = (prefix: string, n: number) =>
      Array.from({ length: n }, (_, i) => ({ draft: draft(`${prefix}${i}`) }));
    await Promise.all([
      repo().replace(CREATOR, items('x', 4), now.now()),
      repo().replace(CREATOR, items('y', 3), now.now()),
      repo().replace(CREATOR, items('z', 4), now.now()),
    ]);
    const live = await prisma.featuredPost.findMany({
      where: { creatorId: CREATOR, deletedAt: null },
      orderBy: { position: 'asc' },
    });
    // 저장이 차례로 일어났으므로 마지막에 끝난 저장 하나의 전체가 남는다.
    expect(live.length === 3 || live.length === 4).toBe(true);
    expect(live.map((r) => r.position)).toEqual(
      Array.from({ length: live.length }, (_, i) => i + 1),
    );
    const prefixes = new Set(live.map((r) => r.caption?.[0]));
    expect(prefixes.size).toBe(1);
  });
});
