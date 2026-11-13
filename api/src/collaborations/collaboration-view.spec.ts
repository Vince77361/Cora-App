import { CollaborationStage } from '@prisma/client';
import {
  buildSteps,
  COLLABORATION_DONE_STAGES,
  liveAmounts,
  payoutStatusOf,
  StepInput,
  viewReportStatusOf,
} from './collaboration-view';

const T0 = new Date('2026-12-01T03:00:00.000Z');
const T1 = new Date('2026-12-02T03:00:00.000Z');
const T2 = new Date('2026-12-03T03:00:00.000Z');
const T3 = new Date('2026-12-10T03:00:00.000Z');

function input(over: Partial<StepInput> = {}): StepInput {
  return {
    kind: 'STORE_OFFER',
    stage: 'FUNDED',
    stageBeforeHalt: null,
    settlementMethod: 'PER_VIEW',
    acceptedAt: T0,
    fundedAt: T1,
    submittedAt: null,
    settledAt: null,
    ...over,
  };
}
const states = (i: StepInput) => buildSteps(i).map((s) => s.state);

describe('buildSteps', () => {
  it('always returns the five fixed steps in order', () => {
    expect(buildSteps(input()).map((s) => s.key)).toEqual([
      'ACCEPTED',
      'PAID',
      'VISIT',
      'SUBMIT',
      'SETTLE',
    ]);
  });

  it('waits for payment right after the offer is accepted', () => {
    const steps = buildSteps(
      input({ stage: 'AWAITING_PAYMENT', fundedAt: null }),
    );
    expect(steps.map((s) => s.state)).toEqual([
      'DONE',
      'NOW',
      'TODO',
      'TODO',
      'TODO',
    ]);
    expect(steps[0].at).toEqual(T0);
    expect(steps[1].at).toBeNull();
  });

  it('shows VISIT as NOW right after funding, until the link is submitted', () => {
    const steps = buildSteps(input());
    expect(steps.map((s) => s.state)).toEqual([
      'DONE',
      'DONE',
      'NOW',
      'TODO',
      'TODO',
    ]);
    expect(steps[1].at).toEqual(T1);
  });

  it('moves to SETTLE as NOW while counting views', () => {
    const steps = buildSteps(input({ stage: 'COUNTING', submittedAt: T2 }));
    expect(steps.map((s) => s.state)).toEqual([
      'DONE',
      'DONE',
      'DONE',
      'DONE',
      'NOW',
    ]);
    expect(steps[3].at).toEqual(T2);
    expect(steps[4].at).toBeNull();
  });

  it('marks every step DONE when settled and stamps the settle time', () => {
    const steps = buildSteps(
      input({ stage: 'SETTLED', submittedAt: T2, settledAt: T3 }),
    );
    expect(steps.every((s) => s.state === 'DONE')).toBe(true);
    expect(steps[4].at).toEqual(T3);
  });

  it('treats PAID as done from the start for a voucher-only offer', () => {
    const steps = buildSteps(
      input({
        settlementMethod: 'NONE',
        fundedAt: T0,
      }),
    );
    expect(steps.map((s) => s.state)).toEqual([
      'DONE',
      'DONE',
      'NOW',
      'TODO',
      'TODO',
    ]);
  });

  it('keeps PAID as the current step for a fixed cash offer that is not paid yet', () => {
    for (const settlementMethod of ['FIXED', 'FIXED_AND_PER_VIEW'] as const) {
      expect(
        states(
          input({
            settlementMethod,
            stage: 'AWAITING_PAYMENT',
            fundedAt: null,
          }),
        ),
      ).toEqual(['DONE', 'NOW', 'TODO', 'TODO', 'TODO']);
    }
  });

  it('settles a voucher-only offer on submission with the submit time as the settle time', () => {
    const steps = buildSteps(
      input({
        settlementMethod: 'NONE',
        stage: 'SETTLED',
        submittedAt: T2,
      }),
    );
    expect(steps.every((s) => s.state === 'DONE')).toBe(true);
    expect(steps[4].at).toEqual(T2);
  });

  it('keeps the step where a halted collaboration stopped', () => {
    expect(
      states(
        input({
          stage: 'HALTED',
          stageBeforeHalt: 'COUNTING',
          submittedAt: T2,
        }),
      ),
    ).toEqual(['DONE', 'DONE', 'DONE', 'DONE', 'NOW']);
    expect(
      states(input({ stage: 'HALTED', stageBeforeHalt: 'FUNDED' })),
    ).toEqual(['DONE', 'DONE', 'NOW', 'TODO', 'TODO']);
  });

  it('shows no NOW step once a collaboration is cancelled or refunded', () => {
    expect(states(input({ stage: 'CANCELLED' }))).toEqual([
      'DONE',
      'DONE',
      'TODO',
      'TODO',
      'TODO',
    ]);
    expect(states(input({ stage: 'REFUNDED' }))).toEqual([
      'DONE',
      'DONE',
      'TODO',
      'TODO',
      'TODO',
    ]);
    // 결제 전에 끝난 협업은 결제 단계도 해내지 못했다.
    expect(states(input({ stage: 'CANCELLED', fundedAt: null }))).toEqual([
      'DONE',
      'TODO',
      'TODO',
      'TODO',
      'TODO',
    ]);
    // 제출한 뒤 운영자가 환급으로 끝낸 협업은 제출까지 DONE이다.
    expect(states(input({ stage: 'REFUNDED', submittedAt: T2 }))).toEqual([
      'DONE',
      'DONE',
      'DONE',
      'DONE',
      'TODO',
    ]);
  });
});

