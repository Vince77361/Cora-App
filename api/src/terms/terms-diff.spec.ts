import { diffTerms, TermsDiffValues } from './terms-diff';

const base = (over: Partial<TermsDiffValues> = {}): TermsDiffValues => ({
  title: '아침 한 컵',
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
  ...over,
});

describe('diffTerms', () => {
  it('lists the changed fields between two versions', () => {
    const next = base({
      fee: 350000,
      startDate: new Date('2026-11-25T00:00:00.000Z'),
    });
    expect(diffTerms(base(), next)).toEqual(['FEE', 'START_DATE']);
  });

  it('is empty for version 1 and for identical versions', () => {
    expect(diffTerms(null, base())).toEqual([]);
    expect(diffTerms(base(), base())).toEqual([]);
  });

  it('treats the same date as unchanged even for a different Date object', () => {
    const same = base({ startDate: new Date('2026-11-20T00:00:00.000Z') });
    expect(diffTerms(base(), same)).toEqual([]);
  });

  it('maps format and pieces to DELIVERABLE once', () => {
    expect(diffTerms(base(), base({ format: 'SHORTS' }))).toEqual([
      'DELIVERABLE',
    ]);
    expect(diffTerms(base(), base({ pieces: 2 }))).toEqual(['DELIVERABLE']);
    expect(diffTerms(base(), base({ format: 'BLOG', pieces: 3 }))).toEqual([
      'DELIVERABLE',
    ]);
  });

  it('maps the performance bonus on, off, rate and cap to PERFORMANCE', () => {
    const on = base({ perfRatePerThousand: 2000, perfCap: 60000 });
    expect(diffTerms(base(), on)).toEqual(['PERFORMANCE']);
    expect(diffTerms(on, base())).toEqual(['PERFORMANCE']);
    expect(
      diffTerms(on, base({ perfRatePerThousand: 2500, perfCap: 60000 })),
    ).toEqual(['PERFORMANCE']);
    expect(
      diffTerms(on, base({ perfRatePerThousand: 2000, perfCap: 70000 })),
    ).toEqual(['PERFORMANCE']);
  });

  it('reports every field in the fixed order', () => {
    const next = base({
      title: '다른 제목',
      fee: 310000,
      perfRatePerThousand: 1000,
      perfCap: 10000,
      startDate: new Date('2026-12-01T00:00:00.000Z'),
      pieces: 2,
      productProvided: false,
      revisionScope: 'DRAFT_2',
      usageRights: 'ADS_TOO',
      payoutDays: 14,
    });
    expect(diffTerms(base(), next)).toEqual([
      'TITLE',
      'FEE',
      'PERFORMANCE',
      'START_DATE',
      'DELIVERABLE',
      'PRODUCT',
      'REVISION',
      'USAGE',
      'PAYOUT',
    ]);
  });
});
