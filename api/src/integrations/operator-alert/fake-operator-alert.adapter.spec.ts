import { Logger } from '@nestjs/common';
import { FakeOperatorAlertAdapter } from './fake-operator-alert.adapter';

describe('FakeOperatorAlertAdapter', () => {
  it('logs only the subject, never the body', async () => {
    const log = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    await new FakeOperatorAlertAdapter().alert({
      subject: '조회수 집계 멈춤',
      body: '010-0000-0001 협업 abc',
    });
    const logged = log.mock.calls.map((c) => String(c[0])).join('\n');
    expect(logged).toContain('조회수 집계 멈춤');
    expect(logged).not.toContain('010-0000-0001');
    log.mockRestore();
  });
});
