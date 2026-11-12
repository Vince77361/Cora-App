import { loadEnv } from './env';

const valid = {
  NODE_ENV: 'test',
  PORT: '3000',
  DATABASE_URL: 'postgresql://u:p@localhost:6543/db',
  DIRECT_URL: 'postgresql://u:p@localhost:5432/db',
  SUPABASE_URL: 'https://example.supabase.co',
  PUSH_ADAPTER: 'fake',
  STORE_LINK_ADAPTER: 'fake',
  CONTENT_DRAFT_ADAPTER: 'fake',
};

const NEW_ADAPTERS = [
  'PAYMENT_ADAPTER',
  'PAYOUT_ADAPTER',
  'VIEW_COUNT_ADAPTER',
  'INSTAGRAM_ADAPTER',
  'OPERATOR_ALERT_ADAPTER',
] as const;

const productionBase = {
  ...valid,
  NODE_ENV: 'production',
  PUSH_ADAPTER: 'real',
  STORE_LINK_ADAPTER: 'real',
  CONTENT_DRAFT_ADAPTER: 'real',
  SUPABASE_SERVICE_ROLE_KEY: 'k',
  PAYMENT_ADAPTER: 'real',
  PAYOUT_ADAPTER: 'real',
  VIEW_COUNT_ADAPTER: 'real',
  INSTAGRAM_ADAPTER: 'real',
  OPERATOR_ALERT_ADAPTER: 'real',
  REDIS_URL: 'redis://redis.internal:6379',
  OPERATOR_EMAIL: 'ops@example.com',
  PAYOUT_ACCOUNT_KEY: Buffer.alloc(32, 9).toString('base64'),
  PAYMENT_WEBHOOK_SECRET: 'w'.repeat(32),
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

  it.each(['STORE_LINK_ADAPTER', 'CONTENT_DRAFT_ADAPTER'])(
    'keeps %s and rejects unknown or missing values',
    (key) => {
      // @Expose가 빠지면 loadEnv가 이 키를 버려 검증이 조용히 사라진다.
      expect(loadEnv({ ...valid, [key]: 'real' })[key as 'PUSH_ADAPTER']).toBe(
        'real',
      );
      expect(() => loadEnv({ ...valid, [key]: 'mock' })).toThrow(
        new RegExp(key),
      );
      expect(() => loadEnv({ ...valid, [key]: undefined })).toThrow(
        new RegExp(key),
      );
    },
  );

  it('allows a missing SUPABASE_SERVICE_ROLE_KEY outside production', () => {
    expect(loadEnv(valid).SUPABASE_SERVICE_ROLE_KEY).toBeUndefined();
  });

  it('keeps SUPABASE_SERVICE_ROLE_KEY when it is set', () => {
    // @Expose가 빠지면 loadEnv가 이 키를 버려 Storage가 항상 키 없이 동작한다.
    expect(
      loadEnv({ ...valid, SUPABASE_SERVICE_ROLE_KEY: 'k' })
        .SUPABASE_SERVICE_ROLE_KEY,
    ).toBe('k');
  });

  it.each([undefined, ''])(
    'rejects SUPABASE_SERVICE_ROLE_KEY=%p in production',
    (value) => {
      expect(() =>
        loadEnv({
          ...valid,
          NODE_ENV: 'production',
          PUSH_ADAPTER: 'real',
          SUPABASE_SERVICE_ROLE_KEY: value,
        }),
      ).toThrow(/SUPABASE_SERVICE_ROLE_KEY/);
    },
  );

  it('ignores unrelated keys such as PATH', () => {
    expect(() => loadEnv({ ...valid, PATH: '/usr/bin' })).not.toThrow();
  });
});

