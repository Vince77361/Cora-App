import { Logger } from '@nestjs/common';
import { UnrecoverableError } from 'bullmq';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeJobScheduler } from '../../test/support/fake-job-scheduler';
import { BullMqJobScheduler, toBullJobId } from './bullmq-job-scheduler';
import type { JobLike, JobQueue } from './bullmq-job-scheduler';
import { JobHandlerRegistry, NoJobHandlerError } from './job-handler-registry';

const T0 = new Date('2026-11-11T00:00:00.000Z');
const minutes = (n: number) => new Date(T0.getTime() + n * 60_000);

describe('JobHandlerRegistry', () => {
  it('runs the registered handler with the payload', async () => {
    const registry = new JobHandlerRegistry();
    const seen: unknown[] = [];
    registry.register('settle', (p) => {
      seen.push(p);
      return Promise.resolve();
    });
    await registry.run('settle', { collaborationId: 'c1' });
    expect(seen).toEqual([{ collaborationId: 'c1' }]);
  });

  it('warns and throws NoJobHandlerError when no handler is registered', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    const registry = new JobHandlerRegistry();
    await expect(
      registry.run('settle', { collaborationId: 'c1' }),
    ).rejects.toBeInstanceOf(NoJobHandlerError);
    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });

  it('refuses to register two handlers for the same job name', () => {
    const registry = new JobHandlerRegistry();
    registry.register('settle', () => Promise.resolve());
    expect(() => registry.register('settle', () => Promise.resolve())).toThrow(
      /settle/,
    );
  });
});

describe('FakeJobScheduler', () => {
  function build() {
    const registry = new JobHandlerRegistry();
    const ran: string[] = [];
    registry.register('decline-notice', (p) => {
      ran.push(`decline:${p.collaborationId}`);
      return Promise.resolve();
    });
    registry.register('settle', (p) => {
      ran.push(`settle:${p.collaborationId}`);
      return Promise.resolve();
    });
    return { scheduler: new FakeJobScheduler(registry), registry, ran };
  }

  it('registers a job once for the same job key', async () => {
    const { scheduler } = build();
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(5),
      'settle:c1',
    );
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(9),
      'settle:c1',
    );
    expect(scheduler.jobs).toHaveLength(1);
    expect(scheduler.jobs[0].runAt).toEqual(minutes(5));
  });

  it('runs only jobs whose time has come', async () => {
    const { scheduler, ran } = build();
    await scheduler.schedule(
      'decline-notice',
      { collaborationId: 'a' },
      minutes(5),
      'decline:a',
    );
    await scheduler.schedule(
      'settle',
      { collaborationId: 'b' },
      minutes(60),
      'settle:b',
    );
    await scheduler.runDue(minutes(10));
    expect(ran).toEqual(['decline:a']);
    await scheduler.runDue(minutes(10));
    expect(ran).toEqual(['decline:a']);
    await scheduler.runDue(minutes(61));
    expect(ran).toEqual(['decline:a', 'settle:b']);
  });

  it('does not run a cancelled job and lets the key be scheduled again', async () => {
    const { scheduler, ran } = build();
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(5),
      'settle:c1',
    );
    await scheduler.cancel('settle:c1');
    await scheduler.runDue(minutes(10));
    expect(ran).toEqual([]);
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(20),
      'settle:c1',
    );
    await scheduler.runDue(minutes(30));
    expect(ran).toEqual(['settle:c1']);
  });

  it('records a job with no handler, then fails it on run without retrying', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    const { scheduler } = build();
    await scheduler.schedule(
      'payout-send',
      { collaborationId: 'c1' },
      minutes(1),
      'payout:c1',
    );
    expect(scheduler.jobs).toHaveLength(1);
    await scheduler.runDue(minutes(2), { allowFailures: true });
    expect(scheduler.jobs[0].status).toBe('failed');
    expect(scheduler.jobs[0].error).toBeInstanceOf(NoJobHandlerError);
    // 실패한 작업은 다시 실행되지 않는다(재시도 없음).
    await scheduler.runDue(minutes(3));
    expect(scheduler.jobs[0].status).toBe('failed');
    warn.mockRestore();
  });

  it('records a handler error as failed and keeps running other due jobs', async () => {
    const registry = new JobHandlerRegistry();
    registry.register('settle', () => Promise.reject(new Error('boom')));
    const ran: string[] = [];
    registry.register('decline-notice', () => {
      ran.push('ok');
      return Promise.resolve();
    });
    const scheduler = new FakeJobScheduler(registry);
    await scheduler.schedule(
      'settle',
      { collaborationId: 'a' },
      minutes(1),
      'k1',
    );
    await scheduler.schedule(
      'decline-notice',
      { collaborationId: 'b' },
      minutes(2),
      'k2',
    );
    await scheduler.runDue(minutes(5), { allowFailures: true });
    expect(scheduler.jobs.map((j) => j.status)).toEqual(['failed', 'done']);
    expect(ran).toEqual(['ok']);
  });

  it('throws from runDue by default when a handler fails, after running the other due jobs', async () => {
    const registry = new JobHandlerRegistry();
    registry.register('settle', () => Promise.reject(new Error('boom')));
    const ran: string[] = [];
    registry.register('decline-notice', () => {
      ran.push('ok');
      return Promise.resolve();
    });
    const scheduler = new FakeJobScheduler(registry);
    await scheduler.schedule(
      'settle',
      { collaborationId: 'a' },
      minutes(1),
      'k1',
    );
    await scheduler.schedule(
      'decline-notice',
      { collaborationId: 'b' },
      minutes(2),
      'k2',
    );
    await expect(scheduler.runDue(minutes(5))).rejects.toThrow(/settle.*boom/);
    expect(ran).toEqual(['ok']);
    expect(scheduler.jobs.map((j) => j.status)).toEqual(['failed', 'done']);
  });

  it('throws from runDue by default for a job with no handler', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    const scheduler = new FakeJobScheduler(new JobHandlerRegistry());
    await scheduler.schedule(
      'payout-send',
      { collaborationId: 'c1' },
      minutes(1),
      'payout:c1',
    );
    await expect(scheduler.runDue(minutes(2))).rejects.toThrow(/payout-send/);
    expect(scheduler.jobs[0].status).toBe('failed');
    warn.mockRestore();
  });

  it('runs jobs that a handler schedules during the same runDue when they are due', async () => {
    const registry = new JobHandlerRegistry();
    const scheduler = new FakeJobScheduler(registry);
    const ran: string[] = [];
    registry.register('settle', async (p) => {
      ran.push('settle');
      await scheduler.schedule('payout-send', p, minutes(2), 'payout:x');
    });
    registry.register('payout-send', () => {
      ran.push('payout');
      return Promise.resolve();
    });
    await scheduler.schedule(
      'settle',
      { collaborationId: 'x' },
      minutes(1),
      'settle:x',
    );
    await scheduler.runDue(minutes(5));
    expect(ran).toEqual(['settle', 'payout']);
  });
});

