import {
  CampaignFacts,
  feeBandRange,
  matchScore,
  Principles,
  regionMatch,
  storeScore,
} from './match-score';

// 어느 규칙도 맞지 않는 기준. 테스트마다 맞추려는 규칙 하나만 바꾼다.
const NONE_MATCH: Principles = {
  fields: ['BEAUTY'],
  faceOk: false,
  scriptOk: false,
  feeBand: 'W500K_PLUS',
  trialDays: 'D14',
};
const CAMPAIGN: CampaignFacts = {
  industry: 'ACCESSORY',
  fee: 300000,
  notRequired: [],
  trialDays: 'D7',
};

describe('feeBandRange', () => {
  it('maps every band to its documented range', () => {
    expect(feeBandRange('W200K')).toEqual({ min: 200000, max: 299999 });
    expect(feeBandRange('W300K')).toEqual({ min: 300000, max: 399999 });
    expect(feeBandRange('W400K')).toEqual({ min: 400000, max: 499999 });
    expect(feeBandRange('W500K_PLUS')).toEqual({ min: 500000, max: null });
  });
});

describe('matchScore', () => {
  it('scores zero with no reasons when nothing matches', () => {
    expect(matchScore(NONE_MATCH, CAMPAIGN)).toEqual({
      score: 0,
      reasons: [],
    });
  });

  it('matches the field when the creator takes the campaign industry', () => {
    const result = matchScore(
      { ...NONE_MATCH, fields: ['BEAUTY', 'ACCESSORY'] },
      CAMPAIGN,
    );
    expect(result).toEqual({ score: 1, reasons: ['FIELD'] });
  });

  it('matches the face rule when the creator is fine with it or the campaign does not require it', () => {
    expect(
      matchScore({ ...NONE_MATCH, faceOk: true }, CAMPAIGN).reasons,
    ).toEqual(['FACE']);
    expect(
      matchScore(NONE_MATCH, { ...CAMPAIGN, notRequired: ['FACE'] }).reasons,
    ).toEqual(['FACE']);
  });

  it('matches the script rule when the creator is fine with it or the campaign does not require reading', () => {
    expect(
      matchScore({ ...NONE_MATCH, scriptOk: true }, CAMPAIGN).reasons,
    ).toEqual(['SCRIPT']);
    expect(
      matchScore(NONE_MATCH, { ...CAMPAIGN, notRequired: ['SCRIPT_READING'] })
        .reasons,
    ).toEqual(['SCRIPT']);
  });

  it('does not count fixed lines as the script rule', () => {
    expect(
      matchScore(NONE_MATCH, { ...CAMPAIGN, notRequired: ['FIXED_LINES'] })
        .score,
    ).toBe(0);
  });

  it('matches the product trial period when it is the same or the creator does not mind', () => {
    expect(
      matchScore({ ...NONE_MATCH, trialDays: 'D7' }, CAMPAIGN).reasons,
    ).toEqual(['TRIAL']);
    expect(
      matchScore({ ...NONE_MATCH, trialDays: 'ANY' }, CAMPAIGN).reasons,
    ).toEqual(['TRIAL']);
  });

  it('counts the fee as matching when the campaign pays at least the band minimum', () => {
    const fee = (feeBand: Principles['feeBand'], amount: number) =>
      matchScore({ ...NONE_MATCH, feeBand }, { ...CAMPAIGN, fee: amount })
        .reasons;
    expect(fee('W300K', 300000)).toEqual(['FEE']);
    expect(fee('W300K', 290000)).toEqual([]);
    // 구간의 위 끝을 넘겨도(더 많이 줘도) 맞는 것으로 본다.
    expect(fee('W200K', 1000000)).toEqual(['FEE']);
    expect(fee('W500K_PLUS', 490000)).toEqual([]);
    expect(fee('W500K_PLUS', 500000)).toEqual(['FEE']);
  });

  it('scores one point per matching rule and lists the reasons in rule order', () => {
    const everything = matchScore(
      {
        fields: ['ACCESSORY'],
        faceOk: true,
        scriptOk: true,
        feeBand: 'W300K',
        trialDays: 'ANY',
      },
      CAMPAIGN,
    );
    expect(everything).toEqual({
      score: 5,
      reasons: ['FIELD', 'FACE', 'SCRIPT', 'FEE', 'TRIAL'],
    });
  });
});

describe('regionMatch', () => {
  const creator = { regionSido: '서울특별시', regionSigungu: '성동구' };

  it('reports the same district only inside the same province', () => {
    expect(
      regionMatch(
        { regionSido: '서울특별시', regionSigungu: '성동구' },
        creator,
      ),
    ).toEqual({ sameSido: true, sameSigungu: true });
    expect(
      regionMatch(
        { regionSido: '서울특별시', regionSigungu: '마포구' },
        creator,
      ),
    ).toEqual({ sameSido: true, sameSigungu: false });
    expect(
      regionMatch(
        { regionSido: '부산광역시', regionSigungu: '성동구' },
        creator,
      ),
    ).toEqual({ sameSido: false, sameSigungu: false });
  });

  it('never matches a district when the creator has none', () => {
    expect(
      regionMatch(
        { regionSido: '서울특별시', regionSigungu: null },
        { regionSido: '서울특별시', regionSigungu: null },
      ),
    ).toEqual({ sameSido: true, sameSigungu: false });
  });
});

describe('storeScore', () => {
  const store = { industry: 'FOOD_CAFE' as const };
  const principles = { fields: ['FOOD_CAFE' as const] };

  it('adds 1 for the field, 2 for the same district and 1 for the same province only', () => {
    const none = { sameSigungu: false, sameSido: false };
    expect(storeScore(principles, store, none)).toBe(1);
    expect(
      storeScore(principles, store, { sameSigungu: false, sameSido: true }),
    ).toBe(2);
    expect(
      storeScore(principles, store, { sameSigungu: true, sameSido: true }),
    ).toBe(3);
    expect(storeScore({ fields: ['BEAUTY'] }, store, none)).toBe(0);
  });

  it('scores only the region when there are no principles yet', () => {
    expect(storeScore(null, store, { sameSigungu: true, sameSido: true })).toBe(
      2,
    );
  });
});
