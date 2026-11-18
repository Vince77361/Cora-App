import { randomUUID } from 'node:crypto';
import { CreatorSeries, UserRole } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { UploadRateLimiter } from '../uploads/upload-rate-limiter';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeFeaturedPostsRepository } from '../../test/support/fake-featured-posts.repository';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
import type { UpsertCreatorProfileDto } from './dto/upsert-creator-profile.dto';
import { CreatorsRepository } from './creators.repository';
import type {
  CreatorCardRow,
  CreatorProfileData,
  CreatorSeriesData,
  CreatorProfileRow,
} from './creators.repository';
import { CreatorsService } from './creators.service';
import { FeaturedPostsService } from './featured-posts.service';

const USER = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const PHOTO = `creators/${USER}/33333333-3333-4333-8333-333333333333.jpg`;

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현.
class FakeCreatorsRepository extends CreatorsRepository {
  readonly rows = new Map<string, CreatorProfileRow>();
  // 연결 정보는 프로필 행 밖(instagram_connections)에 있어 따로 둔다.
  readonly connections = new Map<
    string,
    { handle: string; followers: number | null }
  >();

  constructor() {
    super(null as never);
  }

  findActiveByUserId(userId: string): Promise<CreatorProfileRow | null> {
    const row = this.rows.get(userId);
    return Promise.resolve(
      row && !row.deletedAt
        ? { ...row, instagram: this.connections.get(userId) ?? null }
        : null,
    );
  }

  // 한 번의 읽기로 센다(목록이 줄마다 읽지 않는지 보려고).
  batchReads = 0;

  async findActiveByUserIds(userIds: string[]): Promise<CreatorProfileRow[]> {
    this.batchReads += 1;
    const rows = await Promise.all(
      userIds.map((id) => this.findActiveByUserId(id)),
    );
    return rows.flatMap((row) => (row ? [row] : []));
  }

  listForCards(ids?: string[]): Promise<CreatorCardRow[]> {
    return Promise.resolve(
      [...this.rows.values()]
        .filter((r) => !r.deletedAt && (!ids || ids.includes(r.userId)))
        .map((row) => {
          const profile: Partial<CreatorProfileRow> = { ...row };
          delete profile.instagram;
          return { ...(profile as CreatorCardRow), joinedAt: row.createdAt };
        }),
    );
  }

  upsert(userId: string, data: CreatorProfileData): Promise<CreatorProfileRow> {
    const now = new Date();
    const before = this.rows.get(userId);
    const row: CreatorProfileRow = {
      id: before?.id ?? `id-${userId}`,
      userId,
      // 옛 카드 열은 저장 요청이 건드리지 않는다.
      cardHeadline: before?.cardHeadline ?? null,
      cardPhotoPath: before?.cardPhotoPath ?? null,
      ...data,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      instagram: null,
    };
    this.rows.set(userId, row);
    return this.findActiveByUserId(userId) as Promise<CreatorProfileRow>;
  }

  findConnectedHandle(userId: string): Promise<string | null> {
    return Promise.resolve(this.connections.get(userId)?.handle ?? null);
  }

  updateInstagramHandle(userId: string, handle: string): Promise<void> {
    const row = this.rows.get(userId);
    if (row) this.rows.set(userId, { ...row, instagramHandle: handle });
    return Promise.resolve();
  }

  readonly series: CreatorSeries[] = [];

  listSeries(creatorId: string): Promise<CreatorSeries[]> {
    return Promise.resolve(
      this.series.filter((s) => s.creatorId === creatorId),
    );
  }

  findSeries(creatorId: string, id: string): Promise<CreatorSeries | null> {
    return Promise.resolve(
      this.series.find((s) => s.id === id && s.creatorId === creatorId) ?? null,
    );
  }

  createSeries(
    creatorId: string,
    data: CreatorSeriesData,
    max: number,
  ): Promise<CreatorSeries | null> {
    if (this.series.filter((s) => s.creatorId === creatorId).length >= max) {
      return Promise.resolve(null);
    }
    const now = new Date();
    const row: CreatorSeries = {
      id: randomUUID(),
      creatorId,
      ...data,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    };
    this.series.push(row);
    return Promise.resolve(row);
  }
}

