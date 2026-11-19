import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/store_discover/domain/store_discover_repository.dart';
import 'package:cora/features/store_discover/presentation/pages/store_discover_page.dart';
import 'package:cora/features/store_interests/domain/store_interests_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_discover/fake_store_discover_repository.dart';
import 'fake_store_interests_repository.dart';

/// 둘러보기 머리 북마크의 저장 수는 저장함이 읽은 저장 목록의 수이고, 둘러보기가 결정을 보내면 따라간다.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpDiscover(
    WidgetTester tester, {
    required FakeStoreDiscoverRepository discover,
    required FakeStoreInterestsRepository interests,
  }) async {
    useCanvasPhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeDiscoverRepositoryProvider.overrideWithValue(discover),
          storeInterestsRepositoryProvider.overrideWithValue(interests),
        ],
        child: MaterialApp(
          theme: coraLightTheme,
          home: const StoreDiscoverPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the number of saved creators on the bookmark', (
    tester,
  ) async {
    await pumpDiscover(
      tester,
      discover: FakeStoreDiscoverRepository(cards: [storeCard('c1')]),
      interests: FakeStoreInterestsRepository(
        saved: [storeInterest('a'), storeInterest('b')],
      ),
    );

    expect(find.bySemanticsLabel('저장함, 2명'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('hides the badge when nothing is saved', (tester) async {
    await pumpDiscover(
      tester,
      discover: FakeStoreDiscoverRepository(cards: [storeCard('c1')]),
      interests: FakeStoreInterestsRepository(),
    );

    expect(find.bySemanticsLabel('저장함'), findsOneWidget);
  });

  testWidgets('hides the badge when the saved list cannot be read', (
    tester,
  ) async {
    await pumpDiscover(
      tester,
      discover: FakeStoreDiscoverRepository(cards: [storeCard('c1')]),
      interests: FakeStoreInterestsRepository(saved: [storeInterest('a')])
        ..failFetch = true,
    );

    expect(find.bySemanticsLabel('저장함'), findsOneWidget);
  });

  testWidgets('reads the saved list again after a decision so the count '
      'follows', (tester) async {
    final interests = FakeStoreInterestsRepository(saved: [storeInterest('a')]);
    await pumpDiscover(
      tester,
      discover: FakeStoreDiscoverRepository(
        cards: [
          storeCard('c1'),
          storeCard('c2', name: '민의 옷장 기록'),
        ],
      ),
      interests: interests,
    );
    expect(find.bySemanticsLabel('저장함, 1명'), findsOneWidget);
    final before = interests.savedCalls;

    // 서버에서 위로 밀어 저장한 것처럼 저장 목록이 늘어난다.
    interests.saved = [storeInterest('a'), storeInterest('c1')];
    await tester.drag(find.text('하루 한 컵 게시물 1'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(interests.savedCalls, before + 1);
    expect(find.bySemanticsLabel('저장함, 2명'), findsOneWidget);
  });
}
