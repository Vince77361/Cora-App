import { Store, SwipeDecisionKind, SwipeTargetKind } from '@prisma/client';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeVisibility } from '../../test/support/fake-visibility';
import { ApplicationsService } from '../applications/applications.service';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { CreatorsService } from '../creators/creators.service';
import { CreatorCardSource } from '../creators/dto/creator-card-source';
import { CreatorSummaryModel } from '../creators/dto/creator-profile.model';
import { FeaturedPostModel } from '../creators/dto/featured-post.model';
import { PrinciplesModel } from '../principles/dto/principles.model';
import { PrinciplesService } from '../principles/principles.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { DecisionRow } from './candidate-rules';
import {
  RecommendationsRepository,
  StoredItem,
} from './recommendations.repository';
import { RecommendationsService } from './recommendations.service';

const OWNER = '00000000-0000-4000-8000-000000000001';
const STORE_ID = '00000000-0000-4000-8000-0000000000aa';

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 부분 유니크 인덱스와 조건부 갱신은 e2e와 db 시험이 확인한다.
class FakeRecommendationsRepository extends RecommendationsRepository {
  readonly lists = new Map<string, StoredItem[]>();
  readonly decisions: (DecisionRow & {
    actorId: string;
    targetKind: SwipeTargetKind;
  })[] = [];

  constructor() {
    super(null as never);
  }

  findList(
    userId: string,
    scope: string,
    campaignId: string | null,
    day: string,
  ): Promise<StoredItem[] | null> {
    return Promise.resolve(
      this.lists.get(`${userId}:${scope}:${campaignId}:${day}`) ?? null,
    );
  }

  saveList(
    userId: string,
    scope: string,
    campaignId: string | null,
    day: string,
    items: StoredItem[],
  ): Promise<StoredItem[]> {
    const key = `${userId}:${scope}:${campaignId}:${day}`;
    const existing = this.lists.get(key);
    if (existing) return Promise.resolve(existing);
    this.lists.set(key, items);
    return Promise.resolve(items);
  }

  listDecisions(
    actorId: string,
    targetKind: SwipeTargetKind,
  ): Promise<DecisionRow[]> {
    return Promise.resolve(
      this.decisions.filter(
        (d) => d.actorId === actorId && d.targetKind === targetKind,
      ),
    );
  }

  decide(targetId: string, decision: SwipeDecisionKind): void {
    this.decisions.push({
      actorId: OWNER,
      targetKind: 'CREATOR',
      targetId,
      decision,
      updatedAt: new Date('2026-11-19T01:00:00.000Z'),
    });
  }
}

interface World {
  clock: FakeClock;
  visibility: FakeVisibility;
  repository: FakeRecommendationsRepository;
  service: RecommendationsService;
  // 크리에이터 풀. 서비스는 호출할 때마다 이 배열을 읽는다(최근 가입순이 아니라 아무 순서여도 된다).
  pool: CreatorCardSource[];
  summaries: Map<string, CreatorSummaryModel>;
  principles: Map<string, PrinciplesModel>;
  applicants: Set<string>;
  openCollaborations: Set<string>;
  role: { current: string | null };
}

const store = {
  id: STORE_ID,
  ownerId: OWNER,
  industry: 'FOOD_CAFE',
  regionSido: '서울특별시',
  regionSigungu: '마포구',
} as Store;

function post(creatorId: string): FeaturedPostModel {
  return {
    id: `post-${creatorId}`,
    position: 1,
    source: 'GALLERY',
    kind: 'PHOTO',
    photoUrl: `https://cdn.test/${creatorId}.jpg`,
    mediaUrl: `https://cdn.test/${creatorId}.jpg`,
    caption: `한 줄 ${creatorId}`,
    instagramMediaId: null,
  };
}

let seq = 0;
// 가입 시각은 만든 차례대로 최근이 된다.
function creator(
  world: World,
  over: {
    sido?: string;
    sigungu?: string | null;
    posts?: boolean;
    principles?: boolean;
  } = {},
): string {
  seq += 1;
  const id = `00000000-0000-4000-8000-${String(seq).padStart(12, '0')}`;
  const posts = over.posts === false ? [] : [post(id)];
  world.pool.push({
    userId: id,
    displayName: `크리에이터${seq}`,
    instagramHandle: null,
    headline: posts[0]?.caption ?? null,
    photoUrl: posts[0]?.photoUrl ?? null,
    posts,
    joinedAt: new Date(Date.UTC(2026, 0, 1, 0, 0, seq)),
  });
  world.summaries.set(id, {
    userId: id,
    displayName: `크리에이터${seq}`,
    contentFocus: '맛집',
    photoUrl: null,
    regionSido: over.sido ?? '부산광역시',
    regionSigungu: over.sigungu ?? null,
    instagramConnected: true,
    followers: 2100,
  });
  if (over.principles !== false) {
    world.principles.set(id, {
      fields: [],
      blockedIndustries: [],
      faceOk: false,
      scriptOk: true,
      honestReview: true,
      feeBand: 'UNDER_100K',
      trialDays: 'NONE',
    } as unknown as PrinciplesModel);
  }
  return id;
}

