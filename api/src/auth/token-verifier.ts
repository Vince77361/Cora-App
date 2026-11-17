import { AppError } from '../common/errors/app-error';

// 보안 로그에 남기는 401 사유 분류. 토큰이나 오류 원문은 남기지 않는다.
// MISSING: Authorization 헤더가 없거나 형식이 틀림. EXPIRED: 만료. INVALID: 서명·발급자 등이 틀림.
// ANONYMOUS: 익명 로그인 토큰. DELETED_USER: 탈퇴한 사용자.
export type AuthFailReason =
  'MISSING' | 'EXPIRED' | 'INVALID' | 'ANONYMOUS' | 'DELETED_USER';

// 토큰이 틀렸다는 401. 응답은 일반 UNAUTHENTICATED와 같고, 사유는 가드가 보안 로그에만 남긴다.
export class TokenRejectedError extends AppError {
  constructor(
    readonly reason: AuthFailReason,
    message: string,
  ) {
    super('UNAUTHENTICATED', message);
    this.name = 'TokenRejectedError';
  }
}

// 검증된 토큰이 말해 주는 것. expiresAt은 Clock의 시간선 위의 만료 시각이다(실시간 게이트웨이가 만료 때 연결을 끊는다).
export interface VerifiedToken {
  userId: string;
  expiresAt: Date;
}

// DI 토큰으로 쓰려고 인터페이스가 아닌 추상 클래스로 둔다. 테스트는 이것을 가짜로 바꿔 끼운다.
// 실패하면 AppError('UNAUTHENTICATED')를 던져야 한다(사유를 알면 TokenRejectedError).
export abstract class TokenVerifier {
  abstract verify(token: string): Promise<VerifiedToken>;
}
