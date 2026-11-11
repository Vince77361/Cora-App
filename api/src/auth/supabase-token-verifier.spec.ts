import {
  createLocalJWKSet,
  exportJWK,
  generateKeyPair,
  JWTVerifyGetKey,
  SignJWT,
} from 'jose';
import { AppError } from '../common/errors/app-error';
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
    } = {},
  ) =>
    new SignJWT({})
      .setProtectedHeader({ alg: 'ES256' })
      .setSubject(over.sub ?? USER)
      .setAudience(over.aud ?? 'authenticated')
      .setIssuer(over.iss ?? ISSUER)
      .setIssuedAt()
      .setExpirationTime(over.exp ?? '5m')
      .sign(privateKey);

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
});
