import { Injectable } from '@nestjs/common';
import { PayoutAccount } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface PayoutAccountData {
  bankCode: string;
  accountNumberEnc: string;
  accountLast4: string;
  holderName: string;
}

@Injectable()
export class PayoutAccountsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 지워진(deleted_at) 행은 없는 것으로 본다.
  findByCreatorId(creatorId: string): Promise<PayoutAccount | null> {
    return this.prisma.payoutAccount.findFirst({
      where: { creatorId, deletedAt: null },
    });
  }

  // 크리에이터당 한 줄(creator_id 유니크). 다시 등록하면 같은 줄을 덮어쓴다.
  upsert(creatorId: string, data: PayoutAccountData): Promise<PayoutAccount> {
    return this.prisma.payoutAccount.upsert({
      where: { creatorId },
      create: { creatorId, ...data },
      update: { ...data, deletedAt: null },
    });
  }
}
