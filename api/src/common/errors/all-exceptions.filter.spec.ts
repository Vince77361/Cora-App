import { ArgumentsHost, HttpException, Logger } from '@nestjs/common';
import { AllExceptionsFilter } from './all-exceptions.filter';
import { AppError, ErrorCode, STATUS_BY_CODE } from './app-error';

// 손으로 쓴 가짜 응답: status와 json 본문만 기록한다.
class FakeResponse {
  statusCode = 0;
  body: unknown = null;
  status(code: number): this {
    this.statusCode = code;
    return this;
  }
  json(body: unknown): this {
    this.body = body;
    return this;
  }
}

function hostOf(res: FakeResponse): ArgumentsHost {
  return {
    switchToHttp: () => ({ getResponse: () => res }),
  } as unknown as ArgumentsHost;
}

describe('AllExceptionsFilter', () => {
  let error: jest.SpyInstance;
  beforeEach(() => {
    error = jest.spyOn(Logger.prototype, 'error').mockImplementation();
  });
  afterEach(() => error.mockRestore());

  it('logs an INTERNAL AppError so an outage is visible', () => {
    const res = new FakeResponse();
    new AllExceptionsFilter().catch(
      new AppError('INTERNAL', '서버 오류가 발생했어요.'),
      hostOf(res),
    );
    expect(res.statusCode).toBe(500);
    expect(error).toHaveBeenCalledTimes(1);
    const logged = JSON.stringify(error.mock.calls);
    expect(logged).toContain('INTERNAL');
    expect(logged).not.toContain('Bearer');
  });

  it('does not log expected client errors', () => {
    const res = new FakeResponse();
    new AllExceptionsFilter().catch(
      new AppError('UNAUTHENTICATED', '로그인이 필요해요.'),
      hostOf(res),
    );
    expect(res.statusCode).toBe(401);
    expect(error).not.toHaveBeenCalled();
  });

  function run(exception: unknown): FakeResponse {
    const res = new FakeResponse();
    new AllExceptionsFilter().catch(exception, hostOf(res));
    return res;
  }
  function codeOf(res: FakeResponse): string {
    return (res.body as { error: { code: string } }).error.code;
  }

  it('maps an AppError RATE_LIMITED to 429', () => {
    const res = run(new AppError('RATE_LIMITED', '잠시 뒤에 다시 해 주세요.'));
    expect(res.statusCode).toBe(429);
    expect(res.body).toEqual({
      error: {
        code: 'RATE_LIMITED',
        message: '잠시 뒤에 다시 해 주세요.',
        details: null,
      },
    });
    expect(error).not.toHaveBeenCalled();
  });

  it('maps an HttpException 429 to RATE_LIMITED', () => {
    // 나중 계획의 ThrottlerException이 HttpException 429라 500으로 나가면 안 된다.
    const res = run(
      new HttpException('ThrottlerException: Too Many Requests', 429),
    );
    expect(res.statusCode).toBe(429);
    expect(codeOf(res)).toBe('RATE_LIMITED');
    // 영어 원문 대신 화면에 보여 줄 고정 문구를 쓴다.
    expect(JSON.stringify(res.body)).not.toContain('Throttler');
    expect(error).not.toHaveBeenCalled();
  });

  it('keeps the status of an exposed body-parser 413', () => {
    const res = run(
      Object.assign(new Error('request entity too large'), {
        status: 413,
        statusCode: 413,
        expose: true,
        type: 'entity.too.large',
      }),
    );
    expect(res.statusCode).toBe(413);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
    expect(JSON.stringify(res.body)).not.toContain('entity');
    expect(error).not.toHaveBeenCalled();
  });

  it('returns 400 VALIDATION_FAILED for an exposed parse error', () => {
    const res = run(
      Object.assign(new SyntaxError('Unexpected token } in JSON'), {
        status: 400,
        expose: true,
      }),
    );
    expect(res.statusCode).toBe(400);
    expect(codeOf(res)).toBe('VALIDATION_FAILED');
    expect(JSON.stringify(res.body)).not.toContain('token');
  });

  it('maps an unmapped HttpException 4xx without turning it into 500', () => {
    for (const status of [405, 415, 422]) {
      const res = run(new HttpException('nope', status));
      expect(res.statusCode).toBe(status);
      expect(codeOf(res)).toBe('VALIDATION_FAILED');
    }
    expect(error).not.toHaveBeenCalled();
  });

  it('keeps a 5xx HttpException status and hides its message', () => {
    const res = run(new HttpException('db down at 10.0.0.1', 503));
    expect(res.statusCode).toBe(503);
    expect(codeOf(res)).toBe('INTERNAL');
    expect(JSON.stringify(res.body)).not.toContain('10.0.0.1');
    expect(error).toHaveBeenCalledTimes(1);
  });

  it('treats an error that is not exposed as INTERNAL even with a 4xx status', () => {
    const res = run(Object.assign(new Error('secret'), { status: 400 }));
    expect(res.statusCode).toBe(500);
    expect(codeOf(res)).toBe('INTERNAL');
    expect(JSON.stringify(res.body)).not.toContain('secret');
  });

  it('treats an exposed error with a 5xx status as INTERNAL', () => {
    const res = run(
      Object.assign(new Error('x'), { status: 502, expose: true }),
    );
    expect(res.statusCode).toBe(500);
    expect(codeOf(res)).toBe('INTERNAL');
  });

  it('maps every error code to the documented status', () => {
    const table: Record<ErrorCode, number> = {
      VALIDATION_FAILED: 400,
      UNAUTHENTICATED: 401,
      FORBIDDEN: 403,
      NOT_FOUND: 404,
      CONFLICT: 409,
      RATE_LIMITED: 429,
      INTERNAL: 500,
    };
    expect(STATUS_BY_CODE).toEqual(table);
  });
});
