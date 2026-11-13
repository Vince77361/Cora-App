import { Injectable, Logger } from '@nestjs/common';
import {
  Collaboration,
  EvidenceSource,
  Prisma,
  SettlementConfirmer,
} from '@prisma/client';
import {
  CollaborationPatch,
  CollaborationsRepository,
} from '../collaborations/collaborations.repository';
import { VIEW_REPORT_POLICY } from '../common/collaboration-policy';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { StoragePort } from '../integrations/storage/storage.port';
import { JobRunContext, JobScheduler } from '../jobs/job-scheduler';
import { postingsForSettlement } from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { hasViewPay, readTerms } from '../stores/reward-terms';
import { UploadsService } from '../uploads/uploads.service';
import { UsersService } from '../users/users.service';
import { assertEscrowMatches } from './escrow-check';
import {
  autoConfirmJobKey,
  disputeDedupeKey,
  evidenceHaltJobKey,
  evidenceRequestDedupeKey,
  SETTLEMENT_DISPUTED_HALT_REASON,
  settleJobKey,
  settlePayoutKey,
  settleRefundKey,
  SNAPSHOT_DAYS,
  viewReportDedupeKey,
} from './job-keys';
import { PayoutsService } from './payouts.service';
import { RefundsService } from './refunds.service';
import { SettlementFinishService } from './settlement-finish.service';
import { pickFinalViews, settleReward } from './settlement-math';
import {
  CorrectedCalculation,
  NewSettlement,
  SettlementsRepository,
} from './settlements.repository';
import { isViewCountUnreadable } from './unreadable-rule';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;
// 캡처 이미지를 읽는 서명 주소의 기한(초). 화면을 열 때마다 새로 만들어 준다.
const EVIDENCE_URL_TTL_SECONDS = 10 * 60;

export type ViewReportStatus =
  'COUNTING' | 'UNCONFIRMED' | 'CONFIRMED' | 'DISPUTED';
export type ViewReportSource =
  'CONNECTED_ACCOUNT' | 'CAPTURE_PENDING' | 'CAPTURE_CONFIRMED';

// 조회 자료 확인 화면(F4)이 읽는 값. 컨트롤러의 응답 모델(ViewReportModel)과 같은 모양이다.
export interface ViewReportView {
  status: ViewReportStatus;
  views: number | null;
  postUrl: string;
  periodStart: string;
  periodEnd: string;
  source: ViewReportSource;
  calc: {
    viewPay: number;
    ratePerThousand: number;
    cap: number;
    capApplied: boolean;
    fixedCash: number;
    refund: number;
    payout: number;
  } | null;
  confirmDueAt: string | null;
  canConfirm: boolean;
  canDispute: boolean;
  canUploadEvidence: boolean;
  evidence: { imageUrl: string; statedViews: number } | null;
}

// 조회수 수당이 있는 협업의 "계산 만들기 → 확인 → 확정" 가운데 계산과 확인을 맡는다.
// 협업의 종류(가게 오퍼, 브랜드 계약)를 가정하지 않는다: 측정 기간의 끝은 협업의 countingEndsAt에서, 조건은 readTerms로,
// 맡기는 쪽 알림의 역할은 그 사람의 지금 역할로 읽고, 단계 전이는 COUNTING인 것만 본다.
// 잠금 순서: 정산 행이 이미 있는 길(확인)은 정산 행 → 협업, 정산 행이 아직 없는 길(계산 만들기)은 오퍼 → 협업이다.
@Injectable()
export class ViewReportService {
  private readonly logger = new Logger(ViewReportService.name);

  constructor(
    private readonly repository: SettlementsRepository,
    private readonly collaborations: CollaborationsRepository,
    private readonly ledger: LedgerService,
    private readonly payouts: PayoutsService,
    private readonly refunds: RefundsService,
    private readonly finisher: SettlementFinishService,
    private readonly notifications: NotificationsService,
    private readonly users: UsersService,
    private readonly jobs: JobScheduler,
    private readonly clock: Clock,
    private readonly operatorAlert: OperatorAlertPort,
    private readonly storage: StoragePort,
    private readonly uploads: UploadsService,
  ) {}

