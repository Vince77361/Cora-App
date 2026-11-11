import '../../offer_terms/domain/offer_terms.dart';

/// 결제 화면(A8)이 그리는 견적. 서버가 협업의 확정 조건에서 계산한 값이라 앱은 다시 계산하지 않는다.
class PaymentQuote {
  const PaymentQuote({
    required this.creatorName,
    required this.creatorPhotoUrl,
    required this.format,
    required this.pieces,
    required this.voucherName,
    required this.escrow,
    required this.fee,
    required this.total,
  });

  /// 오퍼를 수락한 크리에이터의 활동 이름.
  final String creatorName;
  final String? creatorPhotoUrl;
  final ContentFormat format;

  /// 콘텐츠 편 수. 오퍼는 지금 한 편이다.
  final int pieces;

  /// 식사권 이름. 조회수당 지급만 있는 오퍼는 null이라 식사권 줄을 그리지 않는다.
  final String? voucherName;

  /// 에스크로에 보관할 금액(조회수당 상한).
  final int escrow;

  /// 서비스 수수료.
  final int fee;

  /// 지금 결제할 금액(보관 금액 + 수수료).
  final int total;
}
