// 정산 쪽 작업의 중복 방지 키. 등록과 취소가 같은 키를 쓰므로 한 곳에 모은다.
export const SNAPSHOT_DAYS = 7;

export const snapshotJobKey = (
  collaborationId: string,
  dayIndex: number,
): string => `view-snapshot:${collaborationId}:${dayIndex}`;

export const settleJobKey = (collaborationId: string): string =>
  `settle:${collaborationId}`;

// 조회 자료 확인 기한이 되면 자동으로 확인하는 작업. 정산 장부의 키('settle:' + 협업 id)와는 다른 키다(작업 큐의 키).
export const autoConfirmJobKey = (collaborationId: string): string =>
  `auto-confirm:${collaborationId}`;

// 계산이 만들어졌다는 알림의 중복 방지 키(사장님·크리에이터 각자 한 건).
export const viewReportDedupeKey = (collaborationId: string): string =>
  `view-report:${collaborationId}`;

export const payoutJobKey = (payoutId: string): string => `payout:${payoutId}`;

// 조회수를 읽지 못해 멈춘 협업의 사유. 운영 명령(10번 작업)이 이 값으로 조회수 정산 대상을 가린다.
export const VIEW_COUNT_HALT_REASON = 'VIEW_COUNT_UNAVAILABLE';

// 최근 이만큼 연속으로 읽지 못하면 멈춘다.
export const HALT_AFTER_UNREADABLE_DAYS = 3;

// 돈 행(지급·환급)의 중복 방지 키. 같은 정산을 다시 처리해도 행이 하나뿐이도록 협업 id로 정한다.
export const settlePayoutKey = (collaborationId: string): string =>
  `settle-payout:${collaborationId}`;
export const settleRefundKey = (collaborationId: string): string =>
  `settle-refund:${collaborationId}`;
export const unsubmittedRefundKey = (collaborationId: string): string =>
  `unsubmitted-refund:${collaborationId}`;

// 운영 명령(ops)의 중복 방지 키. 장부 줄과 돈 행(지급·환급)이 같은 문자열을 쓴다(서로 다른 표의 유일 제약이다).
// 같은 명령을 다시 실행해도 장부와 돈 행이 하나뿐이다.
export const forceRefundKey = (collaborationId: string): string =>
  `force-refund:${collaborationId}`;
export const forcePayoutKey = (collaborationId: string): string =>
  `force-payout:${collaborationId}`;
// 강제 지급에서 지급하고 남은 보관액의 환급 행.
export const forcePayoutRefundKey = (collaborationId: string): string =>
  `force-payout-refund:${collaborationId}`;
// 협업에 반영되지 못한 결제(늦은 승인, 이중 결제)의 환급. 환급 행의 키에서 어느 결제를 돌려보낼지 알 수 있다.
export const LATE_REFUND_KEY_PREFIX = 'late-refund:';
export const lateRefundKey = (paymentId: string): string =>
  `${LATE_REFUND_KEY_PREFIX}${paymentId}`;
// 협업에 반영되지 못한 결제의 장부 줄(결제 승인 묶음). 협업을 보관 중으로 만든 결제와 같은 키 모양이다.
export const paymentLedgerKey = (paymentId: string): string =>
  `payment:${paymentId}`;
