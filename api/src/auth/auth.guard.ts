import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AppError } from '../common/errors/app-error';
import { AuthedRequest } from './current-user.decorator';
import { IS_PUBLIC_KEY } from './public.decorator';
import { TokenVerifier } from './token-verifier';

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
      throw new AppError('UNAUTHENTICATED', '로그인이 필요해요.');
    }
    request.user = await this.verifier.verify(match[1]);
    return true;
  }
}
