# Cora 공통 기반 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 빈 레포에서, 개발용 이메일로 로그인해 역할을 고르면 서버에 저장되고 역할별 빈 홈 화면으로 넘어가는 앱과 서버를 만든다. 이후 모든 기능이 올라설 뼈대다.

**Architecture:** Flutter 앱은 데이터를 NestJS API로만 읽고 쓰고, 로그인만 Supabase Auth에 직접 붙는다. NestJS는 Supabase가 발급한 토큰을 검증하고 Prisma로 Supabase PostgreSQL에 접근한다. API 계약은 Swagger에서 Dart 클라이언트를 생성해 맞춘다.

**Tech Stack:** Flutter 3.44 · Riverpod 3 · go_router · supabase_flutter / NestJS · Prisma · class-validator · Swagger · jest + supertest / Supabase(PostgreSQL, Auth) · Redis · Docker

**Spec:** `docs/superpowers/specs/2026-11-11-tech-stack-design.md`

## 이 계획의 범위

설계 문서는 서로 독립된 여러 기능 묶음을 다룬다. 한 계획에 담지 않고 아래 순서로 나눈다. 이 문서는 **1번**만 다룬다. 2번부터는 기능별 설계(화면 동작과 DB 스키마)를 먼저 쓴 뒤 각각 계획을 만든다.

| 순서 | 계획 | 기획 화면 | 목표 주차 (제안) |
|---|---|---|---|
| 1 | **공통 기반 (이 문서)** | A1 | 11/11 ~ 11/17 |
| 2 | 가게 사장님 흐름과 오퍼 | A2~A6, A9, D2 | 11/18 ~ 11/29 |
| 3 | 결제·에스크로 장부·지급 (가짜 PG) | A7, A8 | 11/30 ~ 12/6 |
| 4 | 브랜드 탐색·매칭 | 01~07, 08, D1 | 12/7 ~ 12/16 |
| 5 | 대화·조건 합의·계약 | 10~12, D3, D4 | 12/17 ~ 12/26 |
| 6 | 제작·검토·회고, 협업 원칙 | 09, 13~15, D5 | 12/27 ~ 1/2 |
| 7 | 포트폴리오·릴스·인스타그램·입찰 ("논의 중") | B1~B7 | 1/3 ~ 1/10 |
| 8 | 유입 전략 ("검토 중") | C1, C2 | 1/11 ~ 1/13 |
| 9 | 실제 연동 교체, 출시 준비 | — | 승인 나는 순서대로 |

여유 주차가 없다. 한 묶음이 밀리면 뒤가 모두 밀린다.

**이 계획에서 하지 않는 것:** CI, 서버 호스팅과 배포, 작업 큐(첫 예약 작업이 생기는 3번 계획에서 추가), 파일 업로드(2번 계획), 카카오·Apple 로그인(9번 계획).

## Global Constraints

- 지원 기기: 휴대폰만, 세로 방향만. 최소 iOS 16, Android 8(minSdk 26).
- 로컬 도구: Flutter 3.44.5 / Dart 3.12.2, Node 23.5.0, yarn 1.22.22, Docker 27.3.1.
- Supabase는 원격의 개발용 프로젝트를 쓴다. 로컬에 띄우지 않고 Supabase CLI도 쓰지 않는다. 로컬 Docker로 띄우는 것은 Redis뿐이다.
- 자동 테스트는 같은 DB의 `cora_test` 스키마에서 돈다(`TEST_DATABASE_URL`, `TEST_DIRECT_URL`, 둘 다 `?schema=cora_test`). 마이그레이션의 직접 SQL에 `public.`을 쓰지 않는다. 테스트는 인터넷 연결이 필요하다.
- 에이전트는 `api/.env`와 `app/config/dev.json`을 읽지 않는다. 값이 비어 실패하면 멈추고 소유자에게 어떤 키가 필요한지 알린다.
- 앱은 데이터를 NestJS API로만 읽고 쓴다. Supabase의 자동 생성 데이터 API를 호출하지 않는다.
- `public` 스키마의 모든 테이블에 RLS를 켜고 정책은 만들지 않는다.
- DB 연결 주소는 두 개다: 실행용 `DATABASE_URL`(풀링), 마이그레이션용 `DIRECT_URL`(직접 연결).
- 서비스 역할 키와 DB 주소는 `api/.env`에만 둔다. 앱에는 Supabase 공개 키만 넣는다. `.env` 파일은 커밋하지 않는다.
- NestJS: controller → service → repository. Prisma 호출은 repository에만. 다른 모듈의 내부 파일을 import하지 않는다.
- JSON 키는 camelCase. DB 테이블과 컬럼은 snake_case(`@map`, `@@map`).
- 오류 응답 형식: `{ "error": { "code": string, "message": string, "details": unknown } }`.
- 오류 코드: `VALIDATION_FAILED`(400), `UNAUTHENTICATED`(401), `FORBIDDEN`(403), `NOT_FOUND`(404), `CONFLICT`(409), `INTERNAL`(500).
- Flutter: `lib/features/<feature>/{data,domain,presentation/{pages,viewmodels}}` + `lib/core/`. 의존 방향 `presentation → domain ← data`.
- ViewModel은 Riverpod `AsyncNotifier`, 이름 `*ViewModel`, 파일 `*_view_model.dart`. `@riverpod` 코드 생성, freezed, build_runner를 쓰지 않는다.
- 저장소 provider는 기본값이 `throw UnimplementedError`이고 `main.dart`에서 override한다.
- 테스트는 손으로 쓴 `Fake*` 구현을 쓴다. mockito와 jest mock 남용을 피한다. 테스트 이름은 영어 문장.
- 가짜 연동 구현은 이름이 `Fake`로 시작한다. `NODE_ENV=production`에서 가짜가 선택되면 서버가 시작을 거부한다.
- 로그인은 E1·E2 화면(2026-11-11 소유자 결정). 인증은 `AUTH_ADAPTER` 포트 뒤 가짜 구현으로 시작하고, 운영 빌드(`CORA_ENV=prod`)에서 가짜면 앱이 시작을 거부한다.
- 화면 문구는 기획 캔버스의 문구를 그대로 쓴다.
- 커밋: 한국어 conventional commit(`feat:`, `fix:`, `docs:`, `chore:`), 한 커밋에 한 목적. 작업 브랜치를 만들지 않고 `main`에 바로 커밋한다. 커밋마다 테스트가 통과한 상태여야 한다. push는 소유자 확인 후에만 한다.
- 코드 주석은 한국어로, "왜"를 설명한다.

## Review Focus

테스트가 없으면 놓치기 쉬운 조건들이다. 각 줄의 테스트는 표시한 작업에 들어 있다.

1. **토큰이 만료된 채 API를 호출함** → 앱이 멈추지 않고 로그인 화면으로 돌아간다. (Task 9)
2. **앱을 켰는데 서버에 닿지 않음** → 빈 화면이 아니라 오류 문구와 "다시 시도" 버튼이 보인다. (Task 10)
3. **시스템 글자 크기를 1.3배로 키움** → 역할 선택 화면에서 글자가 잘리거나 넘치지 않는다. (Task 10)
4. **허용되지 않은 필드나 역할 값을 보냄** → 서버가 400 `VALIDATION_FAILED`로 거절하고 DB는 바뀌지 않는다. (Task 4)
5. **새 테이블을 추가하면서 RLS를 켜지 않음** → 테스트가 실패해 알려 준다. (Task 3)

