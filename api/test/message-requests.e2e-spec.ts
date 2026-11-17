import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { IndustryCategory, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { PushPort } from '../src/integrations/push/push.port';
import { PresenceService } from '../src/realtime/presence.service';
import { RealtimePublisher } from '../src/realtime/realtime-publisher';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakePresence } from './support/fake-presence';
import { FakePushPort } from './support/fake-push.port';
import { FakeRealtimePublisher } from './support/fake-realtime-publisher';
import { OTHER, USER_A } from './support/fake-token-verifier';

// user-a는 브랜드, user-b는 크리에이터다.
const authBrand = { Authorization: 'Bearer user-a' };
const authCreator = { Authorization: 'Bearer user-b' };
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const CAMPAIGN = {
  headline: '나만의 아침 루틴 속 작은 포인트',
  fee: 300000,
  budget: 1000000,
  productProvided: true,
  format: 'REELS',
  startFrom: '2026-11-20',
  trialDays: 'D7',
  mustInclude: ['제품 로고가 보이게'],
  notRequired: ['FACE'],
};
const PRINCIPLES = {
  fields: ['ACCESSORY'],
  blockedIndustries: [] as string[],
  faceOk: true,
  scriptOk: true,
  honestReview: true,
  feeBand: 'W300K',
  trialDays: 'ANY',
};
const PROPOSAL = {
  fee: 450000,
  productProvided: false,
  performance: { ratePer1000: 2000, cap: 60000 },
};
const NOON = new Date('2026-11-11T03:00:00.000Z');

interface InquiryResult {
  collaborationId: string;
  conversationId: string;
}
interface DecisionResult {
  matched: boolean;
  collaborationId: string | null;
  conversationId: string | null;
}
interface Msg {
  seq: number;
  kind: string;
  mine: boolean;
  text: string | null;
}
interface Summary {
  id: string;
  status: string;
  section: string;
}
interface Detail extends Summary {
  stage: string;
  requestedByMe: boolean;
  canSend: boolean;
  canLikeCampaign: boolean;
}
interface ProposalBody {
  campaignId: string;
}

