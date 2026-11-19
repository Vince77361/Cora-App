import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/discovery/domain/discovery_card.dart';
import 'package:cora/features/discovery/domain/featured_post_ref.dart';
import 'package:cora/features/discovery/presentation/widgets/creator_swipe_card.dart';
import 'package:cora/features/discovery/presentation/widgets/featured_post_viewer.dart';
import 'package:cora/features/discovery/presentation/widgets/swipe_progress_bar.dart';
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;
import 'package:cora/features/store_discover/domain/store_creator_card.dart';
import 'package:cora/features/store_discover/presentation/widgets/featured_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_store_discover_repository.dart';

Future<void> _pumpCard(WidgetTester tester, Widget card) async {
  useCanvasPhone(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: coraLightTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 64, 12, 100),
          child: card,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 스크린 리더가 [finder]의 노드에 [action]을 보낸 것처럼 부른다.
void _perform(WidgetTester tester, Finder finder, SemanticsAction action) =>
    tester.binding.rootPipelineOwner.semanticsOwner!.performAction(
      tester.getSemantics(finder).id,
      action,
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the card text follows the post on screen', (tester) async {
    await _pumpCard(tester, FeaturedPostCard(card: storeCard('c1')));

    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('하루 한 컵 게시물 1'), findsOneWidget);
    await tester.tapAt(const Offset(300, 300));
    await tester.pumpAndSettle();
    expect(find.text('하루 한 컵 게시물 2'), findsOneWidget);
    expect(find.text('하루 한 컵 게시물 1'), findsNothing);
  });

  testWidgets('a screen reader can move between posts with increase and '
      'decrease', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpCard(tester, FeaturedPostCard(card: storeCard('c1')));
    // 뷰어가 만든 조절 가능한 항목(값이 있는 `Semantics`).
    final viewer = find.descendant(
      of: find.byType(FeaturedPostViewer),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.value != null,
      ),
    );

    // 처음에는 이전이 없고 다음만 있다.
    var node = tester.getSemantics(viewer);
    expect(node.value, '1 / 4');
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.decrease),
      isFalse,
    );

    _perform(tester, viewer, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(find.text('하루 한 컵 게시물 2'), findsOneWidget);
    node = tester.getSemantics(viewer);
    expect(node.value, '2 / 4');
    expect(node.getSemanticsData().hasAction(SemanticsAction.decrease), isTrue);

    _perform(tester, viewer, SemanticsAction.decrease);
    await tester.pumpAndSettle();
    expect(find.text('하루 한 컵 게시물 1'), findsOneWidget);

    // 맨 끝에서는 다음이 없다.
    for (var i = 0; i < 3; i++) {
      _perform(tester, viewer, SemanticsAction.increase);
      await tester.pumpAndSettle();
    }
    node = tester.getSemantics(viewer);
    expect(node.value, '4 / 4');
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.increase),
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('only a focus or only followers still reads well', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      FeaturedPostCard(card: storeCard('c1', followers: null)),
    );
    expect(find.text('리빙 릴스'), findsOneWidget);

    await _pumpCard(
      tester,
      FeaturedPostCard(card: storeCard('c2', contentFocus: null)),
    );
    expect(find.text('팔로워 640'), findsOneWidget);
  });

  testWidgets('a long one-liner stops at two lines', (tester) async {
    final long = '아주 긴 한 줄 ' * 8;
    await _pumpCard(
      tester,
      FeaturedPostCard(
        card: StoreCreatorCard(
          creatorId: 'c1',
          displayName: '하루 한 컵',
          posts: [FeaturedPostRef(photoUrl: null, caption: long.trim())],
        ),
      ),
    );
    final text = tester.widget<Text>(find.text(long.trim()));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a brand card with posts uses the same viewer and keeps its '
      'fee line and badge', (tester) async {
    await _pumpCard(
      tester,
      CreatorSwipeCard(
        card: CreatorCard(
          creatorId: 'c1',
          displayName: '서윤의 작은 취향',
          feeBand: FeeBand.w300k,
          headline: '첫 줄',
          posts: const [
            FeaturedPostRef(photoUrl: null, caption: '첫 줄'),
            FeaturedPostRef(photoUrl: null, caption: '둘째 줄'),
          ],
        ),
        position: 1,
        total: 3,
      ),
    );

    expect(find.text('운영자 추천 1 / 3'), findsOneWidget);
    expect(find.text('30만 원대'), findsOneWidget);
    expect(
      tester.widget<SwipeProgressBar>(find.byType(SwipeProgressBar)).segments,
      2,
    );
    await tester.tapAt(const Offset(300, 300));
    await tester.pumpAndSettle();
    expect(find.text('둘째 줄'), findsOneWidget);
  });

  testWidgets('a brand card without posts keeps the single photo and three '
      'segments', (tester) async {
    await _pumpCard(
      tester,
      CreatorSwipeCard(
        card: CreatorCard(
          creatorId: 'c1',
          displayName: '서윤의 작은 취향',
          feeBand: FeeBand.w300k,
          headline: '한 줄',
        ),
        position: 1,
        total: 3,
      ),
    );

    expect(
      tester.widget<SwipeProgressBar>(find.byType(SwipeProgressBar)).segments,
      3,
    );
    expect(find.text('한 줄'), findsOneWidget);
  });

  testWidgets('a brand card opens the detail from the text area and keeps '
      'post taps on the photo', (tester) async {
    var opened = 0;
    await _pumpCard(
      tester,
      CreatorSwipeCard(
        card: CreatorCard(
          creatorId: 'c1',
          displayName: '서윤의 작은 취향',
          feeBand: FeeBand.w300k,
          posts: const [
            FeaturedPostRef(photoUrl: null, caption: '첫 줄'),
            FeaturedPostRef(photoUrl: null, caption: '둘째 줄'),
          ],
        ),
        position: 1,
        total: 3,
        onOpenDetail: () => opened++,
      ),
    );

    await tester.tapAt(const Offset(300, 300));
    await tester.pumpAndSettle();
    expect(opened, 0);
    expect(find.text('둘째 줄'), findsOneWidget);

    await tester.tapAt(const Offset(200, 650));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(find.text('둘째 줄'), findsOneWidget);
  });
}
