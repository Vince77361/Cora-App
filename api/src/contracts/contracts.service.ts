import { Injectable, Logger } from '@nestjs/common';
import { Collaboration, Contract, Payment, TermsVersion } from '@prisma/client';
import { CampaignsService } from '../campaigns/campaigns.service';
import { BrandsService } from '../brands/brands.service';
import { negotiableStages } from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { securityLog } from '../common/logging/security-log';
import { ConversationsService } from '../conversations/conversations.service';
import { CreatorsService } from '../creators/creators.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PaymentCreatedModel } from '../payments/dto/payment-created.model';
import { PaymentQuoteModel } from '../payments/dto/payment-quote.model';
import { PaymentsService } from '../payments/payments.service';
import { feeFor } from '../settlements/settlement-math';
import { TermsVersionModel } from '../terms/dto/terms-version.model';
import { toTermsVersionModel } from '../terms/terms-rules';
import { TermsService } from '../terms/terms.service';
import { ConsentRole, consentTexts } from './consent-texts';
import {
  maxCashOfSnapshot,
  readSnapshot,
  snapshotOf,
} from './contract-snapshot';
import { ContractsRepository } from './contracts.repository';
import { BrandConsentDto, CreatorConsentDto } from './dto/consent.dto';
import { ContractModel } from './dto/contract.model';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const WAITING_CREATOR_MESSAGE = '크리에이터의 동의를 기다리고 있어요.';

// 계약 동의: 크리에이터가 먼저 동의하면 계약 행(AWAITING_BRAND)과 조건 사본이 생기고, 브랜드가 동의하면서 결제를 만든다.
// 계약은 결제가 승인되는 순간에야 체결된다(BrandContractPayments). 동의는 모두 협업 행을 잠근 트랜잭션 안에서 최신 판본과 단계를 다시 보고
// 판정한다: 동의와 새 판본이 엇갈려도 지난 판본에 동의한 계약이 남지 않는다.
@Injectable()
export class ContractsService {
  private readonly logger = new Logger(ContractsService.name);

  constructor(
    private readonly contracts: ContractsRepository,
    private readonly collaborations: CollaborationsRepository,
    private readonly terms: TermsService,
    private readonly payments: PaymentsService,
    private readonly campaigns: CampaignsService,
    private readonly brands: BrandsService,
    private readonly creators: CreatorsService,
    private readonly conversations: ConversationsService,
    private readonly notifications: NotificationsService,
    private readonly clock: Clock,
  ) {}

  async get(userId: string, collaborationId: string): Promise<ContractModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const isCreator = collaboration.creatorId === userId;
    const role: ConsentRole = isCreator ? 'CREATOR' : 'BRAND';
    const [live, latest] = await Promise.all([
      this.contracts.findLive(collaboration.id),
      this.terms.latest(collaboration.id),
    ]);
    const agreed =
      collaboration.stage === 'AGREED' &&
      !!latest?.brandConfirmedAt &&
      !!latest?.creatorConfirmedAt;

    let status: ContractModel['status'] = 'NOT_READY';
    let openPayment: Payment | null = null;
    if (live?.status === 'CONCLUDED') status = 'CONCLUDED';
    else if (live) {
      openPayment = await this.collaborations.findOpenPayment(
        collaboration.id,
        this.clock.now(),
      );
      status = openPayment ? 'PAYING' : 'AWAITING_BRAND';
    } else if (agreed) status = 'AWAITING_CREATOR';

    // 계약 행이 있으면 그 사본, 없으면 협의 중인 판본의 미리 보기.
    let terms: TermsVersionModel | null = null;
    if (live) terms = readSnapshot(live.termsSnapshot);
    else if (
      latest &&
      (collaboration.stage === 'MATCHED' ||
        collaboration.stage === 'NEGOTIATING' ||
        collaboration.stage === 'AGREED')
    ) {
      terms = toTermsVersionModel(
        latest,
        collaboration.commissionerId,
        await this.terms.versionBefore(collaboration.id, latest.version),
      );
    }

