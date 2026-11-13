import { Injectable, Logger } from '@nestjs/common';
import { Collaboration, CollaborationStage, Prisma } from '@prisma/client';
import {
  scheduleSubmissionDeadlineJobs,
  submissionDeadlineJobKeys,
} from '../collaborations/collaboration-jobs';
import { canTransition } from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { JobScheduler } from '../jobs/job-scheduler';
import {
  postingsForFullRefund,
  postingsForPaymentApproved,
} from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { PaymentsService } from '../payments/payments.service';
import {
  autoConfirmJobKey,
  evidenceHaltJobKey,
  forcePayoutKey,
  forcePayoutRefundKey,
  forceRefundKey,
  lateRefundKey,
  payoutJobKey,
  paymentLedgerKey,
  SETTLEMENT_DISPUTED_HALT_REASON,
  settleJobKey,
  SNAPSHOT_DAYS,
  snapshotJobKey,
  VIEW_COUNT_HALT_REASON,
} from '../settlements/job-keys';
import { PayoutsService } from '../settlements/payouts.service';
import { RefundsService } from '../settlements/refunds.service';
import { SettlementsRepository } from '../settlements/settlements.repository';
import { SettlementsService } from '../settlements/settlements.service';
import { ViewReportService } from '../settlements/view-report.service';
import { hasViewPay, readTerms } from '../stores/reward-terms';
import { OpsError } from './ops-error';
import { formatSnapshot } from './ops-format';
import { OpsRepository } from './ops.repository';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_OPERATOR = 100;
const MAX_REASON = 1000;

// 운영자가 멈춘 협업의 사유. 조회수를 읽지 못해 멈춘 것(VIEW_COUNT_UNAVAILABLE)과 구별한다.
export const OPERATOR_HALT_REASON = 'OPERATOR_HALT';

// 돈이 보관 중이라 운영자가 강제로 끝낼 수 있는 가게 오퍼의 단계. 멈춘 협업도 돈은 그대로 있다.
const FORCEABLE_STAGES: CollaborationStage[] = ['FUNDED', 'COUNTING', 'HALTED'];

export interface OpsActor {
  operator: string;
  reason: string;
}

// lines는 운영자에게 보여 줄 결과이고, warnings는 커밋된 뒤의 단계(작업 등록, PG 호출)에서 난 문제다.
// 경고가 있으면 돈의 상태는 이미 커밋됐으니 show로 확인하고 retry-* 명령으로 이어 간다.
export interface OpsResult {
  lines: string[];
  warnings: string[];
}

// 모든 돈 정정은 이 서비스를 거친다. 명령마다:
// - 협업 행을 잠근 트랜잭션 안에서 단계를 조건부로 바꾸고, 장부 줄과 감사 기록을 함께 남긴 뒤 장부를 검산한다
//   (하나라도 실패하면 전부 되돌아간다).
// - 작업 취소·등록, PG 호출처럼 트랜잭션 밖에서 해야 하는 일은 커밋 뒤에 하고, 실패하면 경고로 알린다.
// - 장부 키와 돈 행 키가 명령·협업마다 정해져 있어 같은 명령을 다시 실행해도 두 번 움직이지 않는다.
@Injectable()
export class OpsService {
  private readonly logger = new Logger(OpsService.name);

  constructor(
    private readonly repository: OpsRepository,
    private readonly collaborations: CollaborationsRepository,
    private readonly ledger: LedgerService,
    private readonly jobs: JobScheduler,
    private readonly payments: PaymentsService,
    private readonly settlements: SettlementsService,
    private readonly settlementsRepository: SettlementsRepository,
    private readonly payouts: PayoutsService,
    private readonly refunds: RefundsService,
    private readonly clock: Clock,
    private readonly viewReport: ViewReportService,
  ) {}

