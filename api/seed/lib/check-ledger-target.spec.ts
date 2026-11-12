import { assertCheckLedgerTarget } from './check-ledger-target';

const DEV_REF = 'devref1234567890abcd';
const dev = {
  nodeEnv: 'development',
  supabaseUrl: `https://${DEV_REF}.supabase.co`,
  devProjectRef: DEV_REF,
  databaseUrl: 'postgresql://u:p@host:6543/postgres?pgbouncer=true',
  testDbFlag: undefined,
};

describe('assertCheckLedgerTarget', () => {
  it('accepts the dev project in development', () => {
    expect(assertCheckLedgerTarget(dev)).toBe('dev');
    expect(
      assertCheckLedgerTarget({
        ...dev,
        databaseUrl: 'postgresql://u:p@host:5432/postgres?schema=public',
      }),
    ).toBe('dev');
  });

  it('refuses production, a missing NODE_ENV, and another project', () => {
    expect(() =>
      assertCheckLedgerTarget({ ...dev, nodeEnv: 'production' }),
    ).toThrow(/NODE_ENV=development/);
    expect(() =>
      assertCheckLedgerTarget({ ...dev, nodeEnv: undefined }),
    ).toThrow(/NODE_ENV=development/);
    expect(() =>
      assertCheckLedgerTarget({
        ...dev,
        supabaseUrl: 'https://otherproject123456789.supabase.co',
      }),
    ).toThrow(/개발 프로젝트/);
  });

  it('refuses a test schema without the test runner flag', () => {
    expect(() =>
      assertCheckLedgerTarget({
        ...dev,
        databaseUrl: 'postgresql://u:p@host:5432/postgres?schema=cora_test',
      }),
    ).toThrow(/with-test-db/);
  });

  it('accepts the test schema only through the test runner', () => {
    const test = {
      ...dev,
      nodeEnv: 'test',
      databaseUrl: 'postgresql://u:p@host:5432/postgres?schema=cora_test',
      testDbFlag: '1',
    };
    expect(assertCheckLedgerTarget(test)).toBe('test');
    expect(() =>
      assertCheckLedgerTarget({ ...test, databaseUrl: 'postgresql://u:p@h/p' }),
    ).toThrow(/public/);
    expect(() =>
      assertCheckLedgerTarget({ ...test, nodeEnv: 'production' }),
    ).toThrow(/운영/);
    expect(() =>
      assertCheckLedgerTarget({ ...test, databaseUrl: undefined }),
    ).toThrow(/public/);
  });
});
