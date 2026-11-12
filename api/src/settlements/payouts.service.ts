import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Payout, Prisma } from '@prisma/client';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { OperatorAlertPort } from '../integrations/operator-alert/operator-alert.port';
import {
  PayoutFailedError,
  PayoutPort,
} from '../integrations/payout/payout.port';
import { JobScheduler } from '../jobs/job-scheduler';
import { NotificationsService } from '../notifications/notifications.service';
import { PayoutAccountsService } from '../payout-accounts/payout-accounts.service';
import { payoutJobKey } from './job-keys';
import { nextPayday, upcomingPayday } from './payday';
import {
  PayoutWithCreator,
  SettlementsRepository,
} from './settlements.repository';

// 크리에이터에게 나가는 돈. 정산이 확정되면 지급 행을 PENDING으로 만들고, 송금은 지급일(수요일 10:00 KST)에 한다.
@Injectable()
export class PayoutsService implements OnModuleInit {
  private readonly logger = new Logger(PayoutsService.name);

  constructor(
    private readonly repository: SettlementsRepository,
    private readonly accounts: PayoutAccountsService,
    private readonly payoutPort: PayoutPort,
    private readonly operatorAlert: OperatorAlertPort,
    private readonly notifications: NotificationsService,
    private readonly jobs: JobScheduler,
    private readonly clock: Clock,
  ) {}

  // 계좌 등록은 지급 모듈이 아니라 계좌 모듈이 먼저 있어서(순환 방지, 원장 판단 R7) 여기서 구독한다.
  // 이 처리는 계좌 등록 요청 안에서 돈다: 작업 일정만 다시 잡고 돈은 보내지 않는다.
  onModuleInit(): void {
    this.accounts.onRegistered((creatorId) => this.flushPending(creatorId));
  }

  // 지급 행을 만든다(금액 0이면 만들지 않는다). 지급일은 정산 시각이 속한 주의 다음 주 수요일 10:00이고, 바로 보내지 않는다.
  // tx를 주면 그 트랜잭션 안에서 행만 만든다: 정산의 장부·단계와 함께 커밋되거나 함께 되돌아가게. 작업 등록은 커밋 뒤에 schedule로 한다.
  // tx가 없으면 행을 만들고 작업도 바로 올린다. 같은 key로 다시 불러도 행은 하나다.
  async request(
    collaborationId: string,
    amount: number,
    key: string,
    settledAt: Date,
    tx?: Prisma.TransactionClient,
  ): Promise<Payout | null> {
    if (amount === 0) return null;
    await this.repository.createPayoutIfAbsent(
      {
        collaborationId,
        amount,
        idempotencyKey: key,
        scheduledFor: nextPayday(settledAt),
      },
      tx,
    );
    const row = await this.repository.findPayoutByKey(key, tx);
    if (row && !tx) await this.schedule(row);
    return row;
  }

  findByKey(key: string): Promise<Payout | null> {
    return this.repository.findPayoutByKey(key);
  }

  findById(payoutId: string): Promise<PayoutWithCreator | null> {
    return this.repository.findPayoutWithCreator(payoutId);
  }

  // 운영 명령 retry-payout의 앞 절반: 실패한 지급을 대기로 되돌린다(송금은 send가 같은 키로 한다).
  // FAILED가 아니면 false다. 호출한 쪽의 트랜잭션 안에서 감사 기록과 함께 커밋한다.
  reopenFailed(
    payoutId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    return this.repository.markPayoutPending(payoutId, tx);
  }

  // 지급일에 송금 작업이 돌게 올린다. 같은 지급은 키가 같아 한 번만 올라간다.
  schedule(payout: Payout): Promise<void> {
    return this.jobs.schedule(
      'payout-send',
      { payoutId: payout.id },
      payout.scheduledFor,
      payoutJobKey(payout.id),
    );
  }

