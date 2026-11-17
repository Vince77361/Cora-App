import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import {
  CollaborationStage,
  ConversationStatus,
  PrismaClient,
} from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { ConversationsService } from '../src/conversations/conversations.service';
import {
  MessageCreated,
  MessageEvents,
} from '../src/conversations/message-events';
import { PushPort } from '../src/integrations/push/push.port';
import { PresenceService } from '../src/realtime/presence.service';
import { RealtimePublisher } from '../src/realtime/realtime-publisher';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { flushMessages } from './helpers/flush-messages';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakePresence } from './support/fake-presence';
import { FakePushPort } from './support/fake-push.port';
import { FakeRealtimePublisher } from './support/fake-realtime-publisher';
import { OTHER, USER_A } from './support/fake-token-verifier';

const authBrand = { Authorization: 'Bearer user-a' };
const authCreator = { Authorization: 'Bearer user-b' };
const T0 = new Date('2026-12-01T00:00:00.000Z');

interface Msg {
  id: string;
  seq: number;
  kind: string;
  mine: boolean;
  clientId: string | null;
  text: string | null;
  card: { title: string; photoUrl: string | null } | null;
  createdAt: string;
}
interface Summary {
  id: string;
  status: string;
  section: string;
  counterpart: { userId: string; name: string; photoUrl: string | null };
  contextLabel: string;
  lastMessage: { kind: string; preview: string; at: string } | null;
  unreadCount: number;
  muted: boolean;
}
interface Detail extends Summary {
  collaborationId: string;
  stage: string;
  myRole: string;
  requestedByMe: boolean;
  blockedByMe: boolean;
  lastSeq: number;
  lastReadSeq: number;
  terms: unknown;
  campaignTerms: { fee: number; format: string } | null;
  storeTerms: { format: string; fixedCash: number } | null;
  contractStatus: string;
  canSend: boolean;
  canSendContentCard: boolean;
  canProposeTerms: boolean;
  canDrop: boolean;
  canLikeCampaign: boolean;
}

