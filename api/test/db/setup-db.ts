import { PrismaClient } from '@prisma/client';

// db-spec마다 같은 클라이언트를 쓰도록 한 곳에서 만든다.
export const prisma = new PrismaClient();

// URL의 schema 파라미터. scripts/with-test-db.js가 cora_test로 맞춰 준다.
function expectedSchema(): string {
  const url = process.env.DATABASE_URL;
  if (!url)
    throw new Error('DATABASE_URL이 없어요. yarn test:db로 실행하세요.');
  return new URL(url).searchParams.get('schema') ?? 'public';
}

// 테스트끼리 데이터가 섞이지 않게 테스트 스키마의 모든 테이블을 비운다. 마이그레이션 기록은 남긴다.
// jest를 직접 돌리면 Prisma 클라이언트가 api/.env를 읽어 개발 DB의 public을 가리키므로,
// 실행기를 거쳤고 스키마가 확실히 테스트용일 때만 비운다.
beforeEach(async () => {
  if (process.env.CORA_TEST_DB !== '1') {
    throw new Error(
      '테스트 DB 실행기를 거치지 않았어요. 개발 DB를 보호하려고 중단합니다. yarn test:db로 실행하세요.',
    );
  }
  const schema = expectedSchema();
  if (schema === 'public') {
    throw new Error(
      '테스트 스키마가 public이에요. 개발 DB를 보호하려고 중단합니다.',
    );
  }
  await prisma.$transaction(async (tx) => {
    const [{ s }] = await tx.$queryRaw<{ s: string }[]>`
      SELECT current_schema() AS s`;
    if (s !== schema) {
      throw new Error(
        `현재 스키마(${s})가 URL의 schema(${schema})와 달라요. 중단합니다.`,
      );
    }
    const tables = await tx.$queryRaw<{ tablename: string }[]>`
      SELECT tablename FROM pg_tables
      WHERE schemaname = ${schema} AND tablename <> '_prisma_migrations'`;
    if (tables.length === 0) return;
    const quote = (id: string) => `"${id.replace(/"/g, '""')}"`;
    const list = tables
      .map((t) => `${quote(schema)}.${quote(t.tablename)}`)
      .join(', ');
    await tx.$executeRawUnsafe(`TRUNCATE ${list} CASCADE`);
  });
});

afterAll(async () => {
  await prisma.$disconnect();
});
