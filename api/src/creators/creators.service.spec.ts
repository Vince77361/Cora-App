import { CreatorProfile, UserRole } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
import { CreatorsRepository } from './creators.repository';
import type { CreatorProfileData } from './creators.repository';
import { CreatorsService } from './creators.service';

const USER = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const PHOTO = `creators/${USER}/33333333-3333-4333-8333-333333333333.jpg`;

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현.
class FakeCreatorsRepository extends CreatorsRepository {
  readonly rows = new Map<string, CreatorProfile>();

  constructor() {
    super(null as never);
  }

  findActiveByUserId(userId: string): Promise<CreatorProfile | null> {
    const row = this.rows.get(userId);
    return Promise.resolve(row && !row.deletedAt ? row : null);
  }

  upsert(userId: string, data: CreatorProfileData): Promise<CreatorProfile> {
    const now = new Date();
    const row: CreatorProfile = {
      id: this.rows.get(userId)?.id ?? `id-${userId}`,
      userId,
      ...data,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    };
    this.rows.set(userId, row);
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
  let service: CreatorsService;
  const input = {
    displayName: '민지',
    regionSido: '서울특별시',
  };

  beforeEach(() => {
    repo = new FakeCreatorsRepository();
    users = new FakeUsersService();
    const storage = new FakeStoragePort();
    service = new CreatorsService(
      repo,
      users,
      new UploadsService(users, storage),
      storage,
    );
  });

  it('returns null for a missing profile and for a soft-deleted one', async () => {
    expect(await service.getSummary(USER)).toBeNull();
    await service.upsertMine(USER, input);
    repo.rows.set(USER, { ...repo.rows.get(USER)!, deletedAt: new Date() });
    expect(await service.getSummary(USER)).toBeNull();
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
      'photoUrl',
      'regionSido',
      'regionSigungu',
      'userId',
    ]);
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
});
