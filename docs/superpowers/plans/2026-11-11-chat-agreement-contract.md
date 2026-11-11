# 대화·조건 합의·계약 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ] **Step N**`) syntax for tracking.

**Goal:** 협업마다 대화방이 열려 당사자 둘이 글과 콘텐츠 카드를 주고받고, 브랜드 계약은 조건을 버전으로 고쳐 가며 합의한 뒤 크리에이터 동의 → 브랜드 동의와 결제로 계약을 맺고, 게시 링크 제출 뒤 정확히 N일째에 제작비 전액을 지급하는 데까지를 만든다.

**Architecture:** 대화방은 협업과 일대일이고 협업이 생기는 세 곳(서로 관심, 가게 오퍼 수락, "조건부터 질문하기")에서 같은 트랜잭션으로 만든다. 메시지는 REST로 보내고, 서버가 방마다 번호를 매겨 저장한 뒤 WebSocket 게이트웨이(Redis 어댑터)로 참가자에게 밀어 주며, 연결이 없으면 `PushPort`로 알린다. 조건 버전·계약 동의·결제 승인은 모두 `collaborations.latestTermsVersion`과 단계에 건 조건부 갱신으로 처리한다. 브랜드 결제와 고정 지급은 3번의 `payments`, 장부, `settlements`, 작업 큐를 그대로 쓴다.

**Tech Stack:** 앞 계획들과 같다. 추가: 서버 `@nestjs/websockets`, `@nestjs/platform-socket.io`, `socket.io`, `@socket.io/redis-adapter`, `ioredis`, 테스트용 `socket.io-client` / 앱 `socket_io_client`.

**Spec:** `docs/superpowers/specs/2026-11-11-chat-agreement-contract-design.md` · 우선 규칙: `docs/superpowers/specs/2026-11-11-collaboration-common-model.md` (1, 2, 5, 7, 8, 9, 10, 14, 19장) · 상위: `docs/superpowers/specs/2026-11-11-tech-stack-design.md`

**선행 조건:** 공통 기반, 2번, 3번, 4번 계획이 끝나 있어야 한다. 이 계획은 3번의 `collaborations`·`CollaborationStage`·`canTransition`·`isMoneyHeld`·`CollaborationsRepository.advance`·`PaymentsService.applyResult`·`LedgerService`·`feeFor`·`postingsFor*`·`SettlementsService`·`PayoutsService`·`RefundsService`·`JobScheduler`·`OperatorAlertPort`·운영 명령·앱의 `collaboration`·`payment`(`PaymentRepository`, `CheckoutLauncher`, `FakeCheckoutPage`), 4번의 `terms_versions`·`TermsService.createVersion/latest/confirm`·`draftTerms`·`matches`·`swipe_decisions`·`GET /discovery/received-proposals`·`VisibilityService`·앱의 `negotiation`·`interests`·`match_sheet`, 2번의 `OffersService`·`StoragePort.publicUrl`·`Clock`·`won()`·`CoraBottomNav`를 그대로 쓴다.

## Global Constraints

앞 계획들의 Global Constraints가 모두 적용된다. 이 계획에서 더해지는 것:

- 고정 값: 메시지 `1000`자, 푸시 미리 보기 `60`자(넘으면 60자 + `…`), 메시지 한 번에 `50`개, 신고 설명 `500`자, 조건 제목 `1~40`자, 제작비 `10000~10000000`원·1만 원 단위, 편 수 `1~3`, 지급 조건 `7` 또는 `14`일, 브랜드 계약 멈춤 점검 계약 후 `60`일, 결제 진행 중 잠금 `60`분, 앱 재연결 간격 `1·2·4·8·16·30`초(30초에서 멈춤).
- 대화방·메시지·조건 버전·계약은 당사자만 읽고 쓴다. 남의 것을 ID로 요청하면 404 `NOT_FOUND`. 게이트웨이 이벤트도 참가자의 방(`user:<id>`)으로만 보낸다.
- 메시지 번호는 `conversations.lastSeq`를 조건부로 올린 값이다. 같은 방에 같은 번호가 두 번 생기지 않는다(유일 제약). 앱이 보낸 `clientId`가 같으면 두 번째 요청은 새 행을 만들지 않고 첫 행을 돌려준다.
- 조건 버전 만들기, 조건 확인, 크리에이터 동의, 브랜드 동의는 먼저 `UPDATE collaborations ... WHERE id = ? AND latest_terms_version = <기대 버전> AND stage IN (...)`을 하고, 바뀐 행이 0이면 409 `CONFLICT`.
- 안내 줄(`SYSTEM` 메시지)은 코드와 값만 저장하고 문구는 읽는 사람에 맞춰 서버가 만든다. 상대에게 그만둔 이유와 차단 사실을 알리지 않는다.
- WebSocket은 상태를 바꾸지 않는다. 새 메시지와 방의 변경을 밀어 주기만 한다. 이벤트 이름: `message.created`, `conversation.updated`, `session.expired`.
- 새 테이블 6개(`conversations`, `conversation_members`, `messages`, `blocks`, `reports`, `contracts`)에 RLS를 켠다.
- 작업 브랜치는 `feat/chat-agreement-contract`. push는 소유자 확인 후에만 한다.

## Review Focus

1. **두 사람이 거의 동시에 조건 수정 제안을 보냄** → 하나만 다음 버전이 되고 다른 하나는 409, 확인과 제안이 엇갈려도 지난 버전이 합의되지 않는다. (Task 6)
2. **크리에이터가 동의한 뒤, 또는 브랜드 결제창이 열린 사이에 조건이 바뀜** → 동의가 취소되고, 결제 중에는 제안이 409이며, 취소된 계약에 승인이 와도 계약 없이 전액 환급된다. (Task 6, 7)
3. **대화방에 없는 사람이 ID로 읽거나 보내거나 소켓으로 엿들음** → 404이고 이벤트가 가지 않는다. (Task 2, 4)
4. **보내기를 다시 누르거나 연결이 끊겼다 붙음** → 메시지가 두 번 생기지 않고, 빠진 번호를 받아 순서대로 보인다. (Task 2, 10)
5. **결제 링크 제출 뒤 N일** → N일에서 1분 모자라면 지급하지 않고, 정확히 N일째에 제작비 전액을 한 번만 지급한다. (Task 8)

---

## 파일 구조

```text
api/src/
├── conversations/                      # system-lines.ts, message-preview.ts(순수 함수), module, controller, service, repository
├── realtime/                           # 게이트웨이, RealtimePublisher, PresenceService
├── safety/                             # 차단, 신고
├── terms/terms-diff.ts                 # 순수 함수: 바뀐 항목 (4번의 terms 모듈에 더함)
├── contracts/                          # consent-texts.ts(순수 함수: 확인란 세 문구), module, controller, service, repository
└── jobs/handlers/{settle-fixed.handler.ts,brand-halt-check.handler.ts}

app/lib/features/
├── chat/                               # 대화 목록, 메시지 요청(11), 대화방(D3), 실시간 연결
├── proposals/                          # 받은 제안(10)
└── negotiation/                        # (4번) + 조건 합의(12), 수정 제안, 계약(D4)
```

---

### Task 1: 스키마와 단계 전이

**Files:**
- Modify: `api/prisma/schema.prisma`, `api/src/collaborations/collaboration-stage.ts`, `api/src/discovery/discovery.service.ts`(매칭 때 `latestTermsVersion = 1`)
- Create: 마이그레이션
- Test: `api/test/db/chat-contract-schema.db-spec.ts`, `api/src/collaborations/collaboration-stage.spec.ts`(추가)

**Interfaces:**
- Produces:
  - `enum ConversationStatus { REQUESTED, OPEN, DECLINED, CLOSED }`, `enum MessageKind { TEXT, CONTENT_CARD, SYSTEM }`, `enum ReportTargetKind { USER, CONVERSATION }`(7번이 `CONTENT`를 더한다), `enum ReportReason { SPAM, ABUSE, FRAUD, OTHER }`, `enum DropReason { SCHEDULE, BUDGET, DIRECTION, OTHER, REQUEST_DECLINED, BLOCKED }`, `enum ContractStatus { AWAITING_BRAND, CONCLUDED, VOIDED }`
  - `Conversation` → `conversations`: `collaborationId`(unique), `status`, `requestedById?`, `lastSeq Int @default(0)`, `lastMessageAt?`, `closedReason?`(`BLOCKED`)
  - `ConversationMember` → `conversation_members`: `conversationId`, `userId`, `lastReadSeq Int @default(0)`, `mutedAt?`. 유일 제약 `(conversationId, userId)`.
  - `Message` → `messages`: `conversationId`, `seq`, `senderId?`(안내 줄은 null), `clientId?`, `kind`, `text?`, `cardTitle?`, `cardPhotoPath?`, `systemCode?`, `systemParams Json?`. 유일 제약 `(conversationId, seq)`, `(conversationId, senderId, clientId)`.
  - `Block` → `blocks`: `blockerId`, `blockedId`. 유일 제약 `(blockerId, blockedId)`.
  - `Report` → `reports`: `reporterId`, `targetKind`, `targetId`, `reason`, `detail?`, `resolvedAt?`, `resolvedBy?`. 유일 제약 `(reporterId, targetKind, targetId)`.
  - `Contract` → `contracts`: `collaborationId`, `status`, `termsVersion Int`, `termsSnapshot Json`(`TermsVersionModel`의 값 사본), `creatorConsentedAt`, `creatorConsentTexts String[]`, `brandConsentTexts String[]`, `brandConsentedAt?`, `paymentId?`(unique), `concludedAt?`, `voidedAt?`, `voidReason?`(`NEW_TERMS | DROPPED | BLOCKED`). 부분 유니크 `(collaboration_id) WHERE status <> 'VOIDED'`.
  - `collaborations`에 추가: `latestTermsVersion Int @default(0)`, `creatorNote?`(40자), `dropReason?`, `droppedById?`, `contractedAt?`, `extraRevisionsAllowed Int @default(0)`(브랜드의 "수정 한 번 더 허용" 횟수. 6번 계획이 올린다)
  - 마이그레이션의 데이터 단계: 기존 협업마다 `OPEN` 대화방과 참가자 두 줄을 만들고, `latestTermsVersion`을 그 협업의 최대 조건 버전으로 채운다.
  - `canTransition`에 더함: `INQUIRY → MATCHED`, `INQUIRY → DROPPED`, `AGREED → NEGOTIATING`(새 버전), `AGREED → CONTRACTED`. `MATCHED`·`NEGOTIATING`·`AGREED → DROPPED`는 3번 그대로. 상수 `preContractStages` = `[INQUIRY, MATCHED, NEGOTIATING, AGREED]`, `negotiableStages` = `[MATCHED, NEGOTIATING, AGREED]`.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('allows INQUIRY to become MATCHED in the same row and AGREED to fall back to NEGOTIATING', ...);