---

## 파일 구조

```text
Cora-App/
├── .gitignore
├── README.md
├── docker-compose.yml                  # Redis
├── scripts/gen-api.sh                  # OpenAPI → Dart 클라이언트
├── api/
│   ├── .env.example
│   ├── prisma/schema.prisma
│   ├── openapi.json                    # 생성물, 커밋함
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   ├── app.setup.ts                # 파이프·필터·Swagger (main과 e2e가 공유)
│   │   ├── config/env.ts               # 환경변수 검증
│   │   ├── common/errors/              # AppError, 전역 예외 필터
│   │   ├── prisma/                     # PrismaModule, PrismaService
│   │   ├── health/
│   │   ├── auth/                       # TokenVerifier 포트, 가드, 데코레이터
│   │   ├── users/                      # /me
│   │   └── integrations/               # 포트, 가짜 구현, 운영 차단
│   └── test/                           # e2e, DB 통합 테스트
└── app/
    ├── packages/cora_api/              # 생성된 Dart 클라이언트, 커밋함
    ├── assets/fonts/                   # Noto Sans KR
    ├── lib/
    │   ├── main.dart
    │   ├── app.dart
    │   ├── core/
    │   │   ├── config/app_config.dart
    │   │   ├── theme/                  # 색, 글꼴, 모양, 그림자, ThemeData
    │   │   ├── ui/                     # 공용 위젯
    │   │   ├── navigation/             # 라우터, 전환
    │   │   └── network/                # API 클라이언트 조립
    │   └── features/
    │       ├── auth/
    │       ├── onboarding/             # 역할 선택 (A1)
    │       └── dev/                    # 모션 갤러리 (개발 전용)
    └── test/                           # lib/ 구조를 그대로 따름
```

---

### Task 1: 레포 뼈대와 개발 환경

**Files:**
- Create: `.gitignore`(이미 있으면 항목 추가), `README.md`, `docker-compose.yml`, `api/.env.example`, `app/config/dev.example.json`, `CLAUDE.md`(이미 있으면 그대로 둔다)

**Interfaces:**
- Produces:
  - Redis `127.0.0.1:6379` (로컬 Docker)
  - 원격 Supabase 개발용 프로젝트. 연결 값은 `api/.env`에 있다: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `DATABASE_URL`(풀링 주소), `DIRECT_URL`(직접 연결), `TEST_DATABASE_URL`, `TEST_DIRECT_URL`(위 두 주소에 `?schema=cora_test`를 붙인 것)
  - `app/config/dev.json`: `{ "CORA_ENV": "dev", "SUPABASE_URL": "…", "SUPABASE_ANON_KEY": "…", "API_BASE_URL": "http://127.0.0.1:3000" }`. `flutter run --dart-define-from-file=config/dev.json`으로 쓴다.

- [ ] **Step 1: 시작 상태 확인**

`main`에서 작업한다. 브랜치를 만들지 않는다. 설계 문서와 이 계획 문서가 `main`에 커밋돼 있고 작업 트리가 깨끗한지 확인한다. 아니면 멈추고 소유자에게 알린다.

Run: `git switch main && git status --short && git log --oneline -- docs | head -3`
Expected: 작업 트리 변경 없음, 문서 커밋이 보임

- [ ] **Step 2: `.gitignore` 작성**

포함할 항목: `.omc/`, `.superpowers/`, `.env`, `.env.*`(단 `!.env.example`), `app/config/*.json`(단 `!app/config/*.example.json`), `node_modules/`, `dist/`, `.DS_Store`.

- [ ] **Step 3: `docker-compose.yml` 작성**

서비스 하나: `redis`, 이미지 `redis:7-alpine`, 포트 `6379:6379`.

- [ ] **Step 4: 설정 예시 파일 작성**

`api/.env.example`: 위 여섯 키와 `NODE_ENV=development`, `PORT=3000`, `PUSH_ADAPTER=fake`를 값 없이(또는 형식을 보여 주는 가짜 값으로) 적고, 각 값을 Supabase 대시보드의 어디에서 찾는지 한국어 주석으로 단다.
`app/config/dev.example.json`: 키 네 개와 가짜 값.

- [ ] **Step 5: `README.md` 작성**

담을 내용: 프로젝트 한 줄 설명, 폴더 구조, 설계 문서와 계획 문서 위치, 그리고 "개발 환경 준비":
1. Supabase 대시보드에서 개발용 프로젝트를 만든다(지역: 서울).
2. Authentication → 이메일 로그인의 "Confirm email"을 끈다(개발용 로그인에 메일 인증을 요구하지 않기 위해).
3. `api/.env.example`을 `api/.env`로 복사해 값을 채운다. `app/config/dev.example.json`을 `app/config/dev.json`으로 복사해 값을 채운다.
4. `docker compose up -d`.
이 프로젝트는 로컬에 Supabase를 띄우지 않는다는 것과, 테스트가 `cora_test` 스키마에서 돈다는 것도 적는다.

- [ ] **Step 6: 소유자 준비 확인 (멈추는 지점)**

소유자에게 README의 1~3을 마쳤는지 묻는다. **마쳤다는 답을 받기 전에는 Task 2로 넘어가지 않는다.** 에이전트는 `api/.env`와 `app/config/dev.json`을 열지 않는다.

- [ ] **Step 7: 실행 확인**

Run: `docker compose up -d && docker compose exec redis redis-cli ping`
Expected: `PONG`

Run: `test -f api/.env && test -f app/config/dev.json && echo ok`
Expected: `ok` (파일이 있는지만 본다. 내용은 Task 3에서 DB 연결로 확인한다.)

- [ ] **Step 8: Commit**

```bash
git add .gitignore README.md docker-compose.yml api/.env.example app/config/dev.example.json
git commit -m "chore: 레포 뼈대와 개발 환경 추가"
```

---

### Task 2: API 뼈대 — 검증, 오류 형식, Swagger, health

**Files:**
- Create: `api/` (Nest 프로젝트), `api/.env.example`, `api/src/config/env.ts`, `api/src/app.setup.ts`, `api/src/common/errors/app-error.ts`, `api/src/common/errors/all-exceptions.filter.ts`, `api/src/health/health.module.ts`, `api/src/health/health.controller.ts`
- Test: `api/test/health.e2e-spec.ts`, `api/test/errors.e2e-spec.ts`, `api/src/config/env.spec.ts`

**Interfaces:**
- Produces:
  - `setupApp(app: INestApplication): void` — 전역 파이프, 예외 필터, Swagger를 붙인다. `main.ts`와 모든 e2e 테스트가 호출한다.
  - `class AppError extends Error { constructor(code: ErrorCode, message: string, details?: unknown) }`
  - `type ErrorCode = 'VALIDATION_FAILED' | 'UNAUTHENTICATED' | 'FORBIDDEN' | 'NOT_FOUND' | 'CONFLICT' | 'INTERNAL'`
  - `loadEnv(raw: Record<string, unknown>): Env` — 검증 실패 시 throw
  - `Env` 필드: `NODE_ENV: 'development' | 'test' | 'production'`, `PORT: number`(기본 3000), `DATABASE_URL`, `DIRECT_URL`, `SUPABASE_URL`, `SUPABASE_JWT_SECRET?`, `PUSH_ADAPTER: 'fake' | 'real'`
  - `GET /health` → 200 `{ "status": "ok" }`, 인증 불필요
  - Swagger UI `GET /docs`, 문서 `GET /docs-json`

