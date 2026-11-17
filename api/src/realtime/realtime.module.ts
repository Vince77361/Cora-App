import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PresenceService, SocketIoPresenceService } from './presence.service';
import { RealtimePublisher } from './realtime-publisher';
import { RealtimeGateway } from './realtime.gateway';
import { SocketIoRealtimePublisher } from './socket-io-realtime-publisher';

// 실시간 전달. 기능 모듈은 RealtimePublisher(밀어 주기)와 PresenceService(연결 여부)만 쓰고 게이트웨이를 직접 만지지 않는다.
// 이 모듈은 기능 모듈을 import하지 않아 순환이 없다.
@Module({
  imports: [AuthModule],
  providers: [
    RealtimeGateway,
    { provide: RealtimePublisher, useClass: SocketIoRealtimePublisher },
    { provide: PresenceService, useClass: SocketIoPresenceService },
  ],
  exports: [RealtimePublisher, PresenceService],
})
export class RealtimeModule {}
