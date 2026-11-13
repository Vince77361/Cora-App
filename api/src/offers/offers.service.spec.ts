import { randomUUID } from 'node:crypto';
import { Logger } from '@nestjs/common';
import { Collaboration, Store, UserRole } from '@prisma/client';
import { ApplicationsService } from '../applications/applications.service';
import { AppError } from '../common/errors/app-error';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { CreatorsService } from '../creators/creators.service';
import { InstagramService } from '../instagram/instagram.service';
import type { CreatorSummaryModel } from '../creators/dto/creator-profile.model';
import {
  NotifyInput,
  NotificationsService,
} from '../notifications/notifications.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { JobHandlerRegistry } from '../jobs/job-handler-registry';
import { DeclineNoticeHandler } from './jobs/decline-notice.handler';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeJobScheduler } from '../../test/support/fake-job-scheduler';
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
    // 실제 저장소처럼 같은 트랜잭션의 할 일이 false면 만료까지 되돌린다.
    if ((await alongWith?.(null as never)) === false) {
      row.status = from;
      return false;
    }
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
          pieces: 1,
          voucherName: '식사권',
          voucherValue: 40000,
          voucherPeople: 2,
          fixedCash: 0,
          viewRatePerThousand: null,
          perViewCap: null,
          usageRights: 'STORE_REPOST_3M',
          maxCashBurden: 0,
          settlementMethod: 'NONE',
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
            instagramConnected: false,
            followers: null,
          }
        : null,
    );
  }
}