    const [brandName, creatorName] = await Promise.all([
      this.nameOf(collaboration.commissionerId, 'BRAND'),
      this.nameOf(collaboration.creatorId, 'CREATOR'),
    ]);
    const showQuote =
      !isCreator &&
      terms &&
      (status === 'AWAITING_BRAND' || status === 'PAYING');

    return {
      status,
      termsVersion: terms?.version ?? null,
      terms,
      brandName,
      creatorName,
      myConsentTexts: terms
        ? consentTexts(role, terms.version, terms.usageRights)
        : [],
      creatorConsentedAt: live?.creatorConsentedAt.toISOString() ?? null,
      brandConsentedAt: live?.brandConsentedAt?.toISOString() ?? null,
      concludedAt: live?.concludedAt?.toISOString() ?? null,
      // 결제 중에는 결제 행에 저장된 금액을 보여 준다: 그 뒤 수수료율 설정이 바뀌어도 결제창에 뜬 금액과 같다(Review Focus 7).
      quote:
        showQuote && terms
          ? await this.quoteFor(collaboration, terms, openPayment ?? undefined)
          : null,
      voidedNotice: await this.voidedNotice(
        collaboration,
        isCreator,
        live,
        latest,
        status,
      ),
    };
  }

  async consentAsCreator(
    userId: string,
    collaborationId: string,
    dto: CreatorConsentDto,
  ): Promise<ContractModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    if (collaboration.creatorId !== userId) {
      throw new AppError('FORBIDDEN', '크리에이터만 동의할 수 있어요.');
    }
    const actor = await this.actorOf(collaboration, userId);
    const now = this.clock.now();

    const saved = await this.terms.transaction(async (tx) => {
      await this.collaborations.lock(collaboration.id, tx);
      const { latest } = await this.requireAgreed(collaboration.id, dto, tx);
      const existing = await this.contracts.findLive(collaboration.id, tx);
      if (existing) {
        // 이미 동의했다(같은 판본): 아무것도 바꾸지 않고 같은 계약을 돌려준다(안내 줄도 알림도 다시 남기지 않는다).
        if (
          existing.status === 'AWAITING_BRAND' &&
          existing.termsVersion === latest.version
        ) {
          return {
            contract: existing,
            roomId: null,
            lineId: null,
            created: false,
          };
        }
        throw new AppError('CONFLICT', '지금은 계약에 동의할 수 없어요.');
      }
      this.assertTexts(
        dto.accepted,
        consentTexts('CREATOR', latest.version, latest.usageRights),
      );
      const snapshot = snapshotOf(
        toTermsVersionModel(
          latest,
          collaboration.commissionerId,
          await this.terms.versionBefore(collaboration.id, latest.version, tx),
        ),
      );
      const contract = await this.contracts.create(
        {
          collaborationId: collaboration.id,
          termsVersion: latest.version,
          termsSnapshot: snapshot,
          creatorConsentedAt: now,
          creatorConsentTexts: dto.accepted,
        },
        tx,
      );
      const roomId = await this.conversations.idForCollaboration(
        collaboration.id,
        tx,
      );
      const line = roomId
        ? await this.conversations.postSystem(
            roomId,
            'CREATOR_CONSENTED',
            { name: actor.name },
            tx,
          )
        : null;
      return { contract, roomId, lineId: line?.id ?? null, created: true };
    });

    if (saved.created) {
      securityLog('CONSENT_RECORDED', {
        userId,
        target: collaboration.id,
        ref: saved.contract.id,
        result: 'ALLOWED',
        reason: 'CONTRACT_CREATOR',
      });
    }
    if (saved.lineId) await this.conversations.publishCreated(saved.lineId);
    if (saved.roomId) {
      await this.conversations.publishUpdated(saved.roomId, 'CONTRACT');
    }
    if (saved.created) {
      await this.notifyCreatorConsented(collaboration, actor, saved.contract);
    }
    return this.get(userId, collaborationId);
  }

  async consentAsBrand(
    userId: string,
    collaborationId: string,
    dto: BrandConsentDto,
  ): Promise<PaymentCreatedModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    if (collaboration.commissionerId !== userId) {
      throw new AppError('FORBIDDEN', '브랜드만 동의할 수 있어요.');
    }
    const feeRate = this.payments.brandFeeRate();
    // 결제가 진행 중이면 409를 내기 전에 PG에 한 번 묻는다(가게 결제와 같은 도우미). 외부 호출이라 아래 트랜잭션(행 잠금) 밖에서 끝낸다.
    // PG가 실패로 확인하면 그 결제를 FAILED로 바꾸고 이 요청에서 새 결제로 간다. 승인이면 방금 적용했으니 새 결제 없이 409로 끝낸다.
    if (
      (await this.payments.reconcilePendingBeforeNewPayment(
        collaboration.id,
      )) === 'approved'
    ) {
      throw new AppError('CONFLICT', '지금은 계약에 동의할 수 없어요.');
    }

    const saved = await this.terms.transaction(async (tx) => {
      // 잠금 순서: 결제 → 협업 → 계약(결제 승인과 같다). 협업을 먼저 잠그면 같은 협업의 승인과 서로 기다린다.
      await this.payments.lockOpenPayments(collaboration.id, tx);
      await this.collaborations.lock(collaboration.id, tx);
      const { latest } = await this.requireAgreed(collaboration.id, dto, tx);
      const contract = await this.contracts.findLive(collaboration.id, tx);
      if (!contract) throw new AppError('CONFLICT', WAITING_CREATOR_MESSAGE);
      if (
        contract.status !== 'AWAITING_BRAND' ||
        contract.termsVersion !== latest.version
      ) {
        throw new AppError('CONFLICT', '지금은 계약에 동의할 수 없어요.');
      }
      // 결제 금액은 요청이 아니라 크리에이터가 동의한 계약 사본에서만 읽는다.
      const snapshot = readSnapshot(contract.termsSnapshot);
      this.assertTexts(
        dto.accepted,
        consentTexts('BRAND', snapshot.version, snapshot.usageRights),
      );
      const payment = await this.payments.createForContract(
        collaboration.id,
        {
          fixedCash: snapshot.fee,
          performance: snapshot.performance
            ? {
                ratePer1000: snapshot.performance.ratePer1000,
                cap: snapshot.performance.cap,
              }
            : null,
          feeRate,
          method: dto.method,
        },
        tx,
      );
      if (
        !(await this.contracts.saveBrandConsent(
          contract.id,
          dto.accepted,
          payment.id,
          this.clock.now(),
          tx,
        ))
      ) {
        throw new AppError('CONFLICT', '지금은 계약에 동의할 수 없어요.');
      }
      return {
        payment,
        roomId: await this.conversations.idForCollaboration(
          collaboration.id,
          tx,
        ),
      };
    });

    securityLog('CONSENT_RECORDED', {
      userId,
      target: collaboration.id,
      ref: saved.payment.id,
      amount: saved.payment.amountEscrow + saved.payment.amountFee,
      result: 'ALLOWED',
      reason: 'CONTRACT_BRAND',
    });
    if (saved.roomId) {
      await this.conversations.publishUpdated(saved.roomId, 'CONTRACT');
    }
    // 외부 결제창은 트랜잭션 밖에서 연다.
    const campaign = collaboration.campaignId
      ? await this.campaigns.getById(collaboration.campaignId)
      : null;
    return this.payments.openCheckout(
      saved.payment,
      `${campaign?.headline ?? '캠페인'} 제작비`,
    );
  }

  // 결제 견적의 브랜드 분기(GET /collaborations/:id/payment-quote). 계약 사본(없으면 합의한 최신 판본)에서 계산한다.
  async brandQuote(
    userId: string,
    collaborationId: string,
  ): Promise<PaymentQuoteModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    if (collaboration.commissionerId !== userId) {
      throw new AppError('NOT_FOUND', '협업을 찾을 수 없어요.');
    }
    const live = await this.contracts.findLive(collaboration.id);
    if (live?.status === 'AWAITING_BRAND') {
      // 결제 중이면 계약 화면(get)처럼 결제 행에 저장된 금액을 보여 준다: 그 뒤 수수료율 설정이 바뀌어도 결제창 금액과 같다.
      const openPayment = await this.collaborations.findOpenPayment(
        collaboration.id,
        this.clock.now(),
      );
      return this.quoteFor(
        collaboration,
        readSnapshot(live.termsSnapshot),
        openPayment ?? undefined,
      );
    }
    const latest = await this.terms.latest(collaboration.id);
    if (
      !live &&
      collaboration.stage === 'AGREED' &&
      latest?.brandConfirmedAt &&
      latest.creatorConfirmedAt
    ) {
      return this.quoteFor(
        collaboration,
        toTermsVersionModel(latest, collaboration.commissionerId, null),
      );
    }
    throw new AppError('CONFLICT', '결제할 수 있는 협업이 아니에요.');
  }

  // 결제 견적. 보관액 = 최대 현금 부담(제작비 + 성과 추가 상한), 수수료 = 보관액 × 브랜드 계약 수수료율(내림).
  // 줄 칸에는 제작비와 성과 추가 상한을 싣는다(식사권 칸은 없다).
  // payment를 주면(이미 만든 결제) 보관액·수수료·수수료율을 그 행의 값으로 쓰고 다시 계산하지 않는다.
  async quoteFor(
    collaboration: Collaboration,
    terms: TermsVersionModel,
    payment?: Pick<Payment, 'amountEscrow' | 'amountFee' | 'feeRate'>,
  ): Promise<PaymentQuoteModel> {
    const escrow = payment?.amountEscrow ?? maxCashOfSnapshot(terms);
    const feeRate = payment?.feeRate ?? this.payments.brandFeeRate();
    const fee = payment?.amountFee ?? feeFor(escrow, feeRate);
    const [campaign, creator] = await Promise.all([
      collaboration.campaignId
        ? this.campaigns.getById(collaboration.campaignId)
        : null,
      this.creators.getSummary(collaboration.creatorId),
    ]);
    return {
      escrow,
      fee,
      feeRate,
      total: escrow + fee,
      orderName: `${campaign?.headline ?? '캠페인'} 제작비`,
      creatorName: creator?.displayName ?? '크리에이터',
      creatorPhotoUrl: creator?.photoUrl ?? null,
      format: terms.format,
      pieces: terms.pieces,
      voucherName: null,
      voucherValue: null,
      voucherPeople: null,
      fixedCash: terms.fee,
      perViewCap: terms.performance?.cap ?? null,
    };
  }

  // AGREED이고 같은 최신 판본을 양쪽이 확인했을 때만 동의할 수 있다. 협업 행을 잠근 뒤에 부른다.
  // 판본 번호를 단계보다 먼저 본다: 상대가 새 판본을 내면 협업이 협의(NEGOTIATING)로 돌아가므로, 단계를 먼저 보면
  // 낡은 판본으로 동의한 요청이 STALE_VERSION(앱이 옛 판본 화면을 보여 주는 신호)이 아니라 CONFLICT로 답한다.
  private async requireAgreed(
    collaborationId: string,
    dto: { termsVersion: number },
    tx: Parameters<TermsService['latest']>[1],
  ): Promise<{ latest: TermsVersion }> {
    const fresh = await this.collaborations.findById(collaborationId, tx);
    const latest = await this.terms.latest(collaborationId, tx);
    if (!fresh || !latest) {
      throw new AppError('CONFLICT', '지금은 계약에 동의할 수 없어요.');
    }
    if (
      latest.version !== dto.termsVersion &&
      negotiableStages.includes(fresh.stage)
    ) {
      throw new AppError('STALE_VERSION', '이전 판본이라 동의할 수 없어요.', {
        latestVersion: latest.version,
      });
    }
    if (
      fresh.stage !== 'AGREED' ||
      !latest.brandConfirmedAt ||
      !latest.creatorConfirmedAt ||
      latest.version !== dto.termsVersion
    ) {
      throw new AppError('CONFLICT', '지금은 계약에 동의할 수 없어요.');
    }
    return { latest };
  }

  // 사용자가 확인한 문구가 서버가 만든 세 줄과 정확히 같아야 한다(순서까지). 동의한 문구를 그대로 계약에 저장하기 때문이다.
  private assertTexts(accepted: string[], expected: string[]): void {
    if (
      accepted.length !== expected.length ||
      accepted.some((text, index) => text !== expected[index])
    ) {
      throw new AppError(
        'VALIDATION_FAILED',
        '확인란을 모두 확인해 주세요. 화면을 새로 열어 다시 시도해 주세요.',
      );
    }
  }

  // 내 동의가 새 판본으로 취소됐고 새 계약이 아직 없다. 브랜드는 결제를 시작해 문구를 남긴 경우에만 "내 동의"가 있었다.
  private async voidedNotice(
    collaboration: Collaboration,
    isCreator: boolean,
    live: Contract | null,
    latest: TermsVersion | null,
    status: ContractModel['status'],
  ): Promise<boolean> {
    if (live || !latest) return false;
    if (status !== 'NOT_READY' && status !== 'AWAITING_CREATOR') return false;
    const voided = await this.contracts.findLatestVoidedByNewTerms(
      collaboration.id,
    );
    return (
      !!voided &&
      voided.termsVersion < latest.version &&
      (isCreator || voided.brandConsentTexts.length > 0)
    );
  }

  private async notifyCreatorConsented(
    collaboration: Collaboration,
    actor: { userId: string; name: string; photoPath: string | null },
    contract: Contract,
  ): Promise<void> {
    try {
      await this.notifications.notify({
        userId: collaboration.commissionerId,
        role: 'BRAND',
        kind: 'CREATOR_CONSENTED',
        actor,
        target: { kind: 'CONTRACT', id: collaboration.id },
        dedupeKey: `creator-consented:${contract.id}`,
      });
    } catch (error) {
      this.logger.warn(
        `크리에이터 동의 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 안내 줄과 알림에 쓰는 내 이름 사본. 못 읽으면 기본 이름으로 대신한다(동의가 되돌아가지 않게).
  private async actorOf(
    collaboration: Collaboration,
    userId: string,
  ): Promise<{ userId: string; name: string; photoPath: string | null }> {
    const byCreator = collaboration.creatorId === userId;
    try {
      const actor = byCreator
        ? await this.creators.getActor(userId)
        : await this.brands.getActor(userId);
      if (actor) return actor;
    } catch {
      // 아래 기본 이름으로 대신한다.
    }
    return {
      userId,
      name: byCreator ? '크리에이터' : '브랜드',
      photoPath: null,
    };
  }

  private async nameOf(
    userId: string,
    kind: 'BRAND' | 'CREATOR',
  ): Promise<string> {
    try {
      const actor =
        kind === 'BRAND'
          ? await this.brands.getActor(userId)
          : await this.creators.getActor(userId);
      if (actor) return actor.name;
    } catch {
      // 기본 이름으로 대신한다.
    }
    return kind === 'BRAND' ? '브랜드' : '크리에이터';
  }

  // 당사자가 아니거나 브랜드 계약이 아니면 없는 협업과 같게 404다.
  private async requireParty(
    userId: string,
    collaborationId: string,
  ): Promise<Collaboration> {
    const row = UUID.test(collaborationId)
      ? await this.collaborations.findById(collaborationId)
      : null;
    if (
      !row ||
      row.kind !== 'BRAND_CONTRACT' ||
      (row.commissionerId !== userId && row.creatorId !== userId)
    ) {
      throw new AppError('NOT_FOUND', '협업을 찾을 수 없어요.');
    }
    return row;
  }
}
