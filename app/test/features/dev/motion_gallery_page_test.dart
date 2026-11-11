import 'package:cora/app.dart';
import 'package:cora/core/ui/cora_error_view.dart';
import 'package:cora/core/ui/cora_glass_card.dart';
import 'package:cora/core/ui/cora_logo.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/core/ui/cora_select_card.dart';
import 'package:cora/features/dev/presentation/pages/motion_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// iPhone 15 Pro 크기(390 x 844)로 띄운다.
void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
  testWidgets('CoraApp shows the motion gallery until the router arrives', (
    tester,
  ) async {
    _usePhone(tester);
    await tester.pumpWidget(const CoraApp());
    expect(find.byType(MotionGalleryPage), findsOneWidget);
  });

  testWidgets('motion gallery shows a sample of every shared widget', (
    tester,
  ) async {
    _usePhone(tester);
    await tester.pumpWidget(const MotionGalleryPage());

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
    await tester.pumpWidget(const MotionGalleryPage());

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
    await tester.pumpWidget(const MotionGalleryPage());

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
    await tester.pumpWidget(const MotionGalleryPage());

    await _open(tester, '공유 요소 전환');
    expect(find.text('크리에이터 42'), findsOneWidget);
    expect(find.byType(Hero), findsOneWidget);
    await _close(tester);
    expect(find.text('모션 갤러리'), findsOneWidget);
  });

  testWidgets('the gallery switch overrides light and dark', (tester) async {
    _usePhone(tester);
    await tester.pumpWidget(const MotionGalleryPage());
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

    await tester.pumpWidget(const MotionGalleryPage());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
