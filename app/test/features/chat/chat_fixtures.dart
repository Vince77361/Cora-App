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
    show ContentFormat, ViewPay;

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

/// 방 머리. 협업 단계와 조건 판본을 바꿔 가며 쓴다.
ConversationDetail roomDetail({
  String id = 'room-1',
  ConversationStage stage = ConversationStage.negotiating,
  ContractProgress contractStatus = ContractProgress.none,
  TermsVersion? terms,
}) => ConversationDetail(
  id: id,
  collaborationId: 'collab-$id',
  kind: CollaborationKind.brandContract,
  counterpartName: '모아 스튜디오',
  contextLabel: '느린 결, 일상의 주얼리 캠페인',
  status: ConversationStatus.open,
  section: ConversationSection.normal,
  requestedByMe: false,
  myRole: ChatRole.creator,
  stage: stage,
  contractStatus: contractStatus,
  lastSeq: 3,
  lastReadSeq: 3,
  unreadCount: 0,
  muted: false,
  blockedByMe: false,
  canSend: true,
  canSendContentCard: true,
  canProposeTerms: true,
  canDrop: true,
  canLikeCampaign: false,
  terms: terms,
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

  int listCalls = 0;
  final accepted = <String>[];
  final declined = <String>[];

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
  }) async => List.of(messages[id] ?? const []);

  @override
  Future<ChatMessage> send(
    String id, {
    required String clientId,
    required MessageKind kind,
    String? text,
  }) => throw UnimplementedError('이 작업의 화면은 보내지 않는다.');

  @override
  Future<void> markRead(String id, int seq) async {}

  @override
  Future<void> setMuted(String id, bool muted) async {}

  @override
  Future<void> block(String id) async {}

  @override
  Future<void> report(
    ReportTarget target,
    ReportReason reason,
    String? detail,
  ) async {}

  @override
  Future<ConversationDetail> acceptRequest(String id) async {
    await holdAccept?.future;
    final failure = answerFailure;
    if (failure != null) throw failure;
    accepted.add(id);
    final opened = (details[id] ?? requestDetail(id));
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