// 연결 여부만 필요하다. 연결 자체는 인스타그램 서비스 spec이 확인한다.
class FakeInstagram extends InstagramService {
  connected = false;
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
  getConnection(): ReturnType<InstagramService['getConnection']> {
    return Promise.resolve(
      this.connected ? { handle: 'haru', followers: 2100 } : null,
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
    defaultVoucherName: '식사권',
    defaultVoucherValue: 40000,
    defaultVoucherPeople: 2,
    defaultFixedCash: 0,
    defaultViewRatePerThousand: 2000,
    defaultPerViewCap: 60000,
    defaultUsageRights: 'STORE_REPOST_3M',
  } as Store;
}

describe('OffersService', () => {
  let repo: FakeOffersRepository;
  let collaborations: FakeCollaborations;
  let users: FakeUsers;
  let stores: FakeStores;
  let applications: FakeApplications;
  let push: FakeNotifications;
  let instagram: FakeInstagram;
  let creators: FakeCreators;
  let clock: FakeClock;
  let jobs: FakeJobScheduler;
  let service: OffersService;
  const REELS = {
    creatorId: CREATOR,
    format: 'REELS',
    reward: { voucher: {} },
  } as const;

  beforeEach(() => {
    repo = new FakeOffersRepository();
    collaborations = new FakeCollaborations();
    users = new FakeUsers();
    stores = new FakeStores(makeStore());
    applications = new FakeApplications();
    push = new FakeNotifications();
    instagram = new FakeInstagram();
    creators = new FakeCreators();
    clock = new FakeClock(T0);
    jobs = new FakeJobScheduler(new JobHandlerRegistry());
    service = new OffersService(
      repo,
      users,
      stores,
      applications,
      creators,
      collaborations,
      instagram,
      push,
      jobs,
      clock,
    );
  });

  it('checks the role before anything else', async () => {
    users.role = 'CREATOR';
    await expect(service.send(OWNER, { ...REELS })).rejects.toMatchObject({
      code: 'FORBIDDEN',
    });
    users.role = 'STORE';
    await expect(service.listReceived(OWNER)).rejects.toMatchObject({
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
        reward: { perView: {} },
      }),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
  });

  it('sends an offer with the store default view pay when values are omitted', async () => {
    stores.store = {
      ...stores.store,
      defaultViewRatePerThousand: 3000,
      defaultPerViewCap: 100000,
      defaultUsageRights: 'STORE_REPOST_6M',
    };
    await service.send(OWNER, {
      creatorId: CREATOR,
      format: 'REELS',
      reward: { perView: {} },
    });
    expect(repo.rows[0]).toMatchObject({
      voucherName: null,
      fixedCash: 0,
      viewRatePerThousand: 3000,
      perViewCap: 100000,
      usageRights: 'STORE_REPOST_6M',
    });
  });

  it('keeps the values the store gives over its defaults', async () => {
    await service.send(OWNER, {
      creatorId: CREATOR,
      format: 'REELS',
      reward: { perView: { ratePerThousand: 1500, cap: 30000 } },
      usageRights: 'NONE',
    });
    expect(repo.rows[0]).toMatchObject({
      viewRatePerThousand: 1500,
      perViewCap: 30000,
      usageRights: 'NONE',
    });
  });

  it('rejects a rate outside the allowed range and fixed cash for now', async () => {
    await expect(
      service.send(OWNER, {
        creatorId: CREATOR,
        format: 'REELS',
        reward: { perView: { ratePerThousand: 10000 } },
      }),
    ).rejects.toMatchObject({ code: 'VALIDATION_FAILED' });
    await expect(
      service.send(OWNER, {
        creatorId: CREATOR,
        format: 'REELS',
        reward: { voucher: {}, fixedCash: 30000 },
      }),
    ).rejects.toMatchObject({
      code: 'VALIDATION_FAILED',
      message: '고정 현금은 아직 쓸 수 없어요.',
    });
    expect(repo.rows).toEqual([]);
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

    // 보낸 오퍼를 크리에이터가 받은 상태로 돌려준다. id의 식사권 오퍼는 먼저 취소해 열린 오퍼 중복을 피한다.
    async function sendAs(
      format: 'REELS' | 'SHORTS' | 'CARD_NEWS',
      reward: 'PER_VIEW' | 'VOUCHER',
    ) {
      users.role = 'STORE';
      await service.cancel(OWNER, id);
      const sent = await service.send(OWNER, {
        creatorId: CREATOR,
        format,
        reward: reward === 'PER_VIEW' ? { perView: {} } : { voucher: {} },
      });
      users.role = 'CREATOR';
      return sent.id;
    }

    it('marks a per-view reels offer as needing instagram and refuses to accept it', async () => {
      const perView = await sendAs('REELS', 'PER_VIEW');
      const [card] = await service.listReceived(CREATOR);
      expect(card.needsInstagram).toBe(true);
      await expect(service.accept(CREATOR, perView)).rejects.toMatchObject({
        code: 'CONFLICT',
        message: '인스타그램을 연동하면 수락할 수 있어요.',
      });
      expect(collaborations.rows).toEqual([]);
      expect(repo.rows.find((r) => r.id === perView)?.status).toBe('SENT');
      expect(push.sent.filter((n) => n.kind === 'OFFER_ACCEPTED')).toEqual([]);
    });

    it('accepts the same offer after connecting', async () => {
      const perView = await sendAs('CARD_NEWS', 'PER_VIEW');
      instagram.connected = true;
      const [card] = await service.listReceived(CREATOR);
      expect(card.needsInstagram).toBe(false);
      const accepted = await service.accept(CREATOR, perView);
      expect(accepted.view).toBe('ACCEPTED');
      expect(accepted.needsInstagram).toBe(false);
    });

    it('does not require instagram for a voucher-only offer or a shorts offer', async () => {
      const [voucher] = await service.listReceived(CREATOR);
      expect(voucher.needsInstagram).toBe(false);
      await expect(service.accept(CREATOR, id)).resolves.toMatchObject({
        view: 'ACCEPTED',
      });
    });

    it('does not require instagram for a per-view shorts offer', async () => {
      const shorts = await sendAs('SHORTS', 'PER_VIEW');
      const [card] = await service.listReceived(CREATOR);
      expect(card.needsInstagram).toBe(false);
      await expect(service.accept(CREATOR, shorts)).resolves.toMatchObject({
        view: 'ACCEPTED',
      });
    });

    it('points the accepted notification at payment while the collaboration awaits payment', async () => {
      users.role = 'STORE';
      await service.cancel(OWNER, id);
      const perView = await service.send(OWNER, {
        creatorId: CREATOR,
        format: 'REELS',
        reward: { perView: {} },
      });
      push.sent.length = 0;
      users.role = 'CREATOR';
      instagram.connected = true;
      await service.accept(CREATOR, perView.id);
      expect(collaborations.rows[0].stage).toBe('AWAITING_PAYMENT');
      expect(push.sent).toHaveLength(1);
      expect(push.sent[0].target).toEqual({
        kind: 'PAYMENT',
        id: collaborations.rows[0].id,
      });
    });

    it('still accepts and notifies with a default name when the actor cannot be read', async () => {
      const warn = jest
        .spyOn(Logger.prototype, 'warn')
        .mockImplementation(() => undefined);
      jest
        .spyOn(creators, 'getActor')
        .mockRejectedValueOnce(new Error('actor read down'));
      const accepted = await service.accept(CREATOR, id);
      expect(accepted.view).toBe('ACCEPTED');
      expect(push.sent).toHaveLength(1);
      expect(push.sent[0].actor).toEqual({
        userId: CREATOR,
        name: '크리에이터',
        photoPath: null,
      });
      expect(JSON.stringify(warn.mock.calls)).not.toContain('actor read down');
      warn.mockRestore();
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
        terms: {
          format: 'REELS',
          pieces: 1,
          voucherName: '식사권',
          voucherValue: 40000,
          voucherPeople: 2,
          fixedCash: 0,
          viewRatePerThousand: null,
          perViewCap: null,
          usageRights: 'STORE_REPOST_3M',
        },
      });
      // 계산 값은 사본에 넣지 않고 읽을 때 계산한다.
      expect(collaborations.rows[0].terms).not.toHaveProperty('maxCashBurden');
      expect(collaborations.rows[0].terms).not.toHaveProperty(
        'settlementMethod',
      );
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
      const list = await service.listReceived(CREATOR);
      expect(list).toHaveLength(1);
      expect(list[0].terms).toMatchObject({
        format: 'REELS',
        voucherName: '식사권',
        maxCashBurden: 0,
        settlementMethod: 'NONE',
      });
      expect(list[0].receivedAt).toBe(T0.toISOString());
    });
  });

