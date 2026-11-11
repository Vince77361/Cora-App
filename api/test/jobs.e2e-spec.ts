import { INestApplication } from '@nestjs/common';
import { JobHandlerRegistry } from '../src/jobs/job-handler-registry';
import {
  CollaborationJobPayload,
  JobScheduler,
} from '../src/jobs/job-scheduler';
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

  it('uses FakeJobScheduler on the app registry, and runs due jobs by time', async () => {
    const scheduler = app.get<FakeJobScheduler>(JobScheduler);
    expect(scheduler).toBeInstanceOf(FakeJobScheduler);
    // 앱의 처리기 표를 그대로 쓰는지 확인한다(기능 모듈이 등록한 처리기가 runDue로 실행되는 근거).
    expect(scheduler.registry).toBe(app.get(JobHandlerRegistry));
    // 실제 작업 이름을 앱의 표에 등록하면 기능 모듈이 같은 이름을 등록할 때 충돌한다.
    // 그래서 이 테스트는 별도의 표와 Fake 쌍으로 같은 동작을 확인한다.
    const isolated = new JobHandlerRegistry();
    const fake = new FakeJobScheduler(isolated);
    const ran: string[] = [];
    isolated.register('decline-notice', (p) => {
      ran.push((p as CollaborationJobPayload).collaborationId);
      return Promise.resolve();
    });
    const at = new Date('2026-11-12T00:00:00.000Z');
    await fake.schedule(
      'decline-notice',
      { collaborationId: 'c1' },
      at,
      'decline:c1',
    );
    await fake.runDue(new Date(at.getTime() - 1));
    expect(ran).toEqual([]);
    await fake.runDue(at);
    expect(ran).toEqual(['c1']);
  });

  it('wires the fake payment adapter with the test webhook secret', () => {
    const payment = app.get(PaymentPort);
    expect(payment.verifyWebhook('{}', 'bad')).toBeNull();
  });
});
