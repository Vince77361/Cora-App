import { config } from 'dotenv';
import { LedgerRepository } from '../src/ledger/ledger.repository';
import { LedgerService } from '../src/ledger/ledger.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { assertCheckLedgerTarget } from '../seed/lib/check-ledger-target';
import { readDevProjectRef } from '../seed/lib/dev-target';
import { SeedError } from '../seed/lib/supabase-admin';

// 연결된 DB의 모든 협업 장부가 불변식을 지키는지 읽기만 해서 확인한다(쓰지 않는다).
// api/.env를 읽는다. 값은 출력하지 않는다.
config({ quiet: true });

async function main(): Promise<number> {
  const { NODE_ENV, SUPABASE_URL, DATABASE_URL, CORA_TEST_DB } = process.env;
  // DB에 닿기 전에 개발·테스트 DB가 맞는지부터 확인한다.
  assertCheckLedgerTarget({
    nodeEnv: NODE_ENV,
    supabaseUrl: SUPABASE_URL,
    devProjectRef: readDevProjectRef(),
    databaseUrl: DATABASE_URL,
    testDbFlag: CORA_TEST_DB,
  });
  const prisma = new PrismaService();
  try {
    await prisma.$connect();
    const { checked, failures } = await new LedgerService(
      new LedgerRepository(prisma),
    ).checkAll();
    if (failures.length === 0) {
      console.log(`모든 협업의 장부가 맞습니다 (${checked}건)`);
      return 0;
    }
    console.error(
      `장부가 맞지 않는 협업이 ${failures.length}건이에요 (전체 ${checked}건).`,
    );
    for (const failure of failures) {
      console.error(`  협업 ${failure.collaborationId}: ${failure.message}`);
    }
    return 1;
  } finally {
    await prisma.$disconnect();
  }
}

main().then(
  (code) => process.exit(code),
  (error: unknown) => {
    // 사용자에게 보여줘도 되는 메시지만 출력한다. 그 밖의 오류는 종류만 알린다.
    if (error instanceof SeedError) {
      console.error(error.message);
    } else {
      const name = error instanceof Error ? error.name : 'UnknownError';
      console.error(`장부 검산이 실패했어요. (${name})`);
    }
    process.exit(1);
  },
);
