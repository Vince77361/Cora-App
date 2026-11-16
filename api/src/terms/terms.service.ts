import { Injectable } from '@nestjs/common';
import { Prisma, TermsVersion } from '@prisma/client';
import { TermsValues } from './draft-terms';
import { TermsRepository } from './terms.repository';

@Injectable()
export class TermsService {
  constructor(private readonly repository: TermsRepository) {}

  // 협업의 가장 최근 판본. 없으면 null.
  latest(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<TermsVersion | null> {
    return this.repository.findLatest(collaborationId, tx);
  }

  // 여러 협업의 가장 최근 판본(목록이 협업마다 읽지 않게). 판본이 없는 협업은 맵에 없다.
  latestMany(collaborationIds: string[]): Promise<Map<string, TermsVersion>> {
    return this.repository.findLatestMany(collaborationIds);
  }

  // 다음 번호의 새 판본을 만든다(첫 판본이면 1). 같은 번호가 동시에 들어오면 유일 제약(협업, 번호)이 하나만 남기고
  // 나머지는 위반(P2002)으로 던진다: 호출하는 쪽이 같은 트랜잭션에서 최신 번호를 확인해 409로 바꾼다.
  async createVersion(
    collaborationId: string,
    proposedById: string | null,
    values: Omit<TermsValues, 'proposedById'>,
    tx?: Prisma.TransactionClient,
  ): Promise<TermsVersion> {
    const latest = await this.repository.findLatest(collaborationId, tx);
    return this.repository.create(
      collaborationId,
      (latest?.version ?? 0) + 1,
      { ...values, proposedById },
      tx,
    );
  }
}
