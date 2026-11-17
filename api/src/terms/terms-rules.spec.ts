import type { TermsVersion } from '@prisma/client';
import {
  agreementOf,
  isMyTurn,
  proposedByOf,
  termsMaxCash,
  principleFieldLabels,
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

describe('principleFieldLabels', () => {
  it('names the chosen fields in the order the creator chose them', () => {
    expect(principleFieldLabels({ fields: ['LIVING', 'FASHION'] })).toEqual([
      '리빙·소품',
      '패션',
    ]);
    expect(principleFieldLabels({ fields: ['ACCESSORY'] })).toEqual([
      '액세서리·주얼리',
    ]);
  });

  it('is empty without principles or fields', () => {
    expect(principleFieldLabels(null)).toEqual([]);
    expect(principleFieldLabels({ fields: [] })).toEqual([]);
  });
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
    expect(toTermsVersionModel(row(), 'brand', null)).toEqual({
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
      changedFields: [],
      createdAt: '2026-11-11T03:00:00.000Z',
      previousMaxCash: null,
    });
  });

  it('reports the fields and the maximum cash burden of the version before', () => {
    const previous = row({ fee: 300000 });
    const model = toTermsVersionModel(
      row({
        version: 2,
        fee: 350000,
        perfRatePerThousand: 2000,
        perfCap: 60000,
      }),
      'brand',
      previous,
    );
    expect(model.changedFields).toEqual(['FEE', 'PERFORMANCE']);
    expect(model.maxCash).toBe(410000);
    expect(model.previousMaxCash).toBe(300000);
  });

  it('adds the performance cap to the maximum cash burden', () => {
    const model = toTermsVersionModel(
      row({ perfRatePerThousand: 2000, perfCap: 60000 }),
      'brand',
      null,
    );
    expect(model.performance).toEqual({ ratePer1000: 2000, cap: 60000 });
    expect(model.maxCash).toBe(360000);
  });

  it('reports who confirmed', () => {
    const model = toTermsVersionModel(
      row({ brandConfirmedAt: new Date('2026-11-11T04:00:00.000Z') }),
      'brand',
      null,
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
    expect(toTermsVersionModel(withPerf, 'brand', null).maxCash).toBe(360000);
  });
});

describe('agreementOf', () => {
  const at = new Date('2026-11-11T04:00:00.000Z');
  it('reads only the confirmations of the version it is given', () => {
    expect(agreementOf(row())).toBe('NONE');
    expect(agreementOf(row({ creatorConfirmedAt: at }))).toBe('WAITING_BRAND');
    expect(agreementOf(row({ brandConfirmedAt: at }))).toBe('WAITING_CREATOR');
    expect(
      agreementOf(row({ brandConfirmedAt: at, creatorConfirmedAt: at })),
    ).toBe('AGREED');
  });
});
