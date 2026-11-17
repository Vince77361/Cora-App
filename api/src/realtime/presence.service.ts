import { Injectable } from '@nestjs/common';
import { RealtimeGateway } from './realtime.gateway';
import { userRoom } from './realtime-publisher';

// 사용자가 지금 앱에 연결돼 있는지. 연결돼 있으면 화면이 실시간으로 메시지를 받으므로 푸시를 보내지 않는다.
// 테스트는 FakePresence로 바꿔 끼운다.
export abstract class PresenceService {
  abstract isOnline(userId: string): Promise<boolean>;
}

// 소켓 방 user:<id>에 연결이 하나라도 있으면 온라인이다. Redis 어댑터가 있으면 다른 서버의 연결까지 센다.
@Injectable()
export class SocketIoPresenceService extends PresenceService {
  constructor(private readonly gateway: RealtimeGateway) {
    super();
  }

  async isOnline(userId: string): Promise<boolean> {
    // 서버가 없으면(운영 명령처럼 게이트웨이를 띄우지 않는 프로세스) 연결도 없다.
    const namespace = this.gateway.server;
    if (!namespace) return false;
    const sockets = await namespace.in(userRoom(userId)).fetchSockets();
    return sockets.length > 0;
  }
}
