import { Module } from '@nestjs/common';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { LedgerModule } from '../ledger/ledger.module';
import { PayoutAccountsModule } from '../payout-accounts/payout-accounts.module';
import { SettlementsModule } from '../settlements/settlements.module';
import { StoresModule } from '../stores/stores.module';
import { UsersModule } from '../users/users.module';
import { WalletController } from './wallet.controller';
import { WalletService } from './wallet.service';

// 크리에이터의 정산 내역 읽기. 아무도 이 모듈을 import하지 않아(앱 모듈만) 순환이 없다.
@Module({
  imports: [
    UsersModule,
    CollaborationsModule,
    SettlementsModule,
    LedgerModule,
    PayoutAccountsModule,
    StoresModule,
  ],
  controllers: [WalletController],
  providers: [WalletService],
})
export class WalletModule {}