class FakeQueue implements JobQueue {
  jobs = new Map<string, FakeJob>();
  added: {
    name: string;
    data: { payload: unknown; runAt: string };
    opts: { jobId: string; delay: number };
  }[] = [];
  removed: string[] = [];

  getJob(id: string): Promise<JobLike | undefined> {
    return Promise.resolve(this.jobs.get(id));
  }
  add(
    name: string,
    data: unknown,
    opts: Record<string, unknown>,
  ): Promise<unknown> {
    const entry = { name, data, opts } as FakeQueue['added'][number];
    this.added.push(entry);
    if (!this.jobs.has(entry.opts.jobId)) {
      this.jobs.set(
        entry.opts.jobId,
        new FakeJob(this, entry.opts.jobId, entry.data),
      );
    }
    return Promise.resolve();
  }
  remove(id: string): Promise<number> {
    this.removed.push(id);
    return Promise.resolve(this.jobs.delete(id) ? 1 : 0);
  }
  getDelayed(): Promise<JobLike[]> {
    return Promise.resolve(
      [...this.jobs.values()].filter((j) => j.state === 'delayed'),
    );
  }
}
class FakeJob implements JobLike {
  state = 'delayed';
  promoted = false;
  constructor(
    private q: FakeQueue,
    public id: string,
    public data: { runAt?: string },
  ) {}
  getState() {
    return Promise.resolve(this.state);
  }
  remove() {
    this.q.jobs.delete(this.id);
    return Promise.resolve();
  }
  promoteError?: Error;
  promote() {
    if (this.promoteError) return Promise.reject(this.promoteError);
    this.promoted = true;
    return Promise.resolve();
  }
}

describe('toBullJobId', () => {
  it('never contains a colon, which BullMQ rejects in custom job ids', () => {
    expect(toBullJobId('decline:abc')).not.toContain(':');
    expect(toBullJobId('a:b:c')).not.toContain(':');
  });

  it('is deterministic and injective', () => {
    expect(toBullJobId('settle:1')).toBe(toBullJobId('settle:1'));
    expect(toBullJobId('a:b')).not.toBe(toBullJobId('a%3Ab'));
    expect(toBullJobId('a:b')).not.toBe(toBullJobId('a_b'));
  });
});

