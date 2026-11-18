# 2026-11-17 회의 반영 (화면 변경 6묶음) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

**Goal:** 회의로 바뀐 화면 여섯 묶음을 만든다: 카드 넘기기의 하트·저장 이름(G1), 저장함 탭(G2), 이상형 월드컵(G3), 사장님 첫 화면과 전체 둘러보기(G4), 가게 소개 화면의 버튼 순서(G5), 크리에이터 대표 게시물 4개(G6).

**Architecture:** 서버는 4번의 발견·추천·저장 규칙을 사장님 역할로 넓히고(`campaign_id = null`인 `swipe_decisions`, `RecommendationScope.STORE`), 대표 게시물(`featured_posts`)을 `creators` 모듈에 더해 임시 카드 한 장(`creator_profiles.card_*`)을 대체한다. 인스타 게시물 목록은 `InstagramPort`에 앞당겨 더한다. 앱은 4번의 `SwipeDeck`·카드·토스트·시트를 그대로 쓰고 이름과 버튼만 바꾸며, 사장님용 둘러보기·저장함·월드컵·홈은 새 화면이다. 월드컵은 서버에 아무것도 쓰지 않는다.

**Tech Stack:** 앞 계획들과 같다. 새 패키지 없음(`image_picker`는 이미 있다).

