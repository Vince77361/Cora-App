import { Module } from '@nestjs/common';
import { BrandsModule } from '../brands/brands.module';
import { CampaignsModule } from '../campaigns/campaigns.module';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrinciplesModule } from '../principles/principles.module';
import { NegotiationService } from './negotiation.service';
import { TermsController } from './terms.controller';
import { TermsRepository } from './terms.repository';
import { TermsService } from './terms.service';

// 조건 판본. 서로 관심 트랜잭션(발견)과 새 판본 제안(5번 계획)이 TermsService만 쓴다.
@Module({
  imports: [
    CollaborationsModule,
    CampaignsModule,
    BrandsModule,
    CreatorsModule,
    PrinciplesModule,
    NotificationsModule,
  ],
  controllers: [TermsController],
  providers: [TermsService, TermsRepository, NegotiationService],
  exports: [TermsService],
})
export class TermsModule {}
