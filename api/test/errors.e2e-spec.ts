import { Body, Controller, Get, INestApplication, Post } from '@nestjs/common';
import { IsInt } from 'class-validator';
import request from 'supertest';
import { Public } from '../src/auth/public.decorator';
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
});
