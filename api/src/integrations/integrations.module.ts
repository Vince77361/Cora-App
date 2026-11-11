import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppError } from '../common/errors/app-error';
import { FakePushAdapter } from './push/fake-push.adapter';
import { PushPort } from './push/push.port';

@Module({
  providers: [
    {
      provide: PushPort,
      inject: [ConfigService],
      useFactory: (config: ConfigService): PushPort => {
        const adapter = config.get<string>('PUSH_ADAPTER');
        if (adapter === 'fake') return new FakePushAdapter();
        throw new AppError(
          'INTERNAL',
          '실제 푸시 연동은 아직 구현되지 않았어요.',
        );
      },
    },
  ],
  exports: [PushPort],
})
export class IntegrationsModule {}
