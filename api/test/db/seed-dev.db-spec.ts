import { PrismaDevUsers } from '../../src/dev-seed/dev-users';
import { FakeSupabaseAdmin } from '../support/fake-supabase-admin';
import { runSeedDev } from '../../src/dev-seed/seed-dev';
import { prisma } from './setup-db';

describe('seed:dev users upsert', () => {
  const run = (admin = new FakeSupabaseAdmin()) =>
    runSeedDev({
      nodeEnv: 'test',
      admin,
      users: new PrismaDevUsers(prisma),
      log: () => undefined,
    });

  it('stores one row per account with the matching role', async () => {
    await run();

    const rows = await prisma.user.findMany();
    expect(rows.map((r) => r.role).sort()).toEqual([
      'BRAND',
      'CREATOR',
      'STORE',
    ]);
  });

  it('adds no rows when run twice with the same accounts', async () => {
    const admin = new FakeSupabaseAdmin();
    await run(admin);
    const second = await run(admin);

    expect(await prisma.user.count()).toBe(3);
    expect(second.every((r) => !r.rowCreated)).toBe(true);
  });

  it('puts an existing row back to the account role and clears deletedAt', async () => {
    const admin = new FakeSupabaseAdmin();
    await run(admin);
    const [creator] = await prisma.user.findMany({
      where: { role: 'CREATOR' },
    });
    await prisma.user.update({
      where: { id: creator.id },
      data: { role: 'STORE', deletedAt: new Date() },
    });

    await run(admin);

    const fixed = await prisma.user.findUniqueOrThrow({
      where: { id: creator.id },
    });
    expect(fixed.role).toBe('CREATOR');
    expect(fixed.deletedAt).toBeNull();
  });
});
