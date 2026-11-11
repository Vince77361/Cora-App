import { Module, OnModuleInit } from '@nestjs/common';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { InstagramModule } from '../instagram/instagram.module';
import { IntegrationsModule } from '../integrations/integrations.module';
import { JobHandlerRegistry } from '../jobs/job-handler-registry';
import { JobsModule } from '../jobs/jobs.module';
import { LedgerModule } from '../ledger/ledger.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PaymentsModule } from '../payments/payments.module';
import { PayoutAccountsModule } from '../payout-accounts/payout-accounts.module';
import { UsersModule } from '../users/users.module';
import { PayoutSendHandler } from './jobs/payout-send.handler';
import { RefundUnsubmittedHandler } from './jobs/refund-unsubmitted.handler';
import { SettleHandler } from './jobs/settle.handler';
import { SubmitReminderHandler } from './jobs/submit-reminder.handler';
import { ViewSnapshotHandler } from './jobs/view-snapshot.handler';
import { DeadlinesService } from './deadlines.service';
import { PayoutsService } from './payouts.service';
import { RefundsService } from './refunds.service';
import { SettlementsRepository } from './settlements.repository';
import { SettlementsService } from './settlements.service';
import { SubmissionsController } from './submissions.controller';
import { SubmissionsService } from './submissions.service';

// 링크 제출, 조회수 집계, 정산, 지급, 환급. 이 모듈의 작업 처리기는 여기서 작업 큐의 표에 올린다.
@Module({
  imports: [
    CollaborationsModule,
    JobsModule,
    NotificationsModule,
    IntegrationsModule,
    InstagramModule,
    CreatorsModule,
    UsersModule,
    LedgerModule,
    PaymentsModule,
    PayoutAccountsModule,
  ],
  controllers: [SubmissionsController],
  providers: [
    SettlementsRepository,
    SettlementsService,
    SubmissionsService,
    PayoutsService,
    RefundsService,
    DeadlinesService,
    ViewSnapshotHandler,
    SettleHandler,
    PayoutSendHandler,
    RefundUnsubmittedHandler,
    SubmitReminderHandler,
  ],
  exports: [SettlementsService],
})
export class SettlementsModule implements OnModuleInit {
  constructor(
    private readonly registry: JobHandlerRegistry,
    private readonly viewSnapshot: ViewSnapshotHandler,
    private readonly settle: SettleHandler,
    private readonly payoutSend: PayoutSendHandler,
    private readonly refundUnsubmitted: RefundUnsubmittedHandler,
    private readonly submitReminder: SubmitReminderHandler,
  ) {}

  onModuleInit(): void {
    this.registry.register('view-snapshot', (p) => this.viewSnapshot.run(p));
    this.registry.register('settle', (p) => this.settle.run(p));
    this.registry.register('payout-send', (p) => this.payoutSend.run(p));
    this.registry.register('refund-unsubmitted', (p) =>
      this.refundUnsubmitted.run(p),
    );
    this.registry.register('submit-reminder', (p) =>
      this.submitReminder.run(p),
    );
  }
}
