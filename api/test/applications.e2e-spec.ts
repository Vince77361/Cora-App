import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { PushPort } from '../src/integrations/push/push.port';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakePushPort } from './support/fake-push.port';
import { USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const LINKS = [
  { kind: 'NAVER_MAP', url: 'https://map.naver.com/p/entry/place/1' },
];
const REGION = { regionSido: '서울특별시', regionSigungu: '성동구' };
const PROFILE = {
  displayName: '하루 한 컵',
  contentFocus: '카페 릴스',
  ...REGION,
};

interface ApplicationBody {
  id: string;
  storeId: string;
  status: string;
}
interface ApplicantBody {
  applicationId: string;
  creator: {
    userId: string;
    displayName: string;
    regionSigungu: string | null;
  };
  appliedAt: string;
}

describe('applications', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let push: FakePushPort;

  const setRole = (role: 'STORE' | 'CREATOR' | 'BRAND') =>
    request(server).patch('/me/role').set(auth).send({ role }).expect(200);
  const putProfile = (over: Record<string, unknown> = {}) =>
    request(server)
      .put('/creators/me')
      .set(auth)
      .send({ ...PROFILE, ...over })
      .expect(200);
  const apply = (storeId: string) =>
    request(server).post(`/stores/${storeId}/applications`).set(auth).send();
  const cancel = (storeId: string) =>
    request(server).delete(`/stores/${storeId}/applications/mine`).set(auth);
  const applicants = () =>
    request(server).get('/stores/me/applications').set(auth);
  const detail = (storeId: string) =>
    request(server).get(`/stores/${storeId}`).set(auth);
  const codeOf = (res: request.Response) =>
    (res.body as { error: { code: string } }).error.code;

  // 다른 사장님의 가게를 DB에 바로 만든다(테스트용 로그인 사용자는 한 명뿐이다).
  async function seedStore(
    over: Partial<{
      status: 'DRAFT' | 'PUBLISHED';
      regionSido: string;
      regionSigungu: string | null;
    }> = {},
  ): Promise<{ id: string; ownerId: string }> {
    const ownerId = randomUUID();
    await prisma.user.create({ data: { id: ownerId, role: 'STORE' } });
    const status = over.status ?? 'PUBLISHED';
    const store = await prisma.store.create({
      data: {
        ownerId,
        status,
        onboardingStep: status === 'PUBLISHED' ? 'DONE' : 'PAGE',
        name: '남의 가게',
        regionSido: over.regionSido ?? '서울특별시',
        regionSigungu:
          over.regionSigungu === undefined ? '성동구' : over.regionSigungu,
        defaultFormat: 'REELS',
        defaultRewardType: 'VOUCHER',
        defaultVoucherName: '2인 식사권',
        defaultVoucherValue: 40000,
        publishedAt: status === 'PUBLISHED' ? new Date() : null,
      },
    });
    return { id: store.id, ownerId };
  }

  // 내 가게(user-a)를 만들어 공개한다. 끝나면 역할은 STORE다.
  async function publishMine(
    region: { regionSido: string; regionSigungu: string } = {
      regionSido: '서울특별시',
      regionSigungu: '성동구',
    },
  ): Promise<string> {
    await setRole('STORE');
    await request(server)
      .post('/stores/me/analyze')
      .set(auth)
      .send({ links: LINKS })
      .expect(200);
    await request(server)
      .patch('/stores/me')
      .set(auth)
      .send(region)
      .expect(200);
    await request(server)
      .put('/stores/me/default-terms')
      .set(auth)
      .send({ format: 'REELS', rewardType: 'VOUCHER' })
      .expect(200);
    const res = await request(server)
      .post('/stores/me/publish')
      .set(auth)
      .send()
      .expect(200);
    return (res.body as { id: string }).id;
  }

  // 활동 프로필이 있는 다른 크리에이터를 DB에 바로 만들고, 그 이름으로 가게에 지원시킨다.
  async function seedApplicant(
    storeId: string,
    name: string,
    region: { regionSido: string; regionSigungu: string | null },
    status: 'APPLIED' | 'OFFERED' | 'CANCELLED' = 'APPLIED',
    createdAt = new Date(),
  ): Promise<string> {
    const userId = randomUUID();
    await prisma.user.create({ data: { id: userId, role: 'CREATOR' } });
    await prisma.creatorProfile.create({
      data: { userId, displayName: name, ...region },
    });
    const row = await prisma.application.create({
      data: { storeId, creatorId: userId, status, createdAt },
    });
    return row.id;
  }

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    push = app.get<FakePushPort>(PushPort);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    push.sent.length = 0;
  });
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).get('/stores/me/applications').expect(401);
    await request(server)
      .post(`/stores/${randomUUID()}/applications`)
      .expect(401);
    await request(server)
      .delete(`/stores/${randomUUID()}/applications/mine`)
      .expect(401);
  });

  describe('as a creator', () => {
    beforeEach(async () => {
      await setRole('CREATOR');
      await putProfile();
    });

    it('lets a creator apply to a published store', async () => {
      const store = await seedStore();
      const res = await apply(store.id).expect(201);
      const body = res.body as ApplicationBody;
      expect(body).toEqual({
        id: expect.any(String) as string,
        storeId: store.id,
        status: 'APPLIED',
      });
      const row = await prisma.application.findUniqueOrThrow({
        where: { id: body.id },
      });
      expect(row).toMatchObject({ creatorId: USER_A, status: 'APPLIED' });
    });

    it('notifies the store owner on a new application', async () => {
      const store = await seedStore();
      await apply(store.id).expect(201);
      expect(push.sent).toEqual([
        {
          userId: store.ownerId,
          title: 'Cora',
          body: '하루 한 컵님이 지원했어요.',
        },
      ]);
    });

    it('requires a creator profile before applying', async () => {
      await prisma.creatorProfile.deleteMany({});
      const store = await seedStore();
      const res = await apply(store.id).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect(await prisma.application.count()).toBe(0);
    });

    it('requires the CREATOR role', async () => {
      const store = await seedStore();
      await setRole('BRAND');
      expect(codeOf(await apply(store.id).expect(403))).toBe('FORBIDDEN');
      await cancel(store.id).expect(403);
      await setRole('CREATOR');
      await applicants().expect(403);
    });

    it('rejects applying to my own store', async () => {
      const storeId = await publishMine();
      await setRole('CREATOR');
      expect(codeOf(await apply(storeId).expect(409))).toBe('CONFLICT');
      expect(await prisma.application.count()).toBe(0);
    });

    it('rejects a second live application', async () => {
      const store = await seedStore();
      await apply(store.id).expect(201);
      expect(codeOf(await apply(store.id).expect(409))).toBe('CONFLICT');
      await prisma.application.updateMany({ data: { status: 'OFFERED' } });
      await apply(store.id).expect(409);
      expect(await prisma.application.count()).toBe(1);
    });

    it('turns simultaneous applications into one 201 and 409s, never a 500', async () => {
      const store = await seedStore();
      const results = await Promise.all(
        Array.from({ length: 5 }, () => apply(store.id)),
      );
      const statuses = results.map((r) => r.status).sort();
      expect(statuses).toEqual([201, 409, 409, 409, 409]);
      expect(await prisma.application.count()).toBe(1);
      expect(push.sent).toHaveLength(1);
    });

    it('returns 404 for a draft store, a missing store and a malformed id', async () => {
      const draft = await seedStore({ status: 'DRAFT' });
      await apply(draft.id).expect(404);
      await apply(randomUUID()).expect(404);
      await apply('not-a-uuid').expect(404);
    });

    it('cancels an application and allows applying again', async () => {
      const store = await seedStore();
      const first = (await apply(store.id).expect(201)).body as ApplicationBody;
      await cancel(store.id).expect(204);
      expect(
        (
          await prisma.application.findUniqueOrThrow({
            where: { id: first.id },
          })
        ).status,
      ).toBe('CANCELLED');
      const second = (await apply(store.id).expect(201))
        .body as ApplicationBody;
      expect(second.id).not.toBe(first.id);
      expect(await prisma.application.count()).toBe(2);
    });

    it('refuses to cancel once an offer was sent', async () => {
      const store = await seedStore();
      await apply(store.id).expect(201);
      await prisma.application.updateMany({ data: { status: 'OFFERED' } });
      const res = await cancel(store.id).expect(409);
      expect(codeOf(res)).toBe('CONFLICT');
      expect((res.body as { error: { message: string } }).error.message).toBe(
        '오퍼를 받은 뒤에는 받은 오퍼에서 거절해 주세요.',
      );
      expect((await prisma.application.findFirstOrThrow()).status).toBe(
        'OFFERED',
      );
    });

    it('returns 404 when cancelling without a live application', async () => {
      const store = await seedStore();
      await cancel(store.id).expect(404);
      await cancel('not-a-uuid').expect(404);
    });

    it('shows the live application status on the store detail', async () => {
      const store = await seedStore();
      const status = async () =>
        (
          (await detail(store.id).expect(200)).body as {
            myApplicationStatus: string;
          }
        ).myApplicationStatus;
      expect(await status()).toBe('NONE');
      await apply(store.id).expect(201);
      expect(await status()).toBe('APPLIED');
      await prisma.application.updateMany({ data: { status: 'OFFERED' } });
      expect(await status()).toBe('OFFERED');
      await prisma.application.updateMany({ data: { status: 'CLOSED' } });
      expect(await status()).toBe('NONE');
    });

    it("does not show another creator's application as mine", async () => {
      const store = await seedStore();
      await seedApplicant(store.id, '남의 지원', REGION);
      const body = (await detail(store.id).expect(200)).body as {
        myApplicationStatus: string;
      };
      expect(body.myApplicationStatus).toBe('NONE');
    });
  });

  describe('as a store owner', () => {
    let storeId: string;

    beforeEach(async () => {
      storeId = await publishMine();
    });

    it('lists only APPLIED applicants for the store owner', async () => {
      await seedApplicant(storeId, '지원 중', REGION, 'APPLIED');
      await seedApplicant(storeId, '오퍼 받음', REGION, 'OFFERED');
      await seedApplicant(storeId, '취소함', REGION, 'CANCELLED');
      const res = await applicants().expect(200);
      const list = res.body as ApplicantBody[];
      expect(list.map((a) => a.creator.displayName)).toEqual(['지원 중']);
      expect(list[0]).toEqual({
        applicationId: expect.any(String) as string,
        creator: {
          userId: expect.any(String) as string,
          displayName: '지원 중',
          contentFocus: null,
          photoUrl: null,
          regionSido: '서울특별시',
          regionSigungu: '성동구',
        },
        appliedAt: expect.stringMatching(/^\d{4}-\d\d-\d\dT/) as string,
      });
    });

    it("does not show another owner's applicants", async () => {
      const other = await seedStore();
      await seedApplicant(other.id, '남의 가게 지원자', REGION);
      const res = await applicants().expect(200);
      expect(res.body).toEqual([]);
    });

    it('lists applicants from the store district first', async () => {
      const at = (minute: number) =>
        new Date(Date.UTC(2026, 10, 11, 0, minute));
      // 최근 지원 순이면 부산, 강남, 성동 순이지만 지역 묶음이 먼저다.
      await seedApplicant(
        storeId,
        '성동 지원자',
        { regionSido: '서울특별시', regionSigungu: '성동구' },
        'APPLIED',
        at(1),
      );
      await seedApplicant(
        storeId,
        '강남 지원자',
        { regionSido: '서울특별시', regionSigungu: '강남구' },
        'APPLIED',
        at(2),
      );
      await seedApplicant(
        storeId,
        '부산 지원자',
        { regionSido: '부산광역시', regionSigungu: '해운대구' },
        'APPLIED',
        at(3),
      );
      await seedApplicant(
        storeId,
        '성동 최근 지원자',
        { regionSido: '서울특별시', regionSigungu: '성동구' },
        'APPLIED',
        at(4),
      );
      const list = (await applicants().expect(200)).body as ApplicantBody[];
      expect(list.map((a) => a.creator.displayName)).toEqual([
        '성동 최근 지원자',
        '성동 지원자',
        '강남 지원자',
        '부산 지원자',
      ]);
    });

    it('skips applicants whose profile was removed', async () => {
      await seedApplicant(storeId, '지워질 지원자', REGION);
      await prisma.creatorProfile.updateMany({
        data: { deletedAt: new Date() },
      });
      expect((await applicants().expect(200)).body).toEqual([]);
    });

    it('requires the STORE role and a store', async () => {
      await setRole('CREATOR');
      await applicants().expect(403);
      await setRole('STORE');
      await prisma.store.updateMany({ data: { deletedAt: new Date() } });
      await applicants().expect(404);
    });
  });
});
