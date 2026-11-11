import {
  NotificationGlyph,
  NotificationKind,
  NotificationSwitch,
  NotificationTab,
} from '@prisma/client';
import { josa } from './josa';

// 앱이 화면으로 바꾸는 가는 곳. 4~8번 계획이 종류를 더한다.
export type NotificationTarget = {
  kind:
    | 'STORE_APPLICANTS'
    | 'STORE_SENT_OFFERS'
    | 'OFFER_INBOX'
    | 'PAYMENT'
    | 'COLLABORATION'
    | 'WALLET';
  id: string | null;
};

export type NotificationParams = Record<string, string | number>;

export interface CatalogEntry {
  // null은 알림함에 남기지 않는 종류(5번 계획의 대화 메시지)다.
  tab: NotificationTab | null;
  switch: NotificationSwitch;
  glyph: NotificationGlyph | null;
  render(input: {
    actorName: string | null;
    params: NotificationParams;
  }): string;
}

// 오퍼 문구의 {형식}. 앱의 offer_terms_text.dart formatLabel과 같은 이름이다.
const FORMAT_LABEL: Record<string, string> = {
  SHORTS: '쇼츠',
  REELS: '릴스',
  CARD_NEWS: '카드뉴스',
  BLOG: '블로그 글',
};

// params에는 금액을 숫자 그대로 두고, 글자로 바꾸는 것은 여기서 한다. 화면과 푸시가 같은 함수를 쓴다.
function won(value: string | number | undefined): string {
  return `${Number(value ?? 0).toLocaleString('en-US')}원`;
}

// 이름이 없을 때(상대가 지워졌을 때)의 대신 글자.
const CREATOR_FALLBACK = '크리에이터';
const STORE_FALLBACK = '가게';

