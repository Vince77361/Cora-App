import { ArgumentsHost, Logger } from '@nestjs/common';
import { AllExceptionsFilter } from './all-exceptions.filter';
import { AppError } from './app-error';

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
});
