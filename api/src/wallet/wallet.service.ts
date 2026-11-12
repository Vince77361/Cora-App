import { Injectable, Logger } from '@nestjs/common';
import { Collaboration } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { isMoneyHeld } from '../collaborations/collaboration-stage';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import {
  kstDateString,
  startOfKstMonth,
  startOfNextKstMonth,
} from '../common/kst';
import { LedgerService } from '../ledger/ledger.service';
import { PayoutAccountsService } from '../payout-accounts/payout-accounts.service';
import { SettlementsService } from '../settlements/settlements.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { WalletModel } from './dto/wallet.model';
import { buildWalletEntries } from './wallet-entries';

// 크리에이터의 정산 화면(E7). 숫자는 모두 여기서 계산하고 앱은 계산하지 않는다. 읽기만 한다.
@Injectable()
export class WalletService {
  private readonly logger = new Logger(WalletService.name);

  constructor(
    private readonly users: UsersService,
    private readonly collaborations: CollaborationsRepository,
    private readonly settlements: SettlementsService,
    private readonly ledger: LedgerService,
    private readonly accounts: PayoutAccountsService,
    private readonly stores: StoresService,
    private readonly clock: Clock,
  ) {}

  async get(userId: string): Promise<WalletModel> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 볼 수 있어요.');
    }
    const now = this.clock.now();
    const [collaborations, payouts, account] = await Promise.all([
      this.collaborations.listByCreator(userId),
      this.settlements.payoutsOfCreator(userId),
      this.accounts.findMine(userId),
    ]);
    const ids = collaborations.map((c) => c.id);
    const heldIds = collaborations
      .filter((c) => isMoneyHeld(c.kind, c.stage))
      .map((c) => c.id);
    const [settlements, escrow, names] = await Promise.all([
      this.settlements.settlementsOf(ids),
      this.ledger.escrowBalances(heldIds),
      this.counterpartNames(collaborations),
    ]);

    // 다음 지급일: 대기 중(PENDING) 지급 가운데 가장 이른 지급일, 금액은 그날(한국 시간) 나갈 지급의 합.
    const pending = payouts.filter((p) => p.status === 'PENDING');
    let nextPayout: WalletModel['nextPayout'] = null;
    if (pending.length > 0) {
      const earliest = Math.min(
        ...pending.map((p) => p.scheduledFor.getTime()),
      );
      const date = kstDateString(new Date(earliest));
      nextPayout = {
        date,
        amount: pending
          .filter((p) => kstDateString(p.scheduledFor) === date)
          .reduce((sum, p) => sum + p.amount, 0),
      };
    }

    // 이번 달(한국 시간) 받은 금액: 송금이 끝난 시각이 이번 달인 DONE 지급.
    const monthStart = startOfKstMonth(now).getTime();
    const monthEnd = startOfNextKstMonth(now).getTime();
    const receivedThisMonth = payouts
      .filter(
        (p) =>
          p.status === 'DONE' &&
          p.updatedAt.getTime() >= monthStart &&
          p.updatedAt.getTime() < monthEnd,
      )
      .reduce((sum, p) => sum + p.amount, 0);

    let heldAmount = 0;
    for (const id of heldIds) heldAmount += escrow.get(id) ?? 0;

    return {
      nextPayout,
      account: account
        ? {
            bankName: account.bankName,
            bankFullName: account.bankFullName,
            accountLast4: account.accountLast4,
            holderName: account.holderName,
          }
        : null,
      receivedThisMonth,
      heldAmount,
      entries: buildWalletEntries({
        collaborations,
        settlements,
        payouts,
        escrow,
        names,
      }),
    };
  }

  // 가게 오퍼의 상대 이름(가게 이름). 가게를 읽을 수 없으면(비공개 등) 이름 없이 둬서 "가게"로 보인다 —
  // 정산 내역 전체가 실패하지 않게 한다.
  private async counterpartNames(
    collaborations: Collaboration[],
  ): Promise<Map<string, string>> {
    const byStore = new Map<string, string | null>();
    const names = new Map<string, string>();
    for (const c of collaborations) {
      if (!c.storeId) continue;
      if (!byStore.has(c.storeId)) {
        try {
          byStore.set(
            c.storeId,
            (await this.stores.getOfferCard(c.storeId))?.summary.name ?? null,
          );
        } catch (error) {
          this.logger.warn(
            `정산 내역의 가게를 읽지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
          );
          byStore.set(c.storeId, null);
        }
      }
      const name = byStore.get(c.storeId);
      if (name) names.set(c.id, name);
    }
    return names;
  }
}
