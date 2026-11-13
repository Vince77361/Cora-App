import { Injectable, Logger } from '@nestjs/common';
import { OfferEndReason, OfferParty, Prisma } from '@prisma/client';
import { ApplicationsService } from '../applications/applications.service';
import { scheduleSubmissionDeadlineJobs } from '../collaborations/collaboration-jobs';
import {
  initialStoreOfferState,
  storeInProgressStages,
} from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { PROPOSAL_POLICY } from '../common/collaboration-policy';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { InstagramService } from '../instagram/instagram.service';
import { JobScheduler, OfferJobPayload } from '../jobs/job-scheduler';
import {
  NotificationsService,
  NotifyInput,
} from '../notifications/notifications.service';
import { StoresService } from '../stores/stores.service';
import {
  buildTerms,
  copyOfTerms,
  defaultsOfStore,
} from '../stores/reward-terms';
import { UsersService } from '../users/users.service';
import { EndedOfferModel } from './dto/ended-offer.model';
import { OfferVersionModel } from './dto/offer-version.model';
import { ProposeVersionDto } from './dto/propose-version.dto';
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
  defaultsOfVersion,
  endStatusOf,
  partyOf,
  proposalExtras,
  termsOfVersion,
  versionModelOf,
} from './proposal-rules';
import {
  InSameTransaction,
  latestVersionOf,
  OfferRow,
  OffersRepository,
} from './offers.repository';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DAY_MS = 24 * 60 * 60 * 1000;

// 오퍼 모듈이 읽는 가게 카드(소유자, 요약, 소개).
type OfferCard = NonNullable<
  Awaited<ReturnType<StoresService['getOfferCard']>>
>;

// 거절마다 다른 키: 같은 오퍼를 되돌렸다 다시 거절해도 옛 작업과 새 작업이 서로 가리지 않는다.
const declineJobKey = (offerId: string, declinedAt: Date): string =>
  `decline:${offerId}:${declinedAt.getTime()}`;

