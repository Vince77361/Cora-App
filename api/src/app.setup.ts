import {
  INestApplication,
  ValidationError,
  ValidationPipe,
} from '@nestjs/common';
import { SwaggerModule } from '@nestjs/swagger';
import { AppError } from './common/errors/app-error';
import { AllExceptionsFilter } from './common/errors/all-exceptions.filter';
import { buildOpenApiDocument } from './openapi';

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
export function setupApp(app: INestApplication): void {
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

  SwaggerModule.setup('docs', app, buildOpenApiDocument(app));
}
