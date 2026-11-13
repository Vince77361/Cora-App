import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import {
  addVersion,
  createOffer,
  type TestOfferInput,
} from './helpers/create-offer';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const T0 = new Date('2026-12-01T00:00:00.000Z');
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
// 조회수 보상만 있는 조건.
const PER_VIEW_TERMS = {
  voucherName: null,
  voucherValue: null,
  voucherPeople: null,
  viewRatePerThousand: 2000,
  perViewCap: 60000,
} as const;

interface RowBody {
  offerId: string;
  counterpart: { name: string; photoUrl: string | null };
  group: 'MY_TURN' | 'WAITING' | 'ENDED';
  version: number;
  counter: boolean;
  format: string;
  pieces: number;
  daysLeft: number | null;
  endKind: 'AGREED' | 'ENDED' | 'EXPIRED' | null;
  endReason: string | null;
  collaborationId: string | null;
}
interface VersionBody {
  number: number;
  authorParty: string;
  terms: {
    fixedCash: number;
    voucherValue: number | null;
    format: string;
    viewRatePerThousand: number | null;
    perViewCap: number | null;
    maxCashBurden: number;
  };
  idea: string | null;
}
interface DetailBody {
  offerId: string;
  status: string;
  myParty: string;
  group: string;
  latest: VersionBody;
  previous: VersionBody | null;
  changed: string[];
  store: { id: string; name: string; recruitLine: string | null };
  counterpart: { userId: string; name: string; photoUrl: string | null };
  feeRate: number;
  needsInstagram: boolean;
  expiresAt: string;
  endKind: string | null;
  endReason: string | null;
  collaborationId: string | null;
}

