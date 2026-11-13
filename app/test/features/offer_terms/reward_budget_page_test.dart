import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/presentation/pages/reward_budget_page.dart';
import 'package:cora/features/offer_terms/presentation/pages/review_send_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cora/features/server_config/domain/server_config.dart';

import '../../support/load_app_fonts.dart';
import '../server_config/fake_server_config_repository.dart';
import 'proposal_harness.dart';

Finder _burden(String amount) => find.text(amount);

CoraPrimaryButton _reviewButton(WidgetTester tester) =>
    tester.widget<CoraPrimaryButton>(
      find.widgetWithText(CoraPrimaryButton, '검토하고 보내기'),
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('F1 starts from the server defaults with view pay on', (
    tester,
  ) async {
    await pumpProposal(tester);

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.bySemanticsLabel('제안 만들기'), findsOneWidget);
    expect(find.text('보상을 정해요.'), findsOneWidget);
    expect(find.text('식사권과 현금은 따로 계산해요.'), findsOneWidget);
    expect(find.text('제공 혜택'), findsOneWidget);
    expect(find.text('현금과 더하지 않아요'), findsOneWidget);
    expect(find.text('식사권 40,000원 · 2인'), findsOneWidget);
    expect(find.text('고정 현금 (선택)'), findsOneWidget);
    for (final chip in ['없음', '3만 원', '5만 원', '10만 원', '직접 입력']) {
      expect(find.text(chip), findsOneWidget, reason: chip);
    }
    expect(find.text('조회수 수당'), findsOneWidget);
    expect(find.text('조회수만큼 더 드려요 · 기본으로 켜져 있어요'), findsOneWidget);
    expect(find.text('1,000회당 2,000원'), findsOneWidget);
    expect(find.text('최대 60,000원'), findsOneWidget);
    expect(find.text('게시 후 7일'), findsOneWidget);
    expect(find.text('최대 현금 부담 · 남으면 환불'), findsOneWidget);
    expect(_burden('60,000원'), findsOneWidget);
    expect(find.text('검토하고 보내기'), findsOneWidget);
  });

  testWidgets('F1 starts from the store recruit terms when there are some', (
    tester,
  ) async {
    await pumpProposal(
      tester,
      stores: storeWith(
        defaultTerms: const OfferTerms(
          format: ContentFormat.cardNews,
          reward: Reward(
            voucher: Voucher(name: '커트 이용권', value: 30000, people: 1),
            fixedCash: 50000,
          ),
        ),
      ),
    );

    expect(find.text('커트 이용권 30,000원 · 1인'), findsOneWidget);
    expect(_burden('50,000원'), findsOneWidget);
    // 조회수 수당이 꺼진 조건에서 시작하니 상세 줄이 없다.
    expect(find.text('단가'), findsNothing);
  });

  testWidgets('F1 updates the maximum cash burden when fixed cash is picked', (
    tester,
  ) async {
    await pumpProposal(tester);

    await tester.tap(find.text('3만 원'));
    await tester.pumpAndSettle();
    expect(_burden('90,000원'), findsOneWidget);

    await tester.tap(find.text('없음'));
    await tester.pumpAndSettle();
    expect(_burden('60,000원'), findsOneWidget);
  });

  testWidgets(
    'F1 drops the cap from the burden when view pay is switched off',
    (tester) async {
      await pumpProposal(tester);
      await tester.tap(find.text('3만 원'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('조회수 수당'));
      await tester.pumpAndSettle();

      expect(_burden('30,000원'), findsOneWidget);
      expect(find.text('단가'), findsNothing);
      expect(find.text('1인 상한'), findsNothing);
      expect(find.text('측정 기간'), findsNothing);

      // 다시 켜면 고른 단가와 상한이 돌아온다.
      await tester.tap(find.text('조회수 수당'));
      await tester.pumpAndSettle();
      expect(_burden('90,000원'), findsOneWidget);
      expect(find.text('측정 기간'), findsOneWidget);
    },
  );

  testWidgets('F1 offers only rates and caps inside the server range', (
    tester,
  ) async {
    await pumpProposal(tester);

    await tester.tap(find.text('단가'));
    await tester.pumpAndSettle();
    // 1,000원부터 5,000원까지 500원 눈금, 아홉 개다.
    for (final rate in [1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000]) {
      final label = '1,000회당 ${_comma(rate)}원';
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('1,000회당 500원'), findsNothing);
    expect(find.text('1,000회당 5,500원'), findsNothing);
    await tester.tap(find.text('1,000회당 3,000원'));
    await tester.pumpAndSettle();
    expect(find.text('1,000회당 3,000원'), findsOneWidget);

    await tester.tap(find.text('1인 상한'));
    await tester.pumpAndSettle();
    expect(find.text('최대 10,000원'), findsOneWidget);
    expect(find.text('최대 5,000원'), findsNothing);
    await tester.tap(find.text('최대 10,000원'));
    await tester.pumpAndSettle();
    expect(find.text('최대 10,000원'), findsOneWidget);
    expect(_burden('10,000원'), findsOneWidget);
  });

  testWidgets('F1 follows a different server range', (tester) async {
    final config = FakeServerConfigRepository(
      config: const ServerConfigOverride(viewRateMax: 3000).apply(),
    );
    await pumpProposal(tester, config: config);

    await tester.tap(find.text('단가'));
    await tester.pumpAndSettle();
    expect(find.text('1,000회당 3,000원'), findsOneWidget);
    expect(find.text('1,000회당 3,500원'), findsNothing);
  });

  testWidgets('F1 does not press the measuring period row', (tester) async {
    await pumpProposal(tester);

    await tester.tap(find.text('측정 기간'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('게시 후 7일'), findsOneWidget);
  });

  testWidgets('F1 edits the benefit and can drop it', (tester) async {
    await pumpProposal(tester);

    await tester.tap(find.text('식사권 40,000원 · 2인'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('benefitEdit.name')),
      '커트 이용권',
    );
    await tester.enterText(
      find.byKey(const ValueKey('benefitEdit.value')),
      '30000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('benefitEdit.people')),
      '3',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('커트 이용권 30,000원 · 3인'), findsOneWidget);
    // 혜택은 현금이 아니라 최대 현금 부담이 그대로다.
    expect(_burden('60,000원'), findsOneWidget);

    await tester.tap(find.text('커트 이용권 30,000원 · 3인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('혜택 없음'));
    await tester.pumpAndSettle();
    expect(find.text('없음'), findsNWidgets(2)); // 혜택 값과 고정 현금 알약
    expect(find.text('커트 이용권 30,000원 · 3인'), findsNothing);
  });

  testWidgets('F1 rejects a benefit outside the allowed values', (
    tester,
  ) async {
    await pumpProposal(tester);
    await tester.tap(find.text('식사권 40,000원 · 2인'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('benefitEdit.people')),
      '11',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('인원은 1명에서 10명 사이로 적어 주세요.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('benefitEdit.people')),
      '2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('benefitEdit.value')),
      '500',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('금액은 1,000원에서 1,000,000원 사이로 적어 주세요.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('benefitEdit.name')),
      '  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('benefitEdit.value')),
      '40000',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('식사권 이름을 적어 주세요.'), findsOneWidget);
  });

  testWidgets(
    'F1 takes a typed fixed cash in 10,000 won steps up to 1,000,000',
    (tester) async {
      await pumpProposal(tester);

      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('fixedCash.value')),
        '15000',
      );
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(
        find.text('고정 현금은 10,000원 단위로, 1,000,000원까지 적어 주세요.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('fixedCash.value')),
        '1010000',
      );
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(
        find.text('고정 현금은 10,000원 단위로, 1,000,000원까지 적어 주세요.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('fixedCash.value')),
        '150000',
      );
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(_burden('210,000원'), findsOneWidget);
      expect(find.text('직접 입력 · 15만 원'), findsOneWidget);
    },
  );

  testWidgets('F1 disables the button and explains when no reward is left', (
    tester,
  ) async {
    await pumpProposal(tester);
    expect(_reviewButton(tester).onPressed, isNotNull);
    expect(find.text('보상을 하나 이상 정해 주세요.'), findsNothing);

    await tester.tap(find.text('식사권 40,000원 · 2인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('혜택 없음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('조회수 수당'));
    await tester.pumpAndSettle();

    expect(find.text('보상을 하나 이상 정해 주세요.'), findsOneWidget);
    expect(_reviewButton(tester).onPressed, isNull);
    expect(_burden('0원'), findsOneWidget);

    // 고정 현금 하나만 있어도 보낼 수 있다.
    await tester.tap(find.text('5만 원'));
    await tester.pumpAndSettle();
    expect(find.text('보상을 하나 이상 정해 주세요.'), findsNothing);
    expect(_reviewButton(tester).onPressed, isNotNull);
  });

  testWidgets('F1 keeps view pay off for a blog post', (tester) async {
    await pumpProposal(
      tester,
      stores: storeWith(
        defaultTerms: const OfferTerms(
          format: ContentFormat.blog,
          reward: Reward(
            voucher: Voucher(name: '식사권', value: 40000, people: 2),
          ),
        ),
      ),
    );

    expect(find.text('블로그 글은 조회수를 셀 수 없어요.'), findsOneWidget);
    expect(find.text('단가'), findsNothing);

    await tester.tap(find.text('조회수 수당'));
    await tester.pumpAndSettle();
    expect(find.text('단가'), findsNothing);
    expect(_burden('0원'), findsOneWidget);
  });

  testWidgets('F1 opens F2 from the review button', (tester) async {
    await pumpProposal(tester);

    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewSendPage), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('F1 shows the shared failed state and retries', (tester) async {
    final config = FakeServerConfigRepository()..fail = true;
    await pumpProposal(tester, config: config);

    expect(find.text('보상 설정을 불러오지 못했어요.'), findsOneWidget);
    expect(find.byType(RewardBudgetPage), findsOneWidget);

    config.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('보상을 정해요.'), findsOneWidget);
    expect(_burden('60,000원'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets('F1 uses the ${dark ? 'dark' : 'light'} canvas colors', (
      tester,
    ) async {
      await pumpProposal(tester, dark: dark);
      final c = dark ? CoraColors.dark : CoraColors.light;

      Color? boxColor(Finder f) => tester
          .widgetList<DecoratedBox>(
            find.ancestor(of: f, matching: find.byType(DecoratedBox)),
          )
          .map((d) => (d.decoration as BoxDecoration).color)
          .whereType<Color>()
          .first;

      // 카드 바탕: 라이트 #F8F9FA, 다크 #1C1E22.
      expect(boxColor(find.text('식사권 40,000원 · 2인')), c.surface);
      expect(
        c.surface,
        dark ? const Color(0xFF1C1E22) : const Color(0xFFF8F9FA),
      );
      // 고른 알약: 라이트 #FFFFFF, 다크 #2A2D33.
      expect(boxColor(find.text('없음')), c.quietSelected);
      expect(
        c.quietSelected,
        dark ? const Color(0xFF2A2D33) : const Color(0xFFFFFFFF),
      );
      // 켜진 스위치 바탕은 라임, 손잡이는 화면 바탕(라이트 #FFFFFF, 다크 #0F1012).
      final decorations = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>();
      expect(
        decorations.any(
          (d) => d.shape == BoxShape.circle && d.color == c.background,
        ),
        isTrue,
      );
      expect(
        c.background,
        dark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF),
      );
      final track = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((a) => a.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color == c.accent);
      expect(track, isNotEmpty);
      expect(c.accent, const Color(0xFFC6FF3D));
      expect(
        (dark ? coraDarkTheme : coraLightTheme).extension<CoraColors>(),
        c,
      );
    });

    testWidgets('does not overflow at 1.3x text scale (dark: $dark)', (
      tester,
    ) async {
      await pumpProposal(tester, dark: dark, textScale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

String _comma(int n) {
  final s = n.toString();
  return s.length > 3
      ? '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'
      : s;
}

/// 범위가 다른 서버 설정을 만든다(범위가 서버에서 오는지 보려는 테스트용).
class ServerConfigOverride {
  const ServerConfigOverride({required this.viewRateMax});

  final int viewRateMax;

  ServerConfig apply() => ServerConfig(
    reward: RewardLimits(
      viewRate: StepRange(
        min: sampleServerConfig.reward.viewRate.min,
        max: viewRateMax,
        step: sampleServerConfig.reward.viewRate.step,
        defaultValue: sampleServerConfig.reward.viewRate.defaultValue,
      ),
      perViewCap: sampleServerConfig.reward.perViewCap,
      fixedCash: sampleServerConfig.reward.fixedCash,
      voucher: sampleServerConfig.reward.voucher,
      usageRightsDefault: sampleServerConfig.reward.usageRightsDefault,
      countingDays: sampleServerConfig.reward.countingDays,
    ),
    feeRates: sampleServerConfig.feeRates,
  );
}
