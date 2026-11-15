import { ExecutionContext, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { Env } from '../../config/env';
import { RATE_LIMIT_USER, RATE_LIMIT_IP } from './rate-limit';

const MINUTE_MS = 60_000;

interface UserRequest {
  user?: { userId: string };
}

// 두 겹: IP(인증 가드보다 먼저, 잘못된 토큰 홍수까지 막는다)와 사용자(인증 가드 뒤, 사용자 ID로 센다).
// 저장소는 기본 메모리다. 서버를 여러 대로 늘리면 대수만큼 한도가 늘어나므로, 그때 Redis 저장소로 바꿔야 한다(이 Task 범위 밖).
@Module({
  imports: [
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => ({
        throttlers: [
          {
            name: RATE_LIMIT_IP,
            ttl: MINUTE_MS,
            limit: config.get('RATE_LIMIT_IP_PER_MIN', { infer: true }),
          },
          {
            name: RATE_LIMIT_USER,
            ttl: MINUTE_MS,
            limit: config.get('RATE_LIMIT_USER_PER_MIN', { infer: true }),
            // 토큰 없이 열린 경로에는 사용자가 없다. 그 경로는 IP 제한만 받는다.
            skipIf: (context: ExecutionContext) =>
              !context.switchToHttp().getRequest<UserRequest>().user,
            // 같은 IP의 다른 사용자와 세지 않도록 사용자 ID로만 센다.
            getTracker: (req: UserRequest) => `user:${req.user?.userId ?? ''}`,
          },
        ],
      }),
    }),
  ],
  exports: [ThrottlerModule],
})
export class RateLimitModule {}
