import { DevUsers } from './dev-users';
import { FakeSupabaseAdmin } from '../../test/support/fake-supabase-admin';
import { runSeedDev } from './seed-dev';
import { SeedError } from './supabase-admin';

// 손으로 쓴 users 가짜. id별 역할을 기억한다.
class FakeDevUsers implements DevUsers {
  readonly rows = new Map<string, string>();

  upsertRole(id: string, role: string): Promise<{ created: boolean }> {
    const created = !this.rows.has(id);
    this.rows.set(id, role);
    return Promise.resolve({ created });
  }
}

function setup(nodeEnv: string | undefined = 'development') {
  const admin = new FakeSupabaseAdmin();
  const users = new FakeDevUsers();
  const lines: string[] = [];
  const run = () =>
    runSeedDev({ nodeEnv, admin, users, log: (l) => lines.push(l) });
  return { admin, users, lines, run };
}

describe('runSeedDev', () => {
  it('creates the three accounts and stores their roles', async () => {
    const { admin, users, run } = setup();

    const results = await run();

    expect(results.map((r) => r.accountCreated)).toEqual([true, true, true]);
    expect(admin.users.size).toBe(3);
    expect([...users.rows.values()].sort()).toEqual([
      'BRAND',
      'CREATOR',
      'STORE',
    ]);
  });

  it('creates nothing new when run a second time', async () => {
    const { admin, users, run } = setup();
    await run();

    const second = await run();

    expect(second.every((r) => !r.accountCreated && !r.rowCreated)).toBe(true);
    expect(admin.users.size).toBe(3);
    expect(users.rows.size).toBe(3);
  });

  it('refuses to run in production before touching anything', async () => {
    const { admin, users, run } = setup('production');

    await expect(run()).rejects.toThrow(SeedError);
    expect(admin.calls).toBe(0);
    expect(users.rows.size).toBe(0);
  });

  it('logs only the last four digits and the result', async () => {
    const { lines, run } = setup();

    await run();

    expect(lines).toHaveLength(3);
    expect(lines[2]).toContain('…0003');
    for (const line of lines) {
      expect(line).not.toMatch(/010|@|cora-dev-only|[0-9a-f]{8}-/);
    }
  });
});
