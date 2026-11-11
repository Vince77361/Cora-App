import { UserRole } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { UsersService } from '../users/users.service';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
import { UploadRateLimiter } from './upload-rate-limiter';
import { UploadsService } from './uploads.service';

const USER = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const UUID = '33333333-3333-4333-8333-333333333333';
const MB5 = 5 * 1024 * 1024;

// 서비스는 사용자의 역할만 필요하다. 저장소까지 끌어오지 않고 getRole만 손으로 대신한다.
class FakeUsersService extends UsersService {
  role: UserRole | null = 'STORE';

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

function syncCodeOf(fn: () => void): string | undefined {
  try {
    fn();
  } catch (e) {
    return (e as AppError).code;
  }
  return undefined;
}

describe('UploadsService', () => {
  let users: FakeUsersService;
  let storage: FakeStoragePort;
  let clock: FakeClock;
  let service: UploadsService;

  const storeCover = {
    purpose: 'STORE_COVER' as const,
    contentType: 'image/jpeg',
    sizeBytes: 1000,
  };

  beforeEach(() => {
    users = new FakeUsersService();
    storage = new FakeStoragePort();
    clock = new FakeClock();
    service = new UploadsService(users, storage, new UploadRateLimiter(clock));
  });

  describe('createPhotoUpload', () => {
    it('rejects a content type that is not jpeg, png or heic', async () => {
      expect(
        await codeOf(
          service.createPhotoUpload(USER, {
            ...storeCover,
            contentType: 'image/gif',
          }),
        ),
      ).toBe('VALIDATION_FAILED');
      expect(storage.uploadUrlPaths).toHaveLength(0);
    });

    it('rejects a file larger than 5MB', async () => {
      expect(
        await codeOf(
          service.createPhotoUpload(USER, {
            ...storeCover,
            sizeBytes: MB5 + 1,
          }),
        ),
      ).toBe('VALIDATION_FAILED');
    });

    it('accepts exactly 5MB', async () => {
      const res = await service.createPhotoUpload(USER, {
        ...storeCover,
        sizeBytes: MB5,
      });
      expect(res.path).toMatch(/^stores\//);
    });

    it('rejects an empty file', async () => {
      expect(
        await codeOf(
          service.createPhotoUpload(USER, { ...storeCover, sizeBytes: 0 }),
        ),
      ).toBe('VALIDATION_FAILED');
    });

    it('issues a path under the caller id for a store cover', async () => {
      const res = await service.createPhotoUpload(USER, storeCover);
      expect(res.path.startsWith(`stores/${USER}/`)).toBe(true);
      expect(res.path.endsWith('.jpg')).toBe(true);
      expect(res.uploadUrl).toContain(res.path);
      expect(storage.uploadUrlPaths).toEqual([res.path]);
    });

    it('issues a creators path with the png and heic extensions for a creator photo', async () => {
      users.role = 'CREATOR';
      const png = await service.createPhotoUpload(USER, {
        purpose: 'CREATOR_PHOTO',
        contentType: 'image/png',
        sizeBytes: 10,
      });
      const heic = await service.createPhotoUpload(USER, {
        purpose: 'CREATOR_PHOTO',
        contentType: 'image/heic',
        sizeBytes: 10,
      });
      expect(png.path).toMatch(
        new RegExp(`^creators/${USER}/[0-9a-f-]{36}\\.png$`),
      );
      expect(heic.path).toMatch(
        new RegExp(`^creators/${USER}/[0-9a-f-]{36}\\.heic$`),
      );
    });

    it('uses a fresh server-made file name every time', async () => {
      const a = await service.createPhotoUpload(USER, storeCover);
      const b = await service.createPhotoUpload(USER, storeCover);
      expect(a.path).not.toBe(b.path);
    });

    it('requires the STORE role for a store cover', async () => {
      users.role = 'CREATOR';
      expect(await codeOf(service.createPhotoUpload(USER, storeCover))).toBe(
        'FORBIDDEN',
      );
      expect(storage.uploadUrlPaths).toHaveLength(0);
    });

    it('requires the CREATOR role for a creator photo', async () => {
      users.role = 'STORE';
      expect(
        await codeOf(
          service.createPhotoUpload(USER, {
            purpose: 'CREATOR_PHOTO',
            contentType: 'image/jpeg',
            sizeBytes: 10,
          }),
        ),
      ).toBe('FORBIDDEN');
    });

    it('rejects a user who has not chosen a role yet', async () => {
      users.role = null;
      expect(await codeOf(service.createPhotoUpload(USER, storeCover))).toBe(
        'FORBIDDEN',
      );
    });
  });

  describe('rate limit', () => {
    const HOUR = 60 * 60 * 1000;
    const issue = (userId = USER, over = {}) =>
      service.createPhotoUpload(userId, { ...storeCover, ...over });
    const issueMany = async (n: number, userId = USER) => {
      for (let i = 0; i < n; i++) await issue(userId);
    };

    it('refuses the 31st issuance within an hour with RATE_LIMITED', async () => {
      await issueMany(30);
      expect(await codeOf(issue())).toBe('RATE_LIMITED');
      expect(storage.uploadUrlPaths).toHaveLength(30);
    });

    it('allows issuing again once the window has passed', async () => {
      await issueMany(30);
      clock.advance(HOUR - 1);
      expect(await codeOf(issue())).toBe('RATE_LIMITED');
      clock.advance(2);
      expect(await codeOf(issue())).toBeUndefined();
    });

    it('uses a rolling window, not a fixed hour', async () => {
      await issueMany(15);
      clock.advance(HOUR / 2);
      await issueMany(15);
      // 처음 15개가 창 밖으로 나가면 15개만 다시 쓸 수 있다.
      clock.advance(HOUR / 2 + 1);
      await issueMany(15);
      expect(await codeOf(issue())).toBe('RATE_LIMITED');
    });

    it('counts each user separately', async () => {
      await issueMany(30);
      users.role = 'STORE';
      expect(await codeOf(issue(OTHER))).toBeUndefined();
    });

    it('does not count requests rejected for role, type or size', async () => {
      await issueMany(29);
      expect(await codeOf(issue(USER, { contentType: 'image/gif' }))).toBe(
        'VALIDATION_FAILED',
      );
      expect(await codeOf(issue(USER, { sizeBytes: MB5 + 1 }))).toBe(
        'VALIDATION_FAILED',
      );
      users.role = 'CREATOR';
      expect(await codeOf(issue())).toBe('FORBIDDEN');
      users.role = 'STORE';
      // 거절된 3건이 세어졌다면 여기서 막힌다.
      expect(await codeOf(issue())).toBeUndefined();
      expect(await codeOf(issue())).toBe('RATE_LIMITED');
    });

    it('does not count an issuance that failed in storage', async () => {
      await issueMany(29);
      const original = storage.createUploadUrl.bind(storage);
      storage.createUploadUrl = () => Promise.reject(new Error('down'));
      await expect(issue()).rejects.toThrow('down');
      storage.createUploadUrl = original;
      expect(await codeOf(issue())).toBeUndefined();
    });

    it('answers with the Korean retry message', async () => {
      await issueMany(30);
      await expect(issue()).rejects.toMatchObject({
        message: '잠시 후 다시 시도해 주세요.',
      });
    });
  });

  describe('assertOwnedPath', () => {
    const own = `stores/${USER}/${UUID}.jpg`;

    it('accepts the callers own path for each extension', () => {
      for (const ext of ['jpg', 'png', 'heic']) {
        expect(() =>
          service.assertOwnedPath(
            USER,
            `stores/${USER}/${UUID}.${ext}`,
            'STORE_COVER',
          ),
        ).not.toThrow();
      }
      expect(() =>
        service.assertOwnedPath(
          USER,
          `creators/${USER}/${UUID}.png`,
          'CREATOR_PHOTO',
        ),
      ).not.toThrow();
    });

    it('assertOwnedPath rejects a path under another user id', () => {
      expect(
        syncCodeOf(() =>
          service.assertOwnedPath(
            USER,
            `stores/${OTHER}/${UUID}.jpg`,
            'STORE_COVER',
          ),
        ),
      ).toBe('FORBIDDEN');
    });

    it.each([
      ['an empty string', ''],
      ['a parent directory escape', `stores/${USER}/../${OTHER}/${UUID}.jpg`],
      ['a bare parent directory file', `stores/${USER}/..`],
      ['a nested folder', `stores/${USER}/a/${UUID}.jpg`],
      ['a missing file name', `stores/${USER}/`],
      ['a file name that is not a uuid', `stores/${USER}/photo.jpg`],
      ['a disallowed extension', `stores/${USER}/${UUID}.gif`],
      ['a double extension', `stores/${USER}/${UUID}.jpg.exe`],
      ['no extension', `stores/${USER}/${UUID}`],
      ['the other purpose prefix', `creators/${USER}/${UUID}.jpg`],
      ['a leading slash', `/stores/${USER}/${UUID}.jpg`],
      ['a user id prefix without the slash', `stores/${USER}x/${UUID}.jpg`],
      ['a url instead of a path', `https://x.test/stores/${USER}/${UUID}.jpg`],
    ])('rejects %s', (_label, path) => {
      expect(
        syncCodeOf(() => service.assertOwnedPath(USER, path, 'STORE_COVER')),
      ).toBe('FORBIDDEN');
    });

    it('rejects the same id in a different letter case', () => {
      const id = 'abcdef12-1111-4111-8111-111111111111';
      expect(
        syncCodeOf(() =>
          service.assertOwnedPath(
            id,
            `stores/${id.toUpperCase()}/${UUID}.jpg`,
            'STORE_COVER',
          ),
        ),
      ).toBe('FORBIDDEN');
    });

    it('rejects a store path used for a creator photo', () => {
      expect(
        syncCodeOf(() => service.assertOwnedPath(USER, own, 'CREATOR_PHOTO')),
      ).toBe('FORBIDDEN');
    });
  });
});