class FakeUsersService extends UsersService {
  role: UserRole | null = 'CREATOR';

  constructor() {
    super(null as never);
  }

  getRole(): Promise<UserRole | null> {
    return Promise.resolve(this.role);
  }
}

async function codeOf(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
  } catch (e) {
    return (e as AppError).code;
  }
  return undefined;
}

describe('CreatorsService', () => {
  let repo: FakeCreatorsRepository;
  let users: FakeUsersService;
  let featuredRepo: FakeFeaturedPostsRepository;
  let featured: FeaturedPostsService;
  let storage: FakeStoragePort;
  let service: CreatorsService;
  const input: UpsertCreatorProfileDto = {
    displayName: '민지',
    regionSido: '서울특별시',
  };

  beforeEach(() => {
    repo = new FakeCreatorsRepository();
    users = new FakeUsersService();
    storage = new FakeStoragePort();
    const uploads = new UploadsService(
      users,
      storage,
      new UploadRateLimiter(new FakeClock()),
    );
    featuredRepo = new FakeFeaturedPostsRepository();
    featured = new FeaturedPostsService(
      featuredRepo,
      users,
      uploads,
      storage,
      new FakeClock(),
    );
    service = new CreatorsService(repo, users, uploads, storage, featured);
  });

  it('returns null for a missing profile and for a soft-deleted one', async () => {
    expect(await service.getSummary(USER)).toBeNull();
    await service.upsertMine(USER, input);
    repo.rows.set(USER, { ...repo.rows.get(USER)!, deletedAt: new Date() });
    expect(await service.getSummary(USER)).toBeNull();
  });

  it('reads many summaries in one read and leaves out missing and deleted profiles', async () => {
    const other = '44444444-4444-4444-8444-444444444444';
    const gone = '55555555-5555-4555-8555-555555555555';
    await service.upsertMine(USER, input);
    await service.upsertMine(other, { ...input, displayName: '하나' });
    await service.upsertMine(gone, { ...input, displayName: '지움' });
    repo.rows.set(gone, { ...repo.rows.get(gone)!, deletedAt: new Date() });

    const found = await service.getSummaries([USER, other, gone, 'nobody']);
    expect(repo.batchReads).toBe(1);
    expect([...found.keys()].sort()).toEqual([USER, other].sort());
    expect(found.get(other)?.displayName).toBe('하나');
    // 한 명씩 읽는 getSummary와 같은 모양이다.
    expect(found.get(USER)).toEqual(await service.getSummary(USER));
  });

  it('replaces the whole profile and turns missing or blank optionals into null', async () => {
    await service.upsertMine(USER, {
      ...input,
      contentFocus: '카페',
      instagramHandle: 'min.closet',
      regionSigungu: '마포구',
      photoPath: PHOTO,
    });
    const saved = await service.upsertMine(USER, {
      ...input,
      contentFocus: '   ',
      regionSigungu: '',
    });
    expect(saved).toEqual({
      userId: USER,
      displayName: '민지',
      contentFocus: null,
      instagramHandle: null,
      photoUrl: null,
      regionSido: '서울특별시',
      regionSigungu: null,
      instagramConnected: false,
      followers: null,
      cardHeadline: null,
      cardPhotoUrl: null,
    });
  });

  it('trims text and strips one leading @ from the instagram handle', async () => {
    const saved = await service.upsertMine(USER, {
      ...input,
      displayName: '  민지  ',
      instagramHandle: ' @min.closet ',
    });
    expect(saved.displayName).toBe('민지');
    expect(saved.instagramHandle).toBe('min.closet');
  });

  it('builds the photo url from the stored path', async () => {
    const saved = await service.upsertMine(USER, {
      ...input,
      photoPath: PHOTO,
    });
    expect(saved.photoUrl).toBe(`https://fake-storage.test/public/${PHOTO}`);
    expect((await service.getSummary(USER))?.photoUrl).toBe(saved.photoUrl);
  });

  it('rejects a photo path under another user id and saves nothing', async () => {
    const path = PHOTO.replace(USER, OTHER);
    expect(
      await codeOf(service.upsertMine(USER, { ...input, photoPath: path })),
    ).toBe('FORBIDDEN');
    expect(repo.rows.size).toBe(0);
  });

  it('ignores the legacy card fields in the profile save', async () => {
    const saved = await service.upsertMine(USER, {
      ...input,
      cardHeadline: '  카페 릴스 전문 ',
      cardPhotoPath: `creator-cards/${USER}/44444444-4444-4444-8444-444444444444.jpg`,
    });
    expect(saved.cardHeadline).toBeNull();
    expect(saved.cardPhotoUrl).toBeNull();
    // 내 폴더가 아닌 경로가 와도 읽지 않으니 거절하지도 않는다.
    await expect(
      service.upsertMine(USER, { ...input, cardPhotoPath: PHOTO }),
    ).resolves.toBeDefined();
  });

  async function addPosts(userId: string, captions: string[]): Promise<void> {
    const items = [];
    for (const caption of captions) {
      const path = `featured-posts/${userId}/${randomUUID()}.jpg`;
      await storage.createUploadUrl(path);
      items.push({
        source: 'GALLERY' as const,
        kind: 'PHOTO' as const,
        mediaPath: path,
        caption,
      });
    }
    await featured.replaceMine(userId, items);
  }

  it('returns the first post as the card copy', async () => {
    await service.upsertMine(USER, { ...input, photoPath: PHOTO });
    await addPosts(USER, ['카페 릴스 전문', '두 번째']);
    const first = featuredRepo.rows.find((r) => r.position === 1)!;
    expect(await service.getCardCopy(USER)).toEqual({
      headline: '카페 릴스 전문',
      photoPath: first.mediaPath,
    });
    // 썸네일이 있으면 카드 사진은 썸네일이다.
    first.thumbnailPath = `featured-posts/${USER}/${randomUUID()}.jpg`;
    expect((await service.getCardCopy(USER))?.photoPath).toBe(
      first.thumbnailPath,
    );
    // 응답의 옛 이름 두 칸도 1번 게시물에서 채운다.
    const profile = await service.getMine(USER);
    expect(profile.cardHeadline).toBe('카페 릴스 전문');
    expect(profile.cardPhotoUrl).toBe(
      `https://fake-storage.test/public/${first.thumbnailPath}`,
    );
    expect(await service.getCardCopy(OTHER)).toBeNull();
  });

  it('falls back to the profile photo when there is no post', async () => {
    await service.upsertMine(USER, { ...input, photoPath: PHOTO });
    expect(await service.getCardCopy(USER)).toEqual({
      headline: null,
      photoPath: null,
    });
    const [card] = await service.findCardSources([USER]);
    expect(card.headline).toBeNull();
    expect(card.posts).toEqual([]);
    expect(card.photoUrl).toBe(`https://fake-storage.test/public/${PHOTO}`);

    await addPosts(USER, ['카페 릴스 전문']);
    const [withPost] = await service.findCardSources([USER]);
    expect(withPost.headline).toBe('카페 릴스 전문');
    expect(withPost.posts).toHaveLength(1);
    expect(withPost.photoUrl).toBe(withPost.posts[0].photoUrl);
  });

  it('requires the CREATOR role for reading and writing', async () => {
    users.role = 'STORE';
    expect(await codeOf(service.getMine(USER))).toBe('FORBIDDEN');
    expect(await codeOf(service.upsertMine(USER, input))).toBe('FORBIDDEN');
    users.role = null;
    expect(await codeOf(service.upsertMine(USER, input))).toBe('FORBIDDEN');
    expect(repo.rows.size).toBe(0);
  });

  it('throws NOT_FOUND from getMine before a profile exists', async () => {
    expect(await codeOf(service.getMine(USER))).toBe('NOT_FOUND');
  });

  it('exposes only summary fields from getSummary', async () => {
    await service.upsertMine(USER, { ...input, instagramHandle: 'min' });
    expect(Object.keys((await service.getSummary(USER))!).sort()).toEqual([
      'contentFocus',
      'displayName',
      'followers',
      'instagramConnected',
      'photoUrl',
      'regionSido',
      'regionSigungu',
      'userId',
    ]);
  });

  it('shows the connection and followers in the summary and the profile', async () => {
    await service.upsertMine(USER, input);
    expect(await service.getSummary(USER)).toMatchObject({
      instagramConnected: false,
      followers: null,
    });
    repo.connections.set(USER, { handle: 'haru', followers: 2100 });
    expect(await service.getSummary(USER)).toMatchObject({
      instagramConnected: true,
      followers: 2100,
    });
    // 연결한 크리에이터가 프로필을 고쳐도 연결 표시는 그대로다.
    expect(await service.upsertMine(USER, input)).toMatchObject({
      instagramConnected: true,
      followers: 2100,
    });
    repo.connections.set(USER, { handle: 'haru', followers: null });
    expect(await service.getMine(USER)).toMatchObject({
      instagramConnected: true,
      followers: null,
    });
  });

  it('overwrites the profile handle with the connected one and ignores a missing profile', async () => {
    await service.upsertMine(USER, { ...input, instagramHandle: 'typed' });
    await service.overwriteInstagramHandle(USER, 'connected');
    expect((await service.getMine(USER)).instagramHandle).toBe('connected');
    await expect(
      service.overwriteInstagramHandle(OTHER, 'connected'),
    ).resolves.toBeUndefined();
    expect(repo.rows.has(OTHER)).toBe(false);
  });

  it('keeps the connected handle on every profile save, whatever the input says', async () => {
    repo.connections.set(USER, { handle: 'haru', followers: 2100 });
    // 연결을 먼저 하고 프로필을 처음 만들 때도 연결된 아이디가 들어간다.
    const created = await service.upsertMine(USER, {
      ...input,
      instagramHandle: 'typed',
    });
    expect(created.instagramHandle).toBe('haru');
    // 전체 교체(PUT)에서 아이디를 빼도, 다른 아이디를 적어도 그대로다.
    expect((await service.upsertMine(USER, input)).instagramHandle).toBe(
      'haru',
    );
    expect(
      (await service.upsertMine(USER, { ...input, instagramHandle: '@other' }))
        .instagramHandle,
    ).toBe('haru');
  });

  it('uses the typed handle when nothing is connected', async () => {
    const saved = await service.upsertMine(USER, {
      ...input,
      instagramHandle: 'typed',
    });
    expect(saved.instagramHandle).toBe('typed');
  });

  it('requireProfile returns the profile or throws CONFLICT', async () => {
    let error: AppError | undefined;
    try {
      await service.requireProfile(USER);
    } catch (e) {
      error = e as AppError;
    }
    expect(error?.code).toBe('CONFLICT');
    expect(error?.message).toBe('크리에이터 프로필을 먼저 만들어 주세요.');
    await service.upsertMine(USER, input);
    expect((await service.requireProfile(USER)).displayName).toBe('민지');
  });

  describe('series', () => {
    it('turns a blank note into null and trims the name', async () => {
      const created = await service.createMySeries(USER, {
        name: '  오늘의 한 컵  ',
        format: 'REELS',
        note: '   ',
      });
      expect(created).toMatchObject({
        name: '오늘의 한 컵',
        format: 'REELS',
        note: null,
      });
    });

    it('refuses a sixth series but lets another creator make their own', async () => {
      for (let i = 0; i < 5; i += 1) {
        await service.createMySeries(USER, {
          name: `시리즈 ${i}`,
          format: 'REELS',
        });
      }
      expect(
        await codeOf(
          service.createMySeries(USER, { name: '여섯째', format: 'REELS' }),
        ),
      ).toBe('CONFLICT');
      await service.createMySeries(OTHER, {
        name: '다른 사람',
        format: 'BLOG',
      });
      expect(await service.listMySeries(USER)).toHaveLength(5);
    });

    it('finds only my own series and treats a malformed id as missing', async () => {
      const mine = await service.createMySeries(USER, {
        name: '내 것',
        format: 'REELS',
      });
      expect((await service.requireMySeries(USER, mine.id)).name).toBe('내 것');
      expect(await codeOf(service.requireMySeries(OTHER, mine.id))).toBe(
        'NOT_FOUND',
      );
      expect(await codeOf(service.requireMySeries(USER, 'not-a-uuid'))).toBe(
        'NOT_FOUND',
      );
    });

    it('only lets a creator account use series', async () => {
      users.role = 'STORE';
      expect(await codeOf(service.listMySeries(USER))).toBe('FORBIDDEN');
    });
  });
});
