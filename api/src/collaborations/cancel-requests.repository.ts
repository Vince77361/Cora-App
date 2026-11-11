import { Injectable } from '@nestjs/common';
import { CancelRequest, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

// 되돌리기 신호. 값(result)을 실어 transaction이 그 값을 돌려주게 한다(결제·정산 저장소와 같은 방식).
class Rollback<R> extends Error {
  constructor(readonly result: R) {
    super('rollback');
  }
}

// 결제 뒤 취소 요청(cancel_requests)의 저장소. 모든 상태 변경은 조건부 갱신이다.
@Injectable()
export class CancelRequestsRepository {
  constructor(private readonly prisma: PrismaService) {}

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

  // 같은 협업에 대한 취소·요청·동의를 한 줄로 세운다(트랜잭션이 끝날 때까지 잡는다).
  // 이게 없으면 동시에 온 요청 둘이 서로의 줄을 못 봐서 대기 요청이 둘 생기거나, 취소와 동의가 겹친다.
  async lockCollaboration(
    collaborationId: string,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    await tx.$queryRaw`
      SELECT id FROM collaborations WHERE id = ${collaborationId}::uuid FOR UPDATE`;
  }

  findById(id: string): Promise<CancelRequest | null> {
    return this.prisma.cancelRequest.findFirst({
      where: { id, deletedAt: null },
    });
  }

  // 아직 답을 기다리는(PENDING이고 시각이 지나지 않은) 요청. 협업마다 가장 최근 하나다.
  async mapPendingFor(
    collaborationIds: string[],
    now: Date,
  ): Promise<Map<string, CancelRequest>> {
    const map = new Map<string, CancelRequest>();
    if (collaborationIds.length === 0) return map;
    const rows = await this.prisma.cancelRequest.findMany({
      where: {
        collaborationId: { in: collaborationIds },
        status: 'PENDING',
        expiresAt: { gt: now },
        deletedAt: null,
      },
      orderBy: { createdAt: 'desc' },
    });
    for (const row of rows) {
      if (!map.has(row.collaborationId)) map.set(row.collaborationId, row);
    }
    return map;
  }

  findPending(
    collaborationId: string,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<CancelRequest | null> {
    return tx.cancelRequest.findFirst({
      where: {
        collaborationId,
        status: 'PENDING',
        expiresAt: { gt: now },
        deletedAt: null,
      },
    });
  }

  // 시각이 지났는데 작업이 아직 못 지운 낡은 요청을 정리한다. 새 요청을 만들기 전에 부른다.
  async expireStale(
    collaborationId: string,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    await tx.cancelRequest.updateMany({
      where: {
        collaborationId,
        status: 'PENDING',
        expiresAt: { lte: now },
        deletedAt: null,
      },
      data: { status: 'EXPIRED' },
    });
  }

  create(
    data: { collaborationId: string; requestedById: string; expiresAt: Date },
    tx: Prisma.TransactionClient,
  ): Promise<CancelRequest> {
    return tx.cancelRequest.create({ data });
  }

  // 동의: 아직 기다리는 요청만 ACCEPTED로 바꾼다. 이미 답했거나 만료됐으면 0행이라 false다.
  async accept(
    id: string,
    collaborationId: string,
    now: Date,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await tx.cancelRequest.updateMany({
      where: {
        id,
        collaborationId,
        status: 'PENDING',
        expiresAt: { gt: now },
        deletedAt: null,
      },
      data: { status: 'ACCEPTED' },
    });
    return count === 1;
  }

  // 만료 작업: PENDING일 때만 EXPIRED로 바꾼다. 같은 작업이 다시 돌아도 같고, 동의한 요청은 건드리지 않는다.
  async expire(id: string): Promise<boolean> {
    const { count } = await this.prisma.cancelRequest.updateMany({
      where: { id, status: 'PENDING', deletedAt: null },
      data: { status: 'EXPIRED' },
    });
    return count === 1;
  }
}