- [ ] **Step 1: Nest 프로젝트 생성**

Run: `npx @nestjs/cli new api --package-manager yarn --strict --skip-git`
추가 설치: `@nestjs/config`, `@nestjs/swagger`, `class-validator`, `class-transformer`.
생성된 예제 `app.controller.ts`, `app.service.ts`와 그 테스트는 지운다.

- [ ] **Step 2: 실패하는 테스트 작성**

`api/src/config/env.spec.ts`:

```ts
it('rejects a missing DATABASE_URL', () => {
  expect(() => loadEnv({ ...valid, DATABASE_URL: undefined })).toThrow(/DATABASE_URL/);
});
it('defaults PORT to 3000', () => {
  expect(loadEnv({ ...valid, PORT: undefined }).PORT).toBe(3000);
});
it('rejects an unknown PUSH_ADAPTER', () => {
  expect(() => loadEnv({ ...valid, PUSH_ADAPTER: 'mock' })).toThrow(/PUSH_ADAPTER/);
});
```

`api/test/health.e2e-spec.ts`:

```ts
it('GET /health returns ok without a token', async () => {
  await request(app.getHttpServer()).get('/health').expect(200, { status: 'ok' });
});
it('serves the OpenAPI document', async () => {
  const res = await request(app.getHttpServer()).get('/docs-json').expect(200);
  expect(res.body.paths['/health']).toBeDefined();
});
```

`api/test/errors.e2e-spec.ts`:

```ts
it('wraps an unknown route in the error envelope', async () => {
  const res = await request(app.getHttpServer()).get('/nope').expect(404);
  expect(res.body).toEqual({ error: { code: 'NOT_FOUND', message: expect.any(String), details: null } });
});
it('hides internal error messages', async () => {
  // 테스트 전용 컨트롤러가 new Error('db password leaked')를 던진다
  const res = await request(app.getHttpServer()).get('/__test/boom').expect(500);
  expect(res.body.error.code).toBe('INTERNAL');
  expect(JSON.stringify(res.body)).not.toContain('leaked');
});
```

- [ ] **Step 3: 실패 확인**

Run: `cd api && yarn test && yarn test:e2e`
Expected: FAIL — `loadEnv`, `setupApp`이 없음

- [ ] **Step 4: 구현**

- `loadEnv`: class-validator로 `Env` 클래스를 검증한다.
- `setupApp`: `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`. 검증 실패는 `AppError('VALIDATION_FAILED', ...)`로 바꾸고 `details`에 필드별 메시지 배열을 넣는다.
- `AllExceptionsFilter`: `AppError`와 Nest `HttpException`을 오류 형식으로 바꾼다. 그 밖의 예외는 500 `INTERNAL`에 고정 문구 `"서버 오류가 발생했어요."`를 쓰고 원래 메시지는 서버 로그에만 남긴다. `details`가 없으면 `null`.
- `api/.env.example`: Task 1에서 만든 파일에 `Env`의 나머지 키를 더한다.

- [ ] **Step 5: 통과 확인**

