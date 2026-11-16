import type { ContentFormat, TermsVersion } from '@prisma/client';
import { CAMPAIGN_RULES } from '../campaigns/campaign-rules';
import { REWARD_POLICY } from '../common/collaboration-policy';
import type { BrandProposal, TermsValues } from './draft-terms';

// 값이 범위와 단위에 맞는지. 맞으면 null, 틀리면 사용자에게 보일 문장.
// 브랜드가 관심에 붙이는 제안(putDecision)과 협업 중에 내는 새 판본(proposeReward)이 같은 규칙을 쓴다.
// 성과 추가의 범위는 가게 흐름 개정 계획의 정책(GET /config와 같은 값)이다.
export function proposalProblem(
  proposal: BrandProposal,
  format: ContentFormat,
): string | null {
  const { fee, performance } = proposal;
  if (
    !Number.isInteger(fee) ||
    fee < CAMPAIGN_RULES.feeMin ||
    fee > REWARD_POLICY.fixedCash.maxByCommissioner.BRAND ||
    fee % CAMPAIGN_RULES.moneyStep !== 0
  ) {
    return '제작비는 1만 원 단위로, 1만 원부터 1,000만 원까지 정할 수 있어요.';
  }
  if (performance === null) return null;
  if (format === 'BLOG') return '블로그 글에는 조회수 수당을 붙일 수 없어요.';
  const { viewRate, perViewCap } = REWARD_POLICY;
  if (
    !Number.isInteger(performance.ratePer1000) ||
    performance.ratePer1000 < viewRate.min ||
    performance.ratePer1000 > viewRate.max ||
    performance.ratePer1000 % viewRate.step !== 0
  ) {
    return '조회수 단가는 1,000회당 1,000원부터 5,000원까지 500원 단위로 정할 수 있어요.';
  }
  if (
    !Number.isInteger(performance.cap) ||
    performance.cap < perViewCap.min ||
    performance.cap > perViewCap.max ||
    performance.cap % perViewCap.step !== 0
  ) {
    return '조회수 수당 상한은 1만 원부터 30만 원까지 1만 원 단위로 정할 수 있어요.';
  }
  return null;
}

// 새 판본이 돈과 혜택(제작비, 제품 제공, 성과 추가) 세 값 모두 최신 판본과 같은가.
export function sameReward(
  latest: Pick<
    TermsVersion,
    'fee' | 'productProvided' | 'perfRatePerThousand' | 'perfCap'
  >,
  proposal: BrandProposal,
): boolean {
  return (
    latest.fee === proposal.fee &&
    latest.productProvided === proposal.productProvided &&
    (latest.perfRatePerThousand ?? null) ===
      (proposal.performance?.ratePer1000 ?? null) &&
    (latest.perfCap ?? null) === (proposal.performance?.cap ?? null)
  );
}

// 협업 중에 내는 새 판본(공통 모델 7장): 돈과 혜택만 바뀌고 나머지 항목은 직전 판본에서 그대로 옮긴다.
// 낸 쪽은 "확인함"이고 상대 쪽 확인은 비어 있다(이전 판본에 했던 수락은 새 판본에 이어지지 않는다).
export function nextTermsValues(
  latest: TermsVersion,
  proposal: BrandProposal,
  side: 'BRAND' | 'CREATOR',
  now: Date,
): Omit<TermsValues, 'proposedById'> {
  return {
    title: latest.title,
    fee: proposal.fee,
    startDate: latest.startDate,
    format: latest.format,
    pieces: latest.pieces,
    productProvided: proposal.productProvided,
    revisionScope: latest.revisionScope,
    usageRights: latest.usageRights,
    payoutDays: latest.payoutDays,
    perfRatePerThousand: proposal.performance?.ratePer1000 ?? null,
    perfCap: proposal.performance?.cap ?? null,
    brandConfirmedAt: side === 'BRAND' ? now : null,
    creatorConfirmedAt: side === 'CREATOR' ? now : null,
  };
}
