import { IndustryCategory } from '@prisma/client';
import {
  GENERAL_INDUSTRIES,
  INDUSTRY_LABELS,
  SENSITIVE_INDUSTRIES,
} from './industry';

describe('industry', () => {
  it('splits every industry into nine general and four sensitive ones', () => {
    expect(GENERAL_INDUSTRIES).toHaveLength(9);
    expect([...SENSITIVE_INDUSTRIES]).toEqual([
      'ALCOHOL',
      'GAMBLING',
      'LOAN',
      'DIET_SUPPLEMENT',
    ]);
    expect([...GENERAL_INDUSTRIES, ...SENSITIVE_INDUSTRIES].sort()).toEqual(
      Object.values(IndustryCategory).sort(),
    );
  });

  it('names every industry', () => {
    expect(Object.keys(INDUSTRY_LABELS).sort()).toEqual(
      Object.values(IndustryCategory).sort(),
    );
    expect(INDUSTRY_LABELS.DIET_SUPPLEMENT).toBe('다이어트 보조제');
  });
});
