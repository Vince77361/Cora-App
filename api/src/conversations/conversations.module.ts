import { Module } from '@nestjs/common';
import { BrandsModule } from '../brands/brands.module';
import { CampaignsModule } from '../campaigns/campaigns.module';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { IntegrationsModule } from '../integrations/integrations.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { RealtimeModule } from '../realtime/realtime.module';
import { StoresModule } from '../stores/stores.module';
import { TermsModule } from '../terms/terms.module';
import { ConversationsController } from './conversations.controller';
import { ConversationsRepository } from './conversations.repository';
import { ConversationsService } from './conversations.service';
import { MessageEvents } from './message-events';
import { MessageNotifier } from './message-notifier';

// 대화방과 메시지. 발견(서로 관심)과 오퍼(수락)가 이 모듈의 ConversationsService로 방을 열고,
// 이 모듈은 그 둘을 import하지 않아 순환이 없다.
@Module({
  imports: [
    CollaborationsModule,
    CreatorsModule,
    BrandsModule,
    StoresModule,
    CampaignsModule,
    TermsModule,
    IntegrationsModule,
    NotificationsModule,
    RealtimeModule,
  ],
  controllers: [ConversationsController],
  providers: [
    ConversationsService,
    ConversationsRepository,
    MessageEvents,
    MessageNotifier,
  ],
  // MessageNotifier가 MessageEvents를 구독해 실시간 전달과 푸시를 맡는다.
  exports: [ConversationsService, MessageEvents],
})
export class ConversationsModule {}
