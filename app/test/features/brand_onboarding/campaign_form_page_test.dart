import 'package:cora/core/time/clock.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/brand_onboarding/domain/brand_repository.dart';
import 'package:cora/features/brand_onboarding/domain/campaign.dart';
import 'package:cora/features/brand_onboarding/domain/campaign_repository.dart';
import 'package:cora/features/brand_onboarding/presentation/pages/campaign_form_page.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/onboarding/presentation/pages/role_home_placeholder_page.dart';
import 'package:cora/features/principles/domain/principles.dart'
    show ProductTrialDays;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../onboarding/fake_me_repository.dart';
import 'fake_brand_repository.dart';
import 'fake_campaign_repository.dart';

// 한국 시간 2026-11-16(월) 낮 12시.
FakeClock _clock() => FakeClock()..current = DateTime.utc(2026, 11, 16, 3);

void _useTallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeCampaignRepository campaigns,
}) async {
  _useTallPhone(tester);
  await pumpCoraApp(
    tester,
    auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    me: FakeMeRepository(role: UserRole.brand),
    overrides: [
      brandRepositoryProvider.overrideWithValue(
        FakeBrandRepository(profile: defaultBrandProfile),
      ),
      campaignRepositoryProvider.overrideWithValue(campaigns),
      clockProvider.overrideWithValue(_clock()),
    ],
  );
}

