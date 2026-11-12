import { Injectable, Logger } from '@nestjs/common';
import { Prisma, Refund } from '@prisma/client';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { PaymentPort } from '../integrations/payment/payment.port';
import { JobRunContext } from '../jobs/job-scheduler';
import { PaymentsService } from '../payments/payments.service';
import { LATE_REFUND_KEY_PREFIX } from './job-keys';
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
  // 실패하면 던진다: 행은 PENDING으로 남아 큐가 다시 시도한다. 운영자에게는 마지막 시도에서만 알린다
  // (재시도마다 알리면 일시적인 장애에 경보가 시도 수만큼 쌓인다). 마지막 시도인지 모르면 알린다.
  async execute(
    refundId: string,
    context: JobRunContext = { finalAttempt: true },
  ): Promise<void> {
    const refund = await this.repository.findRefundById(refundId);
    if (!refund || refund.status !== 'PENDING') return;
    try {
      await this.sendToPg(refund);
    } catch (error) {
      if (context.finalAttempt) {
        await this.alertQuietly(
          '환급을 보내지 못했어요. 확인해 주세요.',
          `환급 ID: ${refund.id}`,
        );
      }
      throw error;
    }
  }

  // 운영 명령 retry-refund: 큐가 시도를 다 썼거나 PG가 실패를 알린 환급(PENDING·FAILED)을 같은 중복 방지 키로 다시 보낸다.
  // 이미 DONE이면 보내지 않고 'already-done'이다. 실패하면 던진다(운영자가 오류를 보고, 행은 그대로라 다시 실행할 수 있다).
  async retry(refundId: string): Promise<'done' | 'already-done'> {
    const refund = await this.repository.findRefundById(refundId);
    if (!refund) throw new Error('환급을 찾을 수 없어요.');
    if (refund.status === 'DONE') return 'already-done';
    await this.sendToPg(refund);
    return 'done';
  }

  // PG에 환급을 요청하고 DONE으로 바꾼다. 같은 환급은 늘 같은 키(refund:<환급 id>)라 몇 번을 보내도 PG에서 한 번만 환급된다.
  private async sendToPg(refund: Refund): Promise<void> {
    const { externalId } = await this.paymentPort.refund({
      pgTransactionId: await this.pgTransactionIdOf(refund),
      amount: refund.amount,
      idempotencyKey: `refund:${refund.id}`,
    });
    await this.repository.markRefundDone(refund.id, externalId);
  }

  // 돌려보낼 결제의 PG 거래 번호. 보통은 협업의 보관을 시작시킨 결제이고, 협업에 반영되지 못한 결제(늦은 승인, 이중 결제)의
  // 환급은 키(late-refund:<결제 id>)가 그 결제를 가리킨다.
  private async pgTransactionIdOf(refund: Refund): Promise<string> {
    let pgTransactionId: string | null = null;
    if (refund.idempotencyKey.startsWith(LATE_REFUND_KEY_PREFIX)) {
      const payment = await this.payments.findPayment(
        refund.idempotencyKey.slice(LATE_REFUND_KEY_PREFIX.length),
      );
      // 다른 협업의 결제를 키만 보고 돌려보내지 않는다.
      if (payment?.collaborationId === refund.collaborationId) {
        pgTransactionId = payment.pgTransactionId;
      }
    } else {
      pgTransactionId =
        (await this.payments.findFundingPayment(refund.collaborationId))
          ?.pgTransactionId ?? null;
    }
    if (!pgTransactionId) throw new Error('환급할 결제를 찾을 수 없어요.');
    return pgTransactionId;
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
