import {
  RealtimeEvent,
  RealtimePublisher,
} from '../../src/realtime/realtime-publisher';

export interface PublishedEvent {
  userIds: string[];
  event: RealtimeEvent;
  payload: unknown;
}

// 소켓 없이 실시간 전달을 흉내 낸다. 보낸 것을 기록해 테스트가 확인한다.
export class FakeRealtimePublisher extends RealtimePublisher {
  readonly sent: PublishedEvent[] = [];
  // 전달이 실패하는 상황(Redis가 죽었을 때 등)을 만든다.
  fail = false;

  toUsers(
    userIds: string[],
    event: RealtimeEvent,
    payload: object,
  ): Promise<void> {
    if (this.fail) return Promise.reject(new Error('realtime down'));
    this.sent.push({ userIds, event, payload });
    return Promise.resolve();
  }

  // 한 사용자가 받은 이벤트만(이름으로 거른다).
  receivedBy(userId: string, event?: RealtimeEvent): PublishedEvent[] {
    return this.sent.filter(
      (item) =>
        item.userIds.includes(userId) && (!event || item.event === event),
    );
  }
}
