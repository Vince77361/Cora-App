# 브랜드 탐색·매칭과 협업 원칙 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

**Goal:** 크리에이터가 협업 원칙을 정하고, 브랜드가 캠페인을 만들고, 양쪽이 카드를 넘겨 서로 관심이 닿으면 협업과 조건 버전 1이 만들어져 "이 조건으로 협의"를 누를 수 있는 데까지를 만든다.

**Architecture:** 추천은 하루 한 번(조회할 때 없으면) 만들어 저장하는 목록이고, 점수는 순수 함수가 계산한다. 누가 누구에게 보이는지는 서버의 공통 필터 하나(`VisibilityService`)가 정하고 모든 조회가 그것을 거친다. 서로 관심이 닿는 순간 한 트랜잭션에서 `matches`, 브랜드 계약 협업(`MATCHED`), 조건 버전 1을 만든다. 조건 버전 테이블은 이 계획에서 만들고 5번 계획이 수정 제안과 계약을 더한다.

**Tech Stack:** 앞 계획들과 같다. 앱의 카드 넘기기는 Flutter의 `AnimationController`와 `SpringSimulation`으로 직접 만든다(패키지를 쓰지 않는다. 움직임을 소유자가 승인해야 하기 때문이다).

**Spec:** `docs/superpowers/specs/2026-11-11-brand-discovery-matching-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md` (1, 3, 4, 5, 6, 7, 8, 14장)

**선행 조건:** 공통 기반, 2번, 3번 계획이 끝나 있어야 한다. 이 계획은 3번의 `collaborations`·`CollaborationStage`·`CollaborationsRepository.advance`, 2번의 `IndustryCategory`·`ContentFormat`·`stores`·`creator_profiles`·`StoresService`·`CreatorsService`·`UploadsService`·`Clock`, 앱의 `CoraBottomNav`·`CoraTransitions`·`roleEntryResolverProvider`·모션 갤러리를 쓴다.

## Global Constraints

앞 계획들의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것:

- 넘김과 넘긴 이유는 본인의 응답과 추천 계산에만 쓴다. 상대에게 가는 어떤 응답 모델에도 넣지 않는다. 이를 확인하는 테스트를 둔다.
- 크리에이터가 피하는 업종의 가게와 브랜드에게 그 크리에이터는 존재하지 않는 것처럼 보인다(조회 404, 목록에서 빠짐). 모든 조회는 `VisibilityService`를 거친다.
- 협업 원칙이 없는 크리에이터는 브랜드에게 보이지 않는다. 사장님에게는 보인다.
- 고정 값: 하루 추천 `10`장, 추천을 새로 만드는 기준 시각은 한국 시간 자정, 넘기기 기준 가로 `110`·세로 `-140`(가로 `80` 미만), 카드 최대 기울기 `12`도, 좋아한 점 `100`자, 콘텐츠 한 줄 `40`자.
- 민감 업종은 `ALCOHOL`, `GAMBLING`, `LOAN`, `DIET_SUPPLEMENT` 네 개다. 나머지 아홉 개가 일반 업종이다.
- 조건 버전은 만들기만 하고 고치지 않는다.
- 작업 브랜치는 `feat/brand-discovery-matching`.

## Review Focus

