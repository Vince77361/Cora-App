# 실제 연동 교체와 출시 준비 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

> **상태: 소유자 승인 (2026-11-11).** 맨 아래 "소유자 결정"의 20가지는 모두 추천안으로 정해졌다(2026-11-11 소유자 결정). [확인 필요]는 남아 있고, 각 Task의 "소유자 준비 확인"에서 멈추고 묻는다.

**Goal:** 1~8번에서 가짜 구현으로 만든 외부 연동을 실제 구현으로 바꾸고, 출시 전 보안·안정성 보강을 끝내고, 스테이징·운영 환경에 서버를 올리고, 두 스토어에 앱을 낸다.

**Architecture:** 포트는 그대로 두고 연동마다 `real` 어댑터만 더한다. 실제 어댑터는 주입받은 `HttpFetch`(또는 그 서비스의 공식 SDK)로만 밖에 나가고, 가짜와 실제가 같은 포트 계약 테스트를 통과한다. 작업은 다섯 묶음이다: **가**(외부 승인 없이 하는 보강), **나**(운영 기반), **다**(연동 교체 — 승인이 나는 순서대로 하나씩, 서로 기대지 않음), **라**(출시에 필요한데 캔버스에 없는 서버·화면), **마**(출시 게이트).

**Tech Stack:** 앞 계획들과 같다. 더해지는 것(실행자가 공식 문서를 보고 버전을 고정): 서버 `helmet`, `@nestjs/throttler`(8번에서 이미 들어옴), FCM HTTP v1(`firebase-admin` 또는 HTTP), 오류 추적 SDK(Sentry로 정하면 `@sentry/nestjs`), LLM SDK(Claude로 정하면 `@anthropic-ai/sdk`) / 앱 `firebase_core`, `firebase_messaging`, `shared_preferences`, 웹 인증 창 패키지(예: `flutter_web_auth_2`, 실행자 선택), PG의 Flutter SDK, 오류 추적 SDK / CI·배포 GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-11-integrations-launch-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md`(2, 17~20장) · 상위: `docs/superpowers/specs/2026-11-11-tech-stack-design.md` · 보안 기준: Wiki `wiki/patterns/security-baseline.md`, `logging.md`, `error-handling.md`

**선행 조건:** 1~8번 계획 완료(설계의 "앞 단계"). 예외로 가 묶음(Task 1~4)은 1번만 있으면 된다 — 다만 2번 세션이 같은 파일(`app.setup.ts`, `env.ts`, `main.dart`)을 고치고 있으므로 언제 당길지는 소유자가 정한다(소유자 결정 1). 이 계획은 다음을 그대로 쓴다.
- 1번: `assertNoFakesInProduction`, `loadEnv`, `IntegrationsModule`, `AllExceptionsFilter`, `setupApp`, `SupabaseTokenVerifier`, `AppConfig`, `assertAuthAdapterStartable`, `kDevScreensCompiledIn`, `SignInAdapter`, `SupabaseAuthRepository`, `TimeoutHttpClient`, `CoraErrorView`
- 2번: `StoreLinkPort`, `ContentDraftPort`, `StoragePort`, `Clock`, `RATE_LIMITED`, 오류 해석기(`api_error.dart`)
- 3번: `PaymentPort`, `PayoutPort`, `ViewCountPort`, `InstagramPort`, `OperatorAlertPort`, `JobScheduler`, `seal`/`open`, `CheckoutLauncher`, `payment-recheck` 작업, 운영 명령 CLI, `check-ledger`
- 5번: 대화방, 신고. 6번: `drafts` 버킷. 7번: `InstagramPort.listPosts/downloadMedia`, 가져오기
- 8번: `GET /config`, `MIN_APP_VERSION`, `DIRECTORY_ENABLED`, `adapterKeysToCheck`, `expireAllForStore`, `cora://invite/<code>`
- E3~E8 화면(2026-11-11 소유자 결정): 설계 `specs/2026-11-11-account-notify-settings-design.md`, 3번 계획 Task 3A·13A~13D(`NotificationsService.notify`, `PushPort.send`의 `data`, E3·E5·E7)와 Task 8(매주 수요일 송금), 계획 `plans/2026-11-11-account-settings.md`(E4·E6·E8, `LEGAL_URL`). 설정·고객센터·알림 화면과 `LEGAL_URL`은 그쪽이 만들고, 이 계획은 실제 푸시 전송, 탈퇴·동의의 서버와 확인 화면만 만든다.

## 작업 지도

| 묶음 | Task | 막는 것 (소유자 준비 확인) | 먼저 필요한 Task |
|---|---|---|---|
| 가 | 1 요청 ID와 보안 로그 | 없음 | — |
| 가 | 2 서버 경계 보강 | 로컬 Node LTS 설치 | 1 |
| 가 | 3 앱 세션 안전 | 오류 화면 로그아웃 문구 | — |
| 가 | 4 운영 빌드 안전 | 앱 이름 | — |
| 다(공통) | 5 실제 연동 공통 장치 | 없음 | — |
| 나 | 6 스테이징·운영 Supabase | 프로젝트 2개 | — |
| 나 | 7 CI | GitHub 비밀값, `cora_ci` 스키마 | 2 |
| 나 | 8 컨테이너·호스팅·배포 | 호스팅·Redis·도메인 | 6, 7 |
| 나 | 9 오류 추적·백업 복구 | 오류 추적 계정 | 8 |
| 나 | 10 앱 빌드와 서명 | Apple·Google 개발자 계정 | 4, 7 |
| 다 | 11 휴대폰 인증 (SMS) | SMS 업체·발신번호 | 5, 6 |
| 다 | 12 카카오 로그인 | 카카오 개발자 앱 | 5, 6 |
| 다 | 13 네이버 로그인 | 네이버 개발자 앱, 방식 결정 | 5, 6 |
| 다 | 14 Apple 로그인 | 캔버스 E1의 Apple 버튼(소유자가 artifact를 먼저 고침), Apple 키 | 5, 6 |
| 다 | 15 푸시 | Firebase, APNs 키 | 5, 3번 Task 3A |
| 다 | 16 운영자 알림 메일 | 발송 서비스, 도메인 | 5 |
| 다 | 17 AI 초안 (LLM) | LLM 계정, 견본 비교 결과 | 5 |
| 다 | 18 가게 링크 분석 | 약관 확인 결과 | 5 |
| 다 | 19 결제 (PG) | 법률 확인, PG 계약 | 5 |
| 다 | 20 지급 (지급 대행) | 지급 대행 계약, 세무 확인 | 19 |
| 다 | 21 인스타그램 연결·가져오기 | Meta 앱 심사 | 5, 8 |
| 다 | 22 조회수 (인스타그램·쇼츠) | 유튜브 API 키, 쇼츠 확인 방식 | 21 |
| 라 | 23 약관·개인정보 동의 | 문서와 공개 주소, 동의 방식 결정 | 계정·설정 계획 Task 4(`LEGAL_URL`) |
| 라 | 24 유니버설 링크·앱 링크 | 운영 도메인 | 8 |
| 라 | 25 회원 탈퇴 | 보관 기간 확인 | 23 |
| 마 | 26 출시 게이트 점검 | 법률 확인 결과 전부 | 1~25 |
| 마 | 27 실제 돈으로 처음부터 끝까지, 실기기 | 운영 PG, 실기기 2대 | 26 |
| 마 | 28 스토어 제출 | 스토어 등록 정보, 심사 계정 | 27 |

다 묶음은 Task 5만 먼저 끝나면 어느 순서로든 된다. 한 작업이 외부 승인을 기다리면 다음 작업으로 넘어가고, progress.md에 "대기: <무엇>"을 남긴다.

## Global Constraints

앞 계획들의 Global Constraints가 모두 적용된다. 더해지는 것:

- 포트 모양은 바꾸지 않는 것이 원칙이다. 실제 서비스 때문에 바꿔야 하면 그 Task 안에서 가짜 구현과 모든 호출부를 함께 고치고 progress.md에 이유를 남긴다. 이 계획이 아는 후보: `PaymentPort.handleReturn`(Task 19), `PayoutPort.registerPayee`(Task 20), `ViewCountPort.isOwnedBy`의 채널 인자(Task 22), 7번 가져오기 API의 비동기화(Task 21).
- 서비스 이름과 SDK는 실제 어댑터 파일, `docs/integrations/<서비스>.md`, 환경변수 이름에만 나온다.
- 밖으로 나가는 HTTP는 Task 5의 `HttpFetch`로 하고 시간 제한은 기본 `10`초, 결제 승인·취소·지급은 `30`초. 서비스 오류는 `ExternalServiceError`로 바꾸고, 메시지에 응답 본문·전화번호·토큰을 넣지 않는다.
- 서비스 세부 사양(주소, 필드 이름, 오류 코드, 한도, 서명 방식)은 기억으로 쓰지 않는다. 계약·신청 뒤 공식 문서를 읽고 `docs/integrations/<서비스>.md`에 적은 뒤 그 값으로 테스트를 쓴다(설계 1장). 문서로 확인하지 못한 값은 [확인 필요]로 두고 소유자에게 묻는다.
- 비밀값은 `api/.env`(로컬), 호스팅의 비밀 저장소, CI 비밀값에만 둔다. 앱에는 공개 값(Supabase publishable key, Firebase 앱 설정, PG 클라이언트 키)만 넣는다. `<NAME>_ADAPTER=real`인데 그 어댑터의 비밀값이 비면 서버가 시작을 거부한다(`RequiredWhenReal`, Task 5). 에이전트는 비밀 파일을 읽지 않는다(`api/.env*`, `app/config/*.json` — 키 이름은 `*.example`에서 본다).
- 로그에 남기지 않는 것: 전화번호, 인증번호, 토큰(액세스·리프레시·OAuth·기기 토큰 원문), 계좌번호, 주민등록번호, 메시지·초안·알림 본문, 결제창 주소의 쿼리. 남기는 것: 요청 ID, 사용자 ID, 사건 코드, 대상 ID, 결과, 요청 IP(보안 로그만).
- 돈이 오가는 응답(결제 통지, 결제창 복귀, 지급 결과)은 금액·상태를 DB 값과 대조한다. 서명이 없거나 맞지 않으면 그 서비스에 다시 물어 확인한다. 어긋나면 승인하지 않고 `OperatorAlertPort`로 알린다.
- **소유자 준비 확인**이라고 적힌 단계에서 멈추고, 준비됐다는 답을 받은 뒤 진행한다. 비밀값은 소유자가 넣는다.
- 스테이징은 PG·Meta 등의 테스트 환경에, 운영은 실제 환경에 붙인다. 운영 DB에는 `yarn test:db`·`yarn test:e2e`·`yarn seed:dev`를 돌리지 않는다. 운영 확인은 읽기 전용 연결의 `yarn check:rls`와 `yarn check:auth-settings`(Task 6)로만 한다.
- 원격에 영향을 주는 일(push, 태그, 스테이징·운영 배포, 외부 서비스 설정 변경, 스토어 업로드·제출, 실제 요금이 드는 호출)은 매번 소유자에게 확인받는다. 운영 배포는 태그 push라서 태그마다 확인받는다.
- 큰 도구나 이미지를 로컬에 들이기 전에 묻는다(Node LTS, Docker 이미지 빌드, Xcode 구성요소). 서버 이미지는 CI에서 만드는 것을 기본으로 한다.
- 화면 문구는 캔버스 그대로다. 캔버스에 없는 화면·상태(동의, 탈퇴 확인, 오류 화면 로그아웃, 인증번호 만료, 실명 불일치)는 기존 토큰과 공용 위젯으로 최소로 만들고, 문구와 라이트·다크 스크린샷을 소유자에게 목록으로 확인받는다.
- 휴대폰 번호 예시는 테스트·문서·스크린샷 모두 `010-0000-XXXX`(E.164는 `+82100000XXXX`)만 쓴다. 실제 문자 수신 확인은 소유자가 자기 휴대폰으로 하고, 그 번호는 어디에도 적지 않는다.

## Review Focus

1. **서버가 호스팅 프록시 뒤에서 모든 요청을 같은 IP로 봄, 또는 통신사 공용 IP(CGNAT)로 여러 사용자가 한 IP를 씀** → 전역 요청 수 제한이 사용자들을 함께 429로 막지 않는다. 로그인한 요청은 사용자 ID로 세고, IP 기준 제한은 넉넉하게 둔다. (Task 2, Task 8 Step 5)
2. **사장님이 넣은 가게 링크가 사설 주소나 허용 밖 호스트로 리다이렉트됨** → 서버가 따라가지 않고 직접 입력 흐름으로 넘긴다. (Task 18)
3. **결제창 복귀·통지의 금액이 DB와 다르거나 서명이 없음, 또는 둘이 동시에 옴** → 승인하지 않고 PG에 다시 묻고 운영자에게 알린다. 같은 승인은 한 번만 반영된다. (Task 19)
4. **스테이징·운영 Supabase의 토큰 서명 방식이나 로그인 제공자 설정이 개발과 다름** → 배포 직후 확인이 실패해 배포가 멈춘다(사용자가 모두 401을 받기 전에). (Task 6, 8)
5. **탈퇴를 요청한 사이 상대가 오퍼를 수락·결제함, 또는 정리 도중 서버가 죽음** → 로그인은 즉시 막히고, 정리는 다시 실행돼 끝까지 가며, 요청 뒤 생긴 보관 금액이 있으면 멈추고 운영자에게 알린다. (Task 25)

---

## 파일 구조

```text
api/
├── Dockerfile, .dockerignore
├── scripts/{check-auth-settings.ts, auth-settings-rules.ts, smoke.ts, compare-drafts.ts}
└── src/
    ├── common/request-context/          # 요청 ID (AsyncLocalStorage)
    ├── common/logging/security-log.ts
    ├── integrations/http/               # HttpFetch, ExternalServiceError, readJson
    ├── integrations/<port>/<vendor>-*.adapter.ts   # 실제 어댑터 (Task 11~22)
    ├── integrations/sms/                # SmsPort (Task 11)
    ├── auth-hooks/                      # Supabase Send SMS Hook (Task 11)
    ├── external-auth/                   # 네이버 서버 중계 (Task 13, B안일 때)
    ├── devices/                         # 기기 토큰 (Task 15)
    ├── consents/                        # 동의 기록 (Task 23)
    ├── well-known/                      # 유니버설 링크·앱 링크 (Task 24)
    └── accounts/                        # 회원 탈퇴 (Task 25)
api/test/support/{fake-http-fetch.ts, port-contracts/*.contract.ts}
app/lib/
├── core/push/                           # 토큰 등록, 권한 시점, 알림 탭 이동
├── features/auth/data/{supabase_sign_in_adapter.dart, first_run_marker.dart}
├── features/consent/                    # 동의 화면
└── features/account_deletion/           # 탈퇴 확인 화면
docs/integrations/<서비스>.md             # 공식 문서에서 확인한 값
docs/launch/                             # 배포·복구·점검 절차와 기록
.github/workflows/{ci.yml, deploy.yml, app-release.yml}
```

