import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppError } from '../common/errors/app-error';
import { FakePushAdapter } from './push/fake-push.adapter';
import { PushPort } from './push/push.port';
import { StoragePort } from './storage/storage.port';
import { SupabaseStorageAdapter } from './storage/supabase-storage.adapter';

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
    // Storage는 가짜/실제 전환 대상이 아니다. 개발에서도 원격 Supabase의 실제 Storage를 쓰고,
    // 테스트는 StoragePort를 FakeStoragePort로 override한다.
    {
      provide: StoragePort,
      inject: [ConfigService],
      useFactory: (config: ConfigService): StoragePort =>
        new SupabaseStorageAdapter(
          config.get<string>('SUPABASE_URL'),
          config.get<string>('SUPABASE_SERVICE_ROLE_KEY'),
        ),
    },
  ],
  exports: [PushPort, StoragePort],
})
export class IntegrationsModule {}
