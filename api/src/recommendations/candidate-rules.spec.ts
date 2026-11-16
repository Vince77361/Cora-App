import {
  decidedTargetIds,
  DecisionRow,
  rankCandidates,
  settledTargetIds,
} from './candidate-rules';

describe('rankCandidates', () => {
  const item = (
    id: string,
    over: Partial<{ boosted: boolean; score: number; recency: number }> = {},
  ) => ({ id, boosted: false, score: 0, recency: 0, ...over });

  it('puts boosted items first, then higher scores, then more recent ones', () => {
    const ranked = rankCandidates(
      [
        item('low', { score: 1, recency: 9 }),
        item('recent', { score: 3, recency: 5 }),
        item('old', { score: 3, recency: 1 }),
        item('boosted', { boosted: true, score: 0, recency: 0 }),
      ],
      10,
    );
    expect(ranked.map((r) => r.id)).toEqual([
      'boosted',
      'recent',
      'old',
      'low',
    ]);
  });

  it('keeps only the first limit items and leaves the input alone', () => {
    const input = [item('a', { score: 1 }), item('b', { score: 2 })];
    expect(rankCandidates(input, 1).map((r) => r.id)).toEqual(['b']);
    expect(input.map((r) => r.id)).toEqual(['a', 'b']);
  });

  it('breaks full ties by id so the order is stable', () => {
    expect(rankCandidates([item('b'), item('a')], 10).map((r) => r.id)).toEqual(
      ['a', 'b'],
    );
  });
});

describe('decision sets', () => {
  const at = (iso: string) => new Date(iso);
  const rows: DecisionRow[] = [
    {
      targetId: 'liked',
      decision: 'LIKE',
      updatedAt: at('2026-11-01T00:00:00Z'),
    },
    {
      targetId: 'passed',
      decision: 'PASS',
      updatedAt: at('2026-11-01T00:00:00Z'),
    },
    {
      targetId: 'held-today',
      decision: 'HOLD',
      updatedAt: at('2026-11-11T01:00:00Z'),
    },
    {
      targetId: 'held-before',
      decision: 'HOLD',
      updatedAt: at('2026-11-10T01:00:00Z'),
    },
  ];
  const startOfToday = at('2026-11-10T15:00:00Z');

  it('never lists a liked or passed target again but lets holds come back', () => {
    expect([...settledTargetIds(rows)].sort()).toEqual(['liked', 'passed']);
  });

  it('hides a hold only on the day it was made', () => {
    expect([...decidedTargetIds(rows, startOfToday)].sort()).toEqual([
      'held-today',
      'liked',
      'passed',
    ]);
  });
});
