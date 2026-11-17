import type {
  BrandUsageRights,
  ContentFormat,
  RevisionScope,
  TermsVersion,
} from '@prisma/client';
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
  if (format === 'BLOG') return '블로그 글은 조회수를 셀 수 없어요.';
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

// 협업 중에 내는 새 판본이 바꿀 수 있는 항목(공통 모델 7장의 열 항목 가운데 광고 표시를 뺀 아홉). 빠진 항목은 직전 판본 그대로다.
// 성과 추가는 빠짐 = 그대로, null = 끔이다. 돈과 혜택만 바꾸는 길(F2)과 모든 항목을 바꾸는 수정 제안 화면이 같은 입력을 쓴다.
export interface TermsEdit {
  title?: string;
  fee?: number;
  performance?: { ratePer1000: number; cap: number } | null;
  // 'YYYY-MM-DD'.
  startDate?: string;
  format?: ContentFormat;
  pieces?: number;
  productProvided?: boolean;
  revisionScope?: RevisionScope;
  usageRights?: BrandUsageRights;
  payoutDays?: number;
}

// 새 판본의 값 전체: 직전 판본 위에 입력을 덮는다.
// 낸 쪽은 "확인함"이고 상대 쪽 확인은 비어 있다(이전 판본에 했던 수락은 새 판본에 이어지지 않는다).
export function nextTermsValues(
  latest: TermsVersion,
  edit: TermsEdit,
  side: 'BRAND' | 'CREATOR',
  now: Date,
): Omit<TermsValues, 'proposedById'> {
  const performance =
    edit.performance === undefined
      ? latest.perfRatePerThousand !== null && latest.perfCap !== null
        ? { ratePer1000: latest.perfRatePerThousand, cap: latest.perfCap }
        : null
      : edit.performance;
  return {
    title: edit.title ?? latest.title,
    fee: edit.fee ?? latest.fee,
    startDate:
      edit.startDate !== undefined
        ? new Date(`${edit.startDate}T00:00:00.000Z`)
        : latest.startDate,
    format: edit.format ?? latest.format,
    pieces: edit.pieces ?? latest.pieces,
    productProvided: edit.productProvided ?? latest.productProvided,
    revisionScope: edit.revisionScope ?? latest.revisionScope,
    usageRights: edit.usageRights ?? latest.usageRights,
    payoutDays: edit.payoutDays ?? latest.payoutDays,
    perfRatePerThousand: performance?.ratePer1000 ?? null,
    perfCap: performance?.cap ?? null,
    brandConfirmedAt: side === 'BRAND' ? now : null,
    creatorConfirmedAt: side === 'CREATOR' ? now : null,
    createdAt: now,
  };
}

// 새 판본의 값이 범위와 단위에 맞는지. 맞으면 null, 틀리면 사용자에게 보일 문장.
// 합친 결과로 검사한다: 형식만 블로그로 바꿔도 이미 켜져 있던 성과 추가가 걸린다.
// 시작일은 이번에 바꾸는 경우에만 본다(지난 시작일이 그대로인 판본에서 제작비만 바꾸는 협의를 막지 않는다).
export function termsProblem(
  next: Pick<
    TermsValues,
    | 'title'
    | 'fee'
    | 'format'
    | 'pieces'
    | 'payoutDays'
    | 'perfRatePerThousand'
    | 'perfCap'
    | 'productProvided'
  >,
  startDateChange: string | undefined,
  today: string,
): string | null {
  const title = next.title.trim();
  if (title.length < 1 || title.length > CAMPAIGN_RULES.headlineMax) {
    return `콘텐츠 제목은 1자부터 ${CAMPAIGN_RULES.headlineMax}자까지 쓸 수 있어요.`;
  }
  if (!Number.isInteger(next.pieces) || next.pieces < 1 || next.pieces > 3) {
    return '편 수는 1편부터 3편까지 정할 수 있어요.';
  }
  if (next.payoutDays !== 7 && next.payoutDays !== 14) {
    return '지급 조건은 7일 또는 14일이에요.';
  }
  if (startDateChange !== undefined && startDateChange < today) {
    return '시작일은 오늘 이후여야 해요.';
  }
  return proposalProblem(
    {
      fee: next.fee,
      productProvided: next.productProvided,
      performance:
        next.perfRatePerThousand !== null && next.perfCap !== null
          ? { ratePer1000: next.perfRatePerThousand, cap: next.perfCap }
          : null,
    },
    next.format,
  );
}
