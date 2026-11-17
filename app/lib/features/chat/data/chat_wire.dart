import 'package:cora_api/api.dart' as api;

import '../../collaboration/domain/collaboration.dart' show CollaborationKind;
import '../../negotiation/data/terms_version_from_wire.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import '../domain/realtime_connection.dart' show ConversationUpdateReason;

// 서버의 대화 모델을 앱의 타입으로 바꾼다. 생성된 타입은 data 계층 밖으로 새지 않게 여기서 끊는다.
// 소켓이 밀어 주는 메시지도 같은 모양이라 같은 변환을 쓴다.

MessageKind messageKindFromWire(api.MessageKind kind) => switch (kind) {
  api.MessageKind.TEXT => MessageKind.text,
  api.MessageKind.CONTENT_CARD => MessageKind.contentCard,
  _ => MessageKind.system,
};

api.SendableMessageKind sendableKindToWire(MessageKind kind) =>
    kind == MessageKind.contentCard
    ? api.SendableMessageKind.CONTENT_CARD
    : api.SendableMessageKind.TEXT;

ChatMessage chatMessageFromWire(api.MessageModel m) => ChatMessage(
  id: m.id,
  seq: m.seq,
  // 상대 메시지와 안내 줄에는 앱이 만든 값이 없다. 서버가 정한 id가 같은 일을 한다.
  clientId: m.clientId ?? m.id,
  kind: messageKindFromWire(m.kind),
  mine: m.mine,
  text: m.text,
  card: m.card == null
      ? null
      : ContentCard(title: m.card!.title, photoUrl: m.card!.photoUrl),
  at: m.createdAt,
);

ConversationUpdateReason updateReasonFromWire(Object? reason) =>
    switch (reason) {
      'TERMS' => ConversationUpdateReason.terms,
      'CONTRACT' => ConversationUpdateReason.contract,
      'STATUS' => ConversationUpdateReason.status,
      'READ' => ConversationUpdateReason.read,
      _ => ConversationUpdateReason.unknown,
    };

ConversationStatus _status(api.ConversationStatus s) => switch (s) {
  api.ConversationStatus.REQUESTED => ConversationStatus.requested,
  api.ConversationStatus.OPEN => ConversationStatus.open,
  api.ConversationStatus.DECLINED => ConversationStatus.declined,
  _ => ConversationStatus.closed,
};

ConversationSection _section(api.ConversationSection s) =>
    s == api.ConversationSection.REQUEST
    ? ConversationSection.request
    : ConversationSection.normal;

ConversationLastMessage? _last(api.ConversationLastMessageModel? m) => m == null
    ? null
    : ConversationLastMessage(
        kind: messageKindFromWire(m.kind),
        preview: m.preview,
        at: m.at,
      );

ConversationSummary conversationSummaryFromWire(
  api.ConversationSummaryModel m,
) => ConversationSummary(
  id: m.id,
  counterpartName: m.counterpart.name,
  counterpartPhotoUrl: m.counterpart.photoUrl,
  contextLabel: m.contextLabel,
  lastMessage: _last(m.lastMessage),
  muted: m.muted,
  section: _section(m.section),
  status: _status(m.status),
  unreadCount: m.unreadCount,
);

ConversationStage _stage(api.CollaborationStage s) => switch (s) {
  api.CollaborationStage.INQUIRY => ConversationStage.inquiry,
  api.CollaborationStage.MATCHED => ConversationStage.matched,
  api.CollaborationStage.NEGOTIATING => ConversationStage.negotiating,
  api.CollaborationStage.AGREED => ConversationStage.agreed,
  api.CollaborationStage.CONTRACTED => ConversationStage.contracted,
  api.CollaborationStage.GUIDED => ConversationStage.guided,
  api.CollaborationStage.REVIEWING => ConversationStage.reviewing,
  api.CollaborationStage.APPROVED => ConversationStage.approved,
  api.CollaborationStage.PUBLISHED => ConversationStage.published,
  api.CollaborationStage.SETTLED ||
  api.CollaborationStage.REFUNDED => ConversationStage.settled,
  api.CollaborationStage.DROPPED ||
  api.CollaborationStage.CANCELLED => ConversationStage.dropped,
  api.CollaborationStage.HALTED => ConversationStage.halted,
  _ => ConversationStage.other,
};

ConversationDetail conversationDetailFromWire(api.ConversationDetailModel m) =>
    ConversationDetail(
      id: m.id,
      collaborationId: m.collaborationId,
      kind: m.kind == api.CollaborationKind.STORE_OFFER
          ? CollaborationKind.storeOffer
          : CollaborationKind.brandContract,
      counterpartName: m.counterpart.name,
      counterpartPhotoUrl: m.counterpart.photoUrl,
      contextLabel: m.contextLabel,
      status: _status(m.status),
      section: _section(m.section),
      requestedByMe: m.requestedByMe,
      myRole: m.myRole == api.CollaborationRole.COMMISSIONER
          ? ChatRole.commissioner
          : ChatRole.creator,
      stage: _stage(m.stage),
      contractStatus: switch (m.contractStatus) {
        api.ContractProgress.AWAITING_BRAND => ContractProgress.awaitingBrand,
        api.ContractProgress.CONCLUDED => ContractProgress.concluded,
        _ => ContractProgress.none,
      },
      lastSeq: m.lastSeq,
      lastReadSeq: m.lastReadSeq,
      unreadCount: m.unreadCount,
      muted: m.muted,
      blockedByMe: m.blockedByMe,
      canSend: m.canSend,
      canSendContentCard: m.canSendContentCard,
      canProposeTerms: m.canProposeTerms,
      canDrop: m.canDrop,
      canLikeCampaign: m.canLikeCampaign,
      lastMessage: _last(m.lastMessage),
      terms: m.terms == null ? null : termsVersionFromWire(m.terms!),
      storeTerms: m.storeTerms == null
          ? null
          : offerTermsFromWire(m.storeTerms!),
      campaignTerms: m.campaignTerms == null
          ? null
          : CampaignTerms(
              fee: m.campaignTerms!.fee,
              format: formatFromWire(m.campaignTerms!.format),
              productProvided: m.campaignTerms!.productProvided,
              startFrom: dateOnly(m.campaignTerms!.startFrom),
            ),
    );
