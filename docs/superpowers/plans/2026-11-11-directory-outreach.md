# 유입 전략: 외부 리스트 검색과 미가입 계정 연락 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

**Goal:** 사장님이 찾기 탭의 "리스트"에서 운영자가 고른 인스타그램 계정과 가입한 크리에이터를 함께 검색하고, 아직 가입하지 않은 계정에는 앱이 만들어 준 메시지와 초대 링크를 자기 인스타그램으로 직접 보내고, 연락받은 사람이 가입해 **같은 계정을 연동한 순간** 그 연락이 정식 오퍼로 바뀌는 데까지를 만든다. 서버 설정 하나(`DIRECTORY_ENABLED`)로 이 묶음 전체를 끌 수 있다.

**Architecture:** 서버에 항상 실리는 모듈 두 개(`app-config`의 `GET /config`, `invites`의 초대 웹 페이지·수신 거부·전환·만료)와, `DIRECTORY_ENABLED=true`일 때만 실리는 모듈 세 개(`directory`, `outreach`, 그리고 `DirectoryPort`·`OutreachPort`를 담는 `DirectoryIntegrationsModule`)를 더한다. 목록의 출처는 9번 설계 3.7의 기본안대로 운영자가 올린 CSV(`file` 구현)이고, 연락은 사장님이 직접 보내며 서버는 기록만 한다(`manual` 구현). 연락 문구는 고정 틀을 채우는 순수 함수이고 LLM을 쓰지 않는다. 연락의 잠금(계정당 살아 있는 `SENT` 하나)은 DB의 부분 유일 인덱스가, 하루 5건은 가게 행 잠금이 지킨다. 만료는 조회할 때 계산하고 매일 작업이 저장한다. 앱은 시작할 때 `GET /config`를 읽어 강제 업데이트와 이 묶음의 화면 표시를 정한다.

**Tech Stack:** 앞 계획들과 같다. 서버 추가: `@nestjs/throttler`(공개 초대 경로의 요청 수 제한), `csv-parse`(목록 파일 읽기). 앱 추가: `package_info_plus`(앱 버전), 딥 링크 수신 패키지(실행자가 고른다. `DeepLinkSource` 포트 뒤에만 둔다), `url_launcher`(3번에서 이미 들어왔으면 그대로).

**Spec:** `docs/superpowers/specs/2026-11-11-directory-outreach-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md` (3, 14, 16, 17, 18, 20장) · 기본 결정: `docs/superpowers/specs/2026-11-11-integrations-launch-design.md` (3.7, 9장) · 상위: `docs/superpowers/specs/2026-11-11-tech-stack-design.md`

**선행 조건:** 공통 기반, 2번, 3번, 4번, 7번 계획이 끝나 있어야 한다. 이 계획은 공통 기반의 `assertNoFakesInProduction`·`IntegrationsModule`·`Env`·`loadEnv`·`@Public()`·`AppConfig`·`apiClientProvider`·`appRouterProvider`·`CoraErrorView`, 2번의 `OffersService`·`offer-rules.ts`(`OFFER_RESPONSE_DAYS`)·`OfferTermsModel`·`buildTerms`·`StoresService.requireMyStore`·가게 기본 조건·`IndustryCategory`와 표시 이름·`StoreHomeSummaryModel`·`GET /offers/sent`·사장님 홈(숫자 세 칸, `보낸 오퍼` 탭, 바로가기 `리스트 검색` → `/store/coming-soon/…`)·`store_home_text.dart`·`offer_terms_text.dart`(`formatLabel`, `won`)·`roleEntryResolverProvider`·`CoraSegmentedTabs`·`CoraListRow`, 3번의 `InstagramService`(연결 완료)·`instagram_connections`·`CreatorSummaryModel.instagramConnected/followers`·`PushPort`·`OperatorAlertPort`·`JobScheduler`·운영 명령 CLI(`yarn ops …`, `--operator`, `--reason`, `ops_audit_logs`)·앱의 `/creator/instagram` 연동 화면, 4번의 `VisibilityService.filterCreators`·`creator_principles.fields`, 7번의 `JobScheduler.repeatDaily`·`/store/find`(릴스)·B5 라우트 `/store/creators/:id`와 `GET /creators/:id/profile`·가짜 `InstagramPort`(입력한 아이디가 연결 계정이 됨)를 그대로 쓴다.

## 출시 전 법적 확인 (먼저 읽기)

- 이 묶음은 설계 문서 6장의 법적·정책 확인 네 가지(동의 없는 계정 목록 보관, 앱의 도움으로 모르는 사람에게 영리 목적 메시지를 보내는 것, 인스타그램 약관상 반복 발송이 스팸으로 취급되는지, 수신 거부 아이디를 계속 보관하는 근거)가 끝나기 전에는 **운영 환경에서 켜지 않는다.**
- 그때까지 운영 환경은 `DIRECTORY_ENABLED=false`로 출시한다. 이 계획은 그 상태에서도 앱과 서버가 정상으로 돌고, 이미 나간 초대 링크와 수신 거부가 계속 열려 있는 것까지 만든다.
- 이 계획은 법적 결론을 내리지 않는다. Task 12의 출시 게이트 점검표에 확인 결과와 소유자 서명을 받는 칸만 둔다. 확인 결과가 기본안과 다른 방식을 요구하면 이 계획의 범위 밖이다.

## Global Constraints

앞 계획들의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것:

- 고정 값: 메시지 `1~300`자(초대 링크 제외), 연락 만료 `SENT` 후 `14`일, 만료 뒤 누구도 다시 연락할 수 없는 기간 `30`일, 가게당 하루 `5`건(`sentAt` 기준 한국 시간 하루), 변환된 오퍼의 응답 기한은 변환 순간부터 `7`일(`OFFER_RESPONSE_DAYS`), 목록 한 페이지 `20`줄, 검색어 `1~30`자, 목록 계정의 팔로워 범위 `1000~50000`, 목록 파일 최대 `5000`줄, 아이디 형식 `^[a-z0-9._]{1,30}$`(앞의 `@`를 떼고 소문자로 저장), 표시 이름 `1~30`자, 분야 꼬리표 일반 업종 `0~3`개, 초대 코드 `crypto.randomBytes(32)`의 base64url(43자), 공개 초대 경로 요청 제한 IP당 분당 `20`회(넘으면 429), 만료 작업 매일 한국 시간 `03:00`.
- 목록에는 아이디, 표시 이름, 팔로워 수(대략), 분야 꼬리표, 마지막 갱신 시각만 둔다. 사진, 게시물, 소개 글을 받거나 저장하는 칸을 만들지 않는다.
- "가입함"은 `instagram_connections`의 연결된 아이디로만 판단한다. `creator_profiles.instagramHandle`(본인이 적은 값)은 쓰지 않는다. 아이디 비교는 항상 소문자로 한다.
- 가입한 크리에이터의 줄은 반드시 `VisibilityService.filterCreators`를 거친다(피하는 업종, 차단).
- 수신 거부 목록(`directory_opt_outs`)에 있는 아이디는 목록에 들어가지 않고, 연락을 준비하거나 보낼 수 없다(404).
- 초대 코드만으로는 아무것도 얻을 수 없다. 전환은 연결된 인스타그램 아이디가 `SENT`이고 만료되지 않은 연락의 대상 아이디와 같을 때만 일어난다.
- 초대 웹 페이지의 HTML은 사용자가 넣은 모든 글(가게 이름, 동네, 식사권 이름)을 `escapeHtml`로 바꿔 넣는다. 인라인 스크립트를 쓰지 않는다. 응답 헤더: `Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; form-action 'self'`, `X-Robots-Tag: noindex`, `Referrer-Policy: no-referrer`, `Cache-Control: no-store`. GET은 아무것도 바꾸지 않는다(DM의 링크 미리보기가 GET을 부른다).
- `DIRECTORY_ENABLED=false`면 `directory`·`outreach`·`DirectoryIntegrationsModule`을 불러오지 않는다. 그 경로는 모두 404 `NOT_FOUND`, `assertNoFakesInProduction`은 `DIRECTORY_ADAPTER`와 `OUTREACH_ADAPTER`를 검사하지 않는다. `GET /config`, `/i/*`, `/invites/*`, 전환, 만료 작업은 그대로 동작한다.
- 작업 브랜치를 만들지 않고 `main`에 바로 커밋한다. 커밋마다 테스트가 통과한 상태여야 한다.

## 2026-11-11 소유자 결정으로 더한 것 (E3~E8 계정·알림 화면)

설계: `specs/2026-11-11-account-notify-settings-design.md`. 알림 기반은 3번 계획 Task 3A, 알림함·설정·정산 화면은 3번 Task 13A~13D, 설정·프로필 수정·고객센터는 `plans/2026-11-11-account-settings.md`(7번 다음)가 만든다. 아래가 이 계획의 작업에 더해진다.

- 이 계획의 모든 알림은 `PushPort`가 아니라 3번 Task 3A의 `NotificationsService.notify`로 보낸다. 새 알림 종류는 `NOTIFICATION_CATALOG`에 탭·스위치·그림·문구를 더하고(설계 3.2 표), 앱의 `locationFor`(3번 Task 13C)에 가는 곳을 더한다. 작업 처리기에서 보내는 알림은 `dedupeKey`를 넘긴다.
- Task 7: 연락 전환 알림 두 건 — 크리에이터 `OFFER_RECEIVED`, 사장님 `OUTREACH_CONVERTED`(탭 매칭, 스위치 새 오퍼와 제안, 가는 곳 `STORE_SENT_OFFERS`).

## Review Focus

