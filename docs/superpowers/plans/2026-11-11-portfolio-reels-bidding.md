# 포트폴리오·릴스 탐색·인스타그램 가져오기·입찰 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

**Goal:** 크리에이터가 콘텐츠를 직접 올리거나 인스타그램에서 가져와 포트폴리오를 만들고, 사장님과 브랜드가 그 콘텐츠를 릴스처럼 넘겨 보며 좋아요를 누르고 프로필(B5)에서 오퍼나 관심을 보내고, 사장님이 주간 예산 안에서 여러 크리에이터에게 빠르게 입찰하고 결과를 보는 데까지를 만든다.

**Architecture:** 서버에 `portfolio`(콘텐츠, 좋아요, 공개 프로필), `feed`(릴스 순서와 본 기록), `reports`(콘텐츠 신고), `bids`(예산, 후보, 결과) 모듈을 더하고, 3번의 `instagram` 모듈에 게시물 가져오기와 팔로워 갱신을, 2번의 `offers`에 입찰 종류와 거절 사유를 더한다. 입찰은 새 개념이 아니라 `kind = BID`인 오퍼다. 피드 순서, 주 시작일, 예상 조회수는 `Clock`을 받는 순수 함수가 계산한다. 영상 파일은 공개 버킷에 원본으로 두고, 크기 줄이기와 첫 화면 그림은 앱이 올리기 전에 만든다. 앱은 feature 다섯 개를 더하고 4번의 임시 크리에이터 상세를 B5로 바꾼다.

**Tech Stack:** 앞 계획들과 같다. 서버 패키지 추가 없음. 앱의 영상 재생·미리 불러오기, 영상 인코딩·첫 화면 그림 추출, 사진첩 최근 미디어 읽기 패키지는 실행자가 고른다(요구 동작은 Task 9, 11에 적었다). 고른 패키지는 domain의 추상 포트(`MediaPicker`, `MediaPreparer`, `ReelPlayerFactory`) 뒤에만 둔다.

**Spec:** `docs/superpowers/specs/2026-11-11-portfolio-reels-bidding-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md` (2, 3, 4, 5, 8, 14, 15, 16, 19장) · 상위: `docs/superpowers/specs/2026-11-11-tech-stack-design.md`

**선행 조건:** 공통 기반, 2번, 3번, 4번 계획이 끝나 있어야 한다. 이 계획은 2번의 `offers`·`offer-rules.ts`·`OfferTermsModel`·`buildTerms`·`StoragePort`·`UploadsService`·`CreatorsService`·`StoresService`·`PhotoUploader`·`CoraBottomNav`·`CoraSegmentedTabs`·사장님 홈·받은 오퍼 화면·`/store/coming-soon/:title`, 3번의 `collaborations`·`settlements`·`PaymentsService`(견적)·`FEE_RATE_BID`·`InstagramPort`·`instagram_connections`·`InstagramService`·`JobScheduler`·`OperatorAlertPort`·운영 명령 CLI·`ops_audit_logs`, 4번의 `VisibilityService`·`creator_principles`·`CreatorCardModel`·`swipe_decisions`의 콘텐츠 사본·`SwipeDeck`·브랜드 발견 화면·`like_note_sheet.dart`·`creator_card_detail_page.dart`·모션 갤러리를 그대로 쓴다. 5번(대화·계약)과 6번(제작·보관함) 계획은 함께 진행 중이다. 이 계획은 그것들에 기대지 않되 두 가지만 맞춘다: (1) 5번 계획이 `reports` 테이블을 이미 만들었으면 그 테이블의 대상 종류에 `PORTFOLIO_ITEM`을 더하고(대상 종류는 `USER`, `CONVERSATION`, `PORTFOLIO_ITEM`), 없으면 Task 1이 세 종류를 모두 가진 `reports`를 만든다. 5번이 나중에 오면 이 테이블을 쓴다. (2) 6번 계획의 보관함 라우트가 있으면 B2의 `보관함`을 거기로 잇고, 없으면 준비 중 화면으로 둔다.

## Global Constraints

앞 계획들의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것:

- 콘텐츠 한도: 영상 `60`초 이하·`104857600`바이트(100MB) 이하, 사진 `10485760`바이트(10MB) 이하, 첫 화면 그림 JPEG `2097152`바이트(2MB) 이하, 포트폴리오 `30`개(지우지 않은 것 기준), 한 줄 설명 `1~40`자, 분야 `1~3`개(일반 업종 9개 중), 소개 글 `0~100`자.
- 허용 형식: 영상 `video/mp4`(앱이 항상 MP4로 다시 인코딩한다), 사진 `image/jpeg`·`image/png`·`image/heic`, 첫 화면 그림 `image/jpeg`.
- 앱의 올리기 전 처리: 영상은 세로 영상이면 높이, 가로 영상이면 긴 변을 `1280` 이하로 줄여 H.264/AAC MP4로 다시 인코딩하고, 0초 지점의 프레임으로 첫 화면 그림(JPEG 품질 `80`)을 만든다. 사진은 긴 변 `2048` 이하, JPEG 품질 `85`로 다시 인코딩한다. 인스타그램에서 가져온 파일은 서버가 원본 그대로 복사한다.
- 저장소: 공개 버킷 `portfolio`, 경로 `portfolio/<userId>/<uuid>.<ext>`. 파일 주소는 항상 `StoragePort.publicUrl`로 만든다.
- 좋아요: `STORE`·`BRAND` 역할만 누른다. 콘텐츠별 좋아요 수는 올린 크리에이터에게만 내려 준다. 맡기는 쪽의 응답에는 콘텐츠별 수가 없고 B5의 합계(`totalLikes`)만 있다. 누가 눌렀는지는 어떤 응답에도 없다.
- 릴스 피드: 한 번에 `10`개, "최근 좋아요"는 `30`일, "새 콘텐츠"는 올린 지 `7`일 미만, 새 콘텐츠는 `5`장마다 `1`장 섞음, 다음 `2`개 미리 불러오기, 동시에 살아 있는 플레이어 최대 `4`개, 화면에 `1`초 이상 머문 콘텐츠를 본 것으로 기록.
- 신고: 한 사람이 한 대상에 한 번, 서로 다른 `3`명이 신고하면 숨김.
- 입찰: 금액 `30000`·`50000`·`100000`원 중 하나, 응답 기한 `2`일, 결제 기한은 일반 오퍼와 같은 `3`일, 주간 예산의 빠른 선택 `100000`·`300000`·`500000`원, 직접 입력 `30000~10000000`원 `10000`원 단위, 주의 시작 한국 시간 월요일 `00:00`, 예상 조회수 평균의 `±25%`, 팔로워 기준 추정 `0.4~0.6`배.
- 인스타그램: 한 번에 가져오는 게시물 최대 `10`개, 팔로워 수 갱신 매일 한국 시간 `04:00`.
- 맡기는 쪽에게 크리에이터를 보여 주는 모든 조회(피드, B5, 좋아요, 신고, 입찰 후보, 입찰 보내기)는 `VisibilityService`를 거친다. 공통 규칙 5장의 "추천에서 빼는 상대"는 릴스 피드와 입찰 후보에 적용한다.
- 작업 브랜치를 만들지 않고 `main`에 바로 커밋한다. 커밋마다 테스트가 통과한 상태여야 한다.

## Review Focus

1. **같은 가게의 두 입찰이 거의 동시에 들어와 합이 예산을 넘음** → 하나만 저장되고 다른 하나는 409 `남은 예산이 부족해요.` (Task 8)
2. **다른 크리에이터의 파일 경로나 남의 인스타그램 게시물로 콘텐츠를 만들려 함** → 경로는 403, 게시물은 내 연결의 목록에 없으므로 404. (Task 2, 5)
3. **크리에이터가 피하는 업종의 가게·브랜드가 릴스, B5, 좋아요, 입찰 후보로 그 크리에이터에 닿으려 함** → 피드와 후보에서 빠지고 직접 요청은 404. (Task 3, 4, 8)
4. **한 사람이 같은 콘텐츠를 여러 번 신고하거나 두 사람만 신고함** → 숨지 않는다. 서로 다른 세 번째 사람의 신고에서만 숨고 운영자에게 알린다. (Task 6)
5. **릴스를 빠르게 연달아 넘김** → 다음 두 영상은 이미 준비돼 있고, 플레이어가 네 개를 넘게 살아 있지 않으며, 지나간 플레이어는 해제된다. (Task 11)

---

## 파일 구조

```text
api/src/
├── portfolio/      # 콘텐츠, 좋아요, 내 포트폴리오, 공개 프로필(B5) · portfolio-rules.ts(순수 함수)
├── feed/           # 릴스 피드 · reels-order.ts(순수 함수: 순서, 커서)
├── reports/        # 콘텐츠 신고 (5번의 reports가 있으면 확장)
├── bids/           # 예산, 후보, 보내기, 결과 · bid-rules.ts(순수 함수)
├── instagram/      # (3번) + 게시물 목록, 가져오기, 팔로워 갱신 작업
├── uploads/ offers/ ops/commands/   # (2·3번) + 포트폴리오 업로드, 입찰 종류, 콘텐츠 운영 명령
api/seed/instagram/ # 가짜 게시물 파일 (짧은 mp4 4개, jpg 8개)

app/lib/
├── core/media/     # MediaPicker, MediaPreparer, PortfolioFileUploader 포트
└── features/{portfolio(B2·B6), instagram_import(B3), reels(B1), creator_public_profile(B5), reports, bidding(B4·B7)}
```

---

### Task 1: 스키마와 마이그레이션

**Files:**
- Modify: `api/prisma/schema.prisma`
- Create: 마이그레이션, `api/scripts/setup-supabase.ts`에 추가(포트폴리오용 공개 버킷, 파일 한도 100MiB. 이름은 이 작업의 Interfaces를 따른다)
- Test: `api/test/db/portfolio-schema.db-spec.ts`

