import 'package:cora/core/navigation/cora_transitions.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_error_view.dart';
import 'package:cora/core/ui/cora_glass_card.dart';
import 'package:cora/core/ui/cora_logo.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/core/ui/cora_select_card.dart';
import 'package:cora/features/dev/presentation/pages/motion_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// iPhone 15 Pro 크기(390 x 844)로 띄운다.
void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// 갤러리는 앱 라우터의 한 화면(/dev/motion)이라 바깥 MaterialApp 안에서만 뜬다.
/// 앱 라우터와 함께 띄우는 확인은 test/core/navigation/app_router_test.dart에 있다.
Future<void> _pumpGallery(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    theme: coraLightTheme,
    darkTheme: coraDarkTheme,
    home: const MotionGalleryPage(),
  ),
);

/// 앱과 같은 구성: 바깥 라우터의 push 화면(가장자리 밀기 있음) 안에 갤러리가 있다.
/// 테마의 플랫폼을 직접 정한다. 앱 테마(coraLightTheme)는 처음 쓰일 때의 플랫폼을 담아 두므로
/// 테스트 순서에 따라 iOS가 아닐 수 있다.
Future<void> _pumpGalleryOverBasePage(
  WidgetTester tester, {
  required TargetPlatform platform,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/dev/motion'),
              child: const Text('바탕 화면'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/dev/motion',
        pageBuilder: (context, state) =>
            CoraTransitions.push(const MotionGalleryPage(), key: state.pageKey),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: coraLightTheme.copyWith(platform: platform),
      routerConfig: router,
    ),
  );
  await tester.tap(find.text('바탕 화면'));
  await tester.pumpAndSettle();
  expect(find.byType(MotionGalleryPage), findsOneWidget);
}

Future<void> _swipeBackFromLeftEdge(WidgetTester tester) async {
  await tester.dragFrom(const Offset(4, 400), const Offset(300, 0));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String label) async {
  final row = find.text(label);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  final close = find.text('닫기');
  await tester.ensureVisible(close);
  await tester.pumpAndSettle();
  await tester.tap(close);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('motion gallery shows a sample of every shared widget', (
    tester,
  ) async {
    _usePhone(tester);
    await _pumpGallery(tester);

    expect(find.text('모션 갤러리'), findsOneWidget);
    expect(find.byType(CoraLogo), findsWidgets);
    expect(find.byType(CoraSelectCard), findsNWidgets(3));
    expect(find.byType(CoraPrimaryButton), findsAtLeastNWidgets(2));
    expect(find.byType(CoraGlassCard), findsOneWidget);
    expect(find.byType(CoraErrorView), findsOneWidget);
    // A1 문구 그대로
    expect(find.text('가게를 알리고 싶어요'), findsOneWidget);
    expect(find.text('가게 링크로 시작하기'), findsOneWidget);
  });

  testWidgets('select cards in the gallery change the A1 button label', (
    tester,
  ) async {
    _usePhone(tester);
    await _pumpGallery(tester);

    final creator = find.text('콘텐츠를 만들고 싶어요');
    await tester.ensureVisible(creator);
    await tester.pumpAndSettle();
    await tester.tap(creator);
    await tester.pumpAndSettle();
    expect(find.text('내 협업 원칙 정하기'), findsOneWidget);
  });

  testWidgets('motion gallery opens each transition demo and comes back', (
    tester,
  ) async {
    _usePhone(tester);
    await _pumpGallery(tester);

    for (final demo in ['push 전환', 'sheet 전환', 'fade 전환']) {
      await _open(tester, demo);
      expect(find.text('닫기'), findsOneWidget, reason: demo);
      await _close(tester);
      expect(find.text('닫기'), findsNothing, reason: demo);
      expect(find.text('모션 갤러리'), findsOneWidget, reason: demo);
    }
  });

  testWidgets('the hero demo carries the photo into the detail page', (
    tester,
  ) async {
    _usePhone(tester);
    await _pumpGallery(tester);

    await _open(tester, '공유 요소 전환');
    expect(find.text('크리에이터 42'), findsOneWidget);
    expect(find.byType(Hero), findsOneWidget);
    await _close(tester);
    expect(find.text('모션 갤러리'), findsOneWidget);
  });

  testWidgets('the hero photo flies between pages inside the gallery', (
    tester,
  ) async {
    _usePhone(tester);
    await _pumpGallery(tester);
    final card = find.text('공유 요소 전환');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 날아가는 동안 사진은 오버레이의 비행 사본만 보이고, 양쪽 Hero 자리는 비어 있거나 숨겨진다.
    // 비행이 없으면(갤러리 안쪽 Navigator에 HeroController가 없으면) 밑 화면 카드의 사진이 그대로 보인다.
    expect(
      find.descendant(
        of: find.byType(Hero),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('the gallery switch overrides light and dark', (tester) async {
    _usePhone(tester);
    await _pumpGallery(tester);
    Brightness brightness() =>
        Theme.of(tester.element(find.text('모션 갤러리'))).brightness;

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    await tester.tap(find.text('라이트'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
  });

  testWidgets('the gallery lays out at 1.3x text on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpGallery(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'iOS edge swipe closes a gallery demo before leaving the gallery',
    (tester) async {
      _usePhone(tester);
      await _pumpGalleryOverBasePage(tester, platform: TargetPlatform.iOS);
      await _open(tester, 'push 전환');
      expect(find.text('닫기'), findsOneWidget);

      await _swipeBackFromLeftEdge(tester);

      // 시연 화면만 닫히고 갤러리는 남는다.
      expect(find.text('닫기'), findsNothing);
      expect(find.byType(MotionGalleryPage), findsOneWidget);

      await _swipeBackFromLeftEdge(tester);

      // 갤러리 첫 화면에서는 갤러리 자체가 닫힌다.
      expect(find.byType(MotionGalleryPage), findsNothing);
      expect(find.text('바탕 화면'), findsOneWidget);
    },
  );

  testWidgets('the light and dark switch keeps the platform of the app', (
    tester,
  ) async {
    _usePhone(tester);
    await _pumpGalleryOverBasePage(tester, platform: TargetPlatform.iOS);

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.text('모션 갤러리')));
    expect(theme.brightness, Brightness.dark);
    expect(theme.platform, TargetPlatform.iOS);
  });

  testWidgets('the gallery shows the plan 2 widget samples', (tester) async {
    _usePhone(tester);
    await _pumpGallery(tester);

    for (final text in [
      '지원한 크리에이터 5',
      '오퍼 보내기',
      '아직 없어요',
      '정보 고치기',
      '다시 만들기',
      'AI 글',
    ]) {
      expect(find.text(text, skipOffstage: false), findsWidgets, reason: text);
    }
  });
}
