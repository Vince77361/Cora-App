import { Injectable, Logger } from '@nestjs/common';
import { Collaboration, Contract, Payment, Prisma } from '@prisma/client';
import { BRAND_HALT_CHECK_DAYS } from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { ConversationsService } from '../conversations/conversations.service';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import { JobScheduler } from '../jobs/job-scheduler';
import {
  postingsForFullRefund,
  postingsForPaymentApproved,
} from '../ledger/ledger-postings';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  BrandApproval,
  BrandPaymentHandler,
  BrandPaymentOptions,
} from '../payments/brand-payments';
import type { PaymentQuoteModel } from '../payments/dto/payment-quote.model';
import {
  brandHaltJobKey,
  lateRefundKey,
  paymentLedgerKey,
} from '../settlements/job-keys';
import { RefundsService } from '../settlements/refunds.service';
import { feeFor } from '../settlements/settlement-math';
import { maxCashOfSnapshot, readSnapshot } from './contract-snapshot';
import { ContractsRepository } from './contracts.repository';
import { ContractsService } from './contracts.service';

const DAY_MS = 24 * 60 * 60 * 1000;

export const UNCONTRACTED_REFUND_SUBJECT =
  '[Cora] 계약 없이 승인된 결제를 환급했어요';

// 브랜드 계약의 결제가 승인됐을 때 계약·협업·장부를 옮기는 처리기. 결제 모듈이 승인 트랜잭션 안에서 부른다(BrandPayments에 등록).
// 이 결제가 AWAITING_BRAND 계약의 결제이면 체결하고, 아니면(동의가 새 판본·차단·그만둠으로 무효가 됐다) 계약을 맺지 않고 전액 환급한다.
@Injectable()
export class BrandContractPayments implements BrandPaymentHandler {
  private readonly logger = new Logger(BrandContractPayments.name);

  constructor(
    private readonly contracts: ContractsRepository,
    private readonly contractsService: ContractsService,
    private readonly collaborations: CollaborationsRepository,
    private readonly ledger: LedgerService,
    private readonly refunds: RefundsService,
    private readonly operatorAlert: OperatorAlertPort,
    private readonly jobs: JobScheduler,
    private readonly conversations: ConversationsService,
    private readonly notifications: NotificationsService,
  ) {}

  quote(userId: string, collaborationId: string): Promise<PaymentQuoteModel> {
    return this.contractsService.brandQuote(userId, collaborationId);
  }

