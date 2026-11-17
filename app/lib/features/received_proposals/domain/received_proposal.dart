import '../../offer_terms/domain/offer_terms.dart' show ContentFormat, ViewPay;

/// 브랜드가 내 콘텐츠에 관심을 보내며 건넨 제안 하나(10 받은 제안). 캠페인 [campaignId] 하나에 하나다.
///
/// 제작비·제품 제공·성과 추가는 브랜드가 관심과 함께 저장한 제안이 있으면 그 값이고, 없으면 캠페인의 값이다
/// (서버가 정해 보낸다. 앱은 그대로 보여 준다).
class ReceivedProposal {
  const ReceivedProposal({
    required this.campaignId,
    required this.brandName,
    this.brandPhotoUrl,
    this.contentPhotoUrl,
    this.contentTitle,
    required this.fee,
    required this.format,
    this.note,
    this.performance,
    required this.productProvided,
  });

  final String campaignId;
  final String brandName;
  final String? brandPhotoUrl;

  /// 브랜드가 고른 내 콘텐츠의 사진과 제목(보낸 때의 사본). 사본이 없으면 둘 다 null이고 내 프로필에 한 제안이다.
  final String? contentPhotoUrl;
  final String? contentTitle;
  final int fee;
  final ContentFormat format;

  /// 브랜드가 쓴 글(좋아한 점). 조건 제안만 붙었으면 null.
  final String? note;

  /// 성과 추가. 없으면 null.
  final ViewPay? performance;
  final bool productProvided;

  @override
  bool operator ==(Object other) =>
      other is ReceivedProposal &&
      other.campaignId == campaignId &&
      other.brandName == brandName &&
      other.brandPhotoUrl == brandPhotoUrl &&
      other.contentPhotoUrl == contentPhotoUrl &&
      other.contentTitle == contentTitle &&
      other.fee == fee &&
      other.format == format &&
      other.note == note &&
      other.performance == performance &&
      other.productProvided == productProvided;

  @override
  int get hashCode => Object.hash(
    campaignId,
    brandName,
    brandPhotoUrl,
    contentPhotoUrl,
    contentTitle,
    fee,
    format,
    note,
    performance,
    productProvided,
  );
}

/// `조건부터 질문하기`로 열린 메시지 요청. 브랜드가 수락하면 [conversationId]의 대화가 열린다.
class InquiryResult {
  const InquiryResult({
    required this.collaborationId,
    required this.conversationId,
  });

  final String collaborationId;
  final String conversationId;
}
