import { randomUUID } from 'node:crypto';
import {
  ContentDraftKind,
  Store,
  StoreContentDraft,
  UserRole,
} from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import {
  ContentDraftPort,
  DraftContent,
} from '../integrations/content-draft/content-draft.port';
import { FakeContentDraftAdapter } from '../integrations/content-draft/fake-content-draft.adapter';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { FakeClock } from '../../test/support/fake-clock';
import { ContentDraftsRepository } from './content-drafts.repository';
import type { NewDraft } from './content-drafts.repository';
import { ContentDraftsService } from './content-drafts.service';

const OWNER = '11111111-1111-4111-8111-111111111111';

function makeStore(over: Partial<Store> = {}): Store {
  const at = new Date('2026-11-11T03:00:00.000Z');
  return {
    id: randomUUID(),
    ownerId: OWNER,
    status: 'DRAFT',
    onboardingStep: 'DRAFTS',
    name: '한그릇 라멘',
    category: null,
    industry: 'FOOD_CAFE',
    neighborhood: null,
    regionSido: null,
    regionSigungu: null,
    coverPhotoPath: null,
    signatureMenu: '돈코츠 라멘 11,000원',
    hours: null,
    seats: null,
    bestShootingTime: '오후 3시 – 5시',
    intro: '진한 국물',
    slug: null,
    tags: [],
    customerPhrases: [],
    recruitLine: null,
    trialMonthlyFee: null,
    trialEndsOn: null,
    trialPostCount: null,
    trialSnoozedUntil: null,
    trialHintSeenAt: null,
    defaultFormat: null,
    defaultVoucherName: null,
    defaultVoucherValue: null,
    defaultVoucherPeople: null,
    defaultFixedCash: 0,
    defaultViewRatePerThousand: null,
    defaultPerViewCap: null,
    defaultUsageRights: 'STORE_REPOST_3M',
    publishedAt: null,
    createdAt: at,
    updatedAt: at,
    deletedAt: null,
    ...over,
  };
}

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 조건부 갱신(SQL)은 e2e가 확인한다.
class FakeContentDraftsRepository extends ContentDraftsRepository {
  readonly rows: StoreContentDraft[] = [];
  readonly claims: { kind: ContentDraftKind; today: string }[] = [];

  constructor() {
    super(null as never);
  }

  listByStore(storeId: string): Promise<StoreContentDraft[]> {
    return Promise.resolve(this.rows.filter((r) => r.storeId === storeId));
  }

  createMissing(drafts: NewDraft[]): Promise<void> {
    for (const draft of drafts) {
      if (
        this.rows.some(
          (r) => r.storeId === draft.storeId && r.kind === draft.kind,
        )
      ) {
        continue;
      }
      this.rows.push({
        id: randomUUID(),
        ...draft,
        scenes: draft.scenes,
        regeneratedOn: null,
        regenerationsOnDay: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
        deletedAt: null,
      });
    }
    return Promise.resolve();
  }

  claimRegeneration(
    storeId: string,
    kind: ContentDraftKind,
    today: string,
  ): Promise<{ version: number; regenerationsOnDay: number } | null> {
    this.claims.push({ kind, today });
    const row = this.rows.find((r) => r.storeId === storeId && r.kind === kind);
    if (!row) return Promise.resolve(null);
    const sameDay = row.regeneratedOn?.toISOString().slice(0, 10) === today;
    if (sameDay && row.regenerationsOnDay >= 10) return Promise.resolve(null);
    row.regenerationsOnDay = sameDay ? row.regenerationsOnDay + 1 : 1;
    row.regeneratedOn = new Date(`${today}T00:00:00.000Z`);
    row.version += 1;
    return Promise.resolve({
      version: row.version,
      regenerationsOnDay: row.regenerationsOnDay,
    });
  }

  saveContent(
    storeId: string,
    kind: ContentDraftKind,
    content: DraftContent,
  ): Promise<StoreContentDraft> {
    const row = this.rows.find((r) => r.storeId === storeId && r.kind === kind);
    if (!row) throw new Error('no draft');
    Object.assign(row, content);
    return Promise.resolve(row);
  }
}

class FakeUsersService extends UsersService {
  role: UserRole | null = 'STORE';

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

  requireMyStore(): Promise<Store> {
    if (!this.store) {
      return Promise.reject(
        new AppError('NOT_FOUND', '가게를 먼저 만들어 주세요.'),
      );
    }
    return Promise.resolve(this.store);
  }
}

// 부른 인자를 기록하고 가짜 구현에 맡긴다.
class RecordingDraftPort extends ContentDraftPort {
  readonly calls: {
    storeName: string;
    kind: ContentDraftKind;
    version: number;
  }[] = [];
  private readonly inner = new FakeContentDraftAdapter();

  generate(
    input: Parameters<ContentDraftPort['generate']>[0],
    kind: ContentDraftKind,
    version: number,
  ): Promise<DraftContent> {
    this.calls.push({ storeName: input.storeName, kind, version });
    return this.inner.generate(input, kind, version);
  }
}

async function codeOf(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
  } catch (e) {
    return (e as AppError).code;
  }
  return undefined;
}

