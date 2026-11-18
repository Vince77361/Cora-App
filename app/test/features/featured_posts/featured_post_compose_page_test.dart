import 'dart:convert';
import 'dart:typed_data';

import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/featured_posts/domain/featured_posts_repository.dart';
import 'package:cora/features/featured_posts/presentation/pages/featured_post_compose_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_browse/creator_app_harness.dart';
import 'fake_featured_posts_repository.dart';

/// 1 x 1 PNG. 미리보기가 실제로 그려 볼 수 있는 가장 작은 그림.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// 대표 게시물 화면에서 `사진첩에서 올리기`를 눌러 한 줄 설명 화면까지 간다.
Future<void> _openCompose(
  WidgetTester tester,
  FakeFeaturedPostsRepository repo, {
  required FakePhotoPicker picker,
  required FakePhotoUploader uploader,
  bool largeText = false,
}) async {
  await pumpCreatorApp(
    tester,
    smallPhoneLargeText: largeText,
    overrides: [
      featuredPostsRepositoryProvider.overrideWithValue(repo),
      photoPickerProvider.overrideWithValue(picker),
      photoUploaderProvider.overrideWithValue(uploader),
    ],
  );
  routerOf(tester).push(AppRoutes.creatorFeaturedPosts);
  await tester.pumpAndSettle();
  await tester.tap(find.text('사진첩에서 올리기'));
  await tester.pumpAndSettle();
}

FakePhotoPicker _picker() => FakePhotoPicker(
  next: PickedPhoto(bytes: _png, contentType: 'image/png'),
);

