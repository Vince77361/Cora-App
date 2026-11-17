import { Injectable, Logger } from '@nestjs/common';
import { Message } from '@prisma/client';

// 메시지가 저장된 뒤(안내 줄 포함) 한 번 나가는 내부 이벤트. 알림(푸시)과 실시간 게이트웨이가 받는다(4번 Task).
// 저장된 행 그대로 싣는다: 안내 줄의 문구는 읽는 사람마다 달라 받는 쪽이 사람별로 만든다.
export interface MessageCreated {
  conversationId: string;
  collaborationId: string;
  message: Message;
  // 방의 참가자 전부(보낸 사람 포함).
  memberIds: string[];
}

export type MessageCreatedHandler = (event: MessageCreated) => Promise<void>;

// 이 코드베이스에는 이벤트 이미터 패키지가 없어 작업 처리기 표(JobHandlerRegistry)처럼 구독자를 등록받는
// 작은 발행기를 둔다. 구독자의 실패는 이미 저장된 메시지를 되돌리지 않는다(로그만 남긴다).
@Injectable()
export class MessageEvents {
  private readonly logger = new Logger(MessageEvents.name);
  private readonly handlers: MessageCreatedHandler[] = [];

  subscribe(handler: MessageCreatedHandler): void {
    this.handlers.push(handler);
  }

  async publish(event: MessageCreated): Promise<void> {
    for (const handler of this.handlers) {
      try {
        await handler(event);
      } catch (error) {
        this.logger.warn(
          `메시지 이벤트를 처리하지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
  }
}
