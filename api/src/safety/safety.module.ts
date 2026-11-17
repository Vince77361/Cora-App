import { Module } from '@nestjs/common';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { IntegrationsModule } from '../integrations/integrations.module';
import { JobsModule } from '../jobs/jobs.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { OffersModule } from '../offers/offers.module';
import { SettlementsModule } from '../settlements/settlements.module';
import { BlocksController } from './blocks.controller';
import { ReportsController } from './reports.controller';
import { SafetyRepository } from './safety.repository';
import { SafetyService } from './safety.service';

// 차단과 신고. 오퍼·대화·협업·정산 모듈이 내보낸 서비스와 저장소만 쓰고, 이 모듈을 import하는 쪽은 운영 명령(ops)뿐이다.
// 차단을 읽는 공통 필터(VisibilityService)는 이 모듈이 아니라 VisibilityRepository가 blocks 표를 읽는다(순환을 피한다).
@Module({
  imports: [
    CollaborationsModule,
    ConversationsModule,
    IntegrationsModule,
    JobsModule,
    NotificationsModule,
    OffersModule,
    SettlementsModule,
  ],
  controllers: [BlocksController, ReportsController],
  providers: [SafetyService, SafetyRepository],
  exports: [SafetyService],
})
export class SafetyModule {}
