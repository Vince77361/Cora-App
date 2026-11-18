import { PassReason, Store, SwipeDecision } from '@prisma/client';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeVisibility } from '../../test/support/fake-visibility';
import { ApplicationsService } from '../applications/applications.service';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { DecisionFields } from './discovery-rules';
import { DecisionKey, DiscoveryRepository } from './discovery.repository';
import { DiscoveryService } from './discovery.service';

const OWNER = '00000000-0000-4000-8000-000000000001';
const OTHER_OWNER = '00000000-0000-4000-8000-000000000002';
const CREATOR = '00000000-0000-4000-8000-0000000000c1';
const STORE_ID = '00000000-0000-4000-8000-0000000000aa';

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 유니크 인덱스와 잠금은 e2e와 db 시험이 확인한다.
class FakeDiscoveryRepository extends DiscoveryRepository {
  readonly rows: SwipeDecision[] = [];
  readonly matchesCreated: unknown[] = [];
  seq = 0;

  constructor() {
    super(null as never);
  }

  transaction<T>(run: (tx: never) => Promise<T>): Promise<T> {
    return run(null as never);
  }

  lock(): Promise<void> {
    return Promise.resolve();
  }

  private same(row: SwipeDecision, key: DecisionKey): boolean {
    return (
      !row.deletedAt &&
      row.actorId === key.actorId &&
      row.targetKind === key.targetKind &&
      row.targetId === key.targetId &&
      row.campaignId === key.campaignId
    );
  }

  findDecision(key: DecisionKey): Promise<SwipeDecision | null> {
    return Promise.resolve(this.rows.find((r) => this.same(r, key)) ?? null);
  }

  findDecisionById(id: string): Promise<SwipeDecision | null> {
    return Promise.resolve(this.rows.find((r) => r.id === id) ?? null);
  }

  createDecision(
    key: DecisionKey,
    data: DecisionFields,
    now: Date,
  ): Promise<SwipeDecision> {
    this.seq += 1;
    const row = {
      id: `decision-${this.seq}`,
      ...key,
      ...data,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    } as SwipeDecision;
    this.rows.push(row);
    return Promise.resolve(row);
  }

  updateDecision(
    id: string,
    data: Partial<DecisionFields>,
    now: Date,
  ): Promise<SwipeDecision> {
    const row = this.rows.find((r) => r.id === id)!;
    Object.assign(row, data, { updatedAt: now });
    return Promise.resolve(row);
  }

  findLastSince(actorId: string, since: Date): Promise<SwipeDecision | null> {
    const mine = this.rows
      .filter(
        (r) =>
          r.actorId === actorId &&
          !r.deletedAt &&
          r.updatedAt.getTime() >= since.getTime(),
      )
      .sort((a, b) => b.updatedAt.getTime() - a.updatedAt.getTime());
    return Promise.resolve(mine[0] ?? null);
  }

  deleteDecision(id: string): Promise<void> {
    const index = this.rows.findIndex((r) => r.id === id);
    if (index >= 0) this.rows.splice(index, 1);
    return Promise.resolve();
  }

  setPassReason(id: string, reason: PassReason): Promise<boolean> {
    const row = this.rows.find((r) => r.id === id && r.decision === 'PASS');
    if (!row) return Promise.resolve(false);
    row.passReason = reason;
    return Promise.resolve(true);
  }

  findMatch(): Promise<null> {
    return Promise.resolve(null);
  }

  createMatch(data: unknown): never {
    this.matchesCreated.push(data);
    throw new Error('사장님의 하트는 서로 관심(matches)을 만들지 않아요.');
  }
}

const store = {
  id: STORE_ID,
  ownerId: OWNER,
  industry: 'FOOD_CAFE',
} as Store;

