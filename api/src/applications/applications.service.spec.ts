import { randomUUID } from 'node:crypto';
import { Logger } from '@nestjs/common';
import { Application, Store, UserRole } from '@prisma/client';
import { FakeClock } from '../../test/support/fake-clock';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import type {
  CreatorProfileModel,
  CreatorSummaryModel,
} from '../creators/dto/creator-profile.model';
import {
  NotifyInput,
  NotificationsService,
} from '../notifications/notifications.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { ApplicationsRepository } from './applications.repository';
import { ApplicationsService } from './applications.service';

const OWNER = '11111111-1111-4111-8111-111111111111';
const CREATOR = '22222222-2222-4222-8222-222222222222';
const CREATOR_B = '33333333-3333-4333-8333-333333333333';
const CREATOR_C = '44444444-4444-4444-8444-444444444444';

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 조건부 갱신(SQL)과 유니크 인덱스는 e2e가 확인한다.
class FakeApplicationsRepository extends ApplicationsRepository {
  readonly rows: Application[] = [];
  seq = 0;

  constructor() {
    super(null as never);
  }

  private live(storeId: string, creatorId: string): Application | undefined {
    return this.rows.find(
      (r) =>
        r.storeId === storeId &&
        r.creatorId === creatorId &&
        !r.deletedAt &&
        (r.status === 'APPLIED' || r.status === 'OFFERED'),
    );
  }

  findLive(storeId: string, creatorId: string): Promise<Application | null> {
    return Promise.resolve(this.live(storeId, creatorId) ?? null);
  }

  create(
    storeId: string,
    creatorId: string,
    pitch: string | null = null,
  ): Promise<Application | null> {
    if (this.live(storeId, creatorId)) return Promise.resolve(null);
    this.seq += 1;
    const row: Application = {
      id: randomUUID(),
      storeId,
      creatorId,
      status: 'APPLIED',
      pitch,
      skippedFromPicksAt: null,
      createdAt: new Date(Date.UTC(2026, 10, 11, 0, 0, this.seq)),
      updatedAt: new Date(),
      deletedAt: null,
    };
    this.rows.push(row);
    return Promise.resolve(row);
  }

  cancelApplied(storeId: string, creatorId: string): Promise<boolean> {
    const row = this.live(storeId, creatorId);
    if (row?.status !== 'APPLIED') return Promise.resolve(false);
    row.status = 'CANCELLED';
    return Promise.resolve(true);
  }

  listApplied(storeId: string): Promise<Application[]> {
    return Promise.resolve(
      this.rows
        .filter(
          (r) =>
            r.storeId === storeId && r.status === 'APPLIED' && !r.deletedAt,
        )
        .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime()),
    );
  }

  markOffered(storeId: string, creatorId: string): Promise<string | null> {
    const row = this.live(storeId, creatorId);
    if (row?.status !== 'APPLIED') return Promise.resolve(null);
    row.status = 'OFFERED';
    return Promise.resolve(row.id);
  }

  closeOffered(applicationId: string): Promise<void> {
    const row = this.rows.find((r) => r.id === applicationId);
    if (row?.status === 'OFFERED') row.status = 'CLOSED';
    return Promise.resolve();
  }

  reopenOffered(applicationId: string): Promise<void> {
    const row = this.rows.find((r) => r.id === applicationId);
    if (row?.status === 'OFFERED') row.status = 'APPLIED';
    return Promise.resolve();
  }

  countApplied(storeId: string): Promise<number> {
    return Promise.resolve(
      this.rows.filter((r) => r.storeId === storeId && r.status === 'APPLIED')
        .length,
    );
  }

  findAppliedOfStore(
    storeId: string,
    applicationId: string,
  ): Promise<Application | null> {
    return Promise.resolve(
      this.rows.find(
        (r) =>
          r.id === applicationId &&
          r.storeId === storeId &&
          r.status === 'APPLIED' &&
          !r.deletedAt,
      ) ?? null,
    );
  }

  markSkipped(applicationId: string, at: Date): Promise<void> {
    const row = this.rows.find((r) => r.id === applicationId);
    if (row?.status === 'APPLIED' && row.skippedFromPicksAt === null) {
      row.skippedFromPicksAt = at;
    }
    return Promise.resolve();
  }
}

