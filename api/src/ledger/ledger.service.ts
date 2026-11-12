import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { assertBalanced, Posting } from './ledger-postings';
import { LedgerRepository } from './ledger.repository';

// 돈이 움직이는 모든 동작(결제 승인, 정산, 환급, 운영 명령)이 장부에 줄을 남길 때 거치는 유일한 곳이다.
@Injectable()
export class LedgerService {
  constructor(private readonly repository: LedgerRepository) {}

  // 한 동작의 줄들을 한 묶음(batchId)으로 넣는다.
  // 같은 중복 방지 키로 이미 넣었으면 아무것도 넣지 않고 'duplicate'를 돌려준다(던지지 않는다).
  // 호출한 쪽이 tx를 주면 그 트랜잭션 안에서 실행한다 — 결제 상태 갱신과 장부가 함께 커밋되거나 함께 되돌아가게.
  // tx가 없으면 자기 트랜잭션을 열어, 검산이 던질 때 넣은 줄도 함께 되돌린다.
  async post(
    collaborationId: string,
    postings: Posting[],
    idempotencyKey: string,
    tx?: Prisma.TransactionClient,
  ): Promise<'posted' | 'duplicate'> {
    for (const p of postings) assertValidPosting(p);
    const rows = postings.filter((p) => p.amount !== 0);
    // 넣을 줄이 없으면(예: 0원 정산) 키를 남길 것도 없다.
    if (rows.length === 0) return 'posted';

    const run = async (client: Prisma.TransactionClient) => {
      await this.repository.lockCollaboration(collaborationId, client);
      const batchId = randomUUID();
      const inserted = await this.repository.insertRows(
        collaborationId,
        idempotencyKey,
        rows.map((p) => ({
          batchId,
          debitAccount: p.debit,
          creditAccount: p.credit,
          amount: p.amount,
          reason: p.reason,
        })),
        client,
      );
      if (inserted === 0) return 'duplicate' as const;
      // 같은 키로 일부만 이미 있는 것은 중복이 아니라 호출 오류다. 던져서 호출한 쪽이 되돌리게 한다.
      if (inserted !== rows.length) {
        throw new Error(
          `장부 오류: 중복 방지 키(${idempotencyKey})가 일부 줄에만 이미 쓰였어요.`,
        );
      }
      assertBalanced(
        await this.repository.listAmounts(collaborationId, client),
      );
      return 'posted' as const;
    };

    return tx ? run(tx) : this.repository.transaction(run);
  }

  // 돈을 얼마나 움직일지 이 값으로 정하는 호출은 자기 트랜잭션(tx)을 넘겨 같은 트랜잭션에서 읽는다.
  escrowBalance(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<number> {
    return this.repository.escrowBalance(collaborationId, tx);
  }

  // 지갑처럼 여러 협업의 보관액을 한꺼번에 보여 줄 때 쓴다(한 스냅샷에서 읽는다).
  escrowBalances(collaborationIds: string[]): Promise<Map<string, number>> {
    return this.repository.escrowBalances(collaborationIds);
  }
}

function assertValidPosting(p: Posting): void {
  if (!Number.isInteger(p.amount) || p.amount < 0) {
    throw new Error(`장부 오류: 금액은 0 이상의 정수여야 해요(${p.amount}).`);
  }
  if (p.debit === p.credit) {
    throw new Error(`장부 오류: 같은 계정끼리는 옮길 수 없어요(${p.debit}).`);
  }
}