function build(options: { role?: string | null } = {}) {
  const clock = new FakeClock(new Date('2026-11-19T01:00:00.000Z'));
  const visibility = new FakeVisibility();
  const repository = new FakeDiscoveryRepository();
  const liveApplicants = new Set<string>();
  const collaborationsCreated: unknown[] = [];
  const role = { current: options.role === undefined ? 'STORE' : options.role };
  const cardCopy = {
    current: {
      headline: '첫 게시물 한 줄',
      photoPath: 'featured-posts/a.jpg',
    } as {
      headline: string | null;
      photoPath: string | null;
    } | null,
  };
  const summaryExists = { current: true };
  const service = new DiscoveryService(
    { getRole: () => Promise.resolve(role.current) } as unknown as UsersService,
    null as never,
    null as never,
    {
      getSummary: () =>
        Promise.resolve(summaryExists.current ? { userId: CREATOR } : null),
      getCardCopy: () => Promise.resolve(cardCopy.current),
    } as unknown as CreatorsService,
    {
      requireMyStore: () => Promise.resolve(store),
    } as unknown as StoresService,
    visibility,
    null as never,
    null as never,
    {
      create: (data: unknown) => {
        collaborationsCreated.push(data);
        throw new Error('사장님의 하트는 협업을 만들지 않아요.');
      },
    } as unknown as CollaborationsRepository,
    null as never,
    {
      listLiveCreatorIds: () => Promise.resolve(liveApplicants),
    } as unknown as ApplicationsService,
    repository,
    clock,
  );
  return {
    clock,
    visibility,
    repository,
    service,
    liveApplicants,
    collaborationsCreated,
    role,
    cardCopy,
    summaryExists,
  };
}

const heart = {
  targetKind: 'CREATOR' as const,
  targetId: CREATOR,
  decision: 'LIKE' as const,
};

