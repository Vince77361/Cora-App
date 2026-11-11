import {
  kstTimeOnDate,
  kstWeekdayFromMonday,
  startOfKstDay,
  startOfKstWeek,
} from './kst';

describe('startOfKstDay', () => {
  it('returns midnight Korea time of the Korean day that contains the instant', () => {
    // 2026-11-11 12:00 KST
    expect(startOfKstDay(new Date('2026-11-11T03:00:00.000Z'))).toEqual(
      new Date('2026-11-10T15:00:00.000Z'),
    );
  });

  it('keeps the instant that is exactly midnight Korea time on that day', () => {
    expect(startOfKstDay(new Date('2026-11-10T15:00:00.000Z'))).toEqual(
      new Date('2026-11-10T15:00:00.000Z'),
    );
  });

  it('puts the last millisecond before midnight Korea time on the previous Korean day', () => {
    expect(startOfKstDay(new Date('2026-11-10T14:59:59.999Z'))).toEqual(
      new Date('2026-11-09T15:00:00.000Z'),
    );
  });

  it('uses the Korean date even when the UTC date is still the day before', () => {
    // 2026-11-12 05:00 KST는 UTC로는 11일 20:00이다.
    expect(startOfKstDay(new Date('2026-11-11T20:00:00.000Z'))).toEqual(
      new Date('2026-11-11T15:00:00.000Z'),
    );
  });

  it('does not change the date it was given', () => {
    const at = new Date('2026-11-11T03:00:00.000Z');
    startOfKstDay(at);
    expect(at).toEqual(new Date('2026-11-11T03:00:00.000Z'));
  });
});

describe('kstTimeOnDate', () => {
  it('returns the Korea wall-clock time on the Korean day of the date', () => {
    expect(kstTimeOnDate(new Date('2026-11-11T03:00:00.000Z'), 10)).toEqual(
      new Date('2026-11-11T01:00:00.000Z'),
    );
  });

  it('follows the Korean date rather than the UTC date', () => {
    // 한국 시간 11월 12일 05:00의 "그날 10:00"은 12일 10:00 KST다.
    expect(kstTimeOnDate(new Date('2026-11-11T20:00:00.000Z'), 10)).toEqual(
      new Date('2026-11-12T01:00:00.000Z'),
    );
  });

  it('accepts minutes', () => {
    expect(kstTimeOnDate(new Date('2026-11-11T03:00:00.000Z'), 22, 30)).toEqual(
      new Date('2026-11-11T13:30:00.000Z'),
    );
  });

  it('rejects an hour or minute that does not exist', () => {
    const at = new Date('2026-11-11T03:00:00.000Z');
    expect(() => kstTimeOnDate(at, 24)).toThrow();
    expect(() => kstTimeOnDate(at, -1)).toThrow();
    expect(() => kstTimeOnDate(at, 10, 60)).toThrow();
    expect(() => kstTimeOnDate(at, 1.5)).toThrow();
  });
});

describe('kstWeekdayFromMonday', () => {
  it('counts monday as 0 and sunday as 6 by the Korean date', () => {
    // 2026-11-09는 월요일이다.
    expect(kstWeekdayFromMonday(new Date('2026-11-09T00:00:00+09:00'))).toBe(0);
    expect(kstWeekdayFromMonday(new Date('2026-11-11T12:00:00+09:00'))).toBe(2);
    expect(kstWeekdayFromMonday(new Date('2026-11-15T23:59:59+09:00'))).toBe(6);
  });

  it('uses the Korean date even when the UTC date is the day before', () => {
    // UTC로는 일요일 15:30, 한국은 월요일 00:30.
    expect(kstWeekdayFromMonday(new Date('2026-11-15T15:30:00.000Z'))).toBe(0);
  });
});

describe('startOfKstWeek', () => {
  it('returns monday 00:00 Korea time of the week that contains the instant', () => {
    expect(startOfKstWeek(new Date('2026-11-10T14:30:00+09:00'))).toEqual(
      new Date('2026-11-09T00:00:00+09:00'),
    );
    expect(startOfKstWeek(new Date('2026-11-15T23:59:59.999+09:00'))).toEqual(
      new Date('2026-11-09T00:00:00+09:00'),
    );
  });

  it('starts a new week at monday 00:00', () => {
    expect(startOfKstWeek(new Date('2026-11-16T00:00:00+09:00'))).toEqual(
      new Date('2026-11-16T00:00:00+09:00'),
    );
    expect(startOfKstWeek(new Date('2026-11-15T23:59:59.999+09:00'))).toEqual(
      new Date('2026-11-09T00:00:00+09:00'),
    );
  });
});