CoraPrimaryButton _add(WidgetTester tester) => tester.widget(
  find.ancestor(
    of: find.text('대표 게시물에 추가'),
    matching: find.byType(CoraPrimaryButton),
  ),
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(
    find.byKey(FeaturedPostComposePage.captionFieldKey),
    text,
  );
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('asks the picker for a photo shrunk to 2048 at quality 85', (
    tester,
  ) async {
    final picker = _picker();
    await _openCompose(
      tester,
      FakeFeaturedPostsRepository(),
      picker: picker,
      uploader: FakePhotoUploader(),
    );

    expect(picker.pickCalls, 1);
    expect(picker.lastMaxSide, 2048);
    expect(picker.lastQuality, 85);
    expect(topPath(tester), AppRoutes.creatorFeaturedPostsCompose);
    expect(find.text('새 콘텐츠'), findsOneWidget);
    expect(find.text('한 줄 설명'), findsOneWidget);
    // 분야 꼬리표 줄과 "좋아요를 많이 받은…" 안내는 뺐다.
    expect(find.textContaining('좋아요를 많이 받은'), findsNothing);
    expect(find.textContaining('#'), findsNothing);
  });

  testWidgets('stays on the list when the picker is closed without a choice', (
    tester,
  ) async {
    await _openCompose(
      tester,
      FakeFeaturedPostsRepository(),
      picker: FakePhotoPicker(),
      uploader: FakePhotoUploader(),
    );

    expect(topPath(tester), AppRoutes.creatorFeaturedPosts);
  });

  testWidgets('requires a one-line caption of up to 40 characters', (
    tester,
  ) async {
    await _openCompose(
      tester,
      FakeFeaturedPostsRepository(),
      picker: _picker(),
      uploader: FakePhotoUploader(),
    );
    expect(_add(tester).onPressed, isNull);

    await _type(tester, '   ');
    expect(_add(tester).onPressed, isNull);

    await _type(tester, '출근 전 30초, 오늘의 손목 루틴');
    expect(_add(tester).onPressed, isNotNull);

    // 41번째 글자부터는 들어가지 않는다.
    await _type(tester, '가' * 50);
    final field = tester.widget<TextField>(
      find.byKey(FeaturedPostComposePage.captionFieldKey),
    );
    expect(field.controller!.text.length, 40);
  });

  testWidgets('uploads the resized photo with the featuredPost purpose', (
    tester,
  ) async {
    final repo = FakeFeaturedPostsRepository();
    final uploader = FakePhotoUploader()..path = 'featured-posts/user-1/p.png';
    await _openCompose(tester, repo, picker: _picker(), uploader: uploader);
    await _type(tester, '  출근 전 30초  ');

    await tester.tap(find.text('대표 게시물에 추가'));
    await tester.pumpAndSettle();

    expect(uploader.uploadCalls, 1);
    expect(uploader.lastPurpose, PhotoPurpose.featuredPost);
    expect(uploader.lastContentType, 'image/png');
    expect(uploader.lastBytes, _png);
    // 목록에는 사진첩 표지의 임시 게시물이 붙고 서버에는 아직 저장하지 않았다.
    expect(topPath(tester), AppRoutes.creatorFeaturedPosts);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('출근 전 30초'), findsOneWidget);
    expect(find.text('사진첩'), findsOneWidget);
    expect(repo.saved, isEmpty);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    final sent = repo.saved.single.single;
    expect(sent.mediaPath, 'featured-posts/user-1/p.png');
    expect(sent.caption, '출근 전 30초');
    expect(sent.thumbnailPath, isNull);
    expect(sent.instagramMediaId, isNull);
  });

  testWidgets('shows a message and keeps the caption when the upload fails', (
    tester,
  ) async {
    final uploader = FakePhotoUploader()..fail = true;
    await _openCompose(
      tester,
      FakeFeaturedPostsRepository(),
      picker: _picker(),
      uploader: uploader,
    );
    await _type(tester, '한 줄');

    await tester.tap(find.text('대표 게시물에 추가'));
    await tester.pumpAndSettle();

    expect(find.text('사진을 올리지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(topPath(tester), AppRoutes.creatorFeaturedPostsCompose);
    expect(_add(tester).onPressed, isNotNull);
  });

  testWidgets('tells a photo over 5MB is too large', (tester) async {
    final big = FakePhotoPicker(
      next: PickedPhoto(
        bytes: Uint8List(maxPhotoBytes + 1),
        contentType: 'image/jpeg',
      ),
    );
    await _openCompose(
      tester,
      FakeFeaturedPostsRepository(),
      picker: big,
      uploader: FakePhotoUploader(),
    );
    await _type(tester, '한 줄');

    await tester.tap(find.text('대표 게시물에 추가'));
    await tester.pumpAndSettle();

    expect(find.text('사진이 너무 커요. 5MB 이하로 골라 주세요.'), findsOneWidget);
  });

  testWidgets('replaces a post from the sheet with a gallery photo', (
    tester,
  ) async {
    final repo = FakeFeaturedPostsRepository(
      posts: [savedPost(1), savedPost(2)],
    );
    await pumpCreatorApp(
      tester,
      overrides: [
        featuredPostsRepositoryProvider.overrideWithValue(repo),
        photoPickerProvider.overrideWithValue(_picker()),
        photoUploaderProvider.overrideWithValue(FakePhotoUploader()),
      ],
    );
    routerOf(tester).push(AppRoutes.creatorFeaturedPosts);
    await tester.pumpAndSettle();
    await tester.tap(find.text('게시물 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사진첩에서 골라 교체'));
    await tester.pumpAndSettle();
    await _type(tester, '새 사진');

    await tester.tap(find.text('대표 게시물에 추가'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('게시물 1'), findsNothing);
    expect(find.text('새 사진'), findsOneWidget);
    expect(find.text('게시물 2'), findsOneWidget);
  });

  testWidgets('does not open without a photo', (tester) async {
    await pumpCreatorApp(tester);

    routerOf(tester).push(AppRoutes.creatorFeaturedPostsCompose);
    await tester.pumpAndSettle();

    expect(topPath(tester), isNot(AppRoutes.creatorFeaturedPostsCompose));
  });

  testWidgets('does not overflow at 1.3x text scale in the dark theme', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _openCompose(
      tester,
      FakeFeaturedPostsRepository(),
      picker: _picker(),
      uploader: FakePhotoUploader(),
      largeText: true,
    );
    await _type(tester, '가' * 40);

    expect(tester.takeException(), isNull);
  });
}
