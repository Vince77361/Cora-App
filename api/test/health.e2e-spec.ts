import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp, httpOf } from './helpers/create-test-app';

describe('health', () => {
  let app: INestApplication;
  beforeAll(async () => {
    app = await createTestApp();
  });
  afterAll(() => app.close());

  it('GET /health returns ok without a token', async () => {
    await request(httpOf(app)).get('/health').expect(200, { status: 'ok' });
  });

  it('serves the OpenAPI document', async () => {
    const res = await request(httpOf(app)).get('/docs-json').expect(200);
    const body = res.body as { paths: Record<string, unknown> };
    expect(body.paths['/health']).toBeDefined();
  });
});
