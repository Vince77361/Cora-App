import type { JobPayload } from '../../jobs/job-scheduler';

// 오퍼에 붙은 작업의 payload에서 오퍼 id를 꺼낸다. 없으면 던져서, 잘못 등록된 작업이 조용히 사라지지 않고 큐에 실패로 남게 한다.
export function offerIdOf(payload: JobPayload): string {
  if ('offerId' in payload && typeof payload.offerId === 'string') {
    return payload.offerId;
  }
  throw new Error('작업에 offerId가 없어요.');
}
