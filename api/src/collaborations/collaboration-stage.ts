import {
  CollaborationKind,
  CollaborationStage,
  RewardType,
  SettlementMethod,
} from '@prisma/client';

// 협업 단계 규칙은 모두 순수 함수다. 시각은 인자로 받는다(Clock은 서비스가 쥔다).
// 규칙의 원본은 공통 모델 1장의 두 그림이다.
type Stage = CollaborationStage;

const DAY_MS = 24 * 60 * 60 * 1000;
// 결제 대기 기한(오퍼 수락 뒤)과 링크 제출 기한(결제 뒤).
export const PAYMENT_DUE_DAYS = 3;
export const SUBMIT_DUE_DAYS = 14;

// 사장님 홈의 "진행 중"에 세는 단계.
export const storeInProgressStages: CollaborationStage[] = [
  'AWAITING_PAYMENT',
  'FUNDED',
  'COUNTING',
];

// 일반 전이. HALTED로 들어가고 나오는 길은 아래에서 따로 다룬다.
const STORE_NEXT: Partial<Record<Stage, Stage[]>> = {
  AWAITING_PAYMENT: ['FUNDED', 'CANCELLED'],
  // 식사권만 있는 오퍼는 링크 제출로 FUNDED에서 바로 SETTLED가 된다.
  FUNDED: ['COUNTING', 'SETTLED', 'REFUNDED', 'CANCELLED'],
  COUNTING: ['SETTLED'],
};

const BRAND_NEXT: Partial<Record<Stage, Stage[]>> = {
  INQUIRY: ['MATCHED', 'DROPPED'],
  MATCHED: ['NEGOTIATING', 'DROPPED'],
  NEGOTIATING: ['AGREED', 'DROPPED'],
  AGREED: ['CONTRACTED', 'DROPPED'],
  CONTRACTED: ['GUIDED'],
  GUIDED: ['REVIEWING'],
  REVIEWING: ['APPROVED'],
  APPROVED: ['PUBLISHED'],
  PUBLISHED: ['SETTLED'],
};

// 돈이 보관 중이라 운영자·집계 실패·신고로 멈출 수 있는 단계.
const HALTABLE: Record<CollaborationKind, Stage[]> = {
  STORE_OFFER: ['FUNDED', 'COUNTING'],
  BRAND_CONTRACT: [
    'CONTRACTED',
    'GUIDED',
    'REVIEWING',
    'APPROVED',
    'PUBLISHED',
  ],
};

const NEXT: Record<CollaborationKind, Partial<Record<Stage, Stage[]>>> = {
  STORE_OFFER: STORE_NEXT,
  BRAND_CONTRACT: BRAND_NEXT,
};

// stageBeforeHalt를 알면 HALTED에서는 그 단계로만 돌아간다(주지 않으면 멈출 수 있는 어느 단계든).
// 호출하는 쪽이 협업의 stageBeforeHalt를 함께 넘기는 것이 안전하다.
export function canTransition(
  kind: CollaborationKind,
  from: CollaborationStage,
  to: CollaborationStage,
  stageBeforeHalt?: CollaborationStage | null,
): boolean {
  if (from === 'HALTED') {
    if (to === 'SETTLED' || to === 'REFUNDED') return true;
    if (stageBeforeHalt) return to === stageBeforeHalt;
    return HALTABLE[kind].includes(to);
  }
  if (to === 'HALTED') return HALTABLE[kind].includes(from);
  return NEXT[kind][from]?.includes(to) ?? false;
}

// 보관 중인 돈이 있는가. 멈춘 협업도 돈은 그대로 보관 중이다(탈퇴를 막고, 지갑의 "Cora가 보관 중"에 들어간다).
export function isMoneyHeld(
  kind: CollaborationKind,
  stage: CollaborationStage,
): boolean {
  return stage === 'HALTED' || HALTABLE[kind].includes(stage);
}

// 보상에 조회수가 있으면 조회수당 지급이고, 식사권만 있으면 결제와 정산이 없다.
export function settlementMethodOf(rewardType: RewardType): SettlementMethod {
  return rewardType === 'VOUCHER' ? 'NONE' : 'PER_VIEW';
}

export interface InitialStoreOfferState {
  settlementMethod: SettlementMethod;
  stage: CollaborationStage;
  // 오퍼에 저장할 결제 기한. 낼 돈이 없으면 null이다(있으면 읽을 때 만료 규칙이 오퍼를 EXPIRED로 바꾼다).
  paymentDueAt: Date | null;
  fundedAt: Date | null;
  submitDueAt: Date | null;
}

// 오퍼를 수락한 순간의 협업 상태.
export function initialStoreOfferState(
  rewardType: RewardType,
  now: Date,
): InitialStoreOfferState {
  if (settlementMethodOf(rewardType) === 'PER_VIEW') {
    return {
      settlementMethod: 'PER_VIEW',
      stage: 'AWAITING_PAYMENT',
      paymentDueAt: new Date(now.getTime() + PAYMENT_DUE_DAYS * DAY_MS),
      fundedAt: null,
      submitDueAt: null,
    };
  }
  return {
    settlementMethod: 'NONE',
    stage: 'FUNDED',
    paymentDueAt: null,
    fundedAt: now,
    submitDueAt: new Date(now.getTime() + SUBMIT_DUE_DAYS * DAY_MS),
  };
}
