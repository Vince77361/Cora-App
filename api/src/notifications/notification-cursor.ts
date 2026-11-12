import { AppError } from '../common/errors/app-error';

export interface NotificationCursor {
  createdAt: Date;
  id: string;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 쪽 사이에 새 줄이 끼어도 밀리지 않게 (만든 시각, id)의 위치를 가리킨다. 앱은 뜻을 모르고 그대로 돌려준다.
export function encodeCursor(cursor: NotificationCursor): string {
  return Buffer.from(
    `${cursor.createdAt.getTime()}.${cursor.id}`,
    'utf8',
  ).toString('base64url');
}

export function decodeCursor(value: string): NotificationCursor {
  const decoded = Buffer.from(value, 'base64url').toString('utf8');
  const dot = decoded.indexOf('.');
  const millis = Number(decoded.slice(0, dot));
  const id = decoded.slice(dot + 1);
  const createdAt = new Date(millis);
  if (
    dot <= 0 ||
    !/^\d+$/.test(decoded.slice(0, dot)) ||
    Number.isNaN(createdAt.getTime()) ||
    !UUID.test(id)
  ) {
    throw new AppError('VALIDATION_FAILED', '요청 값이 올바르지 않아요.', [
      'cursor가 올바르지 않아요.',
    ]);
  }
  return { createdAt, id };
}
