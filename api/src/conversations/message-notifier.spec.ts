import { Logger } from '@nestjs/common';
import { Message } from '@prisma/client';
import { FakePresence } from '../../test/support/fake-presence';
import { FakeRealtimePublisher } from '../../test/support/fake-realtime-publisher';
import {
  NotificationsService,
  NotifyInput,
} from '../notifications/notifications.service';
import {
  ConversationsService,
  MessageDeliveries,
} from './conversations.service';
import { MessageCreated, MessageEvents } from './message-events';
import { MessageNotifier } from './message-notifier';

const BRAND = '11111111-1111-4111-8111-111111111111';
const CREATOR = '22222222-2222-4222-8222-222222222222';
const ROOM = '44444444-4444-4444-8444-444444444444';

// 방을 읽는 대신 정해 둔 전달 목록을 돌려주는 손 구현. 방과 사람별 메시지 만들기는 e2e와 서비스 spec이 확인한다.
class FakeConversations extends ConversationsService {
  deliveries: MessageDeliveries | null = null;

  constructor() {
    super(
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
    );
  }

  deliveriesOf() {
    return Promise.resolve(this.deliveries);
  }
}

class FakeNotifications extends NotificationsService {
  readonly sent: NotifyInput[] = [];
  fail = false;

  constructor() {
    super(null as never, null as never, null as never);
  }

  notify(input: NotifyInput) {
    if (this.fail) return Promise.reject(new Error('notify down'));
    this.sent.push(input);
    return Promise.resolve();
  }
}

const message = (over: Partial<Message> = {}): Message =>
  ({
    id: 'msg-1',
    conversationId: ROOM,
    seq: 1,
    senderId: CREATOR,
    kind: 'TEXT',
    text: '안녕하세요',
    ...over,
  }) as Message;

const event = (over: Partial<Message> = {}): MessageCreated => ({
  conversationId: ROOM,
  collaborationId: 'collab-1',
  message: message(over),
  memberIds: [BRAND, CREATOR],
});

function delivery(userId: string, over: Record<string, unknown> = {}) {
  return {
    userId,
    role: userId === BRAND ? ('BRAND' as const) : ('CREATOR' as const),
    isSender: userId === CREATOR,
    muted: false,
    message: {
      id: 'msg-1',
      mine: userId === CREATOR,
      text: '안녕하세요',
    } as never,
    preview: '안녕하세요',
    senderName: () => Promise.resolve('하루 한 컵'),
    ...over,
  };
}

describe('MessageNotifier', () => {
  let conversations: FakeConversations;
  let realtime: FakeRealtimePublisher;
  let presence: FakePresence;
  let notifications: FakeNotifications;
  let notifier: MessageNotifier;

  beforeEach(() => {
    conversations = new FakeConversations();
    conversations.deliveries = {
      conversationId: ROOM,
      status: 'OPEN',
      deliveries: [delivery(BRAND), delivery(CREATOR)],
    };
    realtime = new FakeRealtimePublisher();
    presence = new FakePresence();
    notifications = new FakeNotifications();
    notifier = new MessageNotifier(
      new MessageEvents(),
      conversations,
      realtime,
      presence,
      notifications,
    );
  });

  it('sends message.created to both members, each with their own copy', async () => {
    await notifier.onCreated(event());
    expect(realtime.sent).toHaveLength(2);
    expect(realtime.receivedBy(BRAND, 'message.created')[0]).toMatchObject({
      payload: { conversationId: ROOM, message: { mine: false } },
    });
    expect(realtime.receivedBy(CREATOR, 'message.created')[0]).toMatchObject({
      payload: { conversationId: ROOM, message: { mine: true } },
    });
  });

  it('pushes an offline receiver with the sender name and the preview and never the sender', async () => {
    await notifier.onCreated(event());
    expect(notifications.sent).toEqual([
      {
        userId: BRAND,
        role: 'BRAND',
        kind: 'MESSAGE',
        params: { preview: '안녕하세요' },
        actor: { userId: CREATOR, name: '하루 한 컵', photoPath: null },
        target: { kind: 'CONVERSATION', id: ROOM },
        roomMuted: false,
      },
    ]);
  });

  it('does not push a receiver who is connected', async () => {
    presence.online.add(BRAND);
    await notifier.onCreated(event());
    expect(notifications.sent).toHaveLength(0);
    // 연결돼 있어도 실시간 전달은 간다.
    expect(realtime.receivedBy(BRAND)).toHaveLength(1);
  });

  it('hands the room mute to notify so a muted room is not pushed', async () => {
    conversations.deliveries = {
      conversationId: ROOM,
      status: 'OPEN',
      deliveries: [delivery(BRAND, { muted: true }), delivery(CREATOR)],
    };
    await notifier.onCreated(event());
    expect(notifications.sent).toHaveLength(1);
    expect(notifications.sent[0].roomMuted).toBe(true);
  });

  it('does not push a system line but still delivers it', async () => {
    await notifier.onCreated(
      event({ senderId: null, kind: 'SYSTEM', systemCode: 'MATCHED' }),
    );
    expect(notifications.sent).toHaveLength(0);
    expect(realtime.sent).toHaveLength(2);
  });

  it('does not push the first message of a message request that is not accepted yet', async () => {
    conversations.deliveries = {
      conversationId: ROOM,
      status: 'REQUESTED',
      deliveries: [delivery(BRAND), delivery(CREATOR)],
    };
    await notifier.onCreated(event());
    expect(notifications.sent).toHaveLength(0);
    expect(realtime.sent).toHaveLength(2);
  });

  it('does nothing for a room that cannot be read any more', async () => {
    conversations.deliveries = null;
    await notifier.onCreated(event());
    expect(realtime.sent).toHaveLength(0);
    expect(notifications.sent).toHaveLength(0);
  });

  it('still pushes when the realtime delivery fails, and pushes when presence cannot be read', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    realtime.fail = true;
    presence.fail = true;
    await notifier.onCreated(event());
    expect(notifications.sent).toHaveLength(1);
    // 실시간 전달 실패 두 번이 로그로 남는다(본문 없이).
    expect(warn).toHaveBeenCalledTimes(2);
    warn.mockRestore();
  });

  it('does not throw when the push fails', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    notifications.fail = true;
    await expect(notifier.onCreated(event())).resolves.toBeUndefined();
    warn.mockRestore();
  });

  it('listens to the message events', async () => {
    const events = new MessageEvents();
    const wired = new MessageNotifier(
      events,
      conversations,
      realtime,
      presence,
      notifications,
    );
    wired.onModuleInit();
    await events.publish(event());
    expect(realtime.sent).toHaveLength(2);
  });
});
