import { measurementDaysOf, measurementStageOf } from './measurement';

const DAY = 24 * 60 * 60 * 1000;
const T0 = new Date('2026-12-01T03:00:00.000Z');

describe('measurementStageOf', () => {
  it('measures a store offer while it is counting and a brand contract while it is published', () => {
    expect(measurementStageOf('STORE_OFFER')).toBe('COUNTING');
    expect(measurementStageOf('BRAND_CONTRACT')).toBe('PUBLISHED');
  });
});

describe('measurementDaysOf', () => {
  it('reads the number of days from the submission to the end of the period', () => {
    for (const days of [7, 14]) {
      expect(
        measurementDaysOf({
          submittedAt: T0,
          countingEndsAt: new Date(T0.getTime() + days * DAY),
        }),
      ).toBe(days);
    }
  });

  it('falls back to the store offer period when the times are missing', () => {
    expect(measurementDaysOf({ submittedAt: null, countingEndsAt: null })).toBe(
      7,
    );
  });
});
