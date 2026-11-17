import { Injectable } from '@nestjs/common';
import { Prisma, Report, ReportReason, ReportTargetKind } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface NewReport {
  reporterId: string;
  targetKind: ReportTargetKind;
  targetId: string;
  reason: ReportReason;
  detail: string | null;
  now: Date;
}

// 차단과 신고의 저장소. 여러 협업·방·오퍼를 건드리는 차단은 한 트랜잭션이라, 원격 풀러가 느릴 때를 위해 운영 명령과 같은 제한을 둔다.
@Injectable()
export class SafetyRepository {
  constructor(private readonly prisma: PrismaService) {}

  transaction<T>(
    run: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(run, { maxWait: 10_000, timeout: 30_000 });
  }

  // 같은 차단을 다시 하면 그대로 둔다(되돌리기 위해 지운 행이 있어도 살린다).
  async saveBlock(
    blockerId: string,
    blockedId: string,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    await tx.block.upsert({
      where: { blockerId_blockedId: { blockerId, blockedId } },
      create: { blockerId, blockedId, createdAt: now, updatedAt: now },
      update: { deletedAt: null, updatedAt: now },
    });
  }

  findReport(
    reporterId: string,
    targetKind: ReportTargetKind,
    targetId: string,
  ): Promise<Report | null> {
    return this.prisma.report.findFirst({
      where: { reporterId, targetKind, targetId, deletedAt: null },
    });
  }

  // 같은 신고자·대상의 두 번째는 유일 제약에 걸려 null이다(동시에 두 번 눌러도 하나만 남는다).
  async createReport(
    input: NewReport,
    tx: Prisma.TransactionClient,
  ): Promise<Report | null> {
    try {
      return await tx.report.create({
        data: {
          reporterId: input.reporterId,
          targetKind: input.targetKind,
          targetId: input.targetId,
          reason: input.reason,
          detail: input.detail,
          createdAt: input.now,
          updatedAt: input.now,
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return null;
      }
      throw error;
    }
  }

  // 처리 완료로 표시한다. 아직 처리하지 않은 신고만 바뀌고, 없거나 이미 처리했으면 이유를 돌려준다.
  async resolveReport(
    id: string,
    operator: string,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<
    | { result: 'RESOLVED'; report: Report }
    | { result: 'MISSING' }
    | { result: 'ALREADY' }
  > {
    const report = await tx.report.findFirst({
      where: { id, deletedAt: null },
    });
    if (!report) return { result: 'MISSING' };
    const { count } = await tx.report.updateMany({
      where: { id, resolvedAt: null },
      data: { resolvedAt: now, resolvedBy: operator, updatedAt: now },
    });
    if (count !== 1) return { result: 'ALREADY' };
    return { result: 'RESOLVED', report };
  }
}