  // 돈을 보관 중인 협업을 멈춘다. 등록된 정산·집계·제출 기한 작업을 취소한다.
  async halt(collaborationId: string, actor: OpsActor): Promise<OpsResult> {
    this.assertActor(actor);
    const from = await this.inCollaboration(collaborationId, async (tx, c) => {
      if (!canTransition(c.kind, c.stage, 'HALTED')) {
        throw new OpsError(
          `${c.stage} 단계는 멈출 수 없어요. 돈을 보관 중인 단계만 멈출 수 있어요.`,
        );
      }
      // 확인 전인 계산이 있는 협업을 멈추면 확인·재개·강제 끝내기가 모두 막혀 갇힌다. 그 협업은 이의 제기(자동으로 멈춤)나
      // 확인(사장님·자동·confirm-evidence)으로만 움직인다. 돈은 확인 전에는 나가지 않는다.
      const open = await this.settlementsRepository.findSettlement(c.id, tx);
      if (open && open.status !== 'CONFIRMED') {
        throw new OpsError(
          `조회 자료 확인이 끝나지 않은 정산이 있어 멈출 수 없어요. (${open.status}) 돈은 확인 전에는 나가지 않아요. 이의가 걸렸다면 resolve-dispute, 캡처 자료라면 confirm-evidence로 처리해 주세요.`,
        );
      }
      await this.advanceOrConflict(c, c.stage, 'HALTED', tx, {
        stageBeforeHalt: c.stage,
        haltedReason: OPERATOR_HALT_REASON,
      });
      await this.finish(tx, 'halt', c.id, actor, { from: c.stage });
      return c.stage;
    });
    const warnings: string[] = [];
    await this.afterCommit(warnings, '작업 취소', () =>
      this.cancelJobs(collaborationId),
    );
    return {
      lines: [`협업을 멈췄어요. (${from} → HALTED)`],
      warnings,
    };
  }

  // 멈춘 협업을 멈추기 전 단계로 되돌린다. 신고나 조회수 읽기 실패로 멈춘 협업도 같다.
  // 정산 중이었다면 정산을 지금 실행하게 올리고, 제출을 기다리던 중이었다면 미제출 환급과 기한 알림을 다시 올린다
  // (기한이 이미 지났으면 미제출 환급이 바로 돈다).
  async resume(collaborationId: string, actor: OpsActor): Promise<OpsResult> {
    this.assertActor(actor);
    const { to, collaboration } = await this.inCollaboration(
      collaborationId,
      async (tx, c) => {
        if (c.stage !== 'HALTED') {
          throw new OpsError(`멈춘 협업이 아니에요. (지금 단계: ${c.stage})`);
        }
        await this.assertNoOpenSettlement(c, tx);
        const to = c.stageBeforeHalt;
        if (!to) {
          throw new OpsError(
            '멈추기 전 단계를 알 수 없어요. force-refund나 force-payout으로 끝내 주세요.',
          );
        }
        if (!canTransition(c.kind, 'HALTED', to, to)) {
          throw new OpsError(`${to} 단계로는 되돌릴 수 없어요.`);
        }
        if (to === 'COUNTING' && (!c.submittedAt || !c.countingEndsAt)) {
          throw new OpsError(
            '집계 시작·종료 시각이 없어서 집계 작업을 다시 올릴 수 없어요.',
          );
        }
        if (to === 'FUNDED' && !c.submitDueAt) {
          throw new OpsError(
            '제출 기한이 없어서 제출 기한 작업을 올릴 수 없어요.',
          );
        }
        await this.advanceOrConflict(c, 'HALTED', to, tx, {
          haltedReason: null,
          stageBeforeHalt: null,
        });
        await this.finish(tx, 'resume', c.id, actor, {
          from: 'HALTED',
          to,
          haltedReason: c.haltedReason,
        });
        return { to, collaboration: c };
      },
    );
    const warnings: string[] = [];
    const now = this.clock.now();
    if (to === 'COUNTING') {
      await this.afterCommit(warnings, '집계·정산 작업 등록', () =>
        this.rescheduleCounting(collaboration, now),
      );
    } else if (to === 'FUNDED' && collaboration.submitDueAt) {
      const dueAt = collaboration.submitDueAt;
      await this.afterCommit(warnings, '제출 기한 작업 등록', async () => {
        for (const key of submissionDeadlineJobKeys(collaborationId)) {
          await this.jobs.cancel(key);
        }
        await scheduleSubmissionDeadlineJobs(
          this.jobs,
          collaborationId,
          dueAt,
          now,
        );
      });
    }
    return { lines: [`협업을 다시 열었어요. (HALTED → ${to})`], warnings };
  }

