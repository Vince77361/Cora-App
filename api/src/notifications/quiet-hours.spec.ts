import { isQuietAt } from './quiet-hours';

describe('isQuietAt', () => {
  it('treats 22:00 to 07:59 KST as quiet at night', () => {
    expect(isQuietAt(new Date('2026-11-11T13:00:00Z'), 'NIGHT')).toBe(true); // 22:00 KST
    expect(isQuietAt(new Date('2026-11-11T22:59:00Z'), 'NIGHT')).toBe(true); // 07:59 KST
    expect(isQuietAt(new Date('2026-11-11T23:00:00Z'), 'NIGHT')).toBe(false); // 08:00 KST
    expect(isQuietAt(new Date('2026-11-11T12:59:00Z'), 'NIGHT')).toBe(false); // 21:59 KST
    expect(isQuietAt(new Date('2026-11-11T15:00:00Z'), 'NIGHT')).toBe(true); // 00:00 KST
  });

  it('treats saturday 00:00 to monday 00:00 KST as quiet on weekends', () => {
    expect(isQuietAt(new Date('2026-11-13T14:59:00Z'), 'WEEKEND')).toBe(false); // 금 23:59
    expect(isQuietAt(new Date('2026-11-13T15:00:00Z'), 'WEEKEND')).toBe(true); // 토 00:00
    expect(isQuietAt(new Date('2026-11-15T14:59:00Z'), 'WEEKEND')).toBe(true); // 일 23:59
    expect(isQuietAt(new Date('2026-11-15T15:00:00Z'), 'WEEKEND')).toBe(false); // 월 00:00
  });

  it('does not apply the night window on a weekday under WEEKEND', () => {
    expect(isQuietAt(new Date('2026-11-11T13:00:00Z'), 'WEEKEND')).toBe(false);
  });

  it('is never quiet when off', () => {
    expect(isQuietAt(new Date('2026-11-11T13:00:00Z'), 'OFF')).toBe(false);
    expect(isQuietAt(new Date('2026-11-14T03:00:00Z'), 'OFF')).toBe(false);
  });
});
