import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_step_header.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/presentation/widgets/offer_terms_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';

/// 서버에 닿지 않은 실패를 흉내 낸다. 화면은 예외의 종류가 아니라 실패했다는 사실만 본다.
class _Failure implements Exception {
  const _Failure();
}

void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class _Harness {
  final submitted = <OfferTermsInput>[];
  bool fail = false;

  Future<void> onSubmit(OfferTermsInput input) async {
    submitted.add(input);
    if (fail) throw const _Failure();
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Harness h, {
  OfferTermsInput? initial,
  ThemeData? theme,
  double textScale = 1,
}) async {
  _usePhone(tester);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme ?? coraLightTheme,
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
              headerTitle: '기본 오퍼 조건',
              initial: initial,
              storeName: '한그릇 라멘',
              confirmTitle: '이 조건으로 가게를\n공개할까요?',
              confirmDescription: '크리에이터가 가게 페이지에서 이 조건을 봐요.',
              submitLabel: '가게 공개하기',
              onSubmit: h.onSubmit,
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

void main() {
  setUpAll(loadAppFonts);

  testWidgets('starts on reels and voucher plus views', (tester) async {
    final h = _Harness();
    await _pump(tester, h);

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('어떤 콘텐츠를\n부탁할까요?'), findsOneWidget);
    expect(find.text('크리에이터가 올릴 형식을 하나 골라요.'), findsOneWidget);
    for (final text in [
      '쇼츠',
      '유튜브 60초',
      '릴스',
      '인스타그램 30초',
      '카드뉴스',
      '인스타그램 3–5장',
      '블로그 글',
      '사진 포함 후기',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    await _next(tester);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('어떻게\n보상할까요?'), findsOneWidget);
    expect(find.text('식사권만, 조회수만, 또는 둘 다 고를 수 있어요.'), findsOneWidget);
    expect(find.text('식사권 제공'), findsOneWidget);
    expect(find.text('2인 식사권, 약 4만 원 상당'), findsOneWidget);
    expect(find.text('조회수당 지급'), findsOneWidget);
    expect(find.text('조회 1회당 10원, 최대 10만 원'), findsOneWidget);
    expect(find.text('식사권 + 조회수'), findsOneWidget);
    expect(find.text('식사 후 올리고, 조회수만큼 더 받아요'), findsOneWidget);
    expect(find.text('식사권 고치기'), findsOneWidget);

    await _next(tester);
    await tester.tap(find.text('가게 공개하기'));
    await tester.pumpAndSettle();
    expect(h.submitted.single.format, ContentFormat.reels);
    expect(h.submitted.single.rewardType, RewardType.both);
  });

  testWidgets('walks three steps and submits the chosen terms', (tester) async {
    final h = _Harness();
    await _pump(tester, h);

    await tester.tap(find.text('쇼츠'));
    await tester.pumpAndSettle();
    await _next(tester);
    await tester.tap(find.text('식사권 제공'));
    await tester.pumpAndSettle();
    await _next(tester);

    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('이 조건으로 가게를\n공개할까요?'), findsOneWidget);
    expect(find.text('크리에이터가 가게 페이지에서 이 조건을 봐요.'), findsOneWidget);
    expect(find.text('가게'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsOneWidget);
    expect(find.text('콘텐츠'), findsOneWidget);
    expect(find.text('쇼츠 1편'), findsOneWidget);
    expect(find.text('보상'), findsOneWidget);
    expect(find.text('2인 식사권 (약 4만 원)'), findsOneWidget);
    expect(
      find.text('결제한 금액은 Cora가 보관하고, 콘텐츠가 올라온 뒤 크리에이터에게 지급해요.'),
      findsOneWidget,
    );
    expect(find.text('다음'), findsNothing);

    await tester.tap(find.text('가게 공개하기'));
    await tester.pumpAndSettle();
    expect(h.submitted, [
      const OfferTermsInput(
        format: ContentFormat.shorts,
        rewardType: RewardType.voucher,
        voucherName: '2인 식사권',
        voucherValue: 40000,
      ),
    ]);
  });

  testWidgets('shows a combined reward on two lines when confirming', (
    tester,
  ) async {
    await _pump(tester, _Harness());
    await _next(tester);
    await _next(tester);

    expect(find.text('2인 식사권\n+ 조회 1회당 10원, 최대 10만 원'), findsOneWidget);
  });

  testWidgets('back on step 1 is dimmed and does nothing', (tester) async {
    await _pump(tester, _Harness());

    final dim = find.descendant(
      of: find.byType(CoraBackButton),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(dim.first).opacity, 0.3);

    await tester.tap(find.byType(CoraBackButton));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('어떤 콘텐츠를\n부탁할까요?'), findsOneWidget);
  });

  testWidgets('back goes to the previous step and keeps the choices', (
    tester,
  ) async {
    await _pump(tester, _Harness());
    await tester.tap(find.text('카드뉴스'));
    await tester.pumpAndSettle();
    await _next(tester);
    await _next(tester);

    await tester.tap(find.byType(CoraBackButton));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byType(CoraBackButton));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await _next(tester);
    await _next(tester);
    expect(find.text('카드뉴스 1편'), findsOneWidget);
  });

  testWidgets('starts from the given terms', (tester) async {
    await _pump(
      tester,
      _Harness(),
      initial: const OfferTermsInput(
        format: ContentFormat.cardNews,
        rewardType: RewardType.voucher,
        voucherName: '커트 이용권',
        voucherValue: 30000,
      ),
    );
    await _next(tester);
    expect(find.text('커트 이용권, 약 3만 원 상당'), findsOneWidget);
    await _next(tester);
    expect(find.text('카드뉴스 1편'), findsOneWidget);
    expect(find.text('커트 이용권 (약 3만 원)'), findsOneWidget);
  });

  testWidgets('edits the voucher name and value', (tester) async {
    final h = _Harness();
    await _pump(tester, h);
    await _next(tester);

    await tester.tap(find.text('식사권 고치기'));
    await tester.pumpAndSettle();
    expect(find.text('식사권 고치기'), findsNWidgets(2)); // 버튼(뒤 화면)과 시트 제목
    expect(find.text('이름'), findsOneWidget);
    expect(find.text('금액 (원)'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('voucherEdit.name')),
      '커트 이용권',
    );
    await tester.enterText(
      find.byKey(const ValueKey('voucherEdit.value')),
      '30000',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('커트 이용권, 약 3만 원 상당'), findsOneWidget);
    await _next(tester);
    await tester.tap(find.text('가게 공개하기'));
    await tester.pumpAndSettle();
    expect(h.submitted.single.voucherName, '커트 이용권');
    expect(h.submitted.single.voucherValue, 30000);
  });

  testWidgets('rejects a voucher value below 1000 won', (tester) async {
    await _pump(tester, _Harness());
    await _next(tester);
    await tester.tap(find.text('식사권 고치기'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('voucherEdit.value')),
      '500',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('금액은 1,000원에서 1,000,000원 사이로 적어 주세요.'), findsOneWidget);
    // 시트가 그대로 열려 있고 값은 바뀌지 않았다.
    expect(find.byKey(const ValueKey('voucherEdit.name')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('voucherEdit.value')),
      '1000001',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('voucherEdit.name')), findsOneWidget);
  });

  testWidgets('rejects an empty voucher name', (tester) async {
    await _pump(tester, _Harness());
    await _next(tester);
    await tester.tap(find.text('식사권 고치기'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('voucherEdit.name')),
      '  ',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('식사권 이름을 적어 주세요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('voucherEdit.name')), findsOneWidget);
  });

  testWidgets(
    'hides the voucher editor unless a voucher is part of the reward',
    (tester) async {
      await _pump(tester, _Harness());
      await _next(tester);
      await tester.tap(find.text('조회수당 지급'));
      await tester.pumpAndSettle();
      expect(find.text('식사권 고치기'), findsNothing);

      await tester.tap(find.text('식사권 제공'));
      await tester.pumpAndSettle();
      expect(find.text('식사권 고치기'), findsOneWidget);
    },
  );

  testWidgets('sends no voucher fields for a per-view reward', (tester) async {
    final h = _Harness();
    await _pump(tester, h);
    await _next(tester);
    await tester.tap(find.text('조회수당 지급'));
    await tester.pumpAndSettle();
    await _next(tester);
    expect(find.text('조회 1회당 10원, 최대 10만 원'), findsOneWidget);
    await tester.tap(find.text('가게 공개하기'));
    await tester.pumpAndSettle();

    expect(
      h.submitted.single,
      const OfferTermsInput(
        format: ContentFormat.reels,
        rewardType: RewardType.perView,
      ),
    );
  });

  testWidgets('disables per-view rewards for a blog post', (tester) async {
    final h = _Harness();
    await _pump(tester, h);
    // 처음 고른 `식사권 + 조회수`가 블로그 글에서는 `식사권 제공`으로 바뀐다.
    await tester.tap(find.text('블로그 글'));
    await tester.pumpAndSettle();
    await _next(tester);

    expect(find.text('블로그 글은 조회수를 셀 수 없어요.'), findsOneWidget);
    await tester.tap(find.text('조회수당 지급'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('식사권 + 조회수'));
    await tester.pumpAndSettle();
    expect(find.text('식사권 고치기'), findsOneWidget);

    await _next(tester);
    expect(find.text('블로그 글 1편'), findsOneWidget);
    expect(find.text('2인 식사권 (약 4만 원)'), findsOneWidget);
    await tester.tap(find.text('가게 공개하기'));
    await tester.pumpAndSettle();
    expect(h.submitted.single.rewardType, RewardType.voucher);
  });

  testWidgets('shows the blog note only for a blog post', (tester) async {
    await _pump(tester, _Harness());
    await _next(tester);
    expect(find.text('블로그 글은 조회수를 셀 수 없어요.'), findsNothing);
  });

  testWidgets(
    'stays on the confirm step and shows an error when publishing fails',
    (tester) async {
      final h = _Harness()..fail = true;
      await _pump(tester, h);
      await _next(tester);
      await _next(tester);

      await tester.tap(find.text('가게 공개하기'));
      await tester.pumpAndSettle();

      expect(find.text('3 / 3'), findsOneWidget);
      expect(find.text('잠시 문제가 생겼어요. 다시 시도해 주세요.'), findsOneWidget);

      // 다시 누르면 다시 시도한다.
      h.fail = false;
      await tester.tap(find.text('가게 공개하기'));
      await tester.pumpAndSettle();
      expect(h.submitted, hasLength(2));
      expect(find.text('잠시 문제가 생겼어요. 다시 시도해 주세요.'), findsNothing);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'renders every step without overflow at 1.3x text (dark: $dark)',
      (tester) async {
        await _pump(
          tester,
          _Harness(),
          theme: dark ? coraDarkTheme : coraLightTheme,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        await _next(tester);
        expect(tester.takeException(), isNull);
        await _next(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
