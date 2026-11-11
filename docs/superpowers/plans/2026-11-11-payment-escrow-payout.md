# 결제·에스크로·지급 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

**Goal:** 수락된 가게 오퍼를 사장님이 (가짜 PG로) 결제하면 금액을 장부에 보관하고, 크리에이터가 링크를 제출한 뒤 7일간의 조회수로 지급과 환급을 계산해 끝낸다.

**Architecture:** 오퍼 수락 때 `collaborations` 행을 만들고 그 `stage`가 협업의 유일한 기준이 된다. 돈의 움직임은 고치지 않는 두 줄짜리 장부에 적는다. PG, 송금, 조회수, 인스타그램 연결, 운영자 알림은 포트 뒤의 가짜 구현이다. 기한과 집계는 이 계획에서 도입하는 작업 큐가 처리하고, 모든 작업은 여러 번 실행돼도 결과가 같다.

**Tech Stack:** 공통 기반·2번 계획과 같다. 추가: `@nestjs/bullmq` + `bullmq`(작업 큐, Redis), `nest-commander`(운영 명령), Node `crypto`(계좌번호 암호화, AES-256-GCM).

**Spec:** `docs/superpowers/specs/2026-11-11-payment-escrow-payout-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md` (1, 2, 16, 19장) · 상위: `docs/superpowers/specs/2026-11-11-tech-stack-design.md`

**선행 조건:** `plans/2026-11-11-foundation.md`, `plans/2026-11-11-store-owner-offer.md`가 끝나 있어야 한다. 이 계획은 2번의 `OffersService`, `offer-rules.ts`, `OfferTermsModel`, `CreatorsService`, `StoresService`, `Clock`, `PushPort`, 앱의 `store_home`, `offers`, 공용 위젯을 그대로 쓴다.

## Global Constraints

공통 기반과 2번 계획의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것:

- 금액은 원 단위 정수(`Int`)다. 소수와 부동소수 계산을 쓰지 않는다. 수수료는 `Math.floor(상한 × 수수료율 / 100)`.
- 고정 값: 수수료율 `10`(%, 환경변수 `FEE_RATE_STORE_OFFER`, `FEE_RATE_BID`, `FEE_RATE_BRAND_CONTRACT`의 기본값), 링크 제출 기한 결제 후 `14`일, 조회수 집계 `7`일, 집계 실패 허용 연속 `3`일, 제출 기한 알림 `3`일 전과 `1`일 전, 사장님 취소 요청의 유효 기간 `3`일, 결제 대기 재확인 `10`분, 브랜드 계약의 멈춤 기한 `60`일.
- 장부 줄은 만들기만 한다. 수정과 삭제를 하지 않는다. 정정은 반대 줄을 더한다.
- 장부 불변식: 협업마다 `PG_IN에서 나간 합 = ESCROW 잔액 + CREATOR_PAYABLE로 들어간 합 + STORE_REFUND로 들어간 합 + FEE_REVENUE 잔액`. 이 식을 깨는 변경은 실패다.
- 돈이 움직이는 모든 동작(결제 통지, 정산, 지급, 환급, 운영 명령)은 중복 방지 키를 받고, DB의 유일 제약으로 두 번째 실행을 막는다.
- 단계 전이는 `UPDATE ... WHERE id = ? AND stage = <기대 단계>`의 조건부 갱신으로 한다. 바뀐 행이 0이면 409 `CONFLICT`(API) 또는 아무 일도 하지 않고 끝낸다(작업).
- 작업 큐의 작업은 실행 시각을 `Clock`에서 읽고, 다시 실행돼도 같은 결과를 낸다. 작업 안에서 외부 포트를 부른 뒤 DB를 쓰는 순서를 지키고, 포트 호출에도 중복 방지 키를 넘긴다.
- 계좌번호는 AES-256-GCM으로 암호화해 저장한다. 키는 환경변수 `PAYOUT_ACCOUNT_KEY`(32바이트 base64). 응답과 로그에는 뒤 4자리만 낸다.
- 운영자는 DB를 직접 고치지 않는다. 이 계획의 운영 명령만 쓴다.
- 작업 브랜치는 `feat/payment-escrow-payout`.

## Review Focus

1. **PG 통지가 두 번 옴** → 장부 줄과 단계 전이가 한 번만 일어난다. (Task 6)
2. **결제창을 닫았는데 통지는 나중에 옴** → 앱이 "완료되지 않았어요"를 보여 준 뒤에도, 통지가 오면 결제 완료가 되고 홈에 반영된다. (Task 6, 11)
3. **정산 작업이 중간에 죽고 다시 실행됨** → 지급과 환급이 한 번씩만 나가고 장부의 합이 맞는다. (Task 8)
4. **조회수를 3일 연속 읽지 못함** → 0원으로 정산하지 않고 멈추고 운영자에게 알린다. (Task 8)
5. **조회수가 0이거나 상한을 훨씬 넘음** → 지급 0원·전액 환급, 지급 상한·환급 0원. (Task 2, 8)

---

## 파일 구조

```text
api/src/
├── collaborations/
│   ├── collaboration-stage.ts          # 순수 함수: 허용되는 전이, 표시용 단계
│   └── ...                             # module, controller, service, repository, dto
├── ledger/
│   ├── ledger-postings.ts              # 순수 함수: 사건 → 장부 줄
│   └── ...                             # module, service, repository
├── payments/                           # 결제 요청, 통지, 재확인
├── settlements/
│   ├── settlement-math.ts              # 순수 함수: 지급액, 환급액
│   └── ...                             # 링크 제출, 조회수 집계, 정산, 환급
├── payout-accounts/                    # 계좌 등록, 암호화
├── instagram/                          # 계정 연결 (연결과 팔로워 수까지)
├── jobs/                               # 큐 등록, 작업 처리기
├── ops/                                # 운영 명령 (CLI)
└── integrations/{payment,payout,view-count,instagram,operator-alert}/

app/lib/features/
├── payment/                            # A8, 가짜 결제창
├── collaboration/                      # A7, 사장님 진행 화면, 링크 제출, 식사권, 취소
├── payout_account/                     # 계좌 등록
└── instagram_connect/                  # 계정 연결
```

---

