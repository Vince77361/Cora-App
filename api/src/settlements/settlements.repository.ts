import { Injectable } from '@nestjs/common';
import {
  Collaboration,
  Payout,
  Prisma,
  Refund,
  Settlement,
  ViewSnapshot,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface NewSnapshot {
  collaborationId: string;
  dayIndex: number;
  views: number | null;
  takenAt: Date;
}

// 되돌리기 신호. 값(result)을 실어 transaction이 그 값을 돌려주게 한다(결제 저장소와 같은 방식).
class Rollback<R> extends Error {
  constructor(readonly result: R) {
    super('rollback');
  }
}

export interface NewSettlement {
  collaborationId: string;
  finalViews: number | null;
  payoutAmount: number;
  refundAmount: number;
  settledAt: Date;
}

export interface NewPayout {
  collaborationId: string;
  amount: number;
  idempotencyKey: string;
  scheduledFor: Date;
}

export interface NewRefund {
  collaborationId: string;
  amount: number;
  idempotencyKey: string;
}

export type PayoutWithCreator = Payout & { creatorId: string };

// 정산·지급·환급과 조회수 스냅샷의 저장소. Prisma는 여기서만 쓴다.
@Injectable()
export class SettlementsRepository {
  constructor(private readonly prisma: PrismaService) {}

  findSnapshot(
    collaborationId: string,
    dayIndex: number,
  ): Promise<ViewSnapshot | null> {
    return this.prisma.viewSnapshot.findFirst({
      where: { collaborationId, dayIndex, deletedAt: null },
    });
  }

  // 가장 최근(dayIndex가 큰) 순서로 돌려준다.
  latestSnapshots(
    collaborationId: string,
    take: number,
    tx?: Prisma.TransactionClient,
  ): Promise<ViewSnapshot[]> {
    return (tx ?? this.prisma).viewSnapshot.findMany({
      where: { collaborationId, deletedAt: null },
      orderBy: { dayIndex: 'desc' },
      take,
    });
  }

  // (collaborationId, dayIndex) 유일 제약이 같은 날의 두 번째 줄을 막는다. 예외 없이 건너뛴다.
  async createSnapshotIfAbsent(row: NewSnapshot): Promise<boolean> {
    const { count } = await this.prisma.viewSnapshot.createMany({
      data: row,
      skipDuplicates: true,
    });
    return count === 1;
  }

  // run 안에서 rollback(값)을 부르면 트랜잭션 전체를 되돌리고 그 값을 돌려준다. 던지면 되돌리고 그대로 던진다.
  async transaction<T, R>(
    run: (
      tx: Prisma.TransactionClient,
      rollback: (result: R) => never,
    ) => Promise<T>,
  ): Promise<T | R> {
    try {
      return await this.prisma.$transaction((tx) =>
        run(tx, (result: R): never => {
          throw new Rollback(result);
        }),
      );
    } catch (error) {
      if (error instanceof Rollback) return error.result as R;
      throw error;
    }
  }

  listSnapshots(collaborationId: string): Promise<ViewSnapshot[]> {
    return this.prisma.viewSnapshot.findMany({
      where: { collaborationId, deletedAt: null },
      orderBy: { dayIndex: 'asc' },
    });
  }

  // 협업마다 가장 최근에 읽은 조회수(읽지 못한 날은 건너뛴다). 협업 조회 화면이 쓴다.
  async latestViewsFor(ids: string[]): Promise<Map<string, number>> {
    const map = new Map<string, number>();
    if (ids.length === 0) return map;
    const rows = await this.prisma.viewSnapshot.findMany({
      where: {
        collaborationId: { in: ids },
        views: { not: null },
        deletedAt: null,
      },
      orderBy: { dayIndex: 'desc' },
    });
    for (const row of rows) {
      if (row.views !== null && !map.has(row.collaborationId)) {
        map.set(row.collaborationId, row.views);
      }
    }
    return map;
  }

  async settlementsFor(ids: string[]): Promise<Map<string, Settlement>> {
    if (ids.length === 0) return new Map();
    const rows = await this.prisma.settlement.findMany({
      where: { collaborationId: { in: ids }, deletedAt: null },
    });
    return new Map(rows.map((row) => [row.collaborationId, row]));
  }

  // 협업마다 가장 최근에 만든 지급 한 줄.
  async latestPayoutsFor(ids: string[]): Promise<Map<string, Payout>> {
    const map = new Map<string, Payout>();
    if (ids.length === 0) return map;
    const rows = await this.prisma.payout.findMany({
      where: { collaborationId: { in: ids }, deletedAt: null },
      orderBy: { createdAt: 'desc' },
    });
    for (const row of rows) {
      if (!map.has(row.collaborationId)) map.set(row.collaborationId, row);
    }
    return map;
  }

  // 그 크리에이터가 받을(받은) 지급 전부. 정산 내역(지갑)이 읽는다.
  listPayoutsForCreator(creatorId: string): Promise<Payout[]> {
    return this.prisma.payout.findMany({
      where: { deletedAt: null, collaboration: { creatorId } },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    });
  }

  findSettlement(collaborationId: string): Promise<Settlement | null> {
    return this.prisma.settlement.findFirst({
      where: { collaborationId, deletedAt: null },
    });
  }

  // 평소 조회수 읽기의 결과를 한 번만 저장한다(usual_read_at이 비어 있을 때만 바꾼다). 졌으면 false다.
  // 읽지 못했거나 읽을 수 없는 협업은 usualViews와 multiplierTenths가 null이고 시각만 채운다.
  async saveUsualViews(
    settlementId: string,
    values: {
      usualViews: number | null;
      multiplierTenths: number | null;
      readAt: Date;
    },
  ): Promise<boolean> {
    const { count } = await this.prisma.settlement.updateMany({
      where: { id: settlementId, usualReadAt: null, deletedAt: null },
      data: {
        usualViews: values.usualViews,
        multiplierTenths: values.multiplierTenths,
        usualReadAt: values.readAt,
      },
    });
    return count === 1;
  }

  // 그 가게의 끝난(SETTLED) 가게 오퍼 협업의 정산 줄. since 이후에 정산된 것만이다(체험단 비교가 쓴다).
  listSettledForStore(
    storeId: string,
    since: Date,
  ): Promise<(Settlement & { collaboration: Collaboration })[]> {
    return this.prisma.settlement.findMany({
      where: {
        deletedAt: null,
        settledAt: { gte: since },
        collaboration: {
          storeId,
          kind: 'STORE_OFFER',
          stage: 'SETTLED',
          deletedAt: null,
        },
      },
      include: { collaboration: true },
      orderBy: { settledAt: 'asc' },
    });
  }

  // 협업당 한 줄(유일 제약). 이미 있으면 예외 없이 false다(호출한 쪽 트랜잭션이 중단되지 않는다).
  async createSettlement(
    row: NewSettlement,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await tx.settlement.createMany({
      data: row,
      skipDuplicates: true,
    });
    return count === 1;
  }

  // 중복 방지 키(유일 제약)가 같은 지급·환급의 두 번째 줄을 막는다. 이미 있으면 그대로 둔다.
  async createPayoutIfAbsent(
    row: NewPayout,
    tx?: Prisma.TransactionClient,
  ): Promise<void> {
    await (tx ?? this.prisma).payout.createMany({
      data: row,
      skipDuplicates: true,
    });
  }

  async createRefundIfAbsent(
    row: NewRefund,
    tx?: Prisma.TransactionClient,
  ): Promise<void> {
    await (tx ?? this.prisma).refund.createMany({
      data: row,
      skipDuplicates: true,
    });
  }

  findPayoutByKey(
    idempotencyKey: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Payout | null> {
    return (tx ?? this.prisma).payout.findFirst({
      where: { idempotencyKey, deletedAt: null },
    });
  }

  async findPayoutWithCreator(id: string): Promise<PayoutWithCreator | null> {
    const row = await this.prisma.payout.findFirst({
      where: { id, deletedAt: null },
      include: { collaboration: { select: { creatorId: true } } },
    });
    if (!row) return null;
    const { collaboration, ...payout } = row;
    return { ...payout, creatorId: collaboration.creatorId };
  }

  // 그 크리에이터의 대기 중 지급 가운데 지급일이 before보다 이른 것.
  listOverduePendingPayouts(
    creatorId: string,
    before: Date,
  ): Promise<Payout[]> {
    return this.prisma.payout.findMany({
      where: {
        status: 'PENDING',
        scheduledFor: { lt: before },
        deletedAt: null,
        collaboration: { creatorId },
      },
      orderBy: { scheduledFor: 'asc' },
    });
  }

  // 대기 중인 지급의 지급일만 옮긴다. 그사이 보내졌다면 0행이라 false다.
  async reschedulePayout(id: string, scheduledFor: Date): Promise<boolean> {
    const { count } = await this.prisma.payout.updateMany({
      where: { id, status: 'PENDING', deletedAt: null },
      data: { scheduledFor },
    });
    return count === 1;
  }

  // PENDING일 때만 바꾼다. 같은 작업이 두 번 돌아도 한 번만 바뀌고, 바뀐 행이 0이면 false다.
  async markPayoutDone(id: string, externalId: string): Promise<boolean> {
    const { count } = await this.prisma.payout.updateMany({
      where: { id, status: 'PENDING', deletedAt: null },
      data: { status: 'DONE', externalId },
    });
    return count === 1;
  }

  // 운영자가 실패한 지급을 다시 보내려고 대기로 되돌린다. FAILED가 아니면 0행이라 false다.
  async markPayoutPending(
    id: string,
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await (tx ?? this.prisma).payout.updateMany({
      where: { id, status: 'FAILED', deletedAt: null },
      data: { status: 'PENDING' },
    });
    return count === 1;
  }

  async markPayoutFailed(id: string): Promise<boolean> {
    const { count } = await this.prisma.payout.updateMany({
      where: { id, status: 'PENDING', deletedAt: null },
      data: { status: 'FAILED' },
    });
    return count === 1;
  }

  findRefundByKey(
    idempotencyKey: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Refund | null> {
    return (tx ?? this.prisma).refund.findFirst({
      where: { idempotencyKey, deletedAt: null },
    });
  }

  findRefundById(id: string): Promise<Refund | null> {
    return this.prisma.refund.findFirst({ where: { id, deletedAt: null } });
  }

  // 대기 중인 환급, 그리고 운영자가 다시 보내는 실패한 환급만 DONE으로 바꾼다. 이미 DONE이면 0행이다.
  async markRefundDone(id: string, externalId: string): Promise<boolean> {
    const { count } = await this.prisma.refund.updateMany({
      where: { id, status: { in: ['PENDING', 'FAILED'] }, deletedAt: null },
      data: { status: 'DONE', externalId },
    });
    return count === 1;
  }
}
