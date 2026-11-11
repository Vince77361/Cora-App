import {
  submissionDeadlineJobKeys,
  submissionDeadlineJobs,
} from './collaboration-jobs';

describe('submissionDeadlineJobs', () => {
  // 2026-12-15 12:00 KST가 제출 기한이다.
  const due = new Date('2026-12-15T03:00:00.000Z');

  it('refunds at the due time and reminds at 10:00 KST three and one days before', () => {
    const jobs = submissionDeadlineJobs('c1', due);
    expect(jobs).toEqual([
      {
        name: 'refund-unsubmitted',
        payload: { collaborationId: 'c1' },
        runAt: due,
        jobKey: 'refund-unsubmitted:c1',
      },
      {
        name: 'submit-reminder',
        payload: { collaborationId: 'c1', daysLeft: 3 },
        // 12-12 10:00 KST
        runAt: new Date('2026-12-12T01:00:00.000Z'),
        jobKey: 'submit-reminder:c1:3',
      },
      {
        name: 'submit-reminder',
        payload: { collaborationId: 'c1', daysLeft: 1 },
        // 12-14 10:00 KST
        runAt: new Date('2026-12-14T01:00:00.000Z'),
        jobKey: 'submit-reminder:c1:1',
      },
    ]);
  });

  it('uses the korean date of the due time, not the utc date', () => {
    // 기한 2026-12-15 08:00 KST는 UTC로는 12-14 23:00이다. 3일 전은 한국 날짜로 12-12다.
    const early = submissionDeadlineJobs(
      'c1',
      new Date('2026-12-14T23:00:00.000Z'),
    );
    expect(early[1].runAt).toEqual(new Date('2026-12-12T01:00:00.000Z'));
  });

  it('lists the same keys no matter the due time', () => {
    expect(submissionDeadlineJobKeys('c1')).toEqual([
      'refund-unsubmitted:c1',
      'submit-reminder:c1:3',
      'submit-reminder:c1:1',
    ]);
  });
});
