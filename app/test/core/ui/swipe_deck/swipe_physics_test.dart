import 'package:cora/core/ui/swipe_deck/swipe_physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves like, pass and hold at the canvas thresholds', () {
    expect(resolveSwipe(const Offset(111, 0)), SwipeOutcome.like);
    expect(resolveSwipe(const Offset(110, 0)), isNull);
    expect(resolveSwipe(const Offset(-111, 0)), SwipeOutcome.pass);
    expect(resolveSwipe(const Offset(-110, 0)), isNull);
    expect(resolveSwipe(const Offset(79, -141)), SwipeOutcome.hold);
    expect(resolveSwipe(const Offset(-79, -141)), SwipeOutcome.hold);
    expect(resolveSwipe(const Offset(80, -141)), isNull);
    expect(resolveSwipe(const Offset(0, -140)), isNull);
    expect(resolveSwipe(const Offset(0, 300)), isNull);
  });

  test('a sideways drag past the threshold wins over a high drag', () {
    expect(resolveSwipe(const Offset(120, -200)), SwipeOutcome.like);
    expect(resolveSwipe(const Offset(-120, -200)), SwipeOutcome.pass);
  });

  test('tilts up to 12 degrees', () {
    expect(tiltFor(0, 300), 0);
    expect(tiltFor(150, 300), closeTo(6, 1e-9));
    expect(tiltFor(-150, 300), closeTo(-6, 1e-9));
    expect(tiltFor(300, 300), closeTo(12, 1e-9));
    expect(tiltFor(900, 300), 12);
    expect(tiltFor(-900, 300), -12);
  });

  test('does not tilt when the card has no width yet', () {
    expect(tiltFor(50, 0), 0);
  });

  test('stamp opacity rises from 0 to 1 over the threshold', () {
    expect(stampOpacity(Offset.zero, SwipeOutcome.like), 0);
    expect(stampOpacity(const Offset(55, 0), SwipeOutcome.like), 0.5);
    expect(stampOpacity(const Offset(110, 0), SwipeOutcome.like), 1);
    expect(stampOpacity(const Offset(400, 0), SwipeOutcome.like), 1);
    expect(stampOpacity(const Offset(-55, 0), SwipeOutcome.like), 0);

    expect(stampOpacity(const Offset(-55, 0), SwipeOutcome.pass), 0.5);
    expect(stampOpacity(const Offset(55, 0), SwipeOutcome.pass), 0);

    expect(stampOpacity(const Offset(0, -70), SwipeOutcome.hold), 0.5);
    expect(stampOpacity(const Offset(0, -140), SwipeOutcome.hold), 1);
    expect(stampOpacity(const Offset(0, 70), SwipeOutcome.hold), 0);
  });

  test('hold stamp fades out once the drag leans too far sideways', () {
    expect(stampOpacity(const Offset(79, -140), SwipeOutcome.hold), 1);
    expect(stampOpacity(const Offset(80, -140), SwipeOutcome.hold), 0);
  });
}
