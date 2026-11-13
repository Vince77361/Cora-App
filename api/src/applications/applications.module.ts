import { Module } from '@nestjs/common';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { StoresModule } from '../stores/stores.module';
import { UsersModule } from '../users/users.module';
import { ApplicationsController } from './applications.controller';
import { ApplicationsRepository } from './applications.repository';
import { ApplicationsService } from './applications.service';

// CollaborationsModule은 다른 기능 모듈을 import하지 않아 순환이 없다(지원자 추천의 마친 협업 수).
// StoresModule이 이 모듈을 import하면 순환이다. 가게 상세의 내 지원 상태는 StoresRepository가 직접 읽는다.
@Module({
  imports: [
    NotificationsModule,
    StoresModule,
    CreatorsModule,
    UsersModule,
    CollaborationsModule,
  ],
  controllers: [ApplicationsController],
  providers: [ApplicationsService, ApplicationsRepository],
  // 오퍼 모듈이 지원 상태를 바꾸고 센다.
  exports: [ApplicationsService],
})
export class ApplicationsModule {}