describe('payoutStatusOf', () => {
  const pending = { status: 'PENDING' as const, scheduledFor: T3 };

  it('is NONE when no payout is due', () => {
    expect(payoutStatusOf(null, true)).toEqual({
      status: 'NONE',
      scheduledFor: null,
    });
  });

  it('needs an account for a pending payout without one', () => {
    expect(payoutStatusOf(pending, false)).toEqual({
      status: 'NEEDS_ACCOUNT',
      scheduledFor: null,
    });
  });

  it('is PENDING with the scheduled date once an account exists', () => {
    expect(payoutStatusOf(pending, true)).toEqual({
      status: 'PENDING',
      scheduledFor: T3,
    });
  });

  it('reports DONE and FAILED without a scheduled date', () => {
    expect(payoutStatusOf({ status: 'DONE', scheduledFor: T3 }, true)).toEqual({
      status: 'DONE',
      scheduledFor: null,
    });
    expect(
      payoutStatusOf({ status: 'FAILED', scheduledFor: T3 }, true),
    ).toEqual({ status: 'FAILED', scheduledFor: null });
  });
});

describe('liveAmounts', () => {
  const terms = {
    viewRatePerThousand: 2000,
    perViewCap: 60000,
    fixedCash: 0,
  };

  it('computes earned and refund from the latest views while counting', () => {
    expect(liveAmounts({ stage: 'COUNTING', views: 12500, terms })).toEqual({
      earned: 25000,
      refund: 35000,
    });
  });

  it('computes a legacy copy at 10000 won per thousand like before', () => {
    expect(
      liveAmounts({
        stage: 'COUNTING',
        views: 4320,
        terms: { viewRatePerThousand: 10000, perViewCap: 100000, fixedCash: 0 },
      }),
    ).toEqual({ earned: 43200, refund: 56800 });
  });

  it('caps earned at the view pay cap', () => {
    expect(liveAmounts({ stage: 'COUNTING', views: 200000, terms })).toEqual({
      earned: 60000,
      refund: 0,
    });
  });

  it('adds fixed cash to what the creator has earned and keeps it out of the refund', () => {
    expect(
      liveAmounts({
        stage: 'COUNTING',
        views: 12500,
        terms: { ...terms, fixedCash: 30000 },
      }),
    ).toEqual({ earned: 55000, refund: 35000 });
  });

  it('is null outside COUNTING, when nothing has been read or without view pay', () => {
    for (const stage of [
      'FUNDED',
      'HALTED',
      'SETTLED',
      'REFUNDED',
    ] as CollaborationStage[]) {
      expect(liveAmounts({ stage, views: 4320, terms })).toBeNull();
    }
    expect(liveAmounts({ stage: 'COUNTING', views: null, terms })).toBeNull();
    expect(
      liveAmounts({
        stage: 'COUNTING',
        views: 4320,
        terms: { ...terms, viewRatePerThousand: null, perViewCap: null },
      }),
    ).toBeNull();
  });
});

describe('COLLABORATION_DONE_STAGES', () => {
  it('lists the stages that belong to the done scope', () => {
    expect([...COLLABORATION_DONE_STAGES].sort()).toEqual(
      ['CANCELLED', 'DROPPED', 'REFUNDED', 'SETTLED'].sort(),
    );
  });
});

describe('viewReportStatusOf', () => {
  const base = {
    stage: 'COUNTING' as CollaborationStage,
    submitted: true,
    hasViewPay: true,
    settlementStatus: null,
  };

  it('is none without view pay or before the link is submitted', () => {
    expect(viewReportStatusOf({ ...base, hasViewPay: false })).toBe('NONE');
    expect(viewReportStatusOf({ ...base, submitted: false })).toBe('NONE');
  });

  it('is counting while the period runs and when the views could not be read', () => {
    expect(viewReportStatusOf(base)).toBe('COUNTING');
    expect(viewReportStatusOf({ ...base, stage: 'HALTED' })).toBe('COUNTING');
  });

  it('follows the settlement row once there is one', () => {
    for (const status of ['UNCONFIRMED', 'CONFIRMED', 'DISPUTED'] as const) {
      expect(viewReportStatusOf({ ...base, settlementStatus: status })).toBe(
        status,
      );
    }
  });

  it('is none for a collaboration that ended without a calculation', () => {
    expect(viewReportStatusOf({ ...base, stage: 'REFUNDED' })).toBe('NONE');
  });
});