  async applyApproval(
    payment: Payment,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<BrandApproval> {
    // 잠금 순서: 결제(호출한 쪽이 이미 갱신) → 협업 → 계약 → 장부.
    await this.collaborations.lock(payment.collaborationId, tx);
    const collaboration = await this.collaborations.findById(
      payment.collaborationId,
      tx,
    );
    if (!collaboration) throw new Error('결제의 협업을 찾을 수 없어요.');
    const contract = await this.contracts.findLive(collaboration.id, tx);
    if (contract && this.concludable(contract, collaboration, payment)) {
      return this.conclude(contract, collaboration, payment, now, tx);
    }
    return this.refundInFull(collaboration, payment, contract, tx);
  }

  // 이미 승인된 결제에 같은 통지가 또 왔다. 전액 환급이었다면 보내지 못한 환급을 다시 보내고(같은 키라 PG에서 한 번만 나간다),
  // 체결이었다면 커밋 뒤 단계(60일 점검 작업, 알림)를 마친다. 모두 같은 키라 이미 된 일은 그대로다.
  async retryApproved(
    payment: Payment,
    options: BrandPaymentOptions,
  ): Promise<void> {
    const refund = await this.refunds.findByKey(lateRefundKey(payment.id));
    if (refund) {
      await this.refunds.execute(refund.id);
      return;
    }
    const collaboration = await this.collaborations.findById(
      payment.collaborationId,
    );
    const contract = await this.contracts.findLive(payment.collaborationId);
    if (
      collaboration?.stage === 'CONTRACTED' &&
      collaboration.contractedAt &&
      contract?.status === 'CONCLUDED' &&
      contract.paymentId === payment.id
    ) {
      await this.afterConcluded(
        collaboration,
        collaboration.contractedAt,
        null,
        options,
      );
    }
  }

  // 이 결제로 이 계약을 체결할 수 있는가. 협업이 아직 AGREED이고, 계약이 AWAITING_BRAND이고,
  // 결제가 이 계약에 동의한 뒤에 만든 것이고(이전 계약의 결제는 금액이 달라도 알 수 없으니 받지 않는다),
  // 결제 금액이 계약 사본에서 다시 계산한 금액과 정확히 같을 때만이다.
  private concludable(
    contract: Contract,
    collaboration: Collaboration,
    payment: Payment,
  ): boolean {
    if (
      contract.status !== 'AWAITING_BRAND' ||
      collaboration.stage !== 'AGREED' ||
      payment.requestedAt.getTime() < contract.creatorConsentedAt.getTime()
    ) {
      return false;
    }
    try {
      const escrow = maxCashOfSnapshot(readSnapshot(contract.termsSnapshot));
      return (
        payment.amountEscrow === escrow &&
        payment.amountFee === feeFor(escrow, payment.feeRate)
      );
    } catch (error) {
      // 사본이 깨졌다면 체결하지 않는다: 돈은 전액 환급으로 돌려보내고 운영자가 본다.
      this.logger.error(
        `계약 사본을 읽지 못해 체결하지 않아요: ${error instanceof Error ? error.message : 'unknown'}`,
      );
      return false;
    }
  }

  private async conclude(
    contract: Contract,
    collaboration: Collaboration,
    payment: Payment,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<BrandApproval> {
    // 잠금 안이라 실패할 길이 없다. 실패하면 승인까지 되돌려 어긋난 상태를 남기지 않는다.
    if (
      !(await this.collaborations.advance(
        collaboration.id,
        'AGREED',
        'CONTRACTED',
        { fundedAt: now, contractedAt: now },
        tx,
      ))
    ) {
      throw new Error('계약을 체결할 협업의 단계가 맞지 않아요.');
    }
    if (!(await this.contracts.conclude(contract.id, payment.id, now, tx))) {
      throw new Error('체결할 계약이 이미 바뀌었어요.');
    }
    const posted = await this.ledger.post(
      collaboration.id,
      postingsForPaymentApproved({
        escrow: payment.amountEscrow,
        fee: payment.amountFee,
      }),
      paymentLedgerKey(payment.id),
      tx,
    );
    if (posted === 'duplicate') {
      // 대기 중인 결제에 이미 장부 줄이 있다면 상태가 어긋난 것이다. 조용히 넘기지 않고 되돌려 드러낸다.
      throw new Error('대기 중인 결제의 장부 줄이 이미 있어요.');
    }
    const roomId = await this.conversations.idForCollaboration(
      collaboration.id,
      tx,
    );
    const line = roomId
      ? await this.conversations.postSystem(
          roomId,
          'CONTRACT_CONCLUDED',
          {},
          tx,
        )
      : null;
    return {
      outcome: 'concluded',
      afterCommit: (options) =>
        this.afterConcluded(collaboration, now, line?.id ?? null, options),
    };
  }

  // 계약 없이 승인된 결제: 결제 승인 줄과 전액 환급 줄을 함께 남기고(돈이 PG에서 들어왔다 바로 나간다) 환급 행을 만든다.
  // 협업 단계는 건드리지 않는다. 장부 키와 환급 키는 운영 명령 refund-payment와 같아 두 번 환급되지 않는다.
  private async refundInFull(
    collaboration: Collaboration,
    payment: Payment,
    contract: Contract | null,
    tx: Prisma.TransactionClient,
  ): Promise<BrandApproval> {
    const posted = await this.ledger.post(
      collaboration.id,
      postingsForPaymentApproved({
        escrow: payment.amountEscrow,
        fee: payment.amountFee,
      }),
      paymentLedgerKey(payment.id),
      tx,
    );
    if (posted === 'duplicate') {
      throw new Error('대기 중인 결제의 장부 줄이 이미 있어요.');
    }
    const key = lateRefundKey(payment.id);
    await this.ledger.post(
      collaboration.id,
      postingsForFullRefund({
        escrow: payment.amountEscrow,
        fee: payment.amountFee,
      }),
      key,
      tx,
    );
    const refund = await this.refunds.request(
      collaboration.id,
      payment.amountEscrow + payment.amountFee,
      key,
      tx,
    );
    return {
      outcome: 'refunded',
      afterCommit: async () => {
        await this.alertQuietly(
          `결제 ID: ${payment.id}\n협업 ID: ${collaboration.id}\n협업 단계: ${collaboration.stage}\n계약: ${contract ? `${contract.status}(판본 ${contract.termsVersion})` : '없음'}`,
        );
        // 실패하면 던진다: 행은 PENDING으로 남고, 같은 통지가 다시 오면 retryApproved가 같은 키로 다시 보낸다.
        if (refund) await this.refunds.execute(refund.id);
      },
    };
  }

  // 커밋 뒤의 단계. 60일 점검 작업을 올리고(실패하면 던진다: 이것이 빠지면 안 되므로 재시도가 고치게 한다),
  // 안내 줄과 방의 변경을 밀어 주고, 양쪽에 끌 수 없는 알림을 보낸다. 안내 줄의 메시지 푸시는 보내지 않는다(같은 일로 두 번 울리지 않게).
  private async afterConcluded(
    collaboration: Collaboration,
    contractedAt: Date,
    lineId: string | null,
    options: BrandPaymentOptions,
  ): Promise<void> {
    await this.jobs.schedule(
      'brand-halt-check',
      { collaborationId: collaboration.id },
      new Date(contractedAt.getTime() + BRAND_HALT_CHECK_DAYS * DAY_MS),
      brandHaltJobKey(collaboration.id),
    );
    const roomId = await this.conversations.idForCollaboration(
      collaboration.id,
    );
    if (lineId) await this.conversations.publishCreated(lineId);
    if (roomId) await this.conversations.publishUpdated(roomId, 'CONTRACT');
    const send = async () => {
      await this.notifications.notify({
        userId: collaboration.commissionerId,
        role: 'BRAND',
        kind: 'CONTRACT_CONCLUDED',
        target: { kind: 'CONTRACT', id: collaboration.id },
        dedupeKey: `contract-concluded:${collaboration.id}`,
      });
      await this.notifications.notify({
        userId: collaboration.creatorId,
        role: 'CREATOR',
        kind: 'CONTRACT_CONCLUDED',
        target: { kind: 'CONTRACT', id: collaboration.id },
        dedupeKey: `contract-concluded:${collaboration.id}`,
      });
    };
    if (!options.swallowNotifyErrors) return send();
    try {
      await send();
    } catch (error) {
      this.logger.warn(
        `계약 체결 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  private async alertQuietly(body: string): Promise<void> {
    try {
      await this.operatorAlert.alert({
        subject: UNCONTRACTED_REFUND_SUBJECT,
        body,
      });
    } catch (error) {
      this.logger.error(
        `운영자 알림을 보내지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }
}
