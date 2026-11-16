import 'dart:typed_data';

import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/brand_onboarding/domain/brand_repository.dart';
import 'package:cora/features/brand_onboarding/domain/campaign_repository.dart';
import 'package:cora/features/brand_onboarding/presentation/pages/brand_profile_setup_page.dart';
import 'package:cora/features/brand_onboarding/presentation/pages/campaign_form_page.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../onboarding/fake_me_repository.dart';
import 'fake_brand_repository.dart';
import 'fake_campaign_repository.dart';

Future<FakeBrandRepository> _pump(
  WidgetTester tester, {
  FakeBrandRepository? brand,
  FakePhotoPicker? picker,
  FakePhotoUploader? uploader,
}) async {
  usePhone(tester);
  final repo = brand ?? FakeBrandRepository();
  await pumpCoraApp(
    tester,
    auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    me: FakeMeRepository(role: UserRole.brand),
    overrides: <Override>[
      brandRepositoryProvider.overrideWithValue(repo),
      campaignRepositoryProvider.overrideWithValue(FakeCampaignRepository()),
      photoPickerProvider.overrideWithValue(picker ?? FakePhotoPicker()),
      photoUploaderProvider.overrideWithValue(uploader ?? FakePhotoUploader()),
    ],
  );
  return repo;
}

CoraPrimaryButton _next(WidgetTester tester) => tester
    .widget<CoraPrimaryButton>(find.widgetWithText(CoraPrimaryButton, '다음'));

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(BrandProfileSetupPage.nameFieldKey),
    '느린 결',
  );
  await tester.enterText(
    find.byKey(BrandProfileSetupPage.taglineFieldKey),
    '일상의 주얼리',
  );
  await tester.tap(find.text('업종'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('액세서리·주얼리'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a brand without a profile starts at the profile screen', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(BrandProfileSetupPage), findsOneWidget);
    expect(find.text('어떤 브랜드인가요?'), findsOneWidget);
    expect(find.text('브랜드 이름'), findsOneWidget);
    expect(find.text('한 줄 소개 (선택)'), findsOneWidget);
    expect(find.text('예: 느린 결, 일상의 주얼리'), findsOneWidget);
    expect(find.text('대표 사진 (선택)'), findsOneWidget);
  });

  testWidgets('the next button needs a name and an industry', (tester) async {
    await _pump(tester);
    expect(_next(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(BrandProfileSetupPage.nameFieldKey),
      '느린 결',
    );
    await tester.pump();
    expect(_next(tester).onPressed, isNull);

    await tester.tap(find.text('업종'));
    await tester.pumpAndSettle();
    // 업종은 열세 개 모두 고를 수 있다.
    expect(
      find.descendant(
        of: find.byKey(BrandProfileSetupPage.industryListKey),
        matching: find.byType(Text),
      ),
      findsNWidgets(IndustryCategory.values.length),
    );
    await tester.tap(find.text('주류'));
    await tester.pumpAndSettle();

    expect(_next(tester).onPressed, isNotNull);
    expect(find.text('주류'), findsOneWidget);
  });

  testWidgets('saves the profile and goes on to the campaign screen', (
    tester,
  ) async {
    final repo = await _pump(tester);
    await _fill(tester);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(repo.saved!.name, '느린 결');
    expect(repo.saved!.tagline, '일상의 주얼리');
    expect(repo.saved!.industry, IndustryCategory.accessory);
    // 사진을 고르지 않았으면 경로를 보내지 않고, 저장소가 현재 사진을 지킨다.
    expect(repo.saved!.photoPath, isNull);
    expect(find.byType(CampaignFormPage), findsOneWidget);
  });

  testWidgets('uploads the picked photo and sends its path', (tester) async {
    final picker = FakePhotoPicker(
      next: PickedPhoto(bytes: Uint8List(8), contentType: 'image/jpeg'),
    );
    final uploader = FakePhotoUploader()..path = 'brands/user-1/p.jpg';
    final repo = await _pump(tester, picker: picker, uploader: uploader);
    await _fill(tester);

    await tester.tap(find.text('대표 사진 (선택)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(uploader.lastPurpose, PhotoPurpose.brandPhoto);
    expect(repo.saved!.photoPath, 'brands/user-1/p.jpg');
  });

  testWidgets('says so and stays when saving fails or the photo is too large', (
    tester,
  ) async {
    final big = FakePhotoPicker(
      next: PickedPhoto(
        bytes: Uint8List(maxPhotoBytes + 1),
        contentType: 'image/jpeg',
      ),
    );
    final repo = await _pump(
      tester,
      picker: big,
      brand: FakeBrandRepository()..failSave = true,
    );
    await _fill(tester);

    await tester.tap(find.text('대표 사진 (선택)'));
    await tester.pumpAndSettle();
    expect(find.text('사진이 너무 커요. 5MB 이하로 골라 주세요.'), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.byType(BrandProfileSetupPage), findsOneWidget);
    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(repo.saveCalls, 1);
  });
}
