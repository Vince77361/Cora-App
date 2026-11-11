import 'dart:math' as math;

import 'package:cora/core/theme/cora_motion.dart';
import 'package:cora/core/ui/cora_pressable.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

const _surface = ValueKey('surface');

/// 화면에 실제로 그려진 너비 ÷ 배치 너비. 줄어든 만큼 1보다 작다.
double _renderedScale(WidgetTester tester) {
  final finder = find.byKey(_surface);
  return tester.getRect(finder).width / tester.getSize(finder).width;
}

/// 화면보다 긴 스크롤 안에 누를 수 있는 면을 둔다. 스크롤의 끌기 인식기가 경쟁하므로
/// 탭이 짧으면 onTapDown과 onTapUp이 한 이벤트에서 같이 온다.
Widget _inScrollView(VoidCallback onTap, {bool disableAnimations = false}) {
  return coraTestApp(
    SizedBox(
      height: 400,
      child: SingleChildScrollView(
        child: Column(
          children: [
            CoraPressable(
              onTap: onTap,
              child: const SizedBox(key: _surface, width: 300, height: 58),
            ),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    ),
    disableAnimations: disableAnimations,
  );
}

/// 손을 뗀 뒤 [frames] 프레임 동안 그려진 크기를 모은다.
Future<List<double>> _scalesAfterRelease(
  WidgetTester tester, {
  int frames = 20,
}) async {
  final scales = <double>[];
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    scales.add(_renderedScale(tester));
  }
  return scales;
}

void main() {
  testWidgets('a quick tap inside a scroll view still shows the press', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_inScrollView(() => taps++));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_surface)),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    // 동작은 눌림 효과를 기다리지 않고 손을 떼는 순간 바로 불린다.
    expect(taps, 1);

    final scales = await _scalesAfterRelease(tester);
    expect(scales.reduce(math.min), lessThan(1));
    expect(
      scales.reduce(math.min),
      moreOrLessEquals(CoraMotion.pressedScale, epsilon: 0.002),
    );
    // 끝나면 원래 크기로 돌아온다.
    expect(scales.last, 1);
  });

  testWidgets('a held press stays down until it is released', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        CoraPressable(
          onTap: () {},
          child: const SizedBox(key: _surface, width: 300, height: 58),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_surface)),
    );
    // 첫 프레임에서 움직임이 시작되고, 그 뒤 오래 누르고 있는다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      _renderedScale(tester),
      moreOrLessEquals(CoraMotion.pressedScale, epsilon: 0.0001),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_renderedScale(tester), 1);
  });

  testWidgets(
    'a quick tap on the primary button inside a scroll view shows the press',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        coraTestApp(
          SizedBox(
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CoraPrimaryButton(label: '다음', onPressed: () => taps++),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );
      final surface = find.descendant(
        of: find.byType(CoraPrimaryButton),
        matching: find.byType(DecoratedBox),
      );

      await tester.tap(find.byType(CoraPrimaryButton));
      expect(taps, 1);
      var smallest = 1.0;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        smallest = math.min(
          smallest,
          tester.getRect(surface).width / tester.getSize(surface).width,
        );
      }
      expect(smallest, lessThan(1));
    },
  );

  testWidgets('the press does not linger when reducing motion', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _inScrollView(() => taps++, disableAnimations: true),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_surface)),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    expect(taps, 1);
    await tester.pump();
    expect(_renderedScale(tester), 1);
  });
}
