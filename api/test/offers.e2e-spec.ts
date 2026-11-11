import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { CollaborationStage, Prisma, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { PushPort } from '../src/integrations/push/push.port';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { OffersRepository } from '../src/offers/offers.repository';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const T0 = new Date('2026-12-01T00:00:00.000Z');
const SECOND = 1000;
const DAY = 24 * 60 * 60 * SECOND;
const LINKS = [
  { kind: 'NAVER_MAP', url: 'https://map.naver.com/p/entry/place/1' },
];
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const PROFILE = {
  displayName: '하루 한 컵',
  contentFocus: '카페 릴스',
  ...REGION,
};
const REELS_VOUCHER = { format: 'REELS', rewardType: 'VOUCHER' };
// 조회수 보상만 있는 오퍼를 DB에 바로 만들 때 쓰는 값.
const PER_VIEW_TERMS = {
  rewardType: 'PER_VIEW',
  voucherName: null,
  voucherValue: null,
  perViewAmount: 10,
  perViewCap: 100000,
} as const;

interface TermsBody {
  format: string;
  rewardType: string;
  voucherName: string | null;
  voucherValue: number | null;
  perViewAmount: number | null;
  perViewCap: number | null;
}
interface SentBody {
  id: string;
  collaborationId: string | null;
  creator: { userId: string; displayName: string };
  terms: TermsBody;
  view: string;
  paymentDaysLeft: number | null;
  sentAt: string;
}
interface ReceivedBody {
  id: string;
  collaborationId: string | null;
  store: { id: string; name: string };
  storeIntro: string | null;
  bestShootingTime: string | null;
  terms: TermsBody;
  view: string;
  receivedAt: string;
  canUndoDecline: boolean;
  needsInstagram: boolean;
}
interface SummaryBody {
  newApplications: number;
  sentOffers: number;
  inProgress: number;
}

describe('offers', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let push: FakePushPort;
  let clock: FakeClock;
  let scheduler: FakeJobScheduler;

  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const putProfile = () =>
    request(server).put('/creators/me').set(auth).send(PROFILE).expect(200);
  const send = (body: Record<string, unknown>) =>
    request(server).post('/offers').set(auth).send(body);
  const sentList = () => request(server).get('/offers/sent').set(auth);
  const cancel = (id: string) =>
    request(server).post(`/offers/${id}/cancel`).set(auth).send();
  const received = (tab: string) =>
    request(server).get(`/offers/received?tab=${tab}`).set(auth);
  const accept = (id: string) =>
    request(server).post(`/offers/${id}/accept`).set(auth).send();
  const decline = (id: string) =>
    request(server).post(`/offers/${id}/decline`).set(auth).send();
  const undo = (id: string) =>
    request(server).post(`/offers/${id}/undo-decline`).set(auth).send();
  // 크리에이터(user-a)가 인스타그램을 연결한다. 연결할 계정 아이디가 곧 코드다.
  const connectInstagram = (handle = 'haru_cafe') =>
    request(server)
      .post('/instagram/connect/complete')
      .set(auth)
      .send({ code: handle })
      .expect(200);
  const summary = () => request(server).get('/stores/me/summary').set(auth);
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;

  // 내 가게(user-a)를 만들어 공개한다. 끝나면 역할은 STORE다.
  async function publishMine(): Promise<string> {
    await setRole('STORE');
    await request(server)
      .post('/stores/me/analyze')
      .set(auth)
      .send({ links: LINKS })
      .expect(200);
    await request(server)
      .patch('/stores/me')
      .set(auth)
      .send(REGION)
      .expect(200);
    await request(server)
      .put('/stores/me/default-terms')
      .set(auth)
      .send(REELS_VOUCHER)
      .expect(200);
    const res = await request(server)
      .post('/stores/me/publish')
      .set(auth)
      .send()
      .expect(200);
    return (res.body as { id: string }).id;
  }

  // 활동 프로필이 있는 다른 크리에이터(로그인할 수 없다).
  async function seedCreator(name = '다른 크리에이터'): Promise<string> {
    const userId = randomUUID();
    await prisma.user.create({ data: { id: userId, role: 'CREATOR' } });
    await prisma.creatorProfile.create({
      data: { userId, displayName: name, ...REGION },
    });
    return userId;
  }

  async function seedApplication(
    storeId: string,
    creatorId: string,
    status: 'APPLIED' | 'OFFERED' = 'APPLIED',
  ): Promise<string> {
    const row = await prisma.application.create({
      data: { storeId, creatorId, status },
    });
    return row.id;
  }

  // 다른 사장님의 공개된 가게.
  async function seedStore(): Promise<{ id: string; ownerId: string }> {
    const ownerId = randomUUID();
    await prisma.user.create({ data: { id: ownerId, role: 'STORE' } });
    const store = await prisma.store.create({
      data: {
        ownerId,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name: '남의 가게',
        neighborhood: '성수동',
        intro: '성수동의 작은 카페예요.',
        bestShootingTime: '오후 2시',
        regionSido: REGION.regionSido,
        regionSigungu: REGION.regionSigungu,
        defaultFormat: 'REELS',
        defaultRewardType: 'VOUCHER',
        defaultVoucherName: '2인 식사권',
        defaultVoucherValue: 40000,
        publishedAt: T0,
      },
    });
    return { id: store.id, ownerId };
  }

  // 시계를 기준으로 오퍼를 DB에 바로 만든다.
  function seedOffer(
    storeId: string,
    creatorId: string,
    over: Partial<Prisma.OfferUncheckedCreateInput> = {},
  ) {
    return prisma.offer.create({
      data: {
        storeId,
        creatorId,
        format: 'REELS',
        rewardType: 'VOUCHER',
        voucherName: '2인 식사권',
        voucherValue: 40000,
        status: 'SENT',
        expiresAt: new Date(clock.now().getTime() + 7 * DAY),
        createdAt: clock.now(),
        ...over,
      },
    });
  }

  // 오퍼에 연결된 협업을 DB에 바로 만든다. 가게 사장님이 USER_A인 경우가 기본이다.
  async function seedCollaboration(
    offer: {
      id: string;
      storeId: string;
      creatorId: string;
      rewardType: string;
    },
    ownerId: string,
    stage: CollaborationStage,
  ) {
    return prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage,
        commissionerId: ownerId,
        creatorId: offer.creatorId,
        offerId: offer.id,
        storeId: offer.storeId,
        terms: { format: 'REELS', rewardType: offer.rewardType },
        settlementMethod: offer.rewardType === 'VOUCHER' ? 'NONE' : 'PER_VIEW',
      },
    });
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    push = app.get<FakePushPort>(PushPort);
    clock = app.get<FakeClock>(Clock);
    scheduler = app.get<FakeJobScheduler>(JobScheduler);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    push.sent.length = 0;
    scheduler.jobs.length = 0;
    clock.set(T0);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).post('/offers').send({}).expect(401);
    await request(server).get('/offers/sent').expect(401);
    await request(server).get('/offers/received?tab=new').expect(401);
    await request(server).post(`/offers/${randomUUID()}/cancel`).expect(401);
    await request(server).post(`/offers/${randomUUID()}/accept`).expect(401);
    await request(server).get('/stores/me/summary').expect(401);
  });

  describe('as a store owner', () => {
    let storeId: string;
    beforeEach(async () => {
      storeId = await publishMine();
    });

    it('sends an offer to an applicant and links the application', async () => {
      const creatorId = await seedCreator('지원한 크리에이터');
      const applicationId = await seedApplication(storeId, creatorId);

      const res = await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      const body = res.body as SentBody;
      expect(body).toMatchObject({
        creator: { userId: creatorId, displayName: '지원한 크리에이터' },
        view: 'WAITING',
        paymentDaysLeft: null,
        sentAt: T0.toISOString(),
      });
      expect(body.terms).toEqual({
        format: 'REELS',
        rewardType: 'VOUCHER',
        voucherName: '2인 식사권',
        voucherValue: 40000,
        perViewAmount: null,
        perViewCap: null,
      });
      const offer = await prisma.offer.findUniqueOrThrow({
        where: { id: body.id },
      });
      expect(offer).toMatchObject({
        storeId,
        creatorId,
        applicationId,
        status: 'SENT',
        expiresAt: new Date(T0.getTime() + 7 * DAY),
      });
      const application = await prisma.application.findUniqueOrThrow({
        where: { id: applicationId },
      });
      expect(application.status).toBe('OFFERED');
    });

    it('sends an offer to a creator who never applied', async () => {
      const creatorId = await seedCreator();
      const res = await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      const offer = await prisma.offer.findUniqueOrThrow({
        where: { id: (res.body as SentBody).id },
      });
      expect(offer.applicationId).toBeNull();
    });

    it('copies terms so later default changes do not affect it', async () => {
      const creatorId = await seedCreator();
      await send({
        creatorId,
        format: 'REELS',
        rewardType: 'BOTH',
        voucherName: '커피 쿠폰',
        voucherValue: 12000,
      }).expect(201);
      await request(server)
        .put('/stores/me/default-terms')
        .set(auth)
        .send({ format: 'SHORTS', rewardType: 'PER_VIEW' })
        .expect(200);

      const list = (await sentList().expect(200)).body as SentBody[];
      expect(list).toHaveLength(1);
      expect(list[0].terms).toEqual({
        format: 'REELS',
        rewardType: 'BOTH',
        voucherName: '커피 쿠폰',
        voucherValue: 12000,
        perViewAmount: 10,
        perViewCap: 100000,
      });
    });

    it('rejects a blog offer with a per-view reward', async () => {
      const creatorId = await seedCreator();
      const res = await send({
        creatorId,
        format: 'BLOG',
        rewardType: 'PER_VIEW',
      }).expect(400);
      expect(codeOf(res)).toBe('VALIDATION_FAILED');
      expect(await prisma.offer.count()).toBe(0);
    });

    it('rejects a malformed body', async () => {
      await send({ creatorId: 'nope', ...REELS_VOUCHER }).expect(400);
      await send({
        creatorId: randomUUID(),
        format: 'X',
        rewardType: 'VOUCHER',
      }).expect(400);
      await send({
        creatorId: randomUUID(),
        ...REELS_VOUCHER,
        extra: 1,
      }).expect(400);
    });

    it('rejects a second open offer to the same creator', async () => {
      const creatorId = await seedCreator();
      await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      const res = await send({ creatorId, ...REELS_VOUCHER }).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(await prisma.offer.count()).toBe(1);
    });

    it('rejects a new offer while the creator can still undo a decline', async () => {
      const creatorId = await seedCreator();
      await seedOffer(storeId, creatorId, {
        status: 'DECLINED',
        declinedAt: new Date(T0.getTime() - 10 * SECOND),
      });
      // 사장님에게는 아직 "답을 기다려요"이고, 되돌리면 다시 열린 오퍼가 된다.
      await send({ creatorId, ...REELS_VOUCHER }).expect(409);
    });

    it('allows a new offer after the previous one expired', async () => {
      const creatorId = await seedCreator();
      const applicationId = await seedApplication(storeId, creatorId);
      const first = (await send({ creatorId, ...REELS_VOUCHER }).expect(201))
        .body as SentBody;

      clock.advance(7 * DAY);
      const second = (await send({ creatorId, ...REELS_VOUCHER }).expect(201))
        .body as SentBody;

      expect(second.id).not.toBe(first.id);
      const old = await prisma.offer.findUniqueOrThrow({
        where: { id: first.id },
      });
      expect(old.status).toBe('EXPIRED');
      const application = await prisma.application.findUniqueOrThrow({
        where: { id: applicationId },
      });
      expect(application.status).toBe('CLOSED');
    });

    it('allows a new offer after a final decline or a cancel', async () => {
      const creatorId = await seedCreator();
      await seedOffer(storeId, creatorId, {
        status: 'DECLINED',
        declinedAt: new Date(T0.getTime() - 31 * SECOND),
      });
      const first = (await send({ creatorId, ...REELS_VOUCHER }).expect(201))
        .body as SentBody;
      await cancel(first.id).expect(200);
      await send({ creatorId, ...REELS_VOUCHER }).expect(201);
    });

    it('rejects sending to myself', async () => {
      const res = await send({ creatorId: USER_A, ...REELS_VOUCHER }).expect(
        409,
      );
      expect(codeOf(res)).toBe('CONFLICT');
    });

    it('returns 404 when the recipient has no creator profile', async () => {
      const userId = randomUUID();
      await prisma.user.create({ data: { id: userId, role: 'CREATOR' } });
      await send({ creatorId: userId, ...REELS_VOUCHER }).expect(404);
      await send({ creatorId: randomUUID(), ...REELS_VOUCHER }).expect(404);
    });

    it('only lets one of two concurrent sends to the same creator win', async () => {
      const creatorId = await seedCreator();
      const applicationId = await seedApplication(storeId, creatorId);
      const results = await Promise.all([
        send({ creatorId, ...REELS_VOUCHER }),
        send({ creatorId, ...REELS_VOUCHER }),
      ]);
      expect(results.map((r) => r.status).sort()).toEqual([201, 409]);
      expect(await prisma.offer.count()).toBe(1);
      const offer = await prisma.offer.findFirstOrThrow();
      const application = await prisma.application.findUniqueOrThrow({
        where: { id: applicationId },
      });
      // 지원을 OFFERED로 바꾼 요청이 만들기에서 졌어도 지원이 오퍼 없이 OFFERED로 남지 않는다.
      if (offer.applicationId === applicationId) {
        expect(application.status).toBe('OFFERED');
      } else {
        expect(offer.applicationId).toBeNull();
        expect(application.status).toBe('APPLIED');
      }
    });

    it('puts the applicant back to APPLIED when the create loses the race', async () => {
      const creatorId = await seedCreator();
      const applicationId = await seedApplication(storeId, creatorId);
      // 다른 요청이 먼저 오퍼를 만들어 부분 유니크 위반으로 졌을 때(저장소가 null을 돌려준다).
      const create = jest
        .spyOn(app.get(OffersRepository), 'create')
        .mockResolvedValueOnce(null);
      await send({ creatorId, ...REELS_VOUCHER }).expect(409);
      create.mockRestore();

      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: applicationId },
          })
        ).status,
      ).toBe('APPLIED');
      // 지원자는 다시 지원자 목록에 보이고 오퍼를 보낼 수 있다.
      await send({ creatorId, ...REELS_VOUCHER }).expect(201);
    });

    it('notifies the creator with the canvas wording when an offer is sent', async () => {
      await prisma.store.update({
        where: { id: storeId },
        data: { name: '한그릇 라멘', coverPhotoPath: 'stores/ramen.jpg' },
      });
      const creatorId = await seedCreator();
      const res = await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      const offerId = (res.body as SentBody).id;

      expect(push.sent).toEqual([
        {
          userId: creatorId,
          title: '',
          body: '한그릇 라멘이 릴스 1편 오퍼를 보냈어요.',
          data: {
            notificationId: expect.any(String) as string,
            targetKind: 'OFFER_INBOX',
            targetId: offerId,
            role: 'CREATOR',
          },
        },
      ]);
      // 알림함에도 줄이 생기고, 상대(가게)의 이름과 사진 경로는 사본이다.
      const rows = await prisma.notification.findMany();
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        id: push.sent[0].data?.notificationId,
        userId: creatorId,
        role: 'CREATOR',
        kind: 'OFFER_RECEIVED',
        tab: 'MATCHING',
        params: { format: 'REELS', pieceCount: 1 },
        actorUserId: USER_A,
        actorName: '한그릇 라멘',
        actorPhotoPath: 'stores/ramen.jpg',
        targetKind: 'OFFER_INBOX',
        targetId: offerId,
        dedupeKey: `offer-received:${offerId}`,
        readAt: null,
      });
    });

    it('records the inbox row but does not push when the creator turned offer pushes off', async () => {
      const creatorId = await seedCreator();
      await prisma.notificationSetting.create({
        data: { userId: creatorId, offers: false },
      });
      await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      expect(push.sent).toEqual([]);
      expect(await prisma.notification.count()).toBe(1);
    });

    it('records the inbox row but does not push during quiet hours', async () => {
      // 한국 시간 23:30.
      clock.set(new Date('2026-12-01T14:30:00.000Z'));
      const creatorId = await seedCreator();
      await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      expect(push.sent).toEqual([]);
      expect(await prisma.notification.count()).toBe(1);
    });

    it('keeps the offer when the push fails', async () => {
      push.fail = true;
      const creatorId = await seedCreator();
      await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      push.fail = false;
      expect(await prisma.offer.count()).toBe(1);
      expect(await prisma.notification.count()).toBe(1);
    });

    it('lists sent offers most recent first', async () => {
      const a = await seedCreator('첫째');
      const b = await seedCreator('둘째');
      await seedOffer(storeId, a, {
        createdAt: new Date(T0.getTime() - 2 * DAY),
      });
      await seedOffer(storeId, b, {
        createdAt: new Date(T0.getTime() - DAY),
      });
      const list = (await sentList().expect(200)).body as SentBody[];
      expect(list.map((o) => o.creator.displayName)).toEqual(['둘째', '첫째']);
    });

    it('shows view and payment days left, and settles an expired offer', async () => {
      const waiting = await seedCreator('기다림');
      const accepted = await seedCreator('수락');
      const stale = await seedCreator('만료');
      await seedOffer(storeId, waiting, { createdAt: new Date(T0.getTime()) });
      await seedOffer(storeId, accepted, {
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: new Date(T0.getTime() + 3 * DAY),
      });
      const old = await seedOffer(storeId, stale, {
        expiresAt: new Date(T0.getTime() - SECOND),
      });
      const list = (await sentList().expect(200)).body as SentBody[];
      const byName = Object.fromEntries(
        list.map((o) => [o.creator.displayName, o]),
      );
      expect(byName['기다림']).toMatchObject({
        view: 'WAITING',
        paymentDaysLeft: null,
      });
      expect(byName['수락']).toMatchObject({
        view: 'ACCEPTED',
        paymentDaysLeft: 3,
      });
      expect(byName['만료']).toMatchObject({ view: 'EXPIRED' });
      const row = await prisma.offer.findUniqueOrThrow({
        where: { id: old.id },
      });
      expect(row.status).toBe('EXPIRED');
    });

    it('hides a fresh decline and shows it after 30 seconds', async () => {
      const creatorId = await seedCreator();
      const applicationId = await seedApplication(
        storeId,
        creatorId,
        'OFFERED',
      );
      await seedOffer(storeId, creatorId, {
        status: 'DECLINED',
        applicationId,
        declinedAt: T0,
      });
      const early = (await sentList().expect(200)).body as SentBody[];
      expect(early[0].view).toBe('WAITING');

      clock.advance(30 * SECOND);
      const later = (await sentList().expect(200)).body as SentBody[];
      expect(later[0].view).toBe('DECLINED');
    });

    it('closes the linked application once the decline is final', async () => {
      const creatorId = await seedCreator();
      const applicationId = await seedApplication(
        storeId,
        creatorId,
        'OFFERED',
      );
      await seedOffer(storeId, creatorId, {
        status: 'DECLINED',
        applicationId,
        declinedAt: T0,
      });
      await sentList().expect(200);
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: applicationId },
          })
        ).status,
      ).toBe('OFFERED');

      clock.advance(30 * SECOND);
      await sentList().expect(200);
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: applicationId },
          })
        ).status,
      ).toBe('CLOSED');
    });

    it('cancels a sent offer and closes the linked application', async () => {
      const creatorId = await seedCreator();
      const applicationId = await seedApplication(storeId, creatorId);
      const sent = (await send({ creatorId, ...REELS_VOUCHER }).expect(201))
        .body as SentBody;
      const res = await cancel(sent.id).expect(200);
      expect((res.body as SentBody).view).toBe('CANCELLED');
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: applicationId },
          })
        ).status,
      ).toBe('CLOSED');
      await cancel(sent.id).expect(409);
    });

    it('cancels an accepted offer before payment', async () => {
      const creatorId = await seedCreator();
      const offer = await seedOffer(storeId, creatorId, {
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: new Date(T0.getTime() + 3 * DAY),
      });
      const res = await cancel(offer.id).expect(200);
      expect(res.body as SentBody).toMatchObject({
        view: 'CANCELLED',
        paymentDaysLeft: null,
      });
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('CANCELLED');
    });

    it('cancels the collaboration when the owner cancels an accepted offer', async () => {
      const creatorId = await seedCreator();
      const offer = await seedOffer(storeId, creatorId, {
        rewardType: 'PER_VIEW',
        perViewAmount: 10,
        perViewCap: 100000,
        voucherName: null,
        voucherValue: null,
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: new Date(T0.getTime() + 3 * DAY),
      });
      const collaboration = await seedCollaboration(
        offer,
        USER_A,
        'AWAITING_PAYMENT',
      );
      const res = await cancel(offer.id).expect(200);
      expect((res.body as SentBody).view).toBe('CANCELLED');
      expect(
        (
          await prisma.collaboration.findUniqueOrThrow({
            where: { id: collaboration.id },
          })
        ).stage,
      ).toBe('CANCELLED');
    });

    it('refuses to cancel an accepted offer whose collaboration is already funded', async () => {
      const creatorId = await seedCreator();
      const offer = await seedOffer(storeId, creatorId, {
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: null,
      });
      const collaboration = await seedCollaboration(offer, USER_A, 'FUNDED');
      const res = await cancel(offer.id).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect((res.body as { error: { message: string } }).error.message).toBe(
        '결제한 뒤에는 취소 요청을 보내 주세요.',
      );
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('ACCEPTED');
      expect(
        (
          await prisma.collaboration.findUniqueOrThrow({
            where: { id: collaboration.id },
          })
        ).stage,
      ).toBe('FUNDED');
    });

    it('cancels the collaboration when an accepted offer passes its payment due date', async () => {
      const creatorId = await seedCreator();
      const offer = await seedOffer(storeId, creatorId, {
        rewardType: 'PER_VIEW',
        perViewAmount: 10,
        perViewCap: 100000,
        voucherName: null,
        voucherValue: null,
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: new Date(T0.getTime() + 3 * DAY),
      });
      const collaboration = await seedCollaboration(
        offer,
        USER_A,
        'AWAITING_PAYMENT',
      );
      clock.advance(3 * DAY);
      const list = (await sentList().expect(200)).body as SentBody[];
      expect(list[0]).toMatchObject({
        view: 'EXPIRED',
        collaborationId: collaboration.id,
      });
      expect(
        (
          await prisma.collaboration.findUniqueOrThrow({
            where: { id: collaboration.id },
          })
        ).stage,
      ).toBe('CANCELLED');
    });

    it('shows the collaboration id on sent offers', async () => {
      const creatorId = await seedCreator();
      const offer = await seedOffer(storeId, creatorId, {
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: null,
      });
      const collaboration = await seedCollaboration(offer, USER_A, 'FUNDED');
      const other = await seedCreator('아직 답 없음');
      await seedOffer(storeId, other);
      const list = (await sentList().expect(200)).body as SentBody[];
      const byId = Object.fromEntries(list.map((o) => [o.id, o]));
      expect(byId[offer.id].collaborationId).toBe(collaboration.id);
      expect(list.filter((o) => o.collaborationId === null)).toHaveLength(1);
    });

    it('refuses to cancel an expired offer and stores EXPIRED', async () => {
      const creatorId = await seedCreator();
      const offer = await seedOffer(storeId, creatorId, {
        expiresAt: new Date(T0.getTime() - SECOND),
      });
      await cancel(offer.id).expect(409);
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('EXPIRED');
    });

    it('returns 404 when another store owner cancels my offer', async () => {
      // 이 오퍼는 다른 가게의 것이다. user-a의 가게에서는 보이지 않는다.
      const other = await seedStore();
      const creatorId = await seedCreator();
      const offer = await seedOffer(other.id, creatorId);
      const res = await cancel(offer.id).expect(404);
      expect(codeOf(res)).toBe('NOT_FOUND');
      await cancel('not-a-uuid').expect(404);
      await cancel(randomUUID()).expect(404);
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('SENT');
    });

    it('counts new applications, waiting offers and in-progress collaborations', async () => {
      const applicant = await seedCreator('지원자');
      await seedApplication(storeId, applicant);
      const waiting = await seedCreator('기다림');
      const accepted = await seedCreator('수락');
      const expired = await seedCreator('만료');
      const declined = await seedCreator('거절');
      await seedOffer(storeId, waiting);
      const acceptedOffer = await seedOffer(storeId, accepted, {
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: new Date(T0.getTime() + 3 * DAY),
      });
      await seedCollaboration(acceptedOffer, USER_A, 'AWAITING_PAYMENT');
      await seedOffer(storeId, expired, {
        expiresAt: new Date(T0.getTime() - SECOND),
      });
      await seedOffer(storeId, declined, {
        status: 'DECLINED',
        declinedAt: new Date(T0.getTime() - 60 * SECOND),
      });
      const res = await summary().expect(200);
      expect(res.body as SummaryBody).toEqual({
        newApplications: 1,
        sentOffers: 1,
        inProgress: 1,
      });
    });

    it('counts AWAITING_PAYMENT, FUNDED and COUNTING as in progress', async () => {
      const stages: CollaborationStage[] = [
        'AWAITING_PAYMENT',
        'FUNDED',
        'COUNTING',
        'SETTLED',
        'REFUNDED',
        'CANCELLED',
        'HALTED',
      ];
      for (const stage of stages) {
        const creatorId = await seedCreator(`협업 ${stage}`);
        const offer = await seedOffer(storeId, creatorId, {
          status: 'ACCEPTED',
          acceptedAt: T0,
        });
        await seedCollaboration(offer, USER_A, stage);
      }
      // 남의 가게의 진행 중 협업은 세지 않는다.
      const other = await seedStore();
      const otherCreator = await seedCreator('남의 협업');
      const otherOffer = await seedOffer(other.id, otherCreator, {
        status: 'ACCEPTED',
        acceptedAt: T0,
      });
      await seedCollaboration(otherOffer, other.ownerId, 'FUNDED');
      expect((await summary().expect(200)).body).toMatchObject({
        inProgress: 3,
      });
    });

    it('counts an undoable decline as a waiting offer', async () => {
      const creatorId = await seedCreator();
      await seedOffer(storeId, creatorId, {
        status: 'DECLINED',
        declinedAt: T0,
      });
      expect((await summary().expect(200)).body).toMatchObject({
        sentOffers: 1,
      });
    });

    it('keeps GET /stores/me/summary from being read as a store id', async () => {
      const res = await summary().expect(200);
      expect(res.body as SummaryBody).toEqual({
        newApplications: 0,
        sentOffers: 0,
        inProgress: 0,
      });
    });

    it('forbids creator-only actions', async () => {
      await received('new').expect(403);
      await accept(randomUUID()).expect(403);
      await decline(randomUUID()).expect(403);
      await undo(randomUUID()).expect(403);
    });
  });

  describe('as a store owner without a published store', () => {
    it('rejects sending from an unpublished store', async () => {
      await setRole('STORE');
      await request(server)
        .post('/stores/me/analyze')
        .set(auth)
        .send({ links: LINKS })
        .expect(200);
      const creatorId = await seedCreator();
      const res = await send({ creatorId, ...REELS_VOUCHER }).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
    });

    it('returns 404 when there is no store at all', async () => {
      await setRole('STORE');
      const creatorId = await seedCreator();
      await send({ creatorId, ...REELS_VOUCHER }).expect(404);
    });

    it('forbids store-only actions for a creator', async () => {
      await setRole('CREATOR');
      const creatorId = await seedCreator();
      await send({ creatorId, ...REELS_VOUCHER }).expect(403);
      await sentList().expect(403);
      await cancel(randomUUID()).expect(403);
      await summary().expect(403);
    });
  });

  describe('as a creator', () => {
    let store: { id: string; ownerId: string };
    beforeEach(async () => {
      await setRole('CREATOR');
      await putProfile();
      store = await seedStore();
    });

    it('lists new offers in arrival order with the store card', async () => {
      const older = await seedStore();
      await seedOffer(store.id, USER_A, {
        createdAt: new Date(T0.getTime() - DAY),
      });
      await seedOffer(older.id, USER_A, {
        createdAt: new Date(T0.getTime() - 2 * DAY),
      });
      const list = (await received('new').expect(200)).body as ReceivedBody[];
      expect(list.map((o) => o.store.id)).toEqual([older.id, store.id]);
      expect(list[1]).toMatchObject({
        store: { name: '남의 가게' },
        storeIntro: '성수동의 작은 카페예요.',
        bestShootingTime: '오후 2시',
        view: 'WAITING',
        canUndoDecline: false,
        receivedAt: new Date(T0.getTime() - DAY).toISOString(),
      });
      expect(list[1].terms).toMatchObject({
        format: 'REELS',
        rewardType: 'VOUCHER',
      });
    });

    it('keeps accepted offers out of new and in active', async () => {
      const waiting = await seedOffer(store.id, USER_A);
      const other = await seedStore();
      const accepted = await seedOffer(other.id, USER_A, {
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: new Date(T0.getTime() + 3 * DAY),
      });
      const news = (await received('new').expect(200)).body as ReceivedBody[];
      const active = (await received('active').expect(200))
        .body as ReceivedBody[];
      expect(news.map((o) => o.id)).toEqual([waiting.id]);
      expect(active.map((o) => o.id)).toEqual([accepted.id]);
      expect(active[0].view).toBe('ACCEPTED');
    });

    it('shows an undoable decline in new and drops it after 30 seconds', async () => {
      const offer = await seedOffer(store.id, USER_A, {
        status: 'DECLINED',
        declinedAt: T0,
      });
      const early = (await received('new').expect(200)).body as ReceivedBody[];
      expect(early).toHaveLength(1);
      expect(early[0]).toMatchObject({
        id: offer.id,
        view: 'DECLINED',
        canUndoDecline: true,
      });
      clock.advance(30 * SECOND);
      expect((await received('new').expect(200)).body).toEqual([]);
    });

    it('settles an expired offer when listing and closes its application', async () => {
      const applicationId = await seedApplication(store.id, USER_A, 'OFFERED');
      const offer = await seedOffer(store.id, USER_A, {
        applicationId,
        expiresAt: new Date(T0.getTime() - SECOND),
      });
      expect((await received('new').expect(200)).body).toEqual([]);
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('EXPIRED');
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: applicationId },
          })
        ).status,
      ).toBe('CLOSED');
    });

    it('rejects an unknown tab', async () => {
      await received('other').expect(400);
      await request(server).get('/offers/received').set(auth).expect(400);
    });

    it('marks a per-view reels offer as needing instagram', async () => {
      const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
      const list = (await received('new').expect(200)).body as ReceivedBody[];
      expect(list.map((o) => [o.id, o.needsInstagram])).toEqual([
        [offer.id, true],
      ]);
    });

    it('refuses to accept a per-view reels offer without a connection', async () => {
      const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
      const res = await accept(offer.id).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect((res.body as { error: { message: string } }).error.message).toBe(
        '인스타그램을 연동하면 수락할 수 있어요.',
      );
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('SENT');
      expect(await prisma.collaboration.count()).toBe(0);
    });

    it('accepts the same offer after connecting', async () => {
      const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
      await connectInstagram();
      const list = (await received('new').expect(200)).body as ReceivedBody[];
      expect(list[0].needsInstagram).toBe(false);
      const res = await accept(offer.id).expect(200);
      expect(res.body as ReceivedBody).toMatchObject({
        view: 'ACCEPTED',
        needsInstagram: false,
      });
    });

    it('stops flagging an accepted offer after the creator disconnects', async () => {
      const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
      await connectInstagram();
      await accept(offer.id).expect(200);
      // 결제를 기다리는 동안에는 해제할 수 없으므로 DB에서 풀린 상태를 만든다.
      await prisma.instagramConnection.deleteMany();
      const active = (await received('active').expect(200))
        .body as ReceivedBody[];
      expect(active.map((o) => [o.view, o.needsInstagram])).toEqual([
        ['ACCEPTED', false],
      ]);
    });

    it('does not require instagram for a voucher-only offer or a shorts offer', async () => {
      const voucher = await seedOffer(store.id, USER_A);
      const other = await seedStore();
      const shorts = await seedOffer(other.id, USER_A, {
        ...PER_VIEW_TERMS,
        format: 'SHORTS',
      });
      const list = (await received('new').expect(200)).body as ReceivedBody[];
      expect(list.map((o) => o.needsInstagram)).toEqual([false, false]);
      await accept(voucher.id).expect(200);
      await accept(shorts.id).expect(200);
    });

    it('requires instagram for a card-news offer with both rewards', async () => {
      const offer = await seedOffer(store.id, USER_A, {
        ...PER_VIEW_TERMS,
        format: 'CARD_NEWS',
        rewardType: 'BOTH',
        voucherName: '2인 식사권',
        voucherValue: 40000,
      });
      await accept(offer.id).expect(409);
      await connectInstagram();
      await accept(offer.id).expect(200);
    });

    it('accepts an offer and sets a 3 day payment deadline', async () => {
      await connectInstagram();
      const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
      clock.advance(DAY);
      const res = await accept(offer.id).expect(200);
      expect(res.body as ReceivedBody).toMatchObject({
        id: offer.id,
        view: 'ACCEPTED',
        canUndoDecline: false,
      });
      const row = await prisma.offer.findUniqueOrThrow({
        where: { id: offer.id },
      });
      expect(row).toMatchObject({
        status: 'ACCEPTED',
        acceptedAt: clock.now(),
        paymentDueAt: new Date(clock.now().getTime() + 3 * DAY),
      });
    });

    it('creates an AWAITING_PAYMENT collaboration when a per-view offer is accepted', async () => {
      await connectInstagram();
      const offer = await seedOffer(store.id, USER_A, {
        ...PER_VIEW_TERMS,
        rewardType: 'BOTH',
        voucherName: '2인 식사권',
        voucherValue: 40000,
      });
      const res = await accept(offer.id).expect(200);
      const collaboration = await prisma.collaboration.findUniqueOrThrow({
        where: { offerId: offer.id },
      });
      expect(collaboration).toMatchObject({
        kind: 'STORE_OFFER',
        stage: 'AWAITING_PAYMENT',
        settlementMethod: 'PER_VIEW',
        commissionerId: store.ownerId,
        creatorId: USER_A,
        storeId: store.id,
        fundedAt: null,
        submitDueAt: null,
      });
      expect(collaboration.terms).toMatchObject({
        format: 'REELS',
        rewardType: 'BOTH',
        perViewAmount: 10,
        perViewCap: 100000,
        voucherName: '2인 식사권',
      });
      expect((res.body as ReceivedBody).collaborationId).toBe(collaboration.id);
      const list = (await received('active').expect(200))
        .body as ReceivedBody[];
      expect(list[0].collaborationId).toBe(collaboration.id);
    });

    it('creates a FUNDED collaboration with a 14 day due date when a voucher-only offer is accepted', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await accept(offer.id).expect(200);
      const collaboration = await prisma.collaboration.findUniqueOrThrow({
        where: { offerId: offer.id },
      });
      expect(collaboration).toMatchObject({
        stage: 'FUNDED',
        settlementMethod: 'NONE',
        fundedAt: T0,
        submitDueAt: new Date(T0.getTime() + 14 * DAY),
      });
      // 낼 돈이 없으므로 결제 기한이 없다. 며칠이 지나도 오퍼가 만료되지 않는다.
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .paymentDueAt,
      ).toBeNull();
      clock.advance(5 * DAY);
      const active = (await received('active').expect(200))
        .body as ReceivedBody[];
      expect(active.map((o) => o.id)).toEqual([offer.id]);
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('ACCEPTED');
    });

    it('creates no collaboration when the accept loses the race', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await Promise.all([accept(offer.id), accept(offer.id)]);
      expect(
        await prisma.collaboration.count({ where: { offerId: offer.id } }),
      ).toBe(1);
    });

    it('notifies the store owner on accept', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await accept(offer.id).expect(200);
      const collaboration = await prisma.collaboration.findUniqueOrThrow({
        where: { offerId: offer.id },
      });
      // 식사권만 있는 오퍼는 바로 FUNDED라 결제 화면이 아니라 협업 화면으로 보낸다.
      expect(push.sent).toEqual([
        {
          userId: store.ownerId,
          title: '',
          body: '하루 한 컵님이 오퍼를 수락했어요.',
          data: {
            notificationId: expect.any(String) as string,
            targetKind: 'COLLABORATION',
            targetId: collaboration.id,
            role: 'STORE',
          },
        },
      ]);
      expect(await prisma.notification.findFirstOrThrow()).toMatchObject({
        userId: store.ownerId,
        role: 'STORE',
        kind: 'OFFER_ACCEPTED',
        tab: 'MATCHING',
        actorUserId: USER_A,
        actorName: '하루 한 컵',
        dedupeKey: `offer-accepted:${offer.id}`,
      });
    });

    it('sends the store owner to payment when the accepted offer awaits payment', async () => {
      await connectInstagram();
      const offer = await seedOffer(store.id, USER_A, {
        rewardType: 'PER_VIEW',
        voucherName: null,
        voucherValue: null,
        perViewAmount: 10,
        perViewCap: 100000,
      });
      await accept(offer.id).expect(200);
      const collaboration = await prisma.collaboration.findUniqueOrThrow({
        where: { offerId: offer.id },
      });
      expect(collaboration.stage).toBe('AWAITING_PAYMENT');
      expect(push.sent[0].data).toMatchObject({
        targetKind: 'PAYMENT',
        targetId: collaboration.id,
      });
    });

    it('refuses to accept an expired offer and stores EXPIRED', async () => {
      const applicationId = await seedApplication(store.id, USER_A, 'OFFERED');
      const offer = await seedOffer(store.id, USER_A, {
        applicationId,
        expiresAt: new Date(T0.getTime() - SECOND),
      });
      const res = await accept(offer.id).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('EXPIRED');
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: applicationId },
          })
        ).status,
      ).toBe('CLOSED');
      expect(push.sent).toEqual([]);
    });

    it('refuses to respond to an offer that is already handled', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await accept(offer.id).expect(200);
      await accept(offer.id).expect(409);
      await decline(offer.id).expect(409);
      await undo(offer.id).expect(409);
    });

    it('lets only one of two concurrent responses win', async () => {
      const offer = await seedOffer(store.id, USER_A);
      const results = await Promise.all([accept(offer.id), decline(offer.id)]);
      expect(results.map((r) => r.status).sort()).toEqual([200, 409]);
      const row = await prisma.offer.findUniqueOrThrow({
        where: { id: offer.id },
      });
      expect(['ACCEPTED', 'DECLINED']).toContain(row.status);
    });

    it('declines, then undoes within 30 seconds', async () => {
      const offer = await seedOffer(store.id, USER_A);
      const declined = await decline(offer.id).expect(200);
      expect(declined.body as ReceivedBody).toMatchObject({
        view: 'DECLINED',
        canUndoDecline: true,
      });
      expect(push.sent).toEqual([]);

      clock.advance(29 * SECOND);
      const undone = await undo(offer.id).expect(200);
      expect(undone.body as ReceivedBody).toMatchObject({
        view: 'WAITING',
        canUndoDecline: false,
      });
      const row = await prisma.offer.findUniqueOrThrow({
        where: { id: offer.id },
      });
      expect(row).toMatchObject({ status: 'SENT', declinedAt: null });
    });

    it('refuses undo after 30 seconds', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await decline(offer.id).expect(200);
      clock.advance(30 * SECOND);
      const res = await undo(offer.id).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('DECLINED');
    });

    it('closes the linked application once the decline is final', async () => {
      const applicationId = await seedApplication(store.id, USER_A, 'OFFERED');
      const offer = await seedOffer(store.id, USER_A, { applicationId });
      await decline(offer.id).expect(200);
      // 거절 직후에는 지원이 그대로다(되돌릴 수 있다).
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: applicationId },
          })
        ).status,
      ).toBe('OFFERED');

      clock.advance(30 * SECOND);
      await received('new').expect(200);
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: applicationId },
          })
        ).status,
      ).toBe('CLOSED');
      // 다시 지원할 수 있다.
      await request(server)
        .post(`/stores/${store.id}/applications`)
        .set(auth)
        .send()
        .expect(201);
    });

    it("returns 404 for another creator's offer", async () => {
      const other = await seedCreator();
      const offer = await seedOffer(store.id, other);
      for (const act of [accept, decline, undo]) {
        const res = await act(offer.id).expect(404);
        expect(codeOf(res)).toBe('NOT_FOUND');
      }
      await accept('not-a-uuid').expect(404);
      await accept(randomUUID()).expect(404);
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('SENT');
    });

    it('forbids store-only actions', async () => {
      await send({ creatorId: randomUUID(), ...REELS_VOUCHER }).expect(403);
    });

    describe('scheduled jobs', () => {
      const offerRow = (id: string) =>
        prisma.offer.findUniqueOrThrow({ where: { id } });

      it('notifies the owner 30 seconds after a decline and closes the linked application', async () => {
        const applicationId = await seedApplication(
          store.id,
          USER_A,
          'OFFERED',
        );
        const offer = await seedOffer(store.id, USER_A, { applicationId });
        await decline(offer.id).expect(200);
        expect(scheduler.pending()).toMatchObject([
          {
            name: 'decline-notice',
            jobKey: `decline:${offer.id}:${T0.getTime()}`,
          },
        ]);

        await scheduler.runDue(new Date(clock.now().getTime() + 29 * SECOND));
        expect(await prisma.notification.count()).toBe(0);

        clock.advance(30 * SECOND);
        await scheduler.runDue(clock.now());
        expect(await prisma.notification.findFirstOrThrow()).toMatchObject({
          userId: store.ownerId,
          role: 'STORE',
          kind: 'OFFER_DECLINED',
          actorUserId: USER_A,
          actorName: PROFILE.displayName,
          targetKind: 'STORE_SENT_OFFERS',
          targetId: null,
          dedupeKey: `decline:${offer.id}`,
        });
        expect(
          (
            await prisma.application.findUniqueOrThrow({
              where: { id: applicationId },
            })
          ).status,
        ).toBe('CLOSED');
      });

      it('does not notify when the decline was undone, even if the job runs', async () => {
        const offer = await seedOffer(store.id, USER_A);
        await decline(offer.id).expect(200);
        clock.advance(10 * SECOND);
        await undo(offer.id).expect(200);
        expect(scheduler.pending()).toEqual([]);

        // 취소가 실패해 작업이 남은 경우를 흉내 낸다: 처리기가 오퍼의 현재 상태를 보고 아무것도 하지 않는다.
        await scheduler.schedule(
          'decline-notice',
          { offerId: offer.id, declinedAt: T0.toISOString() },
          clock.now(),
          'stale',
        );
        clock.advance(30 * SECOND);
        await scheduler.runDue(clock.now());
        expect(await prisma.notification.count()).toBe(0);
        expect((await offerRow(offer.id)).status).toBe('SENT');
      });

      it('notifies once at the second deadline when the undo could not cancel the first job', async () => {
        const offer = await seedOffer(store.id, USER_A);
        await decline(offer.id).expect(200);
        clock.advance(10 * SECOND);
        jest
          .spyOn(scheduler, 'cancel')
          .mockRejectedValueOnce(new Error('redis'));
        await undo(offer.id).expect(200);
        clock.advance(10 * SECOND);
        await decline(offer.id).expect(200);
        expect(scheduler.pending()).toHaveLength(2);

        clock.set(new Date(T0.getTime() + 30 * SECOND));
        await scheduler.runDue(clock.now());
        expect(await prisma.notification.count()).toBe(0);

        clock.set(new Date(T0.getTime() + 50 * SECOND));
        await scheduler.runDue(clock.now());
        expect(await prisma.notification.count()).toBe(1);
      });

      it('sends one notice when the decline notice job runs twice', async () => {
        const offer = await seedOffer(store.id, USER_A);
        await decline(offer.id).expect(200);
        clock.advance(30 * SECOND);
        await scheduler.runDue(clock.now());
        await scheduler.schedule(
          'decline-notice',
          { offerId: offer.id, declinedAt: T0.toISOString() },
          clock.now(),
          'again',
        );
        await scheduler.runDue(clock.now());
        expect(await prisma.notification.count()).toBe(1);
      });

      it('expires an unpaid accepted offer and cancels its collaboration at the due time', async () => {
        await connectInstagram();
        const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
        await accept(offer.id).expect(200);
        const due = new Date(T0.getTime() + 3 * DAY);
        expect(scheduler.pending()).toMatchObject([
          {
            name: 'payment-due-expiry',
            runAt: due,
            jobKey: `payment-due:${offer.id}`,
          },
        ]);

        await scheduler.runDue(new Date(due.getTime() - SECOND));
        expect((await offerRow(offer.id)).status).toBe('ACCEPTED');

        clock.set(due);
        await scheduler.runDue(clock.now());
        expect((await offerRow(offer.id)).status).toBe('EXPIRED');
        expect(
          (
            await prisma.collaboration.findUniqueOrThrow({
              where: { offerId: offer.id },
            })
          ).stage,
        ).toBe('CANCELLED');
      });

      it('does nothing when the offer was paid before the due time', async () => {
        await connectInstagram();
        const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
        await accept(offer.id).expect(200);
        // 결제가 승인되면 협업은 FUNDED가 되고 오퍼의 결제 기한이 지워진다.
        await prisma.collaboration.update({
          where: { offerId: offer.id },
          data: { stage: 'FUNDED', fundedAt: clock.now() },
        });
        await prisma.offer.update({
          where: { id: offer.id },
          data: { paymentDueAt: null },
        });
        clock.advance(3 * DAY);
        await scheduler.runDue(clock.now());
        expect((await offerRow(offer.id)).status).toBe('ACCEPTED');
        expect(
          (
            await prisma.collaboration.findUniqueOrThrow({
              where: { offerId: offer.id },
            })
          ).stage,
        ).toBe('FUNDED');
      });

      it('does nothing when run twice', async () => {
        await connectInstagram();
        const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
        await accept(offer.id).expect(200);
        clock.advance(3 * DAY);
        await scheduler.runDue(clock.now());
        await scheduler.schedule(
          'payment-due-expiry',
          { offerId: offer.id },
          clock.now(),
          'again',
        );
        await scheduler.runDue(clock.now());
        expect((await offerRow(offer.id)).status).toBe('EXPIRED');
        expect(
          (
            await prisma.collaboration.findUniqueOrThrow({
              where: { offerId: offer.id },
            })
          ).stage,
        ).toBe('CANCELLED');
      });
    });
  });
});
