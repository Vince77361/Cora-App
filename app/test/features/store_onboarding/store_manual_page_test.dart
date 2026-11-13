import 'dart:typed_data';

import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/store_onboarding/domain/source_link.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_manual_page.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_page_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import '../../support/load_app_fonts.dart';
import 'fake_store_repository.dart';
import 'store_app_harness.dart';

Finder _name() => find.byKey(const ValueKey('storeManual.name'));
Finder _menu() => find.byKey(const ValueKey('storeManual.signatureMenu'));

VoidCallback? _createAction(WidgetTester tester) =>
    tester.widget<CoraPrimaryButton>(find.byType(CoraPrimaryButton)).onPressed;

/// A2의 아래 링크로 F7을 연다.
Future<void> _openManual(
  WidgetTester tester, {
  FakeStoreRepository? stores,
  FakePhotoPicker? picker,
  FakePhotoUploader? uploader,
}) async {
  await pumpStoreApp(
    tester,
    stores: stores ?? FakeStoreRepository(),
    picker: picker,
    uploader: uploader,
  );
  await tester.tapOnText(find.textRange.ofSubstring('링크가 없거나 안 열리면 직접 입력'));
  await tester.pumpAndSettle();
}

/// 이름을 넣고 찾기 기다림(0.5초)이 지나게 한다.
Future<void> _typeName(WidgetTester tester, String name) async {
  await tester.enterText(_name(), name);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('A2 opens manual input without the notice from the bottom link', (
    tester,
  ) async {
    await _openManual(tester);

    expect(topPath(tester), AppRoutes.storeOnboardingManual);
    expect(find.byType(StoreManualPage), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('가게 이름'), findsOneWidget);
    expect(find.text('대표 메뉴와 가격'), findsOneWidget);
    expect(find.text('가게 사진 올리기 (사용 권한이 있는 사진만)'), findsOneWidget);
    expect(find.text('링크에서 정보를 가져오지 못했어요. 아래만 채우면 계속할 수 있어요.'), findsNothing);
  });

  testWidgets('A2 sends a failed analysis to manual input with the notice', (
    tester,
  ) async {
    final stores = FakeStoreRepository()..analysisFails = true;
    await pumpStoreApp(tester, stores: stores);
    await tester.enterText(
      find.byKey(ValueKey('storeLinks.${SourceLinkKind.naverMap.name}')),
      'naver.me/fail',
    );
    await tester.pump();
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeOnboardingManual);
    expect(find.text('링크에서 정보를 가져오지 못했어요. 아래만 채우면 계속할 수 있어요.'), findsOneWidget);
  });

  testWidgets('F7 lists two branches for the sample name and picks one', (
    tester,
  ) async {
    final stores = FakeStoreRepository();
    await _openManual(tester, stores: stores);
    expect(find.textContaining('같은 이름의 가게가'), findsNothing);

    await _typeName(tester, '한그릇 라멘');

    expect(find.text('지점 · 같은 이름의 가게가 2곳 있어요'), findsOneWidget);
    expect(find.text('성수점'), findsOneWidget);
    expect(find.text('성수동2가'), findsOneWidget);
    expect(find.text('합정점'), findsOneWidget);
    expect(find.text('합정동'), findsOneWidget);

    await tester.tap(find.text('합정점'));
    await tester.pump();
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    final sent = stores.manuals.single;
    expect(sent.name, '한그릇 라멘');
    expect(sent.branch?.label, '합정점');
    expect(sent.branch?.regionSigungu, '마포구');
    expect(topPath(tester), AppRoutes.storeOnboardingPage);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
    // F7 자리를 A3이 이어받아 뒤로 가면 A2다.
    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storeOnboardingLinks);
  });

  testWidgets('F7 selects the first branch by default', (tester) async {
    final stores = FakeStoreRepository();
    await _openManual(tester, stores: stores);
    await _typeName(tester, '한그릇 라멘');

    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    expect(stores.manuals.single.branch?.label, '성수점');
  });

  testWidgets('F7 hides the branch row when at most one branch is found', (
    tester,
  ) async {
    final stores = FakeStoreRepository()
      ..branchesByName['외딴 가게'] = [sampleBranches.first];
    await _openManual(tester, stores: stores);

    await _typeName(tester, '외딴 가게');
    expect(stores.branchLookups, ['외딴 가게']);
    expect(find.textContaining('같은 이름의 가게가'), findsNothing);

    await _typeName(tester, '이름이 없는 가게');
    expect(find.textContaining('같은 이름의 가게가'), findsNothing);

    // 보이지 않는 지점은 보내지 않는다.
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();
    expect(stores.manuals.single.branch, isNull);
  });

  testWidgets('F7 looks up branches only after typing stops for 0.5 second', (
    tester,
  ) async {
    final stores = FakeStoreRepository();
    await _openManual(tester, stores: stores);

    await tester.enterText(_name(), '한그');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(_name(), '한그릇 라멘');
    await tester.pump(const Duration(milliseconds: 300));
    expect(stores.branchLookups, isEmpty);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(stores.branchLookups, ['한그릇 라멘']);
  });

  testWidgets('F7 keeps going when the branch lookup fails', (tester) async {
    final stores = FakeStoreRepository()..failBranches = true;
    await _openManual(tester, stores: stores);

    await _typeName(tester, '한그릇 라멘');

    expect(find.textContaining('같은 이름의 가게가'), findsNothing);
    expect(_createAction(tester), isNotNull);
  });

  testWidgets('F7 needs only the store name', (tester) async {
    final stores = FakeStoreRepository();
    await _openManual(tester, stores: stores);
    expect(_createAction(tester), isNull);

    await tester.enterText(_name(), '   ');
    await tester.pump();
    expect(_createAction(tester), isNull);

    await tester.enterText(_name(), '직접 쓴 가게');
    await tester.pump();
    expect(_createAction(tester), isNotNull);

    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    final sent = stores.manuals.single;
    expect(sent.name, '직접 쓴 가게');
    expect(sent.signatureMenu, isNull);
    expect(sent.coverPhotoPath, isNull);
    expect(sent.branch, isNull);
  });

  testWidgets('F7 sends the menu and the uploaded photo path', (tester) async {
    final stores = FakeStoreRepository();
    final picker = FakePhotoPicker(
      next: PickedPhoto(bytes: Uint8List(8), contentType: 'image/png'),
    );
    final uploader = FakePhotoUploader()..path = 'stores/user-1/cover.png';
    await _openManual(
      tester,
      stores: stores,
      picker: picker,
      uploader: uploader,
    );
    await tester.enterText(_name(), '직접 쓴 가게');
    await tester.enterText(_menu(), '돈코츠 라멘 11,000원');

    await tester.tap(find.text('가게 사진 올리기 (사용 권한이 있는 사진만)'));
    await tester.pumpAndSettle();
    expect(uploader.uploadCalls, 1);
    expect(find.text('가게 사진 올리기 (사용 권한이 있는 사진만)'), findsNothing);

    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    final sent = stores.manuals.single;
    expect(sent.signatureMenu, '돈코츠 라멘 11,000원');
    expect(sent.coverPhotoPath, 'stores/user-1/cover.png');
  });

  testWidgets('F7 says so when the photo is over 5MB', (tester) async {
    final picker = FakePhotoPicker(
      next: PickedPhoto(
        bytes: Uint8List(5 * 1024 * 1024 + 1),
        contentType: 'image/jpeg',
      ),
    );
    await _openManual(tester, picker: picker);

    await tester.tap(find.text('가게 사진 올리기 (사용 권한이 있는 사진만)'));
    await tester.pumpAndSettle();

    expect(find.text('사진이 너무 커요. 5MB 이하로 골라 주세요.'), findsOneWidget);
    expect(find.text('가게 사진 올리기 (사용 권한이 있는 사진만)'), findsOneWidget);
  });

  testWidgets('F7 stays and says so when creating the store fails', (
    tester,
  ) async {
    final stores = FakeStoreRepository()..failManual = true;
    await _openManual(tester, stores: stores);
    await tester.enterText(_name(), '직접 쓴 가게');
    await tester.pump();

    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreManualPage), findsOneWidget);
    expect(find.text('가게를 만들지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('직접 쓴 가게'), findsOneWidget);
    expect(_createAction(tester), isNotNull);
  });

  testWidgets('F7 uses the canvas colors in light and dark', (tester) async {
    final stores = FakeStoreRepository();
    await _openManual(tester, stores: stores);
    await _typeName(tester, '한그릇 라멘');

    Color? selectedBg() {
      final box = find
          .ancestor(of: find.text('성수점'), matching: find.byType(DecoratedBox))
          .first;
      return (tester.widget<DecoratedBox>(box).decoration as BoxDecoration)
          .color;
    }

    expect(selectedBg(), CoraColors.light.quietSelected);
    expect(CoraColors.light.quietSelected, const Color(0xFFFFFFFF));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();

    expect(selectedBg(), CoraColors.dark.quietSelected);
    expect(CoraColors.dark.quietSelected, const Color(0xFF2A2D33));
  });

  testWidgets('F7 does not overflow at 1.3x text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final stores = FakeStoreRepository();
    await _openManual(tester, stores: stores);
    await _typeName(tester, '한그릇 라멘');

    expect(tester.takeException(), isNull);
  });
}
