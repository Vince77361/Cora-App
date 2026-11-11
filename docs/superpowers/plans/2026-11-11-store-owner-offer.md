# 가게 사장님 흐름과 오퍼 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 사장님이 가게 링크로 가게 페이지를 만들어 공개하고, 크리에이터가 지원하고, 사장님이 오퍼를 보내고, 크리에이터가 수락하거나 거절하는 데까지를 만든다.

**Architecture:** 서버에 `creators`, `stores`, `content-drafts`, `applications`, `offers`, `uploads` 모듈을 더한다. 링크 분석과 AI 초안은 포트 뒤의 가짜 구현이다. 오퍼의 만료와 거절 되돌리기 시간은 예약 작업 없이, 시각을 주입받는 순수 함수로 "지금 보이는 상태"를 계산한다. 앱은 feature 다섯 개를 더하고 공통 기반의 역할별 빈 홈을 실제 화면으로 바꾼다.

**Tech Stack:** 공통 기반과 같다. 추가: `@supabase/supabase-js`(서버의 Storage 접근), `image_picker`(앱의 사진 고르기).

**Spec:** `docs/superpowers/specs/2026-11-11-store-owner-offer-design.md` (상위: `docs/superpowers/specs/2026-11-11-tech-stack-design.md`, 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md`)

**선행 조건:** `docs/superpowers/plans/2026-11-11-foundation.md`의 작업 10개가 모두 끝나 있어야 한다. 이 계획은 그 계획이 만든 `AppError`, `AuthGuard`, `@CurrentUser()`, `PrismaService`, `IntegrationsModule`, `assertNoFakesInProduction`, `scripts/gen-api.sh`, `apiClientProvider`, `appRouterProvider`, `CoraTransitions`, 공용 위젯, 토큰을 그대로 쓴다.

## Global Constraints

공통 기반 계획의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것:

- 새 테이블을 만드는 마이그레이션마다 `ENABLE ROW LEVEL SECURITY`를 넣는다. `yarn test:db`의 RLS 감시 테스트가 통과해야 한다.
- 모든 테이블에 `created_at`, `updated_at`, `deleted_at`을 둔다.
- 권한은 역할과 소유 관계를 함께 본다. 역할이 틀리면 403 `FORBIDDEN`, 남의 것을 ID로 요청하면 404 `NOT_FOUND`.
- 시각은 `Clock`으로 주입받는다. service와 순수 함수 안에서 `new Date()`를 직접 부르지 않는다.
- 고정 값: 조회당 단가 `10`원, 조회수당 상한 `100000`원, 식사권 기본 이름 `2인 식사권`, 식사권 기본 금액 `40000`원, 오퍼 응답 기한 `7`일, 수락 후 결제 기한 `3`일, 거절 되돌리기 `30`초, 초안 다시 만들기 하루 `10`번, 사진 최대 `5`MB, 허용 형식 `image/jpeg`, `image/png`, `image/heic`.
- 새 오류 코드 `RATE_LIMITED`(429)를 `ErrorCode`에 더한다.
- 화면 문구는 설계 문서 3장과 기획 캔버스의 문구를 그대로 쓴다.
- API를 바꾼 작업은 `./scripts/gen-api.sh`를 실행하고 생성물을 같은 커밋에 넣는다.
- 작업 브랜치를 만들지 않고 `main`에 바로 커밋한다. 커밋마다 테스트가 통과한 상태여야 한다. push는 소유자 확인 후에만 한다.

## Review Focus

1. **다른 사장님의 지원자·오퍼를 ID로 요청함** → 404. 내용이 새지 않는다. (Task 6, 7)
2. **같은 오퍼에 수락과 거절이 거의 동시에 들어옴** → 하나만 성공하고 다른 하나는 409. (Task 7)
3. **기한이 지난 오퍼를 수락하려 함** → 409, 상태는 `EXPIRED`로 저장된다. (Task 7)
4. **링크 분석이 실패함** → 사장님이 막히지 않고 빈 가게 페이지로 넘어가 직접 입력할 수 있다. (Task 4, 10)
5. **등록 도중 앱을 껐다 켬** → 멈춘 단계에서 이어진다. (Task 10)

---

## 파일 구조

```text
api/
├── prisma/schema.prisma                         # 모델 6개, enum 7개 추가
├── seed/store-sample-cover.jpg                  # 가짜 링크 분석의 견본 사진
├── src/
│   ├── common/clock.ts                          # Clock, SystemClock
│   ├── uploads/                                 # 사진 업로드 주소 발급
│   ├── integrations/
│   │   ├── storage/                             # StoragePort, SupabaseStorageAdapter
│   │   ├── store-link/                          # StoreLinkPort, FakeStoreLinkAdapter
│   │   └── content-draft/                       # ContentDraftPort, FakeContentDraftAdapter
│   ├── creators/
│   ├── stores/
│   ├── content-drafts/
│   ├── applications/
│   └── offers/
│       ├── offer-rules.ts                       # 순수 함수: 보이는 상태, 가능한 동작
│       └── ...
└── test/support/                                # FakeClock, FakeStoragePort, 테스트 데이터 만들기

app/lib/
├── core/ui/                                     # 단계 머리글, 하단 메뉴, 탭, 준비 중 화면 추가
└── features/
    ├── creator_profile/                         # 크리에이터 최소 프로필
    ├── store_onboarding/                        # A2, A3, 편집, A4
    ├── offer_terms/                             # 3단계 조건 고르기 (기본 조건, A5 공용)
    ├── store_home/                              # A9
    ├── store_browse/                            # 공개된 가게 목록, D2
    └── offers/                                  # A5 보내기, A6 받은 오퍼
```

---

### Task 1: 스키마, 마이그레이션, Clock

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/common/errors/app-error.ts`
- Create: `api/prisma/migrations/<timestamp>_store_owner_offer/migration.sql`, `api/src/common/clock.ts`, `api/test/support/fake-clock.ts`
- Test: `api/test/db/store-offer-schema.db-spec.ts`

**Interfaces:**
- Produces:
  - enum `StoreStatus { DRAFT, PUBLISHED }`, `StoreOnboardingStep { PAGE, DRAFTS, TERMS, DONE }`, `SourceLinkKind { NAVER_MAP, CATCHTABLE, INSTAGRAM }`, `ContentDraftKind { CARD_NEWS, REELS_SCRIPT, BLOG }`, `ContentFormat { SHORTS, REELS, CARD_NEWS, BLOG }`, `RewardType { VOUCHER, PER_VIEW, BOTH }`, `ApplicationStatus { APPLIED, CANCELLED, OFFERED, CLOSED }`, `OfferStatus { SENT, ACCEPTED, DECLINED, EXPIRED, CANCELLED }`
  - `Store` → `stores`: `id`, `ownerId`(unique, → `users`), `status`, `onboardingStep`, `name?`, `category?`, `neighborhood?`, `coverPhotoPath?`, `signatureMenu?`, `hours?`, `seats?`, `bestShootingTime?`, `intro?`, `defaultFormat?`, `defaultRewardType?`, `defaultVoucherName?`, `defaultVoucherValue?`
  - `StoreSourceLink` → `store_source_links`: `storeId`, `kind`, `url`, `summary?`
  - `StoreContentDraft` → `store_content_drafts`: `storeId`, `kind`, `bodyLabel`, `body`, `scenes`(Json), `version`(Int), `regeneratedOn?`(날짜), `regenerationsOnDay`(Int). `(storeId, kind)` unique.
  - `CreatorProfile` → `creator_profiles`: `userId`(unique), `displayName`, `contentFocus?`, `instagramHandle?`, `photoPath?`
  - `Application` → `applications`: `storeId`, `creatorId`(→ `users`), `status`
  - `Offer` → `offers`: `storeId`, `creatorId`, `applicationId?`, `format`, `rewardType`, `voucherName?`, `voucherValue?`, `perViewAmount?`, `perViewCap?`, `status`, `expiresAt`, `acceptedAt?`, `paymentDueAt?`, `declinedAt?`, `respondedAt?`
  - 부분 유니크 인덱스(마이그레이션에 직접 SQL로): `applications (store_id, creator_id) WHERE status IN ('APPLIED','OFFERED') AND deleted_at IS NULL`, `offers (store_id, creator_id) WHERE status IN ('SENT','ACCEPTED') AND deleted_at IS NULL`
  - `abstract class Clock { abstract now(): Date }`, `class SystemClock extends Clock`, 테스트용 `class FakeClock extends Clock { set(d: Date): void; advance(ms: number): void }`
  - `ErrorCode`에 `'RATE_LIMITED'` 추가, 필터가 429로 내보낸다

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- `enum IndustryCategory { FOOD_CAFE, BEAUTY, FASHION, ACCESSORY, LIVING, GROCERY, DIGITAL, HEALTH, OTHER, ALCOHOL, GAMBLING, LOAN, DIET_SUPPLEMENT }` (표시 이름: 맛집·카페, 뷰티·미용, 패션, 액세서리·주얼리, 리빙·소품, 식품, 전자·디지털, 건강·운동, 기타, 주류, 도박·사행성, 대출·금융, 다이어트 보조제)
- `Store`에 `industry: IndustryCategory @default(FOOD_CAFE)`, `regionSido?`, `regionSigungu?` 추가. `CreatorProfile`에 `regionSido`, `regionSigungu?` 추가.
- 시·도 값은 17개 고정 목록이다: 서울특별시, 부산광역시, 대구광역시, 인천광역시, 광주광역시, 대전광역시, 울산광역시, 세종특별자치시, 경기도, 강원특별자치도, 충청북도, 충청남도, 전북특별자치도, 전라남도, 경상북도, 경상남도, 제주특별자치도. `api/src/common/regions.ts`에 `SIDO_LIST`로 둔다.

- [ ] **Step 1: 실패하는 테스트 작성** (`store-offer-schema.db-spec.ts`)

```ts
it('rejects a second live application for the same store and creator', async () => {
  await createApplication({ status: 'APPLIED' });
  await expect(createApplication({ status: 'APPLIED' })).rejects.toThrow();
});
it('allows a new application after the previous one was cancelled', async () => {
  await createApplication({ status: 'CANCELLED' });
  await expect(createApplication({ status: 'APPLIED' })).resolves.toBeDefined();
});
it('rejects a second open offer for the same store and creator', async () => {
  await createOffer({ status: 'SENT' });
  await expect(createOffer({ status: 'ACCEPTED' })).rejects.toThrow();
});
it('allows a new offer after the previous one was declined', async () => {
  await createOffer({ status: 'DECLINED' });
  await expect(createOffer({ status: 'SENT' })).resolves.toBeDefined();
});
it('allows only one store per owner', async () => { ... });
```

기존 `rls.db-spec.ts`는 고치지 않는다. 새 테이블 6개에서도 통과해야 한다.

- [ ] **Step 2: 실패 확인** — Run: `cd api && yarn test:db` · Expected: FAIL (테이블 없음)
- [ ] **Step 3: 스키마, 마이그레이션(부분 인덱스와 테이블 6개의 RLS 포함), `Clock` 구현**
- [ ] **Step 4: 통과 확인** — Run: `cd api && yarn prisma migrate dev && yarn test:db && yarn test` · Expected: PASS
- [ ] **Step 5: Commit** — `feat: 가게·지원·오퍼 스키마와 Clock 추가`

---

### Task 2: Storage 포트와 사진 업로드 주소

**Files:**
- Create: `api/src/integrations/storage/storage.port.ts`, `api/src/integrations/storage/supabase-storage.adapter.ts`, `api/src/uploads/uploads.module.ts`, `api/src/uploads/uploads.controller.ts`, `api/src/uploads/uploads.service.ts`, `api/src/uploads/dto/create-photo-upload.dto.ts`, `api/test/support/fake-storage.port.ts`, `api/scripts/setup-supabase.ts`(`yarn setup:supabase`: 버킷 `photos`를 공개로 만든다. 이미 있으면 아무것도 하지 않는다)
- Modify: `api/src/config/env.ts`(`SUPABASE_SERVICE_ROLE_KEY` 추가), `api/.env.example`, `api/src/integrations/integrations.module.ts`
- Test: `api/src/uploads/uploads.service.spec.ts`, `api/test/uploads.e2e-spec.ts`

**Interfaces:**
- Produces:
  - `abstract class StoragePort { abstract createUploadUrl(path: string): Promise<string>; abstract upload(path: string, bytes: Buffer, contentType: string): Promise<void>; abstract publicUrl(path: string): string }`
  - 버킷 이름 `photos`(공개 읽기). 경로 규칙: `stores/<userId>/<uuid>.<ext>`, `creators/<userId>/<uuid>.<ext>`
  - `POST /uploads/photos` 본문 `{ purpose: 'STORE_COVER' | 'CREATOR_PHOTO', contentType: string, sizeBytes: number }` → 201 `{ uploadUrl: string, path: string }`. `operationId: createPhotoUpload`
  - `UploadsService.assertOwnedPath(userId, path, purpose): void` — 경로가 그 사용자의 것이 아니면 `AppError('FORBIDDEN', ...)`. Task 3, 5가 사진 경로를 저장하기 전에 부른다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('rejects a content type that is not jpeg, png or heic', ...);        // 400 VALIDATION_FAILED, image/gif
it('rejects a file larger than 5MB', ...);                              // sizeBytes 5 * 1024 * 1024 + 1
it('accepts exactly 5MB', ...);
it('issues a path under the caller id for a store cover', ...);         // path가 `stores/${USER_A}/`로 시작, `.jpg`로 끝남
it('requires the STORE role for a store cover', ...);                   // CREATOR 역할 → 403
it('assertOwnedPath rejects a path under another user id', ...);
```

- [ ] **Step 2: 실패 확인** — Run: `cd api && yarn test uploads && yarn test:e2e uploads` · Expected: FAIL
- [ ] **Step 3: 구현** — `SupabaseStorageAdapter`만 `@supabase/supabase-js`를 import한다. Storage는 가짜/실제 전환 대상이 아니므로 `_ADAPTER` 환경변수를 만들지 않는다(개발용 원격 Supabase의 실제 Storage를 쓴다). 테스트는 `FakeStoragePort`로 override한다.
- [ ] **Step 4: 통과 확인, 실제 Storage로 수동 확인** — Run: `cd api && yarn test && yarn test:e2e` · Expected: PASS. 발급된 `uploadUrl`에 `curl -X PUT`으로 작은 JPEG를 올리고 `publicUrl`로 내려받아 본다.
- [ ] **Step 5: `./scripts/gen-api.sh` 실행, Commit** — `feat: 사진 업로드 주소 발급 추가`

---

### Task 3: 크리에이터 최소 프로필 API

**Files:**
- Create: `api/src/creators/creators.module.ts`, `creators.controller.ts`, `creators.service.ts`, `creators.repository.ts`, `dto/upsert-creator-profile.dto.ts`, `dto/creator-profile.model.ts`
- Test: `api/src/creators/creators.service.spec.ts`, `api/test/creators.e2e-spec.ts`

**Interfaces:**
- Consumes: `StoragePort.publicUrl`, `UploadsService.assertOwnedPath` (Task 2)
- Produces:
  - `GET /creators/me` → 200 `CreatorProfileModel` | 404. `operationId: getMyCreatorProfile`
  - `PUT /creators/me` 본문 `{ displayName: string(1~20자), contentFocus?: string(최대 30자), instagramHandle?: string(영문·숫자·`.`·`_`, 최대 30자, 앞의 `@`는 떼고 저장), photoPath?: string }` → 200 `CreatorProfileModel`. `operationId: upsertMyCreatorProfile`
  - `CreatorProfileModel { userId, displayName, contentFocus: string | null, instagramHandle: string | null, photoUrl: string | null }`
  - `CreatorSummaryModel { userId, displayName, contentFocus: string | null, photoUrl: string | null }` — Task 6, 7의 목록이 쓴다
  - `CreatorsService`를 export: `getSummary(userId): Promise<CreatorSummaryModel | null>`, `requireProfile(userId): Promise<CreatorProfileModel>`(없으면 `AppError('CONFLICT', '크리에이터 프로필을 먼저 만들어 주세요.')`)

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- `PUT /creators/me`에 `regionSido`(필수, `SIDO_LIST` 중 하나), `regionSigungu?`(최대 20자) 추가. `CreatorProfileModel`과 `CreatorSummaryModel`에 두 값 추가.
- 테스트 추가: `it('rejects a region that is not in the sido list', ...)` (400), `it('requires a region', ...)` (400).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('returns 404 before a profile exists', ...);
it('creates then updates the profile', ...);
it('requires the CREATOR role', ...);                                  // STORE 역할 → 403 FORBIDDEN
it('rejects an empty display name', ...);                              // 400
it('strips a leading @ from the instagram handle', ...);               // '@min.closet' → 'min.closet'
it('rejects a photo path under another user id', ...);                 // 403
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e`
- [ ] **Step 5: gen-api, Commit** — `feat: 크리에이터 최소 프로필 API 추가`

---

### Task 4: 링크 분석과 AI 초안 포트 (가짜 구현)

**Files:**
- Create: `api/src/integrations/store-link/store-link.port.ts`, `fake-store-link.adapter.ts`, `api/src/integrations/content-draft/content-draft.port.ts`, `fake-content-draft.adapter.ts`, `api/seed/store-sample-cover.jpg`
- Modify: `api/src/config/env.ts`(`STORE_LINK_ADAPTER`, `CONTENT_DRAFT_ADAPTER`: `'fake' | 'real'`), `api/.env.example`, `api/src/integrations/integrations.module.ts`
- Test: `api/src/integrations/store-link/fake-store-link.adapter.spec.ts`, `api/src/integrations/content-draft/fake-content-draft.adapter.spec.ts`, `api/src/integrations/assert-no-fakes.spec.ts`(추가)

**Interfaces:**
- Produces:
  - `type SourceLinkInput = { kind: SourceLinkKind; url: string }`
  - `type StoreLinkResult = { store: { name: string | null; category: string | null; neighborhood: string | null; signatureMenu: string | null; hours: string | null; seats: string | null; bestShootingTime: string | null; intro: string | null }; coverPhoto: { bytes: Buffer; contentType: string } | null; linkSummaries: { kind: SourceLinkKind; summary: string }[] }`
  - `abstract class StoreLinkPort { abstract analyze(links: SourceLinkInput[]): Promise<StoreLinkResult> }` — 분석 실패는 `StoreLinkAnalysisError`를 던진다
  - `type DraftScene = { label: string; text: string; usesPhoto: boolean }`
  - `type DraftContent = { bodyLabel: string; body: string; scenes: DraftScene[] }`
  - `abstract class ContentDraftPort { abstract generate(input: { storeName: string; signatureMenu: string | null; bestShootingTime: string | null; intro: string | null }, kind: ContentDraftKind, version: number): Promise<DraftContent> }`
  - 가짜 링크 분석의 값(캔버스 A3): 이름 `한그릇 라멘`, 업종 `라멘집`, 동네 `성수동`, 대표 메뉴 `돈코츠 라멘 11,000원`, 영업시간 `11:30 – 21:00`, 좌석 `18석, 바 좌석`, 찍기 좋은 시간 `오후 3시 – 5시`, 소개 `진한 국물을 12시간 끓이는 작은 라멘집이에요. 김이 오르는 첫 숟가락 장면을 담아주세요.`
  - 가짜 요약: 네이버 지도 `사진 12장, 메뉴 8개 찾음`, 캐치테이블 `영업시간 찾음`, 인스타그램 `게시물 9개 찾음`
  - 가짜 링크 분석은 주소에 `fail`이 들어 있으면 `StoreLinkAnalysisError`를 던진다(실패 경로를 손으로 확인하기 위해)
  - 가짜 초안: 캔버스 A4의 문안 세 벌(카드뉴스, 릴스 대본, 블로그 글)을 `version`이 짝수일 때 그대로, 홀수일 때 장면 2와 3의 순서를 바꿔 돌려준다

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- `StoreLinkResult.store`에 `industry: IndustryCategory | null`, `regionSido: string | null`, `regionSigungu: string | null` 추가. 가짜 구현의 값: `FOOD_CAFE`, `서울특별시`, `성동구`.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('returns the sample store for any valid links', ...);               // name === '한그릇 라멘'
it('returns one summary per link kind given', ...);
it('throws StoreLinkAnalysisError when the url contains "fail"', ...);
it('returns three scenes and a body for each draft kind', ...);        // CARD_NEWS bodyLabel '본문', REELS_SCRIPT '촬영 순서', BLOG '도입부'
it('returns different scene order for odd and even versions', ...);
it('throws in production when STORE_LINK_ADAPTER is fake', ...);
it('throws in production when CONTENT_DRAFT_ADAPTER is fake', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn test integrations`
- [ ] **Step 5: Commit** — `feat: 링크 분석과 AI 초안 포트, 가짜 구현 추가`

---

### Task 5: 가게와 콘텐츠 초안 API

**Files:**
- Create: `api/src/stores/`(module, controller, service, repository, `dto/analyze-links.dto.ts`, `dto/update-store.dto.ts`, `dto/set-default-terms.dto.ts`, `dto/my-store.model.ts`, `dto/store-public.model.ts`, `dto/offer-terms.model.ts`, `offer-terms.ts`), `api/src/content-drafts/`(module, controller, service, repository, `dto/content-draft.model.ts`)
- Test: `api/src/stores/offer-terms.spec.ts`, `api/src/stores/stores.service.spec.ts`, `api/src/content-drafts/content-drafts.service.spec.ts`, `api/test/stores.e2e-spec.ts`, `api/test/content-drafts.e2e-spec.ts`

**Interfaces:**
- Consumes: `StoreLinkPort`, `ContentDraftPort` (Task 4), `StoragePort`, `UploadsService` (Task 2), `Clock` (Task 1)
- Produces:
  - `OfferTermsModel { format: ContentFormat; rewardType: RewardType; voucherName: string | null; voucherValue: number | null; perViewAmount: number | null; perViewCap: number | null }`
  - `buildTerms(input: { format; rewardType; voucherName?; voucherValue? }): OfferTermsModel` (`offer-terms.ts`, 순수 함수) — `VOUCHER`면 조회 항목은 `null`, `PER_VIEW`면 식사권 항목은 `null`, 식사권이 포함되는데 이름·금액이 없으면 기본값 `2인 식사권`, `40000`. 조회 항목은 항상 `10`, `100000`.
  - `MyStoreModel { id; status; onboardingStep; name; category; neighborhood; coverPhotoUrl; signatureMenu; hours; seats; bestShootingTime; intro; defaultTerms: OfferTermsModel | null; sourceLinks: { kind; url; summary: string | null }[] }` (없는 글자 항목은 `null`)
  - `StoreSummaryModel { id; name; category; neighborhood; coverPhotoUrl; defaultTerms: OfferTermsModel }`
  - `StoreDetailModel` = `StoreSummaryModel` + `{ signatureMenu; hours; seats; bestShootingTime; intro; myApplicationStatus: 'NONE' | 'APPLIED' | 'OFFERED' }`
  - `POST /stores/me/analyze` 본문 `{ links: SourceLinkInput[] }`(1~3개, 종류 중복 불가, 주소 형식 검사) → 200 `{ store: MyStoreModel; analysisFailed: boolean }`. 가게가 없으면 `DRAFT`로 만들고, `DRAFT`면 덮어쓴다. `PUBLISHED`면 409. 분석이 실패하면 링크만 저장한 빈 가게를 만들고 `analysisFailed: true`. 끝나면 `onboardingStep = PAGE`. `operationId: analyzeMyStoreLinks`
  - 주소 검사: `NAVER_MAP`은 호스트가 `naver.me` 또는 `map.naver.com`, `CATCHTABLE`은 `app.catchtable.co.kr`, `INSTAGRAM`은 `instagram.com` 또는 `www.instagram.com`. 모두 `https`.
  - `GET /stores/me` → 200 `MyStoreModel` | 404. `operationId: getMyStore`
  - `PATCH /stores/me` 본문 `{ name?, category?, neighborhood?, signatureMenu?, hours?, seats?, bestShootingTime?, intro?, coverPhotoPath? }`(이름 1~30자, 소개 최대 300자, 나머지 최대 50자) → 200 `MyStoreModel`. `operationId: updateMyStore`
  - `POST /stores/me/onboarding-step` 본문 `{ step: 'DRAFTS' | 'TERMS' }` → 200 `MyStoreModel`. 앞 단계로만 간다. `operationId: advanceMyStoreOnboarding`
  - `PUT /stores/me/default-terms` 본문 `{ format, rewardType, voucherName?(1~20자), voucherValue?(1000~1000000) }` → 200 `MyStoreModel`. `operationId: setMyStoreDefaultTerms`
  - `POST /stores/me/publish` → 200 `MyStoreModel`(`status: PUBLISHED`, `onboardingStep: DONE`). 이름이 없거나 기본 조건이 없으면 409. `operationId: publishMyStore`
  - `GET /stores` → 200 `StoreSummaryModel[]` — `PUBLISHED`만, 내 가게 제외, 최근 공개 순. `operationId: listPublishedStores`
  - `GET /stores/:id` → 200 `StoreDetailModel` | 404(`DRAFT` 포함). `operationId: getPublishedStore`
  - `StoresService`를 export: `requireMyStore(userId): Promise<Store>`(없으면 404), `requirePublished(storeId): Promise<Store>`(없으면 404)
  - `ContentDraftModel { kind; bodyLabel; body; scenes: DraftScene[]; regenerationsLeftToday: number }`
  - `GET /stores/me/content-drafts` → 200 `ContentDraftModel[]`(종류 순서: 카드뉴스, 릴스 대본, 블로그 글). 하나도 없으면 세 종류를 만들어 저장한 뒤 돌려준다. `operationId: listMyContentDrafts`
  - `POST /stores/me/content-drafts/:kind/regenerate` → 200 `ContentDraftModel`. 그 종류만 `version + 1`로 다시 만든다. 그 종류의 오늘 횟수가 10이면 429 `RATE_LIMITED`. 날짜는 한국 시간 기준. `operationId: regenerateMyContentDraft`

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- `MyStoreModel`, `StoreSummaryModel`에 `industry`, `regionSido`, `regionSigungu` 추가. `PATCH /stores/me`가 세 값을 받는다. 분석이 `industry`를 주지 않으면 `FOOD_CAFE`.
- `buildTerms`는 형식이 `BLOG`이고 보상이 `PER_VIEW` 또는 `BOTH`이면 `AppError('VALIDATION_FAILED', '블로그 글은 조회수를 셀 수 없어요.')`를 던진다.
- `POST /stores/me/publish`는 `regionSido`가 없어도 409.
- `GET /stores`의 순서: 요청한 크리에이터와 구·군이 같은 가게, 시·도가 같은 가게, 그 밖의 가게 순. 각 묶음 안에서는 최근 공개 순.
- 테스트 추가: `it('rejects blog with a per-view reward', ...)`, `it('rejects publishing without a region', ...)`, `it('lists stores in my district first, then my province', ...)`.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
// offer-terms.spec.ts
it('fills voucher defaults when a voucher reward has no name or value', ...);   // '2인 식사권', 40000
it('drops voucher fields for a per-view reward', ...);
it('always uses 10 won per view capped at 100000', ...);

// stores.e2e-spec.ts
it('creates a draft store from links', ...);                            // status DRAFT, onboardingStep PAGE, name '한그릇 라멘'
it('copies the cover photo into storage', ...);                         // FakeStoragePort에 stores/<USER>/... 한 건
it('falls back to an empty store when analysis fails', ...);            // analysisFailed true, name null, sourceLinks 유지
it('rejects a naver link on the wrong host', ...);                      // 400
it('rejects duplicate link kinds', ...);                                // 400
it('rejects analyze after publishing', ...);                            // 409
it('requires the STORE role', ...);                                     // 403
it('rejects publishing without default terms', ...);                    // 409
it('publishes once name and terms exist', ...);
it('lists only published stores and excludes my own', ...);
it('hides a draft store from other users', ...);                        // GET /stores/:id → 404
it('shows my application status on the detail', ...);                   // Task 6 이후 'APPLIED'가 되도록 여기서는 'NONE'만

// content-drafts.e2e-spec.ts
it('generates three drafts on first read', ...);
it('regenerates only the requested kind', ...);
it('refuses the 11th regeneration of the day', ...);                    // 429 RATE_LIMITED
it('resets the count on the next Korean calendar day', ...);            // FakeClock을 KST 자정 뒤로
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 가게 등록·수정·공개 API 추가`, `feat: 콘텐츠 초안 API 추가`

---

### Task 6: 지원 API

**Files:**
- Create: `api/src/applications/`(module, controller, service, repository, `dto/applicant.model.ts`, `dto/application.model.ts`)
- Modify: `api/src/stores/stores.service.ts`(`myApplicationStatus` 채우기)
- Test: `api/src/applications/applications.service.spec.ts`, `api/test/applications.e2e-spec.ts`

**Interfaces:**
- Consumes: `StoresService.requireMyStore`, `requirePublished` (Task 5), `CreatorsService.requireProfile`, `getSummary` (Task 3), `PushPort` (공통 기반)
- Produces:
  - `POST /stores/:id/applications` → 201 `ApplicationModel { id; storeId; status }`. `operationId: applyToStore`
  - `DELETE /stores/:id/applications/mine` → 204. `operationId: cancelMyApplication`
  - `GET /stores/me/applications` → 200 `ApplicantModel[] { applicationId; creator: CreatorSummaryModel; appliedAt: string }` — `APPLIED`만, 최근 지원 순. `operationId: listMyStoreApplicants`
  - `ApplicationsService`를 export: `markOffered(storeId, creatorId): Promise<string | null>`(살아 있는 `APPLIED` 지원을 `OFFERED`로 바꾸고 그 id를 돌려준다), `closeFor(applicationId): Promise<void>`(`OFFERED` → `CLOSED`), `countNew(storeId): Promise<number>`
  - 지원이 생기면 `PushPort.send({ userId: 가게 주인, title: 'Cora', body: '{활동 이름}님이 지원했어요.' })`

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- `GET /stores/me/applications`의 순서: 가게와 구·군이 같은 지원자, 시·도가 같은 지원자, 그 밖 순. 각 묶음 안에서는 최근 지원 순.
- 테스트 추가: `it('lists applicants from the store district first', ...)`.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('lets a creator apply to a published store', ...);                   // 201, status APPLIED
it('requires a creator profile before applying', ...);                  // 409
it('requires the CREATOR role', ...);                                   // 403
it('rejects applying to my own store', ...);                            // 409
it('rejects a second live application', ...);                           // 409
it('returns 404 for a draft store', ...);
it('cancels an application and allows applying again', ...);
it('refuses to cancel once an offer was sent', ...);                    // status OFFERED → 409
it('lists only APPLIED applicants for the store owner', ...);
it("does not show another owner's applicants", ...);                    // 다른 사장님 토큰 → 자기 가게 기준의 빈 목록
it('notifies the store owner on a new application', ...);               // FakePush 기록 1건, body '하루 한 컵님이 지원했어요.'
it('shows APPLIED on the store detail after applying', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 가게 지원과 취소, 지원자 목록 API 추가`

---

### Task 7: 오퍼 규칙과 API

**Files:**
- Create: `api/src/offers/offer-rules.ts`, `api/src/offers/`(module, controller, service, repository, `dto/send-offer.dto.ts`, `dto/sent-offer.model.ts`, `dto/received-offer.model.ts`, `dto/store-home-summary.model.ts`)
- Test: `api/src/offers/offer-rules.spec.ts`, `api/src/offers/offers.service.spec.ts`, `api/test/offers.e2e-spec.ts`, `api/test/db/offers.repository.db-spec.ts`

**Interfaces:**
- Consumes: `buildTerms`, `OfferTermsModel`, `StoresService` (Task 5), `ApplicationsService` (Task 6), `CreatorsService` (Task 3), `Clock` (Task 1), `PushPort`
- Produces (`offer-rules.ts`, 모두 순수 함수):
  - 상수 `OFFER_RESPONSE_DAYS = 7`, `PAYMENT_DUE_DAYS = 3`, `DECLINE_UNDO_SECONDS = 30`
  - `type OfferView = 'WAITING' | 'ACCEPTED' | 'DECLINED' | 'EXPIRED' | 'CANCELLED'`
  - `storedStatusAt(offer, now): OfferStatus` — `SENT`이고 `expiresAt <= now`면 `EXPIRED`, `ACCEPTED`이고 `paymentDueAt <= now`면 `EXPIRED`, 아니면 그대로
  - `viewForStore(offer, now): OfferView` — `storedStatusAt` 결과에서, `DECLINED`인데 `declinedAt + 30초 > now`면 `WAITING`, `SENT`는 `WAITING`
  - `viewForCreator(offer, now): OfferView` — `DECLINED`는 바로 `DECLINED`, `SENT`는 `WAITING`
  - `canUndoDecline(offer, now): boolean`
  - `paymentDaysLeft(offer, now): number | null` — 남은 날을 올림한 값
- Produces (API):
  - `POST /offers` 본문 `{ creatorId: string; format; rewardType; voucherName?; voucherValue? }` → 201 `SentOfferModel`. `operationId: sendOffer`
  - `GET /offers/sent` → 200 `SentOfferModel[] { id; creator: CreatorSummaryModel; terms: OfferTermsModel; view: OfferView; paymentDaysLeft: number | null; sentAt }`, 최근 순. `operationId: listSentOffers`
  - `POST /offers/:id/cancel` → 200 `SentOfferModel`. `operationId: cancelOffer`
  - `GET /offers/received?tab=new|active` → 200 `ReceivedOfferModel[] { id; store: StoreSummaryModel; storeIntro: string | null; bestShootingTime: string | null; terms: OfferTermsModel; view: OfferView; receivedAt; canUndoDecline: boolean }`. `new`는 `WAITING`과 되돌릴 수 있는 `DECLINED`를 도착 순으로, `active`는 `ACCEPTED`. `operationId: listReceivedOffers`
  - `POST /offers/:id/accept`, `POST /offers/:id/decline`, `POST /offers/:id/undo-decline` → 200 `ReceivedOfferModel`. `operationId: acceptOffer`, `declineOffer`, `undoDeclineOffer`
  - `GET /stores/me/summary` → 200 `StoreHomeSummaryModel { newApplications: number; sentOffers: number; inProgress: number }` — `sentOffers`는 `view`가 `WAITING`인 수, `inProgress`는 `ACCEPTED`인 수. `operationId: getMyStoreSummary`

규칙:
- 보내기: `STORE` 역할, 내 가게가 `PUBLISHED`, 받는 사람에게 크리에이터 프로필이 있음(없으면 404), 받는 사람이 나 자신이면 409. 보내기 전에 같은 쌍의 기한 지난 오퍼를 `EXPIRED`로 저장한다. 그 뒤에도 열린 오퍼가 있으면 409. `expiresAt = now + 7일`. `ApplicationsService.markOffered`의 결과를 `applicationId`에 넣는다.
- 상태를 바꾸는 요청은 모두 `UPDATE ... WHERE id = ? AND status = <기대 상태>`의 조건부 갱신으로 하고, 바뀐 행이 0이면 409 `CONFLICT`. 읽고 나서 쓰는 방식을 쓰지 않는다.
- 수락: 받는 사람만, `storedStatusAt`이 `SENT`일 때만. 기한이 지났으면 `EXPIRED`로 저장하고 409. `acceptedAt = now`, `paymentDueAt = now + 3일`.
- 거절: 받는 사람만, `SENT`일 때만. `declinedAt = now`. 연결된 지원은 바로 닫지 않는다.
- 거절 되돌리기: 받는 사람만, `canUndoDecline`일 때만. `SENT`로 되돌리고 `declinedAt`을 지운다. 아니면 409.
- 취소: 가게 주인만, `SENT` 또는 `ACCEPTED`일 때만.
- 오퍼가 `DECLINED`(30초 경과 후 처음 읽힐 때)·`EXPIRED`·`CANCELLED`가 되면 연결된 지원을 `ApplicationsService.closeFor`로 닫는다.
- 목록을 읽을 때 `storedStatusAt`이 저장된 상태와 다른 오퍼는 그 자리에서 저장한다.
- 남의 오퍼를 ID로 요청하면 404.
- 알림: 보내면 크리에이터에게 `{가게 이름}에서 오퍼가 왔어요.`, 수락하면 사장님에게 `{활동 이름}님이 오퍼를 수락했어요.` 거절 알림은 이 계획에서 보내지 않는다.

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- `POST /offers`는 `buildTerms`의 블로그 글 규칙을 그대로 따른다. 테스트 추가: `it('rejects a blog offer with a per-view reward', ...)` (400).
- 조회수당 오퍼를 수락하려면 인스타그램 연동이 필요하다는 규칙은 이 계획에서 만들지 않는다. 인스타그램 연결은 3번 계획에서 만들고 그때 수락 검사를 더한다.
- 크리에이터가 피하는 업종의 가게를 거르는 공통 필터는 협업 원칙이 생기는 4번 계획에서 만든다. 이 계획의 조회 쿼리는 repository 한 곳(`stores.repository.ts`의 공개 목록·상세, `creators.repository.ts`의 요약 조회)에 모아 두어 그때 필터를 끼우기 쉽게 한다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
// offer-rules.spec.ts — T0 = 2026-12-01T00:00:00Z에 보낸 오퍼
it('is WAITING for both sides right after sending', ...);
it('expires a sent offer exactly 7 days after sending', ...);          // T0+7d-1ms → SENT, T0+7d → EXPIRED
it('expires an accepted offer 3 days after acceptance', ...);
it('hides a decline from the store for 30 seconds', ...);              // +29s → WAITING, +30s → DECLINED
it('shows a decline to the creator immediately', ...);
it('allows undo only within 30 seconds', ...);
it('rounds payment days left up', ...);                                // 수락 직후 3, 2일 1시간 남으면 3, 23시간 남으면 1

// offers.e2e-spec.ts
it('sends an offer to an applicant and links the application', ...);   // application.status === 'OFFERED'
it('sends an offer to a creator who never applied', ...);              // applicationId null
it('copies terms so later default changes do not affect it', ...);
it('rejects a second open offer to the same creator', ...);            // 409
it('allows a new offer after the previous one expired', ...);          // FakeClock +7d
it('rejects sending from an unpublished store', ...);                  // 409
it('rejects sending to myself', ...);                                  // 409
it('accepts an offer and sets a 3 day payment deadline', ...);         // view ACCEPTED, paymentDaysLeft 3
it('refuses to accept an expired offer and stores EXPIRED', ...);      // 409, DB status EXPIRED
it('lets only one of two concurrent responses win', ...);              // Promise.all([accept, decline]) → 상태코드 정렬 [200, 409]
it('declines, then undoes within 30 seconds', ...);
it('refuses undo after 30 seconds', ...);                              // 409
it('closes the linked application once the decline is final', ...);    // +30s 뒤 GET /offers/sent → application CLOSED, 다시 지원 가능
it("returns 404 for another creator's offer", ...);
it("returns 404 when another store owner cancels my offer", ...);
it('cancels an accepted offer before payment', ...);
it('counts new applications, waiting offers and accepted offers', ...);
it('notifies the creator on send and the owner on accept', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 오퍼 상태 규칙 추가`, `feat: 오퍼 보내기·응답·취소 API 추가`

---

### Task 8: 앱 공용 위젯과 역할별 진입 흐름

**Files:**
- Create: `app/lib/core/ui/cora_step_header.dart`, `cora_bottom_nav.dart`, `cora_segmented_tabs.dart`, `cora_coming_soon_page.dart`, `cora_info_tile.dart`, `cora_secondary_button.dart`, `cora_list_row.dart`, `cora_network_photo.dart`
- Modify: `app/lib/core/navigation/app_router.dart`, `app/lib/features/dev/presentation/pages/motion_gallery_page.dart`(새 위젯 견본 추가)
- Delete: `app/lib/features/onboarding/presentation/pages/role_home_placeholder_page.dart`의 가게·크리에이터 분기(브랜드 분기는 남긴다)
- Test: `app/test/core/ui/*_test.dart`(위젯마다), `app/test/core/navigation/app_router_test.dart`(추가)

**Interfaces:**
- Produces:
  - `CoraStepHeader({ required String title, required int step, required int total, VoidCallback? onBack })` — 높이 64, 가운데 알약 제목, 오른쪽 `2 / 3`, 아래 4px 진행 막대
  - `CoraBottomNav({ required List<CoraNavItem> items, required int currentIndex, required ValueChanged<int> onTap })` — 높이 64, 모서리 32, 좌우 16·아래 20 띄움, 그림자 `0 12px 32px rgba(23,24,28,0.12)`, 꺼진 항목 색 `#8B9099`. `CoraNavItem({ required IconData icon, required String label })`
  - `CoraSegmentedTabs({ required List<String> labels, required int selected, required ValueChanged<int> onChanged })` — 높이 38, 알약
  - `CoraComingSoonPage({ required String title })` — 본문 `준비 중이에요.`
  - `CoraInfoTile({ required String label, required String? value })` — 모서리 18, `surface` 배경, 값이 없으면 `아직 없어요`
  - `CoraSecondaryButton({ required String label, required VoidCallback? onPressed })` — 높이 58, 알약, `surface` 배경
  - `CoraListRow({ String? photoUrl, required String title, String? subtitle, String? actionLabel, bool actionHighlighted, VoidCallback? onAction, VoidCallback? onTap })` — 지름 46 사진(없으면 제목 첫 글자), 버튼 높이 38
  - `CoraNetworkPhoto({ required String? url, BoxFit fit })` — 불러오는 동안과 실패 시 `surfaceMuted` 배경
  - 라우트: `/store/onboarding/links`, `/store/onboarding/page`, `/store/onboarding/edit`, `/store/onboarding/drafts`, `/store/onboarding/terms`, `/store`(홈), `/store/page`, `/store/drafts`, `/store/offers/new/:creatorId`, `/store/coming-soon/:title`, `/creator/profile/setup`, `/creator`(공개된 가게 목록), `/creator/stores/:id`, `/creator/offers`
  - 역할별 진입 규칙(리다이렉트): `store` 역할 — 가게 없음 → `/store/onboarding/links`; `DRAFT` → `onboardingStep`이 `PAGE`면 `/store/onboarding/page`, `DRAFTS`면 `/store/onboarding/drafts`, `TERMS`면 `/store/onboarding/terms`; `PUBLISHED` → `/store`. `creator` 역할 — 프로필 없음 → `/creator/profile/setup`, 있음 → `/creator`. 이 판단에 필요한 조회는 Task 9, 10이 제공하는 provider로 주입받도록 `typedef RoleEntryResolver = Future<String> Function(Ref ref, UserRole role)`과 `roleEntryResolverProvider`를 둔다. 이 작업에서는 `store`와 `creator` 모두 `CoraComingSoonPage`로 가는 기본 구현을 넣고, Task 9, 10이 override한다.

- [ ] **Step 1: 실패하는 테스트 작성** — 위젯마다: 크기, 문구, 누름 동작, 다크 테마 렌더링, 1.3배 글자에서 넘치지 않음. 라우터: `roleEntryResolverProvider`가 돌려준 경로로 이동함.
- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test`
- [ ] **Step 5: Commit** — `feat: 단계 머리글·하단 메뉴 등 공용 위젯과 역할별 진입 흐름 추가`

---

### Task 9: 앱 — 크리에이터 최소 프로필과 사진 올리기

**Files:**
- Create: `app/lib/core/network/photo_uploader.dart`, `app/lib/features/creator_profile/domain/{creator_profile.dart,creator_profile_repository.dart}`, `data/api_creator_profile_repository.dart`, `presentation/viewmodels/creator_profile_setup_view_model.dart`, `presentation/pages/creator_profile_setup_page.dart`
- Modify: `app/lib/main.dart`(override 추가), `app/lib/core/navigation/app_router.dart`
- Test: `app/test/core/network/photo_uploader_test.dart`, `app/test/features/creator_profile/{fake_creator_profile_repository.dart,creator_profile_setup_view_model_test.dart,creator_profile_setup_page_test.dart}`

**Interfaces:**
- Consumes: `cora_api`의 `getMyCreatorProfile`, `upsertMyCreatorProfile`, `createPhotoUpload` (Task 2, 3), 공용 위젯
- Produces:
  - `enum PhotoPurpose { storeCover, creatorPhoto }`
  - `abstract class PhotoUploader { Future<String> upload({ required PhotoPurpose purpose, required Uint8List bytes, required String contentType }); }` — 저장된 `path`를 돌려준다. `photoUploaderProvider`(기본값 `UnimplementedError`). 5MB를 넘으면 서버에 묻지 않고 `PhotoTooLargeException`.
  - `class CreatorProfile { final String displayName; final String? contentFocus; final String? instagramHandle; final String? photoUrl; }`
  - `abstract class CreatorProfileRepository { Future<CreatorProfile?> fetchMine(); Future<CreatorProfile> save({ required String displayName, String? contentFocus, String? instagramHandle, String? photoPath }); }`
  - `creatorProfileRepositoryProvider`, `creatorProfileSetupViewModelProvider`
  - 화면 문구: 제목 `어떤 이름으로\n활동하나요?`, 설명 `가게 사장님에게 이 이름으로 보여요.`, 입력란 `활동 이름`, `주로 만드는 콘텐츠 (선택)` 예시 글자 `예: 맛집 릴스`, `인스타그램 아이디 (선택)`, 맨 위 원형 사진 자리와 `사진 고르기 (선택)`, 버튼 `시작하기`. 사진이 5MB를 넘으면 `사진이 너무 커요. 5MB 이하로 골라 주세요.` 저장되면 `/creator`로 간다.
  - `roleEntryResolverProvider`의 `creator` 분기를 실제로 채운다.

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- 화면에 `활동 지역` 추가: 시·도 고르기(필수, 17개), `구·군 (선택)` 입력란. 시·도를 고르지 않으면 `시작하기`가 꺼진다. `CreatorProfile`과 `save`에 `regionSido`, `regionSigungu` 추가.
- 테스트 추가: `testWidgets('start button stays disabled until a province is chosen', ...)`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('rejects a photo over 5MB before calling the server', ...);
testWidgets('start button is disabled until a display name is typed', ...);
testWidgets('saves and goes to the creator home', ...);
testWidgets('shows an error and keeps the input when saving fails', ...);   // '저장하지 못했어요. 다시 시도해 주세요.'
testWidgets('skips setup when a profile already exists', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 크리에이터 최소 프로필 화면과 사진 올리기 추가`

---

### Task 10: 앱 — 가게 등록 (A2, A3, 편집, A4)

**Files:**
- Create: `app/lib/features/store_onboarding/domain/{my_store.dart,source_link.dart,content_draft.dart,store_repository.dart,content_draft_repository.dart}`, `data/{api_store_repository.dart,api_content_draft_repository.dart}`, `presentation/viewmodels/{store_links_view_model.dart,my_store_view_model.dart,store_edit_view_model.dart,content_drafts_view_model.dart}`, `presentation/pages/{store_links_page.dart,store_page_preview_page.dart,store_edit_page.dart,content_drafts_page.dart}`
- Test: `app/test/features/store_onboarding/`(가짜 저장소 2개, ViewModel 테스트 4개, 화면 테스트 4개)

**Interfaces:**
- Consumes: `cora_api`의 가게·초안 호출 (Task 5), `PhotoUploader` (Task 9), `OfferTerms` (Task 11과 공유하므로 이 작업에서 `app/lib/features/offer_terms/domain/offer_terms.dart`를 먼저 만든다), 공용 위젯 (Task 8)
- Produces:
  - `enum ContentFormat { shorts, reels, cardNews, blog }`, `enum RewardType { voucher, perView, both }`, `class OfferTerms { final ContentFormat format; final RewardType rewardType; final String? voucherName; final int? voucherValue; final int? perViewAmount; final int? perViewCap; }`
  - `class MyStore`(서버의 `MyStoreModel`과 같은 항목, `enum StoreOnboardingStep { page, drafts, terms, done }`), `class SourceLink { final SourceLinkKind kind; final String url; final String? summary; }`
  - `abstract class StoreRepository { Future<MyStore?> fetchMine(); Future<({MyStore store, bool analysisFailed})> analyze(List<SourceLink> links); Future<MyStore> update(StoreEdit edit); Future<MyStore> advance(StoreOnboardingStep step); Future<MyStore> setDefaultTerms(OfferTermsInput input); Future<MyStore> publish(); }`
  - `class OfferTermsInput { final ContentFormat format; final RewardType rewardType; final String? voucherName; final int? voucherValue; }`
  - `abstract class ContentDraftRepository { Future<List<ContentDraft>> fetchMine(); Future<ContentDraft> regenerate(ContentDraftKind kind); }`
  - `myStoreViewModelProvider`(`AsyncNotifier<MyStore?>`) — 다른 feature도 이것으로 내 가게를 읽는다
  - `roleEntryResolverProvider`의 `store` 분기를 실제로 채운다.

화면 문구:
- A2: 머리글 `가게 등록` `1 / 3`. 제목 `가게 링크만 넣으면\n소개 페이지를 만들어 드려요.` 설명 `사진, 메뉴, 영업시간을 링크에서 가져와요. 2개 이상 넣으면 더 정확해요.` 입력란 이름 `네이버 지도`, `캐치테이블`, `인스타그램 · 선택`. 아래 안내 `가져온 정보는 다음 화면에서 고칠 수 있어요. 공개 정보만 사용해요.` 버튼 `가게 페이지 만들기`. 형식이 틀리면 입력란 아래 `{이름} 링크가 맞는지 확인해 주세요.` 분석 중에는 버튼이 `가게 정보를 가져오는 중이에요`로 바뀌고 눌리지 않는다.
- 분석 실패: `정보를 가져오지 못했어요. 직접 입력할 수 있어요.`와 버튼 `직접 입력하기` → 편집 화면.
- A3: 머리글 `가게 등록` `2 / 3`. 사진 위 표지 `링크에서 자동으로 만들었어요`(분석이 실패했으면 표지 없음). 항목 이름 `대표 메뉴`, `영업시간`, `좌석`, `찍기 좋은 시간`. 소개 상자 제목 `크리에이터에게 보여줄 소개`와 `고치기`. 버튼 `정보 고치기`, `이대로 다음`. 가게 이름이 비어 있으면 `이대로 다음`이 꺼지고 그 위에 `가게 이름을 넣어 주세요.`
- 편집: 제목 `가게 정보 고치기`. 입력란 `가게 이름`, `업종`, `동네`, `대표 메뉴`, `영업시간`, `좌석`, `찍기 좋은 시간`, `소개`. 사진 버튼 `사진 바꾸기`. 버튼 `저장`. `고치기`로 들어오면 소개 입력란에 커서가 있다.
- A4: 머리글 `가게 등록` `3 / 3`. 제목 `가게 계정에 올릴\n초안도 만들었어요.` 설명 `가게 페이지 정보로 AI가 썼어요. 그대로 올려도, 고쳐서 올려도 돼요.` 탭 `카드뉴스`, `릴스 대본`, `블로그 글`. 본문 상자에 `복사` 버튼(누르면 `복사했어요.`). 버튼 `다시 만들기`, `저장하고 오퍼 만들기`. 남은 횟수가 0이면 `다시 만들기`가 꺼지고 `오늘은 더 만들 수 없어요.`
- 사장님 홈에서 연 초안 화면(`/store/drafts`)은 같은 화면에서 머리글의 단계 표시와 `저장하고 오퍼 만들기` 버튼만 뺀다.

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- A3과 편집 화면에 `업종 분류`(13개 중 하나 고르기, 표시 이름은 Task 1)와 `지역`(시·도 고르기, `구·군` 입력란) 추가. 시·도가 비어 있으면 `이대로 다음`이 꺼지고 `가게 지역을 골라 주세요.`
- `MyStore`와 `StoreEdit`에 `industry`, `regionSido`, `regionSigungu` 추가.
- 테스트 추가: `testWidgets('blocks next when the store region is empty', ...)`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('create button is disabled until one link is entered', ...);
testWidgets('shows a hint under a link on the wrong host', ...);           // '네이버 지도 링크가 맞는지 확인해 주세요.'
testWidgets('goes to the store page after analysis', ...);
testWidgets('offers manual entry when analysis fails', ...);               // '직접 입력하기' → 편집 화면
testWidgets('shows "아직 없어요" for empty fields', ...);
testWidgets('blocks next when the store name is empty', ...);
testWidgets('saves edits and returns to the preview', ...);
testWidgets('regenerates only the visible draft tab', ...);                // fake.regenerated == [ContentDraftKind.reelsScript]
testWidgets('disables regenerate when none are left today', ...);
testWidgets('copies the body text', ...);
test('resumes at the drafts step for a draft store saved at DRAFTS', ...); // roleEntryResolver → '/store/onboarding/drafts'
test('resumes at the links step when no store exists', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — 단계 사이 이동은 `CoraTransitions.push`. 편집 화면은 `CoraTransitions.sheet`.
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 가게 링크 입력과 가게 페이지 화면 추가`, `feat: AI 콘텐츠 초안 화면 추가`

---

### Task 11: 앱 — 오퍼 조건 3단계 (기본 조건, A5 공용)

**Files:**
- Create: `app/lib/features/offer_terms/presentation/viewmodels/offer_terms_wizard_view_model.dart`, `presentation/widgets/{offer_terms_wizard.dart,format_step.dart,reward_step.dart,confirm_step.dart,voucher_edit_sheet.dart}`, `presentation/offer_terms_text.dart`, `app/lib/features/store_onboarding/presentation/pages/default_terms_page.dart`
- Test: `app/test/features/offer_terms/{offer_terms_text_test.dart,offer_terms_wizard_test.dart}`, `app/test/features/store_onboarding/default_terms_page_test.dart`

**Interfaces:**
- Consumes: `OfferTerms`, `OfferTermsInput`, `StoreRepository.setDefaultTerms`, `publish` (Task 10)
- Produces:
  - `OfferTermsWizard({ required Widget headerTitle, OfferTermsInput? initial, required String storeName, required String confirmTitle, required String confirmDescription, required String submitLabel, required Future<void> Function(OfferTermsInput) onSubmit })` — 기본 조건 화면과 A5(Task 12)가 함께 쓴다
  - `offer_terms_text.dart`(순수 함수): `formatLabel(ContentFormat)`, `formatSubtitle(ContentFormat)`, `contentLine(ContentFormat)`(`릴스 1편`), `rewardTitle(RewardType)`, `rewardSubtitle(OfferTermsInput)`, `rewardSummary(OfferTerms)`, `rewardHeadline(OfferTerms)`(`2인 식사권 + 조회수당`), `won(int)`(`40000` → `4만 원`, `100000` → `10만 원`, `11000` → `11,000원`)

문구:
- 1단계: 제목 `어떤 콘텐츠를\n부탁할까요?` 설명 `크리에이터가 올릴 형식을 하나 골라요.` 카드: `쇼츠`/`유튜브 60초`, `릴스`/`인스타그램 30초`, `카드뉴스`/`인스타그램 3–5장`, `블로그 글`/`사진 포함 후기`. 버튼 `다음`.
- 2단계: 제목 `어떻게\n보상할까요?` 설명 `식사권만, 조회수만, 또는 둘 다 고를 수 있어요.` 카드: `식사권 제공`/`{식사권 이름}, 약 {금액} 상당`, `조회수당 지급`/`조회 1회당 10원, 최대 10만 원`, `식사권 + 조회수`/`식사 후 올리고, 조회수만큼 더 받아요`. 식사권이 들어간 카드가 골라져 있으면 카드 아래에 `식사권 고치기`.
- 식사권 고치기 시트: 제목 `식사권 고치기`, 입력란 `이름`, `금액 (원)`, 버튼 `저장`. 금액은 1,000원에서 1,000,000원 사이.
- 3단계: 항목 `가게`, `콘텐츠`, `보상`. 보상 값 예: `2인 식사권\n+ 조회 1회당 10원, 최대 10만 원`. 안내 `결제한 금액은 Cora가 보관하고, 콘텐츠가 올라온 뒤 크리에이터에게 지급해요.`
- 기본 조건 화면: 머리글 `기본 오퍼 조건`. 3단계 제목 `이 조건으로 가게를\n공개할까요?` 설명 `크리에이터가 가게 페이지에서 이 조건을 봐요. 오퍼를 보낼 때 바꿀 수 있어요.` 버튼 `가게 공개하기`. 처음 고른 값은 `릴스`, `식사권 + 조회수`.

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- 1단계에서 `블로그 글`을 고르면 2단계의 `조회수당 지급`과 `식사권 + 조회수`가 꺼지고 그 아래에 `블로그 글은 조회수를 셀 수 없어요.`가 보인다. 이미 그 둘 중 하나가 골라져 있었으면 `식사권 제공`으로 바뀐다.
- 테스트 추가: `testWidgets('disables per-view rewards for a blog post', ...)`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('formats won amounts the way the canvas does', () {
  expect(won(40000), '4만 원'); expect(won(100000), '10만 원'); expect(won(11000), '11,000원');
});
test('summarises a combined reward on two lines', ...);                    // '2인 식사권\n+ 조회 1회당 10원, 최대 10만 원'
test('uses the custom voucher name', ...);                                 // '커트 이용권 (약 3만 원)'
testWidgets('starts on reels and voucher plus views', ...);
testWidgets('walks three steps and submits the chosen terms', ...);
testWidgets('back on step 1 is dimmed and does nothing', ...);
testWidgets('edits the voucher name and value', ...);
testWidgets('rejects a voucher value below 1000 won', ...);
testWidgets('publishing goes to the store home', ...);                     // default_terms_page_test
testWidgets('stays on the confirm step and shows an error when publishing fails', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 오퍼 조건 3단계와 기본 조건·가게 공개 화면 추가`

---

### Task 12: 앱 — 사장님 홈(A9)과 오퍼 보내기(A5)

**Files:**
- Create: `app/lib/features/store_home/domain/{applicant.dart,sent_offer.dart,store_home_summary.dart,store_home_repository.dart}`, `data/api_store_home_repository.dart`, `presentation/viewmodels/store_home_view_model.dart`, `presentation/pages/store_home_page.dart`, `presentation/store_home_text.dart`, `app/lib/features/offers/domain/offer_view.dart`, `app/lib/features/offers/presentation/pages/send_offer_page.dart`, `presentation/viewmodels/send_offer_view_model.dart`
- Test: `app/test/features/store_home/`, `app/test/features/offers/send_offer_page_test.dart`

**Interfaces:**
- Consumes: `cora_api`의 `listMyStoreApplicants`, `listSentOffers`, `getMyStoreSummary`, `sendOffer`, `cancelOffer` (Task 6, 7), `OfferTermsWizard` (Task 11), `myStoreViewModelProvider` (Task 10)
- Produces:
  - `enum OfferView { waiting, accepted, declined, expired, cancelled }`
  - `class CreatorSummary { final String userId; final String displayName; final String? contentFocus; final String? photoUrl; }`
  - `class Applicant { final String applicationId; final CreatorSummary creator; final DateTime appliedAt; }`
  - `class SentOffer { final String id; final CreatorSummary creator; final OfferTerms terms; final OfferView view; final int? paymentDaysLeft; }`
  - `abstract class StoreHomeRepository { Future<StoreHomeSummary> fetchSummary(); Future<List<Applicant>> fetchApplicants(); Future<List<SentOffer>> fetchSentOffers(); Future<void> sendOffer(String creatorId, OfferTermsInput terms); Future<void> cancelOffer(String offerId); }`
  - `store_home_text.dart`(순수 함수): `appliedAgo(DateTime appliedAt, DateTime now)` → `오늘 지원`, `어제 지원`, `N일 전 지원`; `applicantMeta(Applicant, DateTime now)` → `맛집 릴스, 오늘 지원`(콘텐츠가 없으면 `오늘 지원`만); `sentOfferMeta(SentOffer)` → `답을 기다려요`, `수락함, 결제를 기다려요 · 3일 남음`, `거절함`, `기한이 지났어요`, `취소했어요`; `sentOfferAction(SentOffer)` → `결제하기`(수락), `다시 찾기`(거절), 그 외 없음

화면:
- 머리: 가게 사진, `사장님 홈`, 가게 이름, 오른쪽 `가게 페이지` → `/store/page`(A3 화면을 단계 머리글 없이, 버튼은 `정보 고치기` 하나).
- 숫자 세 칸: `새 지원`, `보낸 오퍼`, `진행 중`.
- 바로가기: `릴스로 찾기`, `리스트 검색`, `빠른 입찰` → `/store/coming-soon/{이름}`.
- 탭: `지원한 크리에이터 {n}`, `보낸 오퍼 {n}`.
- 지원자 줄: 버튼 `오퍼 보내기`(강조) → `/store/offers/new/:creatorId`.
- 보낸 오퍼 줄: `결제하기`, `다시 찾기`는 `/store/coming-soon/...`으로. `waiting`이나 `accepted` 줄을 누르면 아래에서 시트가 올라온다: 조건 요약과 `오퍼 취소` 버튼. 누르면 확인 문구 `이 오퍼를 취소할까요?` / `취소하기` / `그대로 두기`.
- 빈 목록: `아직 지원한 크리에이터가 없어요. 가게가 공개되면 지원이 도착해요.` / `아직 보낸 오퍼가 없어요.`
- 아래로 당기면 숫자와 두 목록을 함께 새로 고친다.
- 하단 메뉴: `홈`, `찾기`(준비 중), `대화`(준비 중), `오퍼`(보낸 오퍼 탭을 연다), `AI 글`(`/store/drafts`).
- A5: 머리글에 크리에이터 사진과 `{활동 이름}에게 오퍼`. `OfferTermsWizard`에 가게의 기본 조건을 처음 값으로 준다. 3단계 제목 `이 오퍼를\n보낼까요?` 설명 `상대가 수락하면 그때 결제해요.` 버튼 `오퍼 보내기`. 성공하면 `/store`의 보낸 오퍼 탭으로 가고 `오퍼를 보냈어요.`를 잠깐 보여 준다. 409면 `이미 보낸 오퍼가 있어요.`

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- 머리의 가게 사진을 누르면 `/store/me`(`내 가게`)가 열린다: `가게 페이지`(→ `/store/page`), `보관함`(준비 중), `설정`(준비 중), `로그아웃`. `가게 페이지` 링크는 그대로 둔다.
- 보낸 오퍼 목록에 미가입 계정 연락을 합치는 것은 8번 계획에서 한다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('describes when a creator applied', ...);                             // 오늘 / 어제 / 3일 전
test('describes each sent offer state', ...);                              // 다섯 상태의 문구와 버튼
testWidgets('shows the three counts', ...);
testWidgets('shows the empty message on each tab', ...);
testWidgets('opens send offer for an applicant', ...);
testWidgets('send offer starts from the store default terms', ...);
testWidgets('returns to the sent tab with a confirmation after sending', ...);
testWidgets('shows a message when an open offer already exists', ...);
testWidgets('cancels a waiting offer after confirmation', ...);
testWidgets('refreshes counts and lists on pull', ...);
testWidgets('offer tab in the bottom nav opens the sent list', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 사장님 홈 추가`, `feat: 오퍼 보내기 화면 추가`

---

### Task 13: 앱 — 크리에이터의 가게 목록, 가게 상세(D2), 받은 오퍼(A6)

**Files:**
- Create: `app/lib/features/store_browse/domain/{store_summary.dart,store_detail.dart,store_browse_repository.dart}`, `data/api_store_browse_repository.dart`, `presentation/viewmodels/{store_list_view_model.dart,store_detail_view_model.dart}`, `presentation/pages/{store_list_page.dart,store_detail_page.dart}`, `app/lib/features/offers/domain/{received_offer.dart,received_offers_repository.dart}`, `data/api_received_offers_repository.dart`, `presentation/viewmodels/received_offers_view_model.dart`, `presentation/pages/received_offers_page.dart`
- Test: `app/test/features/store_browse/`, `app/test/features/offers/received_offers_*_test.dart`

**Interfaces:**
- Consumes: `cora_api`의 `listPublishedStores`, `getPublishedStore`, `applyToStore`, `cancelMyApplication`, `listReceivedOffers`, `acceptOffer`, `declineOffer`, `undoDeclineOffer` (Task 5, 6, 7), `offer_terms_text.dart` (Task 11)
- Produces:
  - `enum MyApplicationStatus { none, applied, offered }`
  - `abstract class StoreBrowseRepository { Future<List<StoreSummary>> fetchPublished(); Future<StoreDetail> fetchDetail(String storeId); Future<void> apply(String storeId); Future<void> cancelApplication(String storeId); }`
  - `class ReceivedOffer { final String id; final StoreSummary store; final String? storeIntro; final String? bestShootingTime; final OfferTerms terms; final OfferView view; final DateTime receivedAt; final bool canUndoDecline; }`
  - `abstract class ReceivedOffersRepository { Future<List<ReceivedOffer>> fetchNew(); Future<List<ReceivedOffer>> fetchActive(); Future<void> accept(String id); Future<void> decline(String id); Future<void> undoDecline(String id); }`

화면:
- 크리에이터 홈(`/creator`): 제목 `공개된 가게`. 가게마다 사진, 이름, `{업종}, {동네}`, 보상 한 줄(`rewardHeadline`). 누르면 상세로, 가게 사진은 `Hero` 태그 `'store:<id>'`로 이어진다. 빈 목록 `아직 공개된 가게가 없어요.` 하단 메뉴: `발견`(이 화면), `관심`(준비 중), `대화`(준비 중), `협업`(`/creator/offers`), `프로필`(준비 중).
- D2: 사진 위 `소상공인` 표지, `{업종}, {동네}`, 가게 이름. 제목 `{형식} 1편을 만들어 줄\n크리에이터를 찾아요`. 항목 `보상`, `찍기 좋은 시간`, `지원 조건` 값 `팔로워 무관`. 소개 글. 버튼 `가게 정보`(준비 중), `지원하기`. 지원 후 `지원했어요. 사장님이 고르면 오퍼가 도착해요.`와 `취소`. `offered` 상태면 `오퍼가 도착했어요.`와 `오퍼 보기` → `/creator/offers`.
- A6: 머리 `받은 오퍼`, 탭 `새 오퍼 {n}` / `진행 중`. 카드: 표지 `소상공인 · {오늘 도착 | 어제 도착 | N일 전 도착}`, `{가게 이름}, {동네}`, `{형식} 1편을\n부탁했어요`, 보상 한 줄, 설명 `{보상 요약}. {가게 소개}`, 꼬리표 `#팔로워무관`, 그리고 찍기 좋은 시간이 있으면 `#{찍기 좋은 시간}`(빈칸 제거). 버튼 `거절`, `수락하기`.
- 거절 후: `거절했어요.` / `가게에는 정중한 거절 알림만 가요. 다음 오퍼를 보여드릴게요.` / `되돌리기`. 30초가 지나거나 `다음 오퍼 보기`를 누르면 다음 카드로 넘어간다. 30초는 화면의 타이머로 세고 `Duration`을 주입받아 테스트에서 줄인다.
- 수락 후: `수락했어요.` / `사장님이 결제하면 알려드릴게요.` / 버튼 `확인` → 진행 중 탭.
- 진행 중 탭: 가게 줄과 `결제를 기다리고 있어요`. 빈 목록 `아직 진행 중인 협업이 없어요.` 새 오퍼가 없으면 `새 오퍼가 없어요. 가게에 지원하면 오퍼가 도착해요.`
- 수락·거절이 409면 `이미 처리된 오퍼예요.`를 보여 주고 목록을 새로 고친다.

**공통 모델 추가** (`specs/2026-11-11-collaboration-common-model.md` 3·4·2장):
- 가게 목록과 상세에서, 가게의 시·도가 내 활동 지역과 다르면 사진 위에 `{시·도}` 표지를 붙인다.
- 테스트 추가: `testWidgets('marks a store in another province', ...)`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('lists published stores with their reward headline', ...);
testWidgets('applies and shows the applied state', ...);
testWidgets('cancels an application', ...);
testWidgets('points to the offer inbox once offered', ...);
testWidgets('shows one offer card at a time in arrival order', ...);
testWidgets('declines, then restores the card on undo', ...);
testWidgets('moves to the next offer when the undo window passes', ...);    // 주입한 Duration 경과
testWidgets('accepting moves the offer to the active tab', ...);
testWidgets('shows a message when the offer was already handled', ...);
testWidgets('shows the empty message on each tab', ...);
testWidgets('store photo is a Hero from list to detail', ...);              // find.byType(Hero) 태그 'store:1'
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 공개된 가게 목록과 가게 상세, 지원 추가`, `feat: 받은 오퍼 화면 추가`

---

### Task 14: 전체 흐름 확인

**Files:** 없음 (확인만. 고칠 것이 나오면 해당 작업의 파일을 고치고 `fix:` 커밋)

- [ ] **Step 1: 자동 확인**

Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
Run: `cd app && flutter analyze && flutter test`
Run: `./scripts/gen-api.sh && git status --short` — Expected: 변경 없음

- [ ] **Step 2: 두 계정으로 수동 확인** (iOS와 Android 각각, 개발용 계정 A는 가게, B는 크리에이터)

1. A: 링크 입력 → 가게 페이지에 `한그릇 라멘` → 소개 고치기 → 초안 세 탭 → `다시 만들기` → 기본 조건 → `가게 공개하기` → 사장님 홈.
2. A: 등록 2단계에서 앱을 껐다 켜면 2단계로 돌아온다(새 계정으로 확인).
3. A: 링크에 `fail`을 넣으면 `직접 입력하기`로 이어진다(새 계정으로 확인).
4. B: 프로필 만들기 → 공개된 가게에 `한그릇 라멘` → 상세 → `지원하기`.
5. A: 홈을 당겨 새로 고침 → `새 지원 1` → `오퍼 보내기` → 식사권 이름을 바꿔 보내기 → `보낸 오퍼` 탭에 `답을 기다려요`.
6. B: `협업` 탭 → 오퍼 카드 → `거절` → `되돌리기` → `수락하기`.
7. A: `수락함, 결제를 기다려요 · 3일 남음` → 줄을 눌러 `오퍼 취소`.
8. B: 가게 상세로 가면 다시 `지원하기`가 보인다.
9. 다크 모드와 글자 크기 1.3배에서 1~6을 훑어본다.
10. 캔버스의 A2, A3, A4, A5, A6, A9, D2와 나란히 놓고 비교한다.

- [ ] **Step 3: 서버 로그 확인** — 알림 로그에 `...님이 지원했어요.`, `...에서 오퍼가 왔어요.`, `...님이 오퍼를 수락했어요.`가 남아 있다.

---

## 완료 기준

- Task 14의 자동 확인 통과, 수동 확인 10개가 iOS와 Android에서 통과
- 설계 문서 6장의 확인 항목 중 소유자가 답한 것이 반영돼 있음

## 설계 문서에서 이 계획이 구체화한 것

- 등록 단계를 서버의 `onboardingStep`으로 저장해 이어 하기를 구현한다.
- 가게 주소 검사에 쓰는 호스트 목록을 정했다(Task 5).
- 초안 다시 만들기 제한은 종류별 하루 10번, 한국 시간 기준이다.
- 가게 상세의 `가게 정보` 버튼은 준비 중 화면으로 간다.
- 받은 오퍼 카드의 꼬리표는 `#팔로워무관`과 `#{찍기 좋은 시간}`이다.
