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

  transaction<T>(
    run: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(run);
  }

  // 판본을 확인하거나 새로 내는 요청을 같은 협업에서는 한 줄로 세운다(트랜잭션이 끝날 때까지 잡는다).
  // 확인과 새 판본이 동시에 와도 "서로 다른 판본에 합의한" 상태가 생기지 않게 하려는 것이다.
  async lockCollaboration(
    collaborationId: string,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    await tx.$queryRaw`
      SELECT id FROM collaborations WHERE id = ${collaborationId}::uuid FOR UPDATE`;
  }

  // 내 쪽 확인 시각을 조건부로 채운다(이미 채워져 있으면 0행이라 false). 판본의 다른 칸은 고치지 않는다.
  async markConfirmed(
    collaborationId: string,
    version: number,
    side: 'BRAND' | 'CREATOR',
    at: Date,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    const column = side === 'BRAND' ? 'brandConfirmedAt' : 'creatorConfirmedAt';
    const { count } = await tx.termsVersion.updateMany({
      where: { collaborationId, version, deletedAt: null, [column]: null },
      data: { [column]: at, updatedAt: at },
    });
    return count === 1;
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

  // 한 판본. 없으면 null.
  findVersion(
    collaborationId: string,
    version: number,
    tx?: Prisma.TransactionClient,
  ): Promise<TermsVersion | null> {
    return this.client(tx).termsVersion.findFirst({
      where: { collaborationId, version, deletedAt: null },
    });
  }

  // 협업의 모든 판본, 최신이 먼저.
  listAll(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<TermsVersion[]> {
    return this.client(tx).termsVersion.findMany({
      where: { collaborationId, deletedAt: null },
      orderBy: { version: 'desc' },
    });
  }

  // 여러 협업의 가장 큰 번호 판본을 한 번에(협업마다 하나).
  async findLatestMany(
    collaborationIds: string[],
  ): Promise<Map<string, TermsVersion>> {
    if (collaborationIds.length === 0) return new Map();
    const rows = await this.prisma.termsVersion.findMany({
      where: { collaborationId: { in: collaborationIds }, deletedAt: null },
      distinct: ['collaborationId'],
      orderBy: [{ collaborationId: 'asc' }, { version: 'desc' }],
    });
    return new Map(rows.map((row) => [row.collaborationId, row]));
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
