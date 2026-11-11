import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { OffersService } from '../offers.service';
import { offerIdOf } from './offer-job-payload';

// 결제 기한 작업. 읽을 때 만료와 같은 길(서비스의 정리)로 오퍼를 만료하고 협업을 취소한다.
@Injectable()
export class PaymentDueExpiryHandler {
  constructor(private readonly offers: OffersService) {}

  async run(payload: JobPayload): Promise<void> {
    await this.offers.expireUnpaid(offerIdOf(payload));
  }
}
