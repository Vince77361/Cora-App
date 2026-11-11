import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { ApplicationsService } from '../applications/applications.service';
import {
  initialStoreOfferState,
  storeInProgressStages,
} from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { InstagramService } from '../instagram/instagram.service';
import { JobScheduler, OfferJobPayload } from '../jobs/job-scheduler';
import {
  NotificationsService,
  NotifyInput,
} from '../notifications/notifications.service';
import { StoresService } from '../stores/stores.service';
import { buildTerms } from '../stores/offer-terms';
import { UsersService } from '../users/users.service';
import { ReceivedTab } from './dto/received-offers-query.dto';
import { ReceivedOfferModel } from './dto/received-offer.model';
import { SendOfferDto } from './dto/send-offer.dto';
import { SentOfferModel } from './dto/sent-offer.model';
import { StoreHomeSummaryModel } from './dto/store-home-summary.model';
import {
  canUndoDecline,
  DECLINE_UNDO_SECONDS,
  needsInstagram,
  OFFER_RESPONSE_DAYS,
  paymentDaysLeft,
  storedStatusAt,
  viewForCreator,
  viewForStore,
} from './offer-rules';
import {
  InSameTransaction,
  OfferRow,
  OffersRepository,
} from './offers.repository';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DAY_MS = 24 * 60 * 60 * 1000;

// 거절마다 다른 키: 같은 오퍼를 되돌렸다 다시 거절해도 옛 작업과 새 작업이 서로 가리지 않는다.
const declineJobKey = (offerId: string, declinedAt: Date): string =>
  `decline:${offerId}:${declinedAt.getTime()}`;

// 서비스는 규칙을 복제하지 않는다. 상태·보임·남은 날은 offer-rules의 순수 함수만 쓴다.
@Injectable()
export class OffersService {
  private readonly logger = new Logger(OffersService.name);

  constructor(
    private readonly offers: OffersRepository,
    private readonly users: UsersService,
    private readonly stores: StoresService,
    private readonly applications: ApplicationsService,
    private readonly creators: CreatorsService,
    private readonly collaborations: CollaborationsRepository,
    private readonly instagram: InstagramService,
    private readonly notifications: NotificationsService,
    private readonly jobs: JobScheduler,
    private readonly clock: Clock,
  ) {}

  // 검사 순서: 역할 → 내 가게 공개됨 → 나 자신 아님 → 받는 사람 프로필 → 조건 → 기한 지난 오퍼 정리 → 열린 오퍼 중복.
  async send(userId: string, input: SendOfferDto): Promise<SentOfferModel> {
    await this.assertRole(userId, 'STORE', '가게 계정만 쓸 수 있어요.');
    const store = await this.stores.requireMyStore(userId);
    if (store.status !== 'PUBLISHED') {
      throw new AppError('CONFLICT', '가게를 먼저 공개해 주세요.');
    }
    if (input.creatorId === userId) {
      throw new AppError('CONFLICT', '나에게는 오퍼를 보낼 수 없어요.');
    }
    const creator = await this.creators.getSummary(input.creatorId);
    if (!creator) {
      throw new AppError('NOT_FOUND', '크리에이터를 찾을 수 없어요.');
    }
    const terms = buildTerms(input);

    const now = this.clock.now();
    // 기한이 지난 오퍼가 새 오퍼를 막지 않도록, 열린 오퍼를 보기 전에 만료를 저장한다.
    const open = await this.offers.findOpen(store.id, creator.userId, now);
    for (const row of open) {
      const settled = await this.settle(row, now);
      if (settled && this.isOpen(settled, now)) throw this.alreadySent();
    }

    // 지원 연결을 먼저 한다: 동시에 두 번 보내면 진 쪽은 연결할 지원을 못 얻고, 만들기에서 막힌다.
    const applicationId = await this.applications.markOffered(
      store.id,
      creator.userId,
    );
    let created: OfferRow | null;
    try {
      created = await this.offers.create({
        storeId: store.id,
        creatorId: creator.userId,
        applicationId,
        ...terms,
        // 보낸 시각을 DB 기본값이 아니라 Clock으로 정해, 만료 기한과 같은 기준을 쓴다.
        createdAt: now,
        expiresAt: new Date(now.getTime() + OFFER_RESPONSE_DAYS * DAY_MS),
      });
    } catch (error) {
      await this.releaseApplication(applicationId);
      throw error;
    }
    if (!created) {
      // 동시에 보낸 다른 요청이 먼저 만들었다. 우리가 OFFERED로 바꾼 지원을 오퍼 없이 두면
      // 크리에이터가 다시 지원하지 못하므로 APPLIED로 되돌린다.
      await this.releaseApplication(applicationId);
      throw this.alreadySent();
    }

    await this.notify({
      userId: creator.userId,
      role: 'CREATOR',
      kind: 'OFFER_RECEIVED',
      // 오퍼는 지금 한 편짜리다(편 수를 고르는 화면이 없다).
      params: { format: created.format, pieceCount: 1 },
      actor: {
        userId,
        name: store.name ?? '가게',
        photoPath: store.coverPhotoPath,
      },
      target: { kind: 'OFFER_INBOX', id: created.id },
      // 요청이 다시 와도 같은 오퍼에는 알림이 한 번만 간다.
      dedupeKey: `offer-received:${created.id}`,
    });
    return this.toSent(created, creator, now, null);
  }

