import { Injectable } from '@nestjs/common';
import type { JobPayload, JobRunContext } from '../../jobs/job-scheduler';
import { SettlementsService } from '../settlements.service';
import { collaborationIdOf } from './collaboration-job-payload';

// 정산 작업. 오류는 그대로 던져 큐가 다시 시도하게 한다: 다시 돌아도 정산·지급·환급·알림은 한 번씩만 일어난다.
@Injectable()
export class SettleHandler {
  constructor(private readonly settlements: SettlementsService) {}

  run(payload: JobPayload, context?: JobRunContext): Promise<void> {
    const collaborationId = collaborationIdOf(payload);
    // 장부의 중복 방지 키는 작업 키와 같은 'settle:' + 협업 id다.
    return this.settlements.settle(
      collaborationId,
      `settle:${collaborationId}`,
      context,
    );
  }
}
