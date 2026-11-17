import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { NotificationsService } from '../notifications/notifications.service';
import { PresenceService } from '../realtime/presence.service';
import { RealtimePublisher } from '../realtime/realtime-publisher';
import { ConversationsService, MessageDelivery } from './conversations.service';
import { MessageCreated, MessageEvents } from './message-events';

// 저장된 메시지(안내 줄 포함)를 두 가지로 전한다.
// 1) 참가자 둘의 화면에 message.created를 밀어 준다(받는 사람 기준으로 mine을 맞춰 따로 보낸다). 방에 없는 사람에게는 가지 않는다.
// 2) 보낸 사람이 아닌 쪽이 앱에 연결돼 있지 않으면 푸시를 한다. 푸시는 NotificationsService.notify({ kind: 'MESSAGE', roomMuted })를 지난다:
//    대화 메시지 스위치와 방의 알림 끄기가 둘 다 허용해야 나가고, 알림함에는 남지 않는다.
// 푸시를 하지 않는 경우: 안내 줄(조건·계약 사건의 알림은 협업 알림이 따로 보내서 같은 일로 두 번 울리지 않게 한다),
// 아직 수락하지 않은 메시지 요청의 첫 메시지(MESSAGE_REQUEST가 이미 갔다).
@Injectable()
export class MessageNotifier implements OnModuleInit {
  private readonly logger = new Logger(MessageNotifier.name);

  constructor(
    private readonly events: MessageEvents,
    private readonly conversations: ConversationsService,
    private readonly realtime: RealtimePublisher,
    private readonly presence: PresenceService,
    private readonly notifications: NotificationsService,
  ) {}

  onModuleInit(): void {
    this.events.subscribe((event) => this.onCreated(event));
  }

  async onCreated(event: MessageCreated): Promise<void> {
    const delivered = await this.conversations.deliveriesOf(event);
    if (!delivered) return;
    const { conversationId, deliveries } = delivered;
    // 한 사람의 전달이 실패해도 다른 사람의 전달과 푸시는 계속한다.
    await Promise.all(
      deliveries.map((delivery) =>
        this.realtime
          .toUsers([delivery.userId], 'message.created', {
            conversationId,
            message: delivery.message,
          })
          .catch((error: unknown) => this.warn('실시간 전달', error)),
      ),
    );
    if (event.message.kind === 'SYSTEM' || delivered.status === 'REQUESTED') {
      return;
    }
    await Promise.all(
      deliveries
        .filter((delivery) => !delivery.isSender)
        .map((delivery) =>
          this.push(conversationId, event.message.senderId, delivery),
        ),
    );
  }

  private async push(
    conversationId: string,
    senderId: string | null,
    delivery: MessageDelivery,
  ): Promise<void> {
    try {
      // 연결을 읽지 못하면 오프라인으로 본다(푸시가 한 번 더 가는 쪽이 메시지를 놓치는 것보다 낫다).
      const online = await this.presence
        .isOnline(delivery.userId)
        .catch(() => false);
      if (online) return;
      await this.notifications.notify({
        userId: delivery.userId,
        role: delivery.role,
        kind: 'MESSAGE',
        params: { preview: delivery.preview },
        actor: {
          userId: senderId ?? '',
          name: await delivery.senderName(),
          photoPath: null,
        },
        target: { kind: 'CONVERSATION', id: conversationId },
        roomMuted: delivery.muted,
      });
    } catch (error) {
      this.warn('메시지 푸시', error);
    }
  }

  // 이름과 본문에는 개인정보가 들어갈 수 있어 오류 이름만 남긴다.
  private warn(what: string, error: unknown): void {
    this.logger.warn(
      `${what}을 하지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
    );
  }
}
