# 브랜드 탐색·매칭과 협업 원칙 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

**Goal:** 크리에이터가 협업 원칙을 정하고, 브랜드가 캠페인을 만들고, 양쪽이 카드를 넘겨 서로 관심이 닿으면 협업과 조건 버전 1이 만들어져 "이 판본 수락"(옛 "이 조건으로 협의")을 누를 수 있는 데까지를 만든다. 2026-11-12 개정으로 둘러보기, 넘김 되돌리기, 후보 비교표, 브랜드의 제안(F1·F2를 열어 돈과 혜택을 정함), 캠페인 예산이 더해졌다.

**Architecture:** 추천은 하루 한 번(조회할 때 없으면) 만들어 저장하는 목록이고, 점수는 순수 함수가 계산한다. 누가 누구에게 보이는지는 서버의 공통 필터 하나(`VisibilityService`)가 정하고 모든 조회가 그것을 거친다. 서로 관심이 닿는 순간 한 트랜잭션에서 `matches`, 브랜드 계약 협업(`MATCHED`), 조건 버전 1을 만든다. 조건 버전 테이블은 이 계획에서 만들고 5번 계획이 수정 제안과 계약을 더한다.

**Tech Stack:** 앞 계획들과 같다. 앱의 카드 넘기기는 Flutter의 `AnimationController`와 `SpringSimulation`으로 직접 만든다(패키지를 쓰지 않는다. 움직임을 소유자가 승인해야 하기 때문이다).

**Spec:** `docs/superpowers/specs/2026-11-11-brand-discovery-matching-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md` (1, 2, 3, 4, 5, 6, 7, 8, 14, 22, 23장) · F1·F2·F3·F8의 화면: `docs/superpowers/specs/2026-11-12-store-flow-revision-design.md`

**선행 조건:** 공통 기반, 2번, 3번, **가게 흐름 개정** 계획이 끝나 있어야 한다(공통 규칙 13장의 순서). 가게 흐름 개정 계획이 만든 F1(보상·예산 설정), F2(보내기 전 검토), F3(제안함), F8(공용 상태 위젯), 가게 모집 조건의 보상 세 요소, 단가·상한 범위 설정(`GET /config`)을 이 계획은 **쓰기만** 한다. 고치거나 다시 만들지 않는다. 그 화면과 값의 이름·인자는 개정 계획이 만든 것을 따르고, 이 계획이 요구하는 것(받는 사람과 처음 값을 넘기고, 보내기를 눌렀을 때 이 계획의 저장소를 부르는 것)을 받지 못하는 모양이면 멈추고 소유자에게 묻는다. 이 계획은 3번의 `collaborations`·`CollaborationStage`·`CollaborationsRepository.advance`, 2번의 `IndustryCategory`·`ContentFormat`·`stores`·`creator_profiles`·`StoresService`·`CreatorsService`·`UploadsService`·`Clock`, 앱의 `CoraBottomNav`·`CoraTransitions`·`roleEntryResolverProvider`·모션 갤러리를 쓴다.

## Global Constraints

앞 계획들의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것:

- 넘김과 넘긴 이유는 본인의 응답과 추천 계산에만 쓴다. 상대에게 가는 어떤 응답 모델에도 넣지 않는다. 이를 확인하는 테스트를 둔다.
- 크리에이터가 피하는 업종의 가게와 브랜드에게 그 크리에이터는 존재하지 않는 것처럼 보인다(조회 404, 목록에서 빠짐). 모든 조회는 `VisibilityService`를 거친다.
- 협업 원칙이 없는 크리에이터는 브랜드에게 보이지 않는다. 사장님에게는 보인다.
- 고정 값: 하루 추천 `10`장, 추천을 새로 만드는 기준 시각은 한국 시간 자정, 넘기기 기준 가로 `110`·세로 `-140`(가로 `80` 미만), 카드 최대 기울기 `12`도, 좋아한 점 `100`자, 콘텐츠 한 줄 `40`자.
- 민감 업종은 `ALCOHOL`, `GAMBLING`, `LOAN`, `DIET_SUPPLEMENT` 네 개다. 나머지 아홉 개가 일반 업종이다.
- 조건 버전은 만들기만 하고 고치지 않는다. 바꾸려면 새 판본을 낸다. 수락과 새 판본은 판본 번호와 함께 받고, 최신이 아니면 409 `STALE_VERSION`이다(공통 규칙 7장).
- 2026-11-12에 더한 고정 값: 둘러보기 카드 `10`장, 비교는 후보 `2`명, 캠페인 예산은 1만 원 단위이고 제작비 이상 `100000000` 이하, 최대 현금 부담 = 제작비 + 성과 추가 상한(없으면 0).
- 팔로워 수는 후보 비교의 응답에 넣지 않는다. 남은 캠페인 예산은 그 캠페인의 브랜드에게만 내려 준다. 둘러보기 카드에는 인스타그램 아이디를 넣지 않는다.
- 화면 문구는 2026-11-12 캔버스의 글자 그대로다. 설계에 "캔버스에 없는 문구"라고 적힌 것만 설계의 문구를 쓴다.
- 작업 브랜치를 만들지 않고 `main`에 바로 커밋한다. 커밋마다 테스트가 통과한 상태여야 한다.

## 2026-11-11 소유자 결정으로 더한 것 (E3~E8 계정·알림 화면)

설계: `specs/2026-11-11-account-notify-settings-design.md`. 알림 기반은 3번 계획 Task 3A, 알림함·설정·정산 화면은 3번 Task 13A~13D, 설정·프로필 수정·고객센터는 `plans/2026-11-11-account-settings.md`(7번 다음)가 만든다. 아래가 이 계획의 작업에 더해진다.

- 이 계획의 모든 알림은 `PushPort`가 아니라 3번 Task 3A의 `NotificationsService.notify`로 보낸다. 새 알림 종류는 `NOTIFICATION_CATALOG`에 탭·스위치·그림·문구를 더하고(설계 3.2 표), 앱의 `locationFor`(3번 Task 13C)에 가는 곳을 더한다. 작업 처리기에서 보내는 알림은 `dedupeKey`를 넘긴다.
- Task 5: 서로 관심은 `MUTUAL_INTEREST`(탭 매칭, 스위치 서로 관심, 가는 곳 `MATCH` → 05), 조건 확인은 `TERMS_CONFIRMED`(탭 협업, 끌 수 없음, 가는 곳 `TERMS` → 12).
- Task 9: 01 머리의 종 아이콘(캔버스 — 3번 Task 13C의 `NotificationBell`, 누르면 `/notifications`).
- Task 11: 08 머리에도 같은 종을 둔다(캔버스 밖, 로고와 `크리에이터` 알약 사이).
- Task 2: `PrinciplesService`를 export하고 `updateFeeBand(creatorId, band: FeeBand)`를 더한다. Task 4의 원칙 꼬리표 규칙(`CreatorCardModel.tags`)은 순수 함수 `principleTags`로 꺼내 둔다. 계정·설정 계획 Task 1이 E6 프로필 수정과 꼬리표에 쓰면서 순서(분야 → 원칙 표시)와 분야 표시("·" 앞만)를 캔버스 E6대로 바꾸고, 자유 꼬리표를 앞에 붙인다.

## 2026-11-12 개정으로 바뀐 것

설계의 "2026-11-12 개정"과 3장의 "저장과 관심", "브랜드의 제안", "캠페인 예산", "둘러보기"를 반영했다. 설계의 **[제안]**은 소유자 확인 전이고, 답이 없으면 제안대로 만든다.

- Task 1: `PassReason`을 `MOOD`, `REGION`, `FEE`, `FIELD`로 바꾸고(이유 없음은 null), `campaigns.budget`, `swipe_decisions`의 브랜드 제안 칸, `terms_versions`의 성과 추가 칸을 더했다.
- Task 3: 캠페인 예산과 남은 예산 계산(순수 함수).
- Task 4: 둘러보기 카드 조회, 가게 카드의 보상 줄.
- Task 5: 브랜드의 제안이 붙은 관심, 넘김 되돌리기의 조건, 저장 탭, 후보 비교 조회, 판본 수락의 `STALE_VERSION`과 인스타그램 연동 검사, 돈과 혜택만 바꾸는 새 판본.
- Task 6: 협업 조회에 확보액, 남은 캠페인 예산, 지금 할 일.
- Task 7: 다크 모드 진행 막대 색.
- Task 9: 02 시트의 새 문구와 되돌리기, 다 본 화면을 F8 위젯으로.
- Task 9A(새로): A1의 "등록 없이 먼저 둘러보기".
- Task 10: 03의 저장 탭과 비교 체크, 04 비교표, 05의 새 버튼.
- Task 11: 08 가게 카드 보상 줄, 06 "받은 제안 · 판본", 07 "지금 할 일"과 예산 칸.
- Task 12: 수동 확인 순서를 새 화면에 맞췄다.

**F1·F2·F3·F8은 쓰기만 한다.** 넷 다 가게 흐름 개정 계획이 먼저 만든다. 이 계획은 F1·F2를 받는 사람과 처음 값으로 열고, F2의 보내기가 이 계획의 저장소(`decide`의 `proposal`, `proposeReward`)를 부르게 잇는다. F3에는 07에서 가는 길만 만든다. F3에 브랜드의 줄을 채우는 것은 5번 계획이다.

**3번 코드와의 어긋남 노트.** `.superpowers/` 아래의 `plan4-preflight.md`(3번 코드와 이 계획의 어긋남을 정리한 노트)가 있으면 Task를 시작하기 전에 읽는다. 그 노트의 판단과 이 계획의 글이 다르면 노트를 따른다. 이 개정이 그 판단을 바꾸지 않는 것: 알림은 `NotificationsService.notify`로 보내고 새 종류는 `NotificationKind` 마이그레이션으로 더한다. 브랜드 협업은 `CollaborationModel`의 `kind`와 nullable `terms`로 내보내며 Task 5와 같은 커밋이다. 한국 날짜 계산은 3번의 `kst.ts`를 다시 쓴다. 업로드 경로는 `creator-cards/`다. `swipe_decisions`와 `daily_recommendations`의 유일 제약은 NULL을 따로 처리한다. `confirmTerms`는 동시에 눌러도 한 번씩만 반영한다. 앱의 하단 메뉴와 `/creator/offers`는 있는 것을 다시 쓴다. 관심에 붙이는 글은 크리에이터 40자, 브랜드 100자다. 아래 Task에서 이와 다르게 읽히는 줄(예: Task 4의 `kst-day.ts`, Task 5의 `PushPort`)은 노트 쪽이 맞다.

## Review Focus

1. **넘긴 사실이 상대에게 새는 경로** → 상대의 추천, 관심 목록, 상세, 알림 어디에도 넘김과 이유가 없다. (Task 5)
2. **양쪽이 거의 동시에 관심을 보냄** → 매칭, 협업, 조건 버전 1이 한 번만 만들어진다. (Task 5)
3. **피하는 업종을 나중에 추가함** → 이미 만들어진 오늘의 추천에서도 바로 빠진다. (Task 2, 4)
4. **추천할 상대가 한 명도 없음** → 빈 화면이 아니라 안내와 다음 행동이 보인다. (Task 9, 11)
5. **카드를 미는 도중 손을 떼거나 빠르게 연달아 넘김** → 카드가 겹치거나 결정이 두 번 저장되지 않는다. (Task 8)
6. **옛 판본을 수락하거나, 수락과 새 판본이 거의 동시에 옴** → 수락은 409 `STALE_VERSION`이고 양쪽이 서로 다른 조건으로 합의된 것처럼 보이지 않는다. (Task 5, 11)
7. **역할 없는 사용자의 둘러보기** → 피하는 업종을 고른 크리에이터와 인스타그램 아이디가 나오지 않고, 어떤 쓰기도 되지 않는다. (Task 4, 9A)
8. **남은 캠페인 예산과 넘김이 상대에게 새는 경로** → 크리에이터가 받는 응답에 예산이 없고, 되돌린 넘김과 그 이유가 어디에도 남지 않는다. (Task 5, 6)
9. **화면의 "최대 현금 부담"과 서버 값이 다름** → 06, F2, 07의 확보액이 같은 판본에서 같은 숫자다. (Task 5, 6, 11)