  // payout-send 작업. 같은 작업이 다시 돌아도 송금은 한 번만 나간다:
  // 상태가 PENDING일 때만 보내고, 포트에도 같은 키를 넘기며, DONE으로 바꾸는 갱신이 조건부다.
  async send(payoutId: string): Promise<void> {
    const payout = await this.repository.findPayoutWithCreator(payoutId);
    if (!payout) return;
    // 송금은 나갔는데 알림 전에 죽었다면 다시 돌 때 알림을 마친다(같은 키라 한 건이다).
    if (payout.status === 'DONE') {
      await this.notifyDone(payout);
      return;
    }
    if (payout.status !== 'PENDING') return;

    const account = await this.readAccount(payout.creatorId);
    // 계좌가 없으면 그대로 둔다. 계좌를 등록하면 다음 지급일로 옮겨 다시 올라간다.
    if (!account) return;
    let externalId: string;
    try {
      ({ externalId } = await this.payoutPort.send({
        ...account,
        amount: payout.amount,
        idempotencyKey: `payout:${payout.id}`,
      }));
    } catch (error) {
      // 송금 쪽이 실패를 알렸다: 자동으로 다시 보내지 않고 운영자가 확인한다(운영 명령 retry-payout).
      if (error instanceof PayoutFailedError) {
        await this.repository.markPayoutFailed(payout.id);
        await this.alertQuietly(
          '송금이 실패했어요. 확인해 주세요.',
          `지급 ID: ${payout.id}`,
        );
        return;
      }
      throw error;
    }
    await this.repository.markPayoutDone(payout.id, externalId);
    await this.notifyDone(payout);
  }

  // 계좌를 등록한 크리에이터의 대기 중 지급 가운데 지급일이 이미 지난 것을 다음 지급일로 옮기고 작업을 다시 올린다.
  // 바로 보내지 않는다: 송금은 늘 수요일 묶음이다.
  async flushPending(creatorId: string): Promise<void> {
    const now = this.clock.now();
    const overdue = await this.repository.listOverduePendingPayouts(
      creatorId,
      now,
    );
    const scheduledFor = upcomingPayday(now);
    for (const payout of overdue) {
      // 작업을 먼저 새 시각으로 올리고 행의 지급일을 나중에 옮긴다: 행을 옮긴 뒤 작업 등록이 실패하면
      // 지급일이 미래인데 작업이 없는 지급이 남기 때문이다. 같은 키로 대기 중인 옛 작업은 새 시각으로 다시 올라가지 않으므로 먼저 지운다.
      await this.jobs.cancel(payoutJobKey(payout.id));
      await this.jobs.schedule(
        'payout-send',
        { payoutId: payout.id },
        scheduledFor,
        payoutJobKey(payout.id),
      );
      await this.repository.reschedulePayout(payout.id, scheduledFor);
    }
  }

  // 계좌번호를 열 수 없는 경우(키가 없거나 읽을 수 없음)도 계좌가 없는 것과 같게 다룬다: 지급은 PENDING으로 남고
  // 작업은 오류 없이 끝난다. 번호와 예금주는 로그에 남기지 않는다. 키 이름이 든 오류는 서버 로그에만 간다.
  private async readAccount(creatorId: string) {
    try {
      return await this.accounts.getForPayout(creatorId);
    } catch (error) {
      if (error instanceof AppError) {
        this.logger.error(
          `지급 계좌를 열지 못해 지급을 미뤄요: ${error.message}`,
        );
        return null;
      }
      throw error;
    }
  }

  private notifyDone(payout: Payout & { creatorId: string }): Promise<void> {
    return this.notifications.notify({
      userId: payout.creatorId,
      role: 'CREATOR',
      kind: 'PAYOUT_DONE',
      params: { amount: payout.amount },
      target: { kind: 'WALLET', id: null },
      dedupeKey: `payout-done:${payout.id}`,
    });
  }

  // 운영자 알림이 실패해도 원래 흐름(이미 FAILED로 기록)을 막지 않는다.
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
