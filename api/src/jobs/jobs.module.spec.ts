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
});