Run: `cd api && yarn lint && yarn test && yarn test:e2e`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add api
git commit -m "feat: API 뼈대와 오류 형식, Swagger, health 추가"
```

---

### Task 3: Prisma와 Supabase DB, RLS 감시 테스트

**Files:**
- Create: `api/prisma/schema.prisma`, `api/prisma/migrations/<timestamp>_init/migration.sql`, `api/src/prisma/prisma.module.ts`, `api/src/prisma/prisma.service.ts`
- Test: `api/test/db/rls.db-spec.ts`

**Interfaces:**
- Consumes: `Env.DATABASE_URL`, `Env.DIRECT_URL` (Task 2)
- Produces:
  - `PrismaModule`(전역)이 `PrismaService extends PrismaClient`를 export
  - `enum UserRole { STORE, BRAND, CREATOR }`
  - `model User { id: String @id @db.Uuid; role: UserRole?; createdAt; updatedAt; deletedAt: DateTime? }` → 테이블 `users`, 컬럼 `created_at`, `updated_at`, `deleted_at`
  - `User.id`는 Supabase Auth 사용자 ID와 같은 값이다
  - 스크립트 `yarn test:db` — `*.db-spec.ts`만 실행. 실행 전에 `TEST_DIRECT_URL`로 `prisma migrate deploy`를 돌려 `cora_test` 스키마를 최신으로 맞추고, 테스트마다 그 스키마의 테이블을 비운다. `yarn test:e2e`도 같은 스키마를 쓴다.
  - RLS 감시 테스트는 `current_schema()`의 테이블을 본다(`public`을 글자로 박지 않는다). 개발 DB의 `public`은 `yarn check:rls`(같은 쿼리를 `DATABASE_URL`로 실행하는 스크립트)로 확인한다. 마이그레이션을 개발 DB에 적용한 뒤 이 스크립트를 돌린다.

- [ ] **Step 1: 실패하는 테스트 작성**

`api/test/db/rls.db-spec.ts`:

```ts
it('has row level security enabled on every table in the public schema', async () => {
  const rows = await prisma.$queryRaw<{ relname: string }[]>`
    SELECT c.relname FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity = false`;
  expect(rows.map((r) => r.relname)).toEqual([]);
});
it('has no RLS policies in the public schema', async () => {
  const rows = await prisma.$queryRaw<{ n: bigint }[]>`
    SELECT count(*) AS n FROM pg_policies WHERE schemaname = 'public'`;
  expect(Number(rows[0].n)).toBe(0);
});
```

- [ ] **Step 2: 스키마와 마이그레이션 작성**

`schema.prisma`의 datasource에 `url = env("DATABASE_URL")`, `directUrl = env("DIRECT_URL")`.
Run: `cd api && yarn prisma migrate dev --name init --create-only`
생성된 `migration.sql` 끝에 추가:

```sql
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "_prisma_migrations" ENABLE ROW LEVEL SECURITY;
```

- [ ] **Step 3: 실패 확인 (마이그레이션 적용 전)**

Run: `cd api && yarn test:db`
Expected: FAIL — `users` 테이블이 없거나 RLS가 꺼진 테이블이 나열됨

- [ ] **Step 4: 마이그레이션 적용, `PrismaModule` 구현**

Run: `cd api && yarn prisma migrate dev`

- [ ] **Step 5: 통과 확인**

Run: `cd api && yarn test:db`
Expected: PASS

- [ ] **Step 6: README에 규칙 추가**

"테이블을 추가하는 마이그레이션에는 `ENABLE ROW LEVEL SECURITY`를 반드시 넣는다. 빠뜨리면 `yarn test:db`가 실패한다."

- [ ] **Step 7: Commit**

```bash
git add api README.md
git commit -m "feat: Prisma 스키마와 users 테이블, RLS 감시 테스트 추가"
```

---

### Task 4: 인증 가드와 `/me`

**Files:**
- Create: `api/src/auth/auth.module.ts`, `api/src/auth/token-verifier.ts`, `api/src/auth/supabase-token-verifier.ts`, `api/src/auth/auth.guard.ts`, `api/src/auth/public.decorator.ts`, `api/src/auth/current-user.decorator.ts`, `api/src/users/users.module.ts`, `api/src/users/users.controller.ts`, `api/src/users/users.service.ts`, `api/src/users/users.repository.ts`, `api/src/users/dto/update-role.dto.ts`, `api/src/users/dto/me.model.ts`
- Modify: `api/src/health/health.controller.ts` (`@Public()` 추가)
- Test: `api/src/users/users.service.spec.ts`, `api/test/me.e2e-spec.ts`, `api/test/db/users.repository.db-spec.ts`, `api/test/support/fake-token-verifier.ts`

**Interfaces:**
- Consumes: `PrismaService`, `UserRole` (Task 3), `AppError` (Task 2)
- Produces:
  - `abstract class TokenVerifier { abstract verify(token: string): Promise<{ userId: string }> }` — 실패 시 `AppError('UNAUTHENTICATED', ...)`
  - `AuthGuard` — 전역 가드. `Authorization: Bearer <token>`을 검증하고 `request.user = { userId }`를 넣는다.
  - `@Public()` — 가드를 건너뛴다. `@CurrentUser()` — `{ userId: string }`을 주입한다.
  - `GET /me` → 200 `MeModel { id: string; role: 'STORE' | 'BRAND' | 'CREATOR' | null }`. 사용자 행이 없으면 만든다.
  - `PATCH /me/role` 본문 `{ role: 'STORE' | 'BRAND' | 'CREATOR' }` → 200 `MeModel`. 이미 역할이 있어도 바꿀 수 있다(기획: "나중에 바꿀 수 있어요").
  - `UsersRepository.findById(id): Promise<User | null>`, `upsert(id): Promise<User>`, `updateRole(id, role): Promise<User>`

- [ ] **Step 1: 실패하는 테스트 작성**

`api/test/me.e2e-spec.ts` (`TokenVerifier`를 `FakeTokenVerifier`로 override. 토큰 `"user-a"`는 고정 UUID로 통과, `"expired"`는 거절):

```ts
it('rejects a request with no token', async () => {
  const res = await request(server).get('/me').expect(401);
  expect(res.body.error.code).toBe('UNAUTHENTICATED');
});
it('rejects an expired token', async () => {
  await request(server).get('/me').set('Authorization', 'Bearer expired').expect(401);
});
it('creates the user on first call with a null role', async () => {
  const res = await request(server).get('/me').set(auth).expect(200);
  expect(res.body).toEqual({ id: USER_A, role: null });
});
it('saves the chosen role', async () => {
  await request(server).patch('/me/role').set(auth).send({ role: 'STORE' }).expect(200, { id: USER_A, role: 'STORE' });
  await request(server).get('/me').set(auth).expect(200, { id: USER_A, role: 'STORE' });
});
it('lets the user change role later', async () => {
  await request(server).patch('/me/role').set(auth).send({ role: 'CREATOR' }).expect(200, { id: USER_A, role: 'CREATOR' });
});
it('rejects an unknown role and leaves the stored role unchanged', async () => {
  const res = await request(server).patch('/me/role').set(auth).send({ role: 'ADMIN' }).expect(400);
  expect(res.body.error.code).toBe('VALIDATION_FAILED');
  await request(server).get('/me').set(auth).expect(200, { id: USER_A, role: 'CREATOR' });
});
it('rejects fields that are not in the DTO', async () => {
  await request(server).patch('/me/role').set(auth).send({ role: 'STORE', id: OTHER }).expect(400);
});
it('still serves /health without a token', async () => {
  await request(server).get('/health').expect(200);
});
```

`users.service.spec.ts`는 손으로 쓴 `FakeUsersRepository`로 같은 규칙(없으면 생성, 역할 변경)을 검증한다. `users.repository.db-spec.ts`는 실제 DB로 `upsert`가 두 번 호출돼도 행이 하나임을 검증한다.

- [ ] **Step 2: 실패 확인**

Run: `cd api && yarn test && yarn test:e2e && yarn test:db`
Expected: FAIL — `/me`가 404

- [ ] **Step 3: 개발용 프로젝트의 토큰 서명 방식 확인**

프로젝트 주소는 공개 값이므로 소유자에게 물어 받는다(`.env`를 열지 않는다).

Run: `curl -s <SUPABASE_URL>/auth/v1/.well-known/jwks.json`
- `keys` 배열에 키가 있으면: `SupabaseTokenVerifier`는 `jose`의 `createRemoteJWKSet`으로 `${SUPABASE_URL}/auth/v1/.well-known/jwks.json`을 사용한다.
- 비어 있거나 404이면: `jose`의 `jwtVerify`에 `SUPABASE_JWT_SECRET`(HS256)을 사용하고, 이 값이 없으면 시작 시 throw한다.

두 경우 모두 `aud`가 `authenticated`인지 확인하고 `sub`를 `userId`로 쓴다. 어느 쪽을 썼는지 README에 한 줄 남긴다.

- [ ] **Step 4: 가드, 데코레이터, users 모듈 구현**

controller는 service만, service는 repository만 주입받는다. `MeModel`은 Prisma 모델을 그대로 내보내지 않고 `id`, `role`만 담는다.

- [ ] **Step 5: 통과 확인**

Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
Expected: PASS

- [ ] **Step 6: 실제 토큰으로 수동 확인**

이 단계는 소유자가 한다(공개 키가 필요하다). README에 방법을 적는다: 개발용 프로젝트에 이메일로 가입(`POST <SUPABASE_URL>/auth/v1/signup`, 헤더 `apikey: <공개 키>`)해 받은 `access_token`으로 `curl -H "Authorization: Bearer <token>" localhost:3000/me`. 소유자가 결과를 알려 주면 다음으로 넘어간다.
Expected: `{"id":"<uuid>","role":null}`

- [ ] **Step 7: Commit**

```bash
git add api README.md
git commit -m "feat: Supabase 토큰 인증 가드와 /me, 역할 저장 추가"
```

---

### Task 5: 외부 연동 포트 장치와 운영 차단

**Files:**
- Create: `api/src/integrations/integrations.module.ts`, `api/src/integrations/push/push.port.ts`, `api/src/integrations/push/fake-push.adapter.ts`, `api/src/integrations/assert-no-fakes.ts`
- Modify: `api/src/main.ts`
- Test: `api/src/integrations/assert-no-fakes.spec.ts`, `api/src/integrations/integrations.module.spec.ts`

**Interfaces:**
- Consumes: `Env` (Task 2)
- Produces:
  - `abstract class PushPort { abstract send(input: { userId: string; title: string; body: string }): Promise<void> }`
  - `class FakePushAdapter extends PushPort` — 로그만 남긴다
  - `IntegrationsModule` — `Env.PUSH_ADAPTER`에 따라 `PushPort` 구현을 고른다. `'real'`은 아직 없으므로 `AppError('INTERNAL', ...)`를 던지는 팩토리로 둔다.
  - `assertNoFakesInProduction(env: Env): void` — 이름이 `_ADAPTER`로 끝나는 모든 키를 검사한다. 이후 계획에서 연동을 추가할 때 `Env`에 `<NAME>_ADAPTER` 키만 추가하면 자동으로 검사된다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('throws in production when any adapter is fake', () => {
  expect(() => assertNoFakesInProduction({ ...env, NODE_ENV: 'production', PUSH_ADAPTER: 'fake' }))
    .toThrow(/PUSH_ADAPTER/);
});
it('allows fake adapters in development and test', () => {
  expect(() => assertNoFakesInProduction({ ...env, NODE_ENV: 'development', PUSH_ADAPTER: 'fake' })).not.toThrow();
});
it('allows production when every adapter is real', () => {
  expect(() => assertNoFakesInProduction({ ...env, NODE_ENV: 'production', PUSH_ADAPTER: 'real' })).not.toThrow();
});
it('provides FakePushAdapter when PUSH_ADAPTER is fake', async () => {
  expect(moduleRef.get(PushPort)).toBeInstanceOf(FakePushAdapter);
});
```

