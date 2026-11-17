import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { SettlementsService } from '../settlements.service';
import { settleJobKey } from '../job-keys';
import { collaborationIdOf } from './collaboration-job-payload';

// 성과 추가가 없는 브랜드 계약의 지급 작업. 오류는 그대로 던져 큐가 다시 시도하게 한다: 다시 돌아도 정산·지급·알림은 한 번씩만 일어난다.
@Injectable()
export class SettleFixedHandler {
  constructor(private readonly settlements: SettlementsService) {}

  run(payload: JobPayload): Promise<void> {
    const collaborationId = collaborationIdOf(payload);
    // 장부의 중복 방지 키는 가게 오퍼의 정산과 같은 키(settleJobKey)다(협업마다 정산은 한 번뿐이다).
    return this.settlements.settleFixed(
      collaborationId,
      settleJobKey(collaborationId),
    );
  }
}
