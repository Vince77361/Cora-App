import { Injectable, Logger } from '@nestjs/common';
import {
  Collaboration,
  CollaborationStage,
  Payout,
  Prisma,
  Settlement,
  SettlementConfirmer,
} from '@prisma/client';
import {
  CollaborationPatch,
  CollaborationsRepository,
} from '../collaborations/collaborations.repository';
import {
  Posting,
  postingsForForcedPayout,
  postingsForForcedRefund,
  postingsForSettlement,
} from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { Clock } from '../common/clock';
import { hasViewPay, readTerms } from '../stores/reward-terms';
import { InstagramService } from '../instagram/instagram.service';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import {
  ViewCountPort,
  ViewCountUnavailableError,
} from '../integrations/view-count/view-count.port';
import { JobRunContext, JobScheduler } from '../jobs/job-scheduler';
import { NotificationsService } from '../notifications/notifications.service';
import {
  forcePayoutKey,
  forcePayoutRefundKey,
  HALT_AFTER_UNREADABLE_DAYS,
  settleJobKey,
  settlePayoutKey,
  settleRefundKey,
  SNAPSHOT_DAYS,
  snapshotJobKey,
  VIEW_COUNT_HALT_REASON,
} from './job-keys';
import { assertEscrowMatches } from './escrow-check';
import { PayoutsService } from './payouts.service';
import { RefundsService } from './refunds.service';
import { SettlementFinishService } from './settlement-finish.service';
import { pickFinalViews, settleReward } from './settlement-math';
import { SettlementsRepository } from './settlements.repository';
import { ViewReportService } from './view-report.service';

@Injectable()
export class SettlementsService {
  private readonly logger = new Logger(SettlementsService.name);

  constructor(
    private readonly repository: SettlementsRepository,
    private readonly collaborations: CollaborationsRepository,
    private readonly instagram: InstagramService,
    private readonly viewCount: ViewCountPort,
    private readonly jobs: JobScheduler,
    private readonly operatorAlert: OperatorAlertPort,
    private readonly notifications: NotificationsService,
    private readonly ledger: LedgerService,
    private readonly payouts: PayoutsService,
    private readonly refunds: RefundsService,
    private readonly finisher: SettlementFinishService,
    private readonly viewReport: ViewReportService,
    private readonly clock: Clock,
  ) {}

  // 크리에이터의 정산 내역(지갑)이 읽는 값. 쓰지 않는다.
  payoutsOfCreator(creatorId: string): Promise<Payout[]> {
    return this.repository.listPayoutsForCreator(creatorId);
  }

  settlementsOf(collaborationIds: string[]): Promise<Map<string, Settlement>> {
    return this.repository.settlementsFor(collaborationIds);
  }

  // view-snapshot 작업: 그날의 조회수를 읽어 저장한다. 같은 날 작업이 다시 돌아도 한 번만 읽고 한 줄만 남는다.
  // 가장 최근 세 줄이 모두 null이면(읽지 못한 날이 연속 3일) 정산하지 않고 멈춘다.
  // 마지막 시도에서 읽기가 예상 밖의 오류로 실패하면 던지지 않고 null로 저장한다: 날이 줄 없이 빠지지 않게(3일 규칙은 날을 센다).
  async takeSnapshot(
    collaborationId: string,
    dayIndex: number,
    context?: JobRunContext,
  ): Promise<void> {
    const collaboration = await this.collaborations.findById(collaborationId);
    if (!collaboration) return;
    // 멈추는 도중에 죽었다면 남은 단계(작업 취소, 알림)를 마친다. 이미 한 일은 같은 키라 그대로다.
    if (isViewCountHalt(collaboration)) {
      await this.finishHalt(collaboration);
      return;
    }
    if (collaboration.stage !== 'COUNTING') return;
    // 조회수 수당이 없는 협업은 조회수를 세지 않는다(운영 재개가 남긴 작업이 돌아도 아무 일 없다).
    if (!hasViewPay(readTerms(collaboration.terms))) return;
    // 계산이 이미 만들어졌다면(확인 전) 측정은 끝난 것이다: 늦게 도는 마지막 날 작업이 확인을 기다리는 협업을 멈추지 않게 한다.
    if (await this.repository.findSettlement(collaboration.id)) return;

    await this.ensureSnapshot(collaboration, dayIndex, context);
    await this.haltIfUnreadable(collaboration);
  }

