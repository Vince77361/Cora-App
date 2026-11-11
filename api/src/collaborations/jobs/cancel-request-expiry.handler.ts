import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { CollaborationsService } from '../collaborations.service';

// 사장님의 취소 요청이 3일 안에 답을 못 받았을 때 도는 작업. 아직 기다리는 요청만 만료로 바꾸고, 몇 번 돌아도 같다.
@Injectable()
export class CancelRequestExpiryHandler {
  constructor(private readonly collaborations: CollaborationsService) {}

  run(payload: JobPayload): Promise<void> {
    if (
      'cancelRequestId' in payload &&
      typeof payload.cancelRequestId === 'string'
    ) {
      return this.collaborations.expireCancelRequest(payload.cancelRequestId);
    }
    // 잘못 등록된 작업이 조용히 사라지지 않고 큐에 실패로 남게 한다.
    return Promise.reject(new Error('작업에 cancelRequestId가 없어요.'));
  }
}
