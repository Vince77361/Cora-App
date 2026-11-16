import { Injectable } from '@nestjs/common';
import { Prisma, TermsVersion } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { TermsValues } from './draft-terms';

// 조건 판본(terms_versions)의 저장소. 판본은 만들기만 하고 고치지 않는다(확인한 시각만 채운다).
// tx를 주면 그 트랜잭션 안에서 실행한다(서로 관심 트랜잭션, 새 판본 제안).
@Injectable()
export class TermsRepository {
  constructor(private readonly prisma: PrismaService) {}

  private client(tx?: Prisma.TransactionClient) {
    return tx ?? this.prisma;
  }

  // 가장 큰 번호의 판본.
  findLatest(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<TermsVersion | null> {
    return this.client(tx).termsVersion.findFirst({
      where: { collaborationId, deletedAt: null },
      orderBy: { version: 'desc' },
    });
  }

  create(
    collaborationId: string,
    version: number,
    values: TermsValues,
    tx?: Prisma.TransactionClient,
  ): Promise<TermsVersion> {
    return this.client(tx).termsVersion.create({
      data: { collaborationId, version, ...values },
    });
  }
}
