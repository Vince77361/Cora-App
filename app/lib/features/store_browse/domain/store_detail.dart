import 'store_summary.dart';

/// 내가 이 가게에 낸 지원의 상태. 지원하지 않았으면 [none], 지원만 했으면 [applied],
/// 사장님이 오퍼를 보냈으면 [offered].
enum MyApplicationStatus { none, applied, offered }

/// 이 가게와 내가 주고받는 열린 제안. 사장님이 보냈든 내가 먼저 냈든 한 가게에 하나다.
class MyOpenOffer {
  const MyOpenOffer({
    required this.offerId,
    required this.latestVersion,
    required this.myTurn,
  });

  final String offerId;
  final int latestVersion;

  /// 지금 응답할 차례가 나다. 아니면 상대의 답을 기다리는 중이라 내 방식으로 제안할 수 없다.
  final bool myTurn;

  @override
  bool operator ==(Object other) =>
      other is MyOpenOffer &&
      other.offerId == offerId &&
      other.latestVersion == latestVersion &&
      other.myTurn == myTurn;

  @override
  int get hashCode => Object.hash(offerId, latestVersion, myTurn);
}

/// D2 가게 오퍼 상세에 보이는 가게.
class StoreDetail {
  const StoreDetail({
    required this.summary,
    required this.myApplicationStatus,
    this.intro,
    this.bestShootingTime,
    this.myOpenOffer,
  });

  final StoreSummary summary;
  final MyApplicationStatus myApplicationStatus;

  /// 이 가게와 열린 제안이 있으면 그 오퍼. 없으면 null.
  final MyOpenOffer? myOpenOffer;

  /// 크리에이터에게 보여 주는 소개 글.
  final String? intro;
  final String? bestShootingTime;

  StoreDetail withStatus(MyApplicationStatus status) => StoreDetail(
    summary: summary,
    myApplicationStatus: status,
    intro: intro,
    bestShootingTime: bestShootingTime,
    myOpenOffer: myOpenOffer,
  );
}
