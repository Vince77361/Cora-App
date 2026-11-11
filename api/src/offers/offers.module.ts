import { Module } from '@nestjs/common';
import { ApplicationsModule } from '../applications/applications.module';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { CreatorsModule } from '../creators/creators.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { StoresModule } from '../stores/stores.module';
import { UsersModule } from '../users/users.module';
import { OffersController } from './offers.controller';
import { OffersRepository } from './offers.repository';
import { OffersService } from './offers.service';

@Module({
  imports: [
    NotificationsModule,
    UsersModule,
    StoresModule,
    CreatorsModule,
    ApplicationsModule,
    CollaborationsModule,
  ],
  controllers: [OffersController],
  providers: [OffersService, OffersRepository],
  // 3번 계획(결제)이 오퍼 상태를 읽고 바꿀 때 쓴다.
  exports: [OffersService],
})
export class OffersModule {}
