import { PushPort } from '../../src/integrations/push/push.port';

// 네트워크 없이 푸시를 흉내 낸다. 보낸 알림을 기록해 테스트가 확인한다.
export class FakePushPort extends PushPort {
  readonly sent: { userId: string; title: string; body: string }[] = [];

  send(input: { userId: string; title: string; body: string }): Promise<void> {
    this.sent.push(input);
    return Promise.resolve();
  }
}
