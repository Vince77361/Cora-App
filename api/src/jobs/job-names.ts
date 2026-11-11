// 작업 큐에 올릴 수 있는 작업 이름. 처리기는 각 기능 모듈이 JobHandlerRegistry에 등록한다.
export const JOB_NAMES = [
  'view-snapshot',
  'settle',
  'refund-unsubmitted',
  'submit-reminder',
  'decline-notice',
  'payment-due-expiry',
  'payment-recheck',
  'cancel-request-expiry',
  'brand-halt-check',
  'payout-send',
] as const;

export type JobName = (typeof JOB_NAMES)[number];
