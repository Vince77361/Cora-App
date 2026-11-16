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
  // 되돌리기와 겹쳐 행이 먼저 지워졌으면 false다(P2025로 500이 되지 않게 updateMany로 쓴다).
  async setPassReason(
    id: string,
    reason: PassReason,
    keepUpdatedAt: Date,
  ): Promise<boolean> {
    const { count } = await this.prisma.swipeDecision.updateMany({
      where: { id, decision: 'PASS', deletedAt: null },
      data: { passReason: reason, updatedAt: keepUpdatedAt },
    });
    return count === 1;
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
    // @updatedAt은 벽시계라서 Clock의 시각을 직접 적는다.
    return tx.match.create({
      data: { ...data, createdAt: data.matchedAt, updatedAt: data.matchedAt },
    });
  }

  // 내가 저장한(관심 + 보류) 결정, 최근 결정이 앞이다. 넘긴 것은 읽지 않는다.
  // campaignId를 주면 그 캠페인에서 한 것만(브랜드), 주지 않으면 내 모든 결정(크리에이터).
  listSavedDecisions(
    actorId: string,
    targetKind: SwipeTargetKind,
    campaignId?: string,
    targetIds?: string[],
  ): Promise<SwipeDecision[]> {
    if (targetIds?.length === 0) return Promise.resolve([]);
    return this.prisma.swipeDecision.findMany({
      where: {
        actorId,
        targetKind,
        decision: { in: ['LIKE', 'HOLD'] },
        deletedAt: null,
        ...(campaignId ? { campaignId } : {}),
        ...(targetIds ? { targetId: { in: targetIds } } : {}),
      },
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
    });
  }

  // 내가 낸 결정 전부(종류와 대상을 고른 것). 받은 제안에서 "내가 이미 결정한 캠페인"을 거를 때 쓴다.
  listDecisionsOn(
    actorId: string,
    targetKind: SwipeTargetKind,
    targetIds: string[],
  ): Promise<SwipeDecision[]> {
    if (targetIds.length === 0) return Promise.resolve([]);
    return this.prisma.swipeDecision.findMany({
      where: {
        actorId,
        targetKind,
        targetId: { in: targetIds },
        deletedAt: null,
      },
    });
  }

  // 그 캠페인에서 서로 관심이 닿은 크리에이터들.
  listMatchesOfCampaign(campaignId: string): Promise<Match[]> {
    return this.prisma.match.findMany({
      where: { campaignId, deletedAt: null },
    });
  }

  // 그 크리에이터가 서로 관심이 닿은 캠페인들.
  listMatchesOfCreator(creatorId: string): Promise<Match[]> {
    return this.prisma.match.findMany({
      where: { creatorId, deletedAt: null },
    });
  }

  // 브랜드가 이 크리에이터에게 보낸 관심 가운데 글이나 조건 제안이 붙은 것(크리에이터의 "받은 제안" 재료).
  // 넘김과 보류, 아무것도 붙지 않은 관심은 읽지 않는다.
  listProposalLikesTo(creatorId: string): Promise<SwipeDecision[]> {
    return this.prisma.swipeDecision.findMany({
      where: {
        targetKind: 'CREATOR',
        targetId: creatorId,
        decision: 'LIKE',
        campaignId: { not: null },
        deletedAt: null,
        OR: [{ note: { not: null } }, { proposedFee: { not: null } }],
      },
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
    });
  }
}
