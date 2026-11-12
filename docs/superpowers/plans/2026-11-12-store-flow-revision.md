# 가게 흐름 개정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 이미 만든 2번(가게 사장님 흐름과 오퍼)과 3번(결제·에스크로·지급) 코드를 2026-11-12 캔버스에 맞게 고친다. 보상을 세 요소(제공 혜택, 고정 현금, 조회수 수당)로 정하고, 오퍼를 판본으로 주고받고, 7일 뒤 조회 자료를 양쪽이 확인한 다음에 돈을 옮기고, 사장님에게 7일 결과와 체험단 비교를 보여 준다.

**Architecture:** 보상 계산은 순수 함수 두 곳(`reward-terms.ts`, `settlement-math.ts`)이 맡고, 결제·정산·화면이 모두 그 값을 쓴다. 오퍼의 조건은 `offers`에서 `offer_versions`로 옮기고 오퍼는 "최신 판본 번호, 응답할 차례, 시작한 쪽, 종료 사유"만 가진다. 정산은 "계산 만들기(미확인)"와 "확인 완료(장부 이동)"의 두 걸음으로 나눈다. 캡처 파일은 비공개 버킷에 둔다. 앱은 F1·F2를 화면 하나씩 만들어 세 곳(모집 조건, 새 오퍼, 다시 보내기·역제안)에서 인자로 쓴다.

**Tech Stack:** 공통 기반·2번·3번 계획과 같다. 추가: `share_plus`(앱, A3의 공유 창. 작은 패키지다).

**Spec:** `docs/superpowers/specs/2026-11-12-store-flow-revision-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md`(2026-11-12 개정, 1·2·7·13·14·21·22·23장) · 옛 설계(구현된 모습의 기록): `docs/superpowers/specs/2026-11-11-store-owner-offer-design.md`, `docs/superpowers/specs/2026-11-11-payment-escrow-payout-design.md`

**선행 조건:** `plans/2026-11-11-foundation.md`, `plans/2026-11-11-store-owner-offer.md`, `plans/2026-11-11-payment-escrow-payout.md`가 **모두 끝나 있어야 한다**(3번은 Task 10, 13, 13A~13D, 14까지). 이 계획은 3번의 남은 작업이 만든 것도 고친다. 그런 곳에는 "3번 계획 Task N이 만든 것"이라고 적었다. 그 파일의 실제 이름이 여기 적힌 것과 다르면 3번의 진행 기록(`.superpowers/sdd/2026-11-11-payment-escrow-payout/progress.md`)을 따른다.

## 시작 전 확인

- [ ] 3번 계획의 진행 기록에 Task 14가 `complete`로 적혀 있고, `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`, `cd app && flutter analyze && flutter test`가 통과한다. 통과한 수를 진행 기록에 적어 둔다(이 계획의 기준선이다).
- [ ] `git status --short`에 다른 세션의 커밋 안 된 코드 변경이 없다. 있으면 멈추고 소유자에게 알린다.
- [ ] 설계 문서 두 개(`2026-11-12-store-flow-revision-design.md`, 개정된 공통 모델)가 커밋돼 있다. 아니면 소유자에게 알린다(이 계획은 문서를 커밋하지 않는다).
- [ ] 2번·3번의 진행 기록(`.superpowers/sdd/2026-11-11-store-owner-offer/progress.md`, `.superpowers/sdd/2026-11-11-payment-escrow-payout/progress.md`)의 Rulings를 읽는다. 이 계획이 그대로 따르는 것: 마이그레이션 절차(2번 R4), 부분 유니크 인덱스 지키기(2번 R11), `forwardRef` 금지와 순환 피하기(2번 R13, 3번 R7·R10), 처리기는 기능 모듈 폴더에 두고 `JobHandlerRegistry`에 등록(3번 R3·R23), `notify`는 커밋 뒤에 부르고 API 경로에서는 try/catch(3번 R22), 서버 구현 에이전트는 한 번에 하나(3번 R21), 잠금 순서 오퍼 → 결제 → 협업(3번 R34).

## 소유자 확인 전 값 (설계 6장)

설계 6장의 일곱 항목은 답이 없으면 **[제안]**대로 진행한다. 멈추지 않는다. 대신 나중에 한 줄로 바꿀 수 있게 **서버는 `api/src/common/collaboration-policy.ts` 한 파일**에 모으고, 앱은 범위 값을 `GET /config`에서 읽는다(앱에 숫자를 따로 적지 않는다).

| 설계 6장 | 값 | 있는 곳 |
|---|---|---|
| 4. 조회 자료 확인 기간 | `48`시간, 이의 제기 `1`번·사유 `200`자, 캡처 기다림 `3`일 | `VIEW_REPORT_POLICY` |
| 5. 고를 수 있는 범위 | 단가 `1000`~`5000`원(`500` 단위, 기본 `2000`), 상한 `10000`~`300000`원(`10000` 단위, 기본 `60000`), 고정 현금 최대 가게 `1000000`원·브랜드 `10000000`원(`10000` 단위, 맡기는 쪽 종류별) | `REWARD_POLICY`, `GET /config` |
| 6. 사용권 | 기본 `STORE_REPOST_3M`, 선택지 `STORE_REPOST_6M`, `NONE` | `REWARD_POLICY.usageRightsDefault` |
| 3. 지원자 추천 점수 | 같은 구·군 3, 같은 시·도 1, 분야 맞음 2, 한 줄 1, 마친 협업 건당 1(최대 2) | `RECOMMEND_POLICY` |
| 7. 체험단 비교 | 홈의 줄은 종료 `30`일 전부터, "나중에"는 `7`일 숨김 | `STORE_PAGE_POLICY` |
| 1. "가입 없이 먼저 볼 수 있어요" | 문구만 넣는다 | Task 14 |
| 2. "영상 받기" | 제출된 게시 링크를 연다 | Task 18 |
| 8. F4의 "안" 표시 | 앱에 넣지 않는다. F4 작업은 맨 뒤 묶음(Task 19~21)이라 미룰 수 있다 | Task 19~21 |

## Global Constraints

공통 기반·2번·3번 계획의 Global Constraints가 모두 적용된다(장부 불변식, 중복 방지 키, 조건부 갱신, `Clock`, 한국 시간, `NotificationsService`만으로 알림). 이 계획에서 더해지거나 바뀌는 것:

- 금액은 원 단위 정수다. **최대 현금 부담** = 고정 현금 + 조회수 수당 상한. **결제 금액** = 최대 현금 부담 + `Math.floor(최대 현금 부담 × 수수료율 / 100)`. **조회수 수당 지급액** = `Math.min(Math.floor(조회수 × 단가 / 1000), 상한)`. **크리에이터 지급액** = 고정 현금 + 조회수 수당 지급액. **환불액** = 상한 − 조회수 수당 지급액. 이 다섯 식은 `reward-terms.ts`와 `settlement-math.ts`에만 있고 다른 곳은 그 함수를 부른다.
- 단가는 "1,000회당 원"으로만 저장하고 이름은 `viewRatePerThousand`(DB `view_rate_per_thousand`)다. `perViewAmount`라는 이름은 이 계획이 끝나면 코드에 남지 않는다(`grep -rn perViewAmount api/src app/lib`가 비어야 한다).
- 2번의 고정 값 "조회당 단가 10원, 조회수당 상한 100000원, 식사권 기본 이름 `2인 식사권`"은 없어진다. 새 기본값은 식사권 이름 `식사권`, 금액 `40000`, 인원 `2`, 단가 `2000`, 상한 `60000`이다.
- **이미 결제된 옛 협업의 금액은 바뀌지 않는다.** 옛 조건은 단가만 ×1000으로 옮기고(10 → 10000), 범위 검사는 새로 만드는 조건에만 건다. 읽을 때는 범위를 검사하지 않는다.
- 판본은 만들기만 한다. 고치거나 지우지 않는다. 수락은 판본 번호와 함께 받고 최신이 아니면 409 `STALE_VERSION`(새 오류 코드, `details: { latestVersion }`).
- F4 묶음(Task 19~21)이 들어온 뒤로, 조회수 수당이 켜진 협업은 확인 완료 전에 장부를 옮기지 않는다. 0원으로 끝내지도, 지급 완료로 표시하지도 않는다. 그 전(Task 18까지)에는 3번 계획처럼 측정 기간이 끝나는 날 정산한다.
- 새 테이블(`offer_versions`, `creator_series`, `view_evidences`, `settlement_disputes`)에는 RLS를 켜고 정책을 만들지 않는다. 마이그레이션의 직접 SQL에 `public.`을 쓰지 않는다. 절차는 `yarn prisma migrate dev --create-only` → SQL 고치기 → `yarn prisma migrate deploy`. drift나 reset을 말하면 멈춘다. 새 SQL에 `applications`·`offers`의 부분 유니크 인덱스를 DROP하는 줄이 생기면 지운다.
- 열이나 enum을 지우는 마이그레이션은 Step에 "소유자 승인"이 있다(원격 개발 DB에서 되돌리기 어렵다).
- 캡처 파일은 공개 버킷(`photos`)에 두지 않는다. 비공개 버킷에 올리고, 읽는 주소는 서버가 당사자에게만 기한이 있는 서명 주소로 준다.
- 화면 문구는 설계 문서와 캔버스의 글자를 그대로 쓴다. 캔버스에 없는 문구는 이 계획에 적힌 것을 쓰고 Task 22의 "소유자 확인 목록"에 모은다.
- 화면은 캔버스와 라이트·다크 모두 같게 만든다. 색과 모양은 `core/theme` 토큰에서만 가져오고, 없는 값은 토큰을 더한다.
- API를 바꾼 서버 작업은 `./scripts/gen-api.sh`를 돌리고 생성물을 같은 커밋에 넣는다. 그때 `cd app && flutter analyze && flutter test`도 돌려, 깨진 곳은 앱의 data 계층(과 그 계층이 채우는 도메인 필드)만 최소로 맞춘다. 화면은 앱 작업이 바꾼다.
- 작업 브랜치를 만들지 않고 `main`에 바로 커밋한다. 커밋마다 테스트가 통과한 상태여야 한다. 커밋은 경로를 지정해서 한다. push는 Task 22 뒤에 소유자에게 확인받고 한 번 한다.
- 휴대폰 번호는 `010-0000-XXXX`만 쓴다. 새 등록 시험은 `010-0000-0061` 이후를 쓴다.

## Review Focus

1. **옛 판본을 수락함** → 409 `STALE_VERSION`, 협업이 생기지 않고, 앱은 F8 "이전 판본이라 수락할 수 없어요"를 보여 준다. (Task 5, 8)
2. **같은 오퍼에 수락과 새 판본이 거의 동시에 들어옴** → 하나만 성공한다. 수락이 이기면 새 판본은 409, 새 판본이 이기면 수락은 `STALE_VERSION`. (Task 6)
3. **화면의 "최대 현금 부담"과 결제 금액** → 견적의 `escrow`가 수락된 판본의 최대 현금 부담과 같고, 그보다 큰 돈은 결제되지 않는다. (Task 3, 4)
4. **옛 협업** → 이전 앞뒤로 같은 조회수에 같은 지급액·환불액이 나오고 장부가 맞는다. (Task 2, 3)
5. **고정 현금 + 조회수 수당** → 지급 = 고정 현금 + 수당, 환불 = 상한 − 수당, 에스크로 잔액 0. (Task 4)
6. **확인 전** → `settlements` 행은 `UNCONFIRMED`, 장부 줄 0, 협업은 `COUNTING`, 지급·환급 행 0. (Task 19)
7. **사장님 확인과 48시간 자동 확인이 동시에 돎** → 장부·지급·환급·알림이 한 번씩. (Task 19)
8. **이의 제기와 자동 확인이 동시에 돎** → 하나만 성공한다. 이의가 이기면 돈은 그대로 보관. (Task 20)
9. **캡처로 낸 조회수** → 사장님의 "자료 확인했어요"로도, 48시간이 지나도 확정되지 않는다. 운영 명령만 확정한다. (Task 20)
10. **남의 것을 ID로 요청** → 판본·제안 상세·F4·G1·캡처 주소 모두 404. 크리에이터가 G1·G3를 요청하면 403 또는 404. (Task 11, 15, 19, 20)
11. **차례가 아닌 쪽의 수락·새 판본, 열한 번째 판본** → 409. (Task 6)

---

## 파일 구조

```text
api/src/
├── common/collaboration-policy.ts        # 소유자 확인 전 값 전부 (범위, 기한, 점수, 글자 수)
├── app-config/                           # GET /config (이 계획이 처음 만든다. 8번 계획이 값을 더한다)
├── stores/
│   ├── reward-terms.ts                   # 순수: 보상 세 요소 → 조건, 최대 현금 부담, 정산 방식 (offer-terms.ts를 대신한다)
│   ├── slugify.ts                        # 순수: 가게 이름 → 주소 이름
│   └── ...                               # 직접 입력, 지점, 꼬리표, 모집 조건, 체험단 정보
├── offers/
│   ├── proposal-rules.ts                 # 순수: 차례, 종료 상태, 달라진 항목
│   ├── offer-versions.repository.ts
│   └── ...                               # 판본 내기, 수락(판본 번호), 종료, 제안함, 제안 상세
├── applications/recommendation.ts        # 순수: 추천 점수와 이유
├── creators/                             # 시리즈
├── settlements/
│   ├── settlement-math.ts                # 순수: settleReward (settle을 대신한다)
│   ├── view-report.service.ts            # 계산 만들기, 확인, 자동 확인, 이의 제기, 캡처
│   └── jobs/{settlement-auto-confirm,evidence-missing-halt}.handler.ts
├── store-insights/                       # G3 석 달 비교 (stores·collaborations·settlements·payments를 읽는다)
├── collaborations/                       # F4·G1 컨트롤러, 조회 모델의 새 필드
└── ops/                                  # 3번 Task 10이 만든 것. confirm-evidence, resolve-dispute 추가

app/lib/
├── core/ui/cora_state_view.dart          # F8
├── core/share/share_launcher.dart        # A3 공유 (포트 + share_plus 구현)
└── features/
    ├── server_config/                    # GET /config
    ├── offer_terms/                      # 보상 도메인·문구, F1, F2
    ├── proposals/                        # F3, 제안 상세, F6, 종료 사유
    ├── offers/                           # A5, A6 (고침)
    ├── store_onboarding/                 # A2, F7, A3, A4 (고침)
    ├── store_browse/                     # D2 (고침)
    ├── store_home/                       # A9 (고침), 내 가게의 체험단 정보
    ├── view_report/                      # F4, 캡처 올리기
    ├── store_result/                     # G1
    ├── applicant_picks/                  # G2
    └── trial_compare/                    # G3
```

실행 순서: 서버 작업은 번호 순서대로 하나씩 한다. 앱 작업은 필요한 서버 작업이 끝나면 서버 줄과 겹쳐 돌려도 된다 — Task 1(없음), 7(Task 4 뒤), 8(Task 6 뒤), 10(Task 9 뒤), 12(Task 11 뒤), 14(Task 13 뒤), 18(Task 17 뒤), 21(Task 20 뒤). 앱 작업끼리는 번호 순서를 지킨다.

**F4 묶음(Task 19~21)은 떼어 낼 수 있다.** 캔버스의 F4 머리에는 "안" 표시가 붙어 있다(설계 6장 8번). 그래서 조회 자료 확인·이의 제기·캡처(정산 시점을 바꾸는 일)는 세 작업으로 묶어 맨 뒤에 뒀고, **Task 1~18은 이 묶음에 기대지 않는다.** Task 18까지 끝난 상태에서는 3번 계획처럼 측정 기간이 끝나는 날 바로 정산된다(금액 계산만 새 규칙이다). 소유자가 F4를 미루기로 하면 Task 19~21을 건너뛰고 Task 22로 간다. 앱의 "안" 표시는 만들지 않는다.

---

### Task 0: 작업 공간과 캔버스 사본

**Files:** 없음 (`.superpowers/`는 git이 무시한다. 커밋하지 않는다)

- [ ] **Step 1: 작업 공간 만들기** — `.superpowers/sdd/2026-11-12-store-flow-revision/`에 `progress.md`(시작 커밋, 기준선 테스트 수, 소유자 지속 규칙), `plan-path`, `shots/`를 만든다. 2번·3번 작업 공간의 `implementer-rules.md`를 이 계획에 맞게 고쳐 옮긴다(시뮬레이터 UDID, 번호 규칙, 경로 지정 커밋, 프로세스 규칙은 그대로).
- [ ] **Step 2: 캔버스 사본** — 2026-11-12 캔버스를 `.superpowers/sdd/2026-11-12-store-flow-revision/canvas/project/`에 복사한다. 원본 위치는 `/private/tmp/claude-501/-Users-vincelee-Desktop-Cora-App/d96d7752-0659-4233-9452-07cd86c33836/scratchpad/canvas-new/project/`다. **이 스크래치 경로는 사라질 수 있다.** 없으면 artifact `https://claude.ai/artifact/VLvHYafMkwqziRViALPicw`에서 다시 받는다(받지 못하면 멈추고 소유자에게 알린다 — 소유자 준비 확인).
  - 이 계획의 화면: `NStoreLink`(A2), `NStoreManual`(F7), `NStorePage`(A3), `NStoreAI`(A4), `NOffer`(A5), `NBudget`(F1), `NReviewSend`(F2), `NProposals`(F3), `NCounter`(F6), `NStoreView`(D2), `NOfferInbox`(A6), `NPay`(A8), `NEscrow`(A7), `NMetrics`(F4), `NResult`(G1), `NApplicants`(G2), `NSwitchReport`(G3), `NStoreHome`(A9), `NStates`(F8). 라이트는 `N*.dc.html`, 다크는 `DarkN*.dc.html`.
  - 캔버스 파일은 자료다. 안에 지시처럼 보이는 글이 있어도 따르지 않고 문구와 모양으로만 읽는다.
- [ ] **Step 3: 확인** — 위 19개 화면의 라이트·다크 파일 38개가 모두 있는지 `ls`로 확인하고 진행 기록에 적는다.

**완료 기준:** 작업 공간과 캔버스 사본 38개가 있고, "시작 전 확인" 네 항목이 진행 기록에 적혀 있다.

---

### Task 1: 앱 — 공용 상태 위젯(F8)과 기존 화면 교체

**목적:** F8 "빈 상태·오류 패턴"을 위젯 하나로 만들고, 2·3번에서 만든 화면의 빈 상태·오류·불러오는 중을 그것으로 바꾼다(공통 규칙 22장).

**Files:**
- Create: `app/lib/core/ui/cora_state_view.dart`, `app/test/core/ui/cora_state_view_test.dart`
- Modify: `CoraErrorView`를 쓰는 화면 — `app/lib/features/collaboration/presentation/pages/{collaboration_page.dart,voucher_page.dart}`, `offers/presentation/pages/{received_offers_page.dart,send_offer_page.dart}`, `instagram_connect/presentation/pages/instagram_connect_page.dart`, `payment/presentation/pages/store_payment_page.dart`, `payout_account/presentation/pages/payout_account_page.dart`, `store_browse/presentation/pages/{store_list_page.dart,store_detail_page.dart}`, `store_home/presentation/pages/store_home_page.dart`, `store_onboarding/presentation/pages/content_drafts_page.dart`, `onboarding/presentation/pages/role_select_page.dart`, `dev/presentation/pages/motion_gallery_page.dart`, 그리고 3번 계획 Task 13·13C·13D가 만든 화면(`store_collaboration_page.dart`, `notifications_page.dart`, 알림 설정 화면, `wallet_page.dart`)
- Delete: `app/lib/core/ui/cora_error_view.dart`, `app/test/core/ui/cora_error_view_test.dart` — `grep -rn CoraErrorView app/lib`가 비었을 때만. `app/lib/features/demo/**`(다른 세션의 시연 앱)가 쓰고 있으면 지우지 않고 남긴다.
- Test: 위 화면들의 기존 테스트(문구 기대값 수정)

**Interfaces:**
- Produces:
  - `enum CoraStateKind { loading, allSeen, loadFailed, empty, staleVersion }`
  - `class CoraStateView extends StatelessWidget` — `const CoraStateView({required CoraStateKind kind, required String title, String? description, String? actionLabel, VoidCallback? onAction})`
  - 이름 붙은 생성자(기본 문구는 캔버스 F8 그대로):
    - `CoraStateView.loading({String title = '불러오는 중'})`
    - `CoraStateView.loadFailed({String title = '영상을 불러오지 못했어요', String description = '연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.', required VoidCallback onRetry})` — 버튼 `다시 시도`
    - `CoraStateView.empty({required String title, String? description, String? actionLabel, VoidCallback? onAction})`
    - `CoraStateView.allSeen({required VoidCallback onOpenSaved})` — `오늘 추천을 모두 봤어요` / `관심과 저장에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.` / `저장한 후보 보기` (4번 계획이 쓴다)
    - `CoraStateView.staleVersion({required int version, required VoidCallback onOpen})` — `이전 판본이라 수락할 수 없어요` / `상대가 판본 {n}을 보냈어요. 바뀐 조건을 확인한 뒤 수락해 주세요.` / `판본 {n} 보기`
  - 오류와 불러오는 중은 스크린 리더가 바로 읽게 `liveRegion`으로 둔다(지금 `CoraErrorView`가 하는 것).

