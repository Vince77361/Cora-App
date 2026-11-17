import { Injectable } from '@nestjs/common';
import { Prisma, TermsVersion } from '@prisma/client';
import { TermsValues } from './draft-terms';
import { TermsRepository } from './terms.repository';

@Injectable()
export class TermsService {
  constructor(private readonly repository: TermsRepository) {}

  // 조건 확인과 새 판본이 한 트랜잭션에서 도는 길(NegotiationService)이 쓰는 저장소 호출의 얇은 포장.
  // 저장소를 모듈 밖으로 내보내지 않고 서비스만 내보내려는 것이다.
  transaction<T>(
    run: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.repository.transaction(run);
  }

  // 같은 협업의 확인·새 판본 요청을 한 줄로 세운다(트랜잭션이 끝날 때까지 협업 행을 잡는다).
  lockCollaboration(
    collaborationId: string,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    return this.repository.lockCollaboration(collaborationId, tx);
  }

  // 내 쪽 확인 시각을 조건부로 채운다(이미 채워져 있으면 false).
  markConfirmed(
    collaborationId: string,
    version: number,
    side: 'BRAND' | 'CREATOR',
    at: Date,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    return this.repository.markConfirmed(
      collaborationId,
      version,
      side,
      at,
      tx,
    );
  }

  // 협업의 가장 최근 판본. 없으면 null.
  latest(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<TermsVersion | null> {
    return this.repository.findLatest(collaborationId, tx);
  }

  // 바로 앞 판본(changedFields와 이전 최대 현금 부담을 읽는 쪽이 쓴다). 판본 1이면 null.
  versionBefore(
    collaborationId: string,
    version: number,
    tx?: Prisma.TransactionClient,
  ): Promise<TermsVersion | null> {
    return version <= 1
      ? Promise.resolve(null)
      : this.repository.findVersion(collaborationId, version - 1, tx);
  }

  // 협업의 모든 판본, 최신이 먼저.
  list(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<TermsVersion[]> {
    return this.repository.listAll(collaborationId, tx);
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
