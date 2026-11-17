import { Injectable } from '@nestjs/common';
import { AppError } from '../../src/common/errors/app-error';
import { Clock } from '../../src/common/clock';
import { TokenVerifier, VerifiedToken } from '../../src/auth/token-verifier';

export const USER_A = '11111111-1111-4111-8111-111111111111';
export const OTHER = '22222222-2222-4222-8222-222222222222';
// 제3자(대화방에 없는 사람)를 흉내 내는 시험용 사용자.
export const STRANGER = '33333333-3333-4333-8333-333333333333';

const HOUR_MS = 60 * 60 * 1000;
const EXPIRING_MS = 1000;

// 네트워크 없이 인증을 흉내 낸다. "user-a"와 "user-b"(협업의 양쪽 당사자를 따로 보는 시험용), "user-c"(제3자)만 통과하고 나머지는 모두 거절한다.
// "expiring:user-a"처럼 앞에 expiring:을 붙이면 1초 뒤에 만료되는 토큰이다(실시간 연결의 만료 시험용). 나머지는 1시간 뒤다.
@Injectable()
export class FakeTokenVerifier extends TokenVerifier {
  constructor(private readonly clock: Clock) {
    super();
  }

  verify(token: string): Promise<VerifiedToken> {
    const expiring = token.startsWith('expiring:');
    const name = expiring ? token.slice('expiring:'.length) : token;
    const userId = this.userOf(name);
    if (!userId) {
      return Promise.reject(
        new AppError('UNAUTHENTICATED', '로그인이 필요해요.'),
      );
    }
    const ttl = expiring ? EXPIRING_MS : HOUR_MS;
    return Promise.resolve({
      userId,
      expiresAt: new Date(this.clock.now().getTime() + ttl),
    });
  }

  private userOf(name: string): string | null {
    if (name === 'user-a') return USER_A;
    if (name === 'user-b') return OTHER;
    if (name === 'user-c') return STRANGER;
    return null;
  }
}
