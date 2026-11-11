import { Module } from '@nestjs/common';
import { LedgerRepository } from './ledger.repository';
import { LedgerService } from './ledger.service';

// 다른 기능 모듈을 import하지 않는다. 결제·정산·환급·운영 명령 모듈이 이 모듈을 import해 LedgerService만 쓴다.
@Module({
  providers: [LedgerService, LedgerRepository],
  exports: [LedgerService],
})
export class LedgerModule {}
