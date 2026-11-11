import { Injectable, Logger } from '@nestjs/common';
import { Prisma, Refund } from '@prisma/client';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { PaymentPort } from '../integrations/payment/payment.port';
import { PaymentsService } from '../payments/payments.service';
import { SettlementsRepository } from './settlements.repository';

// 사장님에게 돌아가는 돈. 장부(STORE_REFUND)와 같은 트랜잭션에서 환급 행을 PENDING으로 만들고, PG 환급은 커밋 뒤에 한다.
@Injectable()
export class RefundsService {
  private readonly logger = new Logger(RefundsService.name);

  constructor(
    private readonly repository: SettlementsRepository,
    private readonly payments: PaymentsService,
    private readonly paymentPort: PaymentPort,
    private readonly operatorAlert: OperatorAlertPort,
  ) {}

  // 환급 행을 만든다(금액 0이면 만들지 않는다). 같은 key로 다시 불러도 행은 하나다.
  // tx를 주면 행만 만든다(커밋 뒤에 execute를 부른다). tx가 없으면 행을 만들고 바로 환급까지 한다.
  async request(
    collaborationId: string,
    amount: number,
    key: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Refund | null> {
    if (amount === 0) return null;
    await this.repository.createRefundIfAbsent(
      { collaborationId, amount, idempotencyKey: key },
      tx,
    );
    const row = await this.repository.findRefundByKey(key, tx);
    if (row && !tx) await this.execute(row.id);
    return row;
  }

  findByKey(key: string): Promise<Refund | null> {
    return this.repository.findRefundByKey(key);
  }

  // PG에 환급을 요청하고 DONE으로 바꾼다. PENDING이 아니면 아무 일도 하지 않으므로 같은 작업이 다시 돌아도 한 번만 나간다.
  // 요청이 나간 뒤 DONE 전에 죽어도 다시 돌 때 같은 키로 요청하므로 PG에서 한 번만 환급된다.
  // 실패하면 운영자에게 알리고 던진다: 행은 PENDING으로 남아 큐가 다시 시도한다.
  async execute(refundId: string): Promise<void> {
    const refund = await this.repository.findRefundById(refundId);
    if (!refund || refund.status !== 'PENDING') return;
    try {
      const payment = await this.payments.findFundingPayment(
        refund.collaborationId,
      );
      if (!payment) throw new Error('환급할 결제를 찾을 수 없어요.');
      const { externalId } = await this.paymentPort.refund({
        pgTransactionId: payment.pgTransactionId,
        amount: refund.amount,
        idempotencyKey: `refund:${refund.id}`,
      });
      await this.repository.markRefundDone(refund.id, externalId);
    } catch (error) {
      await this.alertQuietly(
        '환급을 보내지 못했어요. 확인해 주세요.',
        `환급 ID: ${refund.id}`,
      );
      throw error;
    }
  }

  private async alertQuietly(subject: string, body: string): Promise<void> {
    try {
      await this.operatorAlert.alert({ subject, body });
    } catch (error) {
      this.logger.error(
        `운영자 알림을 보내지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }
}
