import { isViewCountUnreadable } from './unreadable-rule';

const row = (dayIndex: number, views: number | null) => ({ dayIndex, views });

describe('isViewCountUnreadable', () => {
  it('is false while fewer than three days have been recorded', () => {
    expect(
      isViewCountUnreadable([row(0, null), row(1, null)], {
        atSettlement: false,
      }),
    ).toBe(false);
  });

  it('is true when the latest three recorded days are all unreadable', () => {
    expect(
      isViewCountUnreadable(
        [row(0, 10), row(1, null), row(2, null), row(3, null)],
        {
          atSettlement: false,
        },
      ),
    ).toBe(true);
  });

  it('is false when a readable day breaks the run', () => {
    expect(
      isViewCountUnreadable([row(1, null), row(2, 5), row(3, null)], {
        atSettlement: false,
      }),
    ).toBe(false);
  });

  it('counts days without a row as unreadable only at settlement', () => {
    const snapshots = [row(4, 400), row(5, null), row(7, null)];
    expect(isViewCountUnreadable(snapshots, { atSettlement: false })).toBe(
      false,
    );
    expect(isViewCountUnreadable(snapshots, { atSettlement: true })).toBe(true);
  });

  it('is false at settlement when day seven can be read', () => {
    expect(
      isViewCountUnreadable(
        [row(4, 400), row(5, null), row(6, null), row(7, 900)],
        {
          atSettlement: true,
        },
      ),
    ).toBe(false);
  });

  it('counts the last three days of a 14 day period at settlement', () => {
    // 12·13·14일째가 모두 읽지 못한 날이면(줄이 없는 날 포함) 11일째 값으로 정산하지 않는다.
    const rows = [row(10, 5), row(11, 9), row(12, null)];
    expect(
      isViewCountUnreadable(rows, { atSettlement: true, lastDay: 14 }),
    ).toBe(true);
    // 7일 기준이면 그 구간(5~7일)에는 값이 있어 읽을 수 있다.
    expect(
      isViewCountUnreadable([row(5, 3), row(10, 5), row(11, 9)], {
        atSettlement: true,
      }),
    ).toBe(false);
    expect(
      isViewCountUnreadable([row(12, 4), row(13, null), row(14, null)], {
        atSettlement: true,
        lastDay: 14,
      }),
    ).toBe(false);
  });
});
