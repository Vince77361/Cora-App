import 'package:cora/core/time/clock.dart';

/// 손으로 쓴 가짜 시계. 테스트가 시각을 직접 앞으로 보낸다.
class FakeClock implements Clock {
  DateTime current = DateTime.utc(2026, 11, 11, 12);

  @override
  DateTime now() => current;

  void advance(Duration by) => current = current.add(by);
}
