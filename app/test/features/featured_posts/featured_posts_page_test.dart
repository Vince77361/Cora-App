import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_featured_post_tokens.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/core/ui/cora_step_header.dart';
import 'package:cora/features/featured_posts/domain/featured_post.dart';
import 'package:cora/features/featured_posts/domain/featured_posts_repository.dart';
import 'package:cora/features/featured_posts/presentation/pages/featured_posts_page.dart';
import 'package:cora/features/instagram_connect/domain/instagram_connection.dart';
import 'package:cora/features/instagram_connect/domain/instagram_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../instagram_connect/fake_instagram_repository.dart';
import '../store_browse/creator_app_harness.dart';
import 'fake_featured_posts_repository.dart';

const _connected = InstagramConnection(handle: 'min.closet', followers: 1200);

Future<void> _open(
  WidgetTester tester,
  FakeFeaturedPostsRepository repo, {
  FakeInstagramRepository? instagram,
  bool largeText = false,
}) async {
  await pumpCreatorApp(
    tester,
    instagram: instagram ?? FakeInstagramRepository(connection: _connected),
    smallPhoneLargeText: largeText,
    overrides: [featuredPostsRepositoryProvider.overrideWithValue(repo)],
  );
  routerOf(tester).push(AppRoutes.creatorFeaturedPosts);
  await tester.pumpAndSettle();
}

FakeFeaturedPostsRepository _four() => FakeFeaturedPostsRepository(
  posts: [for (var n = 1; n <= 4; n++) savedPost(n)],
);

/// 시트를 열 게시물 칸. 한 줄 글자를 가진 칸을 누른다.
Future<void> _tapPost(WidgetTester tester, int n) async {
  await tester.tap(find.text('게시물 $n'));
  await tester.pumpAndSettle();
}

