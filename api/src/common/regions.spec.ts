import { regionTier, SIDO_LIST } from './regions';

describe('SIDO_LIST', () => {
  it('has the 17 fixed sido names in the documented order', () => {
    expect([...SIDO_LIST]).toEqual([
      '서울특별시',
      '부산광역시',
      '대구광역시',
      '인천광역시',
      '광주광역시',
      '대전광역시',
      '울산광역시',
      '세종특별자치시',
      '경기도',
      '강원특별자치도',
      '충청북도',
      '충청남도',
      '전북특별자치도',
      '전라남도',
      '경상북도',
      '경상남도',
      '제주특별자치도',
    ]);
  });
});

describe('regionTier', () => {
  const store = { regionSido: '서울특별시', regionSigungu: '마포구' };

  it('is 0 for the same district, 1 for the same province and 2 otherwise', () => {
    expect(
      regionTier(store, { regionSido: '서울특별시', regionSigungu: '마포구' }),
    ).toBe(0);
    expect(
      regionTier(store, { regionSido: '서울특별시', regionSigungu: '강남구' }),
    ).toBe(1);
    expect(
      regionTier(store, { regionSido: '서울특별시', regionSigungu: null }),
    ).toBe(1);
    expect(
      regionTier(store, { regionSido: '경기도', regionSigungu: '마포구' }),
    ).toBe(2);
  });

  it('puts everyone in the last tier when the store has no region', () => {
    expect(
      regionTier(
        { regionSido: null, regionSigungu: null },
        { regionSido: '서울특별시', regionSigungu: '마포구' },
      ),
    ).toBe(2);
  });
});
