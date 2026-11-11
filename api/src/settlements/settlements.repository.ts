import { Injectable } from '@nestjs/common';
import { Prisma, ViewSnapshot } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface NewSnapshot {
  collaborationId: string;
  dayIndex: number;
  views: number | null;
  takenAt: Date;
}

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
}
