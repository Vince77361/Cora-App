import {
  CollaborationKind,
  CollaborationStage,
  SettlementMethod,
  TransferStatus,
} from '@prisma/client';
import { settle } from '../settlements/settlement-math';

// 협업 조회 모델을 만드는 순수 함수들. 시각과 DB를 모른다(시각은 호출한 쪽이 인자로 준다).

// "끝난 협업" 범위. 이 밖의 단계는 모두 진행 중이다(브랜드 계약의 협의 단계도 진행 중이다).
export const COLLABORATION_DONE_STAGES: CollaborationStage[] = [
  'SETTLED',
  'REFUNDED',
  'CANCELLED',
  'DROPPED',
];

export type StepKey = 'ACCEPTED' | 'PAID' | 'VISIT' | 'SUBMIT' | 'SETTLE';
export type StepState = 'DONE' | 'NOW' | 'TODO';
export interface Step {
  key: StepKey;
  state: StepState;
  at: Date | null;
}

export interface StepInput {
  kind: CollaborationKind;
  stage: CollaborationStage;
  stageBeforeHalt: CollaborationStage | null;
  settlementMethod: SettlementMethod;
  // 협업은 오퍼를 수락할 때 만들어진다.
  acceptedAt: Date;
  fundedAt: Date | null;
  submittedAt: Date | null;
  // 정산 행의 시각. 식사권만 있는 오퍼는 정산 행이 없다.
  settledAt: Date | null;
}

const ENDED_WITHOUT_FINISH: CollaborationStage[] = [
  'CANCELLED',
  'REFUNDED',
  'DROPPED',
];
// 방문하고 촬영하는 단계. 가게 오퍼는 FUNDED, 브랜드 계약은 계약 뒤 제출 전까지다.
const WORKING_STAGES: CollaborationStage[] = [
  'FUNDED',
  'CONTRACTED',
  'GUIDED',
  'REVIEWING',
  'APPROVED',
];

// 진행 막대의 다섯 단계. 항상 다섯 개다.
// - 멈춘(HALTED) 협업은 멈추기 직전 단계에서 멈춘 모양으로 보인다.
// - 취소·환급·떨어진 협업은 해낸 단계만 DONE이고, 지금 하는 단계(NOW)는 없다.
export function buildSteps(input: StepInput): Step[] {
  const stage =
    input.stage === 'HALTED'
      ? (input.stageBeforeHalt ?? 'COUNTING')
      : input.stage;
  const ended = ENDED_WITHOUT_FINISH.includes(stage);
  const settled = stage === 'SETTLED';
  const submitted = input.submittedAt !== null || settled;
  // 식사권만 있는 오퍼는 낼 돈이 없어 결제가 처음부터 끝나 있다.
  const paid = input.settlementMethod === 'NONE' || input.fundedAt !== null;

  const paidState: StepState = paid
    ? 'DONE'
    : !ended && stage === 'AWAITING_PAYMENT'
      ? 'NOW'
      : 'TODO';
  const visitState: StepState = submitted
    ? 'DONE'
    : !ended && WORKING_STAGES.includes(stage)
      ? 'NOW'
      : 'TODO';
  const settleState: StepState = settled
    ? 'DONE'
    : !ended && submitted
      ? 'NOW'
      : 'TODO';

  return [
    { key: 'ACCEPTED', state: 'DONE', at: input.acceptedAt },
    { key: 'PAID', state: paidState, at: input.fundedAt },
    { key: 'VISIT', state: visitState, at: null },
    {
      key: 'SUBMIT',
      state: submitted ? 'DONE' : 'TODO',
      at: input.submittedAt,
    },
    {
      key: 'SETTLE',
      state: settleState,
      at: settled ? (input.settledAt ?? input.submittedAt) : null,
    },
  ];
}

export type PayoutStatus =
  'NONE' | 'NEEDS_ACCOUNT' | 'PENDING' | 'DONE' | 'FAILED';

// 지급 행이 없으면(정산 전이거나 지급할 돈이 0원) NONE이다.
// 대기 중인데 계좌가 없으면 NEEDS_ACCOUNT, 계좌가 있으면 PENDING과 지급일이다.
export function payoutStatusOf(
  payout: { status: TransferStatus; scheduledFor: Date } | null,
  hasAccount: boolean,
): { status: PayoutStatus; scheduledFor: Date | null } {
  if (!payout) return { status: 'NONE', scheduledFor: null };
  if (payout.status === 'DONE') return { status: 'DONE', scheduledFor: null };
  if (payout.status === 'FAILED') {
    return { status: 'FAILED', scheduledFor: null };
  }
  return hasAccount
    ? { status: 'PENDING', scheduledFor: payout.scheduledFor }
    : { status: 'NEEDS_ACCOUNT', scheduledFor: null };
}

// 집계 중에 "지금 받을 금액"과 "예상 환급액". 정산과 같은 계산(settle)에 최신 조회수를 넣는다.
// 집계 중(COUNTING)이 아니거나 아직 읽은 조회수가 없으면 null이다.
export function liveAmounts(p: {
  stage: CollaborationStage;
  views: number | null;
  perViewAmount: number | null;
  escrow: number;
}): { earned: number; refund: number } | null {
  if (p.stage !== 'COUNTING') return null;
  if (p.views === null || p.perViewAmount === null) return null;
  const { payout, refund } = settle({
    views: p.views,
    perViewAmount: p.perViewAmount,
    cap: p.escrow,
  });
  return { earned: payout, refund };
}