function buildWorld(): World {
  const clock = new FakeClock(new Date('2026-11-19T01:00:00.000Z'));
  const visibility = new FakeVisibility();
  const repository = new FakeRecommendationsRepository();
  const pool: CreatorCardSource[] = [];
  const summaries = new Map<string, CreatorSummaryModel>();
  const principles = new Map<string, PrinciplesModel>();
  const applicants = new Set<string>();
  const openCollaborations = new Set<string>();
  const role = { current: 'STORE' as string | null };

  const creators = {
    listCardSources: () => Promise.resolve(pool),
    findCardSources: (ids: string[]) =>
      Promise.resolve(pool.filter((c) => ids.includes(c.userId))),
    getSummaries: (ids: string[]) =>
      Promise.resolve(
        new Map(
          ids.flatMap((id) => {
            const s = summaries.get(id);
            return s ? [[id, s] as const] : [];
          }),
        ),
      ),
  } as unknown as CreatorsService;
  const service = new RecommendationsService(
    { getRole: () => Promise.resolve(role.current) } as unknown as UsersService,
    null as unknown as BrandsService,
    null as unknown as CampaignsService,
    creators,
    {
      requireMyStore: () => Promise.resolve(store),
    } as unknown as StoresService,
    {
      findMany: (ids: string[]) =>
        Promise.resolve(
          new Map(
            ids.flatMap((id) => {
              const p = principles.get(id);
              return p ? [[id, p] as const] : [];
            }),
          ),
        ),
    } as unknown as PrinciplesService,
    visibility,
    {
      listOpenCreatorIds: (_commissionerId: string, ids: string[]) =>
        Promise.resolve(
          new Set(ids.filter((id) => openCollaborations.has(id))),
        ),
    } as unknown as CollaborationsRepository,
    {
      listLiveCreatorIds: () => Promise.resolve(applicants),
    } as unknown as ApplicationsService,
    repository,
    clock,
  );
  return {
    clock,
    visibility,
    repository,
    service,
    pool,
    summaries,
    principles,
    applicants,
    openCollaborations,
    role,
  };
}

