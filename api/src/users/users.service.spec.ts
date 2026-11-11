import { User, UserRole } from '@prisma/client';
import { UsersRepository } from './users.repository';
import { UsersService } from './users.service';

// jest mock 대신 손으로 쓴 메모리 구현으로 서비스 규칙만 검증한다.
class FakeUsersRepository extends UsersRepository {
  readonly rows = new Map<string, User>();

  constructor() {
    super(null as never);
  }

  findById(id: string): Promise<User | null> {
    return Promise.resolve(this.rows.get(id) ?? null);
  }

  upsert(id: string): Promise<User> {
    const found = this.rows.get(id);
    if (found) return Promise.resolve(found);
    const now = new Date();
    const user: User = {
      id,
      role: null,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    };
    this.rows.set(id, user);
    return Promise.resolve(user);
  }

  updateRole(id: string, role: UserRole): Promise<User> {
    const user = { ...this.rows.get(id)!, role };
    this.rows.set(id, user);
    return Promise.resolve(user);
  }
}

describe('UsersService', () => {
  const ID = '11111111-1111-4111-8111-111111111111';
  let repo: FakeUsersRepository;
  let service: UsersService;

  beforeEach(() => {
    repo = new FakeUsersRepository();
    service = new UsersService(repo);
  });

  it('creates the user with a null role when missing', async () => {
    expect(await service.getMe(ID)).toEqual({ id: ID, role: null });
    expect(repo.rows.size).toBe(1);
  });

  it('does not create a second row on repeated calls', async () => {
    await service.getMe(ID);
    await service.getMe(ID);
    expect(repo.rows.size).toBe(1);
  });

  it('saves the role and allows changing it later', async () => {
    expect(await service.setRole(ID, 'STORE')).toEqual({
      id: ID,
      role: 'STORE',
    });
    expect(await service.setRole(ID, 'CREATOR')).toEqual({
      id: ID,
      role: 'CREATOR',
    });
  });

  it('creates the user when the role is set before the first /me', async () => {
    expect(await service.setRole(ID, 'BRAND')).toEqual({
      id: ID,
      role: 'BRAND',
    });
  });

  it('exposes only id and role', async () => {
    expect(Object.keys(await service.getMe(ID)).sort()).toEqual(['id', 'role']);
  });
});
