import { randomUUID } from 'node:crypto';
import {
  ApplicationStatus,
  Store,
  StoreOnboardingStep,
  StoreSourceLink,
  UserRole,
} from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import type { CreatorSummaryModel } from '../creators/dto/creator-profile.model';
import {
  SourceLinkInput,
  StoreBranch,
  StoreLinkAnalysisError,
  StoreLinkPort,
  StoreLinkResult,
} from '../integrations/store-link/store-link.port';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
import { numberedSlug } from './slugify';
import { StoresRepository } from './stores.repository';
import type {
  PublishedStoreDetail,
  StoreFields,
  StoreUpdateData,
  StoreWithLinks,
  DefaultTermsData,
} from './stores.repository';
import { StoresService } from './stores.service';

const OWNER = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const COVER = `stores/${OWNER}/33333333-3333-4333-8333-333333333333.jpg`;
const LINKS: SourceLinkInput[] = [
  { kind: 'NAVER_MAP', url: 'https://map.naver.com/p/entry/place/1' },
  { kind: 'INSTAGRAM', url: 'https://www.instagram.com/hangeureut' },
];

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현.
class FakeStoresRepository extends StoresRepository {
  readonly stores: StoreWithLinks[] = [];

  constructor() {
    super(null as never);
  }

  private byId(id: string): StoreWithLinks {
    const store = this.stores.find((s) => s.id === id);
    if (!store) throw new Error('no store');
    return store;
  }

  findActiveByOwnerId(ownerId: string): Promise<StoreWithLinks | null> {
    return Promise.resolve(
      this.stores.find((s) => s.ownerId === ownerId && !s.deletedAt) ?? null,
    );
  }

  // 테스트가 직접 채우는 지원 상태(살아 있는 지원만 넣는다).
  readonly applications: {
    storeId: string;
    creatorId: string;
    status: ApplicationStatus;
  }[] = [];

  // 테스트가 직접 채우는 열린 오퍼.
  readonly openOffers: {
    storeId: string;
    creatorId: string;
    id: string;
    latestVersion: number;
    status: 'SENT' | 'ACCEPTED';
    turn: 'STORE' | 'CREATOR';
  }[] = [];

  findPublishedDetail(
    storeId: string,
    viewerId: string,
  ): Promise<PublishedStoreDetail | null> {
    const store = this.stores.find(
      (s) => s.id === storeId && s.status === 'PUBLISHED' && !s.deletedAt,
    );
    if (!store) return Promise.resolve(null);
    return Promise.resolve({
      ...store,
      applications: this.applications
        .filter((a) => a.storeId === storeId && a.creatorId === viewerId)
        .map((a) => ({ status: a.status })),
      offers: this.openOffers
        .filter((o) => o.storeId === storeId && o.creatorId === viewerId)
        .map(({ id, latestVersion, status, turn }) => ({
          id,
          latestVersion,
          status,
          turn,
        })),
    });
  }

  findPublishedById(storeId: string): Promise<Store | null> {
    const store = this.stores.find(
      (s) => s.id === storeId && s.status === 'PUBLISHED' && !s.deletedAt,
    );
    return Promise.resolve(store ?? null);
  }

  listPublished(excludeOwnerId: string): Promise<Store[]> {
    return Promise.resolve(
      this.stores
        .filter(
          (s) =>
            s.status === 'PUBLISHED' &&
            !s.deletedAt &&
            s.ownerId !== excludeOwnerId,
        )
        .sort(
          (a, b) =>
            (b.publishedAt?.getTime() ?? 0) - (a.publishedAt?.getTime() ?? 0),
        ),
    );
  }

  replaceDraft(
    ownerId: string,
    fields: StoreFields,
    links: {
      kind: StoreSourceLink['kind'];
      url: string;
      summary: string | null;
    }[],
    now: Date,
  ): Promise<StoreWithLinks | null> {
    let store = this.stores.find((s) => s.ownerId === ownerId);
    if (store?.status === 'PUBLISHED') return Promise.resolve(null);
    if (!store) {
      store = makeStore({ ownerId });
      this.stores.push(store);
    }
    Object.assign(store, fields, { onboardingStep: 'PAGE' });
    store.sourceLinks = links.map((link) => ({
      id: randomUUID(),
      storeId: (store as Store).id,
      ...link,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    }));
    return Promise.resolve(store);
  }

