import { Injectable } from '@nestjs/common';
import type { JobPayload, JobRunContext } from '../../jobs/job-scheduler';
import { CollaborationsService } from '../collaborations.service';

// 결제 뒤 취소로 만든 환급이 바로 나가지 못했을 때 도는 작업. 오류는 그대로 던져 큐가 다시 시도하게 한다
// (환급은 같은 키로 요청하므로 PG에서 한 번만 나가고, 행이 없거나 이미 DONE이면 아무 일도 하지 않는다).
@Injectable()
export class CancelRefundHandler {
  constructor(private readonly collaborations: CollaborationsService) {}

  run(payload: JobPayload, context?: JobRunContext): Promise<void> {
    if (
      'collaborationId' in payload &&
      typeof payload.collaborationId === 'string'
    ) {
      return this.collaborations.retryCancelRefund(
        payload.collaborationId,
        context,
      );
    }
    // 잘못 등록된 작업이 조용히 사라지지 않고 큐에 실패로 남게 한다.
    return Promise.reject(new Error('작업에 collaborationId가 없어요.'));
  }
}
