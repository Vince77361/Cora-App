import 'dart:math' as math;
import 'dart:ui';

/// 카드를 넘긴 결과. 오른쪽은 하트(`LIKE`), 왼쪽은 넘김, 위쪽은 저장(`HOLD`)이다.
enum SwipeOutcome { like, pass, hold }

/// 넘기기 기준(캔버스 01의 `dx > 110`, `dx < -110`, `dy < -140 && |dx| < 80`).
const double swipeSideThreshold = 110;
const double swipeHoldThreshold = 140;
const double swipeHoldMaxSideways = 80;

/// 카드 최대 기울기(도).
const double swipeMaxTiltDegrees = 12;

/// 놓은 자리에서 어떤 결과가 되는지. 기준에 못 미치면 null이고 카드는 제자리로 돌아간다.
/// 가로 기준을 먼저 보므로 비스듬히 크게 밀면 위쪽 저장이 아니라 하트·넘김이다.
SwipeOutcome? resolveSwipe(Offset offset) {
  if (offset.dx > swipeSideThreshold) return SwipeOutcome.like;
  if (offset.dx < -swipeSideThreshold) return SwipeOutcome.pass;
  if (offset.dy < -swipeHoldThreshold &&
      offset.dx.abs() < swipeHoldMaxSideways) {
    return SwipeOutcome.hold;
  }
  return null;
}

/// 가로로 민 만큼의 카드 기울기(도). 카드 너비만큼 밀면 12도이고 ±12도로 자른다.
double tiltFor(double dx, double width) {
  if (width <= 0) return 0;
  return (dx / width * swipeMaxTiltDegrees).clamp(
    -swipeMaxTiltDegrees,
    swipeMaxTiltDegrees,
  );
}

/// 도장의 불투명도. 해당 기준의 0%에서 100%까지 0에서 1로 오른다.
/// 저장은 옆으로 80 이상 기울면 저장이 아니므로 사라진다.
double stampOpacity(Offset offset, SwipeOutcome outcome) {
  final progress = switch (outcome) {
    SwipeOutcome.like => offset.dx / swipeSideThreshold,
    SwipeOutcome.pass => -offset.dx / swipeSideThreshold,
    SwipeOutcome.hold =>
      offset.dx.abs() < swipeHoldMaxSideways
          ? -offset.dy / swipeHoldThreshold
          : 0.0,
  };
  return math.min(1.0, math.max(0.0, progress));
}

/// 지금 끌린 정도(0~1). 뒤 카드가 96%에서 100%로 커지는 비율에 쓴다.
double swipeProgress(Offset offset) => [
  for (final outcome in SwipeOutcome.values) stampOpacity(offset, outcome),
].reduce(math.max);
