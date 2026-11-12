import { assertDevTarget } from './dev-target';
import { SeedError } from './supabase-admin';

// yarn check:ledger가 읽어도 되는 DB인지 확인한다. 읽기만 하지만, 운영 DB에 조회 부하를 주거나
// 결과를 개발 DB 것으로 착각하지 않도록 seed:dev·테스트 스크립트와 같은 기준으로 개발·테스트 DB만 허용한다.
// - 테스트 DB: 테스트 실행기(scripts/with-test-db.js)를 거쳤고(CORA_TEST_DB=1) 스키마가 public이 아닐 때(운영 환경이 아닐 것).
// - 개발 DB: NODE_ENV=development이고 SUPABASE_URL이 개발 프로젝트일 때(seed:dev와 같은 검사), 스키마는 public이다.
// 메시지에 연결 문자열 같은 값을 넣지 않는다.
export function assertCheckLedgerTarget(target: {
  nodeEnv: string | undefined;
  supabaseUrl: string | undefined;
  devProjectRef: string;
  databaseUrl: string | undefined;
  testDbFlag: string | undefined;
}): 'test' | 'dev' {
  const schema = schemaOf(target.databaseUrl);
  if (target.testDbFlag === '1') {
    if (target.nodeEnv === 'production') {
      throw new SeedError('운영 환경에서는 장부 검산을 돌리지 않아요.');
    }
    if (schema === null || schema === 'public') {
      throw new SeedError(
        '테스트 DB로 알려졌지만 스키마가 public이에요. 개발 DB를 보호하려고 중단해요.',
      );
    }
    return 'test';
  }
  try {
    assertDevTarget({
      nodeEnv: target.nodeEnv,
      supabaseUrl: target.supabaseUrl,
      devProjectRef: target.devProjectRef,
    });
  } catch (error) {
    // seed:dev의 검사를 그대로 쓰므로 메시지가 "개발 계정"을 말한다. 무엇을 거부했는지 먼저 알린다.
    if (error instanceof SeedError) {
      throw new SeedError(
        `장부 검산은 개발·테스트 DB에서만 돌아요. ${error.message}`,
      );
    }
    throw error;
  }
  if (schema !== null && schema !== 'public') {
    throw new SeedError(
      `DATABASE_URL의 스키마(${schema})가 개발 DB의 public이 아니에요. 테스트 스키마는 node scripts/with-test-db.js yarn check:ledger로 확인하세요.`,
    );
  }
  return 'dev';
}

// DATABASE_URL의 ?schema= 값. 없으면 public으로 본다(null은 주소를 알아볼 수 없는 경우).
function schemaOf(databaseUrl: string | undefined): string | null {
  if (!databaseUrl) return null;
  try {
    return new URL(databaseUrl).searchParams.get('schema') ?? 'public';
  } catch {
    return null;
  }
}
