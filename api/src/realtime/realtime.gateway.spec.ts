import { Logger } from '@nestjs/common';
import type { Namespace, Socket } from 'socket.io';
import { FakeClock } from '../../test/support/fake-clock';
import { TokenRejectedError, TokenVerifier } from '../auth/token-verifier';
import { AppError } from '../common/errors/app-error';
import { ConnectionLimiter } from './connection-limiter';
import { MAX_SOCKETS_PER_USER, RealtimeGateway } from './realtime.gateway';

const USER = '11111111-1111-4111-8111-111111111111';
const T0 = new Date('2026-12-01T00:00:00.000Z');

// 소켓 하나를 흉내 낸다. 보낸 이벤트와 disconnect 호출을 기록하고, 끊김 처리기를 직접 불러 줄 수 있다.
class FakeSocket {
  data: Record<string, unknown> = {};
  handshake: { auth: unknown };
  request = { headers: {}, socket: { remoteAddress: '10.0.0.1' } };
  readonly emitted: string[] = [];
  disconnected = false;
  readonly joined: string[] = [];
  private readonly onceHandlers = new Map<string, () => void>();

  constructor(token: unknown = 'good') {
    this.handshake = { auth: { token } };
  }
  emit(event: string) {
    this.emitted.push(event);
    return true;
  }
  disconnect() {
    this.disconnected = true;
    return this;
  }
  join(room: string) {
    this.joined.push(room);
    return Promise.resolve();
  }
  once(event: string, handler: () => void) {
    this.onceHandlers.set(event, handler);
    return this;
  }
  trigger(event: string) {
    this.onceHandlers.get(event)?.();
  }
}

class StubVerifier extends TokenVerifier {
  calls = 0;
  constructor(
    private readonly outcome: () => Promise<{
      userId: string;
      expiresAt: Date;
    }>,
  ) {
    super();
  }
  verify() {
    this.calls += 1;
    return this.outcome();
  }
}

class StubLimiter extends ConnectionLimiter {
  allowed = true;
  constructor() {
    super(
      null as never,
      {
        get: () => 1,
      } as never,
    );
  }
  allow() {
    return Promise.resolve(this.allowed);
  }
}

