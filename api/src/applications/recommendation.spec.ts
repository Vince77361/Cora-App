import {
  INDUSTRY_KEYWORDS,
  pickRecommended,
  reasonsFor,
  scoreApplicant,
} from './recommendation';
import type { Candidate } from './recommendation';

const STORE = {
  regionSido: '서울특별시',
  regionSigungu: '성동구',
  industry: 'FOOD_CAFE' as const,
};

const BASE = {
  regionSido: '부산광역시',
  regionSigungu: '해운대구',
  contentFocus: null,
  hasPitch: false,
  finishedCount: 0,
};

function candidate(id: string, minute: number, over: Partial<Candidate> = {}) {
  return {
    ...BASE,
    id,
    createdAt: new Date(Date.UTC(2026, 10, 11, 0, minute)),
    skippedFromPicksAt: null,
    ...over,
  } satisfies Candidate;
}

describe('recommendation', () => {
  it('scores the same district above the same province', () => {
    const sameDistrict = scoreApplicant(
      { ...BASE, regionSido: '서울특별시', regionSigungu: '성동구' },
      STORE,
    );
    const sameProvince = scoreApplicant(
      { ...BASE, regionSido: '서울특별시', regionSigungu: '강남구' },
      STORE,
    );
    const elsewhere = scoreApplicant(BASE, STORE);
    // 구·군이 같으면 3점만 준다(시·도 1점을 더하지 않는다).
    expect(sameDistrict).toBe(3);
    expect(sameProvince).toBe(1);
    expect(elsewhere).toBe(0);
  });

  it('does not match a district when the store has no region', () => {
    const noRegion = { ...STORE, regionSido: null, regionSigungu: null };
    expect(
      scoreApplicant({ ...BASE, regionSido: '서울특별시' }, noRegion),
    ).toBe(0);
  });

  it('adds two points when the content focus matches the store industry', () => {
    expect(
      scoreApplicant({ ...BASE, contentFocus: '성수동 카페 릴스' }, STORE),
    ).toBe(2);
    expect(scoreApplicant({ ...BASE, contentFocus: '패션 룩북' }, STORE)).toBe(
      0,
    );
    expect(
      scoreApplicant(
        { ...BASE, contentFocus: '패션 룩북' },
        { ...STORE, industry: 'FASHION' },
      ),
    ).toBe(2);
    // 낱말 표가 없는 분류는 맞는 것이 없다.
    expect(INDUSTRY_KEYWORDS.OTHER).toEqual([]);
    expect(
      scoreApplicant(
        { ...BASE, contentFocus: '카페 릴스' },
        { ...STORE, industry: 'OTHER' },
      ),
    ).toBe(0);
  });

  it('adds one point for a pitch and one per finished collaboration up to two', () => {
    expect(scoreApplicant({ ...BASE, hasPitch: true }, STORE)).toBe(1);
    expect(scoreApplicant({ ...BASE, finishedCount: 1 }, STORE)).toBe(1);
    expect(scoreApplicant({ ...BASE, finishedCount: 2 }, STORE)).toBe(2);
    expect(scoreApplicant({ ...BASE, finishedCount: 9 }, STORE)).toBe(2);
    expect(
      scoreApplicant(
        {
          regionSido: '서울특별시',
          regionSigungu: '성동구',
          contentFocus: '맛집',
          hasPitch: true,
          finishedCount: 5,
        },
        STORE,
      ),
    ).toBe(3 + 2 + 1 + 2);
  });

  it('never looks at follower counts', () => {
    // 점수 입력 타입에 팔로워 칸이 없고, 몰래 실어 보내도 점수가 같다(e2e가 API에서도 확인한다).
    const many = { ...BASE, followers: 100000 };
    const few = { ...BASE, followers: 3 };
    expect(scoreApplicant(many, STORE)).toBe(scoreApplicant(few, STORE));
  });

  it('breaks ties by the earlier application', () => {
    const picked = pickRecommended(
      [candidate('late', 5), candidate('early', 1), candidate('mid', 3)],
      STORE,
    );
    expect(picked.map((c) => c.id)).toEqual(['early', 'mid', 'late']);
  });

  it('orders by score before the application time', () => {
    const picked = pickRecommended(
      [
        candidate('plain', 1),
        candidate('pitched', 9, { hasPitch: true }),
        candidate('local', 8, {
          regionSido: '서울특별시',
          regionSigungu: '성동구',
        }),
      ],
      STORE,
    );
    expect(picked.map((c) => c.id)).toEqual(['local', 'pitched', 'plain']);
  });

  it('writes reasons only from the facts used for the score', () => {
    expect(reasonsFor(BASE, STORE)).toEqual([]);
    expect(
      reasonsFor(
        {
          regionSido: '서울특별시',
          regionSigungu: '성동구',
          contentFocus: '카페 릴스',
          hasPitch: true,
          finishedCount: 2,
        },
        STORE,
      ),
    ).toEqual([
      '같은 동네예요',
      '맛집·카페 콘텐츠를 만들어요',
      '지난 협업을 2번 마쳤어요',
    ]);
    // 같은 시·도만 맞거나 한 줄만 있으면 말할 이유가 없다(점수는 오르지만 이유 글 조각이 아니다).
    expect(
      reasonsFor(
        {
          ...BASE,
          regionSido: '서울특별시',
          regionSigungu: '강남구',
          hasPitch: true,
        },
        STORE,
      ),
    ).toEqual([]);
  });

  it('returns at most three applicants', () => {
    const many = ['a', 'b', 'c', 'd', 'e'].map((id, i) => candidate(id, i));
    expect(pickRecommended(many, STORE)).toHaveLength(3);
    expect(pickRecommended(many, STORE, 2)).toHaveLength(2);
  });

  it('returns fewer than three when fewer applied', () => {
    expect(pickRecommended([candidate('a', 1)], STORE)).toHaveLength(1);
    expect(pickRecommended([], STORE)).toEqual([]);
  });

  it('leaves a skipped applicant out of the picks', () => {
    const picked = pickRecommended(
      [
        candidate('skipped', 1, {
          regionSido: '서울특별시',
          regionSigungu: '성동구',
          skippedFromPicksAt: new Date(),
        }),
        candidate('kept', 2),
      ],
      STORE,
    );
    expect(picked.map((c) => c.id)).toEqual(['kept']);
  });
});
