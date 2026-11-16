import { isBlocked } from './visibility-rules';

describe('isBlocked', () => {
  it('blocks a viewer whose industry the creator avoids', () => {
    expect(isBlocked({ blockedIndustries: ['ALCOHOL', 'LOAN'] }, 'LOAN')).toBe(
      true,
    );
  });

  it('does not block an industry the creator did not list', () => {
    expect(isBlocked({ blockedIndustries: ['ALCOHOL'] }, 'FOOD_CAFE')).toBe(
      false,
    );
  });

  it('does not block when the creator avoids nothing', () => {
    expect(isBlocked({ blockedIndustries: [] }, 'ALCOHOL')).toBe(false);
  });

  it('does not block when the creator has no principles', () => {
    expect(isBlocked(null, 'ALCOHOL')).toBe(false);
  });
});
