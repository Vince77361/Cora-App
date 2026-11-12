import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Clock } from '../common/clock';
import { IntegrationsModule } from '../integrations/integrations.module';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { BullMqJobScheduler } from './bullmq-job-scheduler';
import { JobHandlerRegistry } from './job-handler-registry';
import { JobScheduler } from './job-scheduler';
import { redisConnectionFromUrl } from './redis-connection';

// 테스트(NODE_ENV=test)에서는 Redis에 연결하지 않는다. 이 구현이 그대로 쓰이면 FakeJobScheduler로
// 바꿔 끼우지 않은 것이므로, 작업이 조용히 사라지지 않게 오류로 알려 준다.
class UnconfiguredJobScheduler extends JobScheduler {
  schedule(): Promise<void> {
    return Promise.reject(this.error());
  }
  cancel(): Promise<void> {
    return Promise.reject(this.error());
  }
  private error(): Error {
    return new Error(
      '테스트에서는 JobScheduler를 FakeJobScheduler로 바꿔 끼워야 해요. createTestApp을 쓰세요.',
    );
  }
}

// 작업자를 켤지. 어느 쪽이든 off면 끈다.
// 설정값(configured)은 AppModule을 import하는 순간 .env와 process.env를 읽어 굳어지므로, 그 뒤에 process.env를 바꿔도 반영되지 않는다.
// 운영 명령(ops-main)이 시작 직전에 정하는 process.env 값을 이 시점에 직접 읽어, 셸이나 .env가 on이어도 운영 명령은 작업자를 띄우지 않게 한다.
export function workerEnabled(
  configured: string | undefined,
  fromProcessEnv: string | undefined,
): boolean {
  return configured !== 'off' && fromProcessEnv !== 'off';
}

// 기능 모듈은 이 모듈을 import해서 JobScheduler(작업 등록)와 JobHandlerRegistry(onModuleInit에서 처리기 등록)를 쓴다.
@Module({
  imports: [IntegrationsModule],
  providers: [
    JobHandlerRegistry,
    {
      provide: JobScheduler,
      inject: [ConfigService, Clock, JobHandlerRegistry, OperatorAlertPort],
      useFactory: (
        config: ConfigService,
        clock: Clock,
        registry: JobHandlerRegistry,
        operatorAlert: OperatorAlertPort,
      ): JobScheduler => {
        if (config.get<string>('NODE_ENV') === 'test') {
          return new UnconfiguredJobScheduler();
        }
        const url = config.get<string>('REDIS_URL');
        if (!url) throw new Error('REDIS_URL이 없어요.');
        return BullMqJobScheduler.create(
          redisConnectionFromUrl(url),
          clock,
          registry,
          operatorAlert,
          // 운영 명령(yarn ops)은 작업을 올리기만 한다: 작업자는 서버 프로세스에서만 돈다.
          {
            worker: workerEnabled(
              config.get<string>('JOBS_WORKER'),
              process.env.JOBS_WORKER,
            ),
          },
        );
      },
    },
  ],
  exports: [JobScheduler, JobHandlerRegistry],
})
export class JobsModule {}
