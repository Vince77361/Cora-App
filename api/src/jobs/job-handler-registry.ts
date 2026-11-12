import { Injectable, Logger } from '@nestjs/common';
import type { JobName } from './job-names';
import type { JobHandler, JobPayload, JobRunContext } from './job-scheduler';

export class NoJobHandlerError extends Error {
  constructor(readonly jobName: string) {
    super(`처리기가 등록되지 않은 작업이에요: ${jobName}`);
    this.name = 'NoJobHandlerError';
  }
}

// 작업 이름 → 처리기. 기능 모듈이 onModuleInit에서 register하고,
// BullMQ 작업자와 FakeJobScheduler.runDue가 같은 이 표로 작업을 실행한다.
@Injectable()
export class JobHandlerRegistry {
  private readonly logger = new Logger(JobHandlerRegistry.name);
  private readonly handlers = new Map<JobName, JobHandler>();

  register(name: JobName, handler: JobHandler): void {
    // 두 모듈이 같은 작업을 맡으면 어느 쪽이 도는지 알 수 없으므로 시작할 때 드러낸다.
    if (this.handlers.has(name)) {
      throw new Error(`이미 처리기가 등록된 작업이에요: ${name}`);
    }
    this.handlers.set(name, handler);
  }

  async run(
    name: JobName,
    payload: JobPayload,
    context?: JobRunContext,
  ): Promise<void> {
    const handler = this.handlers.get(name);
    if (!handler) {
      this.logger.warn(`처리기가 등록되지 않은 작업을 건너뛰어요: ${name}`);
      throw new NoJobHandlerError(name);
    }
    await handler(payload, context);
  }
}
