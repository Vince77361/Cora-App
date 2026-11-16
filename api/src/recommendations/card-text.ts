import type { IndustryCategory, NotRequired } from '@prisma/client';
import { INDUSTRY_LABELS } from '../common/industry';

// 카드에 들어가는 짧은 글을 만드는 순수 함수들. 화면 문구는 2026-11-12 캔버스 그대로다.

const HEADLINE_MAX = 40;
const NOT_REQUIRED_LABELS: Record<NotRequired, string> = {
  FACE: '얼굴출연없음',
  FIXED_LINES: '정해진대사없음',
  SCRIPT_READING: '대본낭독없음',
};

// 크리에이터 카드의 꼬리표. 얼굴 → 대본 → 솔직후기 → 분야의 첫 이름 순서다.
// 계정·설정 계획(E6 프로필 수정)이 순서와 분야 표시를 캔버스대로 바꾸고 자유 꼬리표를 앞에 붙인다.
export function principleTags(p: {
  faceOk: boolean;
  scriptOk: boolean;
  honestReview: boolean;
  fields: IndustryCategory[];
}): string[] {
  const tags: string[] = [];
  if (!p.faceOk) tags.push('얼굴출연없음');
  if (!p.scriptOk) tags.push('대본낭독없음');
  if (p.honestReview) tags.push('솔직후기');
  const field = p.fields[0];
  if (field !== undefined) tags.push(INDUSTRY_LABELS[field]);
  return tags;
}

// 캠페인 카드의 꼬리표: 요구하지 않는 것의 이름을 최대 2개.
export function campaignTags(notRequired: NotRequired[]): string[] {
  return notRequired.slice(0, 2).map((item) => NOT_REQUIRED_LABELS[item]);
}

// 가게 소개의 첫 문장을 40자까지. 소개가 없으면 모집 한 줄, 그것도 없으면 업종 이름을 쓴다.
export function storeHeadline(store: {
  intro: string | null;
  recruitLine: string | null;
  industry: IndustryCategory;
}): string {
  const intro = store.intro?.trim() ?? '';
  const sentence = /^[^.!?。\n]*[.!?。]?/.exec(intro)?.[0].trim() ?? '';
  const text = sentence || store.recruitLine?.trim() || '';
  if (!text) return INDUSTRY_LABELS[store.industry];
  return Array.from(text).slice(0, HEADLINE_MAX).join('');
}

// 가게 카드의 보상 줄. 가게 모집 조건의 보상 세 요소를 " + "로 잇는다:
// 제공 혜택이 있으면 혜택의 이름(금액과 인원은 뺀다), 고정 현금이 있으면 "현금 {금액}", 조회수 수당이 켜져 있으면 "조회수 수당".
export function storeRewardLine(reward: {
  voucherName: string | null;
  fixedCash: number;
  perViewCap: number | null;
}): string {
  const parts: string[] = [];
  if (reward.voucherName) parts.push(reward.voucherName);
  if (reward.fixedCash > 0) {
    parts.push(`현금 ${reward.fixedCash.toLocaleString('en-US')}원`);
  }
  if (reward.perViewCap !== null) parts.push('조회수 수당');
  return parts.join(' + ');
}
