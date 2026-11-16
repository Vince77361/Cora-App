import {
  campaignTags,
  principleTags,
  storeHeadline,
  storeRewardLine,
} from './card-text';

describe('principleTags', () => {
  const base = {
    faceOk: true,
    scriptOk: true,
    honestReview: false,
    fields: ['ACCESSORY' as const, 'BEAUTY' as const],
  };

  it('shows only the first field name when nothing else stands out', () => {
    expect(principleTags(base)).toEqual(['액세서리·주얼리']);
  });

  it('puts face, script and honest review before the field in that order', () => {
    expect(
      principleTags({
        ...base,
        faceOk: false,
        scriptOk: false,
        honestReview: true,
      }),
    ).toEqual(['얼굴출연없음', '대본낭독없음', '솔직후기', '액세서리·주얼리']);
  });

  it('leaves out the field when the list is empty', () => {
    expect(principleTags({ ...base, fields: [], faceOk: false })).toEqual([
      '얼굴출연없음',
    ]);
  });
});

describe('campaignTags', () => {
  it('names what the campaign does not require, at most two', () => {
    expect(campaignTags([])).toEqual([]);
    expect(campaignTags(['FIXED_LINES'])).toEqual(['정해진대사없음']);
    expect(campaignTags(['FACE', 'FIXED_LINES', 'SCRIPT_READING'])).toEqual([
      '얼굴출연없음',
      '정해진대사없음',
    ]);
  });
});

describe('storeHeadline', () => {
  const store = {
    intro: null as string | null,
    recruitLine: null as string | null,
    industry: 'FOOD_CAFE' as const,
  };

  it('takes the first sentence of the intro', () => {
    expect(
      storeHeadline({
        ...store,
        intro: '성수동 골목의 작은 라멘집이에요. 점심에는 줄이 길어요.',
      }),
    ).toBe('성수동 골목의 작은 라멘집이에요.');
  });

  it('cuts a long first sentence at 40 characters', () => {
    const long = '가'.repeat(60);
    expect(storeHeadline({ ...store, intro: long })).toBe('가'.repeat(40));
  });

  it('falls back to the recruit line and then the industry name', () => {
    expect(storeHeadline({ ...store, recruitLine: '릴스 찍어 주실 분' })).toBe(
      '릴스 찍어 주실 분',
    );
    expect(storeHeadline({ ...store, intro: '  ' })).toBe('맛집·카페');
  });
});

describe('storeRewardLine', () => {
  const none = { voucherName: null, fixedCash: 0, perViewCap: null };

  it('joins the store reward parts into one short line', () => {
    expect(
      storeRewardLine({ ...none, voucherName: '식사권', perViewCap: 100000 }),
    ).toBe('식사권 + 조회수 수당');
    expect(
      storeRewardLine({ ...none, voucherName: '식사권', fixedCash: 30000 }),
    ).toBe('식사권 + 현금 30,000원');
    expect(storeRewardLine({ ...none, perViewCap: 50000 })).toBe('조회수 수당');
  });

  it('lists all three parts in order', () => {
    expect(
      storeRewardLine({
        voucherName: '식사권',
        fixedCash: 30000,
        perViewCap: 50000,
      }),
    ).toBe('식사권 + 현금 30,000원 + 조회수 수당');
  });

  it('gives an empty line when there is no reward', () => {
    expect(storeRewardLine(none)).toBe('');
  });
});
