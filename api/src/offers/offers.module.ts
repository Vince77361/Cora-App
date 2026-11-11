import { Module, OnModuleInit } from '@nestjs/common';
import { ApplicationsModule } from '../applications/applications.module';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { InstagramModule } from '../instagram/instagram.module';
import { JobHandlerRegistry } from '../jobs/job-handler-registry';
import { JobsModule } from '../jobs/jobs.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { StoresModule } from '../stores/stores.module';
import { UsersModule } from '../users/users.module';
import { DeclineNoticeHandler } from './jobs/decline-notice.handler';
import { PaymentDueExpiryHandler } from './jobs/payment-due-expiry.handler';
import { OffersController } from './offers.controller';
import { OffersRepository } from './offers.repository';
import { OffersService } from './offers.service';

@Module({
  imports: [
    NotificationsModule,
    JobsModule,
    UsersModule,
    StoresModule,
    CreatorsModule,
    ApplicationsModule,
    CollaborationsModule,
    InstagramModule,
  ],
  controllers: [OffersController],
  providers: [
    OffersService,
    OffersRepository,
    DeclineNoticeHandler,
    PaymentDueExpiryHandler,
  ],
  // 3번 계획(결제)이 오퍼 상태를 읽고 바꿀 때 쓴다.
  exports: [OffersService],
})
export class OffersModule implements OnModuleInit {
  constructor(
    private readonly registry: JobHandlerRegistry,
    private readonly declineNotice: DeclineNoticeHandler,
    private readonly paymentDueExpiry: PaymentDueExpiryHandler,
  ) {}

  // 오퍼가 맡은 작업의 처리기를 작업 큐의 표에 올린다(jobs 모듈은 기능 모듈을 모른다).
  onModuleInit(): void {
    this.registry.register('decline-notice', (p) => this.declineNotice.run(p));
    this.registry.register('payment-due-expiry', (p) =>
      this.paymentDueExpiry.run(p),
    );
  }
}
