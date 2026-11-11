import { PushPort } from '../../src/integrations/push/push.port';

type PushInput = Parameters<PushPort['send']>[0];

// 네트워크 없이 푸시를 흉내 낸다. 보낸 알림을 data까지 기록해 테스트가 확인한다.
export class FakePushPort extends PushPort {
  readonly sent: PushInput[] = [];
  // 푸시 서버가 죽은 상황을 만든다.
  fail = false;

  send(input: PushInput): Promise<void> {
    if (this.fail) return Promise.reject(new Error('push down'));
    this.sent.push(input);
    return Promise.resolve();
  }
}
