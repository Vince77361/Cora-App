import { Module } from '@nestjs/common';
import { PaymentsModule } from '../payments/payments.module';
import { SettlementsModule } from '../settlements/settlements.module';
import { StoresModule } from '../stores/stores.module';
import { StoreInsightsController } from './store-insights.controller';
import { StoreInsightsService } from './store-insights.service';

// 사장님 가게의 읽기 전용 모아 보기(체험단 비교). 가게·정산·결제 모듈이 내보낸 것만 쓰고 아무것도 바꾸지 않는다.
@Module({
  imports: [StoresModule, SettlementsModule, PaymentsModule],
  controllers: [StoreInsightsController],
  providers: [StoreInsightsService],
})
export class StoreInsightsModule {}
