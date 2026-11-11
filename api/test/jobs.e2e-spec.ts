import { INestApplication } from '@nestjs/common';
import { JobHandlerRegistry } from '../src/jobs/job-handler-registry';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { PaymentPort } from '../src/integrations/payment/payment.port';
import { createTestApp } from './helpers/create-test-app';
import { FakeJobScheduler } from './support/fake-job-scheduler';

describe('job queue in the test app', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  });
  afterAll(async () => {
    await app.close();
  });

  it('uses FakeJobScheduler and runs due jobs through the shared handler registry', async () => {
    const scheduler = app.get<FakeJobScheduler>(JobScheduler);
    expect(scheduler).toBeInstanceOf(FakeJobScheduler);
    const ran: string[] = [];
    app.get(JobHandlerRegistry).register('decline-notice', (p) => {
      ran.push(p.collaborationId);
      return Promise.resolve();
    });
    const at = new Date('2026-11-12T00:00:00.000Z');
    await scheduler.schedule(
      'decline-notice',
      { collaborationId: 'c1' },
      at,
      'decline:c1',
    );
    await scheduler.runDue(new Date(at.getTime() - 1));
    expect(ran).toEqual([]);
    await scheduler.runDue(at);
    expect(ran).toEqual(['c1']);
  });

  it('wires the fake payment adapter with the test webhook secret', () => {
    const payment = app.get(PaymentPort);
    expect(payment.verifyWebhook('{}', 'bad')).toBeNull();
  });
});
