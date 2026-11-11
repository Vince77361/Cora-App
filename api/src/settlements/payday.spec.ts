import { nextPayday, upcomingPayday } from './payday';

// 한국 시간(UTC+9)으로 적는다. 2026-11-09는 월요일이다.
const kst = (iso: string) => new Date(`${iso}+09:00`);

describe('nextPayday', () => {
  it('pays a tuesday settlement on the wednesday of the following week', () => {
    // 2026-11-10(화) → 다음 주 수요일 2026-11-18 10:00.
    expect(nextPayday(kst('2026-11-10T14:30:00'))).toEqual(
      kst('2026-11-18T10:00:00'),
    );
  });

  it('pays a sunday 23:59 settlement on the next wednesday', () => {
    // 2026-11-15(일) 23:59는 아직 11-09 주다 → 2026-11-18.
    expect(nextPayday(kst('2026-11-15T23:59:00'))).toEqual(
      kst('2026-11-18T10:00:00'),
    );
    expect(nextPayday(kst('2026-11-15T23:59:59.999'))).toEqual(
      kst('2026-11-18T10:00:00'),
    );
  });

  it('pays a monday 00:00 settlement on the wednesday after next', () => {
    // 2026-11-16(월) 00:00부터 새 주다 → 2026-11-25.
    expect(nextPayday(kst('2026-11-16T00:00:00'))).toEqual(
      kst('2026-11-25T10:00:00'),
    );
  });

  it('pays a monday settlement at the start of the week on the following wednesday', () => {
    expect(nextPayday(kst('2026-11-09T00:00:00'))).toEqual(
      kst('2026-11-18T10:00:00'),
    );
  });

  it('never pays in the same week, even on a wednesday before ten', () => {
    // 2026-11-11(수) 09:00에 확정돼도 이번 수요일이 아니라 다음 주 수요일이다.
    expect(nextPayday(kst('2026-11-11T09:00:00'))).toEqual(
      kst('2026-11-18T10:00:00'),
    );
  });

  it('works across a month and year boundary', () => {
    // 2026-12-30(수) → 다음 주 수요일 2027-01-06.
    expect(nextPayday(kst('2026-12-30T12:00:00'))).toEqual(
      kst('2027-01-06T10:00:00'),
    );
  });

  it('uses the korean date, not the utc date', () => {
    // UTC로는 일요일 15:30이지만 한국은 월요일 00:30이다 → 그다음 주 수요일.
    expect(nextPayday(new Date('2026-11-15T15:30:00.000Z'))).toEqual(
      kst('2026-11-25T10:00:00'),
    );
  });
});

describe('upcomingPayday', () => {
  it('returns the same wednesday before ten', () => {
    expect(upcomingPayday(kst('2026-11-18T09:59:59'))).toEqual(
      kst('2026-11-18T10:00:00'),
    );
  });

  it('returns the same wednesday at exactly ten', () => {
    expect(upcomingPayday(kst('2026-11-18T10:00:00'))).toEqual(
      kst('2026-11-18T10:00:00'),
    );
  });

  it('returns the next week after ten on a wednesday', () => {
    expect(upcomingPayday(kst('2026-11-18T10:00:01'))).toEqual(
      kst('2026-11-25T10:00:00'),
    );
  });

  it('returns the coming wednesday from any other day', () => {
    // 월요일 → 그 주 수요일, 목요일·일요일 → 다음 주 수요일.
    expect(upcomingPayday(kst('2026-11-16T00:00:00'))).toEqual(
      kst('2026-11-18T10:00:00'),
    );
    expect(upcomingPayday(kst('2026-11-19T08:00:00'))).toEqual(
      kst('2026-11-25T10:00:00'),
    );
    expect(upcomingPayday(kst('2026-11-22T23:59:00'))).toEqual(
      kst('2026-11-25T10:00:00'),
    );
  });

  it('uses the korean date, not the utc date', () => {
    // UTC로는 화요일 23:30이지만 한국은 수요일 08:30이다 → 그날 10:00.
    expect(upcomingPayday(new Date('2026-11-17T23:30:00.000Z'))).toEqual(
      kst('2026-11-18T10:00:00'),
    );
  });
});
