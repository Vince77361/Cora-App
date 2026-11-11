import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';

export interface AuthUser {
  userId: string;
}

export type AuthedRequest = Request & { user?: AuthUser };

// 사용자 ID는 요청 본문이 아니라 검증된 토큰에서만 가져온다.
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthUser => {
    const user = ctx.switchToHttp().getRequest<AuthedRequest>().user;
    if (!user) throw new Error('AuthGuard를 거치지 않은 요청이에요.');
    return user;
  },
);
