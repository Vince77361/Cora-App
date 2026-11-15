import { randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';
import { runWithRequestContext } from './request-context';

export const REQUEST_ID_HEADER = 'X-Request-Id';

// 들어온 값을 그대로 로그와 응답 헤더에 싣기 때문에 길이와 문자를 좁게 제한한다(로그 주입, 헤더 주입 방지).
const VALID_REQUEST_ID = /^[A-Za-z0-9-]{8,64}$/;

// 가장 앞에서 요청 ID를 정하고, 이후 모든 처리(가드, 서비스, 오류 필터)가 같은 ID를 보게 한다.
// 앱이 오류 화면에서 이 ID를 알려 주면 서버 로그와 이어 볼 수 있다.
export function requestIdMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const incoming = req.headers['x-request-id'];
  const requestId =
    typeof incoming === 'string' && VALID_REQUEST_ID.test(incoming)
      ? incoming
      : randomUUID();
  res.setHeader(REQUEST_ID_HEADER, requestId);
  runWithRequestContext({ requestId, ip: req.ip }, () => next());
}
