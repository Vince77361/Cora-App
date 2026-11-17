import { clientIpOf } from './client-ip';

const request = (remote: string, forwarded?: string) => ({
  headers: forwarded === undefined ? {} : { 'x-forwarded-for': forwarded },
  socket: { remoteAddress: remote },
});

describe('clientIpOf', () => {
  it('uses the connection address and ignores the header when no proxy is trusted', () => {
    expect(clientIpOf(request('10.0.0.1', '203.0.113.9'), 0)).toBe('10.0.0.1');
  });

  it('takes the address the trusted proxy saw', () => {
    expect(clientIpOf(request('10.0.0.1', '203.0.113.9'), 1)).toBe(
      '203.0.113.9',
    );
  });

  it('cannot be spoofed by extra addresses a client put in front of the header', () => {
    // 클라이언트가 보낸 가짜 주소가 왼쪽에 붙어도 프록시가 붙인 오른쪽 값을 쓴다.
    expect(clientIpOf(request('10.0.0.1', '1.1.1.1, 203.0.113.9'), 1)).toBe(
      '203.0.113.9',
    );
    expect(
      clientIpOf(request('10.0.0.1', '1.1.1.1, 203.0.113.9, 10.0.0.2'), 2),
    ).toBe('203.0.113.9');
  });

  it('falls back to the connection address when the header is missing or shorter than the trusted hops', () => {
    expect(clientIpOf(request('10.0.0.1'), 1)).toBe('10.0.0.1');
    expect(clientIpOf(request('10.0.0.1', '203.0.113.9'), 5)).toBe(
      '203.0.113.9',
    );
  });
});
