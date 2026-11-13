import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { OffersService } from '../offers.service';
import { offerIdOf, versionOf } from './offer-job-payload';

// 판본 응답 기한 작업. 판본마다 하나씩 올라가고, 최신 판본의 작업만 일한다(서비스가 번호를 비교한다).
@Injectable()
export class OfferResponseExpiryHandler {
  constructor(private readonly offers: OffersService) {}

  async run(payload: JobPayload): Promise<void> {
    await this.offers.expireUnanswered(offerIdOf(payload), versionOf(payload));
  }
}