### Task 1: 스키마와 협업 단계

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/offers/offers.service.ts`(수락 때 협업 생성), `api/src/offers/dto/*.model.ts`(`collaborationId` 추가)
- Create: 마이그레이션, `api/src/collaborations/collaboration-stage.ts`, `api/src/collaborations/collaborations.module.ts`, `collaborations.repository.ts`
- Test: `api/src/collaborations/collaboration-stage.spec.ts`, `api/test/db/collaboration-schema.db-spec.ts`, `api/test/offers.e2e-spec.ts`(추가)

**Interfaces:**
- Produces:
  - `enum CollaborationKind { STORE_OFFER, BRAND_CONTRACT }`
  - `enum CollaborationStage { AWAITING_PAYMENT, FUNDED, COUNTING, SETTLED, REFUNDED, CANCELLED, INQUIRY, MATCHED, NEGOTIATING, AGREED, CONTRACTED, GUIDED, REVIEWING, APPROVED, PUBLISHED, DROPPED, HALTED }`
  - `enum SettlementMethod { PER_VIEW, FIXED, NONE }` (`NONE`은 식사권만 있는 오퍼)
  - `Collaboration` → `collaborations`: `id`, `kind`, `stage`, `commissionerId`(맡기는 쪽 사용자), `creatorId`, `offerId?`(unique), `storeId?`, `terms`(Json, `OfferTermsModel` 사본), `settlementMethod`, `fundedAt?`, `submitDueAt?`, `submittedUrl?`, `submittedAt?`, `countingEndsAt?`, `haltedReason?`, `stageBeforeHalt?`
  - `Payment` → `payments`: `collaborationId`, `amountEscrow`, `amountFee`, `feeRate`, `method`(`CARD | TRANSFER | EASY_PAY`), `status`(`PENDING | APPROVED | FAILED | CANCELLED`), `pgTransactionId?`(unique), `requestedAt`, `approvedAt?`
  - `LedgerEntry` → `ledger_entries`: `collaborationId`, `batchId`, `debitAccount`, `creditAccount`, `amount`, `reason`, `idempotencyKey`. 유일 제약 `(idempotencyKey, debitAccount, creditAccount)`.
  - `enum LedgerAccount { PG_IN, ESCROW, CREATOR_PAYABLE, STORE_REFUND, FEE_REVENUE }`
  - `ViewSnapshot` → `view_snapshots`: `collaborationId`, `takenAt`, `views?`(읽지 못하면 null), `dayIndex`(0~7). 유일 제약 `(collaborationId, dayIndex)`.
  - `Settlement` → `settlements`: `collaborationId`(unique), `finalViews?`, `payoutAmount`, `refundAmount`, `settledAt`
  - `Payout` → `payouts`, `Refund` → `refunds`: `collaborationId`, `amount`, `status`(`PENDING | DONE | FAILED`), `externalId?`, `idempotencyKey`(unique)
  - `PayoutAccount` → `payout_accounts`: `creatorId`(unique), `bankCode`, `accountNumberEnc`, `accountLast4`, `holderName`
  - `InstagramConnection` → `instagram_connections`: `creatorId`(unique), `handle`(unique), `followers?`, `tokenEnc?`, `refreshedAt`
  - `CancelRequest` → `cancel_requests`: `collaborationId`, `requestedById`, `status`(`PENDING | ACCEPTED | EXPIRED`), `expiresAt`
  - `OpsAuditLog` → `ops_audit_logs`: `command`, `collaborationId?`, `operator`, `reason`, `detail`(Json)
  - `canTransition(kind: CollaborationKind, from: CollaborationStage, to: CollaborationStage): boolean` — 공통 규칙 1장의 두 그림 그대로. 어느 단계에서든 `CONTRACTED` 이후의 브랜드 단계는 `HALTED`로 갈 수 있다.
  - `isMoneyHeld(kind, stage): boolean` — 가게 `FUNDED`·`COUNTING`, 브랜드 `CONTRACTED`~`PUBLISHED`·`HALTED`
  - `storeInProgressStages: CollaborationStage[]` = `[AWAITING_PAYMENT, FUNDED, COUNTING]`
  - `CollaborationsRepository.advance(id, from: CollaborationStage, to: CollaborationStage, patch?): Promise<boolean>` — 조건부 갱신, 바뀌었으면 true
  - 2번의 `POST /offers/:id/accept`가 같은 트랜잭션에서 협업을 만든다: `kind: STORE_OFFER`, `terms`는 오퍼의 조건 사본, `settlementMethod`는 보상에 조회수가 있으면 `PER_VIEW` 아니면 `NONE`, 단계는 `PER_VIEW`면 `AWAITING_PAYMENT`, `NONE`이면 `FUNDED`(`fundedAt = now`, `submitDueAt = now + 14일`).
  - 2번의 `SentOfferModel`, `ReceivedOfferModel`에 `collaborationId: string | null` 추가. `StoreHomeSummaryModel.inProgress`는 `storeInProgressStages`에 있는 협업의 수로 바꾼다.
  - 2번의 오퍼 취소·결제 기한 만료가 일어나면 연결된 협업을 `AWAITING_PAYMENT → CANCELLED`로 옮긴다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
// collaboration-stage.spec.ts
it('allows the store path AWAITING_PAYMENT → FUNDED → COUNTING → SETTLED', ...);
it('allows FUNDED → REFUNDED and FUNDED → CANCELLED but not COUNTING → CANCELLED', ...);
it('rejects skipping from AWAITING_PAYMENT to COUNTING', ...);
it('allows the brand path in order and rejects GUIDED → APPROVED', ...);
it('allows HALTED only from CONTRACTED onwards for brand contracts', ...);
it('reports money held for FUNDED and COUNTING store collaborations only', ...);

// offers.e2e-spec.ts (추가)
it('creates an AWAITING_PAYMENT collaboration when a per-view offer is accepted', ...);
it('creates a FUNDED collaboration with a 14 day due date when a voucher-only offer is accepted', ...);
it('cancels the collaboration when the owner cancels an accepted offer', ...);
it('counts AWAITING_PAYMENT, FUNDED and COUNTING as in progress', ...);

// collaboration-schema.db-spec.ts
it('rejects two ledger rows with the same idempotency key and accounts', ...);
it('rejects two collaborations for one offer', ...);
```

- [ ] **Step 2: 실패 확인** — Run: `cd api && yarn test collaboration-stage && yarn test:db && yarn test:e2e offers` · Expected: FAIL
- [ ] **Step 3: 스키마, 마이그레이션(새 테이블 11개의 RLS 포함), 단계 함수, 수락 때 협업 생성 구현**
- [ ] **Step 4: 통과 확인** — Run: `cd api && yarn prisma migrate dev && yarn lint && yarn test && yarn test:e2e && yarn test:db` · Expected: PASS
- [ ] **Step 5: gen-api, Commit** — `feat: 협업·결제·장부 스키마와 협업 단계 추가`

---

### Task 2: 장부와 정산 계산 (순수 함수)

**Files:**
- Create: `api/src/ledger/ledger-postings.ts`, `ledger.module.ts`, `ledger.service.ts`, `ledger.repository.ts`, `api/src/settlements/settlement-math.ts`
- Test: `api/src/ledger/ledger-postings.spec.ts`, `api/src/settlements/settlement-math.spec.ts`, `api/test/db/ledger.repository.db-spec.ts`

**Interfaces:**
- Consumes: `LedgerAccount` (Task 1)
- Produces:
  - `type Posting = { debit: LedgerAccount; credit: LedgerAccount; amount: number; reason: string }`
  - `postingsForPaymentApproved(p: { escrow: number; fee: number }): Posting[]` — `PG_IN→ESCROW`(escrow), `PG_IN→FEE_REVENUE`(fee). 금액이 0인 줄은 만들지 않는다.
  - `postingsForSettlement(p: { payout: number; refund: number }): Posting[]` — `ESCROW→CREATOR_PAYABLE`, `ESCROW→STORE_REFUND`
  - `postingsForFullRefund(p: { escrow: number; fee: number }): Posting[]` — `ESCROW→STORE_REFUND`, `FEE_REVENUE→STORE_REFUND`
  - `postingsForForcedPayout(p: { amount: number }): Posting[]` — `ESCROW→CREATOR_PAYABLE`
  - `balances(entries: { debitAccount; creditAccount; amount }[]): Record<LedgerAccount, number>` — 계정별 (들어온 합 − 나간 합)
  - `assertBalanced(entries): void` — Global Constraints의 불변식이 깨지면 throw
  - `feeFor(escrow: number, feeRate: number): number` = `Math.floor(escrow * feeRate / 100)`
  - `settle(p: { views: number; perViewAmount: number; cap: number }): { payout: number; refund: number }` — `payout = Math.min(views * perViewAmount, cap)`, `refund = cap - payout`. `views`가 음수거나 정수가 아니면 throw.
  - `LedgerService.post(collaborationId, postings: Posting[], idempotencyKey: string, tx?): Promise<'posted' | 'duplicate'>` — 한 묶음(`batchId`)으로 넣는다. 유일 제약에 걸리면 `'duplicate'`를 돌려주고 아무것도 넣지 않는다. 넣은 뒤 그 협업의 전체 줄로 `assertBalanced`를 부른다.
  - `LedgerService.escrowBalance(collaborationId): Promise<number>`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('charges a 10 percent fee rounded down', () => { expect(feeFor(100000, 10)).toBe(10000); expect(feeFor(33333, 10)).toBe(3333); });
it('pays views times unit up to the cap', () => { expect(settle({ views: 4320, perViewAmount: 10, cap: 100000 })).toEqual({ payout: 43200, refund: 56800 }); });
it('pays nothing and refunds everything for zero views', () => { expect(settle({ views: 0, perViewAmount: 10, cap: 100000 })).toEqual({ payout: 0, refund: 100000 }); });
it('caps the payout and refunds nothing when views exceed the cap', () => { expect(settle({ views: 250000, perViewAmount: 10, cap: 100000 })).toEqual({ payout: 100000, refund: 0 }); });
it('rejects negative or fractional views', ...);
it('keeps the ledger balanced after payment then settlement', ...);          // escrow 0, payable 43200, refund 56800, fee 10000
it('keeps the ledger balanced after payment then full refund', ...);         // escrow 0, fee 0, refund 110000
it('skips zero amount postings', ...);
it('throws when escrow would go negative', ...);
it('returns duplicate and inserts nothing for a repeated idempotency key', ...);   // DB
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn test ledger settlement-math && yarn test:db`
- [ ] **Step 5: Commit** — `feat: 장부 기록과 정산 계산 추가`

---

### Task 3: 작업 큐와 새 포트 (가짜 구현)

**Files:**
- Create: `api/src/jobs/jobs.module.ts`, `job-names.ts`, `job-scheduler.ts`, `api/src/integrations/payment/{payment.port.ts,fake-payment.adapter.ts}`, `payout/{payout.port.ts,fake-payout.adapter.ts}`, `view-count/{view-count.port.ts,fake-view-count.adapter.ts}`, `instagram/{instagram.port.ts,fake-instagram.adapter.ts}`, `operator-alert/{operator-alert.port.ts,fake-operator-alert.adapter.ts}`, `api/test/support/fake-job-scheduler.ts`
- Modify: `api/src/config/env.ts`(`REDIS_URL`, `PAYMENT_ADAPTER`, `PAYOUT_ADAPTER`, `VIEW_COUNT_ADAPTER`, `INSTAGRAM_ADAPTER`, `OPERATOR_ALERT_ADAPTER`, `OPERATOR_EMAIL`, `PAYOUT_ACCOUNT_KEY`, `FEE_RATE_*`, `PAYMENT_WEBHOOK_SECRET`), `api/.env.example`, `api/src/integrations/integrations.module.ts`
- Test: 각 가짜 구현의 spec, `api/src/jobs/job-scheduler.spec.ts`, `api/src/integrations/assert-no-fakes.spec.ts`(추가)

**Interfaces:**
- Produces:
  - `abstract class JobScheduler { abstract schedule(name: JobName, payload: { collaborationId: string; [k: string]: unknown }, runAt: Date, jobKey: string): Promise<void>; abstract cancel(jobKey: string): Promise<void> }` — `jobKey`가 같으면 한 번만 등록된다. 실제 구현은 BullMQ의 지연 작업이고, 테스트는 `FakeJobScheduler`(등록된 작업을 기록하고 `runDue(now)`로 실행)를 쓴다.
  - `type JobName = 'view-snapshot' | 'settle' | 'refund-unsubmitted' | 'submit-reminder' | 'decline-notice' | 'payment-due-expiry' | 'payment-recheck' | 'cancel-request-expiry' | 'brand-halt-check'`
  - `PaymentPort`: `createCheckout(input: { paymentId: string; amount: number; method: PaymentMethod; orderName: string }): Promise<{ checkoutUrl: string }>`, `verifyWebhook(rawBody: string, signature: string): { paymentId: string; pgTransactionId: string; status: 'APPROVED' | 'FAILED' } | null`, `fetchStatus(paymentId: string): Promise<'PENDING' | 'APPROVED' | 'FAILED'>`, `refund(input: { pgTransactionId: string; amount: number; idempotencyKey: string }): Promise<{ externalId: string }>`
  - `PayoutPort`: `send(input: { bankCode: string; accountNumber: string; holderName: string; amount: number; idempotencyKey: string }): Promise<{ externalId: string }>`
  - `ViewCountPort`: `isOwnedBy(url: string, creator: { instagramHandle: string | null }): Promise<boolean>`, `read(url: string): Promise<number>`(읽지 못하면 `ViewCountUnavailableError`)
  - `InstagramPort`: `beginConnect(creatorId: string): Promise<{ connectUrl: string }>`, `completeConnect(creatorId: string, code: string): Promise<{ handle: string; followers: number; token: string }>`, `fetchFollowers(token: string): Promise<number>`
  - `OperatorAlertPort`: `alert(input: { subject: string; body: string }): Promise<void>`
  - 가짜 구현의 동작:
    - 결제: `checkoutUrl`은 `cora-dev://fake-pay?paymentId=…`. 통지 서명은 `PAYMENT_WEBHOOK_SECRET`으로 만든 HMAC-SHA256. `fetchStatus`는 가짜 통지 기록을 본다.
    - 송금: 항상 성공. 예금주에 `fail`이 들어 있으면 실패.
    - 조회수: `isOwnedBy`는 주소에 `notmine`이 있으면 false. `read`는 주소에 `unavailable`이 있으면 `ViewCountUnavailableError`, 아니면 주소의 `views=<숫자>` 값(없으면 600 × 제출 후 지난 날 수, `Clock` 기준).
    - 인스타그램: `connectUrl`은 `cora-dev://fake-instagram`. `code`는 사용자가 입력한 아이디이고 그대로 `handle`이 된다. 팔로워 2,100.
    - 운영자 알림: 로그.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('registers a job once for the same job key', ...);
it('runs only jobs whose time has come', ...);                          // FakeJobScheduler.runDue
it('verifies a webhook signed with the shared secret and rejects a tampered body', ...);
it('reads 600 views per elapsed day by default', ...);
it('reads the views value from the url when present', ...);             // ...?views=4320
it('throws ViewCountUnavailableError for an unavailable url', ...);
it('treats a url containing notmine as not owned', ...);
it('uses the typed handle as the connected instagram account', ...);
it('throws in production when PAYMENT_ADAPTER is fake', ...);           // 다섯 어댑터 각각
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn test integrations jobs`. `docker compose up -d redis` 상태에서 `yarn start:dev`가 큐에 연결되는지 로그로 확인한다.
- [ ] **Step 5: Commit** — `feat: 작업 큐와 결제·송금·조회수·인스타그램·운영자 알림 포트 추가`

---

### Task 4: 2번에서 미룬 예약 작업 옮기기

**Files:**
- Create: `api/src/jobs/handlers/{decline-notice.handler.ts,payment-due-expiry.handler.ts}`
- Modify: `api/src/offers/offers.service.ts`
- Test: `api/src/jobs/handlers/*.spec.ts`, `api/test/offers.e2e-spec.ts`(추가)

**Interfaces:**
- Consumes: `JobScheduler` (Task 3), `offer-rules.ts` (2번), `CollaborationsRepository.advance` (Task 1)
- Produces:
  - 거절하면 `decline-notice`를 `declinedAt + 30초`에 등록(`jobKey = 'decline:' + offerId`). 되돌리면 취소. 처리기는 오퍼가 여전히 `DECLINED`일 때만 사장님에게 `{활동 이름}님이 이번 오퍼는 함께하기 어렵대요.`를 보내고 연결된 지원을 닫는다.
  - 수락하면(조회수 보상이 있을 때) `payment-due-expiry`를 `paymentDueAt`에 등록. 처리기는 오퍼가 `ACCEPTED`이고 결제가 승인되지 않았으면 `EXPIRED`로, 협업을 `CANCELLED`로 옮긴다.
  - 2번의 "조회할 때 계산"은 그대로 둔다(작업이 늦어도 화면은 맞다).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('notifies the owner 30 seconds after a decline', ...);
it('does not notify when the decline was undone', ...);
it('expires an unpaid accepted offer and cancels its collaboration at the due time', ...);
it('does nothing when the offer was paid before the due time', ...);
it('does nothing when run twice', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 거절 알림과 결제 기한 만료를 작업 큐로 처리`

---

### Task 5: 인스타그램 계정 연결과 수락 조건

**Files:**
- Create: `api/src/instagram/{instagram.module.ts,instagram.controller.ts,instagram.service.ts,instagram.repository.ts,dto/*.ts}`
- Modify: `api/src/offers/offers.service.ts`, `api/src/offers/dto/received-offer.model.ts`, `api/src/creators/dto/*.model.ts`
- Test: `api/src/instagram/instagram.service.spec.ts`, `api/test/instagram.e2e-spec.ts`, `api/test/offers.e2e-spec.ts`(추가)

**Interfaces:**
- Consumes: `InstagramPort` (Task 3), 계좌번호와 같은 암호화 도우미(`api/src/common/crypto/secret-box.ts`를 이 작업에서 만든다: `seal(plain: string): string`, `open(sealed: string): string`, 키는 `PAYOUT_ACCOUNT_KEY`)
- Produces:
  - `POST /instagram/connect` → 200 `{ connectUrl: string }`. `operationId: beginInstagramConnect`
  - `POST /instagram/connect/complete` 본문 `{ code: string }` → 200 `InstagramConnectionModel { handle: string; followers: number | null }`. 그 `handle`을 다른 크리에이터가 이미 연결했으면 409. `operationId: completeInstagramConnect`
  - `GET /instagram/connection` → 200 `InstagramConnectionModel` | 404. `DELETE /instagram/connection` → 204(보관 중인 돈이 있는 조회수 협업이 있으면 409). `operationId: getInstagramConnection`, `disconnectInstagram`
  - 연결되면 `creator_profiles.instagramHandle`을 연결된 아이디로 덮어쓴다. `CreatorProfileModel`, `CreatorSummaryModel`에 `instagramConnected: boolean`, `followers: number | null` 추가.
  - `InstagramService`를 export: `getConnection(creatorId): Promise<{ handle; followers } | null>`
  - `ReceivedOfferModel`에 `needsInstagram: boolean` 추가 — 형식이 `REELS` 또는 `CARD_NEWS`이고 보상에 조회수가 있고 연결이 없을 때 true.
  - `POST /offers/:id/accept`: `needsInstagram`이면 409 `CONFLICT`, 메시지 `인스타그램을 연동하면 수락할 수 있어요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('connects the typed handle and stores followers', ...);
it('rejects a handle already connected by another creator', ...);        // 409
it('marks a per-view reels offer as needing instagram', ...);
it('refuses to accept a per-view reels offer without a connection', ...); // 409
it('accepts the same offer after connecting', ...);
it('does not require instagram for a voucher-only offer or a shorts offer', ...);
it('refuses to disconnect while a per-view collaboration holds money', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 인스타그램 계정 연결과 조회수당 오퍼의 수락 조건 추가`

---

### Task 6: 결제

**Files:**
- Create: `api/src/payments/{payments.module.ts,payments.controller.ts,payments.webhook.controller.ts,payments.dev.controller.ts,payments.service.ts,payments.repository.ts,dto/*.ts}`, `api/src/jobs/handlers/payment-recheck.handler.ts`
- Test: `api/src/payments/payments.service.spec.ts`, `api/test/payments.e2e-spec.ts`

**Interfaces:**
- Consumes: `PaymentPort`, `JobScheduler` (Task 3), `LedgerService`, `feeFor`, `postingsForPaymentApproved` (Task 2), `CollaborationsRepository` (Task 1), `PushPort`
- Produces:
  - `GET /collaborations/:id/payment-quote` → 200 `PaymentQuoteModel { escrow: number; fee: number; feeRate: number; total: number; orderName: string }` — 사장님만. `escrow`는 조건의 `perViewCap`. `operationId: getPaymentQuote`
  - `POST /collaborations/:id/payments` 본문 `{ method: 'CARD' | 'TRANSFER' | 'EASY_PAY' }` → 201 `{ paymentId: string; checkoutUrl: string }`. 협업이 `AWAITING_PAYMENT`가 아니면 409. 같은 협업에 `PENDING` 결제가 있으면 그것을 `CANCELLED`로 바꾸고 새로 만든다. `payment-recheck`를 10분 뒤에 등록한다. `operationId: createPayment`
  - `GET /payments/:id` → 200 `{ status: 'PENDING' | 'APPROVED' | 'FAILED' | 'CANCELLED' }` — 그 협업의 사장님만. `operationId: getPayment`
  - `POST /webhooks/payments` — `@Public()`. 헤더 `x-cora-signature`. `PaymentPort.verifyWebhook`이 null이면 401. 통과하면 `PaymentsService.applyResult`.
  - `POST /dev/fake-payments/:id/approve`, `/fail` — `PAYMENT_ADAPTER=fake`일 때만 등록되는 컨트롤러. 가짜 통지를 만들어 위 웹훅과 같은 경로로 처리한다. 운영에서는 라우트가 없다(404).
  - `PaymentsService.applyResult(result: { paymentId; pgTransactionId; status }): Promise<void>` — 한 트랜잭션에서: 결제를 `PENDING → APPROVED` 조건부 갱신(바뀐 행 0이면 끝), 장부 `post(..., 'payment:' + paymentId)`, 협업 `AWAITING_PAYMENT → FUNDED`(`fundedAt = now`, `submitDueAt = now + 14일`). 그 뒤 `refund-unsubmitted`(submitDueAt), `submit-reminder`(3일 전, 1일 전) 등록, `payment-due-expiry` 취소, 크리에이터에게 `{가게 이름}이 결제했어요. 방문하고 촬영해 주세요.` `FAILED`면 결제만 `FAILED`로.
  - `payment-recheck` 처리기: 결제가 아직 `PENDING`이면 `PaymentPort.fetchStatus`로 물어 결과를 `applyResult`에 넣는다. 여전히 `PENDING`이면 10분 뒤 다시 등록(최대 6번).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('quotes cap plus a 10 percent fee', ...);                              // escrow 100000, fee 10000, total 110000
it('lets only the commissioner create a payment', ...);                   // 크리에이터 → 404
it('rejects a payment for a collaboration that is not awaiting payment', ...); // 409
it('funds the collaboration on an approved webhook', ...);                // stage FUNDED, ledger escrow 100000, fee 10000
it('ignores a second identical webhook', ...);                            // 장부 줄 수 그대로, 알림 1건
it('rejects a webhook with a bad signature', ...);                        // 401
it('leaves the collaboration awaiting payment on a failed webhook', ...);
it('replaces a pending payment when the owner starts again', ...);
it('picks up an approval the webhook missed when rechecked', ...);        // FakeJobScheduler.runDue(+10분)
it('schedules the unsubmitted refund 14 days after funding', ...);
it('does not expose the dev approve route in production mode', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e`
- [ ] **Step 5: gen-api, Commit** — `feat: 결제 요청과 통지 처리, 보관 시작 추가`

---

### Task 7: 지급받을 계좌

**Files:**
- Create: `api/src/payout-accounts/{payout-accounts.module.ts,payout-accounts.controller.ts,payout-accounts.service.ts,payout-accounts.repository.ts,banks.ts,dto/*.ts}`
- Test: `api/src/common/crypto/secret-box.spec.ts`, `api/test/payout-accounts.e2e-spec.ts`

**Interfaces:**
- Consumes: `seal`, `open` (Task 5)
- Produces:
  - `BANKS: { code: string; name: string }[]` — 은행 목록(국민, 신한, 우리, 하나, 농협, 기업, 카카오뱅크, 토스뱅크, 케이뱅크, 새마을금고, 우체국, SC제일, 부산, 대구, 광주, 전북, 경남, 제주, 수협, 신협). 코드는 금융결제원 은행 코드 세 자리를 쓴다. 실행자는 공개된 은행 코드표를 확인해 채운다.
  - `GET /payout-account/banks` → 200 `{ code; name }[]`. `operationId: listBanks`
  - `GET /payout-account` → 200 `PayoutAccountModel { bankCode; bankName; accountLast4; holderName }` | 404. `operationId: getPayoutAccount`
  - `PUT /payout-account` 본문 `{ bankCode; accountNumber(숫자 10~14자리, 하이픈은 떼고 저장); holderName(1~20자) }` → 200 `PayoutAccountModel`. `CREATOR` 역할만. 등록되면 그 크리에이터의 `PENDING` 지급을 처리하는 Task 8의 `PayoutsService.flushPending(creatorId)`을 부른다(Task 8에서 연결). `operationId: upsertPayoutAccount`
  - `PayoutAccountsService`를 export: `getForPayout(creatorId): Promise<{ bankCode; accountNumber; holderName } | null>`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('round-trips a secret and fails on a tampered value', ...);
it('stores the account number encrypted', ...);                            // DB의 값에 원래 번호가 들어 있지 않다
it('returns only the last four digits', ...);
it('strips hyphens and rejects non-digits', ...);
it('rejects an unknown bank code', ...);
it('requires the CREATOR role', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 지급받을 계좌 등록 추가`

---

### Task 8: 링크 제출, 조회수 집계, 정산, 지급, 환급

**Files:**
- Create: `api/src/settlements/{settlements.module.ts,submissions.controller.ts,submissions.service.ts,settlements.service.ts,payouts.service.ts,refunds.service.ts,settlements.repository.ts,link-rules.ts,dto/*.ts}`, `api/src/jobs/handlers/{view-snapshot.handler.ts,settle.handler.ts,refund-unsubmitted.handler.ts,submit-reminder.handler.ts}`
- Modify: `api/src/payout-accounts/payout-accounts.service.ts`
- Test: `api/src/settlements/link-rules.spec.ts`, `api/src/settlements/*.service.spec.ts`, `api/test/settlements.e2e-spec.ts`

**Interfaces:**
- Consumes: Task 1~7의 전부
- Produces:
  - `isAcceptedLink(format: ContentFormat, url: string): boolean` (`link-rules.ts`, 순수 함수) — `https`만. `SHORTS`: `youtube.com/shorts/…`, `youtu.be/…`. `REELS`, `CARD_NEWS`: `instagram.com/reel/…`, `instagram.com/p/…`(`www.` 허용). `BLOG`: `blog.naver.com/…`, `*.tistory.com/…`.
  - `POST /collaborations/:id/submission` 본문 `{ url: string }` → 200 `CollaborationModel`(Task 9). 크리에이터만, `FUNDED`일 때만(브랜드 계약은 `APPROVED`일 때만 — 이 검사를 지금 넣어 둔다). 형식에 안 맞으면 400 `링크 형식을 확인해 주세요.`, `ViewCountPort.isOwnedBy`가 false면 409 `내 계정의 게시물만 제출할 수 있어요.` 통과하면: `PER_VIEW`는 `FUNDED → COUNTING`(`countingEndsAt = now + 7일`), `view-snapshot` dayIndex 0을 지금, 1~7을 하루 간격으로, `settle`을 `countingEndsAt`에 등록. `NONE`은 `FUNDED → SETTLED`. `refund-unsubmitted`와 `submit-reminder`를 취소한다. 사장님에게 `{활동 이름}님이 콘텐츠를 올렸어요.` `operationId: submitContentLink`
  - `view-snapshot` 처리기: `ViewCountPort.read` 결과를 `(collaborationId, dayIndex)`에 저장. 읽지 못하면 `views = null`로 저장. 가장 최근 3개의 스냅샷이 모두 null이면 협업을 `HALTED`로 옮기고(`stageBeforeHalt = COUNTING`, `haltedReason = 'VIEW_COUNT_UNAVAILABLE'`) `settle`을 취소하고 `OperatorAlertPort.alert`.
  - `settle` 처리기 → `SettlementsService.settle(collaborationId, key)`: 협업이 `COUNTING`이 아니면 끝. `finalViews` = dayIndex 7의 값, null이면 가장 최근의 null이 아닌 값, 하나도 없으면 `HALTED`로 옮기고 알림. 한 트랜잭션에서 `settlements` 행 생성(유일 제약이 중복을 막는다), 장부 `post(..., 'settle:' + collaborationId)`, `COUNTING → SETTLED`. 그 뒤 `PayoutsService.request`, `RefundsService.request`, 알림 두 건(`{금액}원이 지급됐어요.`는 지급이 `DONE`이 된 뒤, 사장님에게 `조회수 집계가 끝났어요. {금액}원을 돌려드려요.`).
  - `PayoutsService.request(collaborationId, amount, key)`: `payouts` 행을 `PENDING`으로 만든다(금액 0이면 만들지 않는다). 계좌가 있으면 `PayoutPort.send` 후 `DONE`, 없으면 `PENDING`으로 둔다. `flushPending(creatorId)`: 그 크리에이터의 `PENDING` 지급을 모두 보낸다. 포트가 실패하면 `FAILED`로 두고 운영자에게 알린다.
  - `RefundsService.request(collaborationId, amount, key)`: `refunds` 행을 만들고 `PaymentPort.refund` 후 `DONE`. 금액 0이면 만들지 않는다.
  - `refund-unsubmitted` 처리기: 협업이 `FUNDED`이면 장부에 `postingsForFullRefund`, `FUNDED → REFUNDED`, 환급 요청(상한 + 수수료), 양쪽에 알림(`기한 안에 콘텐츠가 올라오지 않아 {금액}원을 돌려드려요.` / `제출 기한이 지나 협업이 종료됐어요.`). `NONE` 방식이면 돈 없이 `REFUNDED`로만 옮긴다.
  - `submit-reminder` 처리기: `FUNDED`이면 크리에이터에게 `콘텐츠 제출 기한이 {n}일 남았어요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('accepts instagram reel links for reels and rejects a youtube link', ...);
it('rejects http links', ...);
it('moves to COUNTING and schedules eight snapshots and a settlement', ...);
it('settles a voucher-only collaboration immediately on submission', ...);
it('rejects a link that is not owned by the creator', ...);                 // ...notmine → 409
it('rejects a second submission', ...);                                     // 409
it('settles 4320 views as 43200 paid and 56800 refunded', ...);             // 주소 ?views=4320, FakeClock +7일, runDue
it('pays nothing and refunds the full cap for zero views', ...);
it('caps the payout at the cap', ...);
it('does not pay or refund twice when the settle job runs twice', ...);     // payouts 1행, refunds 1행, 장부 균형
it('keeps the payout pending until an account is registered, then sends it', ...);
it('uses the last readable snapshot when day 7 cannot be read', ...);
it('halts and alerts the operator after three unreadable days in a row', ...); // stage HALTED, settlements 없음
it('refunds cap and fee 14 days after funding when nothing was submitted', ...); // refund 110000, stage REFUNDED
it('does not refund when a link was submitted on day 13', ...);
it('reminds the creator 3 days and 1 day before the due date', ...);
it('keeps every collaboration ledger balanced after each scenario', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 세 개: `feat: 콘텐츠 링크 제출과 조회수 집계 추가`, `feat: 정산과 지급·환급 추가`, `feat: 미제출 환급과 제출 기한 알림 추가`

---

### Task 9: 협업 조회와 결제 뒤 취소

**Files:**
- Create: `api/src/collaborations/{collaborations.controller.ts,collaborations.service.ts,dto/collaboration.model.ts,dto/cancel-request.model.ts}`, `api/src/jobs/handlers/cancel-request-expiry.handler.ts`
- Test: `api/src/collaborations/collaborations.service.spec.ts`, `api/test/collaborations.e2e-spec.ts`

**Interfaces:**
- Consumes: Task 1~8
- Produces:
  - `CollaborationModel { id; kind; stage; role: 'COMMISSIONER' | 'CREATOR'; counterpart: { name: string; photoUrl: string | null }; store: StoreSummaryModel | null; terms: OfferTermsModel; steps: { key: 'ACCEPTED' | 'PAID' | 'VISIT' | 'SUBMIT' | 'SETTLE'; state: 'DONE' | 'NOW' | 'TODO'; at: string | null }[]; escrowAmount: number; submitDueAt: string | null; submittedUrl: string | null; countingEndsAt: string | null; currentViews: number | null; earnedSoFar: number | null; expectedRefund: number | null; settlement: { finalViews: number | null; payoutAmount: number; refundAmount: number } | null; payoutStatus: 'NONE' | 'NEEDS_ACCOUNT' | 'PENDING' | 'DONE' | 'FAILED'; cancelRequest: { id: string; requestedByMe: boolean; expiresAt: string } | null; canCancel: boolean; canRequestCancel: boolean }`
  - `steps`는 다섯 개 고정. 식사권만 있는 오퍼는 `PAID`가 처음부터 `DONE`. `earnedSoFar`와 `expectedRefund`는 `settle()`에 최신 조회수를 넣은 값이고 `COUNTING`일 때만 숫자다. `expectedRefund`는 사장님에게만, `earnedSoFar`는 크리에이터에게만 준다(상대 쪽 값은 null).
  - `GET /collaborations?scope=active|done` → 200 `CollaborationModel[]` — 내가 당사자인 것만. `GET /collaborations/:id` → 200 | 404. `operationId: listCollaborations`, `getCollaboration`
  - `POST /collaborations/:id/cancel` — 크리에이터만, `FUNDED`일 때만. 장부에 전액 환급, `FUNDED → CANCELLED`, 환급 요청, `refund-unsubmitted`·`submit-reminder` 취소, 사장님에게 `{활동 이름}님이 협업을 그만뒀어요. {금액}원을 돌려드려요.` `operationId: cancelCollaboration`
  - `POST /collaborations/:id/cancel-requests` — 사장님만, `FUNDED`일 때만, `PENDING` 요청이 없을 때만. `expiresAt = now + 3일`, `cancel-request-expiry` 등록, 크리에이터에게 `{가게 이름}이 협업 취소를 요청했어요.` `operationId: requestCollaborationCancel`
  - `POST /collaborations/:id/cancel-requests/:requestId/accept` — 크리에이터만. 위의 취소와 같은 처리. `operationId: acceptCollaborationCancel`
  - `cancel-request-expiry` 처리기: `PENDING`이면 `EXPIRED`로.
  - 2번의 `GET /offers/received?tab=active`가 주던 "진행 중" 목록은 이 `GET /collaborations?scope=active`로 대체한다. 2번의 엔드포인트는 `tab=new`만 남긴다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('shows five steps with VISIT as NOW right after funding', ...);
it('shows earned so far to the creator and expected refund to the owner only', ...);
it("returns 404 for a collaboration I am not part of", ...);
it('lets the creator cancel a funded collaboration with a full refund including the fee', ...);  // refund 110000
it('refuses to cancel while counting', ...);                               // 409
it('lets the owner request a cancel and the creator accept it', ...);
it('expires an unanswered cancel request after 3 days', ...);
it('refuses a second pending cancel request', ...);
it('reports NEEDS_ACCOUNT when settled without a payout account', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 협업 조회와 결제 뒤 취소 추가`

---

### Task 10: 운영 명령

**Files:**
- Create: `api/src/ops/{ops.module.ts,ops.service.ts,commands/*.command.ts}`, `api/src/ops-main.ts`
- Modify: `api/package.json`(`"ops": "node dist/ops-main.js"`), `README.md`
- Test: `api/src/ops/ops.service.spec.ts`, `api/test/ops.e2e-spec.ts`

**Interfaces:**
- Consumes: Task 1~9
- Produces — 모두 `--operator <이름>`과 `--reason <글>`이 필수이고 `ops_audit_logs`에 한 줄을 남긴다:
  - `yarn ops halt --collaboration <id>` — 돈을 보관 중인 단계 → `HALTED`(`stageBeforeHalt` 저장). 등록된 작업을 취소한다.
  - `yarn ops resume --collaboration <id>` — `HALTED` → `stageBeforeHalt`. `COUNTING`으로 돌아가면 `settle`을 지금 실행하도록 등록한다.
  - `yarn ops resume-settlement --collaboration <id> --views <n>` — `HALTED`(사유가 조회수)인 협업을 주어진 조회수로 정산한다.
  - `yarn ops force-refund --collaboration <id>` — 보관 중인 전액과 수수료를 환급하고 `REFUNDED`로.
  - `yarn ops force-payout --collaboration <id> --amount <n>` — 보관액 안에서 지급하고 남은 금액을 환급하고 `SETTLED`로. `amount`가 보관액보다 크면 거절.
  - `yarn ops retry-payout --payout <id>` — `FAILED` 지급을 다시 보낸다.
  - `yarn ops show --collaboration <id>` — 단계, 장부 계정별 잔액, 결제·지급·환급 상태를 출력한다(읽기 전용, 감사 기록 없음).
  - 모든 명령은 끝에 그 협업의 장부로 `assertBalanced`를 부른다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('refuses a command without operator and reason', ...);
it('halts a counting collaboration and cancels its settle job', ...);
it('resumes a halted collaboration to its previous stage', ...);
it('settles a view-count halt with the given views', ...);                 // --views 5000 → payout 50000, refund 50000
it('force refunds cap and fee and writes an audit row', ...);
it('refuses a forced payout above the escrow balance', ...);
it('leaves the ledger balanced after every command', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn build && yarn ops show --collaboration <테스트로 만든 id>`
- [ ] **Step 5: README에 명령 목록과 "DB를 직접 고치지 않는다" 추가, Commit** — `feat: 장부를 남기는 운영 명령 추가`

---

### Task 11: 앱 — 가게 결제(A8)와 가짜 결제창

**Files:**
- Create: `app/lib/features/payment/domain/{payment_quote.dart,payment_repository.dart}`, `data/api_payment_repository.dart`, `presentation/viewmodels/payment_view_model.dart`, `presentation/pages/{store_payment_page.dart,fake_checkout_page.dart}`, `app/lib/features/payment/presentation/checkout_launcher.dart`
- Modify: `app/lib/core/navigation/app_router.dart`, `app/lib/features/store_home/presentation/store_home_text.dart`(`결제하기` → `/store/collaborations/:id/pay`)
- Test: `app/test/features/payment/`

**Interfaces:**
- Consumes: `cora_api`의 `getPaymentQuote`, `createPayment`, `getPayment` (Task 6), `won()` (2번 Task 11), 공용 위젯
- Produces:
  - `abstract class PaymentRepository { Future<PaymentQuote> fetchQuote(String collaborationId); Future<({String paymentId, String checkoutUrl})> create(String collaborationId, PaymentMethod method); Future<PaymentStatus> fetchStatus(String paymentId); }`
  - `abstract class CheckoutLauncher { Future<void> open(String checkoutUrl); }` — `cora-dev://fake-pay` 주소면 앱 안의 `FakeCheckoutPage`를 연다. 다른 주소는 `UnimplementedError`(9번 계획에서 PG 결제창을 붙인다). `checkoutLauncherProvider`.
  - `FakeCheckoutPage`는 `AppConfig.isDev`일 때만 라우트에 등록된다. 금액, `결제 승인`, `결제 실패`, `닫기`. 승인·실패는 개발 전용 API(`/dev/fake-payments/:id/approve|fail`)를 부른다.
  - 결제창이 닫히면 `PaymentViewModel`이 `fetchStatus`를 1초 간격으로 최대 10번 묻는다(간격과 횟수는 생성자로 주입).

화면 문구(A8):
- 머리 `결제`. 제목 `{활동 이름}이\n오퍼를 수락했어요`.
- 내역: `콘텐츠` / `{형식} 1편`, (식사권이 있으면) `{식사권 이름}` / `방문 때 가게에서 제공`, `조회수당 (최대)` / `100,000원`, `서비스 수수료` / `10,000원`, `지금 결제할 금액` / `110,000원`.
- 안내 `조회수가 적어 다 쓰지 않은 금액은 7일 집계 후 돌려드려요.`
- 수단 고르기: `카드`, `계좌이체`, `간편결제`(처음 값 카드).
- 아래 안내 `결제 금액은 Cora가 보관하다가, 콘텐츠가 올라오고 조회수가 집계되면 크리에이터에게 지급해요.` 버튼 `결제하고 보관 맡기기`.
- 결과: 승인 → 사장님 홈으로 가고 `결제했어요. 크리에이터에게 알렸어요.` / 실패 또는 확인 시간 초과 → A8에 남고 `결제가 완료되지 않았어요. 다시 시도해 주세요.` / 확인 중 → 버튼 자리에 `결제를 확인하고 있어요`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('shows the quote with fee and total', ...);                    // '10,000원', '110,000원'
testWidgets('hides the voucher row for a per-view only offer', ...);
testWidgets('returns home with a confirmation when the payment is approved', ...);
testWidgets('stays and shows a retry message when the payment fails', ...);
testWidgets('shows a retry message when the status stays pending', ...);   // 주입한 횟수 소진
testWidgets('keeps polling after the checkout is closed without a result', ...);
testWidgets('prod build has no fake checkout route', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test`
- [ ] **Step 5: Commit** — `feat: 가게 결제 화면과 개발용 결제창 추가`

---

### Task 12: 앱 — 협업 진행(A7), 링크 제출, 식사권, 계좌, 인스타그램 연결

**Files:**
- Create: `app/lib/features/collaboration/domain/{collaboration.dart,collaboration_repository.dart}`, `data/api_collaboration_repository.dart`, `presentation/viewmodels/{collaboration_view_model.dart,collaboration_list_view_model.dart,submit_link_view_model.dart}`, `presentation/pages/{collaboration_page.dart,submit_link_page.dart,voucher_page.dart}`, `presentation/collaboration_text.dart`, `app/lib/features/payout_account/…`, `app/lib/features/instagram_connect/…`
- Modify: `app/lib/features/offers/presentation/pages/received_offers_page.dart`(진행 중 탭, 수락 조건), `app/lib/core/navigation/app_router.dart`
- Test: `app/test/features/collaboration/`, `app/test/features/payout_account/`, `app/test/features/instagram_connect/`, `app/test/features/offers/`(추가)

**Interfaces:**
- Consumes: `cora_api`의 협업·제출·계좌·인스타그램 호출 (Task 5, 7, 8, 9)
- Produces:
  - `class Collaboration`(서버의 `CollaborationModel`과 같은 항목), `enum CollaborationStage`, `enum StepState { done, now, todo }`
  - `abstract class CollaborationRepository { Future<List<Collaboration>> fetchActive(); Future<List<Collaboration>> fetchDone(); Future<Collaboration> fetch(String id); Future<Collaboration> submitLink(String id, String url); Future<void> cancel(String id); Future<void> requestCancel(String id); Future<void> acceptCancel(String id, String requestId); }`
  - `collaboration_text.dart`(순수 함수): `stepTitle(key)`, `stepSubtitle(Collaboration, key)`, `heldLabel(Collaboration)`, `dueLabel(DateTime due)`(`11월 23일까지`)
  - 라우트: `/creator/collaborations/:id`, `/creator/collaborations/:id/submit`, `/creator/collaborations/:id/voucher`, `/creator/payout-account`, `/creator/instagram`

화면 문구:
- A7 머리 `{가게 이름} 협업`. 상자: `Cora가 안전하게 보관 중`, `100,000원`, (식사권이 있으면) `+ {식사권 이름} (방문 때 사용)`. 아래 두 칸 `지금 받을 금액` / `43,200원`, `조회수` / `4,320회`. 제출 전에는 두 칸 대신 `링크를 제출하면 집계가 시작돼요.` 식사권만 있는 협업은 금액 자리에 식사권 이름이 크게 나온다.
- 단계: `오퍼 수락`(날짜), `가게 결제 완료` / `Cora가 금액을 보관해요`, `방문하고 촬영하기` / `식사권은 방문 때 보여주세요`, `콘텐츠 올리고 링크 제출` / `{기한}까지`, `7일간 조회수 집계 후 지급` / `최대 10만 원`.
- 버튼: `문의하기`, `콘텐츠 링크 제출`. `COUNTING`이면 주 버튼이 `집계 중이에요 · {n}일 남음`(눌리지 않음). `SETTLED`면 `{금액}원이 지급됐어요` 또는 계좌가 없으면 `지급받을 계좌 등록하기`.
- 식사권이 있으면 단계 아래에 `식사권 보여주기` → 큰 글자로 가게 이름, 식사권 이름, `협업 번호 {앞 8자리}`.
- `문의하기`는 `mailto:{OPERATOR_EMAIL}?subject=[Cora] 협업 {앞 8자리} 문의`. 주소는 `AppConfig.operatorEmail`(`--dart-define=OPERATOR_EMAIL`).
- 오른쪽 위 메뉴 `협업 그만두기`(`FUNDED`일 때만): 확인 `협업을 그만둘까요? 가게에 결제 금액을 모두 돌려드려요.` / `그만두기` / `계속하기`.
- 사장님의 취소 요청이 와 있으면 위에 띠: `{가게 이름}이 협업 취소를 요청했어요.` / `동의하기`.
- 링크 제출: 제목 `올린 콘텐츠의\n링크를 붙여 주세요`, 입력란 `콘텐츠 링크`, 안내 `제출한 뒤에는 고칠 수 없어요.`, 버튼 `제출하기`. 오류: `링크 형식을 확인해 주세요.`, `내 계정의 게시물만 제출할 수 있어요.`
- 계좌 등록: 제목 `지급받을 계좌를\n알려 주세요`, `은행`(고르기), `계좌번호`, `예금주`, 버튼 `등록하기`. 등록 뒤에는 `{은행} ****{뒤 4자리}`와 `바꾸기`.
- 인스타그램 연결: 제목 `인스타그램을\n연동해 주세요`, 설명 `조회수를 세고, 내 게시물만 제출할 수 있게 해요.`, 버튼 `인스타그램 연동하기`. 개발 빌드에서는 아이디 입력란이 있는 가짜 연결 화면이 뜬다. 연결 뒤 `@{아이디} 연동됨`.
- 받은 오퍼 카드(2번 A6): `needsInstagram`이면 `수락하기` 대신 `인스타그램을 연동하면 수락할 수 있어요`와 `연동하기`. 연동하고 돌아오면 `수락하기`가 된다.
- 받은 오퍼의 `진행 중` 탭은 `fetchActive()`의 협업을 줄로 보여 준다: 가게 이름, `결제를 기다리고 있어요` / `방문하고 촬영해 주세요 · {기한}까지` / `집계 중 · {n}일 남음`. 누르면 A7.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('describes each step for a funded collaboration', ...);
testWidgets('shows the held amount and the visit step as current', ...);
testWidgets('shows earned amount and views while counting', ...);          // '43,200원', '4,320회'
testWidgets('asks for a payout account when settled without one', ...);
testWidgets('submits a link and moves to counting', ...);
testWidgets('shows the server message for a link that is not mine', ...);
testWidgets('cancels after confirmation', ...);
testWidgets('accepts an owner cancel request from the banner', ...);
testWidgets('shows the voucher in large type', ...);
testWidgets('registers a payout account and shows only the last four digits', ...);
testWidgets('offers instagram connect instead of accept when needed', ...);
testWidgets('lists active collaborations on the in-progress tab', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 세 개: `feat: 크리에이터 협업 진행 화면과 링크 제출 추가`, `feat: 지급받을 계좌 등록 화면 추가`, `feat: 인스타그램 연동 화면과 수락 조건 표시 추가`

---

### Task 13: 앱 — 사장님 진행 화면과 취소 요청

**Files:**
- Create: `app/lib/features/collaboration/presentation/pages/store_collaboration_page.dart`
- Modify: `app/lib/features/store_home/…`(진행 중 줄), `app/lib/core/navigation/app_router.dart`(`/store/collaborations/:id`)
- Test: `app/test/features/collaboration/store_collaboration_page_test.dart`, `app/test/features/store_home/`(추가)

**Interfaces:**
- Consumes: `CollaborationRepository`, `collaboration_text.dart` (Task 12)
- Produces: 사장님 홈의 보낸 오퍼 줄 가운데 협업이 있는 것은 누르면 이 화면으로 간다. 줄의 문구: `결제했어요, 방문을 기다려요` / `집계 중 · {n}일 남음` / `끝났어요 · {환급액}원 환급`.

화면 문구:
- 머리 `{활동 이름}과의 협업`. 상자: `보관 중인 금액` / `100,000원`, 두 칸 `현재 조회수` / `4,320회`, `예상 환급액` / `56,800원`. 제출 전에는 `크리에이터가 링크를 제출하면 집계가 시작돼요.`
- 단계는 A7과 같고 사장님 쪽 말로 바꾼다: `오퍼 수락됨`, `결제 완료`, `크리에이터 방문·촬영`, `콘텐츠 게시` / `{기한}까지`, `7일 집계 후 정산`.
- 제출된 링크가 있으면 `올라온 콘텐츠 보기`(외부 브라우저).
- 버튼 `문의하기`. 메뉴 `협업 취소 요청`(`FUNDED`일 때만): 확인 `크리에이터가 동의하면 취소되고 결제 금액을 모두 돌려받아요.` / `요청하기`. 요청 뒤 띠 `취소 요청을 보냈어요. 3일 안에 답이 없으면 요청이 사라져요.`
- `SETTLED`: `정산이 끝났어요.` / `지급 {금액}원 · 환급 {금액}원`.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('shows held amount, views and expected refund', ...);
testWidgets('opens the submitted content link', ...);
testWidgets('sends a cancel request after confirmation and shows the banner', ...);
testWidgets('shows the final payout and refund when settled', ...);
testWidgets('opens the collaboration from the sent offers row', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 사장님 협업 진행 화면과 취소 요청 추가`

---

### Task 14: 전체 흐름 확인

**Files:** 없음

- [ ] **Step 1: 자동 확인**

Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
Run: `cd app && flutter analyze && flutter test`
Run: `./scripts/gen-api.sh && git status --short` — Expected: 변경 없음

- [ ] **Step 2: 두 계정으로 수동 확인** (계정 A 가게, B 크리에이터. 날짜를 건너뛰려면 서버를 `FAKE_CLOCK_OFFSET_DAYS=<n>`으로 다시 띄운다 — 이 환경변수는 `NODE_ENV=development`에서만 `SystemClock`에 더해지도록 이 단계에서 넣는다.)

1. A가 릴스 + 조회수 오퍼를 보낸다. B의 카드에 `연동하기`가 보인다. B가 연동하고 수락한다.
2. A: `결제하기` → 견적 `110,000원` → 가짜 결제창 `결제 승인` → `결제했어요. 크리에이터에게 알렸어요.`
3. A: 가짜 결제창에서 `닫기`만 누른 경우 `결제가 완료되지 않았어요.`가 뜨는지(새 오퍼로 확인).
4. B: A7에 `100,000원`과 `방문하고 촬영하기`가 현재 단계. `식사권 보여주기`.
5. B: 링크 `https://www.instagram.com/reel/abc?views=4320` 제출 → `집계 중이에요 · 7일 남음`.
6. 서버를 7일 뒤로 띄운다 → B: `지급받을 계좌 등록하기` → 등록 → `43,200원이 지급됐어요`. A: `지급 43,200원 · 환급 56,800원`.
7. `yarn ops show --collaboration <id>`: `ESCROW 0`, `CREATOR_PAYABLE 43200`, `STORE_REFUND 56800`, `FEE_REVENUE 10000`.
8. 새 오퍼로: 결제 뒤 B가 `협업 그만두기` → A에게 환급 `110,000원`.
9. 새 오퍼로: 결제 뒤 14일을 건너뛴다 → 양쪽에 종료 알림, `REFUNDED`.
10. 새 오퍼로: 링크에 `unavailable`을 넣고 3일을 건너뛴다 → 운영자 알림 로그, `HALTED` → `yarn ops resume-settlement --views 5000` → 지급 `50,000원`.
11. 식사권만 있는 오퍼: 결제 없이 진행되고 링크 제출로 바로 끝난다.

- [ ] **Step 3: 장부 전체 점검** — 테스트 DB의 모든 협업에 대해 `assertBalanced`를 도는 스크립트 `api/scripts/check-ledger.ts`를 만들고 실행한다. Expected: `모든 협업의 장부가 맞습니다 (n건)`.

---

## 완료 기준

- Task 14의 자동 확인과 수동 확인 11개, 장부 점검 통과
- 운영 환경 모드(`NODE_ENV=production`)에서 가짜 어댑터가 하나라도 있으면 서버가 시작을 거부하고, 개발 전용 결제 라우트가 없음

## 이 계획이 하지 않는 것

- 브랜드 계약의 결제와 고정 제작비 정산 (5번 계획. 이 계획은 단계 값과 제출 검사만 미리 넣는다)
- 실제 PG, 송금, 조회수, 인스타그램 연결 (9번 계획)
- 인스타그램 게시물 가져오기 (7번 계획)
