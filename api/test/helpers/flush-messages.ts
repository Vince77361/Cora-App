import { INestApplication } from '@nestjs/common';
import { MessageNotifier } from '../../src/conversations/message-notifier';

// 메시지 전달(실시간, 푸시)은 API 응답을 기다리게 하지 않으려고 응답 뒤에 따로 돈다.
// 전달 결과(보낸 이벤트, 푸시)를 확인하는 테스트는 요청 뒤에 이것으로 끝나기를 기다린다.
export const flushMessages = (app: INestApplication): Promise<void> =>
  app.get(MessageNotifier).flush();
