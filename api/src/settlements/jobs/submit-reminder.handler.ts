import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { DeadlinesService } from '../deadlines.service';
import { collaborationIdOf, daysLeftOf } from './collaboration-job-payload';

// 제출 기한 알림 작업. 같은 날짜 알림은 중복 방지 키로 한 건이다.
@Injectable()
export class SubmitReminderHandler {
  constructor(private readonly deadlines: DeadlinesService) {}

  run(payload: JobPayload): Promise<void> {
    return this.deadlines.remind(
      collaborationIdOf(payload),
      daysLeftOf(payload),
    );
  }
}
