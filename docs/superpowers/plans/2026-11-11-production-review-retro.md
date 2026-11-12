# 제작·검토·회고 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

**Goal:** 계약된 브랜드 협업에서 크리에이터가 기획 방향을 나만 보는 초안으로 정리하다가 브랜드에 검토를 요청하고, 초안을 비공개로 올려 브랜드와 위치별 댓글로 검토하고, 양쪽이 광고 표시를 확인한 뒤 브랜드가 파일 번호가 붙은 그 판본의 게시를 승인하게 한다. 협업이 끝나면 두 종류 모두 양쪽 보관함에 줄이 생기고, 정산이 끝난 협업에는 나만 보는 회고를 남겨 새 제안(F1)으로 잇는다.

**Architecture:** 기획 가이드와 초안은 `collaborations.stage`(`CONTRACTED → GUIDED → REVIEWING → APPROVED`)에 건 조건부 갱신으로 순서를 강제한다. 가이드는 크리에이터의 작업본(`scenes`)과 브랜드에게 보이는 사본(`sharedScenes`)을 따로 두어, "나만 보는 초안 저장"은 작업본만 바꾸고 "브랜드에 검토 요청"만 사본을 만들고 단계를 올린다. 게시 승인은 요청에 실린 판본 번호가 최신일 때만 되고(`STALE_VERSION`), 승인 기록에 파일 번호를 사본으로 남긴다. 초안 파일은 비공개 버킷 `drafts`에 앱이 서버가 발급한 이어 올리기 토큰으로 직접 올리고, 볼 때는 서버가 당사자에게만 1시간짜리 서명 주소를 준다. 협업이 끝나는 모든 길은 `CollaborationEndingsService.onEnded`를 부르고, 이 함수가 순수 규칙으로 양쪽의 보관함 줄을 한 번만 만들고 파일 정리 작업을 등록한다. 회고와 보관함은 작성자 본인의 저장소 조회로만 읽히며 상대에게 가는 응답 모델에는 칸 자체가 없다.

**Tech Stack:** 앞 계획들과 같다. 추가: Supabase Storage의 이어 올리기(TUS) 경로. 앱의 영상 재생과 이어 올리기 패키지는 실행자가 고른다(아래 Task 11의 요구 동작을 만족해야 한다).

**Spec:** `docs/superpowers/specs/2026-11-11-production-review-retro-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md` (1, 2, 7, 9, 11, 12, 14, 21, 22장) · 상위: `docs/superpowers/specs/2026-11-11-tech-stack-design.md` · 함께 읽을 것: `docs/superpowers/specs/2026-11-12-store-flow-revision-design.md`(F1, F4, F6, F8)

**선행 조건:** 공통 기반, 2~5번 계획과 "가게 흐름 개정" 계획이 끝나 있어야 한다. 가게 흐름 개정 계획에서는 F8 공용 상태 위젯(불러오는 중, 불러오기 실패, 빈 목록, 옛 판본), 오류 코드 `STALE_VERSION`, F1 보상·예산 설정 화면(받는 사람을 인자로 받는 라우트), F6 "내 방식으로 제안" 화면, F4 조회 자료와 보상 계산 화면, A7의 "조회 자료와 보상 계산 확인" 줄 위젯, 조회 자료 확인으로 정산을 확정하는 서비스 메서드를 그대로 쓴다. 이 계획은 그것들의 이름을 새로 정하지 않는다. 실행을 시작할 때 그 계획의 Interfaces를 읽어 라우트·위젯·메서드 이름을 맞추고, 없는 것이 있으면 멈추고 소유자에게 묻는다. 이 계획은 2번의 `ContentDraftPort`·`FakeContentDraftAdapter`·`StoragePort`·`FakeStoragePort`·`uploads` 모듈·`PhotoUploader`·`Clock`·`won()`, 3번의 `collaborations`·`CollaborationStage`·`canTransition`·`CollaborationsRepository.advance`·`JobScheduler`·`FakeJobScheduler`·`OperatorAlertPort`·운영 명령·`submitContentLink`(브랜드 계약은 `APPROVED`에서만)·앱의 `collaboration` feature, 4번의 `campaigns.mustInclude`·`creator_principles`·`VisibilityService`·`brandProgress`·`brand_progress_page.dart`(07)·협업 탭, 5번의 `terms_versions`(`title`, `format`, `pieces`, `revisionScope`)·`contracts.termsSnapshot`·`collaborations.extraRevisionsAllowed`·`conversations`·`dropCollaboration`·`DropReason`·`settleFixed`·`GET /collaborations/:id/contract`·앱의 `chat`(`ChatThreadViewModel`)·`contract_page.dart`를 그대로 쓴다.

## Global Constraints

앞 계획들의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것:

- 적용 범위: 기획 가이드와 초안 검토는 `kind = BRAND_CONTRACT`인 협업에만 있다. 가게 협업에 이 경로를 부르면 404. 회고와 보관함은 두 종류 모두에 있다.
- 순서: 기획 가이드는 `CONTRACTED`(첫 검토 요청 전)와 `GUIDED`(방향 수정 요청 뒤, 다시 검토 요청하기 전)에서만 고쳐진다. 그 안에서 "나만 보는 초안 저장"은 횟수 제한이 없고 단계를 바꾸지 않는다. "브랜드에 검토 요청"은 처음 한 번과 방향 수정 요청 뒤 한 번이고, 첫 요청이 `CONTRACTED → GUIDED`로 올린다. 초안은 `GUIDED`·`REVIEWING`에서만 올라가고, `APPROVED` 뒤에는 새 초안·댓글·광고 표시 변경이 409 `CONFLICT`다. 모든 단계 전이는 `CollaborationsRepository.advance`의 조건부 갱신이고 바뀐 행이 0이면 409.
- 게시 승인은 판본 번호와 함께 보낸다. 최신 판본이 아니면 409 `STALE_VERSION`(공통 규칙 7장)이다.
- 파일 번호: 제출을 마친 초안의 편마다 하나. 영문 대문자 하나(`I`, `O` 제외) + 숫자 두 자리(`00`~`99`), 예 `A12`. 한 협업 안에서 유일하고 한 번 붙으면 바뀌지 않는다. 화면에는 `#A12`로 보인다.
- 브랜드에게 가는 가이드 응답에는 크리에이터의 작업본(`scenes`의 나만 보는 초안, `draftSavedAt`)이 없다.
- 고정 값: 장면 `1~5`개(처음 제안 `3`개), 장면 이름 `1~20`자, 편 `1~3`(계약 사본의 `pieces`), 영상 `180`초·`314572800`바이트(300MB)·`video/mp4`·`video/quicktime`, 사진 한 편에 `10`장·장마다 5MB·`image/jpeg`·`image/png`·`image/heic`, 블로그 본문 `5000`자, 댓글 `300`자, 서명 읽기 주소 `3600`초, 이어 올리기 조각 `6`MB, 이어 올리기 토큰 유효 `2`시간, 크리에이터 기한 알림 제작 시작일(한국 시간 0시) `+14`일, 브랜드 반응 알림 초안 제출 `+3`일, 초안 파일 정리 협업 종료 `+90`일, 재협업 인사 글 만들기 사용자당 하루 `10`번(한국 날짜), 다음 희망 제작비 `10000~10000000`원·1만 원 단위, 다음 가능한 날은 한국 날짜로 오늘 이후.
- 초안 허용 버전 수 = 수정 범위 기준(`NONE` 1, `GUIDE_1` 1, `DRAFT_1` 2, `DRAFT_2` 3) + `extraRevisionsAllowed`. 수정 범위는 계약 사본(`contracts.termsSnapshot`)의 값이다.
- 비공개 버킷 `drafts`의 파일은 공개 주소가 없다. 서명 읽기 주소는 그 협업의 당사자 두 사람의 요청에만 만든다. 로그에 서명 주소와 토큰을 남기지 않는다.
- 회고와 보관함은 작성자 본인만 읽는다. 남의 것을 ID로 요청하면 404. 회고의 값(고른 항목, 가능한 날, 희망 제작비, 다시 만날지)과 보관함의 값은 상대에게 가는 어떤 응답 모델에도 칸이 없다. 무산 사유는 그만둔 본인의 보관함에만 보인다.
- 기한 알림은 알림만 보낸다. 단계를 바꾸지 않는다.
- 새 테이블 8개(`production_guides`, `draft_versions`, `draft_pieces`, `draft_files`, `draft_comments`, `draft_approvals`, `retrospectives`, `keep_entries`)에 RLS를 켠다.
- 작업 브랜치를 만들지 않고 `main`에 바로 커밋한다. 커밋마다 테스트가 통과한 상태여야 한다. push는 소유자 확인 후에만 한다.

## 2026-11-11 소유자 결정으로 더한 것 (E3~E8 계정·알림 화면)

설계: `specs/2026-11-11-account-notify-settings-design.md`. 알림 기반은 3번 계획 Task 3A, 알림함·설정·정산 화면은 3번 Task 13A~13D, 설정·프로필 수정·고객센터는 `plans/2026-11-11-account-settings.md`(7번 다음)가 만든다. 아래가 이 계획의 작업에 더해진다.

- 이 계획의 모든 알림은 `PushPort`가 아니라 3번 Task 3A의 `NotificationsService.notify`로 보낸다. 새 알림 종류는 `NOTIFICATION_CATALOG`에 탭·스위치·그림·문구를 더하고(설계 3.2 표), 앱의 `locationFor`(3번 Task 13C)에 가는 곳을 더한다. 작업 처리기에서 보내는 알림은 `dedupeKey`를 넘긴다.
- Task 4~6·8: 이 계획의 알림은 모두 끌 수 없는 협업 알림(탭 협업, 그림 `PEN` ✎)이다. 가는 곳 `GUIDE` → 13, `DRAFT_REVIEW` → 14.
- Task 6: 초안 댓글의 `{위치}`는 영상이면 `m:ss`(캔버스 "초안 0:12 구간에 댓글이 달렸어요."). 카드뉴스는 `초안 {n}번째 장에 댓글이 달렸어요.`, 블로그 글은 `초안 본문에 댓글이 달렸어요.`·`초안 {n}번째 사진에 댓글이 달렸어요.`(캔버스 밖 — 설계 10장 확인 목록).
- Task 8: 기한 알림 작업은 그날 한국 시간 10:00에 실행되게 등록한다(방해 금지에 걸려 사라지지 않게).
- Task 9: 보관함 모듈은 `KeepService`를 export하고 `countFor(userId): Promise<number>`(전체 탭의 수)를 더한다. 계정·설정 계획 Task 2가 E4의 "다시 만나고 싶은 브랜드" 수에 쓴다.

## 2026-11-12 캔버스 개정으로 바꾼 것

설계: `specs/2026-11-11-production-review-retro-design.md`의 "2026-11-12 개정"과 공통 규칙 1·7·12·21·22장. 아래가 이 계획에 반영돼 있다.

- 13 기획 가이드: 맨 위 줄에 합의 버전 번호가 붙고, 버튼이 `나만 보는 초안 저장`과 `브랜드에 검토 요청`으로 나뉜다. `GUIDED`로 올리는 것은 검토 요청이다. (Task 1, 3, 4, 10)
- 14 초안 검토: 머리가 `영상 v{n} · 파일 #{번호} 검토`, 브랜드의 버튼이 `이 판본(v{n}) 게시 승인`이다. 편마다 파일 번호를 붙이고, 승인은 판본 번호를 받아 최신일 때만 된다. (Task 1, 3, 5, 6, 11)
- 15 회고: 버튼이 `이번만 할래요` / `새 제안 만들기`이고 둘 다 회고를 저장한다. `새 제안 만들기`는 가게 흐름 개정 계획의 F1(크리에이터가 가게에게면 F6, 크리에이터가 브랜드에게면 보관함의 `관심 보내기`)을 연다. 안내 문구가 바뀌었다. (Task 9, 12)
- D5 보관함: 캔버스에서 바뀌지 않았다.
- 성과 추가가 켜진 브랜드 계약: 링크 제출 뒤 F4 조회 자료 확인을 거쳐 `SETTLED`가 된다. 이 계획은 그 종료 길에 보관함 줄 만들기를 걸고(Task 7), 07의 6단계에서 F4로 잇는다(Task 10).
- 빈 상태·오류·옛 판본은 F8 공용 상태 위젯으로 보여 준다. (Task 10~12)
- 다크 캔버스에서 달라진 색(14의 댓글 보내기 버튼과 켜진 스위치, 15의 고른 항목·`이번만 할래요`·구분 막대)은 Task 11·12의 화면 확인에서 라이트·다크 캔버스와 각각 나란히 비교한다. 색은 `core/theme` 토큰에서만 가져온다.

## Review Focus

