import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/core/ui/cora_step_header.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/presentation/pages/reward_budget_page.dart';
import 'package:cora/features/offer_terms/presentation/pages/review_send_page.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/domain/store_repository.dart';
import 'package:cora/features/store_onboarding/presentation/pages/recruit_terms_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../server_config/fake_server_config_repository.dart';
import 'fake_store_repository.dart';
import 'store_app_harness.dart';

/// 공개하면 서버의 가게가 공개 상태가 되는 것까지 흉내 낸다(홈이 열리려면 필요하다).
class _PublishingStores extends FakeStoreRepository {
  _PublishingStores({super.store});

  bool failPublish = false;
  final calls = <String>[];

  @override
  Future<MyStore> setDefaultTerms(OfferTerms terms) {
    calls.add('terms');
    return super.setDefaultTerms(terms);
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

Future<void> _tapAndSettle(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('resumes onboarding at the recruit terms step', (tester) async {
    await _openTerms(tester);

    expect(currentPath(tester), AppRoutes.storeOnboardingTerms);
    expect(find.byType(RecruitTermsPage), findsOneWidget);
    expect(find.text('기본 오퍼 조건'), findsNothing);
    expect(find.bySemanticsLabel('제안 만들기'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('어떤 콘텐츠를\n부탁할까요?'), findsOneWidget);
    expect(find.text('크리에이터가 올릴 형식을 하나 골라요.'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
  });

  testWidgets('the next button is lime with #1F2A00 text in light and dark', (
    tester,
  ) async {
    Color? buttonColor() =>
        (tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: find.byType(CoraPrimaryButton),
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .color;
    Color? labelColor() => tester.widget<Text>(find.text('다음')).style?.color;

    await _openTerms(tester);
    expect(buttonColor(), const Color(0xFFC6FF3D));
    expect(labelColor(), const Color(0xFF1F2A00));

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    expect(buttonColor(), const Color(0xFFC6FF3D));
    expect(labelColor(), const Color(0xFF1F2A00));
  });

  testWidgets(
    'recruit flow saves the terms, publishes the store and opens the home',
    (tester) async {
      final stores = await _openTerms(tester);
      await _tapAndSettle(tester, '쇼츠');
      await _tapAndSettle(tester, '다음');

      expect(find.byType(RewardBudgetPage), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
      await _tapAndSettle(tester, '5만 원');
      await _tapAndSettle(tester, '검토하고 보내기');

      expect(find.byType(ReviewSendPage), findsOneWidget);
      expect(find.text('3 / 3'), findsOneWidget);
      // 저장도 공개도 마지막 버튼을 누르기 전에는 하지 않는다.
      expect(stores.calls, isEmpty);

      await _tapAndSettle(tester, '이 조건으로 공개하기');

      expect(stores.terms.single.format, ContentFormat.shorts);
      expect(stores.terms.single.reward.fixedCash, 50000);
      expect(stores.terms.single.reward.maxCashBurden, 110000);
      // 조건을 먼저 저장하고 그다음에 공개한다.
      expect(stores.calls, ['terms', 'publish']);
      expect(currentPath(tester), AppRoutes.store);
      expect(find.byType(RecruitTermsPage), findsNothing);
      expect(find.byType(RewardBudgetPage), findsNothing);
      expect(find.byType(ReviewSendPage), findsNothing);
    },
  );

  testWidgets('recruit review shows the open call wording and button', (
    tester,
  ) async {
    await _openTerms(tester);
    await _tapAndSettle(tester, '다음');
    await _tapAndSettle(tester, '검토하고 보내기');

    expect(find.text('공개 모집'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsOneWidget);
    expect(
      find.text('크리에이터가 가게 페이지에서 이 조건을 봐요. 오퍼를 보낼 때 바꿀 수 있어요.'),
      findsOneWidget,
    );
    expect(find.text('이 조건으로 공개하기'), findsOneWidget);
  });

  testWidgets('stays on the review and shows an error when publishing fails', (
    tester,
  ) async {
    final stores = await _openTerms(tester);
    stores.failPublish = true;
    await _tapAndSettle(tester, '다음');
    await _tapAndSettle(tester, '검토하고 보내기');

    await _tapAndSettle(tester, '이 조건으로 공개하기');

    expect(currentPath(tester), AppRoutes.storeOnboardingTerms);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('가게를 공개하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('이 조건으로 공개하기'), findsOneWidget);

    // 고른 값을 지우지 않고 다시 시도할 수 있다.
    stores.failPublish = false;
    await _tapAndSettle(tester, '이 조건으로 공개하기');
    expect(currentPath(tester), AppRoutes.store);
  });

  testWidgets('goes back from the review to the budget and the format keeps', (
    tester,
  ) async {
    await _openTerms(tester);
    await _tapAndSettle(tester, '카드뉴스');
    await _tapAndSettle(tester, '다음');
    await _tapAndSettle(tester, '검토하고 보내기');
    expect(find.text('카드뉴스 1편 · 3–5장'), findsOneWidget);

    await _tapAndSettle(tester, '고치기');
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byType(CoraBackButton).last);
    await tester.pumpAndSettle();
    expect(find.byType(RewardBudgetPage), findsNothing);
    expect(find.text('1 / 3'), findsOneWidget);
    await _tapAndSettle(tester, '다음');
    await _tapAndSettle(tester, '검토하고 보내기');
    expect(find.text('카드뉴스 1편 · 3–5장'), findsOneWidget);
  });

  testWidgets('starts from the saved recruit terms when reopened', (
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
          reward: Reward(
            voucher: Voucher(name: '커트 이용권', value: 30000, people: 1),
            fixedCash: 30000,
          ),
        ),
      ),
    );
    await pumpStoreApp(tester, stores: stores);

    await _tapAndSettle(tester, '다음');
    expect(find.text('커트 이용권 30,000원 · 1인'), findsOneWidget);
    expect(find.text('30,000원'), findsOneWidget);
    await _tapAndSettle(tester, '검토하고 보내기');
    expect(find.text('카드뉴스 1편 · 3–5장'), findsOneWidget);
  });

  testWidgets('shows the shared failed state when the server config fails', (
    tester,
  ) async {
    final config = FakeServerConfigRepository()..fail = true;
    final stores = _PublishingStores(
      store: sampleStore(step: StoreOnboardingStep.terms),
    );
    await pumpStoreApp(tester, stores: stores, config: config);

    expect(find.text('모집 조건을 불러오지 못했어요.'), findsOneWidget);
    config.fail = false;
    await _tapAndSettle(tester, '다시 시도');
    expect(find.text('어떤 콘텐츠를\n부탁할까요?'), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final stores = _PublishingStores(
      store: sampleStore(step: StoreOnboardingStep.terms),
    );
    await pumpStoreApp(tester, stores: stores);
    expect(tester.takeException(), isNull);
    await _tapAndSettle(tester, '다음');
    expect(tester.takeException(), isNull);
    await _tapAndSettle(tester, '검토하고 보내기');
    expect(tester.takeException(), isNull);
  });
}