  update(storeId: string, data: StoreUpdateData): Promise<StoreWithLinks> {
    return Promise.resolve(Object.assign(this.byId(storeId), data));
  }

  setTrialInfo(
    storeId: string,
    info: { monthlyFee: number; endsOn: Date; postCount: number },
  ): Promise<StoreWithLinks> {
    return Promise.resolve(
      Object.assign(this.byId(storeId), {
        trialMonthlyFee: info.monthlyFee,
        trialEndsOn: info.endsOn,
        trialPostCount: info.postCount,
        trialSnoozedUntil: null,
      }),
    );
  }

  clearTrialInfo(storeId: string): Promise<StoreWithLinks> {
    return Promise.resolve(
      Object.assign(this.byId(storeId), {
        trialMonthlyFee: null,
        trialEndsOn: null,
        trialPostCount: null,
        trialSnoozedUntil: null,
      }),
    );
  }

  snoozeTrialCompare(storeId: string, until: Date): Promise<StoreWithLinks> {
    return Promise.resolve(
      Object.assign(this.byId(storeId), { trialSnoozedUntil: until }),
    );
  }

  markTrialHintSeen(storeId: string, now: Date): Promise<void> {
    const store = this.byId(storeId);
    store.trialHintSeenAt ??= now;
    return Promise.resolve();
  }

  saveManualDraft(
    ownerId: string,
    fields: StoreFields,
  ): Promise<StoreWithLinks | null> {
    let store = this.stores.find((s) => s.ownerId === ownerId);
    if (store?.status === 'PUBLISHED') return Promise.resolve(null);
    if (!store) {
      store = makeStore({ ownerId });
      this.stores.push(store);
    }
    // 링크는 건드리지 않는다.
    Object.assign(store, fields, { onboardingStep: 'PAGE' });
    return Promise.resolve(store);
  }

  // 유일 제약 재시도는 DB 테스트가 확인한다. 여기서는 겹치면 번호를 붙이는 규칙만 흉내 낸다.
  assignSlug(storeId: string, base: string): Promise<StoreWithLinks> {
    const store = this.byId(storeId);
    if (store.slug !== null) return Promise.resolve(store);
    const taken = new Set(this.stores.map((s) => s.slug));
    let slug = base;
    for (let n = 2; taken.has(slug); n += 1) slug = numberedSlug(base, n);
    store.slug = slug;
    return Promise.resolve(store);
  }

  setOnboardingStep(
    storeId: string,
    step: StoreOnboardingStep,
  ): Promise<StoreWithLinks> {
    return Promise.resolve(
      Object.assign(this.byId(storeId), { onboardingStep: step }),
    );
  }

  setDefaultTerms(
    storeId: string,
    terms: DefaultTermsData,
  ): Promise<StoreWithLinks> {
    return Promise.resolve(
      Object.assign(this.byId(storeId), {
        defaultFormat: terms.format,
        defaultVoucherName: terms.voucherName,
        defaultVoucherValue: terms.voucherValue,
        defaultVoucherPeople: terms.voucherPeople,
        defaultFixedCash: terms.fixedCash,
        defaultViewRatePerThousand: terms.viewRatePerThousand,
        defaultPerViewCap: terms.perViewCap,
        defaultUsageRights: terms.usageRights,
      }),
    );
  }

