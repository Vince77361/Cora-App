import { kstTimeOnDate } from '../common/kst';
import type { JobName } from '../jobs/job-names';
import type { JobScheduler } from '../jobs/job-scheduler';

const DAY_MS = 24 * 60 * 60 * 1000;
// 제출 기한 알림은 기한 3일 전과 하루 전 날의 한국 시간 10:00에 보낸다.
export const SUBMIT_REMINDER_DAYS_BEFORE = [3, 1] as const;
const REMINDER_HOUR_KST = 10;

export type SubmissionDeadlineJob =
  | {
      name: 'refund-unsubmitted';
      payload: { collaborationId: string };
      runAt: Date;
      jobKey: string;
    }
  | {
      name: 'submit-reminder';
      payload: { collaborationId: string; daysLeft: number };
      runAt: Date;
      jobKey: string;
    };

export const refundUnsubmittedJobKey = (collaborationId: string): string =>
  `refund-unsubmitted:${collaborationId}`;
export const submitReminderJobKey = (
  collaborationId: string,
  daysLeft: number,
): string => `submit-reminder:${collaborationId}:${daysLeft}`;

// 제출 기한에 걸어 두는 작업: 미제출 환급 한 건(기한 시각)과 기한 알림 두 건.
// 결제가 끝난 뒤(결제 모듈)와 식사권만 있는 오퍼를 수락한 뒤(오퍼 모듈)가 같은 키로 같은 작업을 올리므로 한 곳에 둔다.
// 시각은 인자로 받는 순수 함수다.
export function submissionDeadlineJobs(
  collaborationId: string,
  submitDueAt: Date,
): SubmissionDeadlineJob[] {
  const payload = { collaborationId };
  return [
    {
      name: 'refund-unsubmitted',
      payload,
      runAt: submitDueAt,
      jobKey: refundUnsubmittedJobKey(collaborationId),
    },
    ...SUBMIT_REMINDER_DAYS_BEFORE.map((daysLeft): SubmissionDeadlineJob => ({
      name: 'submit-reminder',
      payload: { ...payload, daysLeft },
      runAt: kstTimeOnDate(
        new Date(submitDueAt.getTime() - daysLeft * DAY_MS),
        REMINDER_HOUR_KST,
      ),
      jobKey: submitReminderJobKey(collaborationId, daysLeft),
    })),
  ];
}

// 제출하면 필요 없어지는 작업의 키. 기한과 상관없이 협업 id만으로 정해진다.
export function submissionDeadlineJobKeys(collaborationId: string): string[] {
  return submissionDeadlineJobs(collaborationId, new Date(0)).map(
    (job) => job.jobKey,
  );
}

// 위 작업을 큐에 올린다. 이미 올라가 있으면 한 번만 등록된다(같은 키).
// 기한 알림은 늦게 올려서 시각이 이미 지났다면 건너뛴다("3일 남았어요"를 뒤늦게 보내지 않는다).
export async function scheduleSubmissionDeadlineJobs(
  jobs: JobScheduler,
  collaborationId: string,
  submitDueAt: Date,
  now: Date,
): Promise<void> {
  for (const job of submissionDeadlineJobs(collaborationId, submitDueAt)) {
    if (
      job.name === 'submit-reminder' &&
      job.runAt.getTime() <= now.getTime()
    ) {
      continue;
    }
    await jobs.schedule(
      job.name satisfies JobName,
      job.payload,
      job.runAt,
      job.jobKey,
    );
  }
}
