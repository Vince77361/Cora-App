import { Module } from '@nestjs/common';
import { IntegrationsModule } from '../integrations/integrations.module';
import { UsersModule } from '../users/users.module';
import { NotificationInboxService } from './notification-inbox.service';
import { NotificationSettingsController } from './notification-settings.controller';
import { NotificationSettingsService } from './notification-settings.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsRepository } from './notifications.repository';
import { NotificationsService } from './notifications.service';

// 다른 기능 모듈은 UsersModule(지금 역할 확인)만 import한다. 오퍼·지원·결제·정산 모듈이 이 모듈을 import해
// NotificationsService만 쓴다. 알림함과 설정 화면의 서비스는 밖으로 내보내지 않는다.
@Module({
  imports: [IntegrationsModule, UsersModule],
  controllers: [NotificationsController, NotificationSettingsController],
  providers: [
    NotificationsService,
    NotificationsRepository,
    NotificationInboxService,
    NotificationSettingsService,
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