**Spec:** `docs/superpowers/specs/2026-11-19-meeting-revision-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md`(2026-11-19 개정 문장 포함) · 기획 캔버스 "11/19 회의 반영" 줄(https://claude.ai/artifact/VLvHYafMkwqziRViALPicw, 로컬 사본 `.superpowers/canvas-2026-11-19-drafts/merge/project/M19*.dc.html`(라이트), `DarkM19*.dc.html`(다크), 메모 `canvas.json`의 `m19-` 줄) · 상위: `2026-11-11-brand-discovery-matching-design.md`(4번), `2026-11-11-portfolio-reels-bidding-design.md`(7번), `2026-11-12-store-flow-revision-design.md`

**선행 조건:** 공통 기반, 2~5번, 가게 흐름 개정, 보안 보강 묶음이 끝나 있다(HEAD 6fcf6f0 기준 확인함). 6번(제작·검토·회고) 이후는 시작하지 않는다.

## Global Constraints

앞 계획들의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것(값은 설계 문서에서 그대로):

- 화면 이름: 서버 `LIKE`는 "하트", `PASS`는 "넘김", `HOLD`는 "저장"(나만 보는 북마크). **"서로 관심"은 그대로다.** 서버 값·DB·OpenAPI의 `LIKE`/`PASS`/`HOLD`와 코드 이름(`likes`, `SwipeOutcome.hold` 등)은 바꾸지 않는다.
- 하트를 보낸 것은 저장이 아니다. 같은 대상에 결정은 하나라서 저장해 둔 카드에 하트를 보내면 저장에서 빠진다.
- 대표 게시물: 최대 `4`개, 한 줄 `1~40`자(인스타에서는 글의 첫 줄을 40자로 자른다), 출처 `INSTAGRAM`/`GALLERY`, 사진첩은 **사진만**(JPEG·PNG·HEIC, 서버 사진 한도 `5MB`를 넘지 않게 앱이 올리기 전에 긴 변 `2048`·품질 `85`로 줄인다), 인스타 영상은 `60`초·`100MB` 이하만, 순서는 `1~4` 빈 틈 없이, 원본 인스타 게시물 ID는 크리에이터마다 한 번만. 한도를 서버 사진 `5MB`로 올리지 않는다.
- 사장님 전체 둘러보기: 하루 최대 `10`장, 한국 시간 자정에 새로 채움. 나오는 사람 = 대표 게시물 1개 이상, 가게 업종을 피하지 않음(공통 모델 3장), 공통 모델 5장 제외 대상 아님, 내가 넘기거나 하트·저장한 사람 아님. 순서: 그 가게에 지원한 사람 → 같은 구·군 → 같은 시·도 → 그 밖.
- 사장님 홈 추천: 지원자가 있으면 그 가게의 살아 있는 지원자(`APPLIED`) 중 최대 `3`명(가게 흐름 개정 G2의 점수 그대로), 없으면 Cora 크리에이터 전체 중 `3`명.
- 월드컵: 저장 `4`명 이상이면 배너, `4강`(4명) / `8강`(8명, 저장 8명 미만이면 꺼짐), 저장한 사람 중 무작위로 뽑음, 서버에 쓰지 않음, 단계 글자 "4강 · 1 / 2", "8강 · 1 / 4", 결승 "결승 · 1 / 1".
- 사장님의 하트는 협업·`matches`를 만들지 않는다. 사장님의 "서로 관심" = 내가 하트를 보낸 크리에이터가 그 가게에 살아 있는 지원(`APPLIED`·`OFFERED`)을 가짐.
- **화면은 캔버스(라이트·다크)와 100% 같게.** 캔버스에 없는 문구는 설계 문서의 **[캔버스에 없음]** 표시된 것만 쓰고 보고서에 "캔버스 밖" 목록으로 적는다.
- 시연 앱(`app/lib/features/demo/**`, `app/lib/main_demo.dart`, `app/test/demo/**`)은 고치지 않는다.
- 작업 브랜치를 만들지 않고 `main`에 바로 커밋한다. 커밋마다 테스트가 통과한 상태여야 한다. push는 하지 않는다(계획이 끝나면 조율 세션에 보고).

## Review Focus

1. **대표 게시물 5개째, 두 기기에서 동시에 저장, 순서에 빈 틈** → 서버는 4개 초과를 400으로 막고 순서는 항상 `1..n`이며 저장은 한 트랜잭션이다. (T2)
2. **남의 사진 경로·남의 인스타 게시물 ID·이미 가져온 게시물을 다시 가져옴** → 업로드 경로 소유 검사 400, 인스타 목록에 없는 ID 404, 중복 ID 409. (T2, T3)
3. **사장님 하트가 브랜드 데이터와 섞임** → 사장님 결정은 `campaign_id = null`·`target_kind = CREATOR`로만 저장되고 `matches`·협업을 만들지 않으며, 다른 가게의 결정은 읽히지 않는다. (T5, T6)
4. **저장해 둔 카드에 하트(또는 반대)** → 결정이 하나만 남고 저장함 탭이 맞게 바뀐다. 서로 관심(하트 + 지원)은 되돌릴 수 없다. (T5, T6)
5. **저장이 0~3명이거나 7명 이하에서 월드컵** → 배너 없음, 8강은 꺼짐, 4강은 정확히 4명을 겨루고 결과에 우승자가 한 명이다. (T10)
6. **글자 1.3배, 다크 모드, 긴 이름·한 줄(2줄 넘음)** → 넘침 없이 캔버스 모양을 지킨다. (모든 앱 작업)

---

## 파일 구조

| 곳 | 새 파일 / 바뀌는 파일 | 책임 |
|---|---|---|
| 서버 `api/src/creators/` | `featured-post-rules.ts`, `featured-posts.repository.ts`, `featured-posts.service.ts`, `dto/featured-post.model.ts`, `dto/replace-featured-posts.dto.ts`; `creators.service.ts`·`creators.controller.ts`·`creators.repository.ts` 수정 | 대표 게시물 저장·읽기, 카드 첫 장 읽기 |
| 서버 `api/src/instagram/`, `api/src/integrations/instagram/` | 포트 `listPosts`/`fetchMedia`/개인 계정 오류, 가짜 어댑터, `instagram.service.ts`·`instagram.controller.ts` | 게시물 목록과 가져오기 |
| 서버 `api/src/recommendations/`, `discovery/` | 사장님 하루 카드, `StoreCreatorCardModel`, 사장님 결정·되돌리기·넘김 이유 | 사장님 전체 둘러보기 |
| 서버 `api/src/discovery/` | `store-interests.service.ts` 등 | 사장님 저장함, 서로 관심 |
| 서버 `api/src/applications/` | 추천 3명 확장 | 사장님 홈 |
| 앱 `core/ui/swipe_deck`, `features/discovery` | 도장·버튼·토스트·시트 문구와 모양 | G1 이름 |
| 앱 `features/featured_posts/` (새) | `{data,domain,presentation/{pages,viewmodels,widgets}}` | G6 |
| 앱 `features/store_discover/` (새) | 사장님 전체 둘러보기 | G4·G1 |
| 앱 `features/interests/`, `features/store_interests/` (새) | 저장함 탭, 사장님 저장함 | G2 |
| 앱 `features/world_cup/` (새) | 월드컵 | G3 |
| 앱 `features/store_home/`, `features/store_onboarding/` | 사장님 홈, A3 | G4, G5 |

---

### Task 1: 앱 — 하트·저장 이름, 카드 버튼 네 개, 이유 시트의 "건너뛰기" (G1 공용)

브랜드 01, 크리에이터 08, 둘러보기(A1)가 같은 위젯을 쓰므로 한 번에 바꾼다.

**Files:**
- Modify: `app/lib/core/ui/swipe_deck/swipe_stamp.dart`(`labelOf`: `like => '하트'`, `hold => '저장'`, 주석), `app/lib/features/discovery/presentation/widgets/swipe_action_buttons.dart`, `.../pass_reason_sheet.dart`, `app/lib/features/discovery/presentation/discovery_text.dart`, `.../creator_discovery_text.dart`, `app/lib/core/ui/cora_state_view.dart`(:82 `allSeen` 설명), `app/lib/features/discovery/presentation/pages/{brand_discovery_page,creator_discovery_page,preview_discovery_page}.dart`(토스트 이동 경로·버튼 연결)
- Test: 위 위젯의 기존 시험(`app/test/core/ui/swipe_deck/`, `app/test/features/discovery/`)을 새 문구로 고치고 아래를 더한다.

**Interfaces:**
- Consumes: `SwipeOutcome { like, pass, hold }`(이름 그대로), `SwipeDeckController.swipe(SwipeOutcome)`.
- Produces: `SwipeActionButtons({required canUndo, onUndo, onPass, onHold, onLike})` — 버튼 네 개 `되돌리기`(52)·`넘기기`(64)·`저장`(52, 북마크 아이콘 `M6 3h12v18l-6-4-6 4z`)·`하트`(64→캔버스 44 아이콘, 형광), 아이콘 아래 11px 글자 라벨(`caption`, 흰색, 캔버스 `act span`). `DiscoveryTexts.{undoLabel='되돌리기', passLabel='넘기기', holdLabel='저장', likeLabel='하트', likeToast='하트를 보냈어요. 상대도 고르면 알려드려요.', likeToastAction='보낸 관심', holdToast='저장했어요. 나만 볼 수 있어요.', holdToastAction='저장함', reasonSave='이유 남기고 다음 보기', reasonSkip='건너뛰기'}`. 크리에이터 08은 `CreatorDiscoveryTexts.likeToast='하트를 보냈어요. 브랜드도 고르면 알려드려요.'`(**캔버스 밖**).

- [ ] **Step 1: 실패하는 시험을 쓴다.** `swipe_stamp_test`: `it('labels the like stamp as heart and the hold stamp as save')` — `find.text('하트')`, `find.text('저장')`, `find.text('관심')` 없음. `swipe_action_buttons_test`: `it('shows four labelled buttons: undo, pass, save, heart')`(글자 네 개, `Semantics` 라벨 `되돌리기/넘기기/저장/하트`), `it('fires onHold from the save button and onLike from the heart button')`. `pass_reason_sheet_test`: `it('disables the save-reason button until a reason is picked and always offers skip')`(고른 것 없으면 `이유 남기고 다음 보기` 버튼 꺼짐, `건너뛰기` 누르면 닫히고 저장 호출 없음), `it('has no undo row in the sheet')`(`되돌리기` 없음). 페이지 시험: `it('shows the save toast with the 저장함 action and the heart toast with the 보낸 관심 action')`, 토스트 `저장함`은 `AppRoutes.brandSaved`(크리에이터는 `creatorHeld`), `보낸 관심`은 `brandInterests?tab=sent`(크리에이터 `creatorInterests?tab=sent`)로 간다.
- [ ] **Step 2: 실행해 실패를 본다.** `cd app && flutter test test/core/ui test/features/discovery` → FAIL(새 글자 없음).
- [ ] **Step 3: 구현.** 위 Interfaces대로. `SwipeActionButtons`의 `showUndo` 인자는 없애고 되돌리기를 항상 버튼 줄에 둔다(`canUndo`가 거짓이면 꺼진 모양). F8 "추천을 다 봄" 화면의 `UndoLastLink`는 그대로 둔다(4번 설계). `CoraStateView.allSeen` 설명을 `하트와 저장에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.`로 바꾼다(**캔버스 밖**). 카드 위젯·상세 화면의 `관심 보내기` 버튼, 하단 메뉴 `관심`, 채팅·받은 제안의 문구는 **바꾸지 않는다**(캔버스에 없음, 계획 Ruling 1). 라이트·다크 모두 캔버스 `M19G1Swipe`/`M19G1Heart`/`M19G1Save`/`M19G1Pass`와 같게(버튼 줄 위치 `bottom:16`, 글자 11/500, 도장 모양).
- [ ] **Step 4: 시험이 통과하는지 본다.** `cd app && flutter analyze && flutter test` → 전부 통과(`demo` 때문에만 실패하면 내 경로로 좁혀 보고에 적는다).
- [ ] **Step 5: 시뮬레이터 확인.** iPhone 15 Pro(A45ED678)에서 브랜드 01과 크리에이터 08을 띄워 라이트·다크 스크린샷을 `.superpowers/sdd/2026-11-19-meeting-revision/shots/task1/`에 저장하고 캔버스와 다른 점을 보고서에 적는다.
- [ ] **Step 6: 커밋.** `git commit -m "feat: 카드 넘기기의 보류를 저장, 관심을 하트로 부르고 버튼 네 개와 건너뛰기를 둠"`

---

### Task 2: 서버 — 대표 게시물(`featured_posts`)과 카드 첫 장 전환

**Files:**
- Modify: `api/prisma/schema.prisma`(모델 `FeaturedPost`, enum `FeaturedPostSource {INSTAGRAM GALLERY}`·`FeaturedPostKind {PHOTO VIDEO}`), 새 마이그레이션 `api/prisma/migrations/<타임스탬프>_featured_posts/migration.sql`, `api/src/uploads/photo-rules.ts`(`PHOTO_PURPOSES`에 `FEATURED_POST`)·`uploads.service.ts`(`RULES`: role `CREATOR`, dir `featured-posts`), `api/src/creators/{creators.service,creators.repository,creators.controller}.ts`, `api/src/creators/dto/{creator-profile.model,upsert-creator-profile.dto}.ts`, `api/src/recommendations/dto/recommendation-cards.model.ts`·`card-models.ts`, `api/seed/lib/*`(시드 크리에이터에게 대표 게시물을 `api/seed/mock/images`로 만들기)
- Create: `api/src/creators/featured-post-rules.ts`, `featured-posts.repository.ts`, `featured-posts.service.ts`, `dto/featured-post.model.ts`, `dto/replace-featured-posts.dto.ts`
- Test: `featured-post-rules.spec.ts`, `featured-posts.service.spec.ts`, `api/test/featured-posts.e2e-spec.ts`, `api/test/db/featured-posts.db-spec.ts`, 카드 사본을 박은 기존 시험(`creators.service.spec.ts`, `test/{creators,discovery,conversations}.e2e-spec.ts`, `test/db/discovery-schema.db-spec.ts:381~386`) 수정

**Interfaces:**
- Produces(`featured-post-rules.ts`): `MAX_FEATURED_POSTS = 4`, `MAX_CAPTION = 40`, `firstLine(text: string | null): string | null`(첫 줄을 40자로), `validateReplacement(items: FeaturedPostDraft[]): void`(4 초과·한 줄 40자 초과·`GALLERY`+`VIDEO`·`GALLERY`인데 한 줄 없음·인스타 게시물 ID 중복이면 `AppError('VALIDATION_FAILED', …)`), `FeaturedPostDraft { source: 'INSTAGRAM'|'GALLERY'; kind: 'PHOTO'|'VIDEO'; mediaPath: string; thumbnailPath: string|null; caption: string|null; instagramMediaId: string|null }`.
- Produces(`FeaturedPostsService`): `listMine(userId): Promise<FeaturedPostModel[]>`, `replaceMine(userId, items: ReplaceFeaturedPostsDto['items']): Promise<FeaturedPostModel[]>`(한 트랜잭션, 기존 행 소프트 삭제 후 `1..n`으로 다시 쓰되 `{id}`만 온 항목은 기존 행을 유지), `listForCreators(userIds: string[]): Promise<Map<string, FeaturedPostModel[]>>`.
- Produces 라우트: `GET /creators/me/featured-posts`(`getMyFeaturedPosts`), `PUT /creators/me/featured-posts`(`replaceMyFeaturedPosts`, 본문 `{ items: [{ id?: uuid } | { source, kind, mediaPath, thumbnailPath?, caption?, instagramMediaId? }] }`). `FeaturedPostModel { id; position: number; source; kind; photoUrl: string; mediaUrl: string; caption: string|null; instagramMediaId: string|null }`(`photoUrl` = 썸네일이 있으면 썸네일, 없으면 사진).
- Produces: `CreatorsService.getCardCopy`가 1번 게시물의 `{ headline: caption, photoPath: thumbnailPath ?? mediaPath }`를, `toCardSource`가 `headline`·`photoUrl`을 1번 게시물에서(없으면 프로필 사진) 읽는다. `CreatorCardSource`·`CreatorCardModel`(브랜드 카드)에 `posts: FeaturedPostModel[]`(최대 4)가 더해진다. `PUT /creators/me`의 `cardHeadline`·`cardPhotoPath`는 받되 **무시한다**(`@ApiProperty` 설명 "더는 읽지 않아요"), 응답의 `cardHeadline`·`cardPhotoUrl`은 1번 게시물에서 채운다(앱이 T4까지 안 깨진다).

- [ ] **Step 1: 규칙 시험을 쓴다**(`featured-post-rules.spec.ts`): `it('rejects a fifth post')`, `it('rejects a caption longer than 40 characters')`, `it('takes the first line of an instagram caption up to 40 characters')`, `it('rejects a gallery video')`, `it('rejects a gallery post without a caption')`, `it('rejects the same instagram media id twice')`, `it('accepts an empty list')`.
- [ ] **Step 2: 서비스 시험**(`featured-posts.service.spec.ts`, 손으로 쓴 `FakeFeaturedPostsRepository`와 `FakeStoragePort`): `it('replaces the whole list and keeps positions 1..n')`, `it('keeps an existing post given only its id and rejects someone else's id')`, `it('asserts the uploaded path belongs to the creator (FEATURED_POST)')`(남의 경로면 `VALIDATION_FAILED`), `it('returns the first post as the card copy')`, `it('falls back to the profile photo when there is no post')`.
- [ ] **Step 3: DB·e2e 시험을 쓴다.** `featured-posts.db-spec.ts`: 순서 `(creator_id, position)` 부분 유니크(지운 행 제외), 인스타 ID `(creator_id, instagram_media_id)` 부분 유니크, **옛 `card_photo_path`가 있는 프로필이 마이그레이션 뒤 1번 게시물(`GALLERY`, `PHOTO`)로 옮겨지는지**, 동시에 두 `replaceMine`이 와도 4개 안에서 `1..n`(`Promise.all`). `featured-posts.e2e-spec.ts`: 크리에이터는 PUT/GET 되고, 5개면 400, 가게·브랜드는 403, 남의 경로는 400, 다른 크리에이터의 게시물 `id`는 404.
- [ ] **Step 4: 실행해 실패를 본다.** `source ~/.nvm/nvm.sh && cd api && nvm use && yarn test featured-post && yarn test:db featured-posts` → FAIL.
- [ ] **Step 5: 구현.** 스키마·마이그레이션(`yarn prisma migrate dev --create-only` → SQL 고치기: `ALTER TABLE "featured_posts" ENABLE ROW LEVEL SECURITY;`, 부분 유니크 인덱스 둘(직접 SQL, `public.` 쓰지 않음), 옛 카드 이전 `INSERT … SELECT`) → `yarn prisma migrate deploy`. 서비스·저장소·컨트롤러. `toCardSource`·`getCardCopy`·`toProfile`의 세 읽는 곳을 바꾼다(`grep -rn "cardHeadline\|cardPhotoPath" api/src`로 빠진 곳이 없는지 확인). 브랜드 카드 `CreatorCardModel`에 `posts`를 더한다. 시드(`yarn seed:dev`)는 시드 크리에이터 3명에게 `api/seed/mock/images`의 사진으로 대표 게시물 2~4개를 만든다(휴대폰 010-0000-0001~0003 계정 그대로).
- [ ] **Step 4': 통과를 본다.** `yarn lint && yarn tsc --noEmit && yarn test && yarn test:db && yarn test:e2e`(e2e·db는 `cora_test`를 쓰므로 이 계획의 서버 구현자는 한 번에 하나만) → 전부 통과.
- [ ] **Step 6: 생성 클라이언트.** 루트에서 `./scripts/gen-api.sh` 뒤 `cd app && flutter analyze && flutter test`. 깨진 곳은 앱 data 계층만 최소로 맞춘다.
- [ ] **Step 7: 커밋.** `git commit -m "feat: 대표 게시물 4개와 카드 첫 장을 대표 게시물에서 읽음"`

---

### Task 3: 서버 — 인스타 게시물 목록과 가져오기, 개인 계정 거절

**Files:**
- Modify: `api/src/integrations/instagram/instagram.port.ts`, `fake-instagram.adapter.ts`(+`.spec.ts`), `api/src/instagram/{instagram.service,instagram.controller}.ts`(+`instagram.service.spec.ts`, `test/instagram.e2e-spec.ts`), `api/src/instagram/dto/*`
- Test: 위 시험 파일들

**Interfaces:**
- Produces(`instagram.port.ts`): `class InstagramPersonalAccountError extends Error`; `interface InstagramPost { id: string; kind: 'PHOTO'|'VIDEO'; caption: string|null; thumbnailUrl: string; durationSec: number|null; sizeBytes: number|null }`; `InstagramPort.listPosts(token: string|null): Promise<InstagramPost[]>`, `InstagramPort.fetchMedia(token: string|null, postId: string): Promise<{ bytes: Buffer; contentType: string }>`, `completeConnect`가 개인 계정이면 `InstagramPersonalAccountError`를 던진다.
- Produces(가짜): `FakeInstagramAdapter`는 견본 게시물 `12`개(`fake-post-1`…`fake-post-12`, 짝수는 `VIDEO` 30초·`sizeBytes` 8MB, 한 줄 "견본 게시물 {n}"), 썸네일은 `https://picsum.photos/seed/cora-ig-{n}/600/600`, `fetchMedia`는 생성자 인자 `fetcher = fetch`로 그 주소를 받아 돌려준다(시험은 손으로 쓴 가짜 `fetcher`). 코드가 `personal`로 시작하면 `completeConnect`가 `InstagramPersonalAccountError`를 던진다.
- Produces 라우트: `GET /instagram/posts`(`listInstagramPosts` → `InstagramPostModel[]`, 연결 없으면 404), `POST /instagram/posts/import`(`importInstagramPosts`, 본문 `{ postIds: string[] }`(1~4) → `FeaturedPostDraftModel[] { source:'INSTAGRAM'; kind; mediaPath; thumbnailPath: string|null; caption: string|null; instagramMediaId: string; photoUrl: string }`). 가져오기는 영상이 `60`초 또는 `100MB`를 넘으면 409 "60초가 넘는 영상은 가져올 수 없어요."(공통 모델 16장), 목록에 없는 ID면 404, 이미 대표 게시물인 ID면 409 `CONFLICT`. 파일은 `StoragePort.upload`로 `featured-posts/<userId>/<uuid>.<ext>`에 복사한다(PHOTOS 버킷). `InstagramService.complete`는 개인 계정이면 409 + `개인 계정은 연동할 수 없어요. 인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 다시 연동해 주세요.`.

- [ ] **Step 1: 시험을 쓴다.** 가짜 어댑터: `it('lists twelve sample posts')`, `it('rejects a personal account code')`, `it('fetches media through the injected fetcher')`. 서비스: `it('copies a photo post into storage under the creator's folder')`, `it('refuses a video longer than 60 seconds or over 100MB')`, `it('returns 404 for a post id that is not in the connected account')`, `it('returns 409 for a post that is already a featured post')`, `it('does not import without a connection')`(404), `it('maps the personal account error to 409 with the guidance sentence')`. e2e: 크리에이터만(가게·브랜드 403), 연결 후 목록 12개.
- [ ] **Step 2: 실행해 실패를 본다.** `yarn test instagram` → FAIL.
- [ ] **Step 3: 구현.** 포트·가짜·서비스·컨트롤러. 토큰은 `connections.findByCreatorId` + `SecretBox` 복호화(키 없는 개발 환경은 토큰이 null이어도 가짜가 동작해야 한다). 가져오기 중 일부가 실패하면 이미 올린 파일은 두고 전체를 실패로 돌려준다(고아 파일은 허용).
- [ ] **Step 4: 통과를 본다.** `yarn lint && yarn tsc --noEmit && yarn test && yarn test:e2e && yarn test:db`.
- [ ] **Step 5: `./scripts/gen-api.sh` + `flutter analyze && flutter test`.**
- [ ] **Step 6: 커밋.** `git commit -m "feat: 인스타 게시물 목록과 대표 게시물 가져오기, 개인 계정 연동 거절"`

---

### Task 4: 앱 — 대표 게시물 화면 (G6)

시안: `M19G6Empty`·`M19G6Full`·`M19G6Sheet`·`M19G6Pick`·`M19G6Personal`(라이트), `DarkM19G6*`(다크). 사진첩 올리기 화면은 기존 캔버스 B6 "새 콘텐츠"에서 분야 꼬리표 줄과 "좋아요를 많이 받은…" 안내를 뺀 것이다(**캔버스 밖**, 설계 7.3).

**Files:**
- Create: `app/lib/features/featured_posts/{domain/{featured_post.dart,featured_posts_repository.dart},data/api_featured_posts_repository.dart,presentation/{featured_posts_text.dart,pages/{featured_posts_page.dart,instagram_pick_page.dart,featured_post_compose_page.dart},viewmodels/{featured_posts_view_model.dart,instagram_pick_view_model.dart},widgets/{post_row.dart,post_sheet.dart,personal_account_notice.dart}}}`
- Modify: `app/lib/core/media/photo_picker.dart`(`pick({int maxSide = 2048, int quality = 85})` — `image_picker`의 `maxWidth/maxHeight/imageQuality`), `app/lib/core/network/photo_uploader.dart`(`PhotoPurpose.featuredPost`), `app/lib/core/navigation/{app_routes,app_router}.dart`(`AppRoutes.creatorFeaturedPosts='/creator/featured-posts'`, `creatorFeaturedPostsPick`, `creatorFeaturedPostsCompose`), `app/lib/features/creator_profile/presentation/pages/creator_profile_setup_page.dart`(카드 사진·한 줄 입력을 `대표 게시물 {n} / 4` 줄로 바꿔 위 화면으로 연결, 저장 때 `cardHeadline`·`cardPhotoPath`를 보내지 않는다), `app/lib/features/store_browse/presentation/widgets/creator_bottom_nav.dart`(`프로필` 탭 → `creatorFeaturedPosts`, 지금의 "준비 중" 대신 — Ruling 2), `app/lib/features/instagram_connect/presentation/pages/instagram_connect_page.dart`(서버가 준 개인 계정 문구는 이미 `value.error`로 보인다), `app/test/support/pump_cora_app.dart`(가짜 저장소 끼우기)
- Test: `app/test/features/featured_posts/{featured_posts_page_test,instagram_pick_page_test,featured_post_compose_page_test,api_featured_posts_repository_test,fake_featured_posts_repository}.dart`

**Interfaces:**
- Consumes: T2·T3의 생성 클라이언트(`CreatorsApi.getMyFeaturedPosts/replaceMyFeaturedPosts`, `InstagramApi.listInstagramPosts/importInstagramPosts`), `InstagramRepository.fetch()`(연결 여부), `PhotoPicker`, `PhotoUploader`.
- Produces: `FeaturedPost { id: String?; position; source: FeaturedPostSource; kind: FeaturedPostKind; photoUrl; caption; instagramMediaId?; draftPath?(아직 서버 행이 아님) }`; `FeaturedPostsRepository { fetchMine(); replaceMine(List<FeaturedPost>); listInstagramPosts(); importInstagram(List<String> postIds) }`; `featuredPostsViewModelProvider`(AsyncNotifier, 상태 `FeaturedPostsState { items, original, instagramConnected }`, 메서드 `addAll`, `replaceAt(i, post)`, `moveToFront(i)`, `removeAt(i)`, `reorder(old, new)`, `save()`, `dirty` getter). 문구는 설계 7장·캔버스 그대로(`대표 게시물`, `가게 사장님에게 가장 먼저 보여요. 최대 4개, 언제든 바꿀 수 있어요.`, `대표 게시물 1개만 있어도 지원할 수 있어요.`, `인스타에서 고르기`, `사진첩에서 올리기`, `꾹 눌러 끌면 순서를 바꿀 수 있어요`, `저장하기`, 시트 `{n}번 게시물`·`다른 게시물로 바꾸거나 순서를 옮겨요.`·`인스타에서 골라 교체`·`사진첩에서 골라 교체`·`맨 앞으로 보내기`·`대표 게시물에서 빼기`, 고르기 `인스타그램에서 가져오기`·`@{아이디} 계정의 게시물이에요.`·`대표 게시물로 보여줄 것만 골라요. 최대 4개예요.`·`{n} / 4개 고름`·`고른 순서대로 보여줘요`·`대표 게시물에 추가`, 개인 계정 `개인 계정은 조회수 수당을 받을 수 없어요. 사진첩에서 올린 게시물은 대표 게시물로만 보여요.`·`프로페셔널 계정으로 바꾸는 방법`). **캔버스 밖**: `대표 게시물은 4개까지예요. {n}개만 더 고를 수 있어요.`(5번째를 누를 때), `바꾼 내용을 저장할까요?`(나갈 때 바뀐 것이 있으면), 프로페셔널 계정 방법 안내 시트(인스타그램 앱 → 설정 → 계정 유형 → 프로페셔널 계정으로 전환), 사진첩 올리기의 한 줄 설명 입력 문구.

- [ ] **Step 1: 시험을 쓴다.** 페이지: `it('shows four empty numbered slots and both source buttons when empty')`, `it('shows the counter 4 / 4 and the reorder hint when full')`, `it('moves a post to the front from the sheet and keeps numbers 1..n')`, `it('removes a post from the sheet and renumbers')`, `it('does not save until 저장하기 and sends the whole list once')`, `it('asks to save changes when leaving a dirty list')`, `it('shows the personal-account notices when instagram is not connected')`(두 안내와 방법 링크), `it('opens the connect screen instead of the picker when not connected')`, `it('does not overflow at 1.3x text scale and paints the dark tokens')`. 고르기: `it('numbers picks in the order tapped and disables the add button at zero')`, `it('blocks the fifth pick with the limit sentence')`, `it('marks already featured posts as 가져옴 and not selectable')`, `it('adds the imported drafts to the list without saving')`. 사진첩: `it('requires a one-line caption of up to 40 characters')`, `it('uploads the resized photo with the featuredPost purpose')`. 저장소: 라우트·본문 모양.
- [ ] **Step 2: 실행해 실패를 본다.** `cd app && flutter test test/features/featured_posts` → FAIL.
- [ ] **Step 3: 구현.** 순서 바꾸기는 `ReorderableListView`(긴 눌림으로 끌기). 사진첩 올리기는 `PhotoPicker.pick()`(줄인 사진) → `PhotoUploader.upload(purpose: featuredPost)` → 한 줄 설명을 받는 새 화면 → 목록에 임시 항목으로 추가. 모든 색·모양은 토큰에서, 라이트·다크 모두 캔버스와 같게.
- [ ] **Step 4: 통과를 본다.** `cd app && flutter analyze && flutter test`.
- [ ] **Step 5: 시뮬레이터 확인.** 서버를 다른 포트로 띄우고(`PORT=3011`, 3000은 끄지 않는다) `yarn seed:dev` 계정 0003으로 로그인, 다섯 화면(비어 있음·4개·시트·인스타 고르기·개인 계정)을 라이트·다크로 찍어 `shots/task4/`에 저장한다. 인스타 연동은 가짜 승인(`@min.closet`), 개인 계정 시험은 코드 `personal_x`.
- [ ] **Step 6: 커밋.** `git commit -m "feat: 크리에이터 대표 게시물 화면(인스타 고르기, 사진첩 올리기, 순서·교체)"`

---

### Task 5: 서버 — 사장님 전체 둘러보기(카드·결정·되돌리기·넘김 이유)

**Files:**
- Modify: `api/prisma/schema.prisma`(`RecommendationScope`에 `STORE`) + 새 마이그레이션 `…_recommendation_scope_store`(`ALTER TYPE "recommendation_scope" ADD VALUE 'STORE';` 한 줄만, 같은 마이그레이션에서 새 값을 쓰지 않는다), `api/src/recommendations/{recommendations.service,recommendations.repository,recommendations.controller}.ts`(`findDecision`의 `campaignId`를 `string | null`로), `api/src/recommendations/dto/recommendation-cards.model.ts`, `api/src/discovery/{discovery.service,discovery.controller}.ts`, `api/src/creators/creators.service.ts`(`getSummaries`로 분야·팔로워·지역), 서버가 사람에게 보이는 "관심" 오류 문구(`discovery.service.ts`:115·227·271·750 → "하트")와 OpenAPI 설명
- Test: `recommendations.service.spec.ts`, `discovery.service.spec.ts`, `api/test/{recommendations,discovery}.e2e-spec.ts`, `api/test/db/discovery-schema.db-spec.ts`

**Interfaces:**
- Produces 라우트: `GET /recommendations/store-creators`(`listStoreCreators`, 역할 `STORE`만) → `StoreCreatorRecommendationsModel { day: string; total: number; cards: StoreCreatorCardModel[] }`; `StoreCreatorCardModel { creatorId; displayName; contentFocus: string|null; followers: number|null; headline: string|null; photoUrl: string|null; posts: FeaturedPostModel[]; tags: string[] }`(꼬리표는 협업 원칙이 있으면 `principleTags`, 없으면 빈 배열 — 협업 원칙이 없어도 나온다).
- Modify: `DiscoveryService.decide`에 `STORE → storeDecide(userId, input)`(`targetKind`는 `CREATOR`만, 결정 키 `{ actorId, targetKind:'CREATOR', targetId, campaignId:null }`, `VisibilityService.creatorVisibleTo(creatorId, { userId: store.ownerId, kind:'STORE', industry: store.industry })`가 거짓이면 404, 하트에 `note`가 없어도 1번 게시물 사본(`content_title`·`content_photo_path`)을 남긴다 — Ruling 3), `setPassReason`·`undoLast`의 역할 검사에 `STORE`를 더한다. `undoLast`는 사장님이 하트를 보낸 크리에이터에게 살아 있는 지원이 있으면(서로 관심) 되돌릴 수 없어 409 "되돌릴 수 없어요."(문구는 4번의 `undoTooLate` 응답과 같은 코드).
- Rule: 사장님 하루 목록은 `daily_recommendations(scope='STORE', campaign_id=null)`에 저장(`saveList`). 풀 = `creators.listCardSources()`; 거름 = `visibility.filterCreators`(STORE 시점) → 대표 게시물 1개 이상 → 5장 제외(차단은 `filterCreators`가, 끝나지 않은 협업이 있는 상대 제외) → 내가 결정한 사람(`LIKE`·`PASS`·`HOLD` 전부 — 저장한 사람은 저장함에 있으므로 덱에서 뺀다. 계획 Ruling 4); 순서 = 지원한 사람(`APPLIED`·`OFFERED`) → `regionTier` 0 → 1 → 2 → 최근 가입순, `DAILY_CARD_COUNT = 10`.

- [ ] **Step 1: 시험을 쓴다.** 규칙·서비스: `it('lists at most ten creators and puts applicants first, then same district, then same province')`, `it('hides creators who avoid the store industry')`, `it('hides creators without a featured post')`, `it('keeps creators without collaboration principles')`, `it('drops creators already liked, saved or passed')`, `it('keeps the same list for the same day and refills at midnight KST')`(FakeClock), `it('records a store heart with campaign null and the first post copy')`, `it('replaces a saved decision with a heart and leaves one row')`, `it('creates no match or collaboration for a store heart')`, `it('refuses to undo a heart on a creator who applied')`, `it('refuses a store decision on a hidden creator with 404')`. e2e: 가게 계정만(브랜드·크리에이터 403), 다른 가게의 결정이 보이지 않음, `PUT /discovery/decisions`가 사장님에게 200. db: 부분 유니크(`campaign_id IS NULL`)로 같은 가게·크리에이터 두 번째 행이 막힘.
- [ ] **Step 2: 실행해 실패를 본다.** `source ~/.nvm/nvm.sh && cd api && nvm use && yarn test recommendations discovery` → FAIL.
- [ ] **Step 3: 구현.** 마이그레이션 → 서비스 → 컨트롤러 → 오류 문구. `DiscoveryRepository.listSavedDecisions`는 그대로 쓴다.
- [ ] **Step 4: 통과를 본다.** `yarn lint && yarn tsc --noEmit && yarn test && yarn test:db && yarn test:e2e`.
- [ ] **Step 5: `./scripts/gen-api.sh` + `cd app && flutter analyze && flutter test`.**
- [ ] **Step 6: 커밋.** `git commit -m "feat: 사장님 전체 둘러보기 카드와 결정·되돌리기·넘김 이유"`

---

### Task 6: 서버 — 사장님 저장함과 서로 관심

**Files:**
- Create: `api/src/discovery/store-interests.service.ts`(+`.spec.ts`), `api/src/discovery/dto/store-interest.model.ts`
- Modify: `api/src/discovery/{discovery.controller,discovery.module}.ts`, `api/src/discovery/discovery.service.ts`(하트 직후 서로 관심 검사·알림), `api/src/applications/{applications.service,applications.repository}.ts`(`listLiveCreatorIds(storeId): Promise<Set<string>>` — `APPLIED`+`OFFERED`; `apply()`가 사장님이 이미 하트를 보낸 크리에이터면 알림), `api/src/notifications/notification-catalog.ts`(`NotificationTarget.kind`에 `STORE_INTERESTS`·`STORE_DETAIL` 더하기, 새 enum 값 없음 — `MUTUAL_INTEREST` 재사용), 앱 `notification_routes.dart`는 T11에서
- Test: `store-interests.service.spec.ts`, `discovery.service.spec.ts`, `applications.service.spec.ts`, `api/test/{discovery,applications}.e2e-spec.ts`

**Interfaces:**
- Produces 라우트: `GET /discovery/store-interests?tab=saved|sent`(`listStoreInterests`, 역할 `STORE`만) → `StoreInterestCardModel[] { creatorId; name; shortName; contentFocus: string|null; followers: number|null; photoUrl: string|null; mutual: boolean }`. `saved` = `HOLD`, `sent` = `LIKE`(`mutual` = 그 크리에이터가 이 가게에 살아 있는 지원을 가짐), 최근 결정순. 사장님의 "보낸 제안"은 새 라우트 없이 기존 `GET /offers/proposals?tab=active`(`ProposalsService.list`)를 앱이 쓴다.
- Rule: 서로 관심은 두 곳에서 한 번만 알린다 — 사장님이 하트를 보낼 때 그 크리에이터가 이미 지원 중이면, 크리에이터가 지원할 때 그 가게가 이미 하트를 보냈으면. 둘 다 양쪽에 `MUTUAL_INTEREST` 알림(`dedupeKey: 'store-mutual:'+storeId+':'+creatorId`), 사장님 쪽 `target: { kind:'STORE_INTERESTS', id:null }`, 크리에이터 쪽 `target: { kind:'STORE_DETAIL', id: storeId }`. 가게의 `matches`·협업·대화방은 만들지 않는다.

- [ ] **Step 1: 시험을 쓴다.** `it('lists saved and sent creators for the store only')`, `it('marks a sent creator as mutual when the creator applied')`, `it('notifies both sides once when a heart meets an existing application')`, `it('notifies both sides once when an application meets an existing heart')`, `it('does not notify twice when the heart is repeated')`, `it('never creates a match, collaboration or conversation')`, `it('hides creators the store may not see')`. e2e: 가게 계정만, 크리에이터 알림함에 `MUTUAL_INTEREST`가 한 번.
- [ ] **Step 2: 실행해 실패를 본다.** `yarn test store-interests discovery applications` → FAIL.
- [ ] **Step 3: 구현.**
- [ ] **Step 4: 통과를 본다.** `yarn lint && yarn tsc --noEmit && yarn test && yarn test:db && yarn test:e2e`.
- [ ] **Step 5: `./scripts/gen-api.sh` + `cd app && flutter analyze && flutter test`.**
- [ ] **Step 6: 커밋.** `git commit -m "feat: 사장님 저장함 목록과 하트·지원이 만나는 서로 관심 알림"`

---

### Task 7: 서버 — 사장님 홈 추천 3명(지원자 중 / 전체 중)

**Files:**
- Modify: `api/src/applications/{applications.service,applications.controller}.ts`, `api/src/applications/dto/recommended-applicants.model.ts`, `api/src/applications/recommendation.ts`(전체 풀용 입력)
- Test: `applications.service.spec.ts`, `recommendation.spec.ts`, `api/test/applications.e2e-spec.ts`

**Interfaces:**
- Modify: `GET /stores/me/applications/recommended`(`listRecommendedApplicants`)의 응답 `RecommendedApplicantsModel { source: 'APPLICANTS'|'ALL'; totalNew: number; items: RecommendedApplicantModel[] }`, `RecommendedApplicantModel { applicationId: string|null; creator: CreatorSummaryModel; appliedAt: string|null; pitch: string|null; reasons: string[] }`(`CreatorSummaryModel`은 `followers`·`contentFocus`를 이미 가진다).
- Rule: 살아 있는 지원자(`APPLIED`)가 있으면 `source = APPLICANTS`, 점수 높은 순 최대 3명(가게 흐름 개정 G2 점수 그대로, **`skippedFromPicksAt` 제외는 이 응답에서 없앤다**: 한 장씩 보는 화면이 없어진다 — Ruling 5). 없으면 `source = ALL`: 풀 = Cora 크리에이터 전체 → `visibility.filterCreators`(STORE) → 이미 지원·오퍼 중이거나 끝나지 않은 협업이 있는 사람 제외 → 대표 게시물 1개 이상 → `scoreApplicant`로 정렬(`hasPitch` = 대표 게시물 한 줄 유무, 같으면 최근 가입순) 최대 3명, `applicationId`·`appliedAt`은 null. 같은 날 같은 가게는 같은 결과(정렬이 결정적이라 별도 시드 없음).

- [ ] **Step 1: 시험을 쓴다.** `it('picks up to three live applicants by score when there are applicants')`, `it('ignores the old skipped-from-picks mark')`, `it('falls back to all creators when nobody applied')`, `it('excludes creators who avoid the store industry, have no featured post, or already have an open offer')`, `it('returns fewer than three when fewer exist')`, `it('is stable across calls on the same day')`.
- [ ] **Step 2~4: 실패 확인 → 구현 → 통과** (`yarn test applications && yarn lint && yarn tsc --noEmit && yarn test:e2e`).
- [ ] **Step 5: `./scripts/gen-api.sh` + 앱 data 계층 최소 수정(`api_applicant_picks_repository.dart`)** 후 `flutter analyze && flutter test`.
- [ ] **Step 6: 커밋.** `git commit -m "feat: 사장님 홈 추천 3명을 지원자가 없으면 전체 크리에이터에서 뽑음"`

---

### Task 8: 앱 — 사장님 전체 둘러보기와 대표 게시물 카드 (G1·G4)

시안: `M19G1Swipe`·`M19G1Heart`·`M19G1Save`·`M19G1Pass`(사장님 머리와 카드), `DarkM19G1*`.

**Files:**
- Create: `app/lib/features/store_discover/{domain/{store_creator_card.dart,store_discover_repository.dart},data/api_store_discover_repository.dart,presentation/{store_discover_text.dart,pages/store_discover_page.dart,viewmodels/store_discover_view_model.dart,widgets/{store_discover_header.dart,featured_post_card.dart}}}`
- Modify: `app/lib/features/discovery/presentation/widgets/{creator_swipe_card,swipe_progress_bar}.dart`(`SwipeProgressBar({segments, current})`), `app/lib/features/discovery/domain/discovery_card.dart`(`CreatorCard.posts: List<FeaturedPostRef>`), `app/lib/core/ui/cora_bottom_nav.dart` 없음, `app/lib/features/store_home/presentation/pages/store_home_page.dart`(`찾기` → 새 화면), `app/lib/core/navigation/{app_routes,app_router}.dart`(`AppRoutes.storeDiscover='/store/discover'`), `app/test/support/pump_cora_app.dart`
- Test: `app/test/features/store_discover/{store_discover_page_test,api_store_discover_repository_test,fake_store_discover_repository,featured_post_card_test}.dart`, 홈 시험의 `bottom menu > find…` 줄 수정

**Interfaces:**
- Consumes: T5 `GET /recommendations/store-creators`, `PUT /discovery/decisions`(`targetKind: CREATOR`), `PUT /discovery/decisions/pass-reason`, `DELETE /discovery/decisions/last`; T1의 `SwipeActionButtons`·`DiscoveryToastBanner`·`showPassReasonSheet`·`CoraStateView.allSeen`.
- Produces: `StoreCreatorCard { creatorId; displayName; contentFocus?; followers?; headline?; photoUrl?; posts: List<FeaturedPostRef>; tags }`; `FeaturedPostCard({required StoreCreatorCard card})`(대표 게시물 사진 + 위 진행 막대 + 왼쪽 위 `대표 게시물 {i} / {n}` + 아래 글, 카드의 오른쪽 절반 탭 = 다음 게시물·왼쪽 절반 = 이전, 게시물이 하나면 막대 한 칸); 브랜드 `CreatorSwipeCard`도 `posts`가 있으면 같은 뷰어를 쓴다(없으면 지금처럼 사진 한 장). `StoreDiscoverRepository { fetchCards(); decide(creatorId, SwipeOutcome); setPassReason(creatorId, PassReason); undoLast() }`. 머리: 뒤로, 가운데 `전체 둘러보기`, 오른쪽 북마크 아이콘 + 저장 수 배지(`StoreInterestsRepository`의 저장 수 — T9 전에는 0으로 두고 T9가 채운다). 카드 글: 활동 이름(작게)·한 줄(큰 글자, 최대 2줄)·`{분야} · 팔로워 {n}`(형광)·꼬리표. 서로 관심 토스트는 사장님에게 오지 않는다(하트 응답에 `matched`가 없다). 토스트 이동: `보낸 관심`·`저장함`은 T9의 사장님 저장함 라우트(`AppRoutes.storeInterests?tab=sent|saved`)로, 그 전에는 상수만 정의해 둔다(T9가 라우트를 등록).

- [ ] **Step 1: 시험을 쓴다.** `it('shows the first post with the progress bar and 대표 게시물 1 / 4')`, `it('goes to the next and previous post by tapping the right and left halves')`, `it('keeps swiping decisions on horizontal drags, not on post taps')`, `it('sends LIKE for a right swipe and HOLD for an upward swipe')`, `it('shows the heart toast with 보낸 관심 and the save toast with 저장함')`, `it('opens the pass-reason sheet only from the 이유 남기기 action')`, `it('shows 오늘 추천을 모두 봤어요 with 저장한 후보 보기 when the deck ends')`, `it('undoes the last decision and puts the card back')`, `it('opens this screen from the 찾기 menu')`, `it('does not overflow at 1.3x text scale and uses dark tokens')`.
- [ ] **Step 2: 실행해 실패를 본다.** `cd app && flutter test test/features/store_discover` → FAIL.
- [ ] **Step 3: 구현.** `SwipeDeck`의 `onTap`은 카드 전체 탭 하나뿐이므로 게시물 넘기기는 카드 안에서 `GestureDetector(onTapUp)`로 좌우 절반을 가른다(밀기와 겹치지 않게 짧은 탭만).
- [ ] **Step 4: 통과를 본다.** `cd app && flutter analyze && flutter test`.
- [ ] **Step 5: 시뮬레이터 확인(라이트·다크)** — 기본·하트·저장·넘김 이유 시트 네 장을 `shots/task8/`에. 서버는 `PORT=3011`, 계정 0001(가게). 시드 크리에이터에 대표 게시물이 있어야 한다.
- [ ] **Step 6: 커밋.** `git commit -m "feat: 사장님 전체 둘러보기와 대표 게시물을 넘겨 보는 카드"`

---

### Task 9: 앱 — 저장함 탭 (G2)

시안: `M19G2TabsB`(`M19G2TabsA`는 만들지 않는다), `DarkM19G2Tabs*`.

**Files:**
- Create: `app/lib/features/store_interests/{domain/{store_interest.dart,store_interests_repository.dart},data/api_store_interests_repository.dart,presentation/{store_interests_text.dart,pages/store_interests_page.dart,viewmodels/store_interests_view_model.dart}}`
- Modify: `app/lib/features/interests/presentation/{interests_text.dart,pages/interests_page.dart,viewmodels/interests_view_model.dart,widgets/{interest_tabs,interest_grid_card}.dart}`(브랜드·크리에이터: 탭 3개/2개), `app/lib/core/navigation/{app_routes,app_router}.dart`(`AppRoutes.storeInterests='/store/interests'`, 쿼리 `?tab=saved|sent|offers`), `app/lib/features/store_discover/…`(머리 배지에 저장 수), `app/test/support/pump_cora_app.dart`
- Test: `app/test/features/store_interests/*`, 고치는 기존 시험: `app/test/features/interests/{interests_page_test,interests_routing_test,compare_page_test}.dart`, `received_proposal_page_test.dart:153,174,297,366`, `store_browse_pages_test.dart:122`(제목·탭 글자)

**Interfaces:**
- Consumes: T6 `GET /discovery/store-interests?tab=`, 기존 `GET /offers/proposals?tab=active`(`ProposalRowModel`), T1 토스트 경로.
- Produces(사장님): `StoreInterestsPage({initialTab})`, 탭 `저장 {n}` / `보낸 관심 {n}` / `보낸 제안 {n}`, 머리 `저장함`, 설명 `저장은 나만 보고, 하트는 상대에게 전해져요.`, 목록 줄(캔버스: 이름 첫 글자 동그라미·이름·표지·`{분야}, 팔로워 {n}명`·버튼, `CoraListRow`를 쓰되 캔버스와 맞지 않으면 새 위젯): 저장 줄은 `제안하기`(형광) → `AppRoutes.storeOfferNew(creatorId)`(받는 사람이 채워진 A5, `SendOfferArgs`), 보낸 관심 줄은 `서로 관심` 표지 + `제안하기` / `응답 대기` 표지 + `프로필`(약한 색), 보낸 제안 줄은 `응답할 차례`면 `역제안 · 판본 {n} · {형식} {편 수}편` + `응답하기`(형광), 아니면 `판본 {n} · {형식} {편 수}편 · {n}일 안에 답이 와요` + `대기` 표지, 누르면 `AppRoutes.storeProposal(offerId)`. 줄을 누르면 크리에이터 카드 상세(4번의 `creator_card_detail_page`). 탭이 비면 설계 4.3의 빈 문구(**캔버스 밖**).
- Produces(브랜드·크리에이터): `InterestTab { saved, sent, proposals }`로 바꾼다 — 서버 값(`saved` 한 번 읽기)은 그대로 읽고 앱이 `saved` = 상태 `held`, `sent` = `waiting`+`mutual`(표지 `서로 관심`/`응답 대기`), `proposals`는 브랜드만(F3 브랜드 줄 — 5번 계획의 같은 서비스, `ProposalParty`에 브랜드가 있으면 그것을 쓰고 없으면 `ProposalsPage`가 쓰는 같은 저장소를 쓴다). 크리에이터는 `saved`/`sent` 두 탭. 제목 `저장함`, 설명은 설계 4.3. 브랜드의 비교 체크는 저장·보낸 관심 카드에 그대로, `서로 관심` 카드는 `협업 조건 확인`(06) 그대로. 옛 `서로 관심`·`보류` 탭과 `InterestState` 이름은 코드에서 유지(탭만 바뀐다). 토스트 `저장함`은 `?tab=saved`, `보낸 관심`은 `?tab=sent`.

- [ ] **Step 1: 시험을 쓴다.** 사장님: `it('shows three tabs with counts: 저장, 보낸 관심, 보낸 제안')`, `it('lists only saved creators in the first tab with a 제안하기 button')`, `it('marks a mutual row with 서로 관심 and a waiting row with 응답 대기 and 프로필')`, `it('shows 응답하기 for a counter proposal on my turn and 대기 otherwise')`, `it('opens the offer form with the creator as receiver')`, `it('shows the empty sentence per tab')`, `it('does not overflow at 1.3x and uses dark tokens')`. 브랜드·크리에이터: `it('brand tabs are 저장, 보낸 관심, 보낸 제안 and the saved tab holds only saved cards')`, `it('creator tabs are 저장 and 보낸 관심')`, `it('keeps the compare checks on the brand cards')`, 기존 탭 글자 시험을 새 글자로.
- [ ] **Step 2: 실행해 실패를 본다.** `cd app && flutter test test/features/store_interests test/features/interests` → FAIL.
- [ ] **Step 3: 구현.** 사장님 하단 메뉴에는 `저장함`이 없으므로 진입은 둘러보기 머리의 북마크와 토스트·F8 `저장한 후보 보기`다(`AppRoutes.storeInterests`).
- [ ] **Step 4: 통과를 본다.** `cd app && flutter analyze && flutter test`.
- [ ] **Step 5: 시뮬레이터 확인(라이트·다크)** — 사장님 저장함 세 탭, 브랜드 03 세 탭을 `shots/task9/`에.
- [ ] **Step 6: 커밋.** `git commit -m "feat: 저장함 탭을 저장, 보낸 관심, 보낸 제안으로 바꾸고 사장님 저장함을 만듦"`

---

### Task 10: 앱 — 이상형 월드컵 (G3)

시안: `M19G3Banner`·`M19G3Count`·`M19G3Match`·`M19G3Result`(`M19G3Interrupt`는 만들지 않는다), `DarkM19G3*`.

**Files:**
- Create: `app/lib/features/world_cup/{domain/{world_cup_round.dart,world_cup_bracket.dart},presentation/{world_cup_text.dart,pages/{world_cup_match_page.dart,world_cup_result_page.dart},viewmodels/world_cup_view_model.dart,widgets/{world_cup_banner.dart,world_cup_count_sheet.dart}}}`
- Modify: `app/lib/features/store_interests/presentation/pages/store_interests_page.dart`, `app/lib/features/interests/presentation/pages/interests_page.dart`(브랜드만), `app/lib/core/navigation/{app_routes,app_router}.dart`(`AppRoutes.worldCupMatch`·`worldCupResult`, 상태는 `extra`)
- Test: `app/test/features/world_cup/{world_cup_bracket_test,world_cup_banner_test,world_cup_count_sheet_test,world_cup_match_page_test,world_cup_result_page_test}.dart`

**Interfaces:**
- Produces(순수 도메인): `class WorldCupBracket<T> { WorldCupBracket.start(List<T> saved, {required int size, required Random random}); int get size; String get roundLabel; /* "4강 · 1 / 2" */ ({T a, T b}) get match; void pick(T winner); bool get finished; T get champion; List<T> get semifinalists; /* 우승자 뺀 4강 진출자 */ }`. `size`는 `4` 또는 `8`이고 `saved.length >= size`여야 하며 아니면 `ArgumentError`. 단계 글자: 8강 `8강 · {i} / 4`, 4강 `4강 · {i} / 2`, 결승 `결승 · 1 / 1`(**캔버스 밖**). `WorldCupText`는 캔버스 글자 그대로(`이상형 월드컵`, `저장한 {n}명 중 한 명을 골라요`, `월드컵 하기`, `몇 강으로 할까요?`, `저장한 {n}명 중에서 골라요. 우승한 분께 바로 제안할 수 있어요.`, `4강`/`4명이 겨뤄요`/`8강`/`8명이 겨뤄요`, `시작하기`, `닫기`, `그만하기`, `더 마음에 드는 분을 골라요.`, `저장 {n}번째`, `이거보다 좋아`, `VS`, `이상형 1위`, `4강까지 올랐던 후보`, `다시 하기`, `제안하기`).
- Consumes: 저장 탭의 카드 목록(사장님 `StoreInterestCard`, 브랜드 `InterestCard`)을 `WorldCupCandidate { id; name; headline?; photoUrl?; meta; savedOrder }`로 바꾸는 어댑터를 각 저장함 쪽에 둔다. `제안하기`는 사장님 `storeOfferNew(creatorId)`, 브랜드 F1 진입(`RewardProposalEntry`)을 연다.

- [ ] **Step 1: 시험을 쓴다.** 순수: `it('plays four candidates in two semifinals and a final and ends with one champion')`, `it('plays eight candidates in four quarterfinals first')`, `it('labels rounds 8강 · 1 / 4, 4강 · 1 / 2 and 결승 · 1 / 1')`, `it('draws exactly size candidates at random from a larger saved list')`(고정 `Random(seed)`), `it('throws when fewer saved than size')`, `it('lists the semifinalists except the champion')`. 위젯: `it('shows the banner only with four or more saved')`, `it('disables 8강 below eight saved and enables 시작하기 after a choice')`, `it('moves to the next match when a card is chosen and 그만하기 returns without saving')`, `it('shows 이상형 1위 with 다시 하기 and 제안하기')`, `it('writes nothing to the server')`(가짜 저장소의 쓰기 호출 0), 1.3배·다크.
- [ ] **Step 2: 실행해 실패를 본다.** `cd app && flutter test test/features/world_cup` → FAIL.
- [ ] **Step 3: 구현.** `Random`은 주입(시험은 고정 시드). 대결 카드는 대표 게시물 1번 사진·활동 이름·한 줄·`{분야} · 팔로워 {n}`.
- [ ] **Step 4: 통과를 본다.** `cd app && flutter analyze && flutter test`.
- [ ] **Step 5: 시뮬레이터 확인(라이트·다크)** — 배너, 몇 강 시트, 대결, 결과를 `shots/task10/`에. 저장 8명이 필요하므로 시드 계정으로 서버 8명을 저장해 둔다(010-0000-0900 이후 시험 계정 사용).
- [ ] **Step 6: 커밋.** `git commit -m "feat: 저장한 후보로 하는 이상형 월드컵(4강·8강, 우승자에게 제안하기)"`

---

### Task 11: 앱 — 사장님 첫 화면 (G4)

시안: `M19G4Applied`·`M19G4Empty`, `DarkM19G4*`.

**Files:**
- Modify: `app/lib/features/store_home/presentation/pages/store_home_page.dart`(구성을 캔버스대로: 머리 → `크리에이터 모집` 상자 → 지원 있음/없음 → `추천 3명` → `마음에 드는 분이 없나요?` + `전체 둘러보기`; 조건부 체험단 줄은 2번과 3번 사이에 남김), `app/lib/features/store_home/presentation/{store_home_text.dart,viewmodels/store_home_view_model.dart}`, `app/lib/features/applicant_picks/data/api_applicant_picks_repository.dart`·`domain/applicant_pick.dart`(새 응답 `source`·`appliedAt`·`followers`), `app/lib/features/notifications/presentation/notification_routes.dart`(`STORE_APPLICANTS` → `/store/applicants`, `STORE_SENT_OFFERS` → 오퍼 탭 `/store/proposals`, `STORE_INTERESTS` → `/store/interests?tab=sent`, 크리에이터의 `STORE_DETAIL` → `/creator/stores/{id}`), `app/lib/core/navigation/{app_routes,app_router}.dart`(`AppRoutes.storeApplicants='/store/applicants'`), `홈` 메뉴 동작(`navHome`은 맨 위로)
- Create: `app/lib/features/store_home/presentation/pages/store_applicants_page.dart`(기존 홈의 지원자 탭을 전체 화면으로 뗀 것, `지원자 보기`), `.../widgets/recruit_box.dart`
- Test: `app/test/features/store_home/*` 수정(아래 목록), `app/test/features/notifications/{notification_text_test,notifications_page_test}.dart`(`/store?tab=…` 문자열), `app/test/features/applicant_picks/*`

**Interfaces:**
- Consumes: T7 `RecommendedApplicantsModel`, T8 `storeDiscover` 라우트, 기존 `StoreHomeSummary.newApplications`.
- Produces: 홈 문구 상수 — `크리에이터 모집`, `고치기`(→ `AppRoutes.storeOnboardingTerms` 모집 조건 F1), `{n} 새 지원`+`지원자 보기`, `아직 지원이 없어요`·`새 지원이 오면 알려드려요`, `추천 3명`, `지원한 {n}명 중 가게와 잘 맞는 3명이에요.`, `Cora 크리에이터 중 가게와 잘 맞는 3명이에요.`, 표지 `지원`, 설명 `{분야}, {오늘/어제/n일 전} 지원`(`appliedAgo`)·`{분야} 팔로워 {n}`, 버튼 `제안하기`(→ `storeOfferNew(creatorId)`), `마음에 드는 분이 없나요?`, `전체 둘러보기`. 공개 전 가게는 `모집 조건을 정하고 공개해요`와 `모집 조건 정하기` 버튼, 추천 없음(**캔버스 밖**). 숫자 세 칸·탭 둘·바로가기 둘은 없앤다. `StoreHomeTab` enum은 지우지 않는다(알림이 쓰던 경로가 새 라우트로 바뀌므로 쓰임이 없으면 이 작업 끝에서 삭제).

- [ ] **Step 1: 시험을 쓴다.** `it('shows the recruit box with the reward line and a fix button that opens the terms screen')`, `it('shows the new-applications row and three applicants with 지원 chips when applicants exist')`, `it('shows 아직 지원이 없어요 and three Cora creators without chips when nobody applied')`, `it('opens the offer form with the creator from 제안하기')`, `it('opens 전체 둘러보기 from the button and from the 찾기 menu')`, `it('keeps the trial banner between the recruit box and the picks when it applies')`, `it('shows the unpublished state with 모집 조건 정하기')`, `it('has no count tiles, tabs or shortcuts anymore')`, 알림 시험: `it('routes applicant notifications to the applicants screen and sent-offer notifications to the offers tab')`, 지원자 화면: `it('lists applicants with 오퍼 보내기')`. 기존 홈 시험 `shows the three counts`·`lists the applicants…`·`shows the shared empty state on each tab`·`A9 …` 네 줄·`bottom menu > find…`는 새 구성에 맞게 고치거나 지운다.
- [ ] **Step 2: 실행해 실패를 본다.** `cd app && flutter test test/features/store_home test/features/notifications test/features/applicant_picks` → FAIL.
- [ ] **Step 3: 구현.** 한 장씩 보는 `ApplicantPicksPage`는 진입점이 사라지므로 **라우트와 화면 코드는 이 작업에서 지우지 않는다**(T13에서 정리). `ApplicantPicksPage._openList`가 `/store?tab=applicants`로 가던 경로는 새 `/store/applicants`로 고친다.
- [ ] **Step 4: 통과를 본다.** `cd app && flutter analyze && flutter test`.
- [ ] **Step 5: 시뮬레이터 확인(라이트·다크)** — 지원 있음·없음 두 상태를 `shots/task11/`에(두 상태 모두 시드·시험 계정으로 만든다).
- [ ] **Step 6: 커밋.** `git commit -m "feat: 사장님 첫 화면을 크리에이터 모집, 추천 3명, 전체 둘러보기로 바꿈"`

---

### Task 12: 앱 — 가게 소개 화면 A3 (G5)

시안: `M19G5Before`·`M19G5After`, `DarkM19G5*`.

**Files:**
- Modify: `app/lib/features/store_onboarding/presentation/pages/store_page_preview_page.dart`(사진 `SizedBox(height: 300)`(:424) → `256`과 주석, 아래 `Row`(:171) → `Column(spacing: 8)`: `크리에이터 모집`(`CoraPrimaryButton`, accent, 높이 58) 위, `AI로 직접 제작`(`CoraSecondaryButton`, subtle, 높이 52) 아래, 좌우 16·아래 32 그대로), `app/lib/core/ui/cora_primary_button.dart`·`cora_secondary_button.dart`(높이 인자가 없으면 `height` 선택 인자 추가, 기본값 그대로)
- Test: `app/test/features/store_onboarding/store_page_preview_page_test.dart`

- [ ] **Step 1: 시험을 쓴다.** `it('puts 크리에이터 모집 above AI로 직접 제작 in a column')`(`tester.getTopLeft`로 y 비교, 가로 폭이 같음), `it('keeps the cover photo at 256 high')`, `it('keeps both buttons at 58 and 52 high')`, 기존 `A3 offers AI drafts and creator recruiting`·두 이동 시험이 그대로 통과, 1.3배 글자 넘침 없음, 다크.
- [ ] **Step 2: 실행해 실패를 본다.** `cd app && flutter test test/features/store_onboarding/store_page_preview_page_test.dart` → FAIL.
- [ ] **Step 3: 구현.**
- [ ] **Step 4: 통과를 본다.** `cd app && flutter analyze && flutter test`.
- [ ] **Step 5: 시뮬레이터 확인(라이트·다크)** — 등록 중 A3와 홈 아래 가게 페이지 두 곳을 `shots/task12/`에.
- [ ] **Step 6: 커밋.** `git commit -m "feat: 가게 소개 화면의 크리에이터 모집을 위로 올리고 사진을 256으로 줄임"`

---

### Task 13: 전체 확인, 정리, 최종 검토

**Files:**
- Modify(정리): `app/lib/features/applicant_picks/**`·`app/test/features/applicant_picks/**`(진입점이 없는 한 장씩 보는 화면, 라우트 `storeApplicantPicks`; 서버 `POST /stores/me/applications/:id/skip`는 남긴다), 안 쓰는 `StoreHomeTab`, 안 쓰는 옛 문구 상수
- Modify(문서): `docs/superpowers/plans/2026-11-19-meeting-revision.md`의 체크박스, `.superpowers/sdd/2026-11-19-meeting-revision/progress.md`

- [ ] **Step 1: 정리 전에 쓰이는 곳을 확인한다.** `grep -rn "ApplicantPicksPage\|storeApplicantPicks\|StoreHomeTab" app/lib app/test`가 시연 앱 밖에서 이 정리 대상뿐인지 본다. 시연 앱이 쓰면 남긴다.
- [ ] **Step 2: 정리한다.** 위를 지우고 `flutter analyze` 통과.
- [ ] **Step 3: 서버 전체.** `source ~/.nvm/nvm.sh && cd api && nvm use && yarn lint && yarn tsc --noEmit && yarn test && yarn test:db && yarn test:e2e`(다른 세션과 `cora_test`를 같이 쓰지 않는다, 조율 세션에 확인).
- [ ] **Step 4: 앱 전체.** `./scripts/gen-api.sh` 뒤 변화가 없는지(`git status`), `cd app && flutter analyze && flutter test`.
- [ ] **Step 5: 시뮬레이터 통과 확인.** iPhone 15 Pro(A45ED678) 하나로 G1~G6 화면 전부를 라이트·다크로 찍어 캔버스와 대조한 표를 `shots/final/compare.md`에 만든다(다른 점은 "고침 / 캔버스 밖 / 남김"으로 분류).
- [ ] **Step 6: 최종 검토.** 서버·앱을 각각 검토 에이전트가 전체 diff(시작 HEAD 6fcf6f0 → 마지막)로 본다. Critical/Important는 고치고 다시 검토한다.
- [ ] **Step 7: 커밋.** `git commit -m "chore: 회의 반영 계획의 마무리 정리와 최종 확인"` (정리가 있을 때만; 없으면 진행 기록 갱신만)

---

## 이 계획이 하지 않는 것

크레딧·상한 초과, 비딩, 인스타만, 관심 크리에이터의 소식·지난 성과, 가게 자동 수집 범위, AI 게시물 직접 올리기, 월드컵의 끼워 넣기 안, 사진첩 영상 올리기(7번), 7번의 좋아요·릴스 피드·입찰, 시연 앱 고치기, 6번 계획.

## 이 계획이 구체화한 것 (Rulings, 진행 기록 `progress.md`에도 같은 번호로 적는다)

1. 상세 화면·시트의 "관심 보내기" 버튼, 하단 메뉴 "관심", 채팅·받은 제안 문구는 이번에 바꾸지 않는다(캔버스에 없다).
2. 크리에이터 하단 "프로필" 탭은 대표 게시물 화면으로 간다(7번의 B2 자리, 지금은 "준비 중").
3. 사장님의 하트에는 글이 없어도 1번 게시물 사본(`content_title`·`content_photo_path`)을 남긴다(설계 7.5).
4. 사장님 하루 덱에서는 하트·저장·넘김 한 사람을 모두 뺀다(저장한 사람은 저장함에 있다). 4번 규칙(HOLD는 다음 날 다시 후보)과 다르다.
5. 사장님 홈 추천은 옛 "추천에서 넘김" 표시를 무시한다(한 장씩 보는 화면이 없어짐).
6. 개인 계정 안내는 인스타그램이 연동돼 있지 않으면 항상 보인다(서버가 개인 계정 여부를 따로 저장하지 않는다).
7. 브랜드·크리에이터 머리의 저장함 북마크 아이콘(설계 4.1)은 만들지 않는다. 브랜드·크리에이터에서는 토스트의 `저장함`과 하단 메뉴 `관심`으로 들어간다(캔버스에 그 머리가 없다).