  // 집계 중이던 협업을 재개하면 멈추기 전의 일정을 이어 간다(일찍 정산하지 않는다):
  // 아직 기록되지 않은 날의 조회수 작업을 원래 시각(제출 시각 + 날수)으로 다시 올리고(지난 시각이면 바로 돈다),
  // 정산은 max(지금, 원래 정산 시각)에 올린다. 멈추면서 모두 취소했으므로 같은 키로 다시 올릴 수 있다.
  private async rescheduleCounting(c: Collaboration, now: Date): Promise<void> {
    const submittedAt = c.submittedAt;
    const endsAt = c.countingEndsAt;
    if (!submittedAt || !endsAt) return;
    // 조회수 수당이 없는 협업(고정 현금만)은 조회수를 세지 않으니 조회수 작업은 올리지 않고 정산만 올린다.
    const viewPay = hasViewPay(readTerms(c.terms));
    const recorded = new Set(
      (await this.settlementsRepository.listSnapshots(c.id)).map(
        (snapshot) => snapshot.dayIndex,
      ),
    );
    for (let day = 0; viewPay && day <= SNAPSHOT_DAYS; day += 1) {
      if (recorded.has(day)) continue;
      const key = snapshotJobKey(c.id, day);
      await this.jobs.cancel(key);
      await this.jobs.schedule(
        'view-snapshot',
        { collaborationId: c.id, dayIndex: day },
        new Date(submittedAt.getTime() + day * DAY_MS),
        key,
      );
    }
    const settleKey = settleJobKey(c.id);
    await this.jobs.cancel(settleKey);
    await this.jobs.schedule(
      'settle',
      { collaborationId: c.id },
      new Date(Math.max(now.getTime(), endsAt.getTime())),
      settleKey,
    );
  }

  // 조회수를 읽지 못해 멈춘 협업을 운영자가 확인한 조회수로 정산한다. 지급·환급·알림은 일반 정산과 같다.
  async resumeSettlement(
    collaborationId: string,
    views: number,
    actor: OpsActor,
  ): Promise<OpsResult> {
    this.assertActor(actor);
    this.assertWhole(views, '조회수');
    const result = await this.inCollaboration(
      collaborationId,
      async (tx, c) => {
        if (c.stage !== 'HALTED' || c.haltedReason !== VIEW_COUNT_HALT_REASON) {
          throw new OpsError(
            '조회수를 읽지 못해 멈춘 협업만 조회수로 정산할 수 있어요.',
          );
        }
        await this.assertNoOpenSettlement(c, tx);
        const settled = await this.settlements.settleHaltedWithViews(
          tx,
          c,
          views,
        );
        if (!settled) throw this.conflict();
        await this.finish(tx, 'resume-settlement', c.id, actor, {
          views,
          ...settled,
        });
        return settled;
      },
    );
    const warnings: string[] = [];
    await this.afterCommit(warnings, '정산 뒷단계(지급 작업·알림·환급)', () =>
      this.settlements.finishSettlementOf(collaborationId),
    );
    await this.afterCommit(warnings, '작업 취소', () =>
      this.cancelJobs(collaborationId),
    );
    return {
      lines: [
        `조회수 ${count(views)}으로 정산했어요. 지급 ${won(result.payout)}원, 환급 ${won(result.refund)}원.`,
      ],
      warnings,
    };
  }

  // 보관 중인 전액과 수수료를 사장님에게 환급하고 REFUNDED로 끝낸다.
  async forceRefund(
    collaborationId: string,
    actor: OpsActor,
  ): Promise<OpsResult> {
    this.assertActor(actor);
    const { refundId, escrow, fee } = await this.inCollaboration(
      collaborationId,
      async (tx, c) => {
        this.assertForceable(c);
        await this.assertNoOpenSettlement(c, tx);
        const balances = await this.ledger.accountBalances(c.id, tx);
        const escrow = balances.ESCROW;
        const fee = balances.FEE_REVENUE;
        if (escrow + fee <= 0) {
          throw new OpsError('환급할 보관 금액이 없어요.');
        }
        await this.advanceOrConflict(c, c.stage, 'REFUNDED', tx, {
          haltedReason: null,
          stageBeforeHalt: null,
        });
        const key = forceRefundKey(c.id);
        if (
          (await this.ledger.post(
            c.id,
            postingsForFullRefund({ escrow, fee }),
            key,
            tx,
          )) === 'duplicate'
        ) {
          throw new OpsError('이 협업은 이미 강제 환급 장부가 있어요.');
        }
        const refund = await this.refunds.request(c.id, escrow + fee, key, tx);
        await this.finish(tx, 'force-refund', c.id, actor, {
          from: c.stage,
          escrow,
          fee,
          refundId: refund?.id ?? null,
        });
        return { refundId: refund?.id ?? null, escrow, fee };
      },
    );
    const warnings: string[] = [];
    await this.afterCommit(warnings, '작업 취소', () =>
      this.cancelJobs(collaborationId),
    );
    if (refundId) await this.sendRefund(refundId, warnings);
    return {
      lines: [
        `전액을 환급해요. 보관액 ${won(escrow)}원 + 수수료 ${won(fee)}원 = ${won(escrow + fee)}원. (REFUNDED)`,
      ],
      warnings,
    };
  }

