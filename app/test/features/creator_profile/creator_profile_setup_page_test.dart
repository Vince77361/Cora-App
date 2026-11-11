import 'dart:convert';
import 'dart:typed_data';

import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/creator_profile/domain/creator_profile.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';
import 'package:cora/features/creator_profile/presentation/pages/creator_profile_setup_page.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/store_browse/domain/store_browse_repository.dart';
import 'package:cora/features/store_browse/presentation/pages/store_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../onboarding/fake_me_repository.dart';
import '../store_browse/fake_store_browse_repository.dart';
import 'fake_creator_profile_repository.dart';

/// 1 x 1 PNG. 사진 미리보기가 실제로 그려 볼 수 있는 가장 작은 그림.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Future<void> _pump(
  WidgetTester tester, {
  FakeCreatorProfileRepository? repo,
  FakePhotoPicker? picker,
  FakePhotoUploader? uploader,
}) async {
  usePhone(tester);
  await pumpCoraApp(
    tester,
    auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    me: FakeMeRepository(role: UserRole.creator),
    overrides: [
      creatorProfileRepositoryProvider.overrideWithValue(
        repo ?? FakeCreatorProfileRepository(),
      ),
      storeBrowseRepositoryProvider.overrideWithValue(
        FakeStoreBrowseRepository(),
      ),
      photoPickerProvider.overrideWithValue(picker ?? FakePhotoPicker()),
      photoUploaderProvider.overrideWithValue(uploader ?? FakePhotoUploader()),
    ],
  );
}

CoraPrimaryButton _start(WidgetTester tester) =>
    tester.widget<CoraPrimaryButton>(find.byType(CoraPrimaryButton));

Future<void> _typeName(WidgetTester tester, String name) async {
  await tester.enterText(
    find.byKey(CreatorProfileSetupPage.nameFieldKey),
    name,
  );
  await tester.pump();
}

