import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module';
import { PayoutAccountsController } from './payout-accounts.controller';
import { PayoutAccountsRepository } from './payout-accounts.repository';
import { PayoutAccountsService } from './payout-accounts.service';

// 정산·지급 모듈이 이 모듈을 import한다. 반대 방향은 없다(순환 방지). 계좌 등록 알림은 onRegistered로 받는다.
@Module({
  imports: [UsersModule],
  controllers: [PayoutAccountsController],
  providers: [PayoutAccountsService, PayoutAccountsRepository],
  exports: [PayoutAccountsService],
})
export class PayoutAccountsModule {}
