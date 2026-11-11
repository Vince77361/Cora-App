import { LedgerAccount } from '@prisma/client';
import {
  assertBalanced,
  balances,
  Posting,
  postingsForForcedPayout,
  postingsForFullRefund,
  postingsForPaymentApproved,
  postingsForSettlement,
} from './ledger-postings';

// 줄 묶음을 장부 줄 모양으로 바꾼다(테스트에서 여러 동작의 결과를 이어 붙이려고).
const entries = (...groups: Posting[][]) =>
  groups.flat().map((p) => ({
    debitAccount: p.debit,
    creditAccount: p.credit,
    amount: p.amount,
  }));

describe('ledger postings', () => {
  it('posts payment approval into escrow and fee revenue', () => {
    expect(postingsForPaymentApproved({ escrow: 100000, fee: 10000 })).toEqual([
      {
        debit: 'PG_IN',
        credit: 'ESCROW',
        amount: 100000,
        reason: 'PAYMENT_ESCROW',
      },
      {
        debit: 'PG_IN',
        credit: 'FEE_REVENUE',
        amount: 10000,
        reason: 'PAYMENT_FEE',
      },
    ]);
  });

  it('skips zero amount postings', () => {
    const postings = postingsForPaymentApproved({ escrow: 100000, fee: 0 });
    expect(postings).toHaveLength(1);
    expect(postings[0]).toMatchObject({ credit: 'ESCROW' });
    expect(postingsForSettlement({ payout: 0, refund: 100000 })).toEqual([
      {
        debit: 'ESCROW',
        credit: 'STORE_REFUND',
        amount: 100000,
        reason: 'SETTLEMENT_REFUND',
      },
    ]);
    expect(postingsForSettlement({ payout: 100000, refund: 0 })).toEqual([
      {
        debit: 'ESCROW',
        credit: 'CREATOR_PAYABLE',
        amount: 100000,
        reason: 'SETTLEMENT_PAYOUT',
      },
    ]);
    expect(postingsForForcedPayout({ amount: 0 })).toEqual([]);
  });

  it('keeps the ledger balanced after payment then settlement', () => {
    const all = entries(
      postingsForPaymentApproved({ escrow: 100000, fee: 10000 }),
      postingsForSettlement({ payout: 43200, refund: 56800 }),
    );
    expect(() => assertBalanced(all)).not.toThrow();
    const b = balances(all);
    expect(b.ESCROW).toBe(0);
    expect(b.CREATOR_PAYABLE).toBe(43200);
    expect(b.STORE_REFUND).toBe(56800);
    expect(b.FEE_REVENUE).toBe(10000);
    expect(b.PG_IN).toBe(-110000);
  });

  it('keeps the ledger balanced after payment then full refund', () => {
    const all = entries(
      postingsForPaymentApproved({ escrow: 100000, fee: 10000 }),
      postingsForFullRefund({ escrow: 100000, fee: 10000 }),
    );
    expect(() => assertBalanced(all)).not.toThrow();
    const b = balances(all);
    expect(b.ESCROW).toBe(0);
    expect(b.FEE_REVENUE).toBe(0);
    expect(b.STORE_REFUND).toBe(110000);
  });

  it('keeps the ledger balanced after a forced payout of the whole escrow', () => {
    const all = entries(
      postingsForPaymentApproved({ escrow: 100000, fee: 10000 }),
      postingsForForcedPayout({ amount: 100000 }),
    );
    expect(() => assertBalanced(all)).not.toThrow();
    expect(balances(all).CREATOR_PAYABLE).toBe(100000);
  });

  it('returns zero balances for every account when there are no entries', () => {
    const b = balances([]);
    const accounts: LedgerAccount[] = [
      'PG_IN',
      'ESCROW',
      'CREATOR_PAYABLE',
      'STORE_REFUND',
      'FEE_REVENUE',
    ];
    for (const account of accounts) expect(b[account]).toBe(0);
  });

  it('throws when escrow would go negative', () => {
    const all = entries(
      postingsForPaymentApproved({ escrow: 100000, fee: 10000 }),
      postingsForSettlement({ payout: 100000, refund: 1 }),
    );
    expect(() => assertBalanced(all)).toThrow(/ESCROW/);
  });

  it('throws when fee revenue would go negative', () => {
    const all = entries(
      postingsForPaymentApproved({ escrow: 100000, fee: 10000 }),
      postingsForFullRefund({ escrow: 100000, fee: 10001 }),
    );
    expect(() => assertBalanced(all)).toThrow(/FEE_REVENUE/);
  });

  it('throws when the conservation identity breaks', () => {
    // 돈이 PG_IN으로 되돌아 들어오면 "PG_IN에서 나간 합"이 설명하지 못하는 잔액이 생긴다.
    const all = entries(
      postingsForPaymentApproved({ escrow: 100000, fee: 10000 }),
    );
    all.push({
      debitAccount: 'CREATOR_PAYABLE',
      creditAccount: 'ESCROW',
      amount: 5,
    });
    expect(() => assertBalanced(all)).toThrow();
  });
});
