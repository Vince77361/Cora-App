import { Body, Controller, INestApplication, Post } from '@nestjs/common';
import request from 'supertest';
import { Public } from '../src/auth/public.decorator';
import { createTestApp, httpOf } from './helpers/create-test-app';

// 테스트 전용 컨트롤러. 토큰 없이 본문 처리만 보려고 공개로 연다.
@Public()
@Controller('__hardening')
class HardeningController {
  @Post('echo')
  echo(@Body() body: unknown) {
    return { ok: true, received: body ?? null };
  }
}

// 요청 수 제한 값은 앱 모듈을 불러오는 순간(ConfigModule.forRoot) process.env에서 읽혀 굳는다.
// 그래서 값을 바꾸고 모듈 레지스트리를 비운 뒤 앱 모듈을 새로 불러와 앱을 만든다(setup-env.ts의 큰 값은 다른 테스트용).
async function createLimitedApp(
  limits: { ip: number; user: number },
  ...args: Parameters<typeof createTestApp>
): Promise<INestApplication> {
  const before = {
    ip: process.env.RATE_LIMIT_IP_PER_MIN,
    user: process.env.RATE_LIMIT_USER_PER_MIN,
  };
  process.env.RATE_LIMIT_IP_PER_MIN = String(limits.ip);
  process.env.RATE_LIMIT_USER_PER_MIN = String(limits.user);
  jest.resetModules();
  try {
    const fresh = jest.requireActual<{ createTestApp: typeof createTestApp }>(
      './helpers/create-test-app',
    );
    return await fresh.createTestApp(...args);
  } finally {
    process.env.RATE_LIMIT_IP_PER_MIN = before.ip;
    process.env.RATE_LIMIT_USER_PER_MIN = before.user;
  }
}

describe('hardening: swagger, headers and body limits', () => {
  it('serves no swagger routes in production', async () => {
    const app = await createTestApp([], { env: { NODE_ENV: 'production' } });
    try {
      await request(httpOf(app)).get('/docs').expect(404);
      await request(httpOf(app)).get('/docs-json').expect(404);
    } finally {
      await app.close();
    }
  });

  it('serves swagger in development', async () => {
    const app = await createTestApp([], { env: { NODE_ENV: 'development' } });
    try {
      const docs = await request(httpOf(app)).get('/docs').expect(200);
      // Swagger UI는 인라인 스크립트를 쓰므로 이 경로에만 CSP가 없다. 다른 경로에는 있다.
      expect(docs.headers['content-security-policy']).toBeUndefined();
      await request(httpOf(app)).get('/docs-json').expect(200);
      const health = await request(httpOf(app)).get('/health').expect(200);
      expect(health.headers['content-security-policy']).toBeDefined();
    } finally {
      await app.close();
    }
  });

  describe('on a running app', () => {
    let app: INestApplication;
    beforeAll(async () => {
      app = await createTestApp([HardeningController]);
    });
    afterAll(() => app.close());

    it('sends helmet headers and no x-powered-by', async () => {
      const res = await request(httpOf(app)).get('/health').expect(200);
      expect(res.headers['x-content-type-options']).toBe('nosniff');
      expect(res.headers['x-powered-by']).toBeUndefined();
      expect(res.headers['strict-transport-security']).toBeDefined();
    });

    it('answers 413 for a json body over 100kb', async () => {
      const res = await request(httpOf(app))
        .post('/__hardening/echo')
        .send({ text: 'a'.repeat(101 * 1024) })
        .expect(413);
      expect((res.body as { error: { code: string } }).error.code).toBe(
        'VALIDATION_FAILED',
      );
    });

    it('accepts a json body just under the limit', async () => {
      await request(httpOf(app))
        .post('/__hardening/echo')
        .send({ text: 'a'.repeat(90 * 1024) })
        .expect(201);
    });

    it('answers 415 for a text/plain body on a json route', async () => {
      const res = await request(httpOf(app))
        .post('/__hardening/echo')
        .set('content-type', 'text/plain')
        .send('hello')
        .expect(415);
      expect((res.body as { error: { code: string } }).error.code).toBe(
        'VALIDATION_FAILED',
      );
      await request(httpOf(app))
        .post('/__hardening/echo')
        .type('form')
        .send({ a: '1' })
        .expect(415);
    });

    it('does not answer 415 for a request without a body or for the raw-body webhook', async () => {
      await request(httpOf(app)).post('/__hardening/echo').expect(201);
      // 원문 본문을 받는 경로는 형식 검사에서 빠진다: 415가 아니라 서명 검증이 거절한다(401).
      await request(httpOf(app))
        .post('/webhooks/payments')
        .set('content-type', 'text/plain')
        .send('raw')
        .expect(401);
    });
  });
});

