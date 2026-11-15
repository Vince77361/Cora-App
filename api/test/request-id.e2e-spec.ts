import { Controller, Get, INestApplication, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { AppError } from '../src/common/errors/app-error';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { USER_A } from './support/fake-token-verifier';

// 테스트 전용 컨트롤러. 로그인한 사용자가 권한 없는 곳에 닿은 403을 만든다.
@Controller('__test')
class ForbiddenController {
  @Get('forbidden')
  forbidden() {
    throw new AppError('FORBIDDEN', '권한이 없어요.');
  }
}

// 이 파일의 보안 로그 확인은 Logger를 가로채서 한다(앱 로거는 createTestApp이 꺼 둔다).
describe('request id and security log', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let logs: jest.SpyInstance[];

  beforeAll(async () => {
    prisma = new PrismaClient();
    await truncateTestDb(prisma);
    app = await createTestApp([ForbiddenController]);
    server = httpOf(app);
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });
  beforeEach(() => {
    logs = (['log', 'warn', 'error'] as const).map((level) =>
      jest.spyOn(Logger.prototype, level).mockImplementation(),
    );
  });
  afterEach(() => jest.restoreAllMocks());

  // 보안 로그 줄만 골라 JSON으로 읽는다(다른 로그는 JSON이 아니거나 event가 없다).
  function securityLines(): Record<string, unknown>[] {
    return logs
      .flatMap((spy) => (spy.mock.calls as unknown[][]).map((call) => call[0]))
      .filter((m): m is string => typeof m === 'string' && m.startsWith('{'))
      .map((m) => JSON.parse(m) as Record<string, unknown>)
      .filter((o) => typeof o.event === 'string');
  }

  it('echoes a valid incoming X-Request-Id and generates one otherwise', async () => {
    const echoed = await request(server)
      .get('/health')
      .set('X-Request-Id', 'client-req-0001')
      .expect(200);
    expect(echoed.headers['x-request-id']).toBe('client-req-0001');

    const generated = await request(server).get('/health').expect(200);
    expect(generated.headers['x-request-id']).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );

    const replaced = await request(server)
      .get('/health')
      .set('X-Request-Id', 'bad id with spaces')
      .expect(200);
    expect(replaced.headers['x-request-id']).not.toBe('bad id with spaces');
  });

  it('puts the same request id in the error body and the response header', async () => {
    const res = await request(server).get('/nope').expect(404);
    const header = res.headers['x-request-id'];
    expect(header).toBeTruthy();
    expect((res.body as { error: { requestId: string } }).error.requestId).toBe(
      header,
    );
  });

  it('logs AUTH_FAILED with a reason category and never the token', async () => {
    const token = 'eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJ4In0.c2ln';
    // 본문이 있는 요청도 같은 요청 ID를 보는지 함께 확인한다(본문 해석 뒤에도 문맥이 이어져야 한다).
    const res = await request(server)
      .patch('/me/role')
      .set('Authorization', `Bearer ${token}`)
      .send({ role: 'STORE' })
      .expect(401);
    const lines = securityLines().filter((l) => l.event === 'AUTH_FAILED');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toMatchObject({
      result: 'DENIED',
      reason: 'INVALID',
      requestId: res.headers['x-request-id'],
    });
    expect(
      JSON.stringify(logs.map((s) => s.mock.calls as unknown[])),
    ).not.toContain('eyJ');

    await request(server).get('/me').expect(401);
    expect(
      securityLines().filter((l) => l.event === 'AUTH_FAILED')[1],
    ).toMatchObject({ reason: 'MISSING' });
  });

  it('logs FORBIDDEN for a 403 with the route and no query string', async () => {
    const res = await request(server)
      .get('/__test/forbidden?token=secret-value')
      .set('Authorization', 'Bearer user-a');
    expect(res.status).toBe(403);
    const forbidden = securityLines().filter((l) => l.event === 'FORBIDDEN');
    expect(forbidden).toHaveLength(1);
    expect(forbidden[0]).toMatchObject({
      result: 'DENIED',
      userId: USER_A,
      target: 'GET /__test/forbidden',
    });
    expect(JSON.stringify(forbidden)).not.toContain('secret-value');
  });

  it('logs ROLE_CHANGED with the previous and the new role', async () => {
    await request(server)
      .patch('/me/role')
      .set('Authorization', 'Bearer user-a')
      .send({ role: 'STORE' })
      .expect(200);
    await request(server)
      .patch('/me/role')
      .set('Authorization', 'Bearer user-a')
      .send({ role: 'CREATOR' })
      .expect(200);
    const changed = securityLines().filter((l) => l.event === 'ROLE_CHANGED');
    expect(changed).toHaveLength(2);
    expect(changed[1]).toMatchObject({
      userId: USER_A,
      result: 'ALLOWED',
      reason: 'STORE→CREATOR',
    });
  });
});