  // 보관액 안에서 amount를 크리에이터에게 지급하고 남은 보관액을 사장님에게 환급한 뒤 SETTLED로 끝낸다.
  async forcePayout(
    collaborationId: string,
    amount: number,
    actor: OpsActor,
  ): Promise<OpsResult> {
    this.assertActor(actor);
    this.assertWhole(amount, '지급액');
    if (amount === 0) {
      throw new OpsError(
        '지급액은 1원 이상이어야 해요. 전액 환급은 force-refund를 쓰세요.',
      );
    }
    const result = await this.inCollaboration(
      collaborationId,
      async (tx, c) => {
        this.assertForceable(c);
        await this.assertNoOpenSettlement(c, tx);
        const escrow = await this.ledger.escrowBalance(c.id, tx);
        if (amount > escrow) {
          throw new OpsError(
            `지급액(${won(amount)}원)이 보관액(${won(escrow)}원)보다 커요.`,
          );
        }
        const settled = await this.settlements.settleForced(tx, c, amount);
        if (!settled) throw this.conflict();
        await this.finish(tx, 'force-payout', c.id, actor, {
          from: c.stage,
          escrow,
          ...settled,
        });
        return settled;
      },
    );
    const warnings: string[] = [];
    await this.afterCommit(warnings, '작업 취소', () =>
      this.cancelJobs(collaborationId),
    );
    await this.afterCommit(warnings, '정산 뒷단계(지급 작업·알림·환급)', () =>
      this.settlements.finishSettlementOf(collaborationId, {
        payout: forcePayoutKey(collaborationId),
        refund: forcePayoutRefundKey(collaborationId),
      }),
    );
    return {
      lines: [
        `지급 ${won(result.payout)}원, 환급 ${won(result.refund)}원으로 끝냈어요. (SETTLED)`,
      ],
      warnings,
    };
  }

  // 크리에이터가 낸 조회수 캡처로 만든 계산을 운영자가 확인 완료로 확정한다. 캡처 자료는 사장님의 확인으로도 48시간으로도
  // 확정되지 않으므로 이 명령만 확정한다. 장부·지급·환급은 사장님 확인과 같은 길(ViewReportService.settleCalculation)이다.
  async confirmEvidence(
    collaborationId: string,
    actor: OpsActor,
  ): Promise<OpsResult> {
    this.assertActor(actor);
    const settled = await this.inCollaboration(
      collaborationId,
      async (tx, c) => {
        const settlement = await this.settlementsRepository.findSettlement(
          c.id,
          tx,
        );
        if (
          !settlement ||
          settlement.status !== 'UNCONFIRMED' ||
          settlement.evidenceSource !== 'CAPTURE'
        ) {
          throw new OpsError(
            '캡처로 만든, 확인 전(UNCONFIRMED)인 계산이 있는 협업만 확인할 수 있어요.',
          );
        }
        if (c.stage !== 'COUNTING') {
          throw new OpsError(
            `집계 중(COUNTING)인 협업만 확인할 수 있어요. (지금 단계: ${c.stage})`,
          );
        }
        const ok = await this.viewReport.settleCalculation(tx, c.id, {
          by: 'OPERATOR',
          key: settleJobKey(c.id),
          fromStatus: 'UNCONFIRMED',
          fromStage: 'COUNTING',
          onlySource: 'CAPTURE',
        });
        if (!ok) throw this.conflict();
        await this.settlementsRepository.confirmEvidence(
          c.id,
          actor.operator.trim(),
          this.clock.now(),
          tx,
        );
        await this.finish(tx, 'confirm-evidence', c.id, actor, {
          views: settlement.finalViews,
          payout: settlement.payoutAmount,
          refund: settlement.refundAmount,
        });
        return settlement;
      },
    );
    return this.afterConfirmation(collaborationId, {
      line: `캡처 조회수 ${count(settled.finalViews ?? 0)}으로 확정했어요. 지급 ${won(settled.payoutAmount)}원, 환급 ${won(settled.refundAmount)}원.`,
    });
  }

