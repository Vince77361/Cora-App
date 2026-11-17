import '../../collaboration/domain/collaboration.dart' show CollaborationKind;
import '../../negotiation/domain/terms_version.dart';
import '../../offer_terms/domain/offer_terms.dart'
    show ContentFormat, OfferTerms;
import 'message.dart';

/// 대화방의 상태. 서버의 `ConversationStatus`와 같다.
enum ConversationStatus { requested, open, declined, closed }

/// 목록에서 어디에 놓이는지. [request]는 내가 답해야 하는 메시지 요청(맨 위 묶음)이다.
enum ConversationSection { request, normal }

/// 계약 진행. [awaitingBrand]는 크리에이터가 동의해 브랜드의 결제를 기다리는 때다.
enum ContractProgress { none, awaitingBrand, concluded }

/// 내 쪽. [commissioner]는 맡긴 쪽(사장님·브랜드)이다.
enum ChatRole { commissioner, creator }

/// 협업의 단계. 대화방 머리의 상태 줄을 고르는 데 필요한 만큼만 나눈다.
enum ConversationStage {
  inquiry,
  matched,
  negotiating,
  agreed,
  contracted,
  guided,
  reviewing,
  approved,
  published,
  settled,
  dropped,
  halted,
  other,
}

/// 목록 줄에 보이는 마지막 메시지.
class ConversationLastMessage {
  const ConversationLastMessage({
    required this.kind,
    required this.preview,
    required this.at,
  });

  final MessageKind kind;

  /// 서버가 60자까지로 줄인 미리 보기. 콘텐츠 카드는 `콘텐츠 카드를 보냈어요.`.
  final String preview;
  final DateTime at;
}

/// 목록의 한 줄.
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.counterpartName,
    this.counterpartPhotoUrl,
    required this.contextLabel,
    this.lastMessage,
    required this.muted,
    required this.section,
    required this.status,
    required this.unreadCount,
  });

  final String id;
  final String counterpartName;
  final String? counterpartPhotoUrl;

  /// 캠페인 한 줄 또는 가게 이름.
  final String contextLabel;
  final ConversationLastMessage? lastMessage;

  /// 이 방의 알림을 꺼 두었다.
  final bool muted;
  final ConversationSection section;
  final ConversationStatus status;
  final int unreadCount;
}

/// 서로 관심 전(`INQUIRY`) 대화방의 캠페인 조건. 메시지 요청(11)의 요약이 이 값이다.
class CampaignTerms {
  const CampaignTerms({
    required this.fee,
    required this.format,
    required this.productProvided,
    required this.startFrom,
  });

  final int fee;
  final ContentFormat format;
  final bool productProvided;

  /// 제작 시작. 날짜만 뜻이 있다.
  final DateTime startFrom;
}

/// 대화방 하나의 머리와 내 처지. 메시지는 [ChatRepository.fetchMessages]가 따로 준다.
class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.collaborationId,
    required this.kind,
    required this.counterpartName,
    this.counterpartPhotoUrl,
    required this.contextLabel,
    required this.status,
    required this.section,
    required this.requestedByMe,
    required this.myRole,
    required this.stage,
    required this.contractStatus,
    required this.lastSeq,
    required this.lastReadSeq,
    required this.unreadCount,
    required this.muted,
    required this.blockedByMe,
    required this.canSend,
    required this.canSendContentCard,
    required this.canProposeTerms,
    required this.canDrop,
    required this.canLikeCampaign,
    this.lastMessage,
    this.terms,
    this.storeTerms,
    this.campaignTerms,
  });

  final String id;
  final String collaborationId;
  final CollaborationKind kind;
  final String counterpartName;
  final String? counterpartPhotoUrl;

  /// 캠페인 한 줄 또는 가게 이름.
  final String contextLabel;
  final ConversationStatus status;
  final ConversationSection section;

  /// 내가 먼저 보낸 메시지 요청이다.
  final bool requestedByMe;
  final ChatRole myRole;
  final ConversationStage stage;
  final ContractProgress contractStatus;
  final int lastSeq;
  final int lastReadSeq;
  final int unreadCount;
  final bool muted;
  final bool blockedByMe;

  /// 지금 글을 보낼 수 있다(방이 열려 있다).
  final bool canSend;
  final bool canSendContentCard;
  final bool canProposeTerms;
  final bool canDrop;
  final bool canLikeCampaign;
  final ConversationLastMessage? lastMessage;

  /// 브랜드 계약의 최신 조건 버전. 아직 없으면 null.
  final TermsVersion? terms;

  /// 가게 오퍼의 수락된 판본의 조건. 브랜드 계약은 null.
  final OfferTerms? storeTerms;

  /// 서로 관심 전의 캠페인 조건. 그 밖은 null.
  final CampaignTerms? campaignTerms;

  /// 내가 답해야 하는 메시지 요청이다(11이 이 방을 연다).
  bool get isRequestForMe =>
      status == ConversationStatus.requested && !requestedByMe;

  /// 서버가 알려 주기 전에 화면이 먼저 바꾸는 값(알림 끄기·켜기)만 바꾼 사본.
  ConversationDetail copyWith({bool? muted}) => ConversationDetail(
    id: id,
    collaborationId: collaborationId,
    kind: kind,
    counterpartName: counterpartName,
    counterpartPhotoUrl: counterpartPhotoUrl,
    contextLabel: contextLabel,
    status: status,
    section: section,
    requestedByMe: requestedByMe,
    myRole: myRole,
    stage: stage,
    contractStatus: contractStatus,
    lastSeq: lastSeq,
    lastReadSeq: lastReadSeq,
    unreadCount: unreadCount,
    muted: muted ?? this.muted,
    blockedByMe: blockedByMe,
    canSend: canSend,
    canSendContentCard: canSendContentCard,
    canProposeTerms: canProposeTerms,
    canDrop: canDrop,
    canLikeCampaign: canLikeCampaign,
    lastMessage: lastMessage,
    terms: terms,
    storeTerms: storeTerms,
    campaignTerms: campaignTerms,
  );
}