  async listSent(userId: string): Promise<SentOfferModel[]> {
    await this.assertRole(userId, 'STORE', '가게 계정만 쓸 수 있어요.');
    const store = await this.stores.requireMyStore(userId);
    const now = this.clock.now();
    const rows = await this.settleAll(
      await this.offers.listForStore(store.id),
      now,
    );
    const summaries = await Promise.all(
      rows.map((row) => this.creators.getSummary(row.creatorId)),
    );
    const collaborationIds = await this.collaborationIds(rows);
    const items: SentOfferModel[] = [];
    rows.forEach((row, index) => {
      const creator = summaries[index];
      // 프로필이 지워진 크리에이터는 보여 줄 것이 없어 뺀다.
      if (creator) {
        items.push(
          this.toSent(row, creator, now, collaborationIds.get(row.id) ?? null),
        );
      }
    });
    return items;
  }

  async cancel(userId: string, id: string): Promise<SentOfferModel> {
    await this.assertRole(userId, 'STORE', '가게 계정만 쓸 수 있어요.');
    const store = await this.stores.requireMyStore(userId);
    const row = UUID.test(id)
      ? await this.offers.findForStore(id, store.id)
      : null;
    if (!row) throw this.notFound();

    const now = this.clock.now();
    const stored = storedStatusAt(row, now);
    if (stored === 'EXPIRED') {
      await this.settle(row, now);
      throw this.expired();
    }
    if (stored !== 'SENT' && stored !== 'ACCEPTED') throw this.alreadyHandled();

    // 결제한 뒤(협업이 AWAITING_PAYMENT를 지난 뒤)에는 사장님 혼자 취소할 수 없고 취소 요청을 보내야 한다.
    // 협업이 아직 없는 수락(3번 계획 이전에 수락된 오퍼)은 낼 돈이 없으므로 기존대로 취소된다.
    const collaboration =
      stored === 'ACCEPTED'
        ? await this.collaborations.findByOfferId(row.id)
        : null;
    if (collaboration && collaboration.stage !== 'AWAITING_PAYMENT') {
      throw new AppError('CONFLICT', '결제한 뒤에는 취소 요청을 보내 주세요.');
    }
    // 오퍼 취소와 협업 AWAITING_PAYMENT → CANCELLED를 한 트랜잭션으로 한다.
    // 그사이 결제가 승인돼 협업이 FUNDED가 되었으면 이동이 0행이라 오퍼 취소까지 되돌린다.
    const alongWith = collaboration
      ? (tx: Prisma.TransactionClient) =>
          this.collaborations.advanceByOffer(
            row.id,
            'AWAITING_PAYMENT',
            'CANCELLED',
            {},
            tx,
          )
      : undefined;
    if (!(await this.offers.cancel(row.id, store.id, stored, now, alongWith))) {
      await this.settleLatest(row.id, now);
      throw this.alreadyHandled();
    }
    await this.closeApplication({ ...row, status: 'CANCELLED' });

    const fresh = await this.offers.findForStore(row.id, store.id);
    const creator = await this.creators.getSummary(row.creatorId);
    if (!fresh || !creator) throw this.notFound();
    return this.toSent(fresh, creator, now, collaboration?.id ?? null);
  }