describe('RecommendationsService.listStoreCreators', () => {
  it('lists at most ten creators and puts applicants first, then same district, then same province', async () => {
    const world = buildWorld();
    const far = Array.from({ length: 6 }, () => creator(world));
    const province = [
      creator(world, { sido: '서울특별시', sigungu: '강남구' }),
      creator(world, { sido: '서울특별시', sigungu: '강남구' }),
    ];
    const district = [
      creator(world, { sido: '서울특별시', sigungu: '마포구' }),
      creator(world, { sido: '서울특별시', sigungu: '마포구' }),
    ];
    const applicant = creator(world);
    world.applicants.add(applicant);
    // 열 명을 넘기려고 먼 곳 사람을 더 만든다.
    far.push(creator(world), creator(world));

    const result = await world.service.listStoreCreators(OWNER);

    expect(result.cards).toHaveLength(10);
    const ids = result.cards.map((c) => c.creatorId);
    expect(ids[0]).toBe(applicant);
    expect(ids.slice(1, 3).sort()).toEqual([...district].sort());
    expect(ids.slice(3, 5).sort()).toEqual([...province].sort());
    expect(ids.slice(5).every((id) => far.includes(id))).toBe(true);
    expect(result.total).toBe(10);
  });

  it('shows the featured posts, field and followers on each card', async () => {
    const world = buildWorld();
    const id = creator(world);

    const [card] = (await world.service.listStoreCreators(OWNER)).cards;

    expect(card).toMatchObject({
      creatorId: id,
      contentFocus: '맛집',
      followers: 2100,
      headline: `한 줄 ${id}`,
      photoUrl: `https://cdn.test/${id}.jpg`,
    });
    expect(card.posts).toHaveLength(1);
    expect(card.tags).toEqual(['얼굴출연없음', '솔직후기']);
  });

  it('hides creators who avoid the store industry', async () => {
    const world = buildWorld();
    const hidden = creator(world);
    const shown = creator(world);
    world.visibility.hiddenCreators.add(hidden);

    const ids = (await world.service.listStoreCreators(OWNER)).cards.map(
      (c) => c.creatorId,
    );

    expect(ids).toEqual([shown]);
  });

  it('hides creators without a featured post', async () => {
    const world = buildWorld();
    creator(world, { posts: false });
    const shown = creator(world);

    const ids = (await world.service.listStoreCreators(OWNER)).cards.map(
      (c) => c.creatorId,
    );

    expect(ids).toEqual([shown]);
  });

  it('keeps creators without collaboration principles', async () => {
    const world = buildWorld();
    const id = creator(world, { principles: false });

    const [card] = (await world.service.listStoreCreators(OWNER)).cards;

    expect(card.creatorId).toBe(id);
    expect(card.tags).toEqual([]);
  });

  it('drops creators with an unfinished collaboration', async () => {
    const world = buildWorld();
    const working = creator(world);
    const shown = creator(world);
    world.openCollaborations.add(working);

    const ids = (await world.service.listStoreCreators(OWNER)).cards.map(
      (c) => c.creatorId,
    );

    expect(ids).toEqual([shown]);
  });

  it('drops creators already liked, saved or passed', async () => {
    const world = buildWorld();
    const liked = creator(world);
    const saved = creator(world);
    const passed = creator(world);
    const fresh = creator(world);
    world.repository.decide(liked, 'LIKE');
    world.repository.decide(saved, 'HOLD');
    world.repository.decide(passed, 'PASS');

    const result = await world.service.listStoreCreators(OWNER);

    expect(result.cards.map((c) => c.creatorId)).toEqual([fresh]);
  });

  it('drops a creator decided after the list was made but keeps counting them in the total', async () => {
    const world = buildWorld();
    const first = creator(world);
    const second = creator(world);
    expect((await world.service.listStoreCreators(OWNER)).total).toBe(2);

    world.repository.decide(second, 'HOLD');
    const result = await world.service.listStoreCreators(OWNER);

    // 이미 결정한 카드도 오늘 목록의 전체 수에는 든다(앱이 다 봤는지 판단하려고).
    expect(result.total).toBe(2);
    expect(result.cards.map((c) => c.creatorId)).toEqual([first]);
  });

  it('keeps the same list for the same day and refills at midnight KST', async () => {
    const world = buildWorld();
    const first = creator(world);
    const before = await world.service.listStoreCreators(OWNER);
    expect(before.day).toBe('2026-11-19');

    // 같은 날 새로 가입한 사람은 목록에 끼지 않는다.
    const late = creator(world);
    const sameDay = await world.service.listStoreCreators(OWNER);
    expect(sameDay.cards.map((c) => c.creatorId)).toEqual([first]);

    // 한국 시간 자정(UTC 15:00) 전까지는 같은 날이다.
    world.clock.set(new Date('2026-11-19T14:59:59.000Z'));
    expect(
      (await world.service.listStoreCreators(OWNER)).cards.map(
        (c) => c.creatorId,
      ),
    ).toEqual([first]);

    world.clock.set(new Date('2026-11-19T15:00:00.000Z'));
    const nextDay = await world.service.listStoreCreators(OWNER);
    expect(nextDay.day).toBe('2026-11-20');
    expect(nextDay.cards.map((c) => c.creatorId)).toEqual([late, first]);
  });

  it('does not save an empty list so a new creator shows up the same day', async () => {
    const world = buildWorld();
    expect((await world.service.listStoreCreators(OWNER)).cards).toEqual([]);

    const id = creator(world);

    expect(
      (await world.service.listStoreCreators(OWNER)).cards.map(
        (c) => c.creatorId,
      ),
    ).toEqual([id]);
  });

  it('removes a stored creator the moment they avoid the store industry', async () => {
    const world = buildWorld();
    const id = creator(world);
    const other = creator(world);
    await world.service.listStoreCreators(OWNER);

    world.visibility.hiddenCreators.add(id);

    const ids = (await world.service.listStoreCreators(OWNER)).cards.map(
      (c) => c.creatorId,
    );
    expect(ids).toEqual([other]);
  });

  it('refuses accounts that are not a store', async () => {
    const world = buildWorld();
    world.role.current = 'BRAND';

    await expect(world.service.listStoreCreators(OWNER)).rejects.toMatchObject({
      code: 'FORBIDDEN',
    });
  });
});
