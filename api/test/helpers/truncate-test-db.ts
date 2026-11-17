import type { PrismaClient } from '@prisma/client';

// URL의 schema 파라미터. scripts/with-test-db.js가 cora_test로 맞춰 준다.
function expectedSchema(): string {
  const url = process.env.DATABASE_URL;
  if (!url)
    throw new Error('DATABASE_URL이 없어요. 테스트 실행기로 실행하세요.');
  return new URL(url).searchParams.get('schema') ?? 'public';
}

// 테스트 스키마의 모든 테이블을 비운다. 마이그레이션 기록은 남긴다.
// jest를 직접 돌리면 Prisma 클라이언트가 api/.env를 읽어 개발 DB의 public을 가리키므로,
// 실행기를 거쳤고 스키마가 확실히 테스트용일 때만 비운다.
// TRUNCATE는 상호작용 트랜잭션($transaction) 없이 문장 하나로 보낸다(자동 커밋). 원격 풀러를 거치면
// 상호작용 트랜잭션의 5초 제한이 먼저 끝나 COMMIT이 사라지고, 서버 세션이 idle in transaction으로 남아
// 모든 표의 락을 쥔 채 이후의 TRUNCATE를 막는다. 문장 하나라면 잃을 COMMIT이 없다.
export async function truncateTestDb(prisma: PrismaClient): Promise<void> {
  if (process.env.CORA_TEST_DB !== '1') {
    throw new Error(
      '테스트 DB 실행기를 거치지 않았어요. 개발 DB를 보호하려고 중단합니다. yarn test:db 또는 yarn test:e2e로 실행하세요.',
    );
  }
  const schema = expectedSchema();
  if (schema === 'public') {
    throw new Error(
      '테스트 스키마가 public이에요. 개발 DB를 보호하려고 중단합니다.',
    );
  }
  const [{ s }] = await prisma.$queryRaw<{ s: string }[]>`
    SELECT current_schema() AS s`;
  if (s !== schema) {
    throw new Error(
      `현재 스키마(${s})가 URL의 schema(${schema})와 달라요. 중단합니다.`,
    );
  }
  const tables = await prisma.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = ${schema} AND tablename <> '_prisma_migrations'`;
  if (tables.length === 0) return;
  const quote = (id: string) => `"${id.replace(/"/g, '""')}"`;
  // 모든 표를 스키마 이름까지 붙여 적어, 연결의 search_path가 어긋나도 다른 스키마를 비우지 않는다.
  const list = tables
    .map((t) => `${quote(schema)}.${quote(t.tablename)}`)
    .join(', ');
  await prisma.$executeRawUnsafe(`TRUNCATE ${list} CASCADE`);
}
