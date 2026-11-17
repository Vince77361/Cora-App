import { submissionDeadlineJobKeys } from '../collaborations/collaboration-jobs';
import {
  autoConfirmJobKey,
  brandHaltJobKey,
  evidenceHaltJobKey,
  haltJobKeys,
  settleFixedJobKey,
  settleJobKey,
  MAX_SNAPSHOT_DAYS,
  snapshotJobKey,
} from './job-keys';

describe('haltJobKeys', () => {
  it('lists every job registered for a collaboration so a halt can cancel them all', () => {
    const keys = haltJobKeys('c1');
    expect(keys).toEqual(
      expect.arrayContaining([
        settleJobKey('c1'),
        settleFixedJobKey('c1'),
        autoConfirmJobKey('c1'),
        evidenceHaltJobKey('c1'),
        brandHaltJobKey('c1'),
        ...submissionDeadlineJobKeys('c1'),
      ]),
    );
    // 브랜드 계약은 14일까지 잰다: 멈출 때 7일 뒤의 조회수 작업도 지워야 한다.
    for (let day = 0; day <= MAX_SNAPSHOT_DAYS; day += 1) {
      expect(keys).toContain(snapshotJobKey('c1', day));
    }
    expect(new Set(keys).size).toBe(keys.length);
  });

  it('names the fixed payout job after the collaboration so a halt can cancel it by id', () => {
    expect(settleFixedJobKey('c1')).toBe('settle-fixed:c1');
  });

  it('names the brand halt check after the collaboration so it can be cancelled by id', () => {
    expect(brandHaltJobKey('c1')).toBe('brand-halt:c1');
  });
});