describe('conversations', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let realtime: FakeRealtimePublisher;
  let presence: FakePresence;
  let push: FakePushPort;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const send = (
    auth: Record<string, string>,
    roomId: string,
    body: Record<string, unknown>,
  ) =>
    request(server)
      .post(`/conversations/${roomId}/messages`)
      .set(auth)
      .send(body);
  const text = (body = '안녕하세요', clientId = randomUUID()) => ({
    clientId,
    kind: 'TEXT',
    text: body,
  });
  const messages = async (
    auth: Record<string, string>,
    roomId: string,
    query = '',
  ) =>
    (
      await request(server)
        .get(`/conversations/${roomId}/messages${query}`)
        .set(auth)
        .expect(200)
    ).body as Msg[];
  const detail = async (auth: Record<string, string>, roomId: string) =>
    (
      await request(server)
        .get(`/conversations/${roomId}`)
        .set(auth)
        .expect(200)
    ).body as Detail;
  const list = async (auth: Record<string, string>) =>
    (await request(server).get('/conversations').set(auth).expect(200))
      .body as Summary[];

  // 브랜드(user-a)와 크리에이터(user-b)가 있고, 둘 사이에 협업 하나와 방 하나를 만든다.
  async function seedParties(): Promise<{ campaignId: string }> {
    await prisma.user.createMany({
      data: [
        { id: USER_A, role: 'BRAND' },
        { id: OTHER, role: 'CREATOR' },
      ],
    });
    await prisma.brandProfile.create({
      data: { userId: USER_A, name: '느린결', industry: 'ACCESSORY' },
    });
    await prisma.creatorProfile.create({
      data: {
        userId: OTHER,
        displayName: '하루 한 컵',
        regionSido: '서울특별시',
        cardHeadline: '출근길 한 컵',
        cardPhotoPath: 'creators/card.jpg',
      },
    });
    const campaign = await prisma.campaign.create({
      data: {
        brandId: USER_A,
        status: 'ACTIVE',
        headline: '나만의 아침 루틴 속 작은 포인트',
        fee: 300000,
        budget: 1000000,
        productProvided: true,
        format: 'REELS',
        startFrom: new Date('2026-11-20'),
        trialDays: 'D7',
        mustInclude: [],
        notRequired: [],
      },
    });
    return { campaignId: campaign.id };
  }

  async function seedRoom(
    campaignId: string,
    over: {
      stage?: CollaborationStage;
      status?: ConversationStatus;
      requestedById?: string | null;
    } = {},
  ): Promise<{ collaborationId: string; roomId: string }> {
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'BRAND_CONTRACT',
        stage: over.stage ?? 'NEGOTIATING',
        commissionerId: USER_A,
        creatorId: OTHER,
        campaignId,
        terms: {},
        settlementMethod: 'FIXED',
      },
    });
    const room = await prisma.conversation.create({
      data: {
        collaborationId: collaboration.id,
        status: over.status ?? 'OPEN',
        requestedById: over.requestedById ?? null,
        members: { create: [{ userId: USER_A }, { userId: OTHER }] },
      },
    });
    return { collaborationId: collaboration.id, roomId: room.id };
  }

  // 두 사람과 무관한 방(user-a는 참가자가 아니다).
  async function seedStrangersRoom(): Promise<string> {
    const [brand, creator] = [randomUUID(), randomUUID()];
    await prisma.user.createMany({
      data: [
        { id: brand, role: 'BRAND' },
        { id: creator, role: 'CREATOR' },
      ],
    });
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'BRAND_CONTRACT',
        stage: 'MATCHED',
        commissionerId: brand,
        creatorId: creator,
        terms: {},
        settlementMethod: 'FIXED',
      },
    });
    const room = await prisma.conversation.create({
      data: {
        collaborationId: collaboration.id,
        status: 'OPEN',
        members: { create: [{ userId: brand }, { userId: creator }] },
      },
    });
    return room.id;
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp([], { fakeRealtime: true });
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    realtime = app.get<FakeRealtimePublisher>(RealtimePublisher);
    presence = app.get<FakePresence>(PresenceService);
    push = app.get<FakePushPort>(PushPort);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(T0);
    realtime.sent.length = 0;
    realtime.fail = false;
    presence.online.clear();
    push.sent.length = 0;
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).get('/conversations').expect(401);
    await request(server).get(`/conversations/${randomUUID()}`).expect(401);
  });

  describe('realtime and push', () => {
    it('delivers a sent message to both members with their own mine flag, once per client id', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      const clientId = randomUUID();
      await send(authCreator, roomId, text('안녕하세요', clientId)).expect(201);
      await send(authCreator, roomId, text('안녕하세요', clientId)).expect(201);
      await flushMessages(app);
      const forBrand = realtime.receivedBy(USER_A, 'message.created');
      const forCreator = realtime.receivedBy(OTHER, 'message.created');
      expect(forBrand).toHaveLength(1);
      expect(forCreator).toHaveLength(1);
      expect(forBrand[0].payload).toMatchObject({
        conversationId: roomId,
        message: { seq: 1, mine: false, clientId: null, text: '안녕하세요' },
      });
      expect(forCreator[0].payload).toMatchObject({
        message: { seq: 1, mine: true, clientId },
      });
      // 같은 clientId로 다시 보내도 푸시는 한 번만 간다.
      expect(push.sent).toHaveLength(1);
    });

    it('tells only the reader about a read and only the one who muted about a mute', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      await send(authCreator, roomId, text()).expect(201);
      await flushMessages(app);
      realtime.sent.length = 0;
      await request(server)
        .post(`/conversations/${roomId}/read`)
        .set(authBrand)
        .send({ seq: 1 })
        .expect(204);
      await request(server)
        .put(`/conversations/${roomId}/mute`)
        .set(authCreator)
        .send({ muted: true })
        .expect(200);
      expect(realtime.sent).toEqual([
        {
          userIds: [USER_A],
          event: 'conversation.updated',
          payload: { conversationId: roomId, reason: 'READ' },
        },
        {
          userIds: [OTHER],
          event: 'conversation.updated',
          payload: { conversationId: roomId, reason: 'STATUS' },
        },
      ]);
    });

    it('sends nothing for a failed send and does not fail a send when the delivery fails', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId, { status: 'CLOSED' });
      await send(authCreator, roomId, text()).expect(409);
      expect(realtime.sent).toEqual([]);
      expect(push.sent).toEqual([]);
      await prisma.conversation.update({
        where: { id: roomId },
        data: { status: 'OPEN' },
      });
      realtime.fail = true;
      await send(authCreator, roomId, text()).expect(201);
      await flushMessages(app);
      // 실시간 전달이 실패해도 메시지는 저장되고 푸시는 간다.
      expect(await messages(authBrand, roomId)).toHaveLength(1);
      expect(push.sent).toHaveLength(1);
    });

    it('treats a connected receiver as online and does not push', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      presence.online.add(USER_A);
      await send(authCreator, roomId, text()).expect(201);
      await flushMessages(app);
      expect(push.sent).toEqual([]);
    });

    it('answers a send without waiting for the connection check or the push', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      // 연결 확인이 끝나지 않는 상황(Redis 응답 시간 제한 대기)에서도 보내기 응답은 바로 온다.
      let release: (online: boolean) => void = () => undefined;
      const original = presence.isOnline.bind(presence);
      const asked = new Promise<void>((resolve) => {
        presence.isOnline = () =>
          new Promise<boolean>((answer) => {
            release = answer;
            resolve();
          });
      });
      try {
        await send(authCreator, roomId, text()).expect(201);
        // 응답은 이미 왔는데 연결 확인은 아직 답이 없다.
        await asked;
        expect(push.sent).toEqual([]);
        release(false);
        await flushMessages(app);
        expect(push.sent).toHaveLength(1);
      } finally {
        presence.isOnline = original;
      }
    });
  });

  describe('sending', () => {
    it('numbers 20 concurrent sends without gaps or duplicates', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      const responses = await Promise.all(
        Array.from({ length: 20 }, (_, i) =>
          send(
            i % 2 === 0 ? authBrand : authCreator,
            roomId,
            text(`메시지 ${i}`),
          ),
        ),
      );
      expect(responses.map((r) => r.status)).toEqual(Array(20).fill(201));
      const seqs = responses
        .map((r) => (r.body as Msg).seq)
        .sort((a, b) => a - b);
      expect(seqs).toEqual(Array.from({ length: 20 }, (_, i) => i + 1));
      const rows = await prisma.message.findMany({ orderBy: { seq: 'asc' } });
      expect(rows.map((r) => r.seq)).toEqual(seqs);
      expect(
        (await prisma.conversation.findUniqueOrThrow({ where: { id: roomId } }))
          .lastSeq,
      ).toBe(20);
    });

    it('returns the first message again for a repeated client id', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      const clientId = randomUUID();
      const first = await send(
        authBrand,
        roomId,
        text('첫 글', clientId),
      ).expect(201);
      const second = await send(
        authBrand,
        roomId,
        text('두 번째 글', clientId),
      ).expect(201);
      expect((second.body as Msg).id).toBe((first.body as Msg).id);
      expect((second.body as Msg).text).toBe('첫 글');
      expect(await prisma.message.count()).toBe(1);
    });

    it('keeps one row when the same client id arrives twice at the same time', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      const clientId = randomUUID();
      const [a, b] = await Promise.all([
        send(authBrand, roomId, text('같은 글', clientId)),
        send(authBrand, roomId, text('같은 글', clientId)),
      ]);
      expect([a.status, b.status]).toEqual([201, 201]);
      expect((a.body as Msg).id).toBe((b.body as Msg).id);
      const rows = await prisma.message.findMany();
      expect(rows).toHaveLength(1);
      // 진 쪽의 번호 증가는 문장과 함께 사라져 다음 번호가 빠지지 않는다.
      await send(authCreator, roomId, text('다음 글')).expect(201);
      expect(
        (await prisma.message.findMany({ orderBy: { seq: 'asc' } })).map(
          (r) => r.seq,
        ),
      ).toEqual([1, 2]);
    });

    it('copies the creator card title and photo path into a content card', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      const res = await send(authCreator, roomId, {
        clientId: randomUUID(),
        kind: 'CONTENT_CARD',
      }).expect(201);
      const body = res.body as Msg;
      expect(body).toMatchObject({
        kind: 'CONTENT_CARD',
        text: null,
        mine: true,
      });
      expect(body.card?.title).toBe('출근길 한 컵');
      expect(body.card?.photoUrl).toContain('creators/card.jpg');
      // 프로필의 카드를 고쳐도 보낸 카드는 그대로다.
      await prisma.creatorProfile.update({
        where: { userId: OTHER },
        data: { cardHeadline: '바뀐 제목', cardPhotoPath: null },
      });
      const seen = await messages(authBrand, roomId);
      expect(seen[0].card?.title).toBe('출근길 한 컵');
      expect(seen[0].mine).toBe(false);
      const row = await prisma.message.findFirstOrThrow();
      expect(row).toMatchObject({
        cardTitle: '출근길 한 컵',
        cardPhotoPath: 'creators/card.jpg',
      });
    });

    it('refuses a content card from the brand and one without a card', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      const card = { clientId: randomUUID(), kind: 'CONTENT_CARD' };
      expect(codeOf(await send(authBrand, roomId, card).expect(403))).toBe(
        'FORBIDDEN',
      );
      await prisma.creatorProfile.update({
        where: { userId: OTHER },
        data: { cardHeadline: null },
      });
      expect(codeOf(await send(authCreator, roomId, card).expect(409))).toBe(
        'CONFLICT',
      );
      expect(await prisma.message.count()).toBe(0);
    });

    it('validates the body', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      await send(authBrand, roomId, { kind: 'TEXT', text: '글' }).expect(400);
      await send(authBrand, roomId, {
        clientId: 'x',
        kind: 'TEXT',
        text: '글',
      }).expect(400);
      await send(authBrand, roomId, text('')).expect(400);
      await send(authBrand, roomId, text('   ')).expect(400);
      await send(authBrand, roomId, text('가'.repeat(1001))).expect(400);
      await send(authBrand, roomId, {
        clientId: randomUUID(),
        kind: 'SYSTEM',
        text: '글',
      }).expect(400);
      await send(authBrand, roomId, text('가'.repeat(1000))).expect(201);
    });

    it('refuses to send into a room that is not open', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId, {
        status: 'REQUESTED',
        requestedById: OTHER,
      });
      expect(codeOf(await send(authBrand, roomId, text()).expect(409))).toBe(
        'CONFLICT',
      );
      expect(codeOf(await send(authCreator, roomId, text()).expect(409))).toBe(
        'CONFLICT',
      );
      await prisma.conversation.update({
        where: { id: roomId },
        data: { status: 'CLOSED', closedReason: 'BLOCKED' },
      });
      await send(authCreator, roomId, text()).expect(409);
      expect(await prisma.message.count()).toBe(0);
    });

    it('publishes a message created event for the subscribers', async () => {
      const { campaignId } = await seedParties();
      const { roomId, collaborationId } = await seedRoom(campaignId);
      const seen: MessageCreated[] = [];
      app.get(MessageEvents).subscribe((event) => {
        seen.push(event);
        return Promise.resolve();
      });
      const res = await send(authBrand, roomId, text()).expect(201);
      expect(seen).toHaveLength(1);
      expect(seen[0]).toMatchObject({
        conversationId: roomId,
        collaborationId,
        message: { id: (res.body as Msg).id, seq: 1, senderId: USER_A },
      });
      expect([...seen[0].memberIds].sort()).toEqual([USER_A, OTHER].sort());
    });
  });

  describe('reading', () => {
    it('returns 404 to a user who is not a member for every conversation route', async () => {
      await seedParties();
      const roomId = await seedStrangersRoom();
      const missing = randomUUID();
      for (const id of [roomId, missing]) {
        await request(server)
          .get(`/conversations/${id}`)
          .set(authBrand)
          .expect(404);
        await request(server)
          .get(`/conversations/${id}/messages`)
          .set(authBrand)
          .expect(404);
        await send(authBrand, id, text()).expect(404);
        await request(server)
          .post(`/conversations/${id}/read`)
          .set(authBrand)
          .send({ seq: 0 })
          .expect(404);
        await request(server)
          .put(`/conversations/${id}/mute`)
          .set(authBrand)
          .send({ muted: true })
          .expect(404);
      }
      expect(await prisma.message.count()).toBe(0);
      expect(await list(authBrand)).toEqual([]);
    });

    it('pages backwards with beforeSeq and forwards with afterSeq', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      for (let i = 1; i <= 7; i++) {
        await send(authBrand, roomId, text(`글 ${i}`)).expect(201);
      }
      const seqs = (rows: Msg[]) => rows.map((r) => r.seq);
      expect(seqs(await messages(authCreator, roomId))).toEqual([
        1, 2, 3, 4, 5, 6, 7,
      ]);
      expect(seqs(await messages(authCreator, roomId, '?limit=3'))).toEqual([
        5, 6, 7,
      ]);
      expect(
        seqs(await messages(authCreator, roomId, '?beforeSeq=5&limit=2')),
      ).toEqual([3, 4]);
      expect(seqs(await messages(authCreator, roomId, '?afterSeq=5'))).toEqual([
        6, 7,
      ]);
      expect(
        seqs(await messages(authCreator, roomId, '?afterSeq=0&limit=2')),
      ).toEqual([1, 2]);
      await request(server)
        .get(`/conversations/${roomId}/messages?limit=51`)
        .set(authCreator)
        .expect(400);
    });

    it('counts unread messages from lastReadSeq and never moves it backwards', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      for (let i = 1; i <= 3; i++) {
        await send(authBrand, roomId, text(`글 ${i}`)).expect(201);
      }
      expect((await list(authCreator))[0].unreadCount).toBe(3);
      // 내가 보낸 메시지는 내 안 읽은 수에 세지 않는다.
      expect((await list(authBrand))[0].unreadCount).toBe(0);
      const read = (seq: number) =>
        request(server)
          .post(`/conversations/${roomId}/read`)
          .set(authCreator)
          .send({ seq });
      await read(2).expect(204);
      expect((await list(authCreator))[0].unreadCount).toBe(1);
      await read(1).expect(204);
      expect((await detail(authCreator, roomId)).lastReadSeq).toBe(2);
      expect(codeOf(await read(4).expect(400))).toBe('VALIDATION_FAILED');
      await read(3).expect(204);
      expect((await list(authCreator))[0].unreadCount).toBe(0);
    });

    it('sets the mute flag per member', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      const res = await request(server)
        .put(`/conversations/${roomId}/mute`)
        .set(authCreator)
        .send({ muted: true })
        .expect(200);
      expect(res.body).toEqual({ muted: true });
      expect((await list(authCreator))[0].muted).toBe(true);
      expect((await list(authBrand))[0].muted).toBe(false);
      await request(server)
        .put(`/conversations/${roomId}/mute`)
        .set(authCreator)
        .send({ muted: false })
        .expect(200);
      expect((await list(authCreator))[0].muted).toBe(false);
    });

    it('renders an announcement line for the one who dropped and for the other side', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId);
      await prisma.$transaction(async (tx) => {
        await app
          .get(ConversationsService)
          .postSystem(roomId, 'DROPPED', { droppedById: OTHER }, tx);
      });
      const [mine] = await messages(authCreator, roomId);
      const [theirs] = await messages(authBrand, roomId);
      expect(mine).toMatchObject({
        kind: 'SYSTEM',
        mine: false,
        text: '협의를 그만뒀어요.',
      });
      expect(theirs.text).toBe('이번에는 함께하기 어렵대요.');
    });
  });

  describe('the list and the room head', () => {
    it('puts message requests first, then the latest message, and cuts the preview at 60 characters', async () => {
      const { campaignId } = await seedParties();
      const quiet = await seedRoom(campaignId, { status: 'OPEN' });
      // 같은 쌍의 협업이 하나뿐이라 요청 방은 다른 크리에이터와 만든다.
      const requester = randomUUID();
      await prisma.user.create({ data: { id: requester, role: 'CREATOR' } });
      await prisma.creatorProfile.create({
        data: {
          userId: requester,
          displayName: '요청한 사람',
          regionSido: '서울특별시',
        },
      });
      const requestCollab = await prisma.collaboration.create({
        data: {
          kind: 'BRAND_CONTRACT',
          stage: 'INQUIRY',
          commissionerId: USER_A,
          creatorId: requester,
          campaignId,
          terms: {},
          settlementMethod: 'FIXED',
        },
      });
      const request1 = await prisma.conversation.create({
        data: {
          collaborationId: requestCollab.id,
          status: 'REQUESTED',
          requestedById: requester,
          members: { create: [{ userId: USER_A }, { userId: requester }] },
        },
      });
      await send(authCreator, quiet.roomId, text('가'.repeat(61))).expect(201);
      const rooms = await list(authBrand);
      expect(rooms.map((r) => r.id)).toEqual([request1.id, quiet.roomId]);
      expect(rooms[0]).toMatchObject({
        status: 'REQUESTED',
        section: 'REQUEST',
        lastMessage: null,
        counterpart: { userId: requester, name: '요청한 사람' },
        contextLabel: '나만의 아침 루틴 속 작은 포인트',
      });
      expect(rooms[1]).toMatchObject({ section: 'NORMAL', unreadCount: 1 });
      expect(rooms[1].lastMessage?.preview).toBe(`${'가'.repeat(60)}…`);
      expect(rooms[1].counterpart).toMatchObject({
        userId: OTHER,
        name: '하루 한 컵',
      });
    });

    it('hides a request I declined and keeps the one that was declined for the requester', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId, {
        status: 'DECLINED',
        requestedById: OTHER,
      });
      // 브랜드(user-a)가 거절했다: 요청자(user-b)가 아닌 쪽의 목록에서는 빠진다.
      expect(await list(authBrand)).toEqual([]);
      const mine = await list(authCreator);
      expect(mine.map((r) => [r.id, r.status])).toEqual([[roomId, 'DECLINED']]);
      // 빠진 요청도 ID로 읽는 것은 막지 않는다(참가자다).
      await request(server)
        .get(`/conversations/${roomId}`)
        .set(authBrand)
        .expect(200);
    });

    it('shows the room head of a brand contract while negotiating', async () => {
      const { campaignId } = await seedParties();
      const { roomId, collaborationId } = await seedRoom(campaignId, {
        stage: 'NEGOTIATING',
      });
      const asBrand = await detail(authBrand, roomId);
      expect(asBrand).toMatchObject({
        collaborationId,
        stage: 'NEGOTIATING',
        myRole: 'COMMISSIONER',
        requestedByMe: false,
        blockedByMe: false,
        lastSeq: 0,
        terms: null,
        campaignTerms: null,
        storeTerms: null,
        contractStatus: 'NONE',
        canSend: true,
        canSendContentCard: false,
        canProposeTerms: true,
        canDrop: true,
        canLikeCampaign: false,
      });
      const asCreator = await detail(authCreator, roomId);
      expect(asCreator).toMatchObject({
        myRole: 'CREATOR',
        canSendContentCard: true,
        counterpart: { userId: USER_A, name: '느린결' },
      });
    });

    it('shows the campaign terms and the like button before mutual interest', async () => {
      const { campaignId } = await seedParties();
      const { roomId } = await seedRoom(campaignId, { stage: 'INQUIRY' });
      const asCreator = await detail(authCreator, roomId);
      expect(asCreator).toMatchObject({
        campaignTerms: {
          fee: 300000,
          format: 'REELS',
          productProvided: true,
          startFrom: '2026-11-20',
        },
        terms: null,
        canLikeCampaign: true,
        canProposeTerms: false,
        canDrop: true,
      });
      expect((await detail(authBrand, roomId)).canLikeCampaign).toBe(false);
    });

    it('shows the accepted terms of a store offer in the room head', async () => {
      await seedParties();
      const owner = USER_A;
      const store = await prisma.store.create({
        data: {
          ownerId: owner,
          status: 'PUBLISHED',
          onboardingStep: 'DONE',
          name: '한그릇 라멘',
          industry: 'FOOD_CAFE',
          regionSido: '서울특별시',
          defaultFormat: 'REELS',
          publishedAt: T0,
        },
      });
      const collaboration = await prisma.collaboration.create({
        data: {
          kind: 'STORE_OFFER',
          stage: 'FUNDED',
          commissionerId: owner,
          creatorId: OTHER,
          storeId: store.id,
          terms: {
            format: 'REELS',
            pieces: 1,
            voucherName: '식사권',
            voucherValue: 40000,
            voucherPeople: 2,
            fixedCash: 100000,
            viewRatePerThousand: null,
            perViewCap: null,
            usageRights: 'NONE',
          },
          settlementMethod: 'FIXED',
        },
      });
      const room = await prisma.conversation.create({
        data: {
          collaborationId: collaboration.id,
          status: 'OPEN',
          members: { create: [{ userId: owner }, { userId: OTHER }] },
        },
      });
      const asCreator = await detail(authCreator, room.id);
      expect(asCreator).toMatchObject({
        kind: 'STORE_OFFER',
        contextLabel: '한그릇 라멘',
        counterpart: { userId: owner, name: '한그릇 라멘' },
        storeTerms: { format: 'REELS', fixedCash: 100000 },
        terms: null,
        campaignTerms: null,
        canProposeTerms: false,
        canDrop: false,
      });
      const asOwner = await detail(authBrand, room.id);
      expect(asOwner.counterpart.name).toBe('하루 한 컵');
    });
  });

  describe('opening a room', () => {
    it('opens a closed room when the two sides are blocked', async () => {
      const { campaignId } = await seedParties();
      await prisma.block.create({
        data: { blockerId: USER_A, blockedId: OTHER },
      });
      const collaboration = await prisma.collaboration.create({
        data: {
          kind: 'BRAND_CONTRACT',
          stage: 'MATCHED',
          commissionerId: USER_A,
          creatorId: OTHER,
          campaignId,
          terms: {},
          settlementMethod: 'FIXED',
        },
      });
      const room = await prisma.$transaction((tx) =>
        app
          .get(ConversationsService)
          .openForCollaboration(collaboration.id, { status: 'OPEN' }, tx),
      );
      expect(room).toMatchObject({ status: 'CLOSED', closedReason: 'BLOCKED' });
      expect(await prisma.conversationMember.count()).toBe(2);
      await send(authBrand, room.id, text()).expect(409);
      expect((await detail(authBrand, room.id)).blockedByMe).toBe(true);
      expect((await detail(authCreator, room.id)).blockedByMe).toBe(false);
    });

    it('returns the existing room instead of creating a second one', async () => {
      const { campaignId } = await seedParties();
      const { collaborationId, roomId } = await seedRoom(campaignId);
      const room = await prisma.$transaction((tx) =>
        app
          .get(ConversationsService)
          .openForCollaboration(collaborationId, { status: 'OPEN' }, tx),
      );
      expect(room.id).toBe(roomId);
      expect(await prisma.conversation.count()).toBe(1);
    });

    it('adds the conversation id, contract status and extra revisions to the collaboration', async () => {
      const { campaignId } = await seedParties();
      const { collaborationId, roomId } = await seedRoom(campaignId, {
        stage: 'AGREED',
      });
      const get = async () =>
        (
          await request(server)
            .get(`/collaborations/${collaborationId}`)
            .set(authCreator)
            .expect(200)
        ).body as {
          conversationId: string | null;
          contractStatus: string;
          extraRevisionsAllowed: number;
        };
      expect(await get()).toMatchObject({
        conversationId: roomId,
        contractStatus: 'NONE',
        extraRevisionsAllowed: 0,
      });
      await prisma.contract.create({
        data: {
          collaborationId,
          status: 'AWAITING_BRAND',
          termsVersion: 1,
          termsSnapshot: {},
          creatorConsentedAt: T0,
          creatorConsentTexts: [],
          brandConsentTexts: [],
        },
      });
      expect((await get()).contractStatus).toBe('AWAITING_BRAND');
    });
  });
});