- [ ] **Step 2: 실패 확인**

Run: `cd api && yarn test integrations`
Expected: FAIL

- [ ] **Step 3: 구현**

`main.ts`는 `NestFactory.create` 전에 `assertNoFakesInProduction(loadEnv(process.env))`을 호출한다.

- [ ] **Step 4: 통과 확인**

Run: `cd api && yarn test integrations`
Expected: PASS

Run: `cd api && yarn build && NODE_ENV=production PUSH_ADAPTER=fake node dist/main.js`
Expected: `PUSH_ADAPTER`를 언급하는 오류와 함께 0이 아닌 종료 코드

- [ ] **Step 5: Commit**

```bash
git add api
git commit -m "feat: 외부 연동 포트 장치와 운영 환경 가짜 구현 차단 추가"
```

---

### Task 6: OpenAPI → Dart 클라이언트 생성

**Files:**
- Create: `api/scripts/export-openapi.ts`, `api/openapi.json`, `scripts/gen-api.sh`, `app/packages/cora_api/` (생성물)
- Modify: `api/package.json` (`openapi:export` 스크립트), `README.md`

**Interfaces:**
- Consumes: `setupApp` (Task 2), `/me` 엔드포인트 (Task 4)
- Produces:
  - `yarn openapi:export` — 서버를 띄우지 않고 `api/openapi.json`을 쓴다
  - `scripts/gen-api.sh` — export 후 Docker 이미지 `openapitools/openapi-generator-cli`의 `dart` 생성기로 `app/packages/cora_api`를 만든다. 패키지 이름 `cora_api`.
  - Dart 패키지 `cora_api` — `/me`, `/me/role`, `/health` 호출 클래스와 모델
  - controller에 `operationId`를 명시한다: `getMe`, `updateMyRole`, `getHealth`

- [ ] **Step 1: `operationId`와 응답 타입 데코레이터 추가**

`@ApiOperation({ operationId })`, `@ApiOkResponse({ type })`, `@ApiBearerAuth()`를 Task 2, 4의 controller에 붙인다.

- [ ] **Step 2: export 스크립트와 생성 스크립트 작성**

`gen-api.sh`는 Docker 이미지 태그를 고정한다(`latest` 금지). 생성 전에 `app/packages/cora_api`를 지우고 다시 만든다.

- [ ] **Step 3: 생성하고 확인**

Run: `./scripts/gen-api.sh && cd app/packages/cora_api && dart pub get && dart analyze`
Expected: `No issues found` (생성 코드의 경고가 나오면 생성기 옵션으로 해결하고, 생성물을 손으로 고치지 않는다)

- [ ] **Step 4: 재생성이 안정적인지 확인**

Run: `./scripts/gen-api.sh && git status --short app/packages/cora_api api/openapi.json`
Expected: 변경 없음 (두 번째 실행에서 차이가 나오지 않아야 함)

- [ ] **Step 5: README에 규칙 추가**

"API를 바꾸면 `./scripts/gen-api.sh`를 실행하고 생성물을 같은 커밋에 넣는다. `app/packages/cora_api`는 손으로 고치지 않는다."

- [ ] **Step 6: Commit**

```bash
git add api scripts app/packages/cora_api README.md
git commit -m "feat: OpenAPI 문서에서 Dart API 클라이언트 생성 추가"
```

---

### Task 7: Flutter 앱 뼈대와 디자인 토큰

**Files:**
- Create: `app/` (Flutter 프로젝트), `app/lib/app.dart`, `app/lib/core/config/app_config.dart`, `app/lib/core/theme/cora_colors.dart`, `app/lib/core/theme/cora_text_styles.dart`, `app/lib/core/theme/cora_shapes.dart`, `app/lib/core/theme/cora_shadows.dart`, `app/lib/core/theme/cora_theme.dart`, `app/assets/fonts/NotoSansKR-*.ttf`
- Test: `app/test/core/theme/cora_colors_test.dart`, `app/test/core/config/app_config_test.dart`

**Interfaces:**
- Produces:
  - `class AppConfig { final CoraEnv env; final String supabaseUrl; final String supabaseAnonKey; final String apiBaseUrl; factory AppConfig.fromEnvironment(); bool get isDev; }` — `--dart-define`의 `CORA_ENV`(`dev` | `prod`), `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`을 읽는다. `enum CoraEnv { dev, prod }`
  - `class CoraColors extends ThemeExtension<CoraColors>` — 필드: `background`, `text`, `textSecondary`, `accent`, `onAccent`, `surface`, `surfaceSelected`, `onSurfaceSelected`, `surfaceMuted`, `line`, `primaryAction`, `onPrimaryAction`, `selectionDot`, `onSelectionDot`. 정적 값 `CoraColors.light`, `CoraColors.dark`.
  - `extension CoraThemeX on BuildContext { CoraColors get colors; }`
  - `CoraRadius`: `sm = 14`, `md = 16`, `lg = 18`, `xl = 24`, `xxl = 28`, `pill = 999`
  - `CoraShadows`: `card`, `floating`, `sheet`
  - `CoraTextStyles`: `display`, `title`, `heading`, `bodyLarge`, `body`, `label`, `caption`, `button`
  - `ThemeData coraLightTheme`, `ThemeData coraDarkTheme`

- [ ] **Step 1: Flutter 프로젝트 생성**

Run: `flutter create app --org com.cora --project-name cora --platforms ios,android`
(번들 ID는 `com.cora.cora`가 된다. 소유자가 다른 ID를 정하면 이 단계에서 바꾼다.)
- iOS 최소 버전 16.0, Android `minSdk = 26`.
- 세로 방향 고정(iOS `Info.plist`, Android manifest).
- 의존성: `flutter_riverpod`, `go_router`, `supabase_flutter`, 로컬 패키지 `cora_api`(path).
- `flutter_lints` 유지.
- Noto Sans KR 400, 500, 700, 900을 `assets/fonts/`에 넣고 `pubspec.yaml`에 family `NotoSansKR`로 등록한다. 실행 중에 글꼴을 내려받지 않는다.

