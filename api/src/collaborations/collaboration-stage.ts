import {
  CollaborationKind,
  CollaborationStage,
  SettlementMethod,
} from '@prisma/client';
import {
  maxCashBurden,
  RewardTerms,
  settlementMethodOfReward,
} from '../stores/reward-terms';

// 협업 단계 규칙은 모두 순수 함수다. 시각은 인자로 받는다(Clock은 서비스가 쥔다).
// 규칙의 원본은 공통 모델 1장의 두 그림이다.
type Stage = CollaborationStage;

const DAY_MS = 24 * 60 * 60 * 1000;
// 결제 대기 기한(오퍼 수락 뒤)과 링크 제출 기한(결제 뒤).
export const PAYMENT_DUE_DAYS = 3;
export const SUBMIT_DUE_DAYS = 14;

// "끝난 협업" 범위. 이 밖의 단계는 모두 진행 중이다(브랜드 계약의 협의 단계도 진행 중이다).
// 저장소가 끝 단계로 옮길 때 연결된 오퍼를 닫는 기준이기도 하다.
export const COLLABORATION_DONE_STAGES: CollaborationStage[] = [
  'SETTLED',
  'REFUNDED',
  'CANCELLED',
  'DROPPED',
];

// 사장님 홈의 "진행 중"에 세는 단계.
export const storeInProgressStages: CollaborationStage[] = [
  'AWAITING_PAYMENT',
  'FUNDED',
  'COUNTING',
];

// 일반 전이. HALTED로 들어가고 나오는 길은 아래에서 따로 다룬다.
const STORE_NEXT: Partial<Record<Stage, Stage[]>> = {
  AWAITING_PAYMENT: ['FUNDED', 'CANCELLED'],
  // FUNDED → SETTLED는 낼 돈이 없는 식사권만 오퍼(settlementMethod NONE)가 쓰는 길이다.
  // 돈이 있는 오퍼는 고정 현금만 있어도 FUNDED → COUNTING을 거쳐 측정 기간이 끝나는 날 정산한다.
  FUNDED: ['COUNTING', 'SETTLED', 'REFUNDED', 'CANCELLED'],
  COUNTING: ['SETTLED'],
};

const BRAND_NEXT: Partial<Record<Stage, Stage[]>> = {
  INQUIRY: ['MATCHED', 'DROPPED'],
  MATCHED: ['NEGOTIATING', 'DROPPED'],
  NEGOTIATING: ['AGREED', 'DROPPED'],
  // 결제 전에 새 판본이 나오면 합의가 취소되고 협의로 돌아간다(공통 모델 2장).
  AGREED: ['CONTRACTED', 'NEGOTIATING', 'DROPPED'],
  CONTRACTED: ['GUIDED'],
  GUIDED: ['REVIEWING'],
  REVIEWING: ['APPROVED'],
  APPROVED: ['PUBLISHED'],
  PUBLISHED: ['SETTLED'],
};

// 계약 전 브랜드 협업의 단계(순서대로). 이 안에서는 그만둘 수 있고(DROPPED), 계약하면 벗어난다.
export const preContractStages: CollaborationStage[] = [
  'INQUIRY',
  'MATCHED',
  'NEGOTIATING',
  'AGREED',
];

// 조건을 확인하거나 새 판본을 낼 수 있는 단계. INQUIRY는 아직 서로 관심이 아니라 협의할 조건이 없다.
export const negotiableStages: CollaborationStage[] = [
  'MATCHED',
  'NEGOTIATING',
  'AGREED',
];

// 브랜드가 결제창을 연 채 두는 동안 조건 변경과 그만두기를 막는 시간(분). PENDING 결제의 요청 시각부터 센다.
// 이 시간이 지나면 열려 있던 결제는 없는 것으로 본다(결제창을 닫고 가 버린 경우를 풀어 준다).
export const BRAND_PAYMENT_LOCK_MINUTES = 60;