  async listReceived(
    userId: string,
    tab: ReceivedTab,
  ): Promise<ReceivedOfferModel[]> {
    await this.assertRole(userId, 'CREATOR', '크리에이터 계정만 쓸 수 있어요.');
    const now = this.clock.now();
    const rows = await this.settleAll(
      await this.offers.listForCreator(userId),
      now,
    );
    const shown = rows.filter((row) =>
      tab === 'new'
        ? viewForCreator(row, now) === 'WAITING' || canUndoDecline(row, now)
        : viewForCreator(row, now) === 'ACCEPTED',
    );
    const collaborationIds = await this.collaborationIds(shown);
    const connected = (await this.instagram.getConnection(userId)) !== null;
    const cards = new Map<string, Awaited<ReturnType<typeof this.card>>>();
    const items: ReceivedOfferModel[] = [];
    for (const row of shown) {
      if (!cards.has(row.storeId)) {
        cards.set(row.storeId, await this.card(row.storeId));
      }
      const card = cards.get(row.storeId);
      if (card) {
        items.push(
          this.toReceived(
            row,
            card,
            now,
            collaborationIds.get(row.id) ?? null,
            connected,
          ),
        );
      }
    }
    return items;
  }

  async accept(userId: string, id: string): Promise<ReceivedOfferModel> {
    await this.assertRole(userId, 'CREATOR', '크리에이터 계정만 쓸 수 있어요.');
    const row = await this.requireReceived(userId, id);
    const now = this.clock.now();
    const stored = storedStatusAt(row, now);
    if (stored === 'EXPIRED') {
      await this.settle(row, now);
      throw this.expired();
    }
    if (stored !== 'SENT') throw this.alreadyHandled();
    // 조회수 보상은 인스타그램 연결이 있어야 정산이 조회수를 읽을 수 있다. 수락 뒤에 알게 되지 않게 여기서 막는다.
    const connected = (await this.instagram.getConnection(userId)) !== null;
    if (needsInstagram(row, connected)) {
      throw new AppError('CONFLICT', '인스타그램을 연동하면 수락할 수 있어요.');
    }
    const card = await this.requireCard(row.storeId);
    // 수락과 협업 만들기는 한 트랜잭션이다. 식사권만 있는 오퍼는 낼 돈이 없어 결제 기한 없이 바로 FUNDED로 시작한다.
    const initial = initialStoreOfferState(row.rewardType, now);
    const accepted = await this.offers.accept(
      row.id,
      userId,
      now,
      initial.paymentDueAt,
      async (tx) => {
        await this.collaborations.create(
          {
            kind: 'STORE_OFFER',
            stage: initial.stage,
            commissionerId: card.ownerId,
            creatorId: userId,
            offerId: row.id,
            storeId: row.storeId,
            terms: this.termsOf(row),
            settlementMethod: initial.settlementMethod,
            fundedAt: initial.fundedAt,
            submitDueAt: initial.submitDueAt,
          },
          tx,
        );
      },
    );
    if (!accepted) {
      await this.settleLatest(row.id, now);
      throw this.alreadyHandled();
    }

    // 결제할 것이 있으면 기한에 만료 작업을 올린다. 올리지 못해도 화면은 읽을 때 만료로 맞는다.
    if (initial.paymentDueAt) {
      await this.schedule(
        'payment-due-expiry',
        { offerId: row.id },
        initial.paymentDueAt,
        `payment-due:${row.id}`,
      );
    }
    const collaboration = await this.collaborations.findByOfferId(row.id);
    // 이미 저장된 수락은 알림 때문에 500이 되면 안 된다. 상대 이름을 읽지 못해도 알림은 기본 이름으로 보낸다.
    await this.notify(async () => ({
      userId: card.ownerId,
      role: 'STORE',
      kind: 'OFFER_ACCEPTED',
      actor: await this.actorOf(userId),
      // 결제할 것이 있으면 결제 화면으로, 식사권만 있어 바로 FUNDED면 협업 화면으로 보낸다.
      target: {
        kind:
          initial.stage === 'AWAITING_PAYMENT' ? 'PAYMENT' : 'COLLABORATION',
        id: collaboration?.id ?? null,
      },
      dedupeKey: `offer-accepted:${row.id}`,
    }));
    return this.reload(userId, row.id, card, now, collaboration);
  }

