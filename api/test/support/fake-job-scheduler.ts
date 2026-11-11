import { JobHandlerRegistry } from '../../src/jobs/job-handler-registry';
import type { JobName } from '../../src/jobs/job-names';
import { JobPayload, JobScheduler } from '../../src/jobs/job-scheduler';

export type FakeJob = {
  name: JobName;
  payload: JobPayload;
  runAt: Date;
  jobKey: string;
  status: 'pending' | 'done' | 'failed';
  error?: unknown;
};

// 등록된 작업을 기록하고, runDue(now)로 때가 된 작업을 처리기 표(JobHandlerRegistry)로 실행한다.
// 운영 구현(BullMQ)과 같은 표를 쓰므로 처리기 등록이 빠지면 테스트에서도 실패로 드러난다.
// 처리기가 던진 오류는 failed로 기록하고, 때가 된 나머지 작업을 다 돌린 뒤 runDue가 던진다
// (망가진 처리기를 테스트가 조용히 지나치지 않게). 일부러 실패를 확인하는 테스트만 { allowFailures: true }를 쓴다.
export class FakeJobScheduler extends JobScheduler {
  readonly jobs: FakeJob[] = [];

  constructor(readonly registry: JobHandlerRegistry) {
    super();
  }

  schedule(
    name: JobName,
    payload: JobPayload,
    runAt: Date,
    jobKey: string,
  ): Promise<void> {
    const existing = this.jobs.findIndex((j) => j.jobKey === jobKey);
    if (existing >= 0) {
      // 대기 중인 같은 키는 한 번만 등록된다. 이미 끝났거나 실패한 키만 BullMQ처럼 새로 올릴 수 있다.
      if (this.jobs[existing].status === 'pending') return Promise.resolve();
      this.jobs.splice(existing, 1);
    }
    this.jobs.push({
      name,
      payload,
      runAt: new Date(runAt.getTime()),
      jobKey,
      status: 'pending',
    });
    return Promise.resolve();
  }

  cancel(jobKey: string): Promise<void> {
    const i = this.jobs.findIndex(
      (j) => j.jobKey === jobKey && j.status === 'pending',
    );
    if (i >= 0) this.jobs.splice(i, 1);
    return Promise.resolve();
  }

  pending(): FakeJob[] {
    return this.jobs.filter((j) => j.status === 'pending');
  }

  // 실행 시각이 now 이하인 대기 작업을 시각 순으로 실행한다. 처리기가 새로 등록한 작업도 때가 됐으면 이어서 실행한다.
  async runDue(
    now: Date,
    options: { allowFailures?: boolean } = {},
  ): Promise<FakeJob[]> {
    const ran: FakeJob[] = [];
    for (;;) {
      const due = this.pending()
        .filter((j) => j.runAt.getTime() <= now.getTime())
        .sort((a, b) => a.runAt.getTime() - b.runAt.getTime())[0];
      if (!due) break;
      try {
        await this.registry.run(due.name, due.payload);
        due.status = 'done';
      } catch (e) {
        due.status = 'failed';
        due.error = e;
      }
      ran.push(due);
    }
    const failed = ran.filter((j) => j.status === 'failed');
    if (failed.length > 0 && !options.allowFailures) {
      const first = failed[0];
      const reason =
        first.error instanceof Error
          ? first.error.message
          : String(first.error);
      throw new Error(
        `작업 ${failed.length}건이 실패했어요: ${first.name}(${first.jobKey}) ${reason}`,
        { cause: first.error },
      );
    }
    return ran;
  }
}
