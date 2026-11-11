import { Env } from '../config/env';
import { assertNoFakesInProduction } from './assert-no-fakes';

const env: Env = {
  NODE_ENV: 'test',
  PORT: 3000,
  DATABASE_URL: 'postgresql://x',
  DIRECT_URL: 'postgresql://x',
  SUPABASE_URL: 'https://x.supabase.co',
  PUSH_ADAPTER: 'real',
};

describe('assertNoFakesInProduction', () => {
  it('throws in production when any adapter is fake', () => {
    expect(() =>
      assertNoFakesInProduction({
        ...env,
        NODE_ENV: 'production',
        PUSH_ADAPTER: 'fake',
      }),
    ).toThrow(/PUSH_ADAPTER/);
  });

  it('allows fake adapters in development and test', () => {
    expect(() =>
      assertNoFakesInProduction({
        ...env,
        NODE_ENV: 'development',
        PUSH_ADAPTER: 'fake',
      }),
    ).not.toThrow();
    expect(() =>
      assertNoFakesInProduction({
        ...env,
        NODE_ENV: 'test',
        PUSH_ADAPTER: 'fake',
      }),
    ).not.toThrow();
  });

  it('allows production when every adapter is real', () => {
    expect(() =>
      assertNoFakesInProduction({
        ...env,
        NODE_ENV: 'production',
        PUSH_ADAPTER: 'real',
      }),
    ).not.toThrow();
  });

  it('scans any key ending in _ADAPTER so future adapters are covered', () => {
    const withExtra = {
      ...env,
      NODE_ENV: 'production',
      FOO_ADAPTER: 'fake',
    } as unknown as Env;
    expect(() => assertNoFakesInProduction(withExtra)).toThrow(/FOO_ADAPTER/);
  });
});