  // 거절은 누르는 즉시 저장한다. 연결된 지원은 30초가 지나 확정된 뒤 목록을 읽을 때 닫는다.
  async decline(userId: string, id: string): Promise<ReceivedOfferModel> {
    await this.assertRole(userId, 'CREATOR', '크리에이터 계정만 쓸 수 있어요.');
    const row = await this.requireReceived(userId, id);
    const now = this.clock.now();
    const stored = storedStatusAt(row, now);
    if (stored === 'EXPIRED') {
      await this.settle(row, now);
      throw this.expired();
    }
    if (stored !== 'SENT') throw this.alreadyHandled();
    const card = await this.requireCard(row.storeId);
    if (!(await this.offers.decline(row.id, userId, now))) {
      await this.settleLatest(row.id, now);
      throw this.alreadyHandled();
    }
    // 30초 안에 되돌리지 않으면 사장님에게 알린다. 키에 거절 시각을 넣어, 되돌리기의 취소가 실패해 옛 작업이
    // 남아 있어도 다시 거절한 작업이 그 키에 막히지 않게 한다.
    await this.schedule(
      'decline-notice',
      { offerId: row.id, declinedAt: now.toISOString() },
      new Date(now.getTime() + DECLINE_UNDO_SECONDS * 1000),
      declineJobKey(row.id, now),
    );
    return this.reload(userId, row.id, card, now);
  }

  async undoDecline(userId: string, id: string): Promise<ReceivedOfferModel> {
    await this.assertRole(userId, 'CREATOR', '크리에이터 계정만 쓸 수 있어요.');
    const row = await this.requireReceived(userId, id);
    const now = this.clock.now();
    if (!canUndoDecline(row, now)) {
      throw new AppError(
        'CONFLICT',
        `거절한 뒤 ${DECLINE_UNDO_SECONDS}초가 지나 되돌릴 수 없어요.`,
      );
    }
    const card = await this.requireCard(row.storeId);
    if (!(await this.offers.undoDecline(row.id, userId, now))) {
      throw this.alreadyHandled();
    }
    // 취소하지 못해 작업이 남아도 처리기가 거절 시각이 다른 옛 작업은 건너뛴다.
    if (row.declinedAt)
      await this.cancelJob(declineJobKey(row.id, row.declinedAt));
    return this.reload(userId, row.id, card, now);
  }