  // settle 작업: 7일 집계가 끝난 협업의 정산을 "계산 만들기"와 "확인 완료"로 나눈다.
  // - 조회수 수당이 없는 협업(고정 현금만)은 확인할 자료가 없어 한 걸음에 확정한다(NOT_NEEDED).
  // - 조회수 수당이 있는 협업은 계산(정산 행 UNCONFIRMED)만 만들고 알린다. 장부·단계·지급·환급은 확인 완료(ViewReportService.confirm)가 한다.
  // 같은 작업이 몇 번 돌아도 지급·환급·알림은 한 번씩만 일어난다. key는 장부의 중복 방지 키다('settle:' + 협업 id).
  // 커밋(정산 행, 장부, 단계, 지급·환급 행)은 한 트랜잭션이고, 그 뒤 단계는 정산 행을 보고 이어서 한다.
  // 그래서 커밋 뒤에 죽어 다시 돌 때는 단계가 이미 SETTLED여도 남은 단계를 마친다.
  async settle(
    collaborationId: string,
    key: string,
    context?: JobRunContext,
  ): Promise<void> {
    const collaboration = await this.collaborations.findById(collaborationId);
    if (!collaboration) return;
    // 조회수를 읽지 못해 멈추는 도중에 죽었다면 남은 정리(작업 취소, 알림)를 마친다.
    if (isViewCountHalt(collaboration)) {
      await this.finishHalt(collaboration);
      return;
    }
    if (collaboration.stage === 'COUNTING') {
      // 계산이 이미 있으면(확인 전) 다시 만들지 않고 알림 단계만 이어서 한다.
      const existing = await this.repository.findSettlement(collaborationId);
      if (existing && existing.status !== 'CONFIRMED') {
        await this.viewReport.announceCalculation(collaborationId);
        return;
      }
      const outcome = await this.settleCounting(collaboration, key, context);
      if (outcome === 'calculated') {
        await this.viewReport.announceCalculation(collaborationId);
        return;
      }
      if (outcome !== 'settled') return;
    } else if (collaboration.stage !== 'SETTLED') {
      return;
    }
    const settlement = await this.repository.findSettlement(collaborationId);
    if (settlement && settlement.status === 'CONFIRMED') {
      await this.finisher.finish(collaboration, settlement, context);
    }
  }

  private async settleCounting(
    collaboration: Collaboration,
    key: string,
    context?: JobRunContext,
  ): Promise<'settled' | 'calculated' | 'halted' | 'gone'> {
    // 조회수 수당이 없는 협업(고정 현금만)은 조회수를 읽지 않고 측정 기간이 끝나는 날 고정 현금으로 정산한다.
    // 스냅샷이 없어 아래의 3일 실패 규칙을 보면 안 된다(거짓으로 멈춘다).
    if (!hasViewPay(readTerms(collaboration.terms))) {
      const fixed = await this.repository.transaction<'settled', 'gone'>(
        async (tx, rollback) => {
          const committed = await this.commitSettlement(
            tx,
            collaboration,
            'COUNTING',
            (escrow) => planFixed(collaboration, escrow),
            key,
            { confirmedBy: 'NOT_NEEDED' },
          );
          return committed ? 'settled' : rollback('gone');
        },
      );
      return fixed === 'settled' ? 'settled' : 'gone';
    }
    // 7일째 줄이 없으면 이 자리에서 읽는다: 같은 시각의 7일째 작업과 이 작업의 실행 순서에 기대지 않는다
    // (같은 날 줄은 유일 제약이 하나만 남긴다).
    await this.ensureSnapshot(collaboration, SNAPSHOT_DAYS, context);
    // 7일째 작업이 먼저 돌았다면 그 작업이 했을 판정을 여기서도 한다: 5~7일을 읽지 못했는데 4일째 값으로 정산하면 안 된다.
    // 정산 시점에는 5~7일의 작업이 이미 끝났어야 하므로, 줄이 없는 날도 읽지 못한 날로 센다.
    if (await this.haltIfUnreadable(collaboration, { atSettlement: true })) {
      return 'halted';
    }
    const snapshots = await this.repository.listSnapshots(collaboration.id);
    const finalViews = pickFinalViews(snapshots, SNAPSHOT_DAYS);
    // 읽은 값이 하나도 없다(위 판정에 걸리기 전의 경우): 0으로 정산하지 않고 멈춘다.
    if (finalViews === null) {
      await this.halt(collaboration);
      return 'halted';
    }
    // 계산만 만든다. 돈은 확인 완료 때 움직인다.
    const created = await this.viewReport.createCalculation(collaboration.id);
    return created === 'gone' ? 'gone' : 'calculated';
  }

