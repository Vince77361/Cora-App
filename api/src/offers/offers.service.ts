import { Injectable, Logger } from '@nestjs/common';
import { ApplicationsService } from '../applications/applications.service';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { PushPort } from '../integrations/push/push.port';
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
  OFFER_RESPONSE_DAYS,
  PAYMENT_DUE_DAYS,
  paymentDaysLeft,
  storedStatusAt,
  viewForCreator,
  viewForStore,
} from './offer-rules';
import { OfferRow, OffersRepository } from './offers.repository';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DAY_MS = 24 * 60 * 60 * 1000;

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
    private readonly push: PushPort,
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

    await this.notify(
      creator.userId,
      `${store.name ?? '가게'}에서 오퍼가 왔어요.`,
    );
    return this.toSent(created, creator, now);
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
    const items: SentOfferModel[] = [];
    rows.forEach((row, index) => {
      const creator = summaries[index];
      // 프로필이 지워진 크리에이터는 보여 줄 것이 없어 뺀다.
      if (creator) items.push(this.toSent(row, creator, now));
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
    if (!(await this.offers.cancel(row.id, store.id, stored, now))) {
      await this.settleLatest(row.id, now);
      throw this.alreadyHandled();
    }
    await this.closeApplication({ ...row, status: 'CANCELLED' });

    const fresh = await this.offers.findForStore(row.id, store.id);
    const creator = await this.creators.getSummary(row.creatorId);
    if (!fresh || !creator) throw this.notFound();
    return this.toSent(fresh, creator, now);
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
    const cards = new Map<string, Awaited<ReturnType<typeof this.card>>>();
    const items: ReceivedOfferModel[] = [];
    for (const row of shown) {
      if (!cards.has(row.storeId)) {
        cards.set(row.storeId, await this.card(row.storeId));
      }
      const card = cards.get(row.storeId);
      if (card) items.push(this.toReceived(row, card, now));
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
    const card = await this.requireCard(row.storeId);
    const accepted = await this.offers.accept(
      row.id,
      userId,
      now,
      new Date(now.getTime() + PAYMENT_DUE_DAYS * DAY_MS),
    );
    if (!accepted) {
      await this.settleLatest(row.id, now);
      throw this.alreadyHandled();
    }

    const creator = await this.creators.getSummary(userId);
    await this.notify(
      card.ownerId,
      `${creator?.displayName ?? '크리에이터'}님이 오퍼를 수락했어요.`,
    );
    return this.reload(userId, row.id, card, now);
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
    return this.reload(userId, row.id, card, now);
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
      inProgress: views.filter((view) => view === 'ACCEPTED').length,
    };
  }

  // 저장된 상태가 지금 시각의 상태와 다르면 그 자리에서 저장하고(조건부), 끝난 오퍼의 지원을 닫는다.
  // 경쟁으로 갱신이 0행이면 무시하고 다시 읽은 값을 쓴다. 지워졌으면 null.
  private async settle(row: OfferRow, now: Date): Promise<OfferRow | null> {
    let current: OfferRow | null = row;
    const target = storedStatusAt(row, now);
    if (target !== row.status) {
      current = (await this.offers.expire(row.id, row.status))
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
  ): Promise<ReceivedOfferModel> {
    const fresh = await this.offers.findForCreator(id, userId);
    if (!fresh) throw this.notFound();
    return this.toReceived(fresh, card, now);
  }

  private card(storeId: string) {
    return this.stores.getOfferCard(storeId);
  }

  private async requireCard(storeId: string) {
    const card = await this.card(storeId);
    if (!card) throw this.notFound();
    return card;
  }

  // 알림이 실패해도 이미 저장된 변경은 유효하다. 목록에서 볼 수 있다.
  private async notify(userId: string, body: string): Promise<void> {
    try {
      await this.push.send({ userId, title: 'Cora', body });
    } catch (error) {
      this.logger.warn(
        `오퍼 알림을 보내지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
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
  ): SentOfferModel {
    return {
      id: row.id,
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
  ): ReceivedOfferModel {
    return {
      id: row.id,
      store: card.summary,
      storeIntro: card.intro,
      bestShootingTime: card.bestShootingTime,
      terms: this.termsOf(row),
      view: viewForCreator(row, now),
      receivedAt: row.createdAt.toISOString(),
      canUndoDecline: canUndoDecline(row, now),
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
