import { Injectable } from '@nestjs/common';
import { Payment, PaymentMethod, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface NewPayment {
  collaborationId: string;
  amountEscrow: number;
  amountFee: number;
  feeRate: number;
  method: PaymentMethod;
  requestedAt: Date;
}

// 되돌리기 신호. 값(result)을 실어 transaction이 그 값을 돌려주게 한다.
class Rollback<R> extends Error {
  constructor(readonly result: R) {
    super('rollback');
  }
}

// 결제 조회와 상태 변경은 모두 여기를 거친다. 상태 변경은 조건부 갱신(UPDATE ... WHERE status = 'PENDING')이라
// 같은 통지가 동시에 여러 번 와도 한 번만 바뀌고, 바뀐 행이 0이면 false를 돌려 서비스가 "이미 처리됨"으로 본다.
@Injectable()
export class PaymentsRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Payment | null> {
    return this.prisma.payment.findFirst({ where: { id, deletedAt: null } });
  }

  // 협업의 보관을 시작시킨 결제: 승인된 결제 가운데 가장 먼저 승인된 것이다.
  // 뒤늦게 승인돼 협업에 반영되지 못한 결제(끝난 협업, 이중 결제)는 항상 그 뒤에 승인된다.
  findFundingPayment(collaborationId: string): Promise<Payment | null> {
    return this.prisma.payment.findFirst({
      where: {
        collaborationId,
        status: 'APPROVED',
        pgTransactionId: { not: null },
        deletedAt: null,
      },
      orderBy: [{ approvedAt: 'asc' }, { createdAt: 'asc' }],
    });
  }

  // 협업 여러 개의 보관을 시작시킨 결제(위와 같은 기준)를 한 번에. 키는 협업 id다.
  async mapFundingPayments(ids: string[]): Promise<Map<string, Payment>> {
    const map = new Map<string, Payment>();
    if (ids.length === 0) return map;
    const rows = await this.prisma.payment.findMany({
      where: {
        collaborationId: { in: ids },
        status: 'APPROVED',
        pgTransactionId: { not: null },
        deletedAt: null,
      },
      orderBy: [{ approvedAt: 'asc' }, { createdAt: 'asc' }],
    });
    for (const row of rows) {
      if (!map.has(row.collaborationId)) map.set(row.collaborationId, row);
    }
    return map;
  }

  // 같은 협업의 대기 중 결제를 취소로 바꾸고 새 결제를 만든다. 호출한 쪽의 트랜잭션 안에서 하므로 대기 결제가 둘이 되지 않는다.
  // 협업 행은 잠그지 않는다: 승인 트랜잭션이 오퍼 → 결제 → 협업 순으로 잡으므로 여기서 협업을 먼저 잡으면 교착이 난다.
  // 호출한 쪽이 먼저 오퍼 행을 잠가(오퍼 → 결제) 동시에 만드는 요청을 한 줄로 세운다.
  async replacePending(
    input: NewPayment,
    tx: Prisma.TransactionClient,
  ): Promise<Payment> {
    await tx.payment.updateMany({
      where: {
        collaborationId: input.collaborationId,
        status: 'PENDING',
        deletedAt: null,
      },
      data: { status: 'CANCELLED' },
    });
    return tx.payment.create({ data: input });
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

  // 대기 중이거나, 새 결제에 밀려 취소된 결제(결제창을 닫았다가 다시 결제한 뒤 첫 결제창의 승인이 뒤늦게 온 경우)만 승인으로 바꾼다.
  // 실패한 결제와 이미 승인된 결제는 0행이다.
  async markApproved(
    id: string,
    pgTransactionId: string,
    approvedAt: Date,
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await (tx ?? this.prisma).payment.updateMany({
      where: {
        id,
        status: { in: ['PENDING', 'CANCELLED'] },
        deletedAt: null,
      },
      data: { status: 'APPROVED', pgTransactionId, approvedAt },
    });
    return count === 1;
  }

  async markFailed(id: string): Promise<boolean> {
    const { count } = await this.prisma.payment.updateMany({
      where: { id, status: 'PENDING', deletedAt: null },
      data: { status: 'FAILED' },
    });
    return count === 1;
  }
}
