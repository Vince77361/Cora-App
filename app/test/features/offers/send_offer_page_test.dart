import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_step_header.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offers/presentation/pages/send_offer_page.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_home/fake_store_home_repository.dart';
import '../store_home/store_home_harness.dart';
import '../store_onboarding/fake_store_repository.dart';

/// 가게의 기본 조건이 쇼츠 + 식사권(`빵 세트`, 3만 원)인 공개된 가게.
FakeStoreRepository _storeWithDefaults() => FakeStoreRepository(
  store: MyStore(
    id: 'store-1',
    status: StoreStatus.published,
    onboardingStep: StoreOnboardingStep.done,
    industry: IndustryCategory.foodCafe,
    name: '한그릇 라멘',
    regionSido: '서울특별시',
    defaultTerms: const OfferTerms(
      format: ContentFormat.shorts,
      reward: Reward(voucher: Voucher(name: '빵 세트', value: 30000)),
    ),
  ),
);

Future<FakeStoreHomeRepository> _openSendOffer(
  WidgetTester tester, {
  FakeStoreRepository? stores,
  FakeStoreHomeRepository? home,
  bool smallPhoneLargeText = false,
}) async {
  final repo = home ?? FakeStoreHomeRepository(applicants: sampleApplicants());
  await pumpStoreHome(
    tester,
    home: repo,
    stores: stores,
    smallPhoneLargeText: smallPhoneLargeText,
  );
  await tester.tap(find.text('오퍼 보내기').first);
  await tester.pumpAndSettle();
  expect(topPath(tester), AppRoutes.storeOfferNew('c1'));
  return repo;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
}

/// 확인 단계에서 F2를 열고 그 마지막 버튼으로 보낸다. 보내기는 F2의 버튼 하나뿐이다.
Future<void> _reviewAndSend(WidgetTester tester) async {
  await tester.tap(find.text('검토하고 보내기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('이 조건으로 보내기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('has no title pill in the header and starts at step 1', (
    tester,
  ) async {
    await _openSendOffer(tester);

    expect(find.byType(SendOfferPage), findsOneWidget);
    // 소유자가 가운데 화면 이름 알약을 뺐다(2026-11-12). 이름은 화면 읽기용으로만 남는다.
    expect(find.text('하루 한 컵에게 오퍼'), findsNothing);
    expect(find.bySemanticsLabel('하루 한 컵에게 오퍼'), findsOneWidget);
    expect(find.byType(CoraBackButton), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('어떤 콘텐츠를\n부탁할까요?'), findsOneWidget);
  });

  testWidgets('send offer starts from the store default terms', (tester) async {
    await _openSendOffer(tester, stores: _storeWithDefaults());

    await _next(tester);
    await _next(tester);

    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('이 오퍼를\n보낼까요?'), findsOneWidget);
    expect(find.text('상대가 수락하면 그때 결제해요.'), findsOneWidget);
    expect(find.text('쇼츠 1편'), findsOneWidget);
    expect(find.text('빵 세트 30,000원'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsWidgets);
    expect(find.text('검토하고 보내기'), findsOneWidget);
    expect(find.text('오퍼 보내기'), findsNothing);
  });

  testWidgets('without default terms it starts from reels with a voucher', (
    tester,
  ) async {
    await _openSendOffer(tester);

    await _next(tester);
    await _next(tester);

    expect(find.text('릴스 1편'), findsOneWidget);
  });

  testWidgets('goes to the proposal box with a confirmation after sending', (
    tester,
  ) async {
    final home = await _openSendOffer(tester, stores: _storeWithDefaults());

    await _next(tester);
    await _next(tester);
    // 확인 단계의 버튼은 보내지 않고 F2를 연다.
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    expect(home.sent, isEmpty);
    expect(find.text('받는 사람과 조건을\n한 번 더 확인해요.'), findsOneWidget);
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(home.sent, hasLength(1));
    expect(home.sent.single.creatorId, 'c1');
    expect(
      home.sent.single.terms,
      const OfferTerms(
        format: ContentFormat.shorts,
        reward: Reward(voucher: Voucher(name: '빵 세트', value: 30000)),
      ),
    );
    // 보낸 오퍼는 제안함으로 가고, 안내가 잠깐 보였다가 사라진다.
    expect(topPath(tester), AppRoutes.storeProposals);
    expect(find.text('제안함'), findsOneWidget);
    expect(find.text('오퍼를 보냈어요.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('오퍼를 보냈어요.'), findsNothing);
  });

  testWidgets('shows a message when an open offer already exists', (
    tester,
  ) async {
    final home = FakeStoreHomeRepository(applicants: sampleApplicants())
      ..conflictOnSend = true;
    await _openSendOffer(tester, home: home);

    await _next(tester);
    await _next(tester);
    await _reviewAndSend(tester);

    // F2에 머물며 보내는 쪽이 준 문구를 보인다.
    expect(find.text('이미 보낸 오퍼가 있어요.'), findsOneWidget);
    expect(find.text('이 조건으로 보내기'), findsOneWidget);
    expect(topPath(tester), AppRoutes.storeOfferNew('c1'));
  });

  testWidgets('shows the generic message when sending fails', (tester) async {
    final home = FakeStoreHomeRepository(applicants: sampleApplicants())
      ..failSend = true;
    await _openSendOffer(tester, home: home);

    await _next(tester);
    await _next(tester);
    await _reviewAndSend(tester);

    expect(find.text('오퍼를 보내지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('이미 보낸 오퍼가 있어요.'), findsNothing);
    expect(topPath(tester), AppRoutes.storeOfferNew('c1'));
  });

  testWidgets('the back button returns to the home without sending', (
    tester,
  ) async {
    final home = await _openSendOffer(tester);

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    // 첫 단계의 이전 버튼은 흐리고 아무 일도 하지 않는다(캔버스 NOffer).
    expect(find.byType(SendOfferPage), findsOneWidget);

    await systemBack(tester);
    expect(topPath(tester), AppRoutes.store);
    expect(home.sent, isEmpty);
  });

  testWidgets('says so when the creator is not among the applicants', (
    tester,
  ) async {
    await pumpStoreHome(tester);
    routerOf(tester).push(AppRoutes.storeOfferNew('nobody'));
    await tester.pumpAndSettle();

    expect(find.text('지원한 크리에이터를 찾지 못했어요.'), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _openSendOffer(tester, smallPhoneLargeText: true);
    expect(tester.takeException(), isNull);
    await _next(tester);
    await _next(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
  });
}