// 종류마다 탭·스위치·그림·문구를 정한다. 근거는 설계 account-notify-settings 3.2의 표(줄 이름을 주석에 적는다).
// "끌 수 없음"은 ESSENTIAL, 정산 종류의 그림은 WON이다.
export const NOTIFICATION_CATALOG: Record<NotificationKind, CatalogEntry> = {
  // 표 "지원 도착": 매칭 / 새 오퍼와 제안 / 사진.
  APPLICATION_RECEIVED: {
    tab: 'MATCHING',
    switch: 'OFFERS',
    glyph: null,
    render: ({ actorName }) =>
      `${actorName ?? CREATOR_FALLBACK}님이 지원했어요.`,
  },
  // 표 "오퍼 도착": 매칭 / 새 오퍼와 제안 / 사진. 캔버스 E3 문구가 2번 계획의 푸시 문구를 대신한다.
  OFFER_RECEIVED: {
    tab: 'MATCHING',
    switch: 'OFFERS',
    glyph: null,
    render: ({ actorName, params }) => {
      const format = FORMAT_LABEL[String(params.format)] ?? '콘텐츠';
      return `${josa(actorName ?? STORE_FALLBACK, '이/가')} ${format} ${params.pieceCount ?? 1}편 오퍼를 보냈어요.`;
    },
  },
  // 표 "오퍼 수락": 매칭 / 새 오퍼와 제안 / 사진.
  OFFER_ACCEPTED: {
    tab: 'MATCHING',
    switch: 'OFFERS',
    glyph: null,
    render: ({ actorName }) =>
      `${actorName ?? CREATOR_FALLBACK}님이 오퍼를 수락했어요.`,
  },
  // 표 "오퍼 거절 (30초 뒤)": 매칭 / 새 오퍼와 제안 / 사진.
  OFFER_DECLINED: {
    tab: 'MATCHING',
    switch: 'OFFERS',
    glyph: null,
    render: ({ actorName }) =>
      `${actorName ?? CREATOR_FALLBACK}님이 이번 오퍼는 함께하기 어렵대요.`,
  },
  // 표 "결제 완료, 링크 제출, 제출 기한, 취소·취소 요청, 미제출 종료" 줄: 협업 / 끌 수 없음 / 사진.
  PAYMENT_FUNDED: {
    tab: 'COLLABORATION',
    switch: 'ESSENTIAL',
    glyph: null,
    render: ({ actorName }) =>
      `${josa(actorName ?? STORE_FALLBACK, '이/가')} 결제했어요. 방문하고 촬영해 주세요.`,
  },
  // 같은 줄(링크 제출).
  CONTENT_SUBMITTED: {
    tab: 'COLLABORATION',
    switch: 'ESSENTIAL',
    glyph: null,
    render: ({ actorName }) =>
      `${actorName ?? CREATOR_FALLBACK}님이 콘텐츠를 올렸어요.`,
  },
  // 같은 줄(제출 기한).
  SUBMIT_REMINDER: {
    tab: 'COLLABORATION',
    switch: 'ESSENTIAL',
    glyph: null,
    render: ({ params }) =>
      `콘텐츠 제출 기한이 ${params.days ?? 0}일 남았어요.`,
  },
  // 같은 줄(미제출 종료).
  UNSUBMITTED_ENDED: {
    tab: 'COLLABORATION',
    switch: 'ESSENTIAL',
    glyph: null,
    render: () => '제출 기한이 지나 협업이 종료됐어요.',
  },
  // 표 "미제출 환급, 결제 뒤 취소 환급" 줄: 정산 / 끌 수 없음 / ₩.
  UNSUBMITTED_REFUNDED: {
    tab: 'SETTLEMENT',
    switch: 'ESSENTIAL',
    glyph: 'WON',
    render: ({ params }) =>
      `기한 안에 콘텐츠가 올라오지 않아 ${josa(won(params.amount), '을/를')} 돌려드려요.`,
  },
  // 표 "결제 뒤 취소 환급"(판단 R20: 크리에이터가 그만둠): 정산 / 끌 수 없음 / ₩.
  CREATOR_CANCELLED: {
    tab: 'SETTLEMENT',
    switch: 'ESSENTIAL',
    glyph: 'WON',
    // 식사권만 있는 협업은 돌려줄 돈이 없어 금액이 0이다: 환급 문장은 빼고 그만뒀다는 소식만 낸다(판단 R41).
    render: ({ actorName, params }) => {
      const base = `${actorName ?? CREATOR_FALLBACK}님이 협업을 그만뒀어요.`;
      return Number(params.amount ?? 0) > 0
        ? `${base} ${josa(won(params.amount), '을/를')} 돌려드려요.`
        : base;
    },
  },
  // 표 "결제 완료, 링크 제출, 제출 기한, 취소·취소 요청, 미제출 종료" 줄(취소 요청): 협업 / 끌 수 없음 / 사진.
  CANCEL_REQUESTED: {
    tab: 'COLLABORATION',
    switch: 'ESSENTIAL',
    glyph: null,
    render: ({ actorName }) =>
      `${josa(actorName ?? STORE_FALLBACK, '이/가')} 협업 취소를 요청했어요.`,
  },
  // 표 "협업 멈춤 (조회수 실패, 60일, 운영 명령, 신고)": 협업 / 끌 수 없음 / 사진.
  COLLABORATION_HALTED: {
    tab: 'COLLABORATION',
    switch: 'ESSENTIAL',
    glyph: null,
    render: () => '협업이 잠시 멈췄어요. 운영팀이 확인하고 연락드릴게요.',
  },
  // 표 "정산 확정": 정산 / 정산 / ₩. 캔버스 E3 문구.
  SETTLEMENT_CONFIRMED: {
    tab: 'SETTLEMENT',
    switch: 'SETTLEMENT',
    glyph: 'WON',
    render: ({ params }) =>
      `정산 ${josa(won(params.amount), '이/가')} 다음 주 수요일에 들어와요.`,
  },
  // 표 "지급 완료": 정산 / 정산 / ₩.
  PAYOUT_DONE: {
    tab: 'SETTLEMENT',
    switch: 'SETTLEMENT',
    glyph: 'WON',
    render: ({ params }) => `${josa(won(params.amount), '이/가')} 지급됐어요.`,
  },
  // 표 "정산 뒤 환급": 정산 / 정산 / ₩.
  SETTLEMENT_REFUNDED: {
    tab: 'SETTLEMENT',
    switch: 'SETTLEMENT',
    glyph: 'WON',
    render: ({ params }) =>
      `조회수 집계가 끝났어요. ${josa(won(params.amount), '을/를')} 돌려드려요.`,
  },
};
