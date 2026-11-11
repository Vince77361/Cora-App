import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  DEV_ACCOUNTS,
  DEV_EMAIL_DOMAIN,
  DEV_PASSWORD_BASE,
  devCredentials,
} from './dev-accounts';

const dartAdapter = readFileSync(
  join(
    __dirname,
    '../../../app/lib/features/auth/data/fake_sign_in_adapter.dart',
  ),
  'utf8',
);

describe('devCredentials', () => {
  it('derives the email and password from the phone digits', () => {
    expect(devCredentials('010-0000-0003')).toEqual({
      email: 'phone-01000000003@example.com',
      password: 'cora-dev-only-phone-01000000003',
    });
  });

  it('gives the same credentials with or without hyphens', () => {
    expect(devCredentials('01000000001')).toEqual(
      devCredentials('010-0000-0001'),
    );
  });

  it('rejects a number that is not a 010 mobile number', () => {
    expect(() => devCredentials('02-000-0000')).toThrow(/010/);
  });

  it('defines one STORE, one BRAND and one CREATOR account', () => {
    expect(DEV_ACCOUNTS.map((a) => a.role)).toEqual([
      'STORE',
      'BRAND',
      'CREATOR',
    ]);
  });
});

// 앱(FakeSignInAdapter)과 규칙이 어긋나면 E1에서 이 계정으로 로그인되지 않는다.
describe('rule shared with the app FakeSignInAdapter', () => {
  it('uses the same email domain', () => {
    expect(dartAdapter).toContain(
      `static const devEmailDomain = '${DEV_EMAIL_DOMAIN}';`,
    );
  });

  it('uses the same password base', () => {
    expect(dartAdapter).toContain(
      `static const _devPasswordBase = '${DEV_PASSWORD_BASE}';`,
    );
  });

  it('builds the key, email and password the same way', () => {
    expect(dartAdapter).toContain(`_signInAs('phone-$phoneDigits')`);
    expect(dartAdapter).toContain(`email: '$key@$devEmailDomain'`);
    expect(dartAdapter).toContain(`password: '$_devPasswordBase-$key'`);
  });
});