  // 정산의 커밋 부분(단계, 정산 행, 장부, 지급·환급 행)을 호출한 쪽의 트랜잭션 안에서 한다.
  // 조회수 정산(작업)과 운영 명령(조회수로 재개, 강제 지급)이 같은 길을 쓰므로, 장부 키와 돈 행 키가 같아 어느 길로든 한 번만 정산된다.
  // 조건부 갱신이 먼저다: 동시에 도는 같은 작업이나 명령 가운데 하나만 통과한다. 졌으면 null이고 호출한 쪽이 되돌린다.
  // plan은 에스크로 잔액을 받아 지급·환급을 정한다(같은 트랜잭션에서 읽어, 읽은 뒤 장부가 바뀌지 않게 한다).
  private async commitSettlement(
    tx: Prisma.TransactionClient,
    collaboration: Collaboration,
    from: CollaborationStage,
    plan: (escrow: number) => {
      finalViews: number | null;
      payout: number;
      refund: number;
      fixedCash: number;
      viewPay: number;
    },
    key: string,
    options: {
      // 확인 완료를 한 쪽. 이 길(한 걸음 정산)은 확인할 자료가 없거나 운영자가 정한 것이라 NOT_NEEDED·OPERATOR다.
      confirmedBy: SettlementConfirmer;
      patch?: CollaborationPatch;
      payoutKey?: string;
      refundKey?: string;
      // 지급·환급이 정산이 아니라 운영 명령의 몫일 때의 장부 줄. 기본은 일반 정산의 줄이다.
      postings?: (p: { payout: number; refund: number }) => Posting[];
    },
  ): Promise<{ payout: number; refund: number } | null> {
    const now = this.clock.now();
    if (
      !(await this.collaborations.advance(
        collaboration.id,
        from,
        'SETTLED',
        options.patch ?? {},
        tx,
      ))
    ) {
      return null;
    }
    const escrow = await this.ledger.escrowBalance(collaboration.id, tx);
    const { finalViews, payout, refund, fixedCash, viewPay } = plan(escrow);
    const created = await this.repository.createSettlement(
      {
        collaborationId: collaboration.id,
        finalViews,
        payoutAmount: payout,
        refundAmount: refund,
        fixedCashAmount: fixedCash,
        viewPayAmount: viewPay,
        status: 'CONFIRMED',
        calculatedAt: now,
        confirmDueAt: null,
        settledAt: now,
        confirmedAt: now,
        confirmedBy: options.confirmedBy,
      },
      tx,
    );
    if (!created) return null;
    const posted = await this.ledger.post(
      collaboration.id,
      (options.postings ?? postingsForSettlement)({ payout, refund }),
      key,
      tx,
    );
    if (posted === 'duplicate') {
      // 정산 행이 없는데 정산 장부가 있다면 상태가 어긋난 것이다. 조용히 넘기지 않고 되돌려 드러낸다.
      throw new Error('정산 전인 협업에 정산 장부 줄이 이미 있어요.');
    }
    await this.payouts.request(
      collaboration.id,
      payout,
      options.payoutKey ?? settlePayoutKey(collaboration.id),
      now,
      tx,
    );
    await this.refunds.request(
      collaboration.id,
      refund,
      options.refundKey ?? settleRefundKey(collaboration.id),
      tx,
    );
    return { payout, refund };
  }

