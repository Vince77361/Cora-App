import { SupabaseAdmin } from '../../src/dev-seed/supabase-admin';

// 테스트용 손으로 쓴 가짜. 이메일마다 id를 하나씩 정해 두고 몇 번 만들었는지 센다.
export class FakeSupabaseAdmin implements SupabaseAdmin {
  readonly users = new Map<string, { id: string; password: string }>();
  calls = 0;

  ensureUser(credentials: {
    email: string;
    password: string;
  }): Promise<{ id: string; created: boolean }> {
    this.calls += 1;
    const existing = this.users.get(credentials.email);
    if (existing) return Promise.resolve({ id: existing.id, created: false });
    const n = String(this.users.size + 1).padStart(12, '0');
    const id = `00000000-0000-4000-8000-${n}`;
    this.users.set(credentials.email, { id, password: credentials.password });
    return Promise.resolve({ id, created: true });
  }
}
