import { EnsuredUser, SupabaseAdmin } from '../../seed/lib/supabase-admin';

// 테스트용 손으로 쓴 가짜. 이메일마다 id를 하나씩 정해 두고 몇 번 불렸는지 센다.
// 이미 있는 계정은 진짜처럼 비밀번호를 받은 값으로 다시 맞춘다.
export class FakeSupabaseAdmin implements SupabaseAdmin {
  readonly users = new Map<string, { id: string; password: string }>();
  calls = 0;

  ensureUser(credentials: {
    email: string;
    password: string;
  }): Promise<EnsuredUser> {
    this.calls += 1;
    const existing = this.users.get(credentials.email);
    if (existing) {
      existing.password = credentials.password;
      return Promise.resolve({
        id: existing.id,
        created: false,
        passwordReset: true,
      });
    }
    const n = String(this.users.size + 1).padStart(12, '0');
    const id = `00000000-0000-4000-8000-${n}`;
    this.users.set(credentials.email, { id, password: credentials.password });
    return Promise.resolve({ id, created: true, passwordReset: false });
  }
}