  // 측정 기간이 끝났을 때 계산을 만든다: 정산 행을 UNCONFIRMED로 만들기만 한다. 장부, 단계, 지급·환급 행은 건드리지 않는다.
  // capture를 주면 연결 계정이 아니라 크리에이터의 캡처 조회수로 계산한다(자료 출처 CAPTURE, 자동 확인 없음).
  // 이미 계산이 있으면 'exists', 협업이 없거나 COUNTING이 아니면(그사이 멈춤·취소) 'gone'이다.
  async createCalculation(
    collaborationId: string,
    capture?: { statedViews: number },
  ): Promise<'created' | 'exists' | 'gone'> {
    const collaboration = await this.collaborations.findById(collaborationId);
    if (!collaboration) return 'gone';
    const views = capture
      ? capture.statedViews
      : pickFinalViews(
          await this.repository.listSnapshots(collaborationId),
          lastDayOf(collaboration),
        );
    // 읽은 값이 하나도 없으면 0으로 계산하지 않는다(호출한 쪽이 먼저 멈춘다).
    if (views === null) throw new Error('읽은 조회수가 없어 계산할 수 없어요.');
    const row = this.calculationRow(
      collaboration,
      views,
      capture ? 'CAPTURE' : 'CONNECTED_ACCOUNT',
    );
    return this.repository.transaction<'created', 'exists' | 'gone'>(
      async (tx, rollback) => {
        if (!(await this.repository.lockCollaboration(collaborationId, tx))) {
          return rollback('gone');
        }
        const fresh = await this.collaborations.findById(collaborationId, tx);
        if (fresh?.stage !== 'COUNTING') return rollback('gone');
        const created = await this.repository.createSettlement(row, tx);
        return created ? 'created' : rollback('exists');
      },
    );
  }

  // 조건과 조회수로 계산 행(UNCONFIRMED)을 만든다. 연결 계정 자료는 확인 기한(48시간)을 두고, 캡처 자료는 운영 명령만 확정하므로 기한이 없다.
  private calculationRow(
    collaboration: Collaboration,
    views: number,
    source: EvidenceSource,
  ): NewSettlement {
    const terms = readTerms(collaboration.terms);
    if (
      terms.viewRatePerThousand === null ||
      terms.perViewCap === null ||
      !hasViewPay(terms)
    ) {
      throw new Error('조회수 수당이 없는 협업은 계산을 만들지 않아요.');
    }
    const { viewPay, payout, refund } = settleReward({
      views,
      ratePerThousand: terms.viewRatePerThousand,
      cap: terms.perViewCap,
      fixedCash: terms.fixedCash,
    });
    const now = this.clock.now();
    return {
      collaborationId: collaboration.id,
      finalViews: views,
      payoutAmount: payout,
      refundAmount: refund,
      fixedCashAmount: terms.fixedCash,
      viewPayAmount: viewPay,
      status: 'UNCONFIRMED',
      calculatedAt: now,
      confirmDueAt:
        source === 'CAPTURE'
          ? null
          : new Date(now.getTime() + VIEW_REPORT_POLICY.confirmHours * HOUR_MS),
      settledAt: null,
      confirmedAt: null,
      confirmedBy: null,
      evidenceSource: source,
    };
  }

