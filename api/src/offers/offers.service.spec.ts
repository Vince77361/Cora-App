import { randomUUID } from 'node:crypto';
import { Logger } from '@nestjs/common';
import { Collaboration, Store, UserRole } from '@prisma/client';
import { ApplicationsService } from '../applications/applications.service';
import { AppError } from '../common/errors/app-error';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { CreatorsService } from '../creators/creators.service';
import type { CreatorSummaryModel } from '../creators/dto/creator-profile.model';
import {
  NotifyInput,
  NotificationsService,
} from '../notifications/notifications.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { FakeClock } from '../../test/support/fake-clock';
import {
  InSameTransaction,
  OfferRow,
  OffersRepository,
} from './offers.repository';
import { OffersService } from './offers.service';

const OWNER = '11111111-1111-4111-8111-111111111111';
const CREATOR = '22222222-2222-4222-8222-222222222222';
const T0 = new Date('2026-12-01T00:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 조건부 갱신(SQL)과 유니크 인덱스는 db-spec·e2e가 확인한다.
class FakeOffersRepository extends OffersRepository {
  readonly rows: OfferRow[] = [];
  // 읽을 때는 비어 있었는데 만들 때 다른 요청이 먼저 만든 경우(부분 유니크 위반)를 흉내 낸다.
  loseCreateRace = false;
  appStatus = new Map<string, 'OFFERED' | 'CLOSED'>();

  constructor() {
    super(null as never);
  }

  private withApp(row: OfferRow): OfferRow {
    const status = row.applicationId
      ? this.appStatus.get(row.applicationId)
      : undefined;
    return {
      ...row,
      application: status ? { status } : null,
    };
  }

  findById(id: string) {
    const row = this.rows.find((r) => r.id === id);
    return Promise.resolve(row ? this.withApp(row) : null);
  }
  findForStore(id: string, storeId: string) {
    const row = this.rows.find((r) => r.id === id && r.storeId === storeId);
    return Promise.resolve(row ? this.withApp(row) : null);
  }
  findForCreator(id: string, creatorId: string) {
    const row = this.rows.find((r) => r.id === id && r.creatorId === creatorId);
    return Promise.resolve(row ? this.withApp(row) : null);
  }
  listForStore(storeId: string) {
    return Promise.resolve(
      this.rows
        .filter((r) => r.storeId === storeId)
        .map((r) => this.withApp(r)),
    );
  }
  listForCreator(creatorId: string) {
    return Promise.resolve(
      this.rows
        .filter((r) => r.creatorId === creatorId)
        .map((r) => this.withApp(r)),
    );
  }
  findOpen(storeId: string, creatorId: string) {
    return Promise.resolve(
      this.rows
        .filter(
          (r) =>
            r.storeId === storeId &&
            r.creatorId === creatorId &&
            ['SENT', 'ACCEPTED', 'DECLINED'].includes(r.status),
        )
        .map((r) => this.withApp(r)),
    );
  }
  create(data: Parameters<OffersRepository['create']>[0]) {
    if (this.loseCreateRace) return Promise.resolve(null);
    const open = this.rows.some(
      (r) =>
        r.storeId === data.storeId &&
        r.creatorId === data.creatorId &&
        (r.status === 'SENT' || r.status === 'ACCEPTED'),
    );
    if (open) return Promise.resolve(null);
    const row = {
      id: randomUUID(),
      ...data,
      status: 'SENT',
      acceptedAt: null,
      paymentDueAt: null,
      declinedAt: null,
      respondedAt: null,
      updatedAt: data.createdAt,
      deletedAt: null,
    } as unknown as OfferRow;
    this.rows.push(row);
    return Promise.resolve(this.withApp(row));
  }
  async accept(
    id: string,
    creatorId: string,
    now: Date,
    paymentDueAt: Date | null,
    alongWith?: InSameTransaction,
  ) {
    const row = this.rows.find((r) => r.id === id);
    if (row?.creatorId !== creatorId || row.status !== 'SENT') return false;
    if (row.expiresAt.getTime() <= now.getTime()) return false;
    Object.assign(row, { status: 'ACCEPTED', acceptedAt: now, paymentDueAt });
    // 메모리 저장소에는 트랜잭션이 없다. 같은 트랜잭션에서 할 일을 그냥 이어서 부른다.
    await alongWith?.(null as never);
    return true;
  }
  decline(id: string, creatorId: string, now: Date) {
    const row = this.rows.find((r) => r.id === id);
    if (row?.creatorId !== creatorId || row.status !== 'SENT') {
      return Promise.resolve(false);
    }
    Object.assign(row, { status: 'DECLINED', declinedAt: now });
    return Promise.resolve(true);
  }
  undoDecline(id: string, creatorId: string) {
    const row = this.rows.find((r) => r.id === id);
    if (row?.creatorId !== creatorId || row.status !== 'DECLINED') {
      return Promise.resolve(false);
    }
    Object.assign(row, { status: 'SENT', declinedAt: null });
    return Promise.resolve(true);
  }
  async cancel(
    id: string,
    storeId: string,
    from: 'SENT' | 'ACCEPTED',
    _now?: Date,
    alongWith?: InSameTransaction,
  ) {
    const row = this.rows.find((r) => r.id === id);
    if (row?.storeId !== storeId || row.status !== from) return false;
    row.status = 'CANCELLED';
    if ((await alongWith?.(null as never)) === false) {
      row.status = from;
      return false;
    }
    return true;
  }
  async expire(
    id: string,
    from: OfferRow['status'],
    alongWith?: InSameTransaction,
  ) {
    const row = this.rows.find((r) => r.id === id);
    if (row?.status !== from) return false;
    row.status = 'EXPIRED';
    await alongWith?.(null as never);
    return true;
  }
}

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 조건부 갱신(SQL)과 유일 제약은 db-spec·e2e가 확인한다.
class FakeCollaborations extends CollaborationsRepository {
  readonly rows: Collaboration[] = [];

  constructor() {
    super(null as never);
  }

  create(data: Parameters<CollaborationsRepository['create']>[0]) {
    const row = {
      id: randomUUID(),
      ...data,
      submittedUrl: null,
      submittedAt: null,
      countingEndsAt: null,
      haltedReason: null,
      stageBeforeHalt: null,
      createdAt: T0,
      updatedAt: T0,
      deletedAt: null,
    } as Collaboration;
    this.rows.push(row);
    return Promise.resolve(row);
  }
  findByOfferId(offerId: string) {
    return Promise.resolve(
      this.rows.find((r) => r.offerId === offerId) ?? null,
    );
  }
  mapByOfferIds(offerIds: string[]) {
    return Promise.resolve(
      new Map(
        this.rows
          .filter((r) => r.offerId && offerIds.includes(r.offerId))
          .map((r) => [r.offerId as string, r]),
      ),
    );
  }
  advanceByOffer(
    offerId: string,
    from: Collaboration['stage'],
    to: Collaboration['stage'],
  ) {
    const row = this.rows.find((r) => r.offerId === offerId);
    if (row?.stage !== from) return Promise.resolve(false);
    row.stage = to;
    return Promise.resolve(true);
  }
  countForStore(storeId: string, stages: Collaboration['stage'][]) {
    return Promise.resolve(
      this.rows.filter((r) => r.storeId === storeId && stages.includes(r.stage))
        .length,
    );
  }
}

class FakeUsers extends UsersService {
  role: UserRole | null = 'STORE';
  constructor() {
    super(null as never);
  }
  getRole(): Promise<UserRole | null> {
    return Promise.resolve(this.role);
  }
}

class FakeStores extends StoresService {
  store: Store;
  constructor(store: Store) {
    super(
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
    );
    this.store = store;
  }
  requireMyStore(): Promise<Store> {
    return Promise.resolve(this.store);
  }
  getOfferCard(): ReturnType<StoresService['getOfferCard']> {
    return Promise.resolve({
      ownerId: this.store.ownerId,
      coverPhotoPath: this.store.coverPhotoPath,
      intro: null,
      bestShootingTime: null,
      summary: {
        id: this.store.id,
        name: this.store.name ?? '',
        category: null,
        industry: 'FOOD_CAFE',
        neighborhood: null,
        regionSido: null,
        regionSigungu: null,
        coverPhotoUrl: null,
        defaultTerms: {
          format: 'REELS',
          rewardType: 'VOUCHER',
          voucherName: '2인 식사권',
          voucherValue: 40000,
          perViewAmount: null,
          perViewCap: null,
        },
      },
    });
  }
}

class FakeApplications extends ApplicationsService {
  readonly closed: string[] = [];
  nextApplicationId: string | null = null;
  newCount = 0;
  constructor() {
    super(
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
    );
  }
  markOffered(): Promise<string | null> {
    return Promise.resolve(this.nextApplicationId);
  }
  closeFor(applicationId: string): Promise<void> {
    this.closed.push(applicationId);
    return Promise.resolve();
  }
  readonly reopened: string[] = [];
  reopen(applicationId: string): Promise<void> {
    this.reopened.push(applicationId);
    return Promise.resolve();
  }
  countNew(): Promise<number> {
    return Promise.resolve(this.newCount);
  }
}

class FakeCreators extends CreatorsService {
  constructor() {
    super(null as never, null as never, null as never, null as never);
  }
  getActor(userId: string): ReturnType<CreatorsService['getActor']> {
    return Promise.resolve(
      userId === CREATOR
        ? { userId, name: '하루 한 컵', photoPath: 'creators/haru.jpg' }
        : null,
    );
  }
  getSummary(userId: string): Promise<CreatorSummaryModel | null> {
    return Promise.resolve(
      userId === CREATOR
        ? {
            userId,
            displayName: '하루 한 컵',
            contentFocus: null,
            photoUrl: null,
            regionSido: '서울특별시',
            regionSigungu: null,
          }
        : null,
    );
  }
}

// 알림 서비스는 따로 시험한다. 여기서는 오퍼 서비스가 어떤 알림을 부르는지만 기록한다.
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

function makeStore(): Store {
  return {
    id: randomUUID(),
    ownerId: OWNER,
    status: 'PUBLISHED',
    name: '한그릇 라멘',
    coverPhotoPath: 'stores/ramen.jpg',
  } as Store;
}

describe('OffersService', () => {
  let repo: FakeOffersRepository;
  let collaborations: FakeCollaborations;
  let users: FakeUsers;
  let stores: FakeStores;
  let applications: FakeApplications;
  let push: FakeNotifications;
  let clock: FakeClock;
  let service: OffersService;
  const REELS = {
    creatorId: CREATOR,
    format: 'REELS',
    rewardType: 'VOUCHER',
  } as const;

  beforeEach(() => {
    repo = new FakeOffersRepository();
    collaborations = new FakeCollaborations();
    users = new FakeUsers();
    stores = new FakeStores(makeStore());
    applications = new FakeApplications();
    push = new FakeNotifications();
    clock = new FakeClock(T0);
    service = new OffersService(
      repo,
      users,
      stores,
      applications,
      new FakeCreators(),
      collaborations,
      push,
      clock,
    );
  });

  it('checks the role before anything else', async () => {
    users.role = 'CREATOR';
    await expect(service.send(OWNER, { ...REELS })).rejects.toMatchObject({
      code: 'FORBIDDEN',
    });
    users.role = 'STORE';
    await expect(service.listReceived(OWNER, 'new')).rejects.toMatchObject({
      code: 'FORBIDDEN',
    });
  });

  it('checks an unpublished store before the recipient', async () => {
    stores.store = { ...stores.store, status: 'DRAFT' };
    await expect(
      service.send(OWNER, { ...REELS, creatorId: OWNER }),
    ).rejects.toMatchObject({ code: 'CONFLICT' });
  });

  it('checks myself before the creator profile', async () => {
    // 나 자신에게는 프로필이 없어도 404가 아니라 409다.
    await expect(
      service.send(OWNER, { ...REELS, creatorId: OWNER }),
    ).rejects.toMatchObject({ code: 'CONFLICT' });
  });

  it('checks the terms before looking for an open offer', async () => {
    await service.send(OWNER, { ...REELS });
    await expect(
      service.send(OWNER, {
        creatorId: CREATOR,
        format: 'BLOG',
        rewardType: 'PER_VIEW',
      }),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
  });

  it('stores the linked application id and the clock time on send', async () => {
    applications.nextApplicationId = 'app-1';
    await service.send(OWNER, { ...REELS });
    expect(repo.rows[0]).toMatchObject({
      applicationId: 'app-1',
      createdAt: T0,
      expiresAt: new Date(T0.getTime() + 7 * DAY),
    });
  });

  it('settles a stale open offer, closes its application, and sends a new one', async () => {
    applications.nextApplicationId = 'app-1';
    await service.send(OWNER, { ...REELS });
    repo.appStatus.set('app-1', 'OFFERED');
    clock.advance(7 * DAY);
    applications.nextApplicationId = null;

    await service.send(OWNER, { ...REELS });
    expect(repo.rows.map((r) => r.status)).toEqual(['EXPIRED', 'SENT']);
    expect(applications.closed).toEqual(['app-1']);
  });

  it('does not close an application that is no longer OFFERED', async () => {
    applications.nextApplicationId = 'app-1';
    await service.send(OWNER, { ...REELS });
    repo.appStatus.set('app-1', 'CLOSED');
    clock.advance(7 * DAY);
    await service.listSent(OWNER);
    expect(applications.closed).toEqual([]);
  });

  it('puts the application back to APPLIED when the create loses a race', async () => {
    applications.nextApplicationId = 'app-1';
    repo.loseCreateRace = true;
    await expect(service.send(OWNER, { ...REELS })).rejects.toMatchObject({
      code: 'CONFLICT',
    });
    expect(applications.reopened).toEqual(['app-1']);
    expect(push.sent).toEqual([]);
  });

  it('puts the application back when the create fails for another reason', async () => {
    applications.nextApplicationId = 'app-1';
    jest.spyOn(repo, 'create').mockRejectedValueOnce(new Error('db down'));
    await expect(service.send(OWNER, { ...REELS })).rejects.toThrow('db down');
    expect(applications.reopened).toEqual(['app-1']);
  });

  it('does not touch applications when the offer was not linked to one', async () => {
    repo.loseCreateRace = true;
    await expect(service.send(OWNER, { ...REELS })).rejects.toMatchObject({
      code: 'CONFLICT',
    });
    expect(applications.reopened).toEqual([]);
  });

  it('keeps the push failure from failing the send', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    push.fail = true;
    const sent = await service.send(OWNER, { ...REELS });
    expect(sent.view).toBe('WAITING');
    expect(warn).toHaveBeenCalledTimes(1);
    expect(JSON.stringify(warn.mock.calls)).not.toContain('notify down');
    warn.mockRestore();
  });

  it('notifies the creator with the store as the actor and the offer terms', async () => {
    const sent = await service.send(OWNER, { ...REELS });
    expect(push.sent).toEqual([
      {
        userId: CREATOR,
        role: 'CREATOR',
        kind: 'OFFER_RECEIVED',
        params: { format: 'REELS', pieceCount: 1 },
        actor: {
          userId: OWNER,
          name: '한그릇 라멘',
          photoPath: 'stores/ramen.jpg',
        },
        target: { kind: 'OFFER_INBOX', id: sent.id },
        dedupeKey: `offer-received:${sent.id}`,
      },
    ]);
  });

  describe('responding', () => {
    let id: string;
    beforeEach(async () => {
      id = (await service.send(OWNER, { ...REELS })).id;
      push.sent.length = 0;
      users.role = 'CREATOR';
    });

    it('does not notify the owner when the offer is declined', async () => {
      await service.decline(CREATOR, id);
      expect(push.sent).toEqual([]);
    });

    it('notifies the owner with the creator as the actor, pointing at the collaboration', async () => {
      // 식사권만 있는 오퍼는 바로 FUNDED로 시작해 결제할 것이 없다.
      await service.accept(CREATOR, id);
      expect(push.sent).toEqual([
        {
          userId: OWNER,
          role: 'STORE',
          kind: 'OFFER_ACCEPTED',
          actor: {
            userId: CREATOR,
            name: '하루 한 컵',
            photoPath: 'creators/haru.jpg',
          },
          target: { kind: 'COLLABORATION', id: collaborations.rows[0].id },
          dedupeKey: `offer-accepted:${id}`,
        },
      ]);
    });

    it('points the accepted notification at payment while the collaboration awaits payment', async () => {
      users.role = 'STORE';
      await service.cancel(OWNER, id);
      const perView = await service.send(OWNER, {
        creatorId: CREATOR,
        format: 'REELS',
        rewardType: 'PER_VIEW',
      });
      push.sent.length = 0;
      users.role = 'CREATOR';
      await service.accept(CREATOR, perView.id);
      expect(collaborations.rows[0].stage).toBe('AWAITING_PAYMENT');
      expect(push.sent).toHaveLength(1);
      expect(push.sent[0].target).toEqual({
        kind: 'PAYMENT',
        id: collaborations.rows[0].id,
      });
    });

    it('creates the collaboration in the accept transaction with a copy of the terms', async () => {
      await service.accept(CREATOR, id);
      expect(collaborations.rows).toHaveLength(1);
      expect(collaborations.rows[0]).toMatchObject({
        kind: 'STORE_OFFER',
        stage: 'FUNDED',
        settlementMethod: 'NONE',
        commissionerId: OWNER,
        creatorId: CREATOR,
        offerId: id,
        terms: { format: 'REELS', rewardType: 'VOUCHER' },
      });
    });

    it('creates no collaboration when the conditional update is lost', async () => {
      jest.spyOn(repo, 'accept').mockResolvedValueOnce(false);
      await expect(service.accept(CREATOR, id)).rejects.toBeInstanceOf(
        AppError,
      );
      expect(collaborations.rows).toEqual([]);
    });

    it('maps a lost conditional update to 409 CONFLICT', async () => {
      // 읽은 뒤 다른 요청이 먼저 바꾼 경우를 흉내 낸다.
      jest.spyOn(repo, 'accept').mockResolvedValueOnce(false);
      await expect(service.accept(CREATOR, id)).rejects.toMatchObject({
        code: 'CONFLICT',
        message: '이미 처리된 오퍼예요.',
      });
    });

    it('maps a refused undo to 409 CONFLICT', async () => {
      await service.decline(CREATOR, id);
      clock.advance(30 * 1000);
      await expect(service.undoDecline(CREATOR, id)).rejects.toBeInstanceOf(
        AppError,
      );
    });

    it('treats a non-uuid id as not found without reading', async () => {
      const find = jest.spyOn(repo, 'findForCreator');
      await expect(service.accept(CREATOR, 'x')).rejects.toMatchObject({
        code: 'NOT_FOUND',
      });
      expect(find).not.toHaveBeenCalled();
    });

    it('uses the stored terms copy in the received card', async () => {
      const list = await service.listReceived(CREATOR, 'new');
      expect(list).toHaveLength(1);
      expect(list[0].terms).toMatchObject({
        format: 'REELS',
        rewardType: 'VOUCHER',
      });
      expect(list[0].receivedAt).toBe(T0.toISOString());
    });
  });
});
