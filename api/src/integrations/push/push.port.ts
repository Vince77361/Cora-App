// 푸시 알림 포트. 구현체는 IntegrationsModule이 PUSH_ADAPTER 값으로 고른다.
export abstract class PushPort {
  abstract send(input: {
    userId: string;
    title: string;
    body: string;
  }): Promise<void>;
}
