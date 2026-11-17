import { Injectable } from '@nestjs/common';
import { Contract, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface NewContract {
  collaborationId: string;
  termsVersion: number;
  termsSnapshot: Prisma.InputJsonValue;
  creatorConsentedAt: Date;
  creatorConsentTexts: string[];
}

// 계약(contracts) 표. 협업 하나에 살아 있는(무효가 아닌) 계약은 하나뿐이다(부분 유니크 인덱스).
// 상태 변경은 모두 조건부 갱신이라 같은 요청이 동시에 와도 한 번만 바뀌고, 바뀐 행이 0이면 false를 돌려 서비스가 판단한다.
@Injectable()
export class ContractsRepository {
  constructor(private readonly prisma: PrismaService) {}

  private client(tx?: Prisma.TransactionClient) {
    return tx ?? this.prisma;
  }

  // 무효가 아닌 계약(AWAITING_BRAND 또는 CONCLUDED). 없으면 null.
  findLive(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Contract | null> {
    return this.client(tx).contract.findFirst({
      where: {
        collaborationId,
        status: { not: 'VOIDED' },
        deletedAt: null,
      },
    });
  }

  // 가장 최근에 새 판본 때문에 무효가 된 계약(내 동의가 취소됐다는 띠를 보여 줄 때 쓴다).
  findLatestVoidedByNewTerms(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Contract | null> {
    return this.client(tx).contract.findFirst({
      where: {
        collaborationId,
        status: 'VOIDED',
        voidReason: 'NEW_TERMS',
        deletedAt: null,
      },
      orderBy: { voidedAt: 'desc' },
    });
  }

  create(data: NewContract, tx: Prisma.TransactionClient): Promise<Contract> {
    return tx.contract.create({
      data: { ...data, status: 'AWAITING_BRAND', brandConsentTexts: [] },
    });
  }

  // 브랜드가 동의한 문구와 결제를 계약에 남긴다. 아직 AWAITING_BRAND일 때만이다.
  async saveBrandConsent(
    id: string,
    brandConsentTexts: string[],
    paymentId: string,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await tx.contract.updateMany({
      where: { id, status: 'AWAITING_BRAND', deletedAt: null },
      data: { brandConsentTexts, paymentId, updatedAt: now },
    });
    return count === 1;
  }

  // 결제가 승인돼 계약이 체결된다. AWAITING_BRAND일 때만이라 같은 승인이 동시에 와도 한 번이다.
  // 결제가 새 결제에 밀려났다가 승인된 경우도 있어, 체결하는 결제를 계약에 다시 적는다.
  async conclude(
    id: string,
    paymentId: string,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await tx.contract.updateMany({
      where: { id, status: 'AWAITING_BRAND', deletedAt: null },
      data: {
        status: 'CONCLUDED',
        paymentId,
        brandConsentedAt: now,
        concludedAt: now,
        updatedAt: now,
      },
    });
    return count === 1;
  }

  transaction<T>(
    run: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(run);
  }
}