  // 이의가 걸려 멈춘 협업(DISPUTED 정산)을 처리한다. views를 주면 그 조회수로 다시 계산해 확정하고(VIEWS_CORRECTED),
  // 주지 않으면 계산 그대로 확정한다(UPHELD_AS_IS). 협업은 HALTED → SETTLED로 끝난다.
  async resolveDispute(
    collaborationId: string,
    views: number | undefined,
    actor: OpsActor,
  ): Promise<OpsResult> {
    this.assertActor(actor);
    if (views !== undefined) this.assertWhole(views, '조회수');
    const result = await this.inCollaboration(
      collaborationId,
      async (tx, c) => {
        const settlement = await this.settlementsRepository.findSettlement(
          c.id,
          tx,
        );
        if (
          !settlement ||
          settlement.status !== 'DISPUTED' ||
          c.stage !== 'HALTED' ||
          c.haltedReason !== SETTLEMENT_DISPUTED_HALT_REASON
        ) {
          throw new OpsError(
            '이의가 걸려 멈춘 협업(DISPUTED 정산, HALTED)만 처리할 수 있어요.',
          );
        }
        const ok = await this.viewReport.settleCalculation(tx, c.id, {
          by: 'OPERATOR',
          key: settleJobKey(c.id),
          fromStatus: 'DISPUTED',
          fromStage: 'HALTED',
          patch: { haltedReason: null, stageBeforeHalt: null },
          correctedViews: views,
        });
        if (!ok) throw this.conflict();
        const after = await this.settlementsRepository.findSettlement(c.id, tx);
        if (!after) throw this.conflict();
        await this.settlementsRepository.resolveDisputes(
          c.id,
          {
            resolution:
              views === undefined ? 'UPHELD_AS_IS' : 'VIEWS_CORRECTED',
            resolvedViews: views ?? null,
            at: this.clock.now(),
          },
          tx,
        );
        if (settlement.evidenceSource === 'CAPTURE') {
          await this.settlementsRepository.confirmEvidence(
            c.id,
            actor.operator.trim(),
            this.clock.now(),
            tx,
          );
        }
        await this.finish(tx, 'resolve-dispute', c.id, actor, {
          resolution: views === undefined ? 'UPHELD_AS_IS' : 'VIEWS_CORRECTED',
          views: views ?? null,
          payout: after.payoutAmount,
          refund: after.refundAmount,
        });
        return after;
      },
    );
    return this.afterConfirmation(collaborationId, {
      line:
        views === undefined
          ? `계산 그대로 확정했어요. 지급 ${won(result.payoutAmount)}원, 환급 ${won(result.refundAmount)}원.`
          : `조회수 ${count(views)}으로 다시 계산해 확정했어요. 지급 ${won(result.payoutAmount)}원, 환급 ${won(result.refundAmount)}원.`,
    });
  }

  // 확정이 커밋된 뒤의 단계(지급 작업·알림·PG 환급)와 남은 작업 정리. 실패하면 경고로 알린다.
  private async afterConfirmation(
    collaborationId: string,
    p: { line: string },
  ): Promise<OpsResult> {
    const warnings: string[] = [];
    await this.afterCommit(warnings, '정산 뒷단계(지급 작업·알림·환급)', () =>
      this.settlements.finishSettlementOf(collaborationId),
    );
    await this.afterCommit(warnings, '작업 취소', () =>
      this.cancelJobs(collaborationId),
    );
    return { lines: [p.line], warnings };
  }

