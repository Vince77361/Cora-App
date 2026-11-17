import type { CollaborationStage, DropReason } from '@prisma/client';
import type { EndKind, ProposalGroup } from '../offers/proposal-rules';

// 제안함(F3)의 브랜드 계약 줄 규칙. 모두 순수 함수다. 묶음 이름과 끝난 갈래는 가게 흐름의 제안함 줄과 같은 값을 쓴다
// (앱이 두 줄을 한 목록으로 합친다. 원장 판단 Q10).

// 제안함에 오를 수 있는 단계. INQUIRY(조건이 아직 없다)와 계약 이후(협업 목록의 몫)는 오르지 않는다.
// DROPPED는 끝난 묶음에 오른다.
export const INBOX_STAGES: CollaborationStage[] = [
  'MATCHED',
  'NEGOTIATING',
  'AGREED',
  'DROPPED',
];

// 사람이 고른 그만둔 이유. 요청 거절(REQUEST_DECLINED)과 차단(BLOCKED)은 그만둔 줄이 아니라서 제안함에 올리지 않는다.
export const CHOSEN_DROP_REASONS: DropReason[] = [
  'SCHEDULE',
  'BUDGET',
  'DIRECTION',
  'OTHER',
];

export type ChosenDropReason = 'SCHEDULE' | 'BUDGET' | 'DIRECTION' | 'OTHER';

// 이 협업이 제안함의 어느 묶음인가. 목록에 없으면 null이다.
// 서버가 만든 버전 1은 양쪽 모두 확인하지 않았으므로 양쪽 모두 내 차례다.
// 양쪽이 확인하면 같은 트랜잭션에서 AGREED가 되므로 MATCHED·NEGOTIATING에 양쪽 확인이 남는 일은 없다.
export function inboxGroup(input: {
  stage: CollaborationStage;
  myConfirmed: boolean;
  otherConfirmed: boolean;
}): ProposalGroup | null {
  switch (input.stage) {
    case 'MATCHED':
    case 'NEGOTIATING':
      return input.myConfirmed ? 'WAITING' : 'MY_TURN';
    case 'AGREED':
    case 'DROPPED':
      return 'ENDED';
    default:
      return null;
  }
}

// 끝난 줄의 갈래. 합의는 AGREED, 그만둠은 ENDED. 끝나지 않았으면 null.
export function inboxEndKind(stage: CollaborationStage): EndKind | null {
  if (stage === 'AGREED') return 'AGREED';
  if (stage === 'DROPPED') return 'ENDED';
  return null;
}

// 상대가 쓴 최신 판본이 번호 2 이상이면 역제안이다. 번호 1은 서버가 만든 초안이고 쓴 사람이 없다.
export function isCounterVersion(
  latest: { version: number; proposedById: string | null },
  userId: string,
): boolean {
  return (
    latest.version >= 2 &&
    latest.proposedById !== null &&
    latest.proposedById !== userId
  );
}

// 내가 그만뒀을 때만 내가 고른 이유를 돌려준다. 상대에게는 이유를 알리지 않으므로 항상 null이다.
export function myDropReasonOf(
  collaboration: { droppedById: string | null; dropReason: DropReason | null },
  userId: string,
): ChosenDropReason | null {
  const { droppedById, dropReason } = collaboration;
  if (droppedById !== userId || dropReason === null) return null;
  return CHOSEN_DROP_REASONS.includes(dropReason)
    ? (dropReason as ChosenDropReason)
    : null;
}