- [ ] **Step 2: 실패하는 테스트 작성**

`cora_colors_test.dart` — 기획 캔버스의 확정값:

```dart
test('light palette matches the design canvas', () {
  const c = CoraColors.light;
  expect(c.background, const Color(0xFFFFFFFF));
  expect(c.text, const Color(0xFF17181C));
  expect(c.textSecondary, const Color(0xFF5C6068));
  expect(c.accent, const Color(0xFFC6FF3D));
  expect(c.onAccent, const Color(0xFF1F2A00));
  expect(c.surface, const Color(0xFFF8F9FA));
  expect(c.surfaceSelected, const Color(0xFFE3E5E9));
  expect(c.onSurfaceSelected, const Color(0xFF17181C));
  expect(c.surfaceMuted, const Color(0xFFF2F3F5));
  expect(c.line, const Color(0xFFE6E8EB));
  expect(c.primaryAction, const Color(0xFFC6FF3D));
  expect(c.onPrimaryAction, const Color(0xFF1F2A00));
  expect(c.selectionDot, const Color(0xFFC6FF3D));
  expect(c.onSelectionDot, const Color(0xFF1F2A00));
});
test('dark palette matches the design canvas', () {
  const c = CoraColors.dark;
  expect(c.background, const Color(0xFF0F1012));
  expect(c.text, const Color(0xFFF2F3F5));
  expect(c.textSecondary, const Color(0xFFA0A4AD));
  expect(c.accent, const Color(0xFFC6FF3D));
  expect(c.surfaceSelected, const Color(0xFFF2F3F5));
  expect(c.onSurfaceSelected, const Color(0xFF0F1012));
  expect(c.line, const Color(0xFF2A2D33));
  expect(c.primaryAction, const Color(0xFFF2F3F5));
  expect(c.onPrimaryAction, const Color(0xFF17181C));
  expect(c.selectionDot, const Color(0xFF0F1012));
  expect(c.onSelectionDot, const Color(0xFFF2F3F5));
});
```

`app_config_test.dart`: `AppConfig`를 직접 생성해 `isDev`가 `CoraEnv.dev`에서만 참임을 검증한다.

- [ ] **Step 3: 실패 확인**

Run: `cd app && flutter test`
Expected: FAIL — `CoraColors`가 없음

- [ ] **Step 4: 토큰 구현**

위 테스트에 없는 다크 값(`surface`, `surfaceMuted`, `onAccent`)은 기획 캔버스의 `DarkPrinciples`, `DarkNEscrow`, `DarkNStoreHome` 화면에서 같은 자리의 색을 읽어 채우고, 읽은 값을 테스트에 추가한다.

글자 스타일(크기 / 굵기 / 자간 / 줄 높이):

| 이름 | 값 | 캔버스 출처 |
|---|---|---|
| `display` | 32 / 900 / -0.05em / 1.25 | A1 제목 |
| `title` | 26 / 900 / -0.045em / 1.3 | 09 질문 제목 |
| `heading` | 19 / 700 / -0.02em | A1 역할 카드 제목 |
| `bodyLarge` | 16 / 500 | 09 선택지 |
| `body` | 15 / 400 / 0 / 1.6 | A1 설명 |
| `label` | 13 / 500 | 머리글 알약 |
| `caption` | 12 / 500 | 보조 문구 |
| `button` | 16 / 700 | 주 버튼 |

그림자:

| 이름 | 값 |
|---|---|
| `card` | `0 8px 24px rgba(23,24,28,0.06)` |
| `floating` | `0 16px 40px rgba(23,24,28,0.08)` |
| `sheet` | `0 -12px 32px rgba(23,24,28,0.10)` |

- [ ] **Step 5: 통과 확인**

Run: `cd app && flutter analyze && flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app
git commit -m "feat: Flutter 앱 뼈대와 디자인 토큰 추가"
```

---

### Task 8: 공용 위젯과 전환 규칙, 모션 갤러리

**Files:**
- Create: `app/lib/core/ui/cora_primary_button.dart`, `app/lib/core/ui/cora_select_card.dart`, `app/lib/core/ui/cora_glass_card.dart`, `app/lib/core/ui/cora_logo.dart`, `app/lib/core/ui/cora_error_view.dart`, `app/lib/core/navigation/cora_transitions.dart`, `app/lib/features/dev/presentation/pages/motion_gallery_page.dart`
- Test: `app/test/core/ui/cora_primary_button_test.dart`, `app/test/core/ui/cora_select_card_test.dart`, `app/test/core/ui/cora_error_view_test.dart`, `app/test/core/navigation/cora_transitions_test.dart`

**Interfaces:**
- Consumes: 토큰 전부 (Task 7)
- Produces:
  - `CoraPrimaryButton({ required String label, required VoidCallback? onPressed })` — 높이 58, 알약 모양, `primaryAction` 색. `onPressed`가 null이면 `line` 배경에 `textSecondary` 글자.
  - `CoraSelectCard({ required String title, String? overline, String? subtitle, required bool selected, required VoidCallback onTap })` — 최소 높이 92, 모서리 24. 선택 시 `surfaceSelected` 배경에 그림자 없음, 아니면 `background` 배경에 `CoraShadows.card`. 오른쪽에 지름 24 원형 체크. 접근성 `selected` 상태 노출.
  - `CoraGlassCard({ required Widget child })` — 모서리 28, 배경 불투명도 75%, 블러 16, `CoraShadows.floating`
  - `CoraLogo({ double size = 28 })` — 겹친 원 두 개(오른쪽이 `accent`)와 글자 "cora"
  - `CoraErrorView({ required String message, required VoidCallback onRetry })` — 버튼 문구 "다시 시도"
  - `CoraTransitions.push<T>(Widget child): CustomTransitionPage<T>` — 320ms, `Curves.easeOutCubic`, 오른쪽에서 24% 밀려 들어오며 페이드. 나가는 화면은 왼쪽으로 8% 밀리며 어두워짐.
  - `CoraTransitions.sheet<T>(Widget child): CustomTransitionPage<T>` — 380ms, 아래에서 올라옴, 뒤 화면은 96%로 축소
  - `CoraTransitions.fade<T>(Widget child): CustomTransitionPage<T>` — 200ms, 탭 전환과 로그인 전후에 사용
  - `CoraMotion.pushDuration`, `sheetDuration`, `fadeDuration`, `standardCurve` 상수
  - 카드 → 상세 공유 요소 전환은 Flutter `Hero`를 쓰고 태그 규칙은 `'<종류>:<id>'`(예: `'creator:42'`)

