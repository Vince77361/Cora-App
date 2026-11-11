import { AppError } from '../../src/common/errors/app-error';
import { TokenVerifier } from '../../src/auth/token-verifier';

export const USER_A = '11111111-1111-4111-8111-111111111111';
export const OTHER = '22222222-2222-4222-8222-222222222222';

// 네트워크 없이 인증을 흉내 낸다. "user-a"만 통과하고 나머지는 모두 거절한다.
export class FakeTokenVerifier extends TokenVerifier {
  verify(token: string): Promise<{ userId: string }> {
    if (token === 'user-a') return Promise.resolve({ userId: USER_A });
    return Promise.reject(
      new AppError('UNAUTHENTICATED', '로그인이 필요해요.'),
    );
  }
}
