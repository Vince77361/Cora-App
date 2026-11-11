# 계정·설정 화면 (E4 설정, E6 프로필 수정, E8 고객센터) Implementation Plan

> **상태: 소유자 승인 (2026-11-11).** 설계 `specs/2026-11-11-account-notify-settings-design.md` 9장의 추천안이 모두 2026-11-11 소유자 결정이다. 실행 순서는 7번 계획 다음, 8번 계획 전이다.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

**Goal:** 크리에이터·사장님·브랜드가 설정 허브(E4)에서 계정·알림·정산·보관함·도움으로 가고, 크리에이터가 프로필(E6)을 고치고, 누구나 자주 묻는 질문과 약관·문의(E8)를 쓴다.

**Architecture:** 서버는 크리에이터 프로필의 부분 수정(`PATCH /creators/me`)과 설정 화면 한 번에 필요한 값을 모은 `GET /me/settings`만 더한다. 나머지 값은 이미 있는 모듈(알림 설정, 계좌, 인스타그램 연결, 보관함, 협업 원칙)이 export한 서비스에서 읽는다. 휴대폰 번호는 서버를 거치지 않고 앱의 로그인 정보(`AuthRepository`)에서 읽고 바꾼다. 약관 문서와 운영자 이메일은 앱 설정값(`--dart-define`)이다.

**Tech Stack:** 공통 기반·2~7번 계획과 같다. 추가 없음(약관 문서는 기존 `url_launcher`가 없으면 이 계획에서 더한다 — 3번 Task 12의 `mailto`가 같은 패키지를 쓴다).

**Spec:** `docs/superpowers/specs/2026-11-11-account-notify-settings-design.md` (2장 E4·E6·E8, 6장, 9장 8번·6번) · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md` (4, 14, 20장) · 상위: `docs/superpowers/specs/2026-11-11-tech-stack-design.md`

**선행 조건:** 공통 기반, 2~7번 계획이 끝나 있어야 한다(8번과는 서로 기대지 않는다). 이 계획은 공통 기반의 `AuthRepository`·`SignInAdapter`·`FakeSignInAdapter`·E2 화면·A1 역할 선택(`/role`, `PATCH /me/role`)·`AppConfig`, 2번의 `creator_profiles`·`PUT /creators/me`·`CreatorProfileModel`·`CreatorSummaryModel`·사진 올리기(`createPhotoUpload`, `PhotoUploader`)·`/store/me`(내 가게)·A3 가게 페이지, 3번의 `PayoutAccountsService`·`BANKS`·`InstagramService`·`/creator/payout-account`·`/creator/instagram`·`NotificationsService`의 설정 조회·E5(`/settings/notifications`)·E7(`/creator/wallet`)·`AppConfig.operatorEmail`, 4번의 `PrinciplesService`(`updateFeeBand` export)·협업 원칙 09·브랜드 프로필 고치기, 6번의 `KeepService.countFor`·D5(`/keep`)·`ProfileMenuPage`, 7번의 소개 글(`bio`)·B2(톱니 → `/settings`)·B5 꼬리표를 그대로 쓴다.

## Global Constraints

공통 기반과 2~7번 계획의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것:

- 화면은 캔버스(`NSettings`, `NEditProfile`, `NHelp`와 `Dark…`)와 라이트·다크 각각 100% 같게 만든다. 설계 6장의 다크 차이(E4 줄 높이 52)를 그대로 따른다. 캔버스에 없는 상태는 설계 10장의 최소 문구로 만들고 끝에 소유자 확인 목록으로 올린다.
- 휴대폰 번호의 예는 `010-0000-XXXX`만 쓴다(테스트, 수동 확인, 스크린샷). 화면에는 가운데 넷을 가린 `010-****-{뒤 4자리}`만 보인다.
- 계좌는 `{은행 짧은 이름} ****{뒤 2자리}`만 보인다(3번 계획 Task 7).
- 크리에이터 프로필의 고치기는 바뀐 칸만 보내고 받는다(`PATCH`). 2번의 `PUT /creators/me`(가입 때)는 그대로 둔다.
- 고정 값: 자유 꼬리표 최대 `3`개, 하나에 `12`자, 소개 `100`자(7번), 활동명 `1~20`자(2번).
- 작업 브랜치를 만들지 않고 `main`에 바로 커밋한다. 커밋마다 테스트가 통과한 상태여야 한다.

## Review Focus

1. **역할마다 E4가 다름** → 사장님·브랜드에게 "연결된 계정"과 "정산 계좌와 내역"이 없고, 보관함 줄 이름이 "다시 만나고 싶은 크리에이터"다. (Task 2, 6)
2. **휴대폰 번호 바꾸기** → 인증이 끝나기 전에는 번호가 바뀌지 않고, 가짜 인증은 `010-0000-XXXX`와 `000000` 밖을 받지 않는다. (Task 3)
3. **E6 저장** → 보낸 칸만 바뀌고 나머지는 그대로다. 남의 프로필은 못 고친다. 협업 원칙이 없으면 희망 제작비를 저장하지 않는다(409). (Task 1)
4. **꼬리표** → E6·발견 카드·B5가 같은 순서(자유 → 분야 → 원칙 표시)의 같은 목록을 보인다. 원칙을 바꾸면 세 곳이 함께 바뀐다. 2번의 "주로 만드는 콘텐츠"와 A9 지원자 줄은 그대로다. (Task 1)
5. **약관과 문의** → 운영 빌드에서 `LEGAL_URL`·`OPERATOR_EMAIL`이 비어 있거나 약관 주소가 https가 아니면 앱이 시작을 거부한다(공통 기반의 https 검사와 같은 자리). (Task 4)

---

## 파일 구조

```text
api/src/
├── creators/                           # PATCH /creators/me (꼬리표, 가능한 시작일, 소개, 희망 제작비)
└── settings/                           # GET /me/settings (여러 모듈의 값을 모음)