  // 운영 명령 resume-settlement: 조회수를 읽지 못해 멈춘 협업을 운영자가 준 조회수로 정산한다(호출한 쪽의 트랜잭션 안).
  // 지급과 환급은 일반 정산과 같은 키·같은 줄이다. 졌으면(그사이 다른 길이 정산·변경했다) null이다.
  settleHaltedWithViews(
    tx: Prisma.TransactionClient,
    collaboration: Collaboration,
    views: number,
  ): Promise<{ payout: number; refund: number } | null> {
    return this.commitSettlement(
      tx,
      collaboration,
      'HALTED',
      (escrow) => planByViews(collaboration, views, escrow),
      settleJobKey(collaboration.id),
      {
        confirmedBy: 'OPERATOR',
        patch: { haltedReason: null, stageBeforeHalt: null },
      },
    );
  }

  // 운영 명령 force-payout: 보관액 안에서 amount를 지급하고 남은 보관액은 사장님에게 돌려준 뒤 정산으로 끝낸다.
  // 수수료는 일반 정산처럼 수익으로 남는다. amount가 보관액보다 크면 던진다(호출한 쪽이 먼저 확인하지만 한 번 더 막는다).
  settleForced(
    tx: Prisma.TransactionClient,
    collaboration: Collaboration,
    amount: number,
  ): Promise<{ payout: number; refund: number } | null> {
    return this.commitSettlement(
      tx,
      collaboration,
      collaboration.stage,
      (escrow) => {
        if (!Number.isInteger(amount) || amount < 0 || amount > escrow) {
          throw new Error(
            `강제 지급액(${amount})이 보관액(${escrow})을 넘거나 올바르지 않아요.`,
          );
        }
        // 운영자가 정한 금액이라 고정 현금과 조회수 수당으로 나누지 않고 전부 수당 칸에 둔다(옛 정산 행 이전과 같다).
        return {
          finalViews: null,
          payout: amount,
          refund: escrow - amount,
          fixedCash: 0,
          viewPay: amount,
        };
      },
      forcePayoutKey(collaboration.id),
      {
        confirmedBy: 'OPERATOR',
        patch: { haltedReason: null, stageBeforeHalt: null },
        payoutKey: forcePayoutKey(collaboration.id),
        refundKey: forcePayoutRefundKey(collaboration.id),
        postings: ({ payout, refund }) => [
          ...postingsForForcedPayout({ amount: payout }),
          ...postingsForForcedRefund({ amount: refund }),
        ],
      },
    );
  }

  // 정산 커밋 뒤의 단계(작업 등록, 알림, PG 환급)를 협업 id로 이어서 한다. 운영 명령이 정산을 커밋한 뒤 부른다.
  finishSettlementOf(
    collaborationId: string,
    keys?: { payout: string; refund: string },
  ): Promise<void> {
    return this.finisher.finishOf(collaborationId, keys);
  }

  // 그날의 줄이 없을 때만 읽어서 저장한다. 읽지 못하면 views = null이다(0이 아니다).
  async ensureSnapshot(
    collaboration: Collaboration,
    dayIndex: number,
    context?: JobRunContext,
  ): Promise<void> {
    const existing = await this.repository.findSnapshot(
      collaboration.id,
      dayIndex,
    );
    if (existing) return;
    const views = await this.readViews(collaboration, context);
    await this.repository.createSnapshotIfAbsent({
      collaborationId: collaboration.id,
      dayIndex,
      views,
      takenAt: this.clock.now(),
    });
  }

