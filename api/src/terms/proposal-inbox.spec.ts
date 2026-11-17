import {
  inboxEndKind,
  inboxGroup,
  isCounterVersion,
  myDropReasonOf,
} from './proposal-inbox';

describe('inboxGroup', () => {
  it('groups a collaboration as my turn until I confirm the latest version', () => {
    expect(
      inboxGroup({
        stage: 'MATCHED',
        myConfirmed: false,
        otherConfirmed: false,
      }),
    ).toBe('MY_TURN');
    expect(
      inboxGroup({
        stage: 'NEGOTIATING',
        myConfirmed: false,
        otherConfirmed: true,
      }),
    ).toBe('MY_TURN');
    expect(
      inboxGroup({
        stage: 'NEGOTIATING',
        myConfirmed: true,
        otherConfirmed: false,
      }),
    ).toBe('WAITING');
  });

  it('puts a server-made version 1 in the turn of both sides', () => {
    // 버전 1은 아무도 확인하지 않은 채 MATCHED로 시작한다.
    const unconfirmed = {
      stage: 'MATCHED' as const,
      myConfirmed: false,
      otherConfirmed: false,
    };
    expect(inboxGroup(unconfirmed)).toBe('MY_TURN');
  });

  it('moves an agreed collaboration to ended and leaves contracted ones out', () => {
    const base = { myConfirmed: true, otherConfirmed: true };
    expect(inboxGroup({ ...base, stage: 'AGREED' })).toBe('ENDED');
    expect(inboxGroup({ ...base, stage: 'DROPPED' })).toBe('ENDED');
    for (const stage of [
      'INQUIRY',
      'CONTRACTED',
      'GUIDED',
      'REVIEWING',
      'APPROVED',
      'PUBLISHED',
      'SETTLED',
      'HALTED',
      'CANCELLED',
    ] as const) {
      expect(inboxGroup({ ...base, stage })).toBeNull();
    }
  });
});

describe('inboxEndKind', () => {
  it('separates an agreement from a dropped negotiation', () => {
    expect(inboxEndKind('AGREED')).toBe('AGREED');
    expect(inboxEndKind('DROPPED')).toBe('ENDED');
    expect(inboxEndKind('NEGOTIATING')).toBeNull();
  });
});

describe('isCounterVersion', () => {
  it('marks a version written by the other side as a counter-proposal', () => {
    expect(isCounterVersion({ version: 2, proposedById: 'other' }, 'me')).toBe(
      true,
    );
    expect(isCounterVersion({ version: 2, proposedById: 'me' }, 'me')).toBe(
      false,
    );
  });

  it('does not count the server-made version 1', () => {
    expect(isCounterVersion({ version: 1, proposedById: null }, 'me')).toBe(
      false,
    );
  });
});

describe('myDropReasonOf', () => {
  it('shows the drop reason only to the side that dropped', () => {
    const dropped = { droppedById: 'me', dropReason: 'BUDGET' as const };
    expect(myDropReasonOf(dropped, 'me')).toBe('BUDGET');
    expect(myDropReasonOf(dropped, 'other')).toBeNull();
  });

  it('has no reason for a decline or a block', () => {
    expect(
      myDropReasonOf({ droppedById: 'me', dropReason: 'BLOCKED' }, 'me'),
    ).toBeNull();
    expect(
      myDropReasonOf({ droppedById: null, dropReason: null }, 'me'),
    ).toBeNull();
  });
});
