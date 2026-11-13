import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offers/domain/offer_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_browse/creator_app_harness.dart';
import 'fake_received_offers_repository.dart';

const _undoWindow = Duration(seconds: 5);

Future<void> _openInbox(
  WidgetTester tester, {
  required FakeReceivedOffersRepository offers,
  bool smallPhoneLargeText = false,
}) async {
  await pumpCreatorApp(
    tester,
    offers: offers,
    undoWindow: _undoWindow,
    smallPhoneLargeText: smallPhoneLargeText,
  );
  await tester.tap(find.text('협업'));
  await tester.pumpAndSettle();
  expect(currentPath(tester), AppRoutes.creatorOffers);
}

FakeReceivedOffersRepository _twoOffers() => FakeReceivedOffersRepository(
  newOffers: [
    receivedOffer(id: 'o1', storeName: '한그릇 라멘'),
    receivedOffer(
      id: 'o2',
      storeName: '달빛 베이커리',
      storeIntro: '갓 구운 빵 향이 나는 동네 빵집이에요.',
      bestShootingTime: null,
      receivedAt: DateTime.utc(2026, 11, 10, 3),
      terms: const OfferTerms(
        format: ContentFormat.shorts,
        reward: Reward(voucher: Voucher(name: '빵 세트', value: 30000)),
      ),
    ),
  ],
);

