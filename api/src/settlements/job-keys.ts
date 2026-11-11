// 정산 쪽 작업의 중복 방지 키. 등록과 취소가 같은 키를 쓰므로 한 곳에 모은다.
export const SNAPSHOT_DAYS = 7;

export const snapshotJobKey = (
  collaborationId: string,
  dayIndex: number,
): string => `view-snapshot:${collaborationId}:${dayIndex}`;

export const settleJobKey = (collaborationId: string): string =>
  `settle:${collaborationId}`;

export const payoutJobKey = (payoutId: string): string => `payout:${payoutId}`;

// 조회수를 읽지 못해 멈춘 협업의 사유. 운영 명령(10번 작업)이 이 값으로 조회수 정산 대상을 가린다.
export const VIEW_COUNT_HALT_REASON = 'VIEW_COUNT_UNAVAILABLE';

// 최근 이만큼 연속으로 읽지 못하면 멈춘다.
export const HALT_AFTER_UNREADABLE_DAYS = 3;
