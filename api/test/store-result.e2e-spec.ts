import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import {
  CollaborationStage,
  Prisma,
  PrismaClient,
  SettlementMethod,
} from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { OTHER, USER_A } from './support/fake-token-verifier';

// 사장님이 USER_A(user-a), 크리에이터가 OTHER(user-b)다.
const owner = { Authorization: 'Bearer user-a' };
const creator = { Authorization: 'Bearer user-b' };
const T0 = new Date('2026-11-04T03:00:00.000Z');
const SETTLED_AT = new Date('2026-11-11T03:00:00.000Z');
const REELS_URL = 'https://www.instagram.com/reel/C8abc123/';
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };

jest.setTimeout(30000);

describe('store result (G1)', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;

  const get = (id: string, headers: Record<string, string> = owner) =>
    request(server).get(`/collaborations/${id}/result`).set(headers);

  // 끝난 협업과 정산 줄을 DB에 바로 만든다(정산 흐름은 settlements e2e가 본다).
  async function seed(
    over: {
      stage?: CollaborationStage;
      settlementMethod?: SettlementMethod;
      terms?: Prisma.InputJsonObject;
      settlement?: {
        finalViews: number | null;
        payoutAmount: number;
        refundAmount: number;
        usualViews?: number | null;
        multiplierTenths?: number | null;
      } | null;
      submittedUrl?: string | null;
      commissionerId?: string;
    } = {},
  ) {
    const commissionerId = over.commissionerId ?? USER_A;
    await prisma.user.upsert({
      where: { id: commissionerId },
      update: {},
      create: { id: commissionerId, role: 'STORE' },
    });
    await prisma.user.upsert({
      where: { id: OTHER },
      update: { role: 'CREATOR' },
      create: { id: OTHER, role: 'CREATOR' },
    });
    await prisma.creatorProfile.upsert({
      where: { userId: OTHER },
      update: {},
      create: { userId: OTHER, displayName: '모카', ...REGION },
    });
    const store = await prisma.store.upsert({
      where: { ownerId: commissionerId },
      update: {},
      create: {
        ownerId: commissionerId,
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        name: '하루 한 컵',
        ...REGION,
        defaultFormat: 'REELS',
        publishedAt: T0,
      },
    });
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: over.stage ?? 'SETTLED',
        commissionerId,
        creatorId: OTHER,
        storeId: store.id,
        terms: over.terms ?? {
          format: 'REELS',
          pieces: 1,
          voucherName: null,
          voucherValue: null,
          voucherPeople: null,
          fixedCash: 0,
          viewRatePerThousand: 2000,
          perViewCap: 60000,
          usageRights: 'STORE_REPOST_3M',
        },
        settlementMethod: over.settlementMethod ?? 'PER_VIEW',
        fundedAt: T0,
        submittedUrl:
          over.submittedUrl === undefined ? REELS_URL : over.submittedUrl,
        submittedAt: T0,
        countingEndsAt: SETTLED_AT,
      },
    });
    const settlement =
      over.settlement === undefined
        ? {
            finalViews: 12500,
            payoutAmount: 25000,
            refundAmount: 35000,
            usualViews: 4000,
            multiplierTenths: 31,
          }
        : over.settlement;
    if (settlement) {
      await prisma.settlement.create({
        data: {
          collaborationId: collaboration.id,
          finalViews: settlement.finalViews,
          payoutAmount: settlement.payoutAmount,
          refundAmount: settlement.refundAmount,
          settledAt: SETTLED_AT,
          usualViews: settlement.usualViews ?? null,
          multiplierTenths: settlement.multiplierTenths ?? null,
          usualReadAt: SETTLED_AT,
        },
      });
    }
    return collaboration;
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    app.get<FakeClock>(Clock).set(SETTLED_AT);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('requires a login', async () => {
    const c = await seed();
    await request(server).get(`/collaborations/${c.id}/result`).expect(401);
  });

  it('shows the result to the owner with payout and refund', async () => {
    const c = await seed();
    const res = await get(c.id).expect(200);
    expect(res.body).toEqual({
      creator: { userId: OTHER, name: '모카', photoUrl: null },
      format: 'REELS',
      postedAt: T0.toISOString(),
      postUrl: REELS_URL,
      views: 12500,
      usualViews: 4000,
      multiplierTenths: 31,
      payout: 25000,
      refund: 35000,
      fixedCashOnly: false,
      fixedCash: 0,
    });
  });

  it('leaves the comparison empty when the usual views could not be read', async () => {
    const c = await seed({
      settlement: {
        finalViews: 12500,
        payoutAmount: 25000,
        refundAmount: 35000,
      },
    });
    const res = await get(c.id).expect(200);
    expect(res.body).toMatchObject({
      views: 12500,
      usualViews: null,
      multiplierTenths: null,
    });
  });

  it('marks a fixed cash only result and leaves views empty', async () => {
    const c = await seed({
      settlementMethod: 'FIXED',
      terms: {
        format: 'REELS',
        pieces: 1,
        voucherName: null,
        voucherValue: null,
        voucherPeople: null,
        fixedCash: 50000,
        viewRatePerThousand: null,
        perViewCap: null,
        usageRights: 'NONE',
      },
      settlement: { finalViews: null, payoutAmount: 50000, refundAmount: 0 },
    });
    const res = await get(c.id).expect(200);
    expect(res.body).toMatchObject({
      views: null,
      usualViews: null,
      multiplierTenths: null,
      payout: 50000,
      refund: 0,
      fixedCashOnly: true,
      fixedCash: 50000,
    });
  });

  it('returns 404 for the result to the creator and to a stranger', async () => {
    const c = await seed();
    await get(c.id, creator).expect(404);
    // 남의 가게의 협업은 없는 협업과 같다.
    const other = await seed({ commissionerId: randomUUID() });
    await get(other.id).expect(404);
    await get(randomUUID()).expect(404);
    await get('not-a-uuid').expect(404);
  });

  it('returns 404 for the result before the collaboration is settled', async () => {
    for (const stage of ['FUNDED', 'COUNTING', 'HALTED'] as const) {
      const c = await seed({ stage, settlement: null });
      await get(c.id).expect(404);
    }
  });

  it('returns 404 for a voucher only collaboration that has no result screen', async () => {
    const c = await seed({
      settlementMethod: 'NONE',
      terms: {
        format: 'REELS',
        pieces: 1,
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        fixedCash: 0,
        viewRatePerThousand: null,
        perViewCap: null,
        usageRights: 'NONE',
      },
      settlement: { finalViews: null, payoutAmount: 0, refundAmount: 0 },
    });
    await get(c.id).expect(404);
  });
});
