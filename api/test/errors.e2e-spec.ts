import {
  Body,
  Controller,
  Get,
  HttpException,
  INestApplication,
  Post,
} from '@nestjs/common';
import { IsInt } from 'class-validator';
import request from 'supertest';
import { Public } from '../src/auth/public.decorator';
import { AppError } from '../src/common/errors/app-error';
import { createTestApp, httpOf } from './helpers/create-test-app';

class SampleDto {
  @IsInt()
  count!: number;
}

// 테스트 전용 컨트롤러. src에는 두지 않는다. 토큰 없이 오류 형식만 보려고 공개로 연다.
@Public()
@Controller('__test')
class TestController {
  @Get('boom')
  boom() {
    throw new Error('db password leaked');
  }

  @Get('throttled')
  throttled() {
    throw new HttpException('ThrottlerException: Too Many Requests', 429);
  }

  @Get('teapot')
  teapot() {
    throw new HttpException('매핑에 없는 4xx', 418);
  }

  @Get('rate-limited')
  rateLimited() {
    throw new AppError('RATE_LIMITED', '요청이 너무 많아요.');
  }

  @Post('validate')
  validate(@Body() body: SampleDto) {
    return body;
  }
}

describe('error envelope', () => {
  let app: INestApplication;
  beforeAll(async () => {
    app = await createTestApp([TestController]);
  });
  afterAll(() => app.close());

  it('wraps an unknown route in the error envelope', async () => {
    const res = await request(httpOf(app)).get('/nope').expect(404);
    expect(res.body).toEqual({
      error: {
        code: 'NOT_FOUND',
        message: expect.any(String) as string,
        details: null,
      },
    });
  });

  it('hides internal error messages', async () => {
    const res = await request(httpOf(app)).get('/__test/boom').expect(500);
    expect(res.body).toEqual({
      error: {
        code: 'INTERNAL',
        message: '서버 오류가 발생했어요.',
        details: null,
      },
    });
    expect(JSON.stringify(res.body)).not.toContain('leaked');
  });

  it('returns VALIDATION_FAILED with per-field details', async () => {
    const res = await request(httpOf(app))
      .post('/__test/validate')
      .send({ count: 'x', extra: 1 })
      .expect(400);
    const body = res.body as { error: { code: string; details: unknown } };
    expect(body.error.code).toBe('VALIDATION_FAILED');
    expect(body.error.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ field: 'count' }),
        expect.objectContaining({ field: 'extra' }),
      ]),
    );
  });

  it('maps an HttpException 429 to RATE_LIMITED', async () => {
    const res = await request(httpOf(app)).get('/__test/throttled').expect(429);
    expect(res.body).toEqual({
      error: {
        code: 'RATE_LIMITED',
        message: expect.any(String) as string,
        details: null,
      },
    });
  });

  it('maps an AppError RATE_LIMITED to 429', async () => {
    const res = await request(httpOf(app))
      .get('/__test/rate-limited')
      .expect(429);
    expect((res.body as { error: { code: string } }).error.code).toBe(
      'RATE_LIMITED',
    );
  });

  it('returns 400 VALIDATION_FAILED for malformed JSON', async () => {
    const res = await request(httpOf(app))
      .post('/__test/validate')
      .set('Content-Type', 'application/json')
      .send('{"count": ')
      .expect(400);
    expect(res.body).toEqual({
      error: {
        code: 'VALIDATION_FAILED',
        message: expect.any(String) as string,
        details: null,
      },
    });
  });

  it('keeps the status of an exposed body-parser 413', async () => {
    const res = await request(httpOf(app))
      .post('/__test/validate')
      .send({ count: 1, padding: 'x'.repeat(200 * 1024) })
      .expect(413);
    expect((res.body as { error: { code: string } }).error.code).toBe(
      'VALIDATION_FAILED',
    );
  });

  it('maps an unmapped HttpException 4xx without turning it into 500', async () => {
    const res = await request(httpOf(app)).get('/__test/teapot').expect(418);
    expect(res.body).toEqual({
      error: {
        code: 'VALIDATION_FAILED',
        message: expect.any(String) as string,
        details: null,
      },
    });
  });
});
