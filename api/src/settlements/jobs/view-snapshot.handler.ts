import { Injectable } from '@nestjs/common';
import type { JobPayload, JobRunContext } from '../../jobs/job-scheduler';
import { SettlementsService } from '../settlements.service';
import { collaborationIdOf, dayIndexOf } from './collaboration-job-payload';

// 조회수 스냅샷 작업. 오류는 그대로 던져 큐가 다시 시도하게 한다(같은 날의 줄은 한 번만 남는다).
@Injectable()
export class ViewSnapshotHandler {
  constructor(private readonly settlements: SettlementsService) {}

  run(payload: JobPayload, context?: JobRunContext): Promise<void> {
    return this.settlements.takeSnapshot(
      collaborationIdOf(payload),
      dayIndexOf(payload),
      context,
    );
  }
}
