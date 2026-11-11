import { randomBytes } from 'node:crypto';
import { AppError } from '../errors/app-error';
import { SecretBox } from './secret-box';

const KEY = Buffer.alloc(32, 5).toString('base64');

function errorOf(run: () => unknown): AppError {
  try {
    run();
  } catch (error) {
    return error as AppError;
  }
  throw new Error('오류가 나야 해요.');
}

describe('SecretBox', () => {
  it('opens what it sealed', () => {
    const box = new SecretBox(KEY);
    expect(box.open(box.seal('fake-instagram-token-haru'))).toBe(
      'fake-instagram-token-haru',
    );
    expect(box.open(box.seal(''))).toBe('');
    expect(box.open(box.seal('한글 값 🙂'))).toBe('한글 값 🙂');
  });

  it('never repeats the same sealed text for the same value and hides the plain text', () => {
    const box = new SecretBox(KEY);
    const a = box.seal('secret-value');
    const b = box.seal('secret-value');
    expect(a).not.toBe(b);
    expect(a).not.toContain('secret-value');
    expect(a.startsWith('v1:')).toBe(true);
  });

  it('refuses a tampered value', () => {
    const box = new SecretBox(KEY);
    const [version, iv, tag, body] = box.seal('secret-value').split(':');
    const flipped = Buffer.from(body, 'base64');
    flipped[0] ^= 1;
    const tampered = [version, iv, tag, flipped.toString('base64')].join(':');
    expect(errorOf(() => box.open(tampered)).code).toBe('INTERNAL');
    expect(errorOf(() => box.open('not-a-sealed-value')).code).toBe('INTERNAL');
    expect(errorOf(() => box.open('v9:a:b:c')).code).toBe('INTERNAL');
  });

  it('refuses a truncated tag, a wrong-sized iv and extra parts', () => {
    const box = new SecretBox(KEY);
    const [version, iv, tag, body] = box.seal('secret-value').split(':');
    const cut = (value: string, bytes: number) =>
      Buffer.from(value, 'base64').subarray(0, bytes).toString('base64');
    for (const sealed of [
      [version, iv, cut(tag, 4), body],
      [version, iv, cut(tag, 15), body],
      [version, cut(iv, 8), tag, body],
      [version, iv, tag, body, 'extra'],
    ]) {
      expect(errorOf(() => box.open(sealed.join(':'))).code).toBe('INTERNAL');
    }
    expect(box.open([version, iv, tag, body].join(':'))).toBe('secret-value');
  });

  it('refuses a value sealed with another key', () => {
    const other = new SecretBox(randomBytes(32).toString('base64'));
    const sealed = other.seal('secret-value');
    expect(errorOf(() => new SecretBox(KEY).open(sealed)).code).toBe(
      'INTERNAL',
    );
  });

  it('reports whether it can be used and names the key when it is missing or wrong', () => {
    expect(new SecretBox(KEY).isConfigured()).toBe(true);
    for (const key of [undefined, '', Buffer.alloc(16, 1).toString('base64')]) {
      const box = new SecretBox(key);
      expect(box.isConfigured()).toBe(false);
      expect(errorOf(() => box.seal('x')).message).toContain(
        'PAYOUT_ACCOUNT_KEY',
      );
      expect(errorOf(() => box.open('v1:a:b:c')).message).toContain(
        'PAYOUT_ACCOUNT_KEY',
      );
    }
  });

  it('does not put the key or the value in an error message', () => {
    const box = new SecretBox(undefined);
    expect(errorOf(() => box.seal('secret-value')).message).not.toContain(
      'secret-value',
    );
  });
});
