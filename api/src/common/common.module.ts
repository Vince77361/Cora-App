import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Clock, SystemClock } from './clock';
import { SecretBox } from './crypto/secret-box';

// 모든 모듈이 import 없이 Clock을 주입받도록 전역으로 둔다.
// ConfigService는 없어도 동작하게(optional) 해서, 설정 없이 CommonModule만 쓰는 테스트가 깨지지 않게 한다.
@Global()
@Module({
  providers: [
    {
      provide: Clock,
      inject: [{ token: ConfigService, optional: true }],
      useFactory: (config?: ConfigService): Clock => {
        // 시계 앞당기기는 개발에서만 적용한다. 다른 환경에서는 값이 있어도 무시한다(운영은 시작 단계에서 거부된다).
        const offset =
          config?.get<string>('NODE_ENV') === 'development'
            ? Number(config.get('FAKE_CLOCK_OFFSET_DAYS') ?? 0)
            : 0;
        return new SystemClock(Number.isFinite(offset) ? offset : 0);
      },
    },
    // 봉하고 여는 도우미. 키(PAYOUT_ACCOUNT_KEY)가 없으면 isConfigured()가 false이고, 쓰려 하면 오류가 난다.
    {
      provide: SecretBox,
      inject: [{ token: ConfigService, optional: true }],
      useFactory: (config?: ConfigService): SecretBox =>
        new SecretBox(config?.get<string>('PAYOUT_ACCOUNT_KEY')),
    },
  ],
  exports: [Clock, SecretBox],
})
export class CommonModule {}
