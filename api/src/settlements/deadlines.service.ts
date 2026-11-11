import { Injectable } from '@nestjs/common';
import { Collaboration } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { postingsForFullRefund } from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PaymentsService } from '../payments/payments.service';
import { unsubmittedRefundKey } from './job-keys';
import { RefundsService } from './refunds.service';
import { SettlementsRepository } from './settlements.repository';

// 링크 제출 기한에 걸린 작업: 기한까지 올리지 않았을 때의 환급과 기한 알림.
@Injectable()
export class DeadlinesService {
  constructor(
    private readonly repository: SettlementsRepository,
    private readonly collaborations: CollaborationsRepository,
    private readonly ledger: LedgerService,
    private readonly payments: PaymentsService,
    private readonly refunds: RefundsService,
    private readonly notifications: NotificationsService,
  ) {}

  // refund-unsubmitted 작업: 기한까지 제출이 없으면 낸 돈 전부(상한 + 수수료)를 돌려주고 협업을 끝낸다.
  // 같은 작업이 몇 번 돌아도 환급과 알림은 한 번씩이다. 환급 행은 장부·단계와 한 트랜잭션에서 만들고,
  // PG 환급과 알림은 커밋 뒤에 행을 보고 이어서 한다(커밋 뒤에 죽어 다시 돌아도 마친다).
  async refundUnsubmitted(collaborationId: string): Promise<void> {
    const collaboration = await this.collaborations.findById(collaborationId);
    if (!collaboration) return;
    if (collaboration.settlementMethod === 'NONE') {
      await this.endWithoutMoney(collaboration);
      return;
    }
    if (collaboration.stage === 'FUNDED') {
      const refunded = await this.refundInTransaction(collaboration);
      if (!refunded) return;
    }
    // 이 작업이 만든 환급 행이 있을 때만 이어서 한다(운영 명령이 REFUNDED로 옮긴 협업은 건드리지 않는다).
    const refund = await this.refunds.findByKey(
      unsubmittedRefundKey(collaboration.id),
    );
    if (!refund) return;
    await this.refunds.execute(refund.id);
    await this.notifyRefunded(collaboration, refund.amount);
  }

  // submit-reminder 작업: 아직 제출하지 않았을 때만 크리에이터에게 남은 날을 알린다.
  async remind(collaborationId: string, daysLeft: number): Promise<void> {
    const collaboration = await this.collaborations.findById(collaborationId);
    if (collaboration?.stage !== 'FUNDED') return;
    await this.notifications.notify({
      userId: collaboration.creatorId,
      role: 'CREATOR',
      kind: 'SUBMIT_REMINDER',
      params: { days: daysLeft },
      target: { kind: 'COLLABORATION', id: collaboration.id },
      dedupeKey: `reminder:${collaboration.id}:${daysLeft}`,
    });
  }

  // 돈이 없는 협업(식사권만)은 돈 없이 끝낸다. 양쪽에 종료만 알린다(금액이 든 환급 문구는 보내지 않는다).
  // 이미 끝난 협업에서 다시 돌 때는 알림만 마친다(같은 키라 한 건이다).
  private async endWithoutMoney(collaboration: Collaboration): Promise<void> {
    if (collaboration.stage === 'FUNDED') {
      const moved = await this.collaborations.advance(
        collaboration.id,
        'FUNDED',
        'REFUNDED',
      );
      if (!moved) return;
    } else if (collaboration.stage !== 'REFUNDED') {
      return;
    }
    await this.notifyEnded(collaboration);
    await this.notifications.notify({
      userId: collaboration.commissionerId,
      role: 'STORE',
      kind: 'UNSUBMITTED_ENDED',
      target: { kind: 'COLLABORATION', id: collaboration.id },
      dedupeKey: `unsubmitted:${collaboration.id}`,
    });
  }

  // 단계(FUNDED → REFUNDED), 장부(에스크로와 수수료를 환급 계정으로), 환급 행을 한 트랜잭션에서 만든다.
  private async refundInTransaction(
    collaboration: Collaboration,
  ): Promise<boolean> {
    const payment = await this.payments.findFundingPayment(collaboration.id);
    if (!payment) {
      throw new Error('보관 중인 협업의 결제를 찾을 수 없어요.');
    }
    const outcome = await this.repository.transaction<'refunded', 'gone'>(
      async (tx, rollback) => {
        if (
          !(await this.collaborations.advance(
            collaboration.id,
            'FUNDED',
            'REFUNDED',
            {},
            tx,
          ))
        ) {
          return rollback('gone');
        }
        const posted = await this.ledger.post(
          collaboration.id,
          postingsForFullRefund({
            escrow: payment.amountEscrow,
            fee: payment.amountFee,
          }),
          `unsubmitted:${collaboration.id}`,
          tx,
        );
        if (posted === 'duplicate') {
          throw new Error('보관 중인 협업에 환급 장부 줄이 이미 있어요.');
        }
        await this.refunds.request(
          collaboration.id,
          payment.amountEscrow + payment.amountFee,
          unsubmittedRefundKey(collaboration.id),
          tx,
        );
        return 'refunded';
      },
    );
    return outcome === 'refunded';
  }

  // 사장님에게는 환급 문구, 크리에이터에게는 종료 문구.
  private async notifyRefunded(
    collaboration: Collaboration,
    amount: number,
  ): Promise<void> {
    await this.notifications.notify({
      userId: collaboration.commissionerId,
      role: 'STORE',
      kind: 'UNSUBMITTED_REFUNDED',
      params: { amount },
      target: { kind: 'WALLET', id: null },
      dedupeKey: `unsubmitted:${collaboration.id}`,
    });
    await this.notifyEnded(collaboration);
  }

  private notifyEnded(collaboration: Collaboration): Promise<void> {
    return this.notifications.notify({
      userId: collaboration.creatorId,
      role: 'CREATOR',
      kind: 'UNSUBMITTED_ENDED',
      target: { kind: 'COLLABORATION', id: collaboration.id },
      dedupeKey: `unsubmitted:${collaboration.id}`,
    });
  }
}
