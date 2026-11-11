import { LedgerRepository } from '../../src/ledger/ledger.repository';
import { LedgerService } from '../../src/ledger/ledger.service';
import {
  postingsForFullRefund,
  postingsForPaymentApproved,
  postingsForSettlement,
} from '../../src/ledger/ledger-postings';
import { prisma } from './setup-db';

const OWNER = '66666666-6666-4666-8666-666666666661';
const CREATOR = '66666666-6666-4666-8666-666666666662';

describe('LedgerService', () => {
  const ledger = new LedgerService(new LedgerRepository(prisma as never));
  let collaborationId: string;

  beforeEach(async () => {
    await prisma.user.createMany({
      data: [
        { id: OWNER, role: 'STORE' },
        { id: CREATOR, role: 'CREATOR' },
      ],
    });
    const store = await prisma.store.create({ data: { ownerId: OWNER } });
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: 'AWAITING_PAYMENT',
        commissionerId: OWNER,
        creatorId: CREATOR,
        storeId: store.id,
        terms: { format: 'REELS', rewardType: 'PER_VIEW' },
        settlementMethod: 'PER_VIEW',
      },
    });
    collaborationId = collaboration.id;
  });

  const payment = () =>
    postingsForPaymentApproved({ escrow: 100000, fee: 10000 });
  const rows = () =>
    prisma.ledgerEntry.findMany({ orderBy: { createdAt: 'asc' } });

  it('posts all rows of one call under a single batch id', async () => {
    await expect(
      ledger.post(collaborationId, payment(), 'payment:1'),
    ).resolves.toBe('posted');
    const all = await rows();
    expect(all).toHaveLength(2);
    expect(new Set(all.map((r) => r.batchId)).size).toBe(1);
    expect(all.every((r) => r.idempotencyKey === 'payment:1')).toBe(true);
    expect(all.map((r) => r.amount).sort()).toEqual([10000, 100000]);
  });

  it('returns duplicate and inserts nothing for a repeated idempotency key', async () => {
    await ledger.post(collaborationId, payment(), 'payment:1');
    await expect(
      ledger.post(collaborationId, payment(), 'payment:1'),
    ).resolves.toBe('duplicate');
    expect(await rows()).toHaveLength(2);
    expect(await ledger.escrowBalance(collaborationId)).toBe(100000);
  });

  it('keeps the caller transaction usable after a duplicate', async () => {
    await ledger.post(collaborationId, payment(), 'payment:1');
    // 유일 제약 위반이 트랜잭션을 중단시키지 않아야, 같은 트랜잭션에서 이어서 쓸 수 있다.
    await prisma.$transaction(async (tx) => {
      expect(
        await ledger.post(collaborationId, payment(), 'payment:1', tx),
      ).toBe('duplicate');
      expect(
        await ledger.post(
          collaborationId,
          postingsForSettlement({ payout: 43200, refund: 56800 }),
          'settle:1',
          tx,
        ),
      ).toBe('posted');
    });
    expect(await ledger.escrowBalance(collaborationId)).toBe(0);
    expect(await rows()).toHaveLength(4);
  });

  it('posts inside the caller transaction and rolls back with it', async () => {
    class Abort extends Error {}
    await expect(
      prisma.$transaction(async (tx) => {
        await ledger.post(collaborationId, payment(), 'payment:1', tx);
        throw new Abort();
      }),
    ).rejects.toBeInstanceOf(Abort);
    expect(await rows()).toHaveLength(0);
  });

  it('rolls back the insert when the ledger would become unbalanced', async () => {
    await ledger.post(collaborationId, payment(), 'payment:1');
    // 에스크로(100000)보다 많이 내보내면 음수 잔액이라 던지고, 방금 넣은 줄도 남지 않는다.
    await expect(
      ledger.post(
        collaborationId,
        postingsForSettlement({ payout: 100000, refund: 1 }),
        'settle:1',
      ),
    ).rejects.toThrow(/ESCROW/);
    expect(await rows()).toHaveLength(2);
    expect(await ledger.escrowBalance(collaborationId)).toBe(100000);
  });

  it('throws inside a caller transaction so the caller rolls back its own work', async () => {
    await expect(
      prisma.$transaction(async (tx) => {
        await ledger.post(collaborationId, payment(), 'payment:1', tx);
        await ledger.post(
          collaborationId,
          postingsForFullRefund({ escrow: 100000, fee: 10001 }),
          'refund:1',
          tx,
        );
      }),
    ).rejects.toThrow(/FEE_REVENUE/);
    expect(await rows()).toHaveLength(0);
  });

  it('lets only one of two concurrent calls with the same key insert', async () => {
    const results = await Promise.all([
      ledger.post(collaborationId, payment(), 'payment:1'),
      ledger.post(collaborationId, payment(), 'payment:1'),
    ]);
    expect(results.sort()).toEqual(['duplicate', 'posted']);
    expect(await rows()).toHaveLength(2);
  });

  it('does not let two concurrent settlements overdraw the escrow', async () => {
    await ledger.post(collaborationId, payment(), 'payment:1');
    const settle = (key: string) =>
      ledger.post(
        collaborationId,
        postingsForSettlement({ payout: 60000, refund: 0 }),
        key,
      );
    const results = await Promise.allSettled([
      settle('settle:1'),
      settle('settle:2'),
    ]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect(await ledger.escrowBalance(collaborationId)).toBe(40000);
  });

  it('skips zero amounts and writes nothing when nothing is left', async () => {
    await expect(
      ledger.post(
        collaborationId,
        [
          {
            debit: 'ESCROW',
            credit: 'CREATOR_PAYABLE',
            amount: 0,
            reason: 'X',
          },
        ],
        'noop:1',
      ),
    ).resolves.toBe('posted');
    expect(await rows()).toHaveLength(0);
  });

  it('rejects a negative, fractional or self-to-self posting', async () => {
    const bad = (
      amount: number,
      debit = 'PG_IN' as const,
      credit = 'ESCROW' as const,
    ) =>
      ledger.post(
        collaborationId,
        [{ debit, credit, amount, reason: 'X' }],
        `bad:${amount}`,
      );
    await expect(bad(-5)).rejects.toThrow();
    await expect(bad(1.5)).rejects.toThrow();
    await expect(
      ledger.post(
        collaborationId,
        [{ debit: 'ESCROW', credit: 'ESCROW', amount: 5, reason: 'X' }],
        'bad:self',
      ),
    ).rejects.toThrow();
    expect(await rows()).toHaveLength(0);
  });

  it('computes the escrow balance per collaboration', async () => {
    expect(await ledger.escrowBalance(collaborationId)).toBe(0);
    await ledger.post(collaborationId, payment(), 'payment:1');
    expect(await ledger.escrowBalance(collaborationId)).toBe(100000);
    await ledger.post(
      collaborationId,
      postingsForSettlement({ payout: 43200, refund: 56800 }),
      'settle:1',
    );
    expect(await ledger.escrowBalance(collaborationId)).toBe(0);
  });
});
