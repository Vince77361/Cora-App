import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { Clock } from '../common/clock';
import {
  IpRateLimitGuard,
  UserRateLimitGuard,
} from '../common/rate-limit/rate-limit';
import { RateLimitModule } from '../common/rate-limit/rate-limit.module';
import { AuthGuard } from './auth.guard';
import { supabaseTokenVerifierFactory } from './supabase-token-verifier';
import { TokenVerifier } from './token-verifier';

@Module({
  imports: [RateLimitModule],
  providers: [
    {
      provide: TokenVerifier,
      useFactory: supabaseTokenVerifierFactory,
      inject: [ConfigService, Clock],
    },
    // 전역 가드는 같은 모듈 안에서만 적힌 순서대로 돈다(모듈 사이의 순서는 보장되지 않는다). 그래서 셋을 이 순서로 여기에 둔다:
    // IP 제한(잘못된 토큰 홍수까지 막는다) → 인증 → 사용자 제한(인증이 채운 사용자 ID로 센다).
    { provide: APP_GUARD, useClass: IpRateLimitGuard },
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_GUARD, useClass: UserRateLimitGuard },
  ],
  exports: [TokenVerifier],
})
export class AuthModule {}
