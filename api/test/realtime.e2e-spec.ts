import { randomUUID } from 'node:crypto';
import type { AddressInfo } from 'node:net';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { io, Socket } from 'socket.io-client';
import { Clock } from '../src/common/clock';
import { PushPort } from '../src/integrations/push/push.port';
import { RedisIoAdapter } from '../src/realtime/redis-io.adapter';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakePushPort } from './support/fake-push.port';
import { OTHER, STRANGER, USER_A } from './support/fake-token-verifier';

const brand = { Authorization: 'Bearer user-a' };
const creator = { Authorization: 'Bearer user-b' };
const T0 = new Date('2026-12-01T00:00:00.000Z');
const REDIS_URL = process.env.REDIS_URL ?? 'redis://127.0.0.1:6379';

interface Received {
  event: string;
  payload: {
    conversationId: string;
    message?: { id: string; seq: number; mine: boolean; text: string | null };
    reason?: string;
  };
}

// 소켓 하나와, 그 소켓이 받은 서버 이벤트(session.expired 포함)를 쌓아 두는 도우미.
interface Client {
  socket: Socket;
  received: Received[];
}

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// 조건이 참이 될 때까지 기다린다(실제 소켓이라 도착 시각을 모른다).
async function until(check: () => boolean, ms = 3000): Promise<void> {
  const end = Date.now() + ms;
  while (!check()) {
    if (Date.now() > end) throw new Error('기다리던 일이 일어나지 않았어요.');
    await wait(10);
  }
}

