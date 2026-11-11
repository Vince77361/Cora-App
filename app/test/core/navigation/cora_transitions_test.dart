import 'package:cora/core/navigation/cora_transitions.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 글자를 왼쪽 위에 둔 화면. 글자 위치로 화면이 얼마나 밀렸는지 잰다.
class _Page extends StatelessWidget {
  const _Page(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(alignment: Alignment.topLeft, child: Text(label)),
  );
}

Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  TargetPlatform platform = TargetPlatform.android,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            CoraTransitions.fade(const _Page('A'), key: state.pageKey),
      ),
      GoRoute(
        path: '/push',
        pageBuilder: (context, state) =>
            CoraTransitions.push(const _Page('B'), key: state.pageKey),
      ),
      GoRoute(
        path: '/push2',
        pageBuilder: (context, state) =>
            CoraTransitions.push(const _Page('E'), key: state.pageKey),
      ),
      GoRoute(
        path: '/sheet',
        pageBuilder: (context, state) =>
            CoraTransitions.sheet(const _Page('C'), key: state.pageKey),
      ),
      GoRoute(
        path: '/fade',
        pageBuilder: (context, state) =>
            CoraTransitions.fade(const _Page('D'), key: state.pageKey),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: coraLightTheme.copyWith(platform: platform),
    ),
  );
  return router;
}

