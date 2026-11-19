import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_network_photo.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/featured_posts/domain/featured_post.dart';
import 'package:cora/features/featured_posts/domain/featured_posts_repository.dart';
import 'package:cora/features/instagram_connect/domain/instagram_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../instagram_connect/fake_instagram_repository.dart';
import '../store_browse/creator_app_harness.dart';
import 'fake_featured_posts_repository.dart';

const _connected = InstagramConnection(handle: 'min.closet', followers: 1200);

FakeFeaturedPostsRepository _repo({
  List<FeaturedPost> posts = const [],
  List<InstagramPost>? instagram,
}) => FakeFeaturedPostsRepository(
  posts: posts,
  instagramPosts: instagram ?? [for (var n = 1; n <= 6; n++) igPost('ig-$n')],
);

/// 대표 게시물 화면을 열고 `인스타에서 고르기`를 눌러 고르기 화면까지 간다.
Future<void> _openPick(
  WidgetTester tester,
  FakeFeaturedPostsRepository repo, {
  bool largeText = false,
}) async {
  await pumpCreatorApp(
    tester,
    instagram: FakeInstagramRepository(connection: _connected),
    smallPhoneLargeText: largeText,
    overrides: [featuredPostsRepositoryProvider.overrideWithValue(repo)],
  );
  routerOf(tester).push(AppRoutes.creatorFeaturedPosts);
  await tester.pumpAndSettle();
  await tester.tap(find.text('인스타에서 고르기'));
  await tester.pumpAndSettle();
}

/// 격자의 [i]번째 칸(0부터)을 누른다.
Future<void> _tapCell(WidgetTester tester, int i) async {
  // 가져온 칸·고를 수 없는 칸은 눌러도 반응이 없으므로 맞지 않는 눌림 경고를 끈다.
  await tester.tap(find.byType(CoraNetworkPhoto).at(i), warnIfMissed: false);
  await tester.pump();
}