1. **상대가 내 회고나 보관함을 엿봄** → 상대의 협업·대화·계약·초안·보관함 응답 어디에도 값이 없고, ID로 요청하면 404다. (Task 9)
2. **허용 횟수를 다 쓴 뒤 초안을 또 올리거나, 완료 요청이 두 번 동시에 옴** → 409이고 버전 번호가 겹치거나 건너뛰지 않는다. (Task 5)
3. **한쪽만 광고 표시를 확인한 채 게시 승인하거나, 브랜드가 보던 판본과 다른 판본이 승인되거나, 승인과 새 버전 제출이 엇갈림** → 승인되지 않거나(`STALE_VERSION`) 하나만 성공하고, 승인 기록의 파일 번호가 그 판본의 것이다. (Task 6)
4. **당사자가 아닌 사람이 초안 파일을 봄** → 404이고 서명 주소가 만들어지지 않으며, 주소는 1시간 뒤 쓸 수 없다. (Task 5)
5. **협업이 끝나는 여러 길(정산, 조회 자료 확인, 환급, 취소, 그만두기, 차단, 운영 명령)** → 양쪽 보관함 줄이 규칙대로 정확히 한 번 생기고 상대에게 무산 사유가 새지 않는다. (Task 7)
6. **브랜드가 크리에이터의 "나만 보는 초안"을 봄** → 검토 요청 전에는 장면이 비어 있고, 방향 수정 요청 뒤 고치는 동안에는 지난번 요청한 내용만 보인다. (Task 4)

---

## 파일 구조

```text
api/src/
├── production/
│   ├── production-rules.ts             # 순수 함수: 가이드 두 열, 허용 버전 수, 편 구성 검사, 댓글 위치 검사
│   ├── guides/                         # 기획 가이드 controller, service, repository, dto
│   └── drafts/                         # 초안 버전·파일·댓글·확인 controller, service, repository, dto
├── retrospectives/                     # 회고
├── keep/
│   ├── keep-rules.ts                   # 순수 함수: 종료 → 보관함 줄, 상태, 다음 걸음
│   ├── collaboration-endings.service.ts
│   └── ...                             # 보관함 controller, service, repository, dto
├── integrations/{content-draft,storage}/   # 포트 확장 (2번)
└── jobs/handlers/{draft-due-reminder,draft-brand-reminder,draft-file-cleanup}.handler.ts

app/lib/features/
├── production/                         # 13 기획 가이드, 14 초안 검토, 초안 올리기
├── retrospective/                      # 15 회고
└── keep/                               # D5 보관함, 재협업 메시지, 프로필 메뉴
```

---

### Task 1: 스키마와 비공개 버킷

**Files:**
- Modify: `api/prisma/schema.prisma`
- Create: 마이그레이션, `api/scripts/setup-supabase.ts`에 추가(초안용 비공개 버킷. 이름과 한도는 이 작업의 Interfaces를 따른다)
- Test: `api/test/db/production-schema.db-spec.ts`

**Interfaces:**
- Produces:
  - `enum DraftStatus { UPLOADING, SUBMITTED, ABANDONED }`, `enum DraftPieceKind { VIDEO, IMAGES, BLOG }`, `enum CommentPositionKind { SECOND, IMAGE, BODY }`, `enum KeepKind { COMPLETED, DROPPED }`, `enum KeepDropReason { SCHEDULE, BUDGET, DIRECTION, OTHER, ENDED_BY_OTHER, CANCELLED_IN_PROGRESS, MISSED_DEADLINE, HALTED_REFUND }`, `enum RetroChip { FREEDOM, FAST_FEEDBACK, ACCURATE_INFO, PAYMENT_PROMISE, DELIVERY, TRIAL_PERIOD, REVISION_COUNT, CREATOR_RESPONSE_SPEED, QUALITY, ON_SCHEDULE, COMMUNICATION, UNDERSTANDING, SCHEDULE, REVISION_PROCESS, COMMISSIONER_RESPONSE_SPEED, TERMS }`
  - `ProductionGuide` → `production_guides`: `collaborationId`(unique), `termsVersion Int`(계약 사본의 조건 버전 번호), `brandDecides String[]`, `creatorDecides String[]`, `scenes String[]`(크리에이터의 작업본, 나만 보는 초안), `sharedScenes String[]`(브랜드에게 보이는 사본), `draftSavedAt?`, `sharedAt?`, `shareCount Int @default(0)`(검토 요청 횟수), `revisionRequestedAt?`
  - `DraftVersion` → `draft_versions`: `collaborationId`, `version Int`, `status`, `submittedAt?`, `filesPurgedAt?`. 부분 유니크 `(collaboration_id, version) WHERE status <> 'ABANDONED'`, `(collaboration_id) WHERE status = 'UPLOADING'`.
  - `DraftPiece` → `draft_pieces`: `draftVersionId`, `collaborationId`(파일 번호의 유일 조건에 쓴다), `pieceIndex Int`(1~3), `kind`, `bodyText?`, `durationSec Int?`, `fileCode String?`(제출을 마칠 때 붙는다). 유일 `(draftVersionId, pieceIndex)`, 부분 유니크 `(collaboration_id, file_code) WHERE file_code IS NOT NULL`.
  - `DraftFile` → `draft_files`: `draftPieceId`, `ordinal Int`(영상 1, 사진 1~10), `path`(unique), `contentType`, `sizeBytes Int`
  - `DraftComment` → `draft_comments`: `draftVersionId`, `pieceIndex`, `authorId`, `positionKind`, `position Int?`(초 또는 장 번호, `BODY`면 null), `text`
  - `DraftApproval` → `draft_approvals`: `draftVersionId`(unique), `creatorAdConfirmedAt?`, `brandAdConfirmedAt?`, `approvedAt?`(게시 승인 시각), `approvedFileCodes String[]`(승인한 판본의 파일 번호 사본, 편 순서), `lastBrandActivityAt?`
  - `Retrospective` → `retrospectives`: `collaborationId`, `authorId`, `goodPoints RetroChip[]`, `changePoints RetroChip[]`, `nextAvailableFrom @db.Date?`, `nextHopeFee Int?`, `wantAgain Boolean`. 유일 `(collaborationId, authorId)`.
  - `KeepEntry` → `keep_entries`: `ownerId`, `counterpartId`, `collaborationId`, `kind`, `dropReason?`, `availableFrom @db.Date?`, `hopeFee Int?`, `wantAgain Boolean?`, `endedAt`, `greetingDay @db.Date?`, `greetingsOnDay Int @default(0)`. 유일 `(ownerId, collaborationId)`.
  - 버킷 `drafts`: `public = false`, `file_size_limit = 314572800`, `allowed_mime_types = {video/mp4, video/quicktime, image/jpeg, image/png, image/heic}`. 운영 Supabase 프로젝트의 전역 업로드 한도가 300MB 이상인지 README의 출시 전 점검에 적는다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('keeps one live version number per collaboration but allows reuse after abandon', ...);