  // 작업 큐가 거절 30초 뒤에 부른다. 작업이 올라갈 때의 거절 시각(declinedAt)이 오퍼의 지금 거절 시각과 같고,
  // 여전히 거절 상태이며 그 거절의 되돌리기 시간이 지났을 때만 알린다(되돌렸다가 다시 거절했으면 옛 작업은 건너뛴다).
  // 알림이 실패하면 던져서 큐가 다시 시도하게 하고, 중복 방지 키가 두 번째 알림을 막는다.
  async sendDeclineNotice(offerId: string, declinedAt: Date): Promise<void> {
    const row = await this.offers.findById(offerId);
    const now = this.clock.now();
    if (!row || row.status !== 'DECLINED' || canUndoDecline(row, now)) return;
    if (row.declinedAt?.getTime() !== declinedAt.getTime()) return;
    // 연결된 지원은 거절이 확정된 지금 닫는다(목록을 읽을 때 닫는 것과 같은 길).
    await this.settle(row, now);
    const card = await this.stores.getOfferCard(row.storeId);
    if (!card) return;
    const actor = (await this.creators.getActor(row.creatorId)) ?? {
      userId: row.creatorId,
      name: '크리에이터',
      photoPath: null,
    };
    await this.notifications.notify({
      userId: card.ownerId,
      role: 'STORE',
      kind: 'OFFER_DECLINED',
      actor,
      target: { kind: 'STORE_SENT_OFFERS', id: null },
      dedupeKey: `decline:${row.id}`,
    });
  }

  // 작업 큐가 결제 기한에 부른다. 읽을 때 만료와 같은 길(settle)을 쓰므로, 결제를 기다리는 협업이 아니면
  // (결제 승인으로 기한이 지워졌거나 협업이 이미 넘어갔으면) 아무것도 하지 않고, 두 번 돌아도 같다.
  async expireUnpaid(offerId: string): Promise<void> {
    const row = await this.offers.findById(offerId);
    if (row?.status !== 'ACCEPTED') return;
    await this.settle(row, this.clock.now());
  }

  // 결제 승인 트랜잭션이 부른다(3번 계획, 원장 판단 R1). 결제를 기다리던 수락 오퍼의 결제 기한을 지운다.
  // 승인 트랜잭션은 이것을 가장 먼저 불러 오퍼 → 협업 순으로 잠근다(취소·만료와 같은 순서).
  // 오퍼가 이미 만료·취소됐으면 false다 — 호출한 쪽이 트랜잭션을 되돌린다.
  clearPaymentDue(
    offerId: string,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    return this.offers.clearPaymentDue(offerId, tx);
  }

  // 결제가 승인되면 결제 기한 작업은 필요 없다. 지우지 못해도 처리기가 결제 기한이 없는 오퍼를 건드리지 않으므로 무해하다.
  cancelPaymentDueJob(offerId: string): Promise<void> {
    return this.cancelJob(`payment-due:${offerId}`);
  }

  // 사장님 홈의 숫자 세 개. 목록과 같은 정리를 거친 뒤 센다.
  async getHomeSummary(userId: string): Promise<StoreHomeSummaryModel> {
    await this.assertRole(userId, 'STORE', '가게 계정만 쓸 수 있어요.');
    const store = await this.stores.requireMyStore(userId);
    const now = this.clock.now();
    const rows = await this.settleAll(
      await this.offers.listForStore(store.id),
      now,
    );
    const views = rows.map((row) => viewForStore(row, now));
    return {
      newApplications: await this.applications.countNew(store.id),
      sentOffers: views.filter((view) => view === 'WAITING').length,
      // 오퍼가 아니라 협업의 단계로 센다: 결제 대기, 결제함, 조회수 집계 중.
      inProgress: await this.collaborations.countForStore(
        store.id,
        storeInProgressStages,
      ),
    };
  }

