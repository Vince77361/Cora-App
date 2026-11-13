import { Injectable } from '@nestjs/common';
import {
  Collaboration,
  CollaborationKind,
  CollaborationStage,
  Prisma,
  SettlementMethod,
} from '@prisma/client';
import { Clock } from '../common/clock';
import { PrismaService } from '../prisma/prisma.service';
import { COLLABORATION_DONE_STAGES } from './collaboration-stage';

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
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

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
    return this.move({ id }, from, to, patch, tx);
  }

  // 오퍼에 연결된 협업의 단계를 옮긴다. 협업을 읽지 않고도 오퍼 id만으로 한 번에 갱신한다.
  async advanceByOffer(
    offerId: string,
    from: CollaborationStage,
    to: CollaborationStage,
    patch: CollaborationPatch = {},
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    return this.move({ offerId }, from, to, patch, tx);
  }

  // 끝 단계로 옮길 때는 연결된 오퍼를 먼저 닫고 지원을 닫는다. 협업이 끝나는 길은 모두 이 저장소의 advance와
  // advanceByOffer를 지나므로, 여기 한 곳에서 닫으면 정산·환급·취소·운영 명령이 전부 덮인다. 오퍼를 닫아야
  // 같은 가게가 다시 오퍼하고 크리에이터가 다시 지원할 수 있다(열린 오퍼의 부분 유니크 인덱스가 closed_at을 본다).
  // 잠금 순서는 오퍼 → 협업이라 오퍼 → 결제 → 협업 순서(3번 R34)와 거꾸로 되지 않는다.
  // 이 모듈은 다른 기능 모듈을 import하지 않으므로(R10) 오퍼·지원 테이블은 저장소 안에서 직접 쓴다.
  private async move(
    key: { id: string } | { offerId: string },
    from: CollaborationStage,
    to: CollaborationStage,
    patch: CollaborationPatch,
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    if (!COLLABORATION_DONE_STAGES.includes(to)) {
      return this.moveStage(this.client(tx), key, from, to, patch);
    }
    // 호출한 쪽이 트랜잭션을 주지 않았어도 오퍼 닫기와 협업 이동은 함께 되거나 함께 안 돼야 한다.
    if (tx) return this.closeThenMove(tx, key, from, to, patch);
    return this.prisma.$transaction((own) =>
      this.closeThenMove(own, key, from, to, patch),
    );
  }

  private async moveStage(
    client: Prisma.TransactionClient | PrismaService,
    key: { id: string } | { offerId: string },
    from: CollaborationStage,
    to: CollaborationStage,
    patch: CollaborationPatch,
  ): Promise<boolean> {
    const { count } = await client.collaboration.updateMany({
      where: { ...key, stage: from, deletedAt: null },
      data: { ...patch, stage: to },
    });
    return count === 1;
  }

  private async closeThenMove(
    tx: Prisma.TransactionClient,
    key: { id: string } | { offerId: string },
    from: CollaborationStage,
    to: CollaborationStage,
    patch: CollaborationPatch,
  ): Promise<boolean> {
    const current = await tx.collaboration.findFirst({
      where: { ...key, stage: from, deletedAt: null },
      select: { offerId: true },
    });
    // 오퍼 없는 협업(브랜드 계약)이거나 이미 단계가 바뀐 경우: 닫을 것이 없다. 이동은 평소대로 조건부로 시도한다.
    if (!current?.offerId) return this.moveStage(tx, key, from, to, patch);

    const closedAt = this.clock.now();
    const closed = await tx.offer.updateMany({
      where: { id: current.offerId, closedAt: null },
      data: { closedAt },
    });
    const moved = await this.moveStage(tx, key, from, to, patch);
    if (!moved) {
      // 읽은 뒤 다른 요청이 먼저 단계를 바꿨다. 우리가 닫은 오퍼만 되돌려 둔다.
      if (closed.count === 1) {
        await tx.offer.updateMany({
          where: { id: current.offerId, closedAt },
          data: { closedAt: null },
        });
      }
      return false;
    }
    const offer = await tx.offer.findUnique({
      where: { id: current.offerId },
      select: { applicationId: true },
    });
    if (offer?.applicationId) {
      await tx.application.updateMany({
        where: { id: offer.applicationId, status: 'OFFERED' },
        data: { status: 'CLOSED' },
      });
    }
    return true;
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