// 판본마다 다른 키: 새 판본이 나오면 새 기한 작업이 올라가고, 옛 판본의 작업은 처리기가 건너뛴다.
const offerExpiryJobKey = (offerId: string, version: number): string =>
  `offer-expiry:${offerId}:${version}`;

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
    // 조회수 단가와 상한, 식사권, 사용권을 비우면 가게의 기본 조건으로 채운다.
    const terms = buildTerms(input, defaultsOfStore(store));

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
        terms,
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

    await this.scheduleExpiry(created.id, 1, created.expiresAt);
    await this.notify({
      userId: creator.userId,
      role: 'CREATOR',
      kind: 'OFFER_RECEIVED',
      // 오퍼는 지금 한 편짜리다(편 수를 고르는 화면이 없다).
      params: { format: terms.format, pieceCount: 1 },
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
    // 받은 제안(크리에이터가 쓴 판본이 최신)은 취소가 아니라 사유를 고르는 종료로 끝낸다.
    if (stored === 'SENT' && row.turn !== 'CREATOR') {
      throw new AppError('CONFLICT', '받은 제안은 종료로 끝내 주세요.');
    }

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

  // 답을 기다리는 오퍼와 방금 거절해 되돌릴 수 있는 오퍼. 수락한 오퍼는 협업 목록이 보여 준다.
  async listReceived(userId: string): Promise<ReceivedOfferModel[]> {
    await this.assertRole(userId, 'CREATOR', '크리에이터 계정만 쓸 수 있어요.');
    const now = this.clock.now();
    const rows = await this.settleAll(
      await this.offers.listForCreator(userId),
      now,
    );
    const shown = rows.filter(
      (row) =>
        viewForCreator(row, now) === 'WAITING' || canUndoDecline(row, now),
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

  // 크리에이터도 사장님도 수락한다(차례인 쪽만). 검사 순서: 내 오퍼(아니면 404) → 역할 → 기한 → 상태 → 판본 번호 → 차례 → 인스타그램.
  // 판본 번호는 읽은 값과 갱신 조건에 모두 걸어, 읽은 뒤 새 판본이 나오면 수락이 0행이 되게 한다.
  // 응답은 받은 오퍼 모양이다. 사장님은 응답의 collaborationId로 결제 화면에 간다.
  async accept(
    userId: string,
    id: string,
    version: number,
  ): Promise<ReceivedOfferModel> {
    const { row, card, party } = await this.requireParty(userId, id);
    const now = this.clock.now();
    const stored = storedStatusAt(row, now);
    if (stored === 'EXPIRED') {
      await this.settle(row, now);
      throw this.expired();
    }
    if (stored !== 'SENT') throw this.alreadyHandled();
    if (version !== row.latestVersion)
      throw this.staleVersion(row.latestVersion);
    // 응답할 차례가 아니면(내가 쓴 판본이 최신이면) 수락할 수 없다.
    if (row.turn !== party) throw this.notYourTurn();
    const terms = this.termsOf(row);
    // 조회수 보상은 인스타그램 연결이 있어야 정산이 조회수를 읽을 수 있다. 수락 뒤에 알게 되지 않게 여기서 막는다.
    // 사장님이 수락할 때는 판본을 낸 뒤 크리에이터가 연동을 끊었을 수 있다.
    const connected =
      (await this.instagram.getConnection(row.creatorId)) !== null;
    if (needsInstagram(terms, connected)) {
      throw new AppError(
        'CONFLICT',
        party === 'CREATOR'
          ? '인스타그램을 연동하면 수락할 수 있어요.'
          : '크리에이터가 인스타그램 연동을 끊어 지금은 수락할 수 없어요.',
      );
    }
    // 수락과 협업 만들기는 한 트랜잭션이다. 식사권만 있는 오퍼는 낼 돈이 없어 결제 기한 없이 바로 FUNDED로 시작한다.
    const initial = initialStoreOfferState(terms, now);
    const accepted = await this.offers.accept(
      row.id,
      row.creatorId,
      version,
      now,
      initial.paymentDueAt,
      async (tx) => {
        await this.collaborations.create(
          {
            kind: 'STORE_OFFER',
            stage: initial.stage,
            commissionerId: card.ownerId,
            creatorId: row.creatorId,
            offerId: row.id,
            storeId: row.storeId,
            // 수락된 판본의 조건과 번호를 그대로 사본으로 남긴다.
            terms: copyOfTerms(terms, version),
            settlementMethod: initial.settlementMethod,
            fundedAt: initial.fundedAt,
            submitDueAt: initial.submitDueAt,
            // 수락한 시각을 DB 기본값이 아니라 Clock으로 남긴다(R42).
            createdAt: now,
          },
          tx,
        );
      },
    );
    if (!accepted) {
      await this.settleLatest(row.id, now);
      // 읽은 뒤 새 판본이 나와 진 경우는 다시 읽어 STALE_VERSION으로 답한다. 그 밖(기한, 다른 요청)은 이미 처리된 오퍼다.
      const fresh = await this.offers.findById(row.id);
      if (fresh?.status === 'SENT' && fresh.latestVersion !== version) {
        throw this.staleVersion(fresh.latestVersion);
      }
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
    // 식사권만 있어 바로 FUNDED가 된 협업은 결제 사후 단계를 거치지 않으므로 제출 기한 작업(미제출 환급, 기한 알림)을 여기서 올린다.
    // 올리지 못해도 이미 저장된 수락은 유효하다(결제 기한 작업과 같게 로그만 남긴다).
    if (collaboration && initial.stage === 'FUNDED' && initial.submitDueAt) {
      try {
        await scheduleSubmissionDeadlineJobs(
          this.jobs,
          collaboration.id,
          initial.submitDueAt,
          now,
        );
      } catch (error) {
        this.logger.warn(
          `제출 기한 작업을 올리지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
    // 이미 저장된 수락은 알림 때문에 500이 되면 안 된다. 상대 이름을 읽지 못해도 알림은 기본 이름으로 보낸다.
    if (party === 'CREATOR') {
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
    } else {
      // 사장님에게는 알림 대신 응답의 collaborationId로 결제 화면에 간다. 크리에이터는 제안 상세로 보낸다.
      await this.notify({
        userId: row.creatorId,
        role: 'CREATOR',
        kind: 'OFFER_ACCEPTED_BY_STORE',
        actor: this.storeActor(card),
        target: { kind: 'PROPOSAL', id: row.id },
        dedupeKey: `offer-accepted:${row.id}`,
      });
    }
    return this.reload(row.id, card, now, collaboration);
  }

  // 새 판본을 낸다(양쪽 모두). 검사 순서: 내 오퍼(아니면 404) → 역할 → 기한 → 상태 → 차례 → 열 개 미만 → 조건 → 인스타그램.
  // 읽은 번호를 갱신 조건에 걸어, 같은 오퍼에 수락과 새 판본이 동시에 와도 하나만 이긴다.
  async proposeVersion(
    userId: string,
    id: string,
    input: ProposeVersionDto,
  ): Promise<OfferVersionModel> {
    const { row, card, party } = await this.requireParty(userId, id);
    const now = this.clock.now();
    const stored = storedStatusAt(row, now);
    if (stored === 'EXPIRED') {
      await this.settle(row, now);
      throw this.expired();
    }
    if (stored !== 'SENT') throw this.alreadyHandled();
    if (row.turn !== party) throw this.notYourTurn();
    if (row.latestVersion >= PROPOSAL_POLICY.maxVersions) {
      throw new AppError(
        'CONFLICT',
        `판본은 ${PROPOSAL_POLICY.maxVersions}개까지 낼 수 있어요.`,
      );
    }
    const terms = buildTerms(input, defaultsOfVersion(latestVersionOf(row)));
    // 조회수 수당이 켜진 판본은 크리에이터가 인스타그램을 연동해야 수락할 수 있다. 사장님의 판본은 크리에이터가 수락할 때 본다.
    if (party === 'CREATOR') {
      const connected = (await this.instagram.getConnection(userId)) !== null;
      if (needsInstagram(terms, connected)) {
        throw new AppError(
          'CONFLICT',
          '인스타그램을 연동하면 수락할 수 있어요.',
        );
      }
    }
    const expiresAt = new Date(
      now.getTime() + PROPOSAL_POLICY.responseDays * DAY_MS,
    );
    const created = await this.offers.propose({
      offerId: row.id,
      author: party,
      readVersion: row.latestVersion,
      terms,
      ...proposalExtras(party, input),
      now,
      expiresAt,
    });
    if (!created) {
      await this.settleLatest(row.id, now);
      // 읽은 뒤 수락·종료·기한 만료로 끝났거나, 같은 쪽의 다른 요청이 먼저 새 판본을 냈다.
      const fresh = await this.offers.findById(row.id);
      if (fresh?.status === 'SENT') throw this.notYourTurn();
      throw this.alreadyHandled();
    }

    await this.scheduleExpiry(row.id, created.number, expiresAt);
    // 사장님이 냈으면 크리에이터에게 "다시 보냈어요", 크리에이터가 냈으면 사장님에게 "제안했어요".
    const dedupeKey = `offer-version:${row.id}:${created.number}`;
    const target = { kind: 'PROPOSAL', id: row.id } as const;
    if (party === 'STORE') {
      await this.notify({
        userId: row.creatorId,
        role: 'CREATOR',
        kind: 'OFFER_REVISED',
        actor: this.storeActor(card),
        target,
        dedupeKey,
      });
    } else {
      await this.notify(async () => ({
        userId: card.ownerId,
        role: 'STORE',
        kind: 'OFFER_COUNTERED',
        actor: await this.actorOf(userId),
        target,
        dedupeKey,
      }));
    }
    return versionModelOf(created);
  }

  // 사유를 골라 제안을 끝낸다(양쪽 모두, 되돌릴 수 없다). 최신 판본을 쓴 쪽이 끝내면 CANCELLED, 받은 쪽이 끝내면 DECLINED다.
  async end(
    userId: string,
    id: string,
    reason: OfferEndReason,
  ): Promise<EndedOfferModel> {
    const { row, card, party } = await this.requireParty(userId, id);
    const now = this.clock.now();
    const stored = storedStatusAt(row, now);
    if (stored === 'EXPIRED') {
      await this.settle(row, now);
      throw this.expired();
    }
    if (stored !== 'SENT') throw this.alreadyHandled();
    const status = endStatusOf(party, row.turn);
    if (
      !(await this.offers.end(
        row.id,
        party,
        status,
        reason,
        row.latestVersion,
        now,
      ))
    ) {
      await this.settleLatest(row.id, now);
      throw this.alreadyHandled();
    }
    // 끝난 제안의 지원은 바로 닫는다(거절의 30초 되돌리기와 달리 되돌릴 수 없다).
    await this.closeApplication({ ...row, status });
    await this.notify(
      party === 'CREATOR'
        ? async () => ({
            userId: card.ownerId,
            role: 'STORE' as const,
            kind: 'OFFER_ENDED' as const,
            actor: await this.actorOf(userId),
            target: { kind: 'PROPOSAL' as const, id: row.id },
            dedupeKey: `offer-ended:${row.id}`,
          })
        : {
            userId: row.creatorId,
            role: 'CREATOR',
            kind: 'OFFER_ENDED',
            actor: this.storeActor(card),
            target: { kind: 'PROPOSAL', id: row.id },
            dedupeKey: `offer-ended:${row.id}`,
          },
    );
    return { id: row.id, status, endReason: reason, endedBy: party };
  }

  // 작업 큐가 판본의 응답 기한에 부른다. 최신 판본의 작업만 일한다: 그사이 새 판본이 나왔으면(번호가 다르면) 건너뛰고,
  // 수락·종료로 이미 끝났어도 건너뛴다. 읽을 때 만료와 같은 길(settle)을 쓰므로 두 번 돌아도 같다.
  async expireUnanswered(offerId: string, version: number): Promise<void> {
    const row = await this.offers.findById(offerId);
    if (row?.status !== 'SENT' || row.latestVersion !== version) return;
    await this.settle(row, this.clock.now());
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
    // 30초 되돌리기 거절은 받은 쪽(크리에이터가 답할 차례)만 쓴다. 내가 쓴 판본의 제안은 종료로 끝낸다.
    if (row.turn !== 'CREATOR') throw this.notYourTurn();
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
    return this.reload(row.id, card, now);
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
    return this.reload(row.id, card, now);
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

  // 결제를 만드는 트랜잭션이 가장 먼저 부른다(승인과 같은 오퍼 → 결제 순서). 오퍼 행을 잠가, 이 트랜잭션이 끝날
  // 때까지 취소·만료·승인이 끼어들지 못하게 한다. 이미 ACCEPTED가 아니면 false다.
  lockAcceptedForPayment(
    offerId: string,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    return this.offers.lockAccepted(offerId, tx);
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
    // 협업이 끝나 닫힌 오퍼는 ACCEPTED여도 열린 것이 아니다.
    return (
      row.status === 'SENT' ||
      (row.status === 'ACCEPTED' && row.closedAt === null) ||
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

  // 이 오퍼의 당사자(가게 사장님 또는 크리에이터)를 찾는다. 당사자가 아니면 없는 오퍼와 같게 404다.
  // 당사자이면 지금 역할이 그쪽이어야 한다(아니면 403).
  private async requireParty(
    userId: string,
    id: string,
  ): Promise<{
    row: OfferRow;
    card: OfferCard;
    party: OfferParty;
  }> {
    const row = UUID.test(id) ? await this.offers.findById(id) : null;
    const card = row ? await this.card(row.storeId) : null;
    const party = row && card ? partyOf(row, userId, card.ownerId) : null;
    if (!row || !card || !party) throw this.notFound();
    await this.assertRole(
      userId,
      party,
      party === 'STORE'
        ? '가게 계정만 쓸 수 있어요.'
        : '크리에이터 계정만 쓸 수 있어요.',
    );
    return { row, card, party };
  }

  private async reload(
    id: string,
    card: OfferCard,
    now: Date,
    // 이미 읽은 협업이 있으면 다시 읽지 않는다.
    known?: { id: string } | null,
  ): Promise<ReceivedOfferModel> {
    const fresh = await this.offers.findById(id);
    if (!fresh) throw this.notFound();
    const collaboration =
      known ?? (await this.collaborations.findByOfferId(fresh.id));
    return this.toReceived(
      fresh,
      card,
      now,
      collaboration?.id ?? null,
      (await this.instagram.getConnection(fresh.creatorId)) !== null,
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
    name: 'decline-notice' | 'payment-due-expiry' | 'offer-response-expiry',
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

  // 판본의 응답 기한 작업. 가장 새 판본의 기한마다 하나씩 올린다.
  private scheduleExpiry(
    offerId: string,
    version: number,
    runAt: Date,
  ): Promise<void> {
    return this.schedule(
      'offer-response-expiry',
      { offerId, version },
      runAt,
      offerExpiryJobKey(offerId, version),
    );
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

  // 알림에 넣을 가게. 이름은 가게 이름, 사진은 대표 사진 경로 사본이다.
  private storeActor(card: OfferCard) {
    return {
      userId: card.ownerId,
      name: card.summary.name || '가게',
      photoPath: card.coverPhotoPath,
    };
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

  // 오퍼의 조건은 가장 새 판본의 것이다.
  private termsOf(row: OfferRow) {
    return termsOfVersion(latestVersionOf(row));
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
      version: row.latestVersion,
      myTurn: storedStatusAt(row, now) === 'SENT' && row.turn === 'STORE',
      view: viewForStore(row, now),
      paymentDaysLeft: paymentDaysLeft(row, now),
      sentAt: row.createdAt.toISOString(),
    };
  }

  private toReceived(
    row: OfferRow,
    card: OfferCard,
    now: Date,
    collaborationId: string | null,
    instagramConnected: boolean,
  ): ReceivedOfferModel {
    const view = viewForCreator(row, now);
    const terms = this.termsOf(row);
    return {
      id: row.id,
      collaborationId,
      store: card.summary,
      storeIntro: card.intro,
      bestShootingTime: card.bestShootingTime,
      terms,
      version: row.latestVersion,
      myTurn: view === 'WAITING' && row.turn === 'CREATOR',
      view,
      receivedAt: row.createdAt.toISOString(),
      canUndoDecline: canUndoDecline(row, now),
      // 수락할 수 있는 오퍼(기다리는 중)에만 알린다. 이미 처리된 오퍼에는 해당이 없다.
      needsInstagram:
        view === 'WAITING' && needsInstagram(terms, instagramConnected),
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

  // 앱이 "이전 판본이라 수락할 수 없어요"를 보여 주고 최신 판본을 다시 불러오게 번호를 함께 준다.
  private staleVersion(latestVersion: number): AppError {
    return new AppError('STALE_VERSION', '이전 판본이라 수락할 수 없어요.', {
      latestVersion,
    });
  }

  private notYourTurn(): AppError {
    return new AppError('CONFLICT', '지금은 상대가 답할 차례예요.');
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
