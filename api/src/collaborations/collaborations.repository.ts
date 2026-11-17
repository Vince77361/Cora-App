import { Injectable } from '@nestjs/common';
import {
  Collaboration,
  CollaborationKind,
  CollaborationStage,
  DropReason,
  Prisma,
  SettlementMethod,
} from '@prisma/client';
import { Clock } from '../common/clock';
import { PrismaService } from '../prisma/prisma.service';
import {
  BRAND_PAYMENT_LOCK_MINUTES,
  COLLABORATION_DONE_STAGES,
  UNSECURED_BRAND_STAGES,
} from './collaboration-stage';

// 단계를 바꿀 때 함께 쓰는 열. 단계 규칙이 정하는 것만 둔다.
export interface CollaborationPatch {
  fundedAt?: Date | null;
  submitDueAt?: Date | null;
  submittedUrl?: string | null;
  submittedAt?: Date | null;
  countingEndsAt?: Date | null;
  haltedReason?: string | null;
  stageBeforeHalt?: CollaborationStage | null;
  // 계약 전에 그만둘 때(DROPPED) 이유와 그만둔 사람을 함께 적는다. 상대에게는 알리지 않고 저장만 한다.
  dropReason?: DropReason | null;
  droppedById?: string | null;
}

export interface NewCollaboration {
  kind: CollaborationKind;
  stage: CollaborationStage;
  commissionerId: string;
  creatorId: string;
  offerId: string | null;
  storeId: string | null;
  // 브랜드 계약이 나온 캠페인. 가게 오퍼는 생략한다.
  campaignId?: string | null;
  // 크리에이터가 "조건부터 질문하기"에 적은 콘텐츠 한 줄(40자).
  creatorNote?: string | null;
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

