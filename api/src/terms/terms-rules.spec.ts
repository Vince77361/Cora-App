import type { TermsVersion } from '@prisma/client';
import {
  isMyTurn,
  proposedByOf,
  termsMaxCash,
  termsNotice,
  toTermsVersionModel,
} from './terms-rules';

const row = (over: Partial<TermsVersion> = {}): TermsVersion => ({
  id: 't1',
  collaborationId: 'c1',
  version: 1,
  proposedById: null,
  title: '출근길 한 컵 이야기',
  fee: 300000,
  startDate: new Date('2026-11-20T00:00:00.000Z'),
  format: 'REELS',
  pieces: 1,
  productProvided: true,
  revisionScope: 'GUIDE_1',
  usageRights: 'REPOST_ONLY',
  payoutDays: 7,
  perfRatePerThousand: null,
  perfCap: null,
  brandConfirmedAt: null,
  creatorConfirmedAt: null,
  createdAt: new Date('2026-11-11T03:00:00.000Z'),
  updatedAt: new Date('2026-11-11T03:00:00.000Z'),
  deletedAt: null,
  ...over,
});

describe('termsNotice', () => {
  it('builds the notice line from the creator principles', () => {
    expect(termsNotice({ faceOk: false, scriptOk: false })).toBe(
      '얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.',
    );
    expect(termsNotice({ faceOk: false, scriptOk: true })).toBe(
      '얼굴 출연은 진행하지 않아요.',
    );
    expect(termsNotice({ faceOk: true, scriptOk: false })).toBe(
      '제품 설명문 낭독은 진행하지 않아요.',
    );
    expect(termsNotice({ faceOk: true, scriptOk: true })).toBeNull();
    expect(termsNotice(null)).toBeNull();
  });
});

describe('proposedByOf', () => {
  it('tells the server, the brand and the creator apart', () => {
    expect(proposedByOf(null, 'brand')).toBe('SYSTEM');
    expect(proposedByOf('brand', 'brand')).toBe('BRAND');
    expect(proposedByOf('creator', 'brand')).toBe('CREATOR');
  });
});

describe('toTermsVersionModel', () => {
  it('maps the stored version and uses the cash burden function for maxCash', () => {
    expect(toTermsVersionModel(row(), 'brand')).toEqual({
      version: 1,
      proposedBy: 'SYSTEM',
      title: '출근길 한 컵 이야기',
      fee: 300000,
      performance: null,
      maxCash: 300000,
      startDate: '2026-11-20',
      format: 'REELS',
      pieces: 1,
      productProvided: true,
      revisionScope: 'GUIDE_1',
      usageRights: 'REPOST_ONLY',
      payoutDays: 7,
      brandConfirmed: false,
      creatorConfirmed: false,
    });
  });

  it('adds the performance cap to the maximum cash burden', () => {
    const model = toTermsVersionModel(
      row({ perfRatePerThousand: 2000, perfCap: 60000 }),
      'brand',
    );
    expect(model.performance).toEqual({ ratePer1000: 2000, cap: 60000 });
    expect(model.maxCash).toBe(360000);
  });

  it('reports who confirmed', () => {
    const model = toTermsVersionModel(
      row({ brandConfirmedAt: new Date('2026-11-11T04:00:00.000Z') }),
      'brand',
    );
    expect(model.brandConfirmed).toBe(true);
    expect(model.creatorConfirmed).toBe(false);
  });
});

describe('isMyTurn', () => {
  it('is my turn while my side has not confirmed the version', () => {
    const at = new Date('2026-11-11T04:00:00.000Z');
    expect(isMyTurn(row(), true)).toBe(true);
    expect(isMyTurn(row(), false)).toBe(true);
    expect(isMyTurn(row({ creatorConfirmedAt: at }), true)).toBe(false);
    expect(isMyTurn(row({ creatorConfirmedAt: at }), false)).toBe(true);
    expect(isMyTurn(row({ brandConfirmedAt: at }), false)).toBe(false);
  });
});

describe('termsMaxCash', () => {
  it('is the fee plus the performance cap and the same number the version model shows', () => {
    const withPerf = row({ perfRatePerThousand: 2000, perfCap: 60000 });
    expect(termsMaxCash(row())).toBe(300000);
    expect(termsMaxCash(withPerf)).toBe(360000);
    expect(toTermsVersionModel(withPerf, 'brand').maxCash).toBe(360000);
  });
});
