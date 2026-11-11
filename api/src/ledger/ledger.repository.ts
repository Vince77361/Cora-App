import { Injectable } from '@nestjs/common';
import { LedgerAccount, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { EntryAmounts } from './ledger-postings';

export interface NewLedgerRow {
  batchId: string;
  debitAccount: LedgerAccount;
  creditAccount: LedgerAccount;
  amount: number;
  reason: string;
}

// 장부 줄은 만들고 읽기만 한다. 수정·삭제 메서드를 두지 않는다(정정은 반대 줄을 더한다).
@Injectable()
export class LedgerRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 호출한 쪽이 트랜잭션을 주지 않았을 때 장부 쪽에서 여는 트랜잭션.
  // 넣은 뒤의 검산(assertBalanced)이 던지면 넣은 줄이 함께 되돌아가게 한다.
  transaction<T>(
    run: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(run);
  }

  // 같은 협업에 동시에 줄을 넣는 호출을 한 줄로 세운다. 트랜잭션이 끝날 때까지 잡고 있다.
  // 이게 없으면 서로 상대가 아직 커밋하지 않은 줄을 못 봐서, 둘 다 검산을 통과하고 에스크로가 음수가 될 수 있다.
  async lockCollaboration(
    collaborationId: string,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    await tx.$queryRaw`
      SELECT id FROM collaborations WHERE id = ${collaborationId}::uuid FOR UPDATE`;
  }

  // ON CONFLICT DO NOTHING으로 넣는다. 유일 제약 위반을 예외로 받으면 호출한 쪽 트랜잭션이 통째로 중단되므로
  // 예외가 나지 않는 방식이어야 한다. 실제로 들어간 줄 수를 돌려준다.
  async insertRows(
    collaborationId: string,
    idempotencyKey: string,
    rows: NewLedgerRow[],
    tx: Prisma.TransactionClient,
  ): Promise<number> {
    const { count } = await tx.ledgerEntry.createMany({
      data: rows.map((row) => ({ ...row, collaborationId, idempotencyKey })),
      skipDuplicates: true,
    });
    return count;
  }

  listAmounts(
    collaborationId: string,
    tx: Prisma.TransactionClient,
  ): Promise<EntryAmounts[]> {
    return tx.ledgerEntry.findMany({
      where: { collaborationId, deletedAt: null },
      select: { debitAccount: true, creditAccount: true, amount: true },
    });
  }

  // tx를 주면 그 트랜잭션 안에서 읽는다. 돈을 얼마나 움직일지 이 값으로 정하는 호출(정산)은 같은 트랜잭션에서 읽어야
  // 읽은 뒤 다른 줄이 끼어들지 못한다. 한 연결에서 차례로 읽으므로 풀 연결을 둘 잡지 않는다.
  async escrowBalance(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<number> {
    const client = tx ?? this.prisma;
    const sum = async (side: 'creditAccount' | 'debitAccount') => {
      const { _sum } = await client.ledgerEntry.aggregate({
        where: { collaborationId, deletedAt: null, [side]: 'ESCROW' },
        _sum: { amount: true },
      });
      return _sum.amount ?? 0;
    };
    const into = await sum('creditAccount');
    const out = await sum('debitAccount');
    return into - out;
  }
}