// 마친 협업 수만 손으로 정해 준다.
class FakeCollaborations extends CollaborationsRepository {
  readonly finished = new Map<string, number>();

  constructor() {
    super(null as never, null as never);
  }

  countByCreators(creatorIds: string[]): Promise<Map<string, number>> {
    const map = new Map<string, number>();
    for (const id of creatorIds) {
      const n = this.finished.get(id);
      if (n) map.set(id, n);
    }
    return Promise.resolve(map);
  }
}

class FakeUsersService extends UsersService {
  role: UserRole | null = 'CREATOR';

  constructor() {
    super(null as never);
  }

  getRole(): Promise<UserRole | null> {
    return Promise.resolve(this.role);
  }
}

class FakeStoresService extends StoresService {
  store: Store | null = null;

  constructor() {
    super(
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
    );
  }

  requirePublished(): Promise<Store> {
    if (!this.store) throw new AppError('NOT_FOUND', '가게를 찾을 수 없어요.');
    return Promise.resolve(this.store);
  }

  requireMyStore(): Promise<Store> {
    if (!this.store)
      throw new AppError('NOT_FOUND', '가게를 먼저 만들어 주세요.');
    return Promise.resolve(this.store);
  }
}

class FakeCreatorsService extends CreatorsService {
  readonly profiles = new Map<string, CreatorProfileModel>();

  constructor() {
    super(null as never, null as never, null as never, null as never);
  }

  add(
    userId: string,
    regionSido: string,
    regionSigungu: string | null,
    contentFocus: string | null = null,
  ): void {
    this.profiles.set(userId, {
      userId,
      displayName: `활동 ${userId.slice(0, 1)}`,
      contentFocus,
      photoUrl: null,
      regionSido,
      regionSigungu,
      instagramHandle: null,
      instagramConnected: false,
      followers: null,
    });
  }

  getSummary(userId: string): Promise<CreatorSummaryModel | null> {
    return Promise.resolve(this.profiles.get(userId) ?? null);
  }

  getActor(userId: string): ReturnType<CreatorsService['getActor']> {
    const profile = this.profiles.get(userId);
    return Promise.resolve(
      profile
        ? {
            userId,
            name: profile.displayName,
            photoPath: `creators/${userId.slice(0, 1)}.jpg`,
          }
        : null,
    );
  }

  requireProfile(userId: string): Promise<CreatorProfileModel> {
    const profile = this.profiles.get(userId);
    if (!profile) {
      throw new AppError('CONFLICT', '크리에이터 프로필을 먼저 만들어 주세요.');
    }
    return Promise.resolve(profile);
  }
}

// 알림 서비스는 따로 시험한다. 여기서는 지원 서비스가 어떤 알림을 부르는지만 기록한다.
class FakeNotifications extends NotificationsService {
  readonly sent: NotifyInput[] = [];
  fail = false;

  constructor() {
    super(null as never, null as never, null as never);
  }

  notify(input: NotifyInput): Promise<void> {
    if (this.fail) return Promise.reject(new Error('notify down'));
    this.sent.push(input);
    return Promise.resolve();
  }
}

