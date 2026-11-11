import { Injectable, Logger } from '@nestjs/common';
import { PayoutAccount } from '@prisma/client';
import { SecretBox } from '../common/crypto/secret-box';
import { AppError } from '../common/errors/app-error';
import { UsersService } from '../users/users.service';
import { BANKS, Bank, findBank } from './banks';
import { PayoutAccountModel } from './dto/payout-account.model';
import { PayoutAccountsRepository } from './payout-accounts.repository';
import { UpsertPayoutAccountDto } from './dto/upsert-payout-account.dto';

export type RegisteredListener = (creatorId: string) => Promise<void>;

// 크리에이터가 지급받을 계좌. 번호는 AES-256-GCM으로 봉해 저장하고, 응답과 로그에는 뒤 4자리만 낸다.
@Injectable()
export class PayoutAccountsService {
  private readonly logger = new Logger(PayoutAccountsService.name);
  private readonly listeners: RegisteredListener[] = [];

  constructor(
    private readonly accounts: PayoutAccountsRepository,
    private readonly users: UsersService,
    private readonly secretBox: SecretBox,
  ) {}

  listBanks(): Bank[] {
    return BANKS.map((b) => ({ ...b }));
  }

  // 계좌가 등록되면 기다리던 지급을 처리하는 쪽(지급 모듈)이 구독한다.
  // 이 모듈이 지급 모듈을 import하면 순환이 생기므로, 지급 모듈이 이 모듈을 import하고 여기에 등록한다.
  onRegistered(listener: RegisteredListener): void {
    this.listeners.push(listener);
  }

  async upsert(
    userId: string,
    dto: UpsertPayoutAccountDto,
  ): Promise<PayoutAccountModel> {
    await this.assertCreator(userId);
    const bank = findBank(dto.bankCode);
    if (!bank) {
      throw new AppError('VALIDATION_FAILED', '지원하지 않는 은행이에요.');
    }
    const sealed = this.seal(userId, dto.accountNumber);
    const saved = await this.accounts.upsert(userId, {
      bankCode: bank.code,
      accountNumberEnc: sealed,
      accountLast4: dto.accountNumber.slice(-4),
      holderName: dto.holderName,
    });
    // 계좌는 이미 저장됐다. 지급 처리가 실패해도 등록은 성공으로 두고, 지급은 작업이 다시 시도한다.
    for (const listener of this.listeners) {
      try {
        await listener(userId);
      } catch (error) {
        this.logger.error(
          `계좌 등록 뒤 처리에 실패했어요(크리에이터 ${userId}): ${
            error instanceof Error ? error.message : String(error)
          }`,
        );
      }
    }
    return this.toModel(saved, bank);
  }

  async getMine(userId: string): Promise<PayoutAccountModel> {
    await this.assertCreator(userId);
    const row = await this.accounts.findByCreatorId(userId);
    if (!row) {
      throw new AppError('NOT_FOUND', '등록된 지급 계좌가 없어요.');
    }
    return this.toModel(row, findBank(row.bankCode));
  }

  // 협업 조회 화면이 "계좌 등록이 필요해요"를 가릴 때 쓴다. 번호는 열지 않는다.
  async hasAccount(creatorId: string): Promise<boolean> {
    return (await this.accounts.findByCreatorId(creatorId)) !== null;
  }

  // 지급 모듈이 송금할 때 쓴다. 전체 번호를 여는 유일한 경로이고 호출자는 로그에 남기지 않는다.
  async getForPayout(creatorId: string): Promise<{
    bankCode: string;
    accountNumber: string;
    holderName: string;
  } | null> {
    const row = await this.accounts.findByCreatorId(creatorId);
    if (!row) return null;
    return {
      bankCode: row.bankCode,
      accountNumber: this.secretBox.open(row.accountNumberEnc),
      holderName: row.holderName,
    };
  }

  // 키가 없으면 저장하지 않고 멈춘다. 평문으로 두는 것보다 등록을 못 하는 편이 낫다.
  // 클라이언트에는 설정 이름을 알리지 않고, 서버 로그에만 어떤 키가 필요한지 남긴다.
  private seal(userId: string, accountNumber: string): string {
    if (!this.secretBox.isConfigured()) {
      this.logger.error(
        `PAYOUT_ACCOUNT_KEY가 없거나 올바르지 않아 지급 계좌를 저장하지 못했어요(크리에이터 ${userId}, 뒤 4자리 ${accountNumber.slice(-4)}).`,
      );
      throw new AppError(
        'INTERNAL',
        '계좌를 등록하지 못했어요. 잠시 뒤에 다시 시도해 주세요.',
      );
    }
    return this.secretBox.seal(accountNumber);
  }

  private toModel(row: PayoutAccount, bank?: Bank): PayoutAccountModel {
    return {
      bankCode: row.bankCode,
      bankName: bank?.name ?? row.bankCode,
      bankFullName: bank?.fullName ?? row.bankCode,
      accountLast4: row.accountLast4,
      holderName: row.holderName,
    };
  }

  private async assertCreator(userId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
  }
}
