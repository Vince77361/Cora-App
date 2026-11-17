import { randomUUID } from 'node:crypto';
import { Logger } from '@nestjs/common';
import { Collaboration, ConversationMember, Message } from '@prisma/client';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeRealtimePublisher } from '../../test/support/fake-realtime-publisher';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
import { CreatorsService } from '../creators/creators.service';
import {
  ConversationsRepository,
  NewMessage,
  RoomWithCollaboration,
} from './conversations.repository';
import { ConversationsService } from './conversations.service';
import { MessageCreated, MessageEvents } from './message-events';

const BRAND = '11111111-1111-4111-8111-111111111111';
const CREATOR = '22222222-2222-4222-8222-222222222222';
const STRANGER = '33333333-3333-4333-8333-333333333333';
const ROOM = '44444444-4444-4444-8444-444444444444';
const T0 = new Date('2026-12-01T00:00:00.000Z');

// 서비스 규칙만 보려고 메모리에 두는 손 구현. 번호 부여(SQL)와 동시성은 e2e가 확인한다.
class FakeRepository extends ConversationsRepository {
  room: RoomWithCollaboration;
  readonly messages: Message[] = [];

  constructor() {
    super(null as never);
    const member = (userId: string): ConversationMember => ({
      id: randomUUID(),
      conversationId: ROOM,
      userId,
      lastReadSeq: 0,
      mutedAt: null,
      createdAt: T0,
      updatedAt: T0,
      deletedAt: null,
    });
    this.room = {
      id: ROOM,
      collaborationId: randomUUID(),
      status: 'OPEN',
      requestedById: null,
      lastSeq: 0,
      lastMessageAt: null,
      closedReason: null,
      createdAt: T0,
      updatedAt: T0,
      deletedAt: null,
      collaboration: {
        id: randomUUID(),
        kind: 'BRAND_CONTRACT',
        stage: 'NEGOTIATING',
        commissionerId: BRAND,
        creatorId: CREATOR,
      } as Collaboration,
      members: [member(BRAND), member(CREATOR)],
    };
  }

  findForMember(id: string, userId: string) {
    const isMember = this.room.members.some((m) => m.userId === userId);
    return Promise.resolve(id === ROOM && isMember ? this.room : null);
  }

  findByClientId(_conversationId: string, senderId: string, clientId: string) {
    return Promise.resolve(
      this.messages.find(
        (m) => m.senderId === senderId && m.clientId === clientId,
      ) ?? null,
    );
  }

  listMessages() {
    return Promise.resolve([...this.messages]);
  }

  findWithMembers() {
    return Promise.resolve(this.room);
  }

  markRead() {
    return Promise.resolve();
  }

  setMuted() {
    return Promise.resolve();
  }

  appendMessage(input: NewMessage) {
    if (input.requireOpen && this.room.status !== 'OPEN') {
      return Promise.resolve(null);
    }
    this.room.lastSeq += 1;
    const row: Message = {
      id: randomUUID(),
      conversationId: input.conversationId,
      seq: this.room.lastSeq,
      senderId: input.senderId,
      clientId: input.clientId,
      kind: input.kind,
      text: input.text,
      cardTitle: input.cardTitle,
      cardPhotoPath: input.cardPhotoPath,
      systemCode: input.systemCode,
      systemParams: input.systemParams as Message['systemParams'],
      createdAt: input.now,
      updatedAt: input.now,
      deletedAt: null,
    };
    this.messages.push(row);
    return Promise.resolve(row);
  }
}

class FakeCreators extends CreatorsService {
  card: { headline: string | null; photoPath: string | null } | null = {
    headline: '출근길 한 컵',
    photoPath: 'creators/card.jpg',
  };

  constructor() {
    super(null as never, null as never, null as never, null as never);
  }

  getCardCopy() {
    return Promise.resolve(this.card);
  }
}

