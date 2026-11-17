import { Module } from '@nestjs/common';
import { BrandsModule } from '../brands/brands.module';
import { CampaignsModule } from '../campaigns/campaigns.module';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { CreatorsModule } from '../creators/creators.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrinciplesModule } from '../principles/principles.module';
import { NegotiationService } from './negotiation.service';
import { TermsController } from './terms.controller';
import { TermsModule } from './terms.module';

// 조건 판본을 당사자에게 보여 주고 확인받고 새로 내는 API(06·12 화면, 수정 제안).
// 확인과 새 판본은 대화방에 안내 줄을 남기므로 ConversationsModule을 쓴다. 그 모듈이 TermsModule을 import하기 때문에
// 이 모듈은 TermsModule과 따로 둔다. 아무도 이 모듈을 import하지 않아 순환이 없다.
@Module({
  imports: [
    TermsModule,
    CollaborationsModule,
    CampaignsModule,
    BrandsModule,
    CreatorsModule,
    PrinciplesModule,
    NotificationsModule,
    ConversationsModule,
  ],
  controllers: [TermsController],
  providers: [NegotiationService],
})
export class TermsApiModule {}
