import { Injectable } from '@nestjs/common';
import { Collaboration, Settlement } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import {
  ViewCountPort,
  ViewCountUnavailableError,
} from '../integrations/view-count/view-count.port';
import { JobRunContext } from '../jobs/job-scheduler';
import { NotificationsService } from '../notifications/notifications.service';
import { StoresService } from '../stores/stores.service';
import { hasViewPay, readTerms } from '../stores/reward-terms';
import { settlePayoutKey, settleRefundKey } from './job-keys';
import { PayoutsService } from './payouts.service';
import { RefundsService } from './refunds.service';
import { multiplierTenthsOf } from './settlement-math';
import { SettlementsRepository } from './settlements.repository';

// 정산 확정(장부와 지급·환급 행이 커밋된 뒤)의 단계: 지급 작업 등록, 알림, PG 환급, 평소 조회수 읽기.
// 일반 정산(settle 작업), 조회 자료 확인(ViewReportService), 운영 명령이 같은 길을 쓴다. 모두 같은 키라 다시 불러도 한 번만 일어난다.
@Injectable()
export class SettlementFinishService {
  constructor(
    private readonly repository: SettlementsRepository,
    private readonly collaborations: CollaborationsRepository,
    private readonly viewCount: ViewCountPort,
    private readonly notifications: NotificationsService,
    private readonly payouts: PayoutsService,
    private readonly refunds: RefundsService,
    private readonly stores: StoresService,
    private readonly clock: Clock,
  ) {}

  // 협업 id로 이어서 한다. 협업이나 정산 행이 없으면 아무 일도 하지 않는다.
  // 강제 지급은 지급·환급 행의 키가 일반 정산과 달라 keys로 알려 준다.
  async finishOf(
    collaborationId: string,
    keys?: { payout: string; refund: string },
    context?: JobRunContext,
  ): Promise<void> {
    const collaboration = await this.collaborations.findById(collaborationId);
    const settlement = collaboration
      ? await this.repository.findSettlement(collaborationId)
      : null;
    if (collaboration && settlement) {
      await this.finish(collaboration, settlement, context, keys);
    }
  }

  // 커밋 뒤의 단계. 확인 완료(CONFIRMED)된 정산에서만 부른다.
  // 크리에이터의 알림을 사장님 환급보다 앞에 둔다: PG 환급이 계속 실패해도 크리에이터의 정산 알림은 막히지 않는다.
  async finish(
    collaboration: Collaboration,
    settlement: Settlement,
    context?: JobRunContext,
    keys: { payout: string; refund: string } = {
      payout: settlePayoutKey(collaboration.id),
      refund: settleRefundKey(collaboration.id),
    },
  ): Promise<void> {
    const payout = await this.payouts.findByKey(keys.payout);
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
    const refund = await this.refunds.findByKey(keys.refund);
    if (refund) await this.refunds.execute(refund.id, context);
    // 평소 조회수는 사장님이 알림으로 7일 결과(G1)를 열기 전에 채운다.
    await this.recordUsualViews(collaboration, settlement);
    await this.notifyStoreOfResult(collaboration, settlement);
  }

  // 사장님에게 정산이 끝났다고 알리고, 누르면 7일 결과(G1)가 열리게 한다. 이 알림이 G1로 가는 유일한 길이라
  // 돌려줄 돈이 0원이어도 보낸다(금액 문장은 카탈로그가 뺀다). 식사권만 있는 협업은 G1이 없어 보내지 않는다.
  // 제출 링크가 없는 협업(운영 명령의 강제 지급)은 G1이 열리지 않아 가는 곳을 지갑으로 둔다.
  private async notifyStoreOfResult(
    collaboration: Collaboration,
    settlement: Settlement,
  ): Promise<void> {
    if (
      settlement.refundAmount === 0 &&
      collaboration.settlementMethod === 'NONE'
    ) {
      return;
    }
    const fixedOnly = !hasViewPay(readTerms(collaboration.terms));
    await this.notifications.notify({
      userId: collaboration.commissionerId,
      role: 'STORE',
      kind: 'SETTLEMENT_REFUNDED',
      params: fixedOnly
        ? { amount: settlement.refundAmount, fixedOnly: 1 }
        : { amount: settlement.refundAmount },
      target: collaboration.submittedUrl
        ? { kind: 'STORE_RESULT', id: collaboration.id }
        : { kind: 'WALLET', id: null },
      dedupeKey: `settle-refund:${collaboration.id}`,
    });
  }

  // 가게 인스타그램 계정의 평소 조회수를 한 번 읽어 배수와 함께 정산 줄에 저장한다.
  // 읽은 적이 있으면(읽지 못한 것도 읽은 것이다) 다시 읽지 않는다: 같은 협업의 결과가 읽을 때마다 달라지지 않게.
  // 조회수를 세지 않은 협업(고정 현금만)과 최종 조회수가 없는 정산(강제 지급)은 비교할 값이 없어 건너뛴다.
  // 조회수 계정을 못 읽는 것(ViewCountUnavailableError)만 "읽지 못함"으로 저장하고 넘어간다. 그 밖의 오류는 던진다:
  // 정산 작업이 실패로 남아 다시 돌 때 usualReadAt이 비어 있으면 이어서 읽고, 삼키면 영영 비어 비교 상자가 숨겨진다.
  private async recordUsualViews(
    collaboration: Collaboration,
    settlement: Settlement,
  ): Promise<void> {
    if (settlement.usualReadAt) return;
    if (
      !hasViewPay(readTerms(collaboration.terms)) ||
      settlement.finalViews === null
    ) {
      return;
    }
    const handle = collaboration.storeId
      ? await this.stores.getInstagramHandle(collaboration.storeId)
      : null;
    let usualViews: number | null = null;
    if (handle) {
      try {
        const average = await this.viewCount.readAccountAverage(handle);
        // 음수나 소수는 잘못 읽은 값이다. 0은 나눌 수 없어 쓰지 않는다.
        usualViews = Number.isInteger(average) && average > 0 ? average : null;
      } catch (error) {
        // 못 읽은 것만 "읽지 못함"으로 저장한다. 그 밖의 오류(DB, 코드 버그)는 던져 작업이 다시 돌게 한다.
        if (!(error instanceof ViewCountUnavailableError)) throw error;
      }
    }
    await this.repository.saveUsualViews(settlement.id, {
      usualViews,
      multiplierTenths:
        usualViews === null
          ? null
          : multiplierTenthsOf(settlement.finalViews, usualViews),
      readAt: this.clock.now(),
    });
  }
}
