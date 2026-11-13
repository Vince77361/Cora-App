import { Injectable } from '@nestjs/common';
import {
  Collaboration,
  CollaborationKind,
  CollaborationStage,
  Prisma,
  SettlementMethod,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

// 단계를 바꿀 때 함께 쓰는 열. 단계 규칙이 정하는 것만 둔다.
export interface CollaborationPatch {
  fundedAt?: Date | null;
  submitDueAt?: Date | null;
  submittedUrl?: string | null;
  submittedAt?: Date | null;
  countingEndsAt?: Date | null;
  haltedReason?: string | null;
  stageBeforeHalt?: CollaborationStage | null;
}

export interface NewCollaboration {
  kind: CollaborationKind;
  stage: CollaborationStage;
  commissionerId: string;
  creatorId: string;
  offerId: string | null;
  storeId: string | null;
  terms: Prisma.InputJsonValue;
  settlementMethod: SettlementMethod;
  fundedAt: Date | null;
  submitDueAt: Date | null;
  // 만든 시각을 DB 기본값이 아니라 Clock으로 정할 때 준다(진행 막대의 "오퍼 수락" 시각, 원장 판단 R42).
  createdAt?: Date;
}

// 다른 기능 모듈이 협업을 읽고 바꿀 때 거치는 유일한 곳이다. 이 모듈은 다른 기능 모듈을 import하지 않는다.
// tx를 주면 그 트랜잭션 안에서 실행한다(오퍼의 수락·취소와 같은 트랜잭션).
@Injectable()
export class CollaborationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  private client(tx?: Prisma.TransactionClient) {
    return tx ?? this.prisma;
  }

  findById(
    id: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Collaboration | null> {
    return this.client(tx).collaboration.findFirst({
      where: { id, deletedAt: null },
    });
  }

  findByOfferId(offerId: string): Promise<Collaboration | null> {
    return this.prisma.collaboration.findFirst({
      where: { offerId, deletedAt: null },
    });
  }

  // 오퍼 여러 개의 협업을 한 번에. 키는 offerId다.
  async mapByOfferIds(offerIds: string[]): Promise<Map<string, Collaboration>> {
    if (offerIds.length === 0) return new Map();
    const rows = await this.prisma.collaboration.findMany({
      where: { offerId: { in: offerIds }, deletedAt: null },
    });
    const map = new Map<string, Collaboration>();
    for (const row of rows) if (row.offerId) map.set(row.offerId, row);
    return map;
  }

  create(
    data: NewCollaboration,
    tx?: Prisma.TransactionClient,
  ): Promise<Collaboration> {
    return this.client(tx).collaboration.create({ data });
  }

  // 단계 전이는 모두 조건부 갱신(UPDATE ... WHERE id = ? AND stage = 기대 단계)이다.
  // 동시에 와도 한 번만 바뀌고, 바뀐 행이 0이면 false를 돌려 호출하는 쪽이 409나 "아무 일도 안 함"으로 바꾼다.
  // 허용되는 전이인지는 호출하는 쪽이 canTransition으로 먼저 본다.
  async advance(
    id: string,
    from: CollaborationStage,
    to: CollaborationStage,
    patch: CollaborationPatch = {},
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await this.client(tx).collaboration.updateMany({
      where: { id, stage: from, deletedAt: null },
      data: { ...patch, stage: to },
    });
    return count === 1;
  }

  // 오퍼에 연결된 협업의 단계를 옮긴다. 협업을 읽지 않고도 오퍼 id만으로 한 번에 갱신한다.
  async advanceByOffer(
    offerId: string,
    from: CollaborationStage,
    to: CollaborationStage,
    patch: CollaborationPatch = {},
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await this.client(tx).collaboration.updateMany({
      where: { offerId, stage: from, deletedAt: null },
      data: { ...patch, stage: to },
    });
    return count === 1;
  }

  // 내가 당사자(맡긴 쪽 또는 크리에이터)인 협업을 최근 것부터. stage로 진행 중·끝남을 가른다.
  listForParty(
    userId: string,
    stage: Prisma.EnumCollaborationStageFilter,
  ): Promise<Collaboration[]> {
    return this.prisma.collaboration.findMany({
      where: {
        OR: [{ commissionerId: userId }, { creatorId: userId }],
        stage,
        deletedAt: null,
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    });
  }

  // 가게의 협업 가운데 이 단계들에 있는 것의 수.
  countForStore(
    storeId: string,
    stages: CollaborationStage[],
  ): Promise<number> {
    return this.prisma.collaboration.count({
      where: { storeId, stage: { in: stages }, deletedAt: null },
    });
  }

  // 크리에이터의 모든 협업(정산 내역이 읽는다). 단계로 거르는 일은 읽는 쪽 규칙이다.
  listByCreator(creatorId: string): Promise<Collaboration[]> {
    return this.prisma.collaboration.findMany({
      where: { creatorId, deletedAt: null },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    });
  }

  // 크리에이터의 협업 가운데 정산 방식이 맞는 것(여럿 가능)의 종류와 단계. 인스타그램 연결 해제처럼
  // "보관 중인 돈이 있는가"를 단계 규칙(isMoneyHeld)으로 판단하는 쪽이 쓴다.
  listForCreator(
    creatorId: string,
    settlementMethods: SettlementMethod[],
  ): Promise<Pick<Collaboration, 'kind' | 'stage'>[]> {
    return this.prisma.collaboration.findMany({
      where: {
        creatorId,
        settlementMethod: { in: settlementMethods },
        deletedAt: null,
      },
      select: { kind: true, stage: true },
    });
  }
}