it('rejects two messages with the same sequence number in one conversation', ...);
it('rejects a second message with the same sender and client id', ...);
it('allows only one live contract per collaboration but keeps voided ones', ...);
it('rejects a second report by the same reporter on the same target', ...);
it('backfills an open conversation for every existing collaboration', ...);
```

- [ ] **Step 2~4: 실패 확인 → 스키마, 마이그레이션(새 테이블 6개의 RLS), 전이 구현 → 통과 확인** — Run: `cd api && yarn prisma migrate dev && yarn test collaboration-stage && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — `feat: 대화·차단·신고·계약 스키마와 협상 단계 전이 추가`

---

### Task 2: 대화방과 메시지 API

**Files:**
- Create: `api/src/conversations/{conversations.module.ts,conversations.controller.ts,conversations.service.ts,conversations.repository.ts,system-lines.ts,message-preview.ts,dto/*.ts}`
- Modify: `api/src/discovery/discovery.service.ts`(매칭 때 대화방), `api/src/offers/offers.service.ts`(수락 때 대화방), `api/src/discovery/dto/decision-result.model.ts`, `api/src/collaborations/dto/collaboration.model.ts`
- Test: `api/src/conversations/system-lines.spec.ts`, `api/src/conversations/message-preview.spec.ts`, `api/src/conversations/conversations.service.spec.ts`, `api/test/conversations.e2e-spec.ts`

**Interfaces:**
- Consumes: `Clock`, `StoragePort.publicUrl`, `CreatorsService`(카드 제목·사진), 3번 `CollaborationsRepository`, 4번 `TermsService.latest`
- Produces:
  - `ConversationsService.openForCollaboration(collaborationId, opts: { status: 'OPEN' | 'REQUESTED'; requestedById?: string }, tx): Promise<Conversation>` — 방과 참가자 두 줄(맡기는 쪽, 크리에이터)
  - `ConversationsService.postSystem(conversationId, code: SystemCode, params: Record<string, string | number>, tx?): Promise<MessageModel>`
  - `type SystemCode = 'MATCHED' | 'OFFER_ACCEPTED' | 'REQUEST_ACCEPTED' | 'TERMS_PROPOSED' | 'TERMS_CONFIRMED' | 'TERMS_AGREED' | 'CREATOR_CONSENTED' | 'CONSENT_VOIDED' | 'CONTRACT_CONCLUDED' | 'DROPPED'`, `renderSystemLine(code, params, viewer: { userId; role: 'COMMISSIONER' | 'CREATOR' }): string` (`system-lines.ts`) — 문구는 "이 계획이 구체화한 것"의 표 그대로. `TERMS_PROPOSED` → `{이름}님이 조건 버전 {n}을 제안했어요.`(제안한 본인에게는 `조건 버전 {n}을 제안했어요.`), `TERMS_AGREED` → `양쪽이 조건 버전 {n}을 확인했어요.`, `DROPPED` → 그만둔 사람 `협의를 그만뒀어요.` / 상대 `이번에는 함께하기 어렵대요.`
  - `MessageModel { id; seq; kind: 'TEXT' | 'CONTENT_CARD' | 'SYSTEM'; mine: boolean; clientId: string | null(내 것만); text: string | null(안내 줄은 렌더한 문구); card: { title: string; photoUrl: string | null } | null; createdAt }`
  - `ConversationSummaryModel { id; kind: 'BRAND_CONTRACT' | 'STORE_OFFER'; status; section: 'REQUEST' | 'NORMAL'; counterpart: { userId; name; photoUrl: string | null }; contextLabel: string(캠페인 한 줄 또는 가게 이름); lastMessage: { kind; preview: string; at: string } | null; unreadCount: number; muted: boolean }`
  - `ConversationDetailModel` = 요약 + `{ collaborationId; stage; myRole; requestedByMe: boolean; blockedByMe: boolean; lastSeq; lastReadSeq; terms: TermsVersionModel | null; campaignTerms: { fee; format; productProvided; startFrom } | null(INQUIRY일 때); storeTerms: OfferTermsModel | null; contractStatus: 'NONE' | 'AWAITING_BRAND' | 'CONCLUDED'; canSend; canSendContentCard; canProposeTerms; canDrop; canLikeCampaign(INQUIRY의 크리에이터) }`
  - `GET /conversations` → 200 `ConversationSummaryModel[]` — `REQUEST` 먼저, 다음 `lastMessageAt` 최근 순. 내가 거절한 요청은 빠지고, 거절당한 요청은 `DECLINED`로 남는다. `operationId: listConversations`
  - `GET /conversations/:id` → 200 `ConversationDetailModel` | 404. `operationId: getConversation`
  - `GET /conversations/:id/messages?afterSeq=&beforeSeq=&limit=50` → 200 `MessageModel[]`(번호 오름차순). 둘 다 없으면 마지막 50개. `operationId: listMessages`
  - `POST /conversations/:id/messages` 본문 `{ clientId: uuid; kind: 'TEXT' | 'CONTENT_CARD'; text?: string(1~1000) }` → 201 `MessageModel`. `CONTENT_CARD`는 크리에이터만, 서버가 `cardHeadline`·`cardPhotoPath`를 사본으로 넣는다(카드가 없으면 409). 방이 `OPEN`이 아니면 409(요청 중에는 양쪽 모두 보낼 수 없다. 요청의 첫 메시지는 Task 3이 만든다). 저장 뒤 `MessageCreated` 이벤트를 낸다(Task 4가 받는다). `operationId: sendMessage`
  - `POST /conversations/:id/read` 본문 `{ seq }` → 204. `lastReadSeq = GREATEST(lastReadSeq, seq)`, `seq`는 `lastSeq`를 넘을 수 없다. `operationId: markConversationRead`. `PUT /conversations/:id/mute` 본문 `{ muted: boolean }` → 200 `{ muted }`. `operationId: setConversationMuted`
  - 서로 관심(4번)과 오퍼 수락(2·3번)이 협업과 함께 `OPEN` 방을 만들고 안내 줄 `MATCHED` / `OFFER_ACCEPTED`를 넣는다. `DecisionResultModel`에 `conversationId: string | null`.
  - `CollaborationModel`에 `conversationId`, `contractStatus`, `extraRevisionsAllowed` 추가.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('renders the proposal line differently for the proposer and the other side', ...);
