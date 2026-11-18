import {
  rankStoreCreators,
  StoreCreatorCandidate,
} from './store-creator-rules';

function candidate(
  id: string,
  over: Partial<StoreCreatorCandidate> = {},
): StoreCreatorCandidate {
  return { id, applied: false, tier: 2, joinedAt: 0, ...over };
}

describe('rankStoreCreators', () => {
  it('puts applicants first, then same district, then same province, then the rest', () => {
    const ranked = rankStoreCreators(
      [
        candidate('far'),
        candidate('province', { tier: 1 }),
        candidate('district', { tier: 0 }),
        candidate('applicant', { applied: true }),
      ],
      10,
    );
    expect(ranked.map((c) => c.id)).toEqual([
      'applicant',
      'district',
      'province',
      'far',
    ]);
  });

  it('orders applicants by region first and everyone within a group by newest join', () => {
    const ranked = rankStoreCreators(
      [
        candidate('old', { joinedAt: 1 }),
        candidate('new', { joinedAt: 2 }),
        candidate('applied-far', { applied: true, joinedAt: 9 }),
        candidate('applied-near', { applied: true, tier: 0, joinedAt: 1 }),
      ],
      10,
    );
    expect(ranked.map((c) => c.id)).toEqual([
      'applied-near',
      'applied-far',
      'new',
      'old',
    ]);
  });

  it('breaks complete ties by id so the same input always gives the same list', () => {
    const ranked = rankStoreCreators([candidate('b'), candidate('a')], 10);
    expect(ranked.map((c) => c.id)).toEqual(['a', 'b']);
  });

  it('cuts to the limit without touching the input', () => {
    const input = [candidate('a'), candidate('b'), candidate('c')];
    expect(rankStoreCreators(input, 2)).toHaveLength(2);
    expect(input.map((c) => c.id)).toEqual(['a', 'b', 'c']);
  });
});
