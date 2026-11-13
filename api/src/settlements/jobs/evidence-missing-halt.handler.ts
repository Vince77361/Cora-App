import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { SettlementsService } from '../settlements.service';
import { collaborationIdOf } from './collaboration-job-payload';

// 조회수를 읽지 못해 캡처를 기다리던 협업의 기한 작업(측정 기간이 끝난 뒤 3일). 기한까지 캡처가 없으면 협업을 멈춘다.
// 오류는 그대로 던져 큐가 다시 시도하게 한다: 다시 돌아도 멈춤과 알림은 한 번씩만 일어난다.
@Injectable()
export class EvidenceMissingHaltHandler {
  constructor(private readonly settlements: SettlementsService) {}

  run(payload: JobPayload): Promise<void> {
    return this.settlements.haltIfEvidenceMissing(collaborationIdOf(payload));
  }
}