1. **두 사장님이 같은 계정에 거의 동시에 "보냈어요"를 누름** → 하나만 `SENT`가 되고 다른 쪽은 409 `다른 가게가 먼저 연락했어요.` 한 가게의 다섯 번째와 여섯 번째가 동시에 들어와도 다섯 건만 저장된다. (Task 5)
2. **초대 링크를 연 사람이 다른 인스타그램 계정을 연동함, 또는 코드만 가지고 있음** → 오퍼가 생기지 않고 연락은 `SENT`로 남는다. (Task 7)
3. **수신 거부한 아이디가 다음 목록 파일에 다시 들어 있음** → 목록에 들어가지 않고, 그 계정으로 연락을 준비하면 404. (Task 3, 6)
4. **운영 환경에서 `DIRECTORY_ENABLED=false`, `DIRECTORY_ADAPTER=fake`** → 서버가 정상으로 시작하고, 목록·연락 경로는 404, 이미 나간 초대 페이지와 수신 거부는 열린다. `OUTREACH_ADAPTER=relay`면 켜져 있을 때 시작을 거부한다. (Task 1, 2)
5. **가게 이름에 `<script>`가 들어 있거나 없는 초대 코드를 연달아 넣음** → 페이지에는 글자로만 보이고, 없는 코드는 모두 같은 404 페이지이며 분당 20회를 넘으면 429. (Task 6)

---

## 파일 구조

```text
api/src/
├── app-config/                      # GET /config (항상)
├── common/outreach/                 # outreach-rules.ts, outreach-message.ts, korean-josa.ts (순수 함수)
├── common/html/escape-html.ts
├── integrations/directory/          # DirectoryPort, FakeDirectoryAdapter, FileDirectoryAdapter
├── integrations/outreach/           # OutreachPort, ManualOutreachAdapter
├── integrations/directory-integrations.module.ts   # 켜져 있을 때만
├── directory/                       # 목록 검색, 목록 동기화 (켜져 있을 때만)
├── outreach/                        # 준비, 보냄, 보낸 연락 목록 (켜져 있을 때만)
├── invites/                         # 초대 페이지(HTML), 초대 요약(JSON), 수신 거부, 전환, 만료 (항상)
├── ops/commands/directory-*.command.ts
└── app.module.ts                    # directoryModules(env)
api/seed/directory-sample.csv        # 견본 여섯 계정 (file 구현 수동 확인용)

app/lib/features/
├── server_config/                   # GET /config, 강제 업데이트
├── store_find/                      # 찾기 탭의 릴스 / 리스트 전환
├── directory/                       # C1 목록, C2 연락
└── invite/                          # 딥 링크, 초대 안내
```

---

### Task 1: 스키마, 환경 설정, 모듈 스위치

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/config/env.ts`, `api/.env.example`, `api/src/integrations/assert-no-fakes.ts`, `api/src/main.ts`, `api/src/app.module.ts`
- Create: 마이그레이션, `api/src/integrations/directory-integrations.module.ts`(빈 모듈, Task 2가 채움)
- Test: `api/test/db/directory-schema.db-spec.ts`, `api/src/config/env.spec.ts`(추가), `api/src/integrations/assert-no-fakes.spec.ts`(추가), `api/src/app.module.spec.ts`

**Interfaces:**
- Produces:
  - enum `OutreachStatus { PREPARED, SENT, CONVERTED, EXPIRED, OPTED_OUT }`, `OptOutSource { INVITE_PAGE, OPERATOR }`
  - `DirectoryAccount` → `directory_accounts`: `id`, `handle`(unique, 소문자), `displayName`, `followersApprox: Int`, `fields: IndustryCategory[]`, `refreshedAt`, `linkedCreatorId?`(→ `users`), `createdAt`, `updatedAt`, `deletedAt?`
  - `DirectoryOptOut` → `directory_opt_outs`: `handle`(unique), `optedOutAt`, `source`
  - `OutreachMessage` → `outreach_messages`: `id`, `storeId`, `directoryAccountId`, `targetHandle`(사본, 소문자), `message`, `terms: Json`(`OfferTermsModel` 사본), `inviteCode`(unique), `status`, `preparedAt`, `sentAt?`, `expiresAt?`, `convertedAt?`, `offerId?`(unique, → `offers`), `optedOutAt?`
  - 부분 유일 인덱스(SQL): `outreach_messages (directory_account_id) WHERE status = 'SENT' AND deleted_at IS NULL`(잠금), `outreach_messages (store_id, directory_account_id) WHERE status = 'PREPARED' AND deleted_at IS NULL`. 인덱스 `(store_id, sent_at)`, `(lower(target_handle), status)`.
  - `Env`에 추가: `DIRECTORY_ENABLED: boolean`(기본 `false`, `.env.example`은 `true`), `DIRECTORY_ADAPTER: 'fake' | 'file'`, `OUTREACH_ADAPTER: 'manual' | 'relay'`(기본 `manual`), `MIN_APP_VERSION: string`(semver, 기본 `1.0.0`), `INVITE_BASE_URL: string`(https 또는 개발의 `http://127.0.0.1:3000`), `APP_STORE_URL`, `PLAY_STORE_URL`
  - `adapterKeysToCheck(env: Env): string[]` — `_ADAPTER`로 끝나는 키 가운데, `DIRECTORY_ENABLED`가 false면 `DIRECTORY_ADAPTER`·`OUTREACH_ADAPTER`를 뺀 것. `assertNoFakesInProduction`이 이것을 쓴다.
  - `assertOutreachSupported(env: Env): void` — `DIRECTORY_ENABLED`이고 `OUTREACH_ADAPTER === 'relay'`면 throw `OUTREACH_ADAPTER=relay는 아직 구현되지 않았어요.` 환경과 무관하게(개발에서도) 검사한다. `main.ts`와 `ops-main.ts`가 `NestFactory.create` 전에 부른다.
  - `directoryModules(env: Env): DynamicModule[]` — 켜져 있으면 `[DirectoryIntegrationsModule, DirectoryModule, OutreachModule]`, 아니면 `[]`. `AppModule.forRoot(env)`가 import한다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('stores no photo or post columns for directory accounts', ...);           // information_schema 열 목록 = 위 칸들만
