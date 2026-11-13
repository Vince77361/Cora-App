import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { CollaborationStage, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { PushPort } from '../src/integrations/push/push.port';
import { JobScheduler } from '../src/jobs/job-scheduler';
import { NotificationsService } from '../src/notifications/notifications.service';
import { OffersRepository } from '../src/offers/offers.repository';
import {
  addVersion,
  createOffer,
  type TestOfferInput,
} from './helpers/create-offer';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { FakeJobScheduler } from './support/fake-job-scheduler';
import { FakePushPort } from './support/fake-push.port';
import { OTHER, USER_A } from './support/fake-token-verifier';

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
const REELS_VOUCHER = { format: 'REELS', reward: { voucher: {} } };
// 조회수 보상만 있는 오퍼를 DB에 바로 만들 때 쓰는 값.
const PER_VIEW_TERMS = {
  voucherName: null,
  voucherValue: null,
  voucherPeople: null,
  viewRatePerThousand: 2000,
  perViewCap: 60000,
} as const;

interface TermsBody {
  format: string;
  pieces: number;
  voucherName: string | null;
  voucherValue: number | null;
  voucherPeople: number | null;
  fixedCash: number;
  viewRatePerThousand: number | null;
  perViewCap: number | null;
  usageRights: string;
  maxCashBurden: number;
  settlementMethod: string;
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
  const accept = (id: string, version: number | null = 1) =>
    request(server)
      .post(`/offers/${id}/accept`)
      .set(auth)
      .send(version === null ? {} : { version });
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
        defaultVoucherName: '식사권',
        defaultVoucherValue: 40000,
        defaultVoucherPeople: 2,
        publishedAt: T0,
      },
    });
    return { id: store.id, ownerId };
  }

  // 시계를 기준으로 오퍼를 DB에 바로 만든다.
  function seedOffer(
    storeId: string,
    creatorId: string,
    over: Partial<TestOfferInput> = {},
  ) {
    return createOffer(prisma, {
      storeId,
      creatorId,
      format: 'REELS',
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      status: 'SENT',
      expiresAt: new Date(clock.now().getTime() + 7 * DAY),
      createdAt: clock.now(),
      ...over,
    });
  }

  // 오퍼에 연결된 협업을 DB에 바로 만든다. 가게 사장님이 USER_A인 경우가 기본이다.
  async function seedCollaboration(
    offer: {
      id: string;
      storeId: string;
      creatorId: string;
      viewRatePerThousand: number | null;
      perViewCap: number | null;
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
        terms: {
          format: 'REELS',
          pieces: 1,
          fixedCash: 0,
          viewRatePerThousand: offer.viewRatePerThousand,
          perViewCap: offer.perViewCap,
        },
        settlementMethod: offer.perViewCap === null ? 'NONE' : 'PER_VIEW',
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
    await request(server).post(`/offers/${randomUUID()}/versions`).expect(401);
    await request(server).post(`/offers/${randomUUID()}/end`).expect(401);
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
        pieces: 1,
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        fixedCash: 0,
        viewRatePerThousand: null,
        perViewCap: null,
        usageRights: 'STORE_REPOST_3M',
        maxCashBurden: 0,
        settlementMethod: 'NONE',
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

    it('creates version 1 written by the store when an offer is sent', async () => {
      const creatorId = await seedCreator();
      const res = await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      const body = res.body as SentBody & { version: number; myTurn: boolean };
      // 처음 보낸 사장님은 답을 기다리는 쪽이라 내 차례가 아니다.
      expect(body).toMatchObject({ version: 1, myTurn: false });
      const offer = await prisma.offer.findUniqueOrThrow({
        where: { id: body.id },
        include: { versions: true },
      });
      expect(offer).toMatchObject({
        latestVersion: 1,
        turn: 'CREATOR',
        initiatedBy: 'STORE',
        endReason: null,
        endedBy: null,
      });
      expect(offer.versions).toHaveLength(1);
      expect(offer.versions[0]).toMatchObject({
        number: 1,
        authorParty: 'STORE',
        format: 'REELS',
        pieces: 1,
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        fixedCash: 0,
        viewRatePerThousand: null,
        perViewCap: null,
        usageRights: 'STORE_REPOST_3M',
        idea: null,
        principles: [],
        seriesName: null,
        createdAt: T0,
      });
    });

    it('sends an offer to a creator who never applied', async () => {
      const creatorId = await seedCreator();
      const res = await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      const offer = await prisma.offer.findUniqueOrThrow({
        where: { id: (res.body as SentBody).id },
      });
      expect(offer.applicationId).toBeNull();
    });

    it('sends an offer with the store default view pay when values are omitted', async () => {
      // 가게의 모집 조건: 1,000회당 3,000원, 상한 100,000원, 사용권 6개월.
      await request(server)
        .put('/stores/me/default-terms')
        .set(auth)
        .send({
          format: 'REELS',
          reward: {
            voucher: {},
            perView: { ratePerThousand: 3000, cap: 100000 },
          },
          usageRights: 'STORE_REPOST_6M',
        })
        .expect(200);
      const creatorId = await seedCreator();
      const res = await send({
        creatorId,
        format: 'REELS',
        reward: { perView: {} },
      }).expect(201);
      expect((res.body as SentBody).terms).toMatchObject({
        voucherName: null,
        fixedCash: 0,
        viewRatePerThousand: 3000,
        perViewCap: 100000,
        usageRights: 'STORE_REPOST_6M',
        maxCashBurden: 100000,
        settlementMethod: 'PER_VIEW',
      });
      // 값을 주면 가게의 기본값보다 먼저다.
      const other = await seedCreator('다른 사람');
      const given = await send({
        creatorId: other,
        format: 'REELS',
        reward: { perView: { ratePerThousand: 1500, cap: 30000 } },
        usageRights: 'NONE',
      }).expect(201);
      expect((given.body as SentBody).terms).toMatchObject({
        viewRatePerThousand: 1500,
        perViewCap: 30000,
        usageRights: 'NONE',
        maxCashBurden: 30000,
      });
    });

    it('rejects a rate outside the allowed range', async () => {
      const creatorId = await seedCreator();
      for (const reward of [
        { perView: { ratePerThousand: 10000 } },
        { perView: { ratePerThousand: 1250 } },
        { perView: { cap: 5000 } },
        { perView: { cap: 15000 } },
      ]) {
        const res = await send({ creatorId, format: 'REELS', reward }).expect(
          400,
        );
        expect(codeOf(res)).toBe('VALIDATION_FAILED');
      }
      expect(await prisma.offer.count()).toBe(0);
    });

    it('sends an offer with fixed cash and view pay together', async () => {
      const creatorId = await seedCreator();
      const res = await send({
        creatorId,
        format: 'REELS',
        reward: {
          voucher: {},
          fixedCash: 30000,
          perView: { ratePerThousand: 2000, cap: 60000 },
        },
      }).expect(201);
      const body = res.body as SentBody;
      expect(body.terms).toMatchObject({
        voucherName: '식사권',
        fixedCash: 30000,
        viewRatePerThousand: 2000,
        perViewCap: 60000,
        maxCashBurden: 90000,
        settlementMethod: 'FIXED_AND_PER_VIEW',
      });
      expect(
        await prisma.offerVersion.findFirstOrThrow({
          where: { offerId: body.id, number: 1 },
        }),
      ).toMatchObject({ fixedCash: 30000, perViewCap: 60000 });
    });

    it('sends an offer with fixed cash only', async () => {
      const creatorId = await seedCreator();
      const res = await send({
        creatorId,
        format: 'REELS',
        reward: { fixedCash: 30000 },
      }).expect(201);
      expect((res.body as SentBody).terms).toMatchObject({
        voucherName: null,
        fixedCash: 30000,
        viewRatePerThousand: null,
        perViewCap: null,
        maxCashBurden: 30000,
        settlementMethod: 'FIXED',
      });
    });

    it('rejects fixed cash outside the range or the unit', async () => {
      const creatorId = await seedCreator();
      for (const fixedCash of [5000, 35000, 1010000, 10000000, -10000]) {
        const res = await send({
          creatorId,
          format: 'REELS',
          reward: { voucher: {}, fixedCash },
        }).expect(400);
        expect(codeOf(res)).toBe('VALIDATION_FAILED');
      }
      expect(await prisma.offer.count()).toBe(0);
    });

    it('copies terms so later default changes do not affect it', async () => {
      const creatorId = await seedCreator();
      await send({
        creatorId,
        format: 'REELS',
        reward: {
          voucher: { name: '커피 쿠폰', value: 12000 },
          perView: {},
        },
      }).expect(201);
      await request(server)
        .put('/stores/me/default-terms')
        .set(auth)
        .send({ format: 'SHORTS', reward: { perView: { cap: 100000 } } })
        .expect(200);

      const list = (await sentList().expect(200)).body as SentBody[];
      expect(list).toHaveLength(1);
      expect(list[0].terms).toEqual({
        format: 'REELS',
        pieces: 1,
        voucherName: '커피 쿠폰',
        voucherValue: 12000,
        voucherPeople: 2,
        fixedCash: 0,
        viewRatePerThousand: 2000,
        perViewCap: 60000,
        usageRights: 'STORE_REPOST_3M',
        maxCashBurden: 60000,
        settlementMethod: 'PER_VIEW',
      });
    });

    it('rejects a blog offer with a per-view reward', async () => {
      const creatorId = await seedCreator();
      const res = await send({
        creatorId,
        format: 'BLOG',
        reward: { perView: {} },
      }).expect(400);
      expect(codeOf(res)).toBe('VALIDATION_FAILED');
      expect(await prisma.offer.count()).toBe(0);
    });

    it('rejects a malformed body', async () => {
      await send({ creatorId: 'nope', ...REELS_VOUCHER }).expect(400);
      await send({
        creatorId: randomUUID(),
        format: 'X',
        reward: { voucher: {} },
      }).expect(400);
      // 옛 모양(rewardType)은 받지 않는다.
      await send({
        creatorId: randomUUID(),
        format: 'REELS',
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
        ...PER_VIEW_TERMS,
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
        ...PER_VIEW_TERMS,
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
      // 사장님도 수락한다: 내 오퍼가 아니면 404이고, 거절·되돌리기는 크리에이터만 쓴다.
      await accept(randomUUID()).expect(404);
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

  // 사장님은 user-a, 크리에이터는 user-b다. 양쪽이 판본을 주고받는다.
  describe('with versions', () => {
    const authB = { Authorization: 'Bearer user-b' };
    const STORE_VERSION = {
      format: 'REELS',
      reward: { voucher: {}, fixedCash: 30000 },
    };
    let storeId: string;
    let offerId: string;

    const post = (
      headers: Record<string, string>,
      path: string,
      body: Record<string, unknown> = {},
    ) => request(server).post(path).set(headers).send(body);
    const propose = (
      headers: Record<string, string>,
      id: string,
      body: Record<string, unknown> = STORE_VERSION,
    ) => post(headers, `/offers/${id}/versions`, body);
    const acceptAs = (
      headers: Record<string, string>,
      id: string,
      version: number,
    ) => post(headers, `/offers/${id}/accept`, { version });
    const endAs = (
      headers: Record<string, string>,
      id: string,
      reason = 'SCHEDULE',
    ) => post(headers, `/offers/${id}/end`, { reason });
    const offerRow = (id: string) =>
      prisma.offer.findUniqueOrThrow({ where: { id } });
    const versionCount = (id: string) =>
      prisma.offerVersion.count({ where: { offerId: id } });

    beforeEach(async () => {
      storeId = await publishMine();
      await prisma.user.create({ data: { id: OTHER, role: 'CREATOR' } });
      await prisma.creatorProfile.create({
        data: { userId: OTHER, displayName: '하루 한 컵', ...REGION },
      });
      offerId = (await seedOffer(storeId, OTHER)).id;
    });

    it('lets the creator answer a store offer with version 2 and passes the turn to the store', async () => {
      const res = await propose(authB, offerId, {
        ...STORE_VERSION,
        idea: '아침 햇살 속 한 컵 릴스',
        principles: ['광고 티 안 내기'],
      }).expect(201);
      expect(res.body).toMatchObject({
        number: 2,
        authorParty: 'CREATOR',
        idea: '아침 햇살 속 한 컵 릴스',
        principles: ['광고 티 안 내기'],
        terms: {
          fixedCash: 30000,
          voucherName: '식사권',
          maxCashBurden: 30000,
        },
      });
      expect(await offerRow(offerId)).toMatchObject({
        latestVersion: 2,
        turn: 'STORE',
        status: 'SENT',
      });
      expect(await versionCount(offerId)).toBe(2);
    });

    it('lets the store send version 3 back after the creator version', async () => {
      await propose(authB, offerId).expect(201);
      const res = await propose(auth, offerId, {
        format: 'REELS',
        reward: { voucher: {}, fixedCash: 20000 },
        idea: '사장님이 보내도 저장하지 않아요',
        principles: ['무시돼요'],
      }).expect(201);
      expect(res.body).toMatchObject({
        number: 3,
        authorParty: 'STORE',
        idea: null,
        principles: [],
        terms: { fixedCash: 20000 },
      });
      expect(await offerRow(offerId)).toMatchObject({
        latestVersion: 3,
        turn: 'CREATOR',
      });
    });

    it('ignores idea and principles sent by the store', async () => {
      await addVersion(prisma, offerId, 'CREATOR', {
        idea: '크리에이터의 생각',
      });
      await propose(auth, offerId, {
        ...STORE_VERSION,
        idea: '사장님의 생각',
        principles: ['사장님 원칙'],
      }).expect(201);
      const row = await prisma.offerVersion.findFirstOrThrow({
        where: { offerId, number: 3 },
      });
      expect(row).toMatchObject({ idea: null, principles: [] });
    });

    it('restarts the 7 day response window with each new version', async () => {
      clock.advance(2 * DAY);
      await propose(authB, offerId).expect(201);
      const secondDeadline = new Date(T0.getTime() + 9 * DAY);
      expect((await offerRow(offerId)).expiresAt).toEqual(secondDeadline);
      expect(scheduler.pending()).toMatchObject([
        {
          name: 'offer-response-expiry',
          payload: { offerId, version: 2 },
          runAt: secondDeadline,
          jobKey: `offer-expiry:${offerId}:2`,
        },
      ]);
      clock.advance(3 * DAY);
      await propose(auth, offerId).expect(201);
      expect((await offerRow(offerId)).expiresAt).toEqual(
        new Date(T0.getTime() + 12 * DAY),
      );
    });

    it('schedules the response expiry of version 1 when an offer is sent', async () => {
      await prisma.offerVersion.deleteMany({ where: { offerId } });
      await prisma.offer.delete({ where: { id: offerId } });
      const res = await send({ creatorId: OTHER, ...REELS_VOUCHER }).expect(
        201,
      );
      const id = (res.body as SentBody).id;
      expect(scheduler.pending()).toMatchObject([
        {
          name: 'offer-response-expiry',
          payload: { offerId: id, version: 1 },
          runAt: new Date(T0.getTime() + 7 * DAY),
          jobKey: `offer-expiry:${id}:1`,
        },
      ]);
    });

    it('refuses a new version from the party that wrote the latest one', async () => {
      // 처음 판본은 사장님이 썼으니 사장님은 낼 수 없다.
      const res = await propose(auth, offerId).expect(409);
      expect(res.body).toMatchObject({
        error: { code: 'CONFLICT', message: '지금은 상대가 답할 차례예요.' },
      });
      await propose(authB, offerId).expect(201);
      await propose(authB, offerId).expect(409);
      expect(await versionCount(offerId)).toBe(2);
    });

    it('refuses an eleventh version', async () => {
      for (let n = 2; n <= 10; n += 1) {
        await addVersion(prisma, offerId, n % 2 === 0 ? 'CREATOR' : 'STORE');
      }
      // 열 번째 판본은 크리에이터가 썼으니 사장님 차례다.
      const res = await propose(auth, offerId).expect(409);
      expect(res.body).toMatchObject({
        error: { code: 'CONFLICT', message: '판본은 10개까지 낼 수 있어요.' },
      });
      expect(await versionCount(offerId)).toBe(10);
    });

    it('refuses a creator version with view pay when instagram is not connected', async () => {
      const body = { format: 'REELS', reward: { perView: {} } };
      const res = await propose(authB, offerId, body).expect(409);
      expect(res.body).toMatchObject({
        error: {
          code: 'CONFLICT',
          message: '인스타그램을 연동하면 수락할 수 있어요.',
        },
      });
      expect(await versionCount(offerId)).toBe(1);
      await post(authB, '/instagram/connect/complete', {
        code: 'haru_cafe',
      }).expect(200);
      await propose(authB, offerId, body).expect(201);
    });

    it('does not ask the store for instagram when it sends a view pay version', async () => {
      await addVersion(prisma, offerId, 'CREATOR');
      await propose(auth, offerId, {
        format: 'REELS',
        reward: { perView: {} },
      }).expect(201);
    });

    it('validates the version body', async () => {
      await propose(authB, offerId, {
        ...STORE_VERSION,
        principles: ['열 글자를 넘는 원칙입니다 정말로'],
      }).expect(400);
      await propose(authB, offerId, {
        ...STORE_VERSION,
        principles: ['하나', '둘', '셋', '넷'],
      }).expect(400);
      await propose(authB, offerId, {
        ...STORE_VERSION,
        idea: 'ㅇ'.repeat(201),
      }).expect(400);
      await propose(authB, offerId, { format: 'REELS' }).expect(400);
      // 범위 밖 단가는 조건 검사에서 막힌다.
      await propose(authB, offerId, {
        format: 'REELS',
        reward: { perView: { ratePerThousand: 9000 } },
      }).expect(400);
      expect(await versionCount(offerId)).toBe(1);
    });

    it('lets the store accept the creator version and creates the collaboration', async () => {
      await propose(authB, offerId).expect(201);
      const res = await acceptAs(auth, offerId, 2).expect(200);
      const collaboration = await prisma.collaboration.findUniqueOrThrow({
        where: { offerId },
      });
      expect(res.body).toMatchObject({
        view: 'ACCEPTED',
        collaborationId: collaboration.id,
        version: 2,
      });
      expect(collaboration).toMatchObject({
        commissionerId: USER_A,
        creatorId: OTHER,
        stage: 'AWAITING_PAYMENT',
        settlementMethod: 'FIXED',
      });
      expect(collaboration.terms).toMatchObject({
        version: 2,
        fixedCash: 30000,
      });
      expect(await offerRow(offerId)).toMatchObject({ status: 'ACCEPTED' });
      // 결제 기한 작업이 올라가고, 수락 알림은 크리에이터에게만 간다(사장님은 응답의 협업 id로 결제 화면에 간다).
      // 앞선 역제안의 알림(사장님에게 간 OFFER_COUNTERED)은 수락 알림이 아니다.
      expect(scheduler.pending().map((j) => j.name)).toContain(
        'payment-due-expiry',
      );
      expect(
        (
          await prisma.notification.findMany({ orderBy: { createdAt: 'asc' } })
        ).map((n) => [n.userId, n.kind]),
      ).toEqual([
        [USER_A, 'OFFER_COUNTERED'],
        [OTHER, 'OFFER_ACCEPTED_BY_STORE'],
      ]);
    });

    it('notifies the creator with the revised and accepted wordings', async () => {
      await addVersion(prisma, offerId, 'CREATOR');
      await propose(auth, offerId).expect(201);
      await addVersion(prisma, offerId, 'CREATOR');
      await acceptAs(auth, offerId, 4).expect(200);
      const rows = await prisma.notification.findMany({
        orderBy: { createdAt: 'asc' },
      });
      expect(rows.map((r) => r.kind)).toEqual([
        'OFFER_REVISED',
        'OFFER_ACCEPTED_BY_STORE',
      ]);
      expect(rows[0]).toMatchObject({
        userId: OTHER,
        role: 'CREATOR',
        tab: 'MATCHING',
        actorUserId: USER_A,
        targetKind: 'PROPOSAL',
        targetId: offerId,
        dedupeKey: `offer-version:${offerId}:3`,
      });
      expect(rows[1]).toMatchObject({
        userId: OTHER,
        role: 'CREATOR',
        targetKind: 'PROPOSAL',
        targetId: offerId,
        dedupeKey: `offer-accepted:${offerId}`,
      });
      const bodies = push.sent.map((p) => p.body);
      expect(bodies[0]).toMatch(/[이가] 조건을 바꿔 다시 보냈어요\.$/);
      expect(bodies[1]).toMatch(
        /[이가] 제안을 수락했어요\. 결제하면 알려드릴게요\.$/,
      );
    });

    it('notifies the store with the counter proposal wording', async () => {
      await propose(authB, offerId).expect(201);
      expect(push.sent).toMatchObject([
        { userId: USER_A, body: '하루 한 컵님이 조건을 바꿔 제안했어요.' },
      ]);
      expect(await prisma.notification.findFirstOrThrow()).toMatchObject({
        userId: USER_A,
        role: 'STORE',
        kind: 'OFFER_COUNTERED',
        actorUserId: OTHER,
        actorName: '하루 한 컵',
        targetKind: 'PROPOSAL',
        targetId: offerId,
        dedupeKey: `offer-version:${offerId}:2`,
      });
    });

    it('does nothing for a repeated version notification', async () => {
      await propose(authB, offerId).expect(201);
      await app.get(NotificationsService).notify({
        userId: USER_A,
        role: 'STORE',
        kind: 'OFFER_COUNTERED',
        actor: { userId: OTHER, name: '하루 한 컵', photoPath: null },
        target: { kind: 'PROPOSAL', id: offerId },
        dedupeKey: `offer-version:${offerId}:2`,
      });
      expect(await prisma.notification.count()).toBe(1);
      expect(push.sent).toHaveLength(1);
    });

    it('refuses an accept from the party whose turn it is not', async () => {
      // 처음 판본은 사장님이 썼다: 사장님은 수락할 수 없다.
      const store = await acceptAs(auth, offerId, 1).expect(409);
      expect(store.body).toMatchObject({
        error: { code: 'CONFLICT', message: '지금은 상대가 답할 차례예요.' },
      });
      await propose(authB, offerId).expect(201);
      // 이제 크리에이터 차례가 아니다.
      expect(codeOf(await acceptAs(authB, offerId, 2).expect(409))).toBe(
        'CONFLICT',
      );
      expect(await prisma.collaboration.count()).toBe(0);
      expect((await offerRow(offerId)).status).toBe('SENT');
    });

    it('refuses the store accept when the creator disconnected instagram', async () => {
      await addVersion(prisma, offerId, 'CREATOR', {
        voucherName: null,
        voucherValue: null,
        voucherPeople: null,
        viewRatePerThousand: 2000,
        perViewCap: 60000,
      });
      const res = await acceptAs(auth, offerId, 2).expect(409);
      expect(res.body).toMatchObject({
        error: {
          code: 'CONFLICT',
          message:
            '크리에이터가 인스타그램 연동을 끊어 지금은 수락할 수 없어요.',
        },
      });
      expect(await prisma.collaboration.count()).toBe(0);
    });

    it('lets only one of a concurrent accept and a new version win', async () => {
      await addVersion(prisma, offerId, 'CREATOR');
      const [accepted, proposed] = await Promise.all([
        acceptAs(auth, offerId, 2),
        propose(auth, offerId),
      ]);
      const row = await offerRow(offerId);
      if (accepted.status === 200) {
        // 수락이 이기면 새 판본은 409이고 판본은 늘지 않는다.
        expect(proposed.status).toBe(409);
        expect(row).toMatchObject({ status: 'ACCEPTED', latestVersion: 2 });
        expect(await versionCount(offerId)).toBe(2);
        expect(await prisma.collaboration.count()).toBe(1);
      } else {
        // 새 판본이 이기면 수락은 STALE_VERSION이고 협업은 없다.
        expect(proposed.status).toBe(201);
        expect(accepted.status).toBe(409);
        expect(codeOf(accepted)).toBe('STALE_VERSION');
        expect(
          (accepted.body as { error: { details: unknown } }).error.details,
        ).toEqual({ latestVersion: 3 });
        expect(row).toMatchObject({ status: 'SENT', latestVersion: 3 });
        expect(await prisma.collaboration.count()).toBe(0);
      }
    });

    it('lets only one of two concurrent new versions from the same party win', async () => {
      const results = await Promise.all([
        propose(authB, offerId),
        propose(authB, offerId),
      ]);
      expect(results.map((r) => r.status).sort()).toEqual([201, 409]);
      expect(await versionCount(offerId)).toBe(2);
    });

    it('ends as DECLINED when the receiving party ends it and stores the reason', async () => {
      const applicationId = await seedApplication(storeId, OTHER, 'OFFERED');
      await prisma.offer.update({
        where: { id: offerId },
        data: { applicationId },
      });
      const res = await endAs(authB, offerId, 'TERMS').expect(200);
      expect(res.body).toEqual({
        id: offerId,
        status: 'DECLINED',
        endReason: 'TERMS',
        endedBy: 'CREATOR',
      });
      expect(await offerRow(offerId)).toMatchObject({
        status: 'DECLINED',
        endReason: 'TERMS',
        endedBy: 'CREATOR',
        declinedAt: null,
      });
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: applicationId },
          })
        ).status,
      ).toBe('CLOSED');
      expect(await prisma.notification.findFirstOrThrow()).toMatchObject({
        userId: USER_A,
        role: 'STORE',
        kind: 'OFFER_ENDED',
        actorName: '하루 한 컵',
        targetKind: 'PROPOSAL',
        targetId: offerId,
        dedupeKey: `offer-ended:${offerId}`,
      });
      expect(push.sent[0].body).toBe('하루 한 컵님과의 제안이 종료됐어요.');
      // 되돌릴 수 없다.
      await post(authB, `/offers/${offerId}/undo-decline`).expect(409);
      await endAs(authB, offerId).expect(409);
    });

    it('ends as CANCELLED when the writing party ends it', async () => {
      const res = await endAs(auth, offerId, 'OTHER_PARTNER').expect(200);
      expect(res.body).toEqual({
        id: offerId,
        status: 'CANCELLED',
        endReason: 'OTHER_PARTNER',
        endedBy: 'STORE',
      });
      expect(await offerRow(offerId)).toMatchObject({
        status: 'CANCELLED',
        endReason: 'OTHER_PARTNER',
        endedBy: 'STORE',
      });
      expect(await prisma.notification.findFirstOrThrow()).toMatchObject({
        userId: OTHER,
        role: 'CREATOR',
        kind: 'OFFER_ENDED',
        targetKind: 'PROPOSAL',
      });
    });

    it('ends a creator version as DECLINED when the store ends it', async () => {
      await propose(authB, offerId).expect(201);
      const res = await endAs(auth, offerId, 'NO_REASON').expect(200);
      expect(res.body).toMatchObject({ status: 'DECLINED', endedBy: 'STORE' });
    });

    it('rejects an unknown end reason', async () => {
      await endAs(auth, offerId, 'BORED').expect(400);
      await post(auth, `/offers/${offerId}/end`).expect(400);
    });

    it('returns 404 to a third user for versions, accept and end', async () => {
      const otherStore = await seedStore();
      const otherCreator = await seedCreator();
      const theirs = (await seedOffer(otherStore.id, otherCreator)).id;
      // user-a(사장님)는 남의 오퍼에, user-b(크리에이터)는 내 가게와 다른 크리에이터의 오퍼에 당사자가 아니다.
      const mine = (await seedOffer(storeId, otherCreator)).id;
      for (const [headers, id] of [
        [auth, theirs],
        [authB, mine],
      ] as const) {
        expect(codeOf(await propose(headers, id).expect(404))).toBe(
          'NOT_FOUND',
        );
        await acceptAs(headers, id, 1).expect(404);
        await endAs(headers, id).expect(404);
      }
      await propose(auth, 'not-a-uuid').expect(404);
      expect(await versionCount(theirs)).toBe(1);
      expect(await versionCount(mine)).toBe(1);
      expect((await offerRow(mine)).status).toBe('SENT');
    });

    it('requires a login for the new routes', async () => {
      await request(server).post(`/offers/${offerId}/versions`).expect(401);
      await request(server).post(`/offers/${offerId}/end`).expect(401);
    });

    it('refuses the 30 second decline when it is not the creator turn', async () => {
      await addVersion(prisma, offerId, 'CREATOR');
      const res = await post(authB, `/offers/${offerId}/decline`).expect(409);
      expect(res.body).toMatchObject({
        error: { code: 'CONFLICT', message: '지금은 상대가 답할 차례예요.' },
      });
      expect((await offerRow(offerId)).status).toBe('SENT');
    });

    it('stores NO_REASON and the creator on a 30 second decline and clears them on undo', async () => {
      await post(authB, `/offers/${offerId}/decline`).expect(200);
      expect(await offerRow(offerId)).toMatchObject({
        status: 'DECLINED',
        endReason: 'NO_REASON',
        endedBy: 'CREATOR',
      });
      await post(authB, `/offers/${offerId}/undo-decline`).expect(200);
      expect(await offerRow(offerId)).toMatchObject({
        status: 'SENT',
        endReason: null,
        endedBy: null,
      });
    });

    it('lets the store cancel only an offer whose latest version it wrote', async () => {
      await propose(authB, offerId).expect(201);
      const res = await post(auth, `/offers/${offerId}/cancel`).expect(409);
      expect(res.body).toMatchObject({
        error: { code: 'CONFLICT', message: '받은 제안은 종료로 끝내 주세요.' },
      });
      await propose(auth, offerId).expect(201);
      await post(auth, `/offers/${offerId}/cancel`).expect(200);
      expect((await offerRow(offerId)).status).toBe('CANCELLED');
    });

    it('refuses the store cancel when the creator sends a new version after the store read the offer', async () => {
      const repo = app.get(OffersRepository);
      const original = repo.cancel.bind(repo);
      // 사장님이 판본 1을 읽은 뒤, 취소가 저장되기 전에 크리에이터가 판본 2를 낸다.
      const spy = jest
        .spyOn(repo, 'cancel')
        .mockImplementationOnce(async (...args) => {
          await propose(authB, offerId).expect(201);
          return original(...args);
        });
      const res = await post(auth, `/offers/${offerId}/cancel`).expect(409);
      spy.mockRestore();
      expect(res.body).toMatchObject({
        error: { code: 'CONFLICT', message: '받은 제안은 종료로 끝내 주세요.' },
      });
      expect(await offerRow(offerId)).toMatchObject({
        status: 'SENT',
        latestVersion: 2,
        turn: 'STORE',
      });
    });

    it('shows version 2 terms and number on the sent list', async () => {
      await propose(authB, offerId).expect(201);
      const rows = (await sentList().expect(200)).body as (SentBody & {
        version: number;
        myTurn: boolean;
      })[];
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({ id: offerId, version: 2, myTurn: true });
      expect(rows[0].terms).toMatchObject({
        fixedCash: 30000,
        maxCashBurden: 30000,
        settlementMethod: 'FIXED',
      });
    });

    describe('response expiry jobs', () => {
      it('expires the offer when the latest version goes unanswered for 7 days', async () => {
        const applicationId = await seedApplication(storeId, OTHER, 'OFFERED');
        await prisma.offer.update({
          where: { id: offerId },
          data: { applicationId },
        });
        await propose(authB, offerId).expect(201);
        clock.advance(7 * DAY - SECOND);
        await scheduler.runDue(clock.now());
        expect((await offerRow(offerId)).status).toBe('SENT');

        clock.advance(SECOND);
        await scheduler.runDue(clock.now());
        expect((await offerRow(offerId)).status).toBe('EXPIRED');
        expect(
          (
            await prisma.application.findUniqueOrThrow({
              where: { id: applicationId },
            })
          ).status,
        ).toBe('CLOSED');
      });

      it('does nothing when the expiry job of an older version runs', async () => {
        await propose(authB, offerId).expect(201);
        // 최신 판본(2)의 기한이 이미 지난 오퍼에 판본 1의 작업이 돈다: 번호가 달라 아무 일도 하지 않는다.
        await prisma.offer.update({
          where: { id: offerId },
          data: { expiresAt: new Date(T0.getTime() - SECOND) },
        });
        await scheduler.schedule(
          'offer-response-expiry',
          { offerId, version: 1 },
          clock.now(),
          'old-version-job',
        );
        await scheduler.runDue(clock.now());
        expect((await offerRow(offerId)).status).toBe('SENT');

        // 판본 2의 작업은 읽을 때 만료와 같은 길로 만료한다.
        await scheduler.schedule(
          'offer-response-expiry',
          { offerId, version: 2 },
          clock.now(),
          'latest-version-job',
        );
        await scheduler.runDue(clock.now());
        expect((await offerRow(offerId)).status).toBe('EXPIRED');
      });

      it('does nothing when the offer was ended before the job runs', async () => {
        await endAs(authB, offerId).expect(200);
        await scheduler.schedule(
          'offer-response-expiry',
          { offerId, version: 1 },
          clock.now(),
          'late-job',
        );
        await scheduler.runDue(clock.now());
        expect((await offerRow(offerId)).status).toBe('DECLINED');
      });
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
        voucherName: '식사권',
        maxCashBurden: 0,
      });
    });

    it('keeps accepted offers out of new', async () => {
      const waiting = await seedOffer(store.id, USER_A);
      const other = await seedStore();
      const accepted = await seedOffer(other.id, USER_A, {
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: new Date(T0.getTime() + 3 * DAY),
      });
      const news = (await received('new').expect(200)).body as ReceivedBody[];
      expect(news.map((o) => o.id)).toEqual([waiting.id]);
      expect(news.map((o) => o.id)).not.toContain(accepted.id);
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
      // 진행 중 탭은 협업 목록으로 옮겨 갔다.
      await received('active').expect(400);
      await request(server).get('/offers/received').set(auth).expect(400);
    });

    it('marks a per-view reels offer as needing instagram', async () => {
      const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
      const list = (await received('new').expect(200)).body as ReceivedBody[];
      expect(list.map((o) => [o.id, o.needsInstagram])).toEqual([
        [offer.id, true],
      ]);
    });

    it('needs instagram for a reels offer with view pay and not for a voucher only offer', async () => {
      const withViewPay = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
      const other = await seedStore();
      const voucherOnly = await seedOffer(other.id, USER_A);
      const list = (await received('new').expect(200)).body as ReceivedBody[];
      const byId = new Map(list.map((o) => [o.id, o.needsInstagram]));
      expect(byId.get(withViewPay.id)).toBe(true);
      expect(byId.get(voucherOnly.id)).toBe(false);
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

    it('does not require instagram for a fixed cash only reels offer', async () => {
      const offer = await seedOffer(store.id, USER_A, {
        voucherName: null,
        voucherValue: null,
        voucherPeople: null,
        fixedCash: 30000,
      });
      const list = (await received('new').expect(200)).body as ReceivedBody[];
      expect(list.map((o) => [o.id, o.needsInstagram])).toEqual([
        [offer.id, false],
      ]);
      // 연결 없이 수락하면 결제를 기다리는 협업이 고정 현금 방식으로 만들어진다.
      await accept(offer.id).expect(200);
      expect(
        await prisma.collaboration.findFirstOrThrow({
          where: { offerId: offer.id },
        }),
      ).toMatchObject({
        stage: 'AWAITING_PAYMENT',
        settlementMethod: 'FIXED',
      });
    });

    it('requires instagram for a card-news offer with both rewards', async () => {
      const offer = await seedOffer(store.id, USER_A, {
        ...PER_VIEW_TERMS,
        format: 'CARD_NEWS',
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
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
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
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
        // 협업이 만들어진 시각(진행 막대의 "오퍼 수락" 시각)은 DB 시각이 아니라 Clock이다(원장 판단 R42).
        createdAt: T0,
        fundedAt: null,
        submitDueAt: null,
      });
      expect(collaboration.terms).toEqual({
        format: 'REELS',
        pieces: 1,
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        fixedCash: 0,
        viewRatePerThousand: 2000,
        perViewCap: 60000,
        usageRights: 'NONE',
        // 수락된 판본의 번호가 조건 사본에 함께 남는다.
        version: 1,
      });
      expect((res.body as ReceivedBody).collaborationId).toBe(collaboration.id);
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
        createdAt: T0,
        fundedAt: T0,
        submitDueAt: new Date(T0.getTime() + 14 * DAY),
      });
      // 식사권만 있어 결제 사후 단계가 없으니 수락이 제출 기한 작업을 올린다: 환급 한 건과 기한 알림 두 건.
      expect(
        scheduler
          .pending()
          .map((j) => j.jobKey)
          .sort(),
      ).toEqual(
        [
          `refund-unsubmitted:${collaboration.id}`,
          `submit-reminder:${collaboration.id}:1`,
          `submit-reminder:${collaboration.id}:3`,
        ].sort(),
      );
      expect(
        scheduler.pending().find((j) => j.name === 'refund-unsubmitted')?.runAt,
      ).toEqual(new Date(T0.getTime() + 14 * DAY));
      // 낼 돈이 없으므로 결제 기한이 없다. 며칠이 지나도 오퍼가 만료되지 않는다.
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .paymentDueAt,
      ).toBeNull();
      clock.advance(5 * DAY);
      // 수락한 오퍼는 받은 오퍼 목록에 없다(협업 목록이 보여 준다).
      expect((await received('new').expect(200)).body).toEqual([]);
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

    it('accepts the latest version and copies its terms and number to the collaboration', async () => {
      const offer = await seedOffer(store.id, USER_A);
      // 사장님이 한 번 고친 판본 2를 크리에이터가 수락한다(고친 판본을 내는 길은 Task 6).
      await addVersion(prisma, offer.id, 'STORE', { fixedCash: 30000 });
      await prisma.offer.update({
        where: { id: offer.id },
        data: { turn: 'CREATOR' },
      });
      const res = await accept(offer.id, 2).expect(200);
      expect(res.body as ReceivedBody).toMatchObject({ view: 'ACCEPTED' });
      const collaboration = await prisma.collaboration.findUniqueOrThrow({
        where: { offerId: offer.id },
      });
      expect(collaboration.terms).toMatchObject({
        version: 2,
        fixedCash: 30000,
        voucherName: '식사권',
      });
      expect(collaboration).toMatchObject({
        stage: 'AWAITING_PAYMENT',
        settlementMethod: 'FIXED',
      });
    });

    it('rejects an older version number with STALE_VERSION and the latest number', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await addVersion(prisma, offer.id, 'STORE', { fixedCash: 30000 });
      const res = await accept(offer.id, 1).expect(409);
      expect(res.body).toEqual({
        error: {
          code: 'STALE_VERSION',
          message: '이전 판본이라 수락할 수 없어요.',
          details: { latestVersion: 2 },
        },
      });
      expect(
        (await prisma.offer.findUniqueOrThrow({ where: { id: offer.id } }))
          .status,
      ).toBe('SENT');
    });

    it('rejects a version number that does not exist', async () => {
      const offer = await seedOffer(store.id, USER_A);
      const res = await accept(offer.id, 7).expect(409);
      expect(codeOf(res)).toBe('STALE_VERSION');
      expect(
        (res.body as { error: { details: unknown } }).error.details,
      ).toEqual({ latestVersion: 1 });
    });

    it('creates no collaboration when the accept is stale', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await addVersion(prisma, offer.id, 'STORE', { fixedCash: 30000 });
      await accept(offer.id, 1).expect(409);
      expect(await prisma.collaboration.count()).toBe(0);
      expect(scheduler.pending()).toEqual([]);
    });

    it('rejects an accept without a version number', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await accept(offer.id, null).expect(400);
      await request(server)
        .post(`/offers/${offer.id}/accept`)
        .set(auth)
        .send({ version: 0 })
        .expect(400);
      expect(await prisma.collaboration.count()).toBe(0);
    });

    it('checks the version before the turn and the turn before instagram', async () => {
      // 인스타그램을 연결하지 않았고 조회수 수당이 있는 판본이지만, 차례가 아니므로 인스타그램 안내보다 차례가 먼저다.
      const offer = await seedOffer(store.id, USER_A, {
        ...PER_VIEW_TERMS,
        turn: 'STORE',
      });
      const notTurn = await accept(offer.id, 1).expect(409);
      expect(notTurn.body).toMatchObject({
        error: { code: 'CONFLICT', message: '지금은 상대가 답할 차례예요.' },
      });
      // 낡은 번호는 그보다 먼저 STALE_VERSION이다.
      expect(codeOf(await accept(offer.id, 3).expect(409))).toBe(
        'STALE_VERSION',
      );
    });

    it('shows the latest terms, the version and whose turn it is on the received list', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await addVersion(prisma, offer.id, 'STORE', { fixedCash: 30000 });
      await prisma.offer.update({
        where: { id: offer.id },
        data: { turn: 'CREATOR' },
      });
      const rows = (await received('new').expect(200)).body as (ReceivedBody & {
        version: number;
        myTurn: boolean;
      })[];
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({ id: offer.id, version: 2, myTurn: true });
      expect(rows[0].terms).toMatchObject({
        fixedCash: 30000,
        maxCashBurden: 30000,
        settlementMethod: 'FIXED',
      });
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
      const offer = await seedOffer(store.id, USER_A, PER_VIEW_TERMS);
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
