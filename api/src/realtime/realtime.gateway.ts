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
import { securityLog } from '../common/logging/security-log';
import { userRoom } from './realtime-publisher';

// 연결의 인증 결과. 소켓의 data에 담아 둔다.
interface SocketAuth {
  userId?: string;
  expiresAt?: Date;
  rejected?: boolean;
}

// setTimeout이 받는 가장 긴 시간(약 24.8일). 넘으면 바로 실행되어 버린다.
const MAX_TIMER_MS = 2_147_483_647;
// 앱이 보내는 것은 연결 때의 토큰뿐이다. 긴 JWT도 들어가는 크기로 제한한다.
const MAX_BUFFER_BYTES = 16 * 1024;

// 새 메시지와 방의 변경을 밀어 주기만 하는 게이트웨이. 상태를 바꾸지 않고 앱이 보내는 이벤트는 받지 않는다(처리기가 없다).
// 연결 때 handshake.auth.token을 검증해, 틀리면 바로 끊고 맞으면 방 user:<id>에 넣는다. 토큰이 만료되는 시각에 session.expired를 보낸 뒤 끊는다.
@WebSocketGateway({
  namespace: '/realtime',
  maxHttpBufferSize: MAX_BUFFER_BYTES,
})
export class RealtimeGateway implements OnGatewayInit, OnGatewayConnection {
  private readonly logger = new Logger(RealtimeGateway.name);

  // 네임스페이스. 게이트웨이를 띄우지 않는 프로세스(운영 명령)에서는 비어 있다.
  @WebSocketServer()
  server?: Namespace;

  constructor(
    private readonly verifier: TokenVerifier,
    private readonly clock: Clock,
  ) {}

  // 방에 넣는 일을 연결이 확정되기 전(미들웨어)에 끝낸다: 앱이 연결됐다고 알게 된 순간부터 밀어 주는 이벤트를 놓치지 않게.
  // 인증에 실패해도 여기서 연결을 막지 않고 표시만 한다. 끊는 일은 handleConnection이 한다(앱은 "연결됐다가 끊김"으로 본다).
  afterInit(namespace: Namespace): void {
    namespace.use((socket, next) => {
      this.authenticate(socket).then(
        () => next(),
        () => next(),
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
  }

  private async authenticate(socket: Socket): Promise<void> {
    const auth = socket.data as SocketAuth;
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
      await socket.join(userRoom(verified.userId));
    } catch (error) {
      // 키 묶음 장애는 검증기가 AUTH_INFRA_FAILED로 따로 남긴다. 여기서는 어느 쪽이든 연결을 끊는다.
      this.reject(
        auth,
        error instanceof TokenRejectedError ? error.reason : 'INVALID',
      );
    }
  }

  // 토큰 원문이나 오류 메시지는 남기지 않고 분류만 남긴다.
  private reject(
    auth: SocketAuth,
    reason: 'MISSING' | 'EXPIRED' | 'INVALID' | 'ANONYMOUS' | 'DELETED_USER',
  ): void {
    auth.rejected = true;
    securityLog('AUTH_FAILED', {
      result: 'DENIED',
      reason,
      target: 'realtime',
    });
  }
}
