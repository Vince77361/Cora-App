import type { Server } from 'http';
import { INestApplication, Type } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../src/app.module';
import { setupApp } from '../../src/app.setup';

// 모든 e2e 테스트가 main.ts와 같은 setupApp을 거치도록 한 곳에서 앱을 만든다.
export async function createTestApp(
  extraControllers: Type<unknown>[] = [],
): Promise<INestApplication> {
  const moduleRef = await Test.createTestingModule({
    imports: [AppModule],
    controllers: extraControllers,
  }).compile();
  const app = moduleRef.createNestApplication();
  // 예상된 오류 로그가 테스트 출력을 어지럽히지 않게 한다.
  app.useLogger(false);
  setupApp(app);
  await app.init();
  return app;
}

// getHttpServer()가 any를 돌려줘서 lint가 막히므로 타입을 좁혀 쓴다.
export function httpOf(app: INestApplication): Server {
  return app.getHttpServer() as Server;
}