  // 송금이 FAILED인 지급, 또는 지급일이 지났는데 송금 작업이 시도를 다 써서 PENDING으로 남은 지급을 같은 중복 방지 키로 다시 보낸다.
  // FAILED는 지급일이 아니어도 바로 보내지만, PENDING은 지급일 전이면 거절한다(송금은 늘 수요일 묶음이다).
  async retryPayout(payoutId: string, actor: OpsActor): Promise<OpsResult> {
    this.assertActor(actor);
    this.assertUuid(payoutId, '지급');
    const payout = await this.payouts.findById(payoutId);
    if (!payout) throw new OpsError('지급을 찾을 수 없어요.');
    const wasPending = payout.status === 'PENDING';
    if (payout.status !== 'FAILED' && !wasPending) {
      throw new OpsError(
        `FAILED 상태의 지급, 또는 지급일이 지난 PENDING 지급만 다시 보낼 수 있어요. (지금: ${payout.status})`,
      );
    }
    if (
      wasPending &&
      payout.scheduledFor.getTime() > this.clock.now().getTime()
    ) {
      throw new OpsError(
        '아직 지급일 전이라 다시 보낼 수 없어요. 지급일이 지난 뒤에 실행해 주세요. (PENDING)',
      );
    }
    await this.inCollaboration(payout.collaborationId, async (tx, c) => {
      // PENDING은 이미 대기라 되돌릴 것이 없다. 송금은 send가 같은 키로 한 번만 보내고 DONE 갱신도 조건부다.
      if (!wasPending && !(await this.payouts.reopenFailed(payout.id, tx))) {
        throw this.conflict();
      }
      await this.finish(tx, 'retry-payout', c.id, actor, {
        payoutId: payout.id,
        amount: payout.amount,
        previousStatus: payout.status,
      });
    });
    const warnings: string[] = [];
    try {
      await this.payouts.send(payout.id);
    } catch (error) {
      // 일시 오류: 지급은 대기로 남아 있으니 작업 큐가 이어서 보내게 올려 둔다.
      warnings.push(`송금 중 오류가 났어요(${describe(error)}).`);
      await this.afterCommit(warnings, '송금 작업 등록', () =>
        this.jobs.schedule(
          'payout-send',
          { payoutId: payout.id },
          this.clock.now(),
          payoutJobKey(payout.id),
        ),
      );
    }
    const after = await this.payouts.findById(payout.id);
    const status = after?.status ?? 'UNKNOWN';
    if (status === 'FAILED') {
      warnings.push('송금이 다시 실패했어요. PG 쪽 상태를 확인해 주세요.');
    }
    const lines = [
      status === 'DONE'
        ? `지급 ${won(payout.amount)}원을 보냈어요. (DONE)`
        : status === 'PENDING'
          ? `지급이 ${wasPending ? '대기로 남아 있어요' : '대기로 되돌아갔어요'}. 계좌가 없으면 계좌를 등록한 뒤 다음 지급일에 나가고, 아니면 작업 큐가 이어서 보내요. (PENDING)`
          : `지급 상태: ${status}`,
    ];
    return { lines, warnings };
  }

  // 큐가 시도를 다 썼거나 실패한 환급(PENDING·FAILED)을 같은 중복 방지 키로 다시 PG에 보낸다.
  async retryRefund(refundId: string, actor: OpsActor): Promise<OpsResult> {
    this.assertActor(actor);
    this.assertUuid(refundId, '환급');
    const refund = await this.settlementsRepository.findRefundById(refundId);
    if (!refund) throw new OpsError('환급을 찾을 수 없어요.');
    if (refund.status === 'DONE') {
      throw new OpsError('이미 환급이 끝났어요. (DONE)');
    }
    await this.inCollaboration(refund.collaborationId, async (tx, c) => {
      await this.finish(tx, 'retry-refund', c.id, actor, {
        refundId: refund.id,
        amount: refund.amount,
        previousStatus: refund.status,
      });
    });
    const warnings: string[] = [];
    await this.sendRefund(refund.id, warnings);
    return {
      lines:
        warnings.length === 0
          ? [`환급 ${won(refund.amount)}원을 보냈어요. (DONE)`]
          : [],
      warnings,
    };
  }