it('allows only one uploading version per collaboration', ...);
it('rejects the same file code twice in one collaboration but allows it in another', ...);
it('allows many pieces without a file code before submission', ...);
it('rejects a second retrospective by the same author on one collaboration', ...);
it('rejects a second keep entry for the same owner and collaboration', ...);
it('creates the drafts bucket as private', ...);                         // storage.buckets.public === false
```

- [ ] **Step 2~4: 실패 확인 → 스키마, 마이그레이션(새 테이블 8개의 RLS), 버킷 구현 → 통과 확인** — Run: `cd api && yarn prisma migrate dev && yarn test:db`
- [ ] **Step 5: Commit** — `feat: 기획 가이드·초안·회고·보관함 스키마와 비공개 버킷 추가`

---

### Task 2: 포트 확장과 작업 이름

**Files:**
- Modify: `api/src/integrations/content-draft/{content-draft.port.ts,fake-content-draft.adapter.ts}`, `api/src/integrations/storage/{storage.port.ts,supabase-storage.adapter.ts}`, `api/test/support/fake-storage.port.ts`, `api/src/jobs/job-names.ts`
- Test: `api/src/integrations/content-draft/fake-content-draft.adapter.spec.ts`(추가), `api/test/support/fake-storage.port.spec.ts`, `api/test/storage.db-spec.ts`(개발용 원격 Supabase로 실제 어댑터 확인)

**Interfaces:**
- Produces:
  - `ContentDraftPort.generateGuideScenes(input: { title: string; format: ContentFormat; brandName: string; mustInclude: string[] }): Promise<string[]>` — 정확히 3개, 각 20자 이내
  - `ContentDraftPort.generateGreeting(input: { myName: string; counterpartName: string; outcome: 'COMPLETED' | 'DROPPED'; contextLabel: string }): Promise<string>` — 300자 이내. 무산 사유를 입력으로 받지 않는다.
  - 가짜 구현: 장면 `['세안', '옷 고르기', '주얼리 착용']`. 인사 `COMPLETED` → `{상대 이름}님, 지난번 「{contextLabel}」 협업 즐거웠어요. 새로 준비하는 콘텐츠가 있어 다시 이야기 나누고 싶어요.`, `DROPPED` → `{상대 이름}님, 지난번에는 함께하지 못했지만 이번에 다시 이야기 나눠 보고 싶어요.` `title`에 `fail`이 있으면 `ContentDraftUnavailableError`.
  - `StoragePort`에 추가(버킷을 인자로 받는다, 기존 메서드는 `photos` 그대로):
    - `createResumableUpload(bucket: 'drafts', path: string, contentType: string): Promise<{ endpoint: string; token: string; expiresAt: Date }>` — Supabase의 서명 업로드 토큰과 TUS 주소(`/storage/v1/upload/resumable`). 유효 2시간.
    - `signedReadUrl(bucket: 'drafts', path: string, ttlSec: number): Promise<string>`
    - `stat(bucket: 'drafts', path: string): Promise<{ sizeBytes: number; contentType: string } | null>`
    - `remove(bucket: 'drafts', paths: string[]): Promise<void>` — 없는 경로는 무시
  - `FakeStoragePort`: 업로드 토큰과 서명 주소를 `fake://drafts/<path>?exp=<epoch>` 꼴로 만들고, `markUploaded(path, sizeBytes, contentType)`으로 `stat` 결과를 심는다. 발급 기록(`issuedReadUrls`)을 남긴다.
  - `JobName`에 `'draft-due-reminder' | 'draft-brand-reminder' | 'draft-file-cleanup'` 추가

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('suggests the three canvas scenes', ...);                            // ['세안','옷 고르기','주얼리 착용']
it('writes a greeting without any drop reason', ...);                   // DROPPED 결과에 '일정', '예산', '방향' 없음
it('throws ContentDraftUnavailableError for a title containing fail', ...);
it('records issued read urls with their expiry in the fake storage', ...);
it('issues a resumable token and a one hour read url from local supabase', ...);   // storage.db-spec
it('returns null stat for a path that was never uploaded', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn test integrations && yarn test:db storage`
- [ ] **Step 5: Commit** — `feat: AI 초안 포트에 장면·인사 글, 저장소 포트에 비공개 업로드 추가`

---

### Task 3: 순수 규칙

**Files:**
- Create: `api/src/production/production-rules.ts`, `api/src/keep/keep-rules.ts`
- Test: `api/src/production/production-rules.spec.ts`, `api/src/keep/keep-rules.spec.ts`

**Interfaces:**
- Produces (`production-rules.ts`):
  - `GUIDE_FIXED_BRAND = ['광고 관계 표시', '확인 안 된 효능 표현 빼기']`, `GUIDE_FIXED_CREATOR = ['도입부와 이야기 흐름', '촬영 장소·구도·음악']`
  - `brandDecides(mustInclude: string[]): string[]` = `[...mustInclude, ...GUIDE_FIXED_BRAND]`
  - `creatorDecides(p: { faceOk: boolean; scriptOk: boolean; honestReview: boolean } | null): string[]` = `[...GUIDE_FIXED_CREATOR, (honestReview ? '평소 말투와 솔직한 후기' : '평소 말투로 소개'), (scriptOk ? 없음 : '대본 없이 내 말로 소개'), (faceOk ? 없음 : '얼굴 없이 손 중심 촬영')]`. 원칙이 없으면 고정 두 줄만.
  - `baseDraftVersions(scope: RevisionScope): 1 | 2 | 3` — `NONE` 1, `GUIDE_1` 1, `DRAFT_1` 2, `DRAFT_2` 3
  - `maxDraftVersions(scope, extraRevisionsAllowed: number): number`
  - `guideEditAllowed(g: { shareCount; revisionRequestedAt }, stage): boolean` — `CONTRACTED`이고 `shareCount = 0`, 또는 `GUIDED`이고 방향 수정 요청이 있고 `shareCount = 1`. "나만 보는 초안 저장"과 "브랜드에 검토 요청"이 같은 조건을 쓴다.
  - `FILE_CODE_LETTERS = 'ABCDEFGHJKLMNPQRSTUVWXYZ'`, `newFileCode(random: () => number, taken: ReadonlySet<string>): string` — 글자 하나 + 숫자 두 자리(`A12`). `taken`에 있으면 다시 뽑고, 2,400개가 모두 찼으면 `AppError('CONFLICT', …)`. `random`은 주입받는다(테스트에서 고정).
  - `pieceKindFor(format: ContentFormat): DraftPieceKind` — `SHORTS`·`REELS` → `VIDEO`, `CARD_NEWS` → `IMAGES`, `BLOG` → `BLOG`
  - `validateManifest(format, pieces: number, manifest: PieceManifest[]): void` — 편 수가 `pieces`와 같고 번호가 1부터 이어짐, 영상은 파일 1개·형식·크기·`durationSec` 1~180, 카드뉴스는 사진 1~10장, 블로그는 본문 1~5000자와 사진 0~10장. 어기면 `AppError('VALIDATION_FAILED', 문구)` — 문구는 "이 계획이 구체화한 것"의 오류 줄.
  - `validateAnchor(piece: { kind; durationSec; imageCount }, a: { positionKind; position }): void` — 영상은 `SECOND` 0~`durationSec`, 카드뉴스는 `IMAGE` 1~장 수, 블로그는 `BODY`(위치 null) 또는 `IMAGE` 1~장 수
- Produces (`keep-rules.ts`):
  - `type EndedCollaboration = { kind; stage; fundedAt: Date | null; commissionerId; creatorId; dropReason: DropReason | null; droppedById: string | null; stageBeforeHalt: CollaborationStage | null }`
  - `keepEntriesFor(c: EndedCollaboration): { ownerId; counterpartId; kind: KeepKind; dropReason: KeepDropReason | null }[]` — `SETTLED` → 양쪽 `COMPLETED`. 브랜드 `DROPPED`: 사유가 `SCHEDULE`·`BUDGET`·`DIRECTION`·`OTHER`이고 단계가 `INQUIRY`에서 온 것이 아니면 그만둔 쪽은 그 사유, 상대는 `ENDED_BY_OTHER`. `REQUEST_DECLINED`·`BLOCKED`는 빈 배열. 가게 `CANCELLED`는 `fundedAt`이 있을 때만 양쪽 `CANCELLED_IN_PROGRESS`. 가게 `REFUNDED` → 양쪽 `MISSED_DEADLINE`. 브랜드 `REFUNDED` → 양쪽 `HALTED_REFUND`. 그 밖은 빈 배열.
  - `isEndStage(kind, stage): boolean` — `SETTLED`, `DROPPED`, `CANCELLED`, `REFUNDED`
  - `keepTabOf(e: { kind; wantAgain }): ('ALL' | 'COMPLETED' | 'DROPPED')[]` — `COMPLETED`는 `COMPLETED`에 늘 있고 `wantAgain`이 false가 아니면 `ALL`에도, `DROPPED`는 `ALL`과 `DROPPED`
  - `type NextAction = { kind: 'SEND_OFFER' | 'LIKE_CREATOR' | 'APPLY_STORE' | 'LIKE_CAMPAIGN'; targetId: string }`
  - `nextActionFor(input: { ownerRole: 'STORE' | 'BRAND' | 'CREATOR'; counterpartKind: 'STORE' | 'BRAND' | 'CREATOR'; counterpartId; myActiveCampaignId: string | null; theirActiveCampaignId: string | null; entryCampaignId: string | null; theirPublishedStoreId: string | null; visible: boolean; hasOpenRelation: boolean }): NextAction | null` — 공통 규칙 12장: 사장님 `SEND_OFFER`, 브랜드는 진행 중 캠페인이 있고 그것이 이 줄의 캠페인과 다를 때 `LIKE_CREATOR`, 크리에이터는 상대가 가게면 공개된 가게에 `APPLY_STORE`, 브랜드면 진행 중 캠페인이 이 줄의 캠페인과 다를 때 `LIKE_CAMPAIGN`. `visible`이 false거나 열린 오퍼·지원·끝나지 않은 협업이 있으면 null.
  - `type NewProposalTarget = { screen: 'F1' | 'F6' | 'KEEP'; recipientKind: 'CREATOR' | 'BRAND' | 'STORE'; recipientId: string; campaignId: string | null }`
  - `newProposalFor(input: nextActionFor와 같은 입력): NewProposalTarget | null` — 15의 "새 제안 만들기"가 여는 곳. `nextActionFor`가 null이면 null. `SEND_OFFER` → `{ F1, CREATOR, 크리에이터, null }`, `LIKE_CREATOR` → `{ F1, CREATOR, 크리에이터, myActiveCampaignId }`, `APPLY_STORE` → `{ F6, STORE, theirPublishedStoreId, null }`, `LIKE_CAMPAIGN` → `{ KEEP, BRAND, 브랜드, theirActiveCampaignId }`(크리에이터가 브랜드에게 낸 제안을 저장하는 규칙이 4번 설계에 없어 F1을 열지 않고 보관함의 `관심 보내기`로 잇는다. 설계 5장 4번).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('puts must-include lines before the two fixed brand lines', ...);    // ['제품 소재와 관리 방법','제품명·브랜드명 정확히','광고 관계 표시','확인 안 된 효능 표현 빼기']
it('builds the canvas creator column from principles', ...);           // faceOk false, honestReview true → 네 줄, 캔버스 순서
it('keeps only the fixed creator lines without principles', ...);
it('allows v1 for NONE and GUIDE_1, v2 for DRAFT_1 and v3 for DRAFT_2', ...);
it('adds one version per extra revision allowed', ...);                // DRAFT_1 + 1 → 3
it('allows guide edits before the first review request and again only after a revision request', ...);
it('builds a file code of one letter without I or O and two digits', ...);   // /^[A-HJ-NP-Z][0-9]{2}$/
it('draws again when the file code is already taken in the collaboration', ...);
it('rejects a video over 180 seconds or 300MB or of another type', ...);
it('rejects eleven images or a blog body over 5000 characters', ...);
it('rejects a piece count different from the contract', ...);
it('accepts a comment at the last second and rejects one past the end', ...);
it('accepts a body comment only for a blog piece', ...);
it('creates completed entries for both sides of a settled collaboration', ...);
it('shows the drop reason to the dropper and ENDED_BY_OTHER to the other side', ...);
it('creates nothing for a declined request, a block or a drop from INQUIRY', ...);
it('creates nothing for a store cancel before funding', ...);
it('maps store cancel after funding and refund to the two common reasons', ...);
it('keeps a just-this-once completion out of the all tab', ...);
it('offers the next step by role and hides it for the same campaign', ...);
it('opens F1 for an owner or a brand toward a creator', ...);
it('sends a creator toward a brand to the keep list instead of F1', ...);   // screen 'KEEP'
it('opens F6 for a creator toward a published store', ...);
it('gives no new proposal target when the next step is unavailable', ...);   // 차단, 열린 오퍼, 진행 중 캠페인 없음
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn test production-rules keep-rules`
- [ ] **Step 5: Commit** — `feat: 기획 가이드·초안·보관함 규칙 추가`

---

### Task 4: 기획 가이드 API

**Files:**
- Create: `api/src/production/{production.module.ts}`, `api/src/production/guides/{guides.controller.ts,guides.service.ts,guides.repository.ts,dto/*.ts}`
- Test: `api/src/production/guides/guides.service.spec.ts`, `api/test/guides.e2e-spec.ts`

**Interfaces:**
- Consumes: `brandDecides`, `creatorDecides`, `guideEditAllowed` (Task 3), `ContentDraftPort.generateGuideScenes` (Task 2), 3번 `CollaborationsRepository.advance`, 4번 캠페인·원칙 조회, 5번 계약 사본(제목, 조건 버전 번호), `PushPort`, `Clock`
- Produces:
  - `ProductionGuideModel { collaborationId; termsVersion: number; title: string; myRole: 'COMMISSIONER' | 'CREATOR'; brandDecides: string[]; creatorDecides: string[]; scenes: string[]; draftSavedAt: string | null; sharedAt: string | null; hasUnsharedChanges: boolean; revisionRequested: boolean; canEdit: boolean; canRequestRevision: boolean }` — 크리에이터에게 `scenes`는 작업본, 브랜드에게는 `sharedScenes`다. 브랜드에게 `draftSavedAt`은 늘 null, `hasUnsharedChanges`는 늘 false다(작업본이 있는지도 알리지 않는다).
  - `GET /collaborations/:id/guide` → 200 — 당사자만, 브랜드 계약만, `CONTRACTED` 이후(그 전이면 409). 크리에이터가 처음 읽을 때 행이 없으면 두 열과 생성한 장면 세 개로 만든다(포트가 실패하면 `['도입', '제품 사용', '마무리']`). 브랜드는 검토 요청 전이면 `scenes: []`, `sharedAt: null`이고 행을 만들지 않는다. `title`과 `termsVersion`은 계약 사본의 제목과 조건 버전 번호. `operationId: getProductionGuide`
  - `PUT /collaborations/:id/guide` 본문 `{ scenes: string[](1~5개, 각 1~20자, 앞뒤 공백 제거) }` → 200 `ProductionGuideModel` — 크리에이터만. "나만 보는 초안 저장"이다. `guideEditAllowed`가 아니면 409 `기획 방향을 더 고칠 수 없어요.` `scenes`와 `draftSavedAt = now`만 바꾼다. `sharedScenes`, `shareCount`, 단계는 건드리지 않고 알림도 보내지 않는다. 횟수 제한이 없다. `operationId: saveProductionGuideDraft`
  - `POST /collaborations/:id/guide/review-request` 본문 `{ scenes: string[](위와 같은 검사) }` → 200 `ProductionGuideModel` — 크리에이터만. "브랜드에 검토 요청"이다. `guideEditAllowed`가 아니면 409 `기획 방향을 더 고칠 수 없어요.` 한 트랜잭션에서 `shareCount`를 기대값에 건 조건부 증가(0행이면 409), `scenes = sharedScenes = 본문`, `sharedAt = now`, 첫 요청이면 `CONTRACTED → GUIDED`, 다시 요청이면 `revisionRequestedAt`을 그대로 두고 `canRequestRevision`이 false가 된다. 브랜드에게 푸시 `{활동 이름}님이 기획 방향 검토를 요청했어요.` `operationId: requestGuideReview`
  - `POST /collaborations/:id/guide/revision-request` → 200 `ProductionGuideModel` — 브랜드만, 계약의 수정 범위가 `GUIDE_1`, 단계 `GUIDED`, 제출된 초안이 없고, 요청한 적이 없을 때만(아니면 409). 크리에이터에게 푸시 `{브랜드 이름}이 기획 방향 수정을 요청했어요. 대화에서 의견을 확인해 주세요.` `operationId: requestGuideRevision`
  - `GuidesService`를 export: `pendingRevision(collaborationId): Promise<boolean>`(Task 5가 쓴다)

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('generates three scenes and both columns on the creator first read', ...);
it('shows the brand an unshared guide without generating scenes', ...);   // scenes [], FakeContentDraft 호출 0번
it('falls back to three plain scenes when generation fails', ...);
it('returns the contracted terms version with the guide', ...);          // termsVersion 2
it('keeps the stage and sends nothing on a private draft save', ...);    // CONTRACTED 그대로, 알림 0건
it('saves a private draft any number of times before the review request', ...);
it('never shows the private draft to the brand', ...);                   // 브랜드 응답: scenes [], draftSavedAt null, hasUnsharedChanges false
it('moves CONTRACTED to GUIDED on the first review request and notifies the brand', ...);
it('rejects six scenes or a 21 character scene', ...);                   // 400
it('refuses a private save or a second review request without a revision request', ...);   // 409
it('lets a GUIDE_1 brand request one revision and the creator request review once more', ...);
it('keeps showing the brand the last shared scenes while the creator edits after a revision request', ...);
it('refuses a revision request for DRAFT_1 terms or after a draft exists', ...);   // 409
it('returns 404 for a store collaboration or a non-party', ...);
it('lets only one of two concurrent first review requests advance the stage', ...);  // Promise.all → 200 하나, 409 하나
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e`
- [ ] **Step 5: gen-api, Commit** — `feat: 기획 가이드의 나만 보는 저장, 검토 요청, 방향 수정 요청 추가`

---

### Task 5: 초안 올리기와 보기

**Files:**
- Create: `api/src/production/drafts/{drafts.controller.ts,drafts.service.ts,drafts.repository.ts,draft-paths.ts,dto/*.ts}`
- Test: `api/src/production/drafts/drafts.service.spec.ts`, `api/test/drafts-upload.e2e-spec.ts`

**Interfaces:**
- Consumes: `validateManifest`, `maxDraftVersions`, `pieceKindFor`, `newFileCode` (Task 3), `StoragePort` (Task 2), `GuidesService.pendingRevision` (Task 4), 3번 `CollaborationsRepository.advance`·`JobScheduler`, `PushPort`, `Clock`
- Produces:
  - `draftPath(collaborationId, version, pieceIndex, ordinal, ext): string` = `<collaborationId>/v<version>/p<pieceIndex>/<ordinal>-<uuid>.<ext>`(버킷 `drafts`)
  - `type PieceManifest = { pieceIndex: number; bodyText?: string; durationSec?: number; files: { contentType: string; sizeBytes: number }[] }`
  - `DraftOverviewModel { format; pieces: number; maxVersions: number; usedVersions: number; exhausted: boolean; canUpload: boolean; canAllowExtra: boolean; uploading: { draftId; version; createdAt } | null; versions: { id; version; submittedAt; approvedAt: string | null; fileCodes: string[] }[](최신 먼저, `fileCodes`는 편 순서) }`
  - `GET /collaborations/:id/drafts` → 200 `DraftOverviewModel` — 당사자만, 브랜드 계약만. `uploading`은 크리에이터에게만. `operationId: getDraftOverview`
  - `POST /collaborations/:id/drafts` 본문 `{ pieces: PieceManifest[] }` → 201 `{ draftId; version; uploads: { fileId; path; endpoint; token; expiresAt }[] }` — 크리에이터만. 단계가 `CONTRACTED`면 409 `기획 방향을 브랜드에 먼저 검토 요청해 주세요.`, `APPROVED` 이후면 409 `게시가 승인된 뒤에는 초안을 올릴 수 없어요.`, 방향 수정 요청이 걸려 있으면 409 `기획 방향을 다시 검토 요청한 뒤 초안을 올릴 수 있어요.`, 제출된 버전 수가 허용 수와 같으면 409 `합의한 수정 횟수를 다 썼어요. 더 고치려면 브랜드가 수정을 허용해야 해요.` 이미 `UPLOADING`인 버전이 있으면 그것을 `ABANDONED`로 바꾸고 파일을 지운 뒤 새로 만든다. `version` = 제출된 수 + 1. `operationId: createDraftVersion`
  - `POST /drafts/:draftId/upload-tokens` → 200 같은 `uploads` — 크리에이터만, `UPLOADING`일 때만. 토큰이 만료된 뒤 이어 올리기를 다시 시작할 때 쓴다. `operationId: reissueDraftUploadTokens`
  - `POST /drafts/:draftId/complete` → 200 `DraftVersionModel` — 크리에이터만. 파일마다 `StoragePort.stat`이 null이거나 크기·형식이 선언과 다르면 409 `아직 다 올라가지 않았어요.` 한 트랜잭션에서 `UPLOADING → SUBMITTED` 조건부 갱신(0행이면 409), 허용 수를 다시 확인, 편마다 `newFileCode`로 파일 번호를 붙임(그 협업에서 이미 쓴 번호를 `taken`으로 넘기고, 유니크 위반이면 다시 뽑는다), 첫 버전이면 `GUIDED → REVIEWING`, `draft_approvals` 행 생성. 그 뒤 브랜드에게 푸시 `{활동 이름}님이 초안 v{n}을 올렸어요.`, `draft-brand-reminder`를 `now + 3일`에 등록(`jobKey = 'draft-react:' + draftId`), 이전 버전의 반응 알림 취소. `operationId: completeDraftVersion`
  - `DELETE /drafts/:draftId` → 204 — 크리에이터만, `UPLOADING`일 때만. `ABANDONED`로 바꾸고 파일을 지운다. `operationId: abandonDraftVersion`
  - `DraftVersionModel { id; version; submittedAt; filesPurged: boolean; urlsExpireAt: string | null; pieces: { pieceIndex; fileCode: string; kind: 'VIDEO' | 'IMAGES' | 'BLOG'; video: { url: string | null; durationSec: number } | null; images: (string | null)[]; bodyText: string | null }[]; comments: DraftCommentModel[]; approval: { creatorAdConfirmed: boolean; brandAdConfirmed: boolean; approvedAt: string | null; approvedFileCodes: string[] }; isLatest: boolean; canComment: boolean; canConfirmAd: boolean; canApprove: boolean }`
  - `GET /drafts/:draftId` → 200 `DraftVersionModel` — 당사자만(아니면 404, 서명 주소를 만들지 않는다), `SUBMITTED`만. 파일마다 `signedReadUrl(..., 3600)`, `urlsExpireAt = now + 1시간`. 정리된 버전은 주소가 null이고 `filesPurged: true`이며 `fileCode`는 남는다. `operationId: getDraftVersion`
  - `CollaborationModel`에 `guideShared: boolean`(검토 요청을 한 번이라도 했는가), `latestDraftVersion: number | null` 추가

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('refuses a draft before the guide review is requested, even with a private draft saved', ...);   // 409
it('creates v1 with one resumable token per file', ...);
it('moves GUIDED to REVIEWING when v1 is completed and notifies the brand', ...);
it('gives every piece a file code on completion and none while uploading', ...);
it('never reuses a file code across versions of one collaboration', ...);   // v1, v2의 번호가 모두 다름
it('keeps the file code after the files are purged', ...);
it('refuses to complete while a file is missing or larger than declared', ...);   // 409
it('keeps REVIEWING and numbers v2 after v1 for DRAFT_1 terms', ...);
it('refuses v2 for GUIDE_1 terms with the exhausted message', ...);       // 409
it('replaces an abandoned upload without skipping a version number', ...);
it('completes only once for two concurrent complete requests', ...);      // 200 하나, 409 하나, SUBMITTED 1행
it('refuses new drafts after approval', ...);                            // 409
it('signs read urls for one hour and only for the two parties', ...);    // 제3자 → 404, FakeStorage.issuedReadUrls 0건
it('returns null urls for purged files but keeps the comments', ...);
it('hides the uploading version from the brand', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e`. 개발용 원격 Supabase로 30MB 영상을 TUS로 올리고 `complete` → 서명 주소로 재생되는지 손으로 확인한다.
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 초안 버전 만들기와 이어 올리기 토큰 발급 추가`, `feat: 초안 제출 완료와 서명 주소로 보기 추가`

---

### Task 6: 댓글, 광고 표시 확인, 판본 게시 승인, 수정 한 번 더 허용

**Files:**
- Modify: `api/src/production/drafts/*`
- Test: `api/test/drafts-review.e2e-spec.ts`

**Interfaces:**
- Consumes: `validateAnchor`, `maxDraftVersions` (Task 3), Task 5, 3번 `CollaborationsRepository.advance`·`JobScheduler`, `PushPort`, 가게 흐름 개정 계획의 오류 코드 `STALE_VERSION`
- Produces:
  - `DraftCommentModel { id; pieceIndex; positionKind: 'SECOND' | 'IMAGE' | 'BODY'; position: number | null; authorRole: 'COMMISSIONER' | 'CREATOR'; authorName; mine: boolean; text; createdAt }` — 편, 위치, 작성 시각 순
  - `POST /drafts/:draftId/comments` 본문 `{ pieceIndex; positionKind; position?: number; text: string(1~300) }` → 201 `DraftCommentModel` — 당사자만, 최신 버전이고 단계 `REVIEWING`일 때만(아니면 409). 상대에게 `초안 {위치} 구간에 댓글이 달렸어요.`(E3 캔버스 문구 (2026-11-11 소유자 결정)) 브랜드가 쓰면 `lastBrandActivityAt = now`. `operationId: createDraftComment`
  - `PUT /drafts/:draftId/ad-disclosure` 본문 `{ confirmed: boolean }` → 200 `DraftVersionModel` — 내 쪽 시각만 채우거나 지운다. 최신 버전·`REVIEWING`·게시 승인 전일 때만. `operationId: setDraftAdDisclosure`
  - `POST /drafts/:draftId/approve` 본문 `{ version: number }` → 200 `DraftVersionModel` — 브랜드만. "이 판본(v{n}) 게시 승인"이다. `version`이 그 초안의 버전 번호와 다르면 400. 그 초안이 협업의 최신 제출 버전이 아니면 409 `STALE_VERSION`(문구 `이전 판본이라 승인할 수 없어요`, 응답의 `details.latestVersion`과 `details.latestDraftId`에 최신 판본을 넣는다). 한 트랜잭션에서 `UPDATE draft_approvals SET approved_at = now, approved_file_codes = <그 버전 편들의 파일 번호> WHERE draft_version_id = ? AND creator_ad_confirmed_at IS NOT NULL AND brand_ad_confirmed_at IS NOT NULL AND approved_at IS NULL`, 그 버전이 여전히 최신인지 다시 확인(아니면 `STALE_VERSION`), `REVIEWING → APPROVED`. 광고 표시 쪽이 0행이면 409 `양쪽이 광고 표시를 확인해야 게시를 승인할 수 있어요.` 반응 알림 취소, 크리에이터에게 푸시 `판본 v{n}의 게시가 승인됐어요. 게시하고 링크를 제출해 주세요.` `operationId: approveDraftVersion`
  - `POST /collaborations/:id/drafts/allow-extra` → 200 `DraftOverviewModel` — 브랜드만, `REVIEWING`이고 허용 수를 다 썼을 때만. `UPDATE collaborations SET extra_revisions_allowed = extra_revisions_allowed + 1 WHERE id = ? AND extra_revisions_allowed = <읽은 값> AND stage = 'REVIEWING'`. 크리에이터에게 푸시 `{브랜드 이름}이 수정을 한 번 더 허용했어요. 초안을 다시 올릴 수 있어요.` `operationId: allowExtraDraftRevision`
  - 브랜드의 광고 표시 확인과 허용도 `lastBrandActivityAt`을 채운다.
  - 새 버전이 제출되면 이전 버전의 확인은 무효다(확인은 버전마다 따로).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('places a comment at a second of a video for both parties', ...);
it('rejects a 301 character comment or a second past the video end', ...);   // 400
it('places card news comments on an image index and blog comments on the body', ...);
it('refuses comments on an older version', ...);                          // 409
it('refuses approval while only the brand confirmed the ad disclosure', ...);  // 409
it('approves when both confirmed and moves to APPROVED', ...);
it('records the file codes of the approved version', ...);               // approvedFileCodes = 그 판본 편들의 번호
it('refuses approval of an older version with STALE_VERSION and names the latest', ...);   // 409, details.latestVersion 2
it('rejects an approval whose version number does not match the draft', ...);   // 400
it('does not carry ad confirmations from v1 over to v2', ...);
it('lets only one of approve and a new version submission win', ...);     // Promise.all → 하나만 성공
it('refuses approval and allow-extra from the creator', ...);             // 403 FORBIDDEN (당사자지만 브랜드가 아님)
it('allows one more version after the brand allows an extra revision', ...);   // GUIDE_1: v2 가능
it('refuses allow-extra before the allowance is used up', ...);           // 409
it('accepts the link submission only after approval', ...);              // 3번 submitContentLink, REVIEWING → 409
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 초안 댓글과 광고 표시 확인 추가`, `feat: 판본 게시 승인과 수정 한 번 더 허용 추가`

---

### Task 7: 협업 종료와 보관함 줄 자동 생성

**Files:**
- Create: `api/src/keep/{keep.module.ts,collaboration-endings.service.ts,keep.repository.ts}`
- Modify (종료 지점마다 `onEnded` 호출): `api/src/settlements/{settlements.service.ts,submissions.service.ts}`(`settle`, `settleFixed`, 식사권 즉시 정산), `api/src/jobs/handlers/refund-unsubmitted.handler.ts`, `api/src/collaborations/collaborations.service.ts`(`cancel`, `acceptCancel`, `drop`), `api/src/conversations/conversations.service.ts`(`declineMessageRequest`), `api/src/safety/safety.service.ts`(차단), `api/src/offers/offers.service.ts`(결제 전 취소·`cancelForBlock`), `api/src/jobs/handlers/payment-due-expiry.handler.ts`, `api/src/ops/ops.service.ts`(`force-refund`, `force-payout`, `resume-settlement`), 그리고 가게 흐름 개정 계획이 더한 정산 확정 지점 전부(공통 규칙 21장): 맡기는 쪽의 "자료 확인했어요", 48시간 뒤 자동 확인 작업, 운영 명령 `confirm-evidence`·`resolve-dispute`. 파일과 메서드 이름은 그 계획의 것을 따른다. `SETTLED`로 바꾸는 곳을 `grep`으로 모두 찾아 빠진 곳이 없는지 확인한다.
- Test: `api/test/keep-endings.e2e-spec.ts`

**Interfaces:**
- Consumes: `keepEntriesFor`, `isEndStage` (Task 3), `JobScheduler`, `Clock`
- Produces:
  - `CollaborationEndingsService.onEnded(collaborationId: string, tx?: Prisma.TransactionClient): Promise<void>` — 협업을 읽어 `isEndStage`가 아니면 아무것도 하지 않는다. `keepEntriesFor` 결과를 `INSERT ... ON CONFLICT (owner_id, collaboration_id) DO NOTHING`으로 넣는다(`endedAt = now`). 브랜드 계약이고 `SUBMITTED` 또는 `UPLOADING` 초안이 있으면 `draft-file-cleanup`을 `now + 90일`에 등록(`jobKey = 'draft-cleanup:' + id`). 같은 협업에 여러 번 불려도 결과가 같다.
  - 종료 전이와 같은 트랜잭션 안에서 부른다(트랜잭션 밖의 작업 등록은 커밋 뒤). `keep` 모듈은 `collaborations` 모듈을 import하지 않는다(순환을 피하려고 자기 repository에서 협업 행을 읽는다).
  - `CollaborationEndingsService`를 export한다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('creates completed entries for both sides when a per-view collaboration settles', ...);
it('creates completed entries when a brand contract is paid out on day N', ...);
it('creates no entries while view evidence is unconfirmed and creates them once it is confirmed', ...);   // 성과 추가 켜진 계약: 미확인 → 0행, 확인 완료 → 2행
it('creates completed entries when view evidence is auto-confirmed after 48 hours', ...);
it('creates entries when an operator resolves a view evidence dispute', ...);
it('creates entries with the two common reasons for a funded store cancel and an unsubmitted refund', ...);
it('creates nothing when an offer is cancelled or expires before payment', ...);
it('shows the reason only to the side that dropped the negotiation', ...);   // 상대 줄 dropReason ENDED_BY_OTHER
it('creates nothing for a declined message request or a block', ...);
it('creates entries once when the settle job runs twice', ...);            // keep_entries 2행
it('creates entries when an operator force refunds a halted brand contract', ...);   // HALTED_REFUND
it('schedules draft cleanup 90 days after a settled brand contract with drafts', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: Commit** — `feat: 협업이 끝나면 양쪽 보관함에 줄 만들기`

---

### Task 8: 기한 알림과 초안 파일 정리

**Files:**
- Create: `api/src/jobs/handlers/{draft-due-reminder.handler.ts,draft-brand-reminder.handler.ts,draft-file-cleanup.handler.ts}`
- Modify: `api/src/payments/payments.service.ts`(브랜드 분기의 계약 체결 뒤 등록), `api/src/ops/commands/resume.command.ts`(브랜드 계약을 `CONTRACTED`·`GUIDED`로 되돌리면 크리에이터 알림을 다시 등록)
- Test: `api/src/jobs/handlers/draft-*.handler.spec.ts`, `api/test/draft-jobs.e2e-spec.ts`

**Interfaces:**
- Consumes: `JobScheduler`, `PushPort`, `StoragePort.remove` (Task 2), `kstDay`(4번), Task 5·6
- Produces:
  - 계약 체결(5번 `applyResult` 브랜드 분기) 뒤 `draft-due-reminder`를 `제작 시작일 00:00(한국 시간) + 14일`에 등록(`jobKey = 'draft-due:' + id`). 이미 지난 시각이면 지금 실행된다.
  - `draft-due-reminder` 처리기: 단계가 `CONTRACTED` 또는 `GUIDED`이고 `SUBMITTED` 초안이 없으면 크리에이터에게 `제작 시작일에서 14일이 지났어요. 초안을 올려 주세요.` 한 번만. 단계를 바꾸지 않는다.
  - `draft-brand-reminder` 처리기: 단계가 `REVIEWING`이고 그 초안이 최신이고 게시 승인 전이며 `lastBrandActivityAt`이 제출 뒤에 없으면 브랜드에게 `{활동 이름}님의 초안 v{n}이 확인을 기다리고 있어요.` 한 번만.
  - `draft-file-cleanup` 처리기: 그 협업의 모든 `draft_files` 경로를 `StoragePort.remove`로 지우고 `draft_versions.filesPurgedAt = now`. 댓글, 확인 기록, 버전 행은 남긴다. 두 번 실행돼도 같다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('reminds the creator 14 days after the agreed start date when no draft exists', ...);   // FakeClock, runDue
it('does not remind the creator once v1 is submitted', ...);
it('reminds the brand 3 days after a draft with no reaction', ...);
it('does not remind the brand after a brand comment or ad confirmation', ...);
it('never changes the stage from a reminder', ...);
it('removes draft files 90 days after the end and keeps comments and approvals', ...);
it('does nothing more when the cleanup job runs twice', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 초안 기한 알림 추가`, `feat: 끝난 협업의 초안 파일 정리 추가`

---

### Task 9: 회고와 보관함 API

**Files:**
- Create: `api/src/retrospectives/{retrospectives.module.ts,retrospectives.controller.ts,retrospectives.service.ts,retrospectives.repository.ts,retro-chips.ts,dto/*.ts}`, `api/src/keep/{keep.controller.ts,keep.service.ts,dto/*.ts}`
- Modify: `api/src/collaborations/dto/collaboration.model.ts`, `api/src/collaborations/collaborations.service.ts`
- Test: `api/src/retrospectives/retro-chips.spec.ts`, `api/test/retrospectives.e2e-spec.ts`, `api/test/keep.e2e-spec.ts`, `api/test/retro-privacy.e2e-spec.ts`

**Interfaces:**
- Consumes: `nextActionFor`, `newProposalFor`, `keepTabOf` (Task 3), `ContentDraftPort.generateGreeting` (Task 2), Task 7, 4번 `VisibilityService`·`CampaignsService`, 2번 `StoresService`, 5번 `conversations`, `kstDay`, `Clock`
- Produces:
  - `chipsFor(role: 'CREATOR' | 'COMMISSIONER'): { good: RetroChip[]; change: RetroChip[] }` (`retro-chips.ts`) — 크리에이터 good `FREEDOM, FAST_FEEDBACK, ACCURATE_INFO, PAYMENT_PROMISE`, change `DELIVERY, TRIAL_PERIOD, REVISION_COUNT, CREATOR_RESPONSE_SPEED`. 맡기는 쪽 good `QUALITY, ON_SCHEDULE, COMMUNICATION, UNDERSTANDING`, change `SCHEDULE, REVISION_PROCESS, COMMISSIONER_RESPONSE_SPEED, TERMS`.
  - `RetrospectiveModel { collaborationId; counterpartName; goodPoints: RetroChip[]; changePoints: RetroChip[]; nextAvailableFrom: string | null; nextHopeFee: number | null; wantAgain: boolean; updatedAt; newProposal: NewProposalTarget | null }` — `newProposal`은 요청한 사람 기준으로 `newProposalFor`가 계산한다(보관함 줄의 `nextAction`과 같은 입력). `wantAgain`은 "새 제안 만들기"면 true, "이번만 할래요"면 false다. 회고의 값은 `newProposal`에 들어가지 않는다.
  - `GET /collaborations/:id/retrospective` → 200 | 404 — 내 회고만. 없거나, 당사자가 아니거나, 상대의 것만 있으면 404. `operationId: getMyRetrospective`
  - `PUT /collaborations/:id/retrospective` 본문 `{ goodPoints; changePoints; nextAvailableFrom?: string | null; nextHopeFee?: number | null; wantAgain: boolean }` → 200 — 당사자만, `SETTLED`일 때만(아니면 409 `정산이 끝난 뒤에 회고를 남길 수 있어요.`). 내 역할의 항목이 아니면 400. 한 트랜잭션에서 회고 upsert, 내 보관함 줄의 `availableFrom`, `hopeFee`, `wantAgain`을 회고 값으로 덮어쓴다. `operationId: saveMyRetrospective`
  - `KeepEntryModel { id; collaborationId; kind: 'COMPLETED' | 'DROPPED'; dropReason: KeepDropReason | null; hasRetrospective: boolean; wantAgain: boolean | null; counterpart: { userId; kind: 'STORE' | 'BRAND' | 'CREATOR'; name; photoUrl: string | null }; contextLabel: string; availableFrom: string | null; hopeFee: number | null; endedAt; hasContract: boolean; conversationId: string; canMakeGreeting: boolean; nextAction: NextAction | null }`
  - `GET /keep-entries?tab=all|completed|dropped` → 200 `KeepEntryModel[]` — 내 줄만, `keepTabOf`로 거르고 `endedAt` 최근 순. `canMakeGreeting`은 대화방이 `CLOSED`가 아닐 때. `hasContract`는 계약이 `CONCLUDED`일 때. `operationId: listKeepEntries`
  - `PATCH /keep-entries/:id` 본문 `{ availableFrom?: string | null; hopeFee?: number | null }` → 200 `KeepEntryModel` — 내 줄만(아니면 404). `operationId: updateKeepEntry`
  - `POST /keep-entries/:id/greeting` → 200 `{ conversationId; text }` — 내 줄만. 대화방이 닫혔으면 409 `대화가 종료돼 메시지를 만들 수 없어요.` 하루 10번(한국 날짜, `greetingDay`·`greetingsOnDay` 조건부 갱신)을 넘으면 429 `RATE_LIMITED`. 포트가 실패하면 503 대신 409 `메시지를 만들지 못했어요. 잠시 뒤 다시 시도해 주세요.` 메시지를 보내지 않는다. `operationId: createReconnectGreeting`
  - `CollaborationModel`에 `canWriteRetrospective: boolean`(`SETTLED`), `hasMyRetrospective: boolean` 추가 — 요청한 사람 기준으로만 계산한다.
  - 상대에게 가는 모델(`CollaborationModel`, `ConversationDetailModel`, `ContractModel`, `DraftVersionModel`, 상대의 `KeepEntryModel`)에는 회고·보관함 칸이 없다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('lists the four good and four change chips for each role', ...);
it('refuses a retrospective before settlement', ...);                    // PUBLISHED → 409
it('rejects a commissioner chip in a creator retrospective', ...);       // 400
it('saves, edits and copies date and fee into my keep entry', ...);
it('returns a new proposal target with the saved retrospective when one can be sent', ...);   // 사장님 → F1, 크리에이터
it('returns no new proposal target for a blocked counterpart but still saves', ...);
it('leaves the ended collaboration terms, contract and settlement untouched after want-again', ...);
it('returns 404 for the counterpart retrospective and for a non-party', ...);
it('never returns my retrospective or keep values to the counterpart', ...);   // 상대의 협업·대화·계약·초안·보관함 응답 전체에 희망 제작비 7770000과 '2027-03-03' 없음
it('rejects a hope fee not in 10000 steps or a past available date', ...);
it('lists completed, dropped and want-again entries on the right tabs', ...);
it('returns 404 when editing another user keep entry', ...);
it('builds a greeting for an open conversation without sending it', ...);    // messages 행 수 그대로
it('refuses a greeting for a blocked conversation', ...);                // 409
it('limits greetings to ten per Korean day', ...);                       // 11번째 429
it('offers send offer to a store owner and like campaign to a creator', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 나만 보는 회고 추가`, `feat: 보관함 목록·편집·재협업 인사 글 추가`

---

### Task 10: 앱 — 기획 가이드(13)와 진행 단계 연결

**Files:**
- Create: `app/lib/features/production/domain/{production_guide.dart,production_repository.dart}`, `data/api_production_repository.dart`, `presentation/viewmodels/production_guide_view_model.dart`, `presentation/pages/production_guide_page.dart`, `presentation/widgets/{guide_columns.dart,scene_editor.dart}`, `presentation/production_text.dart`
- Modify: `app/lib/features/negotiation/presentation/pages/brand_progress_page.dart`(07), `app/lib/main.dart`, `app/lib/core/navigation/app_router.dart`
- Test: `app/test/features/production/guide_*_test.dart`, `app/test/features/negotiation/brand_progress_page_test.dart`(추가)

**Interfaces:**
- Consumes: `cora_api`의 `getProductionGuide`, `saveProductionGuideDraft`, `requestGuideReview`, `requestGuideRevision` (Task 4), `getCollaboration`, 가게 흐름 개정 계획의 F8 공용 상태 위젯·F4 라우트·"조회 자료와 보상 계산 확인" 줄 위젯
- Produces:
  - `class ProductionGuide`(서버 모델과 같은 항목)
  - `abstract class ProductionRepository { Future<ProductionGuide> fetchGuide(String collaborationId); Future<ProductionGuide> saveGuideDraft(String collaborationId, List<String> scenes); Future<ProductionGuide> requestGuideReview(String collaborationId, List<String> scenes); Future<ProductionGuide> requestRevision(String collaborationId); … }`(초안 메서드는 Task 11이 더한다). `productionRepositoryProvider`는 `UnimplementedError` 기본값, `main.dart`에서 override.
  - `ProductionGuideViewModel(collaborationId)`: 장면 이름 고치기, 끌어서 순서 바꾸기, 더하기(5개에서 멈춤), 빼기(1개 아래로 가지 않음), `saveDraft()`, `requestReview()`.
  - `production_text.dart`: `guideHeaderLine(int termsVersion, String title)` = `합의 버전 {n} 연결 · {제목}`
  - 라우트 `/collaborations/:id/guide`
  - 07 연결: 4단계 줄 → 가이드, 5단계 줄 → `/collaborations/:id/drafts`, 6단계 줄 → 크리에이터는 `APPROVED`일 때 3번의 링크 제출 화면. 주 버튼은 단계와 역할로 정한다(`progressAction(stage, role, {required bool viewBonus, required bool evidenceReady})`, 순수 함수). 2026-11-12 캔버스의 07은 주 버튼 자리가 위쪽의 `지금 할 일` 상자다(4번 설계 07, 4번 계획이 만든다). `CONTRACTED` 뒤에는 `progressAction`의 문구를 그 상자에 넣고(설계 3장의 표), 내 차례가 아니면 상자를 숨긴다. 아래 버튼을 따로 만들지 않는다. 4번 계획이 만든 07에 그 상자가 없으면 멈추고 소유자에게 묻는다. 계약이 체결됐으면 위 오른쪽에 `계약서 보기`(→ 5번 계약 화면).
  - 07의 6단계 줄 아래: 성과 추가가 켜져 있고 링크를 제출한 뒤이면 가게 흐름 개정 계획의 "조회 자료와 보상 계산 확인" 줄(상태 표지 포함)을 그대로 놓고 F4를 연다. 꺼진 계약에는 놓지 않는다.

화면 문구:
- 13(크리에이터): 머리 `기획 가이드`, 맨 위 줄 `합의 버전 {n} 연결 · {콘텐츠 제목}`, `정보는 정확하게, 표현은 나답게.` 두 열 `브랜드가 정해요` / `내가 정해요`. `장면 흐름 제안`, 장면 줄마다 번호와 이름 입력란, `장면 더하기`(5개면 숨김). 아래 버튼 둘(캔버스의 너비 비 1 : 1.3): `나만 보는 초안 저장`, `브랜드에 검토 요청`. 나만 보는 저장 뒤 `나만 보는 초안으로 저장했어요. 브랜드에게는 아직 보이지 않아요.` 검토 요청 뒤 `브랜드에 검토를 요청했어요.` 더 고칠 수 없으면(`canEdit` false) 두 버튼 자리에 `검토 요청한 방향이에요`(꺼짐) 하나.
- 방향 수정 요청이 와 있으면 위 띠 `브랜드가 방향 수정을 요청했어요. 대화에서 의견을 확인하고 다시 검토 요청해 주세요.`
- 13(브랜드, 읽기 전용): 맨 위 줄은 같다. 두 열 머리 `브랜드가 정해요` / `크리에이터가 정해요`. 검토 요청 전 `크리에이터가 기획 방향을 정리하고 있어요.` 버튼 `방향 수정 요청`(`canRequestRevision`일 때) → 확인 `방향 수정을 요청할까요? 크리에이터가 한 번 다시 검토를 요청할 수 있어요. 의견은 대화로 전해 주세요.` / `요청하기` / `취소`. 요청 뒤 `방향 수정을 요청했어요.`
- 불러오는 중과 불러오기 실패는 F8 공용 상태 위젯이다(실패 제목은 `기획 가이드를 불러오지 못했어요`, 설명과 버튼은 F8 그대로).
- 07의 주 버튼(`progressAction`): `CONTRACTED` 크리에이터 `기획 방향 정하기` / 브랜드 `기획 가이드 보기` · `GUIDED` 크리에이터 `초안 올리기` / 브랜드 `기획 가이드 보기` · `REVIEWING` `초안 검토하기` · `APPROVED` 크리에이터 `게시 링크 제출하기` / 브랜드 `게시 승인한 판본 보기` · `PUBLISHED` 성과 추가가 켜져 있고 계산이 만들어졌으면 `조회 자료 확인하기`(→ F4), 그 밖에는 없음 · `SETTLED` `회고 남기기`(있으면 `회고 고치기`).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('maps each stage and role to the progress action', ...);              // GUIDED·creator → '초안 올리기'
testWidgets('shows both columns and three suggested scenes', ...);
testWidgets('adds scenes up to five and hides the add button', ...);
testWidgets('reorders scenes by dragging', ...);
test('writes the agreed version line above the title', ...);                // '합의 버전 2 연결 · 출근 전 30초, 오늘의 손목 루틴'
test('offers the view evidence action only for a published contract with a view bonus', ...);
testWidgets('shows the two canvas buttons side by side', ...);              // '나만 보는 초안 저장', '브랜드에 검토 요청'
testWidgets('a private draft save keeps both buttons and says the brand cannot see it', ...);
testWidgets('requesting review shows the confirmation and locks the buttons', ...);    // '검토 요청한 방향이에요'
testWidgets('the brand sees the guide read-only with the creator column title', ...);
testWidgets('the brand requests a revision after confirmation', ...);
testWidgets('the creator sees the revision banner and can request review again', ...);
testWidgets('progress steps 4 to 6 open the guide, drafts and link submission', ...);
testWidgets('step 6 shows the view evidence row and opens F4 when the view bonus is on', ...);
testWidgets('shows the shared loading and error states', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test`. 화면 이동은 `CoraTransitions.push`, 확인은 `CoraTransitions.sheet`.
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 기획 가이드 화면 추가`, `feat: 진행 단계에서 기획·초안·링크 제출·성과 확인으로 잇기`

---

### Task 11: 앱 — 초안 검토(14)와 초안 올리기

**Files:**
- Create: `app/lib/features/production/domain/{draft_overview.dart,draft_version.dart,draft_comment.dart,draft_uploader.dart}`, `data/{supabase_resumable_draft_uploader.dart}`, `presentation/viewmodels/{draft_review_view_model.dart,draft_upload_view_model.dart}`, `presentation/pages/{draft_review_page.dart,draft_upload_page.dart}`, `presentation/widgets/{draft_video_player.dart,comment_scrubber.dart,image_pager.dart,blog_body_view.dart,comment_composer.dart,version_switcher.dart}`
- Modify: `app/lib/features/production/domain/production_repository.dart`, `data/api_production_repository.dart`, `production_text.dart`, `app/lib/main.dart`, `app/lib/core/navigation/app_router.dart`
- Test: `app/test/features/production/draft_*_test.dart`

**Interfaces:**
- Consumes: `cora_api`의 `getDraftOverview`, `createDraftVersion`, `reissueDraftUploadTokens`, `completeDraftVersion`, `abandonDraftVersion`, `getDraftVersion`, `createDraftComment`, `setDraftAdDisclosure`, `approveDraftVersion`, `allowExtraDraftRevision` (Task 5, 6)
- Produces:
  - `ProductionRepository`에 추가: `fetchOverview`, `createVersion(String id, List<PieceManifest>)`, `reissueTokens(String draftId)`, `complete(String draftId)`, `abandon(String draftId)`, `fetchVersion(String draftId)`, `comment(String draftId, CommentInput)`, `setAdDisclosure(String draftId, bool)`, `approve(String draftId, int version)`(409 `STALE_VERSION`은 `StaleDraftVersion(latestVersion, latestDraftId)`로 던진다), `allowExtra(String id)`
  - `abstract class DraftUploader { Stream<UploadProgress> upload(UploadTarget target, String localFilePath); Future<void> cancel(String fileId); }` — `UploadProgress { fileId; sentBytes; totalBytes; state: UploadState(running | paused | done | failed) }`. `draftUploaderProvider`는 `UnimplementedError` 기본값. 실제 구현의 요구 동작: TUS 프로토콜, 6MB 조각, 연결이 끊기면 `paused`로 바꾸고 연결이 돌아오면 마지막으로 받은 위치부터 이어 올림, 앱을 다시 켜면 기기에 저장한 업로드 주소로 이어 올림(토큰이 만료됐으면 `reissueTokens` 후 이어 올림, 서버가 주소를 모르면 그 파일만 처음부터). 패키지는 실행자가 고른다.
  - 영상 고르기 전 검사(앱에서 먼저): 형식, 300MB, 길이 180초(길이는 재생기 메타데이터로 읽는다).
  - `DraftReviewViewModel(collaborationId, {String? draftId})`: 버전·편 고르기, 영상의 현재 시각, 고른 댓글, `urlsExpireAt` 5분 전 또는 재생 오류 403이면 `fetchVersion`으로 주소를 새로 받는다.
  - 영상 재생기의 요구 동작: 서명 주소 스트리밍 재생, 재생·멈춤, 막대 끌기, 막대 위에 댓글 위치 표시(같은 초에 여럿이면 한 점과 수), 표시나 댓글을 누르면 그 초로 이동하고 멈춤. 패키지는 실행자가 고른다.
  - `production_text.dart`에 추가: `timecode(int seconds)`(`0:12`, `1:05`), `composerHint(Anchor)`, `pieceTabLabel(int index)`(`1편`), `versionLabel(int v)`(`v2`), `reviewTitle(DraftPieceKind kind, int version, String fileCode)`(`영상 v2 · 파일 #A12 검토`, 카드뉴스 `카드뉴스 v2 · 파일 #A12 검토`, 블로그 `글 v2 · 파일 #A12 검토`), `approveLabel(int version)`(`이 판본(v2) 게시 승인`)
  - 라우트 `/collaborations/:id/drafts`(최신 버전, 없으면 빈 상태), `/collaborations/:id/drafts/:draftId`, `/collaborations/:id/drafts/upload`

화면 문구:
- 14: 머리 `영상 v{n} · 파일 #{번호} 검토`(`reviewTitle`. 편이 여럿이면 고른 편의 번호). 편이 둘 이상이면 위에 `1편` `2편` `3편`. 오른쪽 위 버전 고르기 `v1` `v2`…(지난 버전은 읽기만, 위 띠 `지난 초안이에요. 댓글은 최신 초안에만 남길 수 있어요.`).
- 영상 아래 고른 댓글 상자: `{시각} · {작성자 이름}`과 내용. 댓글 목록. 입력란 `{시각} 구간에 댓글 남기기`(카드뉴스 `{n}번째 장에 댓글 남기기`, 블로그 `본문 전체에 댓글 남기기` / `{n}번째 사진에 댓글 남기기`), 300자를 넘기면 보내기가 꺼지고 `300자까지 남길 수 있어요.`
- 스위치 `광고 표시를 확인했어요`(내 쪽), 옆에 상대 상태 `{브랜드 | 크리에이터}도 확인했어요` / `{브랜드 | 크리에이터}는 아직 확인 전이에요`.
- 브랜드 주 버튼 `이 판본(v{n}) 게시 승인`(`approveLabel`) — 양쪽 확인 전에는 꺼짐과 `양쪽 모두 광고 표시를 확인하면 누를 수 있어요.` 크리에이터 자리 `브랜드의 게시 승인을 기다리고 있어요.` 승인 뒤 양쪽 `판본 v{n} · 파일 #{번호}의 게시가 승인됐어요.`(편이 여럿이면 번호를 쉼표로 잇는다), 크리에이터는 `게시하고 링크를 제출해 주세요.`와 `게시 링크 제출하기`.
- 승인을 누른 사이 새 판본이 올라왔으면(`StaleDraftVersion`) F8 공용 상태 위젯의 옛 판본 모양으로: 제목 `이전 판본이라 승인할 수 없어요`, 설명 `크리에이터가 판본 v{n}을 올렸어요. 새 판본을 확인한 뒤 승인해 주세요.`, 버튼 `판본 v{n} 보기`(→ 그 판본의 14).
- 불러오는 중은 F8의 `불러오는 중`, 영상이나 화면을 불러오지 못하면 F8의 `영상을 불러오지 못했어요` / `연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.` / `다시 시도` 그대로(카드뉴스·블로그는 제목만 `초안을 불러오지 못했어요`).
- 크리에이터의 `새 버전 올리기`. 다 썼으면 꺼지고 `합의한 수정 횟수를 다 썼어요. 더 고치려면 브랜드가 수정을 허용해야 해요.` 브랜드는 그때 `수정 한 번 더 허용` → 확인 `크리에이터가 초안을 한 번 더 올릴 수 있어요. 제작비는 바뀌지 않아요.` / `허용하기` / `취소`.
- 빈 상태(F8 공용 상태 위젯의 빈 목록 모양): 크리에이터 `기획 방향대로 만든 초안을 올려 주세요.` + `초안 올리기`, 브랜드 `크리에이터가 초안을 준비하고 있어요.`
- 정리된 버전: 영상 자리에 `보관 기간이 지나 초안 파일을 지웠어요. 댓글은 남아 있어요.`
- 올리기: 머리 `초안 올리기`, 편마다 `영상 고르기`(카드뉴스 `사진 고르기 (최대 10장)`, 블로그 `본문`(5,000자, 남은 글자 수) + `사진 고르기 (선택, 최대 10장)`). 안내 `3분, 300MB 이하의 MP4나 MOV 영상을 올려 주세요.` 버튼 `초안 v{n} 올리기`. 진행 `올리는 중 {p}%`, 끊김 `연결이 끊겨 멈췄어요. 다시 연결되면 이어서 올려요.` + `이어 올리기`, 완료 뒤 14로 가며 `초안 v{n}을 올렸어요. 브랜드에게 알렸어요.` 오류 `3분이 넘는 영상은 올릴 수 없어요.`, `300MB가 넘는 영상은 올릴 수 없어요.`, `MP4나 MOV 영상만 올릴 수 있어요.`, `사진은 10장까지 올릴 수 있어요.` 떠날 때 확인 `올리기를 그만둘까요? 올린 파일은 지워져요.` / `그만두기` / `계속 올리기`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('formats timecodes and composer hints for each anchor', ...);          // '0:12 구간에 댓글 남기기'
test('resumes from the last acknowledged offset after a pause', ...);       // FakeDraftUploader
test('reissues tokens and resumes when the stored token expired', ...);
testWidgets('marks comments on the scrubber and seeks when one is tapped', ...);
testWidgets('posts a comment at the paused second', ...);
testWidgets('switches pieces and shows image index comments for card news', ...);
test('titles the review by format, version and file code', ...);            // '영상 v2 · 파일 #A12 검토'
testWidgets('the header follows the file code of the selected piece', ...);
testWidgets('labels the approve button with the version being viewed', ...);   // '이 판본(v2) 게시 승인'
testWidgets('keeps the approve button off until both sides confirm', ...);
testWidgets('approving sends the viewed version number and shows the approved file code', ...);
testWidgets('shows the stale version state and opens the latest version', ...);   // '이전 판본이라 승인할 수 없어요' → '판본 v3 보기'
testWidgets('shows the shared loading and video error states', ...);        // '영상을 불러오지 못했어요', '다시 시도'
testWidgets('the creator sees the waiting text instead of approve', ...);
testWidgets('shows the exhausted message and the brand allow-extra action', ...);
testWidgets('older versions are read-only with the past-version banner', ...);
testWidgets('refreshes signed urls before they expire', ...);
testWidgets('rejects a video longer than three minutes before uploading', ...);
testWidgets('shows progress, pause and resume while uploading', ...);
testWidgets('shows the purged message instead of the player', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — iPhone과 중저가 Android 실기기에서 200MB 영상을 올리다 비행기 모드를 켰다 끄고, 앱을 껐다 켜서 이어 올라가는지 확인한다.
- [ ] **Step 5: Commit** — 커밋 세 개: `feat: 초안 이어 올리기 추가`, `feat: 초안 검토 화면과 구간 댓글 추가`, `feat: 광고 표시 확인과 판본 게시 승인 화면 추가`

---

### Task 12: 앱 — 회고(15)와 보관함(D5)

**Files:**
- Create: `app/lib/features/retrospective/domain/{retrospective.dart,retro_chip.dart,retrospective_repository.dart}`, `data/api_retrospective_repository.dart`, `presentation/viewmodels/retrospective_view_model.dart`, `presentation/pages/retrospective_page.dart`, `app/lib/features/keep/domain/{keep_entry.dart,keep_repository.dart}`, `data/api_keep_repository.dart`, `presentation/viewmodels/{keep_list_view_model.dart,keep_entry_edit_view_model.dart}`, `presentation/pages/{keep_list_page.dart,keep_entry_edit_sheet.dart,profile_menu_page.dart}`, `presentation/keep_text.dart`
- Modify: `app/lib/features/collaboration/presentation/pages/{collaboration_page.dart,store_collaboration_page.dart}`(`SETTLED`에 `회고 남기기`), `app/lib/features/store_home/…`(`내 가게`의 `보관함`), 브랜드·크리에이터 하단 메뉴의 `프로필`, `app/lib/features/chat/presentation/viewmodels/chat_thread_view_model.dart`(`prefillDraft(String text)`), `app/lib/main.dart`, `app/lib/core/navigation/app_router.dart`
- Test: `app/test/features/retrospective/`, `app/test/features/keep/`

**Interfaces:**
- Consumes: `cora_api`의 `getMyRetrospective`, `saveMyRetrospective`, `listKeepEntries`, `updateKeepEntry`, `createReconnectGreeting` (Task 9), 4번 `DiscoveryRepository.decide`, 2번 `StoreBrowseRepository.apply`, `won()`, 가게 흐름 개정 계획의 F1 라우트(받는 사람 인자)·F6 라우트(가게 인자)·F8 공용 상태 위젯
- Produces:
  - `abstract class RetrospectiveRepository { Future<Retrospective?> fetchMine(String collaborationId); Future<Retrospective> save(String collaborationId, RetrospectiveInput input); }`
  - `abstract class KeepRepository { Future<List<KeepEntry>> fetch(KeepTab tab); Future<KeepEntry> update(String id, {DateTime? availableFrom, int? hopeFee}); Future<({String conversationId, String text})> makeGreeting(String id); }`
  - `keep_text.dart`(순수 함수): `keepTitle(UserRole)`, `statusLine(KeepEntry)`, `retroChipLabel(RetroChip, {required bool storeOwner})`, `wantAgainQuestion(counterpartKind)`, `nextActionLabel(NextAction)`
  - `RetrospectiveViewModel(collaborationId)`: `justThisOnce()`(`wantAgain: false`로 저장하고 닫는다), `makeNewProposal()`(`wantAgain: true`로 저장하고 응답의 `newProposal`을 돌려준다). 화면은 `newProposal.screen`이 `F1`이면 받는 사람(`recipientKind`, `recipientId`, `campaignId`)을 넘겨 F1을, `F6`이면 그 가게로 F6을 연다. `KEEP`이나 null이면 안내를 보여 주고 `/keep`으로 간다. F1·F6에 회고의 값(가능한 날, 희망 제작비, 고른 항목)을 넘기지 않는다.
  - `ChatThreadViewModel.prefillDraft(text)` — 입력란에 글을 넣고 보내지는 않는다. 입력란이 비어 있지 않으면 확인 `입력 중인 글을 바꿀까요?` / `바꾸기` / `취소`.
  - 라우트 `/collaborations/:id/retrospective`, `/keep`, `/profile`(브랜드·크리에이터). 프로필 탭이 아직 준비 중 화면이면 `ProfileMenuPage`(줄 `보관함`)로 바꾼다. 7번 계획이 프로필 화면을 만들면 이 줄을 그 화면으로 옮긴다.

화면 문구:
- 15: 위 `상대에게 보이지 않는 회고`, 상대 이름, `게시 완료`(가게 협업도 같은 표지). `잘 맞았던 점`(여러 개): 크리에이터 `촬영 방식의 자유`, `빠른 피드백`, `정확한 제품 정보`, `정산 약속` / 브랜드·사장님 `콘텐츠 완성도`, `일정 준수`, `소통`, `브랜드 이해`(사장님은 `가게 이해`). `다음엔 바꾸고 싶은 점`(여러 개): 크리에이터 `배송 기간`, `제품 사용 기간`, `수정 횟수`, `소통 속도` / 브랜드·사장님 `일정`, `수정 과정`, `소통 속도`, `조건`. `다음에 가능한 날`(날짜 고르기, 오늘부터), `다음 희망 제작비`(1만 원 단위). 질문 `이 브랜드와 다시 만날래요?`(상대가 가게면 `이 가게와 다시 만날래요?`, 맡기는 쪽은 `이 크리에이터와 다시 만날래요?`) → 버튼 둘 `이번만 할래요` / `새 제안 만들기`. 아래 `회고는 나만 봐요. 새 제안은 지난 합의를 고치지 않고 새로 만들어요.` 따로 저장 버튼은 없고 두 버튼이 각각 저장한다. `이번만 할래요` → 저장하고 닫으며 `회고를 저장했어요.` `새 제안 만들기` → 저장하고 F1(크리에이터가 가게에게면 F6)을 연다. 크리에이터가 브랜드에게면(`KEEP`) `브랜드에게는 보관함에서 관심을 보내 다시 시작할 수 있어요.`와 함께 보관함으로 간다. 새 제안을 보낼 수 없는 상대면 `지금은 새 제안을 보낼 수 없어요. 보관함에 남겨 둘게요.`와 함께 보관함으로 간다. 고칠 때(`회고 고치기`)도 같은 화면, 같은 두 버튼이다.
- D5(2026-11-12 캔버스에서 바뀌지 않았다): 머리 `보관함`, 제목 `다시 만나고 싶은 브랜드`(브랜드·사장님 `다시 만나고 싶은 크리에이터`), 설명 `일정이나 예산 때문에 무산된 상대도 여기에 남아요.` 탭 `전체`, `완료한 협업`, `무산된 상대`. 줄: 사진, 이름, 상태(`협업 완료` / `협업 완료, 비공개 회고 저장됨` / `일정이 맞지 않아 무산` / `예산이 맞지 않아 무산` / `방향이 달라 무산` / `기타 사유로 무산` / `협의가 끝나 무산` / `진행 중 취소` / `기한 안에 올리지 못함` / `진행 중 중단`), `가능한 날` / `{날짜} 이후`, `희망 제작비` / `{won}`(값이 없으면 `아직 없어요`), 버튼 `재협업 메시지 만들기`, `계약 보기`(`hasContract`일 때), 다음 걸음(`오퍼 보내기` / `관심 보내기` / `지원하기`). 줄을 누르면 편집 시트(`가능한 날`, `희망 제작비`, `저장`). 빈 목록(F8 공용 상태 위젯의 빈 목록 모양, 버튼 없음) `아직 보관한 상대가 없어요. 협업이 끝나면 여기에 모여요.` 불러오는 중과 실패도 F8 위젯이다(실패 제목 `보관함을 불러오지 못했어요`).
- `재협업 메시지 만들기` → 그 대화방을 열고 입력란에 글을 넣는다. 대화방이 닫혔으면 버튼이 꺼지고 `대화가 종료된 상대예요.` 429면 `오늘은 더 만들 수 없어요.`
- 다음 걸음 결과: `관심을 보냈어요. 상대도 고르면 알려드려요.`, `지원했어요. 사장님이 고르면 오퍼가 도착해요.`, `오퍼 보내기`는 2번 A5로.
- 협업 화면(A7, 사장님 진행, 07)의 `SETTLED`: `회고 남기기`(있으면 `회고 고치기`).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('titles the keep list by role', ...);                                 // creator → '다시 만나고 싶은 브랜드'
test('describes each keep status the way the canvas does', ...);          // '협업 완료, 비공개 회고 저장됨'
testWidgets('shows role-specific chips and the privacy note', ...);
testWidgets('shows the two canvas buttons and no separate save button', ...);   // '이번만 할래요', '새 제안 만들기'
testWidgets('just this once saves with want-again false and closes', ...);
testWidgets('new proposal saves with want-again true and opens F1 with the counterpart as recipient', ...);
testWidgets('a creator new proposal toward a store opens F6 for that store', ...);
testWidgets('a creator new proposal toward a brand goes to the keep list with the like hint', ...);
testWidgets('new proposal falls back to the keep list when no proposal can be sent', ...);   // '지금은 새 제안을 보낼 수 없어요. 보관함에 남겨 둘게요.'
testWidgets('passes no retrospective value to the proposal screen', ...);
testWidgets('loads a saved retrospective for editing', ...);
testWidgets('shows the shared empty state for an empty keep list', ...);
testWidgets('filters entries by the three tabs', ...);
testWidgets('edits the available date and hope fee from the sheet', ...);
testWidgets('the greeting opens the conversation with the text in the composer and sends nothing', ...);
testWidgets('the greeting button is off for a closed conversation', ...);
testWidgets('shows contract and next-step buttons only when available', ...);
testWidgets('the store owner opens the keep list from my store', ...);
testWidgets('settled collaborations offer to leave a retrospective', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 나만 보는 회고 화면 추가`, `feat: 보관함과 재협업 메시지 만들기 추가`

---

### Task 13: 전체 흐름 확인

**Files:** 없음

- [ ] **Step 1: 자동 확인** — `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db` · `cd app && flutter analyze && flutter test` · `./scripts/gen-api.sh && git status --short`(변경 없음)

- [ ] **Step 2: 네 계정으로 수동 확인** (A 브랜드, B 크리에이터, C 가게, D 크리에이터. 날짜는 3번의 `FAKE_CLOCK_OFFSET_DAYS`로 건너뛴다. iOS와 Android 각각.)

1. A·B가 수정 범위 `기획안 기준 1회`로 계약까지 간다(5번 흐름). B: 07 `기획 방향 정하기` → 13에 두 열과 장면 `세안`, `옷 고르기`, `주얼리 착용` → 맨 위 줄 `합의 버전 {n} 연결 · {제목}`의 번호가 계약한 조건 버전과 같다 → 장면 하나 더하고 순서를 바꿔 `나만 보는 초안 저장` → 07은 그대로 3단계 완료, A의 13에는 `크리에이터가 기획 방향을 정리하고 있어요.`만 보이고 알림이 없다 → B가 초안을 올리려 하면 `기획 방향을 브랜드에 먼저 검토 요청해 주세요.` → `브랜드에 검토 요청` → 07 `4단계 진행 중`. A: 푸시와 읽기 전용 13.
2. A: `방향 수정 요청` → B: 띠 → 장면을 고쳐 `나만 보는 초안 저장`(A에게는 지난번 내용이 그대로 보인다) → `브랜드에 검토 요청` → 버튼 `검토 요청한 방향이에요`. A의 `방향 수정 요청`이 사라진다.
3. B: 2분 50초, 250MB MOV를 올리다 비행기 모드 → `연결이 끊겨 멈췄어요…` → 다시 켜서 이어 올림 → 앱을 껐다 켜도 이어짐 → `초안 v1을 올렸어요…`. 3분 10초 영상은 고르는 순간 거절.
4. A·B: 14의 머리가 `영상 v1 · 파일 #{번호} 검토`이고 양쪽에 같은 번호가 보인다. 0:12에 댓글, 서로 바로 보이고 막대 위 표시를 누르면 그 초로 간다. A가 먼저 광고 표시를 켜도 `이 판본(v1) 게시 승인`은 꺼져 있다. B가 켠다 → A `이 판본(v1) 게시 승인` → 양쪽 `판본 v1 · 파일 #{번호}의 게시가 승인됐어요.`, B `게시하고 링크를 제출해 주세요.`
5. 승인 전으로 돌아가 확인(새 계약): B가 v2를 올리려 하면 `합의한 수정 횟수를 다 썼어요…` → A `수정 한 번 더 허용` → A가 v1의 14를 열어 둔 채로 B가 v2를 올린다 → A가 v1에서 승인을 누르면 `이전 판본이라 승인할 수 없어요`와 `판본 v2 보기` → v2의 파일 번호가 v1과 다르고, v1 댓글이 남아 있고, v2의 광고 표시 확인은 양쪽 모두 꺼져 있다.
6. 제3자 D의 토큰으로 `GET /drafts/:id` → 404. A가 받은 서명 주소를 61분 뒤 열면 거절된다.
7. B: 링크 제출 → 지급일까지 건너뛴다 → 양쪽 보관함에 `협업 완료`. B: `회고 남기기`(가능한 날, 희망 제작비 `40만 원`) → 아래 안내가 `회고는 나만 봐요. 새 제안은 지난 합의를 고치지 않고 새로 만들어요.` → `새 제안 만들기` → A에게 진행 중인 다른 캠페인이 있으면 `브랜드에게는 보관함에서 관심을 보내 다시 시작할 수 있어요.`와 함께 보관함으로 가고 그 줄에 `관심 보내기`가 있다. 없으면 `지금은 새 제안을 보낼 수 없어요. 보관함에 남겨 둘게요.` → 보관함 `협업 완료, 비공개 회고 저장됨`, `40만 원`. 끝난 협업의 조건 버전과 계약은 그대로다. A의 화면 어디에도 B의 회고 값이 없다. A도 회고에서 `새 제안 만들기` → (A에게 다른 진행 중 캠페인이 있을 때) B가 받는 사람인 F1.
7-1. 성과 추가를 켠 계약(새 계약, B는 인스타그램 연동): 링크 제출 → 측정 기간을 건너뛴다 → 07의 6단계 아래 `조회 자료와 보상 계산 확인` 줄과 표지 `미확인`, 주 버튼 `조회 자료 확인하기` → F4. 이때 양쪽 보관함에 줄이 없고 `회고 남기기`도 없다 → A가 F4에서 `자료 확인했어요` → `SETTLED`, 양쪽 보관함에 `협업 완료`, `회고 남기기`가 생긴다. 성과 추가가 꺼진 계약에는 그 줄이 없다.
8. 다른 협업: B가 계약 전 `협의 그만두기`(`예산이 맞지 않아요`) → B 보관함 `예산이 맞지 않아 무산`, A 보관함 `협의가 끝나 무산`. 이번만 할래요를 고른 완료 줄은 `전체`에 없고 `완료한 협업`에만 있다.
9. C·D 가게 협업: 결제 뒤 D가 `협업 그만두기` → 양쪽 `진행 중 취소`. 다른 오퍼는 결제 뒤 14일 건너뛰기 → `기한 안에 올리지 못함`. 결제 전 취소는 줄이 없다. C는 `내 가게 → 보관함`에서 `다시 만나고 싶은 크리에이터`와 `오퍼 보내기`를 본다. 정산까지 끝난 C·D 협업: C의 회고 `새 제안 만들기` → D가 받는 사람인 F1, D의 회고 `새 제안 만들기` → C의 가게로 F6.
10. B: `재협업 메시지 만들기` → A와의 대화방 입력란에 인사 글, 보내지 않음. 차단된 대화의 줄은 버튼이 꺼져 있다. `계약 보기`가 체결된 계약을 연다.
11. 시작일 + 14일까지 초안이 없는 계약, 초안 뒤 3일 반응 없는 계약 → 알림 로그 각 1건, 단계 그대로. 종료 90일 뒤 → 초안 화면 `보관 기간이 지나 초안 파일을 지웠어요…`, 댓글은 남음.
12. 라이트와 다크 각각, 글자 1.3배에서 13, 14(영상·카드뉴스·블로그), 올리기, 15, D5. 2026-11-12 캔버스(`Guide`, `Review`, `Retro`, `NKeepList`와 `Dark*`)와 나란히 비교한다. 다크에서 볼 곳: 14의 댓글 보내기 버튼과 켜진 광고 표시 스위치, 15의 고른 항목·`이번만 할래요`·이름 아래 막대. 빈 상태·불러오기 실패·옛 판본은 `NStates`와 비교한다.

- [ ] **Step 3: 보관함 전체 점검** — 테스트 DB의 끝난 협업마다 `keepEntriesFor`의 기대 줄과 실제 `keep_entries`를 비교하는 스크립트 `api/scripts/check-keep-entries.ts`를 만들고 실행한다. Expected: `모든 끝난 협업의 보관함 줄이 맞습니다 (n건)`.

---

## 완료 기준

- Task 13의 자동 확인, 수동 확인 13개(1~12와 7-1), 보관함 점검 통과
- `drafts` 버킷이 비공개이고 공개 주소로 읽히지 않으며, 운영 환경 모드에서 가짜 `CONTENT_DRAFT_ADAPTER`면 서버가 시작을 거부함

## 이 계획이 구체화한 것

설계 문서와 공통 규칙에 문구나 규칙이 없어 이 계획이 정한 것이다. 소유자 확인 대상이다.

| 자리 | 정한 것 |
|---|---|
| 가이드 오른쪽 열 | 원칙에서 만드는 줄: `honestReview` true `평소 말투와 솔직한 후기` / false `평소 말투로 소개`, `scriptOk` false `대본 없이 내 말로 소개`, `faceOk` false `얼굴 없이 손 중심 촬영`. 고정 두 줄이 먼저다. |
| 가이드 규칙 | 장면 이름 20자, 1~5개. 생성이 실패하면 `도입`, `제품 사용`, `마무리`. 방향 수정 요청에는 글이 없다(의견은 대화로). 요청이 걸려 있는 동안 초안을 올릴 수 없다. 나만 보는 저장은 횟수 제한이 없고 검토 요청과 같은 때에만 된다. 브랜드에게는 작업본이 있는지도 알리지 않는다. 검토 요청 뒤에는 화면에 머문다(캔버스의 14 연결은 흐름 순서로 본다). |
| 가이드 문구 | `기획 가이드`, `크리에이터가 정해요`(브랜드 화면), `장면 더하기`, `나만 보는 초안으로 저장했어요. 브랜드에게는 아직 보이지 않아요.`, `브랜드에 검토를 요청했어요.`, `검토 요청한 방향이에요`, `크리에이터가 기획 방향을 정리하고 있어요.`, `기획 가이드를 불러오지 못했어요`, 방향 수정 요청의 확인·띠·완료 문구(Task 10) |
| 초안 규칙 | 영상 길이는 앱이 읽은 값을 서버가 검사한다(서버에서 영상을 처리하지 않으므로). 댓글은 최신 버전에만. 브랜드의 "수정 한 번 더 허용"은 허용 수를 다 썼을 때만. 업로드 중인 버전은 하나이고 새로 시작하면 이전 것을 버린다. |
| 파일 번호 | 편마다 하나, 제출을 마칠 때 붙인다. 글자 하나(`I`·`O` 제외) + 숫자 두 자리를 무작위로 뽑고 협업 안에서 겹치면 다시 뽑는다. 버려진 업로드에는 번호가 없다. 승인 기록에 사본을 남기고 파일을 지운 뒤에도 남긴다. |
| 초안 문구 | 머리의 형식별 첫 낱말(`영상`, `카드뉴스`, `글`), 상대 확인 상태 두 줄, `양쪽 모두 광고 표시를 확인하면 누를 수 있어요.`, `브랜드의 게시 승인을 기다리고 있어요.`, `판본 v{n} · 파일 #{번호}의 게시가 승인됐어요.`, 옛 판본 상태의 세 문구(`이전 판본이라 승인할 수 없어요` 등), `초안을 불러오지 못했어요`, `새 버전 올리기`, 허용 확인 문구, 빈 상태 두 줄, 정리된 파일 문구, 지난 버전 띠, 올리기 화면의 안내·진행·끊김·오류·떠날 때 확인 문구(Task 11), `300자까지 남길 수 있어요.`, 카드뉴스·블로그의 입력란 문구 |
| 오류 | `기획 방향을 더 고칠 수 없어요.`, `기획 방향을 브랜드에 먼저 검토 요청해 주세요.`, `게시가 승인된 뒤에는 초안을 올릴 수 없어요.`, `기획 방향을 다시 검토 요청한 뒤 초안을 올릴 수 있어요.`, `아직 다 올라가지 않았어요.`, `양쪽이 광고 표시를 확인해야 게시를 승인할 수 있어요.`, `이전 판본이라 승인할 수 없어요`(`STALE_VERSION`), `정산이 끝난 뒤에 회고를 남길 수 있어요.`, `대화가 종료돼 메시지를 만들 수 없어요.`, `메시지를 만들지 못했어요. 잠시 뒤 다시 시도해 주세요.` |
| 알림 | `{활동 이름}님이 기획 방향 검토를 요청했어요.`, `{브랜드 이름}이 기획 방향 수정을 요청했어요. 대화에서 의견을 확인해 주세요.`, `{활동 이름}님이 초안 v{n}을 올렸어요.`, `초안 {위치} 구간에 댓글이 달렸어요.`, `판본 v{n}의 게시가 승인됐어요. 게시하고 링크를 제출해 주세요.`, `{브랜드 이름}이 수정을 한 번 더 허용했어요. 초안을 다시 올릴 수 있어요.`, `제작 시작일에서 14일이 지났어요. 초안을 올려 주세요.`, `{활동 이름}님의 초안 v{n}이 확인을 기다리고 있어요.` |
| 기한 기준 | "제작 시작일"은 계약 사본의 시작일 한국 시간 0시. "브랜드의 반응"은 댓글, 광고 표시 확인, 게시 승인, 수정 허용. |
| 보관함 규칙 | 무산 사유는 그만둔 본인에게만 보이고 상대 줄은 `협의가 끝나 무산`. `INQUIRY`에서 끝난 협업, 요청 거절, 차단으로 끝난 협업은 줄을 만들지 않는다. 브랜드 계약이 운영자 환급으로 끝나면 `진행 중 중단`. `전체` 탭은 `이번만 할래요`를 고른 완료 줄을 뺀다. 브랜드·크리에이터의 다음 걸음은 그 줄의 캠페인과 다른 진행 중 캠페인이 있을 때만. 보관함 편집은 완료 줄에도 되고, 회고를 저장하면 회고 값이 덮어쓴다. |
| 회고 | 사장님의 `브랜드 이해`는 `가게 이해`로 쓴다. 질문은 상대에 따라 `이 브랜드와` / `이 가게와` / `이 크리에이터와`. 따로 저장 버튼이 없고 `이번만 할래요`와 `새 제안 만들기`가 각각 저장한다. `회고를 저장했어요.`, `회고 고치기`, `지금은 새 제안을 보낼 수 없어요. 보관함에 남겨 둘게요.` |
| 새 제안 만들기 | 여는 곳은 보관함의 다음 걸음과 같은 규칙으로 정한다: 사장님·브랜드 → F1, 크리에이터 → 가게면 F6, 브랜드면 F1 대신 보관함의 `관심 보내기`(`브랜드에게는 보관함에서 관심을 보내 다시 시작할 수 있어요.`). 캔버스의 15는 크리에이터 → 브랜드에서 F1로 이어지므로 소유자 확인이 필요하다(설계 5장 4번). 브랜드가 얽힌 쪽은 그 줄의 캠페인과 다른 진행 중 캠페인이 있을 때만. 보낸 뒤의 저장은 가게 흐름 개정과 4·5번 계획의 것이고 이 계획은 화면을 여는 데까지다. 회고의 값은 F1·F6에 넘기지 않는다. |
| 성과 확인 | 07의 `PUBLISHED` 주 버튼 `조회 자료 확인하기`와 6단계 아래의 확인 줄은 성과 추가가 켜진 계약에만. 회고와 보관함 줄은 조회 자료가 확인돼 `SETTLED`가 된 뒤에 생긴다. |
| 보관함 문구 | 상태 문구 열 가지(Task 12), `아직 보관한 상대가 없어요. 협업이 끝나면 여기에 모여요.`, `대화가 종료된 상대예요.`, `입력 중인 글을 바꿀까요?` |
| 재협업 인사 | 사용자당 하루 10번. 가짜 인사 글 두 벌(Task 2). 인사 글에 무산 사유를 넣지 않는다. |
| 진행 단계 | 07의 단계·역할별 주 버튼 문구(Task 10)와 `계약서 보기` 위치. 새 캔버스의 `지금 할 일` 카드가 있으면 문구를 그 카드에 넣는다. |
| 화면 위치 | 브랜드·크리에이터의 프로필 탭이 준비 중이면 `보관함` 줄 하나짜리 프로필 메뉴로 바꾼다. |

## 이 계획이 하지 않는 것

- 가게 오퍼의 초안 검토(설계 5장 확인 항목 1)
- F1, F4, F6, F8 화면과 조회 자료의 계산·확인·이의 제기·캡처(가게 흐름 개정 계획), 새 제안을 보낸 뒤의 저장(가게 흐름 개정, 4·5번 계획)
- 기획 가이드에 대한 브랜드의 승인 단계(설계 5장 확인 항목 2)
- 앱 안의 영상 편집·자르기, 서버의 화질 변환과 썸네일 생성
- 상대에게 보이는 후기와 별점
- 기획 방향과 초안 사건을 대화방 안내 줄로 남기기
- 계약 뒤 문제의 자동 처리(운영자가 3번의 운영 명령으로 처리)
- 프로필 화면 자체와 포트폴리오(7번 계획), 탈퇴 때 초안 파일 삭제(탈퇴 계획)
- 실제 LLM으로 장면과 인사 글 만들기, LLM 월 상한(9번 계획)
