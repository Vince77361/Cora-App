import 'reflect-metadata';
import { plainToInstance, Expose, Transform, Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MinLength,
  Min,
  ValidateIf,
  validateSync,
} from 'class-validator';

// 운영이 아닌 곳에서는 비었거나 없으면 fake로 시작한다. 운영에서는 값을 반드시 직접 적어야 한다.
// 값을 채운 채로 Env에 넣어야 assertNoFakesInProduction이 모든 _ADAPTER 키를 계속 검사한다.
const DEV_DEFAULT_ADAPTER_KEYS = [
  'PAYMENT_ADAPTER',
  'PAYOUT_ADAPTER',
  'VIEW_COUNT_ADAPTER',
  'INSTAGRAM_ADAPTER',
  'OPERATOR_ALERT_ADAPTER',
] as const;
const BLANK_MEANS_DEFAULT_KEYS = [
  'FEE_RATE_STORE_OFFER',
  'FEE_RATE_BID',
  'FEE_RATE_BRAND_CONTRACT',
  'FAKE_CLOCK_OFFSET_DAYS',
] as const;
const DEV_DEFAULT_REDIS_URL = 'redis://127.0.0.1:6379';

const isProduction = (env: Env) => env.NODE_ENV === 'production';
// 개발·테스트에서는 비어도 되지만, 값을 적었다면 잘못된 값을 시작할 때 알아야 한다.
const isProductionOrGiven =
  (key: 'PAYOUT_ACCOUNT_KEY' | 'PAYMENT_WEBHOOK_SECRET') => (env: Env) =>
    isProduction(env) || !!env[key];

export class Env {
  @Expose()
  @IsIn(['development', 'test', 'production'])
  NODE_ENV!: 'development' | 'test' | 'production';

  @Expose()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(65535)
  PORT: number = 3000;

  // 빈 값은 연결이 시작된 뒤에야 알아보기 어려운 오류로 드러나므로 시작할 때 거부한다.
  @Expose()
  @IsString()
  @IsNotEmpty()
  DATABASE_URL!: string;

  @Expose()
  @IsString()
  @IsNotEmpty()
  DIRECT_URL!: string;