Future<void> _chooseProvince(WidgetTester tester, String sido) async {
  await tester.tap(find.byKey(CreatorProfileSetupPage.regionTileKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(sido));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the canvas copy', (tester) async {
    await _pump(tester);

    expect(currentPath(tester), AppRoutes.creatorProfileSetup);
    expect(find.text('어떤 이름으로\n활동하나요?'), findsOneWidget);
    expect(find.text('가게 사장님에게 이 이름으로 보여요.'), findsOneWidget);
    expect(find.text('활동 이름'), findsOneWidget);
    expect(find.text('활동 지역'), findsOneWidget);
    expect(find.text('구·군 (선택)'), findsOneWidget);
    expect(find.text('주로 만드는 콘텐츠 (선택)'), findsOneWidget);
    expect(find.text('예: 맛집 릴스'), findsOneWidget);
    expect(find.text('인스타그램 아이디 (선택)'), findsOneWidget);
    expect(find.text('사진 고르기 (선택)'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('the text fields draw no border of their own', (tester) async {
    await _pump(tester);

    // 앱 테마의 입력칸 테두리가 칸 안에 한 겹 더 그려지지 않아야 한다(바깥 상자가 칸 모양이다).
    for (final key in [
      CreatorProfileSetupPage.nameFieldKey,
      CreatorProfileSetupPage.sigunguFieldKey,
      CreatorProfileSetupPage.focusFieldKey,
      CreatorProfileSetupPage.instagramFieldKey,
    ]) {
      final decoration = tester.widget<TextField>(find.byKey(key)).decoration!;
      expect(decoration.border, InputBorder.none);
      expect(decoration.enabledBorder, InputBorder.none);
      expect(decoration.focusedBorder, InputBorder.none);
    }
  });

  testWidgets('start button is disabled until a display name is typed', (
    tester,
  ) async {
    await _pump(tester);
    await _chooseProvince(tester, '서울특별시');
    expect(_start(tester).onPressed, isNull);

    await _typeName(tester, '서윤');
    expect(_start(tester).onPressed, isNotNull);

    await _typeName(tester, '   ');
    expect(_start(tester).onPressed, isNull);
  });

  testWidgets('start button stays disabled until a province is chosen', (
    tester,
  ) async {
    await _pump(tester);
    await _typeName(tester, '서윤');
    expect(_start(tester).onPressed, isNull);

    await _chooseProvince(tester, '경기도');

    expect(find.text('경기도'), findsOneWidget);
    expect(_start(tester).onPressed, isNotNull);
  });

  testWidgets('the province sheet lists all 17 provinces', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(CreatorProfileSetupPage.regionTileKey));
    await tester.pumpAndSettle();

    expect(find.text('서울특별시'), findsOneWidget);
    // 목록은 스크롤되므로 마지막 항목까지 내려서 있는지 본다.
    await tester.scrollUntilVisible(
      find.text('제주특별자치도'),
      200,
      scrollable: find.descendant(
        of: find.byKey(CreatorProfileSetupPage.sidoListKey),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('제주특별자치도'), findsOneWidget);
  });

  testWidgets('saves and goes to the creator home', (tester) async {
    final repo = FakeCreatorProfileRepository();
    await _pump(tester, repo: repo);
    await _typeName(tester, '서윤');
    await _chooseProvince(tester, '서울특별시');
    await tester.enterText(
      find.byKey(CreatorProfileSetupPage.sigunguFieldKey),
      '마포구',
    );
    await tester.enterText(
      find.byKey(CreatorProfileSetupPage.focusFieldKey),
      '맛집 릴스',
    );
    await tester.enterText(
      find.byKey(CreatorProfileSetupPage.instagramFieldKey),
      'seoyun.reels',
    );
    await tester.pump();

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(repo.saveCalls, 1);
    expect(repo.savedDisplayName, '서윤');
    expect(repo.savedRegionSido, '서울특별시');
    expect(repo.savedRegionSigungu, '마포구');
    expect(repo.savedContentFocus, '맛집 릴스');
    expect(repo.savedInstagramHandle, 'seoyun.reels');
    expect(currentPath(tester), AppRoutes.creator);
    expect(find.byType(StoreListPage), findsOneWidget);
  });

  testWidgets('shows an error and keeps the input when saving fails', (
    tester,
  ) async {
    final repo = FakeCreatorProfileRepository()..failSave = true;
    await _pump(tester, repo: repo);
    await _typeName(tester, '서윤');
    await _chooseProvince(tester, '서울특별시');

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(currentPath(tester), AppRoutes.creatorProfileSetup);
    expect(find.text('서윤'), findsOneWidget);
    expect(find.text('서울특별시'), findsOneWidget);
    expect(_start(tester).onPressed, isNotNull);

    // 다시 누르면 다시 저장한다.
    repo.failSave = false;
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), AppRoutes.creator);
  });

  testWidgets('skips setup when a profile already exists', (tester) async {
    final repo = FakeCreatorProfileRepository(
      profile: const CreatorProfile(displayName: '서윤', regionSido: '서울특별시'),
    );
    await _pump(tester, repo: repo);

    expect(currentPath(tester), AppRoutes.creator);
    expect(find.byType(CreatorProfileSetupPage), findsNothing);
  });

  testWidgets('shows the size message and keeps no photo over 5MB', (
    tester,
  ) async {
    final picker = FakePhotoPicker(
      next: PickedPhoto(
        bytes: Uint8List(maxPhotoBytes + 1),
        contentType: 'image/jpeg',
      ),
    );
    await _pump(tester, picker: picker);

    await tester.tap(find.text('사진 고르기 (선택)'));
    await tester.pumpAndSettle();

    expect(find.text('사진이 너무 커요. 5MB 이하로 골라 주세요.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a picked photo is shown in the circle and uploaded on save', (
    tester,
  ) async {
    final repo = FakeCreatorProfileRepository();
    final uploader = FakePhotoUploader()..path = 'creators/user-1/a.png';
    final picker = FakePhotoPicker(
      next: PickedPhoto(bytes: _png, contentType: 'image/png'),
    );
    await _pump(tester, repo: repo, picker: picker, uploader: uploader);
    await _typeName(tester, '서윤');
    await _chooseProvince(tester, '서울특별시');

    await tester.tap(find.text('사진 고르기 (선택)'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    // 사진을 고른 뒤에는 `사진 바꾸기`로 바뀐다.
    expect(find.text('사진 바꾸기'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(uploader.uploadCalls, 1);
    expect(repo.savedPhotoPath, 'creators/user-1/a.png');
  });

  testWidgets('the back button goes to the role screen when nothing is below', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('fits a small phone with large text and the keyboard room', (
    tester,
  ) async {
    useSmallPhoneWithLargeText(tester);
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      me: FakeMeRepository(role: UserRole.creator),
      overrides: [
        creatorProfileRepositoryProvider.overrideWithValue(
          FakeCreatorProfileRepository(),
        ),
        photoPickerProvider.overrideWithValue(FakePhotoPicker()),
        photoUploaderProvider.overrideWithValue(FakePhotoUploader()),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('시작하기'), findsOneWidget);
  });
}
