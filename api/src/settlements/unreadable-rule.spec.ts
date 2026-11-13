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
});
