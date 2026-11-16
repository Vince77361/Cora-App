import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_glass_card.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/principles/domain/principle_questions.dart';
import 'package:cora/features/principles/domain/principles.dart';
import 'package:cora/features/principles/domain/principles_repository.dart';
import 'package:cora/features/principles/presentation/pages/principles_page.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_principles_repository.dart';

/// 09를 `/creator/principles`에 올리고, `/creator`는 갔는지만 보이는 빈 화면으로 둔다.
Future<GoRouter> _pump(
  WidgetTester tester, {
  FakePrinciplesRepository? repo,
  ThemeData? theme,
  TextScaler? textScaler,
  bool canvasSize = true,
}) async {
  if (canvasSize) {
    useCanvasPhone(tester);
  } else {
    usePhone(tester);
  }
  final router = GoRouter(
    initialLocation: AppRoutes.creatorPrinciples,
    routes: [
      GoRoute(
        path: AppRoutes.creatorPrinciples,
        builder: (context, state) => const PrinciplesPage(),
      ),
      GoRoute(
        path: AppRoutes.creator,
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        principlesRepositoryProvider.overrideWithValue(
          repo ?? FakePrinciplesRepository(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: app!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _tapOption(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byType(CoraPrimaryButton));
  await tester.pumpAndSettle();
}

CoraPrimaryButton _nextButton(WidgetTester tester) =>
    tester.widget<CoraPrimaryButton>(find.byType(CoraPrimaryButton));

/// 일곱 질문에 차례로 답해 요약까지 간다. 2번(피하는 업종)은 건너뛴다.
Future<void> _answerAll(WidgetTester tester) async {
  await _tapOption(tester, '뷰티·미용');
  await _next(tester);
  await _next(tester); // 2번은 고르지 않아도 된다.
  await _tapOption(tester, '괜찮아요');
  await _next(tester);
  await _tapOption(tester, '내 말투로 할래요');
  await _next(tester);
  await _tapOption(tester, '솔직하게 말할래요');
  await _next(tester);
  await _tapOption(tester, '30만 원대');
  await _next(tester);
  await _tapOption(tester, '14일');
  await _next(tester);
}

void main() {
  setUpAll(loadAppFonts);

  test('has seven questions with the canvas copy', () {
    final qs = principleQuestions;
    expect(qs.length, 7);
    expect(qs.map((q) => q.kicker), [
      '함께하고 싶은 분야',
      '제안받지 않을 업종',
      '촬영 방식',
      '말하는 방식',
      '후기 방식',
      '희망 제작비',
      '제품 사용 기간',
    ]);
    expect(qs.map((q) => q.title), [
      '어떤 분야의\n제안을 받고 싶나요?',
      '피하고 싶은\n업종이 있나요?',
      '얼굴이 나오는\n촬영도 괜찮나요?',
      '정해진 대본을\n읽는 건 어때요?',
      '단점도 솔직하게\n말해도 될까요?',
      '릴스 1편에\n얼마를 생각하나요?',
      '제품은 얼마나\n써보고 찍고 싶나요?',
    ]);
    expect(qs.map((q) => q.hint), [
      '여러 개 골라도 돼요.',
      '고른 업종의 브랜드에게는 내 프로필이 보이지 않아요.',
      '손이나 소품 중심으로만 찍고 싶다면 알려주세요.',
      '브랜드의 필수 정보는 어느 쪽이든 정확히 담아요.',
      '브랜드가 제안 전에 미리 알 수 있게 보여줘요.',
      '협의로 바뀔 수 있어요.',
      '배송 일정을 정할 때 함께 보여요.',
    ]);
    expect(qs.map((q) => q.multi), [
      true,
      true,
      false,
      false,
      false,
      false,
      false,
    ]);
    // 1번은 일반 업종 아홉 개(맛집·카페가 첫 번째), 2번은 민감 업종 네 개.
    expect(qs[0].options.length, 9);
    expect(qs[0].options.first.label, '맛집·카페');
    expect(qs[0].options.map((o) => o.label), [
      for (final c in IndustryCategory.values.take(9)) c.label,
    ]);
    expect(qs[1].options.map((o) => o.label), [
      '도박·사행성',
      '대출',
      '주류',
      '다이어트 보조제',
    ]);
    // 캔버스에 있는 보조 글만 붙는다.
    final subs = {for (final o in qs[0].options) o.label: o.sub};
    expect(subs['액세서리·주얼리'], '반지, 팔찌, 시계');
    expect(subs['리빙·소품'], '컵, 조명, 향');
    expect(subs['맛집·카페'], '');
    expect(qs[2].options.map((o) => (o.label, o.sub)), [
      ('얼굴 없이 할래요', '손·소품 중심'),
      ('괜찮아요', '얼굴 출연 가능'),
    ]);
    expect(qs[5].options.map((o) => o.label), [
      '20만 원대',
      '30만 원대',
      '40만 원대',
      '50만 원 이상',
    ]);
    expect(qs[6].options.map((o) => o.label), ['3일', '7일', '14일', '상관없어요']);
  });

  test('summary labels follow the canvas and only question 2 differs', () {
    final qs = principleQuestions;
    expect(qs.map((q) => q.summaryLabel), [
      '함께하고 싶은 분야',
      '피하는 업종',
      '촬영 방식',
      '말하는 방식',
      '후기 방식',
      '희망 제작비',
      '제품 사용 기간',
    ]);
    // 질문 화면의 머리말은 그대로다.
    expect(qs[1].kicker, '제안받지 않을 업종');
  });

  testWidgets('question 2 keeps its kicker and the summary calls it avoided', (
    tester,
  ) async {
    await _pump(tester);
    await _tapOption(tester, '맛집·카페');
    await _next(tester);

    expect(find.text('제안받지 않을 업종'), findsOneWidget);
    expect(find.text('피하는 업종'), findsNothing);
  });

  testWidgets('the question area is clipped at the card edge', (tester) async {
    await _pump(tester);

    // 스크롤 영역의 아래 끝이 카드 아래 끝과 같아, 선택지가 둥근 모서리에서 잘린다.
    final card = tester.getRect(find.byType(CoraGlassCard));
    final scroll = tester.getRect(
      find.descendant(
        of: find.byType(CoraGlassCard),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(scroll.bottom, card.bottom);
  });

  testWidgets('shows the first question with the canvas header', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('나의 협업 원칙'), findsOneWidget);
    expect(find.text('나중에'), findsOneWidget);
    expect(find.text('함께하고 싶은 분야'), findsOneWidget);
    expect(find.text('1 / 7 단계'), findsOneWidget);
    expect(find.text('질문'), findsOneWidget);
    expect(find.text('어떤 분야의\n제안을 받고 싶나요?'), findsOneWidget);
    expect(find.text('여러 개 골라도 돼요.'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
    expect(find.text('반지, 팔찌, 시계'), findsOneWidget);
  });

  testWidgets('lays out like the canvas at 390 x 844', (tester) async {
    await _pump(tester);

    // 카드: left 16, right 16, top 76, bottom 112. 아래 버튼: 좌우 16, 아래 32, 높이 58.
    final card = tester.getRect(find.byType(CoraGlassCard));
    expect(card.left, 16);
    expect(card.right, 374);
    expect(card.top, 76);
    expect(card.bottom, 732);
    final button = tester.getRect(find.byType(CoraPrimaryButton));
    expect(button.left, 16);
    expect(button.right, 374);
    expect(button.bottom, 812);
    expect(button.height, 58);
    // 선택지: 카드 안쪽 여백 18, 높이 56 이상, 사이 8.
    final first = tester.getRect(find.byKey(PrinciplesPage.optionKey(0)));
    final second = tester.getRect(find.byKey(PrinciplesPage.optionKey(1)));
    expect(first.left, 34);
    expect(first.right, 356);
    expect(first.height, greaterThanOrEqualTo(56));
    expect(second.top - first.bottom, 8);
  });

  testWidgets('next is disabled until an option is picked', (tester) async {
    await _pump(tester);
    expect(_nextButton(tester).onPressed, isNull);

    await _tapOption(tester, '맛집·카페');

    expect(_nextButton(tester).onPressed, isNotNull);
    // 눌러 둔 것을 다시 누르면 비워지고 다시 꺼진다.
    await _tapOption(tester, '맛집·카페');
    expect(_nextButton(tester).onPressed, isNull);
  });

  testWidgets('the blocked industries question can be skipped', (tester) async {
    await _pump(tester);
    await _tapOption(tester, '맛집·카페');
    await _next(tester);

    expect(find.text('2 / 7 단계'), findsOneWidget);
    expect(find.text('고른 업종의 브랜드에게는 내 프로필이 보이지 않아요.'), findsOneWidget);
    expect(_nextButton(tester).onPressed, isNotNull);

    await _next(tester);
    expect(find.text('3 / 7 단계'), findsOneWidget);
    // 3번부터는 하나 이상 골라야 켜진다.
    expect(_nextButton(tester).onPressed, isNull);
  });

  testWidgets('multi-select questions toggle several options', (tester) async {
    await _pump(tester);

    await _tapOption(tester, '맛집·카페');
    await _tapOption(tester, '패션');
    await _tapOption(tester, '식품');
    await _tapOption(tester, '패션');
    await _next(tester);
    await _next(tester);
    await _tapOption(tester, '괜찮아요');
    await _next(tester);
    await _tapOption(tester, '대본도 괜찮아요');
    await _next(tester);
    await _tapOption(tester, '좋은 점 위주로');
    await _next(tester);
    await _tapOption(tester, '20만 원대');
    await _next(tester);
    await _tapOption(tester, '3일');
    await _next(tester);

    // 고른 두 분야가 눌러 고른 순서대로 요약에 이어 붙는다.
    expect(find.text('맛집·카페, 식품'), findsOneWidget);
  });

  testWidgets('single-select questions keep one option', (tester) async {
    await _pump(tester);
    await _tapOption(tester, '맛집·카페');
    await _next(tester);
    await _next(tester);

    await _tapOption(tester, '얼굴 없이 할래요');
    await _tapOption(tester, '괜찮아요');
    await _next(tester);
    await _tapOption(tester, '내 말투로 할래요');
    await _next(tester);
    await _tapOption(tester, '솔직하게 말할래요');
    await _next(tester);
    await _tapOption(tester, '20만 원대');
    await _next(tester);
    await _tapOption(tester, '3일');
    await _next(tester);

    expect(find.text('괜찮아요'), findsOneWidget);
    expect(find.text('얼굴 없이 할래요'), findsNothing);
  });

  testWidgets('the last question says it is done and shows the summary', (
    tester,
  ) async {
    final repo = FakePrinciplesRepository();
    await _pump(tester, repo: repo);
    await _tapOption(tester, '뷰티·미용');
    await _next(tester);
    await _next(tester);
    await _tapOption(tester, '괜찮아요');
    await _next(tester);
    await _tapOption(tester, '내 말투로 할래요');
    await _next(tester);
    await _tapOption(tester, '솔직하게 말할래요');
    await _next(tester);
    await _tapOption(tester, '30만 원대');
    await _next(tester);
    await _tapOption(tester, '14일');
    // 마지막 질문의 버튼 이름.
    expect(find.text('다 골랐어요'), findsOneWidget);
    expect(find.text('다음'), findsNothing);
    await _next(tester);

    expect(find.text('모두 골랐어요'), findsOneWidget);
    expect(find.text('7 / 7 단계'), findsOneWidget);
    expect(find.text('나답게 일하는 기준이\n완성됐어요.'), findsOneWidget);
    expect(find.text('프로필과 받은 제안에 이 기준이 함께 보여요.'), findsOneWidget);
    expect(find.text('다시 고르기'), findsOneWidget);
    expect(find.text('저장하고 캠페인 보기'), findsOneWidget);
    // 일곱 칸의 이름은 캔버스 요약 글자 그대로다(2번만 머리말과 달리 `피하는 업종`).
    for (final label in [
      '함께하고 싶은 분야',
      '피하는 업종',
      '촬영 방식',
      '말하는 방식',
      '후기 방식',
      '희망 제작비',
      '제품 사용 기간',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    // 머리말 `제안받지 않을 업종`은 1번 칸 위의 질문 화면에만 있고 요약에는 없다.
    expect(find.text('제안받지 않을 업종'), findsNothing);
    expect(find.text('뷰티·미용'), findsOneWidget);
    expect(find.text('고르지 않음'), findsOneWidget);
    expect(find.text('30만 원대'), findsOneWidget);
    expect(find.text('14일'), findsOneWidget);
  });

  testWidgets('shows the summary and saves', (tester) async {
    final repo = FakePrinciplesRepository();
    final router = await _pump(tester, repo: repo);
    await _answerAll(tester);

    await tester.tap(find.text('저장하고 캠페인 보기'));
    await tester.pumpAndSettle();

    expect(repo.saveCalls, 1);
    expect(
      repo.saved,
      const Principles(
        fields: [IndustryCategory.beauty],
        blockedIndustries: [],
        faceOk: true,
        scriptOk: false,
        honestReview: true,
        feeBand: FeeBand.w300k,
        trialDays: ProductTrialDays.d14,
      ),
    );
    expect(router.state.uri.path, AppRoutes.creator);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a failed save keeps the summary and says so', (tester) async {
    final repo = FakePrinciplesRepository()..failSave = true;
    final router = await _pump(tester, repo: repo);
    await _answerAll(tester);

    await tester.tap(find.text('저장하고 캠페인 보기'));
    await tester.pumpAndSettle();

    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.creatorPrinciples);
    expect(find.text('저장하고 캠페인 보기'), findsOneWidget);

    // 다시 누르면 다시 저장한다.
    repo.failSave = false;
    await tester.tap(find.text('저장하고 캠페인 보기'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.creator);
  });

  testWidgets('pick again returns to the first question keeping the picks', (
    tester,
  ) async {
    await _pump(tester);
    await _answerAll(tester);

    await tester.tap(find.text('다시 고르기'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 7 단계'), findsOneWidget);
    // 고른 것이 그대로 있어 `다음`이 켜져 있다.
    expect(_nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('the back arrow is dimmed on the first question and goes back', (
    tester,
  ) async {
    await _pump(tester);
    Opacity back() => tester.widget<Opacity>(
      find.descendant(
        of: find.bySemanticsLabel('이전 질문'),
        matching: find.byType(Opacity),
      ),
    );
    expect(back().opacity, 0.3);

    await _tapOption(tester, '맛집·카페');
    await _next(tester);
    expect(find.text('2 / 7 단계'), findsOneWidget);
    expect(back().opacity, 1);

    await tester.tap(find.bySemanticsLabel('이전 질문'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 7 단계'), findsOneWidget);
  });

  testWidgets('later leaves without saving', (tester) async {
    final repo = FakePrinciplesRepository();
    final router = await _pump(tester, repo: repo);
    await _tapOption(tester, '맛집·카페');

    await tester.tap(find.byKey(PrinciplesPage.laterKey));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.creator);
    expect(repo.saveCalls, 0);
  });

  testWidgets('loads saved principles for editing', (tester) async {
    final repo = FakePrinciplesRepository(
      principles: const Principles(
        fields: [IndustryCategory.accessory, IndustryCategory.living],
        blockedIndustries: [IndustryCategory.loan],
        faceOk: false,
        scriptOk: true,
        honestReview: false,
        feeBand: FeeBand.w500kPlus,
        trialDays: ProductTrialDays.any,
      ),
    );
    await _pump(tester, repo: repo);

    // 첫 질문에서 저장된 분야가 이미 골라져 있다.
    expect(_nextButton(tester).onPressed, isNotNull);
    final selected = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byKey(PrinciplesPage.optionKey(3)),
        matching: find.byType(Semantics),
      ),
    );
    expect(selected.any((s) => s.properties.selected == true), isTrue);

    // 끝까지 가면 저장된 값이 요약에 그대로 보인다.
    await _next(tester);
    await _next(tester);
    await _next(tester);
    await _next(tester);
    await _next(tester);
    await _next(tester);
    await _next(tester);
    expect(find.text('액세서리·주얼리, 리빙·소품'), findsOneWidget);
    expect(find.text('대출'), findsOneWidget);
    expect(find.text('얼굴 없이 할래요'), findsOneWidget);
    expect(find.text('대본도 괜찮아요'), findsOneWidget);
    expect(find.text('좋은 점 위주로'), findsOneWidget);
    expect(find.text('50만 원 이상'), findsOneWidget);
    expect(find.text('상관없어요'), findsOneWidget);
  });

  testWidgets('shows a retry when the saved principles cannot be loaded', (
    tester,
  ) async {
    final repo = FakePrinciplesRepository()..failFetch = true;
    await _pump(tester, repo: repo);

    expect(find.text('협업 원칙을 불러오지 못했어요'), findsOneWidget);
    expect(find.byType(CoraPrimaryButton), findsNothing);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 7 단계'), findsOneWidget);
  });

  testWidgets('the progress bar fill follows the canvas', (tester) async {
    await _pump(tester);
    Rect fill() => tester.getRect(find.byKey(PrinciplesPage.progressFillKey));
    // 질문 안쪽 너비 322(= 358 - 18 x 2)에서 1 / 7은 반올림한 14%다.
    expect(fill().width, closeTo(322 * 0.14, 0.01));
    expect(fill().height, 4);

    await _tapOption(tester, '맛집·카페');
    await _next(tester);
    expect(fill().width, closeTo(322 * 0.29, 0.01));
  });

  testWidgets(
    'the progress bar fill uses the light foreground token in dark mode',
    (tester) async {
      await _pump(tester, theme: coraDarkTheme);

      final fill = tester.widget<ColoredBox>(
        find.byKey(PrinciplesPage.progressFillKey),
      );
      // DarkPrinciples #F2F3F5. 옛 캔버스의 #0F1012(배경색)가 아니다.
      expect(fill.color, const Color(0xFFF2F3F5));
      expect(fill.color, CoraColors.dark.text);
      expect(fill.color, isNot(CoraColors.dark.background));
    },
  );

  testWidgets('light mode keeps the dark progress fill', (tester) async {
    await _pump(tester);
    final fill = tester.widget<ColoredBox>(
      find.byKey(PrinciplesPage.progressFillKey),
    );
    expect(fill.color, const Color(0xFF17181C));
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _pump(
      tester,
      textScaler: const TextScaler.linear(1.3),
      canvasSize: false,
    );
    expect(tester.takeException(), isNull);

    await _tapOption(tester, '맛집·카페');
    await _next(tester);
    await _next(tester);
    await _tapOption(tester, '괜찮아요');
    await _next(tester);
    await _tapOption(tester, '대본도 괜찮아요');
    await _next(tester);
    await _tapOption(tester, '좋은 점 위주로');
    await _next(tester);
    await _tapOption(tester, '50만 원 이상');
    await _next(tester);
    await _tapOption(tester, '상관없어요');
    await _next(tester);
    expect(find.text('나답게 일하는 기준이\n완성됐어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the first question scrolls inside the card with nine options', (
    tester,
  ) async {
    await _pump(tester);

    // 아홉 번째 선택지는 카드 아래로 넘쳐서 스크롤해야 닿는다.
    await tester.scrollUntilVisible(
      find.text('기타'),
      100,
      scrollable: find.descendant(
        of: find.byType(CoraGlassCard),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('기타'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