전환 수치는 작성자의 제안이다. Step 5에서 소유자가 실제 기기로 보고 고친다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('primary button is 58 tall and calls onPressed', (tester) async { ... expect(tester.getSize(find.byType(CoraPrimaryButton)).height, 58); ... });
testWidgets('primary button ignores taps when disabled', (tester) async { ... });
testWidgets('select card exposes selected state to accessibility', (tester) async {
  ... expect(tester.getSemantics(find.byType(CoraSelectCard)), matchesSemantics(isSelected: true, isButton: true, hasTapAction: true, ...));
});
testWidgets('select card is at least 92 tall and grows with long text', (tester) async { ... });
testWidgets('error view shows the message and retries', (tester) async { ... expect(find.text('다시 시도'), findsOneWidget); ... });
testWidgets('push transition finishes after 320ms', (tester) async {
  ... await tester.pump(const Duration(milliseconds: 319)); expect(find.text('A'), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 2)); await tester.pump(); expect(find.text('A'), findsNothing);
});
```

- [ ] **Step 2: 실패 확인**

Run: `cd app && flutter test test/core`
Expected: FAIL

- [ ] **Step 3: 위젯과 전환 구현**

색은 모두 `context.colors`에서 읽는다. 위젯 안에 색 값을 직접 쓰지 않는다.

- [ ] **Step 4: 모션 갤러리 구현, 통과 확인**

`MotionGalleryPage`: push, sheet, fade, Hero 전환을 각각 시연하는 버튼과, 라이트·다크 전환 스위치, 공용 위젯 견본을 보여 준다. `AppConfig.isDev`일 때만 라우트에 등록된다(Task 9).

Run: `cd app && flutter analyze && flutter test`
Expected: PASS

- [ ] **Step 5: 소유자 승인 (실제 기기)**

iPhone 한 대와 중저가 Android 한 대에서 갤러리를 실행한다. 확인할 것: 전환 속도와 곡선, `CoraGlassCard`의 블러가 Android에서 끊기지 않는지. 소유자가 요청한 수치를 `CoraMotion`과 테스트에 반영한다. **승인 전에는 Task 10으로 넘어가지 않는다.**

- [ ] **Step 6: Commit**

```bash
git add app
git commit -m "feat: 공용 위젯과 화면 전환 규칙, 모션 갤러리 추가"
```

---

### Task 9: 앱 인증과 라우팅

> 변경(2026-11-11): `DevLoginPage`·`LoginUnavailablePage`는 Task 9b의 E1·E2 화면으로 대체한다.

**Files:**
- Create: `app/lib/features/auth/domain/auth_repository.dart`, `app/lib/features/auth/domain/auth_session.dart`, `app/lib/features/auth/data/supabase_auth_repository.dart`, `app/lib/features/auth/presentation/viewmodels/auth_view_model.dart`, `app/lib/features/auth/presentation/viewmodels/dev_login_view_model.dart`, `app/lib/features/auth/presentation/pages/dev_login_page.dart`, `app/lib/features/auth/presentation/pages/login_unavailable_page.dart`, `app/lib/core/network/api_client_provider.dart`, `app/lib/core/navigation/app_router.dart`
- Modify: `app/lib/main.dart`, `app/lib/app.dart`
- Test: `app/test/features/auth/fake_auth_repository.dart`, `app/test/features/auth/auth_view_model_test.dart`, `app/test/core/navigation/app_router_test.dart`, `app/test/core/network/api_client_provider_test.dart`

**Interfaces:**
- Consumes: `AppConfig` (Task 7), `CoraTransitions`, 공용 위젯 (Task 8), 패키지 `cora_api` (Task 6)
- Produces:
  - `class AuthSession { final String userId; final String accessToken; }`
  - `abstract class AuthRepository { Stream<AuthSession?> watchSession(); AuthSession? get currentSession; Future<void> signInWithEmail({required String email, required String password}); Future<void> signUpWithEmail({required String email, required String password}); Future<void> signOut(); }`
  - `final authRepositoryProvider = Provider<AuthRepository>((ref) => throw UnimplementedError('authRepositoryProvider must be overridden'));`
  - `final authViewModelProvider = StreamNotifierProvider<AuthViewModel, AuthSession?>(AuthViewModel.new);`
  - `final apiClientProvider = Provider<ApiClient>(...)` — 요청마다 현재 세션의 토큰을 `Authorization: Bearer`로 붙인다. 서버가 401을 주면 `authRepository.signOut()`을 호출한다.
  - `final appRouterProvider = Provider<GoRouter>(...)`
  - 라우트: `/login`, `/role`(Task 10), `/store`, `/brand`, `/creator`(Task 10), `/dev/motion`(dev만)
  - 리다이렉트: 세션이 없으면 어디서든 `/login`. 세션이 있는데 `/login`이면 `/role`.
  - `/login`: `AppConfig.isDev`이면 `DevLoginPage`(이메일, 비밀번호, "로그인", "개발용 계정 만들기"), 아니면 `LoginUnavailablePage`(문구 "로그인 준비 중이에요.").

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('emits null then a session after sign in', () async { ... });
testWidgets('redirects to /login when there is no session', (tester) async { ... expect(find.byType(DevLoginPage), findsOneWidget); });
testWidgets('redirects from /login to /role once signed in', (tester) async { ... });
testWidgets('returns to /login when the session ends', (tester) async { fake.endSession(); await tester.pumpAndSettle(); expect(find.byType(DevLoginPage), findsOneWidget); });
testWidgets('prod build has no email login form', (tester) async {
  // AppConfig(env: CoraEnv.prod)로 override
  expect(find.byType(DevLoginPage), findsNothing);
  expect(find.text('로그인 준비 중이에요.'), findsOneWidget);
});
testWidgets('prod build does not register /dev/motion', (tester) async { ... });
test('signs out when the API answers 401', () async {
  // 401을 돌려주는 가짜 HTTP 클라이언트로 ApiClient를 만든다
  expect(fakeAuth.signOutCalls, 1);
});
```

- [ ] **Step 2: 실패 확인**

Run: `cd app && flutter test`
Expected: FAIL

- [ ] **Step 3: 구현**

- `SupabaseAuthRepository`만 `supabase_flutter`를 import한다. 다른 파일은 `AuthRepository`만 안다.
- `main.dart`: `Supabase.initialize` 후 `ProviderScope(overrides: [authRepositoryProvider.overrideWithValue(SupabaseAuthRepository(...)), appConfigProvider.overrideWithValue(config)])`.
- 로그인 실패는 `AsyncError`로 두고 화면에 "이메일이나 비밀번호를 확인해 주세요."를 보여 준다.

- [ ] **Step 4: 통과 확인**

Run: `cd app && flutter analyze && flutter test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app
git commit -m "feat: 앱 인증 흐름과 라우팅, 개발용 이메일 로그인 추가"
```

---

### Task 10: 역할 선택 화면(A1)과 역할별 빈 홈

**Files:**
- Create: `app/lib/features/onboarding/domain/user_role.dart`, `app/lib/features/onboarding/domain/me.dart`, `app/lib/features/onboarding/domain/me_repository.dart`, `app/lib/features/onboarding/data/api_me_repository.dart`, `app/lib/features/onboarding/presentation/viewmodels/role_select_view_model.dart`, `app/lib/features/onboarding/presentation/pages/role_select_page.dart`, `app/lib/features/onboarding/presentation/pages/role_home_placeholder_page.dart`
- Modify: `app/lib/core/navigation/app_router.dart`, `app/lib/main.dart`
- Test: `app/test/features/onboarding/fake_me_repository.dart`, `app/test/features/onboarding/role_select_view_model_test.dart`, `app/test/features/onboarding/role_select_page_test.dart`, `app/test/features/onboarding/api_me_repository_test.dart`

