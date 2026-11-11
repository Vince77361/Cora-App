import 'package:cora/core/theme/cora_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motion constants follow the foundation plan', () {
    expect(CoraMotion.pushDuration, const Duration(milliseconds: 320));
    expect(CoraMotion.sheetDuration, const Duration(milliseconds: 380));
    expect(CoraMotion.fadeDuration, const Duration(milliseconds: 200));
    expect(CoraMotion.stateDuration, const Duration(milliseconds: 200));
    expect(CoraMotion.standardCurve, Curves.easeOutCubic);
    expect(CoraMotion.pushEnterOffset, 0.24);
    expect(CoraMotion.pushUnderlayOffset, 0.08);
    expect(CoraMotion.sheetUnderlayScale, 0.96);
  });

  testWidgets(
    'durations collapse to zero when the platform asks to reduce motion',
    (tester) async {
      late Duration normal;
      late Duration reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              normal = CoraMotion.resolve(context, CoraMotion.stateDuration);
              return MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Builder(
                  builder: (context) {
                    reduced = CoraMotion.resolve(
                      context,
                      CoraMotion.stateDuration,
                    );
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
      expect(normal, CoraMotion.stateDuration);
      expect(reduced, Duration.zero);
    },
  );
}