---

## 묶음 가 — 외부 승인 없이 하는 보강

### Task 1: 요청 ID와 보안 로그

**Files:**
- Create: `api/src/common/request-context/{request-context.ts,request-id.middleware.ts}`, `api/src/common/logging/security-log.ts`
- Modify: `api/src/common/errors/all-exceptions.filter.ts`, 2번이 만든 오류 형식 모델(`ErrorEnvelope`), `api/src/auth/`(가드·검증기의 실패 로그), `api/src/users/users.service.ts`(역할 변경 로그), 3번 `payments`·`payouts`·`refunds` 서비스와 운영 명령, `api/src/app.setup.ts`, `app/lib/core/network/api_error.dart`
- Test: `api/src/common/request-context/request-id.middleware.spec.ts`, `api/src/common/logging/security-log.spec.ts`, `api/test/request-id.e2e-spec.ts`, `app/test/core/network/api_error_test.dart`(추가)

**Interfaces:**
- Produces:
  - 응답 헤더 `X-Request-Id`. 들어온 값이 `^[A-Za-z0-9-]{8,64}$`이면 그대로 쓰고, 아니면 `crypto.randomUUID()`.
  - 오류 본문 `{ error: { code, message, details, requestId } }` — `requestId`만 더해진다. 앱 해석기는 `requestId`를 읽어 디버그 로그에만 남긴다.
  - `currentRequestId(): string | undefined` — `AsyncLocalStorage`. 작업 큐 처리기는 `job:<jobName>:<jobId>`를 넣고 돈다.
  - `securityLog(event: SecurityEvent, fields: { userId?: string; target?: string; result: 'ALLOWED' | 'DENIED' | 'FAILED'; reason?: string }): void` — 한 줄 JSON(`ts`, `level`, `event`, `requestId`, `ip`, 그리고 fields). 문자열 값의 CR·LF를 지운다.
  - `type SecurityEvent = 'AUTH_FAILED' | 'AUTH_INFRA_FAILED' | 'ROLE_CHANGED' | 'FORBIDDEN' | 'PAYMENT_RESULT' | 'PAYOUT_RESULT' | 'REFUND_RESULT' | 'WEBHOOK_REJECTED' | 'CONSENT_RECORDED' | 'ACCOUNT_DELETION_REQUESTED' | 'OPS_COMMAND'` — 뒤 Task가 쓰는 이름까지 미리 둔다.
  - 남기는 곳: 가드의 401(`reason`은 `EXPIRED | INVALID | ANONYMOUS | DELETED_USER` 같은 분류만), 키 묶음 장애(`AUTH_INFRA_FAILED`), `PATCH /me/role`(`reason: '<이전>→<새>'`), 필터의 403, 3번의 결제 결과 반영·지급·환불(`target`은 협업 ID, 금액은 남기되 계좌·카드 정보는 남기지 않음 — 설계 5장 로그), 3번 운영 명령(`OPS_COMMAND`).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('echoes a valid incoming X-Request-Id and generates one otherwise', ...);
