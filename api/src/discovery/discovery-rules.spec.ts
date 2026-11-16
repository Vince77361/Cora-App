import { planDecisionWrite, StoredDecision } from './discovery-rules';

const stored = (over: Partial<StoredDecision> = {}): StoredDecision => ({
  id: 'd1',
  decision: 'LIKE',
  passReason: null,
  note: null,
  contentTitle: null,
  contentPhotoPath: null,
  proposedFee: null,
  proposedProductProvided: null,
  proposedPerfRate: null,
  proposedPerfCap: null,
  ...over,
});

const proposal = {
  fee: 450000,
  productProvided: false,
  performance: { ratePer1000: 2000, cap: 60000 },
};

describe('planDecisionWrite', () => {
  it('creates a row with the like fields for a new like', () => {
    const write = planDecisionWrite(null, {
      decision: 'LIKE',
      note: '좋았어요',
      proposal,
      card: { headline: '한 줄', photoPath: 'creator-cards/u/p.jpg' },
    });
    expect(write).toEqual({
      kind: 'create',
      data: {
        decision: 'LIKE',
        passReason: null,
        note: '좋았어요',
        contentTitle: '한 줄',
        contentPhotoPath: 'creator-cards/u/p.jpg',
        proposedFee: 450000,
        proposedProductProvided: false,
        proposedPerfRate: 2000,
        proposedPerfCap: 60000,
      },
    });
  });

  it('copies no content when the like has no note', () => {
    const write = planDecisionWrite(null, {
      decision: 'LIKE',
      card: { headline: '한 줄', photoPath: 'x' },
    });
    expect(write).toMatchObject({
      kind: 'create',
      data: { note: null, contentTitle: null, contentPhotoPath: null },
    });
  });

  it('only refreshes the time for the same hold and writes nothing for the same pass', () => {
    expect(
      planDecisionWrite(stored({ decision: 'HOLD' }), { decision: 'HOLD' }),
    ).toEqual({ kind: 'update', data: {} });
    expect(
      planDecisionWrite(stored({ decision: 'PASS', passReason: 'FEE' }), {
        decision: 'PASS',
      }),
    ).toEqual({ kind: 'none' });
  });

  it('writes nothing for a plain like on a like', () => {
    expect(
      planDecisionWrite(stored({ proposedFee: 1 }), { decision: 'LIKE' }),
    ).toEqual({ kind: 'none' });
  });

  it('overwrites only the proposal on a like with a proposal and keeps the note', () => {
    const write = planDecisionWrite(stored({ note: '글' }), {
      decision: 'LIKE',
      proposal,
    });
    expect(write.kind).toBe('update');
    if (write.kind === 'update') {
      expect(write.data).not.toHaveProperty('note');
      expect(write.data.proposedFee).toBe(450000);
    }
  });

  it('clears a stored performance bonus when the new proposal has none', () => {
    const write = planDecisionWrite(
      stored({
        proposedFee: 1,
        proposedPerfRate: 2000,
        proposedPerfCap: 60000,
      }),
      { decision: 'LIKE', proposal: { ...proposal, performance: null } },
    );
    expect(write).toMatchObject({
      kind: 'update',
      data: { proposedPerfRate: null, proposedPerfCap: null },
    });
  });

  it('starts over when the decision changes', () => {
    const write = planDecisionWrite(
      stored({ decision: 'PASS', passReason: 'MOOD' }),
      { decision: 'LIKE' },
    );
    expect(write).toEqual({
      kind: 'update',
      data: {
        decision: 'LIKE',
        passReason: null,
        note: null,
        contentTitle: null,
        contentPhotoPath: null,
        proposedFee: null,
        proposedProductProvided: null,
        proposedPerfRate: null,
        proposedPerfCap: null,
      },
    });
    const toPass = planDecisionWrite(
      stored({ proposedFee: 450000, note: '글' }),
      { decision: 'PASS' },
    );
    expect(toPass).toMatchObject({
      kind: 'update',
      data: { decision: 'PASS', note: null, proposedFee: null },
    });
  });
});