**Interfaces:**
- Produces:
  - enum `PortfolioItemKind { VIDEO, PHOTO }`, `PortfolioSource { DIRECT, INSTAGRAM }`, `OfferKind { STANDARD, BID }`, `BidDeclineReason { SCHEDULE, AMOUNT, FIELD, NONE }`, `ReportTargetKind { USER, CONVERSATION, PORTFOLIO_ITEM }`, `ReportReason { SPAM, ABUSIVE, FRAUD, COPYRIGHT, INAPPROPRIATE_CONTENT, OTHER }`, `ReportStatus { OPEN, RESOLVED }`
  - `PortfolioItem` → `portfolio_items`: `id`, `creatorId`(→ `users`), `kind`, `mediaPath`, `posterPath?`(사진은 null), `durationSec?`(영상만), `sizeBytes`, `description`, `fields: IndustryCategory[]`, `source`, `sourcePostId?`, `likeCount: Int @default(0)`, `hiddenAt?`. 인덱스 `(creator_id, deleted_at)`. 부분 유니크 `(creator_id, source_post_id) WHERE source_post_id IS NOT NULL AND deleted_at IS NULL`.
  - `ItemLike` → `item_likes`: `itemId`, `userId`, `likedAt`. 유일 제약 `(itemId, userId)`. 취소는 `deletedAt`을 채우고 다시 누르면 비우고 `likedAt`을 새로 쓴다.
  - `FeedView` → `feed_views`: `viewerId`, `itemId`, `cycle: Int`, `viewedAt`. 유일 제약 `(viewerId, itemId, cycle)`. `FeedState` → `feed_states`: `viewerId`(unique), `cycle: Int @default(0)`
  - `BidBudget` → `bid_budgets`: `storeId`, `weekStart @db.Date`, `amount: Int`. 유일 제약 `(storeId, weekStart)`. `BidPass` → `bid_passes`: `storeId`, `creatorId`, `weekStart @db.Date`. 유일 제약 `(storeId, creatorId, weekStart)`.
  - `Report` → `reports`: `reporterId`, `targetKind`, `targetId`, `reason`, `note?`(200자), `status @default(OPEN)`, `resolvedAt?`, `resolvedBy?`. 유일 제약 `(reporterId, targetKind, targetId)`. 5번이 먼저 만들었으면 없는 enum 값과 칸만 더한다.
  - `offers`에 `kind OfferKind @default(STANDARD)`, `bidAmount Int?`, `declineReason BidDeclineReason?` 추가. 인덱스 `(store_id, kind, created_at)`. `creator_profiles`에 `bio String?` 추가.
  - 버킷 SQL: `portfolio` 버킷, `public = true`, `file_size_limit = 104857600`, `allowed_mime_types = {video/mp4,image/jpeg,image/png,image/heic}`. 운영용 Supabase 프로젝트의 전역 업로드 한도도 100MB 이상으로 올려야 한다(README에 한 줄).

- [ ] **Step 1: 실패하는 테스트 작성** (`portfolio-schema.db-spec.ts`)

```ts
it('rejects importing the same instagram post twice for one creator', ...);          // 두 번째 insert가 throw
it('allows re-importing a post after the first copy was deleted', ...);              // deleted_at 채운 뒤 insert 성공
it('keeps one like row per user and item', ...);
it('keeps one report per reporter and target', ...);
it('defaults offers to the STANDARD kind', ...);
```

기존 `rls.db-spec.ts`가 새 테이블 7개(`reports`를 5번이 만들었으면 6개)에서도 통과해야 한다.

- [ ] **Step 2~4: 실패 확인 → 스키마, 마이그레이션(RLS 포함), 버킷 SQL → 통과 확인** — Run: `cd api && yarn setup:supabase && yarn prisma migrate dev && yarn check:rls && yarn test:db`
- [ ] **Step 5: Commit** — `feat: 포트폴리오·좋아요·피드·입찰 예산·신고 스키마 추가`

---

### Task 2: 포트폴리오 업로드와 콘텐츠 API

**Files:**
- Create: `api/src/portfolio/{portfolio.module.ts,portfolio.controller.ts,portfolio.service.ts,portfolio.repository.ts,portfolio-rules.ts,dto/*.ts}`
- Modify: `api/src/integrations/storage/storage.port.ts`, `supabase-storage.adapter.ts`, `api/test/support/fake-storage.port.ts`, `api/src/uploads/{uploads.controller.ts,uploads.service.ts,dto/create-portfolio-upload.dto.ts}`, `api/src/creators/{creators.controller.ts,creators.service.ts}`
- Test: `api/src/portfolio/portfolio-rules.spec.ts`, `api/test/uploads.e2e-spec.ts`(추가), `api/test/portfolio.e2e-spec.ts`

**Interfaces:**
- Consumes: `StoragePort`, `UploadsService.assertOwnedPath` (2번 Task 2), `CreatorsService.requireProfile` (2번 Task 3), `InstagramService.getConnection` (3번 Task 5), `Clock`
- Produces:
  - `StoragePort`에 선택 인자 `bucket: StorageBucket = 'photos'`를 모든 메서드 끝에 더하고(`type StorageBucket = 'photos' | 'portfolio'`), 새 메서드 `sizeOf(path, bucket?): Promise<number | null>`(없으면 null), `remove(paths: string[], bucket?): Promise<void>`. 기존 호출은 그대로 동작한다.
  - `POST /uploads/portfolio` 본문 `{ purpose: 'PORTFOLIO_VIDEO' | 'PORTFOLIO_PHOTO' | 'PORTFOLIO_POSTER'; contentType; sizeBytes }` → 201 `{ uploadUrl; path }`. `CREATOR` 역할만. 형식과 크기는 Global Constraints. `operationId: createPortfolioUpload`
  - `portfolio-rules.ts`: 상수 `PORTFOLIO_MAX_ITEMS = 30`, `VIDEO_MAX_SECONDS = 60`, `VIDEO_MAX_BYTES`, `PHOTO_MAX_BYTES`, `POSTER_MAX_BYTES`, `DESCRIPTION_MAX = 40`, `BIO_MAX = 100`; `assertItemShape(input): void`(영상은 `posterPath`와 `durationSec 1~60` 필수, 사진은 둘 다 없어야 함, 분야는 일반 업종 1~3개 중복 없음 — 어기면 `AppError('VALIDATION_FAILED')`); `pickCoverItem(items: { id; likeCount; createdAt; hiddenAt; deletedAt }[]): string | null`(숨기지도 지우지도 않은 것 중 좋아요 많은 순, 같으면 최근 순)
  - `MyPortfolioItemModel { id; kind; mediaUrl; posterUrl: string | null; durationSec: number | null; description; fields: IndustryCategory[]; source; likeCount; underReview: boolean; createdAt }` — `posterUrl`은 사진이면 `mediaUrl`과 같다
  - `POST /portfolio-items` 본문 `{ kind; mediaPath; posterPath?; durationSec?; description; fields }` → 201 `MyPortfolioItemModel`. 경로 소유 확인(403), `sizeOf`로 파일이 실제로 있고 한도 안인지 확인(없으면 400 `파일을 찾을 수 없어요.`, 넘으면 400), 30개 확인은 그 크리에이터의 `creator_profiles` 행을 `FOR UPDATE`로 잡은 트랜잭션 안에서(넘으면 409 `포트폴리오는 30개까지예요.`). `operationId: createPortfolioItem`
  - `PATCH /portfolio-items/:id` 본문 `{ description?; fields? }` → 200. `DELETE /portfolio-items/:id` → 204(`deletedAt` 채우고 `StoragePort.remove`로 파일을 지운다). 남의 것은 404. `operationId: updatePortfolioItem`, `deletePortfolioItem`. `GET /creators/me/portfolio` → 200 `MyPortfolioModel { displayName; photoUrl; instagram: { handle; followers: number | null } | null; bio: string | null; itemCount; totalLikes; completedCollaborations; items: MyPortfolioItemModel[] }` — `items`는 좋아요 많은 순, 같으면 최근 순. `totalLikes`는 지우지 않은 콘텐츠의 `likeCount` 합. `completedCollaborations`는 이 크리에이터의 `SETTLED` 협업 수(두 종류 모두). `operationId: getMyPortfolio`
  - `PUT /creators/me/bio` 본문 `{ bio: string(0~100, 앞뒤 공백 제거, 빈 글은 null) }` → 200 `{ bio: string | null }`. `operationId: updateMyBio`
  - `PortfolioService`를 export: `coverFor(creatorIds: string[]): Promise<Map<string, CoverItem>>`(`CoverItem { itemId; kind; description; mediaPath; posterPath }`), `publicItems(creatorId, viewerId)`, `totalLikes(creatorId)`, `hasVisibleItems(creatorIds): Promise<Set<string>>`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('requires a poster and a duration for a video', ...);                     // 400