describe('proposals', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;

  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const list = (tab: string) =>
    request(server).get(`/offers/proposals?tab=${tab}`).set(auth);
  const rowsOf = async (tab: 'active' | 'ended'): Promise<RowBody[]> =>
    (await list(tab).expect(200)).body as RowBody[];
  const detail = (id: string) => request(server).get(`/offers/${id}`).set(auth);

  async function seedCreator(name = '다른 크리에이터'): Promise<string> {
    const userId = randomUUID();
    await prisma.user.create({ data: { id: userId, role: 'CREATOR' } });
    await prisma.creatorProfile.create({
      data: { userId, displayName: name, ...REGION },
    });
    return userId;
  }

  async function seedStore(
    ownerId: string,
    name = '남의 가게',
  ): Promise<string> {
    const store = await prisma.store.create({
      data: {
        ownerId,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name,
        neighborhood: '성수동',
        regionSido: REGION.regionSido,
        regionSigungu: REGION.regionSigungu,
        defaultFormat: 'REELS',
        defaultVoucherName: '식사권',
        defaultVoucherValue: 40000,
        defaultVoucherPeople: 2,
        publishedAt: T0,
      },
    });
    return store.id;
  }

  // 내 가게(user-a, 사장님). 역할을 바꾼 뒤 직접 만든다.
  async function seedMyStore(): Promise<string> {
    await setRole('STORE');
    return seedStore(USER_A, '한그릇 라멘');
  }

  async function seedOtherStore(name = '남의 가게'): Promise<string> {
    const ownerId = randomUUID();
    await prisma.user.create({ data: { id: ownerId, role: 'STORE' } });
    return seedStore(ownerId, name);
  }

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
      expiresAt: new Date(clock.now().getTime() + 3 * DAY),
      createdAt: clock.now(),
      ...over,
    });
  }

  // 크리에이터가 시작한 오퍼: 판본 1은 가게, 판본 2는 크리에이터이고 차례는 사장님이다.
  async function seedCreatorStarted(
    storeId: string,
    creatorId: string,
    over: Partial<TestOfferInput> = {},
  ) {
    const offer = await seedOffer(storeId, creatorId, {
      initiatedBy: 'STORE',
      turn: 'CREATOR',
      ...over,
    });
    await addVersion(prisma, offer.id, 'CREATOR', { fixedCash: 30000 });
    return offer;
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(T0);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token or a bad tab', async () => {
    await request(server).get('/offers/proposals?tab=active').expect(401);
    await request(server).get(`/offers/${randomUUID()}`).expect(401);
    await setRole('STORE');
    await list('all').expect(400);
    await request(server).get('/offers/proposals').set(auth).expect(400);
  });

  it('refuses a brand account', async () => {
    await setRole('BRAND');
    await list('active').expect(403);
  });

  describe('as a store owner', () => {
    let storeId: string;
    beforeEach(async () => {
      storeId = await seedMyStore();
    });

    it('groups an offer by whose turn it is', async () => {
      const waitingCreator = await seedCreator('기다리는 사람');
      const answerCreator = await seedCreator('답할 사람');
      // 사장님이 방금 보낸 오퍼(판본 1, 차례는 크리에이터)와 크리에이터가 역제안한 오퍼(차례는 사장님).
      const waiting = await seedOffer(storeId, waitingCreator, {
        createdAt: new Date(T0.getTime() + 2 * HOUR),
      });
      const mine = await seedCreatorStarted(storeId, answerCreator);

      const rows = await rowsOf('active');
      expect(rows.map((row) => [row.offerId, row.group])).toEqual([
        [mine.id, 'MY_TURN'],
        [waiting.id, 'WAITING'],
      ]);
      expect(rows[0]).toMatchObject({
        counterpart: { name: '답할 사람', photoUrl: null },
        version: 2,
        counter: true,
        format: 'REELS',
        pieces: 1,
        daysLeft: null,
        endKind: null,
        endReason: null,
        collaborationId: null,
      });
      expect(rows[1]).toMatchObject({
        counterpart: { name: '기다리는 사람' },
        version: 1,
        counter: false,
        daysLeft: 3,
      });
    });

    it('orders offers in the same group by the latest version', async () => {
      const first = await seedCreator('먼저');
      const second = await seedCreator('나중');
      const older = await seedOffer(storeId, first, {
        createdAt: new Date(T0.getTime() - 5 * HOUR),
      });
      const newer = await seedOffer(storeId, second, {
        createdAt: new Date(T0.getTime() - 1 * HOUR),
      });
      const rows = await rowsOf('active');
      expect(rows.map((row) => row.offerId)).toEqual([newer.id, older.id]);
    });

    it('puts accepted, declined, cancelled and expired offers in the ended tab', async () => {
      const agreed = await seedOffer(storeId, await seedCreator('합의'), {
        status: 'ACCEPTED',
      });
      const declined = await seedOffer(storeId, await seedCreator('거절'), {
        status: 'DECLINED',
        declinedAt: new Date(T0.getTime() - HOUR),
        endReason: 'SCHEDULE',
        endedBy: 'CREATOR',
      });
      const cancelled = await seedOffer(storeId, await seedCreator('취소'), {
        status: 'CANCELLED',
        endReason: 'TERMS',
        endedBy: 'STORE',
      });
      const expired = await seedOffer(storeId, await seedCreator('만료'), {
        status: 'EXPIRED',
      });
      const open = await seedOffer(storeId, await seedCreator('진행'));

      expect((await rowsOf('active')).map((row) => row.offerId)).toEqual([
        open.id,
      ]);
      const ended = await rowsOf('ended');
      const byId = new Map(ended.map((row) => [row.offerId, row]));
      expect(ended).toHaveLength(4);
      expect(byId.get(agreed.id)).toMatchObject({
        group: 'ENDED',
        endKind: 'AGREED',
        daysLeft: null,
      });
      expect(byId.get(declined.id)).toMatchObject({
        endKind: 'ENDED',
        endReason: 'SCHEDULE',
      });
      expect(byId.get(cancelled.id)).toMatchObject({
        endKind: 'ENDED',
        endReason: 'TERMS',
      });
      expect(byId.get(expired.id)).toMatchObject({
        endKind: 'EXPIRED',
        endReason: null,
      });
    });

    it('counts the days left to answer and zero for less than a day', async () => {
      const a = await seedOffer(storeId, await seedCreator('일 곱'), {
        expiresAt: new Date(T0.getTime() + 7 * DAY),
      });
      const b = await seedOffer(storeId, await seedCreator('이틀 조금'), {
        expiresAt: new Date(T0.getTime() + 1 * DAY + 3 * HOUR),
      });
      const c = await seedOffer(storeId, await seedCreator('몇 시간'), {
        expiresAt: new Date(T0.getTime() + 5 * HOUR),
      });
      const days = new Map(
        (await rowsOf('active')).map((row) => [row.offerId, row.daysLeft]),
      );
      expect(days.get(a.id)).toBe(7);
      expect(days.get(b.id)).toBe(2);
      expect(days.get(c.id)).toBe(0);
    });

    it('marks a row as a counter proposal when the other party wrote version 2 or later', async () => {
      const creatorId = await seedCreator();
      const offer = await seedOffer(storeId, creatorId);
      expect((await rowsOf('active'))[0]).toMatchObject({ counter: false });
      // 크리에이터가 역제안(판본 2)하면 사장님에게는 역제안이다.
      await addVersion(prisma, offer.id, 'CREATOR', { fixedCash: 30000 });
      expect((await rowsOf('active'))[0]).toMatchObject({
        counter: true,
        group: 'MY_TURN',
        version: 2,
      });
      // 사장님이 고쳐 다시 보내면(판본 3) 상대가 쓴 판본이 아니라 역제안이 아니다.
      await addVersion(prisma, offer.id, 'STORE', { fixedCash: 20000 });
      expect((await rowsOf('active'))[0]).toMatchObject({
        counter: false,
        group: 'WAITING',
        version: 3,
      });
    });

    it('keeps a decline from showing until the creator can no longer undo it', async () => {
      const creatorId = await seedCreator();
      const offer = await seedOffer(storeId, creatorId, {
        status: 'DECLINED',
        declinedAt: new Date(T0.getTime() - 10 * 1000),
        endReason: 'NO_REASON',
        endedBy: 'CREATOR',
      });
      expect((await rowsOf('active')).map((row) => row.offerId)).toEqual([
        offer.id,
      ]);
      expect(await rowsOf('ended')).toEqual([]);
      const body = (await detail(offer.id).expect(200)).body as DetailBody;
      expect(body).toMatchObject({
        status: 'WAITING',
        group: 'WAITING',
        endKind: null,
        endReason: null,
      });
      clock.set(new Date(T0.getTime() + 25 * 1000));
      expect(await rowsOf('active')).toEqual([]);
      expect((await rowsOf('ended'))[0]).toMatchObject({
        endKind: 'ENDED',
        endReason: 'NO_REASON',
      });
    });

    it('expires an overdue offer before listing it', async () => {
      const offer = await seedOffer(storeId, await seedCreator(), {
        expiresAt: new Date(T0.getTime() + HOUR),
      });
      clock.set(new Date(T0.getTime() + 2 * HOUR));
      expect(await rowsOf('active')).toEqual([]);
      expect((await rowsOf('ended'))[0]).toMatchObject({
        offerId: offer.id,
        endKind: 'EXPIRED',
      });
      const stored = await prisma.offer.findUniqueOrThrow({
        where: { id: offer.id },
      });
      expect(stored.status).toBe('EXPIRED');
    });

    it('does not list offers of other stores', async () => {
      const elsewhere = await seedOtherStore();
      await seedOffer(elsewhere, await seedCreator());
      expect(await rowsOf('active')).toEqual([]);
      expect(await rowsOf('ended')).toEqual([]);
    });

    it('returns the latest and previous versions with the changed fields', async () => {
      const creatorId = await seedCreator('하루 한 컵');
      const offer = await seedOffer(storeId, creatorId);
      await addVersion(prisma, offer.id, 'CREATOR', {
        fixedCash: 30000,
        voucherValue: 50000,
        idea: '신메뉴 소개',
      });
      const body = (await detail(offer.id).expect(200)).body as DetailBody;
      expect(body).toMatchObject({
        offerId: offer.id,
        status: 'WAITING',
        myParty: 'STORE',
        group: 'MY_TURN',
        changed: ['VOUCHER', 'FIXED_CASH', 'IDEA'],
        store: { id: storeId, name: '한그릇 라멘', recruitLine: null },
        counterpart: { userId: creatorId, name: '하루 한 컵', photoUrl: null },
        needsInstagram: false,
        expiresAt: offer.expiresAt.toISOString(),
        endKind: null,
        endReason: null,
        collaborationId: null,
      });
      expect(body.latest).toMatchObject({
        number: 2,
        authorParty: 'CREATOR',
        terms: { fixedCash: 30000, voucherValue: 50000 },
        idea: '신메뉴 소개',
      });
      expect(body.previous).toMatchObject({
        number: 1,
        authorParty: 'STORE',
        terms: { fixedCash: 0, voucherValue: 40000 },
      });
      expect(body.feeRate).toBe(
        Number(app.get(ConfigService).getOrThrow('FEE_RATE_STORE_OFFER')),
      );
    });

    it('has no previous version and no changed fields for the first version', async () => {
      const offer = await seedOffer(storeId, await seedCreator());
      const body = (await detail(offer.id).expect(200)).body as DetailBody;
      expect(body).toMatchObject({
        previous: null,
        changed: [],
        group: 'WAITING',
      });
      expect(body.latest.number).toBe(1);
    });

    it('returns the collaboration id for an agreed proposal', async () => {
      const creatorId = await seedCreator();
      const offer = await seedOffer(storeId, creatorId, {
        status: 'ACCEPTED',
        acceptedAt: T0,
        paymentDueAt: new Date(T0.getTime() + 3 * DAY),
      });
      const collaboration = await prisma.collaboration.create({
        data: {
          kind: 'STORE_OFFER',
          stage: 'AWAITING_PAYMENT',
          commissionerId: USER_A,
          creatorId,
          offerId: offer.id,
          storeId,
          terms: { format: 'REELS', pieces: 1, fixedCash: 0 },
          settlementMethod: 'NONE',
        },
      });
      const body = (await detail(offer.id).expect(200)).body as DetailBody;
      expect(body).toMatchObject({
        status: 'ACCEPTED',
        group: 'ENDED',
        endKind: 'AGREED',
        collaborationId: collaboration.id,
      });
      expect((await rowsOf('ended'))[0]).toMatchObject({
        endKind: 'AGREED',
        collaborationId: collaboration.id,
      });
    });

    it('returns 404 for a proposal I am not part of', async () => {
      const elsewhere = await seedOtherStore();
      const foreign = await seedOffer(elsewhere, await seedCreator());
      const res = await detail(foreign.id).expect(404);
      expect((res.body as { error: { code: string } }).error.code).toBe(
        'NOT_FOUND',
      );
      await detail(randomUUID()).expect(404);
      await detail('not-a-uuid').expect(404);
    });

    it('serves the fixed routes before the id route', async () => {
      await request(server).get('/offers/sent').set(auth).expect(200);
      await rowsOf('active');
    });
  });

  describe('as a creator', () => {
    beforeEach(async () => {
      await setRole('CREATOR');
      await prisma.creatorProfile.create({
        data: { userId: USER_A, displayName: '하루 한 컵', ...REGION },
      });
    });

    it('shows the creator both offers received and proposals started', async () => {
      const receivedStore = await seedOtherStore('받은 가게');
      const startedStore = await seedOtherStore('내가 제안한 가게');
      const received = await seedOffer(receivedStore, USER_A, {
        createdAt: new Date(T0.getTime() + HOUR),
      });
      const started = await seedOffer(startedStore, USER_A, {
        initiatedBy: 'STORE',
        turn: 'CREATOR',
      });
      await addVersion(prisma, started.id, 'CREATOR', { fixedCash: 30000 });

      const rows = await rowsOf('active');
      expect(rows.map((row) => [row.offerId, row.group])).toEqual([
        [received.id, 'MY_TURN'],
        [started.id, 'WAITING'],
      ]);
      expect(rows[0]).toMatchObject({
        counterpart: { name: '받은 가게' },
        counter: false,
        version: 1,
      });
      // 내가 쓴 판본이 최신이라 내 쪽에서는 역제안이 아니다.
      expect(rows[1]).toMatchObject({
        counterpart: { name: '내가 제안한 가게' },
        counter: false,
        version: 2,
        daysLeft: 3,
      });
    });

    it('shows a decline as ended right away', async () => {
      const store = await seedOtherStore();
      const offer = await seedOffer(store, USER_A, {
        status: 'DECLINED',
        declinedAt: new Date(T0.getTime() - 10 * 1000),
        endReason: 'NO_REASON',
        endedBy: 'CREATOR',
      });
      expect(await rowsOf('active')).toEqual([]);
      expect((await rowsOf('ended'))[0]).toMatchObject({
        offerId: offer.id,
        endKind: 'ENDED',
        endReason: 'NO_REASON',
      });
    });

    it('does not list offers sent to other creators', async () => {
      const store = await seedOtherStore();
      await seedOffer(store, await seedCreator());
      expect(await rowsOf('active')).toEqual([]);
    });

    it('returns the detail with the store as the counterpart', async () => {
      const store = await seedOtherStore('성수 카페');
      const ownerId = (
        await prisma.store.findUniqueOrThrow({ where: { id: store } })
      ).ownerId;
      const offer = await seedOffer(store, USER_A, PER_VIEW_TERMS);
      const body = (await detail(offer.id).expect(200)).body as DetailBody;
      expect(body).toMatchObject({
        myParty: 'CREATOR',
        group: 'MY_TURN',
        status: 'WAITING',
        counterpart: { userId: ownerId, name: '성수 카페' },
        store: { id: store, name: '성수 카페' },
        // 조회수 수당이 있는데 인스타그램 연동이 없다.
        needsInstagram: true,
      });
      // 역제안(F6)은 받은 오퍼의 최신 판본 조건에서 시작하므로 크리에이터도 그 조건을 읽는다.
      expect(body.latest).toMatchObject({
        number: 1,
        terms: {
          format: 'REELS',
          viewRatePerThousand: 2000,
          perViewCap: 60000,
          maxCashBurden: 60000,
        },
      });
    });

    it('returns 404 for a proposal I am not part of', async () => {
      const store = await seedOtherStore();
      const foreign = await seedOffer(store, await seedCreator());
      await detail(foreign.id).expect(404);
    });
  });
});
