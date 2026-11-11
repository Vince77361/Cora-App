import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { OffersService } from '../offers.service';
import { offerIdOf } from './offer-job-payload';

// 거절 30초 뒤 작업. 거절이 확정됐는지(되돌리지 않았는지)는 서비스가 오퍼의 현재 상태로 정한다.
@Injectable()
export class DeclineNoticeHandler {
  constructor(private readonly offers: OffersService) {}

  async run(payload: JobPayload): Promise<void> {
    await this.offers.sendDeclineNotice(offerIdOf(payload));
  }
}