1. **넘긴 사실이 상대에게 새는 경로** → 상대의 추천, 관심 목록, 상세, 알림 어디에도 넘김과 이유가 없다. (Task 5)
2. **양쪽이 거의 동시에 관심을 보냄** → 매칭, 협업, 조건 버전 1이 한 번만 만들어진다. (Task 5)
3. **피하는 업종을 나중에 추가함** → 이미 만들어진 오늘의 추천에서도 바로 빠진다. (Task 2, 4)
4. **추천할 상대가 한 명도 없음** → 빈 화면이 아니라 안내와 다음 행동이 보인다. (Task 9, 11)
5. **카드를 미는 도중 손을 떼거나 빠르게 연달아 넘김** → 카드가 겹치거나 결정이 두 번 저장되지 않는다. (Task 8)

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
  - `enum FeeBand { W200K, W300K, W400K, W500K_PLUS }`, `enum ProductTrialDays { D3, D7, D14, ANY }`, `enum CampaignStatus { ACTIVE, CLOSED }`, `enum SwipeDecisionKind { LIKE, PASS, HOLD }`, `enum PassReason { MOOD, FIELD, TERMS, NONE }`, `enum SwipeTargetKind { CREATOR, CAMPAIGN, STORE }`, `enum NotRequired { FACE, FIXED_LINES, SCRIPT_READING }`
  - `CreatorPrinciples` → `creator_principles`: `creatorId`(unique), `fields: IndustryCategory[]`, `blockedIndustries: IndustryCategory[]`, `faceOk: Boolean`, `scriptOk: Boolean`, `honestReview: Boolean`, `feeBand`, `trialDays`
  - `BrandProfile` → `brand_profiles`: `userId`(unique), `name`, `tagline?`, `industry: IndustryCategory`, `photoPath?`
  - `Campaign` → `campaigns`: `brandId`, `status`, `headline`, `fee: Int`, `productProvided: Boolean`, `format: ContentFormat`, `startFrom: DateTime @db.Date`, `trialDays: ProductTrialDays`, `mustInclude: String[]`(최대 3), `notRequired: NotRequired[]`. 부분 유니크 인덱스: `(brand_id) WHERE status = 'ACTIVE' AND deleted_at IS NULL`.
  - `SwipeDecision` → `swipe_decisions`: `actorId`, `targetKind`, `targetId`, `campaignId?`(브랜드가 크리에이터를 볼 때 그 캠페인, 크리에이터가 캠페인을 볼 때 그 캠페인), `decision`, `passReason?`, `note?`, `contentTitle?`, `contentPhotoPath?`. 유일 제약 `(actorId, targetKind, targetId, campaignId)`.
  - `Match` → `matches`: `campaignId`, `creatorId`, `collaborationId`(unique), `matchedAt`. 유일 제약 `(campaignId, creatorId)`.
  - `DailyRecommendation` → `daily_recommendations`: `userId`, `scope`(`BRAND` | `CREATOR`), `campaignId?`, `day @db.Date`, `items: Json`(`{ kind, id }[]`). 유일 제약 `(userId, scope, campaignId, day)`.
  - `TermsVersion` → `terms_versions`: `collaborationId`, `version: Int`, `proposedById?`(버전 1은 null), `title`, `fee`, `startDate @db.Date`, `format`, `pieces: Int`, `productProvided`, `revisionScope`(`NONE | GUIDE_1 | DRAFT_1 | DRAFT_2`), `usageRights`(`REPOST_ONLY | ADS_TOO | NONE`), `payoutDays: Int`(7 | 14), `brandConfirmedAt?`, `creatorConfirmedAt?`. 유일 제약 `(collaborationId, version)`.
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
  - `CampaignModel { id; status; headline; fee; productProvided; format; startFrom: string; trialDays; mustInclude: string[]; notRequired: NotRequired[] }`
  - `GET /campaigns/mine/active` → 200 `CampaignModel` | 404. `operationId: getMyActiveCampaign`
  - `POST /campaigns` 본문 `{ headline(1~40자); fee(10000~10000000, 1만 원 단위); productProvided; format; startFrom(오늘 이후); trialDays; mustInclude(0~3줄, 줄마다 20자); notRequired }` → 201. 브랜드 프로필이 없으면 409, 이미 `ACTIVE`가 있으면 409. `operationId: createCampaign`
  - `PATCH /campaigns/:id` → 200(자기 것, `ACTIVE`만). `POST /campaigns/:id/close` → 200. `operationId: updateCampaign`, `closeCampaign`
  - `BrandsService`를 export: `requireProfile(userId)`. `CampaignsService`를 export: `requireMyActive(userId): Promise<Campaign>`(없으면 409 `캠페인을 먼저 만들어 주세요.`), `findActiveById(id)`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('requires the BRAND role', ...);
