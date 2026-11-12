import { Injectable, Logger } from '@nestjs/common';
import { Collaboration, Settlement } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { postingsForSettlement } from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { Clock } from '../common/clock';
import { InstagramService } from '../instagram/instagram.service';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import {
  ViewCountPort,
  ViewCountUnavailableError,
} from '../integrations/view-count/view-count.port';
import { JobRunContext, JobScheduler } from '../jobs/job-scheduler';
import { NotificationsService } from '../notifications/notifications.service';
import {
  HALT_AFTER_UNREADABLE_DAYS,
  settleJobKey,
  settlePayoutKey,
  settleRefundKey,
  SNAPSHOT_DAYS,
  snapshotJobKey,
  VIEW_COUNT_HALT_REASON,
} from './job-keys';
import { PayoutsService } from './payouts.service';
import { RefundsService } from './refunds.service';
import { settle as settleViews } from './settlement-math';
import { SettlementsRepository } from './settlements.repository';

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
    private readonly clock: Clock,
  ) {}

  // view-snapshot 작업: 그날의 조회수를 읽어 저장한다. 같은 날 작업이 다시 돌아도 한 번만 읽고 한 줄만 남는다.
  // 가장 최근 세 줄이 모두 null이면(읽지 못한 날이 연속 3일) 정산하지 않고 멈춘다.
  async takeSnapshot(collaborationId: string, dayIndex: number): Promise<void> {
    const collaboration = await this.collaborations.findById(collaborationId);
    if (!collaboration) return;
    // 멈추는 도중에 죽었다면 남은 단계(작업 취소, 알림)를 마친다. 이미 한 일은 같은 키라 그대로다.
    if (isViewCountHalt(collaboration)) {
      await this.finishHalt(collaboration);
      return;
    }
    if (collaboration.stage !== 'COUNTING') return;

    await this.ensureSnapshot(collaboration, dayIndex);
    await this.haltIfUnreadable(collaboration);
  }

  // settle 작업: 7일 집계가 끝난 협업을 정산한다. 같은 작업이 몇 번 돌아도 지급·환급·알림은 한 번씩만 일어난다.
  // key는 장부의 중복 방지 키다('settle:' + 협업 id).
  // 커밋(정산 행, 장부, 단계, 지급·환급 행)은 한 트랜잭션이고, 그 뒤 단계(작업 등록, PG 환급, 알림)는 정산 행을 보고 이어서 한다.
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
      if ((await this.settleCounting(collaboration, key)) !== 'settled') return;
    } else if (collaboration.stage !== 'SETTLED') {
      return;
    }
    const settlement = await this.repository.findSettlement(collaborationId);
    if (settlement) {
      await this.finishSettlement(collaboration, settlement, context);
    }
  }

  private async settleCounting(
    collaboration: Collaboration,
    key: string,
  ): Promise<'settled' | 'halted' | 'gone'> {
    // 7일째 줄이 없으면 이 자리에서 읽는다: 같은 시각의 7일째 작업과 이 작업의 실행 순서에 기대지 않는다
    // (같은 날 줄은 유일 제약이 하나만 남긴다).
    await this.ensureSnapshot(collaboration, SNAPSHOT_DAYS);
    // 7일째 작업이 먼저 돌았다면 그 작업이 했을 판정을 여기서도 한다: 5~7일을 읽지 못했는데 4일째 값으로 정산하면 안 된다.
    if (await this.haltIfUnreadable(collaboration)) return 'halted';
    const snapshots = await this.repository.listSnapshots(collaboration.id);
    const finalViews = pickFinalViews(snapshots);
    // 읽은 값이 하나도 없다(위 판정에 걸리기 전의 경우): 0으로 정산하지 않고 멈춘다.
    if (finalViews === null) {
      await this.halt(collaboration);
      return 'halted';
    }
    const perViewAmount = readPerViewAmount(collaboration.terms);
    const now = this.clock.now();

    const outcome = await this.repository.transaction<'settled', 'gone'>(
      async (tx, rollback) => {
        // 조건부 갱신이 먼저다: 동시에 도는 같은 작업 가운데 하나만 통과한다.
        if (
          !(await this.collaborations.advance(
            collaboration.id,
            'COUNTING',
            'SETTLED',
            {},
            tx,
          ))
        ) {
          return rollback('gone');
        }
        // 상한은 에스크로에 실제로 있는 돈이다(결제한 상한과 같다). 같은 트랜잭션에서 읽어, 읽은 뒤 장부가 바뀌지 않게 한다.
        const escrow = await this.ledger.escrowBalance(collaboration.id, tx);
        const { payout, refund } = settleViews({
          views: finalViews,
          perViewAmount,
          cap: escrow,
        });
        const created = await this.repository.createSettlement(
          {
            collaborationId: collaboration.id,
            finalViews,
            payoutAmount: payout,
            refundAmount: refund,
            settledAt: now,
          },
          tx,
        );
        if (!created) return rollback('gone');
        const posted = await this.ledger.post(
          collaboration.id,
          postingsForSettlement({ payout, refund }),
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
          settlePayoutKey(collaboration.id),
          now,
          tx,
        );
        await this.refunds.request(
          collaboration.id,
          refund,
          settleRefundKey(collaboration.id),
          tx,
        );
        return 'settled';
      },
    );
    return outcome === 'settled' ? 'settled' : 'gone';
  }

  // 커밋 뒤의 단계. 모두 같은 키라 다시 불러도 한 번만 일어난다.
  // 크리에이터의 알림을 사장님 환급보다 앞에 둔다: PG 환급이 계속 실패해도 크리에이터의 정산 알림은 막히지 않는다.
  private async finishSettlement(
    collaboration: Collaboration,
    settlement: Settlement,
    context?: JobRunContext,
  ): Promise<void> {
    const payout = await this.payouts.findByKey(
      settlePayoutKey(collaboration.id),
    );
    if (payout?.status === 'PENDING') await this.payouts.schedule(payout);

    const target = { kind: 'WALLET', id: null } as const;
    // 0원 정산의 알림("정산 0원…")은 보내지 않는다.
    if (settlement.payoutAmount > 0) {
      await this.notifications.notify({
        userId: collaboration.creatorId,
        role: 'CREATOR',
        kind: 'SETTLEMENT_CONFIRMED',
        params: { amount: settlement.payoutAmount },
        target,
        dedupeKey: `settled:${collaboration.id}`,
      });
    }
    const refund = await this.refunds.findByKey(
      settleRefundKey(collaboration.id),
    );
    if (refund) await this.refunds.execute(refund.id, context);
    if (settlement.refundAmount > 0) {
      await this.notifications.notify({
        userId: collaboration.commissionerId,
        role: 'STORE',
        kind: 'SETTLEMENT_REFUNDED',
        params: { amount: settlement.refundAmount },
        target,
        dedupeKey: `settle-refund:${collaboration.id}`,
      });
    }
  }

  // 그날의 줄이 없을 때만 읽어서 저장한다. 읽지 못하면 views = null이다(0이 아니다).
  async ensureSnapshot(
    collaboration: Collaboration,
    dayIndex: number,
  ): Promise<void> {
    const existing = await this.repository.findSnapshot(
      collaboration.id,
      dayIndex,
    );
    if (existing) return;
    const views = await this.readViews(collaboration);
    await this.repository.createSnapshotIfAbsent({
      collaborationId: collaboration.id,
      dayIndex,
      views,
      takenAt: this.clock.now(),
    });
  }

  // 가장 최근 세 줄이 모두 null이면(읽지 못한 날이 연속 3일) 멈춘다. 멈췄으면 true다.
  // 날마다의 스냅샷 작업과 7일째의 정산 작업이 같은 판정을 쓴다: 어느 쪽이 먼저 돌아도 결과가 같다.
  private async haltIfUnreadable(
    collaboration: Collaboration,
  ): Promise<boolean> {
    const latest = await this.repository.latestSnapshots(
      collaboration.id,
      HALT_AFTER_UNREADABLE_DAYS,
    );
    if (
      latest.length < HALT_AFTER_UNREADABLE_DAYS ||
      latest.some((s) => s.views !== null)
    ) {
      return false;
    }
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

  // 멈춘 뒤의 정리: 정산과 남은 조회수 작업을 취소하고, 운영자와 양쪽에 알린다.
  // 멈추는 도중에 죽어 다시 돌 때도 여기로 오므로, 운영자 알림은 이미 나갔어도 다시 나갈 수 있다(알림이 한 번도 안 가는 것보다 낫다).
  // 사용자 알림은 같은 키라 한 건이다.
  private async finishHalt(collaboration: Collaboration): Promise<void> {
    await this.jobs.cancel(settleJobKey(collaboration.id));
    for (let day = 0; day <= SNAPSHOT_DAYS; day += 1) {
      await this.jobs.cancel(snapshotJobKey(collaboration.id, day));
    }
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
  }

  // 연결된 인스타그램 계정이 없으면 읽을 수 없다(수락 조건과 해제 제한이 있어 보통은 있다). 0회가 아니라 읽기 실패다.
  private async readViews(
    collaboration: Collaboration,
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

// 최종 조회수: 7일째 값, 읽지 못했다면 가장 최근에 읽은 값. 하나도 없으면 null이다.
function pickFinalViews(
  snapshots: { dayIndex: number; views: number | null }[],
): number | null {
  const day7 = snapshots.find((s) => s.dayIndex === SNAPSHOT_DAYS);
  if (day7?.views != null) return day7.views;
  const readable = snapshots
    .filter((s) => s.views !== null)
    .sort((a, b) => b.dayIndex - a.dayIndex);
  return readable[0]?.views ?? null;
}

// 협업에 사본으로 남은 수락 당시의 조건에서 건당 금액을 꺼낸다. 조회수 협업에 없으면 데이터가 어긋난 것이라 던진다.
function readPerViewAmount(terms: unknown): number {
  const amount = (terms as Record<string, unknown> | null)?.perViewAmount;
  if (typeof amount !== 'number' || !Number.isInteger(amount) || amount < 0) {
    throw new Error('조회수 협업의 조건에 건당 금액이 없어요.');
  }
  return amount;
}
