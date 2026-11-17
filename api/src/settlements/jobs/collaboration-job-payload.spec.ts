import { dayIndexOf } from './collaboration-job-payload';

describe('dayIndexOf', () => {
  it('accepts the days of a 7 or 14 day measurement', () => {
    for (const dayIndex of [0, 7, 8, 14]) {
      expect(dayIndexOf({ collaborationId: 'c', dayIndex })).toBe(dayIndex);
    }
  });

  it('rejects a missing, negative, fractional or too large day', () => {
    for (const dayIndex of [undefined, -1, 1.5, 15]) {
      expect(() => dayIndexOf({ collaborationId: 'c', dayIndex })).toThrow(
        '작업에 dayIndex(0~14)가 없어요.',
      );
    }
  });
});
