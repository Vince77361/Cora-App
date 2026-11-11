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

  // 같은 협업의 대기 중 결제를 취소로 바꾸고 새 결제를 만든다. 한 트랜잭션이라 대기 결제가 둘이 되지 않는다.
  // 협업 행은 잠그지 않는다: 승인 트랜잭션이 결제 행 → 협업 행 순으로 잡으므로 여기서 협업을 먼저 잡으면 교착이 난다.
  replacePending(input: NewPayment): Promise<Payment> {
    return this.prisma.$transaction(async (tx) => {
      await tx.payment.updateMany({
        where: {
          collaborationId: input.collaborationId,
          status: 'PENDING',
          deletedAt: null,
        },
        data: { status: 'CANCELLED' },
      });
      return tx.payment.create({ data: input });
    });
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

  async markApproved(
    id: string,
    pgTransactionId: string,
    approvedAt: Date,
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await (tx ?? this.prisma).payment.updateMany({
      where: { id, status: 'PENDING', deletedAt: null },
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
