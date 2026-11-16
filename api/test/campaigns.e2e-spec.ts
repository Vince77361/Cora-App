import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';

const authA = { Authorization: 'Bearer user-a' };
const authB = { Authorization: 'Bearer user-b' };
const BRAND = { name: '느린결', industry: 'ACCESSORY' };
// FakeClock의 기본 시각은 한국 시간 2026-11-11 낮이다.
const CAMPAIGN = {
  headline: '나만의 아침 루틴 속 작은 포인트',
  fee: 300000,
  budget: 1000000,
  productProvided: true,
  format: 'REELS',
  startFrom: '2026-11-20',
  trialDays: 'D7',
  mustInclude: ['제품 로고가 보이게'],
  notRequired: ['FACE'],
};

describe('campaigns', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;

  const setRole = (auth: Record<string, string>, role: string) =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const makeBrand = async (auth = authA) => {
    await setRole(auth, 'BRAND');
    await request(server).put('/brands/me').set(auth).send(BRAND).expect(200);
  };
  const create = (body: Record<string, unknown> = {}, auth = authA) =>
    request(server)
      .post('/campaigns')
      .set(auth)
      .send({ ...CAMPAIGN, ...body });
  const getActive = (auth = authA) =>
    request(server).get('/campaigns/mine/active').set(auth);
  const patch = (id: string, body: Record<string, unknown>, auth = authA) =>
    request(server).patch(`/campaigns/${id}`).set(auth).send(body);
  const close = (id: string, auth = authA) =>
    request(server).post(`/campaigns/${id}/close`).set(auth);
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;
  const idOf = (res: request.Response) => (res.body as { id: string }).id;

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(new Date('2026-11-11T03:00:00.000Z'));
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).get('/campaigns/mine/active').expect(401);
    await request(server).post('/campaigns').expect(401);
    await request(server).patch('/campaigns/x').expect(401);
    await request(server).post('/campaigns/x/close').expect(401);
  });

  it('requires the BRAND role', async () => {
    await setRole(authA, 'CREATOR');
    expect(codeOf(await create().expect(403))).toBe('FORBIDDEN');
    expect(codeOf(await getActive().expect(403))).toBe('FORBIDDEN');
    expect(codeOf(await patch('x', {}).expect(403))).toBe('FORBIDDEN');
    expect(codeOf(await close('x').expect(403))).toBe('FORBIDDEN');
    expect(await prisma.campaign.count()).toBe(0);
  });

  it('refuses a campaign before a brand profile exists', async () => {
    await setRole(authA, 'BRAND');
    const res = await create().expect(409);
    expect(codeOf(res)).toBe('CONFLICT');
    expect(await prisma.campaign.count()).toBe(0);
  });

  it('returns 404 when there is no active campaign', async () => {
    await makeBrand();
    expect(codeOf(await getActive().expect(404))).toBe('NOT_FOUND');
  });

  it('creates a campaign and returns it as the active one', async () => {
    await makeBrand();
    const res = await create().expect(201);
    const expected = { ...CAMPAIGN, status: 'ACTIVE' };
    expect(res.body).toMatchObject(expected);
    expect(idOf(res)).toEqual(expect.any(String));
    expect((await getActive().expect(200)).body).toEqual(res.body);
  });

  it('allows today as the start date and no must-include lines', async () => {
    await makeBrand();
    await create({
      startFrom: '2026-11-11',
      mustInclude: [],
      notRequired: [],
    }).expect(201);
  });

  it('refuses a second active campaign', async () => {
    await makeBrand();
    await create().expect(201);
    expect(codeOf(await create().expect(409))).toBe('CONFLICT');
    expect(await prisma.campaign.count()).toBe(1);
  });

  it('makes exactly one campaign when two creates arrive together', async () => {
    await makeBrand();
    const results = await Promise.all([create(), create()]);
    expect(results.map((r) => r.status).sort()).toEqual([201, 409]);
    expect(await prisma.campaign.count()).toBe(1);
  });

  it('allows a new campaign after closing the old one', async () => {
    await makeBrand();
    const first = idOf(await create().expect(201));
    const closed = await close(first).expect(200);
    expect((closed.body as { status: string }).status).toBe('CLOSED');
    await getActive().expect(404);
    const second = idOf(await create().expect(201));
    expect(second).not.toBe(first);
    expect(idOf(await getActive().expect(200))).toBe(second);
  });

  it('lets a different brand have its own active campaign', async () => {
    await makeBrand(authA);
    await makeBrand(authB);
    await create({}, authA).expect(201);
    await create({}, authB).expect(201);
  });

  it('rejects a fee that is not a multiple of 10000', async () => {
    await makeBrand();
    expect(codeOf(await create({ fee: 15000 + 5 }).expect(400))).toBe(
      'VALIDATION_FAILED',
    );
  });

  it('rejects a fee outside 10000 to 10000000', async () => {
    await makeBrand();
    await create({ fee: 0 }).expect(400);
    await create({ fee: 10000000 + 10000, budget: 20000000 }).expect(400);
    await create({ fee: 10000000, budget: 10000000 }).expect(201);
  });

  it('rejects a start date in the past', async () => {
    await makeBrand();
    expect(codeOf(await create({ startFrom: '2026-11-10' }).expect(400))).toBe(
      'VALIDATION_FAILED',
    );
    // 한국 시간 자정이 지나면 어제였던 날이 아니라 새 날이 오늘이다.
    clock.set(new Date('2026-11-11T15:30:00.000Z'));
    await create({ startFrom: '2026-11-11' }).expect(400);
    await create({ startFrom: '2026-11-12' }).expect(201);
  });

  it('rejects a start date that is not a real calendar date', async () => {
    await makeBrand();
    for (const startFrom of ['2026-02-30', '2026-13-01', '20261120', 'soon']) {
      await create({ startFrom }).expect(400);
    }
  });

  it('rejects more than three must-include lines', async () => {
    await makeBrand();
    await create({ mustInclude: ['a', 'b', 'c', 'd'] }).expect(400);
    await create({ mustInclude: ['a', 'b', 'c'] }).expect(201);
  });

  it('rejects a must-include line that is blank or over 20 characters', async () => {
    await makeBrand();
    await create({ mustInclude: ['가'.repeat(21)] }).expect(400);
    await create({ mustInclude: ['  '] }).expect(400);
  });

  it('rejects a budget below the fee or not a multiple of 10000', async () => {
    await makeBrand();
    await create({ fee: 300000, budget: 290000 }).expect(400);
    await create({ budget: 1000005 }).expect(400);
    await create({ budget: 100010000 }).expect(400);
    await create({ budget: 100000000 }).expect(201);
  });

  it('rejects a bad headline, enum, or unknown field', async () => {
    await makeBrand();
    for (const bad of [
      { headline: '' },
      { headline: 'a'.repeat(41) },
      { format: 'PODCAST' },
      { trialDays: 'D30' },
      { notRequired: ['FACE', 'FACE'] },
      { notRequired: ['NOPE'] },
      { productProvided: 'yes' },
      { status: 'CLOSED' },
      { brandId: '11111111-1111-4111-8111-111111111111' },
    ]) {
      await create(bad).expect(400);
    }
    expect(await prisma.campaign.count()).toBe(0);
  });

  it('updates only the fields that are sent, budget included', async () => {
    await makeBrand();
    const id = idOf(await create().expect(201));
    const res = await patch(id, {
      headline: '새 한 줄',
      budget: 2000000,
    }).expect(200);
    expect(res.body).toMatchObject({
      ...CAMPAIGN,
      headline: '새 한 줄',
      budget: 2000000,
      status: 'ACTIVE',
    });
  });

  it('rejects an update that leaves the budget below the fee', async () => {
    await makeBrand();
    const id = idOf(await create().expect(201));
    expect(codeOf(await patch(id, { budget: 200000 }).expect(400))).toBe(
      'VALIDATION_FAILED',
    );
    expect(codeOf(await patch(id, { fee: 1100000 }).expect(400))).toBe(
      'VALIDATION_FAILED',
    );
    await patch(id, { fee: 1100000, budget: 1100000 }).expect(200);
    const row = await prisma.campaign.findUniqueOrThrow({ where: { id } });
    expect([row.fee, row.budget]).toEqual([1100000, 1100000]);
  });

  it('applies the same field rules to an update', async () => {
    await makeBrand();
    const id = idOf(await create().expect(201));
    await patch(id, { fee: 15005 }).expect(400);
    await patch(id, { startFrom: '2026-11-10' }).expect(400);
    await patch(id, { mustInclude: ['a', 'b', 'c', 'd'] }).expect(400);
    await patch(id, { headline: null }).expect(400);
    await patch(id, { status: 'CLOSED' }).expect(400);
  });

  it('keeps an unchanged start date that has already passed', async () => {
    await makeBrand();
    const id = idOf(await create().expect(201));
    clock.set(new Date('2026-12-01T03:00:00.000Z'));
    await patch(id, { startFrom: '2026-11-20', headline: '고침' }).expect(200);
    await patch(id, { startFrom: '2026-11-25' }).expect(400);
  });

  it("returns 404 when editing another brand's campaign", async () => {
    await makeBrand(authA);
    await makeBrand(authB);
    const id = idOf(await create({}, authA).expect(201));
    expect(
      codeOf(await patch(id, { headline: '가로채기' }, authB).expect(404)),
    ).toBe('NOT_FOUND');
    expect(codeOf(await close(id, authB).expect(404))).toBe('NOT_FOUND');
    const row = await prisma.campaign.findUniqueOrThrow({ where: { id } });
    expect([row.headline, row.status]).toEqual([CAMPAIGN.headline, 'ACTIVE']);
  });

  it('returns 404 for an id that does not exist or is not a uuid', async () => {
    await makeBrand();
    await patch('not-a-uuid', { headline: 'x' }).expect(404);
    await close('not-a-uuid').expect(404);
    await patch('3f0d1c52-4b6e-4f5b-9d8e-0a1b2c3d4e5f', {
      headline: 'x',
    }).expect(404);
  });

  it('refuses to edit a closed campaign and closes idempotently', async () => {
    await makeBrand();
    const id = idOf(await create().expect(201));
    await close(id).expect(200);
    expect(codeOf(await patch(id, { headline: '늦음' }).expect(409))).toBe(
      'CONFLICT',
    );
    const again = await close(id).expect(200);
    expect((again.body as { status: string }).status).toBe('CLOSED');
  });
});
