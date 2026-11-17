import { Logger } from '@nestjs/common';
import {
  OnGatewayConnection,
  OnGatewayInit,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { Namespace, Socket } from 'socket.io';
import { TokenRejectedError, TokenVerifier } from '../auth/token-verifier';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { securityLog } from '../common/logging/security-log';
import { ConnectionLimiter } from './connection-limiter';
import { userRoom } from './realtime-publisher';

// 연결의 인증 결과. 소켓의 data에 담아 둔다.
interface SocketAuth {
  userId?: string;
  expiresAt?: Date;
  // 연결이 들어온 시각(밀리초). 사용자당 연결 상한을 넘으면 가장 오래된 것부터 끊는 데 쓴다.
  connectedAt?: number;
  rejected?: boolean;
}

type FailReason =
  'MISSING' | 'EXPIRED' | 'INVALID' | 'ANONYMOUS' | 'DELETED_USER';

// setTimeout이 받는 가장 긴 시간(약 24.8일). 넘으면 바로 실행되어 버린다.
const MAX_TIMER_MS = 2_147_483_647;
// 앱이 보내는 것은 연결 때의 토큰뿐이다. 긴 JWT도 들어가는 크기로 제한한다.
const MAX_BUFFER_BYTES = 16 * 1024;
// 사용자 한 명이 동시에 붙일 수 있는 소켓 수(휴대폰, 태블릿, 재연결 중인 옛 연결 정도). 넘으면 가장 오래된 연결을 끊는다.
export const MAX_SOCKETS_PER_USER = 5;
// 네임스페이스에 붙지 않고 엔진 연결만 열어 두는 연결을 일찍 정리한다(기본 45초).
const CONNECT_TIMEOUT_MS = 10_000;

// 새 메시지와 방의 변경을 밀어 주기만 하는 게이트웨이. 상태를 바꾸지 않고 앱이 보내는 이벤트는 받지 않는다(처리기가 없다).
// 연결 때 handshake.auth.token을 검증해, 틀리면 바로 끊고 맞으면 방 user:<id>에 넣는다. 토큰이 만료되는 시각에 session.expired를 보낸 뒤 끊는다.
// CORS는 켜지 않는다(HTTP와 같다: 앱은 브라우저가 아니고, 토큰은 쿠키가 아니라 연결 본문으로 보낸다). 클라이언트 스크립트 제공도 끈다.
@WebSocketGateway({
  namespace: '/realtime',
  maxHttpBufferSize: MAX_BUFFER_BYTES,
  connectTimeout: CONNECT_TIMEOUT_MS,
  serveClient: false,
})
export class RealtimeGateway implements OnGatewayInit, OnGatewayConnection {
  private readonly logger = new Logger(RealtimeGateway.name);

  // 네임스페이스. 게이트웨이를 띄우지 않는 프로세스(운영 명령)에서는 비어 있다.
  @WebSocketServer()
  server?: Namespace;

  constructor(
    private readonly verifier: TokenVerifier,
    private readonly clock: Clock,
    private readonly limiter: ConnectionLimiter,
  ) {}

  // 순서: IP별 연결 시도 제한 → 인증(방 넣기). 방에 넣는 일을 연결이 확정되기 전(미들웨어)에 끝낸다:
  // 앱이 연결됐다고 알게 된 순간부터 밀어 주는 이벤트를 놓치지 않게.
  // 제한에 걸리거나 인증에 실패해도 여기서 연결을 막지 않고 표시만 한다. 끊는 일은 handleConnection이 한다(앱은 "연결됐다가 끊김"으로 본다).
  afterInit(namespace: Namespace): void {
    namespace.use((socket, next) => {
      this.limit(socket).then(
        () => next(),
        () => next(),
      );
    });
    namespace.use((socket, next) => {
      this.authenticate(socket).then(
        () => next(),
        () => next(),
      );
    });
    // 기본 네임스페이스(/)는 쓰지 않는다. 인증 없이 열어 두면 아무나 무기한 붙어 있을 수 있어 제한을 거친 뒤 거절한다.
    namespace.server.of('/').use((socket, next) => {
      this.limit(socket).then(
        () => next(new Error('FORBIDDEN')),
        () => next(new Error('FORBIDDEN')),
      );
    });
  }

  handleConnection(client: Socket): void {
    const auth = client.data as SocketAuth;
    if (auth.rejected || !auth.expiresAt) {
      client.disconnect(true);
      return;
    }
    const wait = Math.min(
      Math.max(0, auth.expiresAt.getTime() - this.clock.now().getTime()),
      MAX_TIMER_MS,
    );
    const timer = setTimeout(() => {
      client.emit('session.expired');
      client.disconnect(true);
    }, wait);
    // 이 타이머가 프로세스 종료를 붙잡지 않게 한다.
    timer.unref();
    client.once('disconnect', () => clearTimeout(timer));
    if (auth.userId) void this.enforceUserCap(auth.userId);
  }

  private async limit(socket: Socket): Promise<void> {
    const auth = socket.data as SocketAuth;
    if (!(await this.limiter.allow(socket.request))) auth.rejected = true;
  }

  private async authenticate(socket: Socket): Promise<void> {
    const auth = socket.data as SocketAuth;
    // 제한에 걸린 연결은 검증 비용(서명, 키 묶음)을 쓰지 않는다.
    if (auth.rejected) return;
    const token: unknown = (socket.handshake.auth as { token?: unknown })
      ?.token;
    if (typeof token !== 'string' || token === '') {
      this.reject(auth, 'MISSING');
      return;
    }
    try {
      const verified = await this.verifier.verify(token);
      auth.userId = verified.userId;
      auth.expiresAt = verified.expiresAt;
      auth.connectedAt = Date.now();
      await socket.join(userRoom(verified.userId));
    } catch (error) {
      if (error instanceof AppError && error.code === 'INTERNAL') {
        // 키 묶음 장애 같은 인프라 문제는 토큰이 틀린 것이 아니다. 검증기가 AUTH_INFRA_FAILED로 남기므로
        // 여기서 AUTH_FAILED를 또 남기지 않는다(장애 때 운영자가 토큰 거절 급증으로 오해하지 않게). 연결은 끊는다.
        (socket.data as SocketAuth).rejected = true;
        return;
      }
      this.reject(
        auth,
        error instanceof TokenRejectedError ? error.reason : 'INVALID',
      );
    }
  }

  // 한 사용자의 소켓이 상한을 넘으면 가장 오래된 것부터 끊는다(Redis 어댑터가 있으면 다른 서버의 소켓까지 센다).
  // 방금 붙은 소켓은 가장 새것이라 남는다. 끊긴 앱은 backoff로 다시 붙는다.
  private async enforceUserCap(userId: string): Promise<void> {
    if (!this.server) return;
    try {
      const sockets = await this.server.in(userRoom(userId)).fetchSockets();
      if (sockets.length <= MAX_SOCKETS_PER_USER) return;
      const oldestFirst = [...sockets].sort(
        (a, b) =>
          ((a.data as SocketAuth).connectedAt ?? 0) -
            ((b.data as SocketAuth).connectedAt ?? 0) ||
          a.id.localeCompare(b.id),
      );
      for (const old of oldestFirst.slice(
        0,
        sockets.length - MAX_SOCKETS_PER_USER,
      )) {
        old.disconnect(true);
      }
    } catch (error) {
      this.logger.warn(
        `연결 수 상한을 확인하지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 토큰 원문이나 오류 메시지는 남기지 않고 분류만 남긴다.
  private reject(auth: SocketAuth, reason: FailReason): void {
    auth.rejected = true;
    securityLog('AUTH_FAILED', {
      result: 'DENIED',
      reason,
      target: 'realtime',
    });
  }
}
