import { Collaboration, Prisma } from '@prisma/client';
import { readSnapshot } from '../contracts/contract-snapshot';
import { readTerms, RewardTerms } from '../stores/reward-terms';
import { SettlementsRepository } from './settlements.repository';

// 정산이 읽는 보상. 고정 현금, 1,000회당 단가, 상한 셋뿐이다(최대 현금 부담과 수수료는 reward-terms의 순수 함수가 만든다).
export type SettlementReward = Pick<
  RewardTerms,
  'fixedCash' | 'viewRatePerThousand' | 'perViewCap'
>;

// 협업의 보상을 읽는 단 한 곳. 정산·조회 자료 확인·운영 명령이 모두 여기서 읽는다.
// - 가게 오퍼: 수락할 때 협업에 남긴 조건 사본(readTerms).
// - 브랜드 계약: 체결된 계약의 조건 사본(contracts.termsSnapshot). 브랜드 협업의 terms 칸은 비어 있다.
// 읽을 수 없는 사본은 던진다: 잘못 읽은 금액으로 돈을 움직이는 것보다 멈추는 편이 낫다.
export async function rewardOf(
  collaboration: Pick<Collaboration, 'id' | 'kind' | 'terms'>,
  repository: Pick<SettlementsRepository, 'findConcludedContractSnapshot'>,
  tx?: Prisma.TransactionClient,
): Promise<SettlementReward> {
  if (collaboration.kind !== 'BRAND_CONTRACT') {
    const terms = readTerms(collaboration.terms);
    return {
      fixedCash: terms.fixedCash,
      viewRatePerThousand: terms.viewRatePerThousand,
      perViewCap: terms.perViewCap,
    };
  }
  const snapshot = readSnapshot(
    await repository.findConcludedContractSnapshot(collaboration.id, tx),
  );
  return {
    fixedCash: snapshot.fee,
    viewRatePerThousand: snapshot.performance?.ratePer1000 ?? null,
    perViewCap: snapshot.performance?.cap ?? null,
  };
}
