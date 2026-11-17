import { Injectable } from '@nestjs/common';
import type { JobPayload } from '../../jobs/job-scheduler';
import { BrandHaltService } from '../brand-halt.service';

// 브랜드 계약 체결 뒤 60일에 도는 점검 작업. 오류는 그대로 던져 큐가 다시 시도하게 한다(몇 번 돌아도 멈춤과 알림은 한 번씩이다).
@Injectable()
export class BrandHaltCheckHandler {
  constructor(private readonly brandHalt: BrandHaltService) {}

  run(payload: JobPayload): Promise<void> {
    if (
      'collaborationId' in payload &&
      typeof payload.collaborationId === 'string'
    ) {
      return this.brandHalt.haltIfNoLink(payload.collaborationId);
    }
    // 잘못 등록된 작업이 조용히 사라지지 않고 큐에 실패로 남게 한다.
    return Promise.reject(new Error('작업에 collaborationId가 없어요.'));
  }
}
