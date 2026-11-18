import { randomUUID } from 'node:crypto';
import { UserRole } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { UploadRateLimiter } from '../uploads/upload-rate-limiter';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeFeaturedPostsRepository } from '../../test/support/fake-featured-posts.repository';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
import type { ReplaceFeaturedPostsDto } from './dto/replace-featured-posts.dto';
import { FeaturedPostsService } from './featured-posts.service';

const USER = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';

class FakeUsersService extends UsersService {
  role: UserRole | null = 'CREATOR';

  constructor() {
    super(null as never);
  }

  getRole(): Promise<UserRole | null> {
    return Promise.resolve(this.role);
  }
}

async function failureOf(promise: Promise<unknown>): Promise<AppError> {
  try {
    await promise;
  } catch (e) {
    return e as AppError;
  }
  throw new Error('expected a failure');
}

describe('FeaturedPostsService', () => {
  let repo: FakeFeaturedPostsRepository;
  let users: FakeUsersService;
  let storage: FakeStoragePort;
  let clock: FakeClock;
  let service: FeaturedPostsService;

  // 앱이 하는 대로: 올릴 주소를 받고(서버가 경로를 정함) 그 경로를 저장 요청에 담는다.
  async function uploaded(userId = USER, ext = 'jpg'): Promise<string> {
    const path = `featured-posts/${userId}/${randomUUID()}.${ext}`;
    await storage.createUploadUrl(path);
    return path;
  }

  async function gallery(
    caption = '오늘의 한 줄',
  ): Promise<ReplaceFeaturedPostsDto['items'][number]> {
    return {
      source: 'GALLERY',
      kind: 'PHOTO',
      mediaPath: await uploaded(),
      caption,
    };
  }

  beforeEach(() => {
    repo = new FakeFeaturedPostsRepository();
    users = new FakeUsersService();
    storage = new FakeStoragePort();
    clock = new FakeClock(new Date('2026-11-19T00:00:00Z'));
    service = new FeaturedPostsService(
      repo,
      users,
      new UploadsService(users, storage, new UploadRateLimiter(clock)),
      storage,
      clock,
    );
  });

  it('replaces the whole list and keeps positions 1..n', async () => {
    const first = await service.replaceMine(USER, [
      await gallery('하나'),
      await gallery('둘'),
      await gallery('셋'),
    ]);
    expect(first.map((p) => [p.position, p.caption])).toEqual([
      [1, '하나'],
      [2, '둘'],
      [3, '셋'],
    ]);

    // 둘째를 빼고 새 게시물을 맨 앞에 놓는다: 남은 것은 다시 1..n이다.
    const second = await service.replaceMine(USER, [
      await gallery('새것'),
      { id: first[0].id },
      { id: first[2].id },
    ]);
    expect(second.map((p) => [p.position, p.caption])).toEqual([
      [1, '새것'],
      [2, '하나'],
      [3, '셋'],
    ]);
    expect(second[1].id).toBe(first[0].id);
    expect(repo.rows.find((r) => r.id === first[1].id)?.deletedAt).toEqual(
      clock.now(),
    );
    expect(await service.listMine(USER)).toEqual(second);

    expect(await service.replaceMine(USER, [])).toEqual([]);
  });

  it("keeps an existing post given only its id and rejects someone else's id", async () => {
    const [mine] = await service.replaceMine(USER, [await gallery()]);
    users.role = 'CREATOR';
    const [theirs] = await service.replaceMine(OTHER, [
      {
        source: 'GALLERY',
        kind: 'PHOTO',
        mediaPath: await uploaded(OTHER),
        caption: '남의 것',
      },
    ]);

    const kept = await service.replaceMine(USER, [{ id: mine.id }]);
    expect(kept[0].id).toBe(mine.id);

    const error = await failureOf(
      service.replaceMine(USER, [{ id: theirs.id }]),
    );
    expect(error.code).toBe('NOT_FOUND');
    // 거절된 저장은 아무것도 바꾸지 않는다.
    expect((await service.listMine(USER)).map((p) => p.id)).toEqual([mine.id]);
  });

  it('asserts the uploaded path belongs to the creator (FEATURED_POST)', async () => {
    const foreign = await failureOf(
      service.replaceMine(USER, [
        {
          source: 'GALLERY',
          kind: 'PHOTO',
          mediaPath: await uploaded(OTHER),
          caption: '남의 사진',
        },
      ]),
    );
    expect(foreign.code).toBe('VALIDATION_FAILED');

    const wrongFolder = await failureOf(
      service.replaceMine(USER, [
        {
          source: 'GALLERY',
          kind: 'PHOTO',
          mediaPath: `creator-cards/${USER}/${randomUUID()}.jpg`,
          caption: '다른 폴더',
        },
      ]),
    );
    expect(wrongFolder.code).toBe('VALIDATION_FAILED');

    const neverUploaded = await failureOf(
      service.replaceMine(USER, [
        {
          source: 'GALLERY',
          kind: 'PHOTO',
          mediaPath: `featured-posts/${USER}/${randomUUID()}.jpg`,
          caption: '올리지 않음',
        },
      ]),
    );
    expect(neverUploaded.code).toBe('VALIDATION_FAILED');
    expect(repo.rows).toHaveLength(0);
  });

  it('accepts an instagram video copied as its first frame and refuses one without it', async () => {
    const frame = await uploaded();
    const saved = await service.replaceMine(USER, [
      {
        source: 'INSTAGRAM',
        kind: 'VIDEO',
        mediaPath: frame,
        thumbnailPath: frame,
        caption: null,
        instagramMediaId: 'fake-post-2',
      },
    ]);
    expect(saved[0].photoUrl).toContain('.jpg');
    expect(saved[0].kind).toBe('VIDEO');
    expect(saved[0].instagramMediaId).toBe('fake-post-2');

    const noFrame = await failureOf(
      service.replaceMine(USER, [
        {
          source: 'INSTAGRAM',
          kind: 'VIDEO',
          mediaPath: await uploaded(),
          caption: null,
          instagramMediaId: 'fake-post-4',
        },
      ]),
    );
    expect(noFrame.code).toBe('VALIDATION_FAILED');
  });

  it('refuses a video file path since only pictures are stored', async () => {
    const error = await failureOf(
      service.replaceMine(USER, [
        {
          source: 'INSTAGRAM',
          kind: 'VIDEO',
          mediaPath: await uploaded(USER, 'mp4'),
          thumbnailPath: await uploaded(),
          caption: null,
          instagramMediaId: 'fake-post-2',
        },
      ]),
    );
    expect(error.code).toBe('VALIDATION_FAILED');
  });

  it('rejects the same existing post twice and a fifth post', async () => {
    const [mine] = await service.replaceMine(USER, [await gallery()]);
    expect(
      (
        await failureOf(
          service.replaceMine(USER, [{ id: mine.id }, { id: mine.id }]),
        )
      ).code,
    ).toBe('VALIDATION_FAILED');
    const five = [
      await gallery(),
      await gallery(),
      await gallery(),
      await gallery(),
      await gallery(),
    ];
    expect((await failureOf(service.replaceMine(USER, five))).code).toBe(
      'VALIDATION_FAILED',
    );
  });

  it('refuses a store or a brand', async () => {
    users.role = 'STORE';
    expect((await failureOf(service.listMine(USER))).code).toBe('FORBIDDEN');
    expect((await failureOf(service.replaceMine(USER, []))).code).toBe(
      'FORBIDDEN',
    );
  });

  it('lists posts for several creators in one read and gives the first post copy', async () => {
    await service.replaceMine(USER, [
      await gallery('첫째'),
      await gallery('둘째'),
    ]);
    const map = await service.listForCreators([USER, OTHER]);
    expect(map.get(USER)?.map((p) => p.caption)).toEqual(['첫째', '둘째']);
    expect(map.get(OTHER)).toEqual([]);

    const copy = await service.getFirstPostCopy(USER);
    expect(copy?.headline).toBe('첫째');
    expect(copy?.photoPath).toMatch(new RegExp(`^featured-posts/${USER}/`));
    expect(await service.getFirstPostCopy(OTHER)).toBeNull();
  });
});
