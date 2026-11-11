import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { DeadlinesService } from '../deadlines.service';
import { collaborationIdOf } from './collaboration-job-payload';

// 미제출 환급 작업. 오류는 그대로 던져 큐가 다시 시도하게 한다(환급은 한 번만 나간다).
@Injectable()
export class RefundUnsubmittedHandler {
  constructor(private readonly deadlines: DeadlinesService) {}

  run(payload: JobPayload): Promise<void> {
    return this.deadlines.refundUnsubmitted(collaborationIdOf(payload));
  }
}
