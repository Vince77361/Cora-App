import 'reflect-metadata';
import { plainToInstance, Expose, Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
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

  @Expose()
  @IsString()
  DATABASE_URL!: string;

  @Expose()
  @IsString()
  DIRECT_URL!: string;

  @Expose()
  @IsString()
  SUPABASE_URL!: string;

  // 이 프로젝트의 Supabase는 비대칭 키(ES256)로 토큰을 서명하고 JWKS로 검증하므로 필수가 아니다.
  @Expose()
  @IsOptional()
  @IsString()
  SUPABASE_JWT_SECRET?: string;

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