it('rejects a video longer than 60 seconds', ...);                          // durationSec 61 → 400
it('picks the most liked visible item as the cover', ...);                  // 숨김·삭제 제외, 같은 수면 최근 것
it('issues a portfolio video upload url under the caller id', ...);         // path `portfolio/${USER_C}/…mp4`
it('rejects a 100MB + 1 byte video and an 10MB + 1 byte photo', ...);       // 400
it('rejects a media path under another creator id', ...);                   // 403
it('refuses the 31st item', ...);                                           // 409 '포트폴리오는 30개까지예요.'
it('lets only one of two concurrent creates take the 30th slot', ...);      // 29개에서 Promise.all → [201, 409]
it("returns 404 when editing or deleting another creator's item", ...);
it('removes the files and drops the likes from the total on delete', ...);  // totalLikes 감소, FakeStoragePort.removed 2건
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 포트폴리오 업로드 주소와 저장소 버킷 추가`, `feat: 포트폴리오 콘텐츠와 소개 글 API 추가`

---

### Task 3: 좋아요, 공개 프로필(B5), 발견 카드의 첫 장

**Files:**
- Create: `api/src/portfolio/{likes.controller.ts,likes.service.ts,public-profile.controller.ts,public-profile.service.ts,dto/*.ts}`
- Modify: `api/src/visibility/visibility.service.ts`, `api/src/recommendations/recommendations.service.ts`, `api/src/recommendations/dto/creator-card.model.ts`, `api/src/discovery/discovery.service.ts`
- Test: `api/src/portfolio/portfolio-rules.spec.ts`(추가), `api/test/likes.e2e-spec.ts`, `api/test/public-profile.e2e-spec.ts`, `api/test/recommendations.e2e-spec.ts`(추가), `api/test/discovery.e2e-spec.ts`(추가)

**Interfaces:**
- Consumes: `PortfolioService` (Task 2), `VisibilityService` (4번 Task 2), `CampaignsService`, `DiscoveryRepository` (4번), `InstagramService` (3번)
- Produces:
  - `PUT /portfolio-items/:id/like` 본문 `{ liked: boolean }` → 200 `{ liked: boolean }`. `STORE`·`BRAND`만(크리에이터 403). 콘텐츠가 숨겨졌거나 지워졌거나 올린 사람이 나에게 보이지 않으면 404. 한 트랜잭션에서 `item_likes`를 조건부로 바꾸고, 바뀐 행이 있을 때만 `likeCount`를 ±1 한다(같은 값을 두 번 보내도 수가 변하지 않는다). `operationId: setPortfolioItemLike`
  - `VisibilityService.recommendationExclusions(viewer): Promise<Set<string>>` — 공통 규칙 5장 가운데 필터가 아닌 것: 나와 끝나지 않은 협업이 있는 크리에이터, (브랜드면) 진행 중 캠페인에서 내가 넘긴 크리에이터와 그 캠페인에서 `DROPPED`된 크리에이터. 5번 계획의 차단은 `creatorVisibleTo`에 들어가므로 여기서 다루지 않는다.
  - `portfolio-rules.ts`에 추가: `profileTags(p: Principles): string[]` — `faceOk`면 `얼굴출연가능` 아니면 `얼굴출연없음`, `scriptOk`가 false면 `대본낭독없음`, `honestReview`면 `솔직후기`; `feeSentence(band: FeeBand): string` — `희망 제작비는 20만 원대예요.`, `…30만 원대예요.`, `…40만 원대예요.`, `희망 제작비는 50만 원 이상이에요.`
  - `PublicPortfolioItemModel { id; kind; mediaUrl; posterUrl; durationSec; description; fields; likedByMe: boolean }`(`likeCount` 칸이 없다). `GET /creators/:id/profile` → 200 `CreatorPublicProfileModel { creatorId; displayName; photoUrl; instagramHandle: string | null; fieldLabels: string[]; tags: string[]; followers: number | null; totalLikes; completedCollaborations; bio: string | null; feeSentence: string | null; cover: PublicPortfolioItemModel | null; items: PublicPortfolioItemModel[]; viewer: { kind: 'STORE' | 'BRAND'; hasOpenOffer: boolean; hasActiveCampaign: boolean; myDecision: 'LIKE' | 'HOLD' | null } }` — `STORE`·`BRAND`만, `VisibilityService.creatorVisibleTo`를 통과해야 한다(아니면 404). `instagramHandle`·`followers`는 연결된 계정의 값만 쓴다(본인이 적은 아이디는 쓰지 않는다). `fieldLabels`·`tags`·`feeSentence`는 원칙이 없으면 빈 배열과 null. 숨긴 콘텐츠는 `items`·`cover`·`totalLikes` 모두에서 빠진다. `operationId: getCreatorPublicProfile`
  - `CreatorCardModel`에 `cover: { itemId; kind; posterUrl } | null` 추가. `headline`은 `cover`의 설명 → `cardHeadline` → null, `photoUrl`은 `cover`의 첫 화면 그림 → `cardPhotoPath` → 프로필 사진 순으로 채운다(대체 경로는 남긴다). 4번의 `PUT /discovery/decisions`에서 `note`가 있는 `LIKE`의 `contentTitle`·`contentPhotoPath` 사본도 같은 순서(대표 콘텐츠 → `cardHeadline`/`cardPhotoPath`)로 만든다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('builds profile tags and the fee sentence from principles', ...);          // ['얼굴출연가능','솔직후기'], '희망 제작비는 30만 원대예요.'
it('likes and unlikes an item and keeps the count right on repeats', ...);    // true,true → likeCount 1; false → 0
it('returns 404 when a store whose industry the creator avoids likes an item', ...);
it('counts one like when two requests with liked=true race', ...);            // Promise.all → likeCount 1
it('shows followers from the connected account only', ...);                   // 본인이 적은 handle만 있으면 null
it('returns 404 for the profile of a creator who avoids my industry', ...);
it('returns 404 to a brand for a creator without principles but 200 to a store', ...);
it('never exposes per-item like counts or likers to commissioners', ...);     // 응답 JSON에 'likeCount', 'userId' 없음
it('uses the most liked item as the discovery card cover and falls back to the card fields', ...);
it('copies the cover description and poster into a noted like', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 콘텐츠 좋아요와 크리에이터 공개 프로필 API 추가`, `feat: 발견 카드 첫 장을 대표 콘텐츠로 바꾸기`

---

### Task 4: 릴스 피드 API

**Files:**
- Create: `api/src/feed/{feed.module.ts,feed.controller.ts,feed.service.ts,feed.repository.ts,reels-order.ts,dto/*.ts}`
- Test: `api/src/feed/reels-order.spec.ts`, `api/test/feed.e2e-spec.ts`

**Interfaces:**
- Consumes: `VisibilityService.filterCreators`, `recommendationExclusions` (Task 3), `PortfolioService` (Task 2), `StoresService.requireMyStore`, `BrandsService.requireProfile`, `Clock`
- Produces (`reels-order.ts`, 순수 함수):
  - `type FeedCandidate = { id: string; fields: IndustryCategory[]; recentLikes: number; createdAt: Date }`, `orderReels(items: FeedCandidate[], viewerIndustry: IndustryCategory, now: Date): string[]` — 새 콘텐츠(`createdAt > now − 7일`)를 따로 떼어 최근 순으로 줄 세운다. 나머지를 "분야에 내 업종이 있는 것" → "없는 것"으로 나누고 각각 `recentLikes` 내림차순, 같으면 최근 순, 같으면 `id` 순. 이 목록에서 5개를 낼 때마다 새 콘텐츠를 1개 끼운다. 한쪽이 바닥나면 남은 쪽을 그대로 잇는다.
  - `encodeCursor({ cycle; anchor: Date; offset }): string`, `decodeCursor(s): { cycle; anchor; offset }`(base64url JSON, 틀리면 `AppError('VALIDATION_FAILED')`)
- Produces (API):
  - `ReelItemModel { itemId; kind; mediaUrl; posterUrl; durationSec; description; likedByMe; creator: { creatorId; displayName; photoUrl; followers: number | null } }`
  - `GET /feed/reels?cursor=` → 200 `{ items: ReelItemModel[]; nextCursor: string | null }`. `STORE`(가게 필요, 404)·`BRAND`(브랜드 프로필 필요, 409)만. 진행 중 캠페인이 없는 브랜드도 볼 수 있다. `operationId: listReels`. 후보: 숨기지도 지우지도 않은 콘텐츠 가운데, 올린 사람이 `filterCreators`를 통과하고 `recommendationExclusions`에 없는 것. 커서가 없으면 지금 시각을 `anchor`로, `feed_states.cycle`을 `cycle`로 쓴다. 이 순환에서 아직 안 본 후보가 없고 후보가 하나라도 있으면 `cycle + 1`로 올리고(조건부 갱신) 전부를 다시 후보로 한다. 순서는 `anchor` 시각을 기준으로 계산한다: `recentLikes`는 `likedAt`이 `(anchor − 30일, anchor]`인 좋아요 수, 안 본 것은 `viewedAt <= anchor`인 그 순환의 기록 기준. 그래서 같은 커서로 이어 읽는 동안 순서가 흔들리지 않는다. `offset`부터 10개를 잘라 주되, 그 사이 숨겨지거나 지워진 것과 보이지 않게 된 크리에이터의 것은 뺀다. 목록 끝이면 `nextCursor = null`(앱은 커서 없이 다시 요청한다).
  - `POST /feed/reels/views` 본문 `{ itemId }` → 204. 지금 순환 번호로 `feed_views`에 넣는다(이미 있으면 무시). 보이지 않는 콘텐츠면 404. `operationId: recordReelView`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
// reels-order.spec.ts — now = 2026-12-02T01:00:00Z
it('puts items in my industry first, each group by recent likes', ...);
it('inserts one item newer than 7 days after every five', ...);               // 위치 5, 11에 새 콘텐츠 (0부터)
it('treats an item exactly 7 days old as not fresh', ...);
it('round-trips a cursor and rejects a garbled one', ...);

// feed.e2e-spec.ts
it('returns ten reels and a cursor, then the next ten without repeats', ...);
it('skips items I have already viewed in this cycle', ...);
it('starts a new cycle once everything has been viewed', ...);              // feed_states.cycle 0 → 1, 전부 다시 나옴
it('keeps the order stable across pages when likes change in between', ...);
it('leaves out a creator I have an unfinished collaboration with', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 릴스 피드 순서 계산 추가`, `feat: 릴스 피드와 본 기록 API 추가`

---

### Task 5: 인스타그램 게시물 가져오기와 팔로워 갱신

**Files:**
- Modify: `api/src/integrations/instagram/{instagram.port.ts,fake-instagram.adapter.ts}`, `api/src/instagram/{instagram.controller.ts,instagram.service.ts,instagram.repository.ts}`, `api/src/jobs/{job-names.ts,job-scheduler.ts}`, `api/test/support/fake-job-scheduler.ts`
- Create: `api/src/instagram/{instagram-import.service.ts,dto/instagram-post.model.ts,dto/import-posts.dto.ts}`, `api/src/instagram/fake-instagram-media.dev.controller.ts`, `api/src/jobs/handlers/instagram-followers-refresh.handler.ts`, `api/seed/instagram/*`
- Test: `api/src/integrations/instagram/fake-instagram.adapter.spec.ts`(추가), `api/src/instagram/instagram-import.service.spec.ts`, `api/test/instagram-import.e2e-spec.ts`, `api/src/jobs/handlers/instagram-followers-refresh.handler.spec.ts`

**Interfaces:**
- Consumes: `InstagramPort`, `instagram_connections`, `seal`/`open` (3번 Task 3, 5), `StoragePort` (Task 2), `PortfolioService`의 30개 검사, `JobScheduler`
- Produces:
  - `InstagramPort`에 추가: `listPosts(token: string): Promise<InstagramPost[]>`, `downloadMedia(token: string, postId: string): Promise<{ bytes: Buffer; contentType: string; poster: { bytes: Buffer; contentType: string } | null }>` — 여러 장짜리는 첫 장만 내려 준다. 타입 `InstagramPost = { id: string; type: 'VIDEO' | 'IMAGE' | 'CAROUSEL'; firstMediaType: 'VIDEO' | 'IMAGE'; thumbnailUrl: string; caption: string | null; durationSec: number | null; sizeBytes: number | null; postedAt: Date }`
  - 가짜 구현: 3번의 `completeConnect`가 돌려주는 `token`은 `fake:<handle>` 형식으로 맞춘다. `listPosts`는 그 아이디로 게시물 12개를 돌려준다: 영상 4개(15·30·45초, 그리고 75초짜리 1개), 사진 6개, 여러 장짜리 2개(첫 장 사진 1, 영상 1). 하나는 `sizeBytes`가 120MB다. 글은 `{handle}의 견본 게시물 {n}\n둘째 줄`. 파일은 `api/seed/instagram/`의 작은 견본. `thumbnailUrl`은 `INSTAGRAM_ADAPTER=fake`일 때만 등록되는 `GET /dev/fake-instagram/media/:file`(`@Public()`) 주소다. 팔로워 2,100.
  - `JobName`에 `'instagram-followers-refresh'` 추가. `JobScheduler`에 `repeatDaily(name: JobName, input: { hourKst: number; jobKey: string }): Promise<void>` 추가(BullMQ 반복 작업, `FakeJobScheduler`는 기록하고 `runDue`로 실행). 서버 시작 때 `repeatDaily('instagram-followers-refresh', { hourKst: 4, jobKey: 'followers-daily' })`. 처리기: `refreshedAt`이 20시간보다 오래된 연결마다 `fetchFollowers` 후 `followers`, `refreshedAt` 갱신. 한 계정이 실패해도 나머지는 계속하고 실패한 것은 값을 그대로 둔다.
  - `InstagramPostModel { postId; kind: 'VIDEO' | 'PHOTO'; thumbnailUrl; durationSec: number | null; captionFirstLine: string | null; blockReason: 'TOO_LONG' | 'TOO_LARGE' | null; alreadyImported: boolean }`
  - `GET /instagram/posts` → 200 `{ handle: string; remaining: number; posts: InstagramPostModel[] }` — `CREATOR`만, 연결이 없으면 409 `인스타그램을 먼저 연동해 주세요.` `remaining` = 30 − 지금 콘텐츠 수. `operationId: listInstagramPosts`
  - `POST /instagram/imports` 본문 `{ postIds: string[](1~10개, 중복 불가, 고른 순서) }` → 201 `{ items: MyPortfolioItemModel[]; skipped: { postId; reason: 'TOO_LONG' | 'TOO_LARGE' | 'ALREADY_IMPORTED' | 'NOT_FOUND' }[] }`. `operationId: importInstagramPosts`. 내 연결의 `listPosts`에 없는 `postId`는 `NOT_FOUND`로 건너뛴다(남의 게시물은 이 길로만 들어올 수 있고 여기서 막힌다). 가져올 수 있는 것의 수가 `remaining`보다 많으면 아무것도 가져오지 않고 409, 메시지 `포트폴리오는 30개까지예요. {remaining}개만 더 가져올 수 있어요.`, `details: { remaining }`. 하나씩 `downloadMedia` → `StoragePort.upload`(버킷 `portfolio`, 영상은 첫 화면 그림도) → 행 생성(`source: INSTAGRAM`, `sourcePostId`, 설명은 글의 첫 줄을 40자로 자른 것, 비어 있으면 `인스타그램 게시물`, 분야는 원칙의 `fields` 앞 3개, 원칙이 없으면 `[OTHER]`). 고른 순서가 격자의 순서가 되도록 `createdAt`을 `now − i밀리초`로 넣는다. 부분 유니크 인덱스 위반은 `ALREADY_IMPORTED`로 건너뛴다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('returns twelve sample posts for the connected handle', ...);
it('downloads only the first slide of a carousel', ...);
it('marks a 75 second video TOO_LONG and a 120MB video TOO_LARGE', ...);
it('marks posts that were already imported', ...);
it('imports in the chosen order and copies files into storage', ...);        // items[0].description '…견본 게시물 3', FakeStoragePort 업로드 수
it('skips a post id that is not in my own account', ...);                    // skipped NOT_FOUND
it('skips a too long video and an already imported post with reasons', ...);
it('refuses an import that would pass 30 items and reports how many fit', ...); // 28개 + 3개 → 409, details.remaining 2
it('refreshes followers once a day and keeps the old value on failure', ...);
it('does not register the fake media route in production mode', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 인스타그램 게시물 가져오기 추가`, `feat: 인스타그램 팔로워 수 하루 한 번 갱신 추가`

---

### Task 6: 콘텐츠 신고와 운영 명령

**Files:**
- Create: `api/src/reports/{reports.module.ts,reports.controller.ts,reports.service.ts,reports.repository.ts,dto/*.ts}`(5번이 만들었으면 Modify), `api/src/ops/commands/{unhide-content.command.ts,delete-content.command.ts,resolve-reports.command.ts}`
- Modify: `api/src/ops/ops.service.ts`, `README.md`
- Test: `api/test/reports.e2e-spec.ts`, `api/src/ops/ops.service.spec.ts`(추가)

**Interfaces:**
- Consumes: `OperatorAlertPort`, 운영 명령 틀과 `ops_audit_logs` (3번 Task 3, 10), `PortfolioService`, `VisibilityService`, `StoragePort.remove`
- Produces:
  - `POST /portfolio-items/:id/reports` 본문 `{ reason: 'COPYRIGHT' | 'INAPPROPRIATE_CONTENT' | 'SPAM' | 'OTHER'; note?: string(200자) }` → 201 `{ reportId }`. `STORE`·`BRAND`만, 보이지 않는 콘텐츠는 404, 같은 사람의 두 번째 신고는 409 `이미 신고한 콘텐츠예요.` `operationId: reportPortfolioItem`
  - 한 트랜잭션에서: 신고 행 삽입 → 그 콘텐츠의 `OPEN` 신고자 수를 센다 → 3 이상이고 `hiddenAt`이 비어 있으면 조건부로 `hiddenAt = now`. 커밋 뒤 `OperatorAlertPort.alert`: 언제나 `[Cora] 신고 접수 · 콘텐츠 {id 앞 8자리}`, 숨겼으면 한 번 더 `[Cora] 콘텐츠 숨김 · {id 앞 8자리}`. 본문에 대상 ID, 사유, 신고 수, 운영 명령 예시를 넣는다.
  - 숨긴 콘텐츠는 피드, B5, 좋아요, 입찰 카드의 대표 콘텐츠, 발견 카드의 첫 장에서 빠진다. 올린 사람의 `GET /creators/me/portfolio`에는 `underReview: true`로 남는다.
  - 운영 명령(모두 `--operator`, `--reason` 필수, `ops_audit_logs`에 한 줄, `detail`에 대상): `yarn ops unhide-content --item <id>` — `hiddenAt`을 비우고 그 콘텐츠의 `OPEN` 신고를 모두 `RESOLVED`로(다음 신고 한 건에 바로 다시 숨지 않게); `yarn ops delete-content --item <id>` — `deletedAt`을 채우고 파일을 지우고 `OPEN` 신고를 `RESOLVED`로; `yarn ops resolve-reports --item <id>` — 숨기지 않은 채 `OPEN` 신고만 `RESOLVED`로. 사용자 이용 정지와 해제 명령은 5번 계획이 만든다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('accepts one report per person and rejects a repeat', ...);              // 201, 409
it('does not hide after two distinct reporters', ...);
it('hides after the third distinct reporter and alerts twice', ...);         // FakeOperatorAlert 기록: 신고 접수 3, 콘텐츠 숨김 1
it('shows the hidden item to its owner as under review', ...);
it('removes a hidden item from the feed and the public profile', ...);
it('unhides content and resolves its open reports with an audit row', ...);
it('deletes content and its files with an audit row', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, README에 명령 세 개 추가, Commit** — 커밋 두 개: `feat: 콘텐츠 신고와 세 명 신고 시 숨김 추가`, `feat: 콘텐츠 숨김 해제·삭제·신고 처리 운영 명령 추가`

---

### Task 7: 입찰 규칙과 오퍼 확장

**Files:**
- Create: `api/src/bids/bid-rules.ts`
- Modify: `api/src/offers/{offer-rules.ts,offers.service.ts,offers.repository.ts,offers.controller.ts,dto/decline-offer.dto.ts,dto/received-offer.model.ts,dto/sent-offer.model.ts}`, `api/src/stores/offer-terms.ts`, `api/src/payments/payments.service.ts`
- Test: `api/src/bids/bid-rules.spec.ts`, `api/src/stores/offer-terms.spec.ts`(추가), `api/test/offers.e2e-spec.ts`(추가), `api/test/payments.e2e-spec.ts`(추가)

**Interfaces:**
- Produces (`bid-rules.ts`, 순수 함수):
  - 상수 `BID_AMOUNTS = [30000, 50000, 100000]`, `BID_RESPONSE_DAYS = 2`, `BUDGET_MIN = 30000`, `BUDGET_MAX = 10000000`, `BUDGET_STEP = 10000`
  - `kstWeekStart(now: Date): string` — 한국 시간 기준 그 주 월요일 `YYYY-MM-DD`. `kstWeekRange(now): { start: Date; end: Date }`(UTC 시각, `end`는 다음 월요일 0시)
  - `expectedViews(input: { settledViews: number[]; followers: number | null }): { min: number; max: number; estimated: boolean } | null` — 끝낸 협업의 최종 조회수가 있으면 평균의 `floor(×0.75)`~`ceil(×1.25)`, `estimated: false`. 없고 팔로워가 있으면 `floor(×0.4)`~`ceil(×0.6)`, `estimated: true`. 둘 다 없으면 null. `isValidBudget(amount: number): boolean`, `isValidBidAmount(amount: number): boolean`
- Produces (`offer-terms.ts`): `buildBidTerms(input: { storeDefaultFormat: ContentFormat; amount: number }): OfferTermsModel` — `rewardType: PER_VIEW`, `perViewAmount: 10`, `perViewCap: amount`, 형식은 가게 기본 형식, `BLOG`면 `REELS`
- Produces (오퍼):
  - `offer-rules.ts`에 `responseDays(kind: OfferKind): number`(일반 7, 입찰 2). 오퍼를 만들 때 `expiresAt = now + responseDays(kind)일`.
  - `POST /offers/:id/decline` 본문 `{ reason?: BidDeclineReason }` — 입찰이면 필수(없으면 400), 일반 오퍼면 넣을 수 없다(400). `declineReason`에 저장하고 되돌리기를 하면 지운다. `ReceivedOfferModel`에 `kind`, `respondDueAt`(= `expiresAt`) 추가. `SentOfferModel`에 `kind`, `bidAmount: number | null`, `declineReason: BidDeclineReason | null` 추가(사유는 `viewForStore`가 `DECLINED`일 때만 채운다. 30초 되돌리기 동안은 null).
  - 3번의 `GET /collaborations/:id/payment-quote`와 결제 생성: 협업의 오퍼가 `BID`면 수수료율 `FEE_RATE_BID`를 쓴다(`payments.feeRate`에 사본). 보관액은 그대로 조건의 `perViewCap`(= 입찰 금액).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('starts the week on Monday 00:00 in Korea', () => {
  expect(kstWeekStart(new Date('2026-12-06T14:59:59Z'))).toBe('2026-11-30');   // 일요일 23:59:59 KST
  expect(kstWeekStart(new Date('2026-12-06T15:00:00Z'))).toBe('2026-12-07');   // 월요일 00:00 KST
});
it('ranges expected views 25 percent around the settled average', ...);       // [9600] → { min: 7200, max: 12000, estimated: false }
it('estimates from followers when nothing was settled', ...);                 // 2100 → { min: 840, max: 1260, estimated: true }
it('returns null with neither history nor followers', ...);
it('accepts only the three bid amounts and budgets in 10000 won steps', ...); // 40000 입찰 거절, 35000 예산 거절, 20000 예산 거절
it('builds bid terms capped at the amount and turns blog into reels', ...);   // BLOG, 50000 → REELS, cap 50000, 단가 10
it('gives a bid two days to answer', ...);                                    // T0+2d-1ms WAITING, T0+2d EXPIRED
it('requires a decline reason for a bid and refuses one for a regular offer', ...); // 400, 400
it('shows the decline reason to the store only after the undo window', ...);  // +29s null, +30s 'SCHEDULE'
it('quotes a bid with the bid fee rate', ...);                                // FEE_RATE_BID=12 → fee 6000 for 50000
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 입찰 규칙 순수 함수 추가`, `feat: 오퍼에 입찰 종류와 거절 사유, 2일 기한 추가`

---

### Task 8: 입찰 API — 예산, 후보, 보내기, 결과

**Files:**
- Create: `api/src/bids/{bids.module.ts,bids.controller.ts,bids.service.ts,bids.repository.ts,dto/*.ts}`
- Test: `api/src/bids/bids.service.spec.ts`, `api/test/bids.e2e-spec.ts`, `api/test/db/bids.repository.db-spec.ts`

**Interfaces:**
- Consumes: `bid-rules.ts`, `buildBidTerms`, `offer-rules.ts` (Task 7), `OffersService`·`OffersRepository`(오퍼 생성은 2번의 경로를 그대로 탄다: 열린 오퍼 부분 유니크, 기한 지난 오퍼 정리, 알림), `StoresService.requireMyStore`, `VisibilityService`, `PortfolioService.coverFor`, `InstagramService`, `settlements`, `Clock`
- Produces:
  - `BidsRepository.committedAmount(storeId, range, now, tx): Promise<number>` — 그 주에 **보낸**(`created_at`이 주 안) `BID` 오퍼 가운데 다음의 `bidAmount` 합: `SENT`이고 `expires_at > now`, 또는 `ACCEPTED`이고 (`payment_due_at > now` 또는 연결된 협업이 `AWAITING_PAYMENT`가 아님 = 결제됨). 거절, 만료, 취소, 결제 기한 만료는 세지 않는다. 결제 뒤의 환급·취소는 예산을 돌려주지 않는다.
  - `BidBudgetModel { weekStart; amount: number | null; used: number; remaining: number | null; sentCount: number }` — `sentCount`는 이번 주에 보낸 입찰 수(상태 무관). `GET /bids/budget` → 200 `BidBudgetModel`. `operationId: getBidBudget`. `PUT /bids/budget` 본문 `{ amount }` → 200 `BidBudgetModel`. 이번 주 행을 만들거나 바꾼다. `used`보다 작으면 409 `이번 주에 이미 쓴 금액보다 적게 정할 수 없어요.` `operationId: setBidBudget`
  - `BidCandidateModel { creatorId; displayName; photoUrl; cover: { itemId; kind; posterUrl; mediaUrl } ; contentLine: string; followers: number | null; expectedViews: { min; max; estimated } | null; otherSido: string | null }` — `contentLine`은 `{대표 콘텐츠 첫 분야 표시 이름} {릴스 | 사진}`(예: `패션 릴스`)
  - `GET /bids/candidates?first=<creatorId>` → 200 `BidCandidateModel[]`(최대 20). `STORE`만, 가게가 `PUBLISHED`여야 한다(409). 후보: 인스타그램 연결이 있고, 보이는 콘텐츠가 1개 이상이고, `VisibilityService`를 통과하고, `recommendationExclusions`에 없고, 이 가게와 열린 오퍼(`SENT`, `ACCEPTED` — 기한 지난 것 제외)가 없고, 이번 주에 넘기지 않은 크리에이터. 순서: 같은 구·군 → 같은 시·도 → 그 밖, 각 묶음 안에서 `totalLikes` 내림차순, 같으면 최근 콘텐츠 순. `first`가 후보이면 맨 앞에 둔다(B7의 `다시 입찰`). `operationId: listBidCandidates`. `POST /bids/passes` 본문 `{ creatorId }` → 204. 이번 주 `bid_passes`에 넣는다(있으면 무시). `operationId: passBidCandidate`
  - `POST /bids` 본문 `{ creatorId; amount }` → 201 `SentOfferModel`. `operationId: placeBid`. 검사 순서: `STORE` 역할(403) → 가게 `PUBLISHED`(409) → `isValidBidAmount`(400) → 이번 주 예산 있음(409 `이번 주 예산을 먼저 정해 주세요.`) → 후보 조건(아니면 404). 한 트랜잭션에서: 이번 주 `bid_budgets` 행을 `SELECT … FOR UPDATE`로 잡는다 → `committedAmount` → `used + amount > budget`이면 409 `남은 예산이 부족해요.`, `details: { reason: 'BUDGET_EXCEEDED', remaining }` → `kind: BID`, `bidAmount`, `buildBidTerms`, `expiresAt = now + 2일`로 오퍼를 만든다. 열린 오퍼 유니크 위반은 409 `이미 보낸 오퍼가 있어요.` 크리에이터 알림: `{가게 이름}에서 빠른 입찰이 왔어요. 2일 안에 답해 주세요.`
  - `BidResultModel { offerId; creator: CreatorSummaryModel; amount; view: OfferView; declineReason: BidDeclineReason | null; paid: boolean; collaborationId: string | null; respondDueAt; sentAt }`. `GET /bids/results` → 200 `{ weekStart; budget: number | null; used; counts: { accepted; waiting; declined }; bids: BidResultModel[] }` — 이번 주에 보낸 입찰, 최근 순. `accepted`는 `ACCEPTED`(결제 포함), `waiting`은 `WAITING`, `declined`는 `DECLINED`. 만료·취소는 목록에만 있고 숫자에는 없다. `operationId: listBidResults`. 예상 조회수의 `settledViews`는 그 크리에이터의 `SETTLED` 협업 가운데 `settlements.finalViews`가 있는 것.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('saves a budget and refuses one below what is already used', ...);       // 409
it('orders candidates by district, province, then total likes', ...);
it('leaves out a creator with an open offer from this store', ...);
it('brings a creator back after the bid was declined or expired in the same week', ...);
it('leaves out a creator I passed this week and brings them back next week', ...);
it('places a bid as a per-view offer capped at the amount with a 2 day deadline', ...);
it('refuses a bid that would pass the weekly budget', ...);                  // 500000 중 470000 사용 → 50000 입찰 409
it('lets only one of two concurrent bids take the last of the budget', ...); // remaining 50000, 서로 다른 크리에이터 두 명 Promise.all → [201, 409]
it('returns the amount to the budget on decline, expiry and cancel', ...);
it('returns the amount when an accepted bid passes its payment deadline unpaid', ...);
it('keeps counting a paid bid after its payment deadline', ...);
it('lists results with counts, reasons and payment state', ...);
it("returns 404 when bidding on a creator who is not a candidate", ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 입찰 주간 예산과 후보 API 추가`, `feat: 입찰 보내기와 결과 API 추가`

---

### Task 9: 앱 — 포트폴리오 탭(B2), 콘텐츠 올리기(B6), 콘텐츠 크게 보기

**Files:**
- Create: `app/lib/core/media/{media_picker.dart,media_preparer.dart,portfolio_file_uploader.dart}`(포트와 예외), `app/lib/core/media/data/*`(패키지 구현), `app/lib/features/portfolio/domain/{portfolio_item.dart,my_portfolio.dart,portfolio_repository.dart,portfolio_text.dart}`, `data/api_portfolio_repository.dart`, `presentation/viewmodels/{my_portfolio_view_model.dart,portfolio_upload_view_model.dart,portfolio_item_view_model.dart}`, `presentation/pages/{my_portfolio_page.dart,portfolio_upload_page.dart,portfolio_item_page.dart}`, `presentation/widgets/{bio_edit_sheet.dart,field_chips.dart}`
- Modify: `app/lib/core/navigation/app_router.dart`, `app/lib/main.dart`, 크리에이터 하단 메뉴(`프로필` → `/creator/profile`)
- Test: `app/test/core/media/`, `app/test/features/portfolio/`

**Interfaces:**
- Consumes: `cora_api`의 `createPortfolioUpload`, `createPortfolioItem`, `updatePortfolioItem`, `deletePortfolioItem`, `getMyPortfolio`, `updateMyBio` (Task 2), 4번의 `/creator/principles`, 3번의 `/creator/instagram`
- Produces:
  - `enum MediaKind { video, photo }`, `class PickedMedia { final String path; final MediaKind kind; final int sizeBytes; final Duration? duration; final Uint8List? thumbnail; }`, `abstract class MediaPicker { Future<List<PickedMedia>> recent({int limit = 30}); Future<PickedMedia?> pickFromGallery(); }` — 사진첩 권한이 없으면 `recent`는 빈 목록
  - `class PreparedMedia { final String filePath; final String contentType; final int sizeBytes; final int? durationSec; final Uint8List? posterJpeg; }`, `abstract class MediaPreparer { Future<PreparedMedia> prepare(PickedMedia m); }` — Global Constraints의 크기 줄이기와 첫 화면 그림을 한다. 원본 길이가 60초를 넘으면 인코딩 전에 `MediaTooLongException`, 결과가 한도를 넘으면 `MediaTooLargeException(limitBytes)`.
  - `enum PortfolioUploadPurpose { video, photo, poster }`, `abstract class PortfolioFileUploader { Future<String> upload({ required PortfolioUploadPurpose purpose, required String filePath, required String contentType, required int sizeBytes, void Function(double)? onProgress }); }` — 파일을 메모리에 다 올리지 않고 스트림으로 보낸다. 저장된 `path`를 돌려준다.
  - `class PortfolioItem`(서버의 `MyPortfolioItemModel`), `class MyPortfolio`(서버의 `MyPortfolioModel`), `abstract class PortfolioRepository { Future<MyPortfolio> fetchMine(); Future<PortfolioItem> create(NewPortfolioItem input); Future<PortfolioItem> update(String id, {String? description, List<IndustryCategory>? fields}); Future<void> delete(String id); Future<String?> updateBio(String bio); }`
  - `portfolio_text.dart`: `durationLabel(30)` → `0:30`, `mediaBadge(kind, sec)` → `릴스 0:30` / `사진`, `likeLabel(512)` → `♥ 512` 라우트: `/creator/profile`, `/creator/portfolio/new`, `/creator/portfolio/:itemId`, `/creator/coming-soon/:title`(없으면 만든다)
  - `PortfolioUploadViewModel`: 고르기 → `prepare` → 첫 화면 그림 올리기 → 파일 올리기(진행률) → `create`. 올리는 중에 화면을 나가면 묻지 않고 취소한다.

화면 문구:
- B2: 사진, 활동 이름, 연결돼 있으면 `인스타그램 연동됨, @{아이디}`, 없으면 버튼 `인스타그램 연동하기`. 버튼 `협업 원칙`, `콘텐츠 올리기`, `인스타 가져오기`(연결이 없으면 연동 화면으로). 숫자 세 칸 `콘텐츠`, `받은 좋아요`, `완료한 협업`. 소개 줄 `소개` / 글 또는 `소개 글을 써 보세요. 맡기는 쪽이 프로필에서 봐요.` / `고치기`(시트: 제목 `소개 글`, 입력란 100자, 버튼 `저장`). 격자 제목 `내 콘텐츠 · 좋아요 많은 순`, 칸마다 `♥ {n}`, 영상은 길이 표지, 숨긴 것은 흐리게 `확인 중인 콘텐츠예요.` 빈 격자 `아직 올린 콘텐츠가 없어요. 좋아요를 많이 받은 콘텐츠가 카드 첫 장이 돼요.` 아래 줄 `보관함`, `설정`(준비 중, 6번의 보관함이 있으면 그리로).
- 크게 보기: 영상은 소리 꺼진 반복 재생, `설명 고치기`(시트: `한 줄 설명`, 분야 고르기, `저장`), `지우기`(확인 `이 콘텐츠를 지울까요? 받은 좋아요도 함께 사라져요.` / `지우기` / `그대로 두기`). 숨긴 콘텐츠는 위에 `확인 중인 콘텐츠예요.`
- B6: 머리 `새 콘텐츠`. 큰 미리 보기와 표지(`릴스 0:30`, `사진`), 아래 최근 미디어 줄과 맨 앞 `사진첩` 칸. `한 줄 설명`(40자), `분야`(일반 업종 9개 칩, 1~3개), 안내 `좋아요를 많이 받은 콘텐츠가 카드 첫 장에 먼저 보여요.`, 버튼 `포트폴리오에 올리기`. 설명이나 분야가 비면 버튼이 꺼진다. 네 번째 분야를 누르면 `분야는 3개까지 고를 수 있어요.` B6 상태: 처리 중 버튼 `영상을 준비하고 있어요`, 올리는 중 `올리는 중이에요 {n}%`. 오류: `60초가 넘는 영상은 올릴 수 없어요.`, `영상이 너무 커요. 100MB 이하로 골라 주세요.`, `사진이 너무 커요. 10MB 이하로 골라 주세요.`, `포트폴리오는 30개까지예요. 다른 콘텐츠를 지운 뒤 올려 주세요.`, `올리지 못했어요. 다시 시도해 주세요.` 끝나면 B2로 돌아가 `포트폴리오에 올렸어요.` 30개가 차 있으면 B2의 `콘텐츠 올리기`와 `인스타 가져오기`를 눌렀을 때 `포트폴리오는 30개까지예요. 다른 콘텐츠를 지운 뒤 올려 주세요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('labels durations and media badges the way the canvas does', ...);         // 30 → '0:30', '릴스 0:30', '사진'
test('upload view model uploads the poster, then the video, then creates the item', ...); // FakePortfolioFileUploader 순서 [poster, video]
testWidgets('shows the counts, the connected handle and the grid by likes', ...);
testWidgets('dims an item under review', ...);                                  // '확인 중인 콘텐츠예요.'
testWidgets('upload button stays disabled until description and a field are set', ...);
testWidgets('allows at most three fields', ...);                                // '분야는 3개까지 고를 수 있어요.'
testWidgets('shows progress while uploading and returns to the profile', ...);  // '올리는 중이에요 40%'
testWidgets('shows the size message for an oversized video', ...);
testWidgets('deletes an item after confirmation', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — 실기기에서 한 번: 50초 4K 영상을 골라 올린 뒤 저장된 파일의 해상도가 세로 1280 이하이고 MP4인지 확인한다.
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 미디어 고르기·준비·올리기 포트 추가`, `feat: 크리에이터 포트폴리오 탭과 콘텐츠 올리기 화면 추가`

---

### Task 10: 앱 — 인스타그램에서 가져오기(B3)

**Files:**
- Create: `app/lib/features/instagram_import/domain/{instagram_post.dart,instagram_import_repository.dart}`, `data/api_instagram_import_repository.dart`, `presentation/viewmodels/instagram_import_view_model.dart`, `presentation/pages/instagram_import_page.dart`
- Modify: `app/lib/core/navigation/app_router.dart`, `app/lib/main.dart`
- Test: `app/test/features/instagram_import/`

**Interfaces:**
- Consumes: `cora_api`의 `listInstagramPosts`, `importInstagramPosts` (Task 5), 3번의 연동 화면
- Produces:
  - `class InstagramPost { final String postId; final MediaKind kind; final String thumbnailUrl; final int? durationSec; final InstagramBlockReason? blockReason; final bool alreadyImported; }`, `enum InstagramBlockReason { tooLong, tooLarge }`, `abstract class InstagramImportRepository { Future<({String handle, int remaining, List<InstagramPost> posts})> fetchPosts(); Future<({List<PortfolioItem> items, List<SkippedPost> skipped})> importPosts(List<String> orderedIds); }`
  - `InstagramImportViewModel.toggle(String postId)` — 고른 순서를 유지하고, 빼면 뒤 번호가 당겨진다. 고를 수 있는 최대 수 = `min(10, remaining)`. 라우트 `/creator/instagram/import`. 연결이 없으면(409) `/creator/instagram`으로 보내고 연결 뒤 돌아온다.

화면 문구:
- 머리 `인스타 가져오기`. 설명 `@{아이디} 계정의 게시물이에요. 포트폴리오에 보여줄 것만 골라요.` 세 칸 격자, 고른 칸에 순서 번호, 이미 가져온 칸에 `가져옴`(누를 수 없음), 막힌 칸은 흐리게. 막힌 칸을 누르면: `60초가 넘는 영상은 가져올 수 없어요.` / `100MB가 넘는 영상은 가져올 수 없어요.`
- 아래: `{n}개 골랐어요 · 고른 순서대로 보여줘요`, 버튼 `포트폴리오에 추가`(0개면 꺼짐). 가져오는 중 `가져오는 중이에요`. 한도: 남은 칸을 넘겨 고르려 하면 `포트폴리오는 30개까지예요. {n}개만 더 가져올 수 있어요.`, 10개를 넘기려 하면 `한 번에 10개까지 가져올 수 있어요.` 끝: B2로 돌아가 `{n}개를 포트폴리오에 추가했어요.` 건너뛴 것이 있으면 덧붙여 `{m}개는 가져오지 못했어요.` 빈 목록: `가져올 게시물이 없어요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('keeps the selection order and renumbers after removing one', ...);       // [a,b,c] → b 빼면 a=1, c=2
testWidgets('explains why a long video cannot be picked', ...);
testWidgets('stops at the remaining slots with the canvas message', ...);       // remaining 2 → '…2개만 더 가져올 수 있어요.'
testWidgets('imports and returns to the profile with a count', ...);
testWidgets('sends the user to connect instagram first', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 인스타그램 게시물 가져오기 화면 추가`

---

### Task 11: 앱 — 릴스 피드(B1), 공개 프로필(B5), 신고

**Files:**
- Create: `app/lib/features/reels/domain/{reel_item.dart,reels_repository.dart,reel_player.dart}`, `data/{api_reels_repository.dart,<패키지>_reel_player.dart}`, `presentation/viewmodels/reels_feed_view_model.dart`, `presentation/pages/reels_feed_page.dart`, `presentation/widgets/{reels_pager.dart,reel_overlay.dart}`, `app/lib/features/creator_public_profile/domain/{creator_public_profile.dart,creator_public_profile_repository.dart,portfolio_like_repository.dart}`, `data/*`, `presentation/viewmodels/creator_public_profile_view_model.dart`, `presentation/pages/creator_public_profile_page.dart`, `app/lib/features/reports/{domain/report_repository.dart,data/api_report_repository.dart,presentation/report_sheet.dart}`
- Modify: `app/lib/features/discovery/presentation/pages/brand_discovery_page.dart`(위에 `카드 / 릴스` 전환), `app/lib/features/store_home/…`(바로가기 `릴스로 찾기` → `/store/find`, 하단 메뉴 `찾기` → `/store/find`), `app/lib/core/navigation/app_router.dart`, `app/lib/main.dart`, `app/lib/features/dev/presentation/pages/motion_gallery_page.dart`
- Delete: `app/lib/features/discovery/presentation/pages/creator_card_detail_page.dart`와 그 테스트(라우트 `/brand/creators/:id`는 B5로)
- Test: `app/test/features/reels/`, `app/test/features/creator_public_profile/`, `app/test/features/reports/`

**Interfaces:**
- Consumes: `cora_api`의 `listReels`, `recordReelView`, `setPortfolioItemLike`, `getCreatorPublicProfile`, `reportPortfolioItem` (Task 3, 4, 6), 4번의 `putDecision`·`like_note_sheet.dart`, 2번의 `/store/offers/new/:creatorId`
- Produces:
  - `abstract class ReelPlayer { Future<void> initialize(); Future<void> play(); Future<void> pause(); Future<void> setMuted(bool muted); bool get isReady; void dispose(); }` — 반복 재생은 구현이 켠다. `abstract class ReelPlayerFactory { ReelPlayer create(String url); }`, `reelPlayerFactoryProvider`(기본값 `UnimplementedError`)
  - `ReelsPager({ required List<ReelItem> items, required ValueChanged<int> onPageChanged, required ValueChanged<ReelItem> onViewed, required VoidCallback onNearEnd, required Widget Function(BuildContext, ReelItem) overlayBuilder })` — 세로 `PageView`. 지금 칸과 다음 두 칸, 바로 앞 한 칸의 플레이어만 만들고 나머지는 `dispose`(최대 4개). 지금 칸만 재생, 넘기면 앞 칸은 멈춘다. 다음 두 칸은 `initialize`까지만 해 둔다. 소리 켜기/끄기는 피드 전체에 하나이고 처음에는 꺼짐. 칸을 누르면 멈춤/재생. 사진은 한 장 그림. 한 칸에 1초 머물면 `onViewed`(칸마다 한 번). 남은 칸이 3개면 `onNearEnd`.
  - `ReelsFeedViewModel` — 커서로 이어 받고, `nextCursor`가 null이면 커서 없이 다시 받는다. 받은 것 중 이미 목록에 있는 `itemId`는 버린다. 좋아요는 화면에 먼저 반영하고 실패하면 되돌린다.
  - `abstract class PortfolioLikeRepository { Future<bool> setLike(String itemId, bool liked); }`, `abstract class CreatorPublicProfileRepository { Future<CreatorPublicProfile> fetch(String creatorId); }`, `abstract class ReportRepository { Future<void> reportItem(String itemId, ReportReason reason, {String? note}); }`, `showReportSheet(BuildContext, {required String itemId})`
  - 라우트: `/store/find`(사장님 찾기 탭 = 릴스), `/brand?view=reels`(브랜드 발견의 릴스 쪽), `/store/creators/:id`, `/brand/creators/:id`(B5). 이름이나 사진에서 B5로 갈 때 사진은 `Hero`(`'creator:<id>'`). 사장님 찾기 탭의 전환은 이 계획에서 숨긴다(세그먼트가 `릴스` 하나뿐이라). 8번 계획이 `릴스 / 리스트`를 더한다.

화면 문구:
- B1 머리: 브랜드는 `CoraSegmentedTabs` `카드` / `릴스`. 칸 위 글: 이름(누르면 B5), 콘텐츠 한 줄, `릴스 0:30, 팔로워 2,100명`(사진이면 `사진`, 팔로워가 없으면 앞부분만). 오른쪽 세로 버튼: 좋아요(채운/빈 하트, 수 없음), 소리 켜기/끄기, 더보기(`신고하기`). 아래 주 버튼: 사장님 `오퍼 보내기`, 브랜드 `관심 보내기`. B1 빈 상태: `아직 볼 수 있는 릴스가 없어요.` / `크리에이터가 콘텐츠를 올리면 여기에 보여요.` 불러오기 실패는 `CoraErrorView`.
- B5: 이름, `@{아이디}, {분야1}·{분야2}`(아이디가 없으면 분야만), 꼬리표 `#{…}`, 숫자 세 칸 `팔로워`(없으면 `-`), `받은 좋아요`, `완료 협업`. 소개 글 = `bio`와 `feeSentence`를 이은 글(둘 다 없으면 상자를 숨긴다). 대표 콘텐츠를 크게 보이고 그 위에 좋아요 버튼. 아래 격자(누르면 그 칸부터 `ReelsPager`로 크게). 주 버튼: 사장님 `오퍼 보내기` → `/store/offers/new/:creatorId`(열린 오퍼가 있으면 꺼지고 `이미 보낸 오퍼가 있어요.`), 브랜드 `관심 보내기` → 4번의 좋아한 점 시트 → `putDecision`(이미 보냈으면 `관심을 보냈어요`로 꺼짐). 진행 중 캠페인이 없는 브랜드가 `관심 보내기`를 누르면(B1, B5 모두): 시트 `캠페인을 먼저 만들어 주세요.` / `캠페인 만들기` → `/brand/campaign/new`.
- 신고 시트: 제목 `어떤 문제가 있나요?`, `다른 사람의 콘텐츠예요`, `부적절한 콘텐츠예요`, `광고·스팸이에요`, `기타`, 입력란 `자세히 (선택)`, 버튼 `신고하기`. 성공 `신고를 접수했어요.`, 409 `이미 신고한 콘텐츠예요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('plays only the current reel muted and prepares the next two', ...);   // FakeReelPlayerFactory: play 1개, initialize 3개
testWidgets('never keeps more than four players and disposes passed ones', ...);    // 10칸 넘긴 뒤 살아 있는 수 ≤ 4
testWidgets('records a view after one second on a reel, once', ...);
testWidgets('loads the next page near the end and drops duplicates', ...);
testWidgets('likes optimistically and reverts on failure', ...);
testWidgets('shows no like count to commissioners', ...);                          // find.textContaining('♥') → 없음
testWidgets('shows offer for a store and interest for a brand', ...);
testWidgets('asks a brand without a campaign to create one', ...);                 // '캠페인을 먼저 만들어 주세요.'
testWidgets('brand discovery switches between cards and reels', ...);
testWidgets('reports an item once and shows the duplicate message', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 모션 갤러리 견본, 소유자 승인** — 갤러리에 견본 릴스 6칸(영상 4, 사진 2, 개발 서버의 가짜 인스타그램 파일)을 넣는다. 제안 값: 넘김이 끝나는 시간 `280ms`, 곡선 `Curves.easeOutCubic`, 화면 높이의 `20%` 또는 빠른 손짓이면 다음 칸. iPhone과 중저가 Android 실기기에서 빠르게 연달아 넘길 때 다음 영상이 바로 뜨는지, 끊김이 없는지 확인받고 요청한 값을 반영한다. **승인 전에는 Task 12로 넘어가지 않는다.**
- [ ] **Step 6: Commit** — 커밋 세 개: `feat: 릴스 넘기기 위젯과 플레이어 포트 추가`, `feat: 릴스 피드와 카드·릴스 전환 추가`, `feat: 크리에이터 공개 프로필과 콘텐츠 신고 추가`

---

### Task 12: 앱 — 빠른 입찰(B4), 주간 예산, 입찰 결과(B7)

**Files:**
- Create: `app/lib/features/bidding/domain/{bid_budget.dart,bid_candidate.dart,bid_result.dart,bid_repository.dart,bid_text.dart}`, `data/api_bid_repository.dart`, `presentation/viewmodels/{bid_budget_view_model.dart,bid_deck_view_model.dart,bid_results_view_model.dart}`, `presentation/pages/{bid_budget_page.dart,bid_deck_page.dart,bid_results_page.dart}`, `presentation/widgets/bid_card.dart`
- Modify: `app/lib/core/ui/swipe_deck/{swipe_deck.dart,swipe_stamp.dart}`(선택 인자 `stampLabels: Map<SwipeOutcome, String>?`, 기본값은 지금 글자), `app/lib/features/store_home/…`(바로가기 `빠른 입찰` → `/store/bids`), `app/lib/core/navigation/app_router.dart`, `app/lib/main.dart`, 모션 갤러리
- Test: `app/test/features/bidding/`, `app/test/core/ui/swipe_deck/`(추가)

**Interfaces:**
- Consumes: `cora_api`의 `getBidBudget`, `setBidBudget`, `listBidCandidates`, `passBidCandidate`, `placeBid`, `listBidResults` (Task 8), `SwipeDeck` (4번), `won()` (2번), 3번의 결제 라우트 `/store/collaborations/:id/pay`
- Produces:
  - `abstract class BidRepository { Future<BidBudget> fetchBudget(); Future<BidBudget> setBudget(int amount); Future<List<BidCandidate>> fetchCandidates({String? first}); Future<void> pass(String creatorId); Future<void> place(String creatorId, int amount); Future<BidResults> fetchResults(); }` — 409 `BUDGET_EXCEEDED`는 `BudgetExceededException(remaining)`으로 바꾼다
  - `bid_text.dart`(순수 함수): `wonComma(320000)` → `320,000원`; `viewsShort(840)` → `840`, `7200` → `7.2천`, `8000` → `8천`, `12000` → `1.2만`, `10000` → `1만`; `expectedViewsLabel(ev)` → `예상 조회수 7.2천 – 1.2만 회`, 추정이면 `예상 조회수 840 – 1,260회 · 팔로워 기준 추정`, null이면 `아직 기록이 없어요`; `perViewHint(int amount, ev)` = `max(1, round(amount / ((min + max) / 2)))` → `조회 1회당 약 5원`(ev가 null이면 줄을 숨긴다); `bidResultLine(BidResult, now)` → `10만 원 입찰, 수락했어요` / `10만 원 입찰, 결제했어요` / `5만 원 입찰, 2일 안에 답이 와요`(남은 시간을 올림한 날 수, 하루 미만이면 `오늘 안에 답이 와요`) / `3만 원 입찰, 일정이 안 맞아 거절`·`금액이 안 맞아 거절`·`분야가 달라 거절`·`거절` / `3만 원 입찰, 답이 없어 만료됐어요` / `3만 원 입찰, 취소했어요`; `bidResultAction` → 수락(미결제) `결제하기`, 대기 `대기`(표지), 거절·만료 `다시 입찰`, 결제됨 `진행 보기`
  - `BidDeckViewModel` — 금액 고르기의 처음 값은 `50000`(남은 예산이 모자라면 들어가는 가장 큰 금액, 하나도 안 들어가면 `30000`), 남은 후보가 3장이면 더 받는다. 라우트 `/store/bids`(예산이 없으면 `/store/bids/budget`으로), `/store/bids/budget`, `/store/bids/results`

화면 문구:
- 예산: 제목 `이번 주에 얼마까지 쓸까요?`, 설명 `월요일 0시에 새로 시작해요. 서비스 수수료는 결제할 때 따로 보여 드려요.`, 선택 `10만 원`, `30만 원`, `50만 원`, `직접 입력`(입력란 `금액 (원)`, 틀리면 `3만 원 이상, 1만 원 단위로 넣어 주세요.`), 버튼 `이 예산으로 입찰하기`. 이미 쓴 것보다 적으면 서버 문구 `이번 주에 이미 쓴 금액보다 적게 정할 수 없어요.`
- B4 머리: `빠른 입찰`, 알약 `입찰 {n}건`, 오른쪽 `결과`(→ B7). `남은 예산 320,000원 · 총 500,000원`과 막대, 막대를 누르면 예산 화면.
- 카드: 대표 콘텐츠 그림, 이름, `{contentLine}, 팔로워 {n}명`(팔로워가 없으면 앞부분만), 예상 조회수 줄, `조회 1회당 약 {n}원`, 다른 시·도면 `{시·도}` 표지. 금액 칩 `3만 원`, `5만 원`, `10만 원`. 버튼 `넘기기`, `입찰하기`. 도장 글자 `입찰` / `넘김`. 위로 밀면 제자리로 돌아온다. 고른 금액이 남은 예산보다 크면 `입찰하기`가 꺼지고 그 위에 `남은 예산이 부족해요.` 오른쪽으로 밀어도 카드가 돌아온다. 서버가 409를 주면 같은 문구와 함께 예산을 다시 읽는다. 입찰 뒤 알림 `{이름}님에게 {금액} 입찰했어요.`
- 다 봤을 때: `지금 입찰할 수 있는 크리에이터를 모두 봤어요.` / `넘긴 크리에이터는 다음 주에 다시 나와요.` / `입찰 결과 보기`. 처음부터 없을 때: `아직 입찰할 수 있는 크리에이터가 없어요.` / `인스타그램을 연동하고 콘텐츠를 올린 크리에이터가 여기에 나와요.`
- B7: 머리 `입찰 결과`, `이번 주 입찰 예산 180,000원 / 500,000원 사용`, 숫자 세 칸 `수락`, `대기`, `거절`. 줄은 `bidResultLine`과 `bidResultAction`. `다시 입찰` → `/store/bids?first=<creatorId>`. 아래 버튼 `계속 입찰하기`. 빈 목록 `이번 주에 보낸 입찰이 없어요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('formats views, ranges and the per-view hint', ...);                    // '7.2천', '1.2만', '예상 조회수 7.2천 – 1.2만 회', 50000/{7200,12000} → '조회 1회당 약 5원'
test('describes every bid result line and action', ...);
test('picks the largest affordable amount as the default chip', ...);        // remaining 40000 → 30000
testWidgets('sends a store without a budget to the budget page first', ...);
testWidgets('rejects a custom budget that is not in 10000 won steps', ...);
testWidgets('swiping right places a bid with the chosen amount', ...);
testWidgets('disables bidding when the amount exceeds the remaining budget', ...); // '남은 예산이 부족해요.'
testWidgets('returns the card and refreshes the budget on a server budget conflict', ...);
testWidgets('results show counts, lines and actions', ...);                  // '3만 원 입찰, 일정이 안 맞아 거절' → '다시 입찰'
testWidgets('rebid opens the deck with that creator first', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 모션 갤러리 견본, 소유자 승인** — 입찰 카드 세 장짜리 덱(도장 `입찰`/`넘김`, 금액 칩)을 갤러리에 넣고 실기기에서 확인받는다. 4번의 카드 넘기기 수치를 그대로 쓰되 소유자가 다르게 원하면 `SwipeDeck`의 선택 인자로만 바꾼다. **승인 전에는 Task 13으로 넘어가지 않는다.**
- [ ] **Step 6: Commit** — 커밋 두 개: `feat: 입찰 주간 예산과 빠른 입찰 화면 추가`, `feat: 입찰 결과 화면 추가`

---

### Task 13: 앱 — 받은 오퍼의 입찰 카드와 거절 사유

**Files:**
- Create: `app/lib/features/offers/presentation/widgets/bid_decline_sheet.dart`
- Modify: `app/lib/features/offers/domain/{received_offer.dart,received_offers_repository.dart}`, `data/api_received_offers_repository.dart`, `presentation/pages/received_offers_page.dart`, `presentation/viewmodels/received_offers_view_model.dart`, `app/lib/features/store_home/domain/sent_offer.dart`, `app/lib/features/store_home/presentation/store_home_text.dart`
- Test: `app/test/features/offers/received_offers_bid_test.dart`, `app/test/features/store_home/store_home_text_test.dart`(추가)

**Interfaces:**
- Consumes: `cora_api`의 `declineOffer`(사유 포함), `ReceivedOfferModel.kind`·`respondDueAt`, `SentOfferModel.kind`·`bidAmount`·`declineReason` (Task 7)
- Produces:
  - `enum OfferKind { standard, bid }`, `enum BidDeclineReason { schedule, amount, field, none }`, `ReceivedOffer`에 `kind`, `respondDueAt`, `SentOffer`에 `kind`, `bidAmount`, `declineReason`. `ReceivedOffersRepository.decline(String id, {BidDeclineReason? reason})`
  - `sentOfferMeta`에 입찰 줄 추가: `빠른 입찰 · 답을 기다려요`, 거절이면 `거절함 · {사유}`(사유 문구는 `bidResultLine`과 같은 말)

화면 문구:
- 입찰 카드는 일반 오퍼 카드와 같고 표지만 `빠른 입찰 · 2일 안에 답해 주세요`. 보상 줄은 `조회 1회당 10원, 최대 {금액}`(2번의 `rewardSummary`가 `perViewCap`을 쓰는지 확인하고, 10만 원을 고정으로 쓰고 있으면 고친다).
- 입찰에서 `거절`을 누르면 시트: 제목 `거절하는 이유를 골라 주세요`, 설명 `고른 이유는 사장님에게 보여요.`, `일정이 안 맞아요`, `금액이 안 맞아요`, `분야가 달라요`, `이유 없이 거절`, 버튼 `거절하기`(고르기 전에는 꺼짐), `취소`.
- 입찰 거절 후: `거절했어요.` / `고른 이유가 사장님에게 전해져요. 다음 오퍼를 보여드릴게요.` / `되돌리기`(30초 규칙은 2번 그대로). 일반 오퍼의 거절은 지금처럼 시트 없이 바로 거절된다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('shows the quick bid badge on a bid card', ...);                  // '빠른 입찰 · 2일 안에 답해 주세요'
testWidgets('shows the bid amount as the cap in the reward line', ...);       // '조회 1회당 10원, 최대 5만 원'
testWidgets('asks for a reason before declining a bid', ...);                 // fake.declined == [('o1', BidDeclineReason.schedule)]
testWidgets('declines a regular offer without the sheet', ...);
test('describes a declined bid with its reason for the store', ...);          // '거절함 · 일정이 안 맞아 거절'
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 받은 오퍼에 빠른 입찰 표지와 거절 사유 추가`

---

### Task 14: 전체 흐름 확인

**Files:** 없음 (고칠 것이 나오면 해당 작업의 파일을 고치고 `fix:` 커밋)

- [ ] **Step 1: 자동 확인** — `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db` · `cd app && flutter analyze && flutter test` · `./scripts/gen-api.sh && git status --short`(변경 없음)

- [ ] **Step 2: 네 계정으로 수동 확인** (A 가게(업종 `패션`, 서울 성동구), B 크리에이터(서울 성동구), C 브랜드, D 가게(업종 `주류`). B는 원칙에서 `주류`를 피한다. iOS와 Android 각각)

1. B: 프로필 탭 → `콘텐츠 올리기`로 휴대폰의 45초 영상과 사진 하나를 올린다 → 격자에 `♥ 0` 두 칸, 영상은 `0:45`.
2. B: `인스타그램 연동하기`(아이디 `min.closet`) → `인스타 가져오기` → 75초 영상이 흐리고 누르면 `60초가 넘는 영상은 가져올 수 없어요.` → 세 개를 고르면 번호 1·2·3 → `포트폴리오에 추가` → 격자의 순서가 고른 순서. 같은 화면을 다시 열면 세 칸에 `가져옴`.
3. A: 홈의 `릴스로 찾기` → B의 콘텐츠가 소리 없이 반복 재생 → 소리 켜기 → 다음 칸도 소리가 켜져 있음 → 좋아요. B의 격자에 `♥ 1`, A의 화면에는 숫자가 없음.
4. C: 발견의 `카드 / 릴스` 전환 → 릴스 → B의 이름 → B5에 `@min.closet`, 꼬리표, 팔로워 `2,100`, 소개 글과 `희망 제작비는 …` → 캠페인을 마감한 상태에서 `관심 보내기` → `캠페인을 먼저 만들어 주세요.` C: 발견 카드에서 B의 첫 장이 가장 좋아요가 많은 콘텐츠의 그림이다.
5. D: `찾기` 탭에 B의 콘텐츠가 없다. B5 주소를 직접 열면 404 처리 화면.
6. 서로 다른 세 계정으로 B의 콘텐츠 하나를 신고 → 서버 로그에 운영자 알림 4건 → 피드에서 빠지고 B의 격자에 `확인 중인 콘텐츠예요.` → `yarn ops unhide-content --item <id> --operator dev --reason 확인` → 다시 보인다.
7. A: `빠른 입찰` → 예산 `50만 원` → B 카드에 `예상 조회수 840 – 1,260회 · 팔로워 기준 추정`, `조회 1회당 약 48원`(5만 원) → `입찰하기` → `남은 예산 450,000원`. A: 예산을 `30만 원`으로 줄이고 `10만 원` 칩으로 여러 명에게 입찰해 남은 예산이 5만 원이 되면 `10만 원` 칩에서 `남은 예산이 부족해요.`
8. B: `협업` 탭 → 입찰 카드 `빠른 입찰 · 2일 안에 답해 주세요` → `거절` → `일정이 안 맞아요` → 30초 뒤 A의 B7에 `5만 원 입찰, 일정이 안 맞아 거절`과 `다시 입찰`, 남은 예산이 돌아옴.
9. A: `다시 입찰` → B가 맨 앞 → 입찰 → B가 수락 → B7 `수락했어요` → `결제하기` → 견적의 보관액 `50,000원`, 수수료는 `FEE_RATE_BID` 기준.
10. 서버를 2일 뒤로 띄운다(`FAKE_CLOCK_OFFSET_DAYS=2`) → 답하지 않은 입찰이 `답이 없어 만료됐어요`, 예산이 돌아옴. 서버를 다음 월요일로 띄운다 → B4가 예산 화면부터 다시 시작한다.
11. 다크 모드, 글자 1.3배에서 B1~B7을 훑어본다. 캔버스의 B1~B7과 나란히 놓고 비교한다.

- [ ] **Step 3: 동시성 손 확인** — 남은 예산 5만 원에서 `curl` 두 개로 서로 다른 크리에이터에게 5만 원 입찰을 동시에 보낸다. Expected: 201 하나, 409 하나.

---

## 완료 기준

- Task 14의 자동 확인, 수동 확인 11개, 동시성 확인 통과
- Task 11 Step 5와 Task 12 Step 5의 소유자 승인 완료
- 운영 환경 모드에서 가짜 인스타그램 파일 라우트가 없고 `INSTAGRAM_ADAPTER=fake`면 서버가 시작을 거부함

## 이 계획이 하지 않는 것

- 실제 Meta API 연동과 게시물 가져오기의 작업 큐 처리 (9번 계획. 지금은 요청 안에서 최대 10개를 차례로 복사한다)
- 사장님 찾기 탭의 `리스트` 전환과 목록 검색 (8번 계획)
- 사용자·대화방 신고 화면, 차단, 사용자 이용 정지 명령 (5번 계획)
- 서버에서의 영상 화질 변환, 적응형 재생, CDN 이전
- 크리에이터끼리의 좋아요·팔로우·댓글, 브랜드의 입찰
- 회원 탈퇴 때 포트폴리오 파일 정리 (공통 규칙 20장, 출시 준비 계획)

## 이 계획이 구체화한 것

- 콘텐츠별 좋아요 수는 올린 크리에이터에게만 보인다. 맡기는 쪽은 B5의 합계만 보고, B1의 좋아요 버튼에는 숫자가 없다(캔버스 B1의 수 표시와 다르다).
- B5의 좋아요 버튼은 대표 콘텐츠에 누르는 것이다. 꼬리표는 `얼굴출연가능`/`얼굴출연없음`, `대본낭독없음`, `솔직후기`로 만들고, 희망 제작비 문장은 `희망 제작비는 {띠}예요.`(50만 원 이상은 `…이상이에요.`)로 붙인다.
- 피드의 "본 것"은 순환 번호(`feed_states.cycle`)로 관리하고, 커서는 기준 시각을 담아 이어 읽는 동안 순서가 흔들리지 않게 했다. 본 것으로 치는 시간은 1초.
- 영상 길이는 서버가 파일을 열지 않으므로 앱이 보낸 값을 믿는다. 크기는 서버가 저장소에서 실제 크기를 확인한다. 첫 화면 그림은 JPEG 2MB까지, 사진은 앱이 긴 변 2048로 줄인다.
- 인스타그램에서 가져온 콘텐츠의 분야는 협업 원칙의 분야 앞 3개(없으면 `기타`), 설명이 비면 `인스타그램 게시물`. 지운 콘텐츠의 원본 게시물은 다시 가져올 수 있다. 한 번에 10개까지.
- 신고 사유: `다른 사람의 콘텐츠예요`, `부적절한 콘텐츠예요`, `광고·스팸이에요`, `기타`. 숨김 해제와 삭제는 그 콘텐츠의 열린 신고를 함께 처리 완료로 바꾼다.
- 입찰 금액은 세 단계만 받는다. 예산 직접 입력은 3만~1,000만 원, 1만 원 단위. 주 중에 예산을 바꿀 수 있지만 이미 쓴 금액 아래로는 안 된다. 결제된 입찰은 결제 뒤 환급·취소가 있어도 예산을 돌려주지 않는다.
- 입찰에서 넘긴 크리에이터는 그 주 동안 다시 나오지 않는다(`bid_passes`). 입찰 결과의 숫자 `거절`에 만료와 취소는 넣지 않는다.
- 새로 정한 문구: `소개 글을 써 보세요. 맡기는 쪽이 프로필에서 봐요.`, `아직 올린 콘텐츠가 없어요. 좋아요를 많이 받은 콘텐츠가 카드 첫 장이 돼요.`, `이 콘텐츠를 지울까요? 받은 좋아요도 함께 사라져요.`, `영상을 준비하고 있어요`, `올리는 중이에요 {n}%`, `60초가 넘는 영상은 올릴 수 없어요.`, `영상이 너무 커요. 100MB 이하로 골라 주세요.`, `사진이 너무 커요. 10MB 이하로 골라 주세요.`, `포트폴리오는 30개까지예요. 다른 콘텐츠를 지운 뒤 올려 주세요.`, `포트폴리오에 올렸어요.`, `분야는 3개까지 고를 수 있어요.`, `100MB가 넘는 영상은 가져올 수 없어요.`, `한 번에 10개까지 가져올 수 있어요.`, `{n}개를 포트폴리오에 추가했어요.`, `가져올 게시물이 없어요.`, `인스타그램을 먼저 연동해 주세요.`, `아직 볼 수 있는 릴스가 없어요.`, `어떤 문제가 있나요?`, `이미 신고한 콘텐츠예요.`, `월요일 0시에 새로 시작해요. 서비스 수수료는 결제할 때 따로 보여 드려요.`, `이 예산으로 입찰하기`, `3만 원 이상, 1만 원 단위로 넣어 주세요.`, `이번 주에 이미 쓴 금액보다 적게 정할 수 없어요.`, `이번 주 예산을 먼저 정해 주세요.`, `{이름}님에게 {금액} 입찰했어요.`, `{가게 이름}에서 빠른 입찰이 왔어요. 2일 안에 답해 주세요.`, `지금 입찰할 수 있는 크리에이터를 모두 봤어요.`, `아직 입찰할 수 있는 크리에이터가 없어요.`, `팔로워 기준 추정`, `답이 없어 만료됐어요`, `이번 주에 보낸 입찰이 없어요.`, `거절하는 이유를 골라 주세요`, `고른 이유는 사장님에게 보여요.`, `고른 이유가 사장님에게 전해져요. 다음 오퍼를 보여드릴게요.`