it('refuses a campaign before a brand profile exists', ...);               // 409
it('refuses a second active campaign', ...);                               // 409
it('allows a new campaign after closing the old one', ...);
it('rejects a fee that is not a multiple of 10000', ...);                  // 400
it('rejects a start date in the past', ...);                               // FakeClock
it('rejects more than three must-include lines', ...);
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
  - `PUT /discovery/decisions` 본문 `{ targetKind: 'CREATOR' | 'CAMPAIGN'; targetId: string; decision: 'LIKE' | 'PASS' | 'HOLD'; note?: string(100자) }` → 200 `DecisionResultModel { decision; matched: boolean; collaborationId: string | null }`. 브랜드는 `CREATOR`만, 크리에이터는 `CAMPAIGN`만. 대상이 보이지 않으면 404. 브랜드의 캠페인은 진행 중 캠페인으로 정해진다. `LIKE`에 `note`가 있으면 그 크리에이터의 `cardHeadline`과 `cardPhotoPath`를 `contentTitle`, `contentPhotoPath`에 사본으로 저장한다. 서로 관심이 이미 된 뒤에는 결정을 바꿀 수 없다(409). `operationId: putDecision`
  - 가게 카드의 결정은 이 엔드포인트가 아니다. 앱이 `LIKE`는 2번의 `applyToStore`, `PASS`는 `PUT /discovery/store-passes/:storeId`(이 작업에서 만든다, `targetKind: STORE`로 저장)로 보낸다.
  - `PUT /discovery/decisions/pass-reason` 본문 `{ targetKind; targetId; reason: PassReason }` → 204. `PASS` 결정이 있을 때만. `operationId: putPassReason`
  - `DELETE /discovery/decisions/last` → 200 `{ targetKind; targetId } | null` — 내가 오늘 한 마지막 결정을 지운다. 서로 관심이 된 것이면 409. `operationId: undoLastDecision`
  - 서로 관심 판정: 결정을 저장한 같은 트랜잭션에서, 반대쪽의 `LIKE`가 있으면 `matches` 행 삽입(유일 제약 위반이면 이미 된 것으로 보고 넘어간다), 협업 생성(`kind: BRAND_CONTRACT`, `stage: MATCHED`, `settlementMethod: FIXED`, `commissionerId` = 브랜드 사용자), `terms_versions` 버전 1(`draftTerms`, 크리에이터의 `note`가 있으면 제목으로). 그 뒤 양쪽에 `{상대 이름}과 서로 관심이 닿았어요.`
  - `GET /discovery/interests?tab=all|mutual|sent|held` → 200 `InterestCardModel[] { targetKind; targetId; name; headline: string | null; photoUrl: string | null; state: 'MUTUAL' | 'WAITING' | 'HELD'; feeLabel: number | null; startFrom: string | null; collaborationId: string | null }` — 내 `LIKE`와 `HOLD`만. 넘긴 것은 어디에도 나오지 않는다. `operationId: listInterests`
  - `GET /discovery/received-proposals` → 200 `ProposalModel[] { campaignId; brandName; brandPhotoUrl; note; contentTitle: string | null; contentPhotoUrl: string | null; fee; productProvided; format }` — `CREATOR` 역할. 나에게 온 `note` 있는 `LIKE` 가운데 내가 아직 결정하지 않은 것. (화면은 5번 계획이 만든다.) `operationId: listReceivedProposals`
  - `GET /campaigns/:id/detail` → 200 `CampaignDetailModel` = `CampaignCardModel` + `{ startFrom; trialDays; mustInclude; notRequired; reasons; overlapCount: number; myDecision: 'LIKE' | 'HOLD' | null }` — `CREATOR` 역할, 보이지 않으면 404. `myDecision`에 `PASS`는 나오지 않고(넘긴 캠페인의 상세는 404). `operationId: getCampaignDetail`
  - `GET /creators/:id/card` → 200 `CreatorCardModel` + `{ myDecision }` — `BRAND` 역할, `VisibilityService`를 통과해야 한다. `operationId: getCreatorCard`
  - `TermsVersionModel { version; proposedBy: 'BRAND' | 'CREATOR' | 'SYSTEM'; title; fee; startDate; format; pieces; productProvided; revisionScope; usageRights; payoutDays; brandConfirmed: boolean; creatorConfirmed: boolean }`
  - `GET /collaborations/:id/terms/latest` → 200 `{ terms: TermsVersionModel; notice: string | null; reasons: MatchReason[]; trialDays; followers: number | null }` — 당사자만. `notice`는 크리에이터의 원칙에서 만든다: 둘 다 false면 `얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.`, 얼굴만 false면 `얼굴 출연은 진행하지 않아요.`, 대본만 false면 `제품 설명문 낭독은 진행하지 않아요.`, 아니면 null. `operationId: getLatestTerms`
  - `POST /collaborations/:id/terms/:version/confirm` → 200 `TermsVersionModel`. 최신 버전만 확인할 수 있다(아니면 409). 내 쪽 확인 시각을 조건부로 채운다. 협업이 `MATCHED`면 `NEGOTIATING`으로, 양쪽이 다 확인했으면 `AGREED`로 옮긴다. 상대에게 `{이름}님이 조건을 확인했어요.` `operationId: confirmTerms`
  - `TermsService`를 export: `latest(collaborationId)`, `createVersion(collaborationId, proposedById, values)`(5번 계획이 쓴다)

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
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 세 개: `feat: 관심·넘김·보류와 서로 관심 추가`, `feat: 조건 버전 1 자동 생성과 확인 추가`, `feat: 관심 목록과 상세 조회 추가`

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

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('maps every brand stage to the six step progress', ...);                 // 표의 아홉 줄
it('lists a matched brand collaboration as active for both sides', ...);
it('returns the campaign and the latest terms title', ...);
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
  - `abstract class DiscoveryRepository { Future<({int total, List<CreatorCard> cards})> fetchCreatorCards(); Future<({int total, List<DiscoveryCard> cards})> fetchCampaignCards(); Future<DecisionResult> decide(DiscoveryTarget target, SwipeOutcome o, {String? note}); Future<void> setPassReason(DiscoveryTarget target, PassReason r); Future<DiscoveryTarget?> undoLast(); }`
  - `sealed class DiscoveryCard`(`CampaignCard`, `StoreCard`), `class CreatorCard`
  - 라우트: `/brand/profile/setup`, `/brand/campaign/new`, `/brand/campaign/edit`, `/brand`(발견), `/brand/creators/:id`
  - `roleEntryResolverProvider`의 `brand` 분기: 프로필 없음 → `/brand/profile/setup`, 진행 중 캠페인 없음 → `/brand/campaign/new`, 있음 → `/brand`
  - 브랜드 하단 메뉴: `발견`, `관심`, `대화`(준비 중), `협업`, `프로필`(준비 중)