describe('BullMqJobScheduler', () => {
  function build(now = T0) {
    const queue = new FakeQueue();
    const clock = new FakeClock(now);
    const registry = new JobHandlerRegistry();
    const scheduler = new BullMqJobScheduler({ queue, clock, registry });
    return { queue, clock, registry, scheduler };
  }

  it('adds a delayed job with a colon-free id and the run time in its data', async () => {
    const { queue, scheduler } = build();
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(10),
      'settle:c1',
    );
    expect(queue.added).toHaveLength(1);
    const { name, data, opts } = queue.added[0];
    expect(name).toBe('settle');
    expect(opts.jobId).toBe(toBullJobId('settle:c1'));
    expect(opts.jobId).not.toContain(':');
    expect(opts.delay).toBe(10 * 60_000);
    expect(data.payload).toEqual({ collaborationId: 'c1' });
    expect(data.runAt).toBe(minutes(10).toISOString());
  });

  it('computes the delay from Clock and never goes negative', async () => {
    const { queue, scheduler } = build(minutes(30));
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(10),
      'settle:c1',
    );
    expect(queue.added[0].opts.delay).toBe(0);
  });

  it('registers once for the same job key', async () => {
    const { queue, scheduler } = build();
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(10),
      'settle:c1',
    );
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(20),
      'settle:c1',
    );
    expect(queue.added).toHaveLength(1);
  });

  it('replaces a failed job with the same key so ops can reschedule it', async () => {
    const { queue, scheduler } = build();
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(10),
      'settle:c1',
    );
    queue.jobs.get(toBullJobId('settle:c1'))!.state = 'failed';
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(20),
      'settle:c1',
    );
    expect(queue.added).toHaveLength(2);
  });

  it('removes the job on cancel so the key can be scheduled again', async () => {
    const { queue, scheduler } = build();
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(10),
      'settle:c1',
    );
    await scheduler.cancel('settle:c1');
    expect(queue.removed).toEqual([toBullJobId('settle:c1')]);
    await scheduler.schedule(
      'settle',
      { collaborationId: 'c1' },
      minutes(10),
      'settle:c1',
    );
    expect(queue.added).toHaveLength(2);
  });

  it('does not throw when cancelling a key that does not exist', async () => {
    const { scheduler } = build();
    await expect(scheduler.cancel('nothing:here')).resolves.toBeUndefined();
  });

  it('promotes delayed jobs whose run time has passed on the Clock', async () => {
    const { queue, clock, scheduler } = build();
    await scheduler.schedule(
      'settle',
      { collaborationId: 'a' },
      minutes(60),
      'settle:a',
    );
    await scheduler.schedule(
      'settle',
      { collaborationId: 'b' },
      minutes(60 * 24 * 3),
      'settle:b',
    );
    clock.set(minutes(60 * 24)); // 시계를 하루 앞으로 옮긴 뒤 서버를 다시 켠 상황
    await expect(scheduler.promoteDue()).resolves.toBe(1);
    expect(queue.jobs.get(toBullJobId('settle:a'))!.promoted).toBe(true);
    expect(queue.jobs.get(toBullJobId('settle:b'))!.promoted).toBe(false);
  });

  it('keeps promoting and never throws when a job already moved on before promote', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    const { queue, clock, scheduler } = build();
    await scheduler.schedule(
      'settle',
      { collaborationId: 'a' },
      minutes(60),
      'settle:a',
    );
    await scheduler.schedule(
      'settle',
      { collaborationId: 'b' },
      minutes(61),
      'settle:b',
    );
    // 작업자가 먼저 가져가서 a는 더 이상 지연 상태가 아니다(promote가 -3으로 실패).
    queue.jobs.get(toBullJobId('settle:a'))!.promoteError = new Error(
      'Job is not in the delayed state',
    );
    clock.set(minutes(120));
    await expect(scheduler.promoteDue()).resolves.toBe(1);
    expect(queue.jobs.get(toBullJobId('settle:b'))!.promoted).toBe(true);
    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });

  it('turns a missing handler into an unrecoverable (non-retried) failure', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    const { scheduler } = build();
    await expect(
      scheduler.process({
        name: 'settle',
        data: { payload: { collaborationId: 'c1' } },
      }),
    ).rejects.toBeInstanceOf(UnrecoverableError);
    warn.mockRestore();
  });

  it('runs the registered handler with the stored payload', async () => {
    const { scheduler, registry } = build();
    const seen: unknown[] = [];
    registry.register('settle', (p) => {
      seen.push(p);
      return Promise.resolve();
    });
    await scheduler.process({
      name: 'settle',
      data: { payload: { collaborationId: 'c1' } },
    });
    expect(seen).toEqual([{ collaborationId: 'c1' }]);
  });
});
