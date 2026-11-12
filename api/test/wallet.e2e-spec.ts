import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { CollaborationStage, PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { OTHER, USER_A } from './support/fake-token-verifier';

// user-a와 user-b는 서로 다른 크리에이터다.
const authA = { Authorization: 'Bearer user-a' };
const authB = { Authorization: 'Bearer user-b' };
// 한국 시간 2026-11-12(목) 12:00.
const NOW = new Date('2026-11-12T03:00:00.000Z');
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
// 지급일 규칙: 11월 10일(화) 확정 → 11월 18일(수) 10:00 KST. 11월 4일(수)에 보낸 지급은 이번 달 받은 금액이다.
const SETTLED_AT = new Date('2026-11-10T03:00:00.000Z');
const PAYDAY_1118 = new Date('2026-11-18T01:00:00.000Z');
const PAYDAY_1104 = new Date('2026-11-04T01:00:00.000Z');

interface EntryBody {
  collaborationId: string;
  counterpartName: string;
  format: string;
  pieces: number;
  kind: string;
  amount: number | null;
  views: number | null;
  voucherName: string | null;
  voucherUsed: boolean | null;
  stage: string;
  at: string;
}
interface WalletBody {
  nextPayout: { date: string; amount: number } | null;
  account: {
    bankName: string;
    bankFullName: string;
    accountLast4: string;
    holderName: string;
  } | null;
  receivedThisMonth: number;
  heldAmount: number;
  entries: EntryBody[];
}

jest.setTimeout(30000);

describe('wallet', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;

  const walletOf = async (auth: { Authorization: string }) =>
    (await request(server).get('/wallet').set(auth).expect(200))
      .body as WalletBody;

  async function makeUser(id: string, role: 'CREATOR' | 'STORE') {
    await prisma.user.upsert({
      where: { id },
      update: { role },
      create: { id, role },
    });
    if (role === 'CREATOR') {
      await prisma.creatorProfile.upsert({
        where: { userId: id },
        update: {},
        create: { userId: id, displayName: '모카', ...REGION },
      });
    }
  }

  // 협업을 DB에 바로 만든다. 장부는 결제 승인 직후와 같게(상한 = 에스크로) 채운다.
  async function seedCollaboration(
    creatorId: string,
    over: {
      stage: CollaborationStage;
      storeName: string;
      format?: 'REELS' | 'CARD_NEWS';
      voucher?: boolean;
      held?: number;
      submittedAt?: Date;
      fundedAt?: Date;
    },
  ) {
    const ownerId = randomUUID();
    await makeUser(ownerId, 'STORE');
    const store = await prisma.store.create({
      data: {
        ownerId,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name: over.storeName,
        neighborhood: '성수동',
        ...REGION,
        defaultFormat: 'REELS',
        defaultRewardType: 'BOTH',
        publishedAt: NOW,
      },
    });
    const voucher = over.voucher === true;
    const hasMoney = over.held !== undefined || over.stage === 'SETTLED';
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: over.stage,
        commissionerId: ownerId,
        creatorId,
        storeId: store.id,
        terms: {
          format: over.format ?? 'REELS',
          rewardType: voucher ? (hasMoney ? 'BOTH' : 'VOUCHER') : 'PER_VIEW',
          voucherName: voucher ? '2인 식사권' : null,
          voucherValue: voucher ? 40000 : null,
          perViewAmount: hasMoney ? 10 : null,
          perViewCap: hasMoney ? 100000 : null,
        },
        settlementMethod: hasMoney ? 'PER_VIEW' : 'NONE',
        fundedAt: over.fundedAt ?? new Date('2026-11-02T03:00:00.000Z'),
        submittedAt: over.submittedAt ?? null,
      },
    });
    if (over.held !== undefined) {
      await prisma.ledgerEntry.create({
        data: {
          collaborationId: collaboration.id,
          batchId: randomUUID(),
          debitAccount: 'PG_IN',
          creditAccount: 'ESCROW',
          amount: over.held,
          reason: 'PAYMENT_ESCROW',
          idempotencyKey: `seed:${collaboration.id}`,
        },
      });
    }
    return collaboration;
  }

  const seedSettlement = (collaborationId: string, finalViews: number) =>
    prisma.settlement.create({
      data: {
        collaborationId,
        finalViews,
        payoutAmount: finalViews * 10,
        refundAmount: 0,
        settledAt: SETTLED_AT,
      },
    });
  const seedPayout = (
    collaborationId: string,
    amount: number,
    status: 'PENDING' | 'DONE' | 'FAILED',
    scheduledFor: Date,
    updatedAt?: Date,
  ) =>
    prisma.payout.create({
      data: {
        collaborationId,
        amount,
        status,
        idempotencyKey: `payout:${randomUUID()}`,
        scheduledFor,
        // 송금이 끝난 시각(= 마지막으로 고친 시각)을 정해 둔다.
        ...(updatedAt ? { updatedAt } : {}),
      },
    });

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    app.get<FakeClock>(Clock).set(NOW);
    await makeUser(USER_A, 'CREATOR');
    await makeUser(OTHER, 'CREATOR');
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('requires a token', async () => {
    await request(server).get('/wallet').expect(401);
  });

  it('refuses a store account', async () => {
    await makeUser(OTHER, 'STORE');
    const res = await request(server).get('/wallet').set(authB).expect(403);
    expect((res.body as { error: { code: string } }).error.code).toBe(
      'FORBIDDEN',
    );
  });

  it('returns an empty wallet and a null account for a new creator', async () => {
    expect(await walletOf(authA)).toEqual({
      nextPayout: null,
      account: null,
      receivedThisMonth: 0,
      heldAmount: 0,
      entries: [],
    });
  });

  it('shows the numbers and rows in canvas order with the registered account', async () => {
    await request(server)
      .put('/payout-account')
      .set(authA)
      .send({
        bankCode: '004',
        accountNumber: '110123456789',
        holderName: '민서연',
      })
      .expect(200);

    const ramen = await seedCollaboration(USER_A, {
      stage: 'SETTLED',
      storeName: '한그릇 라멘',
      voucher: true,
      submittedAt: new Date('2026-11-03T03:00:00.000Z'),
    });
    await seedSettlement(ramen.id, 4320);
    await seedPayout(ramen.id, 43200, 'PENDING', PAYDAY_1118);

    const moa = await seedCollaboration(USER_A, {
      stage: 'SETTLED',
      storeName: '모아 스튜디오',
    });
    await seedSettlement(moa.id, 35000);
    await seedPayout(moa.id, 350000, 'DONE', PAYDAY_1104, PAYDAY_1104);

    const cup = await seedCollaboration(USER_A, {
      stage: 'COUNTING',
      storeName: '하루 한 컵',
      format: 'CARD_NEWS',
      held: 100000,
      fundedAt: new Date('2026-11-06T03:00:00.000Z'),
    });

    const wallet = await walletOf(authA);

    expect(wallet.nextPayout).toEqual({ date: '2026-11-18', amount: 43200 });
    expect(wallet.account).toEqual({
      bankName: '국민',
      bankFullName: '국민은행',
      accountLast4: '6789',
      holderName: '민서연',
    });
    expect(wallet.receivedThisMonth).toBe(350000);
    expect(wallet.heldAmount).toBe(100000);
    expect(
      wallet.entries.map((e) => [e.counterpartName, e.kind, e.amount]),
    ).toEqual([
      ['한그릇 라멘', 'PAYOUT_SCHEDULED', 43200],
      ['한그릇 라멘', 'VOUCHER', null],
      ['하루 한 컵', 'HELD', 100000],
      ['모아 스튜디오', 'PAYOUT_DONE', 350000],
    ]);
    expect(wallet.entries[0]).toMatchObject({
      collaborationId: ramen.id,
      format: 'REELS',
      pieces: 1,
      views: 4320,
      stage: 'SETTLED',
      at: SETTLED_AT.toISOString(),
    });
    expect(wallet.entries[1]).toMatchObject({
      voucherName: '2인 식사권',
      voucherUsed: true,
    });
    expect(wallet.entries[2]).toMatchObject({
      collaborationId: cup.id,
      format: 'CARD_NEWS',
      stage: 'COUNTING',
    });
    // 계좌 전체 번호는 응답 어디에도 없다.
    expect(JSON.stringify(wallet)).not.toContain('110123456789');
  });

  it('leaves out cancelled and refunded collaborations', async () => {
    await seedCollaboration(USER_A, {
      stage: 'CANCELLED',
      storeName: '취소 가게',
      voucher: true,
    });
    await seedCollaboration(USER_A, {
      stage: 'REFUNDED',
      storeName: '환급 가게',
    });
    const wallet = await walletOf(authA);
    expect(wallet.entries).toEqual([]);
    expect(wallet.heldAmount).toBe(0);
  });

  it("never shows another creator's rows", async () => {
    const theirs = await seedCollaboration(OTHER, {
      stage: 'COUNTING',
      storeName: '남의 가게',
      held: 500000,
    });
    await seedSettlement(theirs.id, 1);
    await seedPayout(theirs.id, 777000, 'PENDING', PAYDAY_1118);
    const mine = await seedCollaboration(USER_A, {
      stage: 'COUNTING',
      storeName: '내 가게',
      held: 100000,
    });

    const wallet = await walletOf(authA);

    expect(wallet.heldAmount).toBe(100000);
    expect(wallet.nextPayout).toBeNull();
    expect(wallet.entries.map((e) => e.collaborationId)).toEqual([mine.id]);
  });
});
