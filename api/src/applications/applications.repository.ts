import { Injectable } from '@nestjs/common';
import { Application, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

// 살아 있는 지원: 지원 중(APPLIED)이거나 오퍼를 받은(OFFERED) 지원. 지워지지 않은 것만.
const LIVE = {
  status: { in: ['APPLIED', 'OFFERED'] },
  deletedAt: null,
} satisfies Prisma.ApplicationWhereInput;

// 지원 조회와 상태 변경은 모두 여기를 거친다. 상태 변경은 모두 조건부 갱신이라 동시에 와도 한 번만 바뀐다.
@Injectable()
export class ApplicationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  findLive(storeId: string, creatorId: string): Promise<Application | null> {
    return this.prisma.application.findFirst({
      where: { storeId, creatorId, ...LIVE },
    });
  }

  // 같은 가게·크리에이터의 살아 있는 지원은 부분 유니크 인덱스가 하나로 막는다.
  // 미리 읽은 뒤 동시에 만들어 unique 위반(P2002)이 나면 null로 돌려 서비스가 409로 바꾸게 한다.
  async create(
    storeId: string,
    creatorId: string,
    pitch: string | null = null,
  ): Promise<Application | null> {
    try {
      return await this.prisma.application.create({
        data: { storeId, creatorId, status: 'APPLIED', pitch },
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

  // 오퍼가 나간 지원은 건드리지 않도록 상태 조건을 갱신 문장 안에 둔다.
  async cancelApplied(storeId: string, creatorId: string): Promise<boolean> {
    const { count } = await this.prisma.application.updateMany({
      where: { storeId, creatorId, status: 'APPLIED', deletedAt: null },
      data: { status: 'CANCELLED' },
    });
    return count === 1;
  }

  // 최근 지원 순. 지역 순서는 서비스가 이 순서를 지키며 묶는다.
  listApplied(storeId: string): Promise<Application[]> {
    return this.prisma.application.findMany({
      where: { storeId, status: 'APPLIED', deletedAt: null },
      orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
    });
  }

  // 살아 있는 APPLIED 지원은 많아야 하나(부분 유니크). 조건부 갱신이 1건일 때만 그 id를 돌려준다.
  async markOffered(
    storeId: string,
    creatorId: string,
  ): Promise<string | null> {
    const found = await this.prisma.application.findFirst({
      where: { storeId, creatorId, status: 'APPLIED', deletedAt: null },
      select: { id: true },
    });
    if (!found) return null;
    const { count } = await this.prisma.application.updateMany({
      where: { id: found.id, status: 'APPLIED' },
      data: { status: 'OFFERED' },
    });
    return count === 1 ? found.id : null;
  }

  async closeOffered(applicationId: string): Promise<void> {
    await this.prisma.application.updateMany({
      where: { id: applicationId, status: 'OFFERED' },
      data: { status: 'CLOSED' },
    });
  }

  // 오퍼 만들기가 진 뒤 markOffered를 되돌린다. OFFERED일 때만 바꾸므로 여러 번 불려도 안전하다.
  async reopenOffered(applicationId: string): Promise<void> {
    await this.prisma.application.updateMany({
      where: { id: applicationId, status: 'OFFERED', deletedAt: null },
      data: { status: 'APPLIED' },
    });
  }

  countApplied(storeId: string): Promise<number> {
    return this.prisma.application.count({
      where: { storeId, status: 'APPLIED', deletedAt: null },
    });
  }

  // 크리에이터가 시작한 제안이 오퍼를 만드는 트랜잭션 안에서 부른다. 그 가게에 낸 살아 있는 지원을 오퍼 받음으로 잇고
  // (APPLIED면 바꾸고, 없으면 만든다), 이어진 지원의 id를 돌려준다.
  // 읽은 뒤 다른 요청이 같은 지원을 먼저 바꿨으면 null이다 — 호출한 쪽이 트랜잭션을 되돌린다.
  async linkForProposal(
    tx: Prisma.TransactionClient,
    storeId: string,
    creatorId: string,
  ): Promise<string | null> {
    const live = await tx.application.findFirst({
      where: { storeId, creatorId, ...LIVE },
      select: { id: true, status: true },
    });
    if (live?.status === 'APPLIED') {
      const { count } = await tx.application.updateMany({
        where: { id: live.id, status: 'APPLIED' },
        data: { status: 'OFFERED' },
      });
      return count === 1 ? live.id : null;
    }
    if (live) {
      // 열린 오퍼가 없는데 오퍼 받음인 지원은 닫히지 못하고 남은 옛 지원이다. 닫고 새로 만든다.
      const { count } = await tx.application.updateMany({
        where: { id: live.id, status: 'OFFERED' },
        data: { status: 'CLOSED' },
      });
      if (count !== 1) return null;
    }
    const created = await tx.application.create({
      data: { storeId, creatorId, status: 'OFFERED' },
    });
    return created.id;
  }
}