it('puts the same request id in the error body and the response header', ...);   // 없는 경로 404
it('logs AUTH_FAILED with a reason category and never the token', ...);          // 로그 문자열에 'eyJ' 없음
it('logs ROLE_CHANGED with the previous and the new role', ...);
it('logs PAYMENT_RESULT and PAYOUT_RESULT without account numbers', ...);
it('strips CR and LF from logged fields', ...);
```
```dart
test('reads requestId from the error envelope', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e` · `./scripts/gen-api.sh` · `cd app && flutter analyze && flutter test`
- [ ] **Step 5: Commit** — `feat: 요청 ID와 보안 로그 추가`

---

### Task 2: 서버 경계 보강

**Files:**
- Modify: `api/src/app.setup.ts`, `api/src/main.ts`, `api/src/app.module.ts`, `api/src/config/env.ts`, `api/.env.example`, `api/src/auth/supabase-token-verifier.ts`, `api/src/prisma/prisma.service.ts`, `api/.yarnrc`, `api/package.json`(`engines.node`)
- Create: `.nvmrc`
- Test: `api/test/hardening.e2e-spec.ts`, `api/src/auth/supabase-token-verifier.spec.ts`(추가), `api/src/prisma/prisma.service.spec.ts`

**Interfaces:**
- Consumes: `securityLog` (Task 1)
- Produces:
  - `setupApp(app: INestApplication, opts: { env: Env }): void` — `main.ts`와 모든 e2e가 env를 넘긴다.
  - Swagger(`/docs`, `/docs-json`)는 `env.NODE_ENV !== 'production'`일 때만 등록한다. `yarn openapi:export`는 그대로 동작한다.
  - `helmet()` 기본값. 개발에서는 Swagger UI가 돌게 `/docs` 경로에만 CSP를 끈다. 8번 초대 페이지가 정한 CSP가 최종 응답 헤더로 남는다. `x-powered-by`를 끈다.
  - 본문: JSON `100kb`. JSON 경로에 `application/json`이 아닌 본문은 415. 413·415는 2번이 정한 매핑대로 상태를 유지한다(코드 `VALIDATION_FAILED`). 원문 본문을 받는 경로(3번 PG 통지, Task 11 SMS 훅)는 이 검사에서 뺀다.
  - `Env`: `TRUST_PROXY_HOPS: number`(기본 `0`), `RATE_LIMIT_IP_PER_MIN`(기본 `600`), `RATE_LIMIT_USER_PER_MIN`(기본 `120`). `app.set('trust proxy', TRUST_PROXY_HOPS)`. 값은 [제안] — 소유자 확인.
  - 전역 요청 수 제한 두 겹: `ip` 제한은 인증 가드보다 먼저(잘못된 토큰 홍수까지 막는다, CGNAT 때문에 넉넉하게), `user` 제한은 인증 가드 뒤에 `user:<sub>` 키로. 429는 `RATE_LIMITED`. `@SkipThrottle()`: `/health`, PG 통지, SMS 훅. 8번의 초대 경로 제한(IP당 분당 20)은 그대로 남는다.
  - 토큰의 `is_anonymous === true` → `UNAUTHENTICATED`, 보안 로그 `reason: 'ANONYMOUS'`.
  - `app.enableShutdownHooks()`, `PrismaService.onModuleDestroy()` → `$disconnect()`. SIGTERM 뒤 `10`초 안에 종료 코드 0(BullMQ 처리기도 닫힌다).
  - `.nvmrc`·`engines.node`를 실행 시점의 Node Active LTS로 정하고(nodejs.org에서 확인 — 작성 시점 기준 [확인 필요]), `api/.yarnrc`의 `--ignore-engines` 줄을 지운다.

- [ ] **Step 0: 소유자 준비 확인** — 로컬에 Node LTS를 설치해도 되는지(nvm 등). 설치 전에는 이 Task의 Node 부분만 빼고 진행하고 progress.md에 남긴다.
- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('serves no swagger routes in production', ...);                 // GET /docs, /docs-json → 404
it('serves swagger in development', ...);
it('sends helmet headers and no x-powered-by', ...);                 // x-content-type-options: nosniff
it('keeps the invite page content security policy', ...);           // GET /i/<code> → 8번의 CSP
it('answers 413 for a json body over 100kb', ...);
it('answers 415 for a text/plain body on a json route', ...);
it('limits signed-in users by user id, not by shared ip', ...);       // 같은 IP의 두 사용자: 한쪽이 한도여도 다른 쪽 200
it('does not limit the payment webhook or health', ...);
it('rejects an anonymous supabase token', ...);
it('disconnects prisma on module destroy', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn install --frozen-lockfile && yarn lint && yarn test && yarn test:e2e && yarn test:db`. 수동: `yarn build && NODE_ENV=production <운영 형식의 가짜 값> node dist/main.js` → `kill -TERM <pid>` → 10초 안에 종료 코드 0.
- [ ] **Step 5: Commit** — `fix: 보안 헤더·요청 수 제한·본문 제한과 운영 Swagger 차단 추가`

---

### Task 3: 앱 세션 안전

**Files:**
- Create: `app/lib/features/auth/data/first_run_marker.dart`
- Modify: `app/lib/main.dart`, `app/lib/features/auth/data/supabase_auth_repository.dart`, `app/lib/features/auth/data/secure_session_storage.dart`(접근 등급, 소유자 결정 시), `app/lib/core/ui/cora_error_view.dart`, `app/lib/features/onboarding/presentation/pages/role_select_page.dart`, `app/pubspec.yaml`(`shared_preferences`)
- Test: `app/test/features/auth/data/first_run_marker_test.dart`, `app/test/features/auth/data/supabase_auth_repository_test.dart`(추가), `app/test/features/onboarding/presentation/pages/role_select_page_test.dart`(추가)

**Interfaces:**
- Produces:
  - `abstract class FirstRunMarker { Future<bool> isFirstRun(); Future<void> markRan(); }` — 실제 구현은 `shared_preferences`(앱을 지우면 함께 지워지는 저장소).
  - `Future<void> clearSessionOnFirstRun({required FirstRunMarker marker, required SecureKeyValueStore store, required Iterable<String> keys})` — 첫 실행이면 세션 키와 PKCE 키를 지우고 표시를 남긴다. 지우기가 실패해도 디버그 로그만 남기고 앱은 켜진다. `main`이 `Supabase.initialize` 전에 부른다(iOS 키체인은 앱을 지워도 남는다).
  - `validAccessToken()`: 갱신이 실패했을 때, 지금 토큰의 실제 `exp`(SDK의 30초 여유를 빼지 않은 값)가 지났으면 `null`, 아니면 그 토큰. 헤더 없이 나간 요청의 401은 로그아웃을 일으키지 않으므로 결과는 오류 화면과 "다시 시도"다.
  - `CoraErrorView`에 선택 인자 `secondaryLabel: String?`, `onSecondary: VoidCallback?`. A1의 `/me` 오류 화면에 로그아웃(문구 소유자 확인) → `AuthRepository.signOut()`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('clears the stored session on the first run after install', ...);
test('keeps the session on later runs', ...);
test('starts the app even when clearing the keychain throws', ...);
test('returns the current token when refresh fails but the token has not really expired', ...);
test('returns null when refresh fails and the token is past its exp', ...);
testWidgets('signs out from the error screen when me keeps failing', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test`. 시뮬레이터: 로그인 → 앱 삭제 → 다시 설치 → E1이 보인다.
- [ ] **Step 5: 소유자 확인** — 오류 화면의 로그아웃 문구와 모양(라이트·다크 스크린샷), 키체인 접근 등급(소유자 결정 15).
- [ ] **Step 6: Commit** — `fix: 재설치 뒤 세션 정리, 토큰 갱신 실패 처리, 오류 화면 로그아웃 추가`

---

### Task 4: 운영 빌드 안전

**Files:**
- Create: `app/android/app/src/main/res/xml/data_extraction_rules.xml`, `scripts/check-release-binary.sh`
- Modify: `app/lib/core/config/app_config.dart`, `app/lib/main.dart`, 3번의 `checkoutLauncherProvider`와 가짜 인스타그램 연결 화면을 고르는 자리, `app/android/app/src/main/AndroidManifest.xml`(규칙 연결, 주석 정정, 앱 이름), `app/ios/Runner/Info.plist`(앱 이름), `app/pubspec.yaml`(`cupertino_icons` 제거), 1번의 `/me` 해석(모르는 역할)
- Test: `app/test/core/config/app_config_test.dart`(추가), `app/test/platform/android_manifest_test.dart`, `app/test/features/onboarding/data/api_me_repository_test.dart`(추가)

**Interfaces:**
- Produces:
  - `void assertProductionConfig(AppConfig c)` — `env == prod`이면 `supabaseUrl`·`apiBaseUrl`이 비어 있지 않고 `https://`로 시작하며 `supabaseAnonKey`가 비어 있지 않아야 한다. 아니면 `StateError`(값은 메시지에 넣지 않는다). `main`이 `assertAuthAdapterStartable` 다음에 부른다. 계정·설정 계획 Task 4의 `LEGAL_URL`·`OPERATOR_EMAIL` 검사가 먼저 들어와 있으면 이 함수 하나로 합친다.
  - 가짜 구현을 고르는 모든 자리를 `kDevScreensCompiledIn && …` 상수 조건 안에 둔다: `FakeSignInAdapter`, `FakeCheckoutPage`, 가짜 인스타그램 연결 화면. 실제 구현이 아직 없는 자리는 `else` 쪽에서 `StateError`를 던진다(Task 11·19·21이 바꾼다).
  - `scripts/check-release-binary.sh <binary>` — `strings`로 `FakeSignInAdapter`, `FakeCheckoutPage`, `MotionGalleryPage`, `cora-dev-only`, `cora-dev://`를 찾고 하나라도 있으면 exit 1. 난독화하지 않은 운영 빌드에 쓴다.
  - Android: `android:dataExtractionRules="@xml/data_extraction_rules"`. `<cloud-backup>`과 `<device-transfer>` 둘 다 모든 도메인을 뺀다(도메인 목록은 Android 문서대로). API 26~30은 기존 `allowBackup="false"`가 막는다.
  - 서버가 앱이 모르는 역할 값을 보내면 `MeFailure`(오류 화면)로 다룬다. A1로 보내 역할을 덮어쓰지 않는다.
  - 앱 이름: 소유자 결정 값(소유자 결정 15)으로 Android `android:label`, iOS `CFBundleName`·`CFBundleDisplayName`을 맞춘다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('refuses a prod config with an http api url', ...);
test('refuses a prod config with an empty supabase url or key', ...);
test('accepts a prod config with https urls', ...);
test('android manifest points to rules that exclude cloud backup and device transfer', ...);
test('treats an unknown server role as a failure instead of asking for a role', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test` · `cd app && flutter build ios --release --no-codesign --dart-define=CORA_ENV=prod --dart-define=AUTH_ADAPTER=real --dart-define=SUPABASE_URL=https://example.invalid --dart-define=SUPABASE_ANON_KEY=x --dart-define=API_BASE_URL=https://example.invalid` → `./scripts/check-release-binary.sh app/build/ios/iphoneos/Runner.app/Frameworks/App.framework/App` · Expected: 찾은 것 없음, 종료 코드 0
- [ ] **Step 5: Commit** — `fix: 운영 빌드 설정 검사와 가짜 구현 제외, Android 기기 이전 차단 추가`

---

## 다(공통) — 실제 연동 공통 장치

### Task 5: 실제 연동 공통 장치

**Files:**
- Create: `api/src/integrations/http/{http-fetch.ts,external-service-error.ts,read-json.ts}`, `api/src/config/required-when-real.ts`, `api/test/support/fake-http-fetch.ts`, `api/test/support/port-contracts/{push,operator-alert,content-draft,store-link,payment,payout,view-count,instagram}.contract.ts`, `docs/integrations/README.md`
- Modify: `api/src/integrations/integrations.module.ts`(`HTTP_FETCH` 제공), 각 가짜 어댑터 spec(계약 테스트 호출)
- Test: `api/src/integrations/http/http-fetch.spec.ts`, `api/src/config/required-when-real.spec.ts`

**Interfaces:**
- Produces:
  - `type HttpFetch = (url: string, init?: RequestInit & { timeoutMs?: number }) => Promise<Response>`, 토큰 `HTTP_FETCH`. 기본 구현은 전역 `fetch` + `AbortSignal.timeout(timeoutMs ?? 10_000)`.
  - `class ExternalServiceError extends Error { constructor(readonly service: string, readonly kind: 'TIMEOUT' | 'UNAVAILABLE' | 'REJECTED' | 'INVALID_RESPONSE', readonly status?: number) }` — 메시지는 `<service> <kind> <status>`뿐.
  - `readJson<T>(service: string, res: Response, guard: (v: unknown) => v is T): Promise<T>` — 4xx → `REJECTED`, 5xx → `UNAVAILABLE`, JSON이 아니거나 guard 실패 → `INVALID_RESPONSE`.
  - `RequiredWhenReal(adapterKey: string): PropertyDecorator` — `ValidateIf(env => env[adapterKey] === 'real')` + `IsString` + `IsNotEmpty`. 실제 어댑터의 비밀값 키마다 붙인다.
  - `class FakeHttpFetch { readonly requests: { method: string; url: string; body: unknown; headers: Record<string, string> }[]; on(method: string, urlPrefix: string, reply: (req) => Response | Promise<Response>): this; hang(method: string, urlPrefix: string): this; readonly fetch: HttpFetch }` — 맞는 규칙이 없으면 던진다(테스트가 실제 밖으로 나가지 않게).
  - 포트 계약: 포트마다 `export function <port>Contract(make: () => Promise<<Port>Harness>): void`가 `it(...)`들을 정의한다. 가짜 spec과 실제 spec이 같은 함수를 부른다. Harness는 그 포트의 상황을 만드는 메서드만 가진다:
    - `PaymentHarness { port; approveAtPg(paymentId, amount): Promise<void>; signedWebhook(paymentId): { rawBody; signature }; tamper(rawBody): string }` — 계약: 서명된 통지 해석, 변조 통지 `null`, `fetchStatus` 승인 반영, 같은 `idempotencyKey`의 환불은 한 번
    - `PayoutHarness`(같은 키 두 번 → 한 번 송금, 실패 응답 → 던짐), `ViewCountHarness`(소유 아님 → false, 읽기 실패 → `ViewCountUnavailableError`), `InstagramHarness`(연결 완료 → 핸들·팔로워·토큰), `PushHarness`(사용자의 모든 기기에 감), `OperatorAlertHarness`(제목·본문 전달), `ContentDraftHarness`(종류마다 장면 3개와 본문), `StoreLinkHarness`(실패 → `StoreLinkAnalysisError`)
  - `docs/integrations/README.md` — 서비스 문서의 틀: 계정·키 이름, 테스트 환경, 쓰는 API(주소·필드·서명), 오류와 재시도, 한도와 요금, 개인정보 국외 이전 여부, 확인한 날짜와 문서 주소.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('times out a hanging request with ExternalServiceError TIMEOUT', ...);
it('maps 4xx to REJECTED and 5xx to UNAVAILABLE without the response body', ...);
it('rejects startup when an adapter is real and its secret is empty', ...);
it('lets every fake adapter pass its port contract', ...);          // 포트마다 contract 호출
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test`
- [ ] **Step 5: Commit** — `feat: 실제 연동 공통 장치와 포트 계약 테스트 추가`

### 연동 Task(11~22)의 공통 단계

각 Task의 단계는 아래 순서다. Task 본문에는 그 Task만의 값과 테스트만 적는다.

- [ ] **Step 0: 소유자 준비 확인** — Task에 적힌 계정·계약·결정·비밀값.
- [ ] **Step 1: 공식 문서 확인** — `docs/integrations/<서비스>.md`를 채운다. 문서로 확인하지 못한 값은 [확인 필요]로 두고 소유자에게 묻는다.
- [ ] **Step 2: 실패하는 테스트 작성** — 그 포트의 계약 테스트를 실제 어댑터(`FakeHttpFetch` 주입)로 부르는 spec, 그리고 Task에 적힌 테스트. 서비스 응답 견본은 Step 1 문서의 예시로 만든다.
- [ ] **Step 3: 실패 확인**
- [ ] **Step 4: 구현** — 어댑터, `env.ts`의 `<NAME>_ADAPTER` 값 `'real'`과 비밀값 키(`RequiredWhenReal`), `api/.env.example`, 모듈의 `real` 분기(지금 `AppError('INTERNAL')`을 던지는 자리), 앱 쪽이 있으면 앱.
- [ ] **Step 5: 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db` (앱이 바뀌면 `./scripts/gen-api.sh`, `cd app && flutter analyze && flutter test`)
- [ ] **Step 6: 스테이징 확인 (소유자 준비 확인)** — 스테이징 비밀값이 들어간 뒤 그 어댑터를 `real`로 스테이징에 배포하고(Task 8 이전이면 로컬 서버에 테스트 환경 키로) Task의 "스테이징 확인"을 한다. 결과를 progress.md에 적는다.
- [ ] **Step 7: Commit** — Task에 적힌 메시지.

---

## 묶음 나 — 운영 기반

### Task 6: 스테이징·운영 Supabase

**Files:**
- Create: `api/scripts/auth-settings-rules.ts`(순수 함수), `api/scripts/auth-settings-rules.spec.ts`, `api/scripts/check-auth-settings.ts`, `docs/launch/supabase-projects.md`
- Modify: `api/package.json`(`check:auth-settings`, jest `roots`에 `<rootDir>/scripts`), `.gitignore`(`api/.env.*`를 막고 `*.example`은 허용하는지 확인)

**Interfaces:**
- Produces:
  - `evaluateAuthSettings(settings: unknown, jwks: unknown, expect: { emailEnabled: boolean; phone: boolean; kakao: boolean }): { ok: boolean; problems: string[] }` — 규칙: 이메일 제공자가 `expect.emailEnabled`와 같음(개발 `true` — 가짜 인증이 이메일을 씀, 스테이징·운영 `false`), 휴대폰·카카오가 기대대로, 익명 가입 꺼짐(응답에 그 필드가 있을 때), JWKS에 `alg: 'ES256'` 키가 하나 이상. 필드 이름은 GoTrue 공개 엔드포인트(`<SUPABASE_URL>/auth/v1/settings`, `/auth/v1/.well-known/jwks.json`) 응답을 실제로 받아 확인하고 `docs/integrations/supabase-auth.md`에 적는다 [확인 필요].
  - `yarn check:auth-settings` — 환경변수 `CHECK_SUPABASE_URL`, `CHECK_SUPABASE_PUBLISHABLE_KEY`(공개 키), `CHECK_EXPECT=dev|staging|prod`. 문제 목록만 출력, 있으면 exit 1.
  - `docs/launch/supabase-projects.md` — 프로젝트별 설정 표와 절차: 마이그레이션(`DIRECT_URL`은 세션 풀러 5432, `schema=public`)으로 `yarn prisma migrate deploy`, `yarn setup:supabase`, 읽기 전용 역할로 `yarn check:rls`, `yarn check:auth-settings`.

- [ ] **Step 0: 소유자 준비 확인** — 서울 지역 Pro 프로젝트 둘(스테이징, 운영). 각 프로젝트: 이메일 제공자 끔, 익명 로그인 끔, 비대칭 서명 키(ES256), 리디렉션 허용 주소 `cora://login-callback`(Task 12), Storage 전역 업로드 한도 300MB 이상(6번 `drafts`), Auth 요청 한도(문자 발송 시간당). 읽기 전용 DB 역할(SQL은 실행자가 준비해 소유자가 실행). 값은 호스팅 비밀 저장소와 로컬 `api/.env.staging`·`api/.env.production`(커밋 안 함, 에이전트는 읽지 않음).
- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('accepts staging settings with email off, phone and kakao on and an ES256 key', ...);
it('reports email login left on in production', ...);
it('reports a project that signs tokens without ES256', ...);
it('allows email login in dev because the fake sign-in uses it', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test`. 개발 프로젝트에 `CHECK_EXPECT=dev yarn check:auth-settings` → 통과.
- [ ] **Step 5: 스테이징·운영 초기화 (소유자 확인 후)** — 두 프로젝트에 `migrate deploy` → `setup:supabase` → `check:rls`(읽기 전용) → `check:auth-settings`(제공자는 Task 11~13 전이라 `phone`·`kakao` 기대값을 그때까지 `false`로). 결과를 문서에 적는다.
- [ ] **Step 6: Commit** — `chore: 스테이징·운영 Supabase 설정 확인 스크립트와 절차 추가`

---

### Task 7: CI

**Files:**
- Create: `.github/workflows/ci.yml`, `docs/launch/ci.md`
- Modify: `api/package.json`(`lint:check` = `--fix` 없는 eslint)

**Interfaces:**
- Produces — `ci.yml`, `push`와 `pull_request`에서:
  - `api`: Node는 `.nvmrc`, `yarn install --frozen-lockfile`, `yarn lint:check`, `yarn test`, `yarn build`
  - `api-db`: `yarn test:e2e && yarn test:db`. 테스트 연결은 개발 DB의 **`cora_ci` 스키마**(로컬의 `cora_test`와 겹쳐 서로의 테이블을 비우지 않게). `concurrency: cora-ci-db`, 이전 실행을 취소하지 않는다.
  - `app`: Flutter `3.44.5` 고정, `flutter analyze && flutter test`
  - `api-contract`: `./scripts/gen-api.sh && git diff --exit-code`
  - `supply-chain`: 서버 의존성 취약점 검사(높음 이상이면 실패, 도구는 실행자가 yarn 1에 맞게), 비밀값 검사(gitleaks, 액션은 커밋 SHA로 고정)
  - `docs/launch/ci.md`: 필요한 GitHub 비밀값 이름(테스트 연결 둘과 e2e가 읽는 나머지 — 이름은 `api/.env.example`의 테스트 부분), `cora_ci` 스키마 설명.

- [ ] **Step 0: 소유자 준비 확인** — GitHub 저장소 비밀값, Actions 사용 한도. CI를 돌려 보려면 push가 필요하다 — 이 시점의 push를 허락받는다.
- [ ] **Step 1: 로컬 확인** — `TEST_*`를 `cora_ci`로 바꾼 셸에서 `node scripts/with-test-db.js …`가 스키마 검사를 통과하는지(스키마가 `public`이 아니면 통과) — 원격 DB에 스키마가 생기므로 소유자 확인 후.
- [ ] **Step 2: push → 모든 작업 초록** (소유자 확인)
- [ ] **Step 3: Commit** — `chore: CI 추가`

---

### Task 8: 컨테이너·호스팅·배포

**Files:**
- Create: `api/Dockerfile`, `api/.dockerignore`, `.github/workflows/deploy.yml`, `api/scripts/smoke.ts`, `docs/launch/deploy.md`

**Interfaces:**
- Produces:
  - 이미지: 두 단계 빌드, 기준 이미지 `node:<LTS>-slim`(digest 고정), 빌드 단계 `yarn install --frozen-lockfile && yarn build`, 실행 단계는 운영 의존성 + `dist` + `prisma/`, 비루트 사용자, `CMD ["node", "dist/main.js"]`. 이미지에 `.env*`, `seed/`, `test/`가 없다. 빌드는 CI에서만 한다.
  - 배포 순서(스테이징: `main`의 CI 통과 뒤 자동 / 운영: `v*` 태그 + GitHub `production` 환경의 소유자 승인): 이미지 빌드·push → 같은 이미지로 일회성 작업 `node_modules/.bin/prisma migrate deploy`(`DIRECT_URL` = 세션 풀러) → 서비스 교체(무중단) → `yarn smoke --base <url>` → 실패하면 이전 판으로 되돌리고 멈춤.
  - `smoke` 확인: `GET /health` 200, `GET /config` 200, `GET /docs` 404, `x-powered-by` 없음, `X-Request-Id` 있음. Task 11 뒤에는 그 환경의 Supabase 테스트 번호(`+821000000001`, 고정 인증번호)로 토큰을 받아 `GET /me` 200 — Review Focus 4.
  - 운영 명령: 같은 이미지의 일회성 작업으로 `node dist/ops-main.js <명령>`(3번 CLI). 절차는 `docs/launch/deploy.md`.
  - `TRUST_PROXY_HOPS`는 호스팅 문서로 정한다. Redis는 TLS, 지속성 켬, BullMQ가 요구하는 메모리 정책 [확인 필요]. WebSocket 연결 시간 한도를 문서에 적는다.

- [ ] **Step 0: 소유자 준비 확인** — 호스팅·Redis 결정과 계정(소유자 결정 7), 컨테이너 레지스트리, 도메인(`api.<도메인>`, `staging-api.<도메인>`), GitHub 환경 `staging`·`production`과 비밀값.
- [ ] **Step 1: 이미지 빌드를 CI에 추가하고 이미지 내용 확인** — 이미지 안에 `.env`·`seed`가 없고 비루트로 뜨는지(CI 로그).
- [ ] **Step 2: `smoke.ts` 작성** — 실패하는 경우 하나(`/docs` 200인 서버)로 exit 1을 확인.
- [ ] **Step 3: 스테이징 배포** (소유자 확인) → smoke 통과.
- [ ] **Step 4: 종료 확인** — 배포 교체 중 진행 중인 요청이 끊기지 않는지(교체하는 동안 `/health` 반복 호출에 실패 없음), 스테이징 WebSocket이 끊긴 뒤 앱(5번)이 다시 연결하는지.
- [ ] **Step 5: 요청 IP 확인 (Review Focus 1)** — 스테이징 보안 로그의 `ip`가 호스팅 프록시 주소가 아니라 요청한 기기의 공인 IP인지. 아니면 `TRUST_PROXY_HOPS`를 고친다.
- [ ] **Step 6: Commit** — `chore: 서버 이미지와 스테이징·운영 배포 추가`

---

### Task 9: 오류 추적·백업 복구

**Files:**
- Create: `api/src/common/observability/error-reporter.ts`, `app/lib/core/observability/error_reporter.dart`, `docs/launch/backup-restore.md`
- Modify: `api/src/main.ts`, `api/src/common/errors/all-exceptions.filter.ts`(5xx만 보고), `app/lib/main.dart`
- Test: `api/src/common/observability/error-reporter.spec.ts`, `app/test/core/observability/error_reporter_test.dart`

**Interfaces:**
- Produces:
  - `scrubEvent(event): event` (서버) — 요청 헤더의 `authorization`·`cookie`, 쿼리, 본문, 사용자 이메일·전화를 지우고 `requestId` 태그를 단다. 4xx `AppError`는 보내지 않는다.
  - `scrubBreadcrumb(String) → String` (앱) — `01\d{8,9}`와 `+82\d+` 꼴을 `[phone]`, `eyJ…` 꼴을 `[token]`으로 바꾼다. 개발 빌드는 보내지 않는다.
  - 가동 확인: 호스팅이나 외부 감시가 운영 `/health`를 1분마다 부르고, 실패하면 `OPERATOR_EMAIL`로 알린다.

- [ ] **Step 0: 소유자 준비 확인** — 오류 추적 서비스 결정과 계정(소유자 결정 8), 데이터 지역 확인(국외 이전이면 Task 23 처리방침 목록에).
- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('strips authorization headers, query strings and bodies from reported events', ...);
it('does not report 4xx app errors', ...);
```
```dart
test('replaces phone numbers and tokens in breadcrumbs', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 복구 연습 (소유자 준비 확인)** — 스테이징에서 일일 백업으로 복구해 보고, 걸린 시간과 잃은 범위를 `docs/launch/backup-restore.md`에 적는다(설계 5장).
- [ ] **Step 6: Commit** — `feat: 서버·앱 오류 추적과 개인정보 거르기 추가`, `docs: 백업 복구 연습 기록`

---

### Task 10: 앱 빌드와 서명

**Files:**
- Create: `app/config/staging.json.example`, `app/config/prod.json.example`, `.github/workflows/app-release.yml`, `docs/launch/app-release.md`
- Modify: `app/ios/Runner.xcodeproj`(서명 팀, 기능), `app/android/app/build.gradle.kts`(릴리스 서명 설정을 CI 비밀값에서 읽음)

**Interfaces:**
- Produces:
  - 빌드: `flutter build ipa --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=config/<env>.json`, `flutter build appbundle` 같은 옵션. 빌드 번호는 CI 실행 번호, 버전 이름은 `pubspec.yaml`. 기호 파일은 오류 추적 서비스에 올린다.
  - 같은 작업 안에서 먼저 난독화하지 않은 운영 빌드로 `scripts/check-release-binary.sh`를 돌린다(Task 4).
  - 스테이징 빌드 = `CORA_ENV=prod` + 스테이징 주소 → TestFlight 내부 테스트, Play 내부 테스트 트랙. 운영 빌드는 Task 28에서 같은 작업으로.
  - 확인 항목(문서에): Play의 `targetSdk` 요구 [확인 필요], iOS 수출 규정(암호화) 답 [확인 필요], 개인정보 매니페스트 [확인 필요].

- [ ] **Step 0: 소유자 준비 확인** — Apple Developer Program(조직, D-U-N-S), App Store Connect 앱(번들 ID `com.cora.cora` 확정 — 올린 뒤 못 바꿈), 배포 인증서·프로파일 또는 App Store Connect API 키, Google Play Console(조직 계정), 업로드 키스토어(소유자가 만들고 보관), Play App Signing, CI 비밀값.
- [ ] **Step 1: 워크플로 작성 → 스테이징 빌드를 내부 테스트에 올림** (소유자 확인)
- [ ] **Step 2: 내부 테스트 설치 확인** — 두 플랫폼에서 앱이 뜨고 스테이징에 붙는다.
- [ ] **Step 3: Commit** — `chore: 앱 운영 빌드와 서명, 내부 테스트 배포 추가`

---

## 묶음 다 — 연동 교체

### Task 11: 휴대폰 인증 (Supabase 휴대폰 OTP + SMS)

**Step 0 소유자 준비 확인:** SMS 방식은 국내 SMS 업체 + Supabase Send SMS Hook(서버가 받아 보냄)이다(소유자 결정 2, 2026-11-11 소유자 결정). 업체 계정, (국내 업체면) 발신번호 사전 등록, 문자 문구(제안 `[Cora] 인증번호 {code}`), 스테이징 키. 스테이징·운영 Supabase에 휴대폰 로그인 켬, 테스트 번호 `+821000000001`과 고정 인증번호 등록(Supabase의 테스트 번호 기능 [확인 필요]).

**Files:**
- Create (앱): `app/lib/features/auth/data/supabase_sign_in_adapter.dart`
- Modify (앱): `app/lib/main.dart`, `app/lib/core/config/app_config.dart`(`assertAuthAdapterStartable`이 `real`을 받음), `app/lib/features/auth/data/supabase_failures.dart`, `app/lib/features/auth/presentation/viewmodels/phone_verify_view_model.dart`, `phone_verify_page.dart`
- Create (서버): `api/src/integrations/sms/{sms.port.ts,fake-sms.adapter.ts,<vendor>-sms.adapter.ts}`, `api/src/auth-hooks/{auth-hooks.module.ts,auth-hooks.controller.ts,hook-signature.ts}`
- Test: `app/test/features/auth/data/supabase_sign_in_adapter_test.dart`, `app/test/features/auth/presentation/viewmodels/phone_verify_view_model_test.dart`(추가), `api/src/auth-hooks/hook-signature.spec.ts`, `api/test/auth-hooks.e2e-spec.ts`

**Interfaces:**
- Produces (앱):
  - `class SupabaseSignInAdapter implements SignInAdapter` — `requestPhoneCode(digits)` → `signInWithOtp(phone: toE164(digits))`, `verifyPhoneCode` → `verifyOTP(type: sms)`. 카카오·네이버 메서드는 Task 12·13 전까지 `AuthFailure.unknown('not_configured')`.
  - `String toE164(String digits)` — `'01000001234'` → `'+821000001234'`.
  - 오류 해석: 만료·틀린 인증번호 → `invalidCode`, 요청이 너무 잦음 → `unknown('rate_limited')`(화면 `잠시 후 다시 시도해 주세요.`), 연결 실패 → `network`.
  - `main.dart`의 `else` 쪽(Task 4)을 `SupabaseSignInAdapter`로. 운영에서 `real`이 아니면 시작 거부는 그대로.
  - 인증번호 만료: `sent && remaining == Duration.zero`이면 `확인`이 꺼지고 `PhoneVerifyNotice.expired`(문구 소유자 확인, 제안 `인증번호가 만료됐어요. 다시 보내 주세요.`).
- Produces (서버):
  - `abstract class SmsPort { abstract send(input: { phoneE164: string; text: string }): Promise<void> }`, `FakeSmsAdapter`(번호 없이 "보냄"만 로그), `SMS_ADAPTER: 'fake' | 'real'`, `SEND_SMS_HOOK_SECRET`.
  - `POST /auth-hooks/send-sms` — `@Public()`, `@SkipThrottle()`, Swagger 제외, 원문 본문. 서명(Supabase가 쓰는 웹훅 서명 형식 [확인 필요])과 시각(5분 이내)을 확인하고, 틀리면 401 + `WEBHOOK_REJECTED`. 맞으면 `SmsPort.send` → 200 `{}`.

- 테스트:

```dart
test('formats 010 numbers as +82 for supabase', ...);
test('maps an expired or wrong code to invalidCode', ...);
test('maps too many requests to the try later notice', ...);
test('disables confirm once the code has expired and shows the expired notice', ...);
```
```ts
// 서버 (SMS Hook)
it('sends the code through SmsPort for a valid hook signature', ...);
it('rejects a hook with a bad signature or a timestamp older than five minutes', ...);   // SmsPort 호출 0
it('never logs the phone number or the code', ...);
it('throws in production when SMS_ADAPTER is fake', ...);
```

- **스테이징 확인:** 소유자 휴대폰으로 E1 → E2 문자 수신 → 로그인 → A1. 3분 만료 뒤 `확인` 꺼짐, `다시 보내기`, 틀린 인증번호 문구. 테스트 번호로 `smoke`의 `GET /me` 통과.
- **Commit:** `feat: 실제 휴대폰 인증과 문자 발송 연결`

---

### Task 12: 카카오 로그인

**Step 0 소유자 준비 확인:** Kakao Developers 앱, 비즈 앱 전환 필요 여부와 동의 항목(Supabase 카카오 제공자가 요구하는 항목, 이메일을 받지 않을 수 있는지 [확인 필요]), REST API 키·클라이언트 시크릿을 스테이징·운영 Supabase에 입력, Supabase 콜백 주소를 카카오에 등록.

**Files:**
- Modify: `app/lib/features/auth/data/supabase_sign_in_adapter.dart`, `app/ios/Runner/Info.plist`(`cora` 스킴이 있는지), `app/android/app/src/main/AndroidManifest.xml`(`cora://login-callback`), `app/lib/core/navigation/app_router.dart`(로그인 콜백 주소를 라우트로 다루지 않음)
- Test: `app/test/features/auth/data/supabase_sign_in_adapter_test.dart`(추가), `app/test/core/navigation/app_router_test.dart`(추가)

**Interfaces:**
- Produces:
  - 1안(추천): Supabase OAuth — `signInWithOAuth(OAuthProvider.kakao, redirectTo: 'cora://login-callback')`, PKCE(1번이 이미 보안 저장소에 둠). 2안: 카카오 네이티브 SDK로 카카오톡 앱 로그인 + `signInWithIdToken` — Supabase가 카카오 ID 토큰을 받는지 [확인 필요]. 1안으로 시작하고, 카카오톡 앱 전환이 꼭 필요하면 소유자와 정한다.
  - `abstract class OAuthLauncher { Future<void> launch(OAuthProvider provider, {required String redirectTo}); }` — `SupabaseSignInAdapter`가 주입받는다(테스트용).
  - 사용자가 창을 닫고 돌아오면 안내 없이 버튼이 다시 켜진다.
  - 휴대폰으로 가입한 사람이 카카오로 들어오면 다른 계정이 된다(계정 연결은 설계에 없음 — 소유자 결정 4).
- 테스트:

```dart
test('starts kakao oauth with the cora login callback', ...);
test('returns to the login screen without a notice when the user cancels', ...);
testWidgets('does not route cora://login-callback to a not-found page', ...);
```

- **스테이징 확인:** 실기기 두 대에서 카카오 로그인 → A1, 다시 켰을 때 세션 유지, 로그아웃.
- **Commit:** `feat: 카카오 로그인 연결`

---

### Task 13: 네이버 로그인

**Step 0 소유자 준비 확인:** 네이버 개발자센터 앱(네이버 로그인, 받을 정보는 고유 식별자만), 방식 결정(소유자 결정 3).

- **A안** — Supabase가 사용자 정의 OAuth 제공자를 지원하면 [확인 필요]: 대시보드 설정 + Task 12와 같은 OAuth 길. 서버 코드 없음. 앱은 `signInWithNaver()`가 같은 `OAuthLauncher`를 쓴다.
- **B안** — 서버 중계. 아래가 B안의 내용이다.

**Files (B안):**
- Create: `api/src/external-auth/{external-auth.module.ts,naver-auth.controller.ts,naver-auth.service.ts,external-identities.repository.ts}`, `api/src/integrations/naver-auth/{naver-auth.port.ts,fake-naver-auth.adapter.ts,naver-auth.adapter.ts}`, `api/src/integrations/auth-admin/{auth-admin.port.ts,supabase-auth-admin.adapter.ts}`, 마이그레이션
- Modify: `app/lib/features/auth/data/supabase_sign_in_adapter.dart`
- Test: `api/src/external-auth/naver-auth.service.spec.ts`, `api/test/naver-auth.e2e-spec.ts`, `app/test/features/auth/data/supabase_sign_in_adapter_test.dart`(추가)

**Interfaces (B안):**
- `ExternalIdentity` → `external_identities`: `id`, `provider`(`NAVER`), `providerUserId`, `userId`, unique(`provider`, `providerUserId`). RLS.
- `NaverLoginTicket` → `naver_login_tickets`: `id`, `challenge`(SHA-256 hex), `state`(unique), `userId?`, `expiresAt`(생성 + 5분), `usedAt?`. RLS.
- `NaverAuthPort { authorizeUrl(state: string): string; exchange(code: string, state: string): Promise<{ providerUserId: string }> }`, `NAVER_AUTH_ADAPTER: 'fake' | 'real'`. 가짜: `code`가 `naver-dev-<n>`이면 `providerUserId = <n>`.
- `AuthAdminPort { createUser(): Promise<{ userId: string }>; issueSignInToken(userId: string): Promise<{ tokenHash: string }>; deleteUser(userId: string): Promise<void> }` — Supabase 관리 API(서비스 역할 키). Storage처럼 가짜/실제 전환 대상이 아니고 테스트는 `FakeAuthAdminPort`. `issueSignInToken`이 쓰는 Supabase 기능과, 운영에서 이메일 제공자를 끈 채로 되는지 [확인 필요] — 안 되면 설계 3.1과 충돌(어긋나는 점 1).
- 흐름:
  1. 앱이 `verifier`(32바이트 무작위)를 만들고 `POST /auth/naver/start { challenge: sha256(verifier) }` → `{ authorizeUrl }`. 서버가 `state`를 만들어 티켓에 저장.
  2. 앱이 웹 인증 창으로 `authorizeUrl`을 연다. 네이버가 `GET /auth/naver/callback?code&state`(`@Public`)로 돌아온다 → 서버가 `state` 확인 → `exchange` → `external_identities`로 사용자를 찾거나 `createUser`로 만든다 → 티켓에 `userId` → `cora://login-callback/naver?ticket=<id>`로 보낸다(토큰은 주소에 싣지 않는다).
  3. 앱이 `POST /auth/naver/redeem { ticket, verifier }` → 서버가 `sha256(verifier) == challenge`, 미사용, 미만료를 확인하고 `usedAt` → `issueSignInToken` → `{ tokenHash }` → 앱이 Supabase `verifyOTP(tokenHash)`로 세션을 받는다.
  4. 세 경로 모두 IP 기준 분당 `10`회.
- 테스트:

```ts
it('creates one cora user per naver id and reuses it on the next login', ...);
it('rejects a callback whose state the server did not issue', ...);
it('rejects a redeem with the wrong verifier, an expired ticket or a used ticket', ...);
it('puts only the ticket id in the app redirect', ...);                 // Location에 tokenHash 없음
it('throws in production when NAVER_AUTH_ADAPTER is fake', ...);
```
```dart
test('redeems the naver ticket with the verifier it generated', ...);
test('treats a closed browser as a cancel', ...);
```

- **스테이징 확인:** 실기기 두 대에서 네이버 로그인 → A1, 두 번째 로그인이 같은 계정.
- **Commit:** `feat: 네이버 로그인 연결`

---

### Task 14: Apple 로그인 (2026-11-11 소유자 결정: 넣기)

**Step 0 소유자 준비 확인:** 캔버스의 E1에 Apple 버튼 디자인(라이트·다크). 화면은 캔버스와 100% 같게 만드는 규칙이라 **소유자가 artifact의 E1을 먼저 고친다** — 그 전에는 이 Task를 시작하지 않는다. 그 뒤 Apple Developer의 Services ID·키를 Supabase에 입력(소유자 결정 5).

- iOS에서만 버튼을 보인다. 네이티브 Apple 로그인 → `signInWithIdToken(provider: apple, idToken, nonce)`.
- 탈퇴 때 Apple 쪽 연결 해제(공통 모델 20장)를 Task 25의 참여자로 넣는다: `AppleRevokePort { revoke(userId: string): Promise<void> }`(토큰 보관 방식은 Apple 문서 [확인 필요]).
- 테스트: `test('shows the apple button on iOS only', ...)`, `test('signs in with the apple id token and nonce', ...)`, `it('revokes apple when an apple user deletes the account', ...)`.
- **Commit:** `feat: Apple 로그인 연결`

---

### Task 15: 푸시

**Step 0 소유자 준비 확인:** Firebase 프로젝트(스테이징·운영 따로 제안), Android·iOS 앱 등록과 설정 파일, APNs 인증 키(.p8)를 Firebase에 올림, 서버용 서비스 계정 키, iOS Push Notifications 기능.

**Files:**
- Create: `api/src/devices/{devices.module.ts,devices.controller.ts,devices.service.ts,devices.repository.ts,dto/*}`, `api/src/integrations/push/fcm-push.adapter.ts`, 마이그레이션, `app/lib/core/push/{push_token_registrar.dart,push_permission_prompter.dart,push_target.dart}`
- Modify: `api/src/integrations/integrations.module.ts`, `app/lib/main.dart`, 2번의 가게 공개 성공 자리, 크리에이터 첫 지원 성공 자리, `app/lib/core/navigation/app_router.dart`, 플랫폼 설정(Android 13+ 알림 권한, iOS 기능)
- Test: `api/src/devices/devices.service.spec.ts`, `api/test/devices.e2e-spec.ts`, `api/src/integrations/push/fcm-push.adapter.spec.ts`, `app/test/core/push/*_test.dart`

**Interfaces:**
- Produces:
  - `DeviceToken` → `device_tokens`: `id`, `userId`, `token`(unique), `platform`(`IOS | ANDROID`), `lastUsedAt`, `createdAt`. RLS.
  - `PUT /devices` `{ token(1~4096자), platform }` → 204. 같은 토큰이 다른 사용자에게 있으면 지금 사용자로 옮긴다(한 기기에서 계정을 바꾼 경우). `DELETE /devices/:token` → 204(내 것만 지우고, 없어도 204). `operationId: registerDevice`, `unregisterDevice`.
  - `PushPort.send`의 모양은 3번 계획 Task 3A가 정한 것을 그대로 쓴다: `send(input: { userId: string; title: string; body: string; data?: { notificationId: string | null; targetKind: string; targetId: string | null; role: string } })`. 기능 모듈은 `NotificationsService.notify`만 부르고, 방해 금지·E5 스위치도 그 서비스가 본다. 이 Task는 호출부를 고치지 않는다.
  - `FcmPushAdapter` — 그 사용자의 모든 기기에 보내고 `data`를 FCM 데이터(문자열 값)로 싣는다. 서비스가 "등록되지 않은 토큰"으로 답하면 그 행을 지운다. 일시 오류는 한 번 다시 시도한다. 로그에는 기기 행 ID만, 토큰 원문과 알림 본문은 남기지 않는다. `PUSH_ADAPTER: 'fake' | 'real'`, 비밀값 `FCM_SERVICE_ACCOUNT_JSON`.
  - 앱 `PushTokenRegistrar` — 로그인 뒤와 토큰 갱신 때 `PUT /devices`, 로그아웃 직전 `DELETE /devices/:token`(실패해도 로그아웃은 계속).
  - 앱 `PushPermissionPrompter.askAt(PushAskMoment moment)` — `storePublished`(가게 공개 성공 직후), `firstApplication`(크리에이터 첫 지원 직후). 기기 권한 창은 앱 생애에 한 번만 띄운다(첫 실행에는 묻지 않는다).
  - 앱 `String? pushTargetToLocation({required String targetKind, String? targetId, required UserRole role})` — 앱이 꺼진 상태에서 탭(`getInitialMessage`)과 켜진 상태 모두. E3 알림함 줄을 눌렀을 때와 같은 표를 쓴다(3번 Task 13C의 `locationFor`를 그대로 부른다). 모르는 `targetKind`는 역할 첫 화면. 알림의 `role`이 지금 역할과 다르면(한 계정에 역할이 여럿일 때) 먼저 `PATCH /me/role`로 바꾼 뒤 이동한다. `notificationId`가 있으면 읽음 처리(`POST /notifications/:id/read`).
- 테스트:

```ts
it('moves a device token to the current user when another user had it', ...);
it('sends to every device of the user and deletes tokens reported as unregistered', ...);
it('never logs the token or the notification body', ...);
it('carries notificationId, target and role as string data', ...);
it('throws in production when PUSH_ADAPTER is fake', ...);              // 1번에 있던 것 유지
```
```dart
test('registers the token after sign in and unregisters it before sign out', ...);
test('asks for permission once, at the first meaningful moment', ...);
test('opens the conversation when a message notification is tapped from a cold start', ...);
test('switches role before opening a notification sent to another role', ...);
test('marks the notification read when it is opened from a push', ...);
```

- **스테이징 확인:** iOS·Android 실기기에서 지원·오퍼·메시지·정산 알림을 받고 탭해 각 화면으로 간다. 앱을 지웠다 깔면 옛 토큰이 다음 발송에서 지워진다.
- **Commit:** `feat: 실제 푸시 알림과 기기 토큰 등록, 알림 탭 이동 추가`

---

### Task 16: 운영자 알림 메일

**Step 0 소유자 준비 확인:** 발송 서비스 결정과 계정(소유자 결정 9), 보내는 도메인의 SPF·DKIM, `OPERATOR_EMAIL` 값.

- `EmailOperatorAlertAdapter implements OperatorAlertPort` — `OPERATOR_ALERT_ADAPTER: 'fake' | 'real'`, 비밀값은 서비스의 키와 `OPERATOR_ALERT_FROM`.
- 발송은 작업 큐의 `operator-alert` 작업으로 하고 최대 `3`번 다시 시도한다(호출한 쪽이 메일 서비스 장애로 실패하지 않게).
- `sanitizeAlertBody(text: string): string` — 전화번호·토큰 꼴을 가린다. 모든 알림이 거친다.
- 테스트: `it('retries a failed send up to three times through the job queue', ...)`, `it('masks phone numbers and tokens in alert bodies', ...)`, 계약 테스트.
- **스테이징 확인:** 신고 하나 → 메일 수신, 조회수 실패 3일(가짜 조회수 `unavailable`) → 메일 수신(공통 모델 19장).
- **Commit:** `feat: 운영자 알림 메일 연결`

---

### Task 17: AI 초안 (LLM)

**Step 0 소유자 준비 확인:** 후보 LLM 계정(둘 이상), 견본 비교에 드는 요금 승인, 월 상한 값.

**Files:**
- Create: `api/scripts/compare-drafts.ts`, `docs/integrations/llm-compare.md`, `api/src/integrations/content-draft/llm-content-draft.adapter.ts`, `api/src/content-drafts/llm-usage.repository.ts`, 마이그레이션
- Modify: `api/src/integrations/integrations.module.ts`, 2번·6번의 초안 서비스(실패 문구, 월 상한)
- Test: `api/src/integrations/content-draft/llm-content-draft.adapter.spec.ts`, `api/test/db/llm-usage.db-spec.ts`

**Interfaces:**
- Produces:
  - 견본 비교(설계 9장): 견본 가게 10곳(`api/seed/mock`과 2번 가짜 값) × 초안 종류 × 후보 모델로 만들고, 형식 성공률·글자 수·지연·예상 요금을 `llm-compare.md` 표로. 후보: `claude-haiku-5-5`, `claude-sonnet-5-5`, 그리고 소유자가 고른 다른 회사 모델 하나. 소유자가 결과를 보고 고른다.
  - `LlmContentDraftAdapter implements ContentDraftPort`(6번이 같은 포트에 더한 장면·재협업 메시지 메서드 포함). 입력은 가게·캠페인의 공개 정보뿐(포트 입력이 이미 그렇다 — 테스트로 고정). 출력은 정해진 JSON 구조(Claude면 구조화 출력 `output_config.format`). 거절(`stop_reason: "refusal"`)이나 구조 불일치는 한 번 다시 요청하고, 또 실패하면 `ContentDraftUnavailableError` → 화면 `지금은 초안을 만들 수 없어요. 잠시 뒤 다시 시도해 주세요.`(설계 3.4).
  - `LlmUsageMonth` → `llm_usage_months`: `month`(한국 시간 `YYYY-MM`, PK), `requests`, `inputTokens`, `outputTokens`, `limitAlertedAt?`. RLS.
  - `CONTENT_DRAFT_MONTHLY_REQUEST_LIMIT`(정수). 호출 전에 `UPDATE … SET requests = requests + 1 WHERE month = ? AND requests < ?`로 하나 잡고, 0행이면 생성을 멈추고 같은 실패 문구. 그 달 처음 한 번만 `OperatorAlertPort.alert({ subject: '[Cora] AI 초안 월 상한 도달' })`. 2번의 하루 10번은 그대로.
- 테스트:

```ts
it('sends only the public store fields to the model', ...);           // FakeHttpFetch 요청 본문
it('retries once when the output does not match the schema and then fails', ...);
it('treats a refusal as a failed draft', ...);
it('stops at the monthly limit and alerts the operator once', ...);
it('never exceeds the monthly limit under concurrent requests', ...);  // db-spec, Promise.all
```

- **스테이징 확인:** 2번의 A4 세 종류와 6번의 장면·재협업 메시지가 한국어로 자연스럽게 나오는지 소유자가 본다.
- **Commit:** `feat: 실제 AI 초안 생성과 월 사용 상한 추가`

---

### Task 18: 가게 링크 분석

**Step 0 소유자 준비 확인:** 약관 확인 결과(설계 3.3) — 표의 어느 경우인지, 지역 검색 API를 쓸지와 키. 경우 3(받을 수 없음)이면 A2를 "가게 이름으로 시작하기"로 바꾸는 것은 캔버스 변경이라 이 Task에서 하지 않고 소유자와 따로 정한다.

기본 결정(설계 9장): 받을 수 있는 정보만 채우고 나머지는 사장님이 입력한다. 아래는 경우 2(이름·주소 정도)의 구현이다.

**Interfaces:**
- `LinkPreviewStoreLinkAdapter implements StoreLinkPort` — 주입받는 것: `HttpFetch`, `resolveHost: (host: string) => Promise<string[]>`.
  - 허용 호스트 목록 `STORE_LINK_ALLOWED_HOSTS`(쉼표 구분, 기본값은 Step 1 문서로 정한 네이버 지도·단축 주소·캐치테이블·인스타그램 호스트), `https`만.
  - 리다이렉트는 직접 따라가며 최대 `3`번, 매번 허용 목록과 주소를 다시 확인. 해석한 주소가 사설·루프백·링크 로컬·메타데이터 주소면 거절.
  - 응답은 `1MB`, `5`초까지. 약관이 허용하는 범위(예: Open Graph 제목·설명)만 읽는다. 지역 검색 API로 주소·업종·시도·구군 보강(쓰기로 했을 때).
  - 사진은 저작권 확인 전까지 가져오지 않는다(`coverPhoto: null`, 사장님이 올림).
  - 아무것도 못 얻으면 `StoreLinkAnalysisError` → 2번의 직접 입력 흐름.
- 테스트:

```ts
it('refuses non-https links and hosts outside the allow list', ...);
it('refuses a redirect to a private address', ...);   // 10.0.0.1, 127.0.0.1, 169.254.169.254, ::1
it('stops after three redirects', ...);
it('stops reading after one megabyte', ...);
it('reads only the allowed fields from the page', ...);
it('returns no cover photo until photo use is confirmed', ...);
```

- **스테이징 확인:** 실제 네이버 지도·캐치테이블 링크 세 개로 A3까지, 실패 링크로 직접 입력 흐름.
- **Commit:** `feat: 실제 가게 링크 분석 연결`

---

### Task 19: 결제 (PG)

**Step 0 소유자 준비 확인:** 법률 확인(대금 보관 구조, 설계 3.5) 결과, PG 결정(소유자 결정 6)·계약·심사, 테스트·실제 키, 통지 주소 등록(스테이징·운영의 3번 통지 경로), PG가 요구하는 앱 설정(카드사·간편결제 앱 호출 목록).

**Files:**
- Create: `api/src/integrations/payment/<pg>-payment.adapter.ts`, `docs/integrations/<pg>.md`, 앱 `app/lib/features/payment/data/<pg>_checkout_launcher.dart`
- Modify: `api/src/integrations/payment/{payment.port.ts,fake-payment.adapter.ts}`(아래 `handleReturn`이 필요할 때만), 3번 `payments` 컨트롤러·서비스, `app/lib/features/payment/…`(`checkoutLauncherProvider`), iOS `Info.plist`(`LSApplicationQueriesSchemes`), Android 매니페스트(`<queries>`)
- Test: `api/src/integrations/payment/<pg>-payment.adapter.spec.ts`, `api/test/payments-real.e2e-spec.ts`, `app/test/features/payment/*_test.dart`

**Interfaces:**
- Produces:
  - `<Pg>PaymentAdapter implements PaymentPort`: `createCheckout`(PG의 결제 요청 값으로 `checkoutUrl` — 웹 결제창 주소 또는 앱 SDK에 넘길 값을 담은 내부 주소 `cora-pay://<pg>?paymentId=…`, 어느 쪽인지는 PG 문서로), `verifyWebhook`(서명이 있으면 검증, 없거나 틀리면 `null` — 컨트롤러는 `null`이면 `fetchStatus`로 다시 묻는다), `fetchStatus`(3번의 10분 재확인 작업이 쓴다), `refund`(부분 취소 + `idempotencyKey`).
  - PG가 결제창 복귀 뒤 서버의 승인 요청을 요구하면: `PaymentPort.handleReturn(params: Record<string, string>): Promise<{ paymentId: string; pgTransactionId: string; status: 'APPROVED' | 'FAILED' } | null>`를 더하고(가짜는 `null`), `GET /payments/return`(`@Public`)이 부른 뒤 통지와 같은 `PaymentsService.applyResult`로 넘기고 `cora://payments/<id>/done`으로 보낸다. 승인 요청에는 쿼리의 금액이 아니라 DB의 `amountEscrow + amountFee`를 쓴다.
  - 승인 결과의 금액이 DB와 다르면 `FAILED`로 두고 PG 취소를 요청하고 `OperatorAlertPort`. 시간 초과는 `PENDING`으로 두어 재확인 작업이 맞춘다.
  - 앱 `<Pg>CheckoutLauncher implements CheckoutLauncher` — `cora-dev://`가 아닌 주소를 PG 결제창(SDK 또는 앱 안 웹뷰)으로 연다. 결제창을 닫거나 실패해도 결과는 서버가 정한다(3번 흐름 그대로: 돌아오면 서버에 묻는다).
- 테스트:

```ts
it('approves only when the pg amount equals the stored amount', ...);
it('rechecks with the pg when a webhook has no valid signature', ...);
it('applies one approval when the return and the webhook arrive together', ...);
it('refunds the remaining amount once per idempotency key', ...);
it('leaves a timed out approval PENDING for the ten minute recheck', ...);
it('throws in production when PAYMENT_ADAPTER is fake', ...);
```
```dart
testWidgets('opens the pg checkout for a non-dev checkout url', ...);
testWidgets('asks the server for the result after the checkout closes', ...);
```

- **스테이징 확인 (PG 테스트 환경):** 3번 Task 14의 수동 확인 1~3·8, 5번 브랜드 결제, 카드·계좌이체·간편결제 각 한 번, 결제창을 닫고 10분 뒤 재확인으로 맞춰지는지.
- **Commit:** `feat: 실제 PG 결제와 환불 연결`

---

### Task 20: 지급 (지급 대행)

**Step 0 소유자 준비 확인:** 지급 대행 계약, 계좌 실명 확인 기능, 법률·세무 확인 결과(크리에이터 지급의 원천징수, 그에 필요한 개인정보 — 주민등록번호를 받게 되는지, 사업자 크리에이터 처리). **원천징수가 필요하다는 결과면 이 Task를 멈추고 소유자에게 묻는다**(지급액 계산·장부·수집 정보와 E7의 "원천징수 3.3%" 줄이 함께 바뀌어 별도 설계가 필요하다). 송금은 매주 수요일에 모아서 한다(2026-11-11 소유자 결정, 3번 Task 8) — 어댑터는 지급 한 건씩 보내므로 이 Task는 바뀌지 않는다.

**Interfaces:**
- `<Pg>PayoutAdapter implements PayoutPort` — `PAYOUT_ADAPTER: 'fake' | 'real'`.
- 서비스가 받는 사람을 먼저 등록해야 하면: `PayoutPort.registerPayee(input: { creatorId: string; bankCode: string; accountNumber: string; holderName: string }): Promise<{ payeeId: string }>`, `payout_accounts.payeeId` 칸, `send`는 `payeeId`를 받는다(3번 계좌 등록·지급과 가짜 구현을 함께 고친다).
- 계좌 실명 확인: 3번 `PUT /payout-account`에서 서비스로 예금주를 확인하고 다르면 409 `CONFLICT`(문구 소유자 확인, 제안 `예금주 이름이 계좌와 달라요.`).
- 지급이 접수 → 완료로 나뉘면 통지·조회로 `payouts.status`(`PENDING | DONE | FAILED`)를 맞춘다. 실패는 3번대로 운영자 알림과 크리에이터 안내.
- 테스트:

```ts
it('registers the payee once and reuses it', ...);
it('refuses an account whose holder name does not match', ...);
it('does not pay twice when the payout job retries', ...);
it('marks a payout failed from the service result and alerts the operator', ...);
```

- **스테이징 확인:** 3번 Task 14의 수동 확인 6·7·10.
- **Commit:** `feat: 실제 지급 대행과 계좌 실명 확인 연결`

---

### Task 21: 인스타그램 연결·가져오기

**Step 0 소유자 준비 확인:** Meta 개발자 앱, 앱 심사 통과(필요한 권한의 정확한 이름, 개인 계정 가능 여부 [확인 필요] — 설계 3.6), 심사용 동작 영상(가짜 구현 흐름으로, 7번 완료 뒤), 개인정보 처리방침 주소(Task 23), 리디렉션 주소 `https://<api 도메인>/instagram/callback`(스테이징·운영).

**Interfaces:**
- `MetaInstagramAdapter implements InstagramPort` — `INSTAGRAM_ADAPTER: 'fake' | 'real'`.
  - `beginConnect(creatorId)` → 인증 주소. 서버가 만든 `state`를 `instagram_connect_states`(`state` unique, `creatorId`, `expiresAt` = 10분)에 저장.
  - `completeConnect(creatorId, code)` → 장기 토큰, 계정 종류 확인(프로페셔널이 아니면 `InstagramNotProfessionalError`), 핸들·팔로워. `fetchFollowers`, `listPosts`, `downloadMedia`(7번).
- `GET /instagram/callback?code&state` — `@Public`. `state` 확인 → `completeConnect` → `cora://instagram/connected` 또는 `cora://instagram/failed?reason=NOT_PROFESSIONAL|DENIED|EXPIRED`. 코드와 토큰은 앱 주소에 싣지 않는다.
- 토큰은 3번 `seal`로 저장. 만료 전 갱신 작업 `instagram-token-refresh`(매일, 만료 기간은 문서 [확인 필요]). 갱신 실패나 권한 철회 → 연결을 끊긴 상태로 표시하고 크리에이터에게 푸시(문구 소유자 확인, 제안 `인스타그램 연결이 끊겼어요. 다시 연결해 주세요.`). 집계 중이면 3번의 3일 규칙이 적용된다(설계 3.6).
- 7번이 미룬 가져오기 비동기화: `POST /instagram/imports` → 202 `{ importId }`, `GET /instagram/imports/:id` → `{ status: 'RUNNING' | 'DONE'; items; skipped }`. 작업 `instagram-import`가 하나씩 복사하고 실패는 `skipped`에 남긴다. 앱 B 화면은 끝날 때까지 묻고 7번의 진행 문구를 쓴다.
- 앱: 3번 연결 화면이 `cora-dev://`가 아닌 주소를 웹 인증 창으로 열고 `cora://instagram/…` 복귀를 받는다. `NOT_PROFESSIONAL`이면 8번이 쓰는 문구 `개인 계정은 연동할 수 없어요. 인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 다시 연동해 주세요.`
- 테스트:

```ts
it('rejects a callback with an unknown or expired state', ...);
it('reports a personal account as NOT_PROFESSIONAL without saving a connection', ...);
it('stores the long-lived token sealed and never logs it', ...);
it('marks the connection broken and notifies the creator when refresh fails', ...);
it('imports posts in a job and records skipped ones', ...);
```
```dart
testWidgets('shows the professional account guide when a personal account is refused', ...);
testWidgets('waits for the import to finish before showing the result', ...);
```

- **스테이징 확인 (Meta 테스트 사용자):** 연결 → 팔로워 표시 → 게시물 10개 가져오기 → 개인 계정으로 연결 시 안내.
- **Commit:** `feat: 실제 인스타그램 연결과 게시물 가져오기 연결`

---

### Task 22: 조회수 (인스타그램·쇼츠)

**Step 0 소유자 준비 확인:** Meta 인사이트 권한(Task 21 심사에 포함), 유튜브 Data API 키, 쇼츠 소유 확인 방식(소유자 결정 12).

**Interfaces:**
- `CompositeViewCountAdapter implements ViewCountPort` — 주소로 나눈다: 인스타그램 릴스·게시물 → `InstagramViewSource`(연결 토큰으로 그 게시물의 조회수 지표 — 정확한 지표 이름 [확인 필요]), 유튜브 쇼츠 → `YoutubeViewSource`(API 키로 공개 조회수), 그 밖 → `isOwnedBy` false. `VIEW_COUNT_ADAPTER: 'fake' | 'real'`.
- `isOwnedBy(url, creator: { instagramHandle: string | null; youtubeChannelId: string | null })` — 인자 확장(3번·5번 호출부와 가짜 함께). 인스타그램은 연결 계정의 게시물인지, 쇼츠는 영상의 채널이 크리에이터의 확인된 채널인지.
- 쇼츠 채널 확인(추천안일 때): 크리에이터가 채널 주소를 넣으면 Cora가 확인 문구를 주고, 크리에이터가 채널 설명에 잠시 넣은 뒤 `확인`을 누르면 서버가 공개 API로 읽어 맞으면 `youtubeChannelId` 저장. 화면은 캔버스에 없음 → 소유자 확인.
- 읽기 실패는 `ViewCountUnavailableError` → 3번의 3일 연속 규칙.
- 테스트:

```ts
it('routes reels to instagram and shorts to youtube', ...);
it('treats a post outside the connected account as not owned', ...);
it('treats a short from another channel as not owned', ...);
it('verifies a channel only when the description has the issued code', ...);
it('throws ViewCountUnavailableError when the service fails', ...);
```

- **스테이징 확인:** 실제 릴스·쇼츠 링크 하나씩 제출 → 다음 날 스냅샷에 조회수(스테이징은 실제 시간이라 7일 전체는 Task 27에서).
- **Commit:** `feat: 실제 조회수 읽기 연결`

---

## 묶음 라 — 출시에 필요한 서버·화면

### Task 23: 약관·개인정보 동의

**Step 0 소유자 준비 확인:** 이용약관·개인정보 처리방침(법률 확인), 공개 웹 주소(`LEGAL_URL`, `#terms`·`#privacy` — 계정·설정 계획), 문서 버전 이름, 처리방침의 처리 위탁·국외 이전 목록(이 계획이 붙이는 서비스 전부: Supabase, 호스팅, Redis, SMS, 카카오, 네이버, Google·Firebase, Apple, PG, Meta, 유튜브, LLM, 오류 추적, 메일 발송), 동의 방식(소유자 결정 20), 만 14세 확인을 넣을지(소유자 결정 13).

동의 방식은 A안이다(소유자 결정 20, 2026-11-11 소유자 결정). 법률 확인에서 체크 방식의 동의가 필요하다고 하면 B안으로 바꾼다 — 서버는 같고 앱만 달라진다.
- **A안(결정) — 캔버스 그대로:** E1의 "계속하면 … 동의하게 돼요"를 첫 동의로 본다. 첫 로그인 뒤 앱이 화면 없이 `POST /me/consents`를 부른다. 만 14세 확인을 넣기로 했으므로(소유자 결정 13) `REQUIRE_AGE_14`면 첫 로그인 때 `만 14세 이상이에요` 한 줄과 확인 버튼만 있는 화면을 띄운 뒤 기록한다(캔버스 밖 — 문구와 모양은 소유자 확인). 약관 버전이 바뀌었을 때만 아래 동의 화면을 "약관이 바뀌었어요" 안내로 띄운다.
- **B안(법률 확인 결과가 요구할 때만) — 설계 4장 그대로:** 첫 로그인 뒤 아래 동의 화면을 띄운다.
- 마케팅 수신 동의는 E5의 "추천 소식" 스위치(3번 계획 Task 3A의 `notification_settings`, 켠 시각을 동의로 기록)를 쓴다. 이 Task는 마케팅 동의를 따로 저장하지 않는다.

**Files:**
- Create: `api/src/consents/{consents.module.ts,consents.controller.ts,consents.service.ts,consents.repository.ts,consent.guard.ts,dto/*}`, 마이그레이션, `app/lib/features/consent/{data,domain,presentation/{pages,viewmodels}}/…`
- Modify: `api/src/config/env.ts`, 8번 `GET /config` 모델, `GET /me` 모델, `app/lib/core/navigation/app_router.dart`
- Test: `api/test/consents.e2e-spec.ts`, `app/test/features/consent/…`, `app/test/core/navigation/app_router_test.dart`(추가)

**Interfaces:**
- Produces:
  - `UserConsent` → `user_consents`: `id`, `userId`, `kind`(`TERMS | PRIVACY | AGE_14`), `version`, `recordedAt`, `via`(`SIGN_IN_NOTICE | CONSENT_SCREEN`). 더하기만 하고 고치지 않는다.
  - `Env`: `TERMS_VERSION`, `PRIVACY_VERSION`, `REQUIRE_AGE_14: boolean`. 8번 `GET /config`에 `termsVersion`, `privacyVersion`, `requireAge14` 추가. 문서 주소는 앱의 `LEGAL_URL`(계정·설정 계획)이고 서버는 주소를 내려 주지 않는다.
  - `GET /me`에 `consentRequired: boolean` — 현재 버전의 `TERMS`·`PRIVACY`(와 `REQUIRE_AGE_14`면 `AGE_14`) 줄이 없으면 true.
  - `POST /me/consents` `{ termsVersion; privacyVersion; ageOver14?: boolean; via }` → 204. 버전이 현재와 다르면 409(앱이 config를 다시 읽음). 보안 로그 `CONSENT_RECORDED`. `operationId: recordConsents`.
  - `ConsentGuard`(인증 가드 뒤): 동의 전에는 `/me`, `/me/consents`, `/config`, `DELETE /devices/:token`, `DELETE /me`만 열고 나머지는 403 `FORBIDDEN` `details: { reason: 'CONSENT_REQUIRED' }`(옛 앱 버전도 동의를 건너뛰지 못하게).
  - 앱: 로그인 → `/me` → `consentRequired`면 A안은 첫 동의를 화면 없이 기록(`REQUIRE_AGE_14`면 만 14세 한 줄 확인만, 약관 버전이 바뀐 경우만 동의 화면), B안은 `/consent`(A1·홈보다 먼저). 동의 화면(캔버스에 없음): `이용약관 (필수)`, `개인정보 처리방침 (필수)`, (켜면) `만 14세 이상이에요 (필수)`, 줄마다 `보기`(`openLegal(section:)` — 계정·설정 계획), 시작 버튼. 문구 소유자 확인.
- 테스트:

```ts
it('requires consent until the current terms and privacy versions are agreed', ...);
it('requires consent again when TERMS_VERSION changes', ...);
it('refuses a consent for an old version with 409', ...);
it('blocks feature routes with CONSENT_REQUIRED until consent', ...);
```
```dart
test('records the sign-in notice as consent without a screen under option A', ...);
testWidgets('shows the consent screen when the terms version has changed', ...);
testWidgets('shows the consent screen before role selection under option B', ...);
testWidgets('enables the start button only when every required item is checked', ...);
testWidgets('fits at 1.3x text scale', ...);
```

- **Commit:** `feat: 약관·개인정보 동의 추가`

---

### Task 24: 유니버설 링크·앱 링크

**Step 0 소유자 준비 확인:** 초대 링크 도메인(`INVITE_BASE_URL`의 호스트), Apple Team ID, Play App Signing의 인증서 SHA-256.

**Interfaces:**
- 서버 `GET /.well-known/apple-app-site-association`, `GET /.well-known/assetlinks.json` — `@Public`, JSON, 리디렉트 없음, 경로는 `/i/*`만. 값은 `APPLE_APP_ID`(`<TeamID>.com.cora.cora`), `ANDROID_CERT_SHA256`.
- 앱: iOS Associated Domains `applinks:<도메인>`, Android `intent-filter android:autoVerify="true"`(`https`, 그 호스트, `/i/`). `https://<도메인>/i/<code>`를 8번의 `cora://invite/<code>`와 같은 처리로.
- 지연 딥 링크는 만들지 않는다(8번은 아이디로 전환하므로 코드가 안내에만 쓰인다 — 소유자 결정 14).
- 테스트: `it('serves the apple app site association for invite paths only', ...)`, `it('serves assetlinks with the configured fingerprint', ...)`, `test('treats an https invite link like the cora invite link', ...)`.
- 실기기: 메모 앱에 붙인 초대 링크를 누르면 앱이 열리고, 앱이 없으면 웹 초대 페이지가 열린다.
- **Commit:** `feat: 초대 링크의 유니버설 링크·앱 링크 추가`

---

### Task 25: 회원 탈퇴

**Step 0 소유자 준비 확인:** 법정 보관 기간(장부·결제·계약·메시지·동의 기록) 확인, 탈퇴 확인 화면 문구. 탈퇴 줄 자체는 E4 설정(계정·설정 계획 Task 6)에 있고, 그 계획은 이 Task 전까지 그 줄이 E8을 열게 해 두었다 — 이 Task가 확인 화면으로 바꾼다.

**Files:**
- Create: `api/src/accounts/{accounts.module.ts,accounts.controller.ts,account-deletion.service.ts,account-deletion.repository.ts,account-deletion.participant.ts,handlers/account-deletion.handler.ts}`, 기능 모듈마다 `<module>/<module>-deletion.participant.ts`, `api/src/ops/commands/resume-deletion.command.ts`, 마이그레이션, `app/lib/features/account_deletion/…`
- Modify: `api/src/auth/`(탈퇴한 사용자 거절), 5번 `conversations`(`closedReason`에 `USER_DELETED`), Task 13의 `AuthAdminPort`(없으면 이 Task가 만든다)
- Test: `api/src/accounts/account-deletion.service.spec.ts`, `api/test/account-deletion.e2e-spec.ts`, `app/test/features/account_deletion/…`

**Interfaces:**
- Produces:
  - `AccountDeletion` → `account_deletions`: `userId`(unique), `status`(`REQUESTED | CLEANED | DONE | BLOCKED`), `requestedAt`, `doneAt?`, `attempts`, `lastErrorCode?`. RLS.
  - `users.deletedAt`은 요청 순간 채운다. 가드는 `deletedAt`이 있는 사용자의 토큰을 401로 거절한다(보안 로그 `DELETED_USER`) — 1번 최종 검토 T4-6.
  - `interface AccountDeletionParticipant { readonly name: string; blockers(userId: string): Promise<DeletionBlocker[]>; cleanup(userId: string): Promise<void> }`, `type DeletionBlocker = 'MONEY_HELD' | 'PAYOUT_PENDING'`, 다중 제공 토큰 `ACCOUNT_DELETION_PARTICIPANTS`. 기능 모듈마다 자기 참여자를 만들어 등록한다(다른 모듈 내부를 import하지 않는다). `cleanup`은 몇 번 불려도 결과가 같다.
  - 참여자(공통 모델 20장):

| 모듈 | blockers | cleanup |
|---|---|---|
| collaborations | `isMoneyHeld` 협업 → `MONEY_HELD` | 계약 전 브랜드 협업 `DROPPED` |
| settlements·payouts | 계좌가 없어 남은 지급, 수요일 송금을 기다리는 지급(2026-11-11 소유자 결정, 3번 Task 8) → `PAYOUT_PENDING` | — |
| notifications (3번 Task 3A) | — | 내 알림 지움, 내가 상대로 들어간 남의 알림의 이름·사진 사본을 `탈퇴한 사용자`·기본 그림으로 |
| offers·bids·applications | — | 보낸 `SENT`·`ACCEPTED` 취소, 받은 오퍼 거절, 지원 취소 |
| stores | — | 공개 내림, 사진 지움, 이름 `탈퇴한 사용자` |
| invites | — | `expireAllForStore` |
| campaigns | — | 마감 |
| creators·brands | — | 이름 `탈퇴한 사용자`, 사진·소개·채널 정보 지움 |
| portfolio | — | 콘텐츠 `deletedAt`, 파일 삭제 |
| drafts | — | 초안 파일 삭제(버전 행·댓글은 남김) |
| instagram | — | 연결과 토큰 지움 |
| conversations | — | 그 사람과의 방을 읽기 전용(`USER_DELETED`) |
| devices (Task 15) | — | 기기 토큰 지움 |
| external identities (Task 13·14) | — | 네이버 연결 지움, Apple 해제 |

  남는 것: 장부, 결제, 정산, 계약, 조건 버전, 메시지, 동의 기록(보관 기간 동안). 상대 화면의 "탈퇴한 사용자"와 기본 사진은 이름·사진을 지운 자리 행이 그대로 보여 준다(어긋나는 점 9).
  - `DELETE /me` → 202 `{ status: 'REQUESTED' }` | 409 `CONFLICT` `details: { blockers }`. 메시지: `MONEY_HELD` → `진행 중인 협업이 끝나면 탈퇴할 수 있어요.`, `PAYOUT_PENDING` → 계좌가 없으면 `받을 금액이 있어요. 계좌를 등록해 지급받은 뒤 탈퇴해 주세요.`, 계좌가 있고 수요일 송금을 기다리면 `{M}월 {D}일 지급이 끝나면 탈퇴할 수 있어요.`(캔버스 밖 — 소유자 확인, 2026-11-11 소유자 결정의 수요일 송금 때문에 생긴 경우) 한 트랜잭션: blockers 확인 → `deletedAt` → `REQUESTED` → 작업 `account-deletion`(jobKey `account-deletion:<userId>`). 보안 로그 `ACCOUNT_DELETION_REQUESTED`. `operationId: deleteMe`
  - 작업: blockers 다시 확인(요청 뒤 생긴 보관 금액 → `BLOCKED`, 운영자 알림, 멈춤) → 참여자 `cleanup`을 차례로 → `CLEANED` → `AuthAdminPort.deleteUser` → `DONE`. 실패는 `attempts`·`lastErrorCode`를 남기고 늘어나는 간격으로 최대 `5`번, 다 실패하면 운영자 알림.
  - 운영 명령 `yarn ops resume-deletion --user <id> --operator <이름> --reason <이유>`(3번 틀, `ops_audit_logs`).
  - 앱: 확인 화면(캔버스에 없음) → 409면 서버 문구, 202면 로그아웃 → E1.
- 테스트:

```ts
it('refuses deletion while money is held for either party', ...);
it('refuses deletion while a payout waits for an account', ...);
it('rejects the token of a deleted user immediately', ...);
it('runs every participant and deletes the auth user', ...);
it('finishes on a retry after a participant fails halfway', ...);            // Review Focus 5
it('stops as BLOCKED and alerts when money is held after the request', ...); // Review Focus 5
it('keeps ledger, contracts and messages and shows the counterpart as 탈퇴한 사용자', ...);
it('lets the same phone sign up again as a new user', ...);
```
```dart
testWidgets('shows the server reason when deletion is refused', ...);
testWidgets('signs out after deletion is accepted', ...);
```

- **Commit:** `feat: 회원 탈퇴 추가`

---

## 묶음 마 — 출시 게이트

### Task 26: 출시 게이트 점검

**Files:** Create `docs/launch/launch-checklist.md` — 표: 항목 · 확인 방법 · 결과 · 확인한 사람과 날짜.

- [ ] **Step 1: 점검표 작성** — 아래를 모두 넣는다.
  1. 운영 서버가 운영 비밀값으로 시작함 = 모든 `_ADAPTER`가 가짜가 아님(8번 `adapterKeysToCheck`, `DIRECTORY_ENABLED=false`면 그 둘 제외).
  2. 운영 Supabase: `CHECK_EXPECT=prod yarn check:auth-settings`, 읽기 전용 연결의 `yarn check:rls`, 앱 번들에 서비스 역할 키가 없음(`strings`).
  3. 운영 빌드: `scripts/check-release-binary.sh`(가짜 인증·모션 갤러리·가짜 결제창·가짜 인스타그램 화면 없음), `assertProductionConfig`.
  4. Wiki Security baseline의 "Security definition of done" 9줄마다 근거(파일·테스트·문서).
  5. 신고 → 운영자 메일 → 운영 명령으로 숨김·해제(공통 모델 19장).
  6. 8번 법적 확인 4개 결과와 `DIRECTORY_ENABLED` 결정(기본 `false`).
  7. 6번 `drafts`의 300MB와 운영 Storage 전역 한도.
  8. 1번 최종 검토에서 미룬 것 전부 닫힘: 요청 ID, 보안 로그, 보안 헤더, 요청 수 제한, 본문 제한, 종료 처리, 익명 토큰 거부, Node LTS, Swagger 차단(이상 Task 1·2), 키체인 정리, 오류 화면 로그아웃, 토큰 갱신(Task 3), https 검사, 가짜 인증 제외, `dataExtractionRules`, 앱 이름, `cupertino_icons`(Task 4), 인증번호 만료(Task 11), `deletedAt` 처리(Task 25), Apple 4.8 판단(소유자 결정 5).
  9. 법률 확인 결과: 대금 보관, 지급 세금, 전자 계약(5번), 목록·연락(8번), 사업자 정보 표시와 통신판매업 신고, 보관 기간, 약관·처리방침.
  10. 사업자 정보 표시가 의무면 계정·설정 계획의 화면(E4 또는 E8)에 들어갔는지. 운영 빌드의 `LEGAL_URL`·`OPERATOR_EMAIL`.
  11. 운영 `MIN_APP_VERSION`, `OPERATOR_EMAIL`, `TERMS_VERSION`·`PRIVACY_VERSION` 값.
  12. 백업 복구 기록(Task 9), 테스트 오류 하나가 개인정보 없이 오류 추적에 도착.
- [ ] **Step 2: 하나씩 실행하고 결과를 적는다.** 실패하면 멈추고 소유자에게 알린다.
- [ ] **Step 3: Commit** — `docs: 출시 점검표와 결과 기록`

---

### Task 27: 실제 돈으로 처음부터 끝까지, 실기기

- [ ] **Step 0: 소유자 준비 확인** — 운영 PG 실제 키, 소유자 카드, 크리에이터 역할의 두 번째 계정(소유자 지인 또는 두 번째 기기·번호), 중저가 iOS·Android 실기기 각 한 대.
- [ ] **Step 1: 가게 오퍼 (소유자가 직접 결제)** — 가게 등록 → 오퍼 → 수락 → 결제(PG 최소 금액 [확인 필요]) → 링크 제출 → 7일 집계 → 지급 → 환급. 운영 읽기 전용 연결로 `check-ledger`(3번 스크립트) → `모든 협업의 장부가 맞습니다`.
- [ ] **Step 2: 브랜드 계약 (최소 금액)** — 5번의 계약·결제 → 6번 초안 → 링크 → 고정 지급.
- [ ] **Step 3: 실기기** — 두 기기에서 주요 화면 전환이 끊기지 않음, 블러·그림자, 1.3배 글자, 다크 모드. 1번에서 미충족으로 남은 Android 확인(Task 8 Step 5, Task 10 Step 5)을 여기서 닫는다.
- [ ] **Step 4: 결과를 점검표에 적는다.** 테스트 협업은 정산·환급이 끝났는지 확인한다.

---

### Task 28: 스토어 제출

- [ ] **Step 0: 소유자 준비 확인** — 앱 설명·키워드·화면 사진(번호는 010-0000-XXXX만 보이게), 지원 주소, 개인정보 처리방침 주소, App Store 개인정보 답(수집 항목), Google Play 데이터 보안 양식, 콘텐츠 등급 설문, 심사용 로그인(운영 Supabase 테스트 번호 + 고정 인증번호 — 심사 전용 계정, 역할 셋을 볼 수 있게 준비하고 보관 금액 없음), Apple 4.8 결정 반영 여부.
- [ ] **Step 1: 심사 메모 작성** — 결제는 앱 밖에서 제공되는 실제 서비스(콘텐츠 제작)의 대가라 앱 내 구매 대상이 아니라는 설명(App Store 심사 지침과 Google Play 결제 정책의 해당 조항 [확인 필요]), 카카오 계정 없이 테스트 번호로 볼 수 있다는 안내, 회원 탈퇴 경로, 동작 영상 주소.
- [ ] **Step 2: 운영 빌드 업로드** (소유자 확인) — Task 10 워크플로, 운영 주소.
- [ ] **Step 3: 심사 제출** (소유자 확인). 거절되면 사유를 progress.md에 적고 소유자에게 알린다.
- [ ] **Step 4: 출시** — 공개 버튼은 소유자가 누른다.

---

## 완료 기준

- 커밋마다: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`, `cd app && flutter analyze && flutter test`, `./scripts/gen-api.sh` 뒤 `git status` 변경 없음.
- Task 26 점검표의 모든 줄 통과, Task 27의 장부 점검과 실기기 확인 통과, Task 28 두 스토어 심사 통과.
- 운영 서버가 가짜 어댑터 하나 없이 시작하고, 운영 앱 바이너리에 가짜 구현이 없다.

## 소유자 준비 (오래 걸리는 것부터, 설계 7장)

| 신청 | 막는 Task | 메모 |
|---|---|---|
| 법률 확인 의뢰 — 대금 보관, 지급 세금·원천징수와 수집 정보, 전자 계약, 목록·연락, 통신판매업·사업자 정보, 보관 기간, 약관·처리방침 작성 | 19, 20, 23, 25, 26 | 결과가 PG 선택과 8번 기능 유무를 정한다 |
| PG 상담·심사 (두 곳 이상 동시) | 19, 20 | 지급 대행과 Flutter 결제창을 먼저 묻는다 |
| D-U-N-S 번호 → Apple·Google Play 조직 개발자 계정 | 10, 28 | Google Play 개인 계정은 출시 전 비공개 테스트 요건이 있다 [확인 필요] |
| 카카오·네이버 개발자 앱, SMS 업체와 발신번호 | 11, 12, 13 | 사업자 명의 |
| Meta 앱 심사 (7번 뒤 동작 영상), 유튜브 API 키 | 21, 22 | 처리방침 주소가 먼저 필요 |
| 도메인 (API, 초대 링크, 메일 발송, 약관 웹 페이지) | 8, 16, 23, 24 | |
| 호스팅·Redis·레지스트리·오류 추적 계정 | 8, 9 | |
| Supabase 스테이징·운영 프로젝트 | 6 | 서울, Pro |
| Firebase 프로젝트, APNs 키 | 15 | |
| LLM 계정 | 17 | |

## 소유자 결정 (2026-11-11)

20가지 모두 추천안으로 정했다(2026-11-11 소유자 결정). 선택지는 기록으로 남긴다.

1. **가 묶음(Task 1~4)을 언제 할지.** 지금 당김 / 2번 끝난 직후 / 8번 뒤. **결정(추천안): 2번 끝난 직후** — 2번 세션이 같은 파일을 고치는 중이라 지금은 충돌하고, 8번까지 미루면 그동안의 기능이 보안 헤더·요청 ID 없이 쌓인다.
2. **SMS.** A Supabase 기본 업체(코드 없음, 국내 도달률·"국제발신" 표시 [확인 필요]) / B 국내 업체 + Send SMS Hook(서버 코드 조금, 발신번호 등록 필요). **결정(추천안): B** — 한국 사용자가 받는 문자의 신뢰와 도달률. 국내 업체 후보는 상담에서 정한다.
3. **네이버 연동 방식.** A Supabase 사용자 정의 제공자(지원되면) / B 서버 중계(코드 많음, 이메일 제공자를 켜야 할 수 있음) / C 첫 출시에서 빼기(캔버스 E1 변경). **결정(추천안): A가 되는지 먼저 확인, 안 되면 B.**
4. **같은 사람의 휴대폰·카카오·네이버 계정 연결.** 연결 안 함(각각 다른 계정) / 연결 기능 만들기. **결정(추천안): 첫 출시는 연결 안 함**(설계에 없음, 로그인 화면에 "처음 쓴 방법으로 로그인" 안내만 고려).
5. **Apple 로그인(4.8).** 넣기(Task 14, 캔버스 버튼 필요) / 빼고 심사 메모로 설명. **결정(추천안): 넣기** — 거절되면 심사 왕복으로 출시가 밀리고, 휴대폰 번호 로그인이 동등한 대안으로 인정되는지 확실하지 않다 [확인 필요].
6. **PG.** 지급 대행 + Flutter 결제창 + 통지 기반 승인을 함께 주는 곳(설계 9장). 후보 예: 토스페이먼츠, 포트원(여러 PG 묶음), 그 밖의 국내 PG — 모두 [확인 필요]. **결정(추천안): 두 곳 동시 상담, 대금 보관 구조 답을 먼저 주는 곳.**
7. **호스팅과 Redis.** Google Cloud Run 서울(최소 인스턴스 1, CPU 상시) + 관리형 Redis / AWS 서울(ECS Fargate + ElastiCache, 설정이 많음) / 서울 밖 컨테이너 호스팅(도쿄 등, DB와 지연). **결정(추천안): Supabase와 같은 서울에서 1인이 운영하기 쉬운 쪽(Cloud Run 서울을 먼저 검토)** — 일회성 작업으로 마이그레이션과 운영 명령을 돌리기 쉽다. WebSocket 연결 시간 한도와 월 비용 [확인 필요]. Redis는 BullMQ 제약 때문에 서버리스 Redis보다 일반 관리형을 추천.
8. **오류 추적.** Sentry(서버·앱 한곳) / Crashlytics + 호스팅 로그. **결정(추천안): Sentry** — 설계의 "한곳에서". 데이터 지역은 국외 이전 고지.
9. **운영자 메일 발송.** 거래 메일 서비스(예: Amazon SES, Resend) / 개인 메일 SMTP. **결정(추천안): 거래 메일 서비스 + 자체 도메인.**
10. **LLM.** **결정(추천안): Task 17의 견본 비교로 정하되 `claude-haiku-5-5`부터** — 가장 저렴한 후보로 형식 성공률과 문안을 먼저 본다.
11. **링크 분석 범위와 사진.** 약관이 허락하는 메타 정보 + 지역 검색 API, 사진은 사장님이 올림 / 사진 복사까지. **결정(추천안): 사진 복사는 저작권 확인 뒤.**
12. **쇼츠 소유 확인.** 채널 설명의 확인 문구(화면 하나 추가) / 구글 계정 연결(구글 심사) / 첫 출시에서 쇼츠의 조회수당 지급 막기. **결정(추천안): 확인 문구.**
13. **만 14세 확인.** 동의 화면에 필수 항목으로 넣기 / 넣지 않기. **결정(추천안): 넣기** [확인 필요: 법률].
14. **지연 딥 링크.** **결정(추천안): 만들지 않음** — 8번은 연동한 아이디로 전환한다.
15. **앱 세부.** 앱 이름(Android `cora` / iOS `Cora` → **결정 `Cora`로 통일**), 번들 ID `com.cora.cora` 확정(올린 뒤 못 바꿈), 키체인 접근 등급(지금 `first_unlock` — 기기 이전 때 세션이 따라감 / `first_unlock_this_device` — 기기 이전 뒤 다시 로그인. **결정(추천안): `_this_device`**).
16. **요청 수 제한 값.** IP 분당 600, 사용자 분당 120(제안). **결정(추천안): 이 값으로 시작하고 스테이징 로그로 조정.**
17. **로컬 도구.** Node LTS 설치(nvm), 서버 이미지는 CI에서만 빌드. **결정(추천안): 둘 다 그대로.**
18. **심사용 테스트 번호.** 계속 둠 / 심사 기간에만 켬. **결정(추천안): 심사 기간에만 켬** — 고정 인증번호는 운영의 뒷문이다.
19. **캔버스에 없는 화면·상태의 문구:** (결정: 각 Task의 최소 문구로 만들고, 실행할 때 화면을 보여 소유자가 확정한다) 오류 화면 로그아웃, 인증번호 만료, 동의 화면, 탈퇴 확인, 예금주 불일치, 인스타그램 연결 끊김 알림, 문자 문구, 쇼츠 채널 확인.
20. **약관 동의 방식 (E3~E8 설계 충돌 16과 같은 질문).** A 캔버스 그대로 — E1의 "계속하면 동의" 문구를 첫 동의로 기록하고, 약관이 바뀔 때만 화면 / B 설계 4장 그대로 — 첫 로그인 뒤 동의 화면. 마케팅 동의는 어느 쪽이든 E5 "추천 소식". **결정(추천안): A, 법률 확인에서 체크 방식 동의가 필요하다고 하면 B** — 디자인 100% 규칙과 화면 수를 줄이는 쪽. [확인 필요: 법률]

## 설계·다른 계획과 어긋나는 점 (고치지 않고 목록으로만)

1. 설계 3.1 "운영 프로젝트의 이메일 로그인을 끈다" ↔ 네이버 B안(서버 중계)은 Supabase의 이메일 기반 일회용 토큰을 쓰므로 이메일 제공자를 켜야 할 수 있다 [확인 필요].
2. 설계 3.2 [제안] "알림 종류별 켜고 끄기 화면은 만들지 않는다", "정산 → 협업 화면" ↔ 캔버스 E5 알림 설정, E3 정산 → E7. E3~E8 설계 8장 1·2번이 이미 올렸다. 이 계획은 그쪽 결정을 따른다(Task 15). → 2026-11-11 소유자 결정으로 설계 3.2를 고쳤다.
3. 설계 4장의 설정·문의하기·앱 버전·"설정·탈퇴·동의를 9번이 만듦" ↔ 캔버스 E4·E8과 계정·설정 계획. 이 계획은 탈퇴·동의의 서버와 확인 화면만 만든다. 약관 주소도 서버 설정이 아니라 앱의 `LEGAL_URL`(계정·설정 계획)을 쓴다. → 2026-11-11 소유자 결정으로 설계 4장을 고쳤다.
4. 설계 2장 "FCM(Android), APNs(iOS)" ↔ 계획은 FCM 하나로 두 플랫폼에 보낸다(APNs 키는 Firebase에 올림). 전송은 그대로 APNs라 뜻은 같다.
5. 1번의 `PushPort.send({ userId, title, body })` ↔ 3번 계획 Task 3A가 `data: { notificationId, targetKind, targetId }`를 더하고 기능 모듈은 `NotificationsService.notify`만 부르게 한다. 이 계획은 그 모양을 그대로 쓴다. → 3번 계획 Task 3A로 들어갔다(2026-11-11 소유자 결정).
6. 3번 `PaymentPort` ↔ 결제창 복귀 뒤 서버 승인을 요구하는 PG면 `handleReturn`과 `GET /payments/return`이 더해진다.
7. 3번 `PayoutPort.send({ bankCode, accountNumber, … })`와 계좌 등록 ↔ 지급 대행이 받는 사람 등록과 실명 확인을 요구하면 모양과 흐름이 바뀐다. 원천징수가 필요하면 3번 설계 6장의 지급액·장부가 바뀐다.
8. 3번 `ViewCountPort.isOwnedBy(url, { instagramHandle })` ↔ 쇼츠 소유 확인에 채널 ID가 필요(공통 모델 2장의 [확인 필요]).
9. 공통 모델 20장 "프로필, 포트폴리오, 초안 파일은 지운다" ↔ 계획은 프로필·가게 행을 남기고 이름·사진·소개를 지워 "탈퇴한 사용자"로 바꾼다(외래 키와 상대 화면 유지). 포트폴리오·초안 파일은 지운다.
10. 7번 "가져오기는 요청 안에서 최대 10개" ↔ 실제 Meta에서는 시간이 길어 작업 큐로 바꾸고 API가 202 + 조회로 바뀐다(7번 앱 화면 수정).
11. 설계에 없던 것을 더함: 만 14세 확인(제안), 처리방침의 처리 위탁·국외 이전 목록, `ConsentGuard`로 동의 전 API 막기, 심사용 Supabase 테스트 번호(설계 6장 "심사자가 카카오 계정 없이" 의 답), Google Play 조직 계정·D-U-N-S, CI의 `cora_ci` 스키마.
12. 기술 스택 설계 4.3 "마이그레이션에는 직접 연결 주소" ↔ 실제는 세션 풀러(1번 최종 검토 M8). 운영 배포의 마이그레이션도 세션 풀러로 한다.
13. 설계 6장 "가짜 결제창이 없음" ↔ 3번은 `FakeCheckoutPage`를 `AppConfig.isDev`(실행 중 판단)로만 막는다. Task 4가 상수 조건으로 바꾼다.
14. 설계 5장 "Redis — 작업 큐가 쓰므로 데이터가 재시작에도 남아야" ↔ 서버리스 Redis 상품은 BullMQ와 맞지 않을 수 있다 [확인 필요] — 호스팅 결정에 반영.
15. 설계의 실행 순서 "앞 단계 1~8번" ↔ 가 묶음은 1번만 있으면 된다(당길지는 소유자 결정 1).
16. 설계 4장 "첫 로그인 뒤 동의 화면: 이용약관(필수), 개인정보(필수), 마케팅 알림(선택)" ↔ 캔버스 E1의 "계속하면 동의" 문구와 E5 "추천 소식"(E3~E8 설계 충돌 16). 이 계획은 두 안을 모두 받게 서버를 만들고, 마케팅 동의를 따로 저장하지 않는다(소유자 결정 20). → 결정 20(A)으로 설계 4장을 고쳤다.
17. 3번 설계 "원천징수 없음"(법률 확인 전) ↔ 캔버스 E7 "원천징수 3.3%"(E3~E8 설계 충돌 7). Task 20의 세무 확인 결과가 둘 다를 정한다. → E7의 3.3% 줄은 법률·세무 확인 전까지 숨기기로 했다(2026-11-11 소유자 결정).
18. 3번 "정산 즉시 송금" ↔ E3~E8 설계의 "다음 주 수요일" 묶음 송금(충돌 4). Task 20은 어느 쪽이든 같고, Task 25의 `PAYOUT_PENDING`에 송금 대기분이 들어간다. → 수요일 송금으로 정하고 공통 모델 2장·3번 설계·계획을 고쳤다(2026-11-11 소유자 결정).

## 이 계획이 하지 않는 것

- 기능별 켜고 끄기(기술 스택 설계 5.4). 예외는 8번의 `DIRECTORY_ENABLED` 하나.
- 관리자 웹, 사용 분석 도구(설계 5장 제안대로 첫 출시 제외).
- E3~E8 화면(알림, 설정, 알림 설정, 프로필 수정, 정산, 고객센터) — 다른 계획.
- 원천징수 계산과 지급 명세 신고(법률 확인 결과에 따라 별도 설계).
- 계정 연결, 지연 딥 링크, 서버 여러 대로 늘리기, 영상 변환·CDN.