**Interfaces:**
- Consumes: `apiClientProvider`, `appRouterProvider` (Task 9), 공용 위젯 (Task 8), `cora_api`의 `getMe`, `updateMyRole` (Task 6)
- Produces:
  - `enum UserRole { store, brand, creator }`
  - `class Me { final String id; final UserRole? role; }` (불변, `==`와 `hashCode` 직접 구현)
  - `abstract class MeRepository { Future<Me> fetchMe(); Future<Me> updateRole(UserRole role); }`
  - `final meRepositoryProvider = Provider<MeRepository>((ref) => throw UnimplementedError('meRepositoryProvider must be overridden'));`
  - `final roleSelectViewModelProvider = AsyncNotifierProvider<RoleSelectViewModel, RoleSelectState>(RoleSelectViewModel.new);`
  - `class RoleSelectState { final Me me; final UserRole selected; final bool saving; }` — `selected`의 초깃값은 `me.role ?? UserRole.store`
  - `RoleSelectViewModel.select(UserRole role)`, `Future<void> confirm()`
  - 리다이렉트 추가: 세션이 있고 `me.role`이 있으면 `/role` 대신 `/store` · `/brand` · `/creator`로 보낸다.
  - `ApiMeRepository`는 생성된 타입을 `Me`로 변환한다. 생성된 타입은 `data` 밖으로 나가지 않는다.

화면 문구 (캔버스 A1 그대로):

| 자리 | 문구 |
|---|---|
| 제목 | `어떤 일로\n오셨나요?` |
| 설명 | `고른 역할에 맞는 첫 화면을 보여드려요. 나중에 바꿀 수 있어요.` |
| 카드 1 | 윗줄 `일을 맡기는 쪽` · 제목 `가게를 알리고 싶어요` · 설명 `식당, 미용실, 공방 같은 동네 가게` · 버튼 `가게 링크로 시작하기` → `store` |
| 카드 2 | 윗줄 `일을 맡기는 쪽` · 제목 `브랜드 제품을 알리고 싶어요` · 설명 `쇼핑몰, 제조사, 브랜드 담당자` · 버튼 `크리에이터 둘러보기` → `brand` |
| 카드 3 | 윗줄 `일을 하는 쪽` · 제목 `콘텐츠를 만들고 싶어요` · 설명 `팔로워가 적어도 누구나 시작할 수 있어요` · 버튼 `내 협업 원칙 정하기` → `creator` |

배치: 위 여백 72, 좌우 24. 로고 → 36 → 제목 → 12 → 설명 → 32 → 카드 목록(좌우 16, 간격 10) → 하단 고정 버튼(좌우 16, 아래 32).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('starts with the store role selected when the user has no role', () async { ... expect(state.selected, UserRole.store); });
test('starts with the saved role selected', () async { ... });
test('confirm saves the selected role', () async { await vm.confirm(); expect(fake.savedRole, UserRole.creator); });
test('confirm keeps the selection and reports an error when saving fails', () async { ... });

testWidgets('shows the canvas copy for all three roles', (tester) async {
  expect(find.text('어떤 일로\n오셨나요?'), findsOneWidget);
  expect(find.text('가게를 알리고 싶어요'), findsOneWidget);
  expect(find.text('브랜드 제품을 알리고 싶어요'), findsOneWidget);
  expect(find.text('콘텐츠를 만들고 싶어요'), findsOneWidget);
});
testWidgets('button label follows the selected role', (tester) async {
  expect(find.text('가게 링크로 시작하기'), findsOneWidget);
  await tester.tap(find.text('콘텐츠를 만들고 싶어요')); await tester.pump();
  expect(find.text('내 협업 원칙 정하기'), findsOneWidget);
});
testWidgets('confirming navigates to the home for that role', (tester) async { ... expect(find.text('크리에이터 홈'), findsOneWidget); });
testWidgets('shows an error with retry when the server is unreachable', (tester) async {
  fake.failFetch = true; ... expect(find.text('다시 시도'), findsOneWidget);
  fake.failFetch = false; await tester.tap(find.text('다시 시도')); await tester.pumpAndSettle();
  expect(find.text('가게를 알리고 싶어요'), findsOneWidget);
});
testWidgets('does not overflow at 1.3x text scale on a small phone', (tester) async {
  // 화면 360x640, textScaler 1.3
  expect(tester.takeException(), isNull);
});
testWidgets('renders in dark theme without errors', (tester) async { ... });
testWidgets('skips role selection when a role is already saved', (tester) async { ... expect(find.text('가게 홈'), findsOneWidget); });
```

- [ ] **Step 2: 실패 확인**

Run: `cd app && flutter test test/features/onboarding`
Expected: FAIL

- [ ] **Step 3: 구현**

- 카드 목록은 스크롤 가능하게 두어 글자가 커져도 넘치지 않게 한다.
- `RoleHomePlaceholderPage`: 제목 `가게 홈` · `브랜드 홈` · `크리에이터 홈`, 그 아래 "역할 다시 고르기"(→ `/role`)와 "로그아웃" 버튼. 이후 계획에서 실제 홈으로 교체한다.
- `/role` → 역할 홈 이동은 `CoraTransitions.push`, 로그인 전후는 `CoraTransitions.fade`.

- [ ] **Step 4: 통과 확인**

Run: `cd app && flutter analyze && flutter test`
Expected: PASS

- [ ] **Step 5: 전체 흐름 수동 확인**

```bash
docker compose up -d
cd api && yarn start:dev
cd app && flutter run --dart-define-from-file=config/dev.json
```

(Android 에뮬레이터에서는 `config/dev.json`의 `API_BASE_URL`을 `http://10.0.2.2:3000`으로 둔다.)

확인 순서, iOS와 Android 각각:
1. 개발용 계정을 만들고 로그인 → 역할 선택 화면이 보인다.
2. "콘텐츠를 만들고 싶어요"를 고르고 버튼 → "크리에이터 홈".
3. 앱을 완전히 껐다 켠다 → 역할 선택을 건너뛰고 "크리에이터 홈".
4. "역할 다시 고르기"로 "가게"로 바꾼다 → "가게 홈". `users` 테이블의 `role`이 `STORE`.
5. 시스템을 다크 모드로 바꾼다 → 캔버스의 다크 화면과 같은 색.
6. 캔버스 A1 화면과 나란히 놓고 여백, 글자 크기, 모서리를 비교한다.

- [ ] **Step 6: Commit**

```bash
git add app
git commit -m "feat: 역할 선택 화면과 역할별 빈 홈 추가"
```

---

## 완료 기준

- `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db` 통과
- `cd app && flutter analyze && flutter test` 통과
- `./scripts/gen-api.sh` 실행 후 `git status`에 변경 없음
- Task 10 Step 5의 수동 확인 6개가 iOS와 Android에서 모두 통과
- Task 8 Step 5의 소유자 승인 완료

## 소유자 확인이 필요한 것

- **앱 번들 ID**: `com.cora.cora`로 가정했다. 스토어에 올린 뒤에는 바꿀 수 없으므로 Task 7 전에 정한다.
- **전환 수치**: Task 8의 속도와 곡선은 제안이다. 실제 기기에서 보고 정한다.
- **주차별 순서**: 위 표의 순서와 날짜는 제안이다.
