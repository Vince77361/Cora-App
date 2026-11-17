import { josa } from '../common/josa';

// 안내 줄은 코드와 값만 저장하고 문구는 읽는 사람에 맞춰 이 함수가 만든다(Global Constraints).
// 상대에게 그만둔 이유와 차단 사실을 알리는 코드는 만들지 않는다.
export type SystemCode =
  | 'MATCHED'
  | 'OFFER_ACCEPTED'
  | 'REQUEST_ACCEPTED'
  | 'TERMS_PROPOSED'
  | 'TERMS_CONFIRMED'
  | 'TERMS_AGREED'
  | 'CREATOR_CONSENTED'
  | 'CONSENT_VOIDED'
  | 'CONTRACT_CONCLUDED'
  | 'DROPPED';

export const SYSTEM_CODES: readonly SystemCode[] = [
  'MATCHED',
  'OFFER_ACCEPTED',
  'REQUEST_ACCEPTED',
  'TERMS_PROPOSED',
  'TERMS_CONFIRMED',
  'TERMS_AGREED',
  'CREATOR_CONSENTED',
  'CONSENT_VOIDED',
  'CONTRACT_CONCLUDED',
  'DROPPED',
];

export type SystemParams = Record<string, string | number>;

export interface SystemViewer {
  userId: string;
  role: 'COMMISSIONER' | 'CREATOR';
}

// 값이 빠진 옛 줄이 있어도 던지지 않고 빈 글로 읽는다(목록 전체가 깨지지 않게).
const text = (params: SystemParams, key: string): string =>
  String(params[key] ?? '');

// 버전 번호 뒤의 을/를: "1을", "2를"처럼 숫자를 한글로 읽은 마지막 소리에 맞춘다.
const versionWithJosa = (params: SystemParams): string =>
  josa(text(params, 'version'), '을/를');

// 저장하는 값(params)의 키:
// MATCHED { commissionerName, creatorName } · OFFER_ACCEPTED { by, name } · REQUEST_ACCEPTED { name }
// TERMS_PROPOSED { name, version, proposerId } · TERMS_CONFIRMED { name, version } · TERMS_AGREED { version }
// CREATOR_CONSENTED { name } · DROPPED { droppedById }. 나머지는 값이 없다.
export function renderSystemLine(
  code: SystemCode,
  params: SystemParams,
  viewer: SystemViewer,
): string {
  switch (code) {
    case 'MATCHED': {
      const other =
        viewer.role === 'CREATOR'
          ? text(params, 'commissionerName')
          : text(params, 'creatorName');
      return `${other}님과 서로 관심이 닿았어요. 조건 버전 1이 만들어졌어요.`;
    }
    case 'OFFER_ACCEPTED':
      // 사장님이 크리에이터의 역제안을 수락한 경우는 가게 이름으로 쓴다.
      return params.by === 'COMMISSIONER'
        ? `${josa(text(params, 'name'), '이/가')} 제안을 수락했어요.`
        : `${text(params, 'name')}님이 오퍼를 수락했어요.`;
    case 'REQUEST_ACCEPTED':
      return `${text(params, 'name')}님이 대화를 수락했어요.`;
    case 'TERMS_PROPOSED':
      return params.proposerId === viewer.userId
        ? `조건 버전 ${versionWithJosa(params)} 제안했어요.`
        : `${text(params, 'name')}님이 조건 버전 ${versionWithJosa(params)} 제안했어요.`;
    case 'TERMS_CONFIRMED':
      return `${text(params, 'name')}님이 조건 버전 ${versionWithJosa(params)} 확인했어요.`;
    case 'TERMS_AGREED':
      return `양쪽이 조건 버전 ${versionWithJosa(params)} 확인했어요.`;
    case 'CREATOR_CONSENTED':
      return `${text(params, 'name')}님이 계약에 동의했어요.`;
    case 'CONSENT_VOIDED':
      return '조건이 바뀌어 계약 동의가 취소됐어요.';
    case 'CONTRACT_CONCLUDED':
      return '계약이 체결됐어요.';
    case 'DROPPED':
      return params.droppedById === viewer.userId
        ? '협의를 그만뒀어요.'
        : '이번에는 함께하기 어렵대요.';
  }
}
