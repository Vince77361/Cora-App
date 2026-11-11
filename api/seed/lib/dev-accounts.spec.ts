import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  DEV_ACCOUNTS,
  DEV_EMAIL_DOMAIN,
  DEV_PASSWORD_BASE,
  devCredentials,
  PHONE_PATTERN,
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

  it('rejects a real-looking number outside the 010-0000-XXXX band', () => {
    expect(() => devCredentials('010-1234-5678')).toThrow(/010-0000/);
  });

  it('keeps every seeded phone inside the dev band', () => {
    for (const account of DEV_ACCOUNTS) {
      expect(account.phone).toMatch(/^010-0000-\d{4}$/);
      expect(() => devCredentials(account.phone)).not.toThrow();
    }
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
// dart format이 줄바꿈과 들여쓰기를 바꿔도 깨지지 않게 공백을 모두 한 칸으로 줄여 비교한다.
const squash = (text: string) => text.replace(/\s+/g, ' ');
const dart = squash(dartAdapter);

describe('rule shared with the app FakeSignInAdapter', () => {
  it('uses the same email domain', () => {
    expect(dart).toContain(
      squash(`static const devEmailDomain = '${DEV_EMAIL_DOMAIN}';`),
    );
  });

  it('uses the same password base', () => {
    expect(dart).toContain(
      squash(`static const _devPasswordBase = '${DEV_PASSWORD_BASE}';`),
    );
  });

  it('builds the key, email and password the same way', () => {
    expect(dart).toContain(squash(`_signInAs('phone-$phoneDigits')`));
    expect(dart).toContain(squash(`email: '$key@$devEmailDomain'`));
    expect(dart).toContain(squash(`password: '$_devPasswordBase-$key'`));
  });

  it('accepts the same phone pattern', () => {
    expect(dart).toContain(
      squash(
        `static final _phonePattern = RegExp(r'${PHONE_PATTERN.source}');`,
      ),
    );
    expect(dart).toContain(squash('_phonePattern.hasMatch(phoneDigits)'));
  });

  it('receives digits only, like the seed after stripping non-digits', () => {
    expect(dart).toContain(
      squash('Future<void> verifyPhoneCode({ required String phoneDigits,'),
    );
    expect(devCredentials('010-0000-0003')).toEqual(
      devCredentials('01000000003'),
    );
  });
});
