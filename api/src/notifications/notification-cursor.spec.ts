import { AppError } from '../common/errors/app-error';
import { decodeCursor, encodeCursor } from './notification-cursor';

const ID = '33333333-3333-4333-8333-333333333333';

describe('notification cursor', () => {
  it('round-trips the time and id', () => {
    const createdAt = new Date('2026-11-11T03:00:00.123Z');
    expect(decodeCursor(encodeCursor({ createdAt, id: ID }))).toEqual({
      createdAt,
      id: ID,
    });
  });

  it('is safe to put in a url', () => {
    const value = encodeCursor({ createdAt: new Date(0), id: ID });
    expect(value).toMatch(/^[A-Za-z0-9_-]+$/);
  });

  it.each([
    '',
    'not-a-cursor',
    Buffer.from('abc.def').toString('base64url'),
    Buffer.from(`12x.${ID}`).toString('base64url'),
    Buffer.from(`${Date.now()}.not-a-uuid`).toString('base64url'),
    Buffer.from(`${ID}`).toString('base64url'),
    Buffer.from(`99999999999999999999.${ID}`).toString('base64url'),
  ])('rejects the malformed value %p', (value) => {
    expect(() => decodeCursor(value)).toThrow(AppError);
  });
});
