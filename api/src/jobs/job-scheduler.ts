import type { JobName } from './job-names';

// 작업은 협업에 붙거나(결제 이후의 작업), 오퍼에 붙거나(오퍼가 협업을 만들기 전·없이 도는 작업: 거절 알림, 결제 기한 만료),
// 결제에 붙는다(결제 대기 재확인).
// daysLeft는 제출 기한 알림 작업만 싣는다: 기한까지 남은 날(3 또는 1).
// dayIndex는 조회수 스냅샷 작업만 싣는다: 제출한 날부터 지난 날(0~7).
export type CollaborationJobPayload = {
  collaborationId: string;
  daysLeft?: number;
  dayIndex?: number;
};
// attempt는 결제 대기 재확인의 몇 번째 시도인지(1부터)다.
export type PaymentJobPayload = { paymentId: string; attempt: number };
// declinedAt(ISO 시각)은 거절 알림 작업만 싣는다: 어느 거절에 대한 작업인지 처리기가 알아야 옛 작업을 건너뛴다.
export type OfferJobPayload = { offerId: string; declinedAt?: string };
// 지급 송금 작업은 지급 행에 붙는다.
export type PayoutJobPayload = { payoutId: string };
// 사장님의 취소 요청 만료 작업은 요청 행에 붙는다.
export type CancelRequestJobPayload = { cancelRequestId: string };
export type JobPayload =
  | CollaborationJobPayload
  | OfferJobPayload
  | PaymentJobPayload
  | PayoutJobPayload
  | CancelRequestJobPayload;

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
