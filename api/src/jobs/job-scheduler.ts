import type { JobName } from './job-names';

// 작업은 협업에 붙거나(결제 이후의 작업) 오퍼에 붙는다(오퍼가 협업을 만들기 전·없이 도는 작업: 거절 알림, 결제 기한 만료).
export type CollaborationJobPayload = { collaborationId: string };
export type OfferJobPayload = { offerId: string };
export type JobPayload = CollaborationJobPayload | OfferJobPayload;

// 작업 처리기. 다시 실행돼도 같은 결과를 내야 하고, 시각은 Clock에서 읽는다.
export type JobHandler = (payload: JobPayload) => Promise<void>;

// 지연 작업 등록 포트. 실제 구현은 BullMQ, 테스트는 FakeJobScheduler.
export abstract class JobScheduler {
  // jobKey가 같으면 한 번만 등록된다(이미 등록돼 있으면 아무 일도 하지 않는다).
  abstract schedule(
    name: JobName,
    payload: JobPayload,
    runAt: Date,
    jobKey: string,
  ): Promise<void>;

  // 아직 실행되지 않은 작업을 지운다. 지운 뒤에는 같은 jobKey로 다시 등록할 수 있다.
  abstract cancel(jobKey: string): Promise<void>;
}
