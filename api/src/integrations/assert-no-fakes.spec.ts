import { Env, loadEnv } from '../config/env';
import { assertNoFakesInProduction } from './assert-no-fakes';

const env: Env = {
  NODE_ENV: 'test',
  PORT: 3000,
  DATABASE_URL: 'postgresql://x',
  DIRECT_URL: 'postgresql://x',
  SUPABASE_URL: 'https://x.supabase.co',
  PUSH_ADAPTER: 'real',
  STORE_LINK_ADAPTER: 'real',
  CONTENT_DRAFT_ADAPTER: 'real',
  PAYMENT_ADAPTER: 'real',
  PAYOUT_ADAPTER: 'real',
  VIEW_COUNT_ADAPTER: 'real',
  INSTAGRAM_ADAPTER: 'real',
  OPERATOR_ALERT_ADAPTER: 'real',
  REDIS_URL: 'redis://redis.internal:6379',
  FEE_RATE_STORE_OFFER: 10,
  FEE_RATE_BID: 10,
  FEE_RATE_BRAND_CONTRACT: 10,
  FAKE_CLOCK_OFFSET_DAYS: 0,
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

  it('throws in production when STORE_LINK_ADAPTER is fake', () => {
    expect(() =>
      assertNoFakesInProduction({
        ...env,
        NODE_ENV: 'production',
        STORE_LINK_ADAPTER: 'fake',
      }),
    ).toThrow(/STORE_LINK_ADAPTER/);
  });

  it('throws in production when CONTENT_DRAFT_ADAPTER is fake', () => {
    expect(() =>
      assertNoFakesInProduction({
        ...env,
        NODE_ENV: 'production',
        CONTENT_DRAFT_ADAPTER: 'fake',
      }),
    ).toThrow(/CONTENT_DRAFT_ADAPTER/);
  });

  it.each([
    'PAYMENT_ADAPTER',
    'PAYOUT_ADAPTER',
    'VIEW_COUNT_ADAPTER',
    'INSTAGRAM_ADAPTER',
    'OPERATOR_ALERT_ADAPTER',
  ])('throws in production when %s is fake', (key) => {
    expect(() =>
      assertNoFakesInProduction({
        ...env,
        NODE_ENV: 'production',
        [key]: 'fake',
      }),
    ).toThrow(new RegExp(key));
  });

  it('scans any key ending in _ADAPTER so future adapters are covered', () => {
    const withExtra = {
      ...env,
      NODE_ENV: 'production',
      FOO_ADAPTER: 'fake',
    } as unknown as Env;
    expect(() => assertNoFakesInProduction(withExtra)).toThrow(/FOO_ADAPTER/);
  });

  it('refuses a production environment that explicitly picks a fake payment adapter', () => {
    const loaded = loadEnv({
      NODE_ENV: 'production',
      DATABASE_URL: 'postgresql://x',
      DIRECT_URL: 'postgresql://x',
      SUPABASE_URL: 'https://x.supabase.co',
      SUPABASE_SERVICE_ROLE_KEY: 'k',
      PUSH_ADAPTER: 'real',
      STORE_LINK_ADAPTER: 'real',
      CONTENT_DRAFT_ADAPTER: 'real',
      PAYMENT_ADAPTER: 'fake',
      PAYOUT_ADAPTER: 'real',
      VIEW_COUNT_ADAPTER: 'real',
      INSTAGRAM_ADAPTER: 'real',
      OPERATOR_ALERT_ADAPTER: 'real',
      REDIS_URL: 'redis://redis.internal:6379',
      OPERATOR_EMAIL: 'ops@example.com',
      PAYOUT_ACCOUNT_KEY: Buffer.alloc(32, 9).toString('base64'),
      PAYMENT_WEBHOOK_SECRET: 'w'.repeat(32),
    });
    expect(() => assertNoFakesInProduction(loaded)).toThrow(/PAYMENT_ADAPTER/);
  });

  it('keeps the defaulted dev adapters on the Env object so they stay checked', () => {
    const loaded = loadEnv({
      NODE_ENV: 'development',
      DATABASE_URL: 'postgresql://x',
      DIRECT_URL: 'postgresql://x',
      SUPABASE_URL: 'https://x.supabase.co',
      PUSH_ADAPTER: 'fake',
      STORE_LINK_ADAPTER: 'fake',
      CONTENT_DRAFT_ADAPTER: 'fake',
    });
    expect(loaded.PAYMENT_ADAPTER).toBe('fake');
    expect(() =>
      assertNoFakesInProduction({ ...loaded, NODE_ENV: 'production' }),
    ).toThrow(/PAYOUT_ADAPTER/);
  });
});
