import { config as loadDotenv } from 'dotenv';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { setupApp } from './app.setup';
import { loadEnv } from './config/env';
import { assertNoFakesInProduction } from './integrations/assert-no-fakes';
import { assertWorkerOnInProduction } from './jobs/assert-worker';

const SHUTDOWN_TIMEOUT_MS = 10_000;

async function bootstrap() {
  // Nest가 .env를 읽기 전에 검사해야 하므로 여기서 먼저 올린다. 셸에 이미 있는 값은 덮어쓰지 않는다.
  loadDotenv({ quiet: true });
  // 운영에서 가짜 연동이 켜진 채로는 앱이 뜨지 않게 listen 전에 막는다.
  const env = loadEnv(process.env);
  assertNoFakesInProduction(env);
  // 작업자를 끈 운영 서버는 정산·지급·환급이 멈추므로 시작하지 않는다.
  assertWorkerOnInProduction(env);
  // 결제 통지의 서명은 받은 본문 그대로에 대한 것이라 원본 본문(rawBody)을 함께 보관한다.
  const app = await NestFactory.create(AppModule, { rawBody: true });
  setupApp(app, { env });
  // 종료 신호를 받으면 새 요청을 멈추고 DB 연결과 작업 큐 작업자를 닫은 뒤 종료 코드 0으로 끝낸다. 배포 때 처리 중인 작업이 끊기지 않게 한다.
  // enableShutdownHooks()는 닫은 뒤 같은 신호를 자기 자신에게 다시 보내 종료 코드가 143이 되므로(배포 도구가 실패로 읽는다) 직접 처리한다.
  // 신호가 연달아 와도(SIGINT 뒤 SIGTERM 등) 닫기는 한 번만 한다.
  let closing = false;
  for (const signal of ['SIGTERM', 'SIGINT'] as const) {
    process.on(signal, () => {
      if (closing) return;
      closing = true;
      // 닫는 데 걸리는 시간에 상한을 둔다. 넘으면 실패로 끝내 호스팅이 강제로 죽이기 전에 원인을 남긴다.
      setTimeout(() => {
        console.error(
          `종료가 ${SHUTDOWN_TIMEOUT_MS / 1000}초 안에 끝나지 않았어요.`,
        );
        process.exit(1);
      }, SHUTDOWN_TIMEOUT_MS).unref();
      app.close().then(
        () => process.exit(0),
        (error: unknown) => {
          console.error('종료 중 오류가 났어요.', error);
          process.exit(1);
        },
      );
    });
  }
  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
