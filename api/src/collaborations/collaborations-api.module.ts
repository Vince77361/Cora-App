import { Module, OnModuleInit } from '@nestjs/common';
import { CreatorsModule } from '../creators/creators.module';
import { JobHandlerRegistry } from '../jobs/job-handler-registry';
import { JobsModule } from '../jobs/jobs.module';
import { LedgerModule } from '../ledger/ledger.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { OffersModule } from '../offers/offers.module';
import { PaymentsModule } from '../payments/payments.module';
import { PayoutAccountsModule } from '../payout-accounts/payout-accounts.module';
import { SettlementsModule } from '../settlements/settlements.module';
import { StoresModule } from '../stores/stores.module';
import { CancelRequestsRepository } from './cancel-requests.repository';
import { CollaborationsController } from './collaborations.controller';
import { CollaborationsModule } from './collaborations.module';
import { CollaborationsService } from './collaborations.service';
import { CancelRequestExpiryHandler } from './jobs/cancel-request-expiry.handler';
import { SubmissionsController } from './submissions.controller';

// 협업을 읽고 결제 뒤에 그만두는 API. 결제·정산·장부·계좌·알림 모듈을 모두 쓰므로 그 모듈들이 import하는
// 기본 CollaborationsModule과 따로 둔다(원장 판단 R10): 이 모듈은 아무도 import하지 않아 순환이 없다.
@Module({
  imports: [
    CollaborationsModule,
    SettlementsModule,
    PaymentsModule,
    LedgerModule,
    PayoutAccountsModule,
    NotificationsModule,
    JobsModule,
    OffersModule,
    StoresModule,
    CreatorsModule,
  ],
  controllers: [CollaborationsController, SubmissionsController],
  providers: [
    CollaborationsService,
    CancelRequestsRepository,
    CancelRequestExpiryHandler,
  ],
})
export class CollaborationsApiModule implements OnModuleInit {
  constructor(
    private readonly registry: JobHandlerRegistry,
    private readonly cancelRequestExpiry: CancelRequestExpiryHandler,
  ) {}

  // 취소 요청 만료 작업의 처리기를 작업 큐의 표에 올린다(jobs 모듈은 기능 모듈을 모른다).
  onModuleInit(): void {
    this.registry.register('cancel-request-expiry', (p) =>
      this.cancelRequestExpiry.run(p),
    );
  }
}