  // 협업에 반영되지 못한 승인 결제(끝난 뒤에 승인됐거나 두 번째 결제)를 돌려보낸다.
  // 장부에는 결제 승인 묶음과 전액 환급 묶음이 함께 남는다(돈이 PG에서 들어왔다 바로 나간다).
  async refundPayment(paymentId: string, actor: OpsActor): Promise<OpsResult> {
    this.assertActor(actor);
    this.assertUuid(paymentId, '결제');
    const payment = await this.payments.findPayment(paymentId);
    if (!payment) throw new OpsError('결제를 찾을 수 없어요.');
    if (payment.status !== 'APPROVED' || !payment.pgTransactionId) {
      throw new OpsError(
        `승인된 결제만 환불할 수 있어요. (지금: ${payment.status})`,
      );
    }
    const total = payment.amountEscrow + payment.amountFee;
    const refundId = await this.inCollaboration(
      payment.collaborationId,
      async (tx, c) => {
        const funding = await this.payments.findFundingPayment(c.id);
        if (funding?.id === payment.id) {
          throw new OpsError(
            '이 결제는 협업의 보관을 시작시킨 결제예요. force-refund로 환급해 주세요.',
          );
        }
        const refundKey = lateRefundKey(payment.id);
        if (await this.refunds.findByKey(refundKey)) {
          throw new OpsError('이미 환급한 결제예요.');
        }
        const posted = await this.ledger.post(
          c.id,
          postingsForPaymentApproved({
            escrow: payment.amountEscrow,
            fee: payment.amountFee,
          }),
          paymentLedgerKey(payment.id),
          tx,
        );
        if (posted === 'duplicate') {
          throw new OpsError(
            '이 결제의 승인 장부 줄이 이미 있어요. 협업에 반영된 결제일 수 있으니 show로 확인해 주세요.',
          );
        }
        await this.ledger.post(
          c.id,
          postingsForFullRefund({
            escrow: payment.amountEscrow,
            fee: payment.amountFee,
          }),
          refundKey,
          tx,
        );
        const refund = await this.refunds.request(c.id, total, refundKey, tx);
        await this.finish(tx, 'refund-payment', c.id, actor, {
          paymentId: payment.id,
          escrow: payment.amountEscrow,
          fee: payment.amountFee,
          refundId: refund?.id ?? null,
        });
        return refund?.id ?? null;
      },
    );
    const warnings: string[] = [];
    if (refundId) await this.sendRefund(refundId, warnings);
    return {
      lines: [`결제 ${won(total)}원을 환불해요. (협업 단계는 그대로예요)`],
      warnings,
    };
  }

  // 읽기 전용. 감사 기록을 남기지 않는다. 계좌번호는 출력하지 않는다.
  async show(collaborationId: string): Promise<OpsResult> {
    this.assertUuid(collaborationId, '협업');
    const snapshot = await this.repository.snapshot(collaborationId);
    if (!snapshot) throw new OpsError('협업을 찾을 수 없어요.');
    const [balances, funding] = await Promise.all([
      this.ledger.accountBalances(collaborationId),
      this.payments.findFundingPayment(collaborationId),
    ]);
    return {
      lines: formatSnapshot(snapshot, balances, funding?.id ?? null),
      warnings: [],
    };
  }

  // 협업 행을 잠근 트랜잭션에서 run을 실행한다. 협업이 없거나 id가 틀리면 OpsError다.
  private inCollaboration<T>(
    collaborationId: string,
    run: (
      tx: Prisma.TransactionClient,
      collaboration: Collaboration,
    ) => Promise<T>,
  ): Promise<T> {
    this.assertUuid(collaborationId, '협업');
    return this.repository.transaction(async (tx) => {
      if (!(await this.repository.lockCollaboration(collaborationId, tx))) {
        throw new OpsError('협업을 찾을 수 없어요.');
      }
      const collaboration = await this.collaborations.findById(
        collaborationId,
        tx,
      );
      if (!collaboration) throw new OpsError('협업을 찾을 수 없어요.');
      return run(tx, collaboration);
    });
  }

  // 명령의 끝: 감사 기록을 남기고 그 협업의 장부를 검산한다. 어긋나면 던져서 트랜잭션 전체를 되돌린다.
  private async finish(
    tx: Prisma.TransactionClient,
    command: string,
    collaborationId: string,
    actor: OpsActor,
    detail: Prisma.InputJsonObject,
  ): Promise<void> {
    await this.repository.writeAudit(
      {
        command,
        collaborationId,
        operator: actor.operator.trim(),
        reason: actor.reason.trim(),
        detail,
        createdAt: this.clock.now(),
      },
      tx,
    );
    await this.ledger.assertCollaborationBalanced(collaborationId, tx);
  }

  private async advanceOrConflict(
    collaboration: Collaboration,
    from: CollaborationStage,
    to: CollaborationStage,
    tx: Prisma.TransactionClient,
    patch: Parameters<CollaborationsRepository['advance']>[3],
  ): Promise<void> {
    if (
      !(await this.collaborations.advance(
        collaboration.id,
        from,
        to,
        patch,
        tx,
      ))
    ) {
      throw this.conflict();
    }
  }

