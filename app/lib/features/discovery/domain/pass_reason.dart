/// 넘긴 이유(02). 남기면 다음 추천에만 반영하고 상대에게는 알리지 않는다. 이유를 남기지 않은 것은
/// 이 값이 아니라 null이다.
enum PassReason {
  mood('표현 분위기가 달라요'),
  region('지역·방문이 어려워요'),
  fee('금액이 안 맞아요'),
  field('분야가 달라요');

  const PassReason(this.label);

  /// 시트에 보이는 문구(캔버스 Pass).
  final String label;
}