it('allows only one live SENT outreach per account across stores', ...);      // 두 번째 SENT insert가 throw
it('allows a new SENT outreach once the previous one expired', ...);
it('keeps one PREPARED draft per store and account', ...);
it('rejects a second opt-out row for the same handle', ...);
it('defaults DIRECTORY_ENABLED to false', ...);
it('skips directory adapters in the fake check when the bundle is off', ...); // production, ENABLED=false, DIRECTORY_ADAPTER=fake → 통과
it('throws in production when DIRECTORY_ADAPTER is fake and the bundle is on', ...);
it('refuses relay even in development when the bundle is on', ...);           // /OUTREACH_ADAPTER=relay/
it('loads no directory modules when the bundle is off', ...);                 // directoryModules(env) → []
```

기존 `rls.db-spec.ts`가 새 테이블 3개에서도 통과해야 한다.

- [ ] **Step 2~4: 실패 확인 → 스키마, 마이그레이션(RLS와 부분 인덱스 포함), 환경 검사 구현 → 통과 확인** — Run: `cd api && yarn prisma migrate dev && yarn test && yarn test:db`
- [ ] **Step 5: Commit** — `feat: 목록·연락 스키마와 묶음 제외 스위치 추가`

---

### Task 2: 두 포트와 `GET /config`

**Files:**
- Create: `api/src/integrations/directory/{directory.port.ts,fake-directory.adapter.ts,file-directory.adapter.ts}`, `api/src/integrations/outreach/{outreach.port.ts,manual-outreach.adapter.ts}`, `api/src/app-config/{app-config.module.ts,app-config.controller.ts,app-config.service.ts,dto/app-config.model.ts}`, `api/seed/directory-sample.csv`
- Modify: `api/src/integrations/directory-integrations.module.ts`, `api/src/app.module.ts`
- Test: `api/src/integrations/directory/*.spec.ts`, `api/test/app-config.e2e-spec.ts`, `api/test/directory-switch.e2e-spec.ts`

**Interfaces:**
- Produces:
  - `type DirectorySourceRow = { handle: string; displayName: string; followers: number; fields: IndustryCategory[]; refreshedAt?: Date }`
  - `abstract class DirectoryPort { abstract fetchAccounts(source?: { filePath: string }): Promise<DirectorySourceRow[]> }`
  - `FakeDirectoryAdapter` — 캔버스의 여섯 계정을 돌려준다(`source` 무시): `면치기 일기` `noodle.diary` 12000 `[FOOD_CAFE]`(`refreshedAt` = now − 3일), `하루 한 컵` `onecup.day` 640 `[FOOD_CAFE]`, `성수 한 끼` `seongsu.meal` 4800 `[FOOD_CAFE]`, `국물 수집가` `soup.collector` 23000 `[FOOD_CAFE]`, `민의 옷장 기록` `min.closet` 2100 `[FASHION]`, `골목 미식회` `alley.gourmet` 8900 `[FOOD_CAFE]`. (`onecup.day`의 팔로워 640은 캔버스 값이며 범위 검사 대상이 아니다. 가짜 구현만 예외로 둔다.)
  - `FileDirectoryAdapter` — `filePath`가 없으면 throw. UTF-8 CSV, 머리줄 `handle,displayName,followers,fields,refreshedAt`. `fields`는 `;`로 나눈 업종 코드(`FOOD_CAFE;FASHION`), `refreshedAt`은 빈칸이면 없음. 형식이 틀린 줄은 `DirectoryRowError(line, reason)` 목록으로 모아 돌려준다(`fetchAccounts`의 반환 대신 `{ rows, errors }`를 주는 `parse(filePath)`를 따로 export하고 `fetchAccounts`는 `rows`만).
  - `abstract class OutreachPort { abstract readonly mode: 'manual' | 'relay'; abstract deliver(input: { outreachId: string; handle: string; text: string }): Promise<{ delivered: boolean }> }`, `ManualOutreachAdapter` — `mode = 'manual'`, `deliver`는 아무것도 보내지 않고 `{ delivered: false }`
  - `GET /config` → 200 `AppConfigModel { minSupportedVersion: string; directoryEnabled: boolean; outreachMode: 'manual' | 'relay'; storeUrls: { ios: string; android: string } }`. `@Public()`. `Cache-Control: max-age=60`. `operationId: getAppConfig`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('returns the six canvas accounts from the fake directory', ...);          // handles 6개, noodle.diary 12000
it('parses the sample csv and reports bad lines with their line numbers', ...); // 'noodle diary' → line 2 INVALID_HANDLE
it('splits fields by semicolon and rejects a sensitive industry', ...);      // ALCOHOL → INVALID_FIELD
it('requires a file path for the file adapter', ...);
it('records only and delivers nothing in manual mode', ...);
it('serves GET /config without a token', ...);                               // { minSupportedVersion: '1.0.0', directoryEnabled: true, outreachMode: 'manual', storeUrls }
it('reports directoryEnabled false when the bundle is off', ...);
it('returns 404 for every directory and outreach route when the bundle is off', ...); // GET /directory, POST /outreach, POST /outreach/x/mark-sent, GET /outreach/sent
it('keeps the invite page and opt-out routes when the bundle is off', ...);  // GET /i/<code> 200
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 목록·연락 포트와 구현 추가`, `feat: 로그인 없이 읽는 앱 설정 GET /config 추가`

---

### Task 3: 목록 동기화와 운영 명령

**Files:**
- Create: `api/src/directory/{directory.module.ts,directory-sync.service.ts,directory.repository.ts}`, `api/src/invites/opt-outs.repository.ts`, `api/src/ops/commands/{directory-import.command.ts,directory-remove.command.ts,directory-opt-outs.command.ts}`
- Modify: `api/src/ops/ops.module.ts`(켜져 있을 때만 `DirectoryModule` import), `README.md`
- Test: `api/src/directory/directory-sync.service.spec.ts`, `api/test/ops-directory.e2e-spec.ts`

**Interfaces:**
- Consumes: `DirectoryPort` (Task 2), 운영 명령 틀과 `ops_audit_logs` (3번 Task 10), `Clock`
- Produces:
  - `DirectorySyncService.sync(rows: DirectorySourceRow[], now: Date): Promise<SyncReport>` — `SyncReport { added; updated; restored; skippedOptedOut; skippedOutOfRange; invalid: { line?: number; handle: string; reason: string }[] }`. 아이디를 정규화하고, 거부 목록에 있으면 건너뛰고, 팔로워가 1000~50000 밖이면 건너뛰고(가짜 구현의 행은 예외), 아이디로 upsert한다. 지운(`deletedAt`) 행이면 되살리고 `restored`로 센다. `refreshedAt`은 행의 값, 없으면 `now`. 파일에 없는 기존 계정은 지우지 않는다.
  - `yarn ops directory-import [--file <path>] --operator <이름> --reason <글>` — `DirectoryPort.fetchAccounts` → `sync`. 보고서를 출력하고 `ops_audit_logs`의 `detail`에 숫자만 남긴다(아이디 목록은 남기지 않는다). 묶음이 꺼져 있으면 `목록 기능이 꺼져 있어요. DIRECTORY_ENABLED를 확인해 주세요.`를 출력하고 종료 코드 1.
  - `yarn ops directory-remove --handle <아이디> [--opt-out] --operator --reason` — 계정의 `deletedAt`을 채우고, 그 계정의 `PREPARED`·`SENT` 연락을 `EXPIRED`로 바꾼다. `--opt-out`이면 `directory_opt_outs`에 `source: OPERATOR`로 넣는다(본인이 메일로 요청한 경우).
  - `yarn ops directory-opt-outs [--since <YYYY-MM-DD>]` — 읽기 전용. 아이디와 거부 시각, 출처를 출력한다. 묶음이 꺼져 있어도 동작한다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('adds new accounts and updates existing ones by handle', ...);           // 두 번 sync → added 6, 그 뒤 updated 6
it('never re-adds an opted-out handle', ...);                                 // skippedOptedOut 1, 행 없음
it('skips accounts outside 1000 to 50000 followers', ...);                   // 999, 50001 → skippedOutOfRange 2
it('restores a removed account on the next import', ...);
it('lowercases handles and refuses import without operator and reason', ...); // '@Noodle.Diary' → 'noodle.diary'
it('removes an account, expires its live outreach and can record an opt-out', ...);
it('lists opt-outs even when the bundle is off', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn build && DIRECTORY_ADAPTER=file yarn ops directory-import --file seed/directory-sample.csv --operator dev --reason 견본`
- [ ] **Step 5: README에 명령 세 개와 CSV 형식 추가, Commit** — `feat: 목록 파일 가져오기와 계정 제거·거부 목록 운영 명령 추가`

---

### Task 4: 목록 검색 API

**Files:**
- Create: `api/src/directory/{directory.controller.ts,directory.service.ts,directory-row-state.ts,dto/list-directory.query.ts,dto/directory-row.model.ts}`
- Modify: `api/src/directory/directory.repository.ts`
- Test: `api/src/directory/directory-row-state.spec.ts`, `api/test/directory.e2e-spec.ts`

**Interfaces:**
- Consumes: `StoresService.requireMyStore`, `VisibilityService.filterCreators` (4번), `instagram_connections`, `creator_profiles`, `creator_principles.fields`, `outreachStatusAt`·`restingUntil` (Task 5의 `common/outreach/outreach-rules.ts` — 이 작업에서 먼저 만든다), `Clock`
- Produces:
  - `type RowState = 'JOINED' | 'CAN_CONTACT' | 'CONTACTED' | 'OTHER_STORE' | 'RESTING'`
  - `rowState(input: { joined: boolean; outreaches: { storeId; status; sentAt; expiresAt }[] }, myStoreId: string, now: Date): { state: RowState; availableFrom: Date | null }` (순수 함수) — 가입했으면 `JOINED`. 살아 있는 `SENT`가 내 것이면 `CONTACTED`, 남의 것이면 `OTHER_STORE`. 보낸 적 있는 연락이 만료된 지 30일이 안 됐으면 그 연락이 내 것이면 `CONTACTED`, 남의 것이면 `RESTING`(`availableFrom = expiresAt + 30일`). 그 밖은 `CAN_CONTACT`. 내 `PREPARED`는 상태를 바꾸지 않는다.
  - `GET /directory?query=&tab=ALL|JOINED|NOT_JOINED&field=&cursor=` → 200 `{ items: DirectoryRowModel[]; nextCursor: string | null }`. `STORE` 역할만(403), 가게가 없으면 404. `operationId: listDirectory`
  - `DirectoryRowModel { key: string; directoryAccountId: string | null; creatorId: string | null; handle: string; displayName: string; followers: number | null; fieldLabels: string[]; refreshedAt: string | null; state: RowState; availableFrom: string | null }` — `key`는 `d:<id>` 또는 `c:<creatorId>`
  - 합치는 규칙: (1) 지우지 않은 목록 계정(거부 목록 제외) — 연결된 아이디가 같으면 `JOINED`로 바꾸고 `creatorId`, 활동 이름, 연결의 팔로워를 쓴다. (2) 목록에 없는 가입 크리에이터 중 인스타그램 연결이 있는 사람 — `displayName`은 활동 이름, `fieldLabels`는 협업 원칙의 분야, `refreshedAt` null. 가입 줄은 모두 `filterCreators`(viewer `{ userId, kind: 'STORE', industry: store.industry }`)를 통과해야 한다.
  - 검색은 표시 이름과 아이디의 부분 일치(대소문자 무시, `%`·`_`는 이스케이프), `field`는 분야 꼬리표에 그 업종이 있는 줄만. 순서: 팔로워 많은 순(null은 뒤), 같으면 아이디 순. 커서는 base64url `{ offset }`, 틀리면 400.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('marks my live outreach as CONTACTED and another store’s as OTHER_STORE', ...);
it('rests an account for 30 days after an outreach expired', ...);          // expiresAt+30d-1ms RESTING, +30d CAN_CONTACT
it('ignores my PREPARED draft when deciding the state', ...);
it('lists directory accounts and connected creators together by followers', ...); // 6 + 1
it('marks a directory account JOINED only when an instagram connection has that handle', ...); // 본인이 적은 handle만 → CAN_CONTACT
it('hides a joined creator who avoids my industry', ...);
it('filters by tab, query on name and handle, and field', ...);             // query '국물' → soup.collector, tab JOINED → 가입 줄만
it('escapes like wildcards in the query', ...);                              // '%' → 0줄
it('never lists an opted-out handle', ...);
it('requires the STORE role', ...);                                         // 403
it('pages twenty rows with a cursor', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 목록 계정과 가입 크리에이터를 합친 리스트 검색 API 추가`

---

### Task 5: 연락 문구, 준비, 보냄

**Files:**
- Create: `api/src/common/outreach/{outreach-rules.ts,outreach-message.ts,korean-josa.ts}`, `api/src/outreach/{outreach.module.ts,outreach.controller.ts,outreach.service.ts,outreach.repository.ts,dto/*.ts}`
- Test: `api/src/common/outreach/*.spec.ts`, `api/src/outreach/outreach.service.spec.ts`, `api/test/outreach.e2e-spec.ts`, `api/test/db/outreach.repository.db-spec.ts`

**Interfaces:**
- Consumes: `buildTerms`, `OfferTermsModel`, `StoresService.requireMyStore` (2번), `IndustryCategory` 표시 이름, `OutreachPort` (Task 2), `rowState` (Task 4), `Clock`
- Produces (순수 함수):
  - `outreach-rules.ts`: 상수 `OUTREACH_EXPIRY_DAYS = 14`, `OUTREACH_REST_DAYS = 30`, `OUTREACH_DAILY_LIMIT = 5`, `OUTREACH_MESSAGE_MAX = 300`; `outreachStatusAt(o: { status; expiresAt }, now): OutreachStatus`(`SENT`이고 `expiresAt <= now`면 `EXPIRED`); `restingUntil(o: { sentAt; expiresAt }): Date | null`(보낸 적이 없으면 null); `kstDayRange(now): { start: Date; end: Date }`; `newInviteCode(): string`
  - `korean-josa.ts`: `josa(word: string, pair: '이에요/예요' | '으로/로' | '과/와'): string` — 끝의 괄호·공백을 건너뛴 마지막 한글 글자의 받침으로 고른다. `으로/로`는 받침이 `ㄹ`이면 `로`. 한글이 없으면 뒤의 것.
  - `outreach-message.ts`: `outreachRewardPhrase(terms: OfferTermsModel): string` — `VOUCHER` → `{식사권 이름}`, `PER_VIEW` → `조회 1회당 10원(최대 {상한})`, `BOTH` → `{식사권 이름}{과/와} 조회수당 보상`. `draftOutreachMessage(input: { neighborhood: string | null; storeName: string; accountName: string; fieldLabel: string | null; terms: OfferTermsModel }): string` — 틀 `안녕하세요, {동네} {가게 이름}{이에요/예요}. {이름} 님의 {분야} 콘텐츠를 보고 연락드려요. {보상 요약}{으로/로} {형식} 1편을 부탁드리고 싶어요. 자세한 조건은 아래 링크에서 볼 수 있어요.` 분야가 없으면 둘째 문장을 빼고, 동네가 없으면 `{동네} `를 뺀다. 결과가 300자를 넘으면 throw. `composeClipboardText(message, inviteUrl): string` = `message + '\n\n' + inviteUrl`.
- Produces (API, `STORE` 역할만, 가게가 `PUBLISHED`가 아니면 409 `가게를 먼저 공개해 주세요.`):
  - `POST /outreach` 본문 `{ directoryAccountId }` → 201 `OutreachDraftModel { outreachId; account: { handle; displayName; followers; fieldLabels }; message: string; inviteUrl: string; instagramProfileUrl: string; terms: OfferTermsModel; remainingToday: number }`. 계정이 없거나 지워졌거나 거부 목록에 있으면 404. `rowState`가 `JOINED`면 409 `이미 Cora에 가입한 계정이에요.`, `OTHER_STORE`면 409 `다른 가게가 먼저 연락했어요.`, `CONTACTED`·`RESTING`이면 409 `지금은 연락할 수 없는 계정이에요.` 내 `PREPARED`가 있으면 그것을 그대로 돌려준다(코드와 문구 유지). 없으면 가게 기본 조건으로 `terms` 사본, `draftOutreachMessage`, `newInviteCode()`로 `PREPARED`를 만든다. 잠금도 하루 건수도 건드리지 않는다. `inviteUrl` = `{INVITE_BASE_URL}/i/{code}`, `instagramProfileUrl` = `https://www.instagram.com/{handle}/`. `operationId: prepareOutreach`
  - `POST /outreach/:id/mark-sent` 본문 `{ message: string(1~300, 앞뒤 공백 제거) }` → 200 `SentOutreachModel`. 남의 것은 404. 한 트랜잭션에서: 가게 행 `SELECT … FOR UPDATE` → 오늘(KST) `sentAt`이 있는 내 연락이 5건이면 429 `RATE_LIMITED` `오늘은 더 연락할 수 없어요. 하루에 5건까지 보낼 수 있어요.` → 그 계정의 기한 지난 `SENT`를 `EXPIRED`로 저장 → 거부 목록·가입·쉬는 기간 다시 확인(위와 같은 409) → `UPDATE … SET status='SENT', message, sent_at=now, expires_at=now+14일 WHERE id=? AND status='PREPARED'`(0행이면 409 `CONFLICT`). 부분 유일 인덱스 위반은 409 `다른 가게가 먼저 연락했어요.` 커밋 뒤 `OutreachPort.deliver`. `operationId: markOutreachSent`
  - `GET /outreach/sent` → 200 `SentOutreachModel[] { id; account: { handle; displayName }; status: 'SENT' | 'EXPIRED'; sentAt; expiresAt }` — 내 연락 가운데 `outreachStatusAt`이 `SENT`인 것과, 보낸 지 30일 안의 `EXPIRED`·`OPTED_OUT`(둘 다 `EXPIRED`로 보낸다). `CONVERTED`는 오퍼가 됐으므로 빼고, 읽을 때 기한 지난 것은 저장한다. 최근 보낸 순. `operationId: listSentOutreach`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('fills the fixed template for the canvas example', ...);                 // '안녕하세요, 성수동 한그릇 라멘이에요. 면치기 일기 님의 맛집·카페 콘텐츠를 보고 연락드려요. 2인 식사권과 조회수당 보상으로 릴스 1편을 …'
it('drops the second sentence when the account has no field tag', ...);
it('picks 예요, 로 and 와 after a vowel ending', ...);                        // '하루카페예요', '커트 이용권으로'… josa('하루카페','이에요/예요') → '하루카페예요'
it('expires a sent outreach exactly 14 days after sending', ...);
it('prepares a terms copy and a 43 char invite code, the same draft twice', ...); // inviteUrl …/i/<code>
it('does not lock the account or count toward the cap while PREPARED', ...); // 다른 가게도 준비 가능, remainingToday 5
it('marks sent and stores the edited message', ...);
it('lets only one of two stores mark the same account as sent', ...);        // Promise.all → [200, 409 '다른 가게가 먼저 연락했어요.']
it('refuses the sixth outreach of the Korean day with RATE_LIMITED', ...);   // 429
it('keeps the cap under two concurrent mark-sent calls at four', ...);       // 5건만 SENT
it('resets the cap at Korean midnight', ...);
it('refuses contact for 30 days after an outreach expired', ...);            // 409 '지금은 연락할 수 없는 계정이에요.'
it("returns 404 for an opted-out account or another store's outreach", ...);
it('lists live and expired outreach and hides converted ones', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 연락 메시지 고정 틀과 연락 규칙 추가`, `feat: 연락 준비·보냄 기록과 잠금, 하루 5건 제한 추가`

---

### Task 6: 초대 웹 페이지와 수신 거부

**Files:**
- Create: `api/src/common/html/escape-html.ts`, `api/src/invites/{invites.module.ts,invite-page.controller.ts,invites.controller.ts,invites.service.ts,invites.repository.ts,invite-page.html.ts,dto/invite-summary.model.ts}`
- Modify: `api/src/app.module.ts`(`InvitesModule` 항상, `ThrottlerModule`), `api/src/app.setup.ts`(`/i/*`를 Swagger에서 뺌)
- Test: `api/src/common/html/escape-html.spec.ts`, `api/src/invites/invite-page.html.spec.ts`, `api/test/invites.e2e-spec.ts`

**Interfaces:**
- Consumes: `offer_terms` 표시 함수의 서버판(`formatLabel`, `outreachRewardPhrase`), `outreachStatusAt` (Task 5), `opt-outs.repository.ts` (Task 3), `Clock`
- Produces:
  - `escapeHtml(s: string): string` — `& < > " '`를 바꾼다
  - `renderInvitePage(view: InvitePageView): string`, `renderOptOutConfirm(code): string`, `renderOptOutDone(): string`, `renderInviteMessage(title: string): string` — 한 장짜리 HTML, `<html lang="ko">`, 휴대폰 폭, 인라인 CSS만
  - `GET /i/:code` (`@Public()`, `@ApiExcludeController`, 분당 20회) → 200 HTML. 보이는 것은 가게의 공개 정보와 조건뿐이다(대상 아이디·사장님 이름·연락 문구는 넣지 않는다): 제목 `{가게 이름}에서 콘텐츠를 부탁했어요`, 동네, 항목 `콘텐츠` `{형식} 1편`, `보상` `{보상 요약}`, 안내 `Cora에 가입하고, 연락받은 인스타그램 계정을 연동하면 이 오퍼가 도착해요.`, 계정 전환 안내 `개인 계정은 연동할 수 없어요. 인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 연동해 주세요.`, 버튼 `Cora에서 수락하기`(`cora://invite/{code}`), 그 아래 `App Store`, `Google Play`(설정의 주소), 맨 아래 링크 `이런 연락을 받고 싶지 않아요`(→ `GET /i/:code/opt-out`). 상태별: `PREPARED`·`SENT` 위와 같음, `EXPIRED` → `기한이 지난 연락이에요.`(수신 거부 링크는 남김), `CONVERTED` → `이미 오퍼로 전달됐어요. Cora 앱에서 확인해 주세요.`, `OPTED_OUT` → `수신을 거부했어요. 다시 연락하지 않을게요.`, 가게가 지워졌거나 코드가 없거나 형식(43자 base64url)이 틀림 → 모두 같은 404 HTML `연락을 찾을 수 없어요.`
  - `GET /i/:code/opt-out` → 200 확인 페이지(아무것도 바꾸지 않음): `이 연락을 거부할까요? 거부하면 Cora의 목록에서 빠지고, 어떤 가게도 다시 연락할 수 없어요.` 와 `<form method="post">` 버튼 `거부하기`
  - `POST /i/:code/opt-out` → 200 `renderOptOutDone()`. 한 트랜잭션에서: `directory_opt_outs`에 대상 아이디(`source: INVITE_PAGE`, 이미 있으면 그대로), 목록 계정 `deletedAt = now`, 그 아이디를 대상으로 한 모든 가게의 `PREPARED`·`SENT`·`EXPIRED` 연락을 `OPTED_OUT`(`optedOutAt = now`)으로. 이미 거부했으면 같은 완료 페이지. `CONVERTED`면 바꾸지 않고 `이미 오퍼로 전달됐어요. …` 페이지.
  - `GET /invites/:code` (`@Public()`, 분당 20회) → 200 `InviteSummaryModel { storeName: string; neighborhood: string | null; terms: OfferTermsModel; status: 'OPEN' | 'EXPIRED' | 'CLOSED' }` | 404. 앱의 초대 안내가 쓴다. `operationId: getInviteSummary`
  - 요청 제한을 넘으면 HTML 경로는 429 `renderInviteMessage('잠시 뒤 다시 시도해 주세요.')`, JSON 경로는 429 `RATE_LIMITED`.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('escapes all five html special characters', ...);
it('renders a store name with a script tag as plain text', ...);             // '<script>' 없음, '&lt;script&gt;' 있음
it('shows only public store info and terms on the invite page', ...);       // 대상 handle, 연락 문구 없음
it('sets the security headers and never mutates on GET', ...);              // CSP, noindex, no-store; GET 두 번 뒤 상태 그대로
it('returns the same 404 page for an unknown, malformed or deleted-store code', ...);
it('answers 429 after twenty requests a minute from one ip', ...);
it('records the opt-out only on POST and removes the account from the list', ...); // GET /directory에서 사라짐
it('marks every live or expired outreach to that handle OPTED_OUT', ...);  // 두 가게
it('keeps a converted outreach unchanged on opt-out', ...);
it('shows the expired message but keeps the opt-out link', ...);
it('serves the invite summary json for the app', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — 개발 서버에서 `http://127.0.0.1:3000/i/<code>`를 휴대폰 브라우저 크기로 열어 본다.
- [ ] **Step 5: gen-api, Commit** — `feat: 초대 웹 페이지와 수신 거부 추가`

---

### Task 7: 가입 전환, 만료 작업, 탈퇴 연동

**Files:**
- Create: `api/src/invites/{outreach-conversion.service.ts,outreach-lifecycle.service.ts}`, `api/src/jobs/handlers/outreach-expiry.handler.ts`
- Modify: `api/src/instagram/{instagram.module.ts,instagram.service.ts,dto/instagram-connection.model.ts}`, `api/src/offers/{offers.service.ts,offers.repository.ts}`, `api/src/jobs/job-names.ts`
- Test: `api/src/invites/outreach-conversion.service.spec.ts`, `api/test/outreach-conversion.e2e-spec.ts`, `api/src/jobs/handlers/outreach-expiry.handler.spec.ts`

**Interfaces:**
- Consumes: `InstagramService` 연결 완료 (3번 Task 5), `OffersService`, `OFFER_RESPONSE_DAYS` (2번), `VisibilityService.commissionerVisibleTo` (4번), `PushPort`, `OperatorAlertPort`, `JobScheduler.repeatDaily` (7번)
- Produces:
  - `OffersService.createFromOutreach(input: { outreachId: string; storeId: string; creatorId: string; terms: OfferTermsModel }, tx): Promise<string | null>` — 2번의 보내기 경로와 같은 검사(가게 `PUBLISHED`, 크리에이터 프로필, 열린 오퍼 부분 유일, `commissionerVisibleTo`)를 거치되 DTO 대신 저장된 조건 사본을 쓴다. `kind: STANDARD`, `expiresAt = now + 7일`. 막히면 null. 만들면 크리에이터에게 3번 Task 3A의 `OFFER_RECEIVED`(`{가게 이름}{이/가} {형식} {편 수}편 오퍼를 보냈어요.` (2026-11-11 소유자 결정))
  - `OutreachConversionService.convertOnConnect(input: { creatorId: string; handle: string }): Promise<number>` — 소문자 아이디가 같은 목록 계정의 `linkedCreatorId`를 채운다. 한 트랜잭션에서 그 아이디를 대상으로 한 `SENT`이고 `expiresAt > now`인 연락을 `FOR UPDATE`로 잡고(계정당 하나), `createFromOutreach` → `UPDATE … SET status='CONVERTED', converted_at=now, offer_id=? WHERE id=? AND status='SENT'`. `createFromOutreach`가 null이면 `EXPIRED`로 저장한다. 커밋 뒤 사장님에게 `{활동 이름}님이 가입해 오퍼가 전달됐어요.` 만든 오퍼 수를 돌려준다. 초대 코드는 받지 않는다.
  - 3번의 `POST /instagram/connect/complete`: 연결을 저장한 트랜잭션이 끝난 뒤 `convertOnConnect`를 부른다. 이것이 실패해도 연결은 성공으로 응답하고, 오류를 로그와 `OperatorAlertPort.alert({ subject: '[Cora] 연락 전환 실패', … })`로 남긴다. `InstagramConnectionModel`에 `invitedOffers: number` 추가.
  - `JobName`에 `'outreach-expiry'` 추가. `InvitesModule.onModuleInit`에서 `repeatDaily('outreach-expiry', { hourKst: 3, jobKey: 'outreach-expiry-daily' })`. 처리기: `SENT`이고 `expiresAt <= now`인 것을 `EXPIRED`로, `preparedAt`이 14일 넘은 `PREPARED`도 `EXPIRED`로(`sentAt`은 null로 남아 쉬는 기간을 만들지 않는다). 조건부 갱신이라 두 번 돌아도 같다.
  - `OutreachLifecycleService.expireAllForStore(storeId: string): Promise<number>` — 그 가게의 `PREPARED`·`SENT`를 `EXPIRED`로. `InvitesModule`이 export한다. 회원 탈퇴 흐름(출시 준비 계획)이 공통 규칙 20장의 "살아 있는 연락: 만료"로 부른다. 이 계획은 탈퇴 흐름 자체를 만들지 않는다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('turns a sent outreach into an offer when the same handle is connected', ...); // 대소문자 다르게 연결해도
it('copies the stored terms and starts the 7 day window at conversion', ...);     // FakeClock: 보낸 지 10일 뒤 연결 → expiresAt = 연결 시각 + 7일
it('does nothing for a different handle or an expired outreach', ...);      // status 그대로, invitedOffers 0
it('grants nothing to someone who only has the invite code', ...);          // GET /invites/:code만으로는 오퍼 0
it('notifies the store owner and the creator once', ...);
it('expires the outreach instead when the creator avoids the store industry', ...);
it('still connects instagram when the conversion fails', ...);              // 200, 운영자 알림 1건
it('expires sent outreach after 14 days and is safe to run twice', ...);
it('expires every live outreach of a store for account deletion', ...);
it('converts already-sent outreach even when the bundle is off', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 연동한 계정이 같으면 연락을 오퍼로 전환`, `feat: 연락 만료 작업과 탈퇴용 만료 처리 추가`

---

### Task 8: 앱 — 서버 설정과 강제 업데이트

**Files:**
- Create: `app/lib/features/server_config/domain/{server_config.dart,server_config_repository.dart,app_version.dart,app_version_reader.dart}`, `data/{api_server_config_repository.dart,package_info_app_version_reader.dart}`, `presentation/viewmodels/server_config_view_model.dart`, `presentation/pages/update_required_page.dart`, `presentation/config_gate.dart`
- Modify: `app/lib/app.dart`(`ConfigGate`로 감쌈), `app/lib/main.dart`(override), `pubspec.yaml`
- Test: `app/test/features/server_config/`

**Interfaces:**
- Consumes: `cora_api`의 `getAppConfig` (Task 2), `CoraErrorView`, `CoraPrimaryButton`
- Produces:
  - `enum OutreachMode { manual, relay }`, `class ServerConfig { final String minSupportedVersion; final bool directoryEnabled; final OutreachMode outreachMode; final String iosStoreUrl; final String androidStoreUrl; }`
  - `abstract class ServerConfigRepository { Future<ServerConfig> fetch(); }`, `serverConfigRepositoryProvider`(기본값 `UnimplementedError`)
  - `abstract class AppVersionReader { Future<String> current(); }`, `appVersionReaderProvider`(기본값 `UnimplementedError`)
  - `isBelowMinimum(String current, String minimum): bool` (`app_version.dart`, 순수 함수) — `major.minor.patch`를 숫자로 비교, 빌드 번호(`+12`)는 무시
  - `serverConfigViewModelProvider` (`AsyncNotifier<ServerConfig>`), `directoryEnabledProvider` (`Provider<bool>`, 불러오기 전이나 실패 시 false)
  - `ConfigGate({ required Widget child })` — 불러오는 중에는 배경색만, 실패하면 `CoraErrorView`(`다시 시도`), 버전이 낮으면 `UpdateRequiredPage`, 아니면 `child`. 로그인 여부와 무관하게 라우터보다 먼저 판단한다.

화면 문구:
- 업데이트: 제목 `업데이트가 필요해요`, 설명 `새 버전에서 계속 쓸 수 있어요.`, 버튼 `업데이트하기`(플랫폼에 맞는 스토어 주소를 외부 앱으로). 뒤로 가기로 닫히지 않는다.
- 설정을 못 불러옴: `서버에 연결하지 못했어요.` + `다시 시도`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('compares versions numerically and ignores the build number', ...);    // isBelowMinimum('1.9.0','1.10.0') true, ('1.2.0+7','1.2.0') false
testWidgets('blocks the app with the update screen when below the minimum', ...); // '업데이트가 필요해요', 로그인 화면 없음
testWidgets('opens the platform store url from the update button', ...);
testWidgets('shows retry on a load failure and passes through when supported', ...);
test('treats the bundle as disabled until the config has loaded', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test`
- [ ] **Step 5: Commit** — `feat: 앱 시작 시 서버 설정을 읽고 강제 업데이트 안내 추가`

---

### Task 9: 앱 — 찾기 탭 전환과 리스트(C1)

**Files:**
- Create: `app/lib/features/store_find/presentation/pages/store_find_page.dart`, `app/lib/features/directory/domain/{directory_row.dart,directory_repository.dart,directory_text.dart}`, `data/api_directory_repository.dart`, `presentation/viewmodels/directory_list_view_model.dart`, `presentation/pages/directory_list_page.dart`
- Modify: `app/lib/core/navigation/app_router.dart`(`/store/find` → `StoreFindPage`, `/store/find/list`), `app/lib/features/store_home/presentation/pages/store_home_page.dart`(바로가기 `리스트 검색` → `/store/find/list`, 꺼져 있으면 숨김), `app/lib/main.dart`
- Test: `app/test/features/directory/`, `app/test/features/store_find/`, `app/test/features/store_home/`(추가)

**Interfaces:**
- Consumes: `cora_api`의 `listDirectory` (Task 4), `directoryEnabledProvider` (Task 8), 7번의 `ReelsFeedPage` 본문, `CoraSegmentedTabs`, `CoraListRow`, B5 라우트 `/store/creators/:id`
- Produces:
  - `enum DirectoryTab { all, joined, notJoined }`, `enum RowState { joined, canContact, contacted, otherStore, resting }`, `class DirectoryRow { final String key; final String? directoryAccountId; final String? creatorId; final String handle; final String displayName; final int? followers; final List<String> fieldLabels; final DateTime? refreshedAt; final RowState state; final DateTime? availableFrom; }`
  - `abstract class DirectoryRepository { Future<({List<DirectoryRow> items, String? nextCursor})> list({ String? query, DirectoryTab tab, IndustryCategory? field, String? cursor }); }`, `directoryRepositoryProvider`(기본값 `UnimplementedError`)
  - `directory_text.dart`(순수 함수): `followersLabel(12000)` → `1.2만`, `640` → `640`, `4800` → `4,800`, `10000` → `1만`; `refreshedLabel(DateTime, now)` → `오늘 업데이트` / `어제 업데이트` / `3일 전 업데이트`; `rowMeta(DirectoryRow, now)` → `@noodle.diary, 팔로워 1.2만, 3일 전 업데이트`, 가입 줄 `@onecup.day, 팔로워 640, 가입함`(팔로워가 없으면 그 부분을 뺀다); `rowActionLabel(RowState)` → `가입함`, `연락하기`, `연락함`, `다른 가게가 연락 중`, `연락 대기`
  - `DirectoryListViewModel` — 검색어는 300ms 늦춰 요청, 탭·분야를 바꾸면 처음부터, 끝에서 다섯 줄 남으면 다음 페이지.
  - `StoreFindPage` — 위에 `CoraSegmentedTabs` `릴스` / `리스트`. `directoryEnabled`가 false면 전환을 숨기고 릴스만(7번과 같은 모습). 꺼진 상태에서 `/store/find/list`로 오면 `/store/find`로 보낸다. 전환은 `CoraTransitions.fade`.

화면 문구 (C1):
- 제목 `크리에이터 찾기`, 검색란 예시 글자 `이름이나 아이디로 찾기`, 탭 `전체` / `가입함` / `미가입`, 분야 칩(일반 업종 9개, 하나만), 고정 표지 `팔로워 1천 – 5만`(누를 수 없음), 안내 `Cora가 고른 크리에이터 목록이에요.`
- 줄: 이름 첫 글자 원, 이름, `rowMeta`, 오른쪽 버튼 `rowActionLabel`. `연락하기`만 강조. `가입함` 줄을 누르면 B5(`/store/creators/:id`, `CoraTransitions.push`), `연락하기`는 C2, `연락함`·`다른 가게가 연락 중`은 눌리지 않음, `연락 대기`를 누르면 짧은 안내 `최근에 연락을 받은 계정이에요. {M월 D일}부터 연락할 수 있어요.`
- 빈 목록: 검색 결과 없음 `찾는 크리에이터가 없어요.`, 목록 자체가 빔 `아직 목록에 크리에이터가 없어요.` 실패는 `CoraErrorView`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('formats followers, refresh times and meta lines like the canvas', ...); // '1.2만', '640', '4,800', '@onecup.day, 팔로워 640, 가입함'
testWidgets('shows the reels and list switch only when the bundle is enabled', ...);
testWidgets('hides the home list shortcut when the bundle is disabled', ...);
testWidgets('shows the curated notice and the fixed follower scope', ...);   // 'Cora가 고른 크리에이터 목록이에요.', '팔로워 1천 – 5만'
testWidgets('searches after the debounce and filters by tab', ...);
testWidgets('opens the public profile for a joined row', ...);
testWidgets('opens outreach for a contactable row and disables contacted rows', ...);
testWidgets('explains when a resting account can be contacted again', ...);
testWidgets('loads the next page near the end', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 사장님 찾기 탭의 릴스·리스트 전환과 리스트 검색 화면 추가`

---

### Task 10: 앱 — 연락(C2)과 보낸 오퍼에 합치기

**Files:**
- Create: `app/lib/features/directory/domain/{outreach_draft.dart,sent_outreach.dart,outreach_repository.dart,outreach_launcher.dart}`, `data/{api_outreach_repository.dart,system_outreach_launcher.dart}`, `presentation/viewmodels/outreach_view_model.dart`, `presentation/pages/outreach_page.dart`, `presentation/widgets/sent_prompt_sheet.dart`
- Modify: `app/lib/features/store_home/{domain/store_home_repository.dart,presentation/viewmodels/store_home_view_model.dart,presentation/store_home_text.dart,presentation/pages/store_home_page.dart}`, `app/lib/core/navigation/app_router.dart`(`/store/find/list/outreach/:directoryAccountId`), `app/lib/main.dart`
- Test: `app/test/features/directory/outreach_*_test.dart`, `app/test/features/store_home/`(추가)

**Interfaces:**
- Consumes: `cora_api`의 `prepareOutreach`, `markOutreachSent`, `listSentOutreach` (Task 5), `directoryEnabledProvider`, `formatLabel`, `rewardHeadline` (2번)
- Produces:
  - `class OutreachDraft { final String outreachId; final String handle; final String displayName; final int followers; final String message; final String inviteUrl; final String instagramProfileUrl; final OfferTerms terms; final int remainingToday; }`, `class SentOutreach { final String id; final String handle; final String displayName; final bool live; final DateTime sentAt; }`
  - `abstract class OutreachRepository { Future<OutreachDraft> prepare(String directoryAccountId); Future<void> markSent(String outreachId, String message); Future<List<SentOutreach>> fetchSent(); }` — 409는 `OutreachConflictException(message)`, 429는 `OutreachDailyLimitException`으로 바꾼다
  - `abstract class OutreachLauncher { Future<void> copy(String text); Future<bool> openInstagram(Uri profileUrl); }` — 실제 구현은 `Clipboard.setData`와 `url_launcher`의 `LaunchMode.externalApplication`
  - `OutreachViewModel` — `copyAndOpen()`: `composeClipboardText`와 같은 규칙(`메시지 + 빈 줄 + 링크`)으로 복사 → 인스타그램 열기 → `awaitingReturn = true`. `AppLifecycleListener`의 `onResume`에서 `awaitingReturn`이면 `보내셨나요?` 시트를 띄운다. `confirmSent()` → `markSent(편집한 메시지)`.
  - `StoreHomeViewModel` — `directoryEnabled`면 `fetchSent()`도 불러 `보낸 오퍼` 탭에 오퍼와 연락을 보낸 시각 순으로 섞고, 숫자 `보낸 오퍼` = `summary.sentOffers + 살아 있는 연락 수`. 꺼져 있으면 부르지 않는다.
  - `store_home_text.dart`에 `sentOutreachMeta(SentOutreach)` → 살아 있으면 `미가입, 쪽지 보냄`, 아니면 `답이 없었어요`

화면 문구 (C2):
- 머리 `연락하기`. 이름, `@noodle.diary, 팔로워 1.2만`, 표지 `아직 Cora 미가입`.
- `보낼 메시지` 입력란(여러 줄, 300자, 오른쪽 아래 `{n} / 300`), 그 아래 초대 링크 한 줄(고칠 수 없음).
- 안내 세 줄: `메시지를 복사해 드려요. 인스타그램에서 직접 보내 주세요.`, `오퍼 조건과 가입 링크가 함께 가요.`, `답이 오기 전에는 같은 계정에 다시 보낼 수 없어요. 상대가 수신을 거부하면 목록에서 빠져요.` 그 위 작은 글 `오늘 {n}건 더 보낼 수 있어요.`
- 버튼 `메시지 복사하고 인스타그램 열기`(메시지가 비면 꺼짐). 누르면 `메시지와 링크를 복사했어요.` 인스타그램을 열지 못하면 `인스타그램을 열지 못했어요. 메시지는 복사돼 있어요.`
- 돌아왔을 때 시트: `보내셨나요?` / `보냈어요` / `아직이요`. `보냈어요` → 성공하면 `연락을 기록했어요.`와 함께 리스트로 돌아가고 그 줄은 `연락함`. `아직이요` → C2에 그대로(잠금 없음).
- 오류: 409 서버 문구 그대로(`다른 가게가 먼저 연락했어요.`, `이미 Cora에 가입한 계정이에요.`, `지금은 연락할 수 없는 계정이에요.`) 후 리스트를 새로 고침. 429 `오늘은 더 연락할 수 없어요. 하루에 5건까지 보낼 수 있어요.`
- 사장님 홈 보낸 오퍼 줄: 이름, `미가입, 쪽지 보냄` 또는 `답이 없었어요`, 사진 자리는 이름 첫 글자, 버튼 없음, 눌리지 않음.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('shows the account, the editable draft and the three notices', ...); // 첫 줄 '메시지를 복사해 드려요. 인스타그램에서 직접 보내 주세요.'
testWidgets('caps the message at 300 characters and disables an empty one', ...);
testWidgets('copies message and invite link then opens the instagram profile', ...); // FakeOutreachLauncher.copied == '…\n\nhttps://…/i/abc'
testWidgets('asks whether it was sent when the app resumes', ...);          // '보내셨나요?'
testWidgets('records the outreach on 보냈어요 and keeps it prepared on 아직이요', ...);
testWidgets('shows the conflict message when another store sent first', ...); // '다른 가게가 먼저 연락했어요.'
testWidgets('shows the daily limit message on 429', ...);
testWidgets('merges live outreach into the sent tab and the count', ...);   // '미가입, 쪽지 보냄', 숫자 +1
testWidgets('shows an expired outreach as 답이 없었어요 without counting it', ...);
testWidgets('does not load outreach rows when the bundle is disabled', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — C2는 `CoraTransitions.push`, `보내셨나요?`는 바닥 시트.
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 미가입 계정 연락 화면 추가`, `feat: 사장님 홈 보낸 오퍼에 미가입 연락 줄 합치기`

---

### Task 11: 앱 — 초대 딥 링크와 연동 안내

**Files:**
- Create: `app/lib/features/invite/domain/{deep_link_source.dart,pending_invite_store.dart,invite_summary.dart,invite_repository.dart}`, `data/{package_deep_link_source.dart,prefs_pending_invite_store.dart,api_invite_repository.dart}`, `presentation/viewmodels/invite_guide_view_model.dart`, `presentation/pages/invite_guide_page.dart`
- Modify: `app/ios/Runner/Info.plist`·`app/android/app/src/main/AndroidManifest.xml`(스킴 `cora`, 호스트 `invite`), `app/lib/core/navigation/app_router.dart`(`/creator/invite`), `roleEntryResolverProvider`의 `creator` 분기, `app/lib/features/onboarding/presentation/viewmodels/role_select_view_model.dart`(초대가 있으면 처음 선택 `creator`), `app/lib/features/instagram_connect/…`(연동 화면의 안내 줄과 결과), `app/lib/main.dart`
- Test: `app/test/features/invite/`, `app/test/features/instagram_connect/`(추가), `app/test/features/onboarding/`(추가)

**Interfaces:**
- Consumes: `cora_api`의 `getInviteSummary` (Task 6), `completeInstagramConnect`의 `invitedOffers` (Task 7), 3번의 `/creator/instagram`, 2번의 `/creator/offers`
- Produces:
  - `abstract class DeepLinkSource { Future<Uri?> initial(); Stream<Uri> get links; }`, `abstract class PendingInviteStore { Future<String?> read(); Future<void> save(String code); Future<void> clear(); }` — 둘 다 provider 기본값 `UnimplementedError`
  - `parseInviteCode(Uri uri): String?` (순수 함수) — `cora://invite/<43자 base64url>`만 받는다
  - 흐름: 링크를 받으면 코드를 저장한다(로그인 전이어도). 크리에이터 진입 규칙: 프로필 없음 → `/creator/profile/setup`, 프로필이 있고 저장된 초대가 있고 인스타그램 연결이 없음 → `/creator/invite`, 그 밖은 지금대로. 사장님이나 브랜드 역할이면 초대를 무시하고 지운다.
  - `InviteGuidePage` — `getInviteSummary`로 가게 이름과 조건을 보여 준다(404거나 `CLOSED`면 코드를 지우고 `/creator`로).
  - 연동 결과: `invitedOffers > 0`이면 코드를 지우고 `/creator/offers`로 가며 `연락받은 오퍼가 도착했어요.` 0이고 초대가 남아 있으면 연동 화면에 머물며 안내.

화면 문구:
- 초대 안내: 제목 `{가게 이름}의 오퍼가\n기다리고 있어요`, 조건 두 줄(`콘텐츠` `{형식} 1편`, `보상` `{보상 한 줄}`), 안내 `연락받은 계정과 같은 계정을 연동하면 오퍼가 도착해요.`, 버튼 `인스타그램 연동하기`(→ `/creator/instagram`), 아래 `나중에 하기`(→ `/creator`, 초대는 남겨 둠). `EXPIRED`면 위에 `기한이 지난 연락이에요. 연동해도 오퍼가 오지 않을 수 있어요.`
- 연동 화면(초대가 있을 때만 추가): 위 안내와 같은 줄, 그리고 `개인 계정은 연동할 수 없어요. 인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 다시 연동해 주세요.` 연동했는데 전환이 없으면 `이 계정으로 받은 연락이 없어요. 연락받은 인스타그램 계정으로 다시 연동해 주세요.` (어느 계정인지는 보여 주지 않는다.)

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('parses only valid cora invite links and keeps one received before login', ...);
testWidgets('preselects the creator role when an invite is pending', ...);
testWidgets('sends a creator with an invite and no connection to the guide after profile setup', ...);
testWidgets('shows the store terms and the same-account notice', ...);    // '연락받은 계정과 같은 계정을 연동하면 오퍼가 도착해요.'
testWidgets('goes to received offers and clears the invite after a converting connection', ...);
testWidgets('stays on connect with guidance when nothing converted', ...);
testWidgets('drops the invite for a store or brand account', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — iOS 시뮬레이터에서 `xcrun simctl openurl booted "cora://invite/<code>"`, Android 에뮬레이터에서 `adb shell am start -d "cora://invite/<code>"`로 열어 본다.
- [ ] **Step 5: Commit** — `feat: 초대 딥 링크와 같은 계정 연동 안내 추가`

---

### Task 12: 출시 게이트와 전체 흐름 확인

**Files:**
- Modify: `README.md`(절 `8번 묶음 출시 게이트` 추가). 고칠 것이 나오면 해당 작업의 파일을 고치고 `fix:` 커밋.

- [ ] **Step 1: 출시 게이트 점검표 작성** — README에 아래 항목을 체크 상자로 넣는다. 각 항목에 확인한 사람, 날짜, 근거 문서 위치를 적는 칸을 둔다. 이 점검표가 모두 채워지고 소유자가 서명하기 전에는 운영 환경의 `DIRECTORY_ENABLED`를 `true`로 바꾸지 않는다.
  1. 설계 6장 1: 운영자가 고른 계정의 아이디·표시 이름·팔로워 수·분야를 본인 동의 없이 보관해도 되는지
  2. 설계 6장 2: 사장님이 앱이 만든 메시지를 모르는 사람에게 보내는 것이 광고성 정보 전송 규정에 걸리는지, 필요한 표시 문구가 있는지
  3. 설계 6장 3: 인스타그램 약관상 앱이 만든 메시지의 반복 발송이 스팸으로 취급되는지
  4. 설계 6장 4: 수신 거부 아이디를 거부 목록으로 계속 보관하는 근거와 보관 기간
  5. 확인 결과 기본안(운영자 목록 + 직접 발송)에서 바꿀 것이 없음, 또는 바꿀 것을 새 설계로 넘김
  6. 개인정보 처리방침에 목록과 거부 목록의 항목이 들어감
  7. 운영 환경 값: `DIRECTORY_ADAPTER=file`, `OUTREACH_ADAPTER=manual`, `INVITE_BASE_URL`이 운영 주소, 첫 목록 파일을 `yarn ops directory-import`로 넣음
- [ ] **Step 2: 자동 확인** — `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db` · `cd app && flutter analyze && flutter test` · `./scripts/gen-api.sh && git status --short`(변경 없음)
- [ ] **Step 3: 스위치 확인** — `cd api && yarn build && NODE_ENV=production DIRECTORY_ENABLED=false DIRECTORY_ADAPTER=fake <나머지 실제 값> node dist/main.js` → 시작함, `GET /directory` 404, `GET /config`의 `directoryEnabled: false`, 앱에서 `리스트` 전환·`리스트 검색`·`미가입` 줄이 보이지 않음. `DIRECTORY_ENABLED=true DIRECTORY_ADAPTER=fake` → 시작 거부. `OUTREACH_ADAPTER=relay` → 시작 거부. `MIN_APP_VERSION=99.0.0` → 앱이 `업데이트가 필요해요`.
- [ ] **Step 4: 세 계정으로 수동 확인** (개발 서버, `DIRECTORY_ADAPTER=fake`, `yarn ops directory-import --operator dev --reason 견본`. A 가게 `한그릇 라멘`, A2 다른 가게, C 새 크리에이터. iOS와 Android 각각)
  1. A: 홈 `리스트 검색` → `Cora가 고른 크리에이터 목록이에요.`, `팔로워 1천 – 5만`, 여섯 줄. `면치기 일기`의 줄 `@noodle.diary, 팔로워 1.2만, 3일 전 업데이트`, `연락하기`.
  2. A: `면치기 일기` → C2의 메시지가 `안녕하세요, 성수동 한그릇 라멘이에요. 면치기 일기 님의 맛집·카페 콘텐츠를 보고 연락드려요. …` → 한 줄 고침 → `메시지 복사하고 인스타그램 열기` → 클립보드에 메시지와 링크 → 앱으로 돌아와 `보내셨나요?` → `아직이요`.
  3. A2: 같은 계정을 준비하고 `보냈어요` → 성공. A: `보냈어요` → `다른 가게가 먼저 연락했어요.` A의 줄은 `다른 가게가 연락 중`.
  4. A: 다른 계정 다섯 곳에 `보냈어요` → 여섯 번째에서 `오늘은 더 연락할 수 없어요. …`. 홈의 `보낸 오퍼` 숫자가 5 늘고 줄마다 `미가입, 쪽지 보냄`.
  5. 휴대폰 브라우저로 A가 보낸 `/i/<code>` → 가게 이름, 조건, `Cora에서 수락하기`. 가게 이름을 `<b>라멘</b>`으로 바꾸고 다시 열면 태그가 글자로 보인다.
  6. 다른 연락의 페이지 → `이런 연락을 받고 싶지 않아요` → `거부하기` → A의 목록에서 그 계정이 사라지고 홈 줄은 `답이 없었어요`. 견본을 다시 가져와도 그 계정은 돌아오지 않는다(`yarn ops directory-opt-outs`에 보임).
  7. C: `cora://invite/<A의 noodle.diary 코드>`로 앱을 연다 → 로그인(E1 `휴대폰 번호로 시작하기` → 아무 `010` 번호 + 인증번호 `000000`, 개발용 가짜 인증) → 역할 선택이 크리에이터로 골라져 있음 → 프로필 → 초대 안내 → 연동 화면에서 `seongsu.meal` 입력 → `이 계정으로 받은 연락이 없어요. …` → 연결을 끊고 `noodle.diary` 입력 → `연락받은 오퍼가 도착했어요.` → 받은 오퍼에 한그릇 라멘의 오퍼, 응답 기한 7일. A에게 알림 로그 `…님이 가입해 오퍼가 전달됐어요.` A의 목록에서 `면치기 일기`는 `가입함`, 누르면 B5.
  8. 서버를 15일 뒤로 띄운다(`FAKE_CLOCK_OFFSET_DAYS=15`) → 남은 연락이 `답이 없었어요`, 그 계정은 A2에게 `연락 대기`. 45일 뒤로 → 다시 `연락하기`.
  9. 서버를 `DIRECTORY_ENABLED=false`로 다시 띄운다 → 앱을 다시 켜면 리스트 관련 화면이 모두 숨고, 3에서 보낸 링크의 페이지와 수신 거부는 그대로 열린다.
  10. 다크 모드와 글자 1.3배에서 C1, C2, 초대 안내, 업데이트 화면을 훑어보고 캔버스 C1, C2와 나란히 놓고 비교한다.

---

## 완료 기준

- Task 12의 자동 확인, 스위치 확인, 수동 확인 10개가 iOS와 Android에서 통과
- README의 출시 게이트 점검표가 들어가 있음(채우는 것은 법적 확인 뒤의 일이다)
- 운영 환경 모드에서 `DIRECTORY_ENABLED=false`면 가짜 목록 구현이 있어도 시작하고, `true`면 `fake`와 `relay`가 시작을 거부함

## 이 계획이 구체화한 것

- 모듈 경계: 초대 페이지·수신 거부·전환·만료 작업은 항상 실리는 `invites` 모듈에 두었다. 묶음을 꺼도 이미 보낸 연락이 가입으로 이어지면 오퍼로 바뀌고, 14일 만료도 계속 돈다.
- 연락 상태를 줄마다 다섯 가지로 정했다: `가입함`, `연락하기`, `연락함`(내 연락이 살아 있거나 만료 뒤 30일 안), `다른 가게가 연락 중`, `연락 대기`(남의 연락이 만료된 뒤 30일 안). 30일 쉬는 기간은 사장님에게 `RESTING`으로 따로 보인다.
- 초대 코드는 연락을 준비할 때 만들고 다시 준비해도 바꾸지 않는다(이미 복사한 링크가 죽지 않게). 문구는 "보냈어요" 때의 편집본을 저장하고, 조건 사본은 준비할 때의 가게 기본 조건이다. 14일 넘게 "보냈어요"를 누르지 않은 준비 상태는 만료로 정리하고 쉬는 기간을 만들지 않는다.
- 고정 틀의 조사(`이에요/예요`, `으로/로`, `과/와`)는 받침에 맞춰 고른다. 보상 요약은 `{식사권 이름}`, `조회 1회당 10원(최대 {상한})`, `{식사권 이름}과 조회수당 보상` 세 가지이고, 동네가 없으면 그 낱말을 뺀다.
- 사장님 홈의 보낸 오퍼 합치기는 앱이 한다(`GET /offers/sent` + `GET /outreach/sent`). 숫자에는 살아 있는 연락만 더하고, 만료와 수신 거부는 30일 동안 `답이 없었어요`로만 보인다(수신 거부 사실은 사장님에게 알리지 않는다). 전환된 연락은 오퍼 줄로 바뀐다.
- 전환이 막힌 경우(가게 비공개, 피하는 업종, 이미 열린 오퍼)는 연락을 만료로 바꾼다. 연동은 전환 실패와 무관하게 성공하고 운영자에게 알린다.
- 공개 초대 경로: 짧은 주소 `/i/:code`, 수신 거부는 GET 확인 페이지 + POST 실행(링크 미리보기가 거부를 일으키지 않게), IP당 분당 20회, 없는 코드는 모두 같은 404 페이지. 앱용 JSON `GET /invites/:code`를 더했다. `GET /config`에 스토어 주소(`storeUrls`)를 더했다.
- 딥 링크는 `cora://invite/<code>`이고, 설치 뒤로 코드를 넘기는 기능(지연 딥 링크)은 만들지 않는다. 전환이 아이디로 일어나므로 코드는 안내 화면에만 쓴다.
- 운영 명령: `directory-import`, `directory-remove [--opt-out]`(본인이 메일로 요청한 거부를 운영자가 기록), `directory-opt-outs`. 목록 파일은 `handle,displayName,followers,fields,refreshedAt` CSV이고 팔로워 1천~5만 밖의 줄은 건너뛴다.
- 새로 정한 문구: `이름이나 아이디로 찾기`, `연락 대기`, `최근에 연락을 받은 계정이에요. {M월 D일}부터 연락할 수 있어요.`, `찾는 크리에이터가 없어요.`, `아직 목록에 크리에이터가 없어요.`, `{n} / 300`, `오늘 {n}건 더 보낼 수 있어요.`, `메시지와 링크를 복사했어요.`, `인스타그램을 열지 못했어요. 메시지는 복사돼 있어요.`, `연락을 기록했어요.`, `이미 Cora에 가입한 계정이에요.`, `지금은 연락할 수 없는 계정이에요.`, `오늘은 더 연락할 수 없어요. 하루에 5건까지 보낼 수 있어요.`, `가게를 먼저 공개해 주세요.`, `{가게 이름}에서 콘텐츠를 부탁했어요`, `Cora에 가입하고, 연락받은 인스타그램 계정을 연동하면 이 오퍼가 도착해요.`, `개인 계정은 연동할 수 없어요. 인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 연동해 주세요.`, `기한이 지난 연락이에요.`, `이미 오퍼로 전달됐어요. Cora 앱에서 확인해 주세요.`, `이 연락을 거부할까요? 거부하면 Cora의 목록에서 빠지고, 어떤 가게도 다시 연락할 수 없어요.`, `거부하기`, `수신을 거부했어요. 다시 연락하지 않을게요.`, `연락을 찾을 수 없어요.`, `잠시 뒤 다시 시도해 주세요.`, `{활동 이름}님이 가입해 오퍼가 전달됐어요.`, `{가게 이름}의 오퍼가\n기다리고 있어요`, `나중에 하기`, `기한이 지난 연락이에요. 연동해도 오퍼가 오지 않을 수 있어요.`, `연락받은 오퍼가 도착했어요.`, `이 계정으로 받은 연락이 없어요. 연락받은 인스타그램 계정으로 다시 연동해 주세요.`, `새 버전에서 계속 쓸 수 있어요.`, `업데이트하기`, `서버에 연결하지 못했어요.`, `목록 기능이 꺼져 있어요. DIRECTORY_ENABLED를 확인해 주세요.`

## 이 계획이 하지 않는 것

- 법적·정책 확인 자체와 그 결론 (Task 12의 점검표로 넘긴다)
- 자동 수집으로 목록을 채우는 구현, `relay`(대신 전달) 구현 (포트 자리만 있고 `relay`는 시작을 거부한다)
- 브랜드의 목록 사용, 목록 계정에 대한 평가·메모, 사진·게시물 보관, 운영자용 웹 화면
- 회원 탈퇴 흐름 전체 (이 계획은 `expireAllForStore`만 내놓는다)
- 설치 뒤로 초대 코드를 넘기는 지연 딥 링크, 유니버설 링크·앱 링크 (출시 준비 계획)