function makeStore(over: Partial<Store> = {}): Store {
  const at = new Date('2026-11-11T03:00:00.000Z');
  return {
    id: randomUUID(),
    ownerId: OWNER,
    status: 'PUBLISHED',
    onboardingStep: 'DONE',
    name: '한그릇 라멘',
    category: null,
    industry: 'FOOD_CAFE',
    neighborhood: null,
    regionSido: '서울특별시',
    regionSigungu: '성동구',
    coverPhotoPath: null,
    signatureMenu: null,
    hours: null,
    seats: null,
    bestShootingTime: null,
    intro: null,
    slug: null,
    tags: [],
    customerPhrases: [],
    recruitLine: null,
    trialMonthlyFee: null,
    trialEndsOn: null,
    trialPostCount: null,
    trialSnoozedUntil: null,
    trialHintSeenAt: null,
    defaultFormat: 'REELS',
    defaultVoucherName: null,
    defaultVoucherValue: null,
    defaultVoucherPeople: null,
    defaultFixedCash: 0,
    defaultViewRatePerThousand: null,
    defaultPerViewCap: null,
    defaultUsageRights: 'STORE_REPOST_3M',
    publishedAt: at,
    createdAt: at,
    updatedAt: at,
    deletedAt: null,
    ...over,
  };
}

async function codeOf(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
  } catch (e) {
    return (e as AppError).code;
  }
  return undefined;
}