// 브랜드 계약이 체결된 뒤 이 날수 안에 게시 링크가 없으면 협업을 멈추고 운영자에게 알리는 점검(brand-halt-check)을 건다.
export const BRAND_HALT_CHECK_DAYS = 60;

// 캠페인 예산의 확보액에 세지 않는 브랜드 협업 단계: 아직 서로 관심이 아니거나(INQUIRY), 계약 전에 그만뒀거나(DROPPED),
// 보관 중이던 돈이 환급된(REFUNDED) 협업이다. 멈춘(HALTED) 협업은 돈이 그대로 보관 중이라 센다.
export const UNSECURED_BRAND_STAGES: CollaborationStage[] = [
  'INQUIRY',
  'DROPPED',
  'REFUNDED',
];

export interface BrandProgress {
  // 끝난 단계의 수(0~6).
  doneCount: number;
  // 지금 하는 단계(1~6). 모두 끝났으면 null.
  current: 1 | 2 | 3 | 4 | 5 | 6 | null;
  // 현재 단계 줄의 보조 글 종류. 없으면 null.
  currentNote: 'WAITING_OTHER_CONFIRM' | 'WAITING_CONTRACT' | null;
}

// 07 화면의 여섯 단계(공통 모델 1장의 표). 표에 없는 단계(INQUIRY, DROPPED, HALTED)는 null이다:
// 멈춘 협업은 부르는 쪽이 멈추기 전 단계로 읽는다.
const BRAND_PROGRESS: Partial<Record<Stage, BrandProgress>> = {
  MATCHED: { doneCount: 1, current: 2, currentNote: null },
  NEGOTIATING: {
    doneCount: 2,
    current: 3,
    currentNote: 'WAITING_OTHER_CONFIRM',
  },
  AGREED: { doneCount: 2, current: 3, currentNote: 'WAITING_CONTRACT' },
  CONTRACTED: { doneCount: 3, current: 4, currentNote: null },
  GUIDED: { doneCount: 3, current: 4, currentNote: null },
  REVIEWING: { doneCount: 4, current: 5, currentNote: null },
  APPROVED: { doneCount: 5, current: 6, currentNote: null },
  PUBLISHED: { doneCount: 5, current: 6, currentNote: null },
  SETTLED: { doneCount: 6, current: null, currentNote: null },
};

export function brandProgress(stage: CollaborationStage): BrandProgress | null {
  const progress = BRAND_PROGRESS[stage];
  return progress ? { ...progress } : null;
}

export type NextAction = 'RESPOND_TERMS' | 'SIGN_CONTRACT';

// 지금 내가 할 일. 조건을 아직 확인하지 않았으면 답하고(MATCHED·NEGOTIATING), 양쪽이 합의했으면(AGREED) 계약한다.
// CONTRACTED 뒤의 할 일은 이후 계획이 더한다.
export function nextActionFor(
  stage: CollaborationStage,
  myTurn: boolean,
): NextAction | null {
  if ((stage === 'MATCHED' || stage === 'NEGOTIATING') && myTurn) {
    return 'RESPOND_TERMS';
  }
  if (stage === 'AGREED') return 'SIGN_CONTRACT';
  return null;
}

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

export interface InitialStoreOfferState {
  settlementMethod: SettlementMethod;
  stage: CollaborationStage;
  // 오퍼에 저장할 결제 기한. 낼 돈이 없으면 null이다(있으면 읽을 때 만료 규칙이 오퍼를 EXPIRED로 바꾼다).
  paymentDueAt: Date | null;
  fundedAt: Date | null;
  submitDueAt: Date | null;
}

// 오퍼를 수락한 순간의 협업 상태. 최대 현금 부담이 0이면(식사권만 있으면) 결제 없이 바로 FUNDED로 시작한다.
export function initialStoreOfferState(
  reward: Pick<RewardTerms, 'fixedCash' | 'perViewCap'>,
  now: Date,
): InitialStoreOfferState {
  if (maxCashBurden(reward) > 0) {
    return {
      settlementMethod: settlementMethodOfReward(reward),
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
