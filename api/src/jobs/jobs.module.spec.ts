import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { CommonModule } from '../common/common.module';
import { JobHandlerRegistry } from './job-handler-registry';
import { JobScheduler } from './job-scheduler';
import { JobsModule } from './jobs.module';

describe('JobsModule', () => {
  it('does not open Redis connections when NODE_ENV is test', async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          ignoreEnvFile: true,
          ignoreEnvVars: true,
          load: [
            () => ({
              NODE_ENV: 'test',
              REDIS_URL: 'redis://127.0.0.1:1',
              // JobsModule이 운영자 알림 포트를 쓰려고 IntegrationsModule을 import하므로, 그 모듈의 어댑터 설정이 필요하다.
              SUPABASE_URL: 'https://fake.supabase.co',
              PUSH_ADAPTER: 'fake',
              STORE_LINK_ADAPTER: 'fake',
              CONTENT_DRAFT_ADAPTER: 'fake',
              PAYMENT_ADAPTER: 'fake',
              PAYOUT_ADAPTER: 'fake',
              VIEW_COUNT_ADAPTER: 'fake',
              INSTAGRAM_ADAPTER: 'fake',
              OPERATOR_ALERT_ADAPTER: 'fake',
            }),
          ],
        }),
        CommonModule,
        JobsModule,
      ],
    }).compile();
    await moduleRef.init();
    expect(moduleRef.get(JobHandlerRegistry)).toBeInstanceOf(
      JobHandlerRegistry,
    );
    // 테스트 환경의 기본 구현은 연결 없이, 쓰려 하면 FakeJobScheduler로 바꿔 끼우라고 알려 준다.
    await expect(
      moduleRef
        .get(JobScheduler)
        .schedule('settle', { collaborationId: 'c' }, new Date(), 'k'),
    ).rejects.toThrow(/FakeJobScheduler/);
    await moduleRef.close();
  });

  describe('worker switch', () => {
    const config = (jobsWorker: string) => ({
      isGlobal: true,
      ignoreEnvFile: true,
      ignoreEnvVars: true,
      load: [
        () => ({
          NODE_ENV: 'development',
          // 연결되지 않는 주소: 작업자를 시작하지 않으므로 큐 객체만 만들고 닫는다.
          REDIS_URL: 'redis://127.0.0.1:1',
          JOBS_WORKER: jobsWorker,
          SUPABASE_URL: 'https://fake.supabase.co',
          PUSH_ADAPTER: 'fake',
          STORE_LINK_ADAPTER: 'fake',
          CONTENT_DRAFT_ADAPTER: 'fake',
          PAYMENT_ADAPTER: 'fake',
          PAYOUT_ADAPTER: 'fake',
          VIEW_COUNT_ADAPTER: 'fake',
          INSTAGRAM_ADAPTER: 'fake',
          OPERATOR_ALERT_ADAPTER: 'fake',
        }),
      ],
    });
    const workerOf = async (jobsWorker: string, processEnv?: string) => {
      const saved = process.env.JOBS_WORKER;
      if (processEnv === undefined) delete process.env.JOBS_WORKER;
      else process.env.JOBS_WORKER = processEnv;
      try {
        const moduleRef = await Test.createTestingModule({
          imports: [
            ConfigModule.forRoot(config(jobsWorker)),
            CommonModule,
            JobsModule,
          ],
        }).compile();
        const scheduler = moduleRef.get<{ real: { worker: boolean } }>(
          JobScheduler,
        );
        const worker = scheduler.real.worker;
        // init하지 않았으므로 작업자는 시작되지 않았다. 큐 연결만 닫는다.
        await moduleRef.close();
        return worker;
      } finally {
        if (saved === undefined) delete process.env.JOBS_WORKER;
        else process.env.JOBS_WORKER = saved;
      }
    };

    it('turns the worker off for ops commands even when the validated config says on', async () => {
      // ops-main이 process.env를 off로 덮어써도 ConfigModule이 굳힌 값은 on이다.
      await expect(workerOf('on', 'off')).resolves.toBe(false);
    });

    it('keeps the worker on for the server and off when the config says off', async () => {
      await expect(workerOf('on', undefined)).resolves.toBe(true);
      await expect(workerOf('off', undefined)).resolves.toBe(false);
    });
  });
});