  // 가장 최근 세 줄이 모두 null이면(읽지 못한 날이 연속 3일) 멈춘다. 멈췄으면 true다.
  // 날마다의 스냅샷 작업과 7일째의 정산 작업이 같은 판정을 쓴다: 어느 쪽이 먼저 돌아도 결과가 같다.
  // atSettlement이면 줄을 세는 것에 더해 마지막 3일(5~7일)을 날로 센다: 줄이 없는 날(작업이 시도를 다 쓰고 죽었거나
  // 작업자를 다시 켜느라 건너뛴 날)도 읽지 못한 날이라, 5일째 null·6일째 줄 없음·7일째 null이면 4일째 값으로 정산하지 않는다.
  private async haltIfUnreadable(
    collaboration: Collaboration,
    options: { atSettlement?: boolean } = {},
  ): Promise<boolean> {
    const latest = await this.repository.latestSnapshots(
      collaboration.id,
      HALT_AFTER_UNREADABLE_DAYS,
    );
    const rowsAllNull =
      latest.length === HALT_AFTER_UNREADABLE_DAYS &&
      latest.every((s) => s.views === null);
    let daysAllUnreadable = false;
    if (options.atSettlement) {
      const byDay = new Map(
        (await this.repository.listSnapshots(collaboration.id)).map((s) => [
          s.dayIndex,
          s.views,
        ]),
      );
      daysAllUnreadable = Array.from(
        { length: HALT_AFTER_UNREADABLE_DAYS },
        (_, i) => SNAPSHOT_DAYS - i,
      ).every((day) => (byDay.get(day) ?? null) === null);
    }
    if (!rowsAllNull && !daysAllUnreadable) return false;
    await this.halt(collaboration);
    return true;
  }

  // 조회수 집계를 읽지 못해 협업을 멈춘다. 돈은 에스크로에 그대로 있다.
  // 조건부 전이가 이겼을 때만(또는 이미 조회수 사유로 멈춰 있을 때만) 뒷정리와 운영자 알림으로 간다:
  // 전이에서 졌다면(동시 정산 등) 멈춘 것이 아니므로 거짓 경보를 보내지 않는다.
  async halt(collaboration: Collaboration): Promise<void> {
    await this.collaborations.advance(collaboration.id, 'COUNTING', 'HALTED', {
      stageBeforeHalt: 'COUNTING',
      haltedReason: VIEW_COUNT_HALT_REASON,
    });
    const fresh = await this.collaborations.findById(collaboration.id);
    if (fresh && isViewCountHalt(fresh)) await this.finishHalt(fresh);
  }

  // 멈춘 뒤의 정리: 운영자와 양쪽에 알리고, 정산과 남은 조회수 작업은 맨 뒤에 취소한다.
  // 알림이 먼저다: 운영자 알림이나 알림함이 이 작업의 재시도 기간 내내 죽어 있어도 작업이 남아 있어야 다시 돌아 알릴 수 있다
  // (취소가 먼저면 다시 돌 작업이 없어 알림 없이 멈춘 협업만 남는다). 취소는 오류를 삼킨다.
  // 멈추는 도중에 죽어 다시 돌 때도 여기로 오므로, 운영자 알림은 이미 나갔어도 다시 나갈 수 있다(한 번도 안 가는 것보다 낫다).
  // 사용자 알림은 같은 키라 한 건이다.
  private async finishHalt(collaboration: Collaboration): Promise<void> {
    await this.operatorAlert.alert({
      subject: '조회수를 읽지 못해 협업이 멈췄어요. 확인해 주세요.',
      body: `협업 ID: ${collaboration.id}`,
    });
    const target = { kind: 'COLLABORATION', id: collaboration.id } as const;
    const dedupeKey = `halted:${collaboration.id}`;
    await this.notifications.notify({
      userId: collaboration.commissionerId,
      role: 'STORE',
      kind: 'COLLABORATION_HALTED',
      target,
      dedupeKey,
    });
    await this.notifications.notify({
      userId: collaboration.creatorId,
      role: 'CREATOR',
      kind: 'COLLABORATION_HALTED',
      target,
      dedupeKey,
    });
    await this.jobs.cancel(settleJobKey(collaboration.id));
    for (let day = 0; day <= SNAPSHOT_DAYS; day += 1) {
      await this.jobs.cancel(snapshotJobKey(collaboration.id, day));
    }
  }

