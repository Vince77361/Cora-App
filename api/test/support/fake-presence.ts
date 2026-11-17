import { PresenceService } from '../../src/realtime/presence.service';

// 소켓 없이 연결 여부를 흉내 낸다. online에 넣은 사용자만 연결돼 있다.
export class FakePresence extends PresenceService {
  readonly online = new Set<string>();
  // 연결 여부를 읽지 못하는 상황(Redis 응답 시간 초과 등)을 만든다.
  fail = false;

  isOnline(userId: string): Promise<boolean> {
    if (this.fail) return Promise.reject(new Error('presence down'));
    return Promise.resolve(this.online.has(userId));
  }
}