Future<void> _type(WidgetTester tester, Key key, String text) async {
  await tester.enterText(find.byKey(key), text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// 필수 칸을 모두 채운다.
Future<void> _fillRequired(
  WidgetTester tester, {
  String fee = '300000',
  String budget = '1000000',
}) async {
  await _type(tester, CampaignFormPage.headlineFieldKey, '나만의 아침 루틴 속 작은 포인트');
  await _type(tester, CampaignFormPage.feeFieldKey, fee);
  await _type(tester, CampaignFormPage.budgetFieldKey, budget);
  await _tap(tester, '릴스');
  await _tap(tester, '날짜 고르기');
  await _tap(tester, '11월 20일 (금)');
}

CoraPrimaryButton _submit(WidgetTester tester, String label) => tester
    .widget<CoraPrimaryButton>(find.widgetWithText(CoraPrimaryButton, label));

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'campaign form requires headline, fee, budget, format and start date',
    (tester) async {
      await _pump(tester, campaigns: FakeCampaignRepository());
      expect(find.byType(CampaignFormPage), findsOneWidget);
      expect(find.text('어떤 콘텐츠를\n함께 만들까요?'), findsOneWidget);
      expect(_submit(tester, '캠페인 시작하기').onPressed, isNull);

      await _type(tester, CampaignFormPage.headlineFieldKey, '한 줄');
      await _type(tester, CampaignFormPage.feeFieldKey, '300000');
      await _type(tester, CampaignFormPage.budgetFieldKey, '1000000');
      await _tap(tester, '릴스');
      // 시작 가능한 날이 아직 없다.
      expect(_submit(tester, '캠페인 시작하기').onPressed, isNull);

      await _tap(tester, '날짜 고르기');
      // 오늘(11월 16일)부터 고를 수 있다.
      expect(find.text('11월 16일 (월)'), findsOneWidget);
      await _tap(tester, '11월 20일 (금)');

      expect(_submit(tester, '캠페인 시작하기').onPressed, isNotNull);
    },
  );

  testWidgets('shows the fee and budget rules next to the fields', (
    tester,
  ) async {
    await _pump(tester, campaigns: FakeCampaignRepository());
    await _fillRequired(tester);

    await _type(tester, CampaignFormPage.feeFieldKey, '15000');
    expect(find.textContaining('1만 원 단위'), findsOneWidget);
    expect(_submit(tester, '캠페인 시작하기').onPressed, isNull);

    // 예산이 제작비보다 작다.
    await _type(tester, CampaignFormPage.feeFieldKey, '500000');
    await _type(tester, CampaignFormPage.budgetFieldKey, '300000');
    expect(find.text('캠페인 예산은 제작비 이상이어야 해요.'), findsOneWidget);
    expect(_submit(tester, '캠페인 시작하기').onPressed, isNull);

    // 1억 원을 넘는다.
    await _type(tester, CampaignFormPage.budgetFieldKey, '100010000');
    expect(find.textContaining('1억 원 이하'), findsOneWidget);
    expect(_submit(tester, '캠페인 시작하기').onPressed, isNull);

    await _type(tester, CampaignFormPage.budgetFieldKey, '100000000');
    expect(_submit(tester, '캠페인 시작하기').onPressed, isNotNull);
  });

  testWidgets(
    'creates the campaign with the entered values and opens discovery',
    (tester) async {
      final campaigns = FakeCampaignRepository();
      await _pump(tester, campaigns: campaigns);
      await _fillRequired(tester);
      await _type(tester, CampaignFormPage.mustIncludeFieldKey(0), '제품 로고');
      await _tap(tester, '14일');
      await _tap(tester, '얼굴 출연');
      await _tap(tester, '대본 낭독');
      // 제품 제공 스위치.
      await _tap(tester, '제품 제공');

      await _tap(tester, '캠페인 시작하기');

      final input = campaigns.lastInput!;
      expect(input.headline, '나만의 아침 루틴 속 작은 포인트');
      expect(input.fee, 300000);
      expect(input.budget, 1000000);
      expect(input.productProvided, isTrue);
      expect(input.format, ContentFormat.reels);
      expect(input.startFrom, DateTime(2026, 11, 20));
      expect(input.trialDays, ProductTrialDays.d14);
      expect(input.mustInclude, ['제품 로고']);
      expect(input.notRequired, [NotRequired.face, NotRequired.scriptReading]);
      // 캠페인이 있으니 발견(01)이 열린다.
      expect(find.byType(RoleHomePlaceholderPage), findsOneWidget);
    },
  );

  testWidgets('shows the server message and stays when the server refuses', (
    tester,
  ) async {
    final campaigns = FakeCampaignRepository()
      ..failWrite = const CampaignFailure(message: '캠페인 예산은 제작비 이상이어야 해요.');
    await _pump(tester, campaigns: campaigns);
    await _fillRequired(tester);

    await _tap(tester, '캠페인 시작하기');

    expect(find.byType(CampaignFormPage), findsOneWidget);
    expect(find.text('캠페인 예산은 제작비 이상이어야 해요.'), findsOneWidget);

    // 문구 없는 실패는 일반 안내를 보인다. 입력을 고치면 안내는 사라진다.
    campaigns.failWrite = const CampaignFailure();
    await _tap(tester, '캠페인 시작하기');
    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    await _type(tester, CampaignFormPage.headlineFieldKey, '다른 한 줄');
    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsNothing);
  });

  testWidgets(
    'the edit screen starts from the active campaign and saves changes',
    (tester) async {
      final campaigns = FakeCampaignRepository(active: defaultCampaign);
      await _pump(tester, campaigns: campaigns);
      // 수정 화면은 라우트로 연다(진입 화면은 발견).
      routerOf(tester).push('/brand/campaign/edit');
      await tester.pumpAndSettle();

      expect(find.byType(CampaignFormPage), findsOneWidget);
      expect(find.text('나만의 아침 루틴 속 작은 포인트'), findsOneWidget);
      expect(find.text('300000'), findsOneWidget);
      expect(find.text('1000000'), findsOneWidget);
      expect(find.text('11월 20일 (금)'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
      expect(find.text('캠페인 마감'), findsOneWidget);

      await _type(tester, CampaignFormPage.budgetFieldKey, '2000000');
      await _tap(tester, '저장');

      expect(campaigns.updateCalls, 1);
      expect(campaigns.lastInput!.budget, 2000000);
      expect(campaigns.lastInput!.headline, '나만의 아침 루틴 속 작은 포인트');
      // 저장하면 온 곳(발견)으로 돌아간다.
      expect(find.byType(RoleHomePlaceholderPage), findsOneWidget);
    },
  );

  testWidgets('closing asks first and then sends the brand to a new campaign', (
    tester,
  ) async {
    final campaigns = FakeCampaignRepository(active: defaultCampaign);
    await _pump(tester, campaigns: campaigns);
    routerOf(tester).push('/brand/campaign/edit');
    await tester.pumpAndSettle();

    await _tap(tester, '캠페인 마감');
    expect(find.text('캠페인을 마감할까요? 진행 중인 협업은 그대로 이어져요.'), findsOneWidget);

    // 취소하면 아무 일도 없다.
    await _tap(tester, '취소');
    expect(campaigns.closeCalls, 0);

    await _tap(tester, '캠페인 마감');
    await _tap(tester, '마감하기');

    expect(campaigns.closeCalls, 1);
    // 진행 중인 캠페인이 없으니 캠페인 만들기가 열린다.
    expect(find.text('캠페인 시작하기'), findsOneWidget);
  });

  testWidgets(
    'the edit screen offers a retry when the campaign cannot be read',
    (tester) async {
      final campaigns = FakeCampaignRepository(active: defaultCampaign);
      await _pump(tester, campaigns: campaigns);
      campaigns.failFetch = true;
      routerOf(tester).push('/brand/campaign/edit');
      await tester.pumpAndSettle();

      expect(find.text('다시 시도'), findsOneWidget);

      campaigns.failFetch = false;
      await _tap(tester, '다시 시도');
      expect(find.text('저장'), findsOneWidget);
    },
  );

  testWidgets('the format and trial chips sit side by side, not full width', (
    tester,
  ) async {
    await _pump(tester, campaigns: FakeCampaignRepository());

    final reels = tester.getRect(
      find
          .ancestor(of: find.text('릴스'), matching: find.byType(DecoratedBox))
          .first,
    );
    final shorts = tester.getRect(
      find
          .ancestor(of: find.text('쇼츠'), matching: find.byType(DecoratedBox))
          .first,
    );
    expect(reels.width, lessThan(150));
    expect(reels.top, shorts.top);
    expect(reels.left, greaterThan(shorts.right));
  });
}
