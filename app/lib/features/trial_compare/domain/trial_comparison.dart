import '../../offer_terms/domain/offer_terms.dart';

/// 형식별로 생긴 콘텐츠 수.
class ContentCount {
  const ContentCount({required this.format, required this.count});

  final ContentFormat format;
  final int count;
}

/// 체험단 쪽: 사장님이 입력한 값이다.
class TrialSide {
  const TrialSide({
    required this.monthlyFee,
    required this.endsOn,
    required this.postCount,
    required this.spent,
  });

  final int monthlyFee;
  final DateTime endsOn;
  final int postCount;

  /// 석 달 동안 들어간 돈(원).
  final int spent;
}

/// Cora 쪽: 석 달 동안 끝난 협업을 서버가 모은 값이다.
class CoraSide {
  const CoraSide({
    required this.offerCount,
    required this.spent,
    this.averageMultiplierTenths,
    this.contentByFormat = const [],
  });

  final int offerCount;
  final int spent;

  /// 평소 대비 배수(10배 한 정수)의 평균. 배수가 있는 협업이 없으면 null.
  final int? averageMultiplierTenths;
  final List<ContentCount> contentByFormat;
}

/// 지난 3개월 비교(G3).
class TrialComparison {
  const TrialComparison({required this.trial, required this.cora});

  final TrialSide trial;
  final CoraSide cora;
}