  // 저장된 상태가 지금 시각의 상태와 다르면 그 자리에서 저장하고(조건부), 끝난 오퍼의 지원을 닫는다.
  // 경쟁으로 갱신이 0행이면 무시하고 다시 읽은 값을 쓴다. 지워졌으면 null.
  private async settle(row: OfferRow, now: Date): Promise<OfferRow | null> {
    let current: OfferRow | null = row;
    const target = storedStatusAt(row, now);
    if (target !== row.status) {
      // 결제를 기다리던 수락 오퍼가 기한을 넘겨 만료되면 연결된 협업도 같은 트랜잭션에서 취소한다(오퍼 → 협업 순).
      // 협업이 이미 결제 대기를 지났으면(결제 승인) 오퍼를 만료하지 않는다. 읽은 뒤 결제가 승인돼
      // 협업 이동이 0행이면 오퍼 만료까지 되돌린다. 협업이 아직 없는 옛 수락은 오퍼만 만료한다.
      let alongWith: InSameTransaction | undefined;
      if (row.status === 'ACCEPTED' && target === 'EXPIRED') {
        const collaboration = await this.collaborations.findByOfferId(row.id);
        if (collaboration && collaboration.stage !== 'AWAITING_PAYMENT') {
          return current;
        }
        if (collaboration) {
          alongWith = (tx) =>
            this.collaborations.advanceByOffer(
              row.id,
              'AWAITING_PAYMENT',
              'CANCELLED',
              {},
              tx,
            );
        }
      }
      current = (await this.offers.expire(row.id, row.status, alongWith))
        ? { ...row, status: target }
        : await this.offers.findById(row.id);
    }
    if (!current) return null;
    if (this.isFinal(current, now)) await this.closeApplication(current);
    return current;
  }

  private async settleAll(rows: OfferRow[], now: Date): Promise<OfferRow[]> {
    const settled = await Promise.all(rows.map((row) => this.settle(row, now)));
    return settled.filter((row): row is OfferRow => row !== null);
  }

  // 조건부 갱신이 0행이었을 때, 기한 경쟁으로 뒤처진 저장을 맞춘다.
  private async settleLatest(id: string, now: Date): Promise<void> {
    const fresh = await this.offers.findById(id);
    if (fresh) await this.settle(fresh, now);
  }

  // 더 이상 되살릴 수 없는 오퍼: 만료·취소, 그리고 되돌리기 시간이 지난 거절.
  private isFinal(row: OfferRow, now: Date): boolean {
    const status = storedStatusAt(row, now);
    if (status === 'EXPIRED' || status === 'CANCELLED') return true;
    return status === 'DECLINED' && !canUndoDecline(row, now);
  }

  private isOpen(row: OfferRow, now: Date): boolean {
    return (
      row.status === 'SENT' ||
      row.status === 'ACCEPTED' ||
      canUndoDecline(row, now)
    );
  }

  private async releaseApplication(
    applicationId: string | null,
  ): Promise<void> {
    if (applicationId) await this.applications.reopen(applicationId);
  }

  // 아직 오퍼 받음(OFFERED)인 지원만 닫는다. 이미 닫힌 지원은 부르지 않는다.
  private async closeApplication(row: OfferRow): Promise<void> {
    if (row.applicationId && row.application?.status === 'OFFERED') {
      await this.applications.closeFor(row.applicationId);
    }
  }

  private async requireReceived(userId: string, id: string): Promise<OfferRow> {
    const row = UUID.test(id)
      ? await this.offers.findForCreator(id, userId)
      : null;
    if (!row) throw this.notFound();
    return row;
  }

  private async reload(
    userId: string,
    id: string,
    card: NonNullable<Awaited<ReturnType<typeof this.card>>>,
    now: Date,
    // 이미 읽은 협업이 있으면 다시 읽지 않는다.
    known?: { id: string } | null,
  ): Promise<ReceivedOfferModel> {
    const fresh = await this.offers.findForCreator(id, userId);
    if (!fresh) throw this.notFound();
    const collaboration =
      known ?? (await this.collaborations.findByOfferId(fresh.id));
    return this.toReceived(
      fresh,
      card,
      now,
      collaboration?.id ?? null,
      (await this.instagram.getConnection(userId)) !== null,
    );
  }

  // 오퍼 id → 연결된 협업 id. 협업이 아직 없는(수락 전) 오퍼는 들어 있지 않다.
  private async collaborationIds(
    rows: OfferRow[],
  ): Promise<Map<string, string>> {
    const found = await this.collaborations.mapByOfferIds(
      rows.map((row) => row.id),
    );
    return new Map([...found].map(([offerId, c]) => [offerId, c.id]));
  }

  private card(storeId: string) {
    return this.stores.getOfferCard(storeId);
  }

  private async requireCard(storeId: string) {
    const card = await this.card(storeId);
    if (!card) throw this.notFound();
    return card;
  }

