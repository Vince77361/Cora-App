// 푸시 알림 포트. 구현체는 IntegrationsModule이 PUSH_ADAPTER 값으로 고른다.
// 부르는 곳은 NotificationsService 하나다(기능 모듈은 직접 부르지 않는다).
export interface PushData {
  // 알림함에 남기지 않는 종류는 줄이 없어 null이다.
  notificationId: string | null;
  // 앱이 누르면 가는 화면으로 바꾸는 값. 알림함 줄과 같은 표를 쓴다.
  targetKind: string;
  targetId: string | null;
  // 받는 역할. 역할이 여럿인 계정에서 앱이 역할을 바꾼 뒤 이동하게 한다.
  role: string;
}

export abstract class PushPort {
  abstract send(input: {
    userId: string;
    title: string;
    body: string;
    data?: PushData;
  }): Promise<void>;
}