describe('ContentDraftsService', () => {
  let repo: FakeContentDraftsRepository;
  let users: FakeUsersService;
  let stores: FakeStoresService;
  let port: RecordingDraftPort;
  let clock: FakeClock;
  let service: ContentDraftsService;

  beforeEach(() => {
    repo = new FakeContentDraftsRepository();
    users = new FakeUsersService();
    stores = new FakeStoresService();
    stores.store = makeStore();
    port = new RecordingDraftPort();
    clock = new FakeClock();
    service = new ContentDraftsService(repo, users, stores, port, clock);
  });

  describe('list', () => {
    it('creates the three kinds in order with the current store values', async () => {
      const drafts = await service.list(OWNER);
      expect(drafts.map((d) => d.kind)).toEqual([
        'CARD_NEWS',
        'REELS_SCRIPT',
        'BLOG',
      ]);
      expect(drafts.every((d) => d.regenerationsLeftToday === 10)).toBe(true);
      expect(port.calls.map((c) => [c.storeName, c.version])).toEqual([
        ['한그릇 라멘', 0],
        ['한그릇 라멘', 0],
        ['한그릇 라멘', 0],
      ]);
    });

    it('does not generate again once the drafts exist, even without a store name', async () => {
      await service.list(OWNER);
      stores.store = makeStore({ id: stores.store!.id, name: null });
      port.calls.length = 0;
      await service.list(OWNER);
      expect(port.calls).toHaveLength(0);
      expect(repo.rows).toHaveLength(3);
    });

    it('asks for a store name before the first generation', async () => {
      stores.store = makeStore({ name: null });
      expect(await codeOf(service.list(OWNER))).toBe('CONFLICT');
      expect(port.calls).toHaveLength(0);
    });

    it('requires the STORE role and an existing store', async () => {
      users.role = 'CREATOR';
      expect(await codeOf(service.list(OWNER))).toBe('FORBIDDEN');
      users.role = 'STORE';
      stores.store = null;
      expect(await codeOf(service.list(OWNER))).toBe('NOT_FOUND');
    });
  });

  describe('regenerate', () => {
    it('bumps only the requested kind and passes version + 1 to the generator', async () => {
      await service.list(OWNER);
      port.calls.length = 0;
      const draft = await service.regenerate(OWNER, 'BLOG');
      expect(port.calls).toEqual([
        { storeName: '한그릇 라멘', kind: 'BLOG', version: 1 },
      ]);
      expect(draft.kind).toBe('BLOG');
      expect(draft.regenerationsLeftToday).toBe(9);
      // 홀수 버전은 장면 2와 3의 순서가 바뀐다.
      expect(draft.scenes.map((s) => s.label)).toEqual([
        '제목',
        '소제목 2',
        '소제목 1',
      ]);
      expect(repo.rows.map((r) => r.version)).toEqual([0, 0, 1]);
    });

    it('creates missing drafts first so the first call can be a regenerate', async () => {
      const draft = await service.regenerate(OWNER, 'CARD_NEWS');
      expect(repo.rows).toHaveLength(3);
      expect(draft.regenerationsLeftToday).toBe(9);
    });

    it('turns a refused claim into RATE_LIMITED', async () => {
      await service.list(OWNER);
      for (let i = 0; i < 10; i += 1) await service.regenerate(OWNER, 'BLOG');
      const error = await service
        .regenerate(OWNER, 'BLOG')
        .catch((e) => e as AppError);
      expect(error).toBeInstanceOf(AppError);
      expect((error as AppError).code).toBe('RATE_LIMITED');
      expect((error as AppError).message).toBe('오늘은 더 만들 수 없어요.');
      // 거절된 요청은 생성기를 부르지 않는다.
      expect(
        port.calls.filter((c) => c.kind === 'BLOG' && c.version === 11),
      ).toHaveLength(0);
    });

    it('uses the Korean calendar date at the day boundary', async () => {
      await service.list(OWNER);
      // 한국 시간 2026-11-11 23:59:59 → 아직 11일이다.
      clock.set(new Date('2026-11-11T14:59:59.000Z'));
      await service.regenerate(OWNER, 'BLOG');
      // 한국 시간 2026-11-12 00:00:00 → 12일이다.
      clock.set(new Date('2026-11-11T15:00:00.000Z'));
      await service.regenerate(OWNER, 'BLOG');
      expect(repo.claims.map((c) => c.today)).toEqual([
        '2026-11-11',
        '2026-11-12',
      ]);
    });

    it('counts only today when computing the remaining regenerations', async () => {
      await service.list(OWNER);
      await service.regenerate(OWNER, 'BLOG');
      await service.regenerate(OWNER, 'BLOG');
      expect(
        (await service.list(OWNER)).find((d) => d.kind === 'BLOG')
          ?.regenerationsLeftToday,
      ).toBe(8);
      clock.advance(24 * 3_600_000);
      expect(
        (await service.list(OWNER)).find((d) => d.kind === 'BLOG')
          ?.regenerationsLeftToday,
      ).toBe(10);
    });

    it('asks for a store name and requires the STORE role', async () => {
      stores.store = makeStore({ name: null });
      expect(await codeOf(service.regenerate(OWNER, 'BLOG'))).toBe('CONFLICT');
      users.role = 'BRAND';
      expect(await codeOf(service.regenerate(OWNER, 'BLOG'))).toBe('FORBIDDEN');
    });
  });
});
