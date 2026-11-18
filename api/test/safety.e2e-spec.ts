import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import {
  CollaborationStage,
  ConversationStatus,
  PrismaClient,
} from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { OperatorAlertPort } from '../src/integrations/operator-alert/operator-alert.port';
import { PushPort } from '../src/integrations/push/push.port';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { OpsRunner } from '../src/ops/ops.runner';
import { RealtimePublisher } from '../src/realtime/realtime-publisher';
import { brandHaltJobKey, settleJobKey } from '../src/settlements/job-keys';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { createOffer } from './helpers/create-offer';
import { flushMessages } from './helpers/flush-messages';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { FakeRealtimePublisher } from './support/fake-realtime-publisher';
import { OTHER, USER_A } from './support/fake-token-verifier';

const authA = { Authorization: 'Bearer user-a' };
const authB = { Authorization: 'Bearer user-b' };
const T0 = new Date('2026-12-01T03:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const HELD_MESSAGE = '진행 중인 협업이 있어요. 문의하기로 알려 주세요.';

jest.setTimeout(60000);

interface Seeded {
  collaborationId: string;
  roomId: string;
}

// user-a(맡기는 쪽)와 user-b(크리에이터) 사이의 협업·방·계약을 DB에 바로 만들어 차단과 신고를 확인한다.
describe('safety (block and report)', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let scheduler: FakeJobScheduler;
  let realtime: FakeRealtimePublisher;
  let push: FakePushPort;
  let alert: jest.SpyInstance;

  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const messageOf = (res: request.Response) =>
    (res.body as { error: { message: string } }).error.message;
  const block = (roomId: string, auth = authA) =>
    request(server).post(`/conversations/${roomId}/block`).set(auth);
  const report = (body: Record<string, unknown>, auth = authA) =>
    request(server)
      .post('/reports')
      .set(auth)
      .send({ reason: 'SPAM', ...body });
  const sendText = (roomId: string, auth: Record<string, string>) =>
    request(server)
      .post(`/conversations/${roomId}/messages`)
      .set(auth)
      .send({ clientId: randomUUID(), kind: 'TEXT', text: '안녕하세요' });
  const detail = async (roomId: string, auth: Record<string, string>) =>
    (
      await request(server)
        .get(`/conversations/${roomId}`)
        .set(auth)
        .expect(200)
    ).body as { status: string; blockedByMe: boolean; canSend: boolean };
  const alertOf = (index: number) =>
    (alert.mock.calls as [{ subject: string; body: string }][])[index][0];
  const collaborationOf = (id: string) =>
    prisma.collaboration.findUniqueOrThrow({ where: { id } });
  const roomOf = (id: string) =>
    prisma.conversation.findUniqueOrThrow({ where: { id } });

  // 브랜드(user-a)와 크리에이터(user-b). 가게 시나리오는 role을 STORE로 준다.
  async function seedParties(commissionerRole: 'BRAND' | 'STORE' = 'BRAND') {
    await prisma.user.createMany({
      data: [
        { id: USER_A, role: commissionerRole },
        { id: OTHER, role: 'CREATOR' },
      ],
    });
    await prisma.creatorProfile.create({
      data: { userId: OTHER, displayName: '하루 한 컵', ...REGION },
    });
    if (commissionerRole === 'BRAND') {
      await prisma.brandProfile.create({
        data: { userId: USER_A, name: '느린결', industry: 'ACCESSORY' },
      });
    }
  }

  async function seedBrandCollab(
    stage: CollaborationStage,
    over: { status?: ConversationStatus } = {},
  ): Promise<Seeded> {
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'BRAND_CONTRACT',
        stage,
        commissionerId: USER_A,
        creatorId: OTHER,
        terms: {},
        settlementMethod: 'FIXED',
        contractedAt: stage === 'CONTRACTED' ? T0 : null,
      },
    });
    const room = await prisma.conversation.create({
      data: {
        collaborationId: collaboration.id,
        status: over.status ?? 'OPEN',
        members: { create: [{ userId: USER_A }, { userId: OTHER }] },
      },
    });
    return { collaborationId: collaboration.id, roomId: room.id };
  }

  // 가게(user-a의 가게)와 크리에이터(user-b)의 오퍼·협업·방.
  async function seedStoreCollab(
    stage: CollaborationStage,
    offerStatus: 'SENT' | 'ACCEPTED' = 'ACCEPTED',
  ): Promise<Seeded & { offerId: string; storeId: string }> {
    const store =
      (await prisma.store.findUnique({ where: { ownerId: USER_A } })) ??
      (await prisma.store.create({
        data: {
          ownerId: USER_A,
          status: 'PUBLISHED',
          onboardingStep: 'DONE',
          name: '한그릇 라멘',
          ...REGION,
          defaultFormat: 'REELS',
          publishedAt: T0,
        },
      }));
    const offer = await createOffer(prisma, {
      storeId: store.id,
      creatorId: OTHER,
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      fixedCash: 30000,
      status: offerStatus,
      expiresAt: new Date(T0.getTime() + 7 * DAY),
      createdAt: T0,
      acceptedAt: offerStatus === 'ACCEPTED' ? T0 : null,
      paymentDueAt:
        offerStatus === 'ACCEPTED' && stage === 'AWAITING_PAYMENT'
          ? new Date(T0.getTime() + 3 * DAY)
          : null,
    });
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage,
        commissionerId: USER_A,
        creatorId: OTHER,
        offerId: offer.id,
        storeId: store.id,
        terms: { format: 'REELS', pieces: 1, fixedCash: 30000 },
        settlementMethod: 'FIXED',
      },
    });
    const room = await prisma.conversation.create({
      data: {
        collaborationId: collaboration.id,
        status: 'OPEN',
        members: { create: [{ userId: USER_A }, { userId: OTHER }] },
      },
    });
    return {
      collaborationId: collaboration.id,
      roomId: room.id,
      offerId: offer.id,
      storeId: store.id,
    };
  }

  async function seedContract(collaborationId: string) {
    return prisma.contract.create({
      data: {
        collaborationId,
        status: 'AWAITING_BRAND',
        termsVersion: 1,
        termsSnapshot: {},
        creatorConsentedAt: T0,
      },
    });
  }

  // 두 사람과 무관한 방(user-c의 것도 아닌 제3자 둘).
  async function seedStrangersRoom(): Promise<{
    roomId: string;
    brandId: string;
    creatorId: string;
  }> {
    const [brandId, creatorId] = [randomUUID(), randomUUID()];
    await prisma.user.createMany({
      data: [
        { id: brandId, role: 'BRAND' },
        { id: creatorId, role: 'CREATOR' },
      ],
    });
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'BRAND_CONTRACT',
        stage: 'CONTRACTED',
        commissionerId: brandId,
        creatorId,
        terms: {},
        settlementMethod: 'FIXED',
      },
    });
    const room = await prisma.conversation.create({
      data: {
        collaborationId: collaboration.id,
        status: 'OPEN',
        members: { create: [{ userId: brandId }, { userId: creatorId }] },
      },
    });
    return { roomId: room.id, brandId, creatorId };
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp([], { fakeRealtime: true });
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    scheduler = app.get<FakeJobScheduler>(JobScheduler);
    realtime = app.get<FakeRealtimePublisher>(RealtimePublisher);
    push = app.get<FakePushPort>(PushPort);
    alert = jest
      .spyOn(app.get(OperatorAlertPort), 'alert')
      .mockResolvedValue(undefined);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(T0);
    scheduler.jobs.length = 0;
    realtime.sent.length = 0;
    push.sent.length = 0;
    alert.mockClear();
  });
  afterAll(async () => {
    alert.mockRestore();
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server)
      .post(`/conversations/${randomUUID()}/block`)
      .expect(401);
    await request(server).post('/reports').expect(401);
  });

  describe('block', () => {
    it('refuses to block while money is held in any collaboration between the two', async () => {
      await seedParties();
      // 협의 중인 협업과 계약된(돈이 보관 중인) 협업이 함께 있다. 하나라도 보관 중이면 전부 그대로다.
      const negotiating = await seedBrandCollab('NEGOTIATING');
      await seedBrandCollab('CONTRACTED');
      const res = await block(negotiating.roomId).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(messageOf(res)).toBe(HELD_MESSAGE);
      expect(await prisma.block.count()).toBe(0);
      expect((await collaborationOf(negotiating.collaborationId)).stage).toBe(
        'NEGOTIATING',
      );
      expect((await roomOf(negotiating.roomId)).status).toBe('OPEN');
      // 멈춘 협업과 가게의 결제한 협업도 돈이 보관 중이다.
      await prisma.collaboration.updateMany({
        where: { stage: 'CONTRACTED' },
        data: { stage: 'HALTED', stageBeforeHalt: 'CONTRACTED' },
      });
      await block(negotiating.roomId, authB).expect(409);
      expect(await prisma.block.count()).toBe(0);
    });

    it('refuses to block a store collaboration that was paid', async () => {
      await seedParties('STORE');
      const funded = await seedStoreCollab('FUNDED');
      const res = await block(funded.roomId, authB).expect(409);
      expect(messageOf(res)).toBe(HELD_MESSAGE);
      expect(await prisma.block.count()).toBe(0);
      expect(
        (
          await prisma.offer.findUniqueOrThrow({
            where: { id: funded.offerId },
          })
        ).status,
      ).toBe('ACCEPTED');
    });

    it('closes every conversation between the two and rejects sends from both sides', async () => {
      await seedParties();
      const first = await seedBrandCollab('NEGOTIATING');
      const second = await seedBrandCollab('MATCHED', { status: 'OPEN' });
      const third = await seedBrandCollab('INQUIRY', { status: 'REQUESTED' });
      await sendText(first.roomId, authB).expect(201);
      const res = await block(first.roomId, authB).expect(200);
      expect(res.body).toMatchObject({
        id: first.roomId,
        status: 'CLOSED',
        blockedByMe: true,
        canSend: false,
        canProposeTerms: false,
        canDrop: false,
      });
      for (const room of [first, second, third]) {
        expect(await roomOf(room.roomId)).toMatchObject({
          status: 'CLOSED',
          closedReason: 'BLOCKED',
        });
        await sendText(room.roomId, authA).expect(409);
        await sendText(room.roomId, authB).expect(409);
      }
      expect(await prisma.block.findMany()).toEqual([
        expect.objectContaining({ blockerId: OTHER, blockedId: USER_A }),
      ]);
    });

    it('shows the blocked side a closed room without saying who closed it', async () => {
      await seedParties();
      const room = await seedBrandCollab('NEGOTIATING');
      await sendText(room.roomId, authA).expect(201);
      await flushMessages(app);
      push.sent.length = 0;
      realtime.sent.length = 0;
      await block(room.roomId, authB).expect(200);
      expect(await detail(room.roomId, authA)).toMatchObject({
        status: 'CLOSED',
        blockedByMe: false,
        canSend: false,
      });
      expect(await detail(room.roomId, authB)).toMatchObject({
        status: 'CLOSED',
        blockedByMe: true,
      });
      // 안내 줄도 알림도 푸시도 남기지 않는다: 차단 사실은 상대에게 보이지 않는다.
      const lines = await prisma.message.findMany({
        where: { conversationId: room.roomId },
      });
      expect(lines.map((m) => m.kind)).toEqual(['TEXT']);
      expect(await prisma.notification.count()).toBe(0);
      expect(push.sent).toEqual([]);
      // 두 사람의 화면은 닫힌 방을 다시 읽는다(메시지 이벤트는 없다).
      expect(realtime.receivedBy(USER_A, 'message.created')).toEqual([]);
      expect(
        realtime
          .receivedBy(USER_A, 'conversation.updated')
          .map((e) => e.payload),
      ).toContainEqual({ conversationId: room.roomId, reason: 'STATUS' });
      expect(
        realtime
          .receivedBy(OTHER, 'conversation.updated')
          .map((e) => e.payload),
      ).toContainEqual({ conversationId: room.roomId, reason: 'STATUS' });
    });

    it('drops a negotiating brand collaboration and voids its contract on block', async () => {
      await seedParties();
      const agreed = await seedBrandCollab('AGREED');
      const contract = await seedContract(agreed.collaborationId);
      const inquiry = await seedBrandCollab('INQUIRY', { status: 'REQUESTED' });
      await block(agreed.roomId, authB).expect(200);
      expect(await collaborationOf(agreed.collaborationId)).toMatchObject({
        stage: 'DROPPED',
        dropReason: 'BLOCKED',
        droppedById: OTHER,
      });
      expect(await collaborationOf(inquiry.collaborationId)).toMatchObject({
        stage: 'DROPPED',
        dropReason: 'BLOCKED',
      });
      expect(
        await prisma.contract.findUniqueOrThrow({ where: { id: contract.id } }),
      ).toMatchObject({ status: 'VOIDED', voidReason: 'BLOCKED' });
      expect(
        (
          await prisma.contract.findUniqueOrThrow({
            where: { id: contract.id },
          })
        ).voidedAt,
      ).toEqual(T0);
    });

    describe('while a brand payment is in progress', () => {
      const insertPayment = (
        collaborationId: string,
        status: 'PENDING' | 'FAILED' | 'CANCELLED',
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

      it('refuses to block and changes nothing', async () => {
        await seedParties();
        const agreed = await seedBrandCollab('AGREED');
        const contract = await seedContract(agreed.collaborationId);
        await insertPayment(agreed.collaborationId, 'PENDING', T0);
        const inquiry = await seedBrandCollab('INQUIRY', {
          status: 'REQUESTED',
        });
        clock.set(new Date(T0.getTime() + 30 * 60 * 1000));
        const res = await block(agreed.roomId, authB).expect(409);
        expect(codeOf(res)).toBe('CONFLICT');
        expect(messageOf(res)).toBe(HELD_MESSAGE);
        expect(await prisma.block.count()).toBe(0);
        expect((await collaborationOf(agreed.collaborationId)).stage).toBe(
          'AGREED',
        );
        expect((await collaborationOf(inquiry.collaborationId)).stage).toBe(
          'INQUIRY',
        );
        expect(
          (
            await prisma.contract.findUniqueOrThrow({
              where: { id: contract.id },
            })
          ).status,
        ).toBe('AWAITING_BRAND');
        expect((await roomOf(agreed.roomId)).status).toBe('OPEN');
        expect(await prisma.payment.findFirstOrThrow({})).toMatchObject({
          status: 'PENDING',
        });
        // 다른 방에서 눌러도, 맡긴 브랜드가 눌러도 같다.
        await block(inquiry.roomId, authB).expect(409);
        await block(agreed.roomId, authA).expect(409);
        expect(await prisma.block.count()).toBe(0);
      });

      it('allows the block once the 60 minute lock has passed', async () => {
        await seedParties();
        const agreed = await seedBrandCollab('AGREED');
        await seedContract(agreed.collaborationId);
        await insertPayment(agreed.collaborationId, 'PENDING', T0);
        clock.set(new Date(T0.getTime() + 60 * 60 * 1000));
        await block(agreed.roomId, authB).expect(200);
        expect((await collaborationOf(agreed.collaborationId)).stage).toBe(
          'DROPPED',
        );
      });

      it.each(['FAILED', 'CANCELLED'] as const)(
        'does not count a %s payment as in progress',
        async (status) => {
          await seedParties();
          const agreed = await seedBrandCollab('AGREED');
          await seedContract(agreed.collaborationId);
          await insertPayment(agreed.collaborationId, status, T0);
          await block(agreed.roomId, authB).expect(200);
          expect((await collaborationOf(agreed.collaborationId)).stage).toBe(
            'DROPPED',
          );
        },
      );
    });

    it('cancels a store offer that is waiting for payment together with its collaboration', async () => {
      await seedParties('STORE');
      const awaiting = await seedStoreCollab('AWAITING_PAYMENT');
      await block(awaiting.roomId, authB).expect(200);
      expect(
        await prisma.offer.findUniqueOrThrow({
          where: { id: awaiting.offerId },
        }),
      ).toMatchObject({ status: 'CANCELLED' });
      expect(
        (
          await prisma.offer.findUniqueOrThrow({
            where: { id: awaiting.offerId },
          })
        ).closedAt,
      ).not.toBeNull();
      expect((await collaborationOf(awaiting.collaborationId)).stage).toBe(
        'CANCELLED',
      );
      expect((await roomOf(awaiting.roomId)).status).toBe('CLOSED');
    });

    it('ends an open offer that nobody answered yet so it cannot be accepted after the block', async () => {
      await seedParties('STORE');
      const store = await prisma.store.create({
        data: {
          ownerId: USER_A,
          status: 'PUBLISHED',
          onboardingStep: 'DONE',
          name: '한그릇 라멘',
          ...REGION,
          defaultFormat: 'REELS',
          publishedAt: T0,
        },
      });
      const application = await prisma.application.create({
        data: { storeId: store.id, creatorId: OTHER, status: 'OFFERED' },
      });
      const offer = await createOffer(prisma, {
        storeId: store.id,
        creatorId: OTHER,
        applicationId: application.id,
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        status: 'SENT',
        expiresAt: new Date(T0.getTime() + 7 * DAY),
        createdAt: T0,
      });
      // 협업이 없는 문의 방(두 사람 사이의 다른 방)에서 차단한다.
      await prisma.user.update({
        where: { id: USER_A },
        data: { role: 'BRAND' },
      });
      await prisma.brandProfile.create({
        data: { userId: USER_A, name: '느린결', industry: 'ACCESSORY' },
      });
      const room = await seedBrandCollab('NEGOTIATING');
      await block(room.roomId, authB).expect(200);
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('CANCELLED');
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: application.id },
          })
        ).status,
      ).toBe('CLOSED');
      const accept = await request(server)
        .post(`/offers/${offer.id}/accept`)
        .set(authB)
        .send({ version: 1 });
      expect(accept.status).toBe(409);
      expect(
        await prisma.collaboration.count({ where: { offerId: offer.id } }),
      ).toBe(0);
    });

    it('is idempotent and answers 404 for a room the caller does not belong to', async () => {
      await seedParties();
      const room = await seedBrandCollab('NEGOTIATING');
      await block(room.roomId).expect(200);
      await block(room.roomId).expect(200);
      expect(await prisma.block.count()).toBe(1);
      const stranger = await seedStrangersRoom();
      const res = await block(stranger.roomId).expect(404);
      expect(codeOf(res)).toBe('NOT_FOUND');
      await block('not-a-uuid').expect(404);
      await block(randomUUID()).expect(404);
      await request(server)
        .post(`/conversations/${room.roomId}/block`)
        .set({ Authorization: 'Bearer user-c' })
        .expect(404);
      expect(await prisma.block.count()).toBe(1);
    });

    it('does not roll the room back when delivery to the screens fails', async () => {
      await seedParties();
      const room = await seedBrandCollab('NEGOTIATING');
      realtime.fail = true;
      await block(room.roomId).expect(200);
      realtime.fail = false;
      expect((await roomOf(room.roomId)).status).toBe('CLOSED');
    });
  });

  describe('report', () => {
    it('stores a report and emails the operator once', async () => {
      await seedParties();
      const room = await seedBrandCollab('NEGOTIATING');
      const res = await report({
        targetKind: 'CONVERSATION',
        targetId: room.roomId,
        reason: 'ABUSE',
        detail: '  욕설을 했어요.  ',
      }).expect(201);
      const { id } = res.body as { id: string };
      expect(
        await prisma.report.findUniqueOrThrow({ where: { id } }),
      ).toMatchObject({
        reporterId: USER_A,
        targetKind: 'CONVERSATION',
        targetId: room.roomId,
        reason: 'ABUSE',
        detail: '욕설을 했어요.',
        resolvedAt: null,
      });
      expect(alert).toHaveBeenCalledTimes(1);
      const sent = alertOf(0);
      expect(sent.subject).toBe('[Cora] 신고 접수 · 부적절한 말');
      expect(sent.body).toContain(id);
      expect(sent.body).toContain(`CONVERSATION ${room.roomId}`);
      expect(sent.body).toContain(USER_A);
      expect(sent.body).toContain('욕설을 했어요.');
      // 돈이 보관 중이 아니면 협업은 그대로이고 아무에게도 알림이 가지 않는다.
      expect((await collaborationOf(room.collaborationId)).stage).toBe(
        'NEGOTIATING',
      );
      expect(await prisma.notification.count()).toBe(0);
    });

    it('refuses a second report on the same target', async () => {
      await seedParties();
      const room = await seedBrandCollab('NEGOTIATING');
      const body = { targetKind: 'CONVERSATION', targetId: room.roomId };
      await report(body).expect(201);
      const again = await report({ ...body, reason: 'FRAUD' }).expect(409);
      expect(codeOf(again)).toBe('CONFLICT');
      expect(messageOf(again)).toBe('이미 신고했어요.');
      expect(await prisma.report.count()).toBe(1);
      expect(alert).toHaveBeenCalledTimes(1);
      // 같은 대상이라도 상대(user-b)는 따로 신고할 수 있다.
      await report(body, authB).expect(201);
      expect(await prisma.report.count()).toBe(2);
    });

    it('reports the other user of a room I belong to', async () => {
      await seedParties();
      await seedBrandCollab('NEGOTIATING');
      const res = await report({
        targetKind: 'USER',
        targetId: OTHER,
        reason: 'FRAUD',
      }).expect(201);
      expect(
        await prisma.report.findUniqueOrThrow({
          where: { id: (res.body as { id: string }).id },
        }),
      ).toMatchObject({ targetKind: 'USER', targetId: OTHER, reason: 'FRAUD' });
      expect(alertOf(0).subject).toBe('[Cora] 신고 접수 · 사기 의심');
    });

    it('answers 404 for rooms and users that are not mine', async () => {
      await seedParties();
      await seedBrandCollab('NEGOTIATING');
      const stranger = await seedStrangersRoom();
      for (const body of [
        { targetKind: 'CONVERSATION', targetId: stranger.roomId },
        { targetKind: 'CONVERSATION', targetId: randomUUID() },
        { targetKind: 'CONVERSATION', targetId: 'nope' },
        { targetKind: 'USER', targetId: stranger.creatorId },
        { targetKind: 'USER', targetId: USER_A },
        { targetKind: 'USER', targetId: 'nope' },
      ]) {
        const res = await report(body).expect(404);
        expect(codeOf(res)).toBe('NOT_FOUND');
      }
      expect(await prisma.report.count()).toBe(0);
      expect(alert).not.toHaveBeenCalled();
    });

    it('validates the reason and the length of the detail', async () => {
      await seedParties();
      const room = await seedBrandCollab('NEGOTIATING');
      const base = { targetKind: 'CONVERSATION', targetId: room.roomId };
      await report({ ...base, reason: 'RUDE' }).expect(400);
      await report({ ...base, detail: 'a'.repeat(501) }).expect(400);
      await report({ targetKind: 'CONTENT', targetId: room.roomId }).expect(
        400,
      );
      expect(await prisma.report.count()).toBe(0);
      await report({ ...base, detail: '가'.repeat(500) }).expect(201);
    });

    it('does not fail the report when the operator mail cannot be sent', async () => {
      await seedParties();
      const room = await seedBrandCollab('NEGOTIATING');
      alert.mockRejectedValueOnce(new Error('smtp down'));
      await report({
        targetKind: 'CONVERSATION',
        targetId: room.roomId,
      }).expect(201);
      expect(await prisma.report.count()).toBe(1);
    });
  });

  describe('report of a collaboration that holds money', () => {
    it('halts a money-held collaboration when its conversation is reported', async () => {
      await seedParties();
      const room = await seedBrandCollab('CONTRACTED');
      for (const [key, name] of [
        [brandHaltJobKey(room.collaborationId), 'brand-halt-check'],
        [settleJobKey(room.collaborationId), 'settle'],
      ] as const) {
        await scheduler.schedule(
          name,
          { collaborationId: room.collaborationId },
          new Date(T0.getTime() + 7 * DAY),
          key,
        );
      }
      await scheduler.schedule(
        'brand-halt-check',
        { collaborationId: randomUUID() },
        new Date(T0.getTime() + 7 * DAY),
        'brand-halt:someone-else',
      );
      await report({
        targetKind: 'CONVERSATION',
        targetId: room.roomId,
        reason: 'FRAUD',
      }).expect(201);
      expect(await collaborationOf(room.collaborationId)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'CONTRACTED',
        haltedReason: 'REPORTED',
      });
      // 등록된 작업은 취소되고 남의 작업은 그대로다.
      expect(scheduler.pending().map((j) => j.jobKey)).toEqual([
        'brand-halt:someone-else',
      ]);
      expect(alert).toHaveBeenCalledTimes(1);
      const sent = alertOf(0);
      expect(sent.subject).toBe('[Cora] 신고 접수 · 사기 의심 · 협업 멈춤');
      expect(sent.body).toContain(room.collaborationId);
      // 양쪽에 같은 알림이 가고, 누가 신고했는지는 어디에도 없다.
      const notes = await prisma.notification.findMany({
        orderBy: { role: 'asc' },
      });
      expect(
        notes.map((n) => [n.userId, n.role, n.kind, n.targetKind, n.targetId]),
      ).toEqual([
        [
          USER_A,
          'BRAND',
          'COLLABORATION_HALTED',
          'COLLABORATION',
          room.collaborationId,
        ],
        [
          OTHER,
          'CREATOR',
          'COLLABORATION_HALTED',
          'COLLABORATION',
          room.collaborationId,
        ],
      ]);
      for (const note of notes) {
        expect(note.actorUserId).toBeNull();
        expect(note.actorName).toBeNull();
        expect(JSON.stringify(note.params)).not.toContain(USER_A);
      }
      expect(push.sent.map((p) => p.userId).sort()).toEqual(
        [USER_A, OTHER].sort(),
      );
      // 두 사람의 화면이 방을 다시 읽는다.
      for (const user of [USER_A, OTHER]) {
        expect(
          realtime
            .receivedBy(user, 'conversation.updated')
            .map((e) => e.payload),
        ).toContainEqual({ conversationId: room.roomId, reason: 'STATUS' });
      }
      // 같은 방을 다시 신고하면(상대가) 이미 멈춘 협업은 다시 멈추지 않고 알림도 늘지 않는다.
      await report(
        { targetKind: 'CONVERSATION', targetId: room.roomId },
        authB,
      ).expect(201);
      expect(await prisma.notification.count()).toBe(2);
      expect(alertOf(1).subject).not.toContain('협업 멈춤');
    });

    it('lets an operator resume a collaboration that was halted by a report', async () => {
      await seedParties();
      const room = await seedBrandCollab('CONTRACTED');
      await report({
        targetKind: 'CONVERSATION',
        targetId: room.roomId,
      }).expect(201);
      const result = await app
        .get(OpsRunner)
        .run([
          'resume',
          '--collaboration',
          room.collaborationId,
          '--operator',
          '김운영',
          '--reason',
          '신고 확인 끝',
        ]);
      expect(result.exitCode).toBe(0);
      expect(await collaborationOf(room.collaborationId)).toMatchObject({
        stage: 'CONTRACTED',
        stageBeforeHalt: null,
        haltedReason: null,
      });
    });

    it('sends the halted notice again when a resumed collaboration is halted a second time', async () => {
      await seedParties();
      const room = await seedBrandCollab('CONTRACTED');
      const resume = () =>
        app
          .get(OpsRunner)
          .run([
            'resume',
            '--collaboration',
            room.collaborationId,
            '--operator',
            '김운영',
            '--reason',
            '신고 확인 끝',
          ]);
      const halted = () =>
        prisma.notification.findMany({
          where: { kind: 'COLLABORATION_HALTED' },
        });
      await report({
        targetKind: 'CONVERSATION',
        targetId: room.roomId,
      }).expect(201);
      expect(await halted()).toHaveLength(2);
      expect((await resume()).exitCode).toBe(0);
      // 풀었다가 다른 신고(상대의 신고)로 다시 멈추면 양쪽에 새 알림이 간다.
      await report(
        { targetKind: 'CONVERSATION', targetId: room.roomId },
        authB,
      ).expect(201);
      expect((await collaborationOf(room.collaborationId)).stage).toBe(
        'HALTED',
      );
      const rows = await halted();
      expect(rows).toHaveLength(4);
      expect(new Set(rows.map((n) => n.dedupeKey)).size).toBe(2);
      for (const userId of [USER_A, OTHER]) {
        expect(rows.filter((n) => n.userId === userId)).toHaveLength(2);
      }
      expect(push.sent).toHaveLength(4);
    });

    it('sends the halted notice for a report even after an earlier view-count halt was resumed', async () => {
      await seedParties('STORE');
      const counting = await seedStoreCollab('COUNTING');
      await prisma.collaboration.update({
        where: { id: counting.collaborationId },
        data: {
          submittedUrl: 'https://www.instagram.com/reel/C8abc123/',
          submittedAt: T0,
          countingEndsAt: new Date(T0.getTime() + 7 * DAY),
        },
      });
      // 조회수 실패 멈춤이 남긴 알림(옛 키 모양과 새 키 모양 모두 이 신고의 키와 다르다).
      for (const [userId, role] of [
        [USER_A, 'STORE'],
        [OTHER, 'CREATOR'],
      ] as const) {
        await prisma.notification.create({
          data: {
            userId,
            role,
            kind: 'COLLABORATION_HALTED',
            tab: 'COLLABORATION',
            params: {},
            targetKind: 'COLLABORATION',
            targetId: counting.collaborationId,
            dedupeKey: `halted:${counting.collaborationId}`,
          },
        });
      }
      await report({
        targetKind: 'CONVERSATION',
        targetId: counting.roomId,
      }).expect(201);
      expect(
        await prisma.notification.count({
          where: { kind: 'COLLABORATION_HALTED' },
        }),
      ).toBe(4);
    });

    it('leaves an audit row when a report halts a collaboration', async () => {
      await seedParties();
      const room = await seedBrandCollab('CONTRACTED');
      const negotiating = await seedBrandCollab('NEGOTIATING');
      const { id } = (
        await report({ targetKind: 'USER', targetId: OTHER }).expect(201)
      ).body as { id: string };
      const rows = await prisma.opsAuditLog.findMany();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        command: 'report-halt',
        collaborationId: room.collaborationId,
        operator: 'system',
        reason: 'REPORTED',
        detail: { reportId: id, from: 'CONTRACTED' },
      });
      expect(rows[0].createdAt).toEqual(T0);
      // 멈추지 않은 신고에는 기록이 없다.
      await report(
        { targetKind: 'CONVERSATION', targetId: negotiating.roomId },
        authB,
      ).expect(201);
      expect(await prisma.opsAuditLog.count()).toBe(1);
    });

    it('does not wait for the operator mail before answering the report', async () => {
      await seedParties();
      const room = await seedBrandCollab('NEGOTIATING');
      alert.mockReturnValueOnce(new Promise<void>(() => undefined));
      await report({
        targetKind: 'CONVERSATION',
        targetId: room.roomId,
      }).expect(201);
      expect(alert).toHaveBeenCalledTimes(1);
      expect(await prisma.report.count()).toBe(1);
    });

    it('does not halt when no money is held', async () => {
      await seedParties();
      const negotiating = await seedBrandCollab('NEGOTIATING');
      const agreed = await seedBrandCollab('AGREED');
      await report({
        targetKind: 'CONVERSATION',
        targetId: negotiating.roomId,
      }).expect(201);
      await report({ targetKind: 'USER', targetId: OTHER }).expect(201);
      expect((await collaborationOf(negotiating.collaborationId)).stage).toBe(
        'NEGOTIATING',
      );
      expect((await collaborationOf(agreed.collaborationId)).stage).toBe(
        'AGREED',
      );
      expect(await prisma.notification.count()).toBe(0);
      for (const call of alert.mock.calls as [{ subject: string }][]) {
        expect(call[0].subject).not.toContain('협업 멈춤');
      }
    });

    it('halts every money-held collaboration between the two when the user is reported', async () => {
      await seedParties();
      const brand = await seedBrandCollab('PUBLISHED');
      const negotiating = await seedBrandCollab('NEGOTIATING');
      await report(
        { targetKind: 'USER', targetId: OTHER, reason: 'SPAM' },
        authA,
      ).expect(201);
      expect(await collaborationOf(brand.collaborationId)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'PUBLISHED',
        haltedReason: 'REPORTED',
      });
      expect((await collaborationOf(negotiating.collaborationId)).stage).toBe(
        'NEGOTIATING',
      );
      expect(alertOf(0).subject).toBe(
        '[Cora] 신고 접수 · 광고·스팸 · 협업 멈춤',
      );
    });

    it('halts only the collaboration of the reported room when two rooms exist', async () => {
      await seedParties();
      const first = await seedBrandCollab('CONTRACTED');
      const second = await seedBrandCollab('GUIDED');
      await report({
        targetKind: 'CONVERSATION',
        targetId: first.roomId,
      }).expect(201);
      expect((await collaborationOf(first.collaborationId)).stage).toBe(
        'HALTED',
      );
      expect((await collaborationOf(second.collaborationId)).stage).toBe(
        'GUIDED',
      );
    });

    it('halts a counting store collaboration and cancels its settlement jobs', async () => {
      await seedParties('STORE');
      const counting = await seedStoreCollab('COUNTING');
      await prisma.collaboration.update({
        where: { id: counting.collaborationId },
        data: {
          submittedUrl: 'https://www.instagram.com/reel/C8abc123/',
          submittedAt: T0,
          countingEndsAt: new Date(T0.getTime() + 7 * DAY),
        },
      });
      await scheduler.schedule(
        'settle',
        { collaborationId: counting.collaborationId },
        new Date(T0.getTime() + 7 * DAY),
        settleJobKey(counting.collaborationId),
      );
      await report(
        { targetKind: 'CONVERSATION', targetId: counting.roomId },
        authB,
      ).expect(201);
      expect(await collaborationOf(counting.collaborationId)).toMatchObject({
        stage: 'HALTED',
        stageBeforeHalt: 'COUNTING',
        haltedReason: 'REPORTED',
      });
      expect(scheduler.pending()).toEqual([]);
      const notes = await prisma.notification.findMany();
      expect(notes.map((n) => n.role).sort()).toEqual(['CREATOR', 'STORE']);
    });

    it('does not halt a collaboration whose view report is still waiting to be confirmed, and says so in the mail', async () => {
      await seedParties('STORE');
      const counting = await seedStoreCollab('COUNTING');
      await prisma.settlement.create({
        data: {
          collaborationId: counting.collaborationId,
          payoutAmount: 0,
          refundAmount: 0,
          status: 'UNCONFIRMED',
        },
      });
      await report({
        targetKind: 'CONVERSATION',
        targetId: counting.roomId,
      }).expect(201);
      expect((await collaborationOf(counting.collaborationId)).stage).toBe(
        'COUNTING',
      );
      const sent = alertOf(0);
      expect(sent.subject).not.toContain('협업 멈춤');
      expect(sent.body).toContain('멈추지 못한 협업');
      expect(await prisma.notification.count()).toBe(0);
    });
  });

  describe('visibility after a block', () => {
    it('stops showing the blocked user a conversation list entry as normal and keeps the room readable', async () => {
      await seedParties();
      const room = await seedBrandCollab('NEGOTIATING');
      await sendText(room.roomId, authB).expect(201);
      await block(room.roomId, authA).expect(200);
      const list = (
        await request(server).get('/conversations').set(authB).expect(200)
      ).body as { id: string; status: string }[];
      expect(list).toEqual([
        expect.objectContaining({ id: room.roomId, status: 'CLOSED' }),
      ]);
      const read = await request(server)
        .get(`/conversations/${room.roomId}/messages`)
        .set(authB)
        .expect(200);
      expect(read.body as unknown[]).toHaveLength(1);
    });
  });
});
