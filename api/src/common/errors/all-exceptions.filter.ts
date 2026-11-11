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
    default:
      return 'INTERNAL';
  }
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
      // 4xx 중 매핑 밖의 상태(예: 429)나 5xx는 내부 메시지를 숨긴다.
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
      this.send(res, status, code, messageOf(exception), null);
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
