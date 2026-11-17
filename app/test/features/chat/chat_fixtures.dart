import 'dart:async';

import 'package:cora/features/chat/domain/chat_repository.dart';
import 'package:cora/features/chat/domain/conversation.dart';
import 'package:cora/features/chat/domain/message.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart'
    show CollaborationKind;
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/negotiation/domain/terms_version.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, OfferTerms, ViewPay;

/// 목록 줄. 기본은 열린 방, 마지막 메시지가 있고 읽지 않은 것이 없다.
ConversationSummary summary(
  String id, {
  String name = '모아 스튜디오',
  String contextLabel = '느린 결, 일상의 주얼리 캠페인',
  ConversationStatus status = ConversationStatus.open,
  ConversationSection section = ConversationSection.normal,
  String? preview = '안녕하세요!',
  DateTime? at,
  int unread = 0,
  bool muted = false,
}) => ConversationSummary(
  id: id,
  counterpartName: name,
  contextLabel: contextLabel,
  lastMessage: preview == null
      ? null
      : ConversationLastMessage(
          kind: MessageKind.text,
          preview: preview,
          at: at ?? DateTime.utc(2026, 11, 11, 6, 20),
        ),
  muted: muted,
  section: section,
  status: status,
  unreadCount: unread,
);

/// 메시지 요청 줄(내가 답해야 한다).
ConversationSummary requestSummary(
  String id, {
  String name = '모아 스튜디오',
  String preview = '안녕하세요! 조건부터 여쭤볼게요.',
}) => summary(
  id,
  name: name,
  status: ConversationStatus.requested,
  section: ConversationSection.request,
  preview: preview,
  unread: 1,
);

/// 11이 읽는 메시지 요청의 방 머리. 캔버스의 값(`릴스 1편`, `30만 원`, `11/16 이후`)이다.
ConversationDetail requestDetail(
  String id, {
  String name = '모아 스튜디오',
  ConversationStatus status = ConversationStatus.requested,
  bool requestedByMe = false,
  CampaignTerms? campaignTerms,
}) => ConversationDetail(
  id: id,
  collaborationId: 'collab-$id',
  kind: CollaborationKind.brandContract,
  counterpartName: name,
  contextLabel: '느린 결, 일상의 주얼리 캠페인',
  status: status,
  section: ConversationSection.request,
  requestedByMe: requestedByMe,
  myRole: ChatRole.commissioner,
  stage: ConversationStage.inquiry,
  contractStatus: ContractProgress.none,
  lastSeq: 1,
  lastReadSeq: 0,
  unreadCount: 1,
  muted: false,
  blockedByMe: false,
  canSend: false,
  canSendContentCard: false,
  canProposeTerms: false,
  canDrop: false,
  canLikeCampaign: false,
  campaignTerms:
      campaignTerms ??
      CampaignTerms(
        fee: 300000,
        format: ContentFormat.reels,
        productProvided: false,
        startFrom: DateTime(2026, 11, 16),
      ),
);

/// 방 머리. 협업 단계와 조건 판본을 바꿔 가며 쓴다. 기본은 크리에이터가 본 열린 브랜드 협업이다.
ConversationDetail roomDetail({
  String id = 'room-1',
  ConversationStage stage = ConversationStage.negotiating,
  ContractProgress contractStatus = ContractProgress.none,
  TermsVersion? terms,
  ChatRole myRole = ChatRole.creator,
  CollaborationKind kind = CollaborationKind.brandContract,
  ConversationStatus status = ConversationStatus.open,
  bool requestedByMe = false,
  bool blockedByMe = false,
  bool muted = false,
  bool canSendContentCard = true,
  bool canProposeTerms = true,
  bool canDrop = true,
  bool canLikeCampaign = false,
  int lastSeq = 3,
  int lastReadSeq = 3,
  CampaignTerms? campaignTerms,
  OfferTerms? storeTerms,
}) => ConversationDetail(
  id: id,
  collaborationId: 'collab-$id',
  kind: kind,
  counterpartName: '모아 스튜디오',
  contextLabel: '느린 결, 일상의 주얼리 캠페인',
  status: status,
  section: ConversationSection.normal,
  requestedByMe: requestedByMe,
  myRole: myRole,
  stage: stage,
  contractStatus: contractStatus,
  lastSeq: lastSeq,
  lastReadSeq: lastReadSeq,
  unreadCount: 0,
  muted: muted,
  blockedByMe: blockedByMe,
  canSend: status == ConversationStatus.open,
  canSendContentCard: canSendContentCard,
  canProposeTerms: canProposeTerms,
  canDrop: canDrop,
  canLikeCampaign: canLikeCampaign,
  terms: terms,
  storeTerms: storeTerms,
  campaignTerms: campaignTerms,
);