describe('realtime gateway', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let url: string;
  let clock: FakeClock;
  let push: FakePushPort;
  const clients: Client[] = [];

  const urlOf = (target: INestApplication) =>
    `http://127.0.0.1:${(httpOf(target).address() as AddressInfo).port}/realtime`;

  // 서버에 붙고 연결이 확정될 때(connect)나 끊길 때(disconnect)까지 기다린다.
  async function connect(
    token: string | undefined,
    target = url,
  ): Promise<Client> {
    const socket = io(target, {
      auth: token === undefined ? {} : { token },
      transports: ['websocket'],
      reconnection: false,
      forceNew: true,
    });
    const client: Client = { socket, received: [] };
    socket.onAny((event: string, payload: Received['payload']) => {
      client.received.push({ event, payload });
    });
    clients.push(client);
    await new Promise<void>((resolve, reject) => {
      socket.once('connect', () => resolve());
      socket.once('connect_error', (error) => reject(error));
    });
    return client;
  }

  const eventsOf = (client: Client, event: string) =>
    client.received.filter((r) => r.event === event);

  // 브랜드(user-a)와 크리에이터(user-b) 사이의 협업과 열린 방.
  async function seedRoom(
    status: 'OPEN' | 'REQUESTED' = 'OPEN',
  ): Promise<string> {
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
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'BRAND_CONTRACT',
        stage: 'NEGOTIATING',
        commissionerId: USER_A,
        creatorId: OTHER,
        campaignId: campaign.id,
        terms: {},
        settlementMethod: 'FIXED',
      },
    });
    const room = await prisma.conversation.create({
      data: {
        collaborationId: collaboration.id,
        status,
        requestedById: status === 'REQUESTED' ? OTHER : null,
        members: { create: [{ userId: USER_A }, { userId: OTHER }] },
      },
    });
    return room.id;
  }

  const send = (
    target: INestApplication,
    auth: Record<string, string>,
    roomId: string,
    text: string,
  ) =>
    request(httpOf(target))
      .post(`/conversations/${roomId}/messages`)
      .set(auth)
      .send({ clientId: randomUUID(), kind: 'TEXT', text });

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    await app.listen(0);
    url = urlOf(app);
    clock = app.get<FakeClock>(Clock);
    push = app.get<FakePushPort>(PushPort);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(T0);
    push.sent.length = 0;
  });
  afterEach(() => {
    // 소켓을 닫지 않으면 jest가 끝나지 않는다.
    for (const client of clients.splice(0)) client.socket.close();
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  describe('connecting', () => {
    it('disconnects a client with a bad token or no token', async () => {
      for (const token of ['nobody', undefined]) {
        const client = await connect(token);
        await until(() => client.socket.disconnected);
        expect(eventsOf(client, 'message.created')).toHaveLength(0);
      }
    });

    it('keeps a client with a valid token connected', async () => {
      const client = await connect('user-a');
      await wait(100);
      expect(client.socket.connected).toBe(true);
    });

    it('sends session.expired and disconnects when the token expires', async () => {
      const client = await connect('expiring:user-a');
      expect(client.socket.connected).toBe(true);
      await until(() => client.socket.disconnected);
      expect(eventsOf(client, 'session.expired')).toHaveLength(1);
    });

    it('does not run any event a client sends', async () => {
      const roomId = await seedRoom();
      const client = await connect('user-a');
      client.socket.emit('message.created', { conversationId: roomId });
      client.socket.emit('join', 'user:' + OTHER);
      client.socket.emit('conversation.updated', {});
      const other = await connect('user-b');
      await send(app, brand, roomId, '안녕하세요').expect(201);
      await until(() => eventsOf(other, 'message.created').length === 1);
      // 클라이언트가 보낸 이벤트로 다른 사람의 방에 들어가거나 이벤트가 만들어지지 않는다.
      expect(eventsOf(other, 'message.created')).toHaveLength(1);
      expect(eventsOf(other, 'conversation.updated')).toHaveLength(0);
      expect(client.socket.connected).toBe(true);
    });
  });

  describe('delivery', () => {
    it('pushes a new message to both members and to nobody else', async () => {
      const roomId = await seedRoom();
      const a = await connect('user-a');
      const b = await connect('user-b');
      const stranger = await connect('user-c');

      const sent = await send(app, creator, roomId, '안녕하세요').expect(201);
      await until(
        () =>
          eventsOf(a, 'message.created').length === 1 &&
          eventsOf(b, 'message.created').length === 1,
      );

      const forBrand = eventsOf(a, 'message.created')[0].payload;
      const forCreator = eventsOf(b, 'message.created')[0].payload;
      expect(forBrand.conversationId).toBe(roomId);
      expect(forBrand.message).toMatchObject({
        id: (sent.body as { id: string }).id,
        seq: 1,
        mine: false,
        text: '안녕하세요',
      });
      // 같은 메시지가 보낸 사람에게는 mine: true로 간다.
      expect(forCreator.message).toMatchObject({ seq: 1, mine: true });
      // 방에 없는 사람의 소켓은 아무것도 받지 않는다.
      await wait(150);
      expect(stranger.received).toHaveLength(0);
      expect(STRANGER).not.toBe(USER_A);
    });

    it('does not let a stranger hear another conversation', async () => {
      const roomId = await seedRoom();
      const stranger = await connect('user-c');
      await send(app, brand, roomId, '둘만의 이야기').expect(201);
      await send(app, creator, roomId, '네, 알겠어요').expect(201);
      await wait(200);
      expect(stranger.received).toHaveLength(0);
    });

    it('tells the reader about a read and only the reader', async () => {
      const roomId = await seedRoom();
      await send(app, creator, roomId, '안녕하세요').expect(201);
      const a = await connect('user-a');
      const b = await connect('user-b');
      await request(httpOf(app))
        .post(`/conversations/${roomId}/read`)
        .set(brand)
        .send({ seq: 1 })
        .expect(204);
      await until(() => eventsOf(a, 'conversation.updated').length === 1);
      expect(eventsOf(a, 'conversation.updated')[0].payload).toEqual({
        conversationId: roomId,
        reason: 'READ',
      });
      await wait(100);
      expect(eventsOf(b, 'conversation.updated')).toHaveLength(0);
    });
  });

  describe('push', () => {
    it('sends a push with a 60 character preview when the receiver is offline', async () => {
      const roomId = await seedRoom();
      await send(app, creator, roomId, '가'.repeat(70)).expect(201);
      expect(push.sent).toHaveLength(1);
      expect(push.sent[0]).toMatchObject({
        userId: USER_A,
        title: '하루 한 컵',
        body: `${'가'.repeat(60)}…`,
        data: {
          notificationId: null,
          targetKind: 'CONVERSATION',
          targetId: roomId,
          role: 'BRAND',
        },
      });
    });

    it('pushes the content card line for a card and never pushes the sender', async () => {
      const roomId = await seedRoom();
      await request(httpOf(app))
        .post(`/conversations/${roomId}/messages`)
        .set(creator)
        .send({ clientId: randomUUID(), kind: 'CONTENT_CARD' })
        .expect(201);
      expect(push.sent).toHaveLength(1);
      expect(push.sent[0]).toMatchObject({
        userId: USER_A,
        body: '콘텐츠 카드를 보냈어요.',
      });
    });

    it('does not push when the receiver is connected', async () => {
      const roomId = await seedRoom();
      const a = await connect('user-a');
      await send(app, creator, roomId, '안녕하세요').expect(201);
      await until(() => eventsOf(a, 'message.created').length === 1);
      expect(push.sent).toHaveLength(0);
    });

    it('pushes again after the receiver disconnects', async () => {
      const roomId = await seedRoom();
      const a = await connect('user-a');
      a.socket.close();
      // 서버가 연결 끊김을 알 때까지 기다린 뒤 보낸다.
      await wait(100);
      await send(app, creator, roomId, '안녕하세요').expect(201);
      expect(push.sent).toHaveLength(1);
    });

    it('does not push a muted conversation', async () => {
      const roomId = await seedRoom();
      await request(httpOf(app))
        .put(`/conversations/${roomId}/mute`)
        .set(brand)
        .send({ muted: true })
        .expect(200);
      await send(app, creator, roomId, '안녕하세요').expect(201);
      expect(push.sent).toHaveLength(0);
      // 알림을 켜면 다시 간다.
      await request(httpOf(app))
        .put(`/conversations/${roomId}/mute`)
        .set(brand)
        .send({ muted: false })
        .expect(200);
      await send(app, creator, roomId, '다시 한번').expect(201);
      expect(push.sent).toHaveLength(1);
    });

    it('does not push when the chat message switch is off, and keeps it out of the inbox', async () => {
      const roomId = await seedRoom();
      await request(httpOf(app))
        .put('/me/notification-settings')
        .set(brand)
        .send({
          mutualInterest: true,
          offers: true,
          messages: false,
          settlement: true,
          recommendations: false,
          quietHours: 'NIGHT',
        })
        .expect(200);
      await send(app, creator, roomId, '안녕하세요').expect(201);
      expect(push.sent).toHaveLength(0);
      const inbox = await request(httpOf(app))
        .get('/notifications')
        .set(brand)
        .expect(200);
      expect((inbox.body as { items: unknown[] }).items).toHaveLength(0);
    });

    it('does not keep a pushed message in the inbox', async () => {
      const roomId = await seedRoom();
      await send(app, creator, roomId, '안녕하세요').expect(201);
      expect(push.sent).toHaveLength(1);
      const inbox = await request(httpOf(app))
        .get('/notifications')
        .set(brand)
        .expect(200);
      expect((inbox.body as { items: unknown[] }).items).toHaveLength(0);
    });
  });

  describe('two server instances behind the redis adapter', () => {
    const prefix = `cora-test-realtime-${randomUUID()}`;
    let first: INestApplication;
    let second: INestApplication;
    const adapters: RedisIoAdapter[] = [];

    // 테스트 전용 key 접두어로 같은 Redis를 쓰는 개발 서버와 채널이 섞이지 않게 한다.
    const withRedis = async (target: INestApplication) => {
      const adapter = new RedisIoAdapter(target, REDIS_URL, prefix);
      await adapter.connectToRedis();
      adapters.push(adapter);
      return adapter;
    };

    beforeAll(async () => {
      first = await createTestApp([], { webSocketAdapter: withRedis });
      second = await createTestApp([], { webSocketAdapter: withRedis });
      await first.listen(0);
      await second.listen(0);
    });
    afterAll(async () => {
      await first.close();
      await second.close();
    });

    it('delivers through the redis adapter between two server instances', async () => {
      const roomId = await seedRoom();
      // 받는 사람은 둘째 서버에, 보내는 요청은 첫째 서버에 간다.
      const onSecond = await connect('user-a', urlOf(second));
      const stranger = await connect('user-c', urlOf(second));
      await send(first, creator, roomId, '다른 서버로 가요').expect(201);
      await until(() => eventsOf(onSecond, 'message.created').length === 1);
      expect(
        eventsOf(onSecond, 'message.created')[0].payload.message,
      ).toMatchObject({ mine: false, text: '다른 서버로 가요' });
      await wait(150);
      expect(stranger.received).toHaveLength(0);
      // 다른 서버에 연결돼 있는 사람은 온라인이라 푸시가 가지 않는다.
      expect(first.get<FakePushPort>(PushPort).sent).toHaveLength(0);
    });

    it('does not reach a server that is not on the same redis channel', async () => {
      const roomId = await seedRoom();
      const lonely = await connect('user-a');
      await send(first, creator, roomId, '이 서버끼리만').expect(201);
      await wait(200);
      // 어댑터 없이 도는 서버(위의 첫 번째 app)의 소켓에는 가지 않는다.
      expect(lonely.received).toHaveLength(0);
    });
  });
});