---

## 파일 구조

```text
api/src/
├── principles/                       # 협업 원칙
├── brands/                           # 브랜드 프로필
├── campaigns/                        # 캠페인
├── visibility/                       # 공통 필터 (누가 누구에게 보이나)
├── recommendations/
│   ├── match-score.ts                # 순수 함수: 겹침 점수, 잘 맞는 이유
│   └── ...                           # 하루 추천 만들기와 조회
├── discovery/                        # 관심·넘김·보류, 서로 관심, 관심 목록
└── terms/
    ├── draft-terms.ts                # 순수 함수: 캠페인 + 원칙 → 조건 버전 1
    └── ...                           # 조건 버전 저장, 확인

app/lib/
├── core/ui/swipe_deck/               # 카드 넘기기 (브랜드, 크리에이터 공용)
└── features/
    ├── principles/                   # 09
    ├── brand_onboarding/             # 브랜드 프로필, 캠페인 만들기
    ├── discovery/                    # 01, 02, 08, D1, 크리에이터 상세(임시)
    ├── interests/                    # 03, 04, 05
    └── negotiation/                  # 06, 07
```

---

### Task 1: 스키마

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/creators/dto/*`, `api/src/creators/creators.service.ts`
- Create: 마이그레이션
- Test: `api/test/db/discovery-schema.db-spec.ts`, `api/test/creators.e2e-spec.ts`(추가)

**Interfaces:**
- Produces:
  - `enum FeeBand { W200K, W300K, W400K, W500K_PLUS }`, `enum ProductTrialDays { D3, D7, D14, ANY }`, `enum CampaignStatus { ACTIVE, CLOSED }`, `enum SwipeDecisionKind { LIKE, PASS, HOLD }`, `enum PassReason { MOOD, REGION, FEE, FIELD }`(2026-11-12: 표현 분위기, 지역·방문, 금액, 분야. 이유를 남기지 않으면 `passReason`은 null), `enum SwipeTargetKind { CREATOR, CAMPAIGN, STORE }`, `enum NotRequired { FACE, FIXED_LINES, SCRIPT_READING }`
  - `CreatorPrinciples` → `creator_principles`: `creatorId`(unique), `fields: IndustryCategory[]`, `blockedIndustries: IndustryCategory[]`, `faceOk: Boolean`, `scriptOk: Boolean`, `honestReview: Boolean`, `feeBand`, `trialDays`
  - `BrandProfile` → `brand_profiles`: `userId`(unique), `name`, `tagline?`, `industry: IndustryCategory`, `photoPath?`
  - `Campaign` → `campaigns`: `brandId`, `status`, `headline`, `fee: Int`, `budget: Int`(캠페인 예산, 2026-11-12), `productProvided: Boolean`, `format: ContentFormat`, `startFrom: DateTime @db.Date`, `trialDays: ProductTrialDays`, `mustInclude: String[]`(최대 3), `notRequired: NotRequired[]`. 부분 유니크 인덱스: `(brand_id) WHERE status = 'ACTIVE' AND deleted_at IS NULL`.
  - `SwipeDecision` → `swipe_decisions`: `actorId`, `targetKind`, `targetId`, `campaignId?`(브랜드가 크리에이터를 볼 때 그 캠페인, 크리에이터가 캠페인을 볼 때 그 캠페인), `decision`, `passReason?`, `note?`, `contentTitle?`, `contentPhotoPath?`, 브랜드의 제안(2026-11-12) `proposedFee?: Int`, `proposedProductProvided?: Boolean`, `proposedPerfRate?: Int`(1,000회당 원), `proposedPerfCap?: Int`. 유일 제약 `(actorId, targetKind, targetId, campaignId)`.
  - `Match` → `matches`: `campaignId`, `creatorId`, `collaborationId`(unique), `matchedAt`. 유일 제약 `(campaignId, creatorId)`.
  - `DailyRecommendation` → `daily_recommendations`: `userId`, `scope`(`BRAND` | `CREATOR`), `campaignId?`, `day @db.Date`, `items: Json`(`{ kind, id }[]`). 유일 제약 `(userId, scope, campaignId, day)`.
  - `TermsVersion` → `terms_versions`: `collaborationId`, `version: Int`, `proposedById?`(버전 1은 null), `title`, `fee`, `startDate @db.Date`, `format`, `pieces: Int`, `productProvided`, `revisionScope`(`NONE | GUIDE_1 | DRAFT_1 | DRAFT_2`), `usageRights`(`REPOST_ONLY | ADS_TOO | NONE`), `payoutDays: Int`(7 | 14), 성과 추가(2026-11-12) `perfRatePerThousand?: Int`, `perfCap?: Int`(둘 다 있거나 둘 다 없다), `brandConfirmedAt?`, `creatorConfirmedAt?`. 유일 제약 `(collaborationId, version)`.
  - `collaborations`에 `campaignId?` 추가. 부분 유니크 인덱스 `(campaign_id, creator_id) WHERE kind = 'BRAND_CONTRACT'`.
  - `creator_profiles`에 `cardHeadline?`(40자), `cardPhotoPath?` 추가. `PUT /creators/me`가 두 값을 받고 `CreatorProfileModel`에 `cardHeadline`, `cardPhotoUrl`을 더한다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('allows only one active campaign per brand', ...);
it('allows a new campaign after the previous one is closed', ...);
it('keeps one decision per actor, target and campaign', ...);
it('rejects a second match for the same campaign and creator', ...);
it('rejects a second brand collaboration for the same campaign and creator', ...);
it('saves the card headline and photo on the creator profile', ...);
it('keeps the brand proposal amounts on a like decision', ...);
it('stores a performance bonus on a terms version only as a rate and cap pair', ...);
it('requires a campaign budget', ...);
```

- [ ] **Step 2~4: 실패 확인 → 스키마와 마이그레이션(새 테이블 7개의 RLS) 구현 → 통과 확인** — Run: `cd api && yarn prisma migrate dev && yarn test:db && yarn test:e2e creators`
- [ ] **Step 5: gen-api, Commit** — `feat: 협업 원칙·캠페인·관심·조건 버전 스키마 추가`

---

### Task 2: 협업 원칙 API와 공통 필터

**Files:**
- Create: `api/src/principles/{principles.module.ts,principles.controller.ts,principles.service.ts,principles.repository.ts,dto/*.ts}`, `api/src/visibility/{visibility.module.ts,visibility.service.ts,visibility-rules.ts}`
- Modify: `api/src/stores/stores.repository.ts`, `api/src/stores/stores.service.ts`, `api/src/applications/applications.service.ts`, `api/src/offers/offers.service.ts`
- Test: `api/src/visibility/visibility-rules.spec.ts`, `api/test/principles.e2e-spec.ts`, `api/test/visibility.e2e-spec.ts`

**Interfaces:**
- Produces:
  - `GET /creators/me/principles` → 200 `PrinciplesModel { fields; blockedIndustries; faceOk; scriptOk; honestReview; feeBand; trialDays }` | 404. `operationId: getMyPrinciples`
  - `PUT /creators/me/principles` → 200 `PrinciplesModel`. `fields`는 일반 업종 중 1개 이상, `blockedIndustries`는 민감 업종 중 0개 이상. 다른 값이 섞이면 400. `CREATOR` 역할만. `operationId: upsertMyPrinciples`
  - `isBlocked(principles: { blockedIndustries } | null, viewerIndustry: IndustryCategory): boolean` (`visibility-rules.ts`, 순수 함수)
  - `VisibilityService`:
    - `creatorVisibleTo(creatorId: string, viewer: { userId: string; kind: 'STORE' | 'BRAND'; industry: IndustryCategory }): Promise<boolean>` — 본인이면 false, 피하는 업종이면 false, `BRAND`인데 원칙이 없으면 false. (차단은 5번 계획이 여기에 더한다.)
    - `filterCreators(creatorIds: string[], viewer): Promise<string[]>`
    - `commissionerVisibleTo(target: { ownerId: string; industry: IndustryCategory }, creatorId: string): Promise<boolean>` — 크리에이터가 그 업종을 피하면 false
  - 2번의 경로에 필터를 끼운다: `GET /stores`와 `GET /stores/:id`(크리에이터가 피하는 업종의 가게는 목록에서 빠지고 상세는 404), `POST /stores/:id/applications`(404), `GET /stores/me/applications`(피하게 된 지원자는 빠짐), `POST /offers`(받는 사람이 그 가게 업종을 피하면 404).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('blocks a viewer whose industry the creator avoids', ...);
it('does not block when the creator has no principles', ...);
it('rejects a sensitive industry in fields and a general one in blockedIndustries', ...);   // 400
it('requires at least one field', ...);
it('hides an alcohol store from a creator who avoids alcohol', ...);       // 목록에서 빠짐, 상세 404
it('returns 404 when a store offers to a creator who avoids its industry', ...);
it('hides a creator without principles from brands but not from stores', ...);
it('applies a newly added blocked industry immediately', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 협업 원칙 API 추가`, `feat: 피하는 업종 공통 필터를 가게 조회와 오퍼에 적용`

---

### Task 3: 브랜드 프로필과 캠페인 API

**Files:**
- Create: `api/src/brands/…`, `api/src/campaigns/…`
- Modify: `api/src/uploads/…`(`purpose`에 `BRAND_PHOTO`, `CREATOR_CARD` 추가, 경로 `brands/<userId>/…`, `creators/<userId>/card-…`)
- Test: `api/test/brands.e2e-spec.ts`, `api/test/campaigns.e2e-spec.ts`

**Interfaces:**
- Produces:
  - `GET /brands/me` → 200 `BrandProfileModel { userId; name; tagline: string | null; industry; photoUrl: string | null }` | 404. `PUT /brands/me` 본문 `{ name(1~30자); tagline?(40자); industry; photoPath? }`. `BRAND` 역할만. `operationId: getMyBrand`, `upsertMyBrand`
  - `CampaignModel { id; status; headline; fee; budget; productProvided; format; startFrom: string; trialDays; mustInclude: string[]; notRequired: NotRequired[] }`
  - `GET /campaigns/mine/active` → 200 `CampaignModel` | 404. `operationId: getMyActiveCampaign`
  - `POST /campaigns` 본문 `{ headline(1~40자); fee(10000~10000000, 1만 원 단위); budget(1만 원 단위, fee 이상 100000000 이하); productProvided; format; startFrom(오늘 이후); trialDays; mustInclude(0~3줄, 줄마다 20자); notRequired }` → 201. 브랜드 프로필이 없으면 409, 이미 `ACTIVE`가 있으면 409. `operationId: createCampaign`
  - `PATCH /campaigns/:id` → 200(자기 것, `ACTIVE`만). `POST /campaigns/:id/close` → 200. `operationId: updateCampaign`, `closeCampaign`
  - `BrandsService`를 export: `requireProfile(userId)`. `CampaignsService`를 export: `requireMyActive(userId): Promise<Campaign>`(없으면 409 `캠페인을 먼저 만들어 주세요.`), `findActiveById(id)`
  - `PATCH /campaigns/:id`로 `budget`도 고칠 수 있다. 고친 뒤에도 `budget >= fee`여야 한다(아니면 400).
  - `budgetLeft(budget: number, secured: number[]): { left: number; over: number }` (`campaign-budget.ts`, 순수 함수) — 합이 예산 이하면 `left = budget − 합`, `over = 0`. 넘으면 `left = 0`, `over = 합 − budget`. Task 6이 쓴다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('requires the BRAND role', ...);
it('refuses a campaign before a brand profile exists', ...);               // 409
it('refuses a second active campaign', ...);                               // 409
it('allows a new campaign after closing the old one', ...);
it('rejects a fee that is not a multiple of 10000', ...);                  // 400
it('rejects a start date in the past', ...);                               // FakeClock
it('rejects more than three must-include lines', ...);
it('rejects a budget below the fee or not a multiple of 10000', ...);     // 400
it('rejects an update that leaves the budget below the fee', ...);
it('reports the budget left, and zero with the overrun when over budget', ...);  // budgetLeft
it("returns 404 when editing another brand's campaign", ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 브랜드 프로필과 캠페인 API 추가`

---

### Task 4: 점수와 하루 추천

**Files:**
- Create: `api/src/recommendations/{match-score.ts,recommendations.module.ts,recommendations.controller.ts,recommendations.service.ts,recommendations.repository.ts,kst-day.ts,dto/*.ts}`
- Test: `api/src/recommendations/match-score.spec.ts`, `api/src/recommendations/kst-day.spec.ts`, `api/test/recommendations.e2e-spec.ts`

**Interfaces:**
- Consumes: `VisibilityService` (Task 2), `Clock`, 3번의 협업 조회
- Produces:
  - `kstDay(now: Date): string` — 한국 시간 기준 `YYYY-MM-DD`
  - `feeBandRange(band: FeeBand): { min: number; max: number | null }` — `W200K` 200000~299999, `W300K` 300000~399999, `W400K` 400000~499999, `W500K_PLUS` 500000~null
  - `matchScore(p: Principles, c: { industry; fee; notRequired; trialDays }): { score: number; reasons: MatchReason[] }` — 규칙마다 1점:
    - `FIELD`: `p.fields`에 `c.industry`가 있음
    - `FACE`: `p.faceOk`가 true이거나 `c.notRequired`에 `FACE`가 있음
    - `SCRIPT`: `p.scriptOk`가 true이거나 `c.notRequired`에 `SCRIPT_READING`이 있음
    - `FEE`: `c.fee >= feeBandRange(p.feeBand).min`
    - `TRIAL`: `p.trialDays`가 `ANY`이거나 `c.trialDays`와 같음
  - `type MatchReason = 'FIELD' | 'FACE' | 'SCRIPT' | 'FEE' | 'TRIAL'`
  - `storeScore(p: Principles | null, s: { industry }, region: { sameSigungu: boolean; sameSido: boolean }): number` — 분야가 맞으면 1, 같은 구·군 2, 같은 시·도 1
  - `CreatorCardModel { creatorId; displayName; instagramHandle: string | null; headline: string | null; photoUrl: string | null; feeBand; tags: string[]; reasons: MatchReason[]; theyLikedMe: false }` — `tags`는 원칙에서 만든다: `faceOk`가 false면 `얼굴출연없음`, `scriptOk`가 false면 `대본낭독없음`, `honestReview`가 true면 `솔직후기`, 그리고 `fields`의 첫 표시 이름. **`theyLikedMe`는 항상 false로 내보낸다**(상대의 관심을 미리 알려 주지 않는다. 순서에만 쓴다).
  - `CampaignCardModel { kind: 'CAMPAIGN'; campaignId; brandName; brandTagline: string | null; photoUrl: string | null; headline; fee; productProvided; tags: string[]; reasons: MatchReason[] }` — `tags`: `notRequired`의 표시 이름(`얼굴출연없음`, `정해진대사없음`, `대본낭독없음`) 최대 2개
  - `StoreCardModel { kind: 'STORE'; store: StoreSummaryModel; headline: string; tags: string[]; otherSido: string | null }` — `headline`은 가게 소개의 첫 문장(40자까지), `tags`는 `소상공인`, `팔로워무관`
  - `GET /recommendations/creators` → 200 `{ day: string; total: number; cards: CreatorCardModel[] }` — `BRAND` 역할, 진행 중 캠페인 필요. 오늘 목록이 없으면 만든다. 이미 결정한 카드는 빼고 남은 것만 준다. `total`은 오늘 목록의 전체 수. `operationId: listCreatorRecommendations`
  - `GET /recommendations/campaigns` → 200 `{ day; total; cards: (CampaignCardModel | StoreCardModel)[] }` — `CREATOR` 역할. `operationId: listCampaignRecommendations`
  - 목록을 만드는 규칙(브랜드용): 후보 = `VisibilityService`를 통과하고, 이 캠페인에서 결정(`LIKE`·`PASS`)한 적 없고, 끝나지 않은 협업이 없고, 같은 캠페인에서 `DROPPED`된 적 없는 크리에이터. 순서 = 그 크리에이터가 이 캠페인에 이미 `LIKE`를 보냈으면 먼저, 다음 `matchScore` 높은 순, 같으면 최근 가입 순. 앞에서 10명.
  - 크리에이터용: 후보 = `ACTIVE` 캠페인과 `PUBLISHED` 가게 가운데 `commissionerVisibleTo`를 통과하고 결정한 적 없고 끝나지 않은 협업이나 열린 오퍼가 없는 것. 순서 = 상대가 나에게 `LIKE`(브랜드) 또는 오퍼를 보낸 적 있으면 먼저, 다음 점수 순. 앞에서 10개.
  - 저장된 목록을 줄 때마다 `VisibilityService`로 다시 거른다(오늘 목록이 만들어진 뒤 피하는 업종이 바뀌어도 바로 빠진다).
  - `HOLD`한 카드는 다음 날 목록에 다시 나올 수 있다.
  - (2026-11-12) `StoreCardModel`에 `rewardLine: string`을 더한다. `storeRewardLine(reward): string`(순수 함수)이 가게 모집 조건의 보상 세 요소(가게 흐름 개정 계획이 만든 값)를 ` + `로 잇는다: 제공 혜택이 있으면 혜택의 이름(금액과 인원은 뺀다), 고정 현금이 있으면 `현금 {금액}`, 조회수 수당이 켜져 있으면 `조회수 수당`. 예: `식사권 + 조회수 수당`.
  - (2026-11-12) `GET /recommendations/preview` → 200 `{ total: number; cards: PreviewCardModel[] }` — 로그인했고 **역할이 없는** 사용자만(역할이 있으면 403). `PreviewCardModel { creatorId; displayName; headline: string | null; photoUrl: string | null; feeBand; tags: string[] }`(`CreatorCardModel`에서 `instagramHandle`, `reasons`, `theyLikedMe`를 뺀 것). 후보 = 협업 원칙이 있고 `blockedIndustries`가 비어 있고 탈퇴·이용 정지가 아닌 크리에이터. 최근 가입 순으로 10명. 저장하지 않고 조회할 때마다 계산한다. `operationId: listPreviewCards`
  - 역할이 없는 사용자의 다른 추천·결정 호출은 지금처럼 403이다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('uses the Korean calendar day', () => { expect(kstDay(new Date('2026-12-01T14:59:59Z'))).toBe('2026-12-01'); expect(kstDay(new Date('2026-12-01T15:00:00Z'))).toBe('2026-12-02'); });
it('scores one point per matching rule and lists the reasons', ...);       // 다섯 규칙 각각
it('counts the fee as matching when the campaign pays at least the band minimum', ...);
it('builds at most 10 cards and keeps the list for the day', ...);
it('puts creators who already liked this campaign first without revealing it', ...);  // theyLikedMe === false
it('omits cards I already decided on', ...);
it('builds a new list after Korean midnight', ...);
it('drops a card from today\'s list once the creator blocks my industry', ...);
it('mixes stores into the creator list and marks another province', ...);
it('excludes a counterpart I have an unfinished collaboration with', ...);
it('returns an empty list with total 0 when nobody qualifies', ...);
it('refuses creator recommendations without an active campaign', ...);    // 409
it('joins the store reward parts into one short line', ...);               // '식사권 + 조회수 수당', '식사권 + 현금 30,000원', '조회수 수당'
it('gives preview cards to a signed-in user without a role', ...);
it('leaves creators with any blocked industry out of the preview', ...);
it('never puts the instagram handle or match reasons on a preview card', ...);
it('refuses the preview for a user who already has a role', ...);          // 403
it('refuses a decision from a user without a role', ...);                  // 403
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 겹침 점수 계산 추가`, `feat: 하루 추천 목록 추가`

---

### Task 5: 관심·넘김·보류, 서로 관심, 조건 버전 1

**Files:**
- Create: `api/src/discovery/{discovery.module.ts,discovery.controller.ts,discovery.service.ts,discovery.repository.ts,dto/*.ts}`, `api/src/terms/{draft-terms.ts,terms.module.ts,terms.service.ts,terms.repository.ts,dto/terms-version.model.ts}`
- Test: `api/src/terms/draft-terms.spec.ts`, `api/src/discovery/discovery.service.spec.ts`, `api/test/discovery.e2e-spec.ts`

**Interfaces:**
- Consumes: Task 1~4, `CollaborationsRepository` (3번), `PushPort`
- Produces:
  - `draftTerms(campaign: Campaign, creator: { cardHeadline: string | null }, creatorNote: string | null): Omit<TermsVersion, 'id' | …>` (순수 함수) — 공통 규칙 7장의 표 그대로: `title` = `creatorNote ?? campaign.headline`, `fee`, `startDate = campaign.startFrom`, `format`, `pieces = 1`, `productProvided`, `revisionScope = GUIDE_1`, `usageRights = REPOST_ONLY`, `payoutDays = 7`
  - (2026-11-12) `draftTerms`는 넷째 인자 `proposal: { fee; productProvided; performance: { ratePer1000; cap } | null } | null`을 받는다. 있으면 `fee`, `productProvided`, 성과 추가가 그 값이고, 없으면 캠페인 값과 성과 추가 없음이다. 어느 쪽이든 버전 1은 `proposedById = null`이고 양쪽 확인 시각이 비어 있다.
  - (2026-11-12) 최대 현금 부담(제작비 + 성과 추가 상한, 없으면 0)은 **가게 흐름 개정 계획의 순수 함수**로 계산한다. 같은 식을 여기서 다시 쓰지 않는다. 06, 07의 확보액, F2에 넘기는 값이 모두 그 함수의 결과다.
  - `PUT /discovery/decisions` 본문 `{ targetKind: 'CREATOR' | 'CAMPAIGN'; targetId: string; decision: 'LIKE' | 'PASS' | 'HOLD'; note?: string(100자) }` → 200 `DecisionResultModel { decision; matched: boolean; collaborationId: string | null }`. 브랜드는 `CREATOR`만, 크리에이터는 `CAMPAIGN`만. 대상이 보이지 않으면 404. 브랜드의 캠페인은 진행 중 캠페인으로 정해진다. `LIKE`에 `note`가 있으면 그 크리에이터의 `cardHeadline`과 `cardPhotoPath`를 `contentTitle`, `contentPhotoPath`에 사본으로 저장한다. 서로 관심이 이미 된 뒤에는 결정을 바꿀 수 없다(409). `operationId: putDecision`
  - (2026-11-12) 브랜드의 `LIKE`는 `proposal?: { fee(1만 원 단위, 10000~10000000); productProvided: boolean; performance: { ratePer1000; cap } | null }`을 함께 받는다(04의 `…에게 제안`). `performance`의 범위는 가게 흐름 개정 계획의 서버 설정(단가 1,000~5,000원·500원 단위, 상한 10,000~300,000원·10,000원 단위)을 쓰고, 캠페인 형식이 블로그 글이면 `performance`를 받지 않는다(400). 값은 `proposed*` 칸에 저장한다. 이미 `LIKE`인 결정에 `proposal`을 다시 보내면 관심은 그대로 두고 값만 덮어쓴다. `proposal`이 없는 `LIKE`를 다시 보내도 저장된 제안은 지우지 않는다. 크리에이터가 보내면 400. 서로 관심이 닿는 트랜잭션에서 이 값을 `draftTerms`의 `proposal`로 넘긴다.
  - 가게 카드의 결정은 이 엔드포인트가 아니다. 앱이 `LIKE`는 2번의 `applyToStore`, `PASS`는 `PUT /discovery/store-passes/:storeId`(이 작업에서 만든다, `targetKind: STORE`로 저장)로 보낸다.
  - `PUT /discovery/decisions/pass-reason` 본문 `{ targetKind; targetId; reason: PassReason }` → 204. `PASS` 결정이 있을 때만. `targetKind`는 `CREATOR`, `CAMPAIGN`, `STORE` 모두 받는다. 이유를 남기지 않는 것(`이유 없이 다음 보기`)은 이 호출을 하지 않는 것이다. `operationId: putPassReason`
  - `DELETE /discovery/decisions/last` → 200 `{ targetKind; targetId } | null` — 내가 오늘 한 마지막 결정을 지운다. 서로 관심이 된 것이면 409. 가게 넘김(`store-passes`)도 대상이다. "오늘"은 한국 날짜(3번의 `kst.ts`)다. 지우는 것은 행 전체이므로 넘긴 이유와 브랜드의 제안도 함께 사라진다. 오늘 한 결정이 없으면(자정이 지났거나 없음) `null`을 돌려주고 아무것도 지우지 않는다. 02 시트의 `되돌리기`와 01·08의 `마지막 카드 되돌리기`가 같은 호출이다. `operationId: undoLastDecision`
  - 서로 관심 판정: 결정을 저장한 같은 트랜잭션에서, 반대쪽의 `LIKE`가 있으면 `matches` 행 삽입(유일 제약 위반이면 이미 된 것으로 보고 넘어간다), 협업 생성(`kind: BRAND_CONTRACT`, `stage: MATCHED`, `settlementMethod: FIXED`, `commissionerId` = 브랜드 사용자), `terms_versions` 버전 1(`draftTerms`, 크리에이터의 `note`가 있으면 제목으로). 그 뒤 양쪽에 `{상대 이름}{과/와} 서로 관심이 닿았어요.`(조사는 3번의 `josa`)
  - `GET /discovery/interests?tab=saved|mutual|sent|held`(2026-11-12: 옛 `all`이 `saved`다. 저장 = 내 `LIKE` + `HOLD`) → 200 `InterestCardModel[] { targetKind; targetId; name; shortName; headline: string | null; photoUrl: string | null; state: 'MUTUAL' | 'WAITING' | 'HELD'; feeLabel: number | null; feeBand: FeeBand | null; startFrom: string | null; hasProposal: boolean; collaborationId: string | null }`(브랜드가 볼 때 `feeLabel`은 서로 관심이면 최신 판본의 제작비, 아니면 내가 만든 제안의 금액, 둘 다 없으면 null이고 앱이 `feeBand`를 보여 준다. `startFrom`은 서로 관심일 때만 최신 판본의 제작 시작이고 아니면 null → `일정 협의`. `shortName`은 `shortName(name)` 순수 함수: 이름이 `{X}의 …` 꼴이면 X, 아니면 이름 전체) — 내 `LIKE`와 `HOLD`만. 넘긴 것은 어디에도 나오지 않는다. `operationId: listInterests`
  - `GET /discovery/received-proposals` → 200 `ProposalModel[] { campaignId; brandName; brandPhotoUrl; note; contentTitle: string | null; contentPhotoUrl: string | null; fee; productProvided; format }` — `CREATOR` 역할. 나에게 온 `note` 있는 `LIKE` 가운데 내가 아직 결정하지 않은 것. (화면은 5번 계획이 만든다.) (2026-11-12) `note`가 없어도 브랜드의 제안(`proposed*`)이 붙은 `LIKE`는 여기에 나온다. 그때 `fee`와 `productProvided`는 제안의 값이고, `performance: { ratePer1000; cap } | null`을 더한다. `note`는 `string | null`이 된다. `operationId: listReceivedProposals`
  - `GET /campaigns/:id/detail` → 200 `CampaignDetailModel` = `CampaignCardModel` + `{ startFrom; trialDays; mustInclude; notRequired; reasons; overlapCount: number; myDecision: 'LIKE' | 'HOLD' | null }` — `CREATOR` 역할, 보이지 않으면 404. `myDecision`에 `PASS`는 나오지 않고(넘긴 캠페인의 상세는 404). `operationId: getCampaignDetail`
  - `GET /creators/:id/card` → 200 `CreatorCardModel` + `{ myDecision }` — `BRAND` 역할, `VisibilityService`를 통과해야 한다. `operationId: getCreatorCard`
  - `TermsVersionModel { version; proposedBy: 'BRAND' | 'CREATOR' | 'SYSTEM'; title; fee; performance: { ratePer1000: number; cap: number } | null; maxCash: number; startDate; format; pieces; productProvided; revisionScope; usageRights; payoutDays; brandConfirmed: boolean; creatorConfirmed: boolean }`(`performance`와 `maxCash`은 2026-11-12 추가)
  - `GET /collaborations/:id/terms/latest` → 200 `{ terms: TermsVersionModel; notice: string | null; reasons: MatchReason[]; trialDays; followers: number | null }` — 당사자만. `notice`는 크리에이터의 원칙에서 만든다: 둘 다 false면 `얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.`, 얼굴만 false면 `얼굴 출연은 진행하지 않아요.`, 대본만 false면 `제품 설명문 낭독은 진행하지 않아요.`, 아니면 null. (2026-11-12) 응답에 `myTurn: boolean`(최신 판본을 내가 아직 확인하지 않았다), `mine: boolean`(최신 판본을 내가 냈다), `needsInstagram: boolean`(내가 크리에이터이고, 성과 추가가 켜져 있고, 형식이 릴스나 카드뉴스이고, 인스타그램이 연동돼 있지 않다)을 더한다. 버전 1은 양쪽 모두 `myTurn = true`, `mine = false`다. `operationId: getLatestTerms`
  - `POST /collaborations/:id/terms/:version/confirm` → 200 `TermsVersionModel`. 최신 버전만 확인할 수 있다(아니면 409 `STALE_VERSION`, 본문에 `latestVersion`. 앱은 F8의 옛 판본 화면을 띄운다). `needsInstagram`인 크리에이터의 확인은 409 `INSTAGRAM_REQUIRED`(3번이 오퍼 수락에 쓰는 것과 같은 연동 검사). 화면의 이름은 2026-11-12부터 `이 판본 수락`이다. 내 쪽 확인 시각을 조건부로 채운다. 협업이 `MATCHED`면 `NEGOTIATING`으로, 양쪽이 다 확인했으면 `AGREED`로 옮긴다. 상대에게 `{이름}{이/가} 조건 버전 {n}{을/를} 확인했어요.`(E3 캔버스 문구 (2026-11-11 소유자 결정)) `operationId: confirmTerms`
  - `TermsService`를 export: `latest(collaborationId)`, `createVersion(collaborationId, proposedById, values)`(5번 계획이 쓴다)
  - (2026-11-12) `POST /collaborations/:id/terms` 본문 `{ baseVersion: number; fee; productProvided; performance: { ratePer1000; cap } | null }` → 201 `TermsVersionModel` — 05의 `내가 먼저 제안하기`가 F1·F2를 거쳐 부른다. 당사자만, `BRAND_CONTRACT`이고 `MATCHED`·`NEGOTIATING`·`AGREED`일 때만. 값 검사는 `putDecision`의 `proposal`과 같다. 세 값이 최신 판본과 모두 같으면 400 `바꾼 조건이 없어요.` 한 트랜잭션에서: `baseVersion`이 최신이 아니면 409 `STALE_VERSION`(동시에 두 제안이 오면 하나만 다음 판본이 된다), 나머지 항목을 직전 판본에서 옮긴 버전 `baseVersion + 1`을 `createVersion`으로 넣고 낸 쪽의 확인 시각을 채운다(상대 쪽은 비운다), 단계를 `NEGOTIATING`으로 옮긴다. 크리에이터가 `performance`를 켜서 내는데 `needsInstagram`이면 409 `INSTAGRAM_REQUIRED`. 상대에게 `{이름}{이/가} 조건 버전 {n}{을/를} 제안했어요.`(알림 종류 `TERMS_PROPOSED`를 `NotificationKind` 마이그레이션과 `NOTIFICATION_CATALOG`에 더한다: 탭 협업, 끌 수 없음, 가는 곳 `TERMS`). `operationId: proposeReward`. **5번 계획 Task 6의 `POST /collaborations/:id/terms`는 이 엔드포인트를 나머지 항목까지 받도록 넓히는 것이다. 다시 만들지 않는다.**
  - (2026-11-12) `GET /discovery/compare?a=<creatorId>&b=<creatorId>` → 200 `CompareModel { sides: [CompareSideModel, CompareSideModel]; differs: CompareField[] }` — `BRAND` 역할만. 두 사람 모두 진행 중 캠페인에서 내가 `LIKE`나 `HOLD`한 크리에이터여야 하고 `VisibilityService`를 통과해야 한다(아니면 404). `CompareSideModel { creatorId; name; shortName; photoUrl: string | null; state: 'MUTUAL' | 'WAITING' | 'HELD'; collaborationId: string | null; format; pieces; productProvided; fee: number | null; feeBand; perfCap: number | null; usageRights; startDate: string | null; faceOk: boolean }`. 값이 오는 곳은 설계 04의 표다: 서로 관심이면 최신 판본, 아니면 내 제안(`proposed*`), 그것도 없으면 캠페인 값(`fee`는 null, `startDate`는 null, `usageRights`는 `REPOST_ONLY`). `type CompareField = 'DELIVERABLE' | 'BENEFIT' | 'FEE' | 'PERF_CAP' | 'USAGE' | 'START' | 'FACE'`. `compareDiff(a, b): CompareField[]`(순수 함수)는 화면에 보일 값이 다른 줄을 돌려준다(`FEE`는 `fee ?? feeBand`로, `START`는 `startDate ?? 'TBD'`로 견준다). **응답에 팔로워 수가 없다.** `operationId: compareCandidates`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('drafts version 1 from the campaign with the documented defaults', ...);  // GUIDE_1, REPOST_ONLY, 7, pieces 1
it('uses the creator note as the title when present', ...);
it('stores a like and reports no match when the other side has not liked', ...);
it('creates a match, a MATCHED collaboration and terms version 1 on mutual like', ...);
it('creates exactly one match when both likes arrive at the same time', ...);  // Promise.all, matches 1행, collaborations 1행, terms 1행
it('notifies both sides on a match', ...);
it('never returns a pass or its reason to the other side', ...);             // 상대의 추천·관심 목록·상세·알림 응답 전체에 'PASS', 'passReason' 문자열 없음
it('returns 404 for the detail of a campaign I passed', ...);
it('copies the creator card title and photo when a brand likes with a note', ...);
it('lists a noted like as a received proposal until the creator decides', ...);
it('undoes my last decision but not a matched one', ...);                    // 409
it('refuses to change a decision after a match', ...);
it('returns 404 when liking a creator who avoids my industry', ...);
it('confirming version 1 moves MATCHED to NEGOTIATING, and both confirming moves to AGREED', ...);
it('builds the notice line from the creator principles', ...);
it("returns 404 for terms of a collaboration I am not part of", ...);
// 2026-11-12 개정
it('drafts version 1 from the brand proposal when the like carried one', ...);       // fee, productProvided, perf
it('leaves version 1 unconfirmed by both sides even when it came from a brand proposal', ...);
it('overwrites the proposal on an existing like without creating a second decision', ...);
it('rejects a proposal from a creator and a performance bonus on a blog campaign', ...);   // 400
it('lists a like with a proposal as a received proposal showing the proposed amounts', ...);
it('saves a pass reason for a store pass', ...);
it('undo removes the pass together with its reason', ...);
it('undo returns null after Korean midnight and deletes nothing', ...);              // FakeClock
it('the saved tab returns my likes and holds, never passes', ...);
it('refuses to confirm an older version with STALE_VERSION', ...);                   // 409, latestVersion
it('refuses a creator confirming a performance bonus without instagram', ...);       // 409 INSTAGRAM_REQUIRED
it('creates the next version with only money and benefit changed and marks the proposer confirmed', ...);
it('clears the earlier confirmation when a new version is proposed', ...);
it('accepts only one of two proposals sent on the same base version', ...);          // Promise.all → 201 하나, 409 하나
it('rejects a proposal that changes nothing', ...);                                  // 400
it('adds the performance cap to the maximum cash burden', ...);
it('compares two saved candidates and marks the rows that differ', ...);             // compareDiff
it('returns 404 when comparing a candidate I have not saved', ...);
it('never includes follower counts in the comparison', ...);
it('builds a short name from an activity name', ...);                                // '서윤의 작은 취향' → '서윤', '하루 한 컵' → '하루 한 컵'
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 네 개: `feat: 관심·넘김·보류와 서로 관심 추가`, `feat: 조건 버전 1 자동 생성과 확인 추가`, `feat: 관심 목록과 상세 조회 추가`, `feat: 브랜드의 제안과 후보 비교 조회 추가`

---

### Task 6: 협업 조회에 브랜드 계약 더하기

**Files:**
- Modify: `api/src/collaborations/collaborations.service.ts`, `dto/collaboration.model.ts`, `collaboration-stage.ts`
- Test: `api/src/collaborations/collaboration-stage.spec.ts`(추가), `api/test/collaborations.e2e-spec.ts`(추가)

**Interfaces:**
- Consumes: 3번 Task 9의 `CollaborationModel`
- Produces:
  - `brandProgress(stage: CollaborationStage): { doneCount: number; current: 1 | 2 | 3 | 4 | 5 | 6 | null; currentNote: 'WAITING_OTHER_CONFIRM' | 'WAITING_CONTRACT' | null }` (순수 함수) — 공통 규칙 1장의 표: `MATCHED` 1 완료·현재 2, `NEGOTIATING` 2 완료·현재 3, `AGREED` 2 완료·현재 3, `CONTRACTED` 3 완료·현재 4, `GUIDED` 3 완료·현재 4, `REVIEWING` 4 완료·현재 5, `APPROVED` 5 완료·현재 6, `PUBLISHED` 5 완료·현재 6, `SETTLED` 6 완료·현재 없음
  - `CollaborationModel`에 추가: `campaign: { id; headline; brandName } | null`, `title: string | null`(최신 조건 버전의 제목), `brandProgress: { doneCount; current; currentNote } | null`. 브랜드 계약의 `steps`는 빈 배열.
  - `GET /collaborations?scope=active`가 브랜드 계약(`MATCHED`~`PUBLISHED`, `HALTED`)도 준다. `INQUIRY`는 주지 않는다.
  - (2026-11-12) 브랜드 계약의 `CollaborationModel`에 더한다(가게 오퍼는 모두 null):
    - `securedAmount: number | null` — 최신 판본의 `maxCash`(이번 협업 확보액)
    - `campaignBudgetLeft: { left: number; over: number } | null` — **보는 사람이 그 캠페인의 브랜드일 때만** 채운다. 크리에이터에게는 null. Task 3의 `budgetLeft`에 캠페인 예산과, 그 캠페인에서 `INQUIRY`·`DROPPED`·`REFUNDED`가 아닌 브랜드 협업들의 확보액을 넣은 결과다.
    - `nextAction: 'RESPOND_TERMS' | 'SIGN_CONTRACT' | null` — `nextActionFor(stage, myTurn)`(순수 함수): `MATCHED`·`NEGOTIATING`이고 최신 판본을 내가 확인하지 않았으면 `RESPOND_TERMS`, `AGREED`면 `SIGN_CONTRACT`, 그 밖은 null. (`CONTRACTED` 뒤는 5·6번 계획이 더한다.)
  - 이 Task가 `CollaborationModel`을 넓히는 모양(`kind`, nullable `terms`, Task 5와 같은 커밋)은 `plan4-preflight.md`의 판단을 따른다. 위 세 값은 그 모양에 필드로 더한다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('maps every brand stage to the six step progress', ...);                 // 표의 아홉 줄
it('lists a matched brand collaboration as active for both sides', ...);
it('returns the campaign and the latest terms title', ...);
it('reports the secured amount as the maximum cash burden of the latest version', ...);
it('subtracts every live collaboration of the campaign from the budget and skips dropped ones', ...);
it('reports zero left and the overrun when the secured total exceeds the budget', ...);
it('never sends the campaign budget to the creator', ...);                 // campaignBudgetLeft === null
it('asks me to respond while I have not confirmed and to sign once agreed', ...);   // nextActionFor
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 협업 조회에 브랜드 계약의 진행 단계 추가`

---

### Task 7: 앱 — 협업 원칙(09)

**Files:**
- Create: `app/lib/features/principles/domain/{principles.dart,principles_repository.dart,principle_questions.dart}`, `data/api_principles_repository.dart`, `presentation/viewmodels/principles_view_model.dart`, `presentation/pages/principles_page.dart`
- Modify: `app/lib/core/navigation/app_router.dart`, `app/lib/features/creator_profile/…`(프로필 설정 화면에 `대표 콘텐츠 한 줄`, `대표 사진` 추가. 저장 뒤 `/creator/principles`로)
- Test: `app/test/features/principles/`

**Interfaces:**
- Produces:
  - `principleQuestions: List<PrincipleQuestion>` — 질문 7개의 머리말, 제목, 안내, 선택지, 여러 개 고르기 여부. 설계 문서 2장의 표와 캔버스 문구 그대로. 1번의 선택지는 일반 업종 9개의 표시 이름(맛집·카페가 첫 번째), 2번은 민감 업종 4개.
  - `abstract class PrinciplesRepository { Future<Principles?> fetchMine(); Future<Principles> save(Principles p); }`
  - 라우트 `/creator/principles`. `roleEntryResolverProvider`의 `creator` 분기: 프로필 없음 → 프로필 설정, 있음 → `/creator`. (원칙은 강제하지 않는다.)

화면 문구:
- 머리글 알약 `나의 협업 원칙`, 오른쪽 `나중에`. 카드 안: 머리말, `{n} / 7 단계`, 진행 막대, `질문`, 제목, 안내, 선택지. 버튼 `다음`, 마지막 `다 골랐어요`.
- 선택지의 보조 글: 캔버스의 값(예: `반지, 팔찌, 시계`, `손·소품 중심`, `얼굴 출연 가능`). 캔버스에 없는 업종은 보조 글이 없다.
- 2번은 아무것도 고르지 않아도 `다음`이 켜져 있다. 나머지는 하나 이상 골라야 켜진다.
- 끝: `나답게 일하는 기준이\n완성됐어요.`, `프로필과 받은 제안에 이 기준이 함께 보여요.`, 요약 일곱 칸(고르지 않은 칸은 `고르지 않음`), `다시 고르기`, `저장하고 캠페인 보기`.
- `나중에` → 저장하지 않고 `/creator`.
- (2026-11-12) 다크 모드에서 진행 막대의 채워진 부분은 밝은 글자색(캔버스 `#F2F3F5`)이다. 옛 캔버스는 배경색(`#0F1012`)이었다. 라이트 모드는 그대로다. 색은 `core/theme`의 토큰에서 가져온다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('has seven questions with the canvas copy', ...);
testWidgets('next is disabled until an option is picked', ...);
testWidgets('the blocked industries question can be skipped', ...);
testWidgets('multi-select questions toggle several options', ...);
testWidgets('single-select questions keep one option', ...);
testWidgets('shows the summary and saves', ...);
testWidgets('later leaves without saving', ...);
testWidgets('loads saved principles for editing', ...);
testWidgets('the progress bar fill uses the light foreground token in dark mode', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 협업 원칙 화면 추가`

---

### Task 8: 앱 — 카드 넘기기 위젯

**Files:**
- Create: `app/lib/core/ui/swipe_deck/{swipe_deck.dart,swipe_deck_controller.dart,swipe_physics.dart,swipe_card_frame.dart,swipe_stamp.dart}`
- Modify: `app/lib/features/dev/presentation/pages/motion_gallery_page.dart`
- Test: `app/test/core/ui/swipe_deck/`

**Interfaces:**
- Produces:
  - `enum SwipeOutcome { like, pass, hold }`
  - `resolveSwipe(Offset offset): SwipeOutcome?` (`swipe_physics.dart`, 순수 함수) — `dx > 110` → like, `dx < -110` → pass, `dy < -140 && dx.abs() < 80` → hold, 아니면 null
  - `tiltFor(double dx, double width): double` — `dx / width × 12도`, ±12도로 자른다
  - `stampOpacity(Offset offset, SwipeOutcome o): double` — 기준의 0%에서 100%까지 0→1
  - `class SwipeDeckController { Future<void> swipe(SwipeOutcome o); bool get busy; }` — 버튼으로 넘길 때 쓴다
  - `SwipeDeck<T>({ required List<T> items, required Widget Function(BuildContext, T) cardBuilder, required Future<void> Function(T, SwipeOutcome) onSwiped, VoidCallback? onTap, required Widget empty, SwipeDeckController? controller })` — 맨 위 카드만 움직인다. 다음 카드는 뒤에서 96% 크기로 보이다가 앞 카드가 나가면 100%가 된다. 날아가는 동안(`busy`)에는 끌기와 `swipe()`를 받지 않는다. `onSwiped`가 끝나기 전에 다음 카드를 넘길 수 없다. `onSwiped`가 예외를 던지면 카드가 제자리로 돌아온다.
  - `SwipeCardFrame({ required String? photoUrl, required String badge, required String name, required String title, required String priceLine, required List<String> tags, Object? heroTag })` — 모서리 28, 사진 위 아래쪽 어두운 그라데이션, 흰 글자, 제작비 줄은 `accent` 색
  - `SwipeStamp(SwipeOutcome)` — 글자 `관심`, `넘김`, `보류`, 흰 테두리 5, 14도 기울임
  - 움직임: 끌 때는 손가락을 그대로 따른다. 놓으면 스프링(질량 1, 강성 380, 감쇠 28)으로 돌아오거나 280ms `easeOut`으로 화면 밖으로 나간다. 수치는 소유자 승인 대상이다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('resolves like, pass and hold at the canvas thresholds', () {
  expect(resolveSwipe(const Offset(111, 0)), SwipeOutcome.like);
  expect(resolveSwipe(const Offset(110, 0)), isNull);
  expect(resolveSwipe(const Offset(-111, 0)), SwipeOutcome.pass);
  expect(resolveSwipe(const Offset(79, -141)), SwipeOutcome.hold);
  expect(resolveSwipe(const Offset(80, -141)), isNull);
});
test('tilts up to 12 degrees', ...);
testWidgets('dragging past the threshold calls onSwiped once with like', ...);
testWidgets('a short drag springs back and calls nothing', ...);
testWidgets('ignores a second drag while the first card is flying out', ...);
testWidgets('controller.swipe animates the same way as a drag', ...);
testWidgets('returns the card when onSwiped throws', ...);
testWidgets('shows the empty widget after the last card', ...);
testWidgets('tapping without dragging calls onTap', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 모션 갤러리에 견본 추가, 소유자 승인** — 갤러리에 카드 세 장짜리 견본 덱을 넣는다. iPhone과 중저가 Android 실기기에서 끌기, 놓기, 연달아 넘기기를 확인받는다. 요청한 수치를 반영한다. **승인 전에는 Task 9로 넘어가지 않는다.**
- [ ] **Step 6: Commit** — `feat: 카드 넘기기 위젯 추가`

---

### Task 9: 앱 — 브랜드 시작과 발견(01, 02)

**Files:**
- Create: `app/lib/features/brand_onboarding/…`(브랜드 프로필, 캠페인 만들기·고치기), `app/lib/features/discovery/domain/{discovery_card.dart,discovery_repository.dart}`, `data/api_discovery_repository.dart`, `presentation/viewmodels/{brand_discovery_view_model.dart}`, `presentation/pages/{brand_discovery_page.dart,creator_card_detail_page.dart}`, `presentation/widgets/{pass_reason_sheet.dart,discovery_toast.dart,discovery_empty.dart,like_note_sheet.dart}`
- Modify: `app/lib/core/navigation/app_router.dart`, `app/lib/main.dart`
- Test: `app/test/features/brand_onboarding/`, `app/test/features/discovery/`

**Interfaces:**
- Consumes: `SwipeDeck` (Task 8), `cora_api`의 브랜드·캠페인·추천·결정 호출 (Task 3~5)
- Produces:
  - `abstract class DiscoveryRepository { Future<({int total, List<CreatorCard> cards})> fetchCreatorCards(); Future<({int total, List<DiscoveryCard> cards})> fetchCampaignCards(); Future<DecisionResult> decide(DiscoveryTarget target, SwipeOutcome o, {String? note, RewardProposal? proposal}); Future<List<PreviewCard>> fetchPreviewCards(); Future<void> setPassReason(DiscoveryTarget target, PassReason r); Future<DiscoveryTarget?> undoLast(); }`
  - `sealed class DiscoveryCard`(`CampaignCard`, `StoreCard`), `class CreatorCard`
  - 라우트: `/brand/profile/setup`, `/brand/campaign/new`, `/brand/campaign/edit`, `/brand`(발견), `/brand/creators/:id`
  - `roleEntryResolverProvider`의 `brand` 분기: 프로필 없음 → `/brand/profile/setup`, 진행 중 캠페인 없음 → `/brand/campaign/new`, 있음 → `/brand`
  - 브랜드 하단 메뉴: `발견`, `관심`, `대화`(준비 중), `협업`, `프로필`(준비 중)

화면 문구:
- 브랜드 프로필: 제목 `어떤 브랜드인가요?`, `브랜드 이름`, `한 줄 소개 (선택)` 예시 `예: 느린 결, 일상의 주얼리`, `업종`(13개 고르기), `대표 사진 (선택)`, 버튼 `다음`.
- 캠페인 만들기: 제목 `어떤 콘텐츠를\n함께 만들까요?`, `캠페인 한 줄` 예시 `예: 나만의 아침 루틴 속 작은 포인트`, `제작비 (원)`, `제품 제공`(스위치), `형식`(네 가지), `시작 가능한 날`, `제품 사용 기간`(`3일`, `7일`, `14일`, `상관없어요`), `꼭 담을 것 (최대 3줄)`, `요구하지 않는 것`(`얼굴 출연`, `정해진 대사`, `대본 낭독`), 버튼 `캠페인 시작하기`. 고치기 화면은 버튼 `저장`과 `캠페인 마감`(확인 `캠페인을 마감할까요? 진행 중인 협업은 그대로 이어져요.`).
- 01 발견: 머리 로고 `cora`, 오른쪽 알약 `브랜드`. 카드 표지 `운영자 추천 {n}/{total}`. 카드: 이름, 콘텐츠 한 줄(없으면 `대표 콘텐츠를 준비 중이에요`), 희망 제작비(`20만 원대`, `30만 원대`, `40만 원대`, `50만 원 이상`), 꼬리표 `#…`. 아래 버튼 셋: 넘김, 보류, 관심(아이콘, `aria` 이름 포함).
- 알림 문구(카드 아래에 3초): 넘김 `넘겼어요. 상대에게는 알리지 않아요.` + `이유 남기기` / 관심 `관심을 보냈어요. 상대도 고르면 알려드려요.` + `관심 목록` / 보류 `보류함에 담았어요.` + `보류 보기` / 서로 관심 `{이름}과 서로 관심이 닿았어요.` + `확인하기`(→ Task 10의 05 화면).
- 다 봤을 때(2026-11-12 개정): 가게 흐름 개정 계획의 F8 공용 상태 위젯을 쓴다. 제목 `오늘 추천을 모두 봤어요`, 설명 `관심과 저장에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.`, 버튼 `저장한 후보 보기`(→ 03의 저장 탭). 그 아래 `마지막 카드 되돌리기`(01 캔버스 그대로. 되돌릴 결정이 없으면 흐리게). 오늘 목록이 처음부터 0장이면 `아직 추천할 크리에이터가 없어요.`, `크리에이터가 늘어나면 알려드릴게요.`
- 02 넘기기 이유(2026-11-12 개정. 아래에서 올라오는 시트, 넘긴 **뒤에** `이유 남기기`를 눌렀을 때만): 제목 `넘겼어요. 이유를 남길까요?`, 설명 `선택이에요. 남기면 다음 추천에만 반영하고 상대에게는 알리지 않아요.` 선택지 `표현 분위기가 달라요`(`MOOD`), `지역·방문이 어려워요`(`REGION`), `금액이 안 맞아요`(`FEE`), `분야가 달라요`(`FIELD`). 처음에는 아무것도 골라져 있지 않고, 하나만 고르며, 다시 누르면 풀린다.
- 02의 버튼: 고른 것이 없으면 `이유 없이 다음 보기`(아무것도 저장하지 않고 닫는다), 있으면 `이유 남기고 다음 보기`(`setPassReason` 뒤 닫는다). 그 아래 `되돌리기`: `undoLast`를 부르고 그 카드를 덱 맨 앞에 다시 놓는다. `undoLast`가 `null`이면 `되돌릴 수 없어요. 내일 추천에 다시 나올 수 있어요.`
- 크리에이터 상세(임시, 7번에서 B5로 대체): 사진, 이름, 콘텐츠 한 줄, 꼬리표, `잘 맞는 점`(이유의 표시 이름: `분야가 맞아요`, `얼굴 출연 조건이 맞아요`, `대본 조건이 맞아요`, `제작비가 맞아요`, `제품 사용 기간이 맞아요`), 버튼 `넘기기`, `관심 보내기`. `관심 보내기`를 누르면 시트: `좋았던 점을 한 줄 남길까요? (선택)`, 입력란, `관심 보내기`.
- 카드에서 상세로 갈 때 사진이 `Hero`(`'creator:<id>'`)로 이어진다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('brand entry goes to profile, then campaign, then discovery', ...);
testWidgets('campaign form requires headline, fee, format and start date', ...);
testWidgets('shows the badge with position and total', ...);                // '운영자 추천 1/3'
testWidgets('swiping right sends a like and shows the like toast', ...);
testWidgets('swiping left shows the pass toast with a reason link', ...);
testWidgets('the reason sheet opens with nothing picked and the no-reason button', ...);   // '이유 없이 다음 보기'
testWidgets('picking a reason switches the button and saves that reason', ...);             // '이유 남기고 다음 보기'
testWidgets('leaving without a reason saves nothing', ...);
testWidgets('undo on the reason sheet brings the passed card back to the top', ...);
testWidgets('undo says it is too late when the server has nothing to undo', ...);
testWidgets('a mutual like shows the match toast', ...);
testWidgets('shows the shared all-seen state with the saved-candidates button and undo', ...);
testWidgets('undo brings back the last card', ...);
testWidgets('shows the no-candidates state when today has zero cards', ...);
testWidgets('the card returns when the decision fails', ...);              // '잠시 뒤 다시 시도해 주세요.'
testWidgets('liking from the detail can carry a note', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 브랜드 프로필과 캠페인 만들기 화면 추가`, `feat: 브랜드 발견 화면과 넘기기 이유 추가`

---

### Task 9A: 앱 — 등록 없이 먼저 둘러보기 (A1 → 01) (2026-11-12 추가)

**Files:**
- Create: `app/lib/features/discovery/presentation/viewmodels/preview_discovery_view_model.dart`, `app/lib/features/discovery/presentation/pages/preview_discovery_page.dart`
- Modify: `app/lib/features/onboarding/presentation/pages/role_select_page.dart`(버튼 한 줄), `app/lib/core/navigation/app_router.dart`, `app/lib/core/navigation/role_entry.dart`(역할이 없는 사용자가 `/browse`에 머물 수 있게)
- Test: `app/test/features/discovery/preview_discovery_test.dart`, `app/test/features/onboarding/role_select_page_test.dart`(추가)

**Interfaces:**
- Consumes: `SwipeDeck`·`SwipeCardFrame` (Task 8), `DiscoveryRepository.fetchPreviewCards` (Task 9), `cora_api`의 `listPreviewCards` (Task 4), 가게 흐름 개정 계획의 F8 공용 상태 위젯
- Produces: 라우트 `/browse`. 역할이 없는 로그인 사용자만 들어온다. 역할이 있으면 그 역할의 첫 화면으로 보낸다.

규칙(공통 규칙 23장, 설계 "A1의 등록 없이 먼저 둘러보기"):
- 이 화면은 `PreviewCard`만 읽는다. 결정, 넘긴 이유, 되돌리기를 부르지 않는다.
- 왼쪽으로 밀기와 넘김 버튼 → 다음 카드(저장 없음). 오른쪽·위로 밀기 → 카드가 제자리로 돌아온 뒤 A1로. 관심·보류 버튼, 카드를 눌렀을 때, 하단 메뉴의 `발견` 밖의 탭 → A1로.
- A1로 돌아갈 때 A1 위에 한 번: `역할을 고르면 관심을 보낼 수 있어요.`
- 넘긴 뒤의 알림 문구와 02 시트는 없다. 머리의 종 아이콘도 없다.

화면 문구:
- A1: 역할 버튼 아래에 `등록 없이 먼저 둘러보기`(캔버스 A1. 높이 44, 보조 글자색). A1의 다른 변화는 가게 흐름 개정 계획의 몫이라 건드리지 않는다.
- 둘러보기 01: 머리 로고 `cora`, 알약 `둘러보는 중`, 오른쪽 `역할 고르기`(→ A1). 카드 표지 `운영자 추천 {n}/{total}`, 카드의 이름·콘텐츠 한 줄·희망 제작비·꼬리표는 01과 같다. 아래 버튼 셋도 같은 모양이다.
- 다 봤을 때(F8 위젯): `여기까지 둘러봤어요.`, `역할을 고르면 나에게 맞는 추천을 받아요.`, 버튼 `역할 고르기`.
- 카드가 0장일 때: `아직 둘러볼 크리에이터가 없어요.`, 버튼 `역할 고르기`.
- 불러오지 못했을 때: F8의 불러오기 실패 모양에 `추천을 불러오지 못했어요`, `연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.`, `다시 시도`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('the role page shows the browse-first link and opens the preview', ...);
testWidgets('passing in the preview shows the next card and saves nothing', ...);   // 저장소의 decide 호출 0회
testWidgets('swiping right in the preview snaps back and returns to the role page', ...);
testWidgets('the like and hold buttons return to the role page with the hint', ...);
testWidgets('tapping a preview card does not open the creator detail', ...);
testWidgets('the preview never shows an instagram handle or a notification bell', ...);
testWidgets('shows the end-of-preview state with the choose-role button', ...);
testWidgets('a user with a role is sent to their own first screen instead of the preview', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 시뮬레이터에서 확인** — 역할이 없는 계정으로 로그인해 A1 → 둘러보기 → 오른쪽으로 밀어 A1로 돌아오는 것을 라이트와 다크에서 본다.
- [ ] **Step 6: Commit** — `feat: 역할 선택에 등록 없이 먼저 둘러보기 추가`

---

### Task 10: 앱 — 관심·보류(03), 비교(04), 서로 관심(05)

**Files:**
- Create: `app/lib/features/interests/domain/{interest_card.dart,interests_repository.dart}`, `data/api_interests_repository.dart`, `presentation/viewmodels/interests_view_model.dart`, `presentation/pages/{interests_page.dart,compare_page.dart,match_sheet.dart}`
- Test: `app/test/features/interests/`

**Interfaces:**
- Consumes: `cora_api`의 `listInterests`, `putDecision`, `compareCandidates`, `proposeReward` (Task 5), `DiscoveryRepository.decide`의 `proposal` (Task 9), `CoraTransitions.sheet`, `terms_text.dart`의 라벨(Task 11과 함께 쓰므로 이 Task에서 먼저 만들어도 된다), **가게 흐름 개정 계획의 F1(보상·예산 설정)과 F2(보내기 전 검토)**
- Produces: 라우트 `/brand/interests`, `/brand/interests/compare?a=…&b=…`, `/creator/interests`. 05는 `showMatchSheet(context, MatchInfo)`.
  - `openRewardProposal(context, RewardProposalTarget target)` — F1 → F2를 여는 한 곳이다. `RewardProposalTarget`은 둘이다: `BeforeMatch(creatorId)`(04의 `…에게 제안`. F2의 보내기 → `decide(LIKE, proposal)`)와 `AfterMatch(collaborationId, baseVersion)`(05의 `내가 먼저 제안하기`. F2의 보내기 → `proposeReward`). F1·F2에는 받는 사람, 처음 값, 줄의 이름(공통 규칙 2장의 브랜드 계약 쪽: `혜택`, `현금 고정비`, `성과 추가`), `모집` 줄(`{브랜드 이름} · {캠페인 한 줄}`), 결과물(`{형식} {편 수}편`), 사용권(고칠 수 없음), 현금 고정비의 범위(1만~1,000만 원)를 넘긴다. **F1·F2 화면은 고치지 않는다.** 넘길 수 없는 값이 있으면 멈추고 소유자에게 묻는다.

화면 문구:
(2026-11-12 캔버스 기준으로 다시 썼다.)
- 03: 제목 `관심·보류`, 설명 `저장은 나만 보고, 관심은 상대에게 전해져요. 비교할 후보를 골라요.` 탭 `저장 {n}`, `서로 관심 {n}`, `보낸 관심 {n}`, `보류 {n}`(저장 = 관심 + 보류). 카드 표지 `서로 관심` / `응답 대기` / `보류`. 카드 아래 글: 이름, 콘텐츠 한 줄, `{금액}, {가능한 날} 이후` 또는 `{금액}, 일정 협의`(`startFrom`이 null일 때). 금액은 `feeLabel`이 있으면 `30만 원`, 없으면 희망 제작비 구간(`30만 원대`).
- 서로 관심이 있으면 아래 상자: `{이름}과 서로 관심` / `협업 조건 확인`(→ Task 11의 06). 응답을 기다리는 후보가 있으면 그 아래 `{이름}은 상대의 응답을 기다리고 있어요.`(조사는 3번의 `josa`)
- 카드 오른쪽 위의 동그라미(지름 26)를 눌러 비교할 후보를 고른다. 고른 카드는 체크가 든 `accent` 동그라미이고 접근성 이름은 `비교에 선택됨`, 고르지 않은 카드는 빈 동그라미다. 두 장까지 고른다. 세 번째를 누르면 `비교는 2명까지예요.` 화면을 열 때 저장 탭의 위 두 장이 골라져 있다. 길게 눌러 고르기는 없다.
- 버튼 `선택한 {n}명 비교하기`: 두 장을 골랐을 때만 켜진다(`선택한 2명 비교하기`). 아니면 꺼지고 `비교할 후보 2명을 골라 주세요.`
- 동그라미 밖을 누르면: 보류 카드는 시트 `관심 보내기`, `넘기기`. 그 밖의 카드는 크리에이터 상세.
- 빈 목록(F8 공용 위젯의 빈 목록 모양): `아직 담은 후보가 없어요. 발견에서 마음에 드는 카드를 오른쪽으로 밀어 보세요.`
- 04: 머리 `후보 비교`. 안내 `같은 결과물 기준으로 맞췄어요. 점 표시는 조건이 다른 항목이에요. 팔로워 수는 비교하지 않아요.` 표의 머리에 후보마다 사진(높이 132, 모서리 20), 이름, 상태(`서로 관심` / `응답 대기` / `보류`). 줄 일곱 개와 값의 라벨:
  - `결과물` — `{형식} {편 수}편`, 릴스와 쇼츠는 뒤에 ` · 30초`
  - `혜택` — `제품 제공` / `없음`
  - `현금 고정비` — `fee`가 있으면 `30만 원`, 없으면 희망 제작비 구간 `30만 원대`
  - `성과 상한` — `없음` 또는 `{상한}`(예: `6만 원`)
  - `사용권` — `브랜드 계정 재게시` / `재게시 + 광고` / `사용 안 함`(`compareUsageLabel`. 06의 `usageLabel`과 다른 짧은 라벨이다)
  - `촬영 가능일` — `{날짜} 이후` 또는 `일정 협의`
  - `얼굴 출연` — `faceOk`가 false면 `없음`, true면 `있음`
- `differs`에 든 줄은 이름 앞에 점(지름 6, 접근성 이름 `조건이 달라요`)이 붙고 두 값이 굵다.
- 04의 버튼 둘: 서로 관심인 후보는 `{shortName}의 제안 보기`(→ 06), 아닌 후보는 `{shortName}에게 제안`(→ `openRewardProposal(BeforeMatch)`). 서로 관심인 후보의 버튼이 오른쪽 강조 버튼이고, 두 후보의 상태가 같으면 표의 왼쪽 후보가 강조 버튼이다. 제안을 보내고 돌아오면 `{이름}에게 제안을 보냈어요. 상대도 고르면 알려드려요.`를 보여 주고 표를 다시 읽는다.
- 05(시트): 두 사진이 양쪽에서 들어와 겹치고 가운데 하트. 표지 `{브랜드의 한 줄 소개} 캠페인에서 연결`(한 줄 소개가 없으면 브랜드 이름), `서로를 골랐어요.`, `{브랜드 이름}와 {크리에이터 이름}이 서로의 콘텐츠에 관심을 표시했어요. 아직 계약이나 지급 의무는 생기지 않아요.`, 버튼 `받은 제안 보기 · {n}건`(→ 06. n은 내가 응답할 차례인 판본 수, 0이면 `제안 보기`), `내가 먼저 제안하기`(→ `openRewardProposal(AfterMatch)`, 보내면 07로). `협업 조건 확인하기`와 `계속 둘러보기`는 없다. 시트는 아래로 내리거나 바깥을 눌러 닫는다. 첫 인사 입력란은 이 계획에서 만들지 않는다(5번 계획이 더한다).
- 크리에이터 쪽 03은 같은 화면이고 설명은 `저장은 나만 보고, 관심은 상대에게 전해져요.`까지만 쓴다. 비교 동그라미와 비교 버튼이 없다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('shows counts on each tab and filters the grid', ...);
testWidgets('never shows passed candidates', ...);
testWidgets('the first tab is labelled saved and counts likes and holds', ...);   // '저장 2'
testWidgets('the top two saved cards start selected for comparison', ...);
testWidgets('tapping the circle toggles the comparison check', ...);
testWidgets('a third selection is refused with a message', ...);            // '비교는 2명까지예요.'
testWidgets('compare is enabled only with two selected cards and shows the count', ...);   // '선택한 2명 비교하기'
testWidgets('the creator side has no comparison controls', ...);
testWidgets('compare shows the seven rows with the canvas labels', ...);
testWidgets('compare marks only the differing rows with a dot', ...);
testWidgets('compare shows no follower counts', ...);                      // find.textContaining('팔로워') → 안내 문구 하나뿐
testWidgets('compare offers to propose to a waiting candidate and to view a mutual one', ...);   // '민에게 제안', '서윤의 제안 보기'
testWidgets('proposing from compare sends a like with the proposal', ...);
testWidgets('a held card can be turned into a like or a pass', ...);
testWidgets('the match sheet shows the campaign badge and the two new buttons', ...);
testWidgets('the received-proposal button opens the terms screen', ...);
testWidgets('proposing first from the match sheet creates a new version and goes to progress', ...);
testWidgets('the match sheet no longer has the keep-browsing button', ...);
testWidgets('shows the empty message', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 관심·보류, 후보 비교, 서로 관심 화면 추가`, `feat: 비교와 서로 관심에서 보상 제안 만들기 연결`

---

### Task 11: 앱 — 크리에이터의 발견(08, D1), 조건 초안(06), 진행 단계(07)

**Files:**
- Create: `app/lib/features/discovery/presentation/{viewmodels/creator_discovery_view_model.dart,pages/creator_discovery_page.dart,pages/campaign_detail_page.dart}`, `app/lib/features/negotiation/domain/{terms_version.dart,negotiation_repository.dart}`, `data/api_negotiation_repository.dart`, `presentation/viewmodels/{terms_view_model.dart}`, `presentation/pages/{draft_terms_page.dart,brand_progress_page.dart,collaboration_hub_page.dart}`, `presentation/terms_text.dart`
- Modify: `app/lib/features/store_browse/…`(목록 화면을 없애고 `/creator`를 발견 화면으로), `app/lib/core/navigation/app_router.dart`
- Test: `app/test/features/discovery/creator_discovery_*_test.dart`, `app/test/features/negotiation/`

**Interfaces:**
- Consumes: `SwipeDeck` (Task 8), `DiscoveryRepository` (Task 9), 2번의 `StoreBrowseRepository.apply`, `cora_api`의 `getCampaignDetail`, `getLatestTerms`, `confirmTerms`, `listCollaborations` (Task 5, 6), 3번의 `Collaboration`
- Produces:
  - `terms_text.dart`(순수 함수): `revisionLabel(RevisionScope)`(`없음`, `기획안 기준 1회`, `초안 기준 1회`, `초안 기준 2회`), `usageLabel(UsageRights)`(`브랜드 계정 재게시만`, `광고 소재로도 사용`, `사용 안 함`), `payoutLabel(int days)`(`최종 게시 후 7일 이내`), `deliverableLabel(format, pieces)`(`릴스 1편`), `startLabel(DateTime)`(`11월 16일 이후`), `reasonLabel(MatchReason)`
  - (2026-11-12) 더하는 라벨: `cashLabel(int won)`(1만 원 단위면 `30만 원`, 아니면 `350,000원`), `wonLabel(int won)`(`350,000원`), `benefitLabel(bool productProvided)`(`제품 제공` / `없음`), `perfLabel(performance)`(`없음` / `최대 6만 원`), `compareUsageLabel(UsageRights)`, `termsHeader(version, myTurn, mine, agreed)`(06의 머리와 표지), `nextActionLabel(NextAction)`
  - 라우트: `/creator`(발견), `/creator/campaigns/:id`, `/collaborations/:id/terms`, `/collaborations/:id/progress`, `/creator/collaborations`와 `/brand/collaborations`(협업 탭)
  - 크리에이터 하단 메뉴: `발견`, `관심`, `대화`(준비 중), `협업`, `프로필`(준비 중)

화면 문구:
- 08: 머리 알약 `크리에이터`. 표지 `내 원칙과 맞는 캠페인 {n}/{total}`. 캠페인 카드: 브랜드 이름, 캠페인 한 줄, `{제작비}` 또는 `{제작비} + 제품`, 꼬리표. 가게 카드: 가게 이름, 소개 첫 문장, `{보상 줄}`(Task 4의 `rewardLine`. 2026-11-12 캔버스: `식사권 + 조회수 수당`), `#소상공인 #팔로워무관`, 다른 시·도면 표지 `{시·도}`.
- 알림 문구: 넘김 `넘겼어요. 브랜드에는 알리지 않아요.` + `이유 남기기` / 관심 `관심을 보냈어요. 브랜드도 고르면 알려드려요.` + `관심 목록` / 가게를 오른쪽으로 밀면 `지원했어요. 사장님이 고르면 오퍼가 도착해요.`(가게 흐름 개정의 `조건 그대로 지원`과 같은 호출이다) / 서로 관심 `{브랜드 이름}와 서로 관심이 닿았어요.` + `확인하기`.
- 가게 카드는 위로 밀기(보류)가 없다. 위로 밀면 제자리로 돌아온다.
- 다 봤을 때: `오늘 맞는 캠페인을 모두 봤어요.`, `협업 원칙을 다듬으면 더 잘 맞는 캠페인이 올라와요.`, `협업 원칙 다듬기`, `마지막 카드 되돌리기`. (08 캔버스 그대로다. 모양은 F8 공용 위젯을 쓴다.)
- 08에서 넘긴 뒤의 `이유 남기기`는 Task 9의 02 시트를 그대로 쓴다. 가게 카드를 넘긴 뒤에도 뜬다.
- 원칙이 없으면 화면 위 띠: `협업 원칙을 정하면 브랜드에게 보여요.` / `정하기`.
- 카드를 누르면: 캠페인 → D1, 가게 → 2번의 D2.
- D1: `{브랜드 이름}, {한 줄 소개}`, 캠페인 한 줄, `{제작비}` + `+ 제품 제공, {형식} 1편`, 상자 `나와 잘 맞는 이유` / 이유를 문장으로 이은 글 + `내 협업 원칙과 {n}개가 겹쳐요.`(0개면 상자를 숨긴다), `꼭 담을 것` 목록(비면 `정해진 것이 없어요`), `요구하지 않아요` 목록, `일정` / `{날짜} 이후`, `제품 사용` / `{n}일 먼저 사용`(`ANY`면 `기간 자유`). 버튼 `넘기기`, `관심 보내기`.
- 06(2026-11-12 개정): 사진, 상대 이름, 콘텐츠 제목. 머리 `받은 제안 · 판본 {n}`, 오른쪽 표지 `내가 응답할 차례`(`accent` 알약). 머리와 표지는 `termsHeader`로 정한다:
  - `myTurn` → `받은 제안 · 판본 {n}` / `내가 응답할 차례`
  - 내가 확인했거나 내가 낸 판본이고 상대가 아직 → `mine`이면 `보낸 제안 · 판본 {n}`, 아니면 `받은 제안 · 판본 {n}` / `상대 대기`
  - 양쪽 확인 → `합의한 조건 · 판본 {n}` / `합의 완료`
- 06의 칸 세 개(옛 큰 글자 제작비 자리): `현금 고정비` / `{cashLabel}`, `혜택` / `{benefitLabel}`, `성과 추가` / `{perfLabel}`. 그 아래 `수락하면 이 판본 조건으로 계약 준비를 시작해요. 최대 현금 부담 {cashLabel(maxCash)}.` 성과 추가가 있으면 뒤에 ` 성과 추가는 조회수만큼, 남으면 환불해요.`
- 그 아래는 전과 같다: `{형식 라벨}`, `{시작 라벨}`, 안내 한 줄(`notice`가 있을 때). 접히는 묶음:
  - `추천된 이유` / 요약은 첫 이유의 라벨 → 안: `잘 맞는 점`(이유 라벨들), `주요 분야`, `팔로워`(연동돼 있으면 숫자, 아니면 줄을 숨긴다)
  - `수정과 촬영` / `{수정 범위}` → 안: `수정 범위`, `추가 촬영` / `별도 협의`
  - `콘텐츠 활용` / `{활용 권한}` → 안: `재게시`, `광고 활용` / `별도 협의`(활용 권한이 `광고 소재로도 사용`이면 `포함`)
  - `지급과 광고 표시` / `{지급 라벨}` → 안: `지급 시점`, `광고 표시` / `게시물·영상에 명확히`
- 06의 버튼: `조건 수정 제안`(이 계획에서는 `준비 중이에요` 화면으로), `이 판본 수락`(옛 `이 조건으로 협의`). 누르면 판본 번호와 함께 `confirmTerms` → 07로. 내가 이미 확인했으면 버튼이 `상대의 응답을 기다리고 있어요`(꺼짐), 양쪽이 확인했으면 수락 버튼이 없다.
- 06에서 `confirmTerms`가 409 `STALE_VERSION`이면 F8 공용 위젯의 옛 판본 상태를 띄운다: `이전 판본이라 수락할 수 없어요`, `상대가 판본 {n}을 보냈어요. 바뀐 조건을 확인한 뒤 수락해 주세요.`, `판본 {n} 보기`(최신 판본으로 06을 다시 읽는다).
- 06에서 `needsInstagram`이면 수락 버튼 대신 `인스타그램을 연동하면 수락할 수 있어요`와 연동 버튼(3번의 인스타그램 연동 화면으로)을 보여 준다.
- 07(2026-11-12 개정): 머리 로고, 상대 사진, `콘텐츠 방향을 함께 잡아요.`, `{크리에이터 이름}과 {브랜드 이름}`. 그 아래 강조 상자(`accent` 바탕, 오른쪽 화살표) `지금 할 일` / `{nextActionLabel}`:
  - `RESPOND_TERMS` → `받은 제안 확인하고 응답하기`(캔버스에 없는 문구, 설계 6장 16번) → 06
  - `SIGN_CONTRACT` → `계약서 확인하고 동의하기` → D4(5번 계획. 이 계획에서는 `준비 중이에요` 화면으로)
  - `nextAction`이 null이면 상자를 숨긴다.
- 07의 두 칸: `이번 협업 확보액` / `{wonLabel(securedAmount)}`(누르면 06), `남은 캠페인 예산` / `{wonLabel(left)}`(누르면 F3 제안함. 가게 흐름 개정 계획의 화면을 연다. 브랜드의 줄은 5번 계획이 채우므로 그 전에는 F8의 빈 상태가 보인다). `over > 0`이면 남은 예산 칸에 `0원`과 그 아래 `예산을 {wonLabel(over)} 넘었어요.` `campaignBudgetLeft`가 null(크리에이터)이면 확보액 한 칸만 가로로 길게 둔다.
- 07의 진행: `진행 단계` / `{doneCount} / 6 완료`, 막대, 여섯 줄: `서로 관심 확인`, `조건 검토 의사 표시`, `양쪽 조건 확정·계약`, `기획안 검토·제작`, `광고 표시·초안 검토`, `게시·성과 확인`. 현재 줄의 보조 글: `WAITING_OTHER_CONFIRM` → `상대의 동의를 기다리고 있어요`, `WAITING_CONTRACT` → `계약을 진행해 주세요`. 옛 `함께 만들 콘텐츠` 상자와 맨 아래 안내 문장(`상대의 동의와 최종 계약을 확인한 뒤 제작을 시작해요.`)은 없다.
- 협업 탭: 브랜드는 진행 중인 브랜드 협업의 목록(한 건이면 바로 07). 크리에이터는 위에서 `받은 오퍼` / `진행 중`으로 나누고, `진행 중`에 가게 협업(3번)과 브랜드 협업을 함께 보여 준다. 빈 목록 `아직 진행 중인 협업이 없어요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('labels terms the way the canvas does', ...);
testWidgets('mixes campaign and store cards', ...);
testWidgets('swiping a store card right applies to the store', ...);
testWidgets('swiping a store card up snaps back', ...);
testWidgets('shows the principles banner when none are set', ...);
testWidgets('campaign detail lists the overlap reasons and count', ...);
testWidgets('campaign detail hides the reasons box when nothing overlaps', ...);
testWidgets('store cards show the short reward line', ...);                // '식사권 + 조회수 수당'
testWidgets('the reason sheet also opens after passing a store card', ...);
testWidgets('terms shows the received-proposal header with the version and my-turn badge', ...);   // '받은 제안 · 판본 1', '내가 응답할 차례'
testWidgets('terms shows the three reward cells and the maximum cash burden', ...);                // '현금 고정비', '혜택', '성과 추가', '최대 현금 부담 30만 원'
testWidgets('terms shows the notice and four groups', ...);
testWidgets('accepting the version sends its number and goes to the progress screen', ...);
testWidgets('the accept button waits once I have accepted', ...);
testWidgets('a stale version shows the shared older-version state and reloads the latest', ...);
testWidgets('a creator without instagram sees the connect prompt instead of accept', ...);
testWidgets('progress shows two of six done after one side confirms', ...);
testWidgets('progress shows what to do now and opens the terms or the contract placeholder', ...);
testWidgets('progress shows the secured amount and the budget left for a brand', ...);
testWidgets('progress hides the campaign budget from a creator', ...);
testWidgets('progress shows the overrun when the budget is exceeded', ...);
testWidgets('progress no longer shows the content box or the closing note', ...);
testWidgets('tapping the budget left opens the proposals inbox', ...);
testWidgets('the collaboration tab mixes store and brand collaborations for a creator', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 세 개: `feat: 크리에이터 발견 화면과 캠페인 상세 추가`, `feat: 조건 초안 화면 추가`, `feat: 진행 단계와 협업 탭 추가`

---

### Task 12: 전체 흐름 확인

**Files:** 없음

- [ ] **Step 1: 자동 확인** — `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db` · `cd app && flutter analyze && flutter test` · `./scripts/gen-api.sh && git status --short`(변경 없음)

- [ ] **Step 2: 세 계정으로 수동 확인** (A 브랜드, B 크리에이터, C 가게. iOS와 Android 각각)

1. B: 프로필에 대표 콘텐츠 한 줄과 사진 → 협업 원칙 7문항(피하는 업종 `주류`) → 발견.
0. 역할이 없는 새 계정: A1의 `등록 없이 먼저 둘러보기` → 카드를 왼쪽으로 넘기면 다음 카드, 오른쪽으로 밀면 A1로 돌아오고 `역할을 고르면 관심을 보낼 수 있어요.` 피하는 업종을 고른 B는 둘러보기에 나오지 않는다(1번에서 `주류`를 고른 뒤 확인).
2. A: 브랜드 프로필(업종 `액세서리·주얼리`) → 캠페인 만들기(제작비 30만 원, 캠페인 예산 50만 원) → 발견에 B의 카드.
3. A: B를 오른쪽으로 민다 → `관심을 보냈어요…`. B: 발견 맨 앞에 A의 캠페인이 나오지만 A가 관심을 보냈다는 표시는 없다.
4. B: A의 캠페인을 오른쪽으로 민다 → `…서로 관심이 닿았어요.` → `확인하기` → 05 시트(표지 `… 캠페인에서 연결`) → `받은 제안 보기 · 1건` → 06에 `받은 제안 · 판본 1`, `내가 응답할 차례`, `최대 현금 부담 30만 원`.
5. B: `이 판본 수락` → 07에 `2 / 6 완료`, 현재 3단계 `상대의 동의를 기다리고 있어요`, `이번 협업 확보액 300,000원`. B의 07에는 `남은 캠페인 예산`이 없다.
6. A: 관심 탭에 `서로 관심` → `협업 조건 확인` → `이 판본 수락` → 협업 단계가 `AGREED`(서버에서 확인). A의 07에 `지금 할 일 · 계약서 확인하고 동의하기`, `남은 캠페인 예산 200,000원`. 예산 칸을 누르면 F3가 열린다.
6-1. A: 다른 크리에이터 D와 서로 관심 → 05에서 `내가 먼저 제안하기` → F1에서 현금 고정비 35만 원 → F2 `이 조건으로 보내기` → D의 06에 `받은 제안 · 판본 2`. 그동안 판본 1 화면을 열어 둔 D가 `이 판본 수락`을 누르면 `이전 판본이라 수락할 수 없어요`. A의 07에 `남은 캠페인 예산 0원`과 `예산을 150,000원 넘었어요.`
6-2. A: 관심 탭에서 두 후보를 체크 → `선택한 2명 비교하기` → 값이 다른 줄에만 점. 서로 관심이 아닌 후보에게 `…에게 제안` → F1·F2 → 그 후보의 받은 제안 조회(`listReceivedProposals`)에 제안한 금액이 보인다.
7. A: 다른 크리에이터를 왼쪽으로 밀고 `이유 남기기` → `금액이 안 맞아요` → `이유 남기고 다음 보기`. 그 크리에이터 계정으로 들어가 어디에도 흔적이 없음을 확인. 한 번 더 넘기고 시트의 `되돌리기` → 카드가 맨 앞에 돌아온다.
8. C의 가게 업종을 `주류`로 바꾼다 → B의 발견과 가게 목록에서 C가 사라진다.
9. A의 업종을 `주류`로 바꾼다 → A의 발견에서 B가 사라진다(오늘 목록이 이미 만들어진 뒤에도).
10. 카드를 빠르게 연달아 넘겨도 결정이 한 장에 하나씩만 저장된다.
11. 다크 모드, 글자 1.3배에서 01, 02, 03, 04, 05, 06, 07, 08, 09, D1, 둘러보기.
12. 2026-11-12 캔버스의 해당 화면과 라이트·다크를 각각 나란히 놓고 비교한다. 다크는 하단 메뉴의 고른 탭 색, 09의 진행 막대, 02에서 고른 이유의 색을 본다(설계 "다크 모드에서만 바뀐 것").

---

## 완료 기준

- Task 12의 자동 확인과 수동 확인(0번부터 12번, 6-1과 6-2 포함) 통과
- 설계 6장 7~16번(2026-11-12 개정의 확인 항목)에 소유자의 답이 있으면 그 답대로, 없으면 설계의 **[제안]**대로 만들어져 있다
- Task 8 Step 5의 소유자 승인 완료

## 이 계획이 하지 않는 것

- 조건 수정 제안(돈과 혜택 밖의 항목), 대화, 계약(D4), 받은 제안 화면(10), F3에 브랜드의 줄 채우기, 차단에 따른 추천 제외 (5번 계획)
- F1·F2·F3·F8 화면 만들기와 고치기, A1의 다른 변화, 가게 모집 조건의 보상 세 요소 (가게 흐름 개정 계획)
- 캠페인 예산을 넘는 수락과 제안을 막는 것 (설계 6장 14번의 답이 나오기 전에는 알리기만 한다)
- 릴스 피드와 포트폴리오, B5 프로필 (7번 계획)
- 운영자가 추천을 직접 고르는 도구
