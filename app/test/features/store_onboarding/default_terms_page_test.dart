import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/domain/store_repository.dart';
import 'package:cora/features/store_onboarding/presentation/pages/default_terms_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_store_repository.dart';
import 'store_app_harness.dart';

/// 공개하면 서버의 가게가 공개 상태가 되는 것까지 흉내 낸다(홈이 열리려면 필요하다).
class _PublishingStores extends FakeStoreRepository {
  _PublishingStores({super.store});

  bool failPublish = false;
  final calls = <String>[];

  @override
  Future<MyStore> setDefaultTerms(OfferTerms input) {
    calls.add('terms');
    return super.setDefaultTerms(input);
  }

  @override
  Future<MyStore> publish() async {
    calls.add('publish');
    if (failPublish) throw const StoreFailure();
    return store = sampleStore(
      status: StoreStatus.published,
      step: StoreOnboardingStep.done,
    );
  }
}

Future<_PublishingStores> _openTerms(WidgetTester tester) async {
  final stores = _PublishingStores(
    store: sampleStore(step: StoreOnboardingStep.terms),
  );
  await pumpStoreApp(tester, stores: stores);
  return stores;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('opens on the default terms of a store still being set up', (
    tester,
  ) async {
    await _openTerms(tester);

    expect(currentPath(tester), AppRoutes.storeOnboardingTerms);
    expect(find.text('기본 오퍼 조건'), findsNothing);
    expect(find.bySemanticsLabel('기본 오퍼 조건'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('어떤 콘텐츠를\n부탁할까요?'), findsOneWidget);
  });

  testWidgets('publishing goes to the store home', (tester) async {
    final stores = await _openTerms(tester);
    await _next(tester);
    await _next(tester);

    expect(find.text('이 조건으로 가게를\n공개할까요?'), findsOneWidget);
    expect(
      find.text('크리에이터가 가게 페이지에서 이 조건을 봐요. 오퍼를 보낼 때 바꿀 수 있어요.'),
      findsOneWidget,
    );
    expect(find.text('한그릇 라멘'), findsOneWidget);

    await tester.tap(find.text('가게 공개하기'));
    await tester.pumpAndSettle();

    expect(stores.terms.single.format, ContentFormat.reels);
    expect(stores.terms.single.reward.maxCashBurden, 60000);
    // 조건을 먼저 저장하고 그다음에 공개한다.
    expect(stores.calls, ['terms', 'publish']);
    expect(currentPath(tester), AppRoutes.store);
    expect(find.byType(DefaultTermsPage), findsNothing);
  });

  testWidgets(
    'stays on the confirm step and shows an error when publishing fails',
    (tester) async {
      final stores = await _openTerms(tester);
      stores.failPublish = true;
      await _next(tester);
      await _next(tester);

      await tester.tap(find.text('가게 공개하기'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), AppRoutes.storeOnboardingTerms);
      expect(find.text('3 / 3'), findsOneWidget);
      expect(find.text('가게를 공개하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('가게 공개하기'), findsOneWidget);

      // 고른 값을 지우지 않고 다시 시도할 수 있다.
      stores.failPublish = false;
      await tester.tap(find.text('가게 공개하기'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), AppRoutes.store);
    },
  );

  testWidgets('starts from the saved default terms when reopened', (
    tester,
  ) async {
    final stores = _PublishingStores(
      store: MyStore(
        id: 'store-1',
        status: StoreStatus.draft,
        onboardingStep: StoreOnboardingStep.done,
        industry: IndustryCategory.foodCafe,
        name: '한그릇 라멘',
        defaultTerms: const OfferTerms(
          format: ContentFormat.cardNews,
          reward: Reward(voucher: Voucher(name: '커트 이용권', value: 30000)),
        ),
      ),
    );
    await pumpStoreApp(tester, stores: stores);

    await _next(tester);
    expect(find.text('커트 이용권 30,000원'), findsOneWidget);
    await _next(tester);
    expect(find.text('카드뉴스 1편'), findsOneWidget);
    expect(find.text('커트 이용권 30,000원'), findsOneWidget);
  });
}
