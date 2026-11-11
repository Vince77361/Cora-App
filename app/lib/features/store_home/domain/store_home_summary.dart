/// 사장님 홈 맨 위의 숫자 세 칸.
class StoreHomeSummary {
  const StoreHomeSummary({
    required this.newApplications,
    required this.sentOffers,
    required this.inProgress,
  });

  final int newApplications;
  final int sentOffers;
  final int inProgress;
}
