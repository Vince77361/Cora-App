import { Injectable } from '@nestjs/common';
import {
  Collaboration,
  OpsAuditLog,
  Payment,
  Payout,
  Prisma,
  Refund,
  Settlement,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface NewAuditRow {
  command: string;
  collaborationId: string | null;
  operator: string;
  reason: string;
  detail: Prisma.InputJsonValue;
  createdAt: Date;
}

export interface CollaborationSnapshot {
  collaboration: Collaboration;
  payments: Payment[];
  payouts: Payout[];
  refunds: Refund[];
  settlement: Settlement | null;
  audits: OpsAuditLog[];
}

// 운영 명령의 감사 기록과 트랜잭션, 읽기 전용 조회(show). Prisma는 여기서만 쓴다.
// show는 결제·지급·환급·정산을 한 번에 읽어야 해서 이 저장소가 읽기만 한다(쓰기는 각 모듈의 서비스를 거친다).
@Injectable()
export class OpsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 원격 DB라 기본 5초로는 장부와 단계를 함께 쓰는 명령이 모자랄 수 있다.
  transaction<T>(
    run: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(run, { maxWait: 10_000, timeout: 30_000 });
  }

  // 협업 행을 잠가 같은 협업에 대한 명령·정산·장부 쓰기를 한 줄로 세운다. 협업이 없으면 false다.
  // 잠금 순서는 오퍼 → 협업이다: 끝 단계로 옮길 때 연결된 오퍼도 닫으므로, 오퍼를 먼저 잠그는 길(결제 승인, 판본 수락)과 맞춘다.
  async lockCollaboration(
    collaborationId: string,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    await tx.$queryRaw`
      SELECT o.id FROM offers o
      JOIN collaborations c ON c.offer_id = o.id
      WHERE c.id = ${collaborationId}::uuid FOR UPDATE OF o`;
    const rows = await tx.$queryRaw<{ id: string }[]>`
      SELECT id FROM collaborations WHERE id = ${collaborationId}::uuid FOR UPDATE`;
    return rows.length > 0;
  }

  async writeAudit(row: NewAuditRow, tx: Prisma.TransactionClient) {
    await tx.opsAuditLog.create({ data: row });
  }

  async snapshot(
    collaborationId: string,
  ): Promise<CollaborationSnapshot | null> {
    const row = await this.prisma.collaboration.findFirst({
      where: { id: collaborationId, deletedAt: null },
      include: {
        payments: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } },
        payouts: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } },
        refunds: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } },
        settlement: true,
        opsAuditLogs: {
          where: { deletedAt: null },
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
      },
    });
    if (!row) return null;
    const {
      payments,
      payouts,
      refunds,
      settlement,
      opsAuditLogs: audits,
      ...collaboration
    } = row;
    return {
      collaboration,
      payments,
      payouts,
      refunds,
      settlement: settlement?.deletedAt ? null : settlement,
      audits,
    };
  }
}
