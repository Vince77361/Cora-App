// 공통 모델 4장의 시·도 고정 목록. 순서도 그대로 쓴다(앱의 선택 목록 순서).
export const SIDO_LIST = [
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
] as const;

export type Sido = (typeof SIDO_LIST)[number];

// 지역 정렬 묶음: 구·군까지 같으면 0, 시·도만 같으면 1, 그 밖(가게에 지역이 없을 때 포함)은 2.
// 지역은 거르지 않고 순서에만 쓴다(공통 모델 4장).
export function regionTier(
  store: { regionSido: string | null; regionSigungu: string | null },
  creator: { regionSido: string; regionSigungu: string | null },
): 0 | 1 | 2 {
  if (!store.regionSido || creator.regionSido !== store.regionSido) return 2;
  return store.regionSigungu !== null &&
    creator.regionSigungu === store.regionSigungu
    ? 0
    : 1;
}
