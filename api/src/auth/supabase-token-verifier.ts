import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createRemoteJWKSet, errors, jwtVerify } from 'jose';
import type { JWTVerifyGetKey } from 'jose';
import { AppError } from '../common/errors/app-error';
import { Env } from '../config/env';
import { TokenVerifier } from './token-verifier';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// jose의 오류 메시지는 클라이언트에 보여 주지 않으려고 고정 문구만 쓴다.
const UNAUTHENTICATED_MESSAGE = '로그인이 필요해요.';
const INTERNAL_MESSAGE = '서버 오류가 발생했어요.';

// 토큰 자체가 틀렸다는 뜻의 오류만 401로 돌린다.
// 키 묶음을 받아 오지 못한 장애(JWKSTimeout, 네트워크 오류 등)까지 401로 보내면,
// 앱은 401을 "토큰이 틀림"으로 읽고 접속 중인 사용자를 모두 로그아웃시킨다.
function isTokenProblem(e: unknown): boolean {
  return (
    e instanceof errors.JWTExpired ||
    e instanceof errors.JWTClaimValidationFailed ||
    e instanceof errors.JWTInvalid ||
    e instanceof errors.JWSInvalid ||
    e instanceof errors.JWSSignatureVerificationFailed ||
    e instanceof errors.JOSEAlgNotAllowed ||
    e instanceof errors.JOSENotSupported ||
    e instanceof errors.JWKSNoMatchingKey ||
    e instanceof errors.JWKSMultipleMatchingKeys
  );
}

// Supabase 프로젝트의 JWKS(ES256 공개키)로 토큰을 검증한다.
// 공개키만 쓰므로 서버에 JWT 비밀값을 둘 필요가 없다.
@Injectable()
export class SupabaseTokenVerifier extends TokenVerifier {
  private readonly issuer: string;
  private readonly logger = new Logger(SupabaseTokenVerifier.name);

  // jwks 인자는 테스트가 네트워크 없이 로컬 키를 넣기 위한 틈이다.
  constructor(
    supabaseUrl: string,
    private readonly jwks?: JWTVerifyGetKey,
  ) {
    super();
    this.issuer = `${supabaseUrl}/auth/v1`;
    this.jwks ??= createRemoteJWKSet(
      new URL(`${supabaseUrl}/auth/v1/.well-known/jwks.json`),
    );
  }

  async verify(token: string): Promise<{ userId: string }> {
    try {
      const { payload } = await jwtVerify(token, this.jwks!, {
        audience: 'authenticated',
        issuer: this.issuer,
        // HS256과 alg none 같은 다른 알고리즘으로 위조한 토큰을 막는다.
        algorithms: ['ES256'],
        // jose는 exp가 없는 토큰도 기본으로 통과시키므로 둘 다 반드시 있어야 한다.
        requiredClaims: ['exp', 'sub'],
      });
      const sub = payload.sub;
      if (typeof sub !== 'string' || !UUID.test(sub)) {
        throw new AppError('UNAUTHENTICATED', UNAUTHENTICATED_MESSAGE);
      }
      return { userId: sub };
    } catch (e) {
      if (e instanceof AppError) throw e;
      if (isTokenProblem(e)) {
        throw new AppError('UNAUTHENTICATED', UNAUTHENTICATED_MESSAGE);
      }
      // 오류 이름만 남긴다. 메시지에는 URL 같은 값이, 토큰은 더더욱 남기지 않는다.
      this.logger.warn(
        `키 묶음 조회에 실패했어요: ${e instanceof Error ? e.name : 'unknown'}`,
      );
      throw new AppError('INTERNAL', INTERNAL_MESSAGE);
    }
  }
}

export function supabaseTokenVerifierFactory(
  config: ConfigService<Env, true>,
): SupabaseTokenVerifier {
  return new SupabaseTokenVerifier(config.get('SUPABASE_URL', { infer: true }));
}
