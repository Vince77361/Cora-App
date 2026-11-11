import { Module } from '@nestjs/common';
import { IntegrationsModule } from '../integrations/integrations.module';
import { NotificationsRepository } from './notifications.repository';
import { NotificationsService } from './notifications.service';

// 다른 기능 모듈을 import하지 않는다. 오퍼·지원·결제·정산 모듈이 이 모듈을 import해 NotificationsService만 쓴다.
@Module({
  imports: [IntegrationsModule],
  providers: [NotificationsService, NotificationsRepository],
  exports: [NotificationsService],
})
export class NotificationsModule {}
