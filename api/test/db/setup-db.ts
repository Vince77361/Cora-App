import { PrismaClient } from '@prisma/client';

// db-spec마다 같은 클라이언트를 쓰도록 한 곳에서 만든다.
export const prisma = new PrismaClient();

// 테스트끼리 데이터가 섞이지 않게 current_schema()의 모든 테이블을 비운다.
// 스키마 이름은 URL에서 오므로 코드에 박지 않는다. 마이그레이션 기록은 남긴다.
beforeEach(async () => {
  const tables = await prisma.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = current_schema() AND tablename <> '_prisma_migrations'`;
  if (tables.length === 0) return;
  const list = tables
    .map((t) => `"${t.tablename.replace(/"/g, '""')}"`)
    .join(', ');
  await prisma.$executeRawUnsafe(`TRUNCATE ${list} CASCADE`);
});

afterAll(async () => {
  await prisma.$disconnect();
});
