import { Injectable } from '@nestjs/common';
import { SkipThrottle, ThrottlerGuard } from '@nestjs/throttler';

export const RATE_LIMIT_IP = 'ip';
export const RATE_LIMIT_USER = 'user';

// 두 겹 모두 건너뛴다. 상태 확인(/health)과 PG 통지처럼 호출자가 사용자가 아니고, 제한에 걸리면 안 되는 경로에만 쓴다.
export const SkipRateLimit = () =>
  SkipThrottle({ [RATE_LIMIT_IP]: true, [RATE_LIMIT_USER]: true });

// ThrottlerGuard는 설정된 제한을 한 가드에서 모두 센다. 우리는 IP는 인증 전에, 사용자는 인증 뒤에 세야 해서
// 가드를 둘로 나누고 각자 자기 이름의 제한만 남긴다.
abstract class NamedRateLimitGuard extends ThrottlerGuard {
  protected abstract readonly limitName: string;

  async onModuleInit(): Promise<void> {
    await super.onModuleInit();
    this.throttlers = this.throttlers.filter((t) => t.name === this.limitName);
  }
}

@Injectable()
export class IpRateLimitGuard extends NamedRateLimitGuard {
  protected readonly limitName = RATE_LIMIT_IP;
}

@Injectable()
export class UserRateLimitGuard extends NamedRateLimitGuard {
  protected readonly limitName = RATE_LIMIT_USER;
}
