import { Module } from '@nestjs/common';
import { CollaborationsModule } from '../collaborations/collaborations.module';
import { JobsModule } from '../jobs/jobs.module';
import { LedgerModule } from '../ledger/ledger.module';
import { PaymentsModule } from '../payments/payments.module';
import { SettlementsModule } from '../settlements/settlements.module';
import { OpsRepository } from './ops.repository';
import { OpsRunner } from './ops.runner';
import { OpsService } from './ops.service';

// 운영자가 서버에서 실행하는 명령(yarn ops). HTTP로 열지 않는다(컨트롤러 없음).
// 돈을 움직이는 일은 각 모듈의 서비스(정산·지급·환급·장부)를 거치고, 이 모듈은 순서와 감사 기록을 맡는다.
@Module({
  imports: [
    CollaborationsModule,
    JobsModule,
    LedgerModule,
    PaymentsModule,
    SettlementsModule,
  ],
  providers: [OpsService, OpsRepository, OpsRunner],
  exports: [OpsRunner],
})
export class OpsModule {}
