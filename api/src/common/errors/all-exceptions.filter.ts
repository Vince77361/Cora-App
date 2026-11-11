import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  Logger,
} from '@nestjs/common';
import type { Response } from 'express';
import { AppError, ErrorCode, STATUS_BY_CODE } from './app-error';

export const INTERNAL_MESSAGE = '서버 오류가 발생했어요.';

function codeForStatus(status: number): ErrorCode {
  switch (status) {
    case 400:
      return 'VALIDATION_FAILED';
    case 401:
      return 'UNAUTHENTICATED';
    case 403:
      return 'FORBIDDEN';
    case 404:
      return 'NOT_FOUND';
    case 409:
      return 'CONFLICT';
    case 429:
      return 'RATE_LIMITED';
    default:
      // 매핑에 없는 4xx(405, 413, 415 등)는 호출자의 요청이 잘못된 것이므로 요청 값 오류로 묶는다.
      // 상태 코드는 바꾸지 않는다. 5xx만 서버 오류다.
      return status >= 400 && status < 500 ? 'VALIDATION_FAILED' : 'INTERNAL';
  }
}

export const RATE_LIMITED_MESSAGE =
  '요청이 너무 많아요. 잠시 뒤에 다시 시도해 주세요.';
export const MALFORMED_REQUEST_MESSAGE = '요청 형식이 올바르지 않아요.';
export const PAYLOAD_TOO_LARGE_MESSAGE = '요청이 너무 커요.';
export const BAD_REQUEST_MESSAGE = '요청을 처리할 수 없어요.';

// body-parser(깨진 JSON, 너무 큰 본문)가 던지는 http-errors는 HttpException이 아니지만
// status와 expose: true를 가진다. 호출자 잘못이므로 원래 4xx 상태를 지켜서 내보낸다.
function exposedClientStatus(exception: unknown): number | null {
  if (typeof exception !== 'object' || exception === null) return null;
  const e = exception as { status?: unknown; expose?: unknown };
  if (e.expose !== true) return null;
  return typeof e.status === 'number' && e.status >= 400 && e.status < 500
    ? e.status
    : null;
}

function messageForExposed(status: number): string {
  if (status === 400) return MALFORMED_REQUEST_MESSAGE;
  if (status === 413) return PAYLOAD_TOO_LARGE_MESSAGE;
  return BAD_REQUEST_MESSAGE;
}

function messageOf(exception: HttpException): string {
  const body = exception.getResponse();
  if (typeof body === 'string') return body;
  const message = (body as { message?: unknown }).message;
  if (typeof message === 'string') return message;
  return exception.message;
}

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();

    if (exception instanceof AppError) {
      // INTERNAL은 서버 쪽 장애(예: 키 묶음 조회 실패)라 로그가 없으면 보이지 않는다.
      // AppError의 메시지는 화면에 보여 줄 고정 문구라 토큰이나 개인정보가 없다.
      if (exception.code === 'INTERNAL') {
        this.logger.error(
          `AppError INTERNAL: ${exception.message}`,
          exception.stack,
        );
      }
      this.send(
        res,
        STATUS_BY_CODE[exception.code],
        exception.code,
        exception.message,
        exception.details,
      );
      return;
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const code = codeForStatus(status);
      // 5xx는 내부 메시지를 숨기고 로그에만 남긴다.
      if (code === 'INTERNAL') {
        this.logger.error(exception.message, exception.stack);
        this.send(
          res,
          status >= 500 ? status : 500,
          'INTERNAL',
          INTERNAL_MESSAGE,
          null,
        );
        return;
      }
      const message =
        code === 'RATE_LIMITED' ? RATE_LIMITED_MESSAGE : messageOf(exception);
      this.send(res, status, code, message, null);
      return;
    }

    const exposedStatus = exposedClientStatus(exception);
    if (exposedStatus !== null) {
      this.send(
        res,
        exposedStatus,
        codeForStatus(exposedStatus),
        messageForExposed(exposedStatus),
        null,
      );
      return;
    }

    // 알 수 없는 오류의 원문은 서버 로그에만 남기고 응답에는 고정 문구만 쓴다.
    this.logger.error(
      exception instanceof Error ? exception.message : String(exception),
      exception instanceof Error ? exception.stack : undefined,
    );
    this.send(res, 500, 'INTERNAL', INTERNAL_MESSAGE, null);
  }

  private send(
    res: Response,
    status: number,
    code: ErrorCode,
    message: string,
    details: unknown,
  ): void {
    res
      .status(status)
      .json({ error: { code, message, details: details ?? null } });
  }
}
