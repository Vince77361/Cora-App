import type {
  ContentFormat,
  PassReason,
  SwipeDecisionKind,
} from '@prisma/client';
import { CAMPAIGN_RULES } from '../campaigns/campaign-rules';
import { REWARD_POLICY } from '../common/collaboration-policy';
import type { BrandProposal } from '../terms/draft-terms';

// 관심에 붙이는 글의 길이. 크리에이터는 조건 버전의 제목이 되고(40자), 브랜드는 "좋아한 점"이다(100자).
export const NOTE_MAX = { CREATOR: 40, BRAND: 100 } as const;

// 값이 범위와 단위에 맞는지. 맞으면 null, 틀리면 사용자에게 보일 문장.
// 성과 추가의 범위는 가게 흐름 개정 계획의 정책(GET /config와 같은 값)을 쓴다.
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

// 저장돼 있는 결정 한 줄에서 규칙이 읽는 값.
export interface StoredDecision {
  id: string;
  decision: SwipeDecisionKind;
  passReason: PassReason | null;
  note: string | null;
  contentTitle: string | null;
  contentPhotoPath: string | null;
  proposedFee: number | null;
  proposedProductProvided: boolean | null;
  proposedPerfRate: number | null;
  proposedPerfCap: number | null;
}

// 결정 행에 쓸 칸. 쓰는 곳은 항상 updatedAt을 Clock의 시각으로 함께 적는다
// (@updatedAt은 벽시계라서, 보류가 "오늘 한 것"인지 보는 추천의 판정이 Clock과 어긋나지 않게).
export interface DecisionFields {
  decision: SwipeDecisionKind;
  passReason: PassReason | null;
  note: string | null;
  contentTitle: string | null;
  contentPhotoPath: string | null;
  proposedFee: number | null;
  proposedProductProvided: boolean | null;
  proposedPerfRate: number | null;
  proposedPerfCap: number | null;
}

export interface DecisionInput {
  decision: SwipeDecisionKind;
  // 정리된 글(빈 글은 null). undefined는 보내지 않은 것이다.
  note?: string | null;
  proposal?: BrandProposal;
  // 브랜드가 글을 붙여 관심을 보낼 때 그 크리에이터의 대표 콘텐츠(사본으로 저장한다).
  card?: { headline: string | null; photoPath: string | null } | null;
}

export type DecisionWrite =
  | { kind: 'none' }
  | { kind: 'create'; data: DecisionFields }
  | { kind: 'update'; data: Partial<DecisionFields> };

const EMPTY: Omit<DecisionFields, 'decision'> = {
  passReason: null,
  note: null,
  contentTitle: null,
  contentPhotoPath: null,
  proposedFee: null,
  proposedProductProvided: null,
  proposedPerfRate: null,
  proposedPerfCap: null,
};

// 글이 붙은 관심이 상대의 "받은 제안"이 되므로 글이 있을 때만 콘텐츠 사본을 남긴다.
function likeFields(input: DecisionInput): Partial<DecisionFields> {
  const fields: Partial<DecisionFields> = {};
  if (input.note !== undefined) {
    fields.note = input.note;
    const copied = input.note !== null && input.card;
    fields.contentTitle = copied ? input.card!.headline : null;
    fields.contentPhotoPath = copied ? input.card!.photoPath : null;
  }
  if (input.proposal) {
    fields.proposedFee = input.proposal.fee;
    fields.proposedProductProvided = input.proposal.productProvided;
    fields.proposedPerfRate = input.proposal.performance?.ratePer1000 ?? null;
    fields.proposedPerfCap = input.proposal.performance?.cap ?? null;
  }
  return fields;
}

// 결정 한 건을 어떻게 저장할지. 순수 함수다.
// - 결정이 바뀌면 그 결정에 속한 값(넘긴 이유, 글, 제안)은 모두 새로 시작한다.
// - 같은 결정을 다시 보내면: 넘김과 보류는 아무것도 쓰지 않는다(보류의 "오늘"이 밀리지 않게).
//   관심은 글이나 제안을 보냈을 때만 그 값을 덮어쓰고, 보내지 않은 값은 지우지 않는다.
export function planDecisionWrite(
  existing: StoredDecision | null,
  input: DecisionInput,
): DecisionWrite {
  const isLike = input.decision === 'LIKE';
  if (!existing || existing.decision !== input.decision) {
    const data: DecisionFields = {
      ...EMPTY,
      decision: input.decision,
      ...(isLike ? likeFields(input) : {}),
    };
    return existing ? { kind: 'update', data } : { kind: 'create', data };
  }
  if (!isLike) return { kind: 'none' };
  const data = likeFields(input);
  return Object.keys(data).length === 0
    ? { kind: 'none' }
    : { kind: 'update', data };
}
