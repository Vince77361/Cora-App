import { TermsVersionModel } from '../terms/dto/terms-version.model';
import {
  maxCashOfSnapshot,
  readSnapshot,
  snapshotOf,
} from './contract-snapshot';

const model = (over: Partial<TermsVersionModel> = {}): TermsVersionModel => ({
  version: 2,
  proposedBy: 'BRAND',
  title: '출근길 한 컵 이야기',
  fee: 350000,
  performance: { ratePer1000: 2000, cap: 60000 },
  maxCash: 410000,
  previousMaxCash: 350000,
  startDate: '2026-11-20',
  format: 'REELS',
  pieces: 1,
  productProvided: true,
  revisionScope: 'GUIDE_1',
  usageRights: 'ADS_TOO',
  payoutDays: 14,
  brandConfirmed: true,
  creatorConfirmed: true,
  changedFields: [],
  createdAt: '2026-11-11T03:00:00.000Z',
  ...over,
});

describe('contract snapshot', () => {
  it('round-trips the agreed terms and derives the max cash from the copy', () => {
    const copy = readSnapshot(snapshotOf(model()));
    expect(copy).toMatchObject({
      version: 2,
      fee: 350000,
      usageRights: 'ADS_TOO',
    });
    expect(maxCashOfSnapshot(copy)).toBe(410000);
    expect(
      maxCashOfSnapshot(
        readSnapshot(snapshotOf(model({ performance: null, maxCash: 350000 }))),
      ),
    ).toBe(350000);
  });

  it('refuses a copy whose money fields do not agree', () => {
    expect(() => readSnapshot(snapshotOf(model({ maxCash: 999 })))).toThrow();
    expect(() => readSnapshot(snapshotOf(model({ fee: -1 })))).toThrow();
    expect(() => readSnapshot({})).toThrow();
    expect(() => readSnapshot(null)).toThrow();
    expect(() =>
      readSnapshot(
        snapshotOf(model({ usageRights: 'STORE_REPOST_3M' as never })),
      ),
    ).toThrow();
  });
});
