import { config as loadDotenv } from 'dotenv';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { setupApp } from './app.setup';
import { loadEnv } from './config/env';
import { assertNoFakesInProduction } from './integrations/assert-no-fakes';

async function bootstrap() {
  // Nest가 .env를 읽기 전에 검사해야 하므로 여기서 먼저 올린다. 셸에 이미 있는 값은 덮어쓰지 않는다.
  loadDotenv({ quiet: true });
  // 운영에서 가짜 연동이 켜진 채로는 앱이 뜨지 않게 listen 전에 막는다.
  assertNoFakesInProduction(loadEnv(process.env));
  const app = await NestFactory.create(AppModule);
  setupApp(app);
  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
