import { Collaboration, Payout, Settlement } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { LedgerService } from '../ledger/ledger.service';
import { PayoutAccountModel } from '../payout-accounts/dto/payout-account.model';
import { PayoutAccountsService } from '../payout-accounts/payout-accounts.service';
import { SettlementsService } from '../settlements/settlements.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { WalletService } from './wallet.service';

const CREATOR = '11111111-1111-4111-8111-111111111111';
// 한국 시간 2026-11-12(목) 12:00.
const NOW = new Date('2026-11-12T03:00:00.000Z');
// 지급일 규칙(수요일 10:00 KST): 11월 10일(화) 확정은 11월 18일(수), 10월 28일(수) 10시 송금.
const PAYDAY_1118 = new Date('2026-11-18T01:00:00.000Z');
const PAYDAY_1104 = new Date('2026-11-04T01:00:00.000Z');

class FixedClock extends Clock {
  now(): Date {
    return new Date(NOW);
  }
}

class FakeUsers extends UsersService {
  role: 'CREATOR' | 'STORE' | null = 'CREATOR';
  constructor() {
    super(null as never);
  }
  getRole() {
    return Promise.resolve(this.role);
  }
}

class FakeCollaborations extends CollaborationsRepository {
  rows: Collaboration[] = [];
  askedFor: string[] = [];
  constructor() {
    super(null as never);
  }
  listByCreator(creatorId: string) {
    this.askedFor.push(creatorId);
    return Promise.resolve(this.rows.filter((r) => r.creatorId === creatorId));
  }
}

class FakeSettlements extends SettlementsService {
  payoutRows: Payout[] = [];
  settlementRows: Settlement[] = [];
  constructor() {
    super(
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
    );
  }
  payoutsOfCreator(creatorId: string) {
    const mine = new Set(
      fakeCollaborations.rows
        .filter((c) => c.creatorId === creatorId)
        .map((c) => c.id),
    );
    return Promise.resolve(
      this.payoutRows.filter((p) => mine.has(p.collaborationId)),
    );
  }
  settlementsOf(ids: string[]) {
    return Promise.resolve(
      new Map(
        this.settlementRows
          .filter((s) => ids.includes(s.collaborationId))
          .map((s) => [s.collaborationId, s]),
      ),
    );
  }
}

class FakeLedger extends LedgerService {
  balances = new Map<string, number>();
  asked: string[][] = [];
  constructor() {
    super(null as never);
  }
  escrowBalances(ids: string[]) {
    this.asked.push(ids);
    return Promise.resolve(
      new Map(ids.map((id) => [id, this.balances.get(id) ?? 0])),
    );
  }
}

class FakeAccounts extends PayoutAccountsService {
  account: PayoutAccountModel | null = null;
  constructor() {
    super(null as never, null as never, null as never);
  }
  findMine() {
    return Promise.resolve(this.account);
  }
}

class FakeStores extends StoresService {
  constructor() {
    super(
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
    );
  }
  getOfferCard(storeId: string) {
    return Promise.resolve({
      summary: {
        name: storeId === 'store-ramen' ? '한그릇 라멘' : '하루 한 컵',
      },
    } as never);
  }
}

// 이 파일 안에서 payoutsOfCreator가 협업의 주인을 알아야 해서 모듈 변수로 둔다.
let fakeCollaborations: FakeCollaborations;

let seq = 0;
function collaboration(over: Partial<Collaboration> = {}): Collaboration {
  seq += 1;
  return {
    id: `c-${seq}`,
    kind: 'STORE_OFFER',
    stage: 'FUNDED',
    commissionerId: 'owner',
    creatorId: CREATOR,
    offerId: null,
    storeId: 'store-ramen',
    terms: {
      format: 'REELS',
      rewardType: 'PER_VIEW',
      voucherName: null,
      voucherValue: null,
      perViewAmount: 10,
      perViewCap: 100000,
    },
    settlementMethod: 'PER_VIEW',
    fundedAt: new Date('2026-11-02T03:00:00.000Z'),
    submitDueAt: null,
    submittedUrl: null,
    submittedAt: null,
    countingEndsAt: null,
    haltedReason: null,
    stageBeforeHalt: null,
    createdAt: new Date('2026-11-01T03:00:00.000Z'),
    updatedAt: new Date('2026-11-01T03:00:00.000Z'),
    deletedAt: null,
    ...over,
  };
}