app/lib/features/
├── settings/                           # E4
├── creator_profile/                    # E6 (2번의 최소 프로필 기능에 고치기 화면을 더함)
├── help/                               # E8, 자주 묻는 질문 목록
└── auth/                               # 휴대폰 번호 바꾸기 (E2 재사용)
```

---

### Task 1: 크리에이터 프로필 고치기 (서버)

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/creators/{creators.controller.ts,creators.service.ts,creators.repository.ts,dto/*.ts}`, 4번의 원칙 꼬리표 함수(규칙 변경: 순서를 분야 → 원칙 표시로, 분야는 "·" 앞만 — 4번 카드와 7번 B5도 함께 바뀐다), 4번 카드·7번 B5의 꼬리표 조립(자유 꼬리표를 앞에 붙임)
- Create: 마이그레이션, `api/src/creators/content-tags.ts`
- Test: `api/src/creators/content-tags.spec.ts`, `api/test/creators.e2e-spec.ts`(추가), 4번 카드·7번 B5 테스트(추가)

**Interfaces:**
- Consumes: 2번 `CreatorProfile`, 7번 `bio`와 그 검사(`PUT /creators/me/bio`), 4번 `FeeBand { W200K, W300K, W400K, W500K_PLUS }`·`PrinciplesService.updateFeeBand`·원칙 꼬리표 규칙(`CreatorCardModel.tags`), `Clock`
- Produces (꼬리표·희망 제작비 — 2026-11-11 소유자 결정, 설계 9장 8번):
  - `CreatorProfile`에 `customTags: String[]`(기본 빈 목록), `availableFrom: DateTime? @db.Date` 추가. 2번의 `contentFocus`는 그대로 둔다(A9 지원자 줄이 쓴다).
  - `normalizeTags(input: string[]): string[]` (순수) — 앞의 `#`과 앞뒤 공백을 떼고, 빈 것과 중복을 빼고, 한글·영문·숫자·`_`만 허용(아니면 400), 하나 12자·최대 3개(넘으면 400).
  - `principleTags(p: Principles): string[]` (순수, 4번의 규칙을 함수로 꺼내 export) — 분야의 첫 표시 이름("·" 앞), `faceOk`가 false면 `얼굴출연없음`, `scriptOk`가 false면 `대본낭독없음`, `honestReview`가 true면 `솔직후기`. 순서는 캔버스 E6대로 분야 → 원칙 표시.
  - `creatorTags(custom: string[], p: Principles | null): string[]` (순수) = 자유 꼬리표 + `principleTags`. 4번 발견 카드의 `tags`와 7번 B5의 꼬리표(7번 `portfolio-rules.ts`의 `profileTags` 자리)가 이것을 쓴다.
  - `PATCH /creators/me` 본문(모두 선택) `{ displayName?: string(1~20); bio?: string | null(7번과 같은 검사); customTags?: string[]; availableFrom?: 'YYYY-MM-DD' | null(오늘(한국 시간) 이후); photoPath?: string; feeBand?: FeeBand }` → 200 `CreatorProfileModel`. `CREATOR` 역할만. `feeBand`는 `PrinciplesService.updateFeeBand`로 저장하고, 협업 원칙이 없으면 409 `협업 원칙을 먼저 정해 주세요.` 사진 경로는 2번의 `UploadsService.assertOwnedPath`로 검사한다. `operationId: patchMyCreatorProfile`
  - `CreatorProfileModel`에 `bio: string | null`, `customTags: string[]`, `principleTags: string[]`, `availableFrom: string | null`, `feeBand: FeeBand | null` 추가.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