describe('message requests and the inquiry', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let push: FakePushPort;
  let realtime: FakeRealtimePublisher;
  let presence: FakePresence;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const setRole = (auth: Record<string, string>, role: string) =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const put = (auth: Record<string, string>, body: Record<string, unknown>) =>
    request(server).put('/discovery/decisions').set(auth).send(body);
  const brandLike = (extra: Record<string, unknown> = {}) =>
    put(authBrand, {
      targetKind: 'CREATOR',
      targetId: OTHER,
      decision: 'LIKE',
      ...extra,
    });
  const creatorLike = (campaignId: string, extra = {}) =>
    put(authCreator, {
      targetKind: 'CAMPAIGN',
      targetId: campaignId,
      decision: 'LIKE',
      ...extra,
    });
  const inquire = (
    campaignId: string,
    body: Record<string, unknown> = { message: '조건이 궁금해요.' },
    auth: Record<string, string> = authCreator,
  ) =>
    request(server)
      .post(`/discovery/received-proposals/${campaignId}/inquiry`)
      .set(auth)
      .send(body);
  const accept = (roomId: string, auth = authBrand) =>
    request(server).post(`/conversations/${roomId}/request/accept`).set(auth);
  const decline = (roomId: string, auth = authBrand) =>
    request(server).post(`/conversations/${roomId}/request/decline`).set(auth);
  const sendText = (roomId: string, auth: Record<string, string>) =>
    request(server)
      .post(`/conversations/${roomId}/messages`)
      .set(auth)
      .send({ clientId: randomUUID(), kind: 'TEXT', text: '안녕하세요' });
  const resultOf = (res: request.Response) => res.body as InquiryResult;
  const detail = async (auth: Record<string, string>, roomId: string) =>
    (
      await request(server)
        .get(`/conversations/${roomId}`)
        .set(auth)
        .expect(200)
    ).body as Detail;
  const messages = async (auth: Record<string, string>, roomId: string) =>
    (
      await request(server)
        .get(`/conversations/${roomId}/messages`)
        .set(auth)
        .expect(200)
    ).body as Msg[];
  const list = async (auth: Record<string, string>) =>
    (await request(server).get('/conversations').set(auth).expect(200))
      .body as Summary[];
  const received = async () =>
    (
      await request(server)
        .get('/discovery/received-proposals')
        .set(authCreator)
        .expect(200)
    ).body as ProposalBody[];

  async function makeBrand(industry: IndustryCategory = 'ACCESSORY') {
    await setRole(authBrand, 'BRAND');
    await request(server)
      .put('/brands/me')
      .set(authBrand)
      .send({ name: '느린결', tagline: '천천히 쓰는 물건', industry })
      .expect(200);
    const res = await request(server)
      .post('/campaigns')
      .set(authBrand)
      .send(CAMPAIGN)
      .expect(201);
    return (res.body as { id: string }).id;
  }

  async function makeCreator() {
    await setRole(authCreator, 'CREATOR');
    await request(server)
      .put('/creators/me')
      .set(authCreator)
      .send({ displayName: '하루 한 컵', ...REGION })
      .expect(200);
    await request(server)
      .put('/creators/me/principles')
      .set(authCreator)
      .send(PRINCIPLES)
      .expect(200);
  }

  // 브랜드가 글을 붙인 관심을 보낸 상태까지 만든다.
  async function seedNotedLike(extra: Record<string, unknown> = {}) {
    const campaignId = await makeBrand();
    await makeCreator();
    await brandLike({ note: '아침 사진이 좋았어요', ...extra }).expect(200);
    return campaignId;
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp([], { fakeRealtime: true });
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    push = app.get<FakePushPort>(PushPort);
    realtime = app.get<FakeRealtimePublisher>(RealtimePublisher);
    presence = app.get<FakePresence>(PresenceService);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(NOON);
    push.sent.length = 0;
    realtime.sent.length = 0;
    presence.online.clear();
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    const id = randomUUID();
    await request(server)
      .post(`/discovery/received-proposals/${id}/inquiry`)
      .send({})
      .expect(401);
    await request(server)
      .post(`/conversations/${id}/request/accept`)
      .expect(401);
    await request(server)
      .post(`/conversations/${id}/request/decline`)
      .expect(401);
  });

  describe('sending the inquiry', () => {
    it('sends an inquiry as a request with one first message', async () => {
      const campaignId = await seedNotedLike();
      const res = await inquire(campaignId, {
        message: '조건이 궁금해요.',
        contentLine: '출근길 한 컵',
      }).expect(201);
      const { collaborationId, conversationId } = resultOf(res);

      const collaboration = await prisma.collaboration.findUniqueOrThrow({
        where: { id: collaborationId },
      });
      expect(collaboration).toMatchObject({
        kind: 'BRAND_CONTRACT',
        stage: 'INQUIRY',
        commissionerId: USER_A,
        creatorId: OTHER,
        campaignId,
        settlementMethod: 'FIXED',
        creatorNote: '출근길 한 컵',
      });
      const room = await prisma.conversation.findUniqueOrThrow({
        where: { id: conversationId },
        include: { messages: true, members: true },
      });
      expect(room).toMatchObject({
        collaborationId,
        status: 'REQUESTED',
        requestedById: OTHER,
        lastSeq: 1,
      });
      expect(room.members.map((m) => m.userId).sort()).toEqual(
        [USER_A, OTHER].sort(),
      );
      expect(room.messages).toHaveLength(1);
      expect(room.messages[0]).toMatchObject({
        seq: 1,
        kind: 'TEXT',
        senderId: OTHER,
        text: '조건이 궁금해요.',
      });
      // 서로 관심이 아니라서 매칭 행도 조건 버전도 없다.
      expect(await prisma.match.count()).toBe(0);
      expect(await prisma.termsVersion.count()).toBe(0);
    });

    it('delivers the first message and the new room to both members without a chat message push', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      const forBrand = realtime.receivedBy(USER_A, 'message.created');
      const forCreator = realtime.receivedBy(OTHER, 'message.created');
      expect(forBrand).toHaveLength(1);
      expect(forBrand[0].payload).toMatchObject({
        conversationId,
        message: { seq: 1, mine: false, text: '조건이 궁금해요.' },
      });
      expect(forCreator[0].payload).toMatchObject({
        message: { seq: 1, mine: true },
      });
      for (const user of [USER_A, OTHER]) {
        expect(
          realtime
            .receivedBy(user, 'conversation.updated')
            .map((e) => e.payload),
        ).toEqual([{ conversationId, reason: 'STATUS' }]);
      }
      // 메시지 요청 알림 하나뿐이다. 일반 대화 메시지 푸시(제목이 보낸 사람 이름)는 가지 않는다.
      expect(push.sent.map((p) => [p.userId, p.title, p.body])).toEqual([
        [USER_A, '', '하루 한 컵님이 메시지를 보냈어요.'],
      ]);
    });

    it('lists the request first for the brand and as a plain row for the creator', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      expect(await list(authBrand)).toEqual([
        expect.objectContaining({
          id: conversationId,
          status: 'REQUESTED',
          section: 'REQUEST',
        }),
      ]);
      expect(await list(authCreator)).toEqual([
        expect.objectContaining({
          id: conversationId,
          status: 'REQUESTED',
          section: 'NORMAL',
        }),
      ]);
      expect(await detail(authCreator, conversationId)).toMatchObject({
        stage: 'INQUIRY',
        requestedByMe: true,
        canSend: false,
        canLikeCampaign: false,
      });
    });

    it('tells the brand with a message request notification', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      const page = (
        await request(server).get('/notifications').set(authBrand).expect(200)
      ).body as {
        items: {
          tab: string;
          text: string;
          target: { kind: string; id: string };
        }[];
      };
      expect(page.items).toEqual([
        expect.objectContaining({
          tab: 'MATCHING',
          text: '하루 한 컵님이 메시지를 보냈어요.',
          target: { kind: 'CONVERSATION', id: conversationId },
        }),
      ]);
      expect(push.sent.map((p) => [p.userId, p.body])).toEqual([
        [USER_A, '하루 한 컵님이 메시지를 보냈어요.'],
      ]);
    });

    it('still sends the inquiry when the notification cannot be saved', async () => {
      const campaignId = await seedNotedLike();
      push.fail = true;
      try {
        await inquire(campaignId).expect(201);
      } finally {
        push.fail = false;
      }
      expect(await prisma.conversation.count()).toBe(1);
    });

    it('accepts a brand proposal without a note as a reason to ask', async () => {
      const campaignId = await makeBrand();
      await makeCreator();
      await brandLike({ proposal: PROPOSAL }).expect(200);
      await inquire(campaignId).expect(201);
    });

    it('returns 404 for an inquiry without a noted like from the brand', async () => {
      const campaignId = await makeBrand();
      await makeCreator();
      // 관심이 아예 없다.
      expect((await inquire(campaignId).expect(404)).body).toBeDefined();
      // 글도 제안도 없는 관심은 받은 제안이 아니다.
      await brandLike().expect(200);
      expect(codeOf(await inquire(campaignId).expect(404))).toBe('NOT_FOUND');
      // 넘김과 보류는 제안이 아니다.
      await brandLike({ decision: 'HOLD', note: '글이 있어도' }).expect(200);
      await inquire(campaignId).expect(404);
      expect(await prisma.collaboration.count()).toBe(0);
      expect(await prisma.conversation.count()).toBe(0);
    });

    it('returns 404 when the campaign is unknown or closed or the creator already passed it', async () => {
      const campaignId = await seedNotedLike();
      await inquire(randomUUID()).expect(404);
      await put(authCreator, {
        targetKind: 'CAMPAIGN',
        targetId: campaignId,
        decision: 'PASS',
      }).expect(200);
      await inquire(campaignId).expect(404);
      expect(await prisma.collaboration.count()).toBe(0);
    });

    it('returns 404 and creates nothing when the two are blocked', async () => {
      const campaignId = await seedNotedLike();
      await prisma.block.create({
        data: { blockerId: USER_A, blockedId: OTHER },
      });
      expect(codeOf(await inquire(campaignId).expect(404))).toBe('NOT_FOUND');
      expect(await prisma.collaboration.count()).toBe(0);
      expect(await prisma.conversation.count()).toBe(0);
    });

    it('allows only creators and validates the message and the content line', async () => {
      const campaignId = await seedNotedLike();
      expect(
        codeOf(
          await inquire(campaignId, { message: '안녕' }, authBrand).expect(403),
        ),
      ).toBe('FORBIDDEN');
      await inquire(campaignId, {}).expect(400);
      await inquire(campaignId, { message: '' }).expect(400);
      await inquire(campaignId, { message: '   ' }).expect(400);
      await inquire(campaignId, { message: 'ㅁ'.repeat(1001) }).expect(400);
      await inquire(campaignId, {
        message: '안녕',
        contentLine: 'ㅁ'.repeat(41),
      }).expect(400);
      expect(await prisma.collaboration.count()).toBe(0);
      // 경계값은 된다.
      await inquire(campaignId, {
        message: 'ㅁ'.repeat(1000),
        contentLine: 'ㅁ'.repeat(40),
      }).expect(201);
    });

    it('refuses a second inquiry for the same campaign', async () => {
      const campaignId = await seedNotedLike();
      await inquire(campaignId).expect(201);
      expect(codeOf(await inquire(campaignId).expect(409))).toBe('CONFLICT');
      expect(await prisma.collaboration.count()).toBe(1);
      expect(await prisma.message.count()).toBe(1);
    });

    it('removes the campaign from the received proposals once it has an inquiry', async () => {
      const campaignId = await seedNotedLike();
      expect((await received()).map((p) => p.campaignId)).toEqual([campaignId]);
      await inquire(campaignId).expect(201);
      expect(await received()).toEqual([]);
    });

    it('removes a campaign that already has any collaboration from the received proposals', async () => {
      const campaignId = await seedNotedLike();
      await prisma.collaboration.create({
        data: {
          kind: 'BRAND_CONTRACT',
          stage: 'DROPPED',
          commissionerId: USER_A,
          creatorId: OTHER,
          campaignId,
          terms: {},
          settlementMethod: 'FIXED',
        },
      });
      expect(await received()).toEqual([]);
    });
  });

  describe('answering the request', () => {
    it('lets the requester send nothing more until the request is accepted', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      expect(
        codeOf(await sendText(conversationId, authCreator).expect(409)),
      ).toBe('CONFLICT');
      expect(
        codeOf(await sendText(conversationId, authBrand).expect(409)),
      ).toBe('CONFLICT');
      expect(await prisma.message.count()).toBe(1);
    });

    it('opens the conversation when the brand accepts and keeps INQUIRY', async () => {
      const campaignId = await seedNotedLike();
      const { collaborationId, conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      push.sent.length = 0;
      const res = await accept(conversationId).expect(200);
      expect(res.body).toMatchObject({
        id: conversationId,
        status: 'OPEN',
        stage: 'INQUIRY',
        canSend: true,
        section: 'NORMAL',
      });
      expect(
        (
          await prisma.collaboration.findUniqueOrThrow({
            where: { id: collaborationId },
          })
        ).stage,
      ).toBe('INQUIRY');

      // 안내 줄이 남고, 읽는 사람 모두에게 같은 사건이 보인다.
      const lines = await messages(authCreator, conversationId);
      expect(lines.map((m) => [m.seq, m.kind, m.text])).toEqual([
        [1, 'TEXT', '조건이 궁금해요.'],
        [2, 'SYSTEM', '느린결님이 대화를 수락했어요.'],
      ]);
      // 열린 방에서는 양쪽이 메시지를 보낼 수 있고, 크리에이터가 관심을 보낼 수 있다.
      await sendText(conversationId, authCreator).expect(201);
      await sendText(conversationId, authBrand).expect(201);
      expect(await detail(authCreator, conversationId)).toMatchObject({
        canLikeCampaign: true,
        requestedByMe: true,
      });
      expect(await detail(authBrand, conversationId)).toMatchObject({
        canLikeCampaign: false,
        requestedByMe: false,
      });
    });

    it('delivers the accepted line to both members after the commit and tells them the room changed', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      realtime.sent.length = 0;
      await accept(conversationId).expect(200);
      for (const user of [USER_A, OTHER]) {
        const lines = realtime.receivedBy(user, 'message.created');
        expect(lines).toHaveLength(1);
        expect(lines[0].payload).toMatchObject({
          conversationId,
          message: {
            seq: 2,
            kind: 'SYSTEM',
            mine: false,
            text: '느린결님이 대화를 수락했어요.',
          },
        });
        expect(
          realtime
            .receivedBy(user, 'conversation.updated')
            .map((e) => e.payload),
        ).toEqual([{ conversationId, reason: 'STATUS' }]);
      }
    });

    it('tells the requester that the request was accepted', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      push.sent.length = 0;
      await accept(conversationId).expect(200);
      const page = (
        await request(server).get('/notifications').set(authCreator).expect(200)
      ).body as {
        items: {
          tab: string;
          text: string;
          target: { kind: string; id: string };
        }[];
      };
      expect(page.items).toEqual([
        expect.objectContaining({
          tab: 'MATCHING',
          text: '느린결님이 대화를 수락했어요.',
          target: { kind: 'CONVERSATION', id: conversationId },
        }),
      ]);
      expect(push.sent.map((p) => p.userId)).toEqual([OTHER]);
    });

    it('lets only the receiver answer and only once', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      // 요청을 보낸 사람은 스스로 수락·거절할 수 없다.
      expect(
        codeOf(await accept(conversationId, authCreator).expect(403)),
      ).toBe('FORBIDDEN');
      expect(
        codeOf(await decline(conversationId, authCreator).expect(403)),
      ).toBe('FORBIDDEN');
      // 방에 없는 사람(남의 방)과 없는 방은 404다.
      const [brandX, creatorY] = [randomUUID(), randomUUID()];
      await prisma.user.createMany({
        data: [
          { id: brandX, role: 'BRAND' },
          { id: creatorY, role: 'CREATOR' },
        ],
      });
      const others = await prisma.collaboration.create({
        data: {
          kind: 'BRAND_CONTRACT',
          stage: 'INQUIRY',
          commissionerId: brandX,
          creatorId: creatorY,
          terms: {},
          settlementMethod: 'FIXED',
        },
      });
      const othersRoom = await prisma.conversation.create({
        data: {
          collaborationId: others.id,
          status: 'REQUESTED',
          requestedById: creatorY,
          members: {
            create: [{ userId: brandX }, { userId: creatorY }],
          },
        },
      });
      await accept(othersRoom.id).expect(404);
      await decline(othersRoom.id).expect(404);
      await accept(randomUUID()).expect(404);
      await accept('not-a-uuid').expect(404);
      await decline('not-a-uuid').expect(404);

      await accept(conversationId).expect(200);
      expect(codeOf(await accept(conversationId).expect(409))).toBe('CONFLICT');
      expect(codeOf(await decline(conversationId).expect(409))).toBe(
        'CONFLICT',
      );
      // 두 번째 수락은 안내 줄을 또 만들지 않는다.
      expect(await prisma.message.count({ where: { kind: 'SYSTEM' } })).toBe(1);
    });

    it('hides a declined request from the brand and shows DECLINED to the creator', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      push.sent.length = 0;
      const notificationsBefore = await prisma.notification.count();
      await decline(conversationId).expect(204);

      expect(await list(authBrand)).toEqual([]);
      expect(await list(authCreator)).toEqual([
        expect.objectContaining({ id: conversationId, status: 'DECLINED' }),
      ]);
      expect(await detail(authCreator, conversationId)).toMatchObject({
        status: 'DECLINED',
        canSend: false,
      });
      // 거절은 상대에게 알리지 않는다.
      expect(push.sent).toEqual([]);
      expect(await prisma.notification.count()).toBe(notificationsBefore);
      // 닫힌 방에는 보낼 수 없다.
      await sendText(conversationId, authCreator).expect(409);
    });

    it('does not tell the requester about a decline over realtime', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      realtime.sent.length = 0;
      await decline(conversationId).expect(204);
      expect(realtime.receivedBy(OTHER)).toEqual([]);
      // 거절한 사람의 다른 기기만 목록을 새로 읽는다.
      expect(
        realtime
          .receivedBy(USER_A, 'conversation.updated')
          .map((e) => e.payload),
      ).toEqual([{ conversationId, reason: 'STATUS' }]);
      expect(realtime.receivedBy(USER_A, 'message.created')).toEqual([]);
    });

    it('drops the inquiry collaboration on decline so it cannot be asked again', async () => {
      const campaignId = await seedNotedLike();
      const { collaborationId, conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      await decline(conversationId).expect(204);
      expect(
        await prisma.collaboration.findUniqueOrThrow({
          where: { id: collaborationId },
        }),
      ).toMatchObject({
        stage: 'DROPPED',
        dropReason: 'REQUEST_DECLINED',
        droppedById: USER_A,
      });
      expect(codeOf(await inquire(campaignId).expect(409))).toBe('CONFLICT');
      // 받은 제안에서도 사라지고, 관심을 보내도 다시 열리지 않는다.
      expect(await received()).toEqual([]);
      await creatorLike(campaignId).expect(409);
      expect(await prisma.match.count()).toBe(0);
    });
  });

  describe('a mutual like after the inquiry', () => {
    it('upgrades the same INQUIRY row to MATCHED with version 1 on a later mutual like', async () => {
      const campaignId = await seedNotedLike();
      const { collaborationId, conversationId } = resultOf(
        await inquire(campaignId, {
          message: '조건이 궁금해요.',
          contentLine: '출근길 한 컵',
        }).expect(201),
      );
      const res = (await creatorLike(campaignId).expect(200))
        .body as DecisionResult;
      expect(res).toEqual({
        decision: 'LIKE',
        matched: true,
        collaborationId,
        conversationId,
      });

      expect(await prisma.collaboration.count()).toBe(1);
      expect(await prisma.conversation.count()).toBe(1);
      expect(
        (
          await prisma.collaboration.findUniqueOrThrow({
            where: { id: collaborationId },
          })
        ).stage,
      ).toBe('MATCHED');
      // 요청 상태였던 방이 열리고, 첫 메시지 뒤에 안내 줄이 붙는다.
      const room = await prisma.conversation.findUniqueOrThrow({
        where: { id: conversationId },
      });
      expect(room.status).toBe('OPEN');
      expect(
        (await messages(authBrand, conversationId)).map((m) => [m.seq, m.kind]),
      ).toEqual([
        [1, 'TEXT'],
        [2, 'SYSTEM'],
      ]);
      const [version] = await prisma.termsVersion.findMany();
      expect(await prisma.termsVersion.count()).toBe(1);
      expect(version).toMatchObject({
        version: 1,
        // 크리에이터가 관심에 글을 붙이지 않았으니 문의에 적은 한 줄이 제목이다.
        title: '출근길 한 컵',
        fee: CAMPAIGN.fee,
        brandConfirmedAt: null,
        creatorConfirmedAt: null,
      });
    });

    it('prefers the note on the like over the content line for the title', async () => {
      const campaignId = await seedNotedLike();
      await inquire(campaignId, {
        message: '조건이 궁금해요.',
        contentLine: '출근길 한 컵',
      }).expect(201);
      await creatorLike(campaignId, { note: '아침 루틴 영상' }).expect(200);
      const [version] = await prisma.termsVersion.findMany();
      expect(version.title).toBe('아침 루틴 영상');
    });

    it('falls back to the campaign line when neither a note nor a content line exists', async () => {
      const campaignId = await seedNotedLike();
      await inquire(campaignId).expect(201);
      await creatorLike(campaignId).expect(200);
      const [version] = await prisma.termsVersion.findMany();
      expect(version.title).toBe(CAMPAIGN.headline);
    });

    it('uses the brand pre-made proposal for version 1 when an inquiry later becomes a match', async () => {
      const campaignId = await makeBrand();
      await makeCreator();
      await brandLike({
        note: '아침 사진이 좋았어요',
        proposal: PROPOSAL,
      }).expect(200);
      await inquire(campaignId).expect(201);
      await creatorLike(campaignId).expect(200);
      const [version] = await prisma.termsVersion.findMany();
      expect(version).toMatchObject({
        fee: 450000,
        productProvided: false,
        perfRatePerThousand: 2000,
        perfCap: 60000,
        brandConfirmedAt: null,
        creatorConfirmedAt: null,
      });
    });

    it('delivers the matched line to both members after the commit without a chat message push', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      realtime.sent.length = 0;
      push.sent.length = 0;
      await creatorLike(campaignId).expect(200);
      for (const user of [USER_A, OTHER]) {
        const lines = realtime.receivedBy(user, 'message.created');
        expect(lines).toHaveLength(1);
        expect(lines[0].payload).toMatchObject({
          conversationId,
          message: { seq: 2, kind: 'SYSTEM', mine: false },
        });
        expect(
          realtime
            .receivedBy(user, 'conversation.updated')
            .map((e) => e.payload),
        ).toEqual([{ conversationId, reason: 'STATUS' }]);
      }
      // 서로 관심 알림만 간다. 안내 줄의 대화 메시지 푸시는 없다.
      expect(push.sent.every((p) => p.title === '')).toBe(true);
    });

    it('opens the conversation the same way when the inquiry was already accepted', async () => {
      const campaignId = await seedNotedLike();
      const { conversationId } = resultOf(
        await inquire(campaignId).expect(201),
      );
      await accept(conversationId).expect(200);
      await creatorLike(campaignId).expect(200);
      expect(await detail(authCreator, conversationId)).toMatchObject({
        status: 'OPEN',
        stage: 'MATCHED',
        canLikeCampaign: false,
      });
      expect(
        (await messages(authCreator, conversationId)).map((m) => m.seq),
      ).toEqual([1, 2, 3]);
    });

    it('creates exactly one collaboration when an inquiry and a mutual like arrive at the same time', async () => {
      const campaignId = await seedNotedLike();
      const [a, b] = await Promise.all([
        inquire(campaignId),
        creatorLike(campaignId),
      ]);
      const statuses = [a.status, b.status].sort();
      // 문의가 먼저면 둘 다 성공하고(문의 → 승격), 관심이 먼저면 문의가 409다.
      expect([
        [200, 201],
        [200, 409],
      ]).toContainEqual(statuses);
      expect(await prisma.collaboration.count()).toBe(1);
      expect(await prisma.conversation.count()).toBe(1);
      expect(await prisma.match.count()).toBe(1);
      expect(await prisma.termsVersion.count()).toBe(1);
    });
  });
});
