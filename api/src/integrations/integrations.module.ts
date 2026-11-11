import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { ContentDraftPort } from './content-draft/content-draft.port';
import { FakeContentDraftAdapter } from './content-draft/fake-content-draft.adapter';
import { FakeInstagramAdapter } from './instagram/fake-instagram.adapter';
import { InstagramPort } from './instagram/instagram.port';
import { FakeOperatorAlertAdapter } from './operator-alert/fake-operator-alert.adapter';
import { OperatorAlertPort } from './operator-alert/operator-alert.port';
import { FakePaymentAdapter } from './payment/fake-payment.adapter';
import { PaymentPort } from './payment/payment.port';
import { FakePayoutAdapter } from './payout/fake-payout.adapter';
import { PayoutPort } from './payout/payout.port';
import { FakeViewCountAdapter } from './view-count/fake-view-count.adapter';
import { ViewCountPort } from './view-count/view-count.port';
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
    // real 구현은 "실제 연동 교체" 계획에서 만든다. 그 전에 real을 고르면 조용히 가짜로 돌지 않고 시작을 거부한다.
    {
      provide: PaymentPort,
      inject: [ConfigService],
      useFactory: (config: ConfigService): PaymentPort => {
        const adapter = config.get<string>('PAYMENT_ADAPTER');
        if (adapter === 'fake') {
          return new FakePaymentAdapter(
            config.get<string>('PAYMENT_WEBHOOK_SECRET') || undefined,
          );
        }
        throw new AppError(
          'INTERNAL',
          '실제 결제 연동은 아직 구현되지 않았어요.',
        );
      },
    },
    {
      provide: PayoutPort,
      inject: [ConfigService],
      useFactory: (config: ConfigService): PayoutPort => {
        const adapter = config.get<string>('PAYOUT_ADAPTER');
        if (adapter === 'fake') return new FakePayoutAdapter();
        throw new AppError(
          'INTERNAL',
          '실제 송금 연동은 아직 구현되지 않았어요.',
        );
      },
    },
    {
      provide: ViewCountPort,
      inject: [ConfigService, Clock],
      useFactory: (config: ConfigService, clock: Clock): ViewCountPort => {
        const adapter = config.get<string>('VIEW_COUNT_ADAPTER');
        if (adapter === 'fake') return new FakeViewCountAdapter(clock);
        throw new AppError(
          'INTERNAL',
          '실제 조회수 연동은 아직 구현되지 않았어요.',
        );
      },
    },
    {
      provide: InstagramPort,
      inject: [ConfigService],
      useFactory: (config: ConfigService): InstagramPort => {
        const adapter = config.get<string>('INSTAGRAM_ADAPTER');
        if (adapter === 'fake') return new FakeInstagramAdapter();
        throw new AppError(
          'INTERNAL',
          '실제 인스타그램 연동은 아직 구현되지 않았어요.',
        );
      },
    },
    {
      provide: OperatorAlertPort,
      inject: [ConfigService],
      useFactory: (config: ConfigService): OperatorAlertPort => {
        const adapter = config.get<string>('OPERATOR_ALERT_ADAPTER');
        if (adapter === 'fake') return new FakeOperatorAlertAdapter();
        throw new AppError(
          'INTERNAL',
          '실제 운영자 알림 연동은 아직 구현되지 않았어요.',
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
  exports: [
    PushPort,
    StoragePort,
    StoreLinkPort,
    ContentDraftPort,
    PaymentPort,
    PayoutPort,
    ViewCountPort,
    InstagramPort,
    OperatorAlertPort,
  ],
})
export class IntegrationsModule {}