  // 계산이 만들어진 뒤의 단계: 사장님에게 확인을, 크리에이터에게 계산을 알리고, 연결 계정 자료는 자동 확인 작업을 확인 기한에 올린다.
  // 캡처 자료는 운영자만 확정하므로 자동 확인 작업을 올리지 않고 운영자에게 알린다.
  // 모두 같은 키라 다시 불러도 한 번만 일어난다(작업이 커밋 뒤에 죽어도 다시 돌 때 이어서 한다).
  // 그사이 협업이 멈췄다면(운영자의 멈춤, 이의) 알리지 않는다.
  async announceCalculation(collaborationId: string): Promise<void> {
    const collaboration = await this.collaborations.findById(collaborationId);
    const settlement = collaboration
      ? await this.repository.findSettlement(collaborationId)
      : null;
    if (
      !collaboration ||
      !settlement ||
      settlement.status !== 'UNCONFIRMED' ||
      collaboration.stage !== 'COUNTING'
    ) {
      return;
    }
    const fromCapture = settlement.evidenceSource === 'CAPTURE';
    if (!fromCapture) {
      if (!settlement.confirmDueAt) return;
      await this.jobs.schedule(
        'settlement-auto-confirm',
        { collaborationId },
        settlement.confirmDueAt,
        autoConfirmJobKey(collaborationId),
      );
    }
    const target = { kind: 'VIEW_REPORT', id: collaborationId } as const;
    const dedupeKey = viewReportDedupeKey(collaborationId);
    await this.notifications.notify({
      userId: collaboration.commissionerId,
      role: await this.commissionerRole(collaboration),
      kind: 'VIEW_REPORT_REQUESTED',
      target,
      dedupeKey,
    });
    await this.notifications.notify({
      userId: collaboration.creatorId,
      role: 'CREATOR',
      kind: 'VIEW_REPORT_READY',
      target,
      dedupeKey,
    });
    if (fromCapture) {
      await this.operatorAlert.alert({
        subject: '조회수 캡처가 제출됐어요. 확인해 주세요.',
        body: `협업 ID: ${collaborationId}`,
      });
    }
  }

  // 크리에이터에게 인사이트 캡처를 올려 달라고 알린다(같은 키라 한 번만). 조회수를 연속 3일 읽지 못했을 때 부른다.
  async requestEvidence(collaboration: Collaboration): Promise<void> {
    await this.notifications.notify({
      userId: collaboration.creatorId,
      role: 'CREATOR',
      kind: 'VIEW_EVIDENCE_REQUESTED',
      target: { kind: 'VIEW_REPORT', id: collaboration.id },
      dedupeKey: evidenceRequestDedupeKey(collaboration.id),
    });
  }

  // 맡기는 쪽 알림의 역할은 그 사람의 지금 역할이다(가게 사장님 STORE, 브랜드 BRAND).
  private async commissionerRole(
    collaboration: Collaboration,
  ): Promise<'STORE' | 'BRAND'> {
    const role = await this.users.getRole(collaboration.commissionerId);
    return role === 'BRAND' ? 'BRAND' : 'STORE';
  }

  // 확인 완료: 한 트랜잭션에서 정산 행 UNCONFIRMED → CONFIRMED(조건부) → 협업 COUNTING → SETTLED → 에스크로 잔액 검사 →
  // 장부(key) → 지급·환급 행. 협업이 그사이 COUNTING이 아니게 됐다면(운영자가 멈춤) 정산 행 변경까지 전부 되돌린다.
  // 같은 키라 사장님 확인과 자동 확인이 겹쳐도 한 번이고, 진 쪽은 'lost'다. 이긴 쪽만 커밋 뒤 단계(지급 작업, 알림, PG 환급)를 한다.
  // onlySource를 주면 그 자료 출처의 계산만 확인한다(사장님·자동 확인은 연결 계정 자료만).
  async confirm(
    collaborationId: string,
    by: SettlementConfirmer,
    key: string,
    options: { onlySource?: EvidenceSource; context?: JobRunContext } = {},
  ): Promise<'confirmed' | 'lost'> {
    const outcome = await this.commitConfirmation(
      collaborationId,
      by,
      key,
      options,
    );
    if (outcome === 'confirmed') {
      await this.finisher.finishOf(collaborationId, undefined, options.context);
    }
    return outcome;
  }

  // 자동 확인 작업(settlement-auto-confirm)의 몸: 연결 계정 자료의 계산만 자동으로 확인한다. 그 밖에는 아무 일도 하지 않는다.
  // 이미 확인된 정산은 커밋 뒤 단계를 이어서 한다(확인한 요청이 그 단계 전에 죽었을 수 있다. 모두 같은 키라 한 번씩만 일어난다).
  async autoConfirm(
    collaborationId: string,
    context?: JobRunContext,
  ): Promise<void> {
    const settlement = await this.repository.findSettlement(collaborationId);
    if (!settlement) return;
    if (
      settlement.status === 'UNCONFIRMED' &&
      settlement.evidenceSource === 'CONNECTED_ACCOUNT'
    ) {
      await this.confirm(
        collaborationId,
        'AUTO',
        settleJobKey(collaborationId),
        { onlySource: 'CONNECTED_ACCOUNT', context },
      );
    } else if (settlement.status === 'CONFIRMED') {
      await this.finisher.finishOf(collaborationId, undefined, context);
    }
  }