  // 작업을 올리거나 지우지 못해도 이미 저장된 변경은 유효하다. 화면은 읽을 때 계산으로 맞고, 처리기는 오퍼의 현재 상태를 본다.
  private async schedule(
    name: 'decline-notice' | 'payment-due-expiry',
    payload: OfferJobPayload,
    runAt: Date,
    jobKey: string,
  ): Promise<void> {
    try {
      await this.jobs.schedule(name, payload, runAt, jobKey);
    } catch (error) {
      this.logger.warn(
        `오퍼 작업을 올리지 못했어요(${name}): ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  private async cancelJob(jobKey: string): Promise<void> {
    try {
      await this.jobs.cancel(jobKey);
    } catch (error) {
      this.logger.warn(
        `오퍼 작업을 지우지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 알림에 넣을 크리에이터. 프로필이 없거나 읽지 못하면 기본 이름을 쓴다.
  private async actorOf(userId: string) {
    let actor: Awaited<ReturnType<CreatorsService['getActor']>> = null;
    try {
      actor = await this.creators.getActor(userId);
    } catch (error) {
      this.logger.warn(
        `알림에 넣을 크리에이터를 읽지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
    return actor ?? { userId, name: '크리에이터', photoPath: null };
  }

  // 알림이 실패해도 이미 저장된 변경은 유효하다. 목록에서 볼 수 있다.
  // 입력을 만드는 일(읽기)이 실패해도 같다. 만들기를 함수로 받아 같은 try 안에서 부른다.
  private async notify(
    input: NotifyInput | (() => Promise<NotifyInput>),
  ): Promise<void> {
    try {
      await this.notifications.notify(
        typeof input === 'function' ? await input() : input,
      );
    } catch (error) {
      this.logger.warn(
        `오퍼 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  private termsOf(row: OfferRow) {
    return {
      format: row.format,
      rewardType: row.rewardType,
      voucherName: row.voucherName,
      voucherValue: row.voucherValue,
      perViewAmount: row.perViewAmount,
      perViewCap: row.perViewCap,
    };
  }

  private toSent(
    row: OfferRow,
    creator: NonNullable<Awaited<ReturnType<CreatorsService['getSummary']>>>,
    now: Date,
    collaborationId: string | null,
  ): SentOfferModel {
    return {
      id: row.id,
      collaborationId,
      creator,
      terms: this.termsOf(row),
      view: viewForStore(row, now),
      paymentDaysLeft: paymentDaysLeft(row, now),
      sentAt: row.createdAt.toISOString(),
    };
  }

  private toReceived(
    row: OfferRow,
    card: NonNullable<Awaited<ReturnType<typeof this.card>>>,
    now: Date,
    collaborationId: string | null,
    instagramConnected: boolean,
  ): ReceivedOfferModel {
    return {
      id: row.id,
      collaborationId,
      store: card.summary,
      storeIntro: card.intro,
      bestShootingTime: card.bestShootingTime,
      terms: this.termsOf(row),
      view: viewForCreator(row, now),
      receivedAt: row.createdAt.toISOString(),
      canUndoDecline: canUndoDecline(row, now),
      needsInstagram: needsInstagram(row, instagramConnected),
    };
  }

  private async assertRole(
    userId: string,
    role: 'CREATOR' | 'STORE',
    message: string,
  ): Promise<void> {
    if ((await this.users.getRole(userId)) !== role) {
      throw new AppError('FORBIDDEN', message);
    }
  }

  private alreadySent(): AppError {
    return new AppError('CONFLICT', '이미 보낸 오퍼가 있어요.');
  }

  private alreadyHandled(): AppError {
    return new AppError('CONFLICT', '이미 처리된 오퍼예요.');
  }

  private expired(): AppError {
    return new AppError('CONFLICT', '기한이 지난 오퍼예요.');
  }

  private notFound(): AppError {
    return new AppError('NOT_FOUND', '오퍼를 찾을 수 없어요.');
  }
}
