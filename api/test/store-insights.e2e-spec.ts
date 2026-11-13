import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { ContentFormat, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { OTHER, USER_A } from './support/fake-token-verifier';

// 사장님이 USER_A(user-a), 크리에이터가 OTHER(user-b)다.
const owner = { Authorization: 'Bearer user-a' };
const creator = { Authorization: 'Bearer user-b' };
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
// 한국 시간 2026-11-14 12:00. 석 달 전은 2026-08-14 00:00(한국)이다.
const NOW = new Date('2026-11-14T03:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;

jest.setTimeout(30000);

describe('store insights (G3)', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let storeId: string;

  const get = (headers: Record<string, string> = owner) =>
    request(server).get('/stores/me/trial-comparison').set(headers);

  async function createStore(ownerId: string, trial: boolean): Promise<string> {
    await prisma.user.upsert({
      where: { id: ownerId },
      update: { role: 'STORE' },
      create: { id: ownerId, role: 'STORE' },
    });
    const store = await prisma.store.create({
      data: {
        ownerId,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name: '하루 한 컵',
        ...REGION,
        defaultFormat: 'REELS',
        publishedAt: NOW,
        ...(trial
          ? {
              trialMonthlyFee: 120000,
              trialEndsOn: new Date('2026-12-10T00:00:00.000Z'),
              trialPostCount: 9,
            }
          : {}),
      },
    });
    return store.id;
  }

  // 끝난 협업, 정산 줄, 보관을 시작시킨 결제(수수료)를 만든다.
  async function settled(
    forStoreId: string,
    over: {
      settledAt?: Date;
      payout?: number;
      fee?: number | null;
      format?: ContentFormat;
      multiplierTenths?: number | null;
      stage?: 'SETTLED' | 'CANCELLED';
    } = {},
  ) {
    await prisma.user.upsert({
      where: { id: OTHER },
      update: { role: 'CREATOR' },
      create: { id: OTHER, role: 'CREATOR' },
    });
    const store = await prisma.store.findUniqueOrThrow({
      where: { id: forStoreId },
    });
    const fundedAt = new Date(NOW.getTime() - 20 * DAY);
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: over.stage ?? 'SETTLED',
        commissionerId: store.ownerId,
        creatorId: OTHER,
        storeId: forStoreId,
        terms: {
          format: over.format ?? 'REELS',
          pieces: 1,
          voucherName: null,
          voucherValue: null,
          voucherPeople: null,
          fixedCash: 0,
          viewRatePerThousand: 2000,
          perViewCap: 60000,
          usageRights: 'NONE',
        },
        settlementMethod: 'PER_VIEW',
        fundedAt,
        submittedUrl: 'https://www.instagram.com/reel/C8abc123/',
        submittedAt: fundedAt,
      },
    });
    if (over.fee !== null) {
      await prisma.payment.create({
        data: {
          collaborationId: collaboration.id,
          amountEscrow: 60000,
          amountFee: over.fee ?? 6000,
          feeRate: 10,
          method: 'CARD',
          status: 'APPROVED',
          pgTransactionId: `tx-${collaboration.id}`,
          requestedAt: fundedAt,
          approvedAt: fundedAt,
        },
      });
    }
    await prisma.settlement.create({
      data: {
        collaborationId: collaboration.id,
        finalViews: 5000,
        payoutAmount: over.payout ?? 10000,
        refundAmount: 50000,
        settledAt: over.settledAt ?? new Date(NOW.getTime() - 3 * DAY),
        multiplierTenths: over.multiplierTenths ?? null,
        usualReadAt: NOW,
      },
    });
    return collaboration;
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    app.get<FakeClock>(Clock).set(NOW);
    storeId = await createStore(USER_A, true);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('requires a login and a store account', async () => {
    await request(server).get('/stores/me/trial-comparison').expect(401);
    await prisma.user.upsert({
      where: { id: OTHER },
      update: { role: 'CREATOR' },
      create: { id: OTHER, role: 'CREATOR' },
    });
    await get(creator).expect(403);
  });

  it('sums three months of trial fees and the cora payouts plus fees', async () => {
    await settled(storeId, { payout: 30000, fee: 8000 });
    await settled(storeId, { payout: 25000, fee: 8000 });
    await settled(storeId, { payout: 35000, fee: 8000 });
    await settled(storeId, { payout: 30000, fee: 8000 });
    const res = await get().expect(200);
    expect(res.body).toMatchObject({
      trial: {
        monthlyFee: 120000,
        endsOn: '2026-12-10',
        postCount: 9,
        spent: 360000,
      },
      cora: { offerCount: 4, spent: 152000 },
    });
  });

  it('counts a collaboration without a payment as a payout with no fee', async () => {
    await settled(storeId, { payout: 40000, fee: null });
    const res = await get().expect(200);
    expect(res.body).toMatchObject({ cora: { offerCount: 1, spent: 40000 } });
  });

  it('counts submitted content by format', async () => {
    await settled(storeId, { format: 'REELS' });
    await settled(storeId, { format: 'REELS' });
    await settled(storeId, { format: 'BLOG' });
    const res = await get().expect(200);
    expect((res.body as { cora: unknown }).cora).toMatchObject({
      contentByFormat: [
        { format: 'REELS', count: 2 },
        { format: 'BLOG', count: 1 },
      ],
    });
  });

  it('averages only the collaborations that have a multiplier, rounded down', async () => {
    await settled(storeId, { multiplierTenths: 31 });
    await settled(storeId, { multiplierTenths: 22 });
    await settled(storeId, { multiplierTenths: null });
    await settled(storeId, { multiplierTenths: 20 });
    const res = await get().expect(200);
    // (31 + 22 + 20) / 3 = 24.33 → 24
    expect(res.body).toMatchObject({ cora: { averageMultiplierTenths: 24 } });
  });

  it('leaves the average empty when no collaboration has a multiplier', async () => {
    await settled(storeId);
    const res = await get().expect(200);
    expect((res.body as { cora: unknown }).cora).toMatchObject({
      averageMultiplierTenths: null,
    });
  });

  it('leaves out collaborations settled more than three calendar months ago', async () => {
    // 경계: 2026-08-14 00:00(한국) = 2026-08-13T15:00Z는 들어가고 1ms 앞은 빠진다.
    await settled(storeId, { settledAt: new Date('2026-08-13T15:00:00.000Z') });
    await settled(storeId, { settledAt: new Date('2026-08-13T14:59:59.999Z') });
    await settled(storeId, { settledAt: new Date('2026-05-01T00:00:00.000Z') });
    const res = await get().expect(200);
    expect(res.body).toMatchObject({ cora: { offerCount: 1 } });
  });

  it('leaves out unsettled collaborations and other stores', async () => {
    await settled(storeId, { stage: 'CANCELLED' });
    const otherStore = await createStore(randomUUID(), true);
    await settled(otherStore);
    await settled(storeId, { payout: 10000, fee: 1000 });
    const res = await get().expect(200);
    expect(res.body).toMatchObject({ cora: { offerCount: 1, spent: 11000 } });
  });

  it('returns an empty cora side for a store with no collaborations yet', async () => {
    const res = await get().expect(200);
    expect(res.body).toMatchObject({
      cora: {
        offerCount: 0,
        spent: 0,
        contentByFormat: [],
        averageMultiplierTenths: null,
      },
    });
  });

  it('returns 404 for the comparison without trial info', async () => {
    await prisma.store.update({
      where: { id: storeId },
      data: {
        trialMonthlyFee: null,
        trialEndsOn: null,
        trialPostCount: null,
      },
    });
    await get().expect(404);
  });
});