it('cuts a preview at 60 characters with an ellipsis', ...);              // 61자 → 60자 + '…', 60자 → 그대로
it('opens a conversation with both members on a mutual like', ...);
it('numbers 20 concurrent sends without gaps or duplicates', ...);        // Promise.all, seq 1~20
it('returns the first message again for a repeated client id', ...);      // 행 1개
it('copies the creator card title and photo path into a content card', ...);
it('returns 404 to a user who is not a member for every conversation route', ...);
it('pages backwards with beforeSeq and forwards with afterSeq', ...);
it('counts unread messages from lastReadSeq and never moves it backwards', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 대화방과 메시지 API 추가`, `feat: 서로 관심과 오퍼 수락 때 대화방 열기`

---

### Task 3: 메시지 요청과 "조건부터 질문하기"

**Files:**
- Modify: `api/src/discovery/{discovery.controller.ts,discovery.service.ts,discovery.repository.ts,dto/*.ts}`, `api/src/terms/draft-terms.ts`, `api/src/conversations/*`
- Test: `api/test/message-requests.e2e-spec.ts`, `api/test/discovery.e2e-spec.ts`(추가)

**Interfaces:**
- Consumes: Task 2, 4번 `draftTerms`·`TermsService.createVersion`·`putDecision`, `PushPort`
- Produces:
  - `POST /discovery/received-proposals/:campaignId/inquiry` 본문 `{ message: string(1~1000); contentLine?: string(40) }` → 201 `{ collaborationId; conversationId }` — `CREATOR` 역할. 그 캠페인의 브랜드가 나에게 `note` 있는 `LIKE`를 보냈어야 한다(아니면 404). 한 트랜잭션에서 협업(`BRAND_CONTRACT`, `INQUIRY`, `settlementMethod: FIXED`, `creatorNote = contentLine`), `REQUESTED` 방(`requestedById` = 나), 첫 메시지(번호 1). (캠페인, 크리에이터)에 협업이 이미 있으면 409. 브랜드에게 푸시 `메시지 요청` / `{이름}님이 메시지를 보냈어요.` `operationId: createInquiry`
  - `POST /conversations/:id/request/accept` → 200 `ConversationDetailModel` — 받은 사람만. `REQUESTED → OPEN` 조건부, 안내 줄 `REQUEST_ACCEPTED`, 보낸 사람에게 푸시. 협업은 `INQUIRY`에 남는다. `operationId: acceptMessageRequest`
  - `POST /conversations/:id/request/decline` → 204 — 받은 사람만. `REQUESTED → DECLINED`, 협업 `INQUIRY → DROPPED`(`dropReason = REQUEST_DECLINED`). 푸시는 보내지 않는다. `operationId: declineMessageRequest`
  - `GET /discovery/received-proposals`는 이미 협업이 있는 캠페인을 뺀다.
  - 서로 관심 판정(4번) 수정: (캠페인, 크리에이터)에 `INQUIRY` 협업이 있으면 새로 만들지 않고 `INQUIRY → MATCHED`, 조건 버전 1(`title = 크리에이터의 note ?? creatorNote ?? 캠페인 한 줄`), `latestTermsVersion = 1`, 방이 `REQUESTED`면 `OPEN`으로, 안내 줄 `MATCHED`. 응답의 `collaborationId`, `conversationId`는 기존 행.
  - `ConversationDetailModel.canLikeCampaign` — `INQUIRY`이고 내가 크리에이터이고 방이 `OPEN`일 때 true(앱이 대화방 머리에 `관심 보내기`를 둔다).

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('sends an inquiry as a request with one first message', ...);          // stage INQUIRY, status REQUESTED, seq 1
it('returns 404 for an inquiry without a noted like from the brand', ...);
it('lets the requester send nothing more until the request is accepted', ...);  // 409
it('opens the conversation when the brand accepts and keeps INQUIRY', ...);
it('hides a declined request from the brand and shows DECLINED to the creator', ...);
it('drops the inquiry collaboration on decline so it cannot be asked again', ...);
it('upgrades the same INQUIRY row to MATCHED with version 1 on a later mutual like', ...);   // collaborations 1행, conversations 1행
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 메시지 요청과 조건부터 질문하기 추가`

---

### Task 4: 실시간 게이트웨이와 푸시 알림

**Files:**
- Create: `api/src/realtime/{realtime.module.ts,realtime.gateway.ts,realtime-publisher.ts,socket-io-realtime-publisher.ts,presence.service.ts,redis-io.adapter.ts}`, `api/test/support/{fake-realtime-publisher.ts,fake-presence.ts}`
- Modify: `api/src/auth/token-verifier.ts`(결과에 `expiresAt`), `api/test/support/fake-token-verifier.ts`, `api/src/main.ts`(Redis 어댑터), `api/src/conversations/conversations.service.ts`
- Test: `api/src/conversations/message-notifier.spec.ts`, `api/test/realtime.e2e-spec.ts`

**Interfaces:**
- Consumes: `TokenVerifier`, `Clock`, `PushPort`, `Env.REDIS_URL`(3번), Task 2
- Produces:
  - `TokenVerifier.verify(token): Promise<{ userId: string; expiresAt: Date }>` — 가짜는 토큰 `expiring:<user>`면 `Clock.now() + 1초`, 나머지는 `+ 1시간`
  - 게이트웨이: 네임스페이스 `/realtime`, 연결 때 `handshake.auth.token`을 검증하고 실패하면 바로 끊는다. 통과하면 방 `user:<userId>`에 넣고 `expiresAt`에 `session.expired`를 보낸 뒤 끊는다. 앱이 보내는 이벤트는 받지 않는다.
  - `abstract class RealtimePublisher { abstract toUsers(userIds: string[], event: 'message.created' | 'conversation.updated', payload: object): Promise<void> }` — 실제 구현은 `server.to('user:'+id).emit`(Redis 어댑터로 여러 서버에 퍼진다). 테스트는 `FakeRealtimePublisher`(보낸 것을 기록).
  - `abstract class PresenceService { abstract isOnline(userId): Promise<boolean> }` — 실제는 `fetchSockets()`가 하나라도 있으면 true
  - 페이로드: `message.created` = `{ conversationId; message: MessageModel }`(받는 사람 기준으로 `mine`을 맞춰 따로 보낸다), `conversation.updated` = `{ conversationId; reason: 'TERMS' | 'CONTRACT' | 'STATUS' | 'READ' }`
  - `MessageNotifier.onCreated(conversationId, message)` — 참가자 둘에게 `message.created`. 보낸 사람이 아닌 쪽이 연결돼 있지 않고 알림을 끄지 않았으면 `PushPort.send({ userId, title: 보낸 사람 이름, body: previewOf(text) })`. 콘텐츠 카드는 `콘텐츠 카드를 보냈어요.`, 안내 줄은 렌더한 문구. 계약 체결 알림(Task 7)은 알림 끄기와 상관없이 보낸다. 조건·계약·방 상태가 바뀌는 모든 곳(Task 3, 5, 6, 7)은 `conversation.updated`를 낸다.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('pushes a new message to both members and to nobody else', ...);      // 세 번째 사용자의 소켓은 아무것도 받지 않음
it('sends session.expired and disconnects when the token expires', ...);  // 'expiring:user-a', jest fake timers
it('sends a push with a 60 character preview when the receiver is offline', ...);
it('does not push when the receiver is connected', ...);
it('does not push a muted conversation', ...);
it('delivers through the redis adapter between two server instances', ...);   // app 두 개, 같은 REDIS_URL
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — `docker compose up -d redis` 상태에서 `yarn test:e2e realtime`
- [ ] **Step 5: Commit** — `feat: 대화 실시간 전달과 푸시 알림 추가`

---

### Task 5: 차단, 신고, 공통 필터

**Files:**
- Create: `api/src/safety/{safety.module.ts,blocks.controller.ts,reports.controller.ts,safety.service.ts,safety.repository.ts,dto/*.ts}`, `api/src/ops/commands/{resolve-report.command.ts,show-conversation.command.ts}`
- Modify: `api/src/visibility/visibility.service.ts`, `api/src/offers/offers.service.ts`(`cancelForBlock`), `api/src/conversations/conversations.service.ts`
- Test: `api/src/safety/safety.service.spec.ts`, `api/test/safety.e2e-spec.ts`, `api/test/visibility.e2e-spec.ts`(추가), `api/test/ops.e2e-spec.ts`(추가)

**Interfaces:**
- Consumes: `isMoneyHeld` (3번), `OperatorAlertPort`, `VisibilityService` (4번), Task 2, 4
- Produces:
  - `POST /conversations/:id/block` → 200 `ConversationDetailModel` — 참가자만. 두 사람 사이의 협업 중 하나라도 `isMoneyHeld`이면 409 `진행 중인 협업이 있어요. 문의하기로 알려 주세요.` 통과하면 한 트랜잭션에서: `blocks` 행, 두 사람 사이의 모든 방 `CLOSED`(`closedReason = BLOCKED`), 계약 전 브랜드 협업 `DROPPED`(`dropReason = BLOCKED`, 살아 있는 계약은 `VOIDED`), 결제 전 가게 협업은 `OffersService.cancelForBlock(offerId)`로 오퍼 `CANCELLED`·협업 `CANCELLED`. 안내 줄은 남기지 않는다. `operationId: blockConversationMember`
  - 닫힌 방에 보내면 409. `blockedByMe`가 true면 앱은 `차단한 대화예요.`, false면 `대화가 종료됐어요.`
  - `VisibilityService.creatorVisibleTo`·`commissionerVisibleTo`·`filterCreators`가 양방향 차단을 뺀다. 차단한 상대에게 오퍼·지원·관심을 보내면 404.
  - `POST /reports` 본문 `{ targetKind: 'USER' | 'CONVERSATION'; targetId; reason: 'SPAM' | 'ABUSE' | 'FRAUD' | 'OTHER'; detail?: string(500) }` → 201 `{ id }`. 대상은 내가 참가한 방이나 그 상대여야 한다(아니면 404). 두 번째는 409 `이미 신고했어요.` 저장 뒤 `OperatorAlertPort.alert({ subject: '[Cora] 신고 접수 · {사유}', body: 신고 ID, 대상, 신고자 ID, 설명 })`. `operationId: createReport`
  - 운영 명령: `yarn ops resolve-report --report <id>`(`resolvedAt`, `resolvedBy`), `yarn ops show-conversation --conversation <id> [--limit 50]`(메시지를 출력, 읽은 사실을 `ops_audit_logs`에 남긴다). 둘 다 `--operator`, `--reason` 필수.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('refuses to block while money is held in any collaboration between the two', ...);   // CONTRACTED → 409
it('closes every conversation between the two and rejects sends from both sides', ...); // 409
it('drops a negotiating brand collaboration and voids its contract on block', ...);
it('hides blocked users from recommendations in both directions', ...);
it('returns 404 when offering to a creator who blocked the store owner', ...);
it('stores a report and emails the operator once', ...);                  // FakeOperatorAlert 1건
it('refuses a second report on the same target', ...);                    // 409
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 대화 차단과 추천 제외 추가`, `feat: 신고 접수와 운영자 알림 추가`

---

### Task 6: 조건 수정 제안, 합의 안내, 협의 그만두기

**Files:**
- Create: `api/src/terms/terms-diff.ts`, `api/src/terms/dto/{propose-terms.dto.ts,terms-history.model.ts}`, `api/src/collaborations/dto/drop-collaboration.dto.ts`
- Modify: `api/src/terms/{terms.controller.ts,terms.service.ts,terms.repository.ts}`, `api/src/collaborations/{collaborations.controller.ts,collaborations.service.ts}`
- Test: `api/src/terms/terms-diff.spec.ts`, `api/src/terms/terms.service.spec.ts`(추가), `api/test/terms.e2e-spec.ts`, `api/test/drop.e2e-spec.ts`

**Interfaces:**
- Consumes: 4번 `TermsService`, Task 1·2·4, `Clock`, `kstDay`
- Produces:
  - `type TermsField = 'TITLE' | 'FEE' | 'START_DATE' | 'DELIVERABLE' | 'PRODUCT' | 'REVISION' | 'USAGE' | 'PAYOUT'` (`DELIVERABLE` = 형식과 편 수)
  - `diffTerms(prev: TermsValues | null, next: TermsValues): TermsField[]` (순수 함수, 버전 1은 빈 배열). `TermsVersionModel`에 `changedFields: TermsField[]`, `createdAt` 추가
  - `GET /collaborations/:id/terms` → 200 `TermsHistoryModel { versions: TermsVersionModel[](최신 먼저); agreement: 'NONE' | 'WAITING_BRAND' | 'WAITING_CREATOR' | 'AGREED'; editable: boolean }` — 최신 버전의 확인 상태로 정한다(이전 버전의 확인은 보지 않는다). `editable`은 `negotiableStages`이고 결제 잠금이 없을 때. `operationId: listTermsVersions`
  - `POST /collaborations/:id/terms` 본문 `{ baseVersion: number; title?; fee?; startDate?; format?; pieces?; productProvided?; revisionScope?; usageRights?; payoutDays? }` → 201 `TermsVersionModel` — 당사자만, `BRAND_CONTRACT`이고 `negotiableStages`일 때만. 값 검사: 제목 1~40자, 제작비 1만 원 단위 10000~10000000, 시작일은 한국 날짜로 오늘 이후(오늘 포함), 편 수 1~3, 지급 7 | 14. 광고 표시는 받지 않는다. 바뀐 항목이 없으면 400 `바꾼 조건이 없어요.` 한 트랜잭션에서: `latestTermsVersion = baseVersion`에 건 조건부 갱신(0행이면 409 `상대가 먼저 새 조건을 제안했어요.`), 버전 `baseVersion + 1` 삽입(제안한 쪽 확인 시각 = now), 단계 `MATCHED`·`AGREED → NEGOTIATING`, 살아 있는 계약 `AWAITING_BRAND → VOIDED`(`NEW_TERMS`, 안내 줄 `CONSENT_VOIDED`), 안내 줄 `TERMS_PROPOSED`. 브랜드 결제가 `PENDING`이고 요청이 60분 안이면 409 `브랜드가 결제를 진행하고 있어요. 잠시 뒤 다시 시도해 주세요.` 상대에게 푸시. `operationId: proposeTerms`
  - 4번 `POST /collaborations/:id/terms/:version/confirm` 수정: 같은 조건부 갱신을 먼저 하고, 안내 줄 `TERMS_CONFIRMED`(한쪽) 또는 `TERMS_AGREED`(양쪽), `conversation.updated`.
  - `POST /collaborations/:id/drop` 본문 `{ reason: 'SCHEDULE' | 'BUDGET' | 'DIRECTION' | 'OTHER' }` → 200 `CollaborationModel` — 당사자만, `preContractStages`일 때만(아니면 409), 결제 잠금 중이면 409. `→ DROPPED`(`dropReason`, `droppedById`), 살아 있는 계약 `VOIDED`(`DROPPED`), 안내 줄 `DROPPED`, 상대에게 푸시 `이번에는 함께하기 어렵대요.` 방은 열어 둔다. `operationId: dropCollaboration`

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('lists the changed fields between two versions', ...);                 // fee·startDate → ['FEE','START_DATE']
it('creates version 2 with the proposer already confirmed', ...);
it('moves MATCHED and AGREED to NEGOTIATING on a new version', ...);
it('lets only one of two concurrent proposals on the same base win', ...); // Promise.all → 201 하나, 409 하나, 버전 2만 존재
it('refuses to confirm version 2 once version 3 exists', ...);            // 409
it('does not count confirmations of an older version toward agreement', ...);
it('rejects a proposal with no change, a fee not in 10000 steps, or a past start date', ...);
it('voids the creator consent when a new version is proposed', ...);
it('refuses a proposal while the brand payment is pending', ...);          // 409, 61분 뒤에는 허용
it('drops before contract and tells the other side only that it will not continue', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 조건 수정 제안과 합의 안내 추가`, `feat: 계약 전 협의 그만두기 추가`

---

### Task 7: 계약 동의와 브랜드 결제

**Files:**
- Create: `api/src/contracts/{contracts.module.ts,contracts.controller.ts,contracts.service.ts,contracts.repository.ts,consent-texts.ts,dto/*.ts}`
- Modify: `api/src/payments/payments.service.ts`(`createForContract`, `applyResult`의 브랜드 분기), `api/src/payments/payments.controller.ts`(견적에 브랜드), `api/src/config/env.ts`
- Test: `api/src/contracts/consent-texts.spec.ts`, `api/src/contracts/contracts.service.spec.ts`, `api/test/contracts.e2e-spec.ts`

**Interfaces:**
- Consumes: 3번 `PaymentsService`·`PaymentPort`·`LedgerService`·`feeFor`·`postingsForPaymentApproved`·`postingsForFullRefund`·`RefundsService`·`JobScheduler`·`OperatorAlertPort`, `Env.FEE_RATE_BRAND_CONTRACT`, Task 2·4·6
- Produces:
  - `consentTexts(role: 'CREATOR' | 'BRAND', version: number, usage: UsageRights): [string, string, string]` (순수 함수) — 1 `합의한 조건 버전 {n}을 확인했어요`, 2 크리에이터 `광고 표시 의무를 지킬게요` / 브랜드 `광고 표시를 요청할게요`, 3 `REPOST_ONLY` `콘텐츠는 브랜드 계정 재게시에만 쓰여요` / `ADS_TOO` `콘텐츠는 브랜드 계정 재게시와 광고 소재로 쓰여요` / `NONE` `콘텐츠는 브랜드가 따로 활용하지 않아요`
  - `ContractModel { status: 'NOT_READY' | 'AWAITING_CREATOR' | 'AWAITING_BRAND' | 'PAYING' | 'CONCLUDED'; termsVersion: number | null; terms: TermsVersionModel | null(계약이면 사본); brandName; creatorName; myConsentTexts: string[]; creatorConsentedAt: string | null; brandConsentedAt: string | null; concludedAt: string | null; quote: PaymentQuoteModel | null(브랜드에게만); voidedNotice: boolean(내 동의가 새 버전으로 취소된 뒤 처음 볼 때) }`
  - `GET /collaborations/:id/contract` → 200 `ContractModel`. `AGREED` 전이면 `NOT_READY`(미리 보기용으로 최신 버전과 문구를 준다). `operationId: getContract`
  - `POST /collaborations/:id/contract/creator-consent` 본문 `{ termsVersion; accepted: string[] }` → 200 `ContractModel` — 크리에이터만, `AGREED`이고 `termsVersion`이 최신이고 양쪽 확인일 때만(아니면 409). `accepted`가 `consentTexts`와 정확히 같지 않으면 400. 계약 행(`AWAITING_BRAND`, 조건 사본, 문구, 시각). 안내 줄 `CREATOR_CONSENTED`, 브랜드에게 푸시. `operationId: consentContractAsCreator`
  - `POST /collaborations/:id/contract/brand-consent` 본문 `{ termsVersion; accepted: string[]; method: 'CARD' | 'TRANSFER' | 'EASY_PAY' }` → 201 `{ paymentId; checkoutUrl }` — 브랜드만, 계약이 `AWAITING_BRAND`이고 같은 버전일 때만. 크리에이터가 아직이면 409 `크리에이터의 동의를 기다리고 있어요.` 문구를 계약에 저장하고 `PaymentsService.createForContract(collaborationId, { escrow: 제작비, feeRate: FEE_RATE_BRAND_CONTRACT, method, orderName: '{캠페인 한 줄} 제작비' })`, `contracts.paymentId` 저장. `PENDING` 결제가 있으면 3번처럼 바꿔 만든다. `operationId: consentContractAsBrand`
  - `GET /collaborations/:id/payment-quote`(3번)가 브랜드 계약에도 답한다: `escrow` = 합의한 제작비, `fee` = `feeFor(escrow, FEE_RATE_BRAND_CONTRACT)`. 브랜드 계약에 `POST /collaborations/:id/payments`는 409(동의 경로만 쓴다).
  - `applyResult` 브랜드 분기(한 트랜잭션): 결제 `PENDING → APPROVED`, 장부 `postingsForPaymentApproved`, 계약 `AWAITING_BRAND → CONCLUDED`(`brandConsentedAt = concludedAt = now`), 협업 `AGREED → CONTRACTED`(`fundedAt`, `contractedAt = now`). 그 뒤 `brand-halt-check`를 `contractedAt + 60일`에 등록(`jobKey = 'brand-halt:' + id`), 안내 줄 `CONTRACT_CONCLUDED`, 양쪽에 푸시 `계약이 체결됐어요. 이제 제작을 시작할 수 있어요.` 계약이 `AWAITING_BRAND`가 아니면(취소·무산) 계약을 맺지 않고 `postingsForFullRefund`와 `RefundsService.request(제작비 + 수수료)`, 운영자 알림 `[Cora] 계약 없이 승인된 결제를 환급했어요`.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('builds three consent lines that follow the role and usage rights', ...);
it('lets the creator consent only to the agreed latest version with the exact texts', ...);   // 400, 409
it('refuses brand consent before the creator consents', ...);              // 409
it('quotes fee plus a 10 percent service fee for the brand', ...);         // 350000 → fee 35000, total 385000
it('concludes the contract and moves to CONTRACTED only when payment is approved', ...);
it('keeps AGREED and AWAITING_BRAND while the payment is pending or failed', ...);
it('concludes once for two identical approvals', ...);                     // 계약 1행 CONCLUDED, 푸시 1번씩
it('refunds in full without a contract when approval arrives after the consent was voided', ...);  // 장부 균형, 운영자 알림
it('schedules the 60 day halt check at conclusion', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db`
- [ ] **Step 5: gen-api, Commit** — 커밋 두 개: `feat: 계약 동의 기록 추가`, `feat: 브랜드 동의와 결제 승인으로 계약 체결`

---

### Task 8: 고정 지급과 60일 멈춤 점검

**Files:**
- Create: `api/src/jobs/handlers/{settle-fixed.handler.ts,brand-halt-check.handler.ts}`
- Modify: `api/src/jobs/job-names.ts`(`'settle-fixed'`), `api/src/settlements/{submissions.service.ts,settlements.service.ts}`, `api/src/ops/commands/resume.command.ts`, `api/src/collaborations/dto/collaboration.model.ts`
- Test: `api/src/settlements/settlements.service.spec.ts`(추가), `api/test/brand-settlement.e2e-spec.ts`

**Interfaces:**
- Consumes: 3번 `submitContentLink`·`isAcceptedLink`·`ViewCountPort.isOwnedBy`·`postingsForSettlement`·`PayoutsService.request`·`OperatorAlertPort`, Task 7
- Produces:
  - 링크 제출(3번) 브랜드 분기: `APPROVED`일 때만, 형식은 계약 사본의 형식. `APPROVED → PUBLISHED`(`submittedAt`, `submittedUrl`), `settle-fixed`를 `submittedAt + payoutDays × 24시간`에 등록(`jobKey = 'settle-fixed:' + id`), `brand-halt-check` 취소, 브랜드에게 `{활동 이름}님이 콘텐츠를 올렸어요.`
  - `SettlementsService.settleFixed(collaborationId, key)`: `PUBLISHED`가 아니면 끝. 한 트랜잭션에서 `settlements`(`finalViews = null`, `payoutAmount = 보관액`, `refundAmount = 0`), 장부 `postingsForSettlement({ payout: 보관액, refund: 0 })`, `PUBLISHED → SETTLED`. 그 뒤 `PayoutsService.request`. 지급이 `DONE`이면 크리에이터에게 `{금액}원이 지급됐어요.`, 브랜드에게 `제작비 {금액}원을 크리에이터에게 지급했어요.` 조회수는 읽지 않는다.
  - `brand-halt-check` 처리기: 단계가 `CONTRACTED`·`GUIDED`·`REVIEWING`·`APPROVED`면 `HALTED`(`stageBeforeHalt`, `haltedReason = 'NO_LINK_60_DAYS'`), `OperatorAlertPort.alert({ subject: '[Cora] 협업 멈춤 · 60일 동안 링크 없음' })`, 양쪽에 `협업이 잠시 멈췄어요. 운영팀이 확인하고 연락드릴게요.` 그 밖의 단계면 아무것도 하지 않는다.
  - 운영 명령 `resume`(3번) 브랜드 분기: `PUBLISHED`로 돌아가면 `settle-fixed`를 지금 등록, 그 전 단계면 `brand-halt-check`를 `now + 60일`에 다시 등록.
  - `CollaborationModel`에 `fixedPayoutAt: string | null`(`PUBLISHED`일 때 지급 예정 시각) 추가.

- [ ] **Step 1: 실패하는 테스트 작성**

```ts
it('accepts a link only at APPROVED and moves to PUBLISHED', ...);
it('does not pay one minute before N days after submission', ...);       // payoutDays 7, FakeClock +7일 −1분, runDue → SETTLED 아님
it('pays the full fee exactly N days after submission with no refund', ...); // payoutDays 14, payout 350000, refunds 0행
it('pays once when the settle-fixed job runs twice', ...);
it('halts and alerts the operator 60 days after contract without a link', ...);
it('does nothing at 60 days when the link was already submitted', ...);
it('keeps every brand collaboration ledger balanced', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: gen-api, Commit** — `feat: 브랜드 계약의 고정 지급과 60일 멈춤 점검 추가`

---

### Task 9: 앱 — 대화 목록, 메시지 요청(11), 하단 메뉴

**Files:**
- Create: `app/lib/features/chat/domain/{conversation.dart,message.dart,chat_repository.dart,realtime_connection.dart}`, `data/{api_chat_repository.dart,socket_realtime_connection.dart}`, `presentation/viewmodels/{conversation_list_view_model.dart,message_request_view_model.dart}`, `presentation/pages/{conversation_list_page.dart,message_request_page.dart}`, `presentation/chat_text.dart`
- Modify: `app/lib/main.dart`, `app/lib/core/navigation/app_router.dart`, 세 역할의 하단 메뉴 정의(2번 Task 12, 4번 Task 9·11)
- Test: `app/test/features/chat/`

**Interfaces:**
- Consumes: `cora_api`의 `listConversations`, `getConversation`, `acceptMessageRequest`, `declineMessageRequest` (Task 2, 3), `AuthRepository.currentSession`
- Produces:
  - `class ConversationSummary`, `class ConversationDetail`, `class ChatMessage { final String? id; final int? seq; final String clientId; final MessageKind kind; final bool mine; final String? text; final ContentCard? card; final DateTime at; final SendState state; }`, `enum SendState { sent, sending, failed }`
  - `abstract class ChatRepository { Future<List<ConversationSummary>> fetchList(); Future<ConversationDetail> fetch(String id); Future<List<ChatMessage>> fetchMessages(String id, {int? afterSeq, int? beforeSeq}); Future<ChatMessage> send(String id, {required String clientId, required MessageKind kind, String? text}); Future<void> markRead(String id, int seq); Future<void> setMuted(String id, bool muted); Future<void> block(String id); Future<void> report(ReportTarget target, ReportReason reason, String? detail); Future<ConversationDetail> acceptRequest(String id); Future<void> declineRequest(String id); }`
  - `abstract class RealtimeConnection { Stream<RealtimeEvent> get events; Stream<void> get reconnected; Future<void> start(); Future<void> stop(); }`, `sealed class RealtimeEvent`(`MessageCreated`, `ConversationUpdated`, `SessionExpired`). `SocketRealtimeConnection`은 `/realtime`에 현재 토큰으로 붙고, 끊기거나 `session.expired`면 새 토큰으로 `1·2·4·8·16·30`초 간격으로 다시 붙는다(간격은 생성자로 주입). `chatRepositoryProvider`, `realtimeConnectionProvider`는 `UnimplementedError` 기본값, `main.dart`에서 override. 세션이 생기면 `start`, 없어지면 `stop`.
  - `chat_text.dart`(순수 함수): `listTime(DateTime at, DateTime now)`(`오후 3:20`, `어제`, `11월 23일`), `dayDivider(DateTime)`(`11월 23일 (월)`), `termsSummary(TermsVersion)`(`릴스 1편, 35만 원 + 제품, 11월 23일 시작`), `statusLine(ConversationDetail)`, `storeHeaderLine(OfferTerms)`(= `rewardHeadline`)
  - 라우트: `/chats`, `/chats/:id`, `/chats/:id/request`. 세 역할의 하단 메뉴 `대화`가 `/chats`를 연다.

화면 문구:
- 목록: 제목 `대화`. 받은 요청이 있으면 맨 위 묶음 `메시지 요청 {n}`. 줄: 상대 사진과 이름, `{캠페인 한 줄 또는 가게 이름}` 꼬리, 마지막 메시지, 시각, 안 읽은 수(0이면 숨김). 알림을 끈 방은 이름 옆에 종 꺼짐 아이콘.
- 보낸 요청의 줄: `수락을 기다리고 있어요` / 거절된 요청: `대화가 열리지 않았어요.` 닫힌 방: `대화가 종료됐어요.`
- 빈 목록: `아직 대화가 없어요.` / `서로 관심이 닿거나 오퍼가 수락되면 대화가 열려요.`
- 11: 머리 `메시지 요청`. 보낸 사람 이름과 캠페인, 첫 메시지와 시각, 요약 `제작물` / `{형식} 1편`, `제작비` / `{won}`, `촬영` / `{날짜} 이후`. 안내 `수락하기 전에는 상대가 메시지를 더 보낼 수 없어요.` 버튼 `거절`, `대화 수락`. 거절 확인 `요청을 거절할까요? 상대에게는 대화가 열리지 않았다고만 보여요.` / `거절하기` / `취소`. 수락하면 대화방으로 바꿔 연다(`CoraTransitions.push`).

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('formats list times as time, yesterday or date', ...);               // '오후 3:20', '어제', '11월 23일'
test('summarizes terms the way the canvas does', ...);                    // '릴스 1편, 35만 원 + 제품, 11월 23일 시작'
test('reconnects with the injected backoff and stops growing at 30 seconds', ...);
testWidgets('groups message requests above the conversations', ...);      // '메시지 요청 1'
testWidgets('accepting a request opens the conversation', ...);
testWidgets('declining asks for confirmation and removes the request', ...);
testWidgets('refreshes the list when a message arrives over the socket', ...);
testWidgets('the chat tab is live for store, brand and creator', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인** — Run: `cd app && flutter analyze && flutter test`
- [ ] **Step 5: Commit** — `feat: 대화 목록과 메시지 요청 화면 추가`

---

### Task 10: 앱 — 대화방(D3)

**Files:**
- Create: `app/lib/features/chat/presentation/viewmodels/chat_thread_view_model.dart`, `presentation/pages/chat_thread_page.dart`, `presentation/widgets/{message_bubble.dart,content_card_bubble.dart,system_line.dart,attach_sheet.dart,report_sheet.dart,drop_sheet.dart,chat_header.dart}`
- Test: `app/test/features/chat/chat_thread_*_test.dart`

**Interfaces:**
- Consumes: `ChatRepository`, `RealtimeConnection` (Task 9), `NegotiationRepository.drop`·`likeCampaign` (Task 12, 4번 `DiscoveryRepository.decide`)
- Produces:
  - `ChatThreadViewModel(conversationId)` 상태 `{ detail; messages(번호 순, 확정된 것); pending(보내는 중·실패, clientId 순서); hasOlder }`
  - `send(text)`: `clientId`(uuid v4)를 만들어 `pending`에 넣고 보낸다. 실패하면 `failed`. `retry(clientId)`는 같은 `clientId`로 다시 보낸다. 서버나 소켓에서 같은 `clientId`의 메시지가 오면 `pending`에서 빼고 확정 목록에 넣는다.
  - 받은 메시지는 번호로 중복을 거른다. 받은 번호가 마지막 번호 + 1보다 크거나 `reconnected`가 오면 `fetchMessages(afterSeq: 마지막 번호)`로 메운다. 위로 끝까지 올리면 `beforeSeq`로 50개씩 더 읽는다.
  - 화면이 보이는 동안 마지막 번호로 `markRead`. `conversation.updated`가 오면 `fetch(id)`로 머리를 새로 고친다.

화면 문구:
- 머리(브랜드 계약): 상대 이름, 캠페인 한 줄, 조건 요약 한 줄(`termsSummary`), 상태 한 줄(`statusLine`, 예 `조건 버전 2 · 브랜드 확인 대기`). 조건 요약을 누르면 12. `INQUIRY`면 요약은 캠페인 조건, 상태는 `서로 관심 전 · 조건 문의 중`, 크리에이터에게는 오른쪽에 `관심 보내기`(→ 4번의 관심, 서로 관심이 되면 머리가 바뀐다).
- 머리(가게 오퍼): 가게 이름과 `storeHeaderLine`. 조건 수정 제안이 없다.
- 날짜 구분선, 말풍선, 콘텐츠 카드(사진과 제목), 가운데 작은 글씨의 안내 줄. 실패한 말풍선 아래 `보내지 못했어요` / `다시 보내기`. 빈 방 `첫 메시지를 보내 보세요.`
- 입력란 안내 `메시지 보내기`, 1,000자를 넘기면 보내기 버튼이 꺼지고 `1,000자까지 보낼 수 있어요.`
- 더하기 버튼 시트: `내 콘텐츠 카드`(크리에이터이고 대표 콘텐츠가 있을 때), `조건 수정 제안`(`canProposeTerms`일 때 → Task 12의 수정 제안 화면).
- 오른쪽 위 메뉴: `알림 끄기` / `알림 켜기`, `차단하기`, `신고하기`, `협의 그만두기`(`canDrop`일 때).
- 차단 확인: `{이름}님을 차단할까요?` / `이 대화방에서 서로 메시지를 보낼 수 없고, 추천에도 나오지 않아요.` / `차단하기` / `취소`. 409면 `진행 중인 협업이 있어요. 문의하기로 알려 주세요.` 차단 뒤 입력란 자리에 `차단한 대화예요.`, 상대 쪽은 `대화가 종료됐어요.`
- 신고 시트: `신고하기`, `광고·스팸`, `부적절한 말`, `사기 의심`, `기타`, `자세한 내용 (선택)`, 버튼 `신고하기`. 성공 `신고를 접수했어요.`, 409 `이미 신고했어요.`
- 그만두기 시트: `협의를 그만둘까요?`, `상대에게는 이유를 알리지 않아요.`, `일정이 맞지 않아요`, `예산이 맞지 않아요`, `방향이 달라요`, `기타`, `그만두기` / `계속 협의하기`.
- 요청을 보내고 기다리는 동안 입력란 자리에 `상대가 수락하면 대화를 이어갈 수 있어요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('keeps messages in sequence order when they arrive out of order', ...);
test('fills a gap by fetching after the last sequence number', ...);       // 3 다음 6이 오면 afterSeq 3
test('fetches missed messages after a reconnect', ...);
test('retries a failed message with the same client id', ...);
testWidgets('shows the terms summary and status line in the header', ...);
testWidgets('shows a retry action on a failed bubble', ...);               // '다시 보내기'
testWidgets('the attach sheet hides the content card for a brand', ...);
testWidgets('blocking shows the held-money message on conflict', ...);
testWidgets('dropping asks for a reason and shows the drop line', ...);
testWidgets('an inquiry shows like campaign to the creator only', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 대화방 화면과 다시 보내기, 재연결 추가`, `feat: 대화방의 차단·신고·협의 그만두기 메뉴 추가`

---

### Task 11: 앱 — 받은 제안(10)과 서로 관심 시트의 첫 인사

**Files:**
- Create: `app/lib/features/proposals/domain/{received_proposal.dart,proposals_repository.dart}`, `data/api_proposals_repository.dart`, `presentation/viewmodels/received_proposal_view_model.dart`, `presentation/pages/{received_proposal_page.dart,inquiry_sheet.dart}`
- Modify: `app/lib/features/interests/presentation/pages/interests_page.dart`(크리에이터 쪽 맨 위 묶음), `app/lib/features/interests/presentation/pages/match_sheet.dart`, `app/lib/core/navigation/app_router.dart`
- Test: `app/test/features/proposals/`, `app/test/features/interests/match_sheet_test.dart`(추가)

**Interfaces:**
- Consumes: `cora_api`의 `listReceivedProposals`, `createInquiry` (4번, Task 3), `DiscoveryRepository.decide` (4번), `ChatRepository.send` (Task 9)
- Produces:
  - `abstract class ProposalsRepository { Future<List<ReceivedProposal>> fetchAll(); Future<({String collaborationId, String conversationId})> inquire(String campaignId, {required String message, String? contentLine}); }`
  - 라우트 `/creator/proposals/:campaignId`
  - `MatchInfo`에 `conversationId` 추가. 시트의 첫 인사가 비어 있지 않으면 `협업 조건 확인하기`를 누를 때 그 방에 보낸다. 실패해도 이동은 막지 않는다.

화면 문구:
- 관심 탭 맨 위(크리에이터, 받은 제안이 있을 때): `받은 제안 {n}`, 카드에 브랜드 사진과 이름, `내 콘텐츠 「{제목}」에 제안했어요`(사본이 없으면 `내 프로필에 제안했어요`).
- 10: 머리 `받은 제안`, 브랜드 이름, `내 콘텐츠 「{제목}」에 제안했어요`, 상자 `브랜드가 좋아한 점` / 브랜드가 쓴 글, `{제작비}` + (제품 제공이면) `+ 제품`, `{형식} 1편`, 입력란 `내가 만들고 싶은 콘텐츠 한 줄`(40자, 선택), 버튼 `관심 보내기`, `조건부터 질문하기`.
- `관심 보내기` → 입력한 한 줄을 `note`로 관심. 서로 관심이 되면 05 시트.
- `조건부터 질문하기` 시트: `브랜드에게 물어볼 내용을 적어 주세요`, 입력란(1,000자, 필수), 버튼 `질문 보내기`. 성공 `질문을 보냈어요. 브랜드가 수락하면 대화가 열려요.` 409면 `이미 이 캠페인에 질문했어요.`
- 05 시트: 입력란 `첫 인사를 남겨 보세요 (선택)`. 보내기 실패 `첫 인사를 보내지 못했어요. 대화에서 다시 보내 주세요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('shows received proposals above the creator interests', ...);
testWidgets('shows the copied content title and the brand note', ...);
testWidgets('sending interest carries my one line as the note', ...);
testWidgets('a mutual like from the proposal opens the match sheet', ...);
testWidgets('asking first requires a message and confirms', ...);
testWidgets('the match sheet sends the greeting into the conversation', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 받은 제안 화면과 조건부터 질문하기 추가`, `feat: 서로 관심 시트에 첫 인사 추가`

---

### Task 12: 앱 — 조건 합의(12)와 수정 제안

**Files:**
- Create: `app/lib/features/negotiation/presentation/viewmodels/{agreement_view_model.dart,terms_proposal_view_model.dart}`, `presentation/pages/{agreement_page.dart,terms_proposal_page.dart}`
- Modify: `app/lib/features/negotiation/domain/{terms_version.dart,negotiation_repository.dart}`, `data/api_negotiation_repository.dart`, `presentation/terms_text.dart`, `presentation/pages/draft_terms_page.dart`(`조건 수정 제안` → 수정 제안 화면), `app/lib/core/navigation/app_router.dart`
- Test: `app/test/features/negotiation/agreement_*_test.dart`, `terms_proposal_*_test.dart`

**Interfaces:**
- Consumes: `cora_api`의 `listTermsVersions`, `proposeTerms`, `confirmTerms`, `dropCollaboration` (Task 6)
- Produces:
  - `NegotiationRepository`에 추가: `Future<TermsHistory> fetchHistory(String collaborationId); Future<TermsVersion> propose(String collaborationId, int baseVersion, TermsChanges changes); Future<void> drop(String collaborationId, DropReason reason);`
  - `terms_text.dart`에 추가: `changedFromLabel(TermsField, TermsVersion previous)`(`35만 원에서 변경`), `historyLine(TermsVersion, {required bool mine, required String counterpartRoleName})`(`버전 1 · 브랜드의 최초 제안`, `버전 2 · 내가 제작비·일정 수정 제안`, `버전 3 · 브랜드가 수정 범위 수정 제안`), `agreementStatus(TermsHistory, myRole)`, `fieldName(TermsField)`(`콘텐츠 제목`, `제작비`, `일정`, `제작물`, `제품 제공`, `수정 범위`, `활용 권한`, `지급 조건`)
  - 라우트 `/collaborations/:id/agreement`, `/collaborations/:id/terms/propose`

화면 문구:
- 12: 머리 `조건 합의`, `버전 {n}`, 상태 `브랜드 확인 대기 중` / `크리에이터 확인 대기 중` / `양쪽 확인 대기 중` / `합의됨`. 양쪽 표시 `나 · 확인함` / `나 · 대기`, `{브랜드 | 크리에이터} · 확인함` / `· 대기`.
- `대화에서 정한 조건`, `초록색은 이번 버전에서 바뀐 조건이에요.` 줄: 콘텐츠 제목, `제작비`, `제작 시작`, `제작물`, `제품 제공`, `수정 범위`, `활용 권한`, `지급 조건`, `광고 표시` / `영상·게시물에 명확히`. 바뀐 줄은 `accent` 색이고 새 값 아래 `{이전 값}에서 변경`.
- `변경 기록` 목록(`historyLine`).
- 버튼: 내가 최신 버전을 아직 확인하지 않았으면 `확인`, 그리고 `수정 제안`. 아래 주 버튼은 합의 전 `계약서 미리 보기`, 합의되면 `계약하러 가기`(→ D4). 계약 뒤 `계약서 보기`와 안내 `계약한 뒤에는 조건을 바꿀 수 없어요.` 무산 뒤 `협의가 끝난 조건이에요.` 오른쪽 위 메뉴 `협의 그만두기`(Task 10의 시트).
- 수정 제안: 머리 `조건 수정 제안`, `버전 {n}을 바탕으로 고쳐요.` 항목 여덟 개(콘텐츠 제목, 제작비(1만 원 단위), 제작 시작(날짜 고르기, 오늘부터), 제작물(형식 네 가지와 편 수 1~3), 제품 제공(`포함` / `미포함`), 수정 범위 네 가지, 활용 권한 세 가지, 지급 조건 `게시 후 7일 이내` / `게시 후 14일 이내`), 광고 표시는 고정 표시. 바뀐 항목에 점. 하나 이상 바꿔야 `제안 보내기`가 켜진다. 보내면 `조건 버전 {n}을 제안했어요.`와 함께 12로 돌아간다. 409 `상대가 먼저 새 조건을 제안했어요. 최신 조건을 확인해 주세요.`(12를 새로 읽는다) 또는 서버 문구.

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
test('describes history lines for system, me and the other side', ...);   // '버전 2 · 내가 제작비·일정 수정 제안'
test('labels a changed fee with its previous value', ...);                // '35만 원에서 변경'
testWidgets('highlights only the fields changed in the latest version', ...);
testWidgets('confirming flips to agreed and offers to go to the contract', ...);   // '계약하러 가기'
testWidgets('send proposal is disabled until a field changes', ...);
testWidgets('a conflicting proposal reloads the latest version', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — 커밋 두 개: `feat: 조건 합의와 변경 기록 화면 추가`, `feat: 조건 수정 제안 화면 추가`

---

### Task 13: 앱 — 계약(D4)과 브랜드 결제

**Files:**
- Create: `app/lib/features/negotiation/domain/contract.dart`, `presentation/viewmodels/contract_view_model.dart`, `presentation/pages/contract_page.dart`
- Modify: `app/lib/features/negotiation/domain/negotiation_repository.dart`, `data/api_negotiation_repository.dart`, `app/lib/core/navigation/app_router.dart`
- Test: `app/test/features/negotiation/contract_*_test.dart`

**Interfaces:**
- Consumes: `cora_api`의 `getContract`, `consentContractAsCreator`, `consentContractAsBrand` (Task 7), 3번의 `PaymentRepository.fetchStatus`, `CheckoutLauncher`, `won()`
- Produces:
  - `NegotiationRepository`에 추가: `Future<Contract> fetchContract(String id); Future<Contract> consentAsCreator(String id, int version, List<String> accepted); Future<({String paymentId, String checkoutUrl})> consentAsBrand(String id, int version, List<String> accepted, PaymentMethod method);`
  - `ContractViewModel`: 확인란 세 개의 상태, `consent()`. 브랜드는 결제창이 닫히면 3번 `PaymentViewModel`과 같은 방식으로 `fetchStatus`를 1초 간격 최대 10번 묻고, 승인되면 `fetchContract`로 `CONCLUDED`를 확인한다(간격과 횟수는 생성자로 주입).
  - 라우트 `/collaborations/:id/contract`(`?preview=1`이면 미리 보기)

화면 문구:
- 머리 `협업 계약`, `합의한 버전 {n}으로 계약해요.`, `양쪽이 모두 동의하면 계약이 체결되고 제작이 시작돼요.` 양쪽 이름, 요약 `제작물`, `제작비`, `제작 시작`, `지급`(`최종 게시 후 7일 이내`).
- 확인란 세 개: 서버의 `myConsentTexts` 그대로(크리에이터 둘째 `광고 표시 의무를 지킬게요`, 브랜드 둘째 `광고 표시를 요청할게요`, 셋째는 활용 권한별). 다 확인해야 `동의하고 계약하기`가 켜진다. 그 전 안내 `모두 확인하면 계약할 수 있어요`.
- 크리에이터가 동의한 뒤: `브랜드 동의를 기다리고 있어요. 계약서는 체결 후 보관함에 저장돼요.`
- 브랜드, 크리에이터 동의 전: 버튼 꺼짐과 `크리에이터의 동의를 기다리고 있어요.`
- 브랜드, 크리에이터 동의 뒤: 확인란 위에 결제 상자 `제작비` / `350,000원`, `서비스 수수료` / `35,000원`, `동의하면 결제할 금액` / `385,000원`, 수단 `카드`, `계좌이체`, `간편결제`, 안내 `결제 금액은 Cora가 보관하다가, 콘텐츠가 게시되고 {N}일째에 크리에이터에게 지급해요.` 확인 중 버튼 자리 `결제를 확인하고 있어요`, 실패·시간 초과 `결제가 완료되지 않았어요. 다시 시도해 주세요.`
- 체결: `계약이 체결됐어요.`, `{날짜} 체결`, 버튼 `협업 진행 보기`(→ 07).
- 미리 보기(합의 전): 확인란 꺼짐, 안내 `양쪽이 같은 버전을 확인하면 계약할 수 있어요.`
- 내 동의가 새 버전으로 취소됐을 때 위 띠: `조건이 바뀌어 동의가 취소됐어요. 새 조건을 확인해 주세요.`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('the consent button turns on only after all three boxes', ...);
testWidgets('shows the brand wording on the second box for a brand', ...); // '광고 표시를 요청할게요'
testWidgets('the creator waits for the brand after consenting', ...);
testWidgets('the brand pays the fee plus service fee and sees the contract concluded', ...);  // '385,000원'
testWidgets('a failed payment keeps the contract unsigned with a retry message', ...);
testWidgets('shows the voided banner after the terms changed', ...);
testWidgets('does not overflow at 1.3x text scale', ...);
```

- [ ] **Step 2~4: 실패 확인 → 구현 → 통과 확인**
- [ ] **Step 5: Commit** — `feat: 계약 동의와 브랜드 결제 화면 추가`

---

### Task 14: 전체 흐름 확인

**Files:** 없음

- [ ] **Step 1: 자동 확인** — `cd api && yarn lint && yarn test && yarn test:e2e && yarn test:db` · `cd app && flutter analyze && flutter test` · `./scripts/gen-api.sh && git status --short`(변경 없음)

- [ ] **Step 2: 네 계정으로 수동 확인** (A 브랜드, B 크리에이터, C 가게, D 크리에이터. 두 기기를 나란히. 날짜는 3번의 `FAKE_CLOCK_OFFSET_DAYS`로 건너뛴다.)

1. A: 발견 상세에서 B에게 `좋아한 점`을 쓰고 관심. B: 관심 탭 맨 위 `받은 제안 1` → 10 → `조건부터 질문하기` → 질문 보냄.
2. A: 대화 탭 `메시지 요청 1` → 11 → `대화 수락`. B의 방에 `관심 보내기` → 같은 방에 `서로 관심이 닿았어요` 안내 줄, 머리에 `조건 버전 1 · 양쪽 확인 대기`. 서버에서 협업 행이 하나인지 확인.
3. 두 기기에서 글을 주고받는다 → 바로 뜬다. B의 앱을 끄면 60자 미리 보기 푸시, `알림 끄기` 뒤에는 없다. B: 비행기 모드에서 보내기 → `다시 보내기` → 한 번만 도착하고 그 사이 A의 메시지가 순서대로 채워진다. B의 `내 콘텐츠 카드`가 A에게 보이고, A의 더하기 메뉴에는 그 항목이 없다.
4. B: `조건 수정 제안`(제작비 35만 원, 시작일) → A의 방에 `B님이 조건 버전 2를 제안했어요.` → A: 12에서 `35만 원에서 변경` 등 바뀐 줄만 초록 → `확인` → `합의됨` → `계약하러 가기`.
5. B: D4에서 세 칸 확인 → `브랜드 동의를 기다리고 있어요…`. A: 결제 상자 `385,000원` → 가짜 결제창 `결제 승인` → 양쪽에 `계약이 체결됐어요…`, 단계 `CONTRACTED`.
6. 새 캠페인으로: B 동의 뒤 A가 새 버전을 제안 → B의 D4에 취소 띠. A가 결제창을 연 채로 B가 제안 → 409 문구.
7. 계약된 협업을 테스트 도우미로 `APPROVED`로 옮기고 B가 링크 제출 → 지급 조건 14일이면 13일 23시간 뒤 미지급, 14일 뒤 `350,000원이 지급됐어요`. `yarn ops show`: `ESCROW 0`, `CREATOR_PAYABLE 350000`, `FEE_REVENUE 35000`.
8. 다른 계약 협업을 60일 건너뛴다 → 운영자 알림 로그, `HALTED`.
9. C가 D에게 오퍼, D 수락 → 가게 대화방(머리에 가게 이름과 보상, 조건 수정 제안 없음). 결제 뒤 D가 `차단하기` → `진행 중인 협업이 있어요…`. 결제 전 오퍼로는 차단되고 양쪽 입력란이 막히며 D의 발견에서 C의 가게가 사라진다.
10. B가 A의 방을 `신고하기` → 운영자 알림 로그, 다시 신고하면 `이미 신고했어요.` 협의 중인 다른 협업에서 B가 `협의 그만두기`(`예산이 맞지 않아요`) → A에게는 `이번에는 함께하기 어렵대요.`만 보인다.
11. 다크 모드, 글자 1.3배에서 대화 목록, 11, D3, 10, 12, 수정 제안, D4. 캔버스와 나란히 비교.

---

## 완료 기준

- Task 14의 자동 확인과 수동 확인 11개 통과
- 운영 환경 모드에서 가짜 어댑터가 있으면 서버가 시작을 거부하고, 소켓이 토큰 없이 붙지 못함

## 이 계획이 구체화한 것

설계 문서에 문구나 규칙이 없어 이 계획이 정한 것이다. 소유자 확인 대상이다.

| 자리 | 정한 것 |
|---|---|
| 안내 줄 | `{이름}님과 서로 관심이 닿았어요. 조건 버전 1이 만들어졌어요.`, `{이름}님이 오퍼를 수락했어요.`, `{이름}님이 대화를 수락했어요.`, `{이름}님이 조건 버전 {n}을 확인했어요.`, `{이름}님이 계약에 동의했어요.`, `조건이 바뀌어 계약 동의가 취소됐어요.`, `계약이 체결됐어요.`, 그만둔 본인 `협의를 그만뒀어요.` |
| 셋째 확인란 | `ADS_TOO` `콘텐츠는 브랜드 계정 재게시와 광고 소재로 쓰여요`, `NONE` `콘텐츠는 브랜드가 따로 활용하지 않아요` |
| 상태 한 줄 | `조건 버전 {n} · 양쪽 확인 대기`, `조건 버전 {n} · 합의됨 · 계약 대기`, `크리에이터 동의함 · 브랜드 결제 대기`, `계약 체결 · 제작 중`, `협업 완료`, `협의가 끝났어요`, `운영팀 확인 중`, `서로 관심 전 · 조건 문의 중` |
| 대화 목록·방 | `수락을 기다리고 있어요`, `차단한 대화예요.`, `첫 메시지를 보내 보세요.`, `메시지 보내기`, `1,000자까지 보낼 수 있어요.`, `보내지 못했어요`, `상대가 수락하면 대화를 이어갈 수 있어요.`, 빈 목록 두 줄 |
| 확인 문구 | 차단·요청 거절·그만두기의 확인 문구와 버튼(Task 9, 10) |
| 오류 | `바꾼 조건이 없어요.`, `상대가 먼저 새 조건을 제안했어요.`, `브랜드가 결제를 진행하고 있어요. 잠시 뒤 다시 시도해 주세요.`, `이미 신고했어요.`, `이미 이 캠페인에 질문했어요.`, `첫 인사를 보내지 못했어요. 대화에서 다시 보내 주세요.` |
| 받은 제안·질문 | `내 프로필에 제안했어요`, `브랜드에게 물어볼 내용을 적어 주세요`, `질문 보내기`, `질문을 보냈어요. 브랜드가 수락하면 대화가 열려요.`, `첫 인사를 남겨 보세요 (선택)` |
| 계약·결제 | `동의하면 결제할 금액`, `결제 금액은 Cora가 보관하다가, 콘텐츠가 게시되고 {N}일째에 크리에이터에게 지급해요.`, `계약이 체결됐어요.`, `{날짜} 체결`, `협업 진행 보기`, `양쪽이 같은 버전을 확인하면 계약할 수 있어요.`, `조건이 바뀌어 동의가 취소됐어요. 새 조건을 확인해 주세요.`, `계약한 뒤에는 조건을 바꿀 수 없어요.`, `협의가 끝난 조건이에요.` |
| 알림 | 요청 `메시지 요청` / `{이름}님이 메시지를 보냈어요.`, 콘텐츠 카드 `콘텐츠 카드를 보냈어요.`, 지급 브랜드 쪽 `제작비 {금액}원을 크리에이터에게 지급했어요.`, 멈춤 `협업이 잠시 멈췄어요. 운영팀이 확인하고 연락드릴게요.` |
| 11 안내 | 공통 규칙 10장의 제안대로 `수락하기 전에는 상대가 메시지를 더 보낼 수 없어요.` |
| 규칙 | 콘텐츠 제목도 수정 제안으로 고칠 수 있다(공통 규칙 7장의 아홉 항목). 브랜드 결제가 60분 안에 요청돼 `PENDING`이면 수정 제안과 그만두기를 막는다. 차단은 사람 사이의 것이며 두 사람의 모든 방을 닫고 계약 전 협업을 끝낸다. 요청 거절은 협업을 `DROPPED`로 끝낸다. |

## 이 계획이 하지 않는 것

- "수정 한 번 더 허용" 버튼과 동작, 계약서를 보관함에서 열기, 기획 방향·초안·회고 (6번 계획. 이 계획은 `extraRevisionsAllowed` 칸만 둔다)
- 포트폴리오 콘텐츠 신고와 세 명 신고 시 숨김 (7번 계획)
- 차단 해제, 읽음 표시, 입력 중 표시, 메시지 수정·삭제, 사진·영상 보내기, 계약서 PDF, 운영자용 신고 처리 화면
- 실제 푸시(FCM, APNs)와 실제 PG (9번 계획)
- 탈퇴한 사용자의 표시 (탈퇴 계획)