describe('RealtimeGateway', () => {
  const clock = new FakeClock(T0);
  let limiter: StubLimiter;
  let warn: jest.SpyInstance;

  beforeEach(() => {
    jest.useFakeTimers();
    clock.set(T0);
    limiter = new StubLimiter();
    warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
  });
  afterEach(() => {
    jest.useRealTimers();
    warn.mockRestore();
  });

  const gatewayWith = (verifier: TokenVerifier) =>
    new RealtimeGateway(verifier, clock, limiter);
  const okVerifier = (ttlMs = 60_000) =>
    new StubVerifier(() =>
      Promise.resolve({
        userId: USER,
        expiresAt: new Date(T0.getTime() + ttlMs),
      }),
    );
  // 미들웨어(제한 → 인증) 둘을 순서대로 지난 뒤 handleConnection까지 가는 길.
  async function connect(gateway: RealtimeGateway, socket: FakeSocket) {
    const asSocket = socket as unknown as Socket;
    await (gateway as unknown as { limit(s: Socket): Promise<void> }).limit(
      asSocket,
    );
    await (
      gateway as unknown as { authenticate(s: Socket): Promise<void> }
    ).authenticate(asSocket);
    gateway.handleConnection(asSocket);
  }

  it('sends session.expired at the expiry and disconnects', async () => {
    const socket = new FakeSocket();
    await connect(gatewayWith(okVerifier(5_000)), socket);
    expect(socket.joined).toEqual([`user:${USER}`]);
    jest.advanceTimersByTime(4_999);
    expect(socket.emitted).toEqual([]);
    jest.advanceTimersByTime(1);
    expect(socket.emitted).toEqual(['session.expired']);
    expect(socket.disconnected).toBe(true);
  });

  it('clears the expiry timer when the client disconnects first', async () => {
    const socket = new FakeSocket();
    await connect(gatewayWith(okVerifier(5_000)), socket);
    expect(jest.getTimerCount()).toBe(1);
    socket.trigger('disconnect');
    expect(jest.getTimerCount()).toBe(0);
    jest.advanceTimersByTime(10_000);
    expect(socket.emitted).toEqual([]);
  });

  it('disconnects without verifying when the ip is over the connection limit', async () => {
    limiter.allowed = false;
    const verifier = okVerifier();
    const socket = new FakeSocket();
    await connect(gatewayWith(verifier), socket);
    expect(verifier.calls).toBe(0);
    expect(socket.disconnected).toBe(true);
    expect(socket.joined).toEqual([]);
  });

  it('disconnects a client with no token or a rejected token and logs the reason only', async () => {
    const none = new FakeSocket(null);
    await connect(gatewayWith(okVerifier()), none);
    const bad = new FakeSocket('bad');
    await connect(
      gatewayWith(
        new StubVerifier(() =>
          Promise.reject(
            new TokenRejectedError('EXPIRED', '로그인이 필요해요.'),
          ),
        ),
      ),
      bad,
    );
    expect(none.disconnected).toBe(true);
    expect(bad.disconnected).toBe(true);
    const lines = warn.mock.calls.map((call: unknown[]) => String(call[0]));
    expect(lines).toHaveLength(2);
    expect(lines[0]).toContain('"reason":"MISSING"');
    expect(lines[1]).toContain('"reason":"EXPIRED"');
    expect(lines.join('')).not.toContain('bad');
  });

  it('disconnects on an infrastructure failure without logging it as a rejected token', async () => {
    const socket = new FakeSocket();
    await connect(
      gatewayWith(
        new StubVerifier(() =>
          Promise.reject(new AppError('INTERNAL', '서버 오류가 발생했어요.')),
        ),
      ),
      socket,
    );
    expect(socket.disconnected).toBe(true);
    // 검증기가 AUTH_INFRA_FAILED를 남기므로 소켓 쪽에서는 AUTH_FAILED를 남기지 않는다.
    expect(warn).not.toHaveBeenCalled();
  });

  describe('per user connection cap', () => {
    const remote = (id: string, connectedAt: number) => ({
      id,
      data: { connectedAt },
      disconnect: jest.fn(),
    });
    const withSockets = (gateway: RealtimeGateway, sockets: unknown[]) => {
      gateway.server = {
        in: () => ({ fetchSockets: () => Promise.resolve(sockets) }),
      } as unknown as Namespace;
    };

    it('disconnects the oldest sockets when a sixth connects and keeps the newest', async () => {
      const gateway = gatewayWith(okVerifier());
      const sockets = [6, 2, 5, 1, 4, 3, 7].map((n) => remote(`s${n}`, n));
      withSockets(gateway, sockets);
      await connect(gateway, new FakeSocket());
      await Promise.resolve();
      await Promise.resolve();
      const disconnected = sockets
        .filter((s) => s.disconnect.mock.calls.length > 0)
        .map((s) => s.id)
        .sort();
      // 7개 중 상한(5)을 넘는 가장 오래된 둘.
      expect(MAX_SOCKETS_PER_USER).toBe(5);
      expect(disconnected).toEqual(['s1', 's2']);
    });

    it('leaves everything alone at the cap', async () => {
      const gateway = gatewayWith(okVerifier());
      const sockets = [1, 2, 3, 4, 5].map((n) => remote(`s${n}`, n));
      withSockets(gateway, sockets);
      await connect(gateway, new FakeSocket());
      await Promise.resolve();
      await Promise.resolve();
      expect(sockets.every((s) => s.disconnect.mock.calls.length === 0)).toBe(
        true,
      );
    });
  });
});
