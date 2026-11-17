import { Logger } from '@nestjs/common';
import { Collaboration, Contract, TermsVersion } from '@prisma/client';
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
  } = {},
) {
  const state = {
    latest: opts.latest === undefined ? terms() : opts.latest,
    stage: opts.stage ?? 'AGREED',
    live: opts.live ?? null,
  };
  const created: unknown[] = [];
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
  };
  const service = new ContractsService(
    contracts as never,
    {
      findById: () => Promise.resolve(collaboration({ stage: state.stage })),
      lock: () => Promise.resolve(),
      hasOpenBrandPayment: () => Promise.resolve(false),
    } as never,
    {
      transaction: (run: (tx: object) => Promise<unknown>) => run({}),
      latest: () => Promise.resolve(state.latest),
      versionBefore: () => Promise.resolve(null),
    } as never,
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
  return { service, state, created, notified };
}

const texts = (role: 'CREATOR' | 'BRAND', version = 2) =>
  consentTexts(role, version, 'REPOST_ONLY');

describe('ContractsService', () => {
  // 동의 기록의 보안 로그가 테스트 출력을 어지럽히지 않게 한다.
  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
  });
  afterEach(() => jest.restoreAllMocks());

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
});
