import type { Server } from 'http';
import { INestApplication, Type } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../src/app.module';
import { setupApp } from '../../src/app.setup';
import { Clock } from '../../src/common/clock';
import { TokenVerifier } from '../../src/auth/token-verifier';
import { JobHandlerRegistry } from '../../src/jobs/job-handler-registry';
import { JobScheduler } from '../../src/jobs/job-scheduler';
import { PushPort } from '../../src/integrations/push/push.port';
import { StoragePort } from '../../src/integrations/storage/storage.port';
import { FakeClock } from '../support/fake-clock';
import { FakeJobScheduler } from '../support/fake-job-scheduler';
import { FakePushPort } from '../support/fake-push.port';
import { FakeStoragePort } from '../support/fake-storage.port';
import { FakeTokenVerifier } from '../support/fake-token-verifier';

// 모든 e2e 테스트가 main.ts와 같은 setupApp을 거치도록 한 곳에서 앱을 만든다.
// 토큰 검증은 네트워크가 필요 없는 가짜로, 시계는 손으로 움직이는 FakeClock으로 바꿔 끼운다.
// 테스트에서 시계는 app.get<FakeClock>(Clock)으로, Storage는 app.get<FakeStoragePort>(StoragePort)로 꺼내 쓴다.
// Storage는 원격 Supabase에 닿지 않도록 항상 가짜로 바꾼다. 푸시는 app.get<FakePushPort>(PushPort).sent로 확인한다.
// 작업 큐는 Redis 없이 FakeJobScheduler로 바꾼다: app.get<FakeJobScheduler>(JobScheduler).runDue(시각).
// 결제·송금·조회수·인스타그램·운영자 알림은 NODE_ENV=test에서 가짜 구현이 그대로 쓰이므로 app.get(PaymentPort) 등으로 꺼내 확인한다.
export async function createTestApp(
  extraControllers: Type<unknown>[] = [],
): Promise<INestApplication> {
  const moduleRef = await Test.createTestingModule({
    imports: [AppModule],
    controllers: extraControllers,
  })
    .overrideProvider(TokenVerifier)
    .useClass(FakeTokenVerifier)
    .overrideProvider(Clock)
    .useValue(new FakeClock())
    .overrideProvider(StoragePort)
    .useValue(new FakeStoragePort())
    .overrideProvider(PushPort)
    .useValue(new FakePushPort())
    .overrideProvider(JobScheduler)
    .useFactory({
      factory: (registry: JobHandlerRegistry) => new FakeJobScheduler(registry),
      inject: [JobHandlerRegistry],
    })
    .compile();
  // main.ts와 같게 원본 본문을 보관한다(결제 웹훅 서명 검증).
  const app = moduleRef.createNestApplication({ rawBody: true });
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
