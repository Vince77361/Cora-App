import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:cora/features/store_browse/domain/store_detail.dart';
import 'package:cora/features/store_browse/presentation/pages/store_detail_page.dart';
import 'package:cora/features/store_browse/presentation/pages/store_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'creator_app_harness.dart';
import 'fake_store_browse_repository.dart';

Future<void> _openFirstStore(WidgetTester tester) async {
  await tester.tap(find.text('한그릇 라멘'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('creator home (published stores)', () {
    testWidgets('lists published stores with their reward headline', (
      tester,
    ) async {
      await pumpCreatorApp(tester);

      expect(currentPath(tester), AppRoutes.creator);
      expect(find.text('공개된 가게'), findsOneWidget);
      expect(find.text('한그릇 라멘'), findsOneWidget);
      expect(find.text('라멘집, 성수동'), findsOneWidget);
      expect(find.text('2인 식사권 40,000원 + 조회수 수당'), findsOneWidget);
      // 같은 시·도라서 시·도 표지는 없다.
      expect(find.text('서울특별시'), findsNothing);
    });

    testWidgets('marks a store in another province', (tester) async {
      final stores = FakeStoreBrowseRepository(
        stores: [
          ramenStore(id: '1'),
          ramenStore(id: '2', name: '바다 국수', regionSido: '부산광역시'),
        ],
      );
      await pumpCreatorApp(tester, stores: stores);

      expect(find.text('부산광역시'), findsOneWidget);
      expect(find.text('서울특별시'), findsNothing);

      await tester.tap(find.text('바다 국수'));
      await tester.pumpAndSettle();
      // 상세에도 같은 시·도 표지가 사진 위에 붙는다.
      expect(find.text('부산광역시'), findsOneWidget);
      expect(find.text('소상공인'), findsOneWidget);
    });

    testWidgets('shows the empty message', (tester) async {
      await pumpCreatorApp(
        tester,
        stores: FakeStoreBrowseRepository(stores: []),
      );
      expect(find.text('아직 공개된 가게가 없어요.'), findsOneWidget);
    });

    testWidgets('shows an error with retry when loading fails', (tester) async {
      final stores = FakeStoreBrowseRepository()..failFetch = true;
      await pumpCreatorApp(tester, stores: stores);
      expect(find.text('가게를 불러오지 못했어요.'), findsOneWidget);

      stores.failFetch = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('한그릇 라멘'), findsOneWidget);
    });

    testWidgets('has the creator menu and opens collaboration', (tester) async {
      await pumpCreatorApp(tester);
      for (final label in ['발견', '관심', '대화', '협업', '프로필']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('협업'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), AppRoutes.creatorOffers);
      expect(find.text('받은 오퍼'), findsOneWidget);
    });

    testWidgets('menu items without a screen open the coming soon page', (
      tester,
    ) async {
      await pumpCreatorApp(tester);
      await tester.tap(find.text('관심'));
      await tester.pumpAndSettle();
      expect(find.text('준비 중이에요.'), findsOneWidget);
    });
  });

  group('store detail (D2)', () {
    testWidgets('store photo is a Hero from list to detail', (tester) async {
      await pumpCreatorApp(tester);
      Hero hero() => tester.widget<Hero>(find.byType(Hero));
      expect(hero().tag, 'store:1');

      await _openFirstStore(tester);
      expect(topPath(tester), '/creator/stores/1');
      expect(find.byType(Hero), findsOneWidget);
      expect(hero().tag, 'store:1');
    });

    testWidgets('shows the canvas copy', (tester) async {
      await pumpCreatorApp(tester);
      await _openFirstStore(tester);

      expect(find.text('라멘집, 성수동'), findsOneWidget);
      expect(find.text('한그릇 라멘'), findsOneWidget);
      expect(find.text('소상공인'), findsOneWidget);
      expect(find.text('릴스 1편을 만들어 줄\n크리에이터를 찾아요'), findsOneWidget);
      expect(find.text('보상'), findsOneWidget);
      expect(find.text('2인 식사권 40,000원 + 조회수 수당'), findsOneWidget);
      expect(find.text('조회수 수당은 최대 100,000원'), findsOneWidget);
      expect(find.text('찍기 좋은 시간'), findsOneWidget);
      expect(find.text('오후 3시 – 5시'), findsOneWidget);
      expect(find.text('지원 조건'), findsOneWidget);
      expect(find.text('팔로워 무관'), findsOneWidget);
      expect(find.textContaining('진한 국물을 12시간'), findsOneWidget);
      expect(find.text('가게 정보'), findsOneWidget);
      expect(find.text('지원하기'), findsOneWidget);
      // 같은 시·도라서 시·도 표지는 없다.
      expect(find.text('서울특별시'), findsNothing);
    });

    testWidgets('applies and shows the applied state', (tester) async {
      final stores = FakeStoreBrowseRepository();
      await pumpCreatorApp(tester, stores: stores);
      await _openFirstStore(tester);

      await tester.tap(find.text('지원하기'));
      await tester.pumpAndSettle();

      expect(stores.applied, ['1']);
      expect(find.text('지원했어요. 사장님이 고르면 오퍼가 도착해요.'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('지원하기'), findsNothing);
    });

    testWidgets('cancels an application', (tester) async {
      final stores = FakeStoreBrowseRepository()
        ..statuses['1'] = MyApplicationStatus.applied;
      await pumpCreatorApp(tester, stores: stores);
      await _openFirstStore(tester);
      expect(find.text('지원했어요. 사장님이 고르면 오퍼가 도착해요.'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(stores.cancelled, ['1']);
      expect(find.text('지원하기'), findsOneWidget);
      expect(find.text('지원했어요. 사장님이 고르면 오퍼가 도착해요.'), findsNothing);
    });

    testWidgets('points to the offer inbox once offered', (tester) async {
      final stores = FakeStoreBrowseRepository()
        ..statuses['1'] = MyApplicationStatus.offered;
      await pumpCreatorApp(tester, stores: stores);
      await _openFirstStore(tester);

      expect(find.text('오퍼가 도착했어요.'), findsOneWidget);
      expect(find.text('지원하기'), findsNothing);

      await tester.tap(find.text('오퍼 보기'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.creatorOffers);
      expect(find.text('받은 오퍼'), findsOneWidget);
    });

    testWidgets(
      'syncs with the server when the application changed meanwhile',
      (tester) async {
        // 지원하려는 사이 사장님이 오퍼를 보냈다(409): 서버의 지금 상태로 맞춘다.
        final stores = FakeStoreBrowseRepository()..conflictOnChange = true;
        await pumpCreatorApp(tester, stores: stores);
        await _openFirstStore(tester);

        await tester.tap(find.text('지원하기'));
        await tester.pumpAndSettle();

        expect(find.text('오퍼가 도착했어요.'), findsOneWidget);
      },
    );

    testWidgets('shows a message when applying fails', (tester) async {
      final stores = FakeStoreBrowseRepository()..failApply = true;
      await pumpCreatorApp(tester, stores: stores);
      await _openFirstStore(tester);

      await tester.tap(find.text('지원하기'));
      await tester.pumpAndSettle();

      expect(find.text('처리하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('지원하기'), findsOneWidget);
    });

    testWidgets('the store info button opens a coming soon page', (
      tester,
    ) async {
      await pumpCreatorApp(tester);
      await _openFirstStore(tester);
      await tester.tap(find.text('가게 정보'));
      await tester.pumpAndSettle();
      expect(find.text('준비 중이에요.'), findsOneWidget);
    });

    testWidgets('shows a placeholder when there is no shooting time', (
      tester,
    ) async {
      final stores = FakeStoreBrowseRepository()
        ..intro = null
        ..bestShootingTime = null;
      await pumpCreatorApp(tester, stores: stores);
      await _openFirstStore(tester);
      // 찍기 좋은 시간이 없으면 칸은 남고 값만 `아직 없어요`다.
      expect(find.text('아직 없어요'), findsOneWidget);
    });

    testWidgets('back returns to the list', (tester) async {
      await pumpCreatorApp(tester);
      await _openFirstStore(tester);
      await tester.tap(find.bySemanticsLabel('뒤로'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), AppRoutes.creator);
      expect(find.byType(StoreListPage), findsOneWidget);
      expect(find.byType(StoreDetailPage), findsNothing);
    });
  });

  group('text scale', () {
    testWidgets('does not overflow at 1.3x text scale', (tester) async {
      await pumpCreatorApp(
        tester,
        smallPhoneLargeText: true,
        stores: FakeStoreBrowseRepository(
          stores: [ramenStore(regionSido: '부산광역시')],
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('한그릇 라멘'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('지원하기'), findsOneWidget);

      await tester.tap(find.text('지원하기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  test('creator menu has five items', () {
    expect(CoraCreatorNavItems.items, hasLength(5));
  });
}