  // 사장님(맡기는 쪽)이 "자료 확인했어요"를 누른다. 크리에이터는 403, 남의 협업은 404, 확인할 수 없는 상태는 409다.
  async confirmByCommissioner(
    userId: string,
    collaborationId: string,
  ): Promise<ViewReportView> {
    const collaboration = await this.requireParty(userId, collaborationId);
    if (collaboration.commissionerId !== userId) {
      throw new AppError('FORBIDDEN', '맡긴 쪽만 자료를 확인할 수 있어요.');
    }
    const settlement = await this.repository.findSettlement(collaborationId);
    if (!canConfirm(collaboration, settlement, userId)) {
      throw this.cannotConfirm();
    }
    const outcome = await this.commitConfirmation(
      collaborationId,
      'COMMISSIONER',
      settleJobKey(collaborationId),
      { onlySource: 'CONNECTED_ACCOUNT' },
    );
    if (outcome === 'confirmed') {
      // 돈은 이미 옮겨졌다: 커밋 뒤 단계가 실패해도 확인은 유효하고, 자동 확인 작업이 때가 되면 이어서 한다.
      try {
        await this.finisher.finishOf(collaborationId);
      } catch (error) {
        this.logger.error(
          `확인 뒤 정산 단계를 마치지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
    const view = await this.get(userId, collaborationId);
    // 자동 확인이 먼저 이겼다면 원하던 결과이니 그대로 보여 준다. 그 밖에 확인되지 않았다면 409다.
    if (outcome === 'lost' && view.status !== 'CONFIRMED') {
      throw this.cannotConfirm();
    }
    return view;
  }

  // GET /collaborations/:id/view-report. 당사자만 읽는다(아니면 404).
  // 조회수 수당이 없는 협업, 링크 제출 전, 집계 중도 정산도 아닌 단계의 협업은 보여 줄 것이 없어 404다.
  async get(userId: string, collaborationId: string): Promise<ViewReportView> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const terms = readTerms(collaboration.terms);
    if (
      !hasViewPay(terms) ||
      !collaboration.submittedUrl ||
      !collaboration.submittedAt
    ) {
      throw this.notFound();
    }
    const settlement = await this.repository.findSettlement(collaborationId);
    // 정산 행이 없으면 측정 중이다. 조회수를 읽지 못해 멈춘 협업(HALTED)도 정산 행이 없어 "집계 중"이다.
    if (
      !settlement &&
      collaboration.stage !== 'COUNTING' &&
      collaboration.stage !== 'HALTED'
    ) {
      throw this.notFound();
    }
    const views = settlement
      ? settlement.finalViews
      : ((await this.repository.latestViewsFor([collaborationId])).get(
          collaborationId,
        ) ?? null);
    const periodEnd = collaboration.countingEndsAt;
    const evidence = await this.repository.findEvidence(collaborationId);
    const canUploadEvidence =
      !evidence &&
      collaboration.creatorId === userId &&
      (await this.isEvidenceOpen(collaboration, settlement));
    return {
      status: settlement ? settlement.status : 'COUNTING',
      views,
      postUrl: collaboration.submittedUrl,
      periodStart: collaboration.submittedAt.toISOString(),
      periodEnd: (
        periodEnd ??
        new Date(collaboration.submittedAt.getTime() + SNAPSHOT_DAYS * DAY_MS)
      ).toISOString(),
      source: settlement
        ? settlement.evidenceSource === 'CAPTURE'
          ? settlement.status === 'CONFIRMED'
            ? 'CAPTURE_CONFIRMED'
            : 'CAPTURE_PENDING'
          : 'CONNECTED_ACCOUNT'
        : 'CONNECTED_ACCOUNT',
      calc:
        settlement &&
        terms.viewRatePerThousand !== null &&
        terms.perViewCap !== null
          ? {
              viewPay: settlement.viewPayAmount,
              ratePerThousand: terms.viewRatePerThousand,
              cap: terms.perViewCap,
              capApplied:
                settlement.finalViews !== null &&
                settleReward({
                  views: settlement.finalViews,
                  ratePerThousand: terms.viewRatePerThousand,
                  cap: terms.perViewCap,
                  fixedCash: terms.fixedCash,
                }).capApplied,
              fixedCash: settlement.fixedCashAmount,
              refund: settlement.refundAmount,
              payout: settlement.payoutAmount,
            }
          : null,
      confirmDueAt:
        settlement?.status === 'UNCONFIRMED'
          ? (settlement.confirmDueAt?.toISOString() ?? null)
          : null,
      canConfirm: canConfirm(collaboration, settlement, userId),
      canDispute: canDispute(collaboration, settlement),
      canUploadEvidence,
      evidence: evidence
        ? {
            // 비공개 버킷의 파일이라 화면을 열 때마다 당사자에게만 기한이 있는 주소를 새로 서명해 준다.
            imageUrl: await this.storage.signedReadUrl(
              evidence.filePath,
              EVIDENCE_URL_TTL_SECONDS,
            ),
            statedViews: evidence.statedViews,
          }
        : null,
    };
  }

  // 커밋 부분만. 졌거나(다른 확인이 먼저, 이의, 운영자의 멈춤) 되돌렸으면 'lost'다.
  private commitConfirmation(
    collaborationId: string,
    by: SettlementConfirmer,
    key: string,
    options: { onlySource?: EvidenceSource },
  ): Promise<'confirmed' | 'lost'> {
    return this.repository.transaction<'confirmed', 'lost'>(
      async (tx, rollback) => {
        const settled = await this.settleCalculation(tx, collaborationId, {
          by,
          key,
          fromStatus: 'UNCONFIRMED',
          fromStage: 'COUNTING',
          onlySource: options.onlySource,
        });
        // 협업이 그사이 COUNTING이 아니게 됐다면 정산 행 변경까지 전부 되돌린다(돈은 그대로 보관된다).
        return settled ? 'confirmed' : rollback('lost');
      },
    );
  }

  // 정산 행 확인 완료 → 협업 이동 → 에스크로 잔액 검사 → 장부(key) → 지급·환급 행을 호출한 쪽의 트랜잭션 안에서 한다.
  // 사장님·자동 확인(UNCONFIRMED, COUNTING)과 운영 명령(캡처 확정은 UNCONFIRMED, 이의 처리는 DISPUTED·HALTED)이 같은 길을 쓴다.
  // 졌으면(정산 행이 그 상태가 아니거나 협업이 그 단계가 아님) false다: 호출한 쪽이 반드시 트랜잭션을 되돌려야 한다(정산 행만 바뀐 채 남지 않게).
  // correctedViews를 주면 그 조회수로 다시 계산한 금액을 정산 행에 쓴다(이의 처리). 지급 + 환급은 늘 고정 현금 + 상한이라 에스크로 잔액이 0이 된다.
  async settleCalculation(
    tx: Prisma.TransactionClient,
    collaborationId: string,
    p: {
      by: SettlementConfirmer;
      key: string;
      fromStatus: 'UNCONFIRMED' | 'DISPUTED';
      fromStage: 'COUNTING' | 'HALTED';
      onlySource?: EvidenceSource;
      patch?: CollaborationPatch;
      correctedViews?: number;
    },
  ): Promise<boolean> {
    const now = this.clock.now();
    const before = await this.collaborations.findById(collaborationId, tx);
    if (!before) throw new Error('확인한 정산의 협업을 찾을 수 없어요.');
    const corrected =
      p.correctedViews === undefined
        ? undefined
        : this.correctedCalculation(before, p.correctedViews);
    // 이 갱신이 정산 행을 먼저 잠근다(정산 행 → 협업).
    if (
      !(await this.repository.confirmCalculation(
        collaborationId,
        p.by,
        now,
        { from: p.fromStatus, onlySource: p.onlySource, corrected },
        tx,
      ))
    ) {
      return false;
    }
    const settlement = await this.repository.findSettlement(
      collaborationId,
      tx,
    );
    const collaboration = await this.collaborations.findById(
      collaborationId,
      tx,
    );
    if (!settlement || !collaboration) {
      throw new Error('확인한 정산의 협업을 찾을 수 없어요.');
    }
    if (
      !(await this.collaborations.advance(
        collaborationId,
        p.fromStage,
        'SETTLED',
        p.patch ?? {},
        tx,
      ))
    ) {
      return false;
    }
    const escrow = await this.ledger.escrowBalance(collaborationId, tx);
    assertEscrowMatches(readTerms(collaboration.terms), escrow);
    if (settlement.payoutAmount + settlement.refundAmount !== escrow) {
      throw new Error(
        `정산 금액(${settlement.payoutAmount + settlement.refundAmount})이 에스크로 잔액(${escrow})과 달라요.`,
      );
    }
    const posted = await this.ledger.post(
      collaborationId,
      postingsForSettlement({
        payout: settlement.payoutAmount,
        refund: settlement.refundAmount,
      }),
      p.key,
      tx,
    );
    if (posted === 'duplicate') {
      // 확인 전인 협업에 정산 장부가 이미 있다면 상태가 어긋난 것이다. 조용히 넘기지 않고 되돌려 드러낸다.
      throw new Error('확인 전인 정산에 정산 장부 줄이 이미 있어요.');
    }
    await this.payouts.request(
      collaborationId,
      settlement.payoutAmount,
      settlePayoutKey(collaborationId),
      now,
      tx,
    );
    await this.refunds.request(
      collaborationId,
      settlement.refundAmount,
      settleRefundKey(collaborationId),
      tx,
    );
    return true;
  }

  // 운영자가 고친 조회수로 다시 계산한 금액. 조건 사본(고정 현금, 단가, 상한)을 쓰고 상한은 에스크로 잔액이 아니라 조건의 값이다.
  private correctedCalculation(
    collaboration: Collaboration,
    views: number,
  ): CorrectedCalculation {
    const row = this.calculationRow(collaboration, views, 'CONNECTED_ACCOUNT');
    return {
      finalViews: views,
      payoutAmount: row.payoutAmount,
      refundAmount: row.refundAmount,
      fixedCashAmount: row.fixedCashAmount,
      viewPayAmount: row.viewPayAmount,
    };
  }

  // 이의 제기. 당사자 누구나 확인 전(UNCONFIRMED)인 계산에 한 번 낼 수 있다. 한 트랜잭션에서 정산 행 UNCONFIRMED → DISPUTED(조건부)
  // → 이의 행 → 협업 COUNTING → HALTED를 하고, 돈은 에스크로에 그대로 둔다. 자동 확인과 겹치면 하나만 이긴다(진 쪽은 409 또는 'lost').
  // 커밋 뒤: 자동 확인 작업 취소, 운영자 알림(사유 글은 넣지 않는다), 상대에게 알림. 실패해도 이의는 이미 유효하니 로그만 남긴다.
  async dispute(
    userId: string,
    collaborationId: string,
    reasonInput: string,
  ): Promise<ViewReportView> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const reason = reasonInput.trim();
    if (
      reason.length < 1 ||
      reason.length > VIEW_REPORT_POLICY.disputeReasonMax
    ) {
      throw new AppError(
        'VALIDATION_FAILED',
        `사유는 1자 이상 ${VIEW_REPORT_POLICY.disputeReasonMax}자 이하로 적어 주세요.`,
      );
    }
    const settlement = await this.repository.findSettlement(collaborationId);
    if (!canDispute(collaboration, settlement)) throw this.cannotDispute();
    const outcome = await this.repository.transaction<'disputed', 'lost'>(
      async (tx, rollback) => {
        // 이 갱신이 정산 행을 먼저 잠근다(정산 행 → 협업).
        if (!(await this.repository.disputeCalculation(collaborationId, tx))) {
          return rollback('lost');
        }
        if (
          !(await this.repository.createDispute(
            { collaborationId, raisedById: userId, reason },
            tx,
          ))
        ) {
          return rollback('lost');
        }
        // 운영자가 그사이 멈췄다면 정산 행 변경까지 되돌린다.
        if (
          !(await this.collaborations.advance(
            collaborationId,
            'COUNTING',
            'HALTED',
            {
              stageBeforeHalt: 'COUNTING',
              haltedReason: SETTLEMENT_DISPUTED_HALT_REASON,
            },
            tx,
          ))
        ) {
          return rollback('lost');
        }
        return 'disputed';
      },
    );
    if (outcome === 'lost') throw this.cannotDispute();
    await this.afterDispute(collaboration, userId);
    return this.get(userId, collaborationId);
  }

  private async afterDispute(
    collaboration: Collaboration,
    raisedById: string,
  ): Promise<void> {
    const steps: [string, () => Promise<void>][] = [
      [
        '자동 확인 작업 취소',
        () => this.jobs.cancel(autoConfirmJobKey(collaboration.id)),
      ],
      [
        '운영자 알림',
        () =>
          this.operatorAlert.alert({
            subject: '조회 자료에 이의가 제기됐어요. 확인해 주세요.',
            body: `협업 ID: ${collaboration.id}`,
          }),
      ],
      [
        '상대에게 알림',
        async () => {
          const toCommissioner = raisedById !== collaboration.commissionerId;
          await this.notifications.notify({
            userId: toCommissioner
              ? collaboration.commissionerId
              : collaboration.creatorId,
            role: toCommissioner
              ? await this.commissionerRole(collaboration)
              : 'CREATOR',
            kind: 'VIEW_REPORT_DISPUTED',
            target: { kind: 'VIEW_REPORT', id: collaboration.id },
            dedupeKey: disputeDedupeKey(collaboration.id),
          });
        },
      ],
    ];
    for (const [label, run] of steps) {
      try {
        await run();
      } catch (error) {
        this.logger.error(
          `이의 제기 뒤 ${label}에 실패했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
  }

  // 크리에이터가 조회수 인사이트 캡처와 그 조회수를 낸다. 협업당 한 번, 캡처가 요청된 때(조회수를 연속 3일 읽지 못했고 정산 행이 아직 없을 때)만 받는다.
  // 측정 기간이 이미 끝났다면 같은 트랜잭션에서 캡처의 조회수로 계산을 만든다(자료 출처 CAPTURE, 자동 확인 없음 — 운영 명령만 확정한다).
  // 기간이 아직 남았다면 캡처만 저장하고, 기간이 끝나는 날의 정산 작업이 그 값을 쓴다.
  async submitEvidence(
    userId: string,
    collaborationId: string,
    input: { path: string; views: number },
  ): Promise<ViewReportView> {
    const collaboration = await this.requireParty(userId, collaborationId);
    if (collaboration.creatorId !== userId) {
      throw new AppError('FORBIDDEN', '크리에이터만 캡처를 올릴 수 있어요.');
    }
    // 남의 경로나 임의 경로를 끼워 넣지 못하게 한다(서버가 발급한 내 폴더의 파일 이름만 받는다).
    this.uploads.assertOwnedPath(userId, input.path, 'VIEW_EVIDENCE');
    if (!Number.isInteger(input.views) || input.views < 0) {
      throw new AppError(
        'VALIDATION_FAILED',
        '조회수는 0 이상의 정수여야 해요.',
      );
    }
    const terms = readTerms(collaboration.terms);
    if (!hasViewPay(terms) || !collaboration.submittedAt) {
      throw this.notFound();
    }
    const now = this.clock.now();
    const calculated = await this.repository.transaction<boolean, 'closed'>(
      async (tx, rollback) => {
        if (!(await this.repository.lockCollaboration(collaborationId, tx))) {
          return rollback('closed');
        }
        const fresh = await this.collaborations.findById(collaborationId, tx);
        const settlement = await this.repository.findSettlement(
          collaborationId,
          tx,
        );
        const evidence = await this.repository.findEvidence(
          collaborationId,
          tx,
        );
        if (
          !fresh ||
          evidence ||
          !(await this.isEvidenceOpen(fresh, settlement, tx))
        ) {
          return rollback('closed');
        }
        await this.repository.createEvidence(
          {
            collaborationId,
            filePath: input.path,
            statedViews: input.views,
            submittedById: userId,
          },
          tx,
        );
        const periodOver =
          fresh.countingEndsAt !== null &&
          fresh.countingEndsAt.getTime() <= now.getTime();
        if (!periodOver) return false;
        return this.repository.createSettlement(
          this.calculationRow(fresh, input.views, 'CAPTURE'),
          tx,
        );
      },
    );
    if (calculated === 'closed') throw this.cannotUploadEvidence();
    if (calculated) {
      try {
        await this.jobs.cancel(evidenceHaltJobKey(collaborationId));
        await this.announceCalculation(collaborationId);
      } catch (error) {
        // 계산과 캡처는 이미 커밋됐다. 알림만 놓친 것이라 로그를 남기고 운영자가 show로 확인한다.
        this.logger.error(
          `캡처 계산 뒤 알림에 실패했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
    return this.get(userId, collaborationId);
  }

  // 캡처를 받을 수 있는 때: 협업이 집계 중(COUNTING)이고 정산 행이 아직 없으며 조회수를 연속 3일 읽지 못했을 때다.
  // 측정 기간이 끝났다면 5~7일을 날로 세는 판정까지 쓴다(정산 작업과 같은 규칙).
  private async isEvidenceOpen(
    collaboration: Collaboration,
    settlement: { id: string } | null,
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    if (settlement || collaboration.stage !== 'COUNTING') return false;
    const periodOver =
      collaboration.countingEndsAt !== null &&
      collaboration.countingEndsAt.getTime() <= this.clock.now().getTime();
    return isViewCountUnreadable(
      await this.repository.listSnapshots(collaboration.id, tx),
      { atSettlement: periodOver },
    );
  }

  private async requireParty(
    userId: string,
    collaborationId: string,
  ): Promise<Collaboration> {
    const row = UUID.test(collaborationId)
      ? await this.collaborations.findById(collaborationId)
      : null;
    if (!row || (row.commissionerId !== userId && row.creatorId !== userId)) {
      throw this.notFound();
    }
    return row;
  }

  private notFound(): AppError {
    return new AppError('NOT_FOUND', '조회 자료를 찾을 수 없어요.');
  }

  private cannotConfirm(): AppError {
    return new AppError('CONFLICT', '지금은 자료를 확인할 수 없어요.');
  }

  private cannotDispute(): AppError {
    return new AppError('CONFLICT', '지금은 이의를 제기할 수 없어요.');
  }

  private cannotUploadEvidence(): AppError {
    return new AppError('CONFLICT', '지금은 캡처를 올릴 수 없어요.');
  }
}

// 이의를 낼 수 있을 때: 계산이 확인 전(UNCONFIRMED)이고 협업이 집계 중(COUNTING)일 때다(당사자 누구나, 캡처 자료도 포함).
// 한 사람이 한 번이라는 규칙은 이의가 정산 행을 DISPUTED로 바꾸는 것으로 이미 지켜진다(DISPUTED가 되면 다시 낼 수 없다).
function canDispute(
  collaboration: Collaboration,
  settlement: { status: string } | null,
): boolean {
  return (
    collaboration.stage === 'COUNTING' && settlement?.status === 'UNCONFIRMED'
  );
}

// 확인할 수 있는 사람: 맡기는 쪽이고, 계산이 확인 전이며, 자료가 연결 계정에서 읽은 것일 때만이다(캡처 자료는 운영 명령만 확정한다).
// 협업이 COUNTING이 아니면(운영자가 멈춤) 확인해도 정산되지 않으므로 누를 수 없다.
function canConfirm(
  collaboration: Collaboration,
  settlement: { status: string; evidenceSource: string } | null,
  userId: string,
): boolean {
  return (
    collaboration.commissionerId === userId &&
    collaboration.stage === 'COUNTING' &&
    settlement?.status === 'UNCONFIRMED' &&
    settlement.evidenceSource === 'CONNECTED_ACCOUNT'
  );
}

// 측정 기간의 마지막 날 번호(제출한 날부터 센 날수). 협업의 countingEndsAt에서 읽는다(7일이든 14일이든).
function lastDayOf(collaboration: Collaboration): number {
  if (!collaboration.submittedAt || !collaboration.countingEndsAt) {
    return SNAPSHOT_DAYS;
  }
  return Math.round(
    (collaboration.countingEndsAt.getTime() -
      collaboration.submittedAt.getTime()) /
      DAY_MS,
  );
}
