import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { AuthGuard } from './auth.guard';
import { supabaseTokenVerifierFactory } from './supabase-token-verifier';
import { TokenVerifier } from './token-verifier';

@Module({
  providers: [
    {
      provide: TokenVerifier,
      useFactory: supabaseTokenVerifierFactory,
      inject: [ConfigService],
    },
    { provide: APP_GUARD, useClass: AuthGuard },
  ],
  exports: [TokenVerifier],
})
export class AuthModule {}