  // 연결된 인스타그램 계정이 없으면 읽을 수 없다(수락 조건과 해제 제한이 있어 보통은 있다). 0회가 아니라 읽기 실패다.
  private async readViews(
    collaboration: Collaboration,
    context?: JobRunContext,
  ): Promise<number | null> {
    if (!collaboration.submittedUrl || !collaboration.submittedAt) return null;
    if (!(await this.instagram.getConnection(collaboration.creatorId))) {
      this.logger.warn('연결된 인스타그램 계정이 없어 조회수를 읽지 못했어요.');
      return null;
    }
    try {
      const views = await this.viewCount.read({
        url: collaboration.submittedUrl,
        submittedAt: collaboration.submittedAt,
      });
      // 음수나 소수는 잘못 읽은 값이다. 그 값으로 돈을 움직이지 않는다.
      return Number.isInteger(views) && views >= 0 ? views : null;
    } catch (error) {
      if (error instanceof ViewCountUnavailableError) return null;
      // 예상 밖의 오류는 던져 큐가 다시 시도하게 한다. 마지막 시도라면 더 던져도 날이 비므로 읽지 못한 날로 기록한다.
      if (context?.finalAttempt) {
        this.logger.error(
          `마지막 시도에서도 조회수를 읽지 못해 읽지 못한 날로 기록해요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
        return null;
      }
      throw error;
    }
  }
}

export function isViewCountHalt(collaboration: Collaboration): boolean {
  return (
    collaboration.stage === 'HALTED' &&
    collaboration.haltedReason === VIEW_COUNT_HALT_REASON
  );
}

// 조건 사본(고정 현금, 조회수 단가, 상한)으로 지급·환급을 정한다. 상한은 에스크로 잔액이 아니라 조건의 값이다.
// 조회수 수당이 없는 협업은 조회수로 정산하지 않는다(planFixed).
function planByViews(
  collaboration: Collaboration,
  views: number,
  escrow: number,
): {
  finalViews: number;
  payout: number;
  refund: number;
  fixedCash: number;
  viewPay: number;
} {
  const terms = readTerms(collaboration.terms);
  if (terms.viewRatePerThousand === null || terms.perViewCap === null) {
    throw new Error('조회수 수당이 없는 협업은 조회수로 정산할 수 없어요.');
  }
  assertEscrowMatches(terms, escrow);
  const { viewPay, payout, refund } = settleReward({
    views,
    ratePerThousand: terms.viewRatePerThousand,
    cap: terms.perViewCap,
    fixedCash: terms.fixedCash,
  });
  return {
    finalViews: views,
    payout,
    refund,
    fixedCash: terms.fixedCash,
    viewPay,
  };
}

// 고정 현금만 있는 협업의 정산: 조회수 없이(finalViews = null) 고정 현금 전부를 지급하고 환급은 없다.
function planFixed(
  collaboration: Collaboration,
  escrow: number,
): {
  finalViews: null;
  payout: number;
  refund: number;
  fixedCash: number;
  viewPay: number;
} {
  const terms = readTerms(collaboration.terms);
  assertEscrowMatches(terms, escrow);
  const { viewPay, payout, refund } = settleReward({
    views: 0,
    ratePerThousand: 0,
    cap: 0,
    fixedCash: terms.fixedCash,
  });
  return {
    finalViews: null,
    payout,
    refund,
    fixedCash: terms.fixedCash,
    viewPay,
  };
}