  publish(storeId: string, now: Date): Promise<StoreWithLinks> {
    const store = this.byId(storeId);
    if (store.status === 'DRAFT') {
      Object.assign(store, {
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
        publishedAt: now,
      });
    }
    return Promise.resolve(store);
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

// 경로 검사(assertOwnedPath)는 진짜 규칙을 쓰고, 나머지 의존성은 쓰지 않는다.
class RealRulesUploads extends UploadsService {
  constructor() {
    super(null as never, null as never, null as never);
  }
}

class FakeCreatorsService extends CreatorsService {
  summary: CreatorSummaryModel | null = null;

  constructor() {
    super(null as never, null as never, null as never, null as never);
  }

  getSummary(): Promise<CreatorSummaryModel | null> {
    return Promise.resolve(this.summary);
  }
}

class FakeStoreLinkPort extends StoreLinkPort {
  calls = 0;
  failWith: Error | null = null;
  result: StoreLinkResult = {
    store: {
      name: '한그릇 라멘',
      category: '라멘집',
      neighborhood: '성수동',
      signatureMenu: '돈코츠 라멘 11,000원',
      hours: '11:30 – 21:00',
      seats: '18석, 바 좌석',
      bestShootingTime: '오후 3시 – 5시',
      intro: '진한 국물',
      industry: null,
      regionSido: '서울특별시',
      regionSigungu: '성동구',
      reviewCount: 58,
      tags: ['진한국물', '바좌석'],
      customerPhrases: ['국물이 진해요'],
    },
    coverPhoto: {
      bytes: Buffer.from([0xff, 0xd8, 0xff]),
      contentType: 'image/jpeg',
    },
    linkSummaries: [
      { kind: 'NAVER_MAP', summary: '사진 12장, 메뉴 8개 찾음' },
      { kind: 'INSTAGRAM', summary: '게시물 9개 찾음' },
    ],
  };

  branches: StoreBranch[] = [];

  findBranches(): Promise<StoreBranch[]> {
    return Promise.resolve(this.branches);
  }

  analyze(): Promise<StoreLinkResult> {
    this.calls += 1;
    return this.failWith
      ? Promise.reject(this.failWith)
      : Promise.resolve(this.result);
  }
}

function makeStore(over: Partial<StoreWithLinks> = {}): StoreWithLinks {
  const at = new Date('2026-11-11T03:00:00.000Z');
  return {
    id: randomUUID(),
    ownerId: OWNER,
    status: 'DRAFT',
    onboardingStep: 'PAGE',
    name: null,
    category: null,
    industry: 'FOOD_CAFE',
    neighborhood: null,
    regionSido: null,
    regionSigungu: null,
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
    sourceLinks: [],
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

describe('StoresService', () => {
  let repo: FakeStoresRepository;
  let users: FakeUsersService;
  let creators: FakeCreatorsService;
  let link: FakeStoreLinkPort;
  let storage: FakeStoragePort;
  let clock: FakeClock;
  let service: StoresService;

  beforeEach(() => {
    repo = new FakeStoresRepository();
    users = new FakeUsersService();
    creators = new FakeCreatorsService();
    link = new FakeStoreLinkPort();
    storage = new FakeStoragePort();
    clock = new FakeClock();
    service = new StoresService(
      repo,
      users,
      new RealRulesUploads(),
      storage,
      link,
      creators,
      clock,
    );
  });

  describe('analyze', () => {
    it('copies the cover photo into storage and saves its path', async () => {
      const { store, analysisFailed } = await service.analyze(OWNER, LINKS);
      expect(analysisFailed).toBe(false);
      expect(storage.uploaded).toHaveLength(1);
      expect(storage.uploaded[0].path).toMatch(
        new RegExp(`^stores/${OWNER}/[0-9a-f-]{36}\\.jpg$`),
      );
      expect(store.coverPhotoUrl).toBe(
        `https://fake-storage.test/public/${storage.uploaded[0].path}`,
      );
    });

    it('defaults the industry to FOOD_CAFE when the analysis gives none', async () => {
      const { store } = await service.analyze(OWNER, LINKS);
      expect(store.industry).toBe('FOOD_CAFE');
    });

    it('saves tags and customer phrases from the analysis', async () => {
      const { store } = await service.analyze(OWNER, LINKS);
      expect(store.tags).toEqual(['진한국물', '바좌석']);
      expect(store.customerPhrases).toEqual(['국물이 진해요']);
    });

    it('gives a new store a slug and adds a number when it is taken', async () => {
      repo.stores.push(makeStore({ ownerId: OTHER, slug: 'hangeureut-ramen' }));
      const { store } = await service.analyze(OWNER, LINKS);
      expect(store.slug).toBe('hangeureut-ramen-2');
      expect(store.publicUrl).toBe('cora.page/l/hangeureut-ramen-2');
    });

    it('cuts analyzed tags and customer phrases to the page limits', async () => {
      link.result.store.tags = [
        '하나',
        '둘',
        '셋',
        '넷',
        '다섯',
        '여섯',
        '열글자를넘는아주긴꼬리표입니다',
      ];
      link.result.store.customerPhrases = [
        '하나',
        '스무 글자를 넘는 아주아주 긴 손님 문구입니다',
        '셋',
        '넷',
      ];
      const { store } = await service.analyze(OWNER, LINKS);
      expect(store.tags).toEqual(['하나', '둘', '셋', '넷', '다섯']);
      expect(store.customerPhrases).toEqual([
        '하나',
        '스무 글자를 넘는 아주아주 긴 손님',
        '셋',
      ]);
      link.result.store.tags = ['열글자를넘는아주긴꼬리표입니다'];
      const next = await service.analyze(OWNER, LINKS);
      expect(next.store.tags).toEqual(['열글자를넘는아주긴꼬']);
    });

    it('drops a region that is not in the sido list', async () => {
      link.result.store.regionSido = '서울';
      const { store } = await service.analyze(OWNER, LINKS);
      expect(store.regionSido).toBeNull();
    });

    it('overwrites a draft, replaces its links and keeps its default terms', async () => {
      await service.analyze(OWNER, LINKS);
      await service.setDefaultTerms(OWNER, {
        format: 'REELS',
        reward: { voucher: {} },
      });
      await service.update(OWNER, { name: '고친 이름' });
      await service.advanceOnboarding(OWNER, 'TERMS');

      const { store } = await service.analyze(OWNER, [LINKS[1]]);
      expect(store.name).toBe('한그릇 라멘');
      expect(store.onboardingStep).toBe('PAGE');
      expect(store.sourceLinks).toEqual([
        {
          kind: 'INSTAGRAM',
          url: LINKS[1].url,
          summary: '게시물 9개 찾음',
        },
      ]);
      expect(store.defaultTerms?.voucherName).toBe('식사권');
      expect(repo.stores).toHaveLength(1);
    });

    it('falls back to an empty store when analysis fails', async () => {
      link.failWith = new StoreLinkAnalysisError();
      const { store, analysisFailed } = await service.analyze(OWNER, LINKS);
      expect(analysisFailed).toBe(true);
      expect(store).toMatchObject({
        status: 'DRAFT',
        onboardingStep: 'PAGE',
        name: null,
        industry: 'FOOD_CAFE',
        coverPhotoUrl: null,
      });
      expect(store.sourceLinks.map((l) => l.summary)).toEqual([null, null]);
      expect(storage.uploaded).toHaveLength(0);
    });

    it('lets other analysis errors bubble up', async () => {
      link.failWith = new Error('boom');
      await expect(service.analyze(OWNER, LINKS)).rejects.toThrow('boom');
      expect(repo.stores).toHaveLength(0);
    });

    it('refuses a published store without calling the analyzer', async () => {
      repo.stores.push(makeStore({ status: 'PUBLISHED' }));
      expect(await codeOf(service.analyze(OWNER, LINKS))).toBe('CONFLICT');
      expect(link.calls).toBe(0);
    });

    it('turns a lost race with a publish into a 409 and keeps the store', async () => {
      const published = makeStore({ status: 'PUBLISHED', name: '공개 가게' });
      // 확인할 때는 가게가 없었는데 저장하는 순간 이미 공개된 경우.
      jest.spyOn(repo, 'findActiveByOwnerId').mockResolvedValueOnce(null);
      repo.stores.push(published);
      expect(await codeOf(service.analyze(OWNER, LINKS))).toBe('CONFLICT');
      expect(published.name).toBe('공개 가게');
    });

    it('requires the STORE role', async () => {
      users.role = 'CREATOR';
      expect(await codeOf(service.analyze(OWNER, LINKS))).toBe('FORBIDDEN');
      expect(link.calls).toBe(0);
    });
  });

  describe('manual input', () => {
    it('fills the region of the chosen branch and gives the store a slug', async () => {
      const store = await service.createManually(OWNER, {
        name: ' 한그릇 라멘 ',
        branch: {
          label: '합정점',
          neighborhood: '합정동',
          regionSido: '서울특별시',
          regionSigungu: '마포구',
        },
      });
      expect(store).toMatchObject({
        name: '한그릇 라멘',
        neighborhood: '합정동',
        regionSido: '서울특별시',
        regionSigungu: '마포구',
        slug: 'hangeureut-ramen',
      });
    });

    it('keeps the links already saved', async () => {
      await service.analyze(OWNER, LINKS);
      const store = await service.createManually(OWNER, { name: '새 가게' });
      expect(store.sourceLinks).toHaveLength(2);
    });

    it('refuses a published store and checks the cover path owner', async () => {
      expect(
        await codeOf(
          service.createManually(OWNER, {
            name: '가게',
            coverPhotoPath: COVER.replace(OWNER, OTHER),
          }),
        ),
      ).toBe('FORBIDDEN');
      repo.stores.push(makeStore({ ownerId: OTHER, status: 'PUBLISHED' }));
      expect(
        await codeOf(service.createManually(OTHER, { name: '가게' })),
      ).toBe('CONFLICT');
    });

    it('asks the link port for branches and needs the STORE role', async () => {
      link.branches = [
        {
          label: '성수점',
          address: '서울 성동구',
          neighborhood: '성수동2가',
          regionSido: '서울특별시',
          regionSigungu: '성동구',
        },
      ];
      expect(await service.findBranches(OWNER, '한그릇 라멘')).toHaveLength(1);
      users.role = 'CREATOR';
      expect(await codeOf(service.findBranches(OWNER, '한그릇 라멘'))).toBe(
        'FORBIDDEN',
      );
    });
  });

  describe('trial info', () => {
    beforeEach(async () => {
      await service.analyze(OWNER, LINKS);
    });

    it('saves the contract info and snoozes the compare banner for 7 days', async () => {
      clock.set(new Date('2026-11-13T03:00:00.000Z'));
      const saved = await service.putTrialInfo(OWNER, {
        monthlyFee: 300000,
        endsOn: '2026-12-10',
        postCount: 12,
      });
      expect(saved.trialInfo).toEqual({
        monthlyFee: 300000,
        endsOn: '2026-12-10',
        postCount: 12,
      });
      expect(saved.trialBanner).toBe('COMPARE');
      await service.snoozeTrialCompare(OWNER);
      expect((await service.getMine(OWNER)).trialBanner).toBeNull();
      clock.advance(7 * 24 * 60 * 60 * 1000);
      expect((await service.getMine(OWNER)).trialBanner).toBe('COMPARE');
    });

    it('clears the info and needs the STORE role', async () => {
      await service.putTrialInfo(OWNER, {
        monthlyFee: 1,
        endsOn: '2027-01-01',
        postCount: 1,
      });
      await service.deleteTrialInfo(OWNER);
      expect((await service.getMine(OWNER)).trialInfo).toBeNull();
      users.role = 'CREATOR';
      expect(await codeOf(service.snoozeTrialCompare(OWNER))).toBe('FORBIDDEN');
    });
  });

  describe('getMine and requireMyStore', () => {
    it('fills the slug of an older store on read', async () => {
      repo.stores.push(makeStore({ name: '한그릇 라멘', slug: null }));
      const store = await service.getMine(OWNER);
      expect(store.slug).toBe('hangeureut-ramen');
    });

    it('returns 404 when there is no store', async () => {
      expect(await codeOf(service.getMine(OWNER))).toBe('NOT_FOUND');
      expect(await codeOf(service.requireMyStore(OWNER))).toBe('NOT_FOUND');
    });

    it('ignores a soft-deleted store', async () => {
      repo.stores.push(makeStore({ deletedAt: new Date() }));
      expect(await codeOf(service.requireMyStore(OWNER))).toBe('NOT_FOUND');
    });
  });

  describe('update', () => {
    beforeEach(async () => {
      await service.analyze(OWNER, LINKS);
    });

    it('trims text, turns blank into null and leaves missing fields alone', async () => {
      const saved = await service.update(OWNER, {
        name: '  새 이름  ',
        hours: '   ',
        seats: '',
        intro: ' 소개 ',
      });
      expect(saved).toMatchObject({
        name: '새 이름',
        hours: null,
        seats: null,
        intro: '소개',
        signatureMenu: '돈코츠 라멘 11,000원',
      });
    });

    it('keeps the slug when the name changes', async () => {
      const before = (await service.getMine(OWNER)).slug;
      const saved = await service.update(OWNER, { name: '다른 이름' });
      expect(saved.name).toBe('다른 이름');
      expect(saved.slug).toBe(before);
    });

    it('saves tags, customer phrases and the recruit line', async () => {
      const saved = await service.update(OWNER, {
        tags: ['국물'],
        customerPhrases: ['맛있어요'],
        recruitLine: ' 사진 잘 찍어 주세요 ',
      });
      expect(saved).toMatchObject({
        tags: ['국물'],
        customerPhrases: ['맛있어요'],
        recruitLine: '사진 잘 찍어 주세요',
      });
    });

    it('checks the cover photo path belongs to the caller', async () => {
      const other = `stores/${OTHER}/33333333-3333-4333-8333-333333333333.jpg`;
      expect(
        await codeOf(service.update(OWNER, { coverPhotoPath: other })),
      ).toBe('FORBIDDEN');
      expect(
        await codeOf(service.update(OWNER, { coverPhotoPath: 'stores/x.jpg' })),
      ).toBe('FORBIDDEN');
      const saved = await service.update(OWNER, { coverPhotoPath: COVER });
      expect(saved.coverPhotoUrl).toBe(
        `https://fake-storage.test/public/${COVER}`,
      );
    });

    it('requires the STORE role', async () => {
      users.role = 'BRAND';
      expect(await codeOf(service.update(OWNER, { name: 'x' }))).toBe(
        'FORBIDDEN',
      );
    });
  });

  describe('onboarding step', () => {
    it('only moves forward and returns the current store otherwise', async () => {
      await service.analyze(OWNER, LINKS);
      expect(
        (await service.advanceOnboarding(OWNER, 'DRAFTS')).onboardingStep,
      ).toBe('DRAFTS');
      expect(
        (await service.advanceOnboarding(OWNER, 'TERMS')).onboardingStep,
      ).toBe('TERMS');
      // 같은 단계와 앞 단계는 바꾸지 않는다.
      expect(
        (await service.advanceOnboarding(OWNER, 'TERMS')).onboardingStep,
      ).toBe('TERMS');
      expect(
        (await service.advanceOnboarding(OWNER, 'DRAFTS')).onboardingStep,
      ).toBe('TERMS');
    });

    it('returns 404 without a store', async () => {
      expect(await codeOf(service.advanceOnboarding(OWNER, 'DRAFTS'))).toBe(
        'NOT_FOUND',
      );
    });
  });

  describe('default terms', () => {
    beforeEach(async () => {
      await service.analyze(OWNER, LINKS);
    });

    it('saves the default terms as three reward elements', async () => {
      const saved = await service.setDefaultTerms(OWNER, {
        format: 'REELS',
        reward: { voucher: {}, perView: {} },
      });
      expect(saved.defaultTerms).toEqual({
        format: 'REELS',
        pieces: 1,
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        fixedCash: 0,
        viewRatePerThousand: 2000,
        perViewCap: 60000,
        usageRights: 'STORE_REPOST_3M',
        maxCashBurden: 60000,
        settlementMethod: 'PER_VIEW',
      });
      // 보상에 넣지 않은 요소는 비운다.
      const perView = await service.setDefaultTerms(OWNER, {
        format: 'SHORTS',
        reward: { perView: { ratePerThousand: 3000, cap: 100000 } },
        usageRights: 'STORE_REPOST_6M',
      });
      expect(perView.defaultTerms).toMatchObject({
        voucherName: null,
        voucherValue: null,
        voucherPeople: null,
        viewRatePerThousand: 3000,
        perViewCap: 100000,
        usageRights: 'STORE_REPOST_6M',
        maxCashBurden: 100000,
      });
    });

    it('fills 2000 won per thousand and a 60000 cap when view pay is on without values', async () => {
      const saved = await service.setDefaultTerms(OWNER, {
        format: 'REELS',
        reward: { perView: {} },
      });
      expect(saved.defaultTerms).toMatchObject({
        viewRatePerThousand: 2000,
        perViewCap: 60000,
      });
    });

    it('returns the maximum cash burden with the default terms', async () => {
      const both = await service.setDefaultTerms(OWNER, {
        format: 'REELS',
        reward: { voucher: {}, perView: { cap: 80000 } },
      });
      expect(both.defaultTerms?.maxCashBurden).toBe(80000);
      const voucherOnly = await service.setDefaultTerms(OWNER, {
        format: 'REELS',
        reward: { voucher: {} },
      });
      expect(voucherOnly.defaultTerms).toMatchObject({
        maxCashBurden: 0,
        settlementMethod: 'NONE',
      });
    });

    it('rejects a rate and fixed cash outside the allowed range', async () => {
      expect(
        await codeOf(
          service.setDefaultTerms(OWNER, {
            format: 'REELS',
            reward: { perView: { ratePerThousand: 10000 } },
          }),
        ),
      ).toBe('VALIDATION_FAILED');
      expect(
        await codeOf(
          service.setDefaultTerms(OWNER, {
            format: 'REELS',
            reward: { voucher: {}, fixedCash: 35000 },
          }),
        ),
      ).toBe('VALIDATION_FAILED');
    });

    it('rejects a blog with view pay', async () => {
      expect(
        await codeOf(
          service.setDefaultTerms(OWNER, {
            format: 'BLOG',
            reward: { voucher: {}, perView: {} },
          }),
        ),
      ).toBe('VALIDATION_FAILED');
    });

    it('is allowed on a published store too', async () => {
      await service.setDefaultTerms(OWNER, {
        format: 'REELS',
        reward: { voucher: {} },
      });
      await service.publish(OWNER);
      const saved = await service.setDefaultTerms(OWNER, {
        format: 'SHORTS',
        reward: { perView: {} },
      });
      expect(saved.status).toBe('PUBLISHED');
      expect(saved.defaultTerms?.settlementMethod).toBe('PER_VIEW');
    });
  });

  describe('publish', () => {
    it('rejects publishing without a name', async () => {
      link.failWith = new StoreLinkAnalysisError();
      await service.analyze(OWNER, LINKS);
      await service.setDefaultTerms(OWNER, {
        format: 'REELS',
        reward: { voucher: {} },
      });
      await service.update(OWNER, { regionSido: '서울특별시' });
      expect(await codeOf(service.publish(OWNER))).toBe('CONFLICT');
    });

    it('rejects publishing without default terms', async () => {
      await service.analyze(OWNER, LINKS);
      expect(await codeOf(service.publish(OWNER))).toBe('CONFLICT');
    });

    it('rejects publishing without a region', async () => {
      link.result.store.regionSido = null;
      await service.analyze(OWNER, LINKS);
      await service.setDefaultTerms(OWNER, {
        format: 'REELS',
        reward: { voucher: {} },
      });
      expect(await codeOf(service.publish(OWNER))).toBe('CONFLICT');
      await service.update(OWNER, { regionSido: '서울특별시' });
      expect((await service.publish(OWNER)).status).toBe('PUBLISHED');
    });

    it('publishes with the clock time and does nothing the second time', async () => {
      await service.analyze(OWNER, LINKS);
      await service.setDefaultTerms(OWNER, {
        format: 'REELS',
        reward: { voucher: {} },
      });
      const first = await service.publish(OWNER);
      expect(first).toMatchObject({
        status: 'PUBLISHED',
        onboardingStep: 'DONE',
      });
      const publishedAt = repo.stores[0].publishedAt;
      expect(publishedAt).toEqual(clock.now());
      clock.advance(60_000);
      await service.publish(OWNER);
      expect(repo.stores[0].publishedAt).toEqual(publishedAt);
    });
  });

  describe('public reads', () => {
    it('treats a malformed id as not found', async () => {
      expect(await codeOf(service.getPublished(OTHER, 'not-a-uuid'))).toBe(
        'NOT_FOUND',
      );
      expect(await codeOf(service.requirePublished('not-a-uuid'))).toBe(
        'NOT_FOUND',
      );
    });

    it("reads the viewer's live application status onto the detail", async () => {
      const published = makeStore({
        ownerId: OWNER,
        status: 'PUBLISHED',
        name: '한그릇 라멘',
        defaultFormat: 'REELS',
        defaultVoucherName: '식사권',
        defaultVoucherValue: 40000,
        defaultVoucherPeople: 2,
      });
      repo.stores.push(published);
      expect(
        (await service.getPublished(OTHER, published.id)).myApplicationStatus,
      ).toBe('NONE');
      repo.applications.push({
        storeId: published.id,
        creatorId: OTHER,
        status: 'APPLIED',
      });
      expect(
        (await service.getPublished(OTHER, published.id)).myApplicationStatus,
      ).toBe('APPLIED');
      repo.applications[0].status = 'OFFERED';
      expect(
        (await service.getPublished(OTHER, published.id)).myApplicationStatus,
      ).toBe('OFFERED');
      // 다른 사람의 지원은 보이지 않는다.
      expect(
        (await service.getPublished(OWNER, published.id)).myApplicationStatus,
      ).toBe('NONE');
    });

    it('reads my open offer onto the detail and says whose turn it is', async () => {
      const published = makeStore({
        ownerId: OWNER,
        status: 'PUBLISHED',
        name: '한그릇 라멘',
        defaultFormat: 'REELS',
      });
      repo.stores.push(published);
      expect(
        (await service.getPublished(OTHER, published.id)).myOpenOffer,
      ).toBeNull();
      const offerId = randomUUID();
      repo.openOffers.push({
        storeId: published.id,
        creatorId: OTHER,
        id: offerId,
        latestVersion: 2,
        status: 'SENT',
        turn: 'CREATOR',
      });
      expect(
        (await service.getPublished(OTHER, published.id)).myOpenOffer,
      ).toEqual({ id: offerId, latestVersion: 2, myTurn: true });
      repo.openOffers[0].turn = 'STORE';
      expect(
        (await service.getPublished(OTHER, published.id)).myOpenOffer,
      ).toEqual({ id: offerId, latestVersion: 2, myTurn: false });
      // 수락된 오퍼는 열려 있어도 내가 새 판본을 낼 차례가 아니다.
      repo.openOffers[0].status = 'ACCEPTED';
      repo.openOffers[0].turn = 'CREATOR';
      expect(
        (await service.getPublished(OTHER, published.id)).myOpenOffer?.myTurn,
      ).toBe(false);
      // 다른 사람의 오퍼는 보이지 않는다.
      expect(
        (await service.getPublished(OWNER, published.id)).myOpenOffer,
      ).toBeNull();
    });

    it('hides drafts and soft-deleted stores', async () => {
      const draft = makeStore({ ownerId: OTHER });
      repo.stores.push(draft);
      expect(await codeOf(service.getPublished(OTHER, draft.id))).toBe(
        'NOT_FOUND',
      );
      expect(await codeOf(service.requirePublished(draft.id))).toBe(
        'NOT_FOUND',
      );
    });
  });
});
