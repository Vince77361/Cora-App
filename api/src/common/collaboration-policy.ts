// 가게 흐름 개정(2026-11-12)의 정책 값을 한 파일에 모은다.
// 소유자 확인 전 값(설계 6장)이 많아서, 바뀌면 이 파일 한 줄만 고치면 되게 둔다.
// 앱은 범위 값을 GET /config에서 읽고 숫자를 따로 적지 않는다.

// 보상: 식사권 + 고정 현금 + 조회수 수당(1,000회당 단가, 상한).
export const REWARD_POLICY = {
  // 단가는 "1,000회당 원"이다.
  viewRate: { min: 1000, max: 5000, step: 500, default: 2000 },
  perViewCap: { min: 10000, max: 300000, step: 10000, default: 60000 },
  // 고정 현금의 최대는 맡기는 쪽 종류별이다. 가게 흐름은 STORE만 쓰고 BRAND는 브랜드 계획이 쓴다.
  // presets는 캔버스 F1의 빠른 선택(없음, 3만 원, 5만 원, 10만 원)이다.
  fixedCash: {
    maxByCommissioner: { STORE: 1000000, BRAND: 10000000 },
    step: 10000,
    presets: [0, 30000, 50000, 100000],
  },
  voucher: {
    defaultName: '식사권',
    defaultValue: 40000,
    defaultPeople: 2,
    maxPeople: 10,
    minValue: 1000,
    maxValue: 1000000,
  },
  usageRightsDefault: 'STORE_REPOST_3M',
  // 게시 뒤 조회수를 재는 기간(일).
  countingDays: 7,
} as const;

// 제안(판본)과 시리즈 입력 한도.
export const PROPOSAL_POLICY = {
  responseDays: 7,
  maxVersions: 10,
  // 거절한 뒤 되돌릴 수 있는 시간. 오퍼의 "열림" 판정과 가게 상세의 열린 오퍼가 같은 값을 쓴다.
  declineUndoSeconds: 30,
  ideaMax: 200,
  principlesMax: 3,
  principleLength: 10,
  pitchMax: 100,
  seriesMax: 5,
  seriesNameMax: 20,
  seriesNoteMax: 20,
} as const;

// 조회 자료 확인: 사장님이 확인하지 않으면 confirmHours 뒤 자동 확인한다.
export const VIEW_REPORT_POLICY = {
  confirmHours: 48,
  disputeReasonMax: 200,
  evidenceWaitDays: 3,
  unreadableDays: 3,
} as const;

// 가게 소개 페이지와 체험단 비교 줄.
export const STORE_PAGE_POLICY = {
  tagsMax: 5,
  tagLength: 10,
  phrasesMax: 3,
  phraseLength: 20,
  recruitLineMax: 40,
  trialBannerDays: 30,
  trialSnoozeDays: 7,
  publicPageHost: 'cora.page',
} as const;

// 지원자 추천 점수와 추천 수.
export const RECOMMEND_POLICY = {
  picks: 3,
  sameSigungu: 3,
  sameSido: 1,
  industryMatch: 2,
  hasPitch: 1,
  perFinished: 1,
  finishedMax: 2,
} as const;

// 사용권 값. 저장소 enum이 생기면(Task 3) 그 enum으로 바뀐다.
export type UsageRightsValue = 'STORE_REPOST_3M' | 'STORE_REPOST_6M' | 'NONE';
