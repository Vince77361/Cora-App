// 개발 DB(public 스키마)에 RLS가 빠진 테이블이나 정책이 있는지 확인한다.
// 트랜잭션 풀러(6543)는 세션 설정(search_path)이 다른 연결로 새어 current_schema()가 cora_test로 보일 수 있어
// 세션 풀러인 DIRECT_URL로 연결한다.
require('dotenv').config({ quiet: true });
process.env.PRISMA_HIDE_UPDATE_MESSAGE = '1';
const { PrismaClient } = require('@prisma/client');
const { TABLES_WITHOUT_RLS, POLICY_COUNT } = require('./rls-queries');

async function main() {
  const prisma = new PrismaClient({
    datasources: { db: { url: process.env.DIRECT_URL } },
  });
  try {
    const [{ s }] = await prisma.$queryRawUnsafe('SELECT current_schema() AS s');
    const missing = await prisma.$queryRawUnsafe(TABLES_WITHOUT_RLS);
    const [{ n }] = await prisma.$queryRawUnsafe(POLICY_COUNT);
    console.log(`스키마: ${s}`);
    console.log(`RLS가 꺼진 테이블: ${missing.length === 0 ? '없음' : missing.map((r) => r.relname).join(', ')}`);
    console.log(`정책 수: ${Number(n)}`);
    process.exitCode = missing.length > 0 || Number(n) > 0 ? 1 : 0;
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  console.error(`check:rls 실패: ${e.name}`);
  process.exit(1);
});