function payout(over: Partial<Payout> & { collaborationId: string }): Payout {
  seq += 1;
  return {
    id: `p-${seq}`,
    amount: 43200,
    status: 'PENDING',
    externalId: null,
    idempotencyKey: `k-${seq}`,
    scheduledFor: PAYDAY_1118,
    createdAt: new Date('2026-11-10T03:00:00.000Z'),
    updatedAt: new Date('2026-11-10T03:00:00.000Z'),
    deletedAt: null,
    ...over,
  };
}

function settlement(
  collaborationId: string,
  settledAt: Date,
  finalViews: number | null = 4320,
): Settlement {
  return {
    id: `s-${collaborationId}`,
    collaborationId,
    finalViews,
    payoutAmount: 43200,
    refundAmount: 56800,
    settledAt,
    createdAt: settledAt,
    updatedAt: settledAt,
    deletedAt: null,
  };
}

describe('WalletService', () => {
  let users: FakeUsers;
  let settlements: FakeSettlements;
  let ledger: FakeLedger;
  let accounts: FakeAccounts;
  let service: WalletService;

  beforeEach(() => {
    seq = 0;
    users = new FakeUsers();
    fakeCollaborations = new FakeCollaborations();
    settlements = new FakeSettlements();
    ledger = new FakeLedger();
    accounts = new FakeAccounts();
    service = new WalletService(
      users,
      fakeCollaborations,
      settlements,
      ledger,
      accounts,
      new FakeStores(),
      new FixedClock(),
    );
  });

  it('shows the next payday and its total', async () => {
    const a = collaboration({ stage: 'SETTLED' });
    const b = collaboration({ stage: 'SETTLED' });
    const later = collaboration({ stage: 'SETTLED' });
    fakeCollaborations.rows = [a, b, later];
    settlements.payoutRows = [
      payout({ collaborationId: a.id, amount: 43200 }),
      // 같은 날(한국 시간)의 지급은 합친다.
      payout({ collaborationId: b.id, amount: 10000 }),
      payout({
        collaborationId: later.id,
        amount: 99000,
        scheduledFor: new Date('2026-11-25T01:00:00.000Z'),
      }),
    ];
    settlements.settlementRows = [
      settlement(a.id, new Date('2026-11-10T03:00:00.000Z')),
    ];

    const wallet = await service.get(CREATOR);

    expect(wallet.nextPayout).toEqual({ date: '2026-11-18', amount: 53200 });
  });

  it('has no next payout when nothing is pending', async () => {
    const c = collaboration({ stage: 'SETTLED' });
    fakeCollaborations.rows = [c];
    settlements.payoutRows = [
      payout({
        collaborationId: c.id,
        status: 'DONE',
        scheduledFor: PAYDAY_1104,
        updatedAt: PAYDAY_1104,
      }),
    ];
    expect((await service.get(CREATOR)).nextPayout).toBeNull();
  });

  it('sums payouts done this month in KST only', async () => {
    const c = collaboration({ stage: 'SETTLED' });
    fakeCollaborations.rows = [c];
    settlements.payoutRows = [
      payout({
        collaborationId: c.id,
        amount: 350000,
        status: 'DONE',
        scheduledFor: PAYDAY_1104,
        updatedAt: PAYDAY_1104,
      }),
      // 10월 31일 23시 KST에 끝난 지급은 11월 합계에 들어가지 않는다.
      payout({
        collaborationId: c.id,
        amount: 77000,
        status: 'DONE',
        updatedAt: new Date('2026-10-31T14:00:00.000Z'),
      }),
      // 11월 1일 0시 KST는 들어간다.
      payout({
        collaborationId: c.id,
        amount: 5000,
        status: 'DONE',
        updatedAt: new Date('2026-10-31T15:00:00.000Z'),
      }),
      // 아직 보내지 않은 지급과 실패한 지급은 받은 돈이 아니다.
      payout({ collaborationId: c.id, amount: 1, status: 'PENDING' }),
      payout({ collaborationId: c.id, amount: 2, status: 'FAILED' }),
    ];

    expect((await service.get(CREATOR)).receivedThisMonth).toBe(355000);
  });

  it('sums escrow balances of my money-held collaborations', async () => {
    const counting = collaboration({ stage: 'COUNTING' });
    const halted = collaboration({
      stage: 'HALTED',
      stageBeforeHalt: 'COUNTING',
    });
    const settled = collaboration({ stage: 'SETTLED' });
    fakeCollaborations.rows = [counting, halted, settled];
    // 조회수당 결제 뒤에는 상한(100,000원)이 보관액이다.
    ledger.balances = new Map([
      [counting.id, 100000],
      [halted.id, 30000],
      [settled.id, 999],
    ]);

    const wallet = await service.get(CREATOR);

    expect(wallet.heldAmount).toBe(130000);
    // 돈이 보관 중이 아닌 협업의 잔액은 읽지도 않는다.
    expect(ledger.asked).toEqual([[counting.id, halted.id]]);
  });

  it('lists scheduled, done, held and voucher rows in canvas order', async () => {
    const ramen = collaboration({
      stage: 'SETTLED',
      terms: {
        format: 'REELS',
        rewardType: 'BOTH',
        voucherName: '2인 식사권',
        voucherValue: 40000,
        perViewAmount: 10,
        perViewCap: 100000,
      },
      submittedAt: new Date('2026-11-03T03:00:00.000Z'),
    });
    const moa = collaboration({ stage: 'SETTLED', storeId: 'store-moa' });
    const cup = collaboration({
      stage: 'COUNTING',
      storeId: 'store-cup',
      terms: {
        format: 'CARD_NEWS',
        rewardType: 'PER_VIEW',
        voucherName: null,
        voucherValue: null,
        perViewAmount: 10,
        perViewCap: 100000,
      },
      fundedAt: new Date('2026-11-05T03:00:00.000Z'),
    });
    fakeCollaborations.rows = [cup, moa, ramen];
    settlements.settlementRows = [
      settlement(ramen.id, new Date('2026-11-10T03:00:00.000Z')),
      settlement(moa.id, new Date('2026-10-28T03:00:00.000Z'), 35000),
    ];
    settlements.payoutRows = [
      payout({ collaborationId: ramen.id, amount: 43200 }),
      payout({
        collaborationId: moa.id,
        amount: 350000,
        status: 'DONE',
        scheduledFor: PAYDAY_1104,
        updatedAt: PAYDAY_1104,
      }),
    ];
    ledger.balances = new Map([[cup.id, 100000]]);

    const { entries } = await service.get(CREATOR);

    expect(
      entries.map((e) => [e.counterpartName, e.kind, e.amount, e.at]),
    ).toEqual([
      ['한그릇 라멘', 'PAYOUT_SCHEDULED', 43200, '2026-11-10T03:00:00.000Z'],
      // 식사권 줄은 같은 협업의 돈 줄 바로 아래이고 같은 기준 시각을 쓴다.
      ['한그릇 라멘', 'VOUCHER', null, '2026-11-10T03:00:00.000Z'],
      ['하루 한 컵', 'HELD', 100000, '2026-11-05T03:00:00.000Z'],
      ['하루 한 컵', 'PAYOUT_DONE', 350000, '2026-11-04T01:00:00.000Z'],
    ]);
    expect(entries[0]).toMatchObject({
      format: 'REELS',
      pieces: 1,
      views: 4320,
      stage: 'SETTLED',
    });
    expect(entries[2]).toMatchObject({
      format: 'CARD_NEWS',
      stage: 'COUNTING',
    });
  });

  it('marks the voucher used once the link is submitted', async () => {
    const terms = {
      format: 'REELS',
      rewardType: 'VOUCHER',
      voucherName: '2인 식사권',
      voucherValue: 40000,
      perViewAmount: null,
      perViewCap: null,
    };
    const before = collaboration({
      terms,
      settlementMethod: 'NONE',
      submittedAt: null,
    });
    const after = collaboration({
      terms,
      settlementMethod: 'NONE',
      stage: 'SETTLED',
      submittedAt: new Date('2026-11-06T03:00:00.000Z'),
    });
    fakeCollaborations.rows = [before, after];

    const { entries } = await service.get(CREATOR);

    // 식사권만 있는 협업에는 식사권 줄 하나뿐이다.
    expect(entries.map((e) => e.kind)).toEqual(['VOUCHER', 'VOUCHER']);
    const byId = new Map(entries.map((e) => [e.collaborationId, e]));
    expect(byId.get(before.id)).toMatchObject({
      voucherName: '2인 식사권',
      voucherUsed: false,
      amount: null,
    });
    expect(byId.get(after.id)?.voucherUsed).toBe(true);
  });

  it('leaves out cancelled and refunded collaborations', async () => {
    const voucherTerms = {
      format: 'REELS',
      rewardType: 'BOTH',
      voucherName: '2인 식사권',
      voucherValue: 40000,
      perViewAmount: 10,
      perViewCap: 100000,
    };
    fakeCollaborations.rows = [
      collaboration({ stage: 'CANCELLED', terms: voucherTerms }),
      collaboration({ stage: 'REFUNDED', terms: voucherTerms }),
      collaboration({ stage: 'AWAITING_PAYMENT', fundedAt: null }),
    ];

    const wallet = await service.get(CREATOR);

    expect(wallet.entries).toEqual([]);
    expect(wallet.heldAmount).toBe(0);
  });

  it('keeps a failed payout visible', async () => {
    const c = collaboration({ stage: 'SETTLED' });
    fakeCollaborations.rows = [c];
    settlements.settlementRows = [
      settlement(c.id, new Date('2026-11-10T03:00:00.000Z')),
    ];
    settlements.payoutRows = [
      payout({ collaborationId: c.id, status: 'FAILED' }),
    ];

    const wallet = await service.get(CREATOR);

    expect(wallet.entries.map((e) => e.kind)).toEqual(['PAYOUT_FAILED']);
    // 실패한 지급은 다음 지급 예정에 들어가지 않는다.
    expect(wallet.nextPayout).toBeNull();
  });

  it('returns a null account before registration and the stored fields after', async () => {
    expect((await service.get(CREATOR)).account).toBeNull();
    accounts.account = {
      bankCode: '004',
      bankName: '국민',
      bankFullName: '국민은행',
      accountLast4: '6789',
      holderName: '김민지',
    };
    expect((await service.get(CREATOR)).account).toEqual({
      bankName: '국민',
      bankFullName: '국민은행',
      accountLast4: '6789',
      holderName: '김민지',
    });
  });

  it('refuses a non-creator', async () => {
    for (const role of ['STORE', 'BRAND', null] as const) {
      users.role = role as never;
      const error = await service.get(CREATOR).catch((e: unknown) => e);
      expect(error).toBeInstanceOf(AppError);
      expect((error as AppError).code).toBe('FORBIDDEN');
    }
  });

  it('only reads rows of the requesting creator', async () => {
    const mine = collaboration({ stage: 'COUNTING' });
    const theirs = collaboration({
      stage: 'COUNTING',
      creatorId: '22222222-2222-4222-8222-222222222222',
    });
    fakeCollaborations.rows = [mine, theirs];
    ledger.balances = new Map([
      [mine.id, 100000],
      [theirs.id, 500000],
    ]);

    const wallet = await service.get(CREATOR);

    expect(fakeCollaborations.askedFor).toEqual([CREATOR]);
    expect(wallet.heldAmount).toBe(100000);
    expect(wallet.entries.map((e) => e.collaborationId)).toEqual([mine.id]);
  });
});
