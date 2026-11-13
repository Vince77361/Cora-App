import { Injectable } from '@nestjs/common';
import type { JobPayload, JobRunContext } from '../../jobs/job-scheduler';
import { ViewReportService } from '../view-report.service';
import { collaborationIdOf } from './collaboration-job-payload';

// 조회 자료 확인 기한이 된 협업의 자동 확인 작업. 오류는 그대로 던져 큐가 다시 시도하게 한다:
// 계산이 연결 계정 자료이고 아직 확인 전일 때만 확인하고, 그 밖에는 아무 일도 하지 않는다(이미 확인했거나 이의가 걸렸거나 캡처 자료).
@Injectable()
export class SettlementAutoConfirmHandler {
  constructor(private readonly viewReport: ViewReportService) {}

  run(payload: JobPayload, context?: JobRunContext): Promise<void> {
    return this.viewReport.autoConfirm(collaborationIdOf(payload), context);
  }
}
