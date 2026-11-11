import { loadEnv } from './env';

const valid = {
  NODE_ENV: 'test',
  PORT: '3000',
  DATABASE_URL: 'postgresql://u:p@localhost:6543/db',
  DIRECT_URL: 'postgresql://u:p@localhost:5432/db',
  SUPABASE_URL: 'https://example.supabase.co',
  PUSH_ADAPTER: 'fake',
};

describe('loadEnv', () => {
  it('accepts a valid environment without SUPABASE_JWT_SECRET', () => {
    const env = loadEnv(valid);
    expect(env.NODE_ENV).toBe('test');
    expect(env.SUPABASE_JWT_SECRET).toBeUndefined();
  });

  it('rejects a missing DATABASE_URL', () => {
    expect(() => loadEnv({ ...valid, DATABASE_URL: undefined })).toThrow(
      /DATABASE_URL/,
    );
  });

  it.each(['DATABASE_URL', 'DIRECT_URL', 'SUPABASE_URL'])(
    'rejects an empty %s',
    (key) => {
      expect(() => loadEnv({ ...valid, [key]: '' })).toThrow(new RegExp(key));
    },
  );

  it('strips trailing slashes from SUPABASE_URL', () => {
    // 끝에 /가 남으면 issuer와 JWKS 주소가 어긋나 모든 토큰이 거절된다.
    const env = loadEnv({
      ...valid,
      SUPABASE_URL: 'https://example.supabase.co//',
    });
    expect(env.SUPABASE_URL).toBe('https://example.supabase.co');
  });

  it('defaults PORT to 3000', () => {
    expect(loadEnv({ ...valid, PORT: undefined }).PORT).toBe(3000);
  });

  it('converts a numeric PORT string to a number', () => {
    expect(loadEnv({ ...valid, PORT: '4100' }).PORT).toBe(4100);
  });

  it('rejects an unknown PUSH_ADAPTER', () => {
    expect(() => loadEnv({ ...valid, PUSH_ADAPTER: 'mock' })).toThrow(
      /PUSH_ADAPTER/,
    );
  });

  it('ignores unrelated keys such as PATH', () => {
    expect(() => loadEnv({ ...valid, PATH: '/usr/bin' })).not.toThrow();
  });
});
