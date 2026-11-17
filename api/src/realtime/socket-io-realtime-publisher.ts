import { Injectable } from '@nestjs/common';
import {
  RealtimeEvent,
  RealtimePublisher,
  userRoom,
} from './realtime-publisher';
import { RealtimeGateway } from './realtime.gateway';

// server.to('user:<id>').emit. Redis 어댑터가 붙어 있으면 다른 서버에 연결된 소켓에도 닿는다.
@Injectable()
export class SocketIoRealtimePublisher extends RealtimePublisher {
  constructor(private readonly gateway: RealtimeGateway) {
    super();
  }

  toUsers(
    userIds: string[],
    event: RealtimeEvent,
    payload: object,
  ): Promise<void> {
    // 서버가 없으면(운영 명령처럼 게이트웨이를 띄우지 않는 프로세스) 보낼 곳이 없다.
    const namespace = this.gateway.server;
    if (!namespace || userIds.length === 0) return Promise.resolve();
    // 방 여러 개를 한 번에 지정하면 같은 소켓이 두 방에 있어도 한 번만 받는다.
    namespace.to(userIds.map(userRoom)).emit(event, payload);
    return Promise.resolve();
  }
}
