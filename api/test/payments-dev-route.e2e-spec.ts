import { INestApplication, ModuleMetadata } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AuthModule } from '../src/auth/auth.module';
import { TokenVerifier } from '../src/auth/token-verifier';
import { Clock } from '../src/common/clock';
import { CommonModule } from '../src/common/common.module';
import { loadEnv } from '../src/config/env';
import { PushPort } from '../src/integrations/push/push.port';
import { StoragePort } from '../src/integrations/storage/storage.port';
import { JobHandlerRegistry } from '../src/jobs/job-handler-registry';
import { JobScheduler } from '../src/jobs/job-scheduler';
import {
  DevPaymentEnv,
  devPaymentRoutesEnabled,
  PaymentsDevModule,
} from '../src/payments/payments-dev.module';
import { PaymentsModule } from '../src/payments/payments.module';
import { PrismaModule } from '../src/prisma/prisma.module';
import { setupApp } from '../src/app.setup';
import { httpOf } from './helpers/create-test-app';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { FakeStoragePort } from './support/fake-storage.port';
import { FakeTokenVerifier } from './support/fake-token-verifier';

const PAYMENT_ID = '55555555-5555-4555-8555-555555555555';

// 개발 전용 가짜 결제 경로가 "운영 설정"이나 "실제 PG 설정"에서는 등록조차 되지 않는지 확인한다.
// 운영 환경변수 검증(loadEnv)을 느슨하게 하지 않으려고 AppModule을 운영 값으로 다시 만들지 않는다:
// 결제 모듈과 같은 의존만 가진 작은 앱을 만들고, 등록 조건은 PaymentsDevModule.register에 값을 직접 넘겨 바꾼다.
// 라우트가 없으면 로그인 여부와 상관없이 404이고, 있으면 로그인이 없을 때 401이다(전역 인증 가드가 먼저 막는다).
async function buildApp(env: DevPaymentEnv): Promise<INestApplication> {
  const imports: ModuleMetadata['imports'] = [
    ConfigModule.forRoot({ isGlobal: true, validate: loadEnv }),
    CommonModule,
    PrismaModule,
    AuthModule,
    PaymentsModule,
    PaymentsDevModule.register(env),
  ];
  const moduleRef = await Test.createTestingModule({ imports })
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
  const app = moduleRef.createNestApplication({ rawBody: true });
  app.useLogger(false);
  setupApp(app);
  await app.init();
  return app;
}

describe('devPaymentRoutesEnabled', () => {
  it('opens only for development or test with a fake (or unset) payment adapter', () => {
    expect(
      devPaymentRoutesEnabled({
        NODE_ENV: 'development',
        PAYMENT_ADAPTER: 'fake',
      }),
    ).toBe(true);
    expect(
      devPaymentRoutesEnabled({ NODE_ENV: 'test', PAYMENT_ADAPTER: 'fake' }),
    ).toBe(true);
    expect(devPaymentRoutesEnabled({ NODE_ENV: 'development' })).toBe(true);
    expect(
      devPaymentRoutesEnabled({ NODE_ENV: 'development', PAYMENT_ADAPTER: '' }),
    ).toBe(true);
  });

  it('stays closed in production, with the real adapter, or with an unknown environment', () => {
    expect(
      devPaymentRoutesEnabled({
        NODE_ENV: 'production',
        PAYMENT_ADAPTER: 'fake',
      }),
    ).toBe(false);
    expect(devPaymentRoutesEnabled({ NODE_ENV: 'production' })).toBe(false);
    expect(
      devPaymentRoutesEnabled({
        NODE_ENV: 'development',
        PAYMENT_ADAPTER: 'real',
      }),
    ).toBe(false);
    expect(
      devPaymentRoutesEnabled({ NODE_ENV: 'test', PAYMENT_ADAPTER: 'real' }),
    ).toBe(false);
    expect(devPaymentRoutesEnabled({})).toBe(false);
    expect(
      devPaymentRoutesEnabled({ NODE_ENV: 'staging', PAYMENT_ADAPTER: 'fake' }),
    ).toBe(false);
  });
});

describe('does not expose the dev approve route in production mode', () => {
  let app: INestApplication | undefined;
  afterEach(async () => {
    await app?.close();
    app = undefined;
  });

  const approve = (a: INestApplication) =>
    request(httpOf(a)).post(`/dev/fake-payments/${PAYMENT_ID}/approve`);

  it('registers the route in development with the fake adapter (it is guarded, so 401 without a token)', async () => {
    app = await buildApp({ NODE_ENV: 'development', PAYMENT_ADAPTER: 'fake' });
    await approve(app).expect(401);
    await request(httpOf(app))
      .post(`/dev/fake-payments/${PAYMENT_ID}/fail`)
      .expect(401);
  });

  it('has no route at all in an app built with production settings', async () => {
    app = await buildApp({ NODE_ENV: 'production', PAYMENT_ADAPTER: 'fake' });
    await approve(app).expect(404);
    await approve(app).set('Authorization', 'Bearer user-a').expect(404);
    await request(httpOf(app))
      .post(`/dev/fake-payments/${PAYMENT_ID}/fail`)
      .set('Authorization', 'Bearer user-a')
      .expect(404);
  });

  it('has no route when the payment adapter is real', async () => {
    app = await buildApp({ NODE_ENV: 'test', PAYMENT_ADAPTER: 'real' });
    await approve(app).expect(404);
    await approve(app).set('Authorization', 'Bearer user-a').expect(404);
  });

  it('keeps the public payment routes in the production-mode app', async () => {
    app = await buildApp({ NODE_ENV: 'production', PAYMENT_ADAPTER: 'real' });
    // 웹훅은 서명이 없으면 401이다(라우트가 있다는 뜻). 개발용 경로만 사라진다.
    await request(httpOf(app)).post('/webhooks/payments').send({}).expect(401);
  });
});
