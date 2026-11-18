import { Logger } from '@nestjs/common';
import { Collaboration, Contract, TermsVersion } from '@prisma/client';
import { PaymentsService } from '../payments/payments.service';
import { toTermsVersionModel } from '../terms/terms-rules';
import { consentTexts } from './consent-texts';
import { snapshotOf } from './contract-snapshot';
import { ContractsService } from './contracts.service';

const NOW = new Date('2026-11-11T03:00:00.000Z');
const BRAND = 'brand-1';
const CREATOR = 'creator-1';
const COLLAB = '00000000-0000-4000-8000-0000000000c1';

const terms = (over: Partial<TermsVersion> = {}): TermsVersion => ({
  id: 't2',
  collaborationId: COLLAB,
  version: 2,
  proposedById: null,
  title: '출근길 한 컵 이야기',
  fee: 350000,
  startDate: new Date('2026-11-20T00:00:00.000Z'),
  format: 'REELS',
  pieces: 1,
  productProvided: true,
  revisionScope: 'GUIDE_1',
  usageRights: 'REPOST_ONLY',
  payoutDays: 7,
  perfRatePerThousand: null,
  perfCap: null,
  brandConfirmedAt: NOW,
  creatorConfirmedAt: NOW,
  createdAt: NOW,
  updatedAt: NOW,
  deletedAt: null,
  ...over,
});

const collaboration = (over: Partial<Collaboration> = {}): Collaboration =>
  ({
    id: COLLAB,
    kind: 'BRAND_CONTRACT',
    stage: 'AGREED',
    commissionerId: BRAND,
    creatorId: CREATOR,
    campaignId: 'camp-1',
    ...over,
  }) as Collaboration;

function build(
  opts: {
    latest?: TermsVersion | null;
    stage?: Collaboration['stage'];
    live?: Contract | null;
    feeRate?: number;
    openPayment?: {
      amountEscrow: number;
      amountFee: number;
      feeRate: number;
    } | null;
  } = {},
) {
  const state = {
    latest: opts.latest === undefined ? terms() : opts.latest,
    stage: opts.stage ?? 'AGREED',
    live: opts.live ?? null,
  };
  const created: unknown[] = [];
  const paymentCalls: unknown[] = [];
  const notified: unknown[] = [];
  const contracts = {
    findLive: () => Promise.resolve(state.live),
    findLatestVoidedByNewTerms: () => Promise.resolve(null),
    create: (data: Record<string, unknown>) => {
      created.push(data);
      const row = { id: 'contract-1', ...data } as unknown as Contract;
      state.live = row;
      return Promise.resolve(row);
    },
    saveBrandConsent: () => Promise.resolve(true),
  };
  const service = new ContractsService(
    contracts as never,
    {
      findById: () => Promise.resolve(collaboration({ stage: state.stage })),
      lock: () => Promise.resolve(),
      findOpenPayment: () => Promise.resolve(opts.openPayment ?? null),
    } as never,
    {
      transaction: (run: (tx: object) => Promise<unknown>) => run({}),
      latest: () => Promise.resolve(state.latest),
      versionBefore: () => Promise.resolve(null),
    } as never,
    {
      brandFeeRate: () => opts.feeRate ?? 10,
      lockOpenPayments: () => Promise.resolve(),
      createForContract: (...args: unknown[]) => {
        paymentCalls.push(args);
        return Promise.resolve({ id: 'pay-1' });
      },
      openCheckout: () =>
        Promise.resolve({ paymentId: 'pay-1', checkoutUrl: 'cora-dev://pay' }),
    } as unknown as PaymentsService,
    { getById: () => Promise.resolve({ headline: '아침 루틴' }) } as never,
    {
      getActor: () =>
        Promise.resolve({ userId: BRAND, name: '느린결', photoPath: null }),
    } as never,
    {
      getActor: () =>
        Promise.resolve({
          userId: CREATOR,
          name: '하루 한 컵',
          photoPath: null,
        }),
      getSummary: () =>
        Promise.resolve({ displayName: '하루 한 컵', photoUrl: null }),
    } as never,
    {
      idForCollaboration: () => Promise.resolve(null),
      postSystem: () => Promise.resolve({ id: 'line-1' }),
      publishCreated: () => Promise.resolve(),
      publishUpdated: () => Promise.resolve(),
    } as never,
    {
      notify: (input: unknown) => {
        notified.push(input);
        return Promise.resolve();
      },
    } as never,
    { now: () => NOW },
  );
  return { service, state, created, paymentCalls, notified };
}