double _opacityOf(WidgetTester tester, String label) => tester
    .widget<FadeTransition>(
      find
          .ancestor(of: find.text(label), matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

// 테스트 화면 크기는 800 x 600이다.
const _width = 800.0;
const _height = 600.0;

void main() {
  test('hero tags follow the kind:id rule', () {
    expect(CoraHeroTag.of('creator', 42), 'creator:42');
    expect(CoraHeroTag.of('store', 'a1b2'), 'store:a1b2');
  });

  testWidgets('push transition finishes after 320ms', (tester) async {
    final router = await _pumpRouter(tester);
    router.push('/push');
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 319));
    expect(find.text('A'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets(
    'push slides in from 24% right and fades while the page below slides 8% left',
    (tester) async {
      final router = await _pumpRouter(tester);
      router.push('/push');
      await tester.pump();
      // 절반 시점에서 easeOutCubic은 0.875다.
      await tester.pump(const Duration(milliseconds: 160));
      const eased = 0.875;

      expect(
        tester.getTopLeft(find.text('B')).dx,
        moreOrLessEquals(_width * 0.24 * (1 - eased), epsilon: 0.5),
      );
      expect(_opacityOf(tester, 'B'), moreOrLessEquals(eased, epsilon: 0.01));
      expect(
        tester.getTopLeft(find.text('A')).dx,
        moreOrLessEquals(-_width * 0.08 * eased, epsilon: 0.5),
      );
    },
  );

  testWidgets('a push over another push moves the lower push page aside', (
    tester,
  ) async {
    // 같은 종류끼리는 delegatedTransition이 아니라 아래 화면 자신의 secondaryAnimation이 움직인다.
    final router = await _pumpRouter(tester);
    router.push('/push');
    await tester.pumpAndSettle();
    router.push('/push2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(
      tester.getTopLeft(find.text('B')).dx,
      moreOrLessEquals(-_width * 0.08 * 0.875, epsilon: 0.5),
    );
    expect(
      tester.getTopLeft(find.text('E')).dx,
      moreOrLessEquals(_width * 0.24 * 0.125, epsilon: 0.5),
    );
  });

  testWidgets('popping a push page reverses it in 320ms', (tester) async {
    final router = await _pumpRouter(tester);
    router.push('/push');
    await tester.pumpAndSettle();

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 161));
    await tester.pump();
    expect(find.text('B'), findsNothing);
    expect(tester.getTopLeft(find.text('A')).dx, 0);
  });

  testWidgets(
    'sheet rises from the bottom over 380ms and scales the page behind to 96%',
    (tester) async {
      final router = await _pumpRouter(tester);
      router.push('/sheet');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 190));
      const eased = 0.875;
      const gap = CoraTransitions.sheetTopGap;

      // 시트는 화면 높이만큼 아래에서 올라온다.
      expect(
        tester.getTopLeft(find.text('C')).dy,
        moreOrLessEquals(gap + _height * (1 - eased), epsilon: 0.5),
      );
      final midScale = 1 - 0.04 * eased;
      expect(
        tester.getTopLeft(find.text('A')),
        offsetMoreOrLessEquals(
          Offset(_width * (1 - midScale) / 2, _height * (1 - midScale) / 2),
          epsilon: 0.5,
        ),
      );

      await tester.pump(const Duration(milliseconds: 191));
      await tester.pump();
      // 시트가 다 올라와도 뒤 화면은 96%로 줄어든 채 보인다.
      expect(find.text('A'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('A')),
        offsetMoreOrLessEquals(
          const Offset(_width * 0.02, _height * 0.02),
          epsilon: 0.01,
        ),
      );
      expect(tester.getTopLeft(find.text('C')).dy, gap);
    },
  );

  testWidgets('sheet closes when the dimmed area above it is tapped', (
    tester,
  ) async {
    final router = await _pumpRouter(tester);
    router.push('/sheet');
    await tester.pumpAndSettle();

    await tester.tapAt(
      const Offset(_width / 2, CoraTransitions.sheetTopGap / 2),
    );
    await tester.pumpAndSettle();
    expect(find.text('C'), findsNothing);
    expect(tester.getTopLeft(find.text('A')), Offset.zero);
  });

  testWidgets(
    'fade transition finishes after 200ms and leaves the page below still',
    (tester) async {
      final router = await _pumpRouter(tester);
      router.push('/push');
      await tester.pumpAndSettle();
      router.push('/fade');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_opacityOf(tester, 'D'), moreOrLessEquals(0.875, epsilon: 0.01));
      expect(tester.getTopLeft(find.text('B')).dx, 0);
      await tester.pump(const Duration(milliseconds: 101));
      await tester.pump();
      expect(find.text('B'), findsNothing);
    },
  );

  testWidgets(
    'push over a sheet slides the sheet aside instead of scaling it',
    (tester) async {
      final router = await _pumpRouter(tester);
      router.push('/sheet');
      await tester.pumpAndSettle();
      router.push('/push');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(
        tester.getTopLeft(find.text('C')).dx,
        moreOrLessEquals(-_width * 0.08 * 0.875, epsilon: 0.5),
      );
    },
  );

  testWidgets(
    'transitions are instant when the platform asks to reduce motion',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final router = await _pumpRouter(tester);

      router.push('/push');
      await tester.pump();
      await tester.pump();
      expect(find.text('A'), findsNothing);
      expect(tester.getTopLeft(find.text('B')).dx, 0);
    },
  );

  group('iOS back swipe', () {
    testWidgets('push pages can be swiped back from the left edge on iOS', (
      tester,
    ) async {
      final router = await _pumpRouter(tester, platform: TargetPlatform.iOS);
      router.push('/push');
      await tester.pumpAndSettle();

      // 천천히 끌어 손을 떼는 위치로만 판단하게 한다.
      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(
        const Offset(20, 0),
        timeStamp: const Duration(milliseconds: 100),
      );
      await tester.pump();
      await gesture.moveBy(
        const Offset(440, 0),
        timeStamp: const Duration(milliseconds: 2000),
      );
      await tester.pump();
      // 손가락이 움직인 거리(20 + 440)만큼 곡선 없이 그대로 따라온다.
      expect(
        tester.getTopLeft(find.text('B')).dx,
        moreOrLessEquals(460, epsilon: 0.5),
      );
      expect(find.text('A'), findsOneWidget);

      await gesture.up(timeStamp: const Duration(milliseconds: 2100));
      await tester.pumpAndSettle();
      expect(find.text('B'), findsNothing);
      expect(tester.getTopLeft(find.text('A')).dx, 0);
      // go_router 스택에서도 빠졌다.
      expect(router.canPop(), isFalse);
    });

    testWidgets('a short slow swipe settles back onto the page', (
      tester,
    ) async {
      final router = await _pumpRouter(tester, platform: TargetPlatform.iOS);
      router.push('/push');
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(5, 300));
      var time = Duration.zero;
      for (var i = 0; i < 10; i++) {
        time += const Duration(milliseconds: 100);
        await gesture.moveBy(const Offset(10, 0), timeStamp: time);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up(timeStamp: time + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
      expect(tester.getTopLeft(find.text('B')).dx, 0);
      expect(router.canPop(), isTrue);
    });

    testWidgets('a quick flick goes back even when the page barely moved', (
      tester,
    ) async {
      final router = await _pumpRouter(tester, platform: TargetPlatform.iOS);
      router.push('/push');
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(5, 300));
      for (var i = 1; i <= 6; i++) {
        await gesture.moveBy(
          const Offset(20, 0),
          timeStamp: Duration(milliseconds: 10 * i),
        );
        await tester.pump();
      }
      await gesture.up(timeStamp: const Duration(milliseconds: 70));
      await tester.pumpAndSettle();
      expect(find.text('B'), findsNothing);
      // go_router 스택에서도 빠졌다.
      expect(router.canPop(), isFalse);
    });

    testWidgets('the edge swipe is not added on Android', (tester) async {
      final router = await _pumpRouter(tester);
      router.push('/push');
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(400, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('sheets cannot be swiped back from the edge', (tester) async {
      final router = await _pumpRouter(tester, platform: TargetPlatform.iOS);
      router.push('/sheet');
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(400, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('C'), findsOneWidget);
    });
  });
}
