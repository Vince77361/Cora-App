import { Module, OnModuleInit } from '@nestjs/common';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { IntegrationsModule } from '../integrations/integrations.module';
import { JobHandlerRegistry } from '../jobs/job-handler-registry';
import { JobsModule } from '../jobs/jobs.module';
import { LedgerModule } from '../ledger/ledger.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { OffersModule } from '../offers/offers.module';
import { StoresModule } from '../stores/stores.module';
import { UsersModule } from '../users/users.module';
import { PaymentRecheckHandler } from './jobs/payment-recheck.handler';
import { PaymentsController } from './payments.controller';
import { PaymentsRepository } from './payments.repository';
import { PaymentsService } from './payments.service';
import { PaymentsWebhookController } from './payments.webhook.controller';

// 개발 전용 가짜 결제 경로는 PaymentsDevModule이 조건부로 붙인다.
@Module({
  imports: [
    CollaborationsModule,
    LedgerModule,
    OffersModule,
    JobsModule,
    NotificationsModule,
    IntegrationsModule,
    StoresModule,
    CreatorsModule,
    UsersModule,
  ],
  controllers: [PaymentsController, PaymentsWebhookController],
  providers: [PaymentsService, PaymentsRepository, PaymentRecheckHandler],
  // 브랜드 계약의 결제(5번 계획)와 운영 명령(10번 작업)이 쓴다.
  exports: [PaymentsService],
})
export class PaymentsModule implements OnModuleInit {
  constructor(
    private readonly registry: JobHandlerRegistry,
    private readonly recheck: PaymentRecheckHandler,
  ) {}

  onModuleInit(): void {
    this.registry.register('payment-recheck', (p) => this.recheck.run(p));
  }
}
