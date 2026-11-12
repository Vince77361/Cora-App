import 'package:cora/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../instagram_connect/fake_instagram_repository.dart';
import '../store_browse/creator_app_harness.dart';
import 'fake_received_offers_repository.dart';

Future<void> _openInbox(
  WidgetTester tester, {
  required FakeReceivedOffersRepository offers,
  required FakeInstagramRepository instagram,
  bool smallPhoneLargeText = false,
}) async {
  await pumpCreatorApp(
    tester,
    offers: offers,
    instagram: instagram,
    smallPhoneLargeText: smallPhoneLargeText,
  );
  await tester.tap(find.text('협업'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('offers instagram connect instead of accept when needed', (
    tester,
  ) async {
    final offers = FakeReceivedOffersRepository(
      newOffers: [receivedOffer(id: 'o1', needsInstagram: true)],
    );
    await _openInbox(
      tester,
      offers: offers,
      instagram: FakeInstagramRepository(),
    );

    expect(find.text('인스타그램을 연동하면 수락할 수 있어요'), findsOneWidget);
    expect(find.text('연동하기'), findsOneWidget);
    expect(find.text('수락하기'), findsNothing);
    expect(find.text('거절'), findsOneWidget);
  });

  testWidgets('turns into the accept button after connecting', (tester) async {
    final offers = FakeReceivedOffersRepository(
      newOffers: [receivedOffer(id: 'o1', needsInstagram: true)],
    );
    // 서버는 연결이 끝나면 오퍼의 needsInstagram을 false로 바꾼다.
    final instagram = FakeInstagramRepository()
      ..onConnected = () =>
          offers.newOffers = [receivedOffer(id: 'o1', needsInstagram: false)];
    await _openInbox(tester, offers: offers, instagram: instagram);

    await tester.tap(find.text('연동하기'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.creatorInstagram);

    await tester.tap(find.text('인스타그램 연동하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'haru_cup');
    await tester.pump();
    await tester.tap(find.text('연결하기'));
    await tester.pumpAndSettle();
    expect(find.text('@haru_cup 연동됨'), findsOneWidget);

    // 뒤로 돌아오면 같은 카드가 `수락하기`가 된다.
    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(find.text('수락하기'), findsOneWidget);
    expect(find.text('연동하기'), findsNothing);
    expect(find.text('인스타그램을 연동하면 수락할 수 있어요'), findsNothing);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    final offers = FakeReceivedOffersRepository(
      newOffers: [receivedOffer(id: 'o1', needsInstagram: true)],
    );
    await _openInbox(
      tester,
      offers: offers,
      instagram: FakeInstagramRepository(),
      smallPhoneLargeText: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('연동하기'), findsOneWidget);
  });
}
