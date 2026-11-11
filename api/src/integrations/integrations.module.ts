import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppError } from '../common/errors/app-error';
import { ContentDraftPort } from './content-draft/content-draft.port';
import { FakeContentDraftAdapter } from './content-draft/fake-content-draft.adapter';
import { FakePushAdapter } from './push/fake-push.adapter';
import { PushPort } from './push/push.port';
import { FakeStoreLinkAdapter } from './store-link/fake-store-link.adapter';
import { StoreLinkPort } from './store-link/store-link.port';
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
    {
      provide: StoreLinkPort,
      inject: [ConfigService],
      useFactory: (config: ConfigService): StoreLinkPort => {
        const adapter = config.get<string>('STORE_LINK_ADAPTER');
        if (adapter === 'fake') return new FakeStoreLinkAdapter();
        throw new AppError(
          'INTERNAL',
          '실제 링크 분석 연동은 아직 구현되지 않았어요.',
        );
      },
    },
    {
      provide: ContentDraftPort,
      inject: [ConfigService],
      useFactory: (config: ConfigService): ContentDraftPort => {
        const adapter = config.get<string>('CONTENT_DRAFT_ADAPTER');
        if (adapter === 'fake') return new FakeContentDraftAdapter();
        throw new AppError(
          'INTERNAL',
          '실제 AI 초안 연동은 아직 구현되지 않았어요.',
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
  exports: [PushPort, StoragePort, StoreLinkPort, ContentDraftPort],
})
export class IntegrationsModule {}
