import {
  INestApplication,
  UnsupportedMediaTypeException,
  ValidationError,
  ValidationPipe,
} from '@nestjs/common';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { SwaggerModule } from '@nestjs/swagger';
import type { NextFunction, Request, Response } from 'express';
import helmet from 'helmet';
import { AppError } from './common/errors/app-error';
import { AllExceptionsFilter } from './common/errors/all-exceptions.filter';
import { requestIdMiddleware } from './common/request-context/request-id.middleware';
import { Env } from './config/env';
import { buildOpenApiDocument } from './openapi';

// JSON 본문의 최대 크기. 이 API의 요청은 작은 JSON뿐이고 사진은 서명된 주소로 Storage에 바로 올린다.
export const JSON_BODY_LIMIT = '100kb';
// JSON이 아닌 원문 본문을 받는 경로(서명이 받은 본문 그대로에 대한 것이라서). 새로 열 때(SMS 훅 등) 여기에 적는다.
const RAW_BODY_PATHS = ['/webhooks/payments'];
export const UNSUPPORTED_MEDIA_TYPE_MESSAGE =
  '요청은 JSON(application/json)으로 보내 주세요.';

// 본문이 있는 요청은 JSON이어야 한다. body-parser는 다른 형식을 조용히 건너뛰어 서비스가 빈 본문을 보게 되므로 미리 415로 돌려준다.
// 길이가 0인 본문은 본문이 아니다(Content-Length: 0을 보내는 클라이언트가 많다). Express의 hasBody는 이것도 본문으로 쳐서 직접 판단한다.
function hasBody(req: Request): boolean {
  return (
    req.headers['transfer-encoding'] !== undefined ||
    Number(req.headers['content-length'] ?? 0) > 0
  );
}

function requireJsonBody(req: Request, _res: Response, next: NextFunction) {
  if (
    !['GET', 'HEAD', 'OPTIONS'].includes(req.method) &&
    !RAW_BODY_PATHS.includes(req.path) &&
    hasBody(req) &&
    !req.is('application/json')
  ) {
    next(new UnsupportedMediaTypeException(UNSUPPORTED_MEDIA_TYPE_MESSAGE));
    return;
  }
  next();
}

// 중첩 DTO까지 풀어서 필드별 메시지 배열로 만든다.
function flatten(
  errors: ValidationError[],
  parent = '',
): { field: string; messages: string[] }[] {
  return errors.flatMap((e) => {
    const field = parent ? `${parent}.${e.property}` : e.property;
    const own = e.constraints
      ? [{ field, messages: Object.values(e.constraints) }]
      : [];
    return [...own, ...flatten(e.children ?? [], field)];
  });
}

// main.ts와 모든 e2e 테스트가 같은 설정을 쓰도록 한 곳에 모은다.
export function setupApp(app: INestApplication, opts: { env: Env }): void {
  const { env } = opts;
  const isProduction = env.NODE_ENV === 'production';
  const server = app.getHttpAdapter().getInstance() as {
    set(key: string, value: unknown): void;
    disable(key: string): void;
  };
  // 값이 0이면 X-Forwarded-For를 믿지 않는다. 프록시 수만큼만 믿어야 요청 IP를 속일 수 없다.
  server.set('trust proxy', env.TRUST_PROXY_HOPS);
  server.disable('x-powered-by');

  // 가장 먼저 등록한다: 본문 해석이나 가드가 실패해도 오류 응답과 로그가 같은 요청 ID를 쓰게.
  app.use(requestIdMiddleware);

  // 보안 헤더는 helmet 기본값이다. Swagger UI(개발에서만 열린다)는 인라인 스크립트가 필요해 /docs 경로에만 CSP를 끈다.
  const secure = helmet();
  const secureWithoutCsp = helmet({ contentSecurityPolicy: false });
  app.use((req: Request, res: Response, next: NextFunction) => {
    const isDocs =
      !isProduction &&
      (req.path === '/docs-json' || /^\/docs(\/|$)/.test(req.path));
    (isDocs ? secureWithoutCsp : secure)(req, res, next);
  });

  app.use(requireJsonBody);
  // Nest가 기본으로 등록하는 파서 대신 한도를 정해 둔다. rawBody 보관은 앱 옵션(rawBody: true)을 그대로 따른다.
  (app as NestExpressApplication).useBodyParser('json', {
    limit: JSON_BODY_LIMIT,
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      exceptionFactory: (errors) =>
        new AppError(
          'VALIDATION_FAILED',
          '요청 값이 올바르지 않아요.',
          flatten(errors),
        ),
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());

  // 운영에서는 API 구조를 밖에 보이지 않게 문서 경로 자체를 만들지 않는다. 문서 파일은 yarn openapi:export가 따로 만든다.
  if (!isProduction) {
    SwaggerModule.setup('docs', app, buildOpenApiDocument(app));
  }
}
