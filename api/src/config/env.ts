import 'reflect-metadata';
import { plainToInstance, Expose, Transform, Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateIf,
  validateSync,
} from 'class-validator';

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
}

// process.env에는 PATH 같은 무관한 키가 많아서, Env에 선언한 키만 골라 검증한다.
export function loadEnv(raw: Record<string, unknown>): Env {
  const env = plainToInstance(Env, raw, {
    excludeExtraneousValues: true,
    enableImplicitConversion: true,
    exposeDefaultValues: true,
  });
  const errors = validateSync(env, { skipMissingProperties: false });
  if (errors.length > 0) {
    const lines = errors.map(
      (e) => `${e.property}: ${Object.values(e.constraints ?? {}).join(', ')}`,
    );
    throw new Error(`환경변수가 올바르지 않아요.\n${lines.join('\n')}`);
  }
  return env;
}