화면 문구:
- 브랜드 프로필: 제목 `어떤 브랜드인가요?`, `브랜드 이름`, `한 줄 소개 (선택)` 예시 `예: 느린 결, 일상의 주얼리`, `업종`(13개 고르기), `대표 사진 (선택)`, 버튼 `다음`.
- 캠페인 만들기: 제목 `어떤 콘텐츠를\n함께 만들까요?`, `캠페인 한 줄` 예시 `예: 나만의 아침 루틴 속 작은 포인트`, `제작비 (원)`, `제품 제공`(스위치), `형식`(네 가지), `시작 가능한 날`, `제품 사용 기간`(`3일`, `7일`, `14일`, `상관없어요`), `꼭 담을 것 (최대 3줄)`, `요구하지 않는 것`(`얼굴 출연`, `정해진 대사`, `대본 낭독`), 버튼 `캠페인 시작하기`. 고치기 화면은 버튼 `저장`과 `캠페인 마감`(확인 `캠페인을 마감할까요? 진행 중인 협업은 그대로 이어져요.`).
- 01 발견: 머리 로고 `cora`, 오른쪽 알약 `브랜드`. 카드 표지 `운영자 추천 {n}/{total}`. 카드: 이름, 콘텐츠 한 줄(없으면 `대표 콘텐츠를 준비 중이에요`), 희망 제작비(`20만 원대`, `30만 원대`, `40만 원대`, `50만 원 이상`), 꼬리표 `#…`. 아래 버튼 셋: 넘김, 보류, 관심(아이콘, `aria` 이름 포함).
- 알림 문구(카드 아래에 3초): 넘김 `넘겼어요. 상대에게는 알리지 않아요.` + `이유 남기기` / 관심 `관심을 보냈어요. 상대도 고르면 알려드려요.` + `관심 목록` / 보류 `보류함에 담았어요.` + `보류 보기` / 서로 관심 `{이름}과 서로 관심이 닿았어요.` + `확인하기`(→ Task 10의 05 화면).
- 다 봤을 때: `오늘 추천을 모두 봤어요.`, `관심과 보류에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.`, `관심·보류 보기`, `마지막 카드 되돌리기`. 오늘 목록이 처음부터 0장이면 `아직 추천할 크리에이터가 없어요.`, `크리에이터가 늘어나면 알려드릴게요.`
- 02 넘기기 이유(아래에서 올라오는 시트): `어떤 점이 달랐나요?`, `다음 추천에만 반영하고, {이름}에게는 알리지 않아요.`, `분위기가 달라요`, `분야가 달라요`, `조건이 안 맞아요`, `이유 없이 넘기기`, `넘기고 다음 추천 보기`, `취소`.
- 크리에이터 상세(임시, 7번에서 B5로 대체): 사진, 이름, 콘텐츠 한 줄, 꼬리표, `잘 맞는 점`(이유의 표시 이름: `분야가 맞아요`, `얼굴 출연 조건이 맞아요`, `대본 조건이 맞아요`, `제작비가 맞아요`, `제품 사용 기간이 맞아요`), 버튼 `넘기기`, `관심 보내기`. `관심 보내기`를 누르면 시트: `좋았던 점을 한 줄 남길까요? (선택)`, 입력란, `관심 보내기`.
- 카드에서 상세로 갈 때 사진이 `Hero`(`'creator:<id>'`)로 이어진다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('brand entry goes to profile, then campaign, then discovery', ...);
testWidgets('campaign form requires headline, fee, format and start date', ...);
testWidgets('shows the badge with position and total', ...);                // '운영자 추천 1/3'
testWidgets('swiping right sends a like and shows the like toast', ...);
testWidgets('swiping left shows the pass toast with a reason link', ...);
testWidgets('the reason sheet saves one reason', ...);
testWidgets('a mutual like shows the match toast', ...);
testWidgets('shows the all-seen state with undo', ...);
testWidgets('undo brings back the last card', ...);
testWidgets('shows the no-candidates state when today has zero cards', ...);
testWidgets('the card returns when the decision fails', ...);              // '잠시 뒤 다시 시도해 주세요.'
testWidgets('liking from the detail can carry a note', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 브랜드 프로필과 캠페인 만들기 화면 추가`, `feat: 브랜드 발견 화면과 넘기기 이유 추가`

---

### Task 10: 앱 — 관심·보류(03), 비교(04), 서로 관심(05)

**Files:**
- Create: `app/lib/features/interests/domain/{interest_card.dart,interests_repository.dart}`, `data/api_interests_repository.dart`, `presentation/viewmodels/interests_view_model.dart`, `presentation/pages/{interests_page.dart,compare_page.dart,match_sheet.dart}`
- Test: `app/test/features/interests/`

**Interfaces:**
- Consumes: `cora_api`의 `listInterests`, `putDecision` (Task 5), `CoraTransitions.sheet`
- Produces: 라우트 `/brand/interests`, `/brand/interests/compare?a=…&b=…`, `/creator/interests`. 05는 `showMatchSheet(context, MatchInfo)`.

화면 문구:
- 03: 제목 `관심·보류`, 설명 `관심 표시는 협업 확정이 아니에요. 모아두고 비교해요.` 탭 `전체 {n}`, `서로 관심 {n}`, `보낸 관심 {n}`, `보류 {n}`. 카드 표지 `서로 관심` / `응답 대기` / `보류`. 카드 아래 글: 이름, 콘텐츠 한 줄, `{제작비}, {가능한 날} 이후`(브랜드가 볼 때는 희망 제작비만).
- 서로 관심이 있으면 아래 상자: `{이름}과 서로 관심` / `협업 조건 확인`(→ Task 11의 06).
- 보류 카드를 누르면 시트: `관심 보내기`, `넘기기`.
- 버튼 `후보 2명 비교하기`: 카드를 길게 눌러 두 장을 고르면 켜진다. 골라진 카드에는 번호가 붙는다. 두 장이 아니면 `비교할 후보 2명을 길게 눌러 골라 주세요.`
- 빈 목록: `아직 담은 후보가 없어요. 발견에서 마음에 드는 카드를 오른쪽으로 밀어 보세요.`
- 04: 머리 `후보 비교`, 알약 `팔로워 수는 비교하지 않아요`. 두 칸에 표지, 이름, 콘텐츠 한 줄, 희망 제작비, 조건 한 줄(꼬리표 첫 번째), 버튼 `조건 보기`(서로 관심) 또는 `응답 기다리는 중`(꺼짐).
- 05(시트): 두 사진이 양쪽에서 들어와 겹치고 가운데 하트. `서로를 골랐어요.`, `{브랜드 이름}와 {크리에이터 이름}이 서로의 콘텐츠에 관심을 표시했어요. 아직 계약이나 지급 의무는 생기지 않아요.`, 버튼 `협업 조건 확인하기`, `계속 둘러보기`. 첫 인사 입력란은 이 계획에서 만들지 않는다(5번 계획이 더한다).
- 크리에이터 쪽 03은 같은 화면이고 설명만 `관심 표시는 협업 확정이 아니에요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('shows counts on each tab and filters the grid', ...);
testWidgets('never shows passed candidates', ...);
testWidgets('compare is enabled only with two selected cards', ...);
testWidgets('compare shows no follower counts', ...);                      // find.textContaining('팔로워') → 알약 문구 하나뿐
testWidgets('a held card can be turned into a like or a pass', ...);
testWidgets('the match sheet opens the terms screen', ...);
testWidgets('shows the empty message', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 관심·보류, 후보 비교, 서로 관심 화면 추가`

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
  - 라우트: `/creator`(발견), `/creator/campaigns/:id`, `/collaborations/:id/terms`, `/collaborations/:id/progress`, `/creator/collaborations`와 `/brand/collaborations`(협업 탭)
  - 크리에이터 하단 메뉴: `발견`, `관심`, `대화`(준비 중), `협업`, `프로필`(준비 중)

화면 문구:
- 08: 머리 알약 `크리에이터`. 표지 `내 원칙과 맞는 캠페인 {n}/{total}`. 캠페인 카드: 브랜드 이름, 캠페인 한 줄, `{제작비}` 또는 `{제작비} + 제품`, 꼬리표. 가게 카드: 가게 이름, 소개 첫 문장, `{보상 한 줄}`(2번의 `rewardHeadline`), `#소상공인 #팔로워무관`, 다른 시·도면 표지 `{시·도}`.
- 알림 문구: 넘김 `넘겼어요. 브랜드에는 알리지 않아요.` + `이유 남기기` / 관심 `관심을 보냈어요. 브랜드도 고르면 알려드려요.` + `관심 목록` / 가게를 오른쪽으로 밀면 `지원했어요. 사장님이 고르면 오퍼가 도착해요.` / 서로 관심 `{브랜드 이름}와 서로 관심이 닿았어요.` + `확인하기`.
- 가게 카드는 위로 밀기(보류)가 없다. 위로 밀면 제자리로 돌아온다.
- 다 봤을 때: `오늘 맞는 캠페인을 모두 봤어요.`, `협업 원칙을 다듬으면 더 잘 맞는 캠페인이 올라와요.`, `협업 원칙 다듬기`, `마지막 카드 되돌리기`.
- 원칙이 없으면 화면 위 띠: `협업 원칙을 정하면 브랜드에게 보여요.` / `정하기`.
- 카드를 누르면: 캠페인 → D1, 가게 → 2번의 D2.
- D1: `{브랜드 이름}, {한 줄 소개}`, 캠페인 한 줄, `{제작비}` + `+ 제품 제공, {형식} 1편`, 상자 `나와 잘 맞는 이유` / 이유를 문장으로 이은 글 + `내 협업 원칙과 {n}개가 겹쳐요.`(0개면 상자를 숨긴다), `꼭 담을 것` 목록(비면 `정해진 것이 없어요`), `요구하지 않아요` 목록, `일정` / `{날짜} 이후`, `제품 사용` / `{n}일 먼저 사용`(`ANY`면 `기간 자유`). 버튼 `넘기기`, `관심 보내기`.
- 06: 사진, 상대 이름, 콘텐츠 제목. `협의 전 초안`, 오른쪽 `서로 관심`. 큰 글자 제작비, `{형식 라벨}`, `{시작 라벨}`. 안내 한 줄(`notice`가 있을 때). 접히는 묶음:
  - `추천된 이유` / 요약은 첫 이유의 라벨 → 안: `잘 맞는 점`(이유 라벨들), `주요 분야`, `팔로워`(연동돼 있으면 숫자, 아니면 줄을 숨긴다)
  - `수정과 촬영` / `{수정 범위}` → 안: `수정 범위`, `추가 촬영` / `별도 협의`
  - `콘텐츠 활용` / `{활용 권한}` → 안: `재게시`, `광고 활용` / `별도 협의`(활용 권한이 `광고 소재로도 사용`이면 `포함`)
  - `지급과 광고 표시` / `{지급 라벨}` → 안: `지급 시점`, `광고 표시` / `게시물·영상에 명확히`
- 06의 버튼: `조건 수정 제안`(이 계획에서는 `준비 중이에요` 화면으로), `이 조건으로 협의`. 누르면 `confirmTerms` → 07로. 내가 이미 확인했으면 버튼이 `상대의 확인을 기다리고 있어요`(꺼짐).
- 07: 머리 로고, 상대 사진, `콘텐츠 방향을 함께 잡아요.`, `{크리에이터 이름}과 {브랜드 이름}`, 상자 `함께 만들 콘텐츠` / `“{제목}”`, `진행 단계` / `{doneCount} / 6 완료`, 막대, 여섯 줄: `서로 관심 확인`, `조건 검토 의사 표시`, `양쪽 조건 확정·계약`, `기획안 검토·제작`, `광고 표시·초안 검토`, `게시·성과 확인`. 현재 줄의 보조 글: `WAITING_OTHER_CONFIRM` → `상대의 동의를 기다리고 있어요`, `WAITING_CONTRACT` → `계약을 진행해 주세요`. 아래 `상대의 동의와 최종 계약을 확인한 뒤 제작을 시작해요.` 조건 상자를 누르면 06.
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
testWidgets('draft terms shows the notice and four groups', ...);
testWidgets('confirming the terms goes to the progress screen', ...);
testWidgets('the confirm button waits once I have confirmed', ...);
testWidgets('progress shows two of six done after one side confirms', ...);
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
2. A: 브랜드 프로필(업종 `액세서리·주얼리`) → 캠페인 만들기 → 발견에 B의 카드.
3. A: B를 오른쪽으로 민다 → `관심을 보냈어요…`. B: 발견 맨 앞에 A의 캠페인이 나오지만 A가 관심을 보냈다는 표시는 없다.
4. B: A의 캠페인을 오른쪽으로 민다 → `…서로 관심이 닿았어요.` → `확인하기` → 05 시트 → `협업 조건 확인하기` → 06.
5. B: `이 조건으로 협의` → 07에 `2 / 6 완료`, 현재 3단계 `상대의 동의를 기다리고 있어요`.
6. A: 관심 탭에 `서로 관심` → `협업 조건 확인` → `이 조건으로 협의` → 협업 단계가 `AGREED`(서버에서 확인).
7. A: 다른 크리에이터를 왼쪽으로 밀고 `이유 남기기` → 그 크리에이터 계정으로 들어가 어디에도 흔적이 없음을 확인.
8. C의 가게 업종을 `주류`로 바꾼다 → B의 발견과 가게 목록에서 C가 사라진다.
9. A의 업종을 `주류`로 바꾼다 → A의 발견에서 B가 사라진다(오늘 목록이 이미 만들어진 뒤에도).
10. 카드를 빠르게 연달아 넘겨도 결정이 한 장에 하나씩만 저장된다.
11. 다크 모드, 글자 1.3배에서 01, 03, 06, 07, 08, 09, D1.
12. 캔버스의 해당 화면과 나란히 놓고 비교한다.

---

## 완료 기준

- Task 12의 자동 확인과 수동 확인 12개 통과
- Task 8 Step 5의 소유자 승인 완료

## 이 계획이 하지 않는 것

- 조건 수정 제안, 대화, 계약, 받은 제안 화면(10), 차단에 따른 추천 제외 (5번 계획)
- 릴스 피드와 포트폴리오, B5 프로필 (7번 계획)
- 운영자가 추천을 직접 고르는 도구