  // 같은 캠페인·크리에이터의 브랜드 협업(하나뿐이다).
  findBrandContract(
    campaignId: string,
    creatorId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Collaboration | null> {
    return this.client(tx).collaboration.findFirst({
      where: { kind: 'BRAND_CONTRACT', campaignId, creatorId, deletedAt: null },
    });
  }

  // 이 크리에이터가 이미 협업(문의·끝난 것 포함)을 만든 캠페인. 받은 제안에서 빼는 데 쓴다.
  async listCampaignIdsWithBrandContract(
    creatorId: string,
    campaignIds: string[],
  ): Promise<Set<string>> {
    if (campaignIds.length === 0) return new Set();
    const rows = await this.prisma.collaboration.findMany({
      where: {
        kind: 'BRAND_CONTRACT',
        creatorId,
        campaignId: { in: campaignIds },
        deletedAt: null,
      },
      select: { campaignId: true },
    });
    return new Set(rows.flatMap((r) => (r.campaignId ? [r.campaignId] : [])));
  }

  // 협업마다 대화방의 id. 방이 없는 협업은 맵에 없다. 이 모듈은 다른 기능 모듈을 import하지 않으므로
  // 대화방·계약 표는 저장소 안에서 직접 읽는다(오퍼·지원 표와 같다).
  async mapConversationIds(
    collaborationIds: string[],
  ): Promise<Map<string, string>> {
    if (collaborationIds.length === 0) return new Map();
    const rows = await this.prisma.conversation.findMany({
      where: { collaborationId: { in: collaborationIds }, deletedAt: null },
      select: { id: true, collaborationId: true },
    });
    return new Map(rows.map((row) => [row.collaborationId, row.id]));
  }

  // 협업마다 살아 있는(무효가 아닌) 계약의 진행. 계약이 없는 협업은 맵에 없다(NONE으로 읽는다).
  async mapContractProgress(
    collaborationIds: string[],
    tx?: Prisma.TransactionClient,
  ): Promise<Map<string, 'AWAITING_BRAND' | 'CONCLUDED'>> {
    if (collaborationIds.length === 0) return new Map();
    const rows = await this.client(tx).contract.findMany({
      where: {
        collaborationId: { in: collaborationIds },
        status: { not: 'VOIDED' },
        deletedAt: null,
      },
      select: { collaborationId: true, status: true },
    });
    const map = new Map<string, 'AWAITING_BRAND' | 'CONCLUDED'>();
    for (const row of rows) {
      if (row.status === 'AWAITING_BRAND' || row.status === 'CONCLUDED') {
        map.set(row.collaborationId, row.status);
      }
    }
    return map;
  }

  // 두 사람 사이(어느 쪽이 맡기는 쪽이든)의 협업을 잠그고 읽는다. 차단과 신고가 쓴다.
  // 잠금 순서는 정산 행 → 오퍼 → 협업이다(운영 명령·결제 승인과 같은 순서): 이 순서로 잡으면 그 길과 서로 기다리지 않는다.
  // 오퍼는 아직 협업이 없는 열린(SENT) 오퍼까지 모두 잠근다. 다른 모듈의 표(정산·오퍼)는 이 저장소가 직접 읽는다(R10).
  async lockAndListBetween(
    a: string,
    b: string,
    tx: Prisma.TransactionClient,
  ): Promise<Collaboration[]> {
    await tx.$queryRaw`
      SELECT s.id FROM settlements s
      JOIN collaborations c ON c.id = s.collaboration_id
      WHERE c.deleted_at IS NULL AND (
        (c.commissioner_id = ${a}::uuid AND c.creator_id = ${b}::uuid)
        OR (c.commissioner_id = ${b}::uuid AND c.creator_id = ${a}::uuid))
      ORDER BY s.id FOR UPDATE OF s`;
    await tx.$queryRaw`
      SELECT o.id FROM offers o
      JOIN stores st ON st.id = o.store_id
      WHERE o.deleted_at IS NULL AND o.status IN ('SENT', 'ACCEPTED') AND (
        (o.creator_id = ${a}::uuid AND st.owner_id = ${b}::uuid)
        OR (o.creator_id = ${b}::uuid AND st.owner_id = ${a}::uuid))
      ORDER BY o.id FOR UPDATE OF o`;
    await tx.$queryRaw`
      SELECT id FROM collaborations
      WHERE deleted_at IS NULL AND (
        (commissioner_id = ${a}::uuid AND creator_id = ${b}::uuid)
        OR (commissioner_id = ${b}::uuid AND creator_id = ${a}::uuid))
      ORDER BY id FOR UPDATE`;
    return tx.collaboration.findMany({
      where: {
        deletedAt: null,
        OR: [
          { commissionerId: a, creatorId: b },
          { commissionerId: b, creatorId: a },
        ],
      },
      orderBy: { id: 'asc' },
    });
  }

  transaction<T>(
    run: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(run);
  }

  // 이 협업 행 하나를 트랜잭션이 끝날 때까지 잠근다. 조건 확인·새 판본·그만두기가 같은 협업에서는 한 줄로 서게 한다.
  async lock(id: string, tx: Prisma.TransactionClient): Promise<void> {
    await tx.$queryRaw`
      SELECT id FROM collaborations WHERE id = ${id}::uuid FOR UPDATE`;
  }

  // 브랜드의 결제가 진행 중인가: PENDING이고 요청한 지 BRAND_PAYMENT_LOCK_MINUTES 분이 안 됐다.
  // 경계(now - 잠금 시간)를 여기서 한 번만 계산해, 조건 제안·이력·그만두기가 같은 기준을 쓴다.
  // 결제를 만드는 쪽(7번 작업)이 이 표에 행을 넣는다. 다른 모듈의 표라 이 저장소가 직접 읽는다(R10). 읽기만 하고 잠그지 않는다:
  // 결제 승인은 결제 → 협업 순서로 잠그므로 여기서 결제 행을 잠그면 거꾸로 잡힌다.
  async hasOpenBrandPayment(
    collaborationId: string,
    now: Date,
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    const since = new Date(
      now.getTime() - BRAND_PAYMENT_LOCK_MINUTES * 60 * 1000,
    );
    const count = await this.client(tx).payment.count({
      where: {
        collaborationId,
        status: 'PENDING',
        requestedAt: { gt: since },
        deletedAt: null,
      },
    });
    return count > 0;
  }

  // 아직 브랜드가 결제하지 않은(AWAITING_BRAND) 계약을 무효로 만든다. 협업이 끝나거나 조건이 바뀔 때 부른다.
  // 체결된(CONCLUDED) 계약은 건드리지 않는다: 체결된 협업은 돈이 보관 중이라 이 길로 끝나지 않는다.
  async voidPendingContract(
    collaborationId: string,
    reason: 'NEW_TERMS' | 'DROPPED' | 'BLOCKED',
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await tx.contract.updateMany({
      where: {
        collaborationId,
        status: 'AWAITING_BRAND',
        deletedAt: null,
      },
      data: {
        status: 'VOIDED',
        voidedAt: now,
        voidReason: reason,
        updatedAt: now,
      },
    });
    return count > 0;
  }

  findByOfferId(
    offerId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Collaboration | null> {
    return this.client(tx).collaboration.findFirst({
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

  // 제안함(F3)에 올릴 브랜드 계약 협업: 내가 당사자이고 stages에 있는 것. 끝난 줄 가운데 요청을 거절했거나 차단으로 끝난 것,
  // 받은 사람이 답하기 전에 그만두어 거둔 메시지 요청(방이 DECLINED)은 사람이 협의하다 끝낸 것이 아니라서 뺀다.
  // dropReason이 비어 있거나 chosenDropReasons에 있는 것만 남기는 것은 NOT IN이 빈 값을 걸러 내는 것을 피하려는 것이다.
  listBrandContractsForInbox(
    userId: string,
    stages: CollaborationStage[],
    chosenDropReasons: DropReason[],
  ): Promise<Collaboration[]> {
    return this.prisma.collaboration.findMany({
      where: {
        kind: 'BRAND_CONTRACT',
        stage: { in: stages },
        deletedAt: null,
        AND: [
          { OR: [{ commissionerId: userId }, { creatorId: userId }] },
          {
            OR: [
              { dropReason: null },
              { dropReason: { in: chosenDropReasons } },
            ],
          },
          {
            OR: [
              { conversation: null },
              { conversation: { status: { not: 'DECLINED' } } },
            ],
          },
        ],
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    });
  }

  // 캠페인들의 확보액을 셀 브랜드 협업(INQUIRY·DROPPED·REFUNDED는 뺀다)의 id와 캠페인. 캠페인마다 부르지 않고 한 번에 읽는다.
  listSecuredBrandContracts(
    campaignIds: string[],
  ): Promise<{ id: string; campaignId: string }[]> {
    if (campaignIds.length === 0) return Promise.resolve([]);
    return this.prisma.collaboration
      .findMany({
        where: {
          kind: 'BRAND_CONTRACT',
          campaignId: { in: campaignIds },
          stage: { notIn: UNSECURED_BRAND_STAGES },
          deletedAt: null,
        },
        select: { id: true, campaignId: true },
      })
      .then((rows) =>
        rows.flatMap((row) =>
          row.campaignId ? [{ id: row.id, campaignId: row.campaignId }] : [],
        ),
      );
  }

  // 맡긴 쪽 하나와 끝나지 않은 협업(진행 중이거나 멈춘 것)이 있는 크리에이터. 하루 추천이 이미 일하는 사이를 뺄 때 쓴다.
  async listOpenCreatorIds(
    commissionerId: string,
    creatorIds: string[],
  ): Promise<Set<string>> {
    if (creatorIds.length === 0) return new Set();
    const rows = await this.prisma.collaboration.findMany({
      where: {
        commissionerId,
        creatorId: { in: creatorIds },
        stage: { notIn: COLLABORATION_DONE_STAGES },
        deletedAt: null,
      },
      select: { creatorId: true },
    });
    return new Set(rows.map((r) => r.creatorId));
  }

  // 그 캠페인에서 중도에 그만둔(DROPPED) 크리에이터. 같은 캠페인에서는 다시 추천하지 않는다.
  async listDroppedCreatorIds(
    campaignId: string,
    creatorIds: string[],
  ): Promise<Set<string>> {
    if (creatorIds.length === 0) return new Set();
    const rows = await this.prisma.collaboration.findMany({
      where: {
        campaignId,
        creatorId: { in: creatorIds },
        stage: 'DROPPED',
        deletedAt: null,
      },
      select: { creatorId: true },
    });
    return new Set(rows.map((r) => r.creatorId));
  }

  // 크리에이터와 끝나지 않은 협업이 있는 맡긴 쪽(브랜드·가게 주인). listOpenCreatorIds의 반대쪽이다.
  async listOpenCommissionerIds(
    creatorId: string,
    commissionerIds: string[],
  ): Promise<Set<string>> {
    if (commissionerIds.length === 0) return new Set();
    const rows = await this.prisma.collaboration.findMany({
      where: {
        creatorId,
        commissionerId: { in: commissionerIds },
        stage: { notIn: COLLABORATION_DONE_STAGES },
        deletedAt: null,
      },
      select: { commissionerId: true },
    });
    return new Set(rows.map((r) => r.commissionerId));
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

  // 크리에이터별로 이 단계에 있는 협업의 수(지원자 추천의 "마친 협업"). 없는 크리에이터는 맵에 없다.
  async countByCreators(
    creatorIds: string[],
    stages: CollaborationStage[],
  ): Promise<Map<string, number>> {
    if (creatorIds.length === 0) return new Map();
    const rows = await this.prisma.collaboration.groupBy({
      by: ['creatorId'],
      where: {
        creatorId: { in: creatorIds },
        stage: { in: stages },
        deletedAt: null,
      },
      _count: { _all: true },
    });
    return new Map(rows.map((r) => [r.creatorId, r._count._all]));
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
