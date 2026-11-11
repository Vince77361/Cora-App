import 'reflect-metadata';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
// 다른 import보다 먼저 실행돼야 앱 모듈이 가짜 환경변수를 보므로 맨 위에 둔다.
import './openapi-placeholder-env';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { buildOpenApiDocument } from '../src/openapi';

// 키 순서를 정렬해 두 번 실행해도 같은 파일이 나오게 한다.
function sortKeys(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sortKeys);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
        .map(([k, v]) => [k, sortKeys(v)]),
    );
  }
  return value;
}

async function main() {
  // init()과 listen()을 부르지 않으므로 DB에 연결하지도 포트를 열지도 않는다.
  const app = await NestFactory.create(AppModule, { logger: false });
  const document = buildOpenApiDocument(app);
  const out = join(__dirname, '..', 'openapi.json');
  writeFileSync(out, JSON.stringify(sortKeys(document), null, 2) + '\n');
  await app.close();
}

main().then(
  () => process.exit(0),
  (error) => {
    console.error(error);
    process.exit(1);
  },
);
