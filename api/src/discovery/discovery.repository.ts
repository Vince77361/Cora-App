import { Injectable } from '@nestjs/common';
import {
  Match,
  PassReason,
  Prisma,
  SwipeDecision,
  SwipeTargetKind,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DecisionFields } from './discovery-rules';

export function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  );
}

// 결정 한 줄을 가리키는 키. campaignId는 가게 넘김에서만 null이다.
export interface DecisionKey {
  actorId: string;
  targetKind: SwipeTargetKind;
  targetId: string;
  campaignId: string | null;
}

// 결정(swipe_decisions)과 서로 관심(matches)의 저장소. 모든 읽기와 쓰기가 tx를 받을 수 있다.
// 쓰는 모든 곳이 updatedAt을 직접 받는다: @updatedAt은 벽시계라서 Clock과 어긋난다.
@Injectable()
export class DiscoveryRepository {
  constructor(private readonly prisma: PrismaService) {}

  private client(tx?: Prisma.TransactionClient) {
    return tx ?? this.prisma;
  }

  transaction<T>(
    run: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(run);
  }

  // 같은 키의 결정·되돌리기를 한 줄로 세운다(트랜잭션이 끝날 때까지 잡는다).
  // 이게 없으면 양쪽이 동시에 관심을 보낼 때 서로의 커밋 전 행을 못 봐서 서로 관심이 한 번도 만들어지지 않는다.
  async lock(key: string, tx: Prisma.TransactionClient): Promise<void> {
    await tx.$executeRaw`
      SELECT pg_advisory_xact_lock(hashtextextended(${key}, 0))`;
  }

  findDecisionById(
    id: string,
    tx: Prisma.TransactionClient,
  ): Promise<SwipeDecision | null> {
    return tx.swipeDecision.findFirst({ where: { id, deletedAt: null } });
  }

  findDecision(
    key: DecisionKey,
    tx?: Prisma.TransactionClient,
  ): Promise<SwipeDecision | null> {
    return this.client(tx).swipeDecision.findFirst({
      where: { ...key, deletedAt: null },
    });
  }

  createDecision(
    key: DecisionKey,
    data: DecisionFields,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<SwipeDecision> {
    return tx.swipeDecision.create({
      data: { ...key, ...data, createdAt: now, updatedAt: now },
    });
  }

  updateDecision(
    id: string,
    data: Partial<DecisionFields>,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<SwipeDecision> {
    return tx.swipeDecision.update({
      where: { id },
      data: { ...data, updatedAt: now },
    });
  }

  // 넘긴 이유는 새 결정이 아니라서 결정의 시각(updatedAt)을 그대로 둔다("마지막 결정" 판정이 밀리지 않게).
  setPassReason(
    id: string,
    reason: PassReason,
    keepUpdatedAt: Date,
  ): Promise<SwipeDecision> {
    return this.prisma.swipeDecision.update({
      where: { id },
      data: { passReason: reason, updatedAt: keepUpdatedAt },
    });
  }

  // 오늘(한국 날짜 시작 시각 이후) 내가 가장 나중에 한 결정.
  findLastSince(
    actorId: string,
    since: Date,
    tx?: Prisma.TransactionClient,
  ): Promise<SwipeDecision | null> {
    return this.client(tx).swipeDecision.findFirst({
      where: { actorId, deletedAt: null, updatedAt: { gte: since } },
      orderBy: [{ updatedAt: 'desc' }, { createdAt: 'desc' }, { id: 'desc' }],
    });
  }

  // 되돌리기는 행 전체를 지운다. 넘긴 이유와 브랜드의 제안도 함께 사라진다.
  async deleteDecision(
    id: string,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    await tx.swipeDecision.deleteMany({ where: { id } });
  }

  findMatch(
    campaignId: string,
    creatorId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Match | null> {
    return this.client(tx).match.findFirst({
      where: { campaignId, creatorId, deletedAt: null },
    });
  }

  createMatch(
    data: {
      campaignId: string;
      creatorId: string;
      collaborationId: string;
      matchedAt: Date;
    },
    tx: Prisma.TransactionClient,
  ): Promise<Match> {
    return tx.match.create({ data });
  }
}
