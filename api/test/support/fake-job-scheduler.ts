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
// 처리기가 던진 오류는 failed로 기록할 뿐 runDue가 다시 던지지 않는다(운영의 재시도 대신). 확인은 jobs로 한다.
export class FakeJobScheduler extends JobScheduler {
  readonly jobs: FakeJob[] = [];

  constructor(private readonly registry: JobHandlerRegistry) {
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
  async runDue(now: Date): Promise<FakeJob[]> {
    const ran: FakeJob[] = [];
    for (;;) {
      const due = this.pending()
        .filter((j) => j.runAt.getTime() <= now.getTime())
        .sort((a, b) => a.runAt.getTime() - b.runAt.getTime())[0];
      if (!due) return ran;
      try {
        await this.registry.run(due.name, due.payload);
        due.status = 'done';
      } catch (e) {
        due.status = 'failed';
        due.error = e;
      }
      ran.push(due);
    }
  }
}
