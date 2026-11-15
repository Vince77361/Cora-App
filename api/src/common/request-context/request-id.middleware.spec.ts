import type { NextFunction, Request, Response } from 'express';
import { currentRequestId } from './request-context';
import { requestIdMiddleware } from './request-id.middleware';

// 손으로 쓴 가짜: 헤더만 기록한다.
function fakeRes() {
  const headers = new Map<string, string>();
  return {
    headers,
    res: {
      setHeader: (name: string, value: string) => {
        headers.set(name.toLowerCase(), value);
      },
    } as unknown as Response,
  };
}

function run(incoming?: string) {
  const { headers, res } = fakeRes();
  const req = {
    headers: incoming === undefined ? {} : { 'x-request-id': incoming },
    ip: '203.0.113.7',
  } as unknown as Request;
  let seenInside: string | undefined;
  const next: NextFunction = () => {
    seenInside = currentRequestId();
  };
  requestIdMiddleware(req, res, next);
  return { id: headers.get('x-request-id'), seenInside };
}

describe('requestIdMiddleware', () => {
  it('echoes a valid incoming X-Request-Id and generates one otherwise', () => {
    expect(run('abc12345-DEF').id).toBe('abc12345-DEF');
    const generated = run().id;
    expect(generated).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
    // 너무 짧거나, 허용 밖 문자(CR·LF·공백 등)가 있거나, 너무 길면 버린다.
    for (const bad of [
      'short',
      'has space 12345',
      'a'.repeat(65),
      'ab\r\ncd1234',
    ]) {
      const { id } = run(bad);
      expect(id).not.toBe(bad);
      expect(id).toMatch(/^[0-9a-f-]{36}$/);
    }
  });

  it('makes the same id readable inside the request and not outside', () => {
    const { id, seenInside } = run('abc12345-DEF');
    expect(seenInside).toBe(id);
    expect(currentRequestId()).toBeUndefined();
  });
});
