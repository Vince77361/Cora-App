import type { UserRole } from '@prisma/client';

export interface DevAccount {
  phone: string;
  role: UserRole;
}

// 개발용 역할별 계정. 번호는 E1(로그인)에서 인증번호 000000과 함께 쓰는 값이다.
// 이 세 번호 말고 다른 번호는 쓰지 않는다.
export const DEV_ACCOUNTS: readonly DevAccount[] = [
  { phone: '010-0000-0001', role: 'STORE' },
  { phone: '010-0000-0002', role: 'BRAND' },
  { phone: '010-0000-0003', role: 'CREATOR' },
];

// 아래 두 상수와 devCredentials의 규칙은 앱의 가짜 로그인
// (app/lib/features/auth/data/fake_sign_in_adapter.dart)과 똑같아야 한다.
// 달라지면 E1에서 이 계정으로 로그인되지 않고 새 빈 계정이 만들어진다.
// 두 곳이 어긋나면 dev-accounts.spec.ts가 실패하도록 앱 파일을 읽어 대조한다.
export const DEV_EMAIL_DOMAIN = 'example.com';
export const DEV_PASSWORD_BASE = 'cora-dev-only';

// 한국 휴대폰 번호: 010 + 8자리(하이픈은 있어도 없어도 된다).
export const PHONE_PATTERN = /^010\d{8}$/;

export interface DevCredentials {
  email: string;
  password: string;
}

// 앱은 번호에서 숫자만 뽑아 `phone-<숫자>` 키를 만들고, 이메일과 비밀번호를 그 키로 정한다.
// 비밀번호는 비밀이 아닌 개발 전용 값이다. 개발용 Supabase 프로젝트에서만 쓴다.
export function devCredentials(phone: string): DevCredentials {
  const digits = phone.replace(/\D/g, '');
  if (!PHONE_PATTERN.test(digits)) {
    throw new Error('개발 계정 번호는 010으로 시작하는 11자리여야 해요.');
  }
  const key = `phone-${digits}`;
  return {
    email: `${key}@${DEV_EMAIL_DOMAIN}`,
    password: `${DEV_PASSWORD_BASE}-${key}`,
  };
}
