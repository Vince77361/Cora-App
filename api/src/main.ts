import { config as loadDotenv } from 'dotenv';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { setupApp } from './app.setup';
import { loadEnv } from './config/env';
import { assertNoFakesInProduction } from './integrations/assert-no-fakes';
import { assertWorkerOnInProduction } from './jobs/assert-worker';

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
  setupApp(app);
  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