  // 조회 자료 확인 전(UNCONFIRMED)이나 이의 중(DISPUTED)인 정산이 있으면 돈이 나가는 명령을 거절한다.
  // 이 정산은 확인 완료(사장님·자동·운영 확정)나 이의 처리로만 끝난다: 다른 길로 끝내면 계산이 남은 채 협업이 어긋난다.
  // 정산 행은 inCollaboration이 이미 잠갔으니 여기서 읽은 값이 그대로 유지된다.
  private async assertNoOpenSettlement(
    c: Collaboration,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    const settlement = await this.settlementsRepository.findSettlement(
      c.id,
      tx,
    );
    if (settlement && settlement.status !== 'CONFIRMED') {
      throw new OpsError(
        `조회 자료 확인이 끝나지 않은 정산이 있어요. (${settlement.status}) 이의가 걸렸다면 resolve-dispute, 캡처 자료라면 confirm-evidence로 처리해 주세요.`,
      );
    }
  }

  private assertForceable(c: Collaboration): void {
    if (c.kind !== 'STORE_OFFER') {
      throw new OpsError(
        '브랜드 계약의 강제 환급·지급은 아직 지원하지 않아요.',
      );
    }
    if (!FORCEABLE_STAGES.includes(c.stage)) {
      throw new OpsError(
        `${c.stage} 단계에서는 쓸 수 없어요. 돈을 보관 중인 FUNDED·COUNTING·HALTED 단계만 가능해요.`,
      );
    }
  }

  // 커밋된 뒤의 단계. 실패해도 이미 커밋된 일을 되돌릴 수 없으니 경고로 모아 운영자에게 보여 준다.
  private async afterCommit(
    warnings: string[],
    label: string,
    run: () => Promise<void>,
  ): Promise<void> {
    try {
      await run();
    } catch (error) {
      this.logger.error(`${label} 실패: ${describe(error)}`);
      warnings.push(`${label}에 실패했어요(${describe(error)}).`);
    }
  }

  // PG 환급. 실패하면 환급 행은 PENDING으로 남으니 retry-refund로 이어 간다.
  private async sendRefund(
    refundId: string,
    warnings: string[],
  ): Promise<void> {
    try {
      await this.refunds.retry(refundId);
    } catch (error) {
      this.logger.error(`PG 환급 실패: ${describe(error)}`);
      warnings.push(
        `PG 환급에 실패했어요(${describe(error)}). yarn ops retry-refund --refund ${refundId} 로 다시 보내세요.`,
      );
    }
  }

  // 멈췄거나 끝난 협업에 남은 정산·집계·제출 기한 작업을 지운다. 지울 것이 없어도 오류가 아니다.
  private async cancelJobs(collaborationId: string): Promise<void> {
    const keys = [
      settleJobKey(collaborationId),
      autoConfirmJobKey(collaborationId),
      evidenceHaltJobKey(collaborationId),
      ...Array.from({ length: SNAPSHOT_DAYS + 1 }, (_, day) =>
        snapshotJobKey(collaborationId, day),
      ),
      ...submissionDeadlineJobKeys(collaborationId),
    ];
    for (const key of keys) await this.jobs.cancel(key);
  }

  private assertActor(actor: OpsActor): void {
    const operator = actor.operator?.trim() ?? '';
    const reason = actor.reason?.trim() ?? '';
    if (!operator) throw new OpsError('--operator(실행한 사람)가 필요해요.');
    if (!reason) throw new OpsError('--reason(사유)이 필요해요.');
    if (operator.length > MAX_OPERATOR) {
      throw new OpsError(`--operator는 ${MAX_OPERATOR}자 이하여야 해요.`);
    }
    if (reason.length > MAX_REASON) {
      throw new OpsError(`--reason은 ${MAX_REASON}자 이하여야 해요.`);
    }
  }

  private assertUuid(id: string, label: string): void {
    if (!UUID.test(id))
      throw new OpsError(`${label} id 형식이 올바르지 않아요.`);
  }

  private assertWhole(value: number, label: string): void {
    if (!Number.isInteger(value) || value < 0) {
      throw new OpsError(`${label}은(는) 0 이상의 정수여야 해요.`);
    }
  }

  private conflict(): OpsError {
    return new OpsError(
      '협업의 단계가 그사이 바뀌었어요. show로 확인한 뒤 다시 실행해 주세요.',
    );
  }
}

const won = (n: number): string => n.toLocaleString('en-US');
const count = won;

// 어댑터(PG·송금)의 오류 메시지에는 계좌나 예금주 같은 값이 섞일 수 있어 출력하지도 로그에 남기지도 않는다.
// 오류의 종류(name)와 고정 문구만 낸다. 원인은 PG·송금 쪽 콘솔에서 확인한다.
function describe(error: unknown): string {
  return error instanceof Error ? `${error.name} 오류` : '알 수 없는 오류';
}