/// 위에서 아래, 왼쪽에서 오른쪽으로 읽은 칸의 한 줄 글자 차례.
List<String> _captionOrder(WidgetTester tester) {
  final texts = find
      .byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('게시물 '))
      .evaluate()
      .map((e) => e.widget as Text)
      .toList();
  final positions = {
    for (final t in texts) t.data!: tester.getTopLeft(find.text(t.data!)),
  };
  final entries = positions.entries.toList()
    ..sort((a, b) {
      final row = (a.value.dy / 100).floor().compareTo(
        (b.value.dy / 100).floor(),
      );
      return row != 0 ? row : a.value.dx.compareTo(b.value.dx);
    });
  return [for (final e in entries) e.key];
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    // 앱 테마는 처음 읽을 때 한 번만 만들어지고 그때의 플랫폼을 담는다. iOS 가장자리 밀기 시험이 iOS 테마를 쓰도록
    // 이 파일의 테마를 iOS로 만들어 둔다(밀기 감지기는 iOS 테마에서만 붙는다).
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    coraLightTheme.platform;
    coraDarkTheme.platform;
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'shows four empty numbered slots and both source buttons when empty',
    (tester) async {
      await _open(tester, FakeFeaturedPostsRepository());

      expect(topPath(tester), AppRoutes.creatorFeaturedPosts);
      expect(find.text('대표 게시물'), findsOneWidget);
      expect(find.text('0 / 4'), findsOneWidget);
      expect(
        find.text('가게 사장님에게 가장 먼저 보여요. 최대 4개, 언제든 바꿀 수 있어요.'),
        findsOneWidget,
      );
      for (final n in ['1', '2', '3', '4']) {
        expect(find.text(n), findsOneWidget);
      }
      expect(find.text('대표 게시물 1개만 있어도 지원할 수 있어요.'), findsOneWidget);
      expect(find.text('인스타에서 고르기'), findsOneWidget);
      expect(find.text('사진첩에서 올리기'), findsOneWidget);
      expect(find.text('저장하기'), findsNothing);
    },
  );

  testWidgets('shows the counter 4 / 4 and the reorder hint when full', (
    tester,
  ) async {
    await _open(tester, _four());

    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.text('꾹 눌러 끌면 순서를 바꿀 수 있어요'), findsOneWidget);
    // 다 찼으면 더 담는 버튼이 없고, 바뀐 것이 없으면 저장하기도 없다.
    expect(find.text('인스타에서 고르기'), findsNothing);
    expect(find.text('사진첩에서 올리기'), findsNothing);
    expect(find.text('저장하기'), findsNothing);
    expect(find.text('인스타'), findsNWidgets(4));
    expect(_captionOrder(tester), ['게시물 1', '게시물 2', '게시물 3', '게시물 4']);
  });

  testWidgets('shows the gallery mark on gallery posts', (tester) async {
    await _open(
      tester,
      FakeFeaturedPostsRepository(
        posts: [savedPost(1, source: FeaturedPostSource.gallery)],
      ),
    );

    expect(find.text('사진첩'), findsOneWidget);
  });

  testWidgets(
    'moves a post to the front from the sheet and keeps numbers 1..n',
    (tester) async {
      final repo = _four();
      await _open(tester, repo);

      await _tapPost(tester, 3);
      expect(find.text('3번 게시물'), findsOneWidget);
      expect(find.text('다른 게시물로 바꾸거나 순서를 옮겨요.'), findsOneWidget);
      expect(find.text('인스타에서 골라 교체'), findsOneWidget);
      expect(find.text('사진첩에서 골라 교체'), findsOneWidget);
      expect(find.text('대표 게시물에서 빼기'), findsOneWidget);
      await tester.tap(find.text('맨 앞으로 보내기'));
      await tester.pumpAndSettle();

      expect(_captionOrder(tester), ['게시물 3', '게시물 1', '게시물 2', '게시물 4']);
      for (final n in ['1', '2', '3', '4']) {
        expect(find.text(n), findsOneWidget);
      }
      // 바뀐 것은 화면 안에만 있다.
      expect(repo.saved, isEmpty);
      expect(find.text('저장하기'), findsOneWidget);
    },
  );

  testWidgets('hides move to front for the first post', (tester) async {
    await _open(tester, _four());

    await _tapPost(tester, 1);

    expect(find.text('1번 게시물'), findsOneWidget);
    expect(find.text('맨 앞으로 보내기'), findsNothing);
  });

  testWidgets('removes a post from the sheet and renumbers', (tester) async {
    await _open(tester, _four());

    await _tapPost(tester, 2);
    await tester.tap(find.text('대표 게시물에서 빼기'));
    await tester.pumpAndSettle();

    expect(find.text('3 / 4'), findsOneWidget);
    expect(_captionOrder(tester), ['게시물 1', '게시물 3', '게시물 4']);
    // 번호 1~3은 게시물, 4는 빈 틀이다. 빠진 자리에 번호가 남지 않는다.
    for (final n in ['1', '2', '3', '4']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('인스타에서 고르기'), findsOneWidget);
  });

  testWidgets('reorders by long pressing a post and dropping it on another', (
    tester,
  ) async {
    await _open(tester, _four());

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('게시물 4')) - const Offset(0, 40),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(
      tester.getCenter(find.text('게시물 1')) - const Offset(0, 40),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_captionOrder(tester), ['게시물 4', '게시물 1', '게시물 2', '게시물 3']);
  });

  testWidgets('does not save until 저장하기 and sends the whole list once', (
    tester,
  ) async {
    final repo = _four();
    await _open(tester, repo);
    await _tapPost(tester, 2);
    await tester.tap(find.text('대표 게시물에서 빼기'));
    await tester.pumpAndSettle();
    await _tapPost(tester, 4);
    await tester.tap(find.text('맨 앞으로 보내기'));
    await tester.pumpAndSettle();
    expect(repo.saved, isEmpty);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(1));
    expect(repo.saved.single.map((p) => p.id), ['post-4', 'post-1', 'post-3']);
    // 저장하면 화면이 닫힌다.
    expect(topPath(tester), isNot(AppRoutes.creatorFeaturedPosts));
  });

  testWidgets('keeps the list and shows a message when saving fails', (
    tester,
  ) async {
    final repo = _four()..failSave = true;
    await _open(tester, repo);
    await _tapPost(tester, 2);
    await tester.tap(find.text('대표 게시물에서 빼기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(topPath(tester), AppRoutes.creatorFeaturedPosts);
    expect(find.text('3 / 4'), findsOneWidget);
  });

  testWidgets('asks to save changes when leaving a dirty list', (tester) async {
    final repo = _four();
    await _open(tester, repo);
    await _tapPost(tester, 2);
    await tester.tap(find.text('대표 게시물에서 빼기'));
    await tester.pumpAndSettle();

    await systemBack(tester);

    expect(find.text('바꾼 내용을 저장할까요?'), findsOneWidget);
    expect(topPath(tester), AppRoutes.creatorFeaturedPosts);

    // 저장 안 함은 바뀐 것을 버리고 나간다.
    await tester.tap(find.text('저장 안 함'));
    await tester.pumpAndSettle();
    expect(repo.saved, isEmpty);
    expect(topPath(tester), isNot(AppRoutes.creatorFeaturedPosts));
  });

  testWidgets('saves from the leave question and then leaves', (tester) async {
    final repo = _four();
    await _open(tester, repo);
    await _tapPost(tester, 2);
    await tester.tap(find.text('대표 게시물에서 빼기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CoraBackButton));
    await tester.pumpAndSettle();
    expect(find.text('바꾼 내용을 저장할까요?'), findsOneWidget);
    await tester.tap(find.text('저장하기').last);
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(1));
    expect(topPath(tester), isNot(AppRoutes.creatorFeaturedPosts));
  });

  testWidgets('blocks the save button and every edit while saving', (
    tester,
  ) async {
    final hold = Completer<void>();
    final repo = _four()..holdSave = hold;
    await _open(tester, repo);
    await _tapPost(tester, 2);
    await tester.tap(find.text('대표 게시물에서 빼기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('저장하기'));
    await tester.pump();
    // 연타해도 서버에는 한 번만 간다.
    await tester.tap(find.text('저장하기'), warnIfMissed: false);
    await tester.pump();
    expect(repo.saved, hasLength(1));
    final button = tester.widget<CoraPrimaryButton>(
      find.ancestor(
        of: find.text('저장하기'),
        matching: find.byType(CoraPrimaryButton),
      ),
    );
    expect(button.onPressed, isNull);

    // 저장하는 동안에는 시트에서 골라도 목록이 바뀌지 않는다.
    await _tapPost(tester, 3);
    await tester.tap(find.text('대표 게시물에서 빼기'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);

    hold.complete();
    await tester.pumpAndSettle();
    expect(repo.saved, hasLength(1));
    expect(repo.saved.single.map((p) => p.id), ['post-1', 'post-3', 'post-4']);
    expect(topPath(tester), isNot(AppRoutes.creatorFeaturedPosts));
  });

  group('iOS edge swipe back', () {
    Future<void> swipeBack(WidgetTester tester) async {
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
    }

    testWidgets('leaves by swiping when nothing changed', (tester) async {
      await _open(tester, _four());

      await swipeBack(tester);

      expect(find.text('바꾼 내용을 저장할까요?'), findsNothing);
      expect(topPath(tester), isNot(AppRoutes.creatorFeaturedPosts));
    });

    testWidgets('does not leave by swiping while there are unsaved changes', (
      tester,
    ) async {
      await _open(tester, _four());
      await _tapPost(tester, 2);
      await tester.tap(find.text('대표 게시물에서 빼기'));
      await tester.pumpAndSettle();

      await swipeBack(tester);

      expect(topPath(tester), AppRoutes.creatorFeaturedPosts);
      expect(find.text('3 / 4'), findsOneWidget);
    });
  });

  testWidgets('paints the card scrim and caption shadow from the tokens', (
    tester,
  ) async {
    await _open(tester, _four());

    final gradients = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((w) => w.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.gradient)
        .whereType<LinearGradient>();
    expect(
      gradients.where(
        (g) =>
            g.colors.first == CoraFeaturedPostTokens.photoScrimStart &&
            g.colors.last == CoraFeaturedPostTokens.photoScrimEnd,
      ),
      hasLength(4),
    );
    final caption = tester.widget<Text>(find.text('게시물 1'));
    expect(
      caption.style!.shadows!.single.color,
      CoraFeaturedPostTokens.captionShadow,
    );
  });

  testWidgets('leaves without asking when nothing changed', (tester) async {
    await _open(tester, _four());

    await systemBack(tester);

    expect(find.text('바꾼 내용을 저장할까요?'), findsNothing);
    expect(topPath(tester), isNot(AppRoutes.creatorFeaturedPosts));
  });

  testWidgets(
    'shows the personal-account notices when instagram is not connected',
    (tester) async {
      final instagram = FakeInstagramRepository()
        ..failComplete = const InstagramFailure(
          message: '개인 계정은 연동할 수 없어요. 인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 다시 연동해 주세요.',
          personalAccount: true,
        );
      await _open(
        tester,
        FakeFeaturedPostsRepository(posts: [savedPost(1), savedPost(2)]),
        instagram: instagram,
      );
      // 연동을 시도했다가 개인 계정이라 거절당한 뒤에 안내가 보인다.
      expect(find.text('개인 계정은 연동할 수 없어요.'), findsNothing);

      await tester.tap(find.text('인스타에서 고르기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('인스타그램 연동하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'personal_x');
      await tester.pump();
      await tester.tap(find.text('연결하기'));
      await tester.pumpAndSettle();
      routerOf(tester).pop();
      await tester.pumpAndSettle();
      routerOf(tester).pop();
      await tester.pumpAndSettle();

      expect(find.text('개인 계정은 연동할 수 없어요.'), findsOneWidget);
      expect(
        find.text('인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 다시 연동해 주세요.'),
        findsOneWidget,
      );
      expect(
        find.text('개인 계정은 조회수 수당을 받을 수 없어요. 사진첩에서 올린 게시물은 대표 게시물로만 보여요.'),
        findsOneWidget,
      );
      // 개인 계정은 사진첩 올리기와 방법 안내만 남고 인스타에서 고르기는 없다.
      expect(find.text('프로페셔널 계정으로 바꾸는 방법'), findsOneWidget);
      expect(find.text('사진첩에서 올리기'), findsOneWidget);
      expect(find.text('인스타에서 고르기'), findsNothing);

      await tester.tap(find.text('프로페셔널 계정으로 바꾸는 방법'));
      await tester.pumpAndSettle();
      expect(find.text('인스타그램 앱 → 설정 → 계정 유형 → 프로페셔널 계정으로 전환'), findsOneWidget);
    },
  );

  testWidgets(
    'opens the connect screen instead of the picker when not connected',
    (tester) async {
      await _open(
        tester,
        FakeFeaturedPostsRepository(),
        instagram: FakeInstagramRepository(),
      );

      await tester.tap(find.text('인스타에서 고르기'));
      await tester.pumpAndSettle();

      expect(topPath(tester), AppRoutes.creatorInstagram);
      expect(find.text('인스타그램 연동하기'), findsOneWidget);
    },
  );

  testWidgets('opens from the profile tab of the creator menu', (tester) async {
    await pumpCreatorApp(
      tester,
      overrides: [
        featuredPostsRepositoryProvider.overrideWithValue(
          FakeFeaturedPostsRepository(),
        ),
      ],
    );

    await tester.tap(find.text('프로필'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.creatorFeaturedPosts);
    expect(find.byType(FeaturedPostsPage), findsOneWidget);
  });

  testWidgets('shows a retry when the list cannot be loaded', (tester) async {
    final repo = FakeFeaturedPostsRepository()..failFetch = true;
    await _open(tester, repo);

    expect(find.text('대표 게시물을 불러오지 못했어요.'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 4'), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale and paints the dark tokens', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final repo = FakeFeaturedPostsRepository(
      posts: [
        savedPost(1, caption: '아주 긴 한 줄 설명을 마흔 글자까지 꽉 채워서 써 본 대표 게시물입니다'),
        savedPost(2),
      ],
    );
    await _open(tester, repo, largeText: true);

    // 빈 틀(3번)의 바탕은 다크 `surface`(#1C1E22), 번호 동그라미는 `notifyTabSelected`(#33363D)다.
    final slotPaint = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .where((p) => p.runtimeType.toString() == '_DashedBorderPainter');
    expect(slotPaint, hasLength(2));
    expect((slotPaint.first as dynamic).fill, const Color(0xFF1C1E22));
    expect((slotPaint.first as dynamic).color, const Color(0xFF2A2D33));
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == const Color(0xFF33363D),
      ),
      findsNWidgets(2),
    );

    await _tapPost(tester, 2);
    expect(find.text('2번 게시물'), findsOneWidget);
    // 시트 바탕은 다크 배경(#0F1012)이다.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == const Color(0xFF0F1012) &&
            (w.decoration as BoxDecoration).borderRadius ==
                const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('대표 게시물에서 빼기'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