describe('ConversationsService', () => {
  let repo: FakeRepository;
  let creators: FakeCreators;
  let events: MessageEvents;
  let published: MessageCreated[];
  let realtime: FakeRealtimePublisher;
  let service: ConversationsService;

  beforeEach(() => {
    repo = new FakeRepository();
    creators = new FakeCreators();
    events = new MessageEvents();
    published = [];
    realtime = new FakeRealtimePublisher();
    events.subscribe((event) => {
      published.push(event);
      return Promise.resolve();
    });
    service = new ConversationsService(
      repo,
      null as never,
      creators,
      null as never,
      null as never,
      null as never,
      null as never,
      new FakeStoragePort(),
      events,
      null as never,
      new FakeClock(T0),
      realtime,
    );
  });

  const text = (clientId = randomUUID(), body = '안녕하세요') =>
    ({ clientId, kind: 'TEXT', text: body }) as const;

  it('returns 404 to a user who is not a member for every conversation route', async () => {
    const notFound = { code: 'NOT_FOUND' };
    await expect(service.get(STRANGER, ROOM)).rejects.toMatchObject(notFound);
    await expect(
      service.listMessages(STRANGER, ROOM, {}),
    ).rejects.toMatchObject(notFound);
    await expect(service.send(STRANGER, ROOM, text())).rejects.toMatchObject(
      notFound,
    );
    await expect(service.markRead(STRANGER, ROOM, 0)).rejects.toMatchObject(
      notFound,
    );
    await expect(service.setMuted(STRANGER, ROOM, true)).rejects.toMatchObject(
      notFound,
    );
    // 형식이 틀린 ID도 같은 답이다(ID가 있는지 알려 주지 않는다).
    await expect(service.get(BRAND, 'not-a-uuid')).rejects.toMatchObject(
      notFound,
    );
    expect(repo.messages).toHaveLength(0);
  });

  it('returns the first message again for a repeated client id', async () => {
    const clientId = randomUUID();
    const first = await service.send(CREATOR, ROOM, text(clientId));
    const second = await service.send(CREATOR, ROOM, text(clientId, '다시'));
    expect(second.id).toBe(first.id);
    expect(second.text).toBe('안녕하세요');
    expect(repo.messages).toHaveLength(1);
    expect(published).toHaveLength(1);
  });

  it('copies the creator card title and photo path into a content card', async () => {
    const sent = await service.send(CREATOR, ROOM, {
      clientId: randomUUID(),
      kind: 'CONTENT_CARD',
    });
    expect(repo.messages[0]).toMatchObject({
      kind: 'CONTENT_CARD',
      cardTitle: '출근길 한 컵',
      cardPhotoPath: 'creators/card.jpg',
      text: null,
    });
    expect(sent.card?.title).toBe('출근길 한 컵');
    expect(sent.text).toBeNull();
    // 보낸 뒤 프로필의 카드를 고쳐도 대화의 카드는 그대로다(사본).
    creators.card = { headline: '바뀐 제목', photoPath: null };
    expect(repo.messages[0].cardTitle).toBe('출근길 한 컵');
  });

  it('refuses a content card from the commissioner and when the creator has no card', async () => {
    await expect(
      service.send(BRAND, ROOM, {
        clientId: randomUUID(),
        kind: 'CONTENT_CARD',
      }),
    ).rejects.toMatchObject({ code: 'FORBIDDEN' });
    creators.card = { headline: null, photoPath: null };
    await expect(
      service.send(CREATOR, ROOM, {
        clientId: randomUUID(),
        kind: 'CONTENT_CARD',
      }),
    ).rejects.toMatchObject({ code: 'CONFLICT' });
    expect(repo.messages).toHaveLength(0);
  });

  it('refuses to send into a room that is not open', async () => {
    for (const status of ['REQUESTED', 'DECLINED', 'CLOSED'] as const) {
      repo.room.status = status;
      await expect(service.send(CREATOR, ROOM, text())).rejects.toMatchObject({
        code: 'CONFLICT',
      });
    }
    expect(repo.messages).toHaveLength(0);
    expect(published).toHaveLength(0);
  });

  it('refuses a blank text and a text over 1000 characters', async () => {
    await expect(
      service.send(CREATOR, ROOM, text(randomUUID(), '   ')),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    await expect(
      service.send(CREATOR, ROOM, text(randomUUID(), '가'.repeat(1001))),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    await service.send(CREATOR, ROOM, text(randomUUID(), '가'.repeat(1000)));
    expect(repo.messages).toHaveLength(1);
  });

  it('shows the client id only to the sender', async () => {
    const clientId = randomUUID();
    await service.send(CREATOR, ROOM, text(clientId));
    const [mine] = await service.listMessages(CREATOR, ROOM, {});
    expect(mine).toMatchObject({ mine: true, clientId });
    const [theirs] = await service.listMessages(BRAND, ROOM, {});
    expect(theirs).toMatchObject({ mine: false, clientId: null });
  });

  it('refuses to mark read beyond the last number of the room', async () => {
    await service.send(CREATOR, ROOM, text());
    await expect(service.markRead(BRAND, ROOM, 2)).rejects.toMatchObject({
      code: 'VALIDATION_FAILED',
    });
  });

  describe('realtime updates', () => {
    it('tells both members when a room changed and only the reader about a read', async () => {
      await service.publishUpdated(ROOM, 'STATUS');
      await service.send(CREATOR, ROOM, text());
      await service.markRead(BRAND, ROOM, 1);
      expect(realtime.sent).toEqual([
        {
          userIds: [BRAND, CREATOR],
          event: 'conversation.updated',
          payload: { conversationId: ROOM, reason: 'STATUS' },
        },
        {
          userIds: [BRAND],
          event: 'conversation.updated',
          payload: { conversationId: ROOM, reason: 'READ' },
        },
      ]);
    });

    it('tells only the member who muted the room', async () => {
      await service.setMuted(CREATOR, ROOM, true);
      expect(realtime.sent).toEqual([
        {
          userIds: [CREATOR],
          event: 'conversation.updated',
          payload: { conversationId: ROOM, reason: 'STATUS' },
        },
      ]);
    });

    it('does not fail the request when the realtime delivery fails', async () => {
      // 실패는 로그로만 남는다. 테스트 출력에 섞이지 않게 막고, 남겼는지 확인한다.
      const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
      realtime.fail = true;
      await expect(service.markRead(BRAND, ROOM, 0)).resolves.toBeUndefined();
      await expect(service.setMuted(BRAND, ROOM, true)).resolves.toEqual({
        muted: true,
      });
      expect(warn).toHaveBeenCalledTimes(2);
      warn.mockRestore();
    });

    it('builds the new message from each member point of view', async () => {
      await service.send(CREATOR, ROOM, text());
      const delivered = await service.deliveriesOf(published[0]);
      const byUser = new Map(
        delivered?.deliveries.map((d) => [d.userId, d]) ?? [],
      );
      expect(byUser.get(CREATOR)).toMatchObject({
        isSender: true,
        message: { mine: true },
      });
      expect(byUser.get(BRAND)).toMatchObject({
        isSender: false,
        message: { mine: false, clientId: null },
        preview: '안녕하세요',
        muted: false,
      });
    });
  });
});