describe('ApplicationsService', () => {
  let repo: FakeApplicationsRepository;
  let users: FakeUsersService;
  let stores: FakeStoresService;
  let creators: FakeCreatorsService;
  let push: FakeNotifications;
  let collaborations: FakeCollaborations;
  let clock: FakeClock;
  let service: ApplicationsService;
  let store: Store;

  beforeEach(() => {
    repo = new FakeApplicationsRepository();
    users = new FakeUsersService();
    stores = new FakeStoresService();
    creators = new FakeCreatorsService();
    push = new FakeNotifications();
    collaborations = new FakeCollaborations();
    clock = new FakeClock(new Date('2026-11-14T03:00:00.000Z'));
    service = new ApplicationsService(
      repo,
      users,
      stores,
      creators,
      push,
      collaborations,
      clock,
    );
    store = makeStore();
    stores.store = store;
    creators.add(CREATOR, '서울특별시', '성동구');
  });

  describe('apply', () => {
    it('creates an APPLIED application and notifies the store owner', async () => {
      const result = await service.apply(CREATOR, store.id);
      expect(result).toEqual({
        id: repo.rows[0].id,
        storeId: store.id,
        status: 'APPLIED',
      });
      expect(push.sent).toEqual([
        {
          userId: OWNER,
          role: 'STORE',
          kind: 'APPLICATION_RECEIVED',
          actor: {
            userId: CREATOR,
            name: '활동 2',
            photoPath: 'creators/2.jpg',
          },
          target: { kind: 'STORE_APPLICANTS', id: null },
          dedupeKey: `application-received:${result.id}`,
        },
      ]);
    });

    it('saves the trimmed pitch and lists it for the owner', async () => {
      await service.apply(CREATOR, store.id, {
        pitch: '  성수동 카페 릴스 30편  ',
      });
      expect(repo.rows[0].pitch).toBe('성수동 카페 릴스 30편');
      users.role = 'STORE';
      expect((await service.listApplicants(OWNER))[0].pitch).toBe(
        '성수동 카페 릴스 30편',
      );
    });

    it('stores a blank pitch as null', async () => {
      await service.apply(CREATOR, store.id, { pitch: '   ' });
      expect(repo.rows[0].pitch).toBeNull();
      users.role = 'STORE';
      expect((await service.listApplicants(OWNER))[0].pitch).toBeNull();
    });

    it('requires the CREATOR role before anything else', async () => {
      users.role = 'STORE';
      stores.store = null;
      expect(await codeOf(service.apply(CREATOR, store.id))).toBe('FORBIDDEN');
    });

    it('returns 404 when the store is not published', async () => {
      stores.store = null;
      expect(await codeOf(service.apply(CREATOR, store.id))).toBe('NOT_FOUND');
    });

    it('rejects applying to my own store before checking the profile', async () => {
      stores.store = makeStore({ ownerId: CREATOR });
      creators.profiles.clear();
      expect(await codeOf(service.apply(CREATOR, store.id))).toBe('CONFLICT');
      expect(repo.rows).toHaveLength(0);
    });

    it('requires a creator profile', async () => {
      creators.profiles.clear();
      expect(await codeOf(service.apply(CREATOR, store.id))).toBe('CONFLICT');
    });

    it('rejects a second live application, including an OFFERED one', async () => {
      await service.apply(CREATOR, store.id);
      expect(await codeOf(service.apply(CREATOR, store.id))).toBe('CONFLICT');
      await repo.markOffered(store.id, CREATOR);
      expect(await codeOf(service.apply(CREATOR, store.id))).toBe('CONFLICT');
      expect(repo.rows).toHaveLength(1);
    });

    it('turns a lost race on the unique index into a conflict', async () => {
      // 미리 읽을 때는 없었는데 만드는 순간 다른 요청이 먼저 만든 경우.
      jest.spyOn(repo, 'findLive').mockResolvedValue(null);
      await service.apply(CREATOR, store.id);
      expect(await codeOf(service.apply(CREATOR, store.id))).toBe('CONFLICT');
    });

    it('still succeeds when the push fails', async () => {
      jest.spyOn(Logger.prototype, 'warn').mockImplementation();
      push.fail = true;
      const result = await service.apply(CREATOR, store.id);
      expect(result.status).toBe('APPLIED');
    });

    it('allows applying again after cancelling', async () => {
      await service.apply(CREATOR, store.id);
      await service.cancel(CREATOR, store.id);
      const again = await service.apply(CREATOR, store.id);
      expect(again.status).toBe('APPLIED');
      expect(repo.rows).toHaveLength(2);
    });
  });

  describe('cancel', () => {
    it('requires the CREATOR role', async () => {
      users.role = 'STORE';
      expect(await codeOf(service.cancel(CREATOR, store.id))).toBe('FORBIDDEN');
    });

    it('cancels an APPLIED application', async () => {
      await service.apply(CREATOR, store.id);
      await service.cancel(CREATOR, store.id);
      expect(repo.rows[0].status).toBe('CANCELLED');
    });

    it('refuses to cancel once an offer was sent', async () => {
      await service.apply(CREATOR, store.id);
      await repo.markOffered(store.id, CREATOR);
      expect(await codeOf(service.cancel(CREATOR, store.id))).toBe('CONFLICT');
      expect(repo.rows[0].status).toBe('OFFERED');
    });

    it('returns 404 with no live application or a non-uuid store id', async () => {
      expect(await codeOf(service.cancel(CREATOR, store.id))).toBe('NOT_FOUND');
      expect(await codeOf(service.cancel(CREATOR, 'not-a-uuid'))).toBe(
        'NOT_FOUND',
      );
    });
  });

  describe('listApplicants', () => {
    beforeEach(() => {
      users.role = 'STORE';
    });

    it('requires the STORE role', async () => {
      users.role = 'CREATOR';
      expect(await codeOf(service.listApplicants(OWNER))).toBe('FORBIDDEN');
    });

    it('returns 404 without a store', async () => {
      stores.store = null;
      expect(await codeOf(service.listApplicants(OWNER))).toBe('NOT_FOUND');
    });

    it('lists only APPLIED applicants', async () => {
      creators.add(CREATOR_B, '서울특별시', '성동구');
      await repo.create(store.id, CREATOR);
      await repo.create(store.id, CREATOR_B);
      await repo.markOffered(store.id, CREATOR_B);
      const list = await service.listApplicants(OWNER);
      expect(list.map((a) => a.creator.userId)).toEqual([CREATOR]);
    });

    it('lists applicants from the store district first', async () => {
      // 지원 순서: 다른 시·도, 같은 시·도 다른 구, 같은 구. 최근 지원이 위가 되도록 거꾸로 쌓인다.
      creators.profiles.clear();
      creators.add(CREATOR, '부산광역시', '해운대구');
      creators.add(CREATOR_B, '서울특별시', '강남구');
      creators.add(CREATOR_C, '서울특별시', '성동구');
      await repo.create(store.id, CREATOR_C);
      await repo.create(store.id, CREATOR);
      await repo.create(store.id, CREATOR_B);
      const list = await service.listApplicants(OWNER);
      expect(list.map((a) => a.creator.userId)).toEqual([
        CREATOR_C,
        CREATOR_B,
        CREATOR,
      ]);
    });

    it('keeps the newest first inside the same region group', async () => {
      creators.add(CREATOR_B, '서울특별시', '성동구');
      await repo.create(store.id, CREATOR);
      await repo.create(store.id, CREATOR_B);
      const list = await service.listApplicants(OWNER);
      expect(list.map((a) => a.creator.userId)).toEqual([CREATOR_B, CREATOR]);
      expect(list[0].applicationId).toBe(repo.rows[1].id);
      expect(list[0].appliedAt).toBe(repo.rows[1].createdAt.toISOString());
    });

    it('skips applicants whose profile was removed', async () => {
      await repo.create(store.id, CREATOR);
      creators.profiles.clear();
      expect(await service.listApplicants(OWNER)).toEqual([]);
    });
  });

  describe('listRecommended', () => {
    // 지원자 하나를 만들고 프로필과 마친 협업 수를 정한다.
    async function applicant(
      region: [string, string | null],
      opts: { focus?: string; pitch?: string; finished?: number } = {},
    ): Promise<string> {
      const userId = randomUUID();
      creators.add(userId, region[0], region[1], opts.focus ?? null);
      if (opts.finished) collaborations.finished.set(userId, opts.finished);
      const row = await repo.create(store.id, userId, opts.pitch ?? null);
      return row!.id;
    }

    it('requires the STORE role and a store', async () => {
      users.role = 'CREATOR';
      expect(await codeOf(service.listRecommended(OWNER))).toBe('FORBIDDEN');
      users.role = 'STORE';
      stores.store = null;
      expect(await codeOf(service.listRecommended(OWNER))).toBe('NOT_FOUND');
    });

    it('returns at most three applicants and the total of new applications', async () => {
      users.role = 'STORE';
      const far = ['부산광역시', '해운대구'] as [string, string];
      const ids: string[] = [];
      for (let i = 0; i < 5; i += 1) ids.push(await applicant(far));
      const near = await applicant(['서울특별시', '성동구']);
      const res = await service.listRecommended(OWNER);
      expect(res.totalNew).toBe(6);
      expect(res.items).toHaveLength(3);
      expect(res.items[0].applicationId).toBe(near);
      // 점수가 같은 나머지는 먼저 지원한 순이다.
      expect(res.items.slice(1).map((i) => i.applicationId)).toEqual([
        ids[0],
        ids[1],
      ]);
    });

    it('returns fewer than three when fewer applied', async () => {
      users.role = 'STORE';
      await applicant(['서울특별시', '성동구']);
      const res = await service.listRecommended(OWNER);
      expect(res.totalNew).toBe(1);
      expect(res.items).toHaveLength(1);
      expect(await service.listRecommended(OWNER)).toEqual(res);
    });

    it('builds the reasons and pitch from the facts used for the score', async () => {
      users.role = 'STORE';
      const id = await applicant(['서울특별시', '성동구'], {
        focus: '카페 릴스',
        pitch: '성수동 카페를 찍을게요',
        finished: 1,
      });
      const [item] = (await service.listRecommended(OWNER)).items;
      expect(item.applicationId).toBe(id);
      expect(item.pitch).toBe('성수동 카페를 찍을게요');
      expect(item.reasons).toEqual([
        '같은 동네예요',
        '맛집·카페 콘텐츠를 만들어요',
        '지난 협업을 1번 마쳤어요',
      ]);
    });

    it('leaves a skipped applicant out of the picks but in the applicant list', async () => {
      users.role = 'STORE';
      const near = await applicant(['서울특별시', '성동구']);
      const far = await applicant(['부산광역시', '해운대구']);
      await service.skipRecommended(OWNER, near);
      const res = await service.listRecommended(OWNER);
      expect(res.items.map((i) => i.applicationId)).toEqual([far]);
      expect(res.totalNew).toBe(2);
      expect(repo.rows.find((r) => r.id === near)?.status).toBe('APPLIED');
      const list = await service.listApplicants(OWNER);
      expect(list.map((a) => a.applicationId)).toContain(near);
    });
  });

  describe('skipRecommended', () => {
    it('keeps the first skip time when called twice', async () => {
      users.role = 'STORE';
      const row = (await repo.create(store.id, CREATOR))!;
      await service.skipRecommended(OWNER, row.id);
      const first = row.skippedFromPicksAt;
      expect(first).toEqual(clock.now());
      clock.set(new Date('2026-11-15T03:00:00.000Z'));
      await service.skipRecommended(OWNER, row.id);
      expect(row.skippedFromPicksAt).toEqual(first);
    });

    it('returns 404 for an application of another store, a missing one or a malformed id', async () => {
      users.role = 'STORE';
      const other = (await repo.create(randomUUID(), CREATOR))!;
      expect(await codeOf(service.skipRecommended(OWNER, other.id))).toBe(
        'NOT_FOUND',
      );
      expect(await codeOf(service.skipRecommended(OWNER, randomUUID()))).toBe(
        'NOT_FOUND',
      );
      expect(await codeOf(service.skipRecommended(OWNER, 'nope'))).toBe(
        'NOT_FOUND',
      );
      expect(other.skippedFromPicksAt).toBeNull();
    });

    it('requires the STORE role', async () => {
      users.role = 'CREATOR';
      expect(await codeOf(service.skipRecommended(OWNER, randomUUID()))).toBe(
        'FORBIDDEN',
      );
    });
  });

  describe('used by offers', () => {
    it('markOffered returns the id of the live APPLIED application, else null', async () => {
      expect(await service.markOffered(store.id, CREATOR)).toBeNull();
      const created = await service.apply(CREATOR, store.id);
      expect(await service.markOffered(store.id, CREATOR)).toBe(created.id);
      expect(await service.markOffered(store.id, CREATOR)).toBeNull();
    });

    it('closeFor moves OFFERED to CLOSED and is safe to call twice', async () => {
      const created = await service.apply(CREATOR, store.id);
      await service.closeFor(created.id);
      expect(repo.rows[0].status).toBe('APPLIED');
      await service.markOffered(store.id, CREATOR);
      await service.closeFor(created.id);
      await service.closeFor(created.id);
      expect(repo.rows[0].status).toBe('CLOSED');
    });

    it('reopen moves OFFERED back to APPLIED and leaves other statuses alone', async () => {
      const created = await service.apply(CREATOR, store.id);
      await service.reopen(created.id);
      expect(repo.rows[0].status).toBe('APPLIED');
      await service.markOffered(store.id, CREATOR);
      await service.reopen(created.id);
      await service.reopen(created.id);
      expect(repo.rows[0].status).toBe('APPLIED');
      await service.markOffered(store.id, CREATOR);
      await service.closeFor(created.id);
      await service.reopen(created.id);
      expect(repo.rows[0].status).toBe('CLOSED');
    });

    it('countNew counts only APPLIED applications', async () => {
      creators.add(CREATOR_B, '서울특별시', null);
      await service.apply(CREATOR, store.id);
      await service.apply(CREATOR_B, store.id);
      await service.markOffered(store.id, CREATOR_B);
      expect(await service.countNew(store.id)).toBe(1);
    });
  });
});