// content-tags.spec.ts
it('strips hashes and spaces and drops duplicates', () => { expect(normalizeTags(['#데일리룩', ' 브이로그 ', '데일리룩'])).toEqual(['데일리룩', '브이로그']); });
it('rejects a fourth tag and a tag longer than 12 characters', ...);
it('rejects symbols other than underscore', ...);
it('builds principle tags in canvas order', ...);                 // 분야 액세서리·주얼리, faceOk false → ['액세서리', '얼굴출연없음']
it('puts custom tags before principle tags', ...);                // ['데일리룩', '액세서리', '얼굴출연없음']

// creators.e2e-spec.ts (추가)
it('patches only the fields that were sent', ...);
it('saves custom tags, bio and an available-from date', ...);
it('rejects an available-from date in the past', ...);           // FakeClock 2026-11-11, '2026-11-10' → 400
it('saves the fee band through the principles', ...);
it('refuses the fee band before principles exist', ...);         // 409
it('keeps contentFocus unchanged', ...);
it('requires the CREATOR role', ...);
// 4번 카드·7번 B5 (추가)
it('shows custom tags before principle tags on cards and profiles', ...);
```

- [ ] **Step 2: 실패 확인** — Run: `cd api && yarn test content-tags && yarn test:e2e creators` · Expected: FAIL
- [ ] **Step 3: 스키마, 마이그레이션, 순수 함수, `PATCH`, 카드·B5 꼬리표 구현**
- [ ] **Step 4: 통과 확인** — Run: `cd api && yarn prisma migrate dev && yarn lint && yarn test && yarn test:e2e && yarn test:db` · Expected: PASS
- [ ] **Step 5: gen-api, Commit** — `feat: 크리에이터 프로필 고치기와 꼬리표 추가`

---

### Task 2: 설정 요약 (서버)

**Files:**
- Create: `api/src/settings/{settings.module.ts,settings.controller.ts,settings.service.ts,dto/settings-summary.model.ts}`
- Test: `api/src/settings/settings.service.spec.ts`, `api/test/settings.e2e-spec.ts`

**Interfaces:**
- Consumes (모두 각 모듈이 export한 서비스): `CreatorsService`, `StoresService`, 4번 브랜드 프로필 서비스, `InstagramService.getConnection`, `PayoutAccountsService`, `BANKS`, `NotificationsService`의 설정 조회, `KeepService.countFor`
- Produces:
  - `GET /me/settings` → 200 `SettingsSummaryModel { role: 'STORE' | 'BRAND' | 'CREATOR'; roleLabel: string; card: { name: string; subtitle: string; photoUrl: string | null }; instagramHandle: string | null; notificationsOn: number; payoutAccount: { bankName: string; accountLast4: string } | null; keepCount: number; keepLabel: string }`. `operationId: getSettingsSummary`
  - 역할별 값(설계 2장 E4):
    - 크리에이터: `roleLabel` `크리에이터`, 카드 이름 = 활동명, 부제 `크리에이터 · @{아이디}`(연결 없으면 `크리에이터`), `keepLabel` `다시 만나고 싶은 브랜드`
    - 사장님: `roleLabel` `가게 사장님`, 카드 = 가게 이름·가게 사진, 부제 `가게 사장님`, `instagramHandle`·`payoutAccount`는 null, `keepLabel` `다시 만나고 싶은 크리에이터`
    - 브랜드: `roleLabel` `브랜드`, 카드 = 브랜드 이름·사진, 부제 `브랜드`, 나머지는 사장님과 같다
  - 휴대폰 번호는 이 응답에 넣지 않는다(앱이 로그인 정보에서 읽는다).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('summarizes a creator with instagram, account, four switches on and three kept brands', ...);
it('summarizes a store owner without instagram and account rows', ...);
it('summarizes a brand with the creator keep label', ...);
it('falls back to the role name when instagram is not connected', ...);
it('requires a signed-in user', ...);                               // 401
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 설정 화면 요약 API 추가`

