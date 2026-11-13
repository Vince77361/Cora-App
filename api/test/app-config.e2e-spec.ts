import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp, httpOf } from './helpers/create-test-app';

describe('app config', () => {
  let app: INestApplication;
  beforeAll(async () => {
    app = await createTestApp();
  });
  afterAll(() => app.close());

  it('serves the reward ranges and fee rates without a token', async () => {
    const res = await request(httpOf(app)).get('/config').expect(200);
    expect(res.headers['cache-control']).toBe('max-age=60');
    expect(res.body).toEqual({
      reward: {
        viewRate: { min: 1000, max: 5000, step: 500, default: 2000 },
        perViewCap: { min: 10000, max: 300000, step: 10000, default: 60000 },
        fixedCash: {
          maxByCommissioner: { store: 1000000, brand: 10000000 },
          step: 10000,
          presets: [0, 30000, 50000, 100000],
        },
        voucher: {
          defaultName: '식사권',
          defaultValue: 40000,
          defaultPeople: 2,
          maxPeople: 10,
        },
        usageRightsDefault: 'STORE_REPOST_3M',
        countingDays: 7,
      },
      feeRates: { storeOffer: 10, bid: 10, brandContract: 10 },
    });
  });

  it('lists the config in the OpenAPI document', async () => {
    const res = await request(httpOf(app)).get('/docs-json').expect(200);
    const body = res.body as {
      paths: Record<string, { get?: { operationId?: string } }>;
    };
    expect(body.paths['/config'].get?.operationId).toBe('getAppConfig');
  });
});
