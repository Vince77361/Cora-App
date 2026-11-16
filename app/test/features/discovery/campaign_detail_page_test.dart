import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/domain/campaign_detail.dart';
import 'package:cora/features/discovery/domain/discovery_card.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/discovery/presentation/pages/campaign_detail_page.dart';
import 'package:cora/features/principles/domain/principles.dart'
    show ProductTrialDays;
import 'package:cora/features/principles/domain/principles_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../principles/fake_principles_repository.dart';
import 'fake_discovery_repository.dart';

/// D1을 `/creator/campaigns/k1`에 올린다. 뒤로 갈 곳이 없으면 `/creator`(위치 글자만 보이는 빈 화면)로 간다.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakeDiscoveryRepository repo, {
  CampaignCard? card,
  ThemeData? theme,
  bool smallPhone = false,
}) async {
  if (smallPhone) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  } else {
    useCanvasPhone(tester);
  }
  final router = GoRouter(
    initialLocation: AppRoutes.creatorCampaign('k1'),
    routes: [
      GoRoute(
        path: AppRoutes.creator,
        builder: (context, state) => const Scaffold(body: Text('creator home')),
      ),
      GoRoute(
        path: AppRoutes.creatorCampaignPattern,
        builder: (context, state) =>
            CampaignDetailPage(campaignId: 'k1', card: card),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(repo),
        principlesRepositoryProvider.overrideWithValue(
          FakePrinciplesRepository(principles: defaultPrinciples),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

FakeDiscoveryRepository _repo([CampaignDetail? detail]) =>
    FakeDiscoveryRepository(campaignCards: [discoveryCampaign('k1')])
      ..details['k1'] = detail ?? campaignDetail('k1');

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the brand, the campaign line, the fee and the format', (
    tester,
  ) async {
    await _pump(tester, _repo());

    expect(find.text('모아 스튜디오, 느린 결 일상의 주얼리'), findsOneWidget);
    expect(find.text('나만의 아침 루틴 속 작은 포인트'), findsOneWidget);
    expect(find.text('30만 원'), findsOneWidget);
    expect(find.text('+ 제품 제공, 릴스 1편'), findsOneWidget);
    expect(find.text('넘기기'), findsOneWidget);
    expect(find.text('관심 보내기'), findsOneWidget);
  });

  testWidgets('a campaign without a product shows only the format', (
    tester,
  ) async {
    await _pump(tester, _repo(campaignDetail('k1', productProvided: false)));

    expect(find.text('릴스 1편'), findsOneWidget);
    expect(find.textContaining('제품 제공'), findsNothing);
  });

  testWidgets('campaign detail lists the overlap reasons and count', (
    tester,
  ) async {
    await _pump(tester, _repo());

    expect(find.text('나와 잘 맞는 이유'), findsOneWidget);
    expect(
      find.text('분야가 맞아요. 대본 조건이 맞아요. 제작비가 맞아요. 내 협업 원칙과 3개가 겹쳐요.'),
      findsOneWidget,
    );
  });

  testWidgets('campaign detail hides the reasons box when nothing overlaps', (
    tester,
  ) async {
    await _pump(tester, _repo(campaignDetail('k1', reasons: const [])));

    expect(find.text('나와 잘 맞는 이유'), findsNothing);
    expect(find.textContaining('겹쳐요'), findsNothing);
    // 나머지는 그대로 있다.
    expect(find.text('꼭 담을 것'), findsOneWidget);
  });

  testWidgets('lists what to include and what is not required', (tester) async {
    await _pump(tester, _repo());

    expect(find.text('꼭 담을 것'), findsOneWidget);
    for (final item in ['소재 정보', '광고 표시', '제품명 정확히']) {
      expect(find.text(item), findsOneWidget);
    }
    expect(find.text('요구하지 않아요'), findsOneWidget);
    for (final item in ['얼굴 출연', '정해진 대사', '대본 낭독']) {
      expect(find.text(item), findsOneWidget);
    }
  });

  testWidgets('says nothing is set when the include list is empty', (
    tester,
  ) async {
    await _pump(tester, _repo(campaignDetail('k1', mustInclude: const [])));

    expect(find.text('정해진 것이 없어요'), findsOneWidget);
  });

  testWidgets('shows the schedule and the trial days', (tester) async {
    await _pump(tester, _repo());

    expect(find.text('일정'), findsOneWidget);
    expect(find.text('11월 16일 이후'), findsOneWidget);
    expect(find.text('제품 사용'), findsOneWidget);
    expect(find.text('7일 먼저 사용'), findsOneWidget);
  });

  testWidgets('trial days of any length read as a free period', (tester) async {
    await _pump(
      tester,
      _repo(campaignDetail('k1', trialDays: ProductTrialDays.any)),
    );

    expect(find.text('기간 자유'), findsOneWidget);
  });

  testWidgets('pass sends the campaign pass and goes back', (tester) async {
    final repo = _repo();
    await _pump(tester, repo);

    await tester.tap(find.text('넘기기'));
    await tester.pumpAndSettle();

    expect(repo.decisions.single.target, const DiscoveryTarget.campaign('k1'));
    expect(repo.decisions.single.outcome, SwipeOutcome.pass);
    expect(find.text('creator home'), findsOneWidget);
  });

  testWidgets('sending interest sends the campaign like and goes back', (
    tester,
  ) async {
    final repo = _repo();
    await _pump(tester, repo);

    await tester.tap(find.text('관심 보내기'));
    await tester.pumpAndSettle();

    expect(repo.decisions.single.target, const DiscoveryTarget.campaign('k1'));
    expect(repo.decisions.single.outcome, SwipeOutcome.like);
    expect(find.text('creator home'), findsOneWidget);
  });

  testWidgets('a failed decision keeps the page and says to try again', (
    tester,
  ) async {
    final repo = _repo()..failDecide = true;
    await _pump(tester, repo);

    await tester.tap(find.text('관심 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('나만의 아침 루틴 속 작은 포인트'), findsOneWidget);
    expect(repo.decisions, isEmpty);
  });

  testWidgets('offers a retry when the detail cannot be loaded', (
    tester,
  ) async {
    final repo = _repo()..failDetail = true;
    await _pump(tester, repo);

    expect(find.text('캠페인을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('넘기기'), findsNothing);

    repo.failDetail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('30만 원'), findsOneWidget);
  });

  testWidgets('the card from 08 shows the header while the detail fails', (
    tester,
  ) async {
    final repo = _repo()..failDetail = true;
    await _pump(tester, repo, card: discoveryCampaign('k1'));

    expect(find.text('모아 스튜디오, 느린 결 일상의 주얼리'), findsOneWidget);
    expect(find.text('캠페인을 불러오지 못했어요'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Hero && w.tag == 'campaign:k1',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('back returns to the creator home', (tester) async {
    await _pump(tester, _repo());

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(find.text('creator home'), findsOneWidget);
  });

  testWidgets('uses the dark canvas colors in dark mode', (tester) async {
    await _pump(tester, _repo(), theme: coraDarkTheme);

    Color? boxColor(String text) {
      for (final box in tester.widgetList<DecoratedBox>(
        find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)),
      )) {
        final d = box.decoration;
        if (d is BoxDecoration && d.color != null) return d.color;
      }
      return null;
    }

    // 상자 #1C1E22, 두 버튼은 `넘기기` #1C1E22와 라임 #C6FF3D.
    expect(boxColor('꼭 담을 것'), const Color(0xFF1C1E22));
    expect(boxColor('일정'), const Color(0xFF1C1E22));
    expect(boxColor('넘기기'), const Color(0xFF1C1E22));
    expect(boxColor('관심 보내기'), const Color(0xFFC6FF3D));
    expect(CoraColors.dark.textSecondary, const Color(0xFFA0A4AD));
  });

  testWidgets('does not overflow at 1.3x text scale on a small phone', (
    tester,
  ) async {
    await _pump(tester, _repo(), smallPhone: true);

    expect(tester.takeException(), isNull);
    expect(find.text('관심 보내기'), findsOneWidget);
  });
}