TermsVersion termsVersion({
  int version = 2,
  int fee = 350000,
  bool productProvided = true,
  ViewPay? performance,
  bool brandConfirmed = false,
  bool creatorConfirmed = true,
}) => TermsVersion(
  version: version,
  title: '이런 분위기로 찍을게요',
  fee: fee,
  productProvided: productProvided,
  performance: performance,
  format: ContentFormat.reels,
  pieces: 1,
  startDate: DateTime(2026, 11, 23),
  revisionScope: RevisionScope.draftOnce,
  usageRights: BrandUsageRights.repostOnly,
  payoutDays: 7,
  maxCash: fee,
  brandConfirmed: brandConfirmed,
  creatorConfirmed: creatorConfirmed,
  proposedBy: TermsProposer.creator,
);

ChatMessage message({
  int seq = 1,
  String text = '안녕하세요! 주얼리를 먼저 7일 정도 사용해보신 뒤, 11월 16일 이후 촬영이 가능하실까요?',
  bool mine = false,
  DateTime? at,
}) => ChatMessage(
  id: 'm$seq',
  seq: seq,
  clientId: 'm$seq',
  kind: MessageKind.text,
  mine: mine,
  text: text,
  at: at ?? DateTime.utc(2026, 11, 11, 5, 14),
);

/// 안내 줄(서버가 읽는 사람에 맞춰 만든 문구).
ChatMessage systemLine({
  int seq = 2,
  String text = '조건 버전 2를 크리에이터가 확인했어요.',
  DateTime? at,
}) => ChatMessage(
  id: 'm$seq',
  seq: seq,
  clientId: 'm$seq',
  kind: MessageKind.system,
  mine: false,
  text: text,
  at: at ?? DateTime.utc(2026, 11, 11, 5, 30),
);

/// 콘텐츠 카드 메시지.
ChatMessage cardMessage({
  int seq = 3,
  bool mine = true,
  String title = '이런 분위기로 찍을게요',
  DateTime? at,
}) => ChatMessage(
  id: 'm$seq',
  seq: seq,
  clientId: 'm$seq',
  kind: MessageKind.contentCard,
  mine: mine,
  card: ContentCard(title: title),
  at: at ?? DateTime.utc(2026, 11, 11, 5, 40),
);

