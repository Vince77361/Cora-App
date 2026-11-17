import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { PushPort } from '../src/integrations/push/push.port';
import { RealtimePublisher } from '../src/realtime/realtime-publisher';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { flushMessages } from './helpers/flush-messages';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
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
const NOON = new Date('2026-11-11T03:00:00.000Z');
const minutes = (n: number) => new Date(NOON.getTime() + n * 60_000);

interface Line {
  kind: string;
  text: string | null;
}

describe('dropping a negotiation before the contract', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let push: FakePushPort;
  let realtime: FakeRealtimePublisher;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const messageOf = (res: request.Response) =>
    (res.body as { error: { message: string } }).error.message;
  const drop = (
    auth: Record<string, string>,
    id: string,
    body: Record<string, unknown> = { reason: 'BUDGET' },
  ) => request(server).post(`/collaborations/${id}/drop`).set(auth).send(body);
  const propose = (
    auth: Record<string, string>,
    id: string,
    body: Record<string, unknown>,
  ) => request(server).post(`/collaborations/${id}/terms`).set(auth).send(body);
  const confirm = (auth: Record<string, string>, id: string, version: number) =>
    request(server)
      .post(`/collaborations/${id}/terms/${version}/confirm`)
      .set(auth);
  const collaborationOf = (id: string) =>
    prisma.collaboration.findUniqueOrThrow({ where: { id } });
  const roomIdOf = async (collaborationId: string) =>
    (
      await prisma.conversation.findUniqueOrThrow({
        where: { collaborationId },
      })
    ).id;
  const linesOf = async (
    auth: Record<string, string>,
    collaborationId: string,
  ) =>
    (
      (
        await request(server)
          .get(`/conversations/${await roomIdOf(collaborationId)}/messages`)
          .set(auth)
          .expect(200)
      ).body as Line[]
    )
      .filter((m) => m.kind === 'SYSTEM')
      .map((m) => m.text ?? '');

  async function makeBoth(): Promise<string> {
    await request(server)
      .patch('/me/role')
      .set(authBrand)
      .send({ role: 'BRAND' })
      .expect(200);
    await request(server)
      .put('/brands/me')
      .set(authBrand)
      .send({
        name: '느린결',
        tagline: '천천히 쓰는 물건',
        industry: 'ACCESSORY',
      })
      .expect(200);
    const created = await request(server)
      .post('/campaigns')
      .set(authBrand)
      .send(CAMPAIGN)
      .expect(201);
    await request(server)
      .patch('/me/role')
      .set(authCreator)
      .send({ role: 'CREATOR' })
      .expect(200);
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
    return (created.body as { id: string }).id;
  }

  // 서로 관심을 만들어 협업 id를 돌려준다(MATCHED, 방 열림, 판본 1).
  async function matchUp(): Promise<string> {
    const campaignId = await makeBoth();
    await request(server)
      .put('/discovery/decisions')
      .set(authCreator)
      .send({
        targetKind: 'CAMPAIGN',
        targetId: campaignId,
        decision: 'LIKE',
        note: '아침 한 컵',
      })
      .expect(200);
    const res = await request(server)
      .put('/discovery/decisions')
      .set(authBrand)
      .send({ targetKind: 'CREATOR', targetId: OTHER, decision: 'LIKE' })
      .expect(200);
    return (res.body as { collaborationId: string }).collaborationId;
  }

  const insertContract = (collaborationId: string) =>
    prisma.contract.create({
      data: {
        collaborationId,
        status: 'AWAITING_BRAND',
        termsVersion: 1,
        termsSnapshot: {},
        creatorConsentedAt: NOON,
        creatorConsentTexts: ['a', 'b', 'c'],
        brandConsentTexts: [],
      },
    });
  const insertPayment = (
    collaborationId: string,
    status: 'PENDING' | 'APPROVED',
    requestedAt: Date,
  ) =>
    prisma.payment.create({
      data: {
        collaborationId,
        amountEscrow: 300000,
        amountFee: 30000,
        feeRate: 10,
        method: 'CARD',
        status,
        requestedAt,
      },
    });

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp([], { fakeRealtime: true });
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    push = app.get<FakePushPort>(PushPort);
    realtime = app.get<FakeRealtimePublisher>(RealtimePublisher);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(NOON);
    push.sent.length = 0;
    realtime.sent.length = 0;
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server)
      .post(`/collaborations/${randomUUID()}/drop`)
      .send({ reason: 'BUDGET' })
      .expect(401);
  });

  it('drops before the contract and tells the other side only that it will not continue', async () => {
    const id = await matchUp();
    const res = await drop(authCreator, id, { reason: 'BUDGET' }).expect(200);
    expect(res.body).toMatchObject({ id, stage: 'DROPPED' });
    expect(await collaborationOf(id)).toMatchObject({
      stage: 'DROPPED',
      dropReason: 'BUDGET',
      droppedById: OTHER,
    });
    await flushMessages(app);

    // 그만둔 본인은 본인 문구, 상대는 이유도 이름도 없는 한 줄만 본다.
    expect((await linesOf(authCreator, id)).pop()).toBe('협의를 그만뒀어요.');
    expect((await linesOf(authBrand, id)).pop()).toBe(
      '이번에는 함께하기 어렵대요.',
    );
    const seenByBrand = JSON.stringify([
      await linesOf(authBrand, id),
      (
        await request(server)
          .get(`/collaborations/${id}`)
          .set(authBrand)
          .expect(200)
      ).body,
      (
        await request(server)
          .get(`/conversations/${await roomIdOf(id)}`)
          .set(authBrand)
          .expect(200)
      ).body,
    ]);
    expect(seenByBrand).not.toContain('BUDGET');
    expect(seenByBrand).not.toContain('예산');
    expect(seenByBrand).not.toContain('droppedById');
  });

  it('notifies the other side once with the plain sentence and cannot be switched off', async () => {
    const id = await matchUp();
    push.sent.length = 0;
    await drop(authBrand, id, { reason: 'DIRECTION' }).expect(200);
    await flushMessages(app);
    const got = (
      (await request(server).get('/notifications').set(authCreator).expect(200))
        .body as {
        items: {
          text: string;
          tab: string;
          target: { kind: string; id: string };
        }[];
      }
    ).items.filter((i) => i.text === '이번에는 함께하기 어렵대요.');
    expect(got).toHaveLength(1);
    expect(got[0]).toMatchObject({
      tab: 'COLLABORATION',
      target: { kind: 'CONVERSATION', id: await roomIdOf(id) },
    });
    // 그만둔 쪽에는 알리지 않고, 안내 줄의 대화 메시지 푸시는 따로 나가지 않는다.
    expect(push.sent.map((p) => p.userId)).toEqual([OTHER]);
    const brandGot = (
      (await request(server).get('/notifications').set(authBrand).expect(200))
        .body as { items: { text: string }[] }
    ).items.filter((i) => i.text.includes('함께하기'));
    expect(brandGot).toHaveLength(0);
  });

  it('keeps the room open and pushes the line and a status update to both', async () => {
    const id = await matchUp();
    realtime.sent.length = 0;
    await drop(authCreator, id).expect(200);
    await flushMessages(app);
    const room = await prisma.conversation.findUniqueOrThrow({
      where: { collaborationId: id },
    });
    expect(room.status).toBe('OPEN');
    for (const userId of [USER_A, OTHER]) {
      expect(realtime.receivedBy(userId, 'message.created')).toHaveLength(1);
      const updates = realtime
        .receivedBy(userId, 'conversation.updated')
        .map((e) => (e.payload as { reason: string }).reason);
      expect(updates).toEqual(['STATUS']);
    }
    // 방은 열려 있어 글을 계속 보낼 수 있다.
    await request(server)
      .post(`/conversations/${room.id}/messages`)
      .set(authBrand)
      .send({ clientId: randomUUID(), kind: 'TEXT', text: '아쉽네요' })
      .expect(201);
  });

  it.each(['MATCHED', 'NEGOTIATING', 'AGREED'] as const)(
    'drops from %s and voids a live contract',
    async (stage) => {
      const id = await matchUp();
      if (stage === 'NEGOTIATING') {
        await confirm(authBrand, id, 1).expect(200);
      }
      if (stage === 'AGREED') {
        await confirm(authBrand, id, 1).expect(200);
        await confirm(authCreator, id, 1).expect(200);
      }
      expect(await collaborationOf(id)).toMatchObject({ stage });
      const contract = await insertContract(id);
      await drop(authBrand, id, { reason: 'SCHEDULE' }).expect(200);
      expect(await collaborationOf(id)).toMatchObject({ stage: 'DROPPED' });
      expect(
        await prisma.contract.findUniqueOrThrow({ where: { id: contract.id } }),
      ).toMatchObject({ status: 'VOIDED', voidReason: 'DROPPED' });
    },
  );

  it('refuses a second drop and a drop after the contract was concluded', async () => {
    const id = await matchUp();
    await drop(authBrand, id).expect(200);
    const again = await drop(authCreator, id).expect(409);
    expect(codeOf(again)).toBe('CONFLICT');
    // 이미 끝난 협의의 이유는 처음 값 그대로다.
    expect(await collaborationOf(id)).toMatchObject({
      dropReason: 'BUDGET',
      droppedById: USER_A,
    });

    const second = await prisma.collaboration.create({
      data: {
        kind: 'BRAND_CONTRACT',
        stage: 'CONTRACTED',
        commissionerId: USER_A,
        creatorId: OTHER,
        settlementMethod: 'NONE',
        terms: {},
      },
    });
    await drop(authBrand, second.id).expect(409);
    expect(await collaborationOf(second.id)).toMatchObject({
      stage: 'CONTRACTED',
    });
  });

  it('refuses while the brand payment is pending and allows it after the lock has passed', async () => {
    const id = await matchUp();
    await confirm(authBrand, id, 1).expect(200);
    await confirm(authCreator, id, 1).expect(200);
    await insertPayment(id, 'PENDING', NOON);
    clock.set(minutes(59));
    const res = await drop(authCreator, id).expect(409);
    expect(messageOf(res)).toBe(
      '브랜드가 결제를 진행하고 있어요. 잠시 뒤 다시 시도해 주세요.',
    );
    expect(await collaborationOf(id)).toMatchObject({ stage: 'AGREED' });
    clock.set(minutes(61));
    await drop(authCreator, id).expect(200);
    expect(await collaborationOf(id)).toMatchObject({ stage: 'DROPPED' });
  });

  it('is only for the parties and takes only the four reasons', async () => {
    const id = await matchUp();
    await drop(authBrand, randomUUID()).expect(404);
    await drop(authBrand, 'not-a-uuid').expect(404);
    for (const body of [
      {},
      { reason: 'REQUEST_DECLINED' },
      { reason: 'BLOCKED' },
      { reason: 'nope' },
    ]) {
      await drop(authBrand, id, body).expect(400);
    }
    expect(await collaborationOf(id)).toMatchObject({ stage: 'MATCHED' });
  });

  it('refuses a store offer collaboration', async () => {
    await makeBoth();
    const offerCollab = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: 'AWAITING_PAYMENT',
        commissionerId: USER_A,
        creatorId: OTHER,
        settlementMethod: 'NONE',
        terms: {},
      },
    });
    await drop(authBrand, offerCollab.id).expect(409);
  });

  it('stays consistent when a drop and a proposal cross', async () => {
    const id = await matchUp();
    const [d, p] = await Promise.all([
      drop(authBrand, id),
      propose(authCreator, id, { baseVersion: 1, title: '아침 한 컵 2' }),
    ]);
    // 협의는 어느 순서로든 끝난다. 그만두기가 먼저면 제안은 단계가 맞지 않아 409이고 새 판본이 없다.
    expect(d.status).toBe(200);
    expect(await collaborationOf(id)).toMatchObject({ stage: 'DROPPED' });
    expect([201, 409]).toContain(p.status);
    expect(await prisma.termsVersion.count()).toBe(p.status === 201 ? 2 : 1);
  });
  describe('a collaboration that is still a message request or an inquiry', () => {
    // 브랜드가 글을 붙인 관심을 보내고 크리에이터가 조건부터 질문한 상태: 협업 INQUIRY, 방 REQUESTED.
    async function seedRequest(): Promise<{
      collaborationId: string;
      roomId: string;
    }> {
      const campaignId = await makeBoth();
      await request(server)
        .put('/discovery/decisions')
        .set(authBrand)
        .send({
          targetKind: 'CREATOR',
          targetId: OTHER,
          decision: 'LIKE',
          note: '아침 사진이 좋았어요',
        })
        .expect(200);
      await request(server)
        .post(`/discovery/received-proposals/${campaignId}/inquiry`)
        .set(authCreator)
        .send({ message: '조건이 궁금해요.' })
        .expect(201);
      const room = await prisma.conversation.findFirstOrThrow();
      return { collaborationId: room.collaborationId, roomId: room.id };
    }
    const accept = (auth: Record<string, string>, roomId: string) =>
      request(server).post(`/conversations/${roomId}/request/accept`).set(auth);
    const decline = (auth: Record<string, string>, roomId: string) =>
      request(server)
        .post(`/conversations/${roomId}/request/decline`)
        .set(auth);
    const systemLineCount = (roomId: string) =>
      prisma.message.count({
        where: { conversationId: roomId, kind: 'SYSTEM' },
      });
    const dropNotices = (userId: string) =>
      prisma.notification.count({
        where: { userId, kind: 'COLLABORATION_DROPPED' },
      });

    it('closes a pending message request when the requester drops it', async () => {
      const { collaborationId, roomId } = await seedRequest();
      expect(await collaborationOf(collaborationId)).toMatchObject({
        stage: 'INQUIRY',
      });
      push.sent.length = 0;
      realtime.sent.length = 0;

      await drop(authCreator, collaborationId).expect(200);
      await flushMessages(app);

      // 거둔 요청: 협업은 끝나고 방은 거절한 것과 같은 DECLINED이다.
      expect(await collaborationOf(collaborationId)).toMatchObject({
        stage: 'DROPPED',
        droppedById: OTHER,
      });
      expect(
        (await prisma.conversation.findUniqueOrThrow({ where: { id: roomId } }))
          .status,
      ).toBe('DECLINED');
      // 받은 사람에게는 안내 줄도 알림도 푸시도 없다.
      expect(await systemLineCount(roomId)).toBe(0);
      expect(await dropNotices(USER_A)).toBe(0);
      expect(push.sent).toHaveLength(0);
      expect(realtime.receivedBy(USER_A, 'message.created')).toHaveLength(0);
      // 받은 사람의 목록에서 요청이 사라지도록 방의 변경만 양쪽 화면에 알린다.
      for (const userId of [USER_A, OTHER]) {
        expect(
          realtime
            .receivedBy(userId, 'conversation.updated')
            .map((e) => (e.payload as { reason: string }).reason),
        ).toEqual(['STATUS']);
      }
      const brandList = (
        (await request(server).get('/conversations').set(authBrand).expect(200))
          .body as { id: string; section: string }[]
      ).filter((room) => room.section === 'REQUEST');
      expect(brandList).toHaveLength(0);

      // 받은 사람의 수락과 거절은 이미 답한 요청의 409로 끝나고 아무것도 바뀌지 않는다.
      for (const answer of [accept, decline]) {
        const res = await answer(authBrand, roomId).expect(409);
        expect(codeOf(res)).toBe('CONFLICT');
        expect(messageOf(res)).toBe('이미 답한 메시지 요청이에요.');
      }
      expect(await collaborationOf(collaborationId)).toMatchObject({
        stage: 'DROPPED',
      });
      expect(
        (await prisma.conversation.findUniqueOrThrow({ where: { id: roomId } }))
          .status,
      ).toBe('DECLINED');
    });

    it('also closes a pending request when the receiver drops it, without telling the requester', async () => {
      const { collaborationId, roomId } = await seedRequest();
      push.sent.length = 0;
      await drop(authBrand, collaborationId, { reason: 'DIRECTION' }).expect(
        200,
      );
      await flushMessages(app);
      expect(
        (await prisma.conversation.findUniqueOrThrow({ where: { id: roomId } }))
          .status,
      ).toBe('DECLINED');
      expect(await systemLineCount(roomId)).toBe(0);
      expect(await dropNotices(OTHER)).toBe(0);
      expect(push.sent).toHaveLength(0);
      expect(codeOf(await accept(authBrand, roomId).expect(409))).toBe(
        'CONFLICT',
      );
    });

    it('drops from INQUIRY with an open room like any other negotiation', async () => {
      const { collaborationId, roomId } = await seedRequest();
      await accept(authBrand, roomId).expect(200);
      expect(await collaborationOf(collaborationId)).toMatchObject({
        stage: 'INQUIRY',
      });
      push.sent.length = 0;

      await drop(authCreator, collaborationId, { reason: 'SCHEDULE' }).expect(
        200,
      );
      await flushMessages(app);

      expect(await collaborationOf(collaborationId)).toMatchObject({
        stage: 'DROPPED',
        dropReason: 'SCHEDULE',
      });
      expect(
        (await prisma.conversation.findUniqueOrThrow({ where: { id: roomId } }))
          .status,
      ).toBe('OPEN');
      expect((await linesOf(authBrand, collaborationId)).pop()).toBe(
        '이번에는 함께하기 어렵대요.',
      );
      expect((await linesOf(authCreator, collaborationId)).pop()).toBe(
        '협의를 그만뒀어요.',
      );
      expect(await dropNotices(USER_A)).toBe(1);
      expect(await dropNotices(OTHER)).toBe(0);
    });
  });
});
