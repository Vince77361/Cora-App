import 'store_summary.dart';

/// 내가 이 가게에 낸 지원의 상태. 지원하지 않았으면 [none], 지원만 했으면 [applied],
/// 사장님이 오퍼를 보냈으면 [offered].
enum MyApplicationStatus { none, applied, offered }

/// D2 가게 오퍼 상세에 보이는 가게.
class StoreDetail {
  const StoreDetail({
    required this.summary,
    required this.myApplicationStatus,
    this.intro,
    this.bestShootingTime,
  });

  final StoreSummary summary;
  final MyApplicationStatus myApplicationStatus;

  /// 크리에이터에게 보여 주는 소개 글.
  final String? intro;
  final String? bestShootingTime;

  StoreDetail withStatus(MyApplicationStatus status) => StoreDetail(
    summary: summary,
    myApplicationStatus: status,
    intro: intro,
    bestShootingTime: bestShootingTime,
  );
}
