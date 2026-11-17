// 실시간으로 밀어 주는 이벤트의 이름과 모양. 앱의 SocketRealtimeConnection이 같은 이름과 모양을 읽는다.
export type RealtimeEvent = 'message.created' | 'conversation.updated';

// 대화방이 바뀐 이유. TERMS: 조건 버전, CONTRACT: 계약, STATUS: 방·협업 상태(요청 수락·거절, 알림 끄기 포함), READ: 읽은 번호.
export type ConversationUpdateReason = 'TERMS' | 'CONTRACT' | 'STATUS' | 'READ';

export interface ConversationUpdatedPayload {
  conversationId: string;
  reason: ConversationUpdateReason;
}

// 사용자 방(user:<id>)의 사용자 소켓에만 밀어 준다. 게이트웨이는 상태를 바꾸지 않고 이 포트로 알리기만 한다.
// 전달이 실패해도 이미 저장된 변경은 유효하므로 부르는 쪽은 실패를 삼킨다(앱은 다시 붙을 때 목록을 새로 읽는다).
// 테스트는 FakeRealtimePublisher로 바꿔 끼운다.
export abstract class RealtimePublisher {
  abstract toUsers(
    userIds: string[],
    event: RealtimeEvent,
    payload: object,
  ): Promise<void>;
}

// 게이트웨이가 연결 때 사용자를 넣는 방 이름. 앱과 서버가 같은 이름을 쓴다.
export const userRoom = (userId: string): string => `user:${userId}`;