describe('DiscoveryService for a store owner', () => {
  it('records a store heart with campaign null and the first post copy', async () => {
    const { service, repository } = build();

    const result = await service.decide(OWNER, heart);

    expect(result).toEqual({
      decision: 'LIKE',
      matched: false,
      collaborationId: null,
      conversationId: null,
    });
    expect(repository.rows).toHaveLength(1);
    expect(repository.rows[0]).toMatchObject({
      actorId: OWNER,
      targetKind: 'CREATOR',
      targetId: CREATOR,
      campaignId: null,
      decision: 'LIKE',
      note: null,
      contentTitle: '첫 게시물 한 줄',
      contentPhotoPath: 'featured-posts/a.jpg',
    });
  });

  it('leaves the copy empty when the creator has no featured post', async () => {
    const { service, repository, cardCopy } = build();
    cardCopy.current = { headline: null, photoPath: null };

    await service.decide(OWNER, heart);

    expect(repository.rows[0]).toMatchObject({
      contentTitle: null,
      contentPhotoPath: null,
    });
  });

  it('records a save and a pass without copying the post', async () => {
    const { service, repository } = build();

    await service.decide(OWNER, { ...heart, decision: 'HOLD' });
    expect(repository.rows[0]).toMatchObject({
      decision: 'HOLD',
      contentTitle: null,
    });

    await service.decide(OWNER, { ...heart, decision: 'PASS' });
    expect(repository.rows).toHaveLength(1);
    expect(repository.rows[0]).toMatchObject({ decision: 'PASS' });
  });

  it('replaces a saved decision with a heart and leaves one row', async () => {
    const { service, repository } = build();
    await service.decide(OWNER, { ...heart, decision: 'HOLD' });

    await service.decide(OWNER, heart);

    expect(repository.rows).toHaveLength(1);
    expect(repository.rows[0]).toMatchObject({
      decision: 'LIKE',
      contentTitle: '첫 게시물 한 줄',
    });
  });

  it('replaces a heart with a save and clears the copy', async () => {
    const { service, repository } = build();
    await service.decide(OWNER, heart);

    await service.decide(OWNER, { ...heart, decision: 'HOLD' });

    expect(repository.rows).toHaveLength(1);
    expect(repository.rows[0]).toMatchObject({
      decision: 'HOLD',
      contentTitle: null,
      contentPhotoPath: null,
    });
  });

  it('creates no match or collaboration for a store heart', async () => {
    const { service, repository, collaborationsCreated, liveApplicants } =
      build();
    // 크리에이터가 이미 지원해 있어도(서로 관심) 가게의 협업은 만들지 않는다.
    liveApplicants.add(CREATOR);

    const result = await service.decide(OWNER, heart);

    expect(result.matched).toBe(false);
    expect(repository.matchesCreated).toEqual([]);
    expect(collaborationsCreated).toEqual([]);
  });

  it('refuses a store decision on a hidden creator with 404', async () => {
    const { service, repository, visibility } = build();
    visibility.hiddenCreators.add(CREATOR);

    await expect(service.decide(OWNER, heart)).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
    expect(repository.rows).toEqual([]);
  });

  it('refuses a store decision on a creator who no longer exists with 404', async () => {
    const { service, summaryExists } = build();
    summaryExists.current = false;

    await expect(service.decide(OWNER, heart)).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });

  it('refuses a campaign target, a note and a proposal from a store', async () => {
    const { service } = build();

    await expect(
      service.decide(OWNER, { ...heart, targetKind: 'CAMPAIGN' }),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    await expect(
      service.decide(OWNER, { ...heart, note: '같이 해요' }),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    await expect(
      service.decide(OWNER, {
        ...heart,
        proposal: { fee: 50000, productProvided: false },
      }),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
  });

  it('keeps one store decision per creator for each store', async () => {
    const { service, repository } = build();
    await service.decide(OWNER, heart);
    // 다른 가게의 결정은 서로 다른 행이다.
    repository.rows.push({
      ...repository.rows[0],
      id: 'other',
      actorId: OTHER_OWNER,
    });

    await service.decide(OWNER, heart);

    expect(repository.rows.filter((r) => r.actorId === OWNER)).toHaveLength(1);
    expect(repository.rows).toHaveLength(2);
  });

  it('records a pass reason on a passed creator and refuses it on anything else', async () => {
    const { service, repository } = build();
    const reason = {
      targetKind: 'CREATOR' as const,
      targetId: CREATOR,
      reason: 'FEE' as const,
    };

    await expect(service.setPassReason(OWNER, reason)).rejects.toMatchObject({
      code: 'CONFLICT',
    });

    await service.decide(OWNER, { ...heart, decision: 'PASS' });
    await service.setPassReason(OWNER, reason);

    expect(repository.rows[0].passReason).toBe('FEE');
  });

  it('undoes the last store decision of today', async () => {
    const { service, repository } = build();
    await service.decide(OWNER, heart);

    const undone = await service.undoLast(OWNER);

    expect(undone).toEqual({ targetKind: 'CREATOR', targetId: CREATOR });
    expect(repository.rows).toEqual([]);
  });

  it('refuses to undo a heart on a creator who applied', async () => {
    const { service, repository, liveApplicants } = build();
    await service.decide(OWNER, heart);
    liveApplicants.add(CREATOR);

    await expect(service.undoLast(OWNER)).rejects.toMatchObject({
      code: 'CONFLICT',
      message: '되돌릴 수 없어요.',
    });
    expect(repository.rows).toHaveLength(1);
  });

  it('still undoes a save or a pass on a creator who applied', async () => {
    const { service, repository, liveApplicants } = build();
    liveApplicants.add(CREATOR);
    await service.decide(OWNER, { ...heart, decision: 'HOLD' });

    await service.undoLast(OWNER);

    expect(repository.rows).toEqual([]);
  });

  it('refuses a store decision from a creator or a user without a role', async () => {
    const creatorWorld = build({ role: 'CREATOR' });
    // 크리에이터는 캠페인에만 결정할 수 있다.
    await expect(
      creatorWorld.service.decide(OWNER, heart),
    ).rejects.toBeInstanceOf(AppError);

    const noRole = build({ role: null });
    await expect(noRole.service.decide(OWNER, heart)).rejects.toMatchObject({
      code: 'FORBIDDEN',
    });
    await expect(noRole.service.undoLast(OWNER)).rejects.toMatchObject({
      code: 'FORBIDDEN',
    });
  });
});