CoraPrimaryButton _addButton(WidgetTester tester) => tester.widget(
  find.ancestor(
    of: find.text('대표 게시물에 추가'),
    matching: find.byType(CoraPrimaryButton),
  ),
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the canvas copy and the account handle', (tester) async {
    await _openPick(tester, _repo());

    expect(topPath(tester), AppRoutes.creatorFeaturedPostsPick);
    expect(find.text('인스타그램에서 가져오기'), findsOneWidget);
    expect(
      find.text('@min.closet 계정의 게시물이에요. 대표 게시물로 보여줄 것만 골라요. 최대 4개예요.'),
      findsOneWidget,
    );
    expect(find.text('0 / 4개 고름'), findsOneWidget);
    expect(find.text('고른 순서대로 보여줘요'), findsOneWidget);
    expect(find.text('대표 게시물에 추가'), findsOneWidget);
    expect(find.byType(CoraNetworkPhoto), findsNWidgets(6));
  });

  testWidgets('hides the account line when the connection cannot be read', (
    tester,
  ) async {
    final instagram = FakeInstagramRepository(connection: _connected);
    await pumpCreatorApp(
      tester,
      instagram: instagram,
      overrides: [featuredPostsRepositoryProvider.overrideWithValue(_repo())],
    );
    routerOf(tester).push(AppRoutes.creatorFeaturedPosts);
    await tester.pumpAndSettle();
    // 대표 게시물 화면이 연동을 확인한 뒤에 연결 정보가 사라졌다.
    instagram.connection = null;
    await tester.tap(find.text('인스타에서 고르기'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.creatorFeaturedPostsPick);
    expect(find.textContaining('@'), findsNothing);
    expect(find.text('대표 게시물로 보여줄 것만 골라요. 최대 4개예요.'), findsOneWidget);
  });

  testWidgets(
    'numbers picks in the order tapped and disables the add button at zero',
    (tester) async {
      await _openPick(tester, _repo());
      expect(_addButton(tester).onPressed, isNull);

      await _tapCell(tester, 2);
      await _tapCell(tester, 0);

      expect(find.text('2 / 4개 고름'), findsOneWidget);
      // 세 번째 칸이 1번, 첫 번째 칸이 2번이다.
      final first = tester.getCenter(find.text('1'));
      final second = tester.getCenter(find.text('2'));
      expect(first.dx, greaterThan(second.dx));
      expect(_addButton(tester).onPressed, isNotNull);

      // 다시 누르면 고른 것이 풀리고 뒤 번호가 당겨진다.
      await _tapCell(tester, 2);
      expect(find.text('1 / 4개 고름'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await _tapCell(tester, 0);
      expect(find.text('0 / 4개 고름'), findsOneWidget);
      expect(_addButton(tester).onPressed, isNull);
    },
  );

  testWidgets('blocks the fifth pick with the limit sentence', (tester) async {
    await _openPick(tester, _repo());

    for (var i = 0; i < 4; i++) {
      await _tapCell(tester, i);
    }
    expect(find.text('4 / 4개 고름'), findsOneWidget);
    await _tapCell(tester, 4);

    expect(find.text('대표 게시물은 4개까지예요. 4개만 더 고를 수 있어요.'), findsOneWidget);
    expect(find.text('4 / 4개 고름'), findsOneWidget);
    // 안내는 3초 뒤에 사라진다.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.textContaining('대표 게시물은 4개까지예요'), findsNothing);
  });

  testWidgets('limits picks to the room left when the list already has posts', (
    tester,
  ) async {
    await _openPick(tester, _repo(posts: [savedPost(1), savedPost(2)]));

    // 이미 가져온 ig-1·ig-2는 격자 앞의 두 칸이다.
    expect(find.text('0 / 2개 고름'), findsOneWidget);
    await _tapCell(tester, 2);
    await _tapCell(tester, 3);
    await _tapCell(tester, 4);

    expect(find.text('2 / 2개 고름'), findsOneWidget);
    expect(find.text('대표 게시물은 4개까지예요. 2개만 더 고를 수 있어요.'), findsOneWidget);
  });

  testWidgets('marks already featured posts as 가져옴 and not selectable', (
    tester,
  ) async {
    await _openPick(
      tester,
      _repo(posts: [savedPost(1, instagramMediaId: 'ig-2')]),
    );

    expect(find.text('가져옴'), findsOneWidget);
    await _tapCell(tester, 1);
    expect(find.text('0 / 3개 고름'), findsOneWidget);
    expect(_addButton(tester).onPressed, isNull);
  });

  testWidgets('marks videos over the limit as not importable', (tester) async {
    await _openPick(
      tester,
      _repo(
        instagram: [
          igPost('ig-1'),
          igPost(
            'ig-2',
            kind: FeaturedPostKind.video,
            durationSec: 90,
            sizeBytes: 1000,
          ),
          igPost(
            'ig-3',
            kind: FeaturedPostKind.video,
            durationSec: 30,
            sizeBytes: 8 * 1024 * 1024,
          ),
        ],
      ),
    );

    expect(find.text('가져올 수 없어요'), findsOneWidget);
    await _tapCell(tester, 1);
    expect(find.text('0 / 4개 고름'), findsOneWidget);
    // 한도 안의 영상은 고를 수 있다.
    await _tapCell(tester, 2);
    expect(find.text('1 / 4개 고름'), findsOneWidget);
  });

  testWidgets('adds the imported drafts to the list without saving', (
    tester,
  ) async {
    final repo = _repo();
    await _openPick(tester, repo);
    await _tapCell(tester, 3);
    await _tapCell(tester, 1);

    await tester.tap(find.text('대표 게시물에 추가'));
    await tester.pumpAndSettle();

    // 고른 차례대로 서버에 가져오기를 부른다. 저장은 하지 않는다.
    expect(repo.imported, [
      ['ig-4', 'ig-2'],
    ]);
    expect(repo.saved, isEmpty);
    expect(topPath(tester), AppRoutes.creatorFeaturedPosts);
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('견본 게시물 ig-4'), findsOneWidget);
    expect(find.text('견본 게시물 ig-2'), findsOneWidget);
    expect(find.text('저장하기'), findsOneWidget);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    // 저장 요청에는 초안의 저장 필드가 그대로 간다.
    final sent = repo.saved.single;
    expect(sent.map((p) => p.instagramMediaId), ['ig-4', 'ig-2']);
    expect(sent.first.mediaPath, 'featured-posts/user-1/ig-4.jpg');
  });

  testWidgets('replaces a post from the sheet with a single pick', (
    tester,
  ) async {
    final repo = _repo(posts: [savedPost(1), savedPost(2)]);
    await pumpCreatorApp(
      tester,
      instagram: FakeInstagramRepository(connection: _connected),
      overrides: [featuredPostsRepositoryProvider.overrideWithValue(repo)],
    );
    routerOf(tester).push(AppRoutes.creatorFeaturedPosts);
    await tester.pumpAndSettle();
    await tester.tap(find.text('게시물 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('인스타에서 골라 교체'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 1개 고름'), findsOneWidget);
    await _tapCell(tester, 3);
    await _tapCell(tester, 4);
    // 교체는 한 개만 고르므로 다른 칸을 누르면 고른 것이 바뀐다.
    expect(find.text('1 / 1개 고름'), findsOneWidget);
    await tester.tap(find.text('대표 게시물에 추가'));
    await tester.pumpAndSettle();

    expect(repo.imported, [
      ['ig-5'],
    ]);
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('게시물 2'), findsNothing);
    expect(find.text('견본 게시물 ig-5'), findsOneWidget);
    expect(find.text('게시물 1'), findsOneWidget);
  });

  testWidgets('keeps the picks and shows a message when the import fails', (
    tester,
  ) async {
    final repo = _repo()..failImport = true;
    await _openPick(tester, repo);
    await _tapCell(tester, 0);

    await tester.tap(find.text('대표 게시물에 추가'));
    await tester.pumpAndSettle();

    expect(find.text('가져오지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(topPath(tester), AppRoutes.creatorFeaturedPostsPick);
    expect(find.text('1 / 4개 고름'), findsOneWidget);
  });

  testWidgets('closes with the close button without adding anything', (
    tester,
  ) async {
    final repo = _repo();
    await _openPick(tester, repo);
    await _tapCell(tester, 0);

    await tester.tap(find.bySemanticsLabel('닫기').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.creatorFeaturedPosts);
    expect(find.text('0 / 4'), findsOneWidget);
    expect(repo.imported, isEmpty);
  });

  testWidgets('shows a retry when the posts cannot be loaded', (tester) async {
    final repo = _repo()..failListInstagram = true;
    await _openPick(tester, repo);

    expect(find.text('인스타그램 게시물을 불러오지 못했어요.'), findsOneWidget);
    repo.failListInstagram = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.byType(CoraNetworkPhoto), findsNWidgets(6));
  });

  testWidgets('does not overflow at 1.3x text scale in the dark theme', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _openPick(tester, _repo(), largeText: true);
    await _tapCell(tester, 0);

    expect(tester.takeException(), isNull);
    expect(find.text('1 / 4개 고름'), findsOneWidget);
  });
}
