import { DEV_ACCOUNTS, devCredentials } from './dev-accounts';
import { DevUsers } from './dev-users';
import { assertDevTarget } from './dev-target';
import { MockSeedDeps, runMockSeed } from './mock-seed';
import { SupabaseAdmin } from './supabase-admin';

export interface SeedDevDeps {
  nodeEnv: string | undefined;
  supabaseUrl: string | undefined;
  devProjectRef: string;
  admin: SupabaseAdmin;
  users: DevUsers;
  // 있으면 계정 다음에 목업 가게·크리에이터·지원·오퍼를 맞춘다. 단위 테스트는 생략해도 된다.
  mock?: Omit<MockSeedDeps, 'log'>;
  log: (line: string) => void;
}

export interface SeedDevResult {
  phoneLast4: string;
  role: string;
  accountCreated: boolean;
  passwordReset: boolean;
  rowCreated: boolean;
}

// 역할별 개발 계정 3개와 목업 크리에이터 4개를 Supabase Auth와 users 테이블에 맞춘다. 여러 번 돌려도 같은 결과다.
export async function runSeedDev(deps: SeedDevDeps): Promise<SeedDevResult[]> {
  // 외부를 건드리기 전에 개발 환경·개발 프로젝트인지부터 확인한다.
  assertDevTarget(deps);
  const results: SeedDevResult[] = [];
  const accountIds = new Map<string, string>();
  for (const account of DEV_ACCOUNTS) {
    const {
      id,
      created: accountCreated,
      passwordReset,
    } = await deps.admin.ensureUser(devCredentials(account.phone));
    accountIds.set(account.phone, id);
    const { created: rowCreated } = await deps.users.upsertRole(
      id,
      account.role,
    );
    // 출력에는 번호 끝 4자리와 결과만 남긴다. 이메일·비밀번호·id는 찍지 않는다.
    const phoneLast4 = account.phone.slice(-4);
    deps.log(
      `…${phoneLast4} ${account.role}: 계정 ${accountCreated ? '새로 만듦' : '이미 있음'}${passwordReset ? '(비밀번호 맞춤)' : ''}, users 행 ${rowCreated ? '새로 만듦' : '이미 있음(역할 맞춤)'}`,
    );
    results.push({
      phoneLast4,
      role: account.role,
      accountCreated,
      passwordReset,
      rowCreated,
    });
  }
  if (deps.mock) await runMockSeed({ ...deps.mock, log: deps.log }, accountIds);
  return results;
}
