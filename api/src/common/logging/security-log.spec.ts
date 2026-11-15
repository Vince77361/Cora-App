import { Logger } from '@nestjs/common';
import { runWithRequestContext } from '../request-context/request-context';
import { securityLog } from './security-log';

// 가로챈 호출의 첫 인자(한 줄 JSON)들.
const firstArgs = (spy: jest.SpyInstance): string[] =>
  (spy.mock.calls as unknown[][]).map((call) => call[0] as string);

describe('securityLog', () => {
  let log: jest.SpyInstance;
  let warn: jest.SpyInstance;
  let error: jest.SpyInstance;
  beforeEach(() => {
    log = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    error = jest.spyOn(Logger.prototype, 'error').mockImplementation();
  });
  afterEach(() => jest.restoreAllMocks());

  // 어느 수준으로 나갔든 한 줄 JSON 하나만 나왔는지 확인하고 읽는다.
  function emitted(): Record<string, unknown> {
    const lines = [log, warn, error].flatMap(firstArgs);
    expect(lines).toHaveLength(1);
    const line = lines[0];
    expect(line).not.toMatch(/[\r\n]/);
    return JSON.parse(line) as Record<string, unknown>;
  }

  it('writes one JSON line with ts, level, event, requestId, ip and the fields', () => {
    runWithRequestContext(
      { requestId: 'req-12345678', ip: '203.0.113.7' },
      () =>
        securityLog('ROLE_CHANGED', {
          userId: 'u1',
          result: 'ALLOWED',
          reason: 'NONE→STORE',
        }),
    );
    const out = emitted();
    expect(out).toMatchObject({
      level: 'info',
      event: 'ROLE_CHANGED',
      requestId: 'req-12345678',
      ip: '203.0.113.7',
      userId: 'u1',
      result: 'ALLOWED',
      reason: 'NONE→STORE',
    });
    expect(typeof out.ts).toBe('string');
    expect(Number.isNaN(Date.parse(out.ts as string))).toBe(false);
  });

  it('logs ROLE_CHANGED with the previous and the new role', () => {
    securityLog('ROLE_CHANGED', {
      userId: 'u1',
      result: 'ALLOWED',
      reason: 'STORE→CREATOR',
    });
    expect(emitted().reason).toBe('STORE→CREATOR');
  });

  it('carries a ref so repeated events for the same payout can be matched', () => {
    securityLog('PAYOUT_RESULT', {
      ref: 'payout-1',
      result: 'ALLOWED',
      reason: 'SENT',
    });
    expect(emitted().ref).toBe('payout-1');
  });

  it('uses warn for DENIED and error for FAILED', () => {
    securityLog('FORBIDDEN', { result: 'DENIED' });
    expect(warn).toHaveBeenCalledTimes(1);
    expect(JSON.parse(firstArgs(warn)[0]) as object).toMatchObject({
      level: 'warn',
    });
    securityLog('PAYOUT_RESULT', { result: 'FAILED' });
    expect(error).toHaveBeenCalledTimes(1);
    expect(JSON.parse(firstArgs(error)[0]) as object).toMatchObject({
      level: 'error',
    });
  });

  it('strips CR and LF from logged fields', () => {
    runWithRequestContext(
      { requestId: 'req-12345678', ip: '1.2.3.4\r\nX' },
      () =>
        securityLog('AUTH_FAILED', {
          target: 'GET /a\r\n{"event":"FAKE"}',
          result: 'DENIED',
          reason: 'IN\nVALID',
        }),
    );
    const out = emitted();
    expect(out.target).toBe('GET /a{"event":"FAKE"}');
    expect(out.reason).toBe('INVALID');
    expect(out.ip).toBe('1.2.3.4X');
  });

  it('keeps the amount and leaves out fields that were not given', () => {
    securityLog('PAYOUT_RESULT', {
      target: 'collab-1',
      amount: 12000,
      result: 'ALLOWED',
    });
    const out = emitted();
    expect(out.amount).toBe(12000);
    expect(out).not.toHaveProperty('userId');
    expect(out).not.toHaveProperty('reason');
  });

  it('caps very long values', () => {
    securityLog('FORBIDDEN', { target: 'x'.repeat(5000), result: 'DENIED' });
    expect((emitted().target as string).length).toBeLessThanOrEqual(200);
  });
});
