import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { PayoutsService } from '../payouts.service';

// 지급일에 도는 송금 작업. 오류는 그대로 던져 큐가 다시 시도하게 한다(송금은 한 번만 나간다).
@Injectable()
export class PayoutSendHandler {
  constructor(private readonly payouts: PayoutsService) {}

  run(payload: JobPayload): Promise<void> {
    if ('payoutId' in payload && typeof payload.payoutId === 'string') {
      return this.payouts.send(payload.payoutId);
    }
    // 잘못 등록된 작업이 조용히 사라지지 않고 큐에 실패로 남게 한다.
    return Promise.reject(new Error('작업에 payoutId가 없어요.'));
  }
}
