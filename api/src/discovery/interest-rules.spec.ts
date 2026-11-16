import { inTab, interestState, shortName } from './interest-rules';

describe('shortName', () => {
  it('builds a short name from an activity name', () => {
    expect(shortName('서윤의 작은 취향')).toBe('서윤');
    expect(shortName('하루 한 컵')).toBe('하루 한 컵');
  });

  it('keeps the whole name when "의" is not followed by a word', () => {
    expect(shortName('의자 공방')).toBe('의자 공방');
    expect(shortName('서윤의')).toBe('서윤의');
    expect(shortName('느린결')).toBe('느린결');
  });

  it('cuts at the first "의 " and trims the head', () => {
    expect(shortName('김 서윤의 작은 취향의 기록')).toBe('김 서윤');
    expect(shortName('  서윤의 작은 취향 ')).toBe('서윤');
  });
});

describe('interest state and tabs', () => {
  it('shows a match as mutual regardless of the stored decision', () => {
    expect(interestState('LIKE', true)).toBe('MUTUAL');
    expect(interestState('HOLD', true)).toBe('MUTUAL');
  });

  it('maps a like to waiting and a hold to held', () => {
    expect(interestState('LIKE', false)).toBe('WAITING');
    expect(interestState('HOLD', false)).toBe('HELD');
  });

  it('never lists a pass', () => {
    expect(interestState('PASS', false)).toBeNull();
    expect(interestState('PASS', true)).toBeNull();
  });

  it('puts every state in the saved tab and each state only in its own tab', () => {
    for (const state of ['MUTUAL', 'WAITING', 'HELD'] as const) {
      expect(inTab(state, 'saved')).toBe(true);
    }
    expect(inTab('MUTUAL', 'mutual')).toBe(true);
    expect(inTab('WAITING', 'mutual')).toBe(false);
    expect(inTab('WAITING', 'sent')).toBe(true);
    expect(inTab('HELD', 'sent')).toBe(false);
    expect(inTab('HELD', 'held')).toBe(true);
    expect(inTab('MUTUAL', 'held')).toBe(false);
  });
});