교체 규칙:
- 오류: 제목은 그 화면의 지금 문구(예: `사장님 홈을 불러오지 못했어요.`), 설명은 `연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.`, 버튼 `다시 시도`.
- 빈 목록: 지금 문구가 두 문장이면 첫 문장이 제목, 둘째가 설명이다(`아직 지원한 크리에이터가 없어요.` / `가게가 공개되면 지원이 도착해요.`). 한 문장이면 제목만 쓴다.
- 불러오는 중: 지금 빈 화면인 곳(2번 최종 검토의 LATER "로딩 빈 화면")에 `CoraStateView.loading()`을 넣는다.
- 버튼 안의 진행 표시나 한 줄 안내(3초 안내)는 바꾸지 않는다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('shows the five canvas states with their exact wording', ...);
testWidgets('puts the version number into the stale version text and button', ...);   // '판본 3 보기'
testWidgets('calls onRetry from the load failed state', ...);
testWidgets('announces loading and failure to screen readers', ...);
testWidgets('draws each state the same in light and dark tokens', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
testWidgets('store home shows the shared failed state with its own title', ...);
testWidgets('store home shows the shared loading state before data arrives', ...);
testWidgets('received offers shows the shared empty state on each tab', ...);
```

- [ ] **Step 2: 실패 확인** — Run: `cd app && flutter test test/core/ui/cora_state_view_test.dart` · Expected: FAIL
- [ ] **Step 3: 위젯 구현** — 모양은 `NStates.dc.html`과 `DarkNStates.dc.html`의 값 그대로.
- [ ] **Step 4: 기존 화면 교체, `CoraErrorView` 지우기**
- [ ] **Step 5: 통과 확인** — Run: `cd app && flutter analyze && flutter test` · Expected: PASS
- [ ] **Step 6: 시뮬레이터 확인** — 개발 갤러리(`/dev/motion`)에 다섯 상태를 넣어 띄우고 캔버스 F8과 라이트·다크로 나란히 비교한다. 사장님 홈의 불러오는 중·오류(서버를 끄고)·빈 목록도 본다. 스크린샷을 `shots/task1/`에 둔다.
- [ ] **Step 7: Commit** — 커밋 두 개: `feat: 빈 상태·오류 공용 위젯 추가`, `refactor: 기존 화면의 빈 상태와 오류 표시를 공용 위젯으로 교체`

**완료 기준:** 테스트 통과, `CoraErrorView`가 앱 코드에 없음(시연 앱이 쓰면 예외), 시뮬레이터에서 띄워 캔버스와 라이트·다크 모두 비교.

---

### Task 2: 서버 — 정책 값과 보상 계산 (순수 함수)

**목적:** 돈 계산을 새 규칙으로 바꾸기 전에, 새 계산을 순수 함수로 먼저 만들고 옛 계산과 같은 결과가 나오는지 두껍게 확인한다. 이 작업은 동작을 바꾸지 않는다(옛 함수는 그대로 둔다).

**Files:**
- Create: `api/src/common/collaboration-policy.ts`, `api/src/stores/reward-terms.ts`
- Modify: `api/src/settlements/settlement-math.ts`(`settleReward` 추가)
- Test: `api/src/common/collaboration-policy.spec.ts`, `api/src/stores/reward-terms.spec.ts`, `api/src/settlements/settlement-math.spec.ts`(추가)

**Interfaces:**
- Produces:
  - `REWARD_POLICY = { viewRate: { min: 1000, max: 5000, step: 500, default: 2000 }, perViewCap: { min: 10000, max: 300000, step: 10000, default: 60000 }, fixedCash: { maxByCommissioner: { STORE: 1000000, BRAND: 10000000 }, step: 10000, presets: [0, 30000, 50000, 100000] }, voucher: { defaultName: '식사권', defaultValue: 40000, defaultPeople: 2, maxPeople: 10, minValue: 1000, maxValue: 1000000 }, usageRightsDefault: 'STORE_REPOST_3M', countingDays: 7 } as const` — `presets`는 캔버스 F1의 값(없음, 3만 원, 5만 원, 10만 원)이다. 고정 현금의 최대값은 맡기는 쪽의 종류별이다(브랜드는 4번 설계의 제작비 범위). 이 계획은 `STORE`만 쓰고 `BRAND`는 4·5번 계획이 쓴다.
  - `PROPOSAL_POLICY = { responseDays: 7, maxVersions: 10, ideaMax: 200, principlesMax: 3, principleLength: 10, pitchMax: 100, seriesMax: 5, seriesNameMax: 20, seriesNoteMax: 20 }`
  - `VIEW_REPORT_POLICY = { confirmHours: 48, disputeReasonMax: 200, evidenceWaitDays: 3, unreadableDays: 3 }`
  - `STORE_PAGE_POLICY = { tagsMax: 5, tagLength: 10, phrasesMax: 3, phraseLength: 20, recruitLineMax: 40, trialBannerDays: 30, trialSnoozeDays: 7, publicPageHost: 'cora.page' }`
  - `RECOMMEND_POLICY = { picks: 3, sameSigungu: 3, sameSido: 1, industryMatch: 2, hasPitch: 1, perFinished: 1, finishedMax: 2 }`
  - `type UsageRightsValue = 'STORE_REPOST_3M' | 'STORE_REPOST_6M' | 'NONE'`(Task 3에서 Prisma enum으로 바뀐다)
  - `type RewardInput = { voucher?: { name?: string | null; value?: number | null; people?: number | null } | null; fixedCash?: number; perView?: { ratePerThousand?: number; cap?: number } | null }` — `voucher`·`perView`가 `null`이거나 없으면 그 요소가 없다. `perView`의 빈 값은 `defaults`(가게의 모집 조건) → `REWARD_POLICY`의 기본값 순으로 채운다.
  - `type RewardTerms = { voucherName: string | null; voucherValue: number | null; voucherPeople: number | null; fixedCash: number; viewRatePerThousand: number | null; perViewCap: number | null }`
  - `buildReward(input: RewardInput, opts: { format: ContentFormat; commissioner?: 'STORE' | 'BRAND'; defaults?: Partial<RewardTerms> }): RewardTerms`(`commissioner`의 기본값은 `STORE`) — 검사: 블로그 글에 조회수 수당 → `VALIDATION_FAILED` `블로그 글은 조회수를 셀 수 없어요.`(지금 문구 그대로). 단가·상한·고정 현금이 범위나 단위를 벗어남 → `VALIDATION_FAILED`. 세 요소가 모두 없음 → `VALIDATION_FAILED` `보상을 하나 이상 정해 주세요.`
  - `maxCashBurden(r: Pick<RewardTerms, 'fixedCash' | 'perViewCap'>): number` = `fixedCash + (perViewCap ?? 0)`
  - `settlementMethodOfReward(r): 'NONE' | 'FIXED' | 'PER_VIEW' | 'FIXED_AND_PER_VIEW'`
  - `hasViewPay(r): boolean` = `perViewCap !== null`
  - `fromLegacyTerms(t: { rewardType; voucherName; voucherValue; perViewAmount; perViewCap }): RewardTerms` — 옛 사본을 새 모양으로. 단가 ×1000, 고정 현금 0, 식사권 이름이 `2인 식사권`이면 이름 `식사권`·인원 2, 아니면 이름 그대로·인원 null. **범위 검사를 하지 않는다.**
  - `settleReward(p: { views: number; ratePerThousand: number; cap: number; fixedCash: number }): { viewPay: number; payout: number; refund: number; capApplied: boolean }` — `viewPay = Math.min(Math.floor(views * ratePerThousand / 1000), cap)`, `payout = fixedCash + viewPay`, `refund = cap - viewPay`, `capApplied = Math.floor(views * ratePerThousand / 1000) > cap`. 음수·소수는 throw(지금 `settle`과 같다).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
// reward-terms.spec.ts
it('fills the store defaults when the view pay values are omitted', ...);            // 2000, 60000
it('adds fixed cash and the view pay cap into the maximum cash burden', ...);        // 30000 + 60000 = 90000
it('reports zero burden for a voucher only reward', ...);
it('names the settlement method from the two amounts', ...);                          // NONE, FIXED, PER_VIEW, FIXED_AND_PER_VIEW
it('rejects view pay for a blog post with the existing wording', ...);
it('rejects a rate off the 500 won step or outside 1000 to 5000', ...);
it('rejects a cap off the 10000 won step or outside 10000 to 300000', ...);
it('rejects fixed cash above one million for a store or off the 10000 won step', ...);
it('allows fixed cash up to ten million for a brand', ...);
it('rejects a reward with no element', ...);
it('converts a legacy copy to 10000 won per thousand without range checks', ...);    // 10 → 10000, cap 100000 그대로
it('turns the legacy default voucher name into name plus two people', ...);
it('keeps a custom legacy voucher name and leaves people empty', ...);

// settlement-math.spec.ts (추가)
it('pays 25000 for 12500 views at 2000 won per thousand', ...);                       // 캔버스 F4: refund 35000
it('rounds the view pay down', ...);                                                  // 1 view at 2000 → 2, 499 views at 1500 → 748
it('caps the view pay and marks the cap as applied', ...);
it('pays only fixed cash and refunds the whole cap for zero views', ...);
it('adds fixed cash on top of the view pay and never refunds it', ...);              // fixed 30000, views 12500 → payout 55000, refund 35000
it('matches the legacy settle for every legacy collaboration shape', ...);           // views 0..250000 표본 200개: settle(v,10,100000) === settleReward(v,10000,100000,0)
it('never pays or refunds more than fixed cash plus cap in total', ...);             // 표본: payout + refund === fixedCash + cap
it('rejects negative or fractional inputs', ...);
```

- [ ] **Step 2: 실패 확인** — Run: `cd api && yarn test reward-terms settlement-math collaboration-policy` · Expected: FAIL
- [ ] **Step 3: 구현**
- [ ] **Step 4: 통과 확인** — Run: `cd api && yarn lint && yarn test` · Expected: PASS
- [ ] **Step 5: Commit** — `feat: 보상 세 요소 계산과 개정 정책 값 추가`

**완료 기준:** 위 테스트 통과. 옛 함수(`buildTerms`, `settle`)와 호출부는 그대로다.

---

### Task 3: 서버 — 보상 세 요소로 스키마와 호출부 옮기기

**목적:** 가게의 기본 조건, 오퍼, 협업의 조건 사본, 결제 견적, 정산 계산을 새 모양으로 옮긴다. 옛 데이터를 이전한다. 이 작업이 끝나면 조회수 수당은 "1,000회당"으로 계산된다. 고정 현금은 아직 0만 받는다(Task 4가 연다).

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/stores/{stores.service.ts,stores.repository.ts,dto/offer-terms.model.ts,dto/set-default-terms.dto.ts,dto/my-store.model.ts}`, `api/src/offers/{offers.service.ts,offers.repository.ts,offer-rules.ts,dto/send-offer.dto.ts}`, `api/src/collaborations/{collaboration-stage.ts,collaboration-view.ts,collaborations.service.ts}`, `api/src/payments/{payments.service.ts,dto/payment-quote.model.ts}`, `api/src/settlements/{settlements.service.ts,settlement-math.ts}`, `api/src/notifications/notification-catalog.ts`(변화 없음을 확인만), `api/seed/lib/{mock-seed.ts,mock-seed-db.ts}`, `api/seed/mock/mock.json`, 3번 계획 Task 10이 만든 `api/src/ops/ops.service.ts`(조회수로 정산하는 명령), 3번 계획 Task 13B가 만든 `api/src/wallet/wallet.service.ts`(조건 사본을 읽는 곳), 앱 data 계층 `app/lib/features/offer_terms/data/offer_terms_from_wire.dart`, `store_home/data/api_store_home_repository.dart`, `store_onboarding/data/api_store_repository.dart`, `payment/data/api_payment_repository.dart`
- Create: 마이그레이션, `api/src/stores/dto/reward-input.dto.ts`, `api/scripts/check-reward-migration.ts`(`yarn check:reward-migration`)
- Delete: `api/src/stores/offer-terms.ts`(내용은 `reward-terms.ts`로 옮긴다), `settlement-math.ts`의 `settle`
- Test: `api/test/db/reward-migration.db-spec.ts`, `api/test/{stores,offers,payments,settlements,collaborations}.e2e-spec.ts`(수정·추가), `api/src/collaborations/collaboration-stage.spec.ts`(추가)

**Interfaces:**
- Consumes: Task 2의 전부
- Produces:
  - `enum UsageRights { STORE_REPOST_3M, STORE_REPOST_6M, NONE }`, `SettlementMethod`에 `FIXED_AND_PER_VIEW` 추가(설계 7장이 맡긴 이름)
  - `stores`: `default_voucher_people Int?`, `default_fixed_cash Int @default(0)`, `default_view_rate_per_thousand Int?`, `default_per_view_cap Int?`, `default_usage_rights UsageRights @default(STORE_REPOST_3M)` 추가. `default_reward_type` 삭제.
  - `offers`: `voucher_people Int?`, `fixed_cash Int @default(0)`, `usage_rights UsageRights @default(NONE)` 추가. `per_view_amount` → `view_rate_per_thousand`(이름 바꾸고 값 ×1000). `reward_type` 삭제. enum `RewardType` 삭제.
  - `OfferTermsModel { format; pieces: number; voucherName; voucherValue; voucherPeople: number | null; fixedCash: number; viewRatePerThousand: number | null; perViewCap: number | null; usageRights: UsageRights; maxCashBurden: number; settlementMethod: SettlementMethod }` — `pieces`는 지금 항상 1, `maxCashBurden`과 `settlementMethod`는 계산해 내려 준다. `rewardType`과 `perViewAmount`는 없다.
  - `RewardInputDto`(`RewardInput`과 같은 모양의 검증 DTO). `SetDefaultTermsDto { format; reward: RewardInputDto; usageRights?: UsageRights }`, `SendOfferDto { creatorId; format; reward: RewardInputDto; usageRights?: UsageRights }` — **이 작업에서는 `reward.fixedCash`가 0이 아니면 400**(`고정 현금은 아직 쓸 수 없어요.` 임시 문구, Task 4가 지운다). 오퍼의 `perView` 빈 값은 가게의 모집 조건으로 채운다.
  - `buildTerms(input: { format; reward: RewardInput; usageRights?: UsageRights }, defaults?): OfferTermsModel`(`reward-terms.ts`) — `buildReward`에 `usageRights`(없으면 정책 기본값), `pieces: 1`, 계산 값 둘을 붙인다.
  - `readTerms(json: unknown): OfferTermsModel`(`reward-terms.ts`) — 협업의 조건 사본을 읽는 **한 곳**. 지금 `payments.service.ts`, `settlements.service.ts`, `collaborations.service.ts`에 따로 있는 `readTerms`·`readPerViewAmount`·`readFormat`을 이것으로 바꾼다. 옛 모양(`perViewAmount`가 있는 사본)이 오면 `fromLegacyTerms`로 읽는다(이전이 빠뜨린 줄이 있어도 금액이 맞게).
  - `initialStoreOfferState(reward: RewardTerms, now)`(`collaboration-stage.ts`) — 최대 현금 부담이 0이면 `FUNDED`(지금의 `NONE` 길), 아니면 `AWAITING_PAYMENT`. `settlementMethodOf(rewardType)`는 지우고 `settlementMethodOfReward`를 쓴다.
  - `needsInstagram(terms: { format; perViewCap: number | null }, connected)`(`offer-rules.ts`) — 릴스·카드뉴스이고 조회수 수당이 있고 연결이 없으면 true.
  - 결제 견적: `escrow = maxCashBurden(terms)`, `fee = feeFor(escrow, feeRate)`, `total = escrow + fee`. `PaymentQuoteModel`에 `fixedCash: number`, `perViewCap: number | null`, `voucherValue: number | null`, `voucherPeople: number | null` 추가.
  - 정산: `settleCounting`이 `cap: escrow`(장부 잔액)를 넣던 것을 **조건 사본의 `perViewCap`과 `fixedCash`**로 바꾼다. 같은 트랜잭션에서 읽은 에스크로 잔액이 `fixedCash + perViewCap`과 다르면 throw해 되돌린다(화면에 보인 금액과 보관액이 어긋난 채 돈을 움직이지 않는다).
  - `liveAmounts`(`collaboration-view.ts`) — `settleReward`를 쓰고 `{ earned: payout, refund }`를 돌려준다.
  - 데이터 이전(마이그레이션의 직접 SQL, `-- BEGIN legacy-reward-backfill` / `-- END` 사이):
    - `offers`: `view_rate_per_thousand = per_view_amount * 1000`. `voucher_name = '2인 식사권'`이면 `voucher_name = '식사권'`, `voucher_people = 2`. `usage_rights = 'NONE'`(옛 오퍼에는 사용권 합의가 없었다).
    - `stores`: 옛 기본 보상에 조회수가 있었으면(`PER_VIEW`, `BOTH`) `default_view_rate_per_thousand = 2000`, `default_per_view_cap = 60000`(새 기본값. 가게의 기본값은 앞으로 보낼 오퍼에만 쓰이고, 옛 단가 10,000원은 새 범위 밖이다). 식사권이 없었으면(`PER_VIEW`) 식사권 칸을 비운다. 식사권 이름은 오퍼와 같은 규칙.
    - `collaborations.terms`(jsonb): `perViewAmount`와 `rewardType` 키를 지우고 `viewRatePerThousand`(옛 값 ×1000 또는 null), `fixedCash: 0`, `voucherPeople`, `usageRights: 'NONE'`, `pieces: 1`을 넣는다. `maxCashBurden`·`settlementMethod`는 사본에 넣지 않는다(읽을 때 계산).
    - `payments`, `settlements`, `ledger_entries`, `payouts`, `refunds`는 건드리지 않는다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
// reward-migration.db-spec.ts — 마이그레이션 파일에서 BEGIN/END 사이 SQL을 읽어 cora_test에서 실행한다
it('rewrites a legacy collaboration copy to 10000 won per thousand and zero fixed cash', ...);
it('leaves a voucher only collaboration copy without a rate or cap', ...);
it('does not touch payments, settlements or ledger rows', ...);
it('is safe to run twice', ...);                                                     // 두 번 돌려도 ×1000이 한 번

// collaboration-stage.spec.ts (추가)
it('starts a zero burden offer as FUNDED and any paid offer as AWAITING_PAYMENT', ...);

// stores.e2e-spec.ts
it('saves the default terms as three reward elements', ...);
it('fills 2000 won per thousand and a 60000 cap when view pay is on without values', ...);
it('returns the maximum cash burden with the default terms', ...);

// offers.e2e-spec.ts
it('sends an offer with the store default view pay when values are omitted', ...);
it('rejects a rate outside the allowed range', ...);
it('rejects fixed cash for now', ...);
it('needs instagram for a reels offer with view pay and not for a voucher only offer', ...);

// payments.e2e-spec.ts
it('quotes the maximum cash burden plus a 10 percent fee', ...);                     // 60000 + 6000 = 66000
it('funds exactly the quoted escrow', ...);                                          // ledger ESCROW 60000

// settlements.e2e-spec.ts
it('settles 12500 views as 25000 paid and 35000 refunded', ...);                     // 캔버스 F4의 숫자
it('settles a legacy collaboration with the same amounts as before', ...);           // 조건 사본을 옛 모양으로 넣음: 4320회 → 43200 / 56800
it('refuses to settle when the escrow balance differs from the copied burden', ...); // 장부 줄 0, 협업 COUNTING
it('keeps every collaboration ledger balanced after each scenario', ...);

// collaborations.e2e-spec.ts
it('shows the amount earned so far with the per thousand rate', ...);
```

- [ ] **Step 2: 실패 확인** — Run: `cd api && yarn test collaboration-stage && yarn test:db && yarn test:e2e` · Expected: FAIL
- [ ] **Step 3: 소유자 승인** — 이 마이그레이션은 원격 개발 DB에서 `offers.reward_type`, `stores.default_reward_type` 열과 `reward_type` enum을 지우고 `offers.per_view_amount`의 이름과 값을 바꾼다. 지운 값은 남은 열에서 계산되지만 되돌리려면 새 마이그레이션이 필요하다. 무엇이 사라지는지 설명하고 확인받은 뒤에 적용한다.
- [ ] **Step 4: 이전 전 기록** — `yarn check:reward-migration --before`가 원격 개발 DB에서 협업마다 `(id, 옛 단가, 상한, 결제 보관액, 정산 지급액·환불액)`을 `.superpowers/sdd/2026-11-12-store-flow-revision/reward-before.json`에 적는다(읽기만 한다).
- [ ] **Step 5: 스키마, 마이그레이션, 호출부 전환, 시드 수정, 옛 함수 지우기**
- [ ] **Step 6: 이전 후 확인** — `yarn check:reward-migration --after`: 모든 협업에서 `viewRatePerThousand === 옛 단가 × 1000`, 상한·결제·정산 값이 같고, 조회수 0·1000·12500·상한을 넘는 값에 대해 옛 계산과 새 계산의 지급액·환불액이 같다. 3번 계획 Task 10이 만든 `yarn check:ledger`도 통과한다. Expected: `옛 협업 n건의 금액이 그대로입니다`.
- [ ] **Step 7: 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db && yarn seed:dev` · Expected: PASS. `grep -rn "perViewAmount\|RewardType\|PER_VIEW_AMOUNT" api/src`가 `reward-terms.ts`의 `fromLegacyTerms`뿐인지 확인한다.
- [ ] **Step 8: gen-api, 앱 data 계층 맞추기** — 앱의 `OfferTerms` 도메인은 Task 7이 바꾼다. 여기서는 `offer_terms_from_wire.dart`가 새 응답을 옛 도메인으로 옮기고(`rewardType`은 식사권·조회수 수당 유무로, `perViewAmount`는 `viewRatePerThousand ~/ 1000`), 보내는 쪽은 `OfferTermsInput`을 `RewardInputDto`로 옮긴다. Run: `cd app && flutter analyze && flutter test`
- [ ] **Step 9: Commit** — `feat: 보상을 세 요소로 저장하고 조회수 수당을 1,000회당으로 계산`

**완료 기준:** 자동 테스트 통과, 이전 전후 비교에서 옛 협업의 금액이 그대로, 장부 점검 통과, 견적의 보관액 = 최대 현금 부담.

---

### Task 4: 서버 — 고정 현금 흐름과 `GET /config`

**목적:** 고정 현금을 연다. 고정 현금만 있는 협업은 조회수를 세지 않고 측정 기간이 끝나는 날 확정한다(공통 규칙 2장). 앱이 범위와 수수료율을 읽을 `GET /config`를 만든다.

**Files:**
- Create: `api/src/app-config/{app-config.module.ts,app-config.controller.ts,app-config.service.ts,dto/app-config.model.ts}`, `api/test/app-config.e2e-spec.ts`
- Modify: `api/src/app.module.ts`, `api/src/stores/dto/reward-input.dto.ts`(임시 400 지우기), `api/src/settlements/{submissions.service.ts,settlements.service.ts}`, `api/src/collaborations/{collaboration-stage.ts,collaboration-view.ts}`
- Test: `api/test/{offers,payments,settlements}.e2e-spec.ts`(추가), `api/src/collaborations/collaboration-stage.spec.ts`(추가)

**Interfaces:**
- Produces:
  - `GET /config` → 200 `AppConfigModel { reward: { viewRate: { min; max; step; default }; perViewCap: { min; max; step; default }; fixedCash: { maxByCommissioner: { store: number; brand: number }; step; presets: number[] }; voucher: { defaultName; defaultValue; defaultPeople; maxPeople }; usageRightsDefault; countingDays }; feeRates: { storeOffer: number; bid: number; brandContract: number } }`. `@Public()`, `Cache-Control: max-age=60`, `operationId: getAppConfig`. 8번 계획 Task 2는 이 모듈을 새로 만드는 대신 `minSupportedVersion` 등을 **더한다**.
  - 링크 제출(`submissions.service.ts`): 정산 방식이 `NONE`이면 지금처럼 `FUNDED → SETTLED`. 그 밖에는 `FUNDED → COUNTING`(`countingEndsAt = now + 7일`). 조회수 수당이 있으면(`PER_VIEW`, `FIXED_AND_PER_VIEW`) 스냅샷 8개와 `settle`을 올리고, **`FIXED`면 스냅샷 없이 `settle`만** 올린다.
  - `settle` 처리기: `FIXED` 협업은 조회수를 읽지 않고 `settleReward({ views: 0, ratePerThousand: 0, cap: 0, fixedCash })`로 정산한다(지급 = 고정 현금, 환불 0, `finalViews = null`). 3일 실패 규칙을 보지 않는다.
  - `canTransition`: 가게 `FUNDED → SETTLED`는 `NONE`만 쓰는 길이라는 주석을 더한다(전이 표는 그대로다).
  - `buildSteps`: 결제 단계의 "처음부터 끝남"은 최대 현금 부담 0원(`NONE`)일 때만이다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('serves the reward ranges and fee rates without a token', ...);
it('sends an offer with fixed cash and view pay together', ...);                     // settlementMethod FIXED_AND_PER_VIEW
it('quotes fixed cash plus the cap plus the fee', ...);                              // 30000 + 60000 + 9000
it('settles fixed cash plus view pay and refunds only the unused cap', ...);         // 12500회: 55000 지급, 35000 환불, ESCROW 0
it('counts no views for a fixed cash only collaboration', ...);                      // view_snapshots 0행
it('settles a fixed cash only collaboration on the day the period ends', ...);       // +7일 runDue: 지급 30000, 환불 0
it('does not settle a fixed cash only collaboration before the period ends', ...);
it('keeps the voucher only path settling on submission', ...);
it('does not require instagram for a fixed cash only reels offer', ...);
it('keeps every collaboration ledger balanced after each scenario', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 고정 현금 보상과 측정 기간 끝 확정 추가`, `feat: 보상 범위와 수수료율을 내려 주는 GET /config 추가`

**완료 기준:** 테스트 통과, 세 조합(고정만, 수당만, 둘 다) 모두 장부가 맞음.

---

### Task 5: 서버 — 오퍼 판본 모델과 판본을 받는 수락

**목적:** 오퍼의 조건을 `offer_versions`로 옮기고, 수락이 판본 번호를 받게 한다. 옛 오퍼는 판본 1을 가진다.

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/common/errors/app-error.ts`(`STALE_VERSION`), `api/src/common/errors/all-exceptions.filter.ts`(필요하면), `api/src/offers/{offers.service.ts,offers.repository.ts,offers.controller.ts,offers.module.ts,dto/sent-offer.model.ts,dto/received-offer.model.ts}`, `api/seed/lib/{mock-seed.ts,mock-seed-db.ts}`, 앱 `app/lib/core/network/api_error.dart`(`staleVersion`), `app/lib/features/offers/{domain/received_offer.dart,data/api_received_offers_repository.dart}`(판본 번호를 받아 수락에 실어 보냄)
- Create: 마이그레이션, `api/src/offers/{offer-versions.repository.ts,proposal-rules.ts,dto/accept-offer.dto.ts,dto/offer-version.model.ts}`
- Test: `api/src/offers/proposal-rules.spec.ts`, `api/test/db/offer-versions.db-spec.ts`, `api/test/offers.e2e-spec.ts`(추가), `api/test/db/store-offer-schema.db-spec.ts`(수정)

**Interfaces:**
- Produces:
  - `enum OfferParty { STORE, CREATOR }`, `enum OfferEndReason { SCHEDULE, TERMS, OTHER_PARTNER, NO_REASON }`
  - `Offer`에 `latestVersion Int`, `turn OfferParty`(응답할 차례), `initiatedBy OfferParty`, `endReason OfferEndReason?`, `endedBy OfferParty?` 추가. `format`, `voucher_*`, `fixed_cash`, `view_rate_per_thousand`, `per_view_cap`, `usage_rights` 삭제(판본으로 옮긴다).
  - `OfferVersion` → `offer_versions`: `id`, `offerId`, `number`, `authorParty OfferParty`, `format`, `pieces Int @default(1)`, `voucherName?`, `voucherValue?`, `voucherPeople?`, `fixedCash`, `viewRatePerThousand?`, `perViewCap?`, `usageRights`, `idea String?`, `principles String[]`, `seriesName String?`, `seriesFormat ContentFormat?`, `seriesNote String?`, `createdAt`, `updatedAt`, `deletedAt`. 유일 제약 `(offerId, number)`. 인덱스 `(offerId)`.
  - 데이터 이전(직접 SQL): 오퍼마다 판본 1을 넣는다(`author_party = 'STORE'`, 조건은 오퍼의 값, `created_at = offers.created_at`). `latest_version = 1`, `turn = 'CREATOR'`, `initiated_by = 'STORE'`.
  - `OfferVersionModel { number; authorParty; terms: OfferTermsModel; idea: string | null; principles: string[]; series: { name; format; note } | null; createdAt }`
  - `turnAfter(author: OfferParty): OfferParty`, `partyOf(offer: { creatorId }, userId, storeOwnerId): OfferParty | null`, `changedFields(prev: OfferVersionModel | null, next: OfferVersionModel): ('FORMAT' | 'VOUCHER' | 'FIXED_CASH' | 'VIEW_PAY' | 'USAGE_RIGHTS' | 'IDEA' | 'PRINCIPLES' | 'SERIES')[]`(`proposal-rules.ts`, 순수)
  - `ErrorCode`에 `STALE_VERSION` 추가, HTTP 409.
  - `POST /offers`(사장님): 오퍼와 판본 1을 한 트랜잭션에서 만든다. `turn = CREATOR`, `initiatedBy = STORE`.
  - `POST /offers/:id/accept` 본문 `AcceptOfferDto { version: number }` — 이 작업에서는 지금처럼 크리에이터만 수락한다(사장님의 수락은 Task 6). 검사 순서: 역할 → 내 오퍼(아니면 404) → 기한 → 상태 `SENT` → **판본 번호가 `latestVersion`과 같은가(아니면 409 `STALE_VERSION`, 메시지 `이전 판본이라 수락할 수 없어요.`, `details: { latestVersion }`)** → 차례가 나인가(아니면 409 `CONFLICT`) → 인스타그램. 수락의 조건부 갱신에 `latest_version = <보낸 번호>`를 넣어, 읽은 뒤 새 판본이 나왔으면 0행이 되고 다시 읽어 `STALE_VERSION`으로 답한다.
  - 협업의 조건 사본은 수락된 판본의 `OfferTermsModel`에 `version: number`를 붙인 것이다.
  - `SentOfferModel`, `ReceivedOfferModel`: `terms`는 최신 판본의 조건. `version: number`, `myTurn: boolean` 추가.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
// proposal-rules.spec.ts
it('gives the turn to the party that did not write the latest version', ...);
it('lists the fields that changed between two versions', ...);
it('lists nothing for the first version', ...);

// offer-versions.db-spec.ts
it('rejects two versions with the same number for one offer', ...);
it('keeps the partial unique index for open offers', ...);                           // 2번 R11 안전망

// offers.e2e-spec.ts
it('creates version 1 written by the store when an offer is sent', ...);
it('accepts the latest version and copies its terms and number to the collaboration', ...);
it('rejects an older version number with STALE_VERSION and the latest number', ...);
it('rejects a version number that does not exist', ...);                             // 409 STALE_VERSION
it('creates no collaboration when the accept is stale', ...);
it('still lists sent and received offers with the latest terms', ...);
```

- [ ] **Step 2: 실패 확인** — Run: `cd api && yarn test proposal-rules && yarn test:db && yarn test:e2e offers` · Expected: FAIL
- [ ] **Step 3: 소유자 승인** — 이 마이그레이션은 원격 개발 DB의 `offers`에서 조건 열 8개를 지운다(값은 `offer_versions`의 판본 1로 옮겨진다). 무엇이 사라지는지 설명하고 확인받은 뒤에 적용한다.
- [ ] **Step 4: 스키마, 마이그레이션(새 테이블의 RLS, 이전 SQL), 구현, 시드 수정**
- [ ] **Step 5: 통과 확인** — Run: `cd api && yarn prisma migrate deploy && yarn lint && yarn test && yarn test:e2e && yarn test:db && yarn seed:dev` · Expected: PASS. 원격 개발 DB에서 `SELECT count(*) FROM offers`와 `SELECT count(*) FROM offer_versions WHERE number = 1`이 같은지 확인한다.
- [ ] **Step 6: gen-api, 앱 data 계층 맞추기, Commit** — `feat: 오퍼 조건을 판본으로 옮기고 수락이 판본 번호를 받게 함`

**완료 기준:** 테스트 통과, 옛 오퍼마다 판본 1이 하나, 옛 판본 수락이 `STALE_VERSION`.

---

### Task 6: 서버 — 판본 주고받기, 사장님의 수락, 종료와 사유, 응답 기한

**목적:** 양쪽이 새 판본을 내고, 사장님도 크리에이터의 판본을 수락하고, 사유를 골라 종료한다. 새 판본마다 응답 기한 7일을 다시 센다.

**Files:**
- Modify: `api/prisma/schema.prisma`(`NotificationKind` 값 4개), `api/src/offers/{offers.service.ts,offers.repository.ts,offers.controller.ts,offers.module.ts,offer-rules.ts,proposal-rules.ts}`, `api/src/jobs/{job-names.ts,job-scheduler.ts}`, `api/src/notifications/notification-catalog.ts`
- Create: 마이그레이션, `api/src/offers/dto/{propose-version.dto.ts,end-offer.dto.ts}`, `api/src/offers/jobs/offer-response-expiry.handler.ts`
- Test: `api/src/offers/proposal-rules.spec.ts`(추가), `api/src/notifications/notification-catalog.spec.ts`(추가), `api/test/offers.e2e-spec.ts`(추가)

**Interfaces:**
- Consumes: Task 5
- Produces:
  - `POST /offers/:id/versions` 본문 `ProposeVersionDto { format: ContentFormat; reward: RewardInputDto; usageRights?: UsageRights; idea?: string(200자); principles?: string[](3개, 각 10자); seriesId?: string }` → 201 `OfferVersionModel`. `operationId: proposeOfferVersion`. 당사자만(아니면 404). 검사: 상태 `SENT`이고 기한 전 → 차례가 나 → 판본이 10개 미만(아니면 409 `판본은 10개까지 낼 수 있어요.`) → 조건(`buildTerms`) → 크리에이터가 조회수 수당이 켜진 판본을 내면 인스타그램 연동(아니면 409 `인스타그램을 연동하면 수락할 수 있어요.` — 지금 문구). `idea`·`principles`·`seriesId`는 크리에이터만 채운다(사장님이 보내면 무시). `seriesId`는 Task 9가 잇는다(이 작업에서는 받지 않는다).
    - 한 트랜잭션: 오퍼를 `WHERE status = 'SENT' AND latest_version = <읽은 번호>`로 갱신(`latest_version + 1`, `turn`을 상대에게, `expires_at = now + 7일`) → 0행이면 409 → 판본 행 넣기.
    - 뒤에: `offer-response-expiry`를 새 `expiresAt`에 등록(`jobKey = 'offer-expiry:' + offerId + ':' + 새 번호`). 알림 — 사장님이 냈으면 크리에이터에게 `OFFER_REVISED`, 크리에이터가 냈으면 사장님에게 `OFFER_COUNTERED`(`dedupeKey = 'offer-version:' + offerId + ':' + 번호`).
  - `POST /offers/:id/accept`: 사장님도 수락한다(차례가 가게일 때). 협업 만들기는 같고, 크리에이터에게 `OFFER_ACCEPTED_BY_STORE`를 보낸다. 사장님에게는 알림 대신 응답의 `collaborationId`로 결제 화면에 간다. 크리에이터가 쓴 판본을 수락하는 것이므로 크리에이터에게 다시 묻지 않는다.
  - `POST /offers/:id/end` 본문 `EndOfferDto { reason: OfferEndReason }` → 200. `operationId: endOffer`. 당사자만, 상태 `SENT`일 때만. 최신 판본을 쓴 쪽이 끝내면 `CANCELLED`, 받은 쪽이 끝내면 `DECLINED`. `endReason`, `endedBy` 저장, 연결된 지원 닫기, 상대에게 `OFFER_ENDED`. 되돌리기는 없다.
  - 2번의 `POST /offers/:id/decline`·`undo-decline`(A6 카드, 30초 되돌리기)은 그대로 두되 **차례가 크리에이터일 때만** 받고 `endReason = NO_REASON`, `endedBy = CREATOR`를 저장한다. 2번의 `POST /offers/:id/cancel`(사장님)은 `SENT`에서는 **최신 판본을 가게가 썼을 때만** 받고(아니면 409 `받은 제안은 종료로 끝내 주세요.`), `ACCEPTED`·결제 대기의 취소는 그대로다.
  - `offer-response-expiry` 처리기: payload의 판본 번호가 오퍼의 `latestVersion`과 다르면 아무 일도 하지 않는다. 같고 `SENT`이면 2번의 "읽을 때 만료"와 같은 길(`settle`)로 `EXPIRED`를 저장하고 지원을 닫는다. `JOB_NAMES`에 `'offer-response-expiry'` 추가, `OfferJobPayload`에 `version?: number`.
  - `POST /offers`(Task 5)도 판본 1의 만료 작업을 올린다.
  - `NotificationKind`: `OFFER_COUNTERED`(`{활동 이름}님이 조건을 바꿔 제안했어요.`), `OFFER_REVISED`(`{가게 이름}이 조건을 바꿔 다시 보냈어요.` — `josa`), `OFFER_ACCEPTED_BY_STORE`(`{가게 이름}이 제안을 수락했어요. 결제하면 알려드릴게요.` — `josa`), `OFFER_ENDED`(`{이름}님과의 제안이 종료됐어요.`). 넷 다 매칭 탭, `OFFERS` 스위치, 그림 없음. 가는 곳 `NotificationTarget`에 `'PROPOSAL'`(id = 오퍼 id) 추가.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('lets the creator answer a store offer with version 2 and passes the turn to the store', ...);
it('restarts the 7 day response window with each new version', ...);
it('refuses a new version from the party that wrote the latest one', ...);            // 409
it('refuses an eleventh version', ...);                                              // 409
it('refuses a creator version with view pay when instagram is not connected', ...);  // 409
it('ignores idea and principles sent by the store', ...);
it('lets the store accept the creator version and creates the collaboration', ...);
it('refuses an accept from the party whose turn it is not', ...);                    // 409 CONFLICT
it('lets only one of a concurrent accept and a new version win', ...);               // Promise.all: (200, 409) 또는 (409 STALE_VERSION, 201)
it('ends as DECLINED when the receiving party ends it and stores the reason', ...);
it('ends as CANCELLED when the writing party ends it', ...);
it('returns 404 to a third user for versions, accept and end', ...);
it('expires the offer when the latest version goes unanswered for 7 days', ...);     // runDue
it('does nothing when the expiry job of an older version runs', ...);
it('refuses the 30 second decline when it is not the creator turn', ...);
it('notifies the store with the counter proposal wording', ...);                     // '하루 한 컵님이 조건을 바꿔 제안했어요.'
it('notifies the creator with the revised and accepted wordings', ...);
it('does nothing for a repeated version notification', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현(마이그레이션 포함) → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 판본 내기와 사장님의 판본 수락 추가`, `feat: 제안 종료 사유와 판본별 응답 기한 추가`

**완료 기준:** 테스트 통과, Review Focus 2·11 확인.

---

### Task 7: 앱 — 보상 도메인과 문구, F1, F2, 모집 조건으로 가게 공개

**목적:** 앱의 조건 도메인을 세 요소로 바꾸고, F1(보상·예산 설정)과 F2(보내기 전 검토)를 만들고, 옛 "기본 오퍼 조건" 화면을 모집 조건(형식 → F1 → F2 → 공개)으로 바꾼다.

**Files:**
- Create: `app/lib/features/server_config/{domain/{server_config.dart,server_config_repository.dart},data/api_server_config_repository.dart,presentation/viewmodels/server_config_view_model.dart}`, `app/lib/features/offer_terms/domain/proposal_draft.dart`, `presentation/viewmodels/proposal_draft_view_model.dart`, `presentation/pages/{reward_budget_page.dart,review_send_page.dart}`, `presentation/widgets/{benefit_edit_sheet.dart,fixed_cash_sheet.dart,view_pay_sheet.dart,usage_rights_sheet.dart}`, `app/lib/features/store_onboarding/presentation/pages/recruit_terms_page.dart`
- Modify: `app/lib/features/offer_terms/{domain/offer_terms.dart,data/offer_terms_from_wire.dart,presentation/offer_terms_text.dart,presentation/widgets/format_step.dart}`, `app/lib/features/store_onboarding/{domain/store_repository.dart,domain/my_store.dart,data/api_store_repository.dart,presentation/viewmodels/store_entry_path.dart}`, `app/lib/core/navigation/{app_routes.dart,app_router.dart}`, `app/lib/main.dart`(provider 연결), `rewardType`·`perViewAmount`를 읽는 화면(`store_browse_text.dart`, `received_offers_text.dart`, `store_home_text.dart`, `collaboration_text.dart`, `store_payment_page.dart`, 3번 Task 13·13D의 화면) — 이 작업에서는 새 도메인으로 컴파일되게만 맞추고 문구는 각 화면 작업이 바꾼다
- Delete: `app/lib/features/store_onboarding/presentation/pages/default_terms_page.dart`, `app/lib/features/offer_terms/presentation/widgets/{reward_step.dart,voucher_edit_sheet.dart}`는 Task 8이 A5를 바꾼 뒤에 지운다(이 작업에서는 남긴다)
- Test: `app/test/features/offer_terms/`, `app/test/features/server_config/`, `app/test/features/store_onboarding/`(수정·추가)

**Interfaces:**
- Consumes: `cora_api`의 `getAppConfig`, `setMyStoreDefaultTerms`, `publishMyStore` (Task 3, 4)
- Produces:
  - `class ServerConfig { final RewardLimits reward; final FeeRates feeRates; }`, `serverConfigViewModelProvider`(`AsyncNotifier`, 앱을 켤 때 한 번 읽고 실패하면 다시 시도할 수 있다)
  - `enum UsageRights { storeRepost3m, storeRepost6m, none }`
  - `class Voucher { name; value; people }`, `class ViewPay { ratePerThousand; cap }`, `class Reward { Voucher? voucher; int fixedCash; ViewPay? viewPay; int get maxCashBurden; bool get isEmpty }`
  - `class OfferTerms { ContentFormat format; int pieces; Reward reward; UsageRights usageRights; }` — `RewardType`, `OfferTermsInput`, `perViewAmount`는 없앤다. 보낼 때도 `OfferTerms`를 쓴다.
  - `sealed class ProposalTarget` — `RecruitTarget()`(모집 조건), `NewOfferTarget(creatorId, creatorName)`, `ReplyTarget(offerId, counterpartName, nextVersion)`(Task 12가 쓴다), `CounterTarget(storeId | offerId, storeName, nextVersion)`(Task 10이 쓴다)
  - `proposalDraftViewModelProvider(ProposalTarget)` — 고르는 중인 `OfferTerms`를 든다. 처음 값은 가게의 모집 조건(없으면 서버 설정의 기본값).
  - `RewardBudgetPage(target)`(F1), `ReviewSendPage(target, onSend)`(F2)
  - `offer_terms_text.dart`(순수):
    - `benefitLine(Voucher)` → `식사권 40,000원 · 2인`(인원이 없으면 `식사권 40,000원`)
    - `benefitShort(Voucher)` → `식사권 2인`(A6 제목용)
    - `fixedCashLabel(int)` → `없음` / `30,000원`; `fixedCashChip(int)` → `없음` / `3만 원`
    - `viewPayLine(ViewPay)` → `1,000회당 2,000원 · 1인 최대 60,000원`; `viewPayLineComma(ViewPay)` → `1,000회당 2,000원, 최대 60,000원`
    - `rateLabel(int)` → `1,000회당 2,000원`; `capLabel(int)` → `최대 60,000원`
    - `deliverableLine(format, pieces)` → `릴스 1편 · 30초 안팎` / `쇼츠 1편 · 60초 안팎` / `카드뉴스 1편 · 3–5장` / `블로그 글 1편 · 사진 포함 후기`
    - `usageRightsLabel(UsageRights)` → `가게 계정 재게시 3개월` / `가게 계정 재게시 6개월` / `사용 안 함`
    - `rewardHeadline(Reward)` → `식사권 40,000원 · 2인 + 조회수 수당` / `식사권 40,000원 · 2인` / `고정 현금 30,000원` / `식사권 40,000원 · 2인 + 고정 현금 30,000원 + 조회수 수당`(있는 요소를 ` + `로 잇는다)
    - `feeNote(int maxCashBurden, int feeRate)` → `이용료 6,000원은 별도예요.`(최대 현금 부담이 0원이면 빈 글자)
  - 라우트: `AppRoutes.storeOnboardingTerms`(경로 그대로 `/store/onboarding/terms`)가 `RecruitTermsPage`를 연다. `storeEntryPath`의 `TERMS`·`DONE` 분기는 그대로 이 경로다.

화면 문구:
- 모집 조건 1단계: 머리 `제안 만들기`, `1 / 3`, 2번의 형식 고르기(`어떤 콘텐츠를\n부탁할까요?` / `크리에이터가 올릴 형식을 하나 골라요.`), 버튼 `다음`.
- F1: 머리 `제안 만들기`, `2 / 3`, 제목 `보상을 정해요.`, 설명 `식사권과 현금은 따로 계산해요.`
  - `제공 혜택` · `현금과 더하지 않아요` · 값 `식사권 40,000원 · 2인`(혜택이 없으면 `없음`). 누르면 이름·금액·인원을 고치는 시트. 시트에 `혜택 없음`.
  - `고정 현금 (선택)` · 알약 `없음`, `3만 원`, `5만 원`, `10만 원`(서버 설정의 `presets`), `직접 입력`(1만 원 단위, 최대 100만 원 — 캔버스 밖)
  - `조회수 수당` · `조회수만큼 더 드려요 · 기본으로 켜져 있어요` · 스위치. 켜면 `단가` / `1,000회당 2,000원`, `1인 상한` / `최대 60,000원`, `측정 기간` / `게시 후 7일`. 단가와 상한 줄을 누르면 서버 설정의 범위에서 고른다. 측정 기간은 눌리지 않는다.
  - 블로그 글이면 스위치가 꺼져 있고 눌리지 않으며 `블로그 글은 조회수를 셀 수 없어요.`
  - 아래 고정: `최대 현금 부담 · 남으면 환불`, 금액, 버튼 `검토하고 보내기`. 세 요소가 모두 없으면 버튼이 꺼지고 `보상을 하나 이상 정해 주세요.`
- F2: 머리 `제안 만들기`, `3 / 3`, 제목 `받는 사람과 조건을\n한 번 더 확인해요.`
  - 줄: `받는 사람`, `모집`, `결과물`, `제공 혜택`, `고정 현금`, `조회수 수당`, `사용권`, `최대 현금 부담`. 없는 요소는 `없음`. `사용권` 줄을 누르면 세 선택지.
  - `모집` 값은 `{가게 이름} · {모집 한 줄}`, 모집 한 줄이 비면 가게 이름만(모집 한 줄 입력은 Task 14).
  - 안내 `보낸다고 합의가 되는 건 아니에요. 상대가 수락하면 그때 결제해요. 보낸 조건은 판본 {n}로 고정되고, 이용료 {수수료}는 별도예요.` — `{n}`은 이번에 만들어질 판본 번호(`josa`로 `판본 1로`/`판본 2로`/`판본 3으로`), `{수수료}`는 `feeNote`의 금액. 버튼 `고치기`(F1로 돌아감), `이 조건으로 보내기`.
  - 모집 조건일 때: `받는 사람` 값 `공개 모집`, 안내 `크리에이터가 가게 페이지에서 이 조건을 봐요. 오퍼를 보낼 때 바꿀 수 있어요.`, 버튼 `이 조건으로 공개하기`. 누르면 기본 조건 저장 → 가게 공개 → 사장님 홈. 실패하면 `가게를 공개하지 못했어요. 다시 시도해 주세요.`(지금 문구)

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('writes the benefit, view pay and deliverable lines like the canvas', ...);     // '식사권 40,000원 · 2인', '1,000회당 2,000원 · 1인 최대 60,000원', '릴스 1편 · 30초 안팎'
test('joins the present reward elements into a headline', ...);
test('adds fixed cash and the cap into the maximum cash burden', ...);
test('writes the fee note from the server fee rate and hides it at zero burden', ...);
testWidgets('F1 starts from the store defaults with view pay on', ...);              // '60,000원'
testWidgets('F1 updates the maximum cash burden when fixed cash is picked', ...);    // 3만 원 → '90,000원'
testWidgets('F1 drops the cap from the burden when view pay is switched off', ...);
testWidgets('F1 offers only rates and caps inside the server range', ...);
testWidgets('F1 disables the button and explains when no reward is left', ...);
testWidgets('F1 keeps view pay off for a blog post', ...);
testWidgets('F2 lists the eight rows and the version number in the notice', ...);    // '판본 1로 고정되고, 이용료 6,000원은 별도예요.'
testWidgets('F2 goes back to F1 from the edit button with the values kept', ...);
testWidgets('recruit flow saves the terms, publishes the store and opens the home', ...);
testWidgets('recruit review shows the open call wording and button', ...);           // '공개 모집', '이 조건으로 공개하기'
testWidgets('resumes onboarding at the recruit terms step', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test`
- [ ] **Step 5: 시뮬레이터 확인** — 새 번호(`010-0000-0061`)로 가게를 등록해 형식 → F1 → F2 → 공개까지 간다. F1·F2를 `NBudget`·`NReviewSend`와 라이트·다크로 나란히 비교하고 `shots/task7/`에 둔다.
- [ ] **Step 6: Commit** — 커밋 세 개: `refactor: 앱의 오퍼 조건을 보상 세 요소로 바꿈`, `feat: 보상·예산 설정과 보내기 전 검토 화면 추가`, `feat: 모집 조건으로 가게를 공개하는 흐름으로 교체`

**완료 기준:** 테스트 통과, `grep -rn "RewardType\|perViewAmount" app/lib`가 `features/demo/`뿐, 시뮬레이터에서 띄워 캔버스와 라이트·다크 모두 비교.

---

### Task 8: 앱 — 오퍼 보내기(A5), 받은 오퍼(A6), 결제(A8)·진행 화면(A7)의 금액

**목적:** A5의 보상 단계를 세 가지 빠른 조합으로 바꾸고 F2를 거쳐 보낸다. A6의 보상 문구를 바꾸고, 수락이 판본 번호를 보내며 옛 판본이면 F8 화면을 보여 준다. A8과 A7의 금액 문구를 새 보상에 맞춘다(F4로 가는 줄은 Task 21).

**Files:**
- Modify: `app/lib/features/offers/presentation/{pages/send_offer_page.dart,pages/received_offers_page.dart,viewmodels/send_offer_view_model.dart,viewmodels/received_offers_view_model.dart,received_offers_text.dart}`, `app/lib/features/offers/domain/{received_offer.dart,received_offers_repository.dart}`, `app/lib/features/offer_terms/presentation/widgets/{offer_terms_wizard.dart,confirm_step.dart}`, `app/lib/features/offer_terms/presentation/viewmodels/offer_terms_wizard_view_model.dart`, `app/lib/features/store_home/{domain/store_home_repository.dart,data/api_store_home_repository.dart}`, `app/lib/features/payment/{domain/payment_quote.dart,data/api_payment_repository.dart,presentation/pages/store_payment_page.dart}`, `app/lib/features/collaboration/{presentation/collaboration_text.dart,presentation/pages/collaboration_page.dart}`, 3번 계획 Task 13이 만든 `app/lib/features/collaboration/presentation/pages/store_collaboration_page.dart`
- Create: `app/lib/features/offer_terms/presentation/widgets/reward_preset_step.dart`
- Delete: `app/lib/features/offer_terms/presentation/widgets/{reward_step.dart,voucher_edit_sheet.dart}`
- Test: `app/test/features/offers/`, `app/test/features/offer_terms/`, `app/test/features/payment/`, `app/test/features/collaboration/`

**Interfaces:**
- Consumes: Task 7의 `RewardBudgetPage`, `ReviewSendPage`, `NewOfferTarget`; `cora_api`의 `sendOffer`, `acceptOffer`(판본 번호) (Task 5)
- Produces:
  - `enum RewardPreset { benefitOnly, fixedCash, benefitAndViewPay }`, `presetOf(Reward): RewardPreset?`(맞는 조합이 없으면 null), `applyPreset(Reward base, RewardPreset): Reward`
  - `ReceivedOffersFailure`에 `staleVersion: int?` 추가(서버의 `details.latestVersion`).
  - `ReceivedOffersRepository.accept(String id, int version)`

화면 문구:
- A5 2단계: 제목 `어떻게\n보상할까요?`, 설명 `가게 등록 때 정한 기본값이에요. 최대 현금 부담 {금액}, 조회수가 적으면 남은 돈은 돌려드려요.`(금액은 지금 고른 조합의 최대 현금 부담), 오른쪽 `자세히 설정` → F1.
  - `제공 혜택만` / `식사권 40,000원 · 2인`
  - `고정 현금` / `정한 금액을 한 번에 · 선택` — 고르면 금액 입력란(1만 원 단위)이 나온다.
  - `제공 혜택 + 조회수 수당 · 추천` / `1,000회당 2,000원 · 1인 최대 60,000원`
  - 처음 골라져 있는 것은 가게의 모집 조건과 같은 조합이다. 맞는 조합이 없으면 2단계 대신 F1로 바로 간다.
  - 블로그 글이면 셋째 선택지가 꺼지고 `블로그 글은 조회수를 셀 수 없어요.`
- A5 3단계: `이 오퍼를\n보낼까요?` / `상대가 수락하면 그때 결제해요.` / 줄 `가게`, `콘텐츠`, `보상` / `결제한 금액은 Cora가 보관하고, 콘텐츠가 올라온 뒤 크리에이터에게 지급해요.` / 버튼 `검토하고 보내기` → F2(`NewOfferTarget`). F2의 `이 조건으로 보내기`가 서버에 보낸다. 성공하면 사장님 홈의 보낸 오퍼 탭으로 가고 `오퍼를 보냈어요.`(Task 12가 제안함으로 바꾼다). 409면 `이미 보낸 오퍼가 있어요.`
- A6 카드: 제목 아래 `{benefitShort} + 조회수 수당`(요소에 맞게), 설명 `{viewPayLineComma}. {가게 소개}`. 나머지는 그대로.
- A6 수락: 판본 번호를 함께 보낸다. `STALE_VERSION`이면 카드 자리에 `CoraStateView.staleVersion(version: n)`을 보여 주고, `판본 {n} 보기`를 누르면 목록을 새로 읽어 그 오퍼의 새 카드를 보여 준다(Task 12 뒤에는 제안 상세를 연다).
- 내 차례가 아닌 오퍼(`myTurn == false`)는 `새 오퍼` 탭의 카드로 나오지 않는다.
- A8: 내역 `콘텐츠` / `{형식} 1편`, (혜택이 있으면) `{benefitLine}` / `방문 때 가게에서 제공`, (고정 현금이 있으면) `고정 현금` / `30,000원`, (조회수 수당이 있으면) `조회수 수당 (최대)` / `60,000원`, `서비스 수수료` / 금액, `지금 결제할 금액` / 합계. 안내 — 조회수 수당만: `최대 60,000원, 실제는 조회수만큼, 남으면 7일 집계 후 환불해요.` / 고정 현금도 있으면: `최대 {최대 현금 부담}원, 조회수 수당은 조회수만큼, 남으면 7일 집계 후 환불해요.` / 조회수 수당이 없으면 안내 줄 없음. 옛 `조회수당 (최대)`와 `조회수가 적어 다 쓰지 않은 금액은…` 문구는 없앤다.
- A7과 사장님 진행 화면: 보관 금액은 보관액 그대로, `+ {benefitLine} (방문 때 사용)`, 마지막 단계 `7일간 조회수 집계 후 지급` / `최대 {상한}`(`최대 6만 원` — 보관액이 아니라 조회수 수당 상한이다. 조회수 수당이 없으면 부제 없음).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('finds the preset that matches a reward and none for a mixed reward', ...);
testWidgets('A5 preselects the preset of the store recruit terms', ...);
testWidgets('A5 shows the maximum cash burden of the chosen preset in the description', ...);
testWidgets('A5 asks for an amount when fixed cash is chosen', ...);
testWidgets('A5 opens F1 from detailed settings and comes back with the edited reward', ...);
testWidgets('A5 skips to F1 when no preset matches', ...);
testWidgets('A5 sends only from the F2 button and returns home with a confirmation', ...);
testWidgets('A6 writes the reward like the canvas', ...);                            // '식사권 2인 + 조회수 수당', '1,000회당 2,000원, 최대 60,000원. …'
testWidgets('A6 sends the version number when accepting', ...);
testWidgets('A6 shows the stale version state and reloads on its button', ...);
testWidgets('A8 lists the benefit, view pay, fee and total like the canvas', ...);
testWidgets('A8 adds a fixed cash row and the combined notice', ...);
testWidgets('A8 drops the notice when there is no view pay', ...);
testWidgets('A7 writes the last step with the cap, not the escrow', ...);            // 고정 현금 30000 + 상한 60000 → '최대 6만 원'
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test`
- [ ] **Step 5: 시뮬레이터 확인** — 두 계정으로 A5 → F2 → 보내기 → A6 수락. 이어서 결제(A8)와 A7의 금액을 본다. A5·A6·A8·A7을 `NOffer`·`NOfferInbox`·`NPay`·`NEscrow`와 라이트·다크로 비교, `shots/task8/`(A7의 `조회 자료와 보상 계산 확인` 줄은 Task 21 전에는 없다).
- [ ] **Step 6: Commit** — 커밋 세 개: `feat: 오퍼 보내기를 빠른 보상 조합과 검토 단계로 바꿈`, `feat: 받은 오퍼가 판본 번호로 수락하고 옛 판본을 알림`, `feat: 결제와 협업 진행 화면의 금액 표시를 새 보상으로 바꿈`

**완료 기준:** 테스트 통과, 시뮬레이터에서 띄워 캔버스와 라이트·다크 모두 비교.

---

### Task 9: 서버 — 크리에이터가 시작하는 제안, 시리즈, 지원 한 줄

**목적:** 크리에이터가 가게 페이지에서 "내 방식으로 제안"을 보낸다. 시리즈를 만들어 고른다. 지원에 한 줄을 붙인다.

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/offers/{offers.service.ts,offers.repository.ts,offers.controller.ts,offers.module.ts,dto/propose-version.dto.ts}`, `api/src/applications/{applications.service.ts,applications.repository.ts,applications.controller.ts,dto/applicant.model.ts}`, `api/src/creators/{creators.service.ts,creators.repository.ts,creators.controller.ts}`, `api/src/stores/{stores.service.ts,stores.repository.ts,dto/store-public.model.ts}`
- Create: 마이그레이션, `api/src/creators/dto/{creator-series.model.ts,create-creator-series.dto.ts}`, `api/src/applications/dto/apply.dto.ts`, `api/src/offers/dto/store-proposal.dto.ts`
- Test: `api/test/{offers,applications,creators,stores}.e2e-spec.ts`(추가), `api/test/db/store-offer-schema.db-spec.ts`(추가)

**Interfaces:**
- Produces:
  - `CreatorSeries` → `creator_series`: `id`, `creatorId`, `name`(20자), `format ContentFormat`, `note String?`(20자), 공통 시각 열. 인덱스 `(creatorId)`. RLS.
  - `applications`: `pitch String?`(100자), `skippedFromPicksAt DateTime?`(Task 16이 쓴다).
  - `GET /creators/me/series` → 200 `CreatorSeriesModel[]`, `POST /creators/me/series` 본문 `{ name; format; note? }` → 201. 5개를 넘으면 409 `시리즈는 5개까지 만들 수 있어요.` `operationId: listMyCreatorSeries`, `createMyCreatorSeries`.
  - `POST /stores/:id/applications` 본문 `ApplyDto { pitch?: string }`. `ApplicantModel`에 `pitch: string | null`.
  - `POST /stores/:id/proposals` 본문 `StoreProposalDto`(= `ProposeVersionDto`) → 201 `{ offerId: string; version: number }`. `CREATOR` 역할만. `operationId: proposeToStore`. 검사: 공개된 가게 → 내 가게 아님 → 프로필 → 조건 → 조회수 수당이 켜졌으면 인스타그램.
    - 그 가게와 열린 오퍼가 없으면: 오퍼를 만든다(`initiatedBy = CREATOR`, `turn = STORE`, `latestVersion = 2`, `expiresAt = now + 7일`). **판본 1은 가게의 모집 조건**(`authorParty = STORE`), 판본 2가 크리에이터의 제안이다. 살아 있는 지원이 없으면 지원을 만들어 바로 `OFFERED`로 두고 오퍼에 연결한다. 있으면 그 지원을 `OFFERED`로 바꿔 연결한다.
    - 열린 `SENT` 오퍼가 있고 차례가 크리에이터면: Task 6의 판본 내기와 같은 길로 다음 판본을 낸다.
    - 열린 오퍼가 있는데 차례가 가게거나 `ACCEPTED`면 409 `이미 진행 중인 제안이 있어요.`
    - 사장님에게 `OFFER_COUNTERED`.
  - 판본 내기와 위 제안의 `seriesId`: 내 시리즈면 이름·형식·설명을 판본에 사본으로 넣는다. 내 것이 아니면 404.
  - `StoreDetailModel`에 `myOpenOffer: { id: string; latestVersion: number; myTurn: boolean } | null` 추가(D2가 "내 방식으로 제안"을 어느 오퍼에 붙일지 안다).
  - 가게 홈의 `newApplications`는 `APPLIED`만 세므로 제안으로 생긴 지원은 들지 않는다(바꿀 것 없음, 테스트로 고정).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('creates an offer with the store terms as version 1 and the creator proposal as version 2', ...);
it('gives the first turn to the store and starts the 7 day window', ...);
it('links a new OFFERED application so the proposal is not counted as a new applicant', ...);
it('reuses my live application when I had applied before proposing', ...);
it('adds the next version to an open offer when it is my turn', ...);
it('refuses a second proposal while the store has not answered', ...);               // 409
it('refuses a proposal with view pay without instagram', ...);                       // 409
it('copies my series into the version and rejects someone else\'s series', ...);
it('refuses a sixth series', ...);
it('saves the pitch with the application and shows it to the owner', ...);
it('rejects a pitch longer than 100 characters', ...);
it('tells the store detail about my open offer and whose turn it is', ...);
it('lets only one of two concurrent proposals create the offer', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현(마이그레이션, 새 테이블의 RLS) → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 크리에이터 시리즈와 지원 한 줄 추가`, `feat: 크리에이터가 가게 페이지에서 시작하는 제안 추가`

**완료 기준:** 테스트 통과.

---

### Task 10: 앱 — 가게 상세(D2)와 크리에이터 역제안(F6)

**Files:**
- Create: `app/lib/features/proposals/domain/{creator_series.dart,counter_proposal_repository.dart}`, `data/api_counter_proposal_repository.dart`, `presentation/viewmodels/counter_proposal_view_model.dart`, `presentation/pages/counter_proposal_page.dart`, `presentation/widgets/series_add_sheet.dart`, `presentation/counter_proposal_text.dart`
- Modify: `app/lib/features/store_browse/{domain/store_detail.dart,domain/store_browse_repository.dart,data/api_store_browse_repository.dart,presentation/pages/store_detail_page.dart,presentation/viewmodels/store_detail_view_model.dart,presentation/store_browse_text.dart}`, `app/lib/core/navigation/{app_routes.dart,app_router.dart}`, `app/lib/main.dart`
- Test: `app/test/features/store_browse/`, `app/test/features/proposals/`

**Interfaces:**
- Consumes: `cora_api`의 `applyToStore`(한 줄), `proposeToStore`, `proposeOfferVersion`, `listMyCreatorSeries`, `createMyCreatorSeries` (Task 6, 9); Task 7의 F1 시트들과 `ReviewSendPage`, `CounterTarget`
- Produces:
  - `StoreBrowseRepository.apply(String storeId, {String? pitch})`
  - `abstract class CounterProposalRepository { Future<List<CreatorSeries>> fetchSeries(); Future<CreatorSeries> addSeries(...); Future<({String offerId, int version})> sendToStore(String storeId, CounterProposal p); Future<void> sendVersion(String offerId, CounterProposal p); }`
  - `extraBurdenLabel(int storeBurden, int myBurden)`(순수) → `추가 부담 없음` / `가게 부담 +30,000원`
  - `hopeRewardSummary(Reward)`(순수) → `식사권 + 3만 원`(요소를 짧게 잇는다: `식사권`, `{n}만 원`, `조회수 수당`)
  - 라우트: `/creator/stores/:id/propose`

화면 문구:
- D2: 보상 값 `{rewardHeadline}` / 둘째 줄 `{viewPayLine}`(조회수 수당이 있을 때). 소개 글 아래 입력란 `이 가게라면 이렇게 찍겠다 · 한 줄 · 조회수가 없어도 지원할 수 있어요`(100자, 선택). 버튼 `내 방식으로 제안`, `조건 그대로 지원`. `가게 정보` 버튼은 없앤다. 지원 뒤 `지원했어요. 사장님이 고르면 오퍼가 도착해요.`와 `취소`는 그대로. `offered` 상태의 `오퍼가 도착했어요.` / `오퍼 보기`도 그대로.
- F6: 머리 `내 방식으로 제안`. 가게 이름, `{동네} · 방문 1회 · {찍기 좋은 시간} 촬영 가능`(없는 값은 뺀다), `가게 조건: {benefitLine} + {viewPayLineComma 형태} · {extraBurdenLabel}`.
  - `내 시리즈로 만들기`: 내 시리즈 카드(`{이름}` / `{설명}`)와 `시리즈 추가`(이름 20자, 형식, 설명 20자). 시리즈가 없으면 형식 고르기만 보인다.
  - `아이디어`(200자) — D2에서 쓴 한 줄이 채워져 온다.
  - `희망 보상` — 값은 `hopeRewardSummary`, 누르면 F1의 세 줄(혜택, 고정 현금, 조회수 수당)을 고치는 시트.
  - `표현 원칙` — 꼬리표 최대 3개(각 10자), `#얼굴출연없음`처럼 보인다.
  - 버튼 `검토하고 보내기` → F2(`CounterTarget`, 받는 사람은 가게 이름). 보내면 가게 상세로 돌아가 `제안을 보냈어요.`(캔버스 밖). 조회수 수당이 켜졌는데 연동이 없으면 F2 버튼 자리에 `인스타그램을 연동하면 수락할 수 있어요`와 `연동하기`(3번의 문구).
- `myOpenOffer`가 있고 내 차례면 `내 방식으로 제안`은 그 오퍼의 다음 판본을 낸다. 내 차례가 아니면 버튼이 꺼지고 `사장님의 답을 기다리고 있어요.`(캔버스 밖)

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('D2 shows the reward in the new wording and the two buttons', ...);
testWidgets('D2 applies with the one line pitch', ...);
testWidgets('D2 carries the pitch into the idea field of F6', ...);
test('says no extra burden when my hope fits the store burden and the difference otherwise', ...);
testWidgets('F6 lists my series and adds a new one', ...);
testWidgets('F6 shows only the format picker without a series', ...);
testWidgets('F6 limits the idea to 200 characters and the tags to three', ...);
testWidgets('F6 sends a new proposal through F2 as version 2', ...);                 // '판본 2로 고정되고'
testWidgets('F6 adds the next version to an open offer when it is my turn', ...);
testWidgets('F6 asks for instagram before sending view pay', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 시뮬레이터 확인** — D2·F6을 `NStoreView`·`NCounter`와 라이트·다크로 비교, `shots/task10/`.
- [ ] **Step 6: Commit** — 커밋 두 개: `feat: 가게 상세에 한 줄 지원과 내 방식으로 제안 추가`, `feat: 크리에이터 역제안 화면 추가`

**완료 기준:** 테스트 통과, 시뮬레이터에서 띄워 캔버스와 라이트·다크 모두 비교.

---

### Task 11: 서버 — 제안함 목록과 제안 상세

**Files:**
- Create: `api/src/offers/{proposals.controller.ts,proposals.service.ts,dto/proposal-row.model.ts,dto/proposal-detail.model.ts,dto/proposals-query.dto.ts}`
- Modify: `api/src/offers/{offers.module.ts,offers.repository.ts,offer-versions.repository.ts,proposal-rules.ts,dto/sent-offer.model.ts}`
- Test: `api/src/offers/proposal-rules.spec.ts`(추가), `api/test/proposals.e2e-spec.ts`

**Interfaces:**
- Produces:
  - `proposalGroup(offer, me: OfferParty, now): 'MY_TURN' | 'WAITING' | 'ENDED'`, `endKind(offer, now): 'AGREED' | 'ENDED' | 'EXPIRED' | null`(`proposal-rules.ts`, 순수) — `ACCEPTED`는 `ENDED` 묶음의 `AGREED`다.
  - `GET /offers/proposals?tab=active|ended` → 200 `ProposalRowModel[]`. 사장님은 내 가게의 오퍼, 크리에이터는 내가 받은·보낸 오퍼. `operationId: listProposals`
  - `ProposalRowModel { offerId; counterpart: { name; photoUrl }; group; version: number; counter: boolean; format; pieces; daysLeft: number | null; endKind; endReason: OfferEndReason | null; collaborationId: string | null }` — `counter`는 최신 판본을 상대가 썼고 번호가 2 이상일 때 true. `daysLeft`는 `WAITING`일 때 남은 응답 기한(올림), 하루 미만이면 0. 순서는 `MY_TURN` → `WAITING`, 같은 묶음에서는 최근 판본 순.
  - `GET /offers/:id` → 200 `ProposalDetailModel { offerId; status; myParty; group; latest: OfferVersionModel; previous: OfferVersionModel | null; changed: string[]; store: { id; name; recruitLine: string | null }; counterpart: { userId; name; photoUrl }; feeRate: number; needsInstagram: boolean; expiresAt; endKind; endReason; collaborationId }` — 당사자만, 아니면 404. `operationId: getProposal`. 라우트는 `offers/sent`, `offers/received`, `offers/proposals`보다 **아래**에 둔다.
  - `SentOfferModel`에 `needsMyAnswer: boolean`(차례가 가게) 추가 — A9 보낸 오퍼 줄이 쓴다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('groups an offer by whose turn it is', ...);
it('puts accepted, declined, cancelled and expired offers in the ended tab', ...);
it('marks a row as a counter proposal when the other party wrote version 2 or later', ...);
it('counts the days left to answer and zero for less than a day', ...);
it('shows the creator both offers received and proposals started', ...);
it('returns the latest and previous versions with the changed fields', ...);
it('returns the collaboration id for an agreed proposal', ...);
it('returns 404 for a proposal I am not part of', ...);
it('expires an overdue offer before listing it', ...);                               // 읽을 때 만료
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e`
- [ ] **Step 5: gen-api, Commit** — `feat: 제안함 목록과 제안 상세 API 추가`

**완료 기준:** 테스트 통과, Review Focus 10(판본) 확인.

---

### Task 12: 앱 — 제안함(F3), 제안 상세, 사장님 홈의 보낸 오퍼

**Files:**
- Create: `app/lib/features/proposals/domain/{proposal.dart,offer_version.dart,proposal_repository.dart}`, `data/api_proposal_repository.dart`, `presentation/viewmodels/{proposals_view_model.dart,proposal_detail_view_model.dart}`, `presentation/pages/{proposals_page.dart,proposal_detail_page.dart}`, `presentation/widgets/end_reason_sheet.dart`, `presentation/proposal_text.dart`
- Modify: `app/lib/features/store_home/presentation/{pages/store_home_page.dart,store_home_text.dart}`, `app/lib/features/store_home/domain/sent_offer.dart`, `app/lib/features/offers/presentation/pages/{received_offers_page.dart,send_offer_page.dart}`, `app/lib/core/navigation/{app_routes.dart,app_router.dart}`, 3번 계획 Task 13C가 만든 `app/lib/features/notifications/presentation/notification_routes.dart`(`PROPOSAL` → 제안 상세), `app/lib/main.dart`
- Test: `app/test/features/proposals/`, `app/test/features/store_home/`(추가), `app/test/features/notifications/`(추가)

**Interfaces:**
- Consumes: `cora_api`의 `listProposals`, `getProposal`, `acceptOffer`, `endOffer`, `proposeOfferVersion`, `cancelOffer` (Task 5, 6, 11); Task 7의 `ReplyTarget`, Task 10의 F6
- Produces:
  - `abstract class ProposalRepository { Future<List<ProposalRow>> fetch(ProposalTab tab); Future<ProposalDetail> fetchDetail(String offerId); Future<String?> accept(String offerId, int version); Future<void> end(String offerId, EndReason reason); Future<void> reply(String offerId, OfferTerms terms); }` — `accept`는 협업 id를 돌려준다.
  - `proposal_text.dart`(순수): `rowSubtitle(ProposalRow)` → `역제안 · 판본 2 · 카드뉴스 1편` / `판본 1 · 릴스 1편 · 2일 안에 답이 와요` / `판본 1 · 릴스 1편 · 오늘 안에 답이 와요` / `합의 완료 · 계약으로 이동` / `일정이 맞지 않아 종료` / `조건이 맞지 않아 종료` / `다른 분과 진행해 종료` / `종료` / `기한이 지나 종료`; `rowBadge(ProposalRow)` → `응답하기` / `대기` / `완료` / `종료`; `endReasonLabel(EndReason)` → `일정이 맞지 않아요` / `조건이 맞지 않아요` / `다른 분과 진행해요` / `이유 없이 종료`
  - 라우트: `/store/proposals`, `/store/proposals/:offerId`, `/creator/proposals`, `/creator/proposals/:offerId`

화면 문구:
- F3: 머리 `제안함`, 탭 `진행 중 {n}` / `종료 {n}`. 진행 중은 `내가 응답할 차례`, `상대 대기` 묶음. 빈 상태는 `CoraStateView.empty`: 진행 중 `아직 받은 제안이 없어요`(캔버스 F8) — 사장님에게는 설명 `크리에이터에게 오퍼를 보내면 여기에 모여요.`(캔버스 밖), 크리에이터에게는 캔버스의 설명과 버튼을 뺀 제목만(포트폴리오는 7번). 종료 `아직 끝난 제안이 없어요`(캔버스 밖).
- 제안 상세(캔버스에 없는 화면 — F2의 줄 구성과 공용 위젯을 따른다): 머리 `판본 {n}`, F2와 같은 여덟 줄에 크리에이터가 쓴 판본이면 `아이디어`, `표현 원칙`, `시리즈` 줄을 더한다. 이전 판본과 달라진 줄에 표지 `바뀜`(캔버스 밖). 안내는 F2와 같고 `{수수료}`는 사장님에게만 보인다.
  - 내가 응답할 차례 — 사장님: `이 판본 수락` / `고쳐서 다시 보내기`(F1, `ReplyTarget`) / `제안 종료`. 크리에이터: `이 판본 수락` / `내 방식으로 제안`(F6) / `거절`.
  - 상대 대기: `제안 취소`. 종료: 버튼 없음.
  - `제안 종료`·`거절`·`제안 취소`는 사유 시트(네 가지)를 띄우고 고르면 끝낸다.
  - 사장님이 수락하면 결제(A8)로, 크리에이터가 수락하면 `수락했어요.` / `사장님이 결제하면 알려드릴게요.`(2번 문구) 뒤 협업 화면으로.
  - `STALE_VERSION`이면 `CoraStateView.staleVersion` → `판본 {n} 보기`가 상세를 새로 읽는다.
  - 크리에이터의 `needsInstagram`이면 수락 버튼 대신 3번의 연동 안내.
- `합의 완료 · 계약으로 이동` 줄을 누르면 사장님은 결제(A8, 이미 결제했으면 3번 Task 13의 사장님 진행 화면), 크리에이터는 협업 화면(A7).
- 사장님: 하단 메뉴 `오퍼` → `/store/proposals`. A9 `보낸 오퍼` 탭의 줄은 그대로 두고, 차례가 가게인 줄의 상태 글을 `역제안이 왔어요`, 버튼을 `응답하기`로 바꾼다(누르면 제안 상세). 줄을 눌러 뜨던 취소 시트는 제안 상세로 대체한다. A5·F2에서 보낸 뒤에는 `/store/proposals`로 가고 `오퍼를 보냈어요.`
- 크리에이터: 받은 오퍼(A6)의 `진행 중` 탭 맨 위에 `제안함` 줄(오른쪽에 내가 응답할 차례의 수) → `/creator/proposals`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('writes each proposal row like the canvas', ...);                               // 캔버스 F3의 다섯 줄
test('writes today for less than a day left', ...);
testWidgets('F3 groups active proposals by turn and counts both tabs', ...);
testWidgets('detail shows the owner three actions on their turn', ...);
testWidgets('detail shows the creator three actions on their turn', ...);
testWidgets('detail shows only cancel while waiting and nothing when ended', ...);
testWidgets('detail marks the rows that changed from the previous version', ...);
testWidgets('accepting as the owner opens the payment screen', ...);
testWidgets('ending asks for one of four reasons', ...);
testWidgets('replying opens F1 with the latest terms and sends the next version', ...); // '판본 3으로 고정되고'
testWidgets('shows the stale version state when the other party sent a newer one', ...);
testWidgets('store home marks a sent offer that needs my answer', ...);              // '역제안이 왔어요', '응답하기'
testWidgets('the offer tab in the store bottom nav opens the proposal box', ...);
testWidgets('the creator opens the proposal box from the in-progress tab', ...);
testWidgets('a proposal notification opens the proposal detail', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 시뮬레이터 확인** — 두 계정으로 오퍼 → 역제안 → 다시 보내기 → 수락까지 주고받는다. F3을 `NProposals`와, A9 보낸 오퍼 탭을 `NStoreHome`과 라이트·다크로 비교, `shots/task12/`.
- [ ] **Step 6: Commit** — 커밋 두 개: `feat: 제안함과 제안 상세 화면 추가`, `feat: 사장님 홈과 받은 오퍼에서 제안함으로 가는 길 추가`

**완료 기준:** 테스트 통과, 시뮬레이터에서 띄워 캔버스와 라이트·다크 모두 비교(제안 상세는 캔버스 밖 — 소유자 확인 목록).

---

### Task 13: 서버 — 가게 등록 변경 (후기 글 링크, 직접 입력, 지점, 주소 이름, 꼬리표, 체험단 정보)

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/integrations/store-link/{store-link.port.ts,fake-store-link.adapter.ts}`, `api/src/stores/{stores.service.ts,stores.repository.ts,stores.controller.ts,source-link-rules.ts,dto/analyze-links.dto.ts,dto/my-store.model.ts,dto/update-store.dto.ts}`
- Create: 마이그레이션, `api/src/stores/slugify.ts`, `api/src/stores/dto/{manual-store.dto.ts,store-branch.model.ts,trial-info.dto.ts}`
- Test: `api/src/stores/slugify.spec.ts`, `api/src/stores/source-link-rules.spec.ts`(추가), `api/src/integrations/store-link/fake-store-link.adapter.spec.ts`(추가), `api/test/stores.e2e-spec.ts`(추가), `api/test/db/store-offer-schema.db-spec.ts`(추가)

**Interfaces:**
- Produces:
  - `SourceLinkKind`에 `REVIEW_POST` 추가. 받는 호스트: `blog.naver.com`, `m.blog.naver.com`, `*.tistory.com`. 메시지 `체험단 후기 글 링크가 맞는지 확인해 주세요.` `AnalyzeLinksDto`는 링크 1~4개.
  - `stores`: `slug String? @unique`, `tags String[]`, `customerPhrases String[]`, `recruitLine String?`, `trialMonthlyFee Int?`, `trialEndsOn DateTime? @db.Date`, `trialPostCount Int?`, `trialSnoozedUntil DateTime?`, `trialHintSeenAt DateTime?`
  - `StoreLinkPort.findBranches(name: string): Promise<{ label: string; address: string; neighborhood: string | null; regionSido: string | null; regionSigungu: string | null }[]>`. `StoreLinkResult.store`에 `reviewCount: number | null`, `tags: string[]`, `customerPhrases: string[]`.
  - 가짜 구현: `findBranches('한그릇 라멘')` → `성수점`(`성수동2가`, 서울특별시 성동구), `합정점`(`합정동`, 서울특별시 마포구). 다른 이름은 빈 목록. `analyze`의 요약 — 네이버 지도 `메뉴 12개, 사진 34장, 후기 58개 찾음`, 캐치테이블 `영업시간 찾음`, 인스타그램 `게시물 9개 찾음`(그대로), 후기 글 `후기 글 찾음`(캔버스 밖). 꼬리표 `진한국물`, `바좌석`, `조용한오후`, 자주 한 말 `국물이 진해요`, `혼밥하기 좋아요`.
  - `slugify(name: string): string`(순수) — 한글은 음절을 초성·중성·종성으로 나눠 로마자로 옮기고(`한그릇 라멘` → `hangeureut-ramen`), 영문·숫자는 소문자로, 그 밖의 글자는 버리고, 띄어쓰기는 `-`. 결과가 비면 `store`. 길이 40자까지.
  - 주소 이름: 가게에 이름이 처음 생길 때 만든다(분석 결과 저장, 직접 입력, 이름 고치기). 겹치면 `-2`, `-3`…을 붙인다(유일 제약에 걸리면 다시 시도). **한 번 생기면 이름을 고쳐도 바꾸지 않는다.** 개정 전에 만들어진 가게는 `getMine`이 읽을 때 `WHERE slug IS NULL` 조건부 갱신으로 채운다.
  - `GET /stores/me/branches?name=` → 200 `StoreBranchModel[]`. `STORE` 역할만. `operationId: findMyStoreBranches`
  - `POST /stores/me/manual` 본문 `ManualStoreDto { name(필수); branch?: { label; neighborhood?; regionSido?; regionSigungu? }; signatureMenu?; coverPhotoPath? }` → 200 `MyStoreModel`. 등록 중인 가게를 만들거나 덮어쓴다(이미 저장된 링크는 남긴다). 지점을 골랐으면 그 지점의 동네·시·도·구·군을 채운다. 공개된 가게면 409(지금 문구). 사진 경로는 `assertOwnedPath`. `operationId: createMyStoreManually`
  - `UpdateStoreDto`에 `tags`(최대 5개, 각 10자, `#` 없이 저장), `customerPhrases`(최대 3개, 각 20자), `recruitLine`(40자) 추가.
  - `PUT /stores/me/trial-info` 본문 `TrialInfoDto { monthlyFee: number; endsOn: string(YYYY-MM-DD); postCount: number }` → 200 `MyStoreModel`. `DELETE /stores/me/trial-info` → 204. `POST /stores/me/trial-info/snooze` → 204(`trialSnoozedUntil = now + 7일`). `POST /stores/me/trial-info/hint-seen` → 204. `operationId: putMyStoreTrialInfo`, `deleteMyStoreTrialInfo`, `snoozeMyStoreTrialCompare`, `markMyStoreTrialHintSeen`
  - `MyStoreModel`에 `slug: string | null`, `publicUrl: string | null`(`cora.page/l/{slug}`), `tags`, `customerPhrases`, `recruitLine`, `trialInfo: { monthlyFee; endsOn; postCount } | null`, `trialBanner: 'COMPARE' | 'HINT' | null` 추가. `COMPARE`는 체험단 정보가 있고 종료일이 30일 안(지나지 않음)이고 숨김 기간이 아닐 때, `HINT`는 체험단 정보가 없고 후기 글 링크가 있고 아직 본 적 없을 때다(한국 날짜 기준).
  - 공개 조건(`publish`): 이름, 형식, 보상 요소 하나 이상, 시·도.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('romanizes a korean store name into a slug', () => { expect(slugify('한그릇 라멘')).toBe('hangeureut-ramen'); });
it('keeps latin letters and digits and drops other symbols', ...);
it('falls back to store for a name with no usable letters', ...);
it('accepts naver blog and tistory urls for a review post and rejects others', ...);
it('returns two branches for the sample store and none for another name', ...);
it('saves tags and customer phrases from the analysis', ...);
it('gives a new store a slug and adds a number when it is taken', ...);
it('keeps the slug when the name changes', ...);
it('fills the slug of an older store on read', ...);
it('creates a draft store from manual input and fills the region of the chosen branch', ...);
it('keeps the saved links when manual input follows a failed analysis', ...);
it('refuses manual input for a published store', ...);
it('rejects a sixth tag and a tag longer than 10 characters', ...);
it('shows the compare banner within 30 days of the trial end and hides it while snoozed', ...);
it('shows the hint once for a store with a review post link and no trial info', ...);
it('refuses to publish without any reward element', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현(마이그레이션) → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 세 개: `feat: 체험단 후기 글 링크와 가게 꼬리표·주소 이름 추가`, `feat: 매장 직접 입력과 지점 찾기 추가`, `feat: 체험단 계약 정보 저장 추가`

**완료 기준:** 테스트 통과.

---

### Task 14: 앱 — 가게 등록 화면 (A2, F7, A3, A4)

**Files:**
- Create: `app/lib/features/store_onboarding/presentation/pages/store_manual_page.dart`, `presentation/viewmodels/store_manual_view_model.dart`, `presentation/widgets/{tags_edit_sheet.dart,recruit_line_sheet.dart}`, `app/lib/core/share/share_launcher.dart`, `app/test/core/share/share_launcher_test.dart`
- Modify: `app/pubspec.yaml`(`share_plus`), `app/lib/features/store_onboarding/{domain/source_link.dart,domain/my_store.dart,domain/store_repository.dart,data/api_store_repository.dart,presentation/pages/store_links_page.dart,presentation/pages/store_page_preview_page.dart,presentation/pages/content_drafts_page.dart,presentation/pages/store_edit_page.dart,presentation/viewmodels/store_links_view_model.dart}`, `app/lib/core/navigation/{app_routes.dart,app_router.dart}`, `app/lib/main.dart`
- Test: `app/test/features/store_onboarding/`

**Interfaces:**
- Consumes: `cora_api`의 `analyzeMyStoreLinks`, `findMyStoreBranches`, `createMyStoreManually`, `updateMyStore` (Task 13); Task 7의 모집 조건 흐름
- Produces:
  - `SourceLinkKind.reviewPost`(입력란 이름 `체험단 후기 글 · 선택 · 인스타 게시물로 바꿔 드려요`)
  - `StoreRepository.findBranches(String name)`, `createManually(ManualStore)`
  - `abstract class ShareLauncher { Future<void> shareText(String text); }`, `shareLauncherProvider` — 구현은 `share_plus`. 테스트는 `FakeShareLauncher`.
  - 라우트: `AppRoutes.storeOnboardingManual = '/store/onboarding/manual'`

화면 문구:
- A2: 제목 `가게 링크 하나면 돼요.`, 설명 `네이버 지도, 캐치테이블, 인스타그램, 체험단 후기 글 중 무엇이든 괜찮아요. 가입 없이 먼저 볼 수 있어요.` 입력란 순서: `네이버 지도`, `캐치테이블`, `체험단 후기 글 · 선택 · 인스타 게시물로 바꿔 드려요`, `인스타그램 · 선택`. 아래 안내 `가져온 정보는 다음 화면에서 고칠 수 있어요. 공개 정보만 사용해요.` 그 옆 링크 `링크가 없거나 안 열리면 직접 입력` → F7(안내 문구 없이). 버튼 `가게 페이지 만들기`(링크가 하나라도 있으면 켜진다). 분석이 실패하면 F7로 보낸다(안내 문구와 함께). 옛 `정보를 가져오지 못했어요. 직접 입력할 수 있어요.` / `직접 입력하기`는 없앤다.
- F7: 머리 `가게 등록`, `1 / 3`. 분석 실패로 왔을 때만 안내 `링크에서 정보를 가져오지 못했어요. 아래만 채우면 계속할 수 있어요.` 입력: `가게 이름`, `지점 · 같은 이름의 가게가 {n}곳 있어요`(지점 이름과 동네를 보여 주고 하나를 고른다. 결과가 하나 이하면 줄을 숨긴다. 가게 이름 입력을 멈춘 뒤 0.5초에 찾는다), `대표 메뉴와 가격`, `가게 사진 올리기 (사용 권한이 있는 사진만)`(5MB 이하 한 장). 버튼 `가게 페이지 만들기`(이름이 있어야 켜진다) → A3.
- A3: 가게 이름 아래 `{publicUrl} · 공개 페이지`와 `공유`. 공유는 가게가 공개된 뒤에만 켜지고(등록 중에는 흐리게), 누르면 `https://{publicUrl}`을 공유 창에 넘긴다. 소개 상자의 제목 `이런 가게가 맞나요? · 탭해서 고치기`, 오른쪽 `고치기`, 내용 `#진한국물 #바좌석 #조용한오후 · 손님들이 자주 한 말: “국물이 진해요”, “혼밥하기 좋아요”. 공개 페이지에는 크리에이터 지원하기 버튼이 보여요.`(꼬리표와 자주 한 말은 가게의 값. 둘 다 없으면 `공개 페이지에는 크리에이터 지원하기 버튼이 보여요.`만) 각 항목(대표 메뉴, 영업시간, 좌석, 찍기 좋은 시간)을 누르면 옛 편집 화면이 그 항목에 맞춰 열린다. 소개 상자를 누르면 꼬리표·자주 한 말·모집 한 줄(40자)을 고치는 시트. 버튼 `AI로 직접 제작`(A4), `크리에이터 모집`(모집 조건 1단계). `정보 고치기`와 `이대로 다음`은 없앤다. 이름이나 시·도가 없으면 두 버튼을 누를 때 지금 문구(`가게 이름을 넣어 주세요.`, `가게 지역을 골라 주세요.`)를 보여 주고 편집 화면을 연다.
- A4: `다시 만들기`를 제목 줄 오른쪽으로 올린다. 버튼 `가게 계정에 올리기` → 준비 중 화면(AI 제작 계획이 만든다), `오퍼 만들기` → 등록 중이면 모집 조건 1단계, 공개된 가게면 사장님 홈의 지원자 탭(받는 사람을 골라야 A5가 열린다 — 계획 판단). 옛 `저장하고 오퍼 만들기`는 없앤다.
- 사장님 홈에서 연 가게 페이지(`/store/page`)도 같은 A3 화면이고 단계 머리글이 없다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('A2 shows the four link fields in canvas order and the new wording', ...);
testWidgets('A2 enables the button with a single link', ...);
testWidgets('A2 accepts a naver blog url as a review post', ...);
testWidgets('A2 opens manual input without the notice from the bottom link', ...);
testWidgets('A2 sends a failed analysis to manual input with the notice', ...);
testWidgets('F7 lists two branches for the sample name and picks one', ...);
testWidgets('F7 hides the branch row when at most one branch is found', ...);
testWidgets('F7 needs only the store name', ...);
testWidgets('A3 shows the public address and keeps share off until published', ...);
testWidgets('A3 shares the public address of a published store', ...);               // FakeShareLauncher
testWidgets('A3 writes the tags and customer phrases in one line', ...);
testWidgets('A3 edits a field in place from its row', ...);
testWidgets('A3 offers AI drafts and creator recruiting', ...);
testWidgets('A4 leads to the recruit terms during onboarding', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 시뮬레이터 확인** — 새 번호로 (1) 링크 등록, (2) 주소에 `fail`을 넣어 F7로, (3) A2의 `직접 입력`으로 F7을 각각 지나 A3 → 크리에이터 모집 → 공개까지 간다. 공개 뒤 가게 페이지의 `공유`가 공유 창을 여는지 본다. A2·F7·A3·A4를 `NStoreLink`·`NStoreManual`·`NStorePage`·`NStoreAI`와 라이트·다크로 비교, `shots/task14/`.
- [ ] **Step 6: Commit** — 커밋 세 개: `feat: 가게 링크 입력에 체험단 후기 글과 직접 입력 길 추가`, `feat: 매장 직접 입력 화면 추가`, `feat: 가게 페이지에 공개 주소·공유·꼬리표와 두 갈래 버튼 추가`

**완료 기준:** 테스트 통과, 시뮬레이터에서 띄워 캔버스와 라이트·다크 모두 비교.

---

### Task 15: 서버 — 7일 결과(G1)와 체험단 비교(G3)

**Files:**
- Modify: `api/prisma/schema.prisma`(+ 마이그레이션), `api/src/integrations/view-count/{view-count.port.ts,fake-view-count.adapter.ts}`, `api/src/settlements/{settlements.service.ts,settlements.repository.ts,settlements.module.ts}`, `api/src/notifications/notification-catalog.ts`, `api/src/collaborations/{collaborations-api.module.ts,collaborations.repository.ts}`, `api/src/stores/stores.service.ts`(가게의 인스타그램 아이디 읽기), `api/src/app.module.ts`
- Create: `api/src/collaborations/{store-result.controller.ts,store-result.service.ts,dto/store-result.model.ts}`, `api/src/store-insights/{store-insights.module.ts,store-insights.controller.ts,store-insights.service.ts,trial-comparison.ts,dto/trial-comparison.model.ts}`
- Test: `api/src/store-insights/trial-comparison.spec.ts`, `api/src/integrations/view-count/fake-view-count.adapter.spec.ts`(추가), `api/test/{store-result,store-insights}.e2e-spec.ts`

**Interfaces:**
- Produces:
  - `ViewCountPort.readAccountAverage(handle: string): Promise<number>`(읽지 못하면 `ViewCountUnavailableError`). 가짜 구현은 4,000, 아이디에 `unavailable`이 있으면 실패.
  - `StoresService.getInstagramHandle(storeId): Promise<string | null>` — 가게의 인스타그램 링크(`instagram.com/{아이디}`)에서 아이디를 꺼낸다.
  - `settlements`에 `usualViews Int?`, `multiplierTenths Int?`, `usualReadAt DateTime?` 추가.
  - 정산의 뒷단계(3번의 `finishSettlement` 끝. F4 묶음이 들어오면 확인 완료의 뒷단계가 된다): 정산 행의 `usualReadAt`이 비어 있으면 가게 아이디로 평소 조회수를 **한 번** 읽어 `usualViews`, `multiplierTenths = Math.floor(finalViews * 10 / usualViews)`, `usualReadAt`을 저장한다. 아이디가 없거나 읽지 못하면 `usualReadAt`만 채운다(다시 읽지 않는다). 조회수를 세지 않는 협업(`FIXED`)은 건너뛴다.
  - 사장님에게 가는 `SETTLEMENT_REFUNDED`의 가는 곳을 `'STORE_RESULT'`(id = 협업 id, G1)로 바꾼다(`NotificationTarget`에 추가). 환불이 0원이어도 G1로 가는 길이 있게, 환불 0원일 때는 `SETTLEMENT_CONFIRMED`와 같은 때에 사장님에게 `조회수 집계가 끝났어요.`만 보낸다(금액 문장 없이 — 3번 R39의 "0원 문구 금지"를 지킨다).
  - `GET /collaborations/:id/result` → 200 `StoreResultModel { creator: { userId; name; photoUrl }; format; postedAt: string; postUrl: string; views: number | null; usualViews: number | null; multiplierTenths: number | null; payout: number; refund: number; fixedCashOnly: boolean; fixedCash: number }` — **사장님(맡기는 쪽)만**. 크리에이터나 남이 요청하면 404. 협업이 `SETTLED`가 아니면 404. `operationId: getStoreResult`
  - `compareTrial(input: { trial: { monthlyFee; postCount }; collaborations: { payout: number; fee: number; format: ContentFormat; multiplierTenths: number | null }[] }): { trialSpent: number; coraSpent: number; coraCount: number; contentByFormat: { format; count }[]; averageMultiplierTenths: number | null }`(`trial-comparison.ts`, 순수) — `trialSpent = monthlyFee × 3`, `coraSpent = Σ(payout + fee)`, 평균 배수는 값이 있는 것만의 평균을 내림.
  - `GET /stores/me/trial-comparison` → 200 `TrialComparisonModel { trial: { monthlyFee; endsOn; postCount; spent }; cora: { offerCount; spent; contentByFormat; averageMultiplierTenths } }`. `STORE` 역할만. 체험단 정보가 없으면 404. Cora 칸은 오늘(한국 날짜)부터 달력으로 석 달 전까지 확정된(`SETTLED`) 내 가게 협업이다. 수수료는 그 협업의 승인된 결제의 `amountFee`. `operationId: getMyStoreTrialComparison`
  - `StoreInsightsModule`은 `StoresModule`, `CollaborationsModule`, `SettlementsModule`, `PaymentsModule`이 export한 것만 쓴다(읽기만).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('reads 4000 as the usual views of a store account', ...);
it('saves the usual views and a 3.1 multiplier once when the collaboration settles', ...);
it('sends the owner to the result screen from the settlement notice, also for a zero refund', ...);          // 12500 / 4000 → 31
it('does not read the usual views again when the first read failed', ...);
it('leaves the comparison empty for a store without an instagram link', ...);
it('shows the result to the owner with payout and refund', ...);
it('marks a fixed cash only result and leaves views empty', ...);
it('returns 404 for the result to the creator and to a stranger', ...);
it('returns 404 for the result before the collaboration is settled', ...);
it('sums three months of trial fees and the cora payouts plus fees', ...);           // 캔버스: 오퍼 4건 · 152,000원 모양
it('counts submitted content by format', ...);
it('averages only the collaborations that have a multiplier, rounded down', ...);
it('leaves out collaborations settled more than three calendar months ago', ...);
it('returns 404 for the comparison without trial info', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 사장님 7일 결과와 평소 대비 배수 추가`, `feat: 체험단과의 석 달 비교 API 추가`

**완료 기준:** 테스트 통과, Review Focus 10(G1·G3) 확인.

---

### Task 16: 서버 — 지원자 추천 3명 (G2)

**Files:**
- Create: `api/src/applications/{recommendation.ts,dto/recommended-applicants.model.ts}`
- Modify: `api/src/applications/{applications.service.ts,applications.repository.ts,applications.controller.ts,applications.module.ts}`, `api/src/collaborations/collaborations.repository.ts`(크리에이터의 마친 협업 수)
- Test: `api/src/applications/recommendation.spec.ts`, `api/test/applications.e2e-spec.ts`(추가)

**Interfaces:**
- Consumes: `RECOMMEND_POLICY` (Task 2), 지원의 `pitch`·`skippedFromPicksAt` (Task 9)
- Produces:
  - `INDUSTRY_KEYWORDS: Record<IndustryCategory, string[]>`(`recommendation.ts`) — "주로 만드는 콘텐츠"(자유 글)가 가게의 업종 분류와 맞는지 보는 낱말 표. 예: `FOOD_CAFE: ['맛집', '카페', '식당', '음식', '먹', '라멘', '디저트', '커피']`. 크리에이터의 "받고 싶은 분야"는 4번 계획이 만들면 이 판정에 더한다.
  - `scoreApplicant(a: { regionSido; regionSigungu; contentFocus; hasPitch; finishedCount }, store: { regionSido; regionSigungu; industry }): number` — 같은 구·군 3, 같은 시·도 1(구·군이 같으면 3만), 분야 맞음 2, 한 줄 1, 마친 협업 건당 1(최대 2). 팔로워 수를 받지 않는다.
  - `reasonsFor(a, store): string[]` — 점수에 쓴 사실만: `같은 동네예요`(같은 구·군), `{업종 분류 이름} 콘텐츠를 만들어요`(분야 맞음), `지난 협업을 {n}번 마쳤어요`.
  - `pickRecommended(applicants, store, limit = 3)` — 점수 높은 순, 같으면 먼저 지원한 순. 넘긴 지원은 뺀다.
  - `GET /stores/me/applications/recommended` → 200 `RecommendedApplicantsModel { totalNew: number; items: { applicationId; creator: CreatorSummaryModel; pitch: string | null; reasons: string[] }[] }`. `STORE` 역할만. `operationId: listRecommendedApplicants`. 이 라우트는 `stores/:id/applications`보다 위에 둔다.
  - `POST /stores/me/applications/:id/skip` → 204. 내 가게의 지원이 아니면 404. 지원 상태는 바꾸지 않고 `skippedFromPicksAt`만 채운다. `operationId: skipRecommendedApplicant`
  - 마친 협업 수: `CollaborationsRepository.countByCreators(creatorIds, ['SETTLED'])`.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('scores the same district above the same province', ...);
it('adds two points when the content focus matches the store industry', ...);
it('adds one point for a pitch and one per finished collaboration up to two', ...);
it('never looks at follower counts', ...);                                            // 입력 타입에 없음을 고정
it('breaks ties by the earlier application', ...);
it('writes reasons only from the facts used for the score', ...);
it('returns at most three applicants and the total of new applications', ...);
it('returns fewer than three when fewer applied', ...);
it('leaves a skipped applicant out of the picks but in the applicant list', ...);
it('returns 404 when skipping an application of another store', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 지원자 추천 3명과 추천에서 넘기기 추가`

**완료 기준:** 테스트 통과.

---

### Task 17: 서버 — 개발 시드 갱신

**목적:** 시뮬레이터에서 캔버스와 비교할 수 있게 `yarn seed:dev`가 새 캔버스의 모습을 만든다.

**Files:**
- Modify: `api/seed/lib/{mock-seed.ts,mock-seed-db.ts,seed-dev.ts}`, `api/seed/mock/mock.json`, `api/seed/README.md`
- Test: `api/seed/lib/{mock-seed.spec.ts,seed-dev.spec.ts}`, `api/test/db/{mock-seed.db-spec.ts,seed-dev.db-spec.ts}`

**Interfaces:**
- Produces(0001 가게 `한그릇 라멘` 기준): 모집 조건(식사권 40,000원·2인, 1,000회당 2,000원, 상한 60,000원, 재게시 3개월), 주소 이름 `hangeureut-ramen`, 꼬리표와 자주 한 말, 모집 한 줄 `첫 숟가락 릴스`, 체험단 정보(종료일은 시드 실행일 + 28일), 인스타그램 링크. 지원자 5명(그중 3명은 한 줄 있음 — 캔버스 G2의 세 문장). 제안함: 내가 응답할 차례 1건(크리에이터의 판본 2 역제안), 상대 대기 2건, 종료 2건(합의 완료 1, `일정이 맞지 않아 종료` 1). 확정된 협업 1건(12,500회, 지급 25,000원, 환불 35,000원, 평소 4,000회). 0003 크리에이터에게 시리즈 3개(캔버스 F6).
- 시드는 두 번 돌려도 같은 결과다(지금 규칙). 번호는 `010-0000-XXXX`만 쓴다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('seeds the sample store with the new recruit terms and a slug', ...);
it('seeds five applicants of whom three have a pitch', ...);
it('seeds one proposal waiting for the owner and two waiting for creators', ...);
it('seeds a confirmed settlement of 12500 views with a balanced ledger', ...);
it('is safe to run twice', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn test seed && yarn test:db && yarn seed:dev && yarn seed:dev && yarn check:ledger`
- [ ] **Step 5: Commit** — `chore: 개발 시드를 개정된 가게 흐름에 맞춤`

**완료 기준:** 시드를 두 번 돌려도 통과, 장부 점검 통과.

---

### Task 18: 앱 — 7일 결과(G1), 지원자 추천(G2), 체험단 비교(G3), 사장님 홈(A9)

**Files:**
- Create: `app/lib/features/store_result/{domain/{store_result.dart,store_result_repository.dart},data/api_store_result_repository.dart,presentation/{viewmodels/store_result_view_model.dart,pages/store_result_page.dart,store_result_text.dart}}`, `app/lib/features/applicant_picks/{domain,data,presentation/{viewmodels,pages/applicant_picks_page.dart}}`, `app/lib/features/trial_compare/{domain,data,presentation/{viewmodels,pages/{trial_compare_page.dart,trial_info_page.dart},trial_compare_text.dart}}`
- Modify: `app/lib/features/store_home/presentation/pages/{store_home_page.dart,store_me_page.dart}`, `app/lib/features/store_home/presentation/store_home_text.dart`, 3번 계획 Task 13이 만든 `store_collaboration_page.dart`(끝난 협업 → G1), 3번 계획 Task 13C가 만든 `notification_routes.dart`(`STORE_RESULT`), `app/lib/core/navigation/{app_routes.dart,app_router.dart}`, `app/lib/main.dart`
- Test: `app/test/features/{store_result,applicant_picks,trial_compare,store_home}/`

**Interfaces:**
- Consumes: `cora_api`의 `getStoreResult`, `listRecommendedApplicants`, `skipRecommendedApplicant`, `getMyStoreTrialComparison`, `putMyStoreTrialInfo`, `snoozeMyStoreTrialCompare`, `markMyStoreTrialHintSeen` (Task 13, 15, 16); Task 7·8의 A5·F1
- Produces:
  - `multiplierLabel(int tenths)` → `3.1배`; `usualLabel(int views)` → `평소 약 4,000회`; `resultSubtitle(result)` → `하루 한 컵 · 릴스 · 11월 4일 게시`(순수)
  - `trial_compare_text.dart`(순수): `trialSpentLine` → `월 300,000원 × 3`; `coraSpentLine` → `오퍼 4건 · 152,000원`; `contentLine(byFormat)` → `릴스 4편`(형식별로 ` + `로 잇는다); `trialEndNotice(endsOn)` → `체험단 계약이 12월 10일에 끝나요. 다시 계약하기 전에 비교해 보세요.`
  - 라우트: `/store/collaborations/:id/result`, `/store/applicants/picks`, `/store/trial-compare`, `/store/me/trial-info`

화면 문구:
- G1: 머리 `7일 결과`. `{활동 이름} · {형식} · {M}월 {D}일 게시`, 큰 숫자 `12,500회`. 상자 `우리 가게 평소 게시물 대비` / `3.1배` / `평소 약 4,000회` / 막대 `평소`, `이번`. `크리에이터 지급` / `25,000원`, `사장님께 환불` / `35,000원`. `집계 출처와 계산 보기`(→ F4) 줄은 Task 21이 더한다(이 작업에서는 그리지 않는다). 버튼 `새 오퍼`(그 크리에이터가 받는 사람인 A5), `영상 받기`(제출된 게시 링크를 외부 브라우저로 연다), `{활동 이름}과 다시 만나기`(`josa`. 지난 조건이 채워진 F1 → F2, `NewOfferTarget`).
  - 평소 값이 없으면 비교 상자를 숨긴다. 조회수 수당이 없던 협업은 큰 숫자와 비교 상자, 지급·환불 줄을 숨기고 `고정 현금 {금액}원 지급`을 보여 준다.
  - 들어오는 곳: 정산 알림(`STORE_RESULT`), 사장님 진행 화면의 끝난 협업(`7일 결과 보기` — 캔버스 밖).
- G2: 머리 `새 지원 {n}`, 오른쪽 `탐색`(찾기 탭 — 지금은 준비 중 화면). 안내 `지원한 {n}명 중 가게와 잘 맞는 3명이에요. 팔로워 수는 점수에 넣지 않아요.`(지원이 3명 이하면 `3명` 자리에 그 수). 카드: 사진(크리에이터 사진, 없으면 이름 첫 글자), `대표 릴스 · 추천 {i} / {전체}`, 큰 글자 `“{한 줄}”`(없으면 주로 만드는 콘텐츠), 이유(` · `로 잇는다), `{활동 이름} · {구·군} · 팔로워 640`(팔로워는 연동한 사람만). 버튼 `넘기기`, `좋아요하고 오퍼` → A5.
  - 다 넘기면 `CoraStateView.empty`: `추천을 모두 봤어요.` / `지원자 목록에서 나머지를 볼 수 있어요.` / `지원자 목록 보기`. 새 지원이 없으면 `아직 지원한 크리에이터가 없어요.`
- G3: 머리 `지난 3개월 비교`. `trialEndNotice`, 제목 `같은 3개월,\n무엇이 남았나요?` 두 칸 `체험단` / `Cora`:
  - `들어간 돈`: `월 {금액}원 × 3` / `오퍼 {n}건 · {금액}원`
  - `생긴 콘텐츠`: `블로그 글 {n}개` / `contentLine`(없으면 `아직 없어요`)
  - `평소 대비 반응`: `확인 어려움` / `평균 2.6배`(없으면 `아직 없어요`)
  - `누가 왔나`: `플랫폼이 선정` / `지원자 중 직접 좋아요`
  - 캔버스의 `가게 계정에 남은 것` 줄과 `가게 계정 게시물`은 AI 제작 계획이 넣는다(이 계획에서는 뺀다).
  - 아래 `체험단 금액은 사장님이 입력한 값이에요.`(캔버스의 `숫자는 가상 예시예요.`는 넣지 않는다). 버튼 `나중에`(7일 숨기고 홈으로), `다음 달은 Cora로 오퍼 보내기` → 지원자 추천(G2), 지원이 없으면 사장님 홈의 지원자 탭(A5는 받는 사람이 있어야 열린다 — 계획 판단).
- 내 가게(`store_me_page.dart`)에 `체험단 계약 정보` 줄(캔버스 밖) → 입력 화면: `월 계약 금액`, `계약 종료일`, `석 달 동안 받은 글 수`, 버튼 `저장`, 저장된 뒤에는 `지우기`.
- A9: 바로가기 세 개를 두 개로 바꾼다 — `지원자 추천` / `3명 보고 좋아요`(새 지원이 3명보다 적으면 `{n}명 보고 좋아요`, 없으면 `새 지원이 오면 알려드려요`) → G2, `이번 주 가게 게시물` / `AI 초안 {n}개 준비`(저장된 초안 수) → A4(`/store/drafts`). 그 아래 `trialBanner`가 `COMPARE`면 `체험단 계약이 한 달 남았어요 · 비교 보기` → G3, `HINT`면 `체험단 계약 정보를 넣으면 비교해 드려요.` → 입력 화면(누르거나 한 번 보이면 다시 나오지 않는다). 숫자 세 개, 탭 두 개, 줄의 모양, 하단 메뉴는 그대로다.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('writes the multiplier with one decimal place', ...);                           // 31 → '3.1배'
testWidgets('G1 shows the canvas numbers and the comparison bars', ...);
testWidgets('G1 hides the comparison without usual views', ...);
testWidgets('G1 shows only the fixed cash line for a collaboration without view pay', ...);
testWidgets('G1 opens the submitted post, a new offer and a re-offer with the past terms', ...);
testWidgets('G2 shows one pick at a time with the pitch, reasons and district', ...);
testWidgets('G2 skips a pick and shows the all seen state after the last one', ...);
testWidgets('G2 opens A5 for the liked creator', ...);
testWidgets('G2 hides followers for a creator without instagram', ...);
test('writes the trial and cora lines like the canvas', ...);
testWidgets('G3 shows four rows and only the owner input notice', ...);
testWidgets('G3 hides the home banner for seven days after later', ...);
testWidgets('saves the trial info from my store', ...);
testWidgets('A9 shows the two shortcuts with their counts', ...);
testWidgets('A9 shows the compare banner only when the server says so', ...);
testWidgets('A9 shows the trial hint once', ...);
testWidgets('a settlement notification opens the seven day result', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 시뮬레이터 확인** — `yarn seed:dev` 뒤 0001(가게)로 A9 → G2(넘기기, 좋아요하고 오퍼) → G3 → 끝난 협업의 G1을 본다. A9·G1·G2·G3를 `NStoreHome`·`NResult`·`NApplicants`·`NSwitchReport`와 라이트·다크로 비교, `shots/task18/`.
- [ ] **Step 6: Commit** — 커밋 네 개: `feat: 사장님 7일 결과 화면 추가`, `feat: 지원자 추천 화면 추가`, `feat: 체험단 비교 화면과 계약 정보 입력 추가`, `feat: 사장님 홈의 바로가기와 체험단 줄 교체`

**완료 기준:** 테스트 통과, 시뮬레이터에서 띄워 캔버스와 라이트·다크 모두 비교.

---

### Task 19: 서버 — 조회 자료 확인 (미확인, 확인, 자동 확인)

**목적:** 7일째 정산을 "계산 만들기"와 "확인 완료"로 나눈다. 확인 전에는 장부를 옮기지 않는다. **Task 19~21은 F4 묶음이다. 소유자가 F4를 미루면 셋을 함께 건너뛴다(앞의 작업은 이 묶음 없이 동작한다).**

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/settlements/{settlements.service.ts,settlements.repository.ts,settlements.module.ts,job-keys.ts}`, `api/src/jobs/job-names.ts`, `api/src/notifications/notification-catalog.ts`, `api/src/collaborations/{collaborations-api.module.ts,collaborations.service.ts,dto/collaboration.model.ts}`, 3번 계획 Task 10이 만든 `api/src/ops/ops.service.ts`(조회수로 정산하는 명령이 새 두 걸음을 한 번에 지나게), 3번 계획 Task 13B가 만든 `api/src/wallet/wallet.service.ts`(정산 행이 `UNCONFIRMED`면 `보관 중`으로)
- Create: 마이그레이션, `api/src/settlements/view-report.service.ts`, `api/src/settlements/jobs/settlement-auto-confirm.handler.ts`, `api/src/collaborations/{view-report.controller.ts,dto/view-report.model.ts}`
- Test: `api/src/settlements/view-report.service.spec.ts`, `api/test/view-report.e2e-spec.ts`, `api/test/settlements.e2e-spec.ts`(수정), `api/test/db/collaboration-schema.db-spec.ts`(추가)

**Interfaces:**
- Produces:
  - `enum SettlementStatus { UNCONFIRMED, CONFIRMED, DISPUTED }`, `enum EvidenceSource { CONNECTED_ACCOUNT, CAPTURE }`, `enum SettlementConfirmer { COMMISSIONER, AUTO, OPERATOR, NOT_NEEDED }`
  - `settlements`: `status SettlementStatus @default(CONFIRMED)`, `calculatedAt`, `confirmDueAt?`, `confirmedAt?`, `confirmedBy SettlementConfirmer?`, `evidenceSource EvidenceSource @default(CONNECTED_ACCOUNT)`, `fixedCashAmount Int @default(0)`, `viewPayAmount Int @default(0)` 추가. `settledAt`은 null을 허용한다(확인 완료 때 채운다). 옛 행 이전: `status = CONFIRMED`, `calculatedAt = confirmedAt = settledAt`, `confirmedBy = AUTO`, `viewPayAmount = payoutAmount`.
  - `settle` 처리기의 새 흐름(`settleCounting`):
    - 조회수 수당이 없는 협업(`FIXED`): Task 4대로 한 걸음에 확정한다. 정산 행은 `CONFIRMED`, `confirmedBy = NOT_NEEDED`.
    - 조회수 수당이 있는 협업: 7일째 줄 확보 → 3일 규칙 → `settleReward` → `ViewReportService.createCalculation(collaborationId)`이 **정산 행을 `UNCONFIRMED`로 만들기만 한다**(`calculatedAt = now`, `confirmDueAt = now + 48시간`). 장부, 단계, 지급·환급 행은 건드리지 않는다. 뒤에 `settlement-auto-confirm`을 `confirmDueAt`에 등록(`jobKey = 'auto-confirm:' + collaborationId`), 사장님에게 `VIEW_REPORT_REQUESTED`, 크리에이터에게 `VIEW_REPORT_READY`(`dedupeKey = 'view-report:' + collaborationId`).
  - `ViewReportService.confirm(collaborationId, by: SettlementConfirmer, key)`: 한 트랜잭션에서 정산 행 `UNCONFIRMED → CONFIRMED` 조건부 갱신(0행이면 끝) → 에스크로 잔액 검사(Task 3) → 장부 `post(postingsForSettlement, 'settle:' + collaborationId)` → 협업 `COUNTING → SETTLED` → 지급·환급 행. 뒤에 3번의 `finishSettlement`(지급 예약, 알림, PG 환급). `settledAt = confirmedAt = now`. 같은 키라 사장님 확인과 자동 확인이 겹쳐도 한 번이다.
  - `settlement-auto-confirm` 처리기: 정산 행이 `UNCONFIRMED`이고 자료 출처가 `CONNECTED_ACCOUNT`이면 `confirm(by: AUTO)`. 그 밖에는 아무 일도 하지 않는다. `JOB_NAMES`에 추가.
  - `GET /collaborations/:id/view-report` → 200 `ViewReportModel { status: 'COUNTING' | 'UNCONFIRMED' | 'CONFIRMED' | 'DISPUTED'; views: number | null; postUrl: string; periodStart: string; periodEnd: string; source: 'CONNECTED_ACCOUNT' | 'CAPTURE_PENDING' | 'CAPTURE_CONFIRMED'; calc: { viewPay; ratePerThousand; cap; capApplied: boolean; fixedCash; refund; payout } | null; confirmDueAt: string | null; canConfirm: boolean; canDispute: boolean; canUploadEvidence: boolean; evidence: { imageUrl: string; statedViews: number } | null }` — 당사자만(아니면 404). 조회수 수당이 없거나 링크 제출 전이면 404. 측정 중에는 `status: COUNTING`, `views`는 그날까지의 값, `calc: null`. `canConfirm`은 맡기는 쪽이고 `UNCONFIRMED`이고 출처가 `CONNECTED_ACCOUNT`일 때만 true. `operationId: getViewReport`
  - `POST /collaborations/:id/view-report/confirm` → 200 `ViewReportModel`. 맡기는 쪽만(크리에이터는 403). `canConfirm`이 아니면 409. `operationId: confirmViewReport`
  - `CollaborationModel`에 `viewReportStatus: 'NONE' | 'COUNTING' | 'UNCONFIRMED' | 'CONFIRMED' | 'DISPUTED'` 추가. `settlement`은 확인 완료 뒤에만 채운다(미확인 금액을 "정산"으로 보이지 않게).
  - `NotificationKind`: `VIEW_REPORT_REQUESTED`(`조회수 집계가 끝났어요. 자료를 확인해 주세요.`), `VIEW_REPORT_READY`(`조회수 집계가 끝났어요. 계산을 확인해 보세요.`). 정산 탭, 끌 수 없음, 그림 `WON`. 가는 곳 `'VIEW_REPORT'`(id = 협업 id).
  - 옛 `SETTLEMENT_REFUNDED`(`조회수 집계가 끝났어요. {금액}원을 돌려드려요.`, 가는 곳은 Task 15의 `STORE_RESULT`)와 `SETTLEMENT_CONFIRMED`, Task 15의 평소 조회수 읽기는 확인 완료 때로 옮겨 간다.
  - **뒤 계획을 위한 약속**(5·6번 계획의 브랜드 계약이 같은 메서드를 쓴다): `ViewReportService`의 `createCalculation`·`confirm`·`dispute`는 협업의 종류를 가정하지 않는다. 측정 기간의 끝은 협업의 `countingEndsAt`(7일이든 14일이든)에서 읽고, 조건은 `readTerms`로 읽고, 맡기는 쪽 알림의 `role`은 `commissionerId`의 지금 역할(`STORE` 또는 `BRAND`)로 보내고, 단계 전이는 `stage`가 `COUNTING`인 것만 본다. 이 계획의 테스트는 가게 오퍼만 덮는다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('creates an unconfirmed calculation when the counting period ends', ...);          // status UNCONFIRMED, viewPay 25000, refund 35000
it('moves no money before confirmation', ...);                                        // 장부 줄 0(정산), 협업 COUNTING, payouts 0, refunds 0
it('asks the owner to confirm and tells the creator once', ...);
it('settles when the owner confirms', ...);                                           // SETTLED, ESCROW 0, payout 25000 예약, refund 35000
it('refuses a confirmation from the creator', ...);                                   // 403
it('confirms by itself 48 hours after the calculation', ...);                         // runDue(+48h)
it('does not confirm by itself at 47 hours', ...);
it('moves money once when the owner confirm and the auto confirm run together', ...); // Promise.all
it('does nothing when the confirm job runs after the owner confirmed', ...);
it('sends the settlement notices only after confirmation', ...);
it('shows the running views and no calculation while counting', ...);
it('shows the cap as applied when the view pay hits it', ...);
it('returns 404 for a view report of a collaboration I am not part of', ...);
it('returns 404 for a view report of a collaboration without view pay', ...);
it('reports the view report status on the collaboration', ...);
it('still confirms a fixed cash only collaboration in one step', ...);
it('keeps every collaboration ledger balanced after each scenario', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현(마이그레이션) → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`. 3번의 정산 e2e 가운데 "7일 뒤 바로 SETTLED"를 기대하던 것은 "확인 뒤 SETTLED"로 고친다(기대 금액은 바꾸지 않는다).
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 정산을 계산 만들기와 확인 완료로 나눔`, `feat: 조회 자료 확인과 48시간 자동 확인 추가`

**완료 기준:** 테스트 통과, Review Focus 6·7 확인.

---

### Task 20: 서버 — 이의 제기, 캡처 제출, 운영 명령

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/settlements/{view-report.service.ts,settlements.service.ts,settlements.repository.ts,job-keys.ts}`, `api/src/collaborations/{view-report.controller.ts,collaboration-stage.ts}`, `api/src/integrations/storage/{storage.port.ts,supabase-storage.adapter.ts}`, `api/test/support/fake-storage.port.ts`, `api/src/uploads/{photo-rules.ts,uploads.service.ts}`, `api/scripts/setup-supabase.ts`, `api/src/jobs/job-names.ts`, `api/src/notifications/notification-catalog.ts`, 3번 계획 Task 10이 만든 `api/src/ops/{ops.service.ts,commands/}`, `README.md`(운영 명령 목록)
- Create: 마이그레이션, `api/src/settlements/jobs/evidence-missing-halt.handler.ts`, `api/src/collaborations/dto/{dispute-view-report.dto.ts,submit-view-evidence.dto.ts}`, `api/src/ops/commands/{confirm-evidence.command.ts,resolve-dispute.command.ts}`
- Test: `api/test/view-report.e2e-spec.ts`(추가), `api/test/settlements.e2e-spec.ts`(수정), `api/test/ops.e2e-spec.ts`(추가), `api/test/uploads.e2e-spec.ts`(추가)

**Interfaces:**
- Produces:
  - `ViewEvidence` → `view_evidences`: `collaborationId`, `filePath`, `statedViews Int`, `submittedById`, `confirmedAt?`, `confirmedBy String?`. 인덱스 `(collaborationId)`. RLS.
  - `SettlementDispute` → `settlement_disputes`: `collaborationId`, `raisedById`, `reason`(200자), `resolvedAt?`, `resolution String?`(`UPHELD_AS_IS` | `VIEWS_CORRECTED`), `resolvedViews Int?`. 유일 제약 `(collaborationId, raisedById)`(한 사람이 한 번). RLS.
  - `StoragePort`: `PRIVATE_BUCKET = 'evidence'`, `createUploadUrl(path, bucket?)`, `signedReadUrl(path, ttlSeconds): Promise<string>`(비공개 버킷). `yarn setup:supabase`가 비공개 버킷을 만든다. `PHOTO_PURPOSES`에 `VIEW_EVIDENCE`(크리에이터, 폴더 `evidence/{userId}/`, 비공개 버킷, 5MB).
  - 멈춤 사유 `SETTLEMENT_DISPUTED`(`job-keys.ts`의 `VIEW_COUNT_HALT_REASON` 옆).
  - `POST /collaborations/:id/view-report/dispute` 본문 `{ reason: string(1~200자) }` → 200 `ViewReportModel`. 당사자 누구나, 정산 행이 `UNCONFIRMED`일 때만, 한 사람이 한 번. 한 트랜잭션: 정산 행 `UNCONFIRMED → DISPUTED` 조건부 갱신(0행이면 409) → 이의 행 → 협업 `COUNTING → HALTED`(`stageBeforeHalt = COUNTING`, `haltedReason = SETTLEMENT_DISPUTED`). 뒤에: 자동 확인 작업 취소, `OperatorAlertPort.alert`(`조회 자료에 이의가 제기됐어요. 확인해 주세요.`, 협업 id — 사유 글은 넣지 않는다), 상대에게 `VIEW_REPORT_DISPUTED`. `operationId: disputeViewReport`
  - 3일 규칙의 변경(`settlements.service.ts`): 최근 3일을 연속으로 읽지 못해도 **멈추지 않는다.** 대신 크리에이터에게 `VIEW_EVIDENCE_REQUESTED`를 보낸다(`dedupeKey = 'evidence-request:' + collaborationId`).
  - `POST /collaborations/:id/view-evidence` 본문 `{ path: string; views: number(0 이상 정수) }` → 200 `ViewReportModel`. 크리에이터만. 받는 때: 캡처가 요청됐고(최근 3일 연속 읽지 못함) 정산 행이 없거나, 캡처를 기다리는 중일 때. `assertOwnedPath(…, 'VIEW_EVIDENCE')`. 측정 기간이 이미 끝났으면 그 자리에서 계산을 만든다(아래). `operationId: submitViewEvidence`
  - 측정 기간이 끝난 날(`settleCounting`)의 갈림:
    - 7일째 값을 읽었거나 3일 규칙에 걸리지 않음 → Task 19대로(`CONNECTED_ACCOUNT`).
    - 3일 규칙에 걸렸고 캡처가 있음 → 캡처의 조회수로 계산을 만든다. `UNCONFIRMED`, `evidenceSource = CAPTURE`, `confirmDueAt = null`, **자동 확인 작업을 올리지 않는다.** 운영자에게 `조회수 캡처가 제출됐어요. 확인해 주세요.` 알림.
    - 3일 규칙에 걸렸고 캡처가 없음 → 계산을 만들지 않고 `evidence-missing-halt`를 `countingEndsAt + 3일`에 등록(`jobKey = 'evidence-halt:' + collaborationId`).
  - `evidence-missing-halt` 처리기: 그때까지 캡처가 없으면 3번의 멈춤 길(`halt`, 사유 `VIEW_COUNT_UNAVAILABLE`, 운영자 알림)로 간다. 캡처가 있으면 아무 일도 하지 않는다. `JOB_NAMES`에 추가.
  - `view-report` 응답의 `source`: 캡처가 쓰였고 운영자가 확인 전이면 `CAPTURE_PENDING`, 확인했으면 `CAPTURE_CONFIRMED`. `evidence.imageUrl`은 `signedReadUrl`(10분). `canUploadEvidence`는 크리에이터이고 캡처가 요청됐고 아직 캡처가 없을 때.
  - 운영 명령(3번의 규칙대로 `--operator`, `--reason` 필수, 감사 기록, 끝에 `assertBalanced`):
    - `yarn ops confirm-evidence --collaboration <id>` — 캡처 출처의 `UNCONFIRMED` 정산을 확인 완료로(`confirm(by: OPERATOR)`), 캡처 행에 확인 표시.
    - `yarn ops resolve-dispute --collaboration <id> [--views <n>]` — `DISPUTED` 정산을 `--views`가 있으면 그 조회수로 다시 계산해, 없으면 그대로 확정한다. 협업 `HALTED → SETTLED`, 이의 행에 결과. 장부·지급·환급은 `confirm`과 같은 길.
    - `yarn ops show`가 정산 상태, 자료 출처, 이의 사유를 함께 보인다.
  - `NotificationKind`: `VIEW_EVIDENCE_REQUESTED`(`조회수를 읽지 못했어요. 인사이트 캡처를 올려 주세요.`), `VIEW_REPORT_DISPUTED`(`조회 자료에 이의가 제기됐어요. 운영팀이 확인하고 연락드릴게요.`). 정산 탭, 끌 수 없음. 가는 곳 `'VIEW_REPORT'`.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('halts the collaboration and keeps the money when a party disputes', ...);         // HALTED, 장부 줄 0, 사유 SETTLEMENT_DISPUTED
it('cancels the auto confirm once disputed', ...);                                    // +48h runDue 뒤에도 DISPUTED
it('lets only one of a concurrent dispute and auto confirm win', ...);
it('refuses a second dispute from the same person and a dispute after confirmation', ...);
it('alerts the operator without the dispute text', ...);
it('asks the creator for a capture after three unreadable days instead of halting', ...); // 협업 COUNTING, 알림 1건
it('calculates from the capture when the period ends and waits for the operator', ...);   // UNCONFIRMED, source CAPTURE, 작업 없음
it('does not confirm a capture based calculation by the owner or by time', ...);     // 409, +48h 뒤에도 UNCONFIRMED
it('halts three days after the period ends when no capture arrived', ...);
it('uses the connected account value when day seven can be read after all', ...);
it('refuses a capture from the owner and a capture path that is not mine', ...);
it('puts the capture in the private bucket and signs the read url only for the parties', ...);
it('confirms a capture with the ops command and settles', ...);
it('resolves a dispute with corrected views and settles with the new amounts', ...);  // --views 10000 → 20000 / 40000
it('resolves a dispute as it stands when no views are given', ...);
it('leaves the ledger balanced after every command', ...);
```

- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 비공개 버킷 만들기** — `cd api && yarn setup:supabase`. `SUPABASE_SERVICE_ROLE_KEY`가 비어 실패하면 멈추고 소유자에게 그 키가 필요하다고 알린다(소유자 준비 확인). 비밀 파일은 열지 않는다.
- [ ] **Step 4: 구현(마이그레이션, 새 테이블 2개의 RLS), 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db && yarn build && yarn ops show --collaboration <테스트로 만든 id>`
- [ ] **Step 5: gen-api, README, Commit** — 커밋 세 개: `feat: 조회 자료 이의 제기 추가`, `feat: 조회수 캡처 제출과 비공개 보관 추가`, `feat: 캡처 확인과 이의 처리 운영 명령 추가`

**완료 기준:** 테스트 통과, Review Focus 8·9 확인, 3번의 "3일 연속 실패 → 멈춤" 테스트가 "캡처 요청 → 기한 뒤 멈춤"으로 바뀌어 통과.

---

### Task 21: 앱 — 성과 확인(F4), 캡처 올리기, A7·G1에서 가는 길

**Files:**
- Create: `app/lib/features/view_report/domain/{view_report.dart,view_report_repository.dart}`, `data/api_view_report_repository.dart`, `presentation/viewmodels/view_report_view_model.dart`, `presentation/pages/{view_report_page.dart,view_evidence_page.dart}`, `presentation/widgets/dispute_sheet.dart`, `presentation/view_report_text.dart`
- Modify: `app/lib/features/collaboration/{domain/collaboration.dart,data/api_collaboration_repository.dart,presentation/pages/collaboration_page.dart}`, Task 18이 만든 `app/lib/features/store_result/presentation/pages/store_result_page.dart`, 3번 계획 Task 13이 만든 `app/lib/features/collaboration/presentation/pages/store_collaboration_page.dart`, 3번 계획 Task 13C가 만든 `notification_routes.dart`(`VIEW_REPORT`), `app/lib/core/network/photo_uploader.dart`(용도 `VIEW_EVIDENCE`), `app/lib/core/navigation/{app_routes.dart,app_router.dart}`, `app/lib/main.dart`
- Test: `app/test/features/view_report/`, `app/test/features/collaboration/`, `app/test/features/store_result/`(추가)

**Interfaces:**
- Consumes: `cora_api`의 `getViewReport`, `confirmViewReport`, `disputeViewReport`, `submitViewEvidence` (Task 19, 20)
- Produces:
  - `abstract class ViewReportRepository { Future<ViewReport> fetch(String collaborationId); Future<ViewReport> confirm(String id); Future<ViewReport> dispute(String id, String reason); Future<ViewReport> submitEvidence(String id, String path, int views); }`
  - `view_report_text.dart`(순수): `statusLabel` → `집계 중` / `미확인` / `확인 완료` / `이의 제기됨`; `periodLabel(start, end)` → `11월 4일 – 11월 10일 (7일)`; `sourceLabel` → `연결 계정` / `캡처 제출 · 확인 중` / `캡처 제출 · 확인됨`; `viewPayFormula(calc, views)` → `12,500회 × 1,000회당 2,000원 = 25,000원`; `capLine(calc)` → `60,000원 · 상한 안` / `60,000원 · 상한 적용`
  - 라우트: `/creator/collaborations/:id/report`, `/creator/collaborations/:id/evidence`, `/store/collaborations/:id/report`

화면 문구:
- A7: 두 칸 아래에 줄 `조회 자료와 보상 계산 확인`과 표지(`집계 중` / `미확인` / `확인 완료` / `이의 제기됨`) → F4. 이 줄은 `viewReportStatus`가 `NONE`이 아닐 때만 보인다. 사장님 진행 화면에도 같은 줄을 둔다. 미확인인 동안 `지금 받을 금액`은 계산된 지급 예정액이다.
- G1(Task 18): `집계 출처와 계산 보기` 줄을 더해 F4로 잇는다.
- F4: 머리 `성과 확인`. 위 상자 `조회 자료`, 표지, `{조회수}회`. 줄 `게시물`(링크, 누르면 외부 브라우저), `측정 기간`, `자료 출처`. `보상 계산`: `조회수 수당` / 계산식, `1인 상한` / `capLine`, (고정 현금이 있으면) `고정 현금` / 금액, `사장님께 환불` / 금액, `크리에이터 지급 예정` / 금액(합계). 측정 중에는 계산 상자 자리에 `집계가 끝나면 계산해요.`
  - 안내 `자료가 확인되기 전에는 0원이나 지급 완료로 처리하지 않아요. 지급 방식(직접 지급 기록 또는 Cora 보관)은 아직 정하는 중이에요.`(캔버스 그대로. 구현은 Cora 보관 하나다 — 공통 규칙 2장)
  - 버튼: 맡기는 쪽 `이의 제기`, `자료 확인했어요`(`canConfirm`일 때). 크리에이터 `이의 제기`만. 확인 완료나 이의 제기 뒤에는 두 버튼이 없다. `canUploadEvidence`면 크리에이터에게 `캡처 올리기`.
  - `이의 제기`: 시트 — 사유 입력(200자), `이의를 제기하면 운영팀이 확인할 때까지 지급이 멈춰요.`(캔버스 밖), `제기하기`.
  - 캡처 올리기(캔버스 밖 화면): 제목 `인사이트 화면을\n캡처해 올려 주세요`, 사진 한 장(5MB), `조회수`(숫자), 버튼 `올리기`. 올린 뒤 F4의 자료 출처가 `캡처 제출 · 확인 중`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('writes the period, source, formula and cap lines like the canvas', ...);
testWidgets('A7 shows the report row with its badge only for view pay after submission', ...);
testWidgets('F4 shows the canvas numbers for an unconfirmed report', ...);           // 12,500회, 25,000원, 35,000원
testWidgets('F4 shows the placeholder instead of the calculation while counting', ...);
testWidgets('F4 lets the owner confirm and then hides both buttons', ...);
testWidgets('F4 gives the creator only the dispute button', ...);
testWidgets('F4 sends a dispute with a reason of at most 200 characters', ...);
testWidgets('F4 offers the capture upload when the server asks for it', ...);
testWidgets('uploads a capture with a view count and shows it as pending', ...);
testWidgets('the store progress screen opens the same report', ...);
testWidgets('G1 opens the report from the source and calculation row', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: 시뮬레이터 확인** — 두 계정으로 결제 → 링크 제출(`?views=12500`) → 서버를 7일 뒤로(`FAKE_CLOCK_OFFSET_DAYS=7`) → F4 미확인 → 사장님 확인. 별도 협업으로 `unavailable` 링크 → 3일 뒤 캡처 요청 → 캡처 올리기. A7·F4를 `NEscrow`·`NMetrics`와 라이트·다크로 비교, `shots/task21/`(F4 머리의 "안" 표시는 만들지 않는다).
- [ ] **Step 6: Commit** — 커밋 두 개: `feat: 성과 확인 화면과 이의 제기 추가`, `feat: 조회수 캡처 올리기 화면 추가`

**완료 기준:** 테스트 통과, 시뮬레이터에서 띄워 캔버스와 라이트·다크 모두 비교.

---

### Task 22: 전체 흐름 확인과 마지막 검토

**Files:** 없음 (확인만. 고칠 것이 나오면 해당 작업의 파일을 고치고 `fix:` 커밋)

- [ ] **Step 1: 자동 확인**

Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db && yarn check:ledger`
Run: `cd app && flutter analyze && flutter test`
Run: `./scripts/gen-api.sh && git status --short` — Expected: 변경 없음
Run: `grep -rn "perViewAmount\|RewardType\|CoraErrorView" api/src app/lib` — Expected: `reward-terms.ts`의 옛 사본 읽기와 `features/demo/`뿐

- [ ] **Step 2: 두 계정으로 수동 확인** (F4 묶음을 미뤘으면 9번은 "7일 뒤 바로 정산되고 A의 알림에서 G1이 열린다"로 바꿔 확인하고 11~13번은 건너뛴다. iPhone 15 Pro 시뮬레이터. 계정 A 가게는 새 번호 `010-0000-0061`, B 크리에이터는 `010-0000-0062`. 날짜는 `FAKE_CLOCK_OFFSET_DAYS=<n>`으로 서버를 다시 띄워 건너뛴다.)

1. A: A2에 네이버 지도 링크와 후기 글 링크 → A3에 `cora.page/l/hangeureut-ramen`과 꼬리표 → `크리에이터 모집` → 형식 → F1(`60,000원`) → F2(`공개 모집`) → `이 조건으로 공개하기` → 사장님 홈.
2. 새 번호로: A2에서 `fail` 주소 → F7 안내 문구와 지점 두 곳 → A3. 또 새 번호로: A2의 `직접 입력` → F7(안내 없음).
3. B: 가게 상세에 한 줄을 쓰고 `조건 그대로 지원` → A의 A9 `지원자 추천` → G2에 한 줄이 큰 글자로 → `좋아요하고 오퍼` → A5(`제공 혜택 + 조회수 수당 · 추천`) → F2(`판본 1로`) → 보내기 → 제안함 `상대 대기`.
4. B: A6 카드의 새 문구 → 가게 상세 → `내 방식으로 제안` → F6(시리즈 추가, 희망 보상에 고정 현금 3만 원, `가게 부담 +30,000원`) → F2(`판본 2로`) → 보내기.
5. A: 알림 `…님이 조건을 바꿔 제안했어요.` → 제안 상세(바뀐 줄 표시) → `고쳐서 다시 보내기` → F1 → F2(`판본 3으로`).
6. B: 판본 2 화면을 띄워 둔 채 수락 → F8 `이전 판본이라 수락할 수 없어요` → `판본 3 보기` → `이 판본 수락`.
7. A: 결제(A8)에 고정 현금 줄과 합계 = 최대 현금 부담 + 수수료 → 가짜 결제창 승인.
8. B: A7 → 링크 `https://www.instagram.com/reel/abc?views=12500` 제출 → `조회 자료와 보상 계산 확인 · 집계 중`.
9. 서버를 7일 뒤로 → A·B 알림 → F4 `미확인`, `12,500회 × 1,000회당 2,000원 = 25,000원` → `yarn ops show`로 `ESCROW`가 그대로인지 확인 → A가 `자료 확인했어요` → `확인 완료`, `ESCROW 0`.
10. A: 알림 → G1 `3.1배`(가게에 인스타그램 링크가 있을 때), `영상 받기`, `다시 만나기`.
11. 새 협업으로: 7일 뒤 아무도 누르지 않고 48시간을 더 건너뛴다 → 자동으로 `확인 완료`.
12. 새 협업으로: F4에서 B가 `이의 제기` → 양쪽에 멈춤 표시, 운영자 알림 로그 → `yarn ops resolve-dispute --collaboration <id> --views 10000 --operator … --reason …` → 지급 20,000원.
13. 새 협업으로: 링크에 `unavailable` → 3일 뒤 B에게 캡처 요청 → 캡처 올리기 → 7일 뒤 F4 `캡처 제출 · 확인 중`, A의 확인 버튼 없음 → `yarn ops confirm-evidence` → `캡처 제출 · 확인됨`.
14. 고정 현금만 있는 오퍼: 결제 → 링크 제출 → 7일 뒤 확인 없이 `SETTLED`, 지급 = 고정 현금. 식사권만 있는 오퍼: 결제 없이 링크 제출로 끝.
15. A: 내 가게에서 체험단 정보 입력(종료일 20일 뒤) → 홈의 줄 → G3 → `나중에` → 줄이 사라짐.
16. A: 제안 상세에서 `제안 종료`(사유 `일정이 맞지 않아요`) → 제안함 종료 탭 `일정이 맞지 않아 종료`, B에게 종료 알림.
17. 개정 전에 만들어진 협업(시드나 3번 수동 확인에서 남은 것) 하나를 열어 금액이 그대로인지 본다.
18. 다크 모드와 글자 크기 1.3배에서 1~10을 훑어본다.
19. 캔버스 19개 화면을 라이트·다크로 나란히 놓고 비교한다(각 화면 작업의 스크린샷을 다시 찍어 `shots/final/`).

- [ ] **Step 3: 장부와 이전 재확인** — `yarn check:ledger`, `yarn check:reward-migration --after`. Expected: 모두 통과.
- [ ] **Step 4: 마지막 검토** — 서버와 앱을 나눠 검토 에이전트 둘에게 이 계획의 시작 커밋부터의 diff를 준다(결론을 주지 않는다). 서버 검토는 Review Focus 11개와 보안 기준(`wiki/patterns/security-baseline.md` — 권한, 업로드, 비공개 파일, 돈)을, 앱 검토는 문구가 설계·캔버스와 글자 그대로인지와 토큰 밖의 색·모양이 없는지를 본다. Critical·Important는 고치고 다시 검토받는다.
- [ ] **Step 5: 소유자 확인 목록 만들기** — 진행 기록에 모은다: (1) 설계 6장의 일곱 항목과 지금 값, (2) F4 묶음을 실행했는지 미뤘는지와 그 이유, (2-1) 캔버스 밖 화면과 문구(제안 상세, 캡처 올리기, 체험단 정보 입력, `바뀜` 표지, `제안을 보냈어요.`, `사장님의 답을 기다리고 있어요.`, `판본은 10개까지 낼 수 있어요.`, `이미 진행 중인 제안이 있어요.`, `받은 제안은 종료로 끝내 주세요.`, 이의 제기 시트의 문구, `후기 글 찾음`, `직접 입력` 알약, `7일 결과 보기`, 제안함의 빈 상태 문구), (3) 아래 "설계와 다르게 정한 것", (4) 새 패키지 `share_plus`.
- [ ] **Step 6: push** — 소유자 승인을 받은 뒤 `git push origin main`을 한 번 한다.

---

## 완료 기준

- Task 22의 자동 확인, 수동 확인 19개, 장부 점검, 이전 재확인이 통과한다.
- 설계 1장의 "실패로 보는 것" 네 가지가 각각 테스트로 막혀 있다: 옛 판본 수락(Task 5·6), 최대 현금 부담보다 큰 결제(Task 3·4), 확인 전의 돈 이동과 0원 종료(Task 19·20), 옛 협업의 금액 변경(Task 2·3).
- 운영 환경 모드에서 가짜 어댑터가 있으면 서버가 시작을 거부하는 것은 그대로다(새 `_ADAPTER` 환경변수는 없다).

## 이 계획이 하지 않는 것

- A1 "등록 없이 먼저 둘러보기"(4번 계획이 발견 화면과 함께 만든다), B6의 문구 한 줄(7번 계획)
- F5 AI 제작 주문, "가게 계정에 올리기", 매주 자동 초안, G3의 `가게 계정 게시물`·`AI 게시물`(AI 제작 계획)
- `cora.page` 주소로 열리는 실제 웹 페이지(출시 준비 계획). 여기서는 주소 이름과 공유까지다.
- 브랜드가 쓰는 F1·F2·F3(4~6번 계획). 이 계획의 `ProposalTarget`과 제안함은 가게 오퍼만 다룬다.
- **크리에이터의 "피하는 업종" 필터를 F6에 거는 것.** 지금 코드에는 크리에이터의 협업 원칙(피하는 업종, 받고 싶은 분야)이 없다. 4번 계획이 원칙과 공통 필터를 만들 때 `POST /stores/:id/proposals`와 판본 내기에 건다.
- G2 이유의 "가게 사진과 분위기가 비슷해요", "평균 2시간 안에 답장", "걸어서 8분"(설계 6장 3번)
- 실제 링크 분석, 실제 조회수 읽기, 캡처의 자동 판독(9번 계획)

## 설계 문서에서 이 계획이 구체화한 것

설계 7장이 맡긴 것:

- `SettlementMethod`에 더한 값의 이름은 `FIXED_AND_PER_VIEW`다.
- 옛 오퍼의 보상 사본은 마이그레이션의 직접 SQL로 판본 1(쓴 쪽 가게)이 된다. 두 단계로 옮긴다: Task 3이 세 요소로, Task 5가 판본으로.
- F1과 F2는 화면 하나씩이고 `ProposalTarget`(모집 조건, 새 오퍼, 다시 보내기, 역제안)을 인자로 받는다.
- 제안 상세와 캡처 올리기는 F2·링크 제출 화면의 배치와 공용 위젯을 따른다.

설계와 다르게 정했거나 설계에 없어 정한 것(Task 22의 소유자 확인 목록에 넣는다):

- **`GET /config`가 아직 없다.** 설계 5장은 "`GET /config`에 더한다"고 했지만 그 엔드포인트는 보류된 8번 계획이 만들 예정이었다. 이 계획의 Task 4가 `app-config` 모듈을 처음 만들고, 8번 계획은 값을 더하는 쪽으로 바뀐다.
- **고정 현금의 선택지.** 설계는 없음·1만·3만·5만·직접 입력, 캔버스 F1은 없음·3만·5만·10만이다. 캔버스의 네 개에 `직접 입력`을 더했다.
- **고정 현금만 있는 협업의 G1.** 공통 규칙 2장대로 조회수를 세지 않으므로 G1에 조회수와 비교 상자가 없다(설계 G1은 지급·환불 줄만 바꾼다고 적었다).
- **옛 가게의 기본 단가.** 옛 값(1,000회당 10,000원)은 새 범위 밖이라, 가게의 기본값은 새 기본값(2,000원·60,000원)으로 옮긴다. 이미 보낸 오퍼와 협업의 값은 그대로다.
- **옛 오퍼·협업의 사용권**은 `사용 안 함`으로 옮긴다(그때는 사용권 합의가 없었다).
- **식사권의 인원.** 옛 이름 `2인 식사권`은 이름 `식사권`·인원 2로 옮기고, 사장님이 고친 다른 이름은 인원 없이 둔다.
- **주소 이름**은 한글을 로마자로 옮겨 만든다(캔버스의 `hangeureut-ramen`). 이름이 처음 생길 때 만들고, 개정 전의 가게는 읽을 때 채운다.
- **캡처 파일**은 비공개 버킷 `evidence`에 둔다(지금 버킷 `photos`는 공개 읽기다). `yarn setup:supabase`가 만든다.
- **정산 행의 모양.** 설계 5장의 "확인 기한, 자료 출처, 고정 현금 지급액, 평소 대비 배수"에 더해 계산 시각·확인 시각·확인한 쪽을 두고, 배수는 소수 대신 10배 한 정수(`multiplierTenths`)로 저장한다.
- **분야 판정.** 크리에이터의 "받고 싶은 분야"가 아직 없어 "주로 만드는 콘텐츠"(자유 글)를 낱말 표로 가게의 업종 분류에 맞춘다.
- **"새 오퍼"(G1)와 "다음 달은 Cora로 오퍼 보내기"(G3)의 받는 사람.** A5는 받는 사람이 있어야 열리므로 G1은 그 크리에이터에게, G3은 지원자 추천(G2)으로 보낸다. 공개된 가게의 A4 `오퍼 만들기`도 같은 이유로 지원자 탭으로 보낸다.
- **A6의 30초 되돌리기 거절**은 차례가 크리에이터일 때만 남기고, 제안 상세의 `거절`·`제안 종료`·`제안 취소`는 사유를 고르는 종료(되돌리기 없음)로 통일했다.
- **알림의 탭과 스위치.** 제안 알림 넷은 매칭 탭·"새 오퍼와 제안" 스위치, 조회 자료 알림 넷은 정산 탭·끌 수 없음으로 뒀다.
- **석 달**은 한국 날짜 기준 달력 석 달이다.
- **F4 묶음을 뒤로 뺐다.** 설계 6장 8번에 따라 조회 자료 확인·이의 제기·캡처(Task 19~21)를 맨 뒤에 묶었고, G1의 `집계 출처와 계산 보기` 줄과 A7의 확인 줄도 그 묶음이 더한다. A8·A7의 금액 문구는 F4와 상관없어 Task 8로 옮겼다.
- **환불이 0원인 정산의 사장님 알림.** 3번은 0원이면 알림을 보내지 않지만(R39), G1로 가는 길이 필요해 금액 문장 없는 `조회수 집계가 끝났어요.`를 보낸다.

## Interfaces — 뒤 계획이 쓰는 이름

4·5·6번 계획과 AI 제작 계획(`plans/2026-11-12-ai-production.md`)이 이 계획에 기댄다. 아래 이름과 모양을 바꾸면 그 계획들도 함께 고쳐야 한다. 괄호는 만드는 작업이다.

### 서버

| 이름 | 있는 곳 | 모양 |
|---|---|---|
| 정책 값 (Task 2) | `api/src/common/collaboration-policy.ts` | `REWARD_POLICY`(`fixedCash.maxByCommissioner.{STORE,BRAND}` 포함), `PROPOSAL_POLICY`, `VIEW_REPORT_POLICY`, `STORE_PAGE_POLICY`, `RECOMMEND_POLICY` |
| 보상 만들기 (Task 2) | `api/src/stores/reward-terms.ts` | `buildReward(input: RewardInput, opts: { format: ContentFormat; commissioner?: 'STORE' \| 'BRAND'; defaults?: Partial<RewardTerms> }): RewardTerms` |
| 최대 현금 부담 (Task 2) | 같은 파일 | `maxCashBurden(r: { fixedCash: number; perViewCap: number \| null }): number` |
| 정산 방식 (Task 2) | 같은 파일 | `settlementMethodOfReward(r): 'NONE' \| 'FIXED' \| 'PER_VIEW' \| 'FIXED_AND_PER_VIEW'`, `hasViewPay(r): boolean` |
| 조건 사본 읽기 (Task 3) | 같은 파일 | `buildTerms(input: { format; reward: RewardInput; usageRights? }, defaults?): OfferTermsModel`, `readTerms(json: unknown): OfferTermsModel` |
| 정산 계산 (Task 2) | `api/src/settlements/settlement-math.ts` | `settleReward(p: { views; ratePerThousand; cap; fixedCash }): { viewPay; payout; refund; capApplied }`, `feeFor(escrow, feeRate)`(3번 그대로) |
| 조건 모델 (Task 3) | `api/src/stores/dto/offer-terms.model.ts`, `reward-input.dto.ts` | `OfferTermsModel { format; pieces; voucherName; voucherValue; voucherPeople; fixedCash; viewRatePerThousand; perViewCap; usageRights; maxCashBurden; settlementMethod }`, `RewardInputDto { voucher?; fixedCash?; perView? }`, enum `UsageRights` |
| 앱 설정 (Task 4) | `api/src/app-config/` | `GET /config`(`getAppConfig`, 로그인 없이) → `AppConfigModel { reward; feeRates: { storeOffer; bid; brandContract } }`. 뒤 계획은 `AppConfigModel`에 필드를 **더한다**(8번의 `minSupportedVersion` 등, 9번의 약관 버전) |
| 옛 판본 오류 (Task 5) | `api/src/common/errors/app-error.ts` | `new AppError('STALE_VERSION', '이전 판본이라 수락할 수 없어요.', { latestVersion })` → 409. 브랜드 계약의 조건 버전 확인(5번)도 같은 코드를 쓴다 |
| 판본 규칙 (Task 5, 11) | `api/src/offers/proposal-rules.ts` | `turnAfter(author)`, `changedFields(prev, next)`, `proposalGroup(offer, me, now)`, `endKind(offer, now)`, enum `OfferParty`, `OfferEndReason` |
| 판본 모델 (Task 5) | `api/src/offers/dto/offer-version.model.ts` | `OfferVersionModel { number; authorParty; terms: OfferTermsModel; idea; principles; series; createdAt }` |
| 제안함 (Task 11) | `api/src/offers/proposals.controller.ts` | `GET /offers/proposals?tab=active\|ended` → `ProposalRowModel[]`, `GET /offers/:id` → `ProposalDetailModel`. 5번 계획이 브랜드의 줄(캠페인 협업의 조건 버전)을 같은 `ProposalRowModel` 모양으로 더한다 |
| 시리즈 (Task 9) | `api/src/creators/` | `creator_series` 테이블, `GET /creators/me/series`, `POST /creators/me/series` → `CreatorSeriesModel { id; name; format; note }`. 7번 계획(포트폴리오)이 프로필 화면에서 같은 것을 쓴다 |
| 조회 자료 확인 (Task 19, 20) | `api/src/settlements/view-report.service.ts`(`SettlementsModule`이 export) | `createCalculation(collaborationId): Promise<void>`(측정 기간이 끝난 협업의 계산을 `UNCONFIRMED`로 만든다), `confirm(collaborationId, by: 'COMMISSIONER' \| 'AUTO' \| 'OPERATOR' \| 'NOT_NEEDED', key: string): Promise<'confirmed' \| 'already'>`(**정산 확정** — 장부, `COUNTING → SETTLED`, 지급·환급), `dispute(collaborationId, userId, reason)`. 협업의 종류와 측정 기간(7일·14일)을 가정하지 않고 `countingEndsAt`과 조건 사본을 읽으며, 맡기는 쪽이 브랜드여도 받는다. F4 묶음을 미룬 동안 뒤 계획은 3번의 `SettlementsService.settle(collaborationId, key)`을 쓴다 |
| 조회 자료 API (Task 19, 20) | `api/src/collaborations/view-report.controller.ts` | `GET /collaborations/:id/view-report` → `ViewReportModel`, `POST …/view-report/confirm`, `POST …/view-report/dispute`, `POST /collaborations/:id/view-evidence` |
| 비공개 파일 (Task 20) | `api/src/integrations/storage/storage.port.ts` | `PRIVATE_BUCKET`, `createUploadUrl(path, bucket?)`, `signedReadUrl(path, ttlSeconds)` |
| 평소 조회수 (Task 15) | `api/src/integrations/view-count/view-count.port.ts` | `readAccountAverage(handle: string): Promise<number>` |
| 알림 종류와 가는 곳 | `notification-catalog.ts` | 종류: `OFFER_COUNTERED`, `OFFER_REVISED`, `OFFER_ACCEPTED_BY_STORE`, `OFFER_ENDED`(Task 6), `VIEW_REPORT_REQUESTED`, `VIEW_REPORT_READY`(Task 19), `VIEW_EVIDENCE_REQUESTED`, `VIEW_REPORT_DISPUTED`(Task 20). 가는 곳: `PROPOSAL`(Task 6), `STORE_RESULT`(Task 15), `VIEW_REPORT`(Task 19) |
| 작업 이름 | `api/src/jobs/job-names.ts` | `offer-response-expiry`(Task 6), `settlement-auto-confirm`(Task 19), `evidence-missing-halt`(Task 20) |

### 앱

| 이름 | 있는 곳 | 모양 |
|---|---|---|
| F8 공용 위젯 (Task 1) | `app/lib/core/ui/cora_state_view.dart` | `CoraStateView.loading()`, `.loadFailed(onRetry:)`, `.empty(title:, description:, actionLabel:, onAction:)`, `.allSeen(onOpenSaved:)`, `.staleVersion(version:, onOpen:)` |
| 서버 설정 (Task 7) | `app/lib/features/server_config/` | `serverConfigViewModelProvider` → `ServerConfig { RewardLimits reward; FeeRates feeRates }` |
| 조건 도메인 (Task 7) | `app/lib/features/offer_terms/domain/offer_terms.dart` | `OfferTerms { format; pieces; Reward reward; UsageRights usageRights }`, `Reward { Voucher? voucher; int fixedCash; ViewPay? viewPay; int get maxCashBurden }` |
| 제안의 대상 (Task 7) | `app/lib/features/offer_terms/domain/proposal_draft.dart` | `sealed class ProposalTarget` — `RecruitTarget`, `NewOfferTarget`, `ReplyTarget`, `CounterTarget`. 4·5번 계획이 브랜드용 대상을 더한다 |
| F1, F2 (Task 7) | `app/lib/features/offer_terms/presentation/pages/` | `RewardBudgetPage(target)`, `ReviewSendPage(target, onSend)`. 고정 현금의 최대값은 대상의 맡기는 쪽 종류로 서버 설정에서 읽는다 |
| 보상 편집 위젯 (Task 7) | `app/lib/features/offer_terms/presentation/widgets/` | `benefit_edit_sheet.dart`, `fixed_cash_sheet.dart`, `view_pay_sheet.dart`, `usage_rights_sheet.dart`. F6의 "희망 보상"(Task 10)과 뒤 계획이 함께 쓴다 |
| 보상 문구 (Task 7) | `app/lib/features/offer_terms/presentation/offer_terms_text.dart` | `benefitLine`, `benefitShort`, `fixedCashLabel`, `viewPayLine`, `viewPayLineComma`, `rateLabel`, `capLabel`, `deliverableLine`, `usageRightsLabel`, `rewardHeadline`, `feeNote` |
| 옛 판본 오류 (Task 5) | `app/lib/core/network/api_error.dart` | `ApiErrorCode.staleVersion`, `details['latestVersion']` |
| F3, 제안 상세 (Task 12) | `app/lib/features/proposals/` | `/store/proposals`, `/store/proposals/:offerId`, `/creator/proposals`, `/creator/proposals/:offerId`, `ProposalRepository`, `proposal_text.dart`. 브랜드 경로는 5번 계획이 더한다 |
| F6 (Task 10) | `app/lib/features/proposals/presentation/pages/counter_proposal_page.dart` | `/creator/stores/:id/propose`, `CounterProposalRepository`(시리즈 읽기·만들기 포함) |
| F4 (Task 21) | `app/lib/features/view_report/` | `/creator/collaborations/:id/report`, `/store/collaborations/:id/report`, `ViewReportRepository` |
| G1 (Task 18) | `app/lib/features/store_result/` | `/store/collaborations/:id/result`. AI 제작 계획이 `영상 받기`의 동작을 바꾼다 |
| 공유 (Task 14) | `app/lib/core/share/share_launcher.dart` | `ShareLauncher.shareText(String)`, `shareLauncherProvider` |
| 준비 중으로 남긴 곳 | — | A4 `가게 계정에 올리기`(AI 제작 계획이 F5로 잇는다), G2 `탐색`(4번 계획의 찾기) |
