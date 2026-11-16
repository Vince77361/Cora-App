/// 브랜드가 관심에 붙이는 보상 제안(F2의 `이 조건으로 보내기`가 만든다). 서버의 `BrandProposalDto`와
/// 같은 모양이고, F1의 `OfferTerms`에서 이 값으로 바꾸는 일은 10번 작업이 한다. 01에서는 `decide`에
/// 그대로 실어 보내기만 한다.
class RewardProposal {
  const RewardProposal({
    required this.fee,
    required this.productProvided,
    this.performance,
  });

  /// 현금 고정비(원).
  final int fee;
  final bool productProvided;

  /// 성과 추가(조회수 1,000회당 단가와 상한). 없으면 null.
  final ({int ratePer1000, int cap})? performance;

  @override
  bool operator ==(Object other) =>
      other is RewardProposal &&
      other.fee == fee &&
      other.productProvided == productProvided &&
      other.performance == performance;

  @override
  int get hashCode => Object.hash(fee, productProvided, performance);
}
