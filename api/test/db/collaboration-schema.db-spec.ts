import { randomUUID } from 'node:crypto';
import { prisma } from './setup-db';

const OWNER = '55555555-5555-4555-8555-555555555551';
const CREATOR = '55555555-5555-4555-8555-555555555552';

let storeId: string;
let offerId: string;

beforeEach(async () => {
  // 각 테스트 전에 setup-db가 모든 테이블을 비우므로 기준 데이터를 여기서 다시 만든다.
  await prisma.user.createMany({
    data: [
      { id: OWNER, role: 'STORE' },
      { id: CREATOR, role: 'CREATOR' },
    ],
  });
  const store = await prisma.store.create({ data: { ownerId: OWNER } });
  storeId = store.id;
  const offer = await prisma.offer.create({
    data: {
      storeId,
      creatorId: CREATOR,
      format: 'REELS',
      status: 'ACCEPTED',
      expiresAt: new Date('2026-12-01T00:00:00Z'),
    },
  });
  offerId = offer.id;
});

function createCollaboration(over: { offerId?: string | null } = {}) {
  return prisma.collaboration.create({
    data: {
      kind: 'STORE_OFFER',
      stage: 'AWAITING_PAYMENT',
      commissionerId: OWNER,
      creatorId: CREATOR,
      offerId: over.offerId === undefined ? offerId : over.offerId,
      storeId,
      terms: { format: 'REELS', voucherName: '식사권' },
      settlementMethod: 'PER_VIEW',
    },
  });
}

describe('collaborations', () => {
  it('rejects two collaborations for one offer', async () => {
    await createCollaboration();
    await expect(createCollaboration()).rejects.toThrow();
  });

  it('allows collaborations that have no offer', async () => {
    await createCollaboration({ offerId: null });
    await expect(createCollaboration({ offerId: null })).resolves.toBeDefined();
  });

  it('has the timestamp columns and defaults the stage-less fields to null', async () => {
    const row = await createCollaboration();
    expect(row).toMatchObject({
      fundedAt: null,
      submitDueAt: null,
      haltedReason: null,
      stageBeforeHalt: null,
      deletedAt: null,
    });
    expect(row.createdAt).toBeInstanceOf(Date);
  });
});

describe('ledger_entries', () => {
  async function entry(
    over: Partial<{
      debitAccount: 'PG_IN' | 'ESCROW';
      creditAccount: 'ESCROW' | 'CREATOR_PAYABLE';
      idempotencyKey: string;
    }> = {},
  ) {
    const collaboration = await prisma.collaboration.findFirstOrThrow();
    return prisma.ledgerEntry.create({
      data: {
        collaborationId: collaboration.id,
        batchId: randomUUID(),
        debitAccount: 'PG_IN',
        creditAccount: 'ESCROW',
        amount: 1000,
        reason: 'PAYMENT_APPROVED',
        idempotencyKey: 'payment:1',
        ...over,
      },
    });
  }

  beforeEach(async () => {
    await createCollaboration();
  });

  it('rejects two ledger rows with the same idempotency key and accounts', async () => {
    await entry();
    await expect(entry()).rejects.toThrow();
  });

  it('allows the same idempotency key on different accounts', async () => {
    await entry();
    await expect(
      entry({ debitAccount: 'ESCROW', creditAccount: 'CREATOR_PAYABLE' }),
    ).resolves.toBeDefined();
  });
});

describe('view_snapshots', () => {
  it('rejects a second snapshot for the same collaboration and day and a day outside 0 to 7', async () => {
    const collaboration = await createCollaboration();
    const base = {
      collaborationId: collaboration.id,
      takenAt: new Date('2026-12-02T00:00:00Z'),
    };
    await prisma.viewSnapshot.create({
      data: { ...base, views: null, dayIndex: 3 },
    });
    await expect(
      prisma.viewSnapshot.create({ data: { ...base, views: 5, dayIndex: 3 } }),
    ).rejects.toThrow();
    await expect(
      prisma.viewSnapshot.create({ data: { ...base, views: 5, dayIndex: 8 } }),
    ).rejects.toThrow();
  });
});

describe('payments, settlements, payouts and refunds', () => {
  it('keeps one settlement per collaboration and unique payout idempotency keys', async () => {
    const collaboration = await createCollaboration();
    const settlement = {
      collaborationId: collaboration.id,
      payoutAmount: 100,
      refundAmount: 0,
      settledAt: new Date('2026-12-08T00:00:00Z'),
    };
    await prisma.settlement.create({ data: settlement });
    await expect(
      prisma.settlement.create({ data: settlement }),
    ).rejects.toThrow();

    const payout = {
      collaborationId: collaboration.id,
      amount: 100,
      idempotencyKey: 'payout:1',
      scheduledFor: new Date('2026-12-16T01:00:00Z'),
    };
    await prisma.payout.create({ data: payout });
    await expect(prisma.payout.create({ data: payout })).rejects.toThrow();
    const refund = {
      collaborationId: collaboration.id,
      amount: 100,
      idempotencyKey: 'refund:1',
    };
    await prisma.refund.create({ data: refund });
    await expect(prisma.refund.create({ data: refund })).rejects.toThrow();
  });

  it('rejects a second payment with the same PG transaction id', async () => {
    const collaboration = await createCollaboration();
    const payment = {
      collaborationId: collaboration.id,
      amountEscrow: 100000,
      amountFee: 10000,
      feeRate: 10,
      method: 'CARD' as const,
      pgTransactionId: 'pg-1',
      requestedAt: new Date('2026-12-01T00:00:00Z'),
    };
    await prisma.payment.create({ data: payment });
    await expect(prisma.payment.create({ data: payment })).rejects.toThrow();
  });
});

describe('payout_accounts and instagram_connections', () => {
  it('keeps one payout account and one Instagram connection per creator, and a unique handle', async () => {
    await prisma.payoutAccount.create({
      data: {
        creatorId: CREATOR,
        bankCode: '088',
        accountNumberEnc: 'enc',
        accountLast4: '1234',
        holderName: '홍길동',
      },
    });
    await expect(
      prisma.payoutAccount.create({
        data: {
          creatorId: CREATOR,
          bankCode: '088',
          accountNumberEnc: 'enc',
          accountLast4: '1234',
          holderName: '홍길동',
        },
      }),
    ).rejects.toThrow();

    await prisma.instagramConnection.create({
      data: { creatorId: CREATOR, handle: 'haru', refreshedAt: new Date() },
    });
    await expect(
      prisma.instagramConnection.create({
        data: { creatorId: CREATOR, handle: 'other', refreshedAt: new Date() },
      }),
    ).rejects.toThrow();
    await expect(
      prisma.instagramConnection.create({
        data: { creatorId: OWNER, handle: 'haru', refreshedAt: new Date() },
      }),
    ).rejects.toThrow();
  });
});
