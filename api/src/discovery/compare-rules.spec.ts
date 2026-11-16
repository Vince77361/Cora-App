import { compareDiff, CompareValues } from './compare-rules';

const base: CompareValues = {
  format: 'REELS',
  pieces: 1,
  productProvided: true,
  fee: 300000,
  feeBand: 'W300K',
  perfCap: null,
  usageRights: 'REPOST_ONLY',
  startDate: '2026-11-16',
  faceOk: true,
};

describe('compareDiff', () => {
  it('returns nothing for two identical candidates', () => {
    expect(compareDiff(base, { ...base })).toEqual([]);
  });

  it('marks the rows that differ, in the order of the table', () => {
    const other: CompareValues = {
      ...base,
      fee: 350000,
      usageRights: 'ADS_TOO',
      startDate: null,
      faceOk: false,
    };
    expect(compareDiff(base, other)).toEqual(['FEE', 'USAGE', 'START', 'FACE']);
  });

  it('compares the deliverable by format and pieces', () => {
    expect(compareDiff(base, { ...base, pieces: 2 })).toEqual(['DELIVERABLE']);
    expect(compareDiff(base, { ...base, format: 'CARD_NEWS' })).toEqual([
      'DELIVERABLE',
    ]);
  });

  it('compares the benefit and the performance cap', () => {
    expect(compareDiff(base, { ...base, productProvided: false })).toEqual([
      'BENEFIT',
    ]);
    expect(compareDiff(base, { ...base, perfCap: 60000 })).toEqual([
      'PERF_CAP',
    ]);
    expect(
      compareDiff({ ...base, perfCap: 60000 }, { ...base, perfCap: 60000 }),
    ).toEqual([]);
  });

  it('compares the fee by what is shown: an amount against a band is different', () => {
    // "30만 원"(내 제안)과 "30만 원대"(희망 구간)는 보이는 글이 다르다.
    expect(compareDiff(base, { ...base, fee: null })).toEqual(['FEE']);
    // 둘 다 금액이 없으면 구간으로 견준다.
    const a = { ...base, fee: null };
    expect(compareDiff(a, { ...a })).toEqual([]);
    expect(compareDiff(a, { ...a, feeBand: 'W400K' })).toEqual(['FEE']);
    // 금액이 있으면 구간은 보이지 않으므로 구간이 달라도 같은 줄이다.
    expect(compareDiff(base, { ...base, feeBand: 'W500K_PLUS' })).toEqual([]);
  });

  it('compares the start date and treats a missing date as to be discussed', () => {
    const tbd = { ...base, startDate: null };
    expect(compareDiff(tbd, { ...tbd })).toEqual([]);
    expect(compareDiff(base, tbd)).toEqual(['START']);
    expect(compareDiff(base, { ...base, startDate: '2026-11-20' })).toEqual([
      'START',
    ]);
  });
});
