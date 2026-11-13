import { Injectable, Logger } from '@nestjs/common';
import {
  Collaboration,
  EvidenceSource,
  SettlementConfirmer,
} from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { VIEW_REPORT_POLICY } from '../common/collaboration-policy';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { JobRunContext, JobScheduler } from '../jobs/job-scheduler';
import { postingsForSettlement } from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { hasViewPay, readTerms } from '../stores/reward-terms';
import { UsersService } from '../users/users.service';
import { assertEscrowMatches } from './escrow-check';
import {
  autoConfirmJobKey,
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
import { SettlementsRepository } from './settlements.repository';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

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
  ) {}

  // 측정 기간이 끝났을 때 계산을 만든다: 정산 행을 UNCONFIRMED로 만들기만 한다. 장부, 단계, 지급·환급 행은 건드리지 않는다.
  // 이미 계산이 있으면 'exists', 협업이 없거나 COUNTING이 아니면(그사이 멈춤·취소) 'gone'이다.
  async createCalculation(
    collaborationId: string,
  ): Promise<'created' | 'exists' | 'gone'> {
    const collaboration = await this.collaborations.findById(collaborationId);
    if (!collaboration) return 'gone';
    const terms = readTerms(collaboration.terms);
    if (
      terms.viewRatePerThousand === null ||
      terms.perViewCap === null ||
      !hasViewPay(terms)
    ) {
      throw new Error('조회수 수당이 없는 협업은 계산을 만들지 않아요.');
    }
    const views = pickFinalViews(
      await this.repository.listSnapshots(collaborationId),
      lastDayOf(collaboration),
    );
    // 읽은 값이 하나도 없으면 0으로 계산하지 않는다(호출한 쪽이 먼저 멈춘다).
    if (views === null) throw new Error('읽은 조회수가 없어 계산할 수 없어요.');
    const { viewPay, payout, refund } = settleReward({
      views,
      ratePerThousand: terms.viewRatePerThousand,
      cap: terms.perViewCap,
      fixedCash: terms.fixedCash,
    });
    const now = this.clock.now();
    return this.repository.transaction<'created', 'exists' | 'gone'>(
      async (tx, rollback) => {
        if (!(await this.repository.lockCollaboration(collaborationId, tx))) {
          return rollback('gone');
        }
        const fresh = await this.collaborations.findById(collaborationId, tx);
        if (fresh?.stage !== 'COUNTING') return rollback('gone');
        const created = await this.repository.createSettlement(
          {
            collaborationId,
            finalViews: views,
            payoutAmount: payout,
            refundAmount: refund,
            fixedCashAmount: terms.fixedCash,
            viewPayAmount: viewPay,
            status: 'UNCONFIRMED',
            calculatedAt: now,
            confirmDueAt: new Date(
              now.getTime() + VIEW_REPORT_POLICY.confirmHours * HOUR_MS,
            ),
            settledAt: null,
            confirmedAt: null,
            confirmedBy: null,
          },
          tx,
        );
        return created ? 'created' : rollback('exists');
      },
    );
  }

  // 계산이 만들어진 뒤의 단계: 자동 확인 작업을 확인 기한에 올리고, 사장님에게 확인을, 크리에이터에게 계산을 알린다.
  // 모두 같은 키라 다시 불러도 한 번만 일어난다(작업이 커밋 뒤에 죽어도 다시 돌 때 이어서 한다).
  async announceCalculation(collaborationId: string): Promise<void> {
    const collaboration = await this.collaborations.findById(collaborationId);
    const settlement = collaboration
      ? await this.repository.findSettlement(collaborationId)
      : null;
    if (
      !collaboration ||
      !settlement ||
      settlement.status !== 'UNCONFIRMED' ||
      !settlement.confirmDueAt
    ) {
      return;
    }
    await this.jobs.schedule(
      'settlement-auto-confirm',
      { collaborationId },
      settlement.confirmDueAt,
      autoConfirmJobKey(collaborationId),
    );
    const target = { kind: 'VIEW_REPORT', id: collaborationId } as const;
    const dedupeKey = viewReportDedupeKey(collaborationId);
    const role = await this.users.getRole(collaboration.commissionerId);
    await this.notifications.notify({
      userId: collaboration.commissionerId,
      role: role === 'BRAND' ? 'BRAND' : 'STORE',
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
      // 이의 제기와 캡처 올리기는 Task 20이 연다.
      canDispute: false,
      canUploadEvidence: false,
      evidence: null,
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
        const now = this.clock.now();
        // 이 갱신이 정산 행을 먼저 잠근다(정산 행 → 협업).
        if (
          !(await this.repository.confirmCalculation(
            collaborationId,
            by,
            now,
            options.onlySource ?? null,
            tx,
          ))
        ) {
          return rollback('lost');
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
        // 협업이 그사이 COUNTING이 아니게 됐다면 정산 행 변경까지 전부 되돌린다(돈은 그대로 보관된다).
        if (
          !(await this.collaborations.advance(
            collaborationId,
            'COUNTING',
            'SETTLED',
            {},
            tx,
          ))
        ) {
          return rollback('lost');
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
          key,
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
        return 'confirmed';
      },
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