describe('loadEnv payment, payout and queue settings', () => {
  it.each(NEW_ADAPTERS)(
    'defaults %s to fake outside production when missing or empty',
    (key) => {
      expect(loadEnv({ ...valid, [key]: undefined })[key]).toBe('fake');
      expect(loadEnv({ ...valid, [key]: '' })[key]).toBe('fake');
      expect(
        loadEnv({ ...valid, NODE_ENV: 'development', [key]: undefined })[key],
      ).toBe('fake');
    },
  );

  it.each(NEW_ADAPTERS)('rejects an unknown %s', (key) => {
    expect(() => loadEnv({ ...valid, [key]: 'mock' })).toThrow(new RegExp(key));
  });

  it.each(NEW_ADAPTERS)('requires %s to be given in production', (key) => {
    expect(() => loadEnv({ ...productionBase, [key]: undefined })).toThrow(
      new RegExp(key),
    );
    expect(() => loadEnv({ ...productionBase, [key]: '' })).toThrow(
      new RegExp(key),
    );
    expect(loadEnv(productionBase)[key]).toBe('real');
  });

  it('keeps the production fixture itself valid', () => {
    expect(() => loadEnv(productionBase)).not.toThrow();
  });

  it('defaults REDIS_URL to the local redis outside production', () => {
    expect(loadEnv(valid).REDIS_URL).toBe('redis://127.0.0.1:6379');
    expect(loadEnv({ ...valid, REDIS_URL: '' }).REDIS_URL).toBe(
      'redis://127.0.0.1:6379',
    );
    expect(loadEnv({ ...valid, REDIS_URL: 'redis://h:1' }).REDIS_URL).toBe(
      'redis://h:1',
    );
  });

  it('requires REDIS_URL in production', () => {
    expect(() => loadEnv({ ...productionBase, REDIS_URL: undefined })).toThrow(
      /REDIS_URL/,
    );
  });

  it.each(['PAYOUT_ACCOUNT_KEY', 'PAYMENT_WEBHOOK_SECRET', 'OPERATOR_EMAIL'])(
    'allows %s to be missing outside production and requires it in production',
    (key) => {
      expect(loadEnv(valid)[key as 'OPERATOR_EMAIL']).toBeUndefined();
      expect(() => loadEnv({ ...productionBase, [key]: undefined })).toThrow(
        new RegExp(key),
      );
    },
  );

  it.each([
    'short',
    Buffer.alloc(16, 1).toString('base64'),
    'not base64 at all!!',
  ])(
    'rejects a PAYOUT_ACCOUNT_KEY that is not 32 bytes of base64 (%s)',
    (v) => {
      expect(() => loadEnv({ ...valid, PAYOUT_ACCOUNT_KEY: v })).toThrow(
        /PAYOUT_ACCOUNT_KEY/,
      );
      expect(() =>
        loadEnv({ ...productionBase, PAYOUT_ACCOUNT_KEY: v }),
      ).toThrow(/PAYOUT_ACCOUNT_KEY/);
    },
  );

  it('accepts a 32 byte base64 PAYOUT_ACCOUNT_KEY', () => {
    const key = Buffer.alloc(32, 3).toString('base64');
    expect(
      loadEnv({ ...valid, PAYOUT_ACCOUNT_KEY: key }).PAYOUT_ACCOUNT_KEY,
    ).toBe(key);
  });

  it('rejects a short PAYMENT_WEBHOOK_SECRET in production', () => {
    expect(() =>
      loadEnv({ ...productionBase, PAYMENT_WEBHOOK_SECRET: 'short' }),
    ).toThrow(/PAYMENT_WEBHOOK_SECRET/);
  });

  it.each(['FEE_RATE_STORE_OFFER', 'FEE_RATE_BID', 'FEE_RATE_BRAND_CONTRACT'])(
    'defaults %s to 10 and accepts only integers from 0 to 100',
    (key) => {
      const k = key as 'FEE_RATE_BID';
      expect(loadEnv(valid)[k]).toBe(10);
      // 빈 값은 0%가 아니라 없는 값으로 본다.
      expect(loadEnv({ ...valid, [key]: '' })[k]).toBe(10);
      expect(loadEnv({ ...productionBase, [key]: '' })[k]).toBe(10);
      expect(loadEnv({ ...valid, [key]: '15' })[k]).toBe(15);
      expect(loadEnv({ ...valid, [key]: '0' })[k]).toBe(0);
      expect(() => loadEnv({ ...valid, [key]: '101' })).toThrow(
        new RegExp(key),
      );
      expect(() => loadEnv({ ...valid, [key]: '-1' })).toThrow(new RegExp(key));
      expect(() => loadEnv({ ...valid, [key]: '7.5' })).toThrow(
        new RegExp(key),
      );
    },
  );

  it('accepts JOBS_WORKER on or off and treats blank as unset', () => {
    expect(loadEnv(valid).JOBS_WORKER).toBeUndefined();
    expect(loadEnv({ ...valid, JOBS_WORKER: '' }).JOBS_WORKER).toBeUndefined();
    expect(loadEnv({ ...valid, JOBS_WORKER: 'off' }).JOBS_WORKER).toBe('off');
    expect(() => loadEnv({ ...valid, JOBS_WORKER: 'maybe' })).toThrow(
      /JOBS_WORKER/,
    );
  });

  it('defaults FAKE_CLOCK_OFFSET_DAYS to 0 and parses an integer', () => {
    expect(loadEnv(valid).FAKE_CLOCK_OFFSET_DAYS).toBe(0);
    expect(
      loadEnv({ ...valid, FAKE_CLOCK_OFFSET_DAYS: '' }).FAKE_CLOCK_OFFSET_DAYS,
    ).toBe(0);
    expect(
      loadEnv({ ...productionBase, FAKE_CLOCK_OFFSET_DAYS: '' })
        .FAKE_CLOCK_OFFSET_DAYS,
    ).toBe(0);
    expect(
      loadEnv({ ...valid, FAKE_CLOCK_OFFSET_DAYS: '5' }).FAKE_CLOCK_OFFSET_DAYS,
    ).toBe(5);
    expect(() => loadEnv({ ...valid, FAKE_CLOCK_OFFSET_DAYS: '1.5' })).toThrow(
      /FAKE_CLOCK_OFFSET_DAYS/,
    );
  });

  it('refuses to start in production with a non-zero FAKE_CLOCK_OFFSET_DAYS', () => {
    expect(() =>
      loadEnv({ ...productionBase, FAKE_CLOCK_OFFSET_DAYS: '3' }),
    ).toThrow(/FAKE_CLOCK_OFFSET_DAYS/);
    expect(
      loadEnv({ ...productionBase, FAKE_CLOCK_OFFSET_DAYS: '0' })
        .FAKE_CLOCK_OFFSET_DAYS,
    ).toBe(0);
  });
});
