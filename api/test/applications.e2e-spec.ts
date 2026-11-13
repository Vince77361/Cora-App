import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { PushPort } from '../src/integrations/push/push.port';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakePushPort } from './support/fake-push.port';
import { OTHER, USER_A } from './support/fake-token-verifier';

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
  pitch: string | null;
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
      .send({ format: 'REELS', reward: { voucher: {} } })
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
    extra: Partial<{
      contentFocus: string;
      pitch: string;
      followers: number;
      finished: number;
    }> = {},
  ): Promise<string> {
    const { id } = await seedApplicantWithUser(
      storeId,
      name,
      region,
      status,
      createdAt,
      extra,
    );
    return id;
  }

  async function seedApplicantWithUser(
    storeId: string,
    name: string,
    region: { regionSido: string; regionSigungu: string | null },
    status: 'APPLIED' | 'OFFERED' | 'CANCELLED',
    createdAt: Date,
    extra: Partial<{
      contentFocus: string;
      pitch: string;
      followers: number;
      finished: number;
    }>,
  ): Promise<{ id: string; userId: string }> {
    const userId = randomUUID();
    await prisma.user.create({ data: { id: userId, role: 'CREATOR' } });
    await prisma.creatorProfile.create({
      data: {
        userId,
        displayName: name,
        contentFocus: extra.contentFocus ?? null,
        ...region,
      },
    });
    if (extra.followers !== undefined) {
      await prisma.instagramConnection.create({
        data: {
          creatorId: userId,
          handle: `h_${userId.slice(0, 8)}`,
          followers: extra.followers,
          refreshedAt: createdAt,
        },
      });
    }
    for (let i = 0; i < (extra.finished ?? 0); i += 1) {
      await seedCollaboration(userId, 'SETTLED');
    }
    const row = await prisma.application.create({
      data: {
        storeId,
        creatorId: userId,
        status,
        createdAt,
        pitch: extra.pitch ?? null,
      },
    });
    return { id: row.id, userId };
  }

  // 지원자의 지난 협업. 마친 것(SETTLED)만 추천 점수에 든다.
  async function seedCollaboration(
    creatorId: string,
    stage: 'SETTLED' | 'COUNTING',
  ): Promise<void> {
    await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage,
        commissionerId: USER_A,
        creatorId,
        terms: {},
        settlementMethod: 'PER_VIEW',
      },
    });
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

    it('saves a blank pitch as null and no body as no pitch', async () => {
      const blank = await seedStore();
      await request(server)
        .post(`/stores/${blank.id}/applications`)
        .set(auth)
        .send({ pitch: '   ' })
        .expect(201);
      const bare = await seedStore();
      await request(server)
        .post(`/stores/${bare.id}/applications`)
        .set(auth)
        .send()
        .expect(201);
      const rows = await prisma.application.findMany();
      expect(rows).toHaveLength(2);
      expect(rows.map((row) => row.pitch)).toEqual([null, null]);
    });

    it('rejects a pitch longer than 100 characters', async () => {
      const store = await seedStore();
      const res = await request(server)
        .post(`/stores/${store.id}/applications`)
        .set(auth)
        .send({ pitch: '가'.repeat(101) })
        .expect(400);
      expect(codeOf(res)).toBe('VALIDATION_FAILED');
      expect(await prisma.application.count()).toBe(0);
      await request(server)
        .post(`/stores/${store.id}/applications`)
        .set(auth)
        .send({ pitch: '가'.repeat(100) })
        .expect(201);
    });

    it('notifies the store owner on a new application', async () => {
      const store = await seedStore();
      const res = await apply(store.id).expect(201);
      const applicationId = (res.body as ApplicationBody).id;
      expect(push.sent).toEqual([
        {
          userId: store.ownerId,
          title: '',
          body: '하루 한 컵님이 지원했어요.',
          data: {
            notificationId: expect.any(String) as string,
            targetKind: 'STORE_APPLICANTS',
            targetId: null,
            role: 'STORE',
          },
        },
      ]);
      expect(await prisma.notification.findFirstOrThrow()).toMatchObject({
        userId: store.ownerId,
        role: 'STORE',
        kind: 'APPLICATION_RECEIVED',
        tab: 'MATCHING',
        actorUserId: USER_A,
        actorName: '하루 한 컵',
        dedupeKey: `application-received:${applicationId}`,
      });
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
      expect(await prisma.notification.count()).toBe(1);
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
          instagramConnected: false,
          followers: null,
        },
        appliedAt: expect.stringMatching(/^\d{4}-\d\d-\d\dT/) as string,
        pitch: null,
      });
    });

    it('saves the pitch with the application and shows it to the owner', async () => {
      const authB = { Authorization: 'Bearer user-b' };
      await prisma.user.create({ data: { id: OTHER, role: 'CREATOR' } });
      await prisma.creatorProfile.create({
        data: { userId: OTHER, displayName: '한 줄 지원자', ...REGION },
      });
      await request(server)
        .post(`/stores/${storeId}/applications`)
        .set(authB)
        .send({ pitch: '  성수동 카페 릴스를 한 달에 네 편 올려요  ' })
        .expect(201);
      expect(
        (await prisma.application.findFirstOrThrow({ where: { storeId } }))
          .pitch,
      ).toBe('성수동 카페 릴스를 한 달에 네 편 올려요');
      const list = (await applicants().expect(200)).body as ApplicantBody[];
      expect(list.map((a) => a.pitch)).toEqual([
        '성수동 카페 릴스를 한 달에 네 편 올려요',
      ]);
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

  describe('recommended applicants', () => {
    let storeId: string;
    const SEONGDONG = { regionSido: '서울특별시', regionSigungu: '성동구' };
    const GANGNAM = { regionSido: '서울특별시', regionSigungu: '강남구' };
    const BUSAN = { regionSido: '부산광역시', regionSigungu: '해운대구' };
    const at = (minute: number) => new Date(Date.UTC(2026, 10, 11, 0, minute));
    const recommended = () =>
      request(server).get('/stores/me/applications/recommended').set(auth);
    const skip = (applicationId: string) =>
      request(server)
        .post(`/stores/me/applications/${applicationId}/skip`)
        .set(auth);

    interface RecommendedBody {
      totalNew: number;
      items: {
        applicationId: string;
        pitch: string | null;
        reasons: string[];
        creator: { displayName: string; followers: number | null };
      }[];
    }
    const names = (body: unknown) =>
      (body as RecommendedBody).items.map((i) => i.creator.displayName);

    beforeEach(async () => {
      storeId = await publishMine();
    });

    it('returns the three best applicants with reasons, the pitch and the total of new applications', async () => {
      await seedApplicant(storeId, '부산', BUSAN, 'APPLIED', at(1));
      await seedApplicant(storeId, '강남', GANGNAM, 'APPLIED', at(2));
      await seedApplicant(storeId, '성동', SEONGDONG, 'APPLIED', at(3), {
        contentFocus: '성수동 카페 릴스',
        pitch: '김 오르는 첫 숟가락을 찍을게요',
        finished: 2,
      });
      await seedApplicant(storeId, '부산 한 줄', BUSAN, 'APPLIED', at(4), {
        pitch: '한 줄',
      });
      await seedApplicant(storeId, '오퍼 받음', SEONGDONG, 'OFFERED', at(5));
      await seedApplicant(storeId, '취소함', SEONGDONG, 'CANCELLED', at(6));
      const res = await recommended().expect(200);
      const body = res.body as RecommendedBody;
      // 성동 3+2+1+2=8, 강남 1, 부산 한 줄 1, 부산 0. 강남과 부산 한 줄은 먼저 지원한 순이다.
      expect(names(body)).toEqual(['성동', '강남', '부산 한 줄']);
      expect(body.totalNew).toBe(4);
      expect(body.items[0]).toEqual({
        applicationId: expect.any(String) as string,
        creator: expect.objectContaining({ displayName: '성동' }) as unknown,
        pitch: '김 오르는 첫 숟가락을 찍을게요',
        reasons: [
          '같은 동네예요',
          '맛집·카페 콘텐츠를 만들어요',
          '지난 협업을 2번 마쳤어요',
        ],
      });
      expect(body.items[1].reasons).toEqual([]);
      expect(body.items[1].pitch).toBeNull();
    });

    it('counts only finished collaborations toward the score', async () => {
      await seedApplicant(storeId, '진행 중만', BUSAN, 'APPLIED', at(1));
      const { userId } = await seedApplicantWithUser(
        storeId,
        '진행 중 협업',
        BUSAN,
        'APPLIED',
        at(2),
        {},
      );
      await seedCollaboration(userId, 'COUNTING');
      await seedApplicant(storeId, '마친 협업', BUSAN, 'APPLIED', at(3), {
        finished: 1,
      });
      const body = (await recommended().expect(200)).body as RecommendedBody;
      expect(names(body)).toEqual(['마친 협업', '진행 중만', '진행 중 협업']);
      expect(body.items[0].reasons).toEqual(['지난 협업을 1번 마쳤어요']);
    });

    it('ignores follower counts: applicants who differ only in followers get the same order', async () => {
      // 팔로워만 다른 두 사람. 점수가 같으면 먼저 지원한 순이어야 하므로, 팔로워가 많은 쪽이 늦게 지원하든 먼저 지원하든 순서는 지원 순서를 따른다.
      await seedApplicant(storeId, '적은 먼저', GANGNAM, 'APPLIED', at(1), {
        followers: 12,
        pitch: '같은 한 줄',
      });
      await seedApplicant(storeId, '많은 나중', GANGNAM, 'APPLIED', at(2), {
        followers: 900000,
        pitch: '같은 한 줄',
      });
      const first = (await recommended().expect(200)).body as RecommendedBody;
      expect(names(first)).toEqual(['적은 먼저', '많은 나중']);
      expect(first.items.map((i) => i.reasons)).toEqual([[], []]);
      // 팔로워는 그대로 보여 준다(점수에만 안 쓴다).
      expect(first.items.map((i) => i.creator.followers)).toEqual([12, 900000]);

      await prisma.application.updateMany({ data: { status: 'CANCELLED' } });
      await seedApplicant(storeId, '많은 먼저', GANGNAM, 'APPLIED', at(3), {
        followers: 900000,
        pitch: '같은 한 줄',
      });
      await seedApplicant(storeId, '적은 나중', GANGNAM, 'APPLIED', at(4), {
        followers: 12,
        pitch: '같은 한 줄',
      });
      const second = (await recommended().expect(200)).body as RecommendedBody;
      expect(names(second)).toEqual(['많은 먼저', '적은 나중']);
    });

    it('returns fewer than three, and an empty list with a zero total, when fewer applied', async () => {
      expect((await recommended().expect(200)).body).toEqual({
        totalNew: 0,
        items: [],
      });
      await seedApplicant(storeId, '한 명', BUSAN);
      const body = (await recommended().expect(200)).body as RecommendedBody;
      expect(body.totalNew).toBe(1);
      expect(names(body)).toEqual(['한 명']);
    });

    it('leaves a skipped applicant out of the picks but in the applicant list', async () => {
      const near = await seedApplicant(
        storeId,
        '성동',
        SEONGDONG,
        'APPLIED',
        at(1),
      );
      await seedApplicant(storeId, '부산', BUSAN, 'APPLIED', at(2));
      await skip(near).expect(204);
      const body = (await recommended().expect(200)).body as RecommendedBody;
      expect(names(body)).toEqual(['부산']);
      expect(body.totalNew).toBe(2);
      const row = await prisma.application.findUniqueOrThrow({
        where: { id: near },
      });
      expect(row.status).toBe('APPLIED');
      expect(row.skippedFromPicksAt).not.toBeNull();
      const list = (await applicants().expect(200)).body as ApplicantBody[];
      expect(list.map((a) => a.creator.displayName).sort()).toEqual([
        '부산',
        '성동',
      ]);
    });

    it('keeps the first skip time when skipping twice', async () => {
      const id = await seedApplicant(storeId, '성동', SEONGDONG);
      await skip(id).expect(204);
      const first = (
        await prisma.application.findUniqueOrThrow({ where: { id } })
      ).skippedFromPicksAt;
      await skip(id).expect(204);
      expect(
        (await prisma.application.findUniqueOrThrow({ where: { id } }))
          .skippedFromPicksAt,
      ).toEqual(first);
    });

    it('returns 404 when skipping an application of another store', async () => {
      const other = await seedStore();
      const theirs = await seedApplicant(other.id, '남의 지원자', SEONGDONG);
      await skip(theirs).expect(404);
      expect(
        (await prisma.application.findUniqueOrThrow({ where: { id: theirs } }))
          .skippedFromPicksAt,
      ).toBeNull();
      await skip(randomUUID()).expect(404);
      await skip('not-a-uuid').expect(404);
      // 오퍼를 이미 보낸 지원은 추천 밖이라 넘길 것이 없다.
      const offered = await seedApplicant(
        storeId,
        '오퍼 받음',
        SEONGDONG,
        'OFFERED',
      );
      await skip(offered).expect(404);
    });

    it('requires the STORE role and a store', async () => {
      const id = await seedApplicant(storeId, '성동', SEONGDONG);
      await setRole('CREATOR');
      await recommended().expect(403);
      await skip(id).expect(403);
      await setRole('STORE');
      await prisma.store.updateMany({ data: { deletedAt: new Date() } });
      await recommended().expect(404);
      await skip(id).expect(404);
    });

    it('rejects requests with no token', async () => {
      await request(server)
        .get('/stores/me/applications/recommended')
        .expect(401);
      await request(server)
        .post(`/stores/me/applications/${randomUUID()}/skip`)
        .expect(401);
    });
  });
});
