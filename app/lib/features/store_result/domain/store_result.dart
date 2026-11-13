import '../../offer_terms/domain/offer_terms.dart';

/// 결과를 낸 크리에이터. 이름은 활동 이름이다.
class StoreResultCreator {
  const StoreResultCreator({
    required this.userId,
    required this.name,
    this.photoUrl,
  });

  final String userId;
  final String name;
  final String? photoUrl;
}

/// 사장님이 맡긴 협업의 7일 결과(G1). 서버가 계산한 값을 그대로 담고 앱은 다시 계산하지 않는다.
class StoreResult {
  const StoreResult({
    required this.creator,
    required this.format,
    required this.postedAt,
    required this.postUrl,
    required this.payout,
    required this.refund,
    required this.fixedCash,
    required this.fixedCashOnly,
    this.views,
    this.usualViews,
    this.multiplierTenths,
  });

  final StoreResultCreator creator;
  final ContentFormat format;

  /// 게시한 때(제출된 링크를 낸 때).
  final DateTime postedAt;

  /// 크리에이터가 낸 게시 링크. `영상 받기`가 연다.
  final String postUrl;

  /// 7일 동안 센 조회수. 조회수를 읽지 못한 정산은 null이다.
  final int? views;

  /// 우리 가게 평소 게시물의 조회수. 읽지 못했으면 null.
  final int? usualViews;

  /// 평소 대비 배수를 10배 한 정수(31 = 3.1배). 평소 값이 없으면 null.
  final int? multiplierTenths;

  /// 크리에이터에게 간 돈(고정 현금 + 조회수 수당)과 사장님께 돌아온 돈(원).
  final int payout;
  final int refund;
  final int fixedCash;

  /// 조회수 수당이 없던 협업이다(고정 현금만 있다).
  final bool fixedCashOnly;

  /// 평소와 견줄 수 있다(배수가 있고 두 조회수가 모두 있다). 아니면 비교 상자를 숨긴다.
  bool get hasComparison =>
      multiplierTenths != null && (usualViews ?? 0) > 0 && (views ?? 0) > 0;
}