---

### Task 3: 앱 — 휴대폰 번호 바꾸기

**Files:**
- Modify: `app/lib/features/auth/domain/auth_repository.dart`, `app/lib/features/auth/data/{supabase_auth_repository.dart,fake_sign_in_adapter.dart}`(이름은 공통 기반의 실제 파일을 따른다), E2 화면과 ViewModel(바꾸기 모드)
- Test: `app/test/features/auth/`(추가)

**Interfaces:**
- Consumes: 공통 기반의 `AuthRepository`, `SignInAdapter`, 번호 형식 변환 도우미, E2 화면
- Produces:
  - `AuthRepository`에 `String? get currentPhone`(국내 표기 `010-…`), `Future<void> requestPhoneChange(String phone)`, `Future<void> confirmPhoneChange(String phone, String code)` 추가.
  - 실제 구현: Supabase의 사용자 번호 변경(번호를 바꾸는 사용자 갱신 → 새 번호로 온 인증번호를 번호 변경 종류로 확인). 정확한 호출은 실행자가 `supabase_flutter` 2.18 문서로 확인한다.
  - 가짜 구현: `010-0000-XXXX`만 받고 인증번호 `000000`만 통과. 통과하면 가짜 세션의 번호가 바뀐다.
  - E2에 `PhoneVerifyMode { signIn, changePhone }`. `changePhone`이면 로그인 대신 번호 변경을 확인하고, 끝나면 들어온 화면(E4, Task 6)으로 돌아가 `휴대폰 번호를 바꿨어요.`를 3초 보인다(캔버스 밖 — 확인 목록). 화면 문구는 E2 그대로다.
  - `maskPhone(String)` (순수) — `010-0000-0003` → `010-****-0003`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('masks the middle four digits', () { expect(maskPhone('010-0000-0003'), '010-****-0003'); });