const texts = (role: 'CREATOR' | 'BRAND', version = 2) =>
  consentTexts(role, version, 'REPOST_ONLY');

describe('ContractsService', () => {
  // 동의 기록의 보안 로그가 테스트 출력을 어지럽히지 않게 한다.
  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
  });
  afterEach(() => jest.restoreAllMocks());

  describe('quoteFor', () => {
    it('quotes the fixed fee plus the performance cap and a service fee rounded down', async () => {
      const t = build();
      const model = toTermsVersionModel(
        terms({ perfRatePerThousand: 2000, perfCap: 60000 }),
        BRAND,
        null,
      );
      expect(await t.service.quoteFor(collaboration(), model)).toMatchObject({
        escrow: 410000,
        fee: 41000,
        feeRate: 10,
        total: 451000,
        fixedCash: 350000,
        perViewCap: 60000,
        orderName: '아침 루틴 제작비',
        voucherName: null,
      });
    });

    it('reads the fee rate from the one brand contract setting', async () => {
      const t = build({ feeRate: 15 });
      const model = toTermsVersionModel(terms({ fee: 350000 }), BRAND, null);
      expect(await t.service.quoteFor(collaboration(), model)).toMatchObject({
        fee: 52500,
        total: 402500,
      });
    });
  });

  describe('quote on the contract screen', () => {
    const awaitingBrand = (): Contract =>
      ({
        id: 'contract-1',
        status: 'AWAITING_BRAND',
        termsVersion: 2,
        termsSnapshot: snapshotOf(toTermsVersionModel(terms(), BRAND, null)),
        creatorConsentedAt: NOW,
        brandConsentTexts: [],
      }) as unknown as Contract;

    it('shows the stored fee and escrow of the open payment even after the fee rate setting changed', async () => {
      // 결제는 수수료율 10%로 만들어졌고(35,000원) 지금 설정은 15%다.
      const t = build({
        feeRate: 15,
        live: awaitingBrand(),
        openPayment: { amountEscrow: 350000, amountFee: 35000, feeRate: 10 },
      });
      const res = await t.service.get(BRAND, COLLAB);
      expect(res.status).toBe('PAYING');
      expect(res.quote).toMatchObject({
        escrow: 350000,
        fee: 35000,
        feeRate: 10,
        total: 385000,
      });
    });

    it('quotes with the current fee rate while no payment is open', async () => {
      const t = build({ feeRate: 15, live: awaitingBrand() });
      const res = await t.service.get(BRAND, COLLAB);
      expect(res.status).toBe('AWAITING_BRAND');
      expect(res.quote).toMatchObject({ fee: 52500, feeRate: 15 });
    });
  });

  describe('creator consent', () => {
    it('stores the contract with a snapshot of the agreed version and the consented texts', async () => {
      const t = build();
      const res = await t.service.consentAsCreator(CREATOR, COLLAB, {
        termsVersion: 2,
        accepted: texts('CREATOR'),
      });
      expect(res.status).toBe('AWAITING_BRAND');
      expect(t.created).toHaveLength(1);
      expect(t.created[0]).toMatchObject({
        termsVersion: 2,
        creatorConsentedAt: NOW,
        creatorConsentTexts: texts('CREATOR'),
        termsSnapshot: snapshotOf(toTermsVersionModel(terms(), BRAND, null)),
      });
      expect(t.notified).toHaveLength(1);
    });

    it('returns STALE_VERSION with the latest version when an older version is consented', async () => {
      const t = build({ stage: 'NEGOTIATING' });
      await expect(
        t.service.consentAsCreator(CREATOR, COLLAB, {
          termsVersion: 1,
          accepted: texts('CREATOR', 1),
        }),
      ).rejects.toMatchObject({
        code: 'STALE_VERSION',
        details: { latestVersion: 2 },
      });
      expect(t.created).toHaveLength(0);
    });

    it('refuses when the terms are not agreed yet and when the texts differ', async () => {
      const notYet = build({
        latest: terms({ creatorConfirmedAt: null }),
      });
      await expect(
        notYet.service.consentAsCreator(CREATOR, COLLAB, {
          termsVersion: 2,
          accepted: texts('CREATOR'),
        }),
      ).rejects.toMatchObject({ code: 'CONFLICT' });
      const wrong = build();
      await expect(
        wrong.service.consentAsCreator(CREATOR, COLLAB, {
          termsVersion: 2,
          accepted: texts('BRAND'),
        }),
      ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    });

    it('lets only the creator consent and hides the collaboration from others', async () => {
      const t = build();
      await expect(
        t.service.consentAsCreator(BRAND, COLLAB, {
          termsVersion: 2,
          accepted: texts('CREATOR'),
        }),
      ).rejects.toMatchObject({ code: 'FORBIDDEN' });
      await expect(
        t.service.consentAsCreator('stranger', COLLAB, {
          termsVersion: 2,
          accepted: texts('CREATOR'),
        }),
      ).rejects.toMatchObject({ code: 'NOT_FOUND' });
    });
  });

  describe('brand consent', () => {
    const consentedContract = (over: Partial<Contract> = {}): Contract =>
      ({
        id: 'contract-1',
        status: 'AWAITING_BRAND',
        termsVersion: 2,
        termsSnapshot: snapshotOf(
          toTermsVersionModel(
            terms({ perfRatePerThousand: 2000, perfCap: 60000 }),
            BRAND,
            null,
          ),
        ),
        creatorConsentedAt: NOW,
        brandConsentTexts: [],
        ...over,
      }) as unknown as Contract;

    it('waits for the creator when no contract exists', async () => {
      const t = build();
      await expect(
        t.service.consentAsBrand(BRAND, COLLAB, {
          termsVersion: 2,
          accepted: texts('BRAND'),
          method: 'CARD',
        }),
      ).rejects.toMatchObject({
        code: 'CONFLICT',
        message: '크리에이터의 동의를 기다리고 있어요.',
      });
      expect(t.paymentCalls).toHaveLength(0);
    });

    it('creates the payment from the contract snapshot, not from the latest terms row', async () => {
      // 최신 판본 행은 제작비가 다르지만(거짓 값) 계약 사본의 값으로만 결제를 만든다.
      const t = build({
        latest: terms({ fee: 999990 }),
        live: consentedContract(),
      });
      const res = await t.service.consentAsBrand(BRAND, COLLAB, {
        termsVersion: 2,
        accepted: texts('BRAND'),
        method: 'EASY_PAY',
      });
      expect(res).toEqual({
        paymentId: 'pay-1',
        checkoutUrl: 'cora-dev://pay',
      });
      expect(t.paymentCalls).toHaveLength(1);
      expect(t.paymentCalls[0]).toMatchObject([
        COLLAB,
        {
          fixedCash: 350000,
          performance: { ratePer1000: 2000, cap: 60000 },
          feeRate: 10,
          method: 'EASY_PAY',
        },
        {},
      ]);
    });

    it('refuses wrong texts and an older version without creating a payment', async () => {
      const t = build({ live: consentedContract() });
      await expect(
        t.service.consentAsBrand(BRAND, COLLAB, {
          termsVersion: 2,
          accepted: texts('CREATOR'),
          method: 'CARD',
        }),
      ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
      await expect(
        t.service.consentAsBrand(BRAND, COLLAB, {
          termsVersion: 1,
          accepted: texts('BRAND', 1),
          method: 'CARD',
        }),
      ).rejects.toMatchObject({ code: 'STALE_VERSION' });
      expect(t.paymentCalls).toHaveLength(0);
    });

    it('lets only the commissioning brand consent', async () => {
      const t = build({ live: consentedContract() });
      await expect(
        t.service.consentAsBrand(CREATOR, COLLAB, {
          termsVersion: 2,
          accepted: texts('BRAND'),
          method: 'CARD',
        }),
      ).rejects.toMatchObject({ code: 'FORBIDDEN' });
    });
  });
});
