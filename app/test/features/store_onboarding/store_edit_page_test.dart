import 'dart:async';
import 'dart:typed_data';

import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_edit_page.dart';
import 'package:cora/features/store_onboarding/presentation/pages/store_page_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import '../../support/load_app_fonts.dart';
import 'fake_store_repository.dart';
import 'store_app_harness.dart';

Finder _input(String name) => find.byKey(ValueKey('storeEdit.$name'));

Future<void> _openEdit(
  WidgetTester tester, {
  FakeStoreRepository? stores,
  FakePhotoPicker? picker,
  FakePhotoUploader? uploader,
}) async {
  await pumpStoreApp(
    tester,
    stores: stores ?? FakeStoreRepository(store: sampleStore()),
    picker: picker,
    uploader: uploader,
  );
  await tester.tap(find.text('정보 고치기'));
  await tester.pumpAndSettle();
}

/// 시트 뒤에는 가게 페이지가 그대로 남아 있어, 고치기 화면 안에서만 찾는다.
Finder _inEdit(Finder finder) =>
    find.descendant(of: find.byType(StoreEditPage), matching: finder);

Finder _text(String text) => _inEdit(find.text(text));

VoidCallback? _saveAction(WidgetTester tester) => tester
    .widget<CoraPrimaryButton>(_inEdit(find.byType(CoraPrimaryButton)))
    .onPressed;

Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      120,
      scrollable: _inEdit(find.byType(Scrollable)).first,
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the field names and the filled values', (tester) async {
    await _openEdit(tester);

    expect(_text('가게 정보 고치기'), findsOneWidget);
    expect(_text('가게 이름'), findsOneWidget);
    expect(_text('업종'), findsOneWidget);
    expect(_text('동네'), findsOneWidget);
    expect(_text('업종 분류'), findsOneWidget);
    expect(_text('지역'), findsOneWidget);
    expect(_text('구·군'), findsOneWidget);
    expect(_text('대표 메뉴'), findsOneWidget);
    expect(_text('영업시간'), findsOneWidget);
    await _scrollTo(tester, _text('소개'));
    expect(_text('좌석'), findsOneWidget);
    expect(_text('찍기 좋은 시간'), findsOneWidget);
    expect(_text('소개'), findsOneWidget);
    expect(_text('사진 바꾸기'), findsOneWidget);
    expect(_text('저장'), findsOneWidget);
    expect(_text('한그릇 라멘'), findsOneWidget);
    expect(_text('맛집·카페'), findsOneWidget);
    expect(_text('서울특별시'), findsOneWidget);
  });

  testWidgets('saves edits and returns to the preview', (tester) async {
    final stores = FakeStoreRepository(store: sampleStore());
    await _openEdit(tester, stores: stores);

    await tester.enterText(_input('name'), '두그릇 라멘');
    await tester.enterText(_input('hours'), '10:00 – 20:00');
    await tester.pump();
    await tester.tap(_text('저장'));
    await tester.pumpAndSettle();

    final edit = stores.edits.single;
    expect(edit.name, '두그릇 라멘');
    expect(edit.hours, '10:00 – 20:00');
    expect(edit.industry, IndustryCategory.foodCafe);
    expect(edit.regionSido, '서울특별시');
    expect(edit.coverPhotoPath, isNull);
    expect(find.byType(StoreEditPage), findsNothing);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
    expect(find.text('두그릇 라멘'), findsOneWidget);
    expect(find.text('10:00 – 20:00'), findsOneWidget);
  });

  testWidgets('the save button is off while the store name is empty', (
    tester,
  ) async {
    await _openEdit(tester);

    await tester.enterText(_input('name'), '   ');
    await tester.pump();

    expect(_saveAction(tester), isNull);

    await tester.enterText(_input('name'), '새 이름');
    await tester.pump();
    expect(_saveAction(tester), isNotNull);
  });

  testWidgets('keeps the input and shows an error when saving fails', (
    tester,
  ) async {
    final stores = FakeStoreRepository(store: sampleStore())..failUpdate = true;
    await _openEdit(tester, stores: stores);

    await tester.enterText(_input('name'), '두그릇 라멘');
    await tester.pump();
    await tester.tap(_text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreEditPage), findsOneWidget);
    expect(_text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(_text('두그릇 라멘'), findsOneWidget);
    expect(_saveAction(tester), isNotNull);
  });

  testWidgets('picks the industry class and the province from sheets', (
    tester,
  ) async {
    final stores = FakeStoreRepository(store: sampleStore(regionSido: null));
    await _openEdit(tester, stores: stores);

    expect(_text('시·도 고르기'), findsOneWidget);
    await tester.tap(_text('맛집·카페'));
    await tester.pumpAndSettle();
    // 13개 분류가 시트에 있다.
    expect(find.text('다이어트 보조제'), findsOneWidget);
    await tester.tap(find.text('뷰티·미용'));
    await tester.pumpAndSettle();

    await tester.tap(_text('시·도 고르기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('부산광역시'));
    await tester.pumpAndSettle();
    await tester.enterText(_input('regionSigungu'), '해운대구');
    await tester.pump();
    await tester.tap(_text('저장'));
    await tester.pumpAndSettle();

    final edit = stores.edits.single;
    expect(edit.industry, IndustryCategory.beauty);
    expect(edit.regionSido, '부산광역시');
    expect(edit.regionSigungu, '해운대구');
  });

  testWidgets('shows all 17 provinces in the sheet', (tester) async {
    await _openEdit(tester);

    await tester.tap(_text('서울특별시'));
    await tester.pumpAndSettle();

    final list = find.byKey(StoreEditPage.sidoListKey);
    expect(list, findsOneWidget);
    await tester.drag(list, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('제주특별자치도'), findsOneWidget);
  });

  testWidgets('goes to the preview after saving a manual entry', (
    tester,
  ) async {
    final stores = FakeStoreRepository()..analysisFails = true;
    await pumpStoreApp(tester, stores: stores);
    await tester.enterText(
      find.byKey(const ValueKey('storeLinks.naverMap')),
      'naver.me/fail',
    );
    await tester.pump();
    await tester.tap(find.text('가게 페이지 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('직접 입력하기'));
    await tester.pumpAndSettle();

    await tester.enterText(_input('name'), '직접 쓴 가게');
    await tester.pump();
    await tester.tap(_text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(StoreEditPage), findsNothing);
    expect(find.byType(StorePagePreviewPage), findsOneWidget);
    expect(topPath(tester), AppRoutes.storeOnboardingPage);
    // 링크 입력 화면이 아래에 쌓여 있어 뒤로 가면 돌아간다.
    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storeOnboardingLinks);
  });

  testWidgets('uploads the picked photo and sends its path on save', (
    tester,
  ) async {
    final stores = FakeStoreRepository(store: sampleStore());
    final picker = FakePhotoPicker(
      next: PickedPhoto(bytes: Uint8List(8), contentType: 'image/png'),
    );
    final uploader = FakePhotoUploader()..path = 'stores/user-1/new.png';
    await _openEdit(tester, stores: stores, picker: picker, uploader: uploader);

    await tester.tap(_text('사진 바꾸기'));
    await tester.pumpAndSettle();
    await tester.tap(_text('저장'));
    await tester.pumpAndSettle();

    expect(uploader.uploadCalls, 1);
    expect(uploader.lastContentType, 'image/png');
    expect(stores.edits.single.coverPhotoPath, 'stores/user-1/new.png');
  });

  testWidgets('says so when the picked photo is over 5MB', (tester) async {
    final picker = FakePhotoPicker(
      next: PickedPhoto(
        bytes: Uint8List(5 * 1024 * 1024 + 1),
        contentType: 'image/jpeg',
      ),
    );
    final uploader = FakePhotoUploader();
    await _openEdit(tester, picker: picker, uploader: uploader);

    await tester.tap(_text('사진 바꾸기'));
    await tester.pumpAndSettle();

    expect(_text('사진이 너무 커요. 5MB 이하로 골라 주세요.'), findsOneWidget);
    expect(uploader.uploadCalls, 0);
  });

  testWidgets('says so when the photo upload fails', (tester) async {
    final picker = FakePhotoPicker(
      next: PickedPhoto(bytes: Uint8List(8), contentType: 'image/jpeg'),
    );
    final uploader = FakePhotoUploader()..fail = true;
    await _openEdit(tester, picker: picker, uploader: uploader);

    await tester.tap(_text('사진 바꾸기'));
    await tester.pumpAndSettle();

    expect(_text('사진을 올리지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('the save button waits while a photo is uploading', (
    tester,
  ) async {
    final picker = FakePhotoPicker(
      next: PickedPhoto(bytes: Uint8List(8), contentType: 'image/jpeg'),
    );
    final uploader = FakePhotoUploader()..hold = Completer<void>();
    await _openEdit(tester, picker: picker, uploader: uploader);

    await tester.tap(_text('사진 바꾸기'));
    await tester.pump();
    await tester.pump();

    expect(_text('사진을 올리는 중이에요'), findsOneWidget);
    expect(_saveAction(tester), isNull);

    uploader.hold!.complete();
    await tester.pumpAndSettle();
    expect(_saveAction(tester), isNotNull);
  });
}
