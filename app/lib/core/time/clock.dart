import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 지금 시각. 타이머처럼 시각에 따라 움직이는 코드가 `DateTime.now()`를 직접 부르지 않고
/// 이것을 받게 해서, 테스트가 시각을 마음대로 보내게 한다.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// 기본값이 실제 시계라서 main에서 따로 바꿔 끼우지 않는다. 테스트가 가짜 시계로 바꾼다.
final clockProvider = Provider<Clock>((ref) => const SystemClock());
