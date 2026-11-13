import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/core/ui/cora_step_header.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/domain/proposal_draft.dart';
import 'package:cora/features/offer_terms/presentation/widgets/choice_surface.dart';
import 'package:cora/features/offer_terms/presentation/widgets/offer_terms_wizard.dart';
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:cora/features/store_onboarding/domain/store_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../server_config/fake_server_config_repository.dart';
import 'proposal_harness.dart';

const _target = NewOfferTarget(creatorId: 'c1', creatorName: '하루 한 컵');
const _voucher = Voucher(name: '식사권', value: 40000, people: 2);
const _viewPay = ViewPay(ratePerThousand: 2000, cap: 60000);

/// 가게의 모집 조건이 식사권만인 가게.
const _benefitOnlyTerms = OfferTerms(
  format: ContentFormat.shorts,
  reward: Reward(voucher: _voucher),
);

Future<void> _pump(
  WidgetTester tester, {
  OfferTerms? storeTerms,
  SendRecorder? recorder,
  FakeServerConfigRepository? config,
  bool dark = false,
  double textScale = 1,
}) async {
  usePhone(tester);
  final send = recorder ?? SendRecorder();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        storeRepositoryProvider.overrideWithValue(
          storeWith(defaultTerms: storeTerms),
        ),
        serverConfigRepositoryProvider.overrideWithValue(
          config ?? FakeServerConfigRepository(),
        ),
      ],
      child: MaterialApp(
        theme: dark ? coraDarkTheme : coraLightTheme,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: Scaffold(
          body: SafeArea(
            bottom: false,
            child: OfferTermsWizard(
              target: _target,
              pageLabel: '하루 한 컵에게 오퍼',
              storeName: '한그릇 라멘',
              onSend: send.call,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
}

/// 카드 제목으로 그 보상 조합 카드가 골라져 있는지.
bool _selected(WidgetTester tester, String title) => tester
    .widget<OfferChoiceSurface>(
      find.ancestor(
        of: find.text(title),
        matching: find.byType(OfferChoiceSurface),
      ),
    )
    .selected;

bool _enabled(WidgetTester tester, String title) =>
    tester
        .widget<OfferChoiceSurface>(
          find.ancestor(
            of: find.text(title),
            matching: find.byType(OfferChoiceSurface),
          ),
        )
        .onTap !=
    null;

Future<void> _openDetails(WidgetTester tester) async {
  await tester.tapOnText(find.textRange.ofSubstring('자세히 설정'));
  await tester.pumpAndSettle();
}

CoraPrimaryButton _button(WidgetTester tester, String label) => tester
    .widget<CoraPrimaryButton>(find.widgetWithText(CoraPrimaryButton, label));

const _presetBenefit = '제공 혜택만';
const _presetCash = '고정 현금';
const _presetCombo = '제공 혜택 + 조회수 수당 · 추천';

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'starts on the format step with a dimmed back that does nothing',
    (tester) async {
      await _pump(tester);

      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('어떤 콘텐츠를\n부탁할까요?'), findsOneWidget);
      expect(find.text('크리에이터가 올릴 형식을 하나 골라요.'), findsOneWidget);
      for (final text in ['쇼츠', '릴스', '카드뉴스', '블로그 글']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      final dim = find.descendant(
        of: find.byType(CoraBackButton),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(dim.first).opacity, 0.3);

      await tester.tap(find.byType(CoraBackButton));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
    },
  );

  testWidgets('A5 writes the reward step like the canvas', (tester) async {
    await _pump(tester);
    await _next(tester);

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('어떻게\n보상할까요?'), findsOneWidget);
    expect(
      find.text(
        '가게 등록 때 정한 기본값이에요. 최대 현금 부담 60,000원, 조회수가 적으면 남은 돈은 돌려드려요. 자세히 설정',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text(_presetBenefit), findsOneWidget);
    expect(find.text('식사권 40,000원 · 2인'), findsOneWidget);
    expect(find.text(_presetCash), findsOneWidget);
    expect(find.text('정한 금액을 한 번에 · 선택'), findsOneWidget);
    expect(find.text(_presetCombo), findsOneWidget);
    expect(find.text('1,000회당 2,000원 · 1인 최대 60,000원'), findsOneWidget);
  });

  testWidgets('A5 draws the details link underlined in the text color', (
    tester,
  ) async {
    await _pump(tester);
    await _next(tester);

    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('자세히 설정'),
      ),
    );
    TextSpan? link;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == '자세히 설정') link = span;
      return true;
    });
    expect(link, isNotNull);
    expect(link!.style!.decoration, TextDecoration.underline);
    expect(link!.style!.color, CoraColors.light.text);
  });

  testWidgets('A5 preselects the preset of the store recruit terms', (
    tester,
  ) async {
    // 모집 조건이 없는 가게는 서버 설정의 기본 보상(제공 혜택 + 조회수 수당)이다.
    await _pump(tester);
    await _next(tester);
    expect(_selected(tester, _presetCombo), isTrue);
    expect(_selected(tester, _presetBenefit), isFalse);
    expect(_selected(tester, _presetCash), isFalse);
  });

  testWidgets(
    'A5 preselects the benefit only preset for a benefit only store',
    (tester) async {
      await _pump(tester, storeTerms: _benefitOnlyTerms);
      await _next(tester);
      expect(_selected(tester, _presetBenefit), isTrue);
      expect(_selected(tester, _presetCombo), isFalse);
    },
  );

  testWidgets(
    'A5 shows the maximum cash burden of the chosen preset in the description',
    (tester) async {
      await _pump(tester, storeTerms: _benefitOnlyTerms);
      await _next(tester);
      expect(
        find.textContaining('최대 현금 부담 0원', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.text(_presetCombo));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('최대 현금 부담 60,000원', findRichText: true),
        findsOneWidget,
      );
    },
  );

  testWidgets('A5 asks for an amount when fixed cash is chosen', (
    tester,
  ) async {
    await _pump(tester, storeTerms: _benefitOnlyTerms);
    await _next(tester);
    expect(find.byKey(const ValueKey('rewardPreset.cash')), findsNothing);

    await tester.tap(find.text(_presetCash));
    await tester.pumpAndSettle();

    // 금액을 적기 전에도 이 조합이 골라져 있고, 금액이 없으면 다음으로 갈 수 없다.
    expect(_selected(tester, _presetCash), isTrue);
    expect(find.byKey(const ValueKey('rewardPreset.cash')), findsOneWidget);
    expect(find.text('금액 (원)'), findsOneWidget);
    expect(_button(tester, '다음').onPressed, isNull);

    // 1만 원 단위가 아니면 안내하고 다음으로 가지 못한다.
    await tester.enterText(
      find.byKey(const ValueKey('rewardPreset.cash')),
      '15000',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('고정 현금은 10,000원 단위로, 1,000,000원까지 적어 주세요.'),
      findsOneWidget,
    );
    expect(_button(tester, '다음').onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('rewardPreset.cash')),
      '30000',
    );
    await tester.pumpAndSettle();
    expect(find.text('고정 현금은 10,000원 단위로, 1,000,000원까지 적어 주세요.'), findsNothing);
    expect(
      find.textContaining('최대 현금 부담 30,000원', findRichText: true),
      findsOneWidget,
    );
    expect(_button(tester, '다음').onPressed, isNotNull);

    await _next(tester);
    expect(find.text('고정 현금 30,000원'), findsOneWidget);
  });

  testWidgets('A5 refuses a fixed cash above the server maximum', (
    tester,
  ) async {
    await _pump(tester, storeTerms: _benefitOnlyTerms);
    await _next(tester);
    await tester.tap(find.text(_presetCash));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('rewardPreset.cash')),
      '1010000',
    );
    await tester.pumpAndSettle();
    expect(_button(tester, '다음').onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('rewardPreset.cash')),
      '1000000',
    );
    await tester.pumpAndSettle();
    expect(_button(tester, '다음').onPressed, isNotNull);
  });

  testWidgets('A5 keeps the typed fixed cash when switching presets and back', (
    tester,
  ) async {
    await _pump(tester, storeTerms: _benefitOnlyTerms);
    await _next(tester);
    await tester.tap(find.text(_presetCash));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('rewardPreset.cash')),
      '50000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_presetBenefit));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rewardPreset.cash')), findsNothing);
    expect(
      find.textContaining('최대 현금 부담 0원', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text(_presetCash));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('rewardPreset.cash')),
    );
    expect(field.controller!.text, '50000');
  });

  testWidgets(
    'A5 opens F1 from detailed settings and comes back with the edited reward',
    (tester) async {
      await _pump(tester);
      await _next(tester);

      await _openDetails(tester);
      expect(find.text('보상을 정해요.'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);

      // F1에서 조회수 수당을 끄고 고정 현금 3만 원을 고른다.
      await tester.tap(find.text('조회수 수당'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3만 원'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CoraBackButton).last);
      await tester.pumpAndSettle();

      // 식사권 + 고정 현금은 어느 조합에도 맞지 않아 아무것도 골라져 있지 않다. 설명은 고친 값을 따른다.
      expect(find.text('어떻게\n보상할까요?'), findsOneWidget);
      expect(_selected(tester, _presetBenefit), isFalse);
      expect(_selected(tester, _presetCash), isFalse);
      expect(_selected(tester, _presetCombo), isFalse);
      expect(
        find.textContaining('최대 현금 부담 30,000원', findRichText: true),
        findsOneWidget,
      );

      await _next(tester);
      expect(find.text('식사권 40,000원 · 2인\n+ 고정 현금 30,000원'), findsOneWidget);
    },
  );

  testWidgets('A5 skips to F1 when no preset matches the store terms', (
    tester,
  ) async {
    await _pump(
      tester,
      storeTerms: const OfferTerms(
        format: ContentFormat.shorts,
        reward: Reward(voucher: _voucher, fixedCash: 30000, viewPay: _viewPay),
      ),
    );

    await _next(tester);

    expect(find.text('보상을 정해요.'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    // 보상 단계는 건너뛰었다.
    expect(find.text('어떻게\n보상할까요?'), findsNothing);
    // F1에서 돌아오면 형식 단계 그대로다.
    await tester.tap(find.byType(CoraBackButton).last);
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('A5 sends only from the F2 button with the chosen terms', (
    tester,
  ) async {
    final recorder = SendRecorder();
    await _pump(tester, recorder: recorder, storeTerms: _benefitOnlyTerms);

    await tester.tap(find.text('릴스'));
    await tester.pumpAndSettle();
    await _next(tester);
    await tester.tap(find.text(_presetCombo));
    await tester.pumpAndSettle();
    await _next(tester);

    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('이 오퍼를\n보낼까요?'), findsOneWidget);
    expect(find.text('상대가 수락하면 그때 결제해요.'), findsOneWidget);
    expect(find.text('가게'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsOneWidget);
    expect(find.text('콘텐츠'), findsOneWidget);
    expect(find.text('릴스 1편'), findsOneWidget);
    expect(find.text('보상'), findsOneWidget);
    expect(
      find.text('식사권 40,000원 · 2인\n+ 1,000회당 2,000원, 최대 60,000원'),
      findsOneWidget,
    );
    expect(
      find.text('결제한 금액은 Cora가 보관하고, 콘텐츠가 올라온 뒤 크리에이터에게 지급해요.'),
      findsOneWidget,
    );
    expect(find.text('다음'), findsNothing);
    expect(find.text('오퍼 보내기'), findsNothing);

    // 이 단계의 버튼은 보내지 않고 F2를 연다.
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    expect(recorder.sent, isEmpty);
    expect(find.text('받는 사람과 조건을\n한 번 더 확인해요.'), findsOneWidget);
    expect(find.text('하루 한 컵'), findsOneWidget);

    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();
    expect(recorder.sent, [
      const OfferTerms(
        format: ContentFormat.reels,
        reward: Reward(voucher: _voucher, viewPay: _viewPay),
      ),
    ]);
  });

  testWidgets('A5 shows the message the sender gives when F2 fails', (
    tester,
  ) async {
    final recorder = SendRecorder()
      ..failure = const ProposalSendFailure('이미 보낸 오퍼가 있어요.');
    await _pump(tester, recorder: recorder);
    await _next(tester);
    await _next(tester);
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('이미 보낸 오퍼가 있어요.'), findsOneWidget);
    expect(find.text('받는 사람과 조건을\n한 번 더 확인해요.'), findsOneWidget);
  });

  testWidgets('back goes to the previous step and keeps the choices', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('카드뉴스'));
    await tester.pumpAndSettle();
    await _next(tester);
    await tester.tap(find.text(_presetBenefit));
    await tester.pumpAndSettle();
    await _next(tester);

    await tester.tap(find.byType(CoraBackButton));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(_selected(tester, _presetBenefit), isTrue);
    await tester.tap(find.byType(CoraBackButton));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await _next(tester);
    await _next(tester);
    expect(find.text('카드뉴스 1편'), findsOneWidget);
    expect(find.text('식사권 40,000원 · 2인'), findsOneWidget);
  });

  testWidgets('A5 turns off the view pay preset for a blog post', (
    tester,
  ) async {
    await _pump(tester);
    // 처음 골라진 `제공 혜택 + 조회수 수당`이 블로그 글에서는 `제공 혜택만`으로 바뀐다.
    await tester.tap(find.text('블로그 글'));
    await tester.pumpAndSettle();
    await _next(tester);

    expect(find.text('블로그 글은 조회수를 셀 수 없어요.'), findsOneWidget);
    expect(_enabled(tester, _presetCombo), isFalse);
    expect(_enabled(tester, _presetBenefit), isTrue);
    expect(_selected(tester, _presetBenefit), isTrue);

    await tester.tap(find.text(_presetCombo));
    await tester.pumpAndSettle();
    expect(_selected(tester, _presetCombo), isFalse);
    expect(_selected(tester, _presetBenefit), isTrue);
  });

  testWidgets(
    'A5 gives the view pay back when a blog post is changed to another format',
    (tester) async {
      final recorder = SendRecorder();
      await _pump(tester, recorder: recorder);

      await tester.tap(find.text('블로그 글'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('릴스'));
      await tester.pumpAndSettle();
      await _next(tester);

      expect(_selected(tester, _presetCombo), isTrue);
      expect(
        find.textContaining('최대 현금 부담 60,000원', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('블로그 글은 조회수를 셀 수 없어요.'), findsNothing);
    },
  );

  testWidgets(
    'shows the shared failed state and retries when the terms cannot be loaded',
    (tester) async {
      final config = FakeServerConfigRepository()..fail = true;
      await _pump(tester, config: config);

      expect(find.text('조건을 불러오지 못했어요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);

      config.fail = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('어떤 콘텐츠를\n부탁할까요?'), findsOneWidget);
    },
  );

  for (final dark in [false, true]) {
    testWidgets('does not overflow at 1.3x text scale (dark: $dark)', (
      tester,
    ) async {
      await _pump(
        tester,
        dark: dark,
        textScale: 1.3,
        storeTerms: _benefitOnlyTerms,
      );
      expect(tester.takeException(), isNull);
      await _next(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(_presetCash));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('rewardPreset.cash')),
        '15000',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(_presetCombo));
      await tester.pumpAndSettle();
      await _next(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('uses the lime button in dark mode like the canvas', (
    tester,
  ) async {
    await _pump(tester, dark: true);
    expect(_button(tester, '다음').look, CoraPrimaryButtonLook.accent);
    await _next(tester);
    await _next(tester);
    expect(_button(tester, '검토하고 보내기').look, CoraPrimaryButtonLook.accent);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'A5 paints the chosen preset with the canvas colors (dark: $dark)',
      (tester) async {
        await _pump(tester, dark: dark);
        await _next(tester);
        final c = dark ? CoraColors.dark : CoraColors.light;

        Color? fill(String title) {
          final box = find.descendant(
            of: find.ancestor(
              of: find.text(title),
              matching: find.byType(OfferChoiceSurface),
            ),
            matching: find.byType(DecoratedBox),
          );
          return tester
              .widgetList<DecoratedBox>(box)
              .map((w) => w.decoration)
              .whereType<BoxDecoration>()
              .map((d) => d.color)
              .firstWhere((color) => color != null, orElse: () => null);
        }

        // 고른 카드는 라이트 #E3E5E9, 다크 #33363D, 고르지 않은 카드는 `surface`다.
        expect(
          fill(_presetCombo),
          dark ? const Color(0xFF33363D) : const Color(0xFFE3E5E9),
        );
        expect(fill(_presetCombo), c.notifyTabSelected);
        expect(fill(_presetBenefit), c.surface);
      },
    );
  }
}