  describe('scheduled jobs', () => {
    const SECOND = 1000;
    let id: string;
    beforeEach(async () => {
      id = (await service.send(OWNER, { ...REELS })).id;
      push.sent.length = 0;
      users.role = 'CREATOR';
      // 이 묶음은 조회수 보상 오퍼를 수락하므로 연결된 크리에이터로 둔다(수락 조건은 위에서 시험한다).
      instagram.connected = true;
    });

    // 조회수 보상만 있는 오퍼를 수락해 결제 대기 협업을 만든다.
    async function acceptPerView(): Promise<string> {
      users.role = 'STORE';
      await service.cancel(OWNER, id);
      const perView = await service.send(OWNER, {
        creatorId: CREATOR,
        format: 'REELS',
        reward: { perView: {} },
      });
      users.role = 'CREATOR';
      await service.accept(CREATOR, perView.id);
      return perView.id;
    }

    it('schedules the submission deadline jobs when a voucher-only offer is accepted', async () => {
      await service.accept(CREATOR, id);
      const collaboration = collaborations.rows[0];
      expect(collaboration.stage).toBe('FUNDED');
      // 기한 2026-12-15 09:00 KST: 환급은 그 시각에, 알림은 3일 전(12-12)과 하루 전(12-14) 10:00 KST에.
      expect(
        jobs
          .pending()
          .map((j) => ({ name: j.name, jobKey: j.jobKey, runAt: j.runAt }))
          .sort((a, b) => a.runAt.getTime() - b.runAt.getTime()),
      ).toEqual([
        {
          name: 'submit-reminder',
          jobKey: `submit-reminder:${collaboration.id}:3`,
          runAt: new Date('2026-12-12T01:00:00.000Z'),
        },
        {
          name: 'submit-reminder',
          jobKey: `submit-reminder:${collaboration.id}:1`,
          runAt: new Date('2026-12-14T01:00:00.000Z'),
        },
        {
          name: 'refund-unsubmitted',
          jobKey: `refund-unsubmitted:${collaboration.id}`,
          runAt: new Date(T0.getTime() + 14 * DAY),
        },
      ]);
    });

    it('does not schedule submission deadline jobs for an offer that still needs a payment', async () => {
      await acceptPerView();
      expect(
        jobs.pending().filter((j) => j.name !== 'payment-due-expiry'),
      ).toEqual([]);
    });

    it('keeps a voucher-only accept saved when the deadline jobs cannot be scheduled', async () => {
      jest.spyOn(jobs, 'schedule').mockRejectedValue(new Error('redis'));
      const warn = jest
        .spyOn(Logger.prototype, 'warn')
        .mockImplementation(() => undefined);
      await expect(service.accept(CREATOR, id)).resolves.toMatchObject({
        view: 'ACCEPTED',
      });
      expect(collaborations.rows).toHaveLength(1);
      expect(warn).toHaveBeenCalled();
      warn.mockRestore();
    });

    it('schedules the decline notice 30 seconds after the decline', async () => {
      await service.decline(CREATOR, id);
      expect(jobs.pending()).toMatchObject([
        {
          name: 'decline-notice',
          payload: { offerId: id, declinedAt: T0.toISOString() },
          runAt: new Date(T0.getTime() + 30 * SECOND),
          jobKey: `decline:${id}:${T0.getTime()}`,
        },
      ]);
    });

    it('cancels the decline notice on undo and schedules it again on a new decline', async () => {
      await service.decline(CREATOR, id);
      clock.advance(10 * SECOND);
      await service.undoDecline(CREATOR, id);
      expect(jobs.pending()).toEqual([]);

      clock.advance(10 * SECOND);
      await service.decline(CREATOR, id);
      expect(jobs.pending()).toMatchObject([
        {
          jobKey: `decline:${id}:${clock.now().getTime()}`,
          runAt: new Date(clock.now().getTime() + 30 * SECOND),
        },
      ]);
    });

    it('keeps the decline saved when scheduling fails', async () => {
      jest.spyOn(jobs, 'schedule').mockRejectedValueOnce(new Error('redis'));
      const warn = jest
        .spyOn(Logger.prototype, 'warn')
        .mockImplementation(() => undefined);
      await expect(service.decline(CREATOR, id)).resolves.toMatchObject({
        view: 'DECLINED',
      });
      expect(warn).toHaveBeenCalled();
      warn.mockRestore();
    });

    it('notifies the owner 30 seconds after a decline', async () => {
      await service.decline(CREATOR, id);
      clock.advance(30 * SECOND);
      await service.sendDeclineNotice(id, T0);
      expect(push.sent).toEqual([
        {
          userId: OWNER,
          role: 'STORE',
          kind: 'OFFER_DECLINED',
          actor: {
            userId: CREATOR,
            name: '하루 한 컵',
            photoPath: 'creators/haru.jpg',
          },
          target: { kind: 'STORE_SENT_OFFERS', id: null },
          dedupeKey: `decline:${id}`,
        },
      ]);
    });

    it('closes the linked application when the decline notice runs', async () => {
      const linked = repo.rows.find((r) => r.id === id);
      Object.assign(linked as OfferRow, { applicationId: 'app-1' });
      repo.appStatus.set('app-1', 'OFFERED');
      await service.decline(CREATOR, id);
      clock.advance(30 * SECOND);
      await service.sendDeclineNotice(id, T0);
      expect(applications.closed).toEqual(['app-1']);
    });

    it('does not notify when the decline was undone', async () => {
      await service.decline(CREATOR, id);
      await service.undoDecline(CREATOR, id);
      clock.advance(30 * SECOND);
      await service.sendDeclineNotice(id, T0);
      expect(push.sent).toEqual([]);
    });

    it('does not notify while the undo window of the current decline is still open', async () => {
      await service.decline(CREATOR, id);
      clock.advance(10 * SECOND);
      await service.undoDecline(CREATOR, id);
      clock.advance(10 * SECOND);
      await service.decline(CREATOR, id);
      // 처음 거절의 30초 뒤에 오래된 작업이 돌아도, 지금 거절의 30초는 끝나지 않았다.
      clock.advance(15 * SECOND);
      await service.sendDeclineNotice(id, T0);
      expect(push.sent).toEqual([]);
    });

    it('skips a job of an earlier decline even after the current decline is final', async () => {
      await service.decline(CREATOR, id);
      clock.advance(10 * SECOND);
      await service.undoDecline(CREATOR, id);
      clock.advance(10 * SECOND);
      await service.decline(CREATOR, id);
      clock.advance(30 * SECOND);
      await service.sendDeclineNotice(id, T0);
      expect(push.sent).toEqual([]);
      await service.sendDeclineNotice(id, new Date(T0.getTime() + 20 * SECOND));
      expect(push.sent).toHaveLength(1);
    });

    it('notifies exactly once, at the second deadline, when the undo could not cancel the first job', async () => {
      jobs.registry.register('decline-notice', (p) =>
        new DeclineNoticeHandler(service).run(p),
      );
      await service.decline(CREATOR, id);
      clock.advance(10 * SECOND);
      jest.spyOn(jobs, 'cancel').mockRejectedValueOnce(new Error('redis'));
      const warn = jest
        .spyOn(Logger.prototype, 'warn')
        .mockImplementation(() => undefined);
      await service.undoDecline(CREATOR, id);
      warn.mockRestore();
      clock.advance(10 * SECOND);
      await service.decline(CREATOR, id);
      // 취소가 실패해 첫 작업이 남았어도, 키가 달라 두 번째 작업이 막히지 않고 둘 다 올라가 있다.
      expect(jobs.pending().map((j) => j.runAt)).toEqual([
        new Date(T0.getTime() + 30 * SECOND),
        new Date(T0.getTime() + 50 * SECOND),
      ]);

      // 첫 마감: 옛 작업은 지금 거절의 것이 아니라 아무것도 하지 않는다.
      clock.set(new Date(T0.getTime() + 30 * SECOND));
      await jobs.runDue(clock.now());
      expect(push.sent).toEqual([]);

      // 두 번째 마감: 지금 거절의 작업이 알린다.
      clock.set(new Date(T0.getTime() + 50 * SECOND));
      await jobs.runDue(clock.now());
      expect(push.sent).toHaveLength(1);
      expect(push.sent[0]).toMatchObject({
        kind: 'OFFER_DECLINED',
        dedupeKey: `decline:${id}`,
      });
    });

    it('sends the decline notice with the same dedupe key when run twice', async () => {
      await service.decline(CREATOR, id);
      clock.advance(30 * SECOND);
      await service.sendDeclineNotice(id, T0);
      await service.sendDeclineNotice(id, T0);
      expect(push.sent.map((n) => n.dedupeKey)).toEqual([
        `decline:${id}`,
        `decline:${id}`,
      ]);
    });

    it('lets a failing notification fail the decline notice so the queue retries', async () => {
      await service.decline(CREATOR, id);
      clock.advance(30 * SECOND);
      push.fail = true;
      await expect(service.sendDeclineNotice(id, T0)).rejects.toThrow(
        'notify down',
      );
    });

    it('does nothing for a missing offer', async () => {
      await service.sendDeclineNotice(randomUUID(), T0);
      await service.expireUnpaid(randomUUID());
      expect(push.sent).toEqual([]);
    });

    it('schedules the payment due expiry at the due time for a per-view offer', async () => {
      const offerId = await acceptPerView();
      expect(jobs.pending()).toMatchObject([
        {
          name: 'payment-due-expiry',
          payload: { offerId },
          runAt: new Date(T0.getTime() + 3 * DAY),
          jobKey: `payment-due:${offerId}`,
        },
      ]);
    });

    it('schedules no payment due expiry for a voucher-only offer', async () => {
      await service.accept(CREATOR, id);
      // 낼 돈이 없으니 결제 기한 작업은 없다(제출 기한 작업은 따로 올라간다).
      expect(
        jobs.pending().filter((j) => j.name === 'payment-due-expiry'),
      ).toEqual([]);
    });

    it('keeps the accept saved when scheduling the expiry fails', async () => {
      users.role = 'STORE';
      await service.cancel(OWNER, id);
      const perView = await service.send(OWNER, {
        creatorId: CREATOR,
        format: 'REELS',
        reward: { perView: {} },
      });
      users.role = 'CREATOR';
      jest.spyOn(jobs, 'schedule').mockRejectedValueOnce(new Error('redis'));
      const warn = jest
        .spyOn(Logger.prototype, 'warn')
        .mockImplementation(() => undefined);
      await expect(service.accept(CREATOR, perView.id)).resolves.toMatchObject({
        view: 'ACCEPTED',
      });
      expect(collaborations.rows[0].stage).toBe('AWAITING_PAYMENT');
      warn.mockRestore();
    });

    it('expires an unpaid accepted offer and cancels its collaboration at the due time', async () => {
      const offerId = await acceptPerView();
      clock.advance(3 * DAY);
      await service.expireUnpaid(offerId);
      expect(repo.rows.find((r) => r.id === offerId)?.status).toBe('EXPIRED');
      expect(collaborations.rows[0].stage).toBe('CANCELLED');
    });

    it('does nothing before the due time', async () => {
      const offerId = await acceptPerView();
      clock.advance(3 * DAY - SECOND);
      await service.expireUnpaid(offerId);
      expect(repo.rows.find((r) => r.id === offerId)?.status).toBe('ACCEPTED');
      expect(collaborations.rows[0].stage).toBe('AWAITING_PAYMENT');
    });

    it('does nothing when the offer was paid before the due time', async () => {
      const offerId = await acceptPerView();
      // 결제가 승인되면 협업은 FUNDED가 되고 오퍼의 결제 기한은 지워진다(오퍼는 ACCEPTED 그대로).
      collaborations.rows[0].stage = 'FUNDED';
      const offer = repo.rows.find((r) => r.id === offerId) as OfferRow;
      offer.paymentDueAt = null;
      clock.advance(3 * DAY);
      await service.expireUnpaid(offerId);
      expect(offer.status).toBe('ACCEPTED');
      expect(collaborations.rows[0].stage).toBe('FUNDED');
    });

    it('keeps an offer whose collaboration was funded even if the due time was not cleared', async () => {
      const offerId = await acceptPerView();
      collaborations.rows[0].stage = 'FUNDED';
      clock.advance(3 * DAY);
      await service.expireUnpaid(offerId);
      expect(repo.rows.find((r) => r.id === offerId)?.status).toBe('ACCEPTED');
      expect(collaborations.rows[0].stage).toBe('FUNDED');
    });

    it('does nothing when run twice', async () => {
      const offerId = await acceptPerView();
      clock.advance(3 * DAY);
      const advance = jest.spyOn(collaborations, 'advanceByOffer');
      await service.expireUnpaid(offerId);
      await service.expireUnpaid(offerId);
      expect(advance).toHaveBeenCalledTimes(1);
      expect(repo.rows.find((r) => r.id === offerId)?.status).toBe('EXPIRED');
      expect(collaborations.rows[0].stage).toBe('CANCELLED');
    });
  });
});
