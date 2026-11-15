import { Logger } from '@nestjs/common';
import {
  createLocalJWKSet,
  errors,
  exportJWK,
  generateKeyPair,
  JWTVerifyGetKey,
  SignJWT,
} from 'jose';
import { AppError } from '../common/errors/app-error';
import { TokenRejectedError } from './token-verifier';
import { SupabaseTokenVerifier } from './supabase-token-verifier';

const SUPABASE_URL = 'https://abc.supabase.co';
const ISSUER = `${SUPABASE_URL}/auth/v1`;
const USER = '44444444-4444-4444-8444-444444444444';

describe('SupabaseTokenVerifier', () => {
  let privateKey: CryptoKey;
  let verifier: SupabaseTokenVerifier;

  beforeAll(async () => {
    const pair = await generateKeyPair('ES256');
    privateKey = pair.privateKey as CryptoKey;
    const jwk = { ...(await exportJWK(pair.publicKey)), alg: 'ES256' };
    const jwks: JWTVerifyGetKey = createLocalJWKSet({ keys: [jwk] });
    verifier = new SupabaseTokenVerifier(SUPABASE_URL, jwks);
  });

  const sign = (
    over: {
      aud?: string;
      iss?: string;
      exp?: string | number;
      sub?: string;
      key?: CryptoKey;
    } = {},
  ) =>
    new SignJWT({})
      .setProtectedHeader({ alg: 'ES256' })
      .setSubject(over.sub ?? USER)
      .setAudience(over.aud ?? 'authenticated')
      .setIssuer(over.iss ?? ISSUER)
      .setIssuedAt()
      .setExpirationTime(over.exp ?? '5m')
      .sign(over.key ?? privateKey);

  async function expectRejected(token: string): Promise<void> {
    const err: unknown = await verifier.verify(token).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(AppError);
    expect((err as AppError).code).toBe('UNAUTHENTICATED');
  }

  it('returns the user id for a valid token', async () => {
    expect(await verifier.verify(await sign())).toEqual({ userId: USER });
  });

  it('rejects a token with the wrong audience', async () => {
    await expectRejected(await sign({ aud: 'anon' }));
  });

  it('rejects a token with the wrong issuer', async () => {
    await expectRejected(await sign({ iss: 'https://evil.example/auth/v1' }));
  });

  it('rejects an expired token', async () => {
    await expectRejected(
      await sign({ exp: Math.floor(Date.now() / 1000) - 120 }),
    );
  });

  it('rejects a token whose sub is not a uuid', async () => {
    await expectRejected(await sign({ sub: 'not-a-uuid' }));
  });

  it('rejects an HS256 token', async () => {
    const hs = await new SignJWT({})
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject(USER)
      .setAudience('authenticated')
      .setIssuer(ISSUER)
      .setExpirationTime('5m')
      .sign(new TextEncoder().encode('0123456789abcdef0123456789abcdef'));
    await expectRejected(hs);
  });

  it('rejects an unsigned alg none token', async () => {
    const b64 = (o: object) =>
      Buffer.from(JSON.stringify(o)).toString('base64url');
    const token = `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
      sub: USER,
      aud: 'authenticated',
      iss: ISSUER,
      exp: Math.floor(Date.now() / 1000) + 300,
    })}.`;
    await expectRejected(token);
  });

  it('rejects garbage', async () => {
    await expectRejected('not-a-jwt');
  });

  it('rejects a token signed by a different ES256 key pair', async () => {
    const other = await generateKeyPair('ES256');
    await expectRejected(await sign({ key: other.privateKey as CryptoKey }));
  });

  it('rejects a token without an exp claim', async () => {
    const noExp = await new SignJWT({})
      .setProtectedHeader({ alg: 'ES256' })
      .setSubject(USER)
      .setAudience('authenticated')
      .setIssuer(ISSUER)
      .sign(privateKey);
    await expectRejected(noExp);
  });

  it('tells an expired token from an invalid one for the security log', async () => {
    const expired: unknown = await verifier
      .verify(await sign({ exp: Math.floor(Date.now() / 1000) - 120 }))
      .catch((e: unknown) => e);
    expect(expired).toBeInstanceOf(TokenRejectedError);
    expect((expired as TokenRejectedError).reason).toBe('EXPIRED');
    const invalid: unknown = await verifier
      .verify('not-a-jwt')
      .catch((e: unknown) => e);
    expect((invalid as TokenRejectedError).reason).toBe('INVALID');
  });

  it('rejects an anonymous token with the ANONYMOUS reason, and accepts is_anonymous false', async () => {
    const withClaim = (isAnonymous: boolean) =>
      new SignJWT({ is_anonymous: isAnonymous })
        .setProtectedHeader({ alg: 'ES256' })
        .setSubject(USER)
        .setAudience('authenticated')
        .setIssuer(ISSUER)
        .setExpirationTime('5m')
        .sign(privateKey);
    const err: unknown = await verifier
      .verify(await withClaim(true))
      .catch((e: unknown) => e);
    expect(err).toBeInstanceOf(TokenRejectedError);
    expect((err as TokenRejectedError).code).toBe('UNAUTHENTICATED');
    expect((err as TokenRejectedError).reason).toBe('ANONYMOUS');
    expect(await verifier.verify(await withClaim(false))).toEqual({
      userId: USER,
    });
  });

  describe('when the key set cannot be fetched', () => {
    let warn: jest.SpyInstance;
    beforeEach(() => {
      warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    });
    afterEach(() => warn.mockRestore());

    // 손으로 쓴 가짜: 키 묶음을 가져오다 실패한 상황을 그대로 던진다.
    const failing = (error: Error): SupabaseTokenVerifier =>
      new SupabaseTokenVerifier(SUPABASE_URL, () => Promise.reject(error));

    async function errorOf(v: SupabaseTokenVerifier): Promise<AppError> {
      const err: unknown = await v
        .verify(await sign())
        .catch((e: unknown) => e);
      expect(err).toBeInstanceOf(AppError);
      return err as AppError;
    }

    it('reports a JWKS timeout as INTERNAL, not as a bad token', async () => {
      const err = await errorOf(failing(new errors.JWKSTimeout()));
      expect(err.code).toBe('INTERNAL');
    });

    it('logs AUTH_INFRA_FAILED with the error name only', async () => {
      const error = jest.spyOn(Logger.prototype, 'error').mockImplementation();
      await errorOf(failing(new errors.JWKSTimeout()));
      const line = JSON.parse(error.mock.calls[0][0] as string) as object;
      expect(line).toMatchObject({
        event: 'AUTH_INFRA_FAILED',
        result: 'FAILED',
        reason: 'JWKSTimeout',
      });
      expect(JSON.stringify(line)).not.toContain('eyJ');
      error.mockRestore();
    });

    it('reports a network failure as INTERNAL', async () => {
      const err = await errorOf(failing(new Error('ECONNRESET')));
      expect(err.code).toBe('INTERNAL');
    });

    it('logs only the error name, never the token or the message', async () => {
      await errorOf(failing(new Error('ECONNRESET secret-detail')));
      const logged = JSON.stringify(warn.mock.calls);
      expect(logged).toContain('Error');
      expect(logged).not.toContain('secret-detail');
      expect(logged).not.toContain('eyJ');
    });

    it('keeps a missing signing key as UNAUTHENTICATED', async () => {
      const err = await errorOf(failing(new errors.JWKSNoMatchingKey()));
      expect(err.code).toBe('UNAUTHENTICATED');
    });
  });
});
