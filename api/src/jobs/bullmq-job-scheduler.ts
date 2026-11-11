import {
  Logger,
  OnApplicationBootstrap,
  OnApplicationShutdown,
} from '@nestjs/common';
import { Queue, UnrecoverableError, Worker } from 'bullmq';
import type { ConnectionOptions } from 'bullmq';
import { Clock } from '../common/clock';
import { JobHandlerRegistry, NoJobHandlerError } from './job-handler-registry';
import type { JobName } from './job-names';
import { JobPayload, JobScheduler } from './job-scheduler';

export const JOB_QUEUE_NAME = 'cora-jobs';

const ATTEMPTS = 5;
const BACKOFF_MS = 30_000;
const KEEP_FAILED_SECONDS = 30 * 24 * 60 * 60;
const CONNECT_TIMEOUT_MS = 10_000;

// BullMQ는 사용자 지정 작업 ID에 ':'를 허용하지 않는다(6.x에서 확인).
// 호출한 쪽은 'decline:' + id 같은 키를 그대로 쓰므로, ':'만 '%3A'로 바꾼다. '%'도 '%25'로 바꿔 서로 다른 키가 같은 ID가 되지 않는다.
export function toBullJobId(jobKey: string): string {
  return jobKey.replace(/%/g, '%25').replace(/:/g, '%3A');
}

// 단위 테스트가 Redis 없이 손으로 쓴 가짜를 끼울 수 있게 Queue에서 쓰는 부분만 좁혀 둔다.
export interface JobLike {
  data: { runAt?: string };
  getState(): Promise<string>;
  remove(): Promise<void>;
  promote(): Promise<void>;
}
export interface JobQueue {
  getJob(id: string): Promise<JobLike | undefined>;
  add(
    name: string,
    data: unknown,
    opts: Record<string, unknown>,
  ): Promise<unknown>;
  remove(id: string): Promise<number>;
  getDelayed(): Promise<JobLike[]>;
}

export type BullMqJobSchedulerDeps = {
  queue: JobQueue;
  clock: Clock;
  registry: JobHandlerRegistry;
};

export class BullMqJobScheduler
  extends JobScheduler
  implements OnApplicationBootstrap, OnApplicationShutdown
{
  private readonly logger = new Logger(BullMqJobScheduler.name);
  private worker?: Worker;

  constructor(
    private readonly deps: BullMqJobSchedulerDeps,
    private readonly real?: {
      queue: Queue;
      connection: ConnectionOptions;
      queueName: string;
    },
  ) {
    super();
  }

  static create(
    connection: ConnectionOptions,
    clock: Clock,
    registry: JobHandlerRegistry,
    queueName = JOB_QUEUE_NAME,
  ): BullMqJobScheduler {
    const queue = new Queue(queueName, { connection });
    queue.on('error', (e) => this.logError('큐', e));
    return new BullMqJobScheduler(
      { queue: queue, clock, registry },
      { queue, connection, queueName },
    );
  }

  private static logError(where: string, e: Error) {
    new Logger(BullMqJobScheduler.name).error(
      `작업 ${where} 오류: ${e.message}`,
    );
  }

  async schedule(
    name: JobName,
    payload: JobPayload,
    runAt: Date,
    jobKey: string,
  ): Promise<void> {
    const jobId = toBullJobId(jobKey);
    const existing = await this.deps.queue.getJob(jobId);
    if (existing) {
      // 같은 키가 이미 대기·실행 중이면 한 번만 등록된 것이다. 실패한 작업만 새로 올릴 수 있게 치운다.
      if ((await existing.getState()) !== 'failed') return;
      await existing.remove();
    }
    await this.deps.queue.add(
      name,
      { payload, runAt: runAt.toISOString(), jobKey },
      {
        jobId,
        // 지연은 Clock 기준으로 계산한다. 개발에서 시계를 앞당겨도 작업이 같이 앞당겨진다.
        delay: Math.max(0, runAt.getTime() - this.deps.clock.now().getTime()),
        attempts: ATTEMPTS,
        backoff: { type: 'exponential', delay: BACKOFF_MS },
        removeOnComplete: true,
        removeOnFail: { age: KEEP_FAILED_SECONDS },
      },
    );
  }

  async cancel(jobKey: string): Promise<void> {
    try {
      await this.deps.queue.remove(toBullJobId(jobKey));
    } catch (e) {
      // 지금 실행 중인 작업은 지울 수 없다. 그 작업은 끝나면서 스스로 사라진다.
      this.logger.warn(
        `작업을 지우지 못했어요: ${jobKey} (${(e as Error).message})`,
      );
    }
  }

  // 개발에서 시계를 앞당긴 뒤 서버를 다시 켜면, 이미 때가 된 지연 작업을 바로 실행하게 올린다.
  async promoteDue(): Promise<number> {
    const now = this.deps.clock.now().getTime();
    let promoted = 0;
    for (const job of await this.deps.queue.getDelayed()) {
      const runAt = job.data.runAt ? Date.parse(job.data.runAt) : NaN;
      if (!Number.isNaN(runAt) && runAt <= now) {
        await job.promote();
        promoted += 1;
      }
    }
    return promoted;
  }

  // 작업자가 실제로 작업을 실행하는 한 곳. 처리기가 없으면 다시 시도해도 소용없으므로 재시도하지 않는다.
  async process(job: {
    name: string;
    data: { payload: JobPayload };
  }): Promise<void> {
    try {
      await this.deps.registry.run(job.name as JobName, job.data.payload);
    } catch (e) {
      if (e instanceof NoJobHandlerError) {
        throw new UnrecoverableError(e.message);
      }
      throw e;
    }
  }

  // 모든 모듈의 onModuleInit(처리기 등록)이 끝난 뒤에 작업자를 시작해야 처리기 없는 작업이 먼저 실패하지 않는다.
  async onApplicationBootstrap(): Promise<void> {
    if (!this.real) return;
    const { queue, connection, queueName } = this.real;
    const worker = new Worker(queueName, (job) => this.process(job as never), {
      connection,
      concurrency: 4,
    });
    worker.on('error', (e) => BullMqJobScheduler.logError('작업자', e));
    worker.on('failed', (job, e) => {
      this.logger.error(
        `작업 실패: ${job?.name ?? '?'} key=${String((job?.data as { jobKey?: unknown } | undefined)?.jobKey)} ${e.message}`,
      );
    });
    this.worker = worker;
    await withTimeout(
      Promise.all([queue.waitUntilReady(), worker.waitUntilReady()]),
      CONNECT_TIMEOUT_MS,
      'Redis에 연결하지 못했어요. REDIS_URL과 Redis 실행 상태를 확인해 주세요.',
    );
    const promoted = await this.promoteDue();
    this.logger.log(
      `작업 큐와 작업자가 연결됐어요 (큐=${queueName}, 앞당겨 실행한 작업 ${promoted}건)`,
    );
  }

  async onApplicationShutdown(): Promise<void> {
    await this.worker?.close();
    await this.real?.queue.close();
  }
}

function withTimeout<T>(p: Promise<T>, ms: number, message: string) {
  let timer: NodeJS.Timeout;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error(message)), ms);
  });
  return Promise.race([p, timeout]).finally(() => clearTimeout(timer));
}
