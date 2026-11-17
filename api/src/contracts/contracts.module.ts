import { Module } from '@nestjs/common';
import { BrandsModule } from '../brands/brands.module';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { CreatorsModule } from '../creators/creators.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TermsModule } from '../terms/terms.module';
import { ContractsController } from './contracts.controller';
import { ContractsRepository } from './contracts.repository';
import { ContractsService } from './contracts.service';

// 브랜드 계약의 동의. 크리에이터가 먼저 동의하면 계약 행과 조건 사본이 생기고, 안내 줄과 알림이 나간다.
@Module({
  imports: [
    CollaborationsModule,
    TermsModule,
    ConversationsModule,
    NotificationsModule,
    BrandsModule,
    CreatorsModule,
  ],
  controllers: [ContractsController],
  providers: [ContractsService, ContractsRepository],
})
export class ContractsModule {}
