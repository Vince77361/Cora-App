import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { PaymentsService } from '../payments.service';

// 결제 대기 재확인 작업. 무엇을 할지는 서비스가 정한다(웹훅과 같은 applyResult 길).
// 오류는 그대로 던져 큐가 다시 시도하게 한다: 같은 결과를 다시 넣어도 장부와 단계는 한 번만 바뀐다.
@Injectable()
export class PaymentRecheckHandler {
  constructor(private readonly payments: PaymentsService) {}

  async run(payload: JobPayload): Promise<void> {
    if (
      !('paymentId' in payload) ||
      typeof payload.paymentId !== 'string' ||
      !('attempt' in payload) ||
      typeof payload.attempt !== 'number'
    ) {
      // 잘못 등록된 작업이 조용히 사라지지 않고 큐에 실패로 남게 한다.
      throw new Error('작업에 paymentId와 attempt가 없어요.');
    }
    await this.payments.recheck(payload.paymentId, payload.attempt);
  }
}
