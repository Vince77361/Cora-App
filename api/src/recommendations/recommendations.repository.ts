import { Injectable } from '@nestjs/common';
import {
  Prisma,
  RecommendationScope,
  SwipeDecisionKind,
  SwipeTargetKind,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DecisionRow, OfferStateRow } from './candidate-rules';

export type StoredItem = {
  kind: 'CREATOR' | 'CAMPAIGN' | 'STORE';
  id: string;
};

// @db.Date 열은 UTC 자정의 Date로 오간다. day는 한국 날짜 'YYYY-MM-DD'다.
function dayDate(day: string): Date {
  return new Date(`${day}T00:00:00.000Z`);
}

// 저장된 JSON은 우리가 쓴 것이지만 모양이 어긋난 줄은 버리고 읽는다(500이 되지 않게).
function parseItems(json: Prisma.JsonValue): StoredItem[] {
  if (!Array.isArray(json)) return [];
  return json.flatMap((entry) => {
    if (typeof entry !== 'object' || entry === null || Array.isArray(entry)) {
      return [];
    }
    const { kind, id } = entry;
    if (
      (kind === 'CREATOR' || kind === 'CAMPAIGN' || kind === 'STORE') &&
      typeof id === 'string'
    ) {
      return [{ kind, id }];
    }
    return [];
  });
}

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  );
}

// 하루 추천 목록과, 추천이 읽어야 하는 넘김·오퍼·지원 기록의 조회. 쓰는 것은 하루 추천 목록뿐이다.
// 결정(swipe_decisions)을 쓰는 것은 5번 계획의 발견 모듈이다.
@Injectable()
export class RecommendationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 오늘 목록. 없으면 null. 지워진(deleted_at) 줄은 없는 것으로 본다.
  async findList(
    userId: string,
    scope: RecommendationScope,
    campaignId: string | null,
    day: string,
  ): Promise<StoredItem[] | null> {
    const row = await this.prisma.dailyRecommendation.findFirst({
      where: { userId, scope, campaignId, day: dayDate(day), deletedAt: null },
    });
    return row ? parseItems(row.items) : null;
  }

  // 같은 날 같은 목록은 부분 유니크 인덱스가 하나로 막는다. 두 요청이 동시에 만들면 먼저 들어간 목록이 남고,
  // 나중 요청은 위반(P2002) 대신 남은 목록을 돌려받아 같은 목록을 본다.
  async saveList(
    userId: string,
    scope: RecommendationScope,
    campaignId: string | null,
    day: string,
    items: StoredItem[],
  ): Promise<StoredItem[]> {
    try {
      await this.prisma.dailyRecommendation.create({
        data: { userId, scope, campaignId, day: dayDate(day), items },
      });
      return items;
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      return (await this.findList(userId, scope, campaignId, day)) ?? items;
    }
  }

  // 내가 내린 결정 전부. campaignId를 주면 그 캠페인에서 한 것만. 순수 규칙(candidate-rules)이 거른다.
  async listDecisions(
    actorId: string,
    targetKind: SwipeTargetKind,
    campaignId?: string,
  ): Promise<DecisionRow[]> {
    return this.prisma.swipeDecision.findMany({
      where: {
        actorId,
        targetKind,
        deletedAt: null,
        ...(campaignId ? { campaignId } : {}),
      },
      select: { targetId: true, decision: true, updatedAt: true },
    });
  }

  // 내가 이 대상에 내린 결정. 없으면 null. campaignId가 null이면 캠페인이 없는 결정(사장님의 크리에이터 결정, 크리에이터의 가게 넘김)이다.
  async findDecision(
    actorId: string,
    targetKind: SwipeTargetKind,
    targetId: string,
    campaignId: string | null,
  ): Promise<SwipeDecisionKind | null> {
    const row = await this.prisma.swipeDecision.findFirst({
      where: { actorId, targetKind, targetId, campaignId, deletedAt: null },
      select: { decision: true },
    });
    return row?.decision ?? null;
  }

  // 이 캠페인에 관심을 보낸 크리에이터.
  async listCampaignLikerIds(campaignId: string): Promise<Set<string>> {
    const rows = await this.prisma.swipeDecision.findMany({
      where: {
        targetKind: 'CAMPAIGN',
        targetId: campaignId,
        decision: 'LIKE',
        deletedAt: null,
      },
      select: { actorId: true },
    });
    return new Set(rows.map((r) => r.actorId));
  }

  // 이 크리에이터에게 관심을 보낸 브랜드의 캠페인.
  async listCampaignIdsThatLiked(
    creatorId: string,
    brandIds: string[],
  ): Promise<Set<string>> {
    if (brandIds.length === 0) return new Set();
    const rows = await this.prisma.swipeDecision.findMany({
      where: {
        actorId: { in: brandIds },
        targetKind: 'CREATOR',
        targetId: creatorId,
        decision: 'LIKE',
        campaignId: { not: null },
        deletedAt: null,
      },
      select: { campaignId: true },
    });
    return new Set(rows.flatMap((r) => (r.campaignId ? [r.campaignId] : [])));
  }

  // 이 크리에이터의 오퍼 전부(상태 판단용). 열렸는지·기한이 지났는지는 시각이 필요해서 순수 규칙(candidate-rules)이 가린다.
  async listOfferStates(creatorId: string): Promise<OfferStateRow[]> {
    return this.prisma.offer.findMany({
      where: { creatorId, deletedAt: null },
      select: {
        storeId: true,
        initiatedBy: true,
        status: true,
        expiresAt: true,
        paymentDueAt: true,
        declinedAt: true,
        closedAt: true,
      },
    });
  }

  // 지금 살아 있는 지원(APPLIED, OFFERED)을 낸 가게. 오른쪽으로 밀어 지원한 가게는 다시 나오지 않는다.
  async listLiveApplicationStoreIds(creatorId: string): Promise<Set<string>> {
    const rows = await this.prisma.application.findMany({
      where: {
        creatorId,
        status: { in: ['APPLIED', 'OFFERED'] },
        deletedAt: null,
      },
      select: { storeId: true },
    });
    return new Set(rows.map((r) => r.storeId));
  }
}
