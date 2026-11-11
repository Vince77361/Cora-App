import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';
import { AppError } from '../errors/app-error';

const VERSION = 'v1';
const IV_BYTES = 12;
const KEY_BYTES = 32;
// GCM 태그는 항상 16바이트로 고정한다. 짧은 태그를 받아 주면 변조 검증이 약해진다.
const TAG_BYTES = 16;

// 인스타그램 토큰과 계좌번호처럼 DB에 그대로 두면 안 되는 값을 AES-256-GCM으로 봉한다.
// 출력은 `v1:<iv>:<tag>:<본문>`(각 base64)이라 키를 바꾸는 날에도 어떤 방식으로 봉했는지 알 수 있다.
// 키는 환경변수 PAYOUT_ACCOUNT_KEY(32바이트 base64)다. 오류 메시지에는 키 이름만 쓰고 값은 쓰지 않는다.
export class SecretBox {
  private readonly key: Buffer | null;

  constructor(keyBase64?: string) {
    const key = keyBase64 ? Buffer.from(keyBase64, 'base64') : null;
    this.key = key?.length === KEY_BYTES ? key : null;
  }

  // 개발에서는 키 없이도 돌 수 있어야 하는 호출부가 먼저 묻는다(운영은 키가 없으면 시작하지 않는다).
  isConfigured(): boolean {
    return this.key !== null;
  }

  seal(plain: string): string {
    const key = this.requireKey();
    const iv = randomBytes(IV_BYTES);
    const cipher = createCipheriv('aes-256-gcm', key, iv, {
      authTagLength: TAG_BYTES,
    });
    const body = Buffer.concat([cipher.update(plain, 'utf8'), cipher.final()]);
    return [
      VERSION,
      iv.toString('base64'),
      cipher.getAuthTag().toString('base64'),
      body.toString('base64'),
    ].join(':');
  }

  open(sealed: string): string {
    const key = this.requireKey();
    const [version, iv, tag, body, ...rest] = sealed.split(':');
    if (
      version !== VERSION ||
      !iv ||
      !tag ||
      body === undefined ||
      rest.length
    ) {
      throw this.unreadable();
    }
    const ivBytes = Buffer.from(iv, 'base64');
    const tagBytes = Buffer.from(tag, 'base64');
    if (ivBytes.length !== IV_BYTES || tagBytes.length !== TAG_BYTES) {
      throw this.unreadable();
    }
    try {
      const decipher = createDecipheriv('aes-256-gcm', key, ivBytes, {
        authTagLength: TAG_BYTES,
      });
      decipher.setAuthTag(tagBytes);
      return Buffer.concat([
        decipher.update(Buffer.from(body, 'base64')),
        decipher.final(),
      ]).toString('utf8');
    } catch {
      // 변조되었거나 다른 키로 봉한 값. 원인을 더 자세히 알려 주면 공격자에게만 도움이 된다.
      throw this.unreadable();
    }
  }

  private requireKey(): Buffer {
    if (!this.key) {
      throw new AppError(
        'INTERNAL',
        'PAYOUT_ACCOUNT_KEY가 없거나 올바르지 않아 값을 암호화하거나 열 수 없어요. 32바이트를 base64로 인코딩한 값이어야 해요.',
      );
    }
    return this.key;
  }

  private unreadable(): AppError {
    return new AppError('INTERNAL', '암호화된 값을 열 수 없어요.');
  }
}