/// 손으로 쓴 가짜 대화 저장소.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({
    List<ConversationSummary>? list,
    Map<String, ConversationDetail>? details,
    Map<String, List<ChatMessage>>? messages,
  }) : list = list ?? [],
       details = details ?? {},
       messages = messages ?? {};

  List<ConversationSummary> list;
  final Map<String, ConversationDetail> details;
  final Map<String, List<ChatMessage>> messages;

  bool failList = false;
  bool failDetail = false;

  /// 설정하면 [acceptRequest]·[declineRequest]가 이 예외를 던진다.
  ChatFailure? answerFailure;

  /// 설정하면 [acceptRequest]가 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? holdAccept;

  /// 설정하면 [send]가 이 예외를 던진다(네트워크가 꺼진 것처럼).
  ChatFailure? sendFailure;

  /// 설정하면 [send]가 이 Completer가 끝날 때까지 기다린 뒤 서버가 받은 것으로 처리한다.
  Completer<void>? holdSend;

  /// 설정하면 [send]가 서버에 저장은 하지만 응답 대신 이 예외를 던진다(응답을 잃은 경우).
  ChatFailure? lostResponse;

  /// 설정하면 [setMuted]가 이 예외를 던진다.
  ChatFailure? muteFailure;

  /// 설정하면 [block]·[report]가 이 예외를 던진다(돈이 보관 중이면 409, 이미 신고했으면 409).
  ChatFailure? blockFailure;
  ChatFailure? reportFailure;

  /// 설정하면 [block]이 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? holdBlock;

  /// 설정하면 [fetchMessages]가 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? holdFetch;

  int listCalls = 0;
  final accepted = <String>[];
  final declined = <String>[];
  final fetches = <({int? afterSeq, int? beforeSeq})>[];
  final sends = <({String id, String clientId, MessageKind kind})>[];
  final reads = <({String id, int seq})>[];
  final mutes = <({String id, bool muted})>[];
  final blocked = <String>[];
  final reports =
      <({ReportTarget target, ReportReason reason, String? detail})>[];

  /// 서버가 방에 메시지를 더한다(소켓 이벤트 없이). 가진 번호 다음 번호를 붙인다.
  ChatMessage serverAdds(
    String id, {
    String text = '서버에서 온 메시지',
    bool mine = false,
    String? clientId,
    DateTime? at,
  }) {
    final list = messages.putIfAbsent(id, () => []);
    final seq = list.isEmpty ? 1 : list.last.seq! + 1;
    final m = ChatMessage(
      id: 'm$seq',
      seq: seq,
      clientId: clientId ?? 'm$seq',
      kind: MessageKind.text,
      mine: mine,
      text: text,
      at: at ?? DateTime.utc(2026, 11, 11, 7, seq),
    );
    list.add(m);
    return m;
  }

  @override
  Future<List<ConversationSummary>> fetchList() async {
    listCalls++;
    if (failList) throw const ChatFailure.failed();
    return List.of(list);
  }

  @override
  Future<ConversationDetail> fetch(String id) async {
    if (failDetail) throw const ChatFailure.failed();
    return details[id] ?? (throw const ChatFailure.notFound());
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    String id, {
    int? afterSeq,
    int? beforeSeq,
  }) async {
    fetches.add((afterSeq: afterSeq, beforeSeq: beforeSeq));
    await holdFetch?.future;
    final all = messages[id] ?? const <ChatMessage>[];
    // 서버처럼: 앞 번호 뒤는 오름차순 앞에서 50개, 그 밖은 뒤에서 50개.
    if (afterSeq != null) {
      return all.where((m) => m.seq! > afterSeq).take(50).toList();
    }
    final older = beforeSeq == null
        ? all
        : all.where((m) => m.seq! < beforeSeq).toList();
    return older.length <= 50
        ? List.of(older)
        : older.sublist(older.length - 50);
  }

  @override
  Future<ChatMessage> send(
    String id, {
    required String clientId,
    required MessageKind kind,
    String? text,
  }) async {
    sends.add((id: id, clientId: clientId, kind: kind));
    final failure = sendFailure;
    if (failure != null) throw failure;
    await holdSend?.future;
    final list = messages.putIfAbsent(id, () => []);
    // 같은 clientId면 새로 만들지 않고 처음 것을 준다.
    final first = list.where((m) => m.mine && m.clientId == clientId);
    final ChatMessage saved;
    if (first.isNotEmpty) {
      saved = first.first;
    } else {
      final seq = list.isEmpty ? 1 : list.last.seq! + 1;
      saved = ChatMessage(
        id: 'm$seq',
        seq: seq,
        clientId: clientId,
        kind: kind,
        mine: true,
        text: text,
        card: kind == MessageKind.contentCard
            ? const ContentCard(title: '이런 분위기로 찍을게요')
            : null,
        at: DateTime.utc(2026, 11, 11, 8, seq),
      );
      list.add(saved);
    }
    final lost = lostResponse;
    if (lost != null) throw lost;
    return saved;
  }

  @override
  Future<void> markRead(String id, int seq) async {
    reads.add((id: id, seq: seq));
  }

  @override
  Future<void> setMuted(String id, bool muted) async {
    mutes.add((id: id, muted: muted));
    final failure = muteFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> block(String id) async {
    await holdBlock?.future;
    final failure = blockFailure;
    if (failure != null) throw failure;
    blocked.add(id);
    // 서버처럼 방이 닫히고 차단한 쪽에는 내가 차단했다고 표시된다.
    final before = details[id];
    if (before != null) {
      details[id] = before.copyWith(
        blockedByMe: true,
        status: ConversationStatus.closed,
      );
    }
  }

  @override
  Future<void> report(
    ReportTarget target,
    ReportReason reason,
    String? detail,
  ) async {
    final failure = reportFailure;
    if (failure != null) throw failure;
    reports.add((target: target, reason: reason, detail: detail));
  }

  @override
  Future<ConversationDetail> acceptRequest(String id) async {
    await holdAccept?.future;
    final failure = answerFailure;
    if (failure != null) throw failure;
    accepted.add(id);
    final before = details[id] ?? requestDetail(id);
    // 서버처럼 수락하면 방이 열린다.
    final opened = requestDetail(
      id,
      name: before.counterpartName,
      status: ConversationStatus.open,
      campaignTerms: before.campaignTerms,
    );
    details[id] = opened;
    return opened;
  }

  @override
  Future<void> declineRequest(String id) async {
    final failure = answerFailure;
    if (failure != null) throw failure;
    declined.add(id);
    list = [
      for (final r in list)
        if (r.id != id) r,
    ];
  }
}

/// 손으로 쓴 가짜 실시간 연결. 테스트가 이벤트를 직접 밀어 넣는다.
class FakeRealtimeConnection implements RealtimeConnection {
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _reconnected = StreamController<void>.broadcast();

  int starts = 0;
  int stops = 0;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Stream<void> get reconnected => _reconnected.stream;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> stop() async => stops++;

  void emit(RealtimeEvent event) => _events.add(event);

  void emitReconnected() => _reconnected.add(null);
}
