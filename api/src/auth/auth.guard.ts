import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AppError } from '../common/errors/app-error';
import { securityLog } from '../common/logging/security-log';
import { AuthedRequest } from './current-user.decorator';
import { IS_PUBLIC_KEY } from './public.decorator';
import {
  AuthFailReason,
  TokenRejectedError,
  TokenVerifier,
} from './token-verifier';

const BEARER = /^Bearer ([^\s]+)$/;

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly verifier: TokenVerifier,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<AuthedRequest>();
    const match = BEARER.exec(request.headers.authorization ?? '');
    if (!match) {
      this.logFailure('MISSING');
      throw new AppError('UNAUTHENTICATED', '로그인이 필요해요.');
    }
    try {
      // 만료 시각은 HTTP 요청에서 쓰지 않으므로 사용자 ID만 요청에 싣는다.
      const { userId } = await this.verifier.verify(match[1]);
      request.user = { userId };
    } catch (e) {
      // 키 묶음 장애(INTERNAL)는 검증기가 AUTH_INFRA_FAILED로 따로 남긴다. 여기서는 401만 다룬다.
      if (e instanceof AppError && e.code === 'UNAUTHENTICATED') {
        this.logFailure(e instanceof TokenRejectedError ? e.reason : 'INVALID');
      }
      throw e;
    }
    return true;
  }

  // 토큰 원문이나 오류 메시지는 넣지 않고 분류만 남긴다.
  private logFailure(reason: AuthFailReason): void {
    securityLog('AUTH_FAILED', { result: 'DENIED', reason });
  }
}