  // 끝의 /를 지운다. 남기면 토큰 issuer와 JWKS 주소가 어긋나 모든 요청이 거절된다.
  @Expose()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.replace(/\/+$/, '') : value,
  )
  @IsString()
  @IsNotEmpty()
  SUPABASE_URL!: string;

  // 이 프로젝트의 Supabase는 비대칭 키(ES256)로 토큰을 서명하고 JWKS로 검증하므로 필수가 아니다.
  @Expose()
  @IsOptional()
  @IsString()
  SUPABASE_JWT_SECRET?: string;

  // 모든 RLS를 우회하는 키라 서버 밖으로 나가면 안 된다. Storage가 쓴다.
  // 개발·테스트에서는 비어도 시작하고(Storage를 쓸 때 오류), 운영에서는 비면 시작을 거부한다.
  @Expose()
  @ValidateIf((env: Env) => env.NODE_ENV === 'production')
  @IsString()
  @IsNotEmpty()
  SUPABASE_SERVICE_ROLE_KEY?: string;

  @Expose()
  @IsIn(['fake', 'real'])
  PUSH_ADAPTER!: 'fake' | 'real';

  @Expose()
  @IsIn(['fake', 'real'])
  STORE_LINK_ADAPTER!: 'fake' | 'real';

  @Expose()
  @IsIn(['fake', 'real'])
  CONTENT_DRAFT_ADAPTER!: 'fake' | 'real';

  // 결제·송금·조회수·인스타그램·운영자 알림 어댑터. 개발에서는 값이 없으면 fake다.
  @Expose()
  @IsIn(['fake', 'real'])
  PAYMENT_ADAPTER!: 'fake' | 'real';

  @Expose()
  @IsIn(['fake', 'real'])
  PAYOUT_ADAPTER!: 'fake' | 'real';

  @Expose()
  @IsIn(['fake', 'real'])
  VIEW_COUNT_ADAPTER!: 'fake' | 'real';

  @Expose()
  @IsIn(['fake', 'real'])
  INSTAGRAM_ADAPTER!: 'fake' | 'real';

  @Expose()
  @IsIn(['fake', 'real'])
  OPERATOR_ALERT_ADAPTER!: 'fake' | 'real';

  // 작업 큐(BullMQ)가 쓰는 Redis. 운영이 아니면 로컬 Docker Redis가 기본이다.
  @Expose()
  @Transform(
    ({ value, obj }: { value: unknown; obj: Record<string, unknown> }) =>
      (value === undefined || value === '') && obj.NODE_ENV !== 'production'
        ? 'redis://127.0.0.1:6379'
        : value,
  )
  @IsString()
  @IsNotEmpty()
  REDIS_URL!: string;

  // 운영자 알림을 받을 주소. 운영에서만 필수다.
  @Expose()
  @ValidateIf(isProduction)
  @IsString()
  @IsNotEmpty()
  OPERATOR_EMAIL?: string;

  // 계좌번호 AES-256-GCM 키(32바이트 base64). 없으면 이 키가 필요한 코드가 쓰이는 순간 오류가 난다.
  @Expose()
  @ValidateIf(isProductionOrGiven('PAYOUT_ACCOUNT_KEY'))
  @IsString()
  @Matches(/^[A-Za-z0-9+/]{43}=$/, {
    message: 'PAYOUT_ACCOUNT_KEY는 32바이트를 base64로 인코딩한 값이어야 해요.',
  })
  PAYOUT_ACCOUNT_KEY?: string;

  // 결제 통지 서명(HMAC-SHA256) 비밀값. 값이 있으면 32자 이상이어야 하고, 없으면 이 값이 필요한 코드가 쓰이는 순간 오류가 난다.
  @Expose()
  @ValidateIf(isProductionOrGiven('PAYMENT_WEBHOOK_SECRET'))
  @IsString()
  @IsNotEmpty()
  @MinLength(32)
  PAYMENT_WEBHOOK_SECRET?: string;

  // 수수료율(%). 수수료는 Math.floor(상한 × 수수료율 / 100)이다.
  @Expose()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100)
  FEE_RATE_STORE_OFFER: number = 10;

  @Expose()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100)
  FEE_RATE_BID: number = 10;

  @Expose()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100)
  FEE_RATE_BRAND_CONTRACT: number = 10;

  // 수동 시험에서 시각을 며칠 앞당긴다. 개발에서만 효과가 있고, 운영에서 0이 아니면 시작을 거부한다.
  @Expose()
  @Type(() => Number)
  @IsInt()
  FAKE_CLOCK_OFFSET_DAYS: number = 0;
}

// process.env에는 PATH 같은 무관한 키가 많아서, Env에 선언한 키만 골라 검증한다.
export function loadEnv(rawInput: Record<string, unknown>): Env {
  const raw = { ...rawInput };
  // 빈 값을 Number('')가 0으로 바꾸면 "수수료 0%", "시계 0일"처럼 의도하지 않은 값이 된다. 없는 값으로 보고 기본값을 쓴다.
  for (const key of BLANK_MEANS_DEFAULT_KEYS) {
    if (raw[key] === '' || raw[key] === null) delete raw[key];
  }
  if (raw.NODE_ENV !== 'production') {
    const isEmpty = (v: unknown) => v === undefined || v === null || v === '';
    for (const key of DEV_DEFAULT_ADAPTER_KEYS) {
      if (isEmpty(raw[key])) raw[key] = 'fake';
    }
    if (isEmpty(raw.REDIS_URL)) raw.REDIS_URL = DEV_DEFAULT_REDIS_URL;
  }
  const env = plainToInstance(Env, raw, {
    excludeExtraneousValues: true,
    enableImplicitConversion: true,
    exposeDefaultValues: true,
  });
  const errors = validateSync(env, { skipMissingProperties: false });
  const lines = errors.map(
    (e) => `${e.property}: ${Object.values(e.constraints ?? {}).join(', ')}`,
  );
  // 운영에서 시각이 어긋나면 기한과 정산이 틀어지므로, 값이 0이 아니면 시작을 거부한다.
  if (env.NODE_ENV === 'production' && env.FAKE_CLOCK_OFFSET_DAYS !== 0) {
    lines.push('FAKE_CLOCK_OFFSET_DAYS: 운영에서는 0이어야 해요.');
  }
  if (lines.length > 0) {
    throw new Error(`환경변수가 올바르지 않아요.\n${lines.join('\n')}`);
  }
  return env;
}
