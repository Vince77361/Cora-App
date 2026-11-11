import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { Prisma, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { PushPort } from '../src/integrations/push/push.port';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
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
  creator: { userId: string; displayName: string };
  terms: TermsBody;
  view: string;
  paymentDaysLeft: number | null;
  sentAt: string;
}
interface ReceivedBody {
  id: string;
  store: { id: string; name: string };
  storeIntro: string | null;
  bestShootingTime: string | null;
  terms: TermsBody;
  view: string;
  receivedAt: string;
  canUndoDecline: boolean;
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

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    push = app.get<FakePushPort>(PushPort);
    clock = app.get<FakeClock>(Clock);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    push.sent.length = 0;
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
      expect(offer.applicationId).toBe(applicationId);
    });

    it('notifies the creator on send', async () => {
      const creatorId = await seedCreator();
      await send({ creatorId, ...REELS_VOUCHER }).expect(201);
      expect(push.sent).toEqual([
        {
          userId: creatorId,
          title: 'Cora',
          body: expect.stringMatching(/에서 오퍼가 왔어요\.$/) as string,
        },
      ]);
      expect(push.sent[0].body.startsWith('에서')).toBe(false);
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

    it('counts new applications, waiting offers and accepted offers', async () => {
      const applicant = await seedCreator('지원자');
      await seedApplication(storeId, applicant);
      const waiting = await seedCreator('기다림');
      const accepted = await seedCreator('수락');
      const expired = await seedCreator('만료');
      const declined = await seedCreator('거절');
      await seedOffer(storeId, waiting);
      await seedOffer(storeId, accepted, {
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: new Date(T0.getTime() + 3 * DAY),
      });
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

    it('accepts an offer and sets a 3 day payment deadline', async () => {
      const offer = await seedOffer(store.id, USER_A);
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

    it('notifies the store owner on accept', async () => {
      const offer = await seedOffer(store.id, USER_A);
      await accept(offer.id).expect(200);
      expect(push.sent).toEqual([
        {
          userId: store.ownerId,
          title: 'Cora',
          body: '하루 한 컵님이 오퍼를 수락했어요.',
        },
      ]);
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
  });
});