void main() {
  setUpAll(loadAppFonts);

  group('new offers tab', () {
    testWidgets('shows one offer card at a time in arrival order', (
      tester,
    ) async {
      await _openInbox(tester, offers: _twoOffers());

      expect(find.text('새 오퍼 2'), findsOneWidget);
      expect(find.text('진행 중'), findsOneWidget);
      // 첫 카드: 캔버스 문구 그대로.
      expect(find.text('소상공인 · 오늘 도착'), findsOneWidget);
      expect(find.text('한그릇 라멘, 성수동'), findsOneWidget);
      expect(find.text('릴스 1편을\n부탁했어요'), findsOneWidget);
      expect(find.text('2인 식사권 40,000원 + 조회수 수당'), findsOneWidget);
      expect(
        find.text('1,000회당 2,000원, 최대 100,000원. 김이 오르는 첫 숟가락 장면을 원해요.'),
        findsOneWidget,
      );
      expect(find.text('#팔로워무관'), findsOneWidget);
      expect(find.text('#오후3시'), findsOneWidget);
      expect(find.text('거절'), findsOneWidget);
      expect(find.text('수락하기'), findsOneWidget);
      // 둘째 카드는 아직 보이지 않는다.
      expect(find.textContaining('달빛 베이커리'), findsNothing);
    });

    testWidgets('declines, then restores the card on undo', (tester) async {
      final offers = _twoOffers();
      await _openInbox(tester, offers: offers);

      await tester.tap(find.text('거절'));
      await tester.pumpAndSettle();

      expect(offers.declined, ['o1']);
      expect(find.text('거절했어요.'), findsOneWidget);
      expect(find.text('가게에는 정중한 거절 알림만 가요. 다음 오퍼를 보여드릴게요.'), findsOneWidget);
      expect(find.text('되돌리기'), findsOneWidget);
      // 방금 거절한 오퍼는 탭 숫자에서 빠진다.
      expect(find.text('새 오퍼 1'), findsOneWidget);

      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();

      expect(offers.undone, ['o1']);
      expect(find.text('릴스 1편을\n부탁했어요'), findsOneWidget);
      expect(find.text('새 오퍼 2'), findsOneWidget);
      expect(find.text('거절했어요.'), findsNothing);
    });

    testWidgets('moves to the next offer when the undo window passes', (
      tester,
    ) async {
      await _openInbox(tester, offers: _twoOffers());

      await tester.tap(find.text('거절'));
      await tester.pumpAndSettle();
      expect(find.text('거절했어요.'), findsOneWidget);

      // 주입한 되돌리기 시간이 지나면 다음 카드가 나온다.
      await tester.pump(_undoWindow - const Duration(seconds: 1));
      expect(find.text('거절했어요.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('거절했어요.'), findsNothing);
      expect(find.text('소상공인 · 어제 도착'), findsOneWidget);
      expect(find.text('달빛 베이커리, 성수동'), findsOneWidget);
      expect(find.text('쇼츠 1편을\n부탁했어요'), findsOneWidget);
      // 식사권만이면 보상 줄과 설명이 모두 혜택 한 줄로 시작한다.
      expect(find.text('빵 세트 30,000원'), findsOneWidget);
      expect(find.text('빵 세트 30,000원. 갓 구운 빵 향이 나는 동네 빵집이에요.'), findsOneWidget);
      expect(find.text('#팔로워무관'), findsOneWidget);
      expect(find.textContaining('#오후'), findsNothing);
    });

    testWidgets('moves to the next offer right away on next offer', (
      tester,
    ) async {
      await _openInbox(tester, offers: _twoOffers());

      await tester.tap(find.text('거절'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음 오퍼 보기'));
      await tester.pumpAndSettle();

      expect(find.text('거절했어요.'), findsNothing);
      expect(find.text('달빛 베이커리, 성수동'), findsOneWidget);
      // 시간이 지나도 이미 걷어 낸 카드가 또 걷히지는 않는다.
      await tester.pump(_undoWindow * 2);
      expect(find.text('달빛 베이커리, 성수동'), findsOneWidget);
    });

    testWidgets('accepting moves the offer to the active tab', (tester) async {
      final offers = _twoOffers();
      await _openInbox(tester, offers: offers);

      await tester.tap(find.text('수락하기'));
      await tester.pumpAndSettle();

      expect(offers.accepted, ['o1']);
      // 화면이 보고 있던 판본 번호를 수락에 실어 보낸다.
      expect(offers.acceptedVersions, [1]);
      expect(find.text('수락했어요.'), findsOneWidget);
      expect(find.text('사장님이 결제하면 알려드릴게요.'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      // 진행 중 탭으로 간다(줄 내용은 received_offers_active_tab_test가 본다).
      expect(find.text('수락했어요.'), findsNothing);
      expect(find.text('아직 진행 중인 협업이 없어요.'), findsOneWidget);
      // 남은 새 오퍼는 하나.
      expect(find.text('새 오퍼 1'), findsOneWidget);
    });

    testWidgets('shows a message when the offer was already handled', (
      tester,
    ) async {
      final offers = _twoOffers();
      await _openInbox(tester, offers: offers);
      // 그사이 사장님이 첫 오퍼를 취소했다: 서버는 409를 주고 목록에서도 빠진다.
      offers
        ..conflictOnAnswer = true
        ..newOffers = [offers.newOffers[1]];

      await tester.tap(find.text('수락하기'));
      await tester.pumpAndSettle();

      expect(find.text('이미 처리된 오퍼예요.'), findsOneWidget);
      // 목록을 새로 받아 다음 카드가 보인다.
      expect(find.text('달빛 베이커리, 성수동'), findsOneWidget);
      expect(find.text('새 오퍼 1'), findsOneWidget);
    });

    testWidgets('shows a message when answering fails', (tester) async {
      final offers = _twoOffers()..failAnswer = true;
      await _openInbox(tester, offers: offers);

      await tester.tap(find.text('거절'));
      await tester.pumpAndSettle();

      expect(find.text('처리하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('릴스 1편을\n부탁했어요'), findsOneWidget);
    });

    testWidgets('shows the undo panel for an offer declined moments ago', (
      tester,
    ) async {
      // 앱을 다시 열었더니 방금 거절한 오퍼가 되돌릴 수 있는 채로 남아 있다.
      final offers = FakeReceivedOffersRepository(
        newOffers: [
          receivedOffer(
            id: 'o1',
            view: OfferView.declined,
            canUndoDecline: true,
          ),
          receivedOffer(id: 'o2', storeName: '달빛 베이커리'),
        ],
      );
      await _openInbox(tester, offers: offers);

      expect(find.text('거절했어요.'), findsOneWidget);
      await tester.pump(_undoWindow);
      await tester.pumpAndSettle();
      expect(find.text('달빛 베이커리, 성수동'), findsOneWidget);
    });
  });

  group('empty and failed states', () {
    testWidgets('received offers shows the shared empty state on each tab', (
      tester,
    ) async {
      await _openInbox(tester, offers: FakeReceivedOffersRepository());

      expect(find.text('새 오퍼 0'), findsOneWidget);
      // 두 문장이면 첫 문장이 제목, 둘째가 설명이다.
      expect(find.byType(CoraStateView), findsOneWidget);
      expect(find.text('새 오퍼가 없어요.'), findsOneWidget);
      expect(find.text('가게에 지원하면 오퍼가 도착해요.'), findsOneWidget);

      await tester.tap(find.text('진행 중'));
      await tester.pumpAndSettle();
      expect(find.byType(CoraStateView), findsOneWidget);
      expect(find.text('아직 진행 중인 협업이 없어요.'), findsOneWidget);
    });

    testWidgets('shows an error with retry when loading fails', (tester) async {
      final offers = FakeReceivedOffersRepository()..failFetch = true;
      await _openInbox(tester, offers: offers);
      expect(find.text('받은 오퍼를 불러오지 못했어요.'), findsOneWidget);

      offers.failFetch = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('새 오퍼 0'), findsOneWidget);
    });

    testWidgets('does not overflow at 1.3x text scale', (tester) async {
      await _openInbox(tester, offers: _twoOffers(), smallPhoneLargeText: true);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('거절'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수락하기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('arrival label follows the clock', (tester) async {
    // 3일 전에 도착한 오퍼.
    final clock = FakeClock()..current = DateTime.utc(2026, 11, 13, 12);
    final offers = FakeReceivedOffersRepository(
      newOffers: [receivedOffer(receivedAt: DateTime.utc(2026, 11, 10, 3))],
    );
    await pumpCreatorApp(tester, offers: offers, clock: clock);
    await tester.tap(find.text('협업'));
    await tester.pumpAndSettle();
    expect(find.text('소상공인 · 3일 전 도착'), findsOneWidget);
  });
}
