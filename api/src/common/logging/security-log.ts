import { Logger } from '@nestjs/common';
import { currentRequestContext } from '../request-context/request-context';

// 뒤 Task가 쓰는 이름까지 미리 둔다(동의 기록, 탈퇴 요청, 결제 통지 거절 등).
export type SecurityEvent =
  | 'AUTH_FAILED'
  | 'AUTH_INFRA_FAILED'
  | 'ROLE_CHANGED'
  | 'FORBIDDEN'
  | 'PAYMENT_RESULT'
  | 'PAYOUT_RESULT'
  | 'REFUND_RESULT'
  | 'WEBHOOK_REJECTED'
  | 'CONSENT_RECORDED'
  | 'ACCOUNT_DELETION_REQUESTED'
  | 'OPS_COMMAND';

export interface SecurityLogFields {
  userId?: string;
  // 대상 ID(협업 ID 등). 요청 경로를 쓸 때도 쿼리 문자열은 넣지 않는다.
  target?: string;
  // 돈이 오간 사건의 금액(원). 계좌·카드 정보는 어떤 필드에도 넣지 않는다.
  amount?: number;
  result: 'ALLOWED' | 'DENIED' | 'FAILED';
  // 분류 코드만 쓴다(EXPIRED, INVALID 같은 것). 토큰·전화번호·메시지 본문을 넣지 않는다.
  reason?: string;
}

const MAX_VALUE_LENGTH = 200;
const logger = new Logger('Security');

// 줄을 바꾸는 문자를 지워 한 사건이 항상 한 줄이 되게 한다(가짜 로그 줄을 끼워 넣는 공격 방지).
function clean(value: string | undefined): string | undefined {
  return value?.replace(/[\r\n]/g, '').slice(0, MAX_VALUE_LENGTH);
}

// 인증·권한·역할·돈 사건을 한 줄 JSON으로 남긴다. 요청 ID는 응답 헤더·오류 본문의 것과 같다.
// 출력은 앱의 Logger를 거치므로 테스트에서 끄는 방식과 로그 수준 설정이 그대로 적용된다.
export function securityLog(
  event: SecurityEvent,
  fields: SecurityLogFields,
): void {
  const context = currentRequestContext();
  const level =
    fields.result === 'FAILED'
      ? 'error'
      : fields.result === 'DENIED'
        ? 'warn'
        : 'info';
  const line = JSON.stringify({
    ts: new Date().toISOString(),
    level,
    event,
    requestId: clean(context?.requestId),
    ip: clean(context?.ip),
    userId: clean(fields.userId),
    target: clean(fields.target),
    amount: fields.amount,
    result: fields.result,
    reason: clean(fields.reason),
  });
  if (level === 'error') logger.error(line);
  else if (level === 'warn') logger.warn(line);
  else logger.log(line);
}
