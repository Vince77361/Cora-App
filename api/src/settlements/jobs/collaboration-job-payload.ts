import type { JobPayload } from '../../jobs/job-scheduler';

// 협업에 붙은 작업의 payload에서 협업 id를 꺼낸다. 없으면 던져서, 잘못 등록된 작업이 조용히 사라지지 않고 큐에 실패로 남게 한다.
export function collaborationIdOf(payload: JobPayload): string {
  if (
    'collaborationId' in payload &&
    typeof payload.collaborationId === 'string'
  ) {
    return payload.collaborationId;
  }
  throw new Error('작업에 collaborationId가 없어요.');
}

export function dayIndexOf(payload: JobPayload): number {
  if (
    'dayIndex' in payload &&
    typeof payload.dayIndex === 'number' &&
    Number.isInteger(payload.dayIndex) &&
    payload.dayIndex >= 0 &&
    payload.dayIndex <= 7
  ) {
    return payload.dayIndex;
  }
  throw new Error('작업에 dayIndex(0~7)가 없어요.');
}

export function daysLeftOf(payload: JobPayload): number {
  if (
    'daysLeft' in payload &&
    typeof payload.daysLeft === 'number' &&
    Number.isInteger(payload.daysLeft) &&
    payload.daysLeft > 0
  ) {
    return payload.daysLeft;
  }
  throw new Error('작업에 daysLeft가 없어요.');
}
