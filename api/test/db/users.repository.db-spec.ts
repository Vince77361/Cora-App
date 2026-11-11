import { UsersRepository } from '../../src/users/users.repository';
import { prisma } from './setup-db';

const ID = '33333333-3333-4333-8333-333333333333';

describe('UsersRepository', () => {
  // PrismaService는 PrismaClient를 상속하므로, 같은 테스트 클라이언트를 구조적으로 넘긴다.
  const repo = new UsersRepository(prisma as never);

  it('upsert called twice leaves exactly one row', async () => {
    await repo.upsert(ID);
    await repo.upsert(ID);
    expect(await prisma.user.count()).toBe(1);
  });

  it('concurrent upserts of the same id leave exactly one row', async () => {
    // 첫 로그인 직후 앱이 /me를 동시에 여러 번 부르는 경우를 흉내 낸다.
    const rows = await Promise.all(
      Array.from({ length: 5 }, () => repo.upsert(ID)),
    );
    expect(rows.every((r) => r.id === ID)).toBe(true);
    expect(await prisma.user.count()).toBe(1);
  });

  it('keeps the role when upsert is called again', async () => {
    await repo.upsert(ID);
    await repo.updateRole(ID, 'BRAND');
    const again = await repo.upsert(ID);
    expect(again.role).toBe('BRAND');
  });

  it('findById returns null for an unknown id', async () => {
    expect(await repo.findById(ID)).toBeNull();
  });
});