describe('hardening: request rate limits', () => {
  it('limits signed-in users by user id, not by shared ip', async () => {
    const app = await createLimitedApp({ ip: 1000, user: 3 });
    try {
      const get = (token: string) =>
        request(httpOf(app)).get('/me').set('authorization', `Bearer ${token}`);
      // 사용자 제한이 보는 것은 사용자 ID뿐이라, 같은 IP의 user-a가 한도에 닿아도 user-b는 막히지 않는다.
      for (let i = 0; i < 3; i++) {
        expect((await get('user-a')).status).not.toBe(429);
      }
      const limited = await get('user-a').expect(429);
      expect((limited.body as { error: { code: string } }).error.code).toBe(
        'RATE_LIMITED',
      );
      expect((await get('user-b')).status).not.toBe(429);
    } finally {
      await app.close();
    }
  });

  it('shares one user limit across different routes', async () => {
    const app = await createLimitedApp({ ip: 1000, user: 3 });
    try {
      const get = (path: string) =>
        request(httpOf(app)).get(path).set('authorization', 'Bearer user-a');
      // 경로가 달라도 한 사용자의 한도 하나를 함께 쓴다(경로마다 따로 세면 경로 수만큼 느슨해진다).
      expect((await get('/me')).status).not.toBe(429);
      expect((await get('/notifications')).status).not.toBe(429);
      expect((await get('/wallet')).status).not.toBe(429);
      await get('/me').expect(429);
      await get('/notifications').expect(429);
    } finally {
      await app.close();
    }
  });

  it('shares one ip limit across different routes', async () => {
    const app = await createLimitedApp({ ip: 3, user: 1000 });
    try {
      const bad = (path: string) =>
        request(httpOf(app)).get(path).set('authorization', 'Bearer nope');
      await bad('/me').expect(401);
      await bad('/notifications').expect(401);
      await bad('/wallet').expect(401);
      await bad('/stores/me').expect(429);
    } finally {
      await app.close();
    }
  });

  it('limits an ip even when the tokens are invalid', async () => {
    const app = await createLimitedApp({ ip: 3, user: 1000 });
    try {
      const bad = () =>
        request(httpOf(app)).get('/me').set('authorization', 'Bearer nope');
      for (let i = 0; i < 3; i++) await bad().expect(401);
      // 인증 가드보다 먼저 세므로 잘못된 토큰 홍수도 401이 아니라 429로 막힌다.
      await bad().expect(429);
    } finally {
      await app.close();
    }
  });

  it('ignores x-forwarded-for when no proxy is trusted', async () => {
    const app = await createLimitedApp({ ip: 3, user: 1000 }, [], {
      env: { TRUST_PROXY_HOPS: 0 },
    });
    try {
      for (let i = 0; i < 3; i++) {
        await request(httpOf(app))
          .get('/me')
          .set('x-forwarded-for', `203.0.113.${i}`)
          .expect(401);
      }
      await request(httpOf(app))
        .get('/me')
        .set('x-forwarded-for', '203.0.113.99')
        .expect(429);
    } finally {
      await app.close();
    }
  });

  it('counts the forwarded client ip when one proxy is trusted', async () => {
    const app = await createLimitedApp({ ip: 2, user: 1000 }, [], {
      env: { TRUST_PROXY_HOPS: 1 },
    });
    try {
      const from = (ip: string) =>
        request(httpOf(app)).get('/me').set('x-forwarded-for', ip);
      await from('203.0.113.1').expect(401);
      await from('203.0.113.1').expect(401);
      await from('203.0.113.1').expect(429);
      // 다른 클라이언트 IP는 따로 센다: 프록시 뒤에서 모두가 한 IP로 보이면 안 된다.
      await from('203.0.113.2').expect(401);
    } finally {
      await app.close();
    }
  });

  it('does not limit the payment webhook or health', async () => {
    const app = await createLimitedApp({ ip: 2, user: 2 });
    try {
      for (let i = 0; i < 6; i++) {
        await request(httpOf(app)).get('/health').expect(200);
        // 서명이 없어 401이지만 429가 아니다.
        await request(httpOf(app))
          .post('/webhooks/payments')
          .send({})
          .expect(401);
      }
    } finally {
      await app.close();
    }
  });
});
