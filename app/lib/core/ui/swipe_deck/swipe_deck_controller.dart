import 'package:flutter/foundation.dart';

import 'swipe_physics.dart';

/// 버튼(되돌리기 옆의 넘기기·보류·관심)으로 카드를 넘길 때 쓴다. [SwipeDeck]에 붙이면
/// 끌어서 넘길 때와 같은 움직임으로 맨 위 카드를 보낸다.
///
/// [busy]가 바뀌면 알려 주므로 버튼을 잠그는 데 쓸 수 있다.
class SwipeDeckController extends ChangeNotifier {
  Future<void> Function(SwipeOutcome)? _swipe;
  bool _busy = false;

  /// 카드가 날아가는 중이거나 `onSwiped`가 끝나지 않았는지.
  bool get busy => _busy;

  /// 맨 위 카드를 [outcome]으로 넘긴다. `onSwiped`까지 끝나면 완료된다. [busy]이거나 넘길 카드가
  /// 없으면 아무것도 하지 않고 바로 끝난다.
  Future<void> swipe(SwipeOutcome outcome) =>
      _swipe?.call(outcome) ?? Future<void>.value();

  /// [SwipeDeck]의 State만 부른다.
  void attach(Future<void> Function(SwipeOutcome) swipe) => _swipe = swipe;

  void detach(Future<void> Function(SwipeOutcome) swipe) {
    if (_swipe == swipe) {
      _swipe = null;
      _busy = false;
    }
  }

  void setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }
}
