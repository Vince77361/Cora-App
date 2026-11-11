// Supabase 관리자 API(GoTrue admin)를 얇게 감싼 포트. 시드 로직은 이 인터페이스만 안다.
// 테스트에서는 손으로 쓴 FakeSupabaseAdmin으로 바꿔 끼운다.
export interface SupabaseAdmin {
  // 이메일 계정이 없으면 만들고, 있으면 비밀번호를 개발용 값으로 다시 맞춘다.
  // 어느 쪽이든 계정 id를 돌려준다. passwordReset은 기존 계정의 비밀번호를 맞췄을 때만 true.
  ensureUser(credentials: {
    email: string;
    password: string;
  }): Promise<EnsuredUser>;
}

export interface EnsuredUser {
  id: string;
  created: boolean;
  passwordReset: boolean;
}

// 사용자에게 그대로 보여줘도 되는 메시지만 담는 오류. 키·이메일·비밀번호는 절대 넣지 않는다.
export class SeedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SeedError';
  }
}

const PAGE_SIZE = 200;
// 계정이 이만큼 많은 개발 프로젝트는 상정하지 않는다. 무한 반복을 막는 안전장치다.
const MAX_PAGES = 50;

interface AdminUser {
  id?: unknown;
  email?: unknown;
}

export class HttpSupabaseAdmin implements SupabaseAdmin {
  private readonly baseUrl: string;

  constructor(
    supabaseUrl: string,
    private readonly serviceRoleKey: string,
    private readonly fetchFn: typeof fetch = fetch,
  ) {
    this.baseUrl = supabaseUrl.replace(/\/+$/, '');
  }

  async ensureUser(credentials: {
    email: string;
    password: string;
  }): Promise<EnsuredUser> {
    const res = await this.request('POST', '/auth/v1/admin/users', {
      email: credentials.email,
      password: credentials.password,
      email_confirm: true,
    });
    if (res.ok) {
      const id = ((await res.json()) as AdminUser).id;
      if (typeof id !== 'string') throw unexpected(res.status);
      return { id, created: true, passwordReset: false };
    }
    // 이미 있는 이메일은 422(email_exists)로 온다. 멱등을 위해 정상으로 다룬다.
    if (res.status === 422 && (await isEmailExists(res))) {
      const id = await this.findIdByEmail(credentials.email);
      // 누가 대시보드에서 비밀번호를 바꿔 두면 E1 로그인이 조용히 실패하므로 매번 개발용 값으로 맞춘다.
      const put = await this.request('PUT', `/auth/v1/admin/users/${id}`, {
        password: credentials.password,
        email_confirm: true,
      });
      if (!put.ok) throw failure(put.status);
      return { id, created: false, passwordReset: true };
    }
    throw failure(res.status);
  }

  private async findIdByEmail(email: string): Promise<string> {
    for (let page = 1; page <= MAX_PAGES; page++) {
      const res = await this.request(
        'GET',
        `/auth/v1/admin/users?page=${page}&per_page=${PAGE_SIZE}`,
      );
      if (!res.ok) throw failure(res.status);
      const body = (await res.json()) as { users?: AdminUser[] };
      const users = body.users ?? [];
      const found = users.find((u) => u.email === email);
      if (found) {
        if (typeof found.id !== 'string') throw unexpected(res.status);
        return found.id;
      }
      if (users.length < PAGE_SIZE) break;
    }
    throw new SeedError(
      '이미 있다고 응답한 개발 계정을 목록에서 찾지 못했어요. Supabase 대시보드에서 확인하세요.',
    );
  }

  private async request(
    method: 'GET' | 'POST' | 'PUT',
    path: string,
    body?: unknown,
  ): Promise<Response> {
    // 새 형식 비밀 키(sb_secret_)는 JWT가 아니라서 Authorization 헤더에 넣으면 거부된다.
    // 레거시 service_role JWT는 apikey와 Authorization 둘 다 보낸다.
    const headers: Record<string, string> = {
      apikey: this.serviceRoleKey,
      'Content-Type': 'application/json',
    };
    if (!this.serviceRoleKey.startsWith('sb_secret_')) {
      headers.Authorization = `Bearer ${this.serviceRoleKey}`;
    }
    try {
      return await this.fetchFn(`${this.baseUrl}${path}`, {
        method,
        headers,
        body: body === undefined ? undefined : JSON.stringify(body),
      });
    } catch {
      // 네트워크 오류의 원인(URL 등)은 출력하지 않는다.
      throw new SeedError(
        'Supabase에 연결하지 못했어요. SUPABASE_URL과 인터넷 연결을 확인하세요.',
      );
    }
  }
}

async function isEmailExists(res: Response): Promise<boolean> {
  try {
    const body = (await res.json()) as { error_code?: unknown };
    return body.error_code === 'email_exists';
  } catch {
    return false;
  }
}

function failure(status: number): SeedError {
  if (status === 401 || status === 403) {
    return new SeedError(
      `SUPABASE_SERVICE_ROLE_KEY가 이 프로젝트의 키인지 확인하세요. (관리자 API가 거부했어요: HTTP ${status})`,
    );
  }
  return new SeedError(
    `Supabase 관리자 API 요청이 실패했어요. (HTTP ${status})`,
  );
}

function unexpected(status: number): SeedError {
  return new SeedError(
    `Supabase 관리자 API 응답을 이해하지 못했어요. (HTTP ${status})`,
  );
}
