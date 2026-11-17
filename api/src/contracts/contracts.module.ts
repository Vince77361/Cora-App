import { Module, OnModuleInit } from '@nestjs/common';
import { BrandsModule } from '../brands/brands.module';
import { CampaignsModule } from '../campaigns/campaigns.module';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { CreatorsModule } from '../creators/creators.module';
import { IntegrationsModule } from '../integrations/integrations.module';
import { JobsModule } from '../jobs/jobs.module';
import { LedgerModule } from '../ledger/ledger.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { BrandPayments } from '../payments/brand-payments';
import { PaymentsModule } from '../payments/payments.module';
import { SettlementsModule } from '../settlements/settlements.module';
import { TermsModule } from '../terms/terms.module';
import { BrandContractPayments } from './brand-contract-payments';
import { ContractsController } from './contracts.controller';
import { ContractsRepository } from './contracts.repository';
import { ContractsService } from './contracts.service';

// 브랜드 계약의 동의와 결제. 결제 모듈과 정산 모듈이 이 모듈을 import하지 않으므로 순환이 없다:
// 결제가 승인되면 결제 모듈이 여기서 등록한 처리기(BrandPayments)를 불러 계약을 체결한다.
@Module({
  imports: [
    CollaborationsModule,
    TermsModule,
    PaymentsModule,
    SettlementsModule,
    LedgerModule,
    ConversationsModule,
    NotificationsModule,
    JobsModule,
    IntegrationsModule,
    BrandsModule,
    CreatorsModule,
    CampaignsModule,
  ],
  controllers: [ContractsController],
  providers: [ContractsService, ContractsRepository, BrandContractPayments],
})
export class ContractsModule implements OnModuleInit {
  constructor(
    private readonly brandPayments: BrandPayments,
    private readonly handler: BrandContractPayments,
  ) {}

  onModuleInit(): void {
    this.brandPayments.register(this.handler);
  }
}
