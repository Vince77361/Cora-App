import { PrismaClient } from '@prisma/client';
import { config } from 'dotenv';
import { PrismaDevUsers } from '../seed/lib/dev-users';
import { assertDevTarget, readDevProjectRef } from '../seed/lib/dev-target';
import { runSeedDev } from '../seed/lib/seed-dev';
import { HttpSupabaseAdmin, SeedError } from '../seed/lib/supabase-admin';

// api/.env를 읽는다. 값은 코드에서 출력하지 않는다.
config({ quiet: true });

async function main(): Promise<void> {
  const { NODE_ENV, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = process.env;
  const devProjectRef = readDevProjectRef();
  // 키가 비었는지보다 먼저, 개발 환경·개발 프로젝트가 맞는지부터 확인한다.
  assertDevTarget({
    nodeEnv: NODE_ENV,
    supabaseUrl: SUPABASE_URL,
    devProjectRef,
  });
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    throw new SeedError('api/.env에 SUPABASE_SERVICE_ROLE_KEY 값이 필요해요.');
  }
  const prisma = new PrismaClient();
  try {
    await runSeedDev({
      nodeEnv: NODE_ENV,
      supabaseUrl: SUPABASE_URL,
      devProjectRef,
      admin: new HttpSupabaseAdmin(
        SUPABASE_URL ?? '',
        SUPABASE_SERVICE_ROLE_KEY,
      ),
      users: new PrismaDevUsers(prisma),
      log: (line) => console.log(line),
    });
  } finally {
    await prisma.$disconnect();
  }
}

main().then(
  () => process.exit(0),
  (error: unknown) => {
    // 사용자에게 보여줘도 되는 메시지만 출력한다. 그 밖의 오류는 종류만 알리고 자세한 값은 숨긴다.
    if (error instanceof SeedError) {
      console.error(error.message);
    } else {
      const name = error instanceof Error ? error.name : 'UnknownError';
      console.error(`개발 계정 시드가 실패했어요. (${name})`);
    }
    process.exit(1);
  },
);
