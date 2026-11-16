import '../../store_onboarding/domain/my_store.dart' show IndustryCategory;

/// 릴스 1편에 생각하는 제작비 구간(설계 2장 09의 6번 질문).
enum FeeBand { w200k, w300k, w400k, w500kPlus }

/// 제품을 받고 써 보는 기간(7번 질문). [any]는 `상관없어요`.
enum ProductTrialDays { d3, d7, d14, any }

/// 크리에이터의 협업 원칙. 본인에게만 보인다(브랜드는 이것을 줄여 만든 카드의 꼬리표를 본다).
class Principles {
  const Principles({
    required this.fields,
    required this.blockedIndustries,
    required this.faceOk,
    required this.scriptOk,
    required this.honestReview,
    required this.feeBand,
    required this.trialDays,
  });

  /// 받고 싶은 분야. 일반 업종 중 1개 이상.
  final List<IndustryCategory> fields;

  /// 피하는 업종. 민감 업종 중 0개 이상. 고른 업종의 브랜드에게는 내 프로필이 보이지 않는다.
  final List<IndustryCategory> blockedIndustries;

  /// 얼굴이 나오는 촬영도 괜찮은지.
  final bool faceOk;

  /// 정해진 대본을 읽어도 괜찮은지.
  final bool scriptOk;

  /// 단점도 솔직하게 말해도 되는지.
  final bool honestReview;

  final FeeBand feeBand;
  final ProductTrialDays trialDays;

  @override
  bool operator ==(Object other) =>
      other is Principles &&
      _sameList(other.fields, fields) &&
      _sameList(other.blockedIndustries, blockedIndustries) &&
      other.faceOk == faceOk &&
      other.scriptOk == scriptOk &&
      other.honestReview == honestReview &&
      other.feeBand == feeBand &&
      other.trialDays == trialDays;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(fields),
    Object.hashAll(blockedIndustries),
    faceOk,
    scriptOk,
    honestReview,
    feeBand,
    trialDays,
  );

  static bool _sameList(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