test('fake adapter changes the phone only after 000000', ...);
test('fake adapter rejects numbers outside 010-0000-XXXX', ...);
testWidgets('E2 in change mode pops back with the new number', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test`
- [ ] **Step 5: Commit** — `feat: 휴대폰 번호 바꾸기 추가`

---

### Task 4: 앱 — 고객센터(E8), 약관, 문의

**Files:**
- Create: `app/lib/features/help/{domain/faq.dart,presentation/{viewmodels/help_view_model.dart,pages/help_page.dart,help_text.dart,legal_links.dart}}`
- Modify: `app/lib/core/theme/cora_colors.dart`(`iconMuted` `#A0A4AD`가 3번 계획 Task 13C에서 생기지 않았으면 더함), `app/lib/core/config/app_config.dart`(`legalUrl`, `--dart-define=LEGAL_URL`, 운영 빌드에서 비었거나 https가 아니면 시작 거부. 3번의 `operatorEmail`도 운영 빌드에서 비면 시작 거부. 9번 계획 Task 23도 이 값을 쓴다), `app/lib/features/auth/presentation/pages/login_page.dart`(E1 약관 두 링크), `app/lib/core/navigation/app_router.dart`(`/help` — 로그인 전에도 열 수 있게)
- Test: `app/test/features/help/`, `app/test/core/config/`(추가), `app/test/features/auth/`(추가)

**Interfaces:**
- Consumes: `AppConfig.operatorEmail`(3번), `url_launcher`
- Produces:
  - `const faqs: List<Faq>` — 설계 2장 E8의 다섯 개, 글자 그대로.
  - `List<Faq> searchFaqs(String query)` (순수) — 띄어쓰기를 빼고 질문과 답에서 찾는다.
  - `openLegal({String? section})` — `{LEGAL_URL}` 또는 `{LEGAL_URL}#terms`·`#privacy`를 앱 안 브라우저로 연다. E8 `약관 보기`와 E4 `약관과 개인정보`는 섹션 없이 연다.
  - `openInquiry()` — `mailto:{OPERATOR_EMAIL}?subject=[Cora] 문의`(2026-11-11 소유자 결정, 설계 9장 6번 — 캔버스는 대화방으로 이었지만 운영자가 답할 도구가 없어 메일로 한다).
  - E1의 `이용약관` → `openLegal(section: 'terms')`, `개인정보 처리방침` → `openLegal(section: 'privacy')`(공통 기반 코드의 "E8이 생기면" 주석을 지운다 — 설계 10장 확인 목록).

화면 문구(E8, 캔버스 그대로): 머리 `고객센터`, 제목 `무엇을 도와드릴까요?`, 검색 예시 `정산, 계약, 신고…`(숨은 이름표 `질문 검색`), 질문 다섯, 처음에 첫 질문만 열림, 버튼 `약관 보기`, `1:1 문의하기`(다크에서도 `accent`). 검색 결과 없음 `찾는 질문이 없어요.`(캔버스 밖 — 확인 목록).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('finds a question ignoring spaces', ...);                    // '회원탈퇴' → 다섯째
testWidgets('opens the first question by default and only one at a time', ...);
testWidgets('shows the empty search message', ...);
testWidgets('opens the legal page and the inquiry mail', ...);    // 가짜 런처에 넘어간 주소 확인
testWidgets('opens the terms and privacy sections from E1', ...);
test('refuses to start a production build without LEGAL_URL', ...);
test('refuses to start a production build without OPERATOR_EMAIL', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 시뮬레이터에서 라이트·다크 E8을 캔버스와 나란히 확인**
- [ ] **Step 6: Commit** — 커밋 두 개: `feat: 고객센터와 자주 묻는 질문 추가`, `feat: 약관 문서 링크와 1:1 문의 연결`

---

### Task 5: 앱 — 프로필 수정(E6)

**Files:**
- Create: `app/lib/features/creator_profile/presentation/{viewmodels/edit_profile_view_model.dart,pages/edit_profile_page.dart,widgets/tag_input_sheet.dart,edit_profile_text.dart}`
- Modify: `app/lib/features/creator_profile/domain/{creator_profile.dart,creator_profile_repository.dart}`, `data/api_creator_profile_repository.dart`, `app/lib/core/theme/cora_colors.dart`(사진 자리 `#D9DCE6`이 7번에서 생기지 않았으면 더함, 사진 바꾸기 버튼 바탕·아이콘), `app/lib/core/theme/cora_shadows.dart`(사진 바꾸기 버튼 그림자 라이트·다크), `app/lib/core/navigation/app_router.dart`(`/creator/profile/edit`)
- Test: `app/test/features/creator_profile/`(추가)

**Interfaces:**
- Consumes: `patchMyCreatorProfile` (Task 1), `getMyCreatorProfile`, 2번 `PhotoUploader`, 4번 협업 원칙 09 라우트
- Produces:
  - `CreatorProfile`에 `bio`, `customTags`, `principleTags`, `availableFrom`, `feeBand` 추가. `CreatorProfileRepository.patch({...})`.
  - `edit_profile_text.dart`(순수): `feeBandLabel(band)`(`W300K` → `30만 원부터`, `W500K_PLUS` → `50만 원부터`), `availableFromLabel(DateTime? date, DateTime today)`(`11월 16일 이후`, 비었거나 지났으면 `언제든`), `tagLabel(tag)`(`#데일리룩`)
  - 희망 제작비를 누르면 네 가지 고르기 시트, 원칙이 없으면 09로. 가능한 시작일을 누르면 날짜 고르기(오늘 이후, 지우기 가능). 자유 꼬리표를 누르면 `꼬리표를 지울까요?`, 원칙 꼬리표를 누르면 09 협업 원칙, `+ 추가`를 누르면 입력 시트(자유 꼬리표가 3개면 `+ 추가`를 숨긴다). 모두 캔버스 밖 — 확인 목록.
  - `저장하기`는 바뀐 칸만 보낸다. 성공하면 E4로 돌아간다. 실패하면 남고 3초 안내.

화면 문구(E6, 캔버스 그대로): 머리 `프로필 수정`, 사진 읽을 이름 `현재 프로필 사진`, 버튼 읽을 이름 `사진 바꾸기`, 칸 `활동명`, `소개`, `잘 만드는 콘텐츠`(끝 `+ 추가`), `희망 제작비`, `가능한 시작일`, 버튼 `저장하기`(다크에서도 `accent`).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('labels fee bands as from-amounts', ...);                   // 30만 원부터
test('labels the available date and falls back to anytime', ...); // 11월 16일 이후, 언제든
testWidgets('fills the canvas values from a fake repository', ...);
testWidgets('sends only the changed fields on save', ...);
testWidgets('adds and removes a tag', ...);
testWidgets('opens principles when the fee is tapped without principles', ...);
testWidgets('keeps the save button lime in dark', ...);
testWidgets('draws the camera button white in light and #2A2D33 in dark', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 시뮬레이터에서 라이트·다크 E6을 캔버스와 나란히 확인**
- [ ] **Step 6: Commit** — `feat: 크리에이터 프로필 수정 화면 추가`

---

### Task 6: 앱 — 설정(E4)과 입구

**Files:**
- Create: `app/lib/features/settings/{domain/{settings_summary.dart,settings_repository.dart},data/api_settings_repository.dart,presentation/{viewmodels/settings_view_model.dart,pages/settings_page.dart,settings_text.dart}}`
- Modify: `app/lib/core/navigation/app_router.dart`(`/settings`), 2번 `/store/me`의 `설정(준비 중)` → `/settings`, 6번 `ProfileMenuPage`(브랜드)에 `설정` 줄, 7번 B2 톱니의 준비 중 연결 → `/settings`
- Test: `app/test/features/settings/`

**Interfaces:**
- Consumes: `getSettingsSummary` (Task 2), `AuthRepository.currentPhone`·`signOut`, `maskPhone` (Task 3), 공통 기반 `/role`, 3번 `/creator/instagram`·`/settings/notifications`·`/creator/wallet`, 6번 `/keep`, Task 4의 `/help`·`openLegal`, Task 5의 `/creator/profile/edit`
- Produces:
  - `SettingsPage` — 설계 2장 E4 그대로. 줄의 목록은 `settings_text.dart`의 순수 함수 `rowsFor(SettingsSummary, {required String? phone})`가 역할별로 만든다.
  - 줄과 가는 곳: `역할 전환` → `/role`, `연결된 계정` → `/creator/instagram`, `휴대폰 번호` → E2(`changePhone`), `알림` → `/settings/notifications`, `정산 계좌와 내역` → `/creator/wallet`, 보관함 줄 → `/keep`, `고객센터` → `/help`, `약관과 개인정보` → `openLegal()`, `로그아웃` → 바로 로그아웃 후 E1, `회원 탈퇴` → `/help`(9번 계획이 탈퇴 흐름으로 바꾼다).
  - 프로필 카드: 크리에이터 → `/creator/profile/edit`(Task 5), 사장님 → A3 `/store/page`, 브랜드 → 4번의 브랜드 프로필 고치기.

화면 문구(E4, 캔버스 그대로):
- 머리 `설정`. 카드 오른쪽 `프로필 수정`.
- 묶음 `계정`: `역할 전환` / `{역할 이름}`, `연결된 계정` / `인스타그램`(연결 없으면 `연결하기`), `휴대폰 번호` / `010-****-{뒤 4자리}`(없으면 `등록하기`).
- 묶음 `협업`: `알림` / `{n}개 켜짐`, `정산 계좌와 내역` / `{은행} ****{뒤 2자리}`(없으면 `등록하기`), `다시 만나고 싶은 브랜드` / `{수}`.
- 묶음 `도움`: `고객센터`, `약관과 개인정보`.
- 아래 `로그아웃` | `회원 탈퇴`.
- 사장님·브랜드: `연결된 계정`, `정산 계좌와 내역` 줄 없음, 보관함 줄 `다시 만나고 싶은 크리에이터`(캔버스 밖 — 확인 목록).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('builds the creator rows in canvas order', ...);
test('drops instagram and payout rows for store owners and brands', ...);
testWidgets('shows the creator card and canvas values from a fake repository', ...);  // '4개 켜짐', '국민 ****12', '3'
testWidgets('masks the phone number', ...);                                           // 010-****-0003
testWidgets('uses 48 high rows in light and 52 in dark', ...);
testWidgets('opens each row destination', ...);
testWidgets('signs out from the bottom link without a confirmation', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 시뮬레이터에서 크리에이터·사장님·브랜드 계정으로 라이트·다크 E4 확인**
- [ ] **Step 6: Commit** — `feat: 설정 화면과 역할별 입구 추가`

---

### Task 7: 전체 흐름 확인

**Files:** 없음

- [ ] **Step 1: 자동 확인**

Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
Run: `cd app && flutter analyze && flutter test`
Run: `./scripts/gen-api.sh && git status --short` — Expected: 변경 없음

- [ ] **Step 2: 세 계정으로 수동 확인** (`cd api && yarn seed:dev` → `010-0000-0001` 가게, `010-0000-0002` 브랜드, `010-0000-0003` 크리에이터, 인증번호 `000000`)

1. 크리에이터: B2 톱니 → E4. 카드, 줄 값(`010-****-0003`, `{n}개 켜짐`, 계좌, 보관함 수)이 맞다.
2. 크리에이터: `프로필 수정` → 소개·자유 꼬리표 추가와 지우기·희망 제작비·가능한 시작일을 바꾸고 저장 → E4로 돌아오고 B5(사장님 계정으로 본 프로필)와 브랜드의 발견 카드에 같은 꼬리표(자유 → 분야 → 원칙 표시)와 소개가 보인다.
3. 크리에이터: `휴대폰 번호` → `010-0000-0013`으로 바꾸기 → `000000` → E4에 `010-****-0013`. 다시 `010-0000-0003`으로 되돌린다.
4. 크리에이터: `알림` → E5, `정산 계좌와 내역` → E7, `연결된 계정` → 인스타그램 연결 화면, `다시 만나고 싶은 브랜드` → D5, `역할 전환` → A1.
5. 사장님: 내 가게 → `설정` → E4에 연결된 계정·정산 줄이 없고 보관함 줄이 `다시 만나고 싶은 크리에이터`. 카드 → A3.
6. 브랜드: 프로필 탭 → `설정` → E4. 카드 → 브랜드 프로필 고치기.
7. `고객센터`: 검색 `탈퇴` → 다섯째 질문만. `약관 보기` → 약관 문서. `1:1 문의하기` → 메일 작성 화면.
8. 로그아웃 → E1. E1의 `이용약관`·`개인정보 처리방침` → 약관 문서의 해당 부분.
9. E4·E6·E8을 라이트·다크로 캔버스와 나란히 본다(E4 다크 줄 높이 52 포함).

- [ ] **Step 3: 캔버스 밖 상태 목록**을 진행 기록에 모아 소유자에게 한 번에 묻는다(설계 10장).

---

## 완료 기준

- Task 7의 자동 확인과 수동 확인 9개 통과
- 운영 빌드에서 `LEGAL_URL`이나 `OPERATOR_EMAIL`이 비어 있으면 앱이 시작을 거부함

## 이 계획이 하지 않는 것

- 알림함·알림 설정·정산 화면(3번 계획 Task 13A~13D)
- 회원 탈퇴 흐름, 약관 동의 화면, 약관 문서의 내용 (9번 계획). `회원 탈퇴` 줄은 그때까지 E8을 연다
- 활동 지역 고치기 (캔버스에 칸이 없다 — 설계 10장 확인 목록)
- 사장님·브랜드의 결제·환급 내역 화면 (캔버스에 없다)
