import { config as loadDotenv } from 'dotenv';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { loadEnv } from './config/env';
import { assertNoFakesInProduction } from './integrations/assert-no-fakes';
import { parseOpsArgs, usageLines } from './ops/ops-args';
import { OpsRunner } from './ops/ops.runner';

// 운영 명령(yarn ops)의 진입점. 서버와 같은 환경변수 검증을 거치고, HTTP로 열지 않는다.
async function main(): Promise<number> {
  // 틀린 명령줄은 서버를 띄우기 전에(DB와 Redis에 닿기 전에) 거절한다.
  const parsed = parseOpsArgs(process.argv.slice(2));
  if (!parsed.ok) {
    console.error([parsed.error, '', ...usageLines()].join('\n'));
    return 1;
  }
  loadDotenv({ quiet: true });
  // 작업을 올리기만 하고 실행하지 않는다: 작업자는 서버 프로세스에서만 돈다.
  // 셸에 on이 적혀 있어도 덮어쓴다(운영 명령 안에서 작업이 돌면 같은 작업이 두 곳에서 돌 수 있다).
  process.env.JOBS_WORKER = 'off';
  // 운영에서 가짜 연동이 켜진 채로는 명령이 돌지 않게 서버와 같은 검사를 한다.
  assertNoFakesInProduction(loadEnv(process.env));
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn'],
  });
  try {
    const { exitCode, output } = await app
      .get(OpsRunner)
      .execute(parsed.command);
    (exitCode === 0 ? console.log : console.error)(output.join('\n'));
    return exitCode;
  } finally {
    // 큐와 DB 연결을 닫아야 프로세스가 끝난다.
    await app.close();
  }
}

main().then(
  (code) => process.exit(code),
  (error: unknown) => {
    // 알 수 없는 오류는 종류만 알린다(연결 문자열 같은 값이 새지 않게).
    console.error(
      `운영 명령이 실패했어요. (${error instanceof Error ? error.name : 'UnknownError'})`,
    );
    process.exit(1);
  },
);
