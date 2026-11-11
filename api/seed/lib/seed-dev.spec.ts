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

const REF = 'abcdefghijklmnopqrst';

// nodeEnv에 undefined를 주면 "NODE_ENV가 없는 경우"이므로 기본값으로 바꾸지 않는다.
function setup(options: { nodeEnv?: string; supabaseUrl?: string } = {}) {
  const nodeEnv = 'nodeEnv' in options ? options.nodeEnv : 'development';
  const supabaseUrl = options.supabaseUrl ?? `https://${REF}.supabase.co`;
  const admin = new FakeSupabaseAdmin();
  const users = new FakeDevUsers();
  const lines: string[] = [];
  const run = () =>
    runSeedDev({
      nodeEnv,
      supabaseUrl,
      devProjectRef: REF,
      admin,
      users,
      log: (l) => lines.push(l),
    });
  return { admin, users, lines, run };
}

describe('runSeedDev', () => {
  it('creates the seven accounts and stores their roles', async () => {
    const { admin, users, run } = setup();

    const results = await run();

    expect(results.map((r) => r.accountCreated)).toEqual(
      Array(7).fill(true) as boolean[],
    );
    expect(admin.users.size).toBe(7);
    expect([...users.rows.values()].sort()).toEqual([
      'BRAND',
      'CREATOR',
      'CREATOR',
      'CREATOR',
      'CREATOR',
      'CREATOR',
      'STORE',
    ]);
  });

  it('creates nothing new when run a second time', async () => {
    const { admin, users, run } = setup();
    await run();

    const second = await run();

    expect(second.every((r) => !r.accountCreated && !r.rowCreated)).toBe(true);
    expect(admin.users.size).toBe(7);
    expect(users.rows.size).toBe(7);
  });

  it.each([undefined, '', 'test', 'staging', 'production'])(
    'refuses NODE_ENV=%p before touching anything',
    async (nodeEnv) => {
      const { admin, users, run } = setup({ nodeEnv });

      await expect(run()).rejects.toThrow(SeedError);
      expect(admin.calls).toBe(0);
      expect(users.rows.size).toBe(0);
    },
  );

  it('refuses a SUPABASE_URL that is not the dev project before touching anything', async () => {
    const { admin, users, run } = setup({
      supabaseUrl: 'https://zzzzzzzzzzzzzzzzzzzz.supabase.co',
    });

    await expect(run()).rejects.toThrow(SeedError);
    expect(admin.calls).toBe(0);
    expect(users.rows.size).toBe(0);
  });

  it('resets the password of an existing account and says so', async () => {
    const { admin, lines, run } = setup();
    await run();
    for (const account of admin.users.values()) account.password = 'changed';

    const second = await run();

    expect(second.every((r) => r.passwordReset)).toBe(true);
    for (const account of admin.users.values()) {
      expect(account.password).toMatch(/^cora-dev-only-phone-010\d{8}$/);
    }
    expect(lines.slice(-7).every((l) => l.includes('비밀번호 맞춤'))).toBe(
      true,
    );
  });

  it('logs only the last four digits and the result', async () => {
    const { lines, run } = setup();

    await run();

    expect(lines).toHaveLength(7);
    expect(lines[2]).toContain('…0003');
    expect(lines[6]).toContain('…0007');
    for (const line of lines) {
      expect(line).not.toMatch(/010|@|cora-dev-only|[0-9a-f]{8}-/);
    }
  });
});
