import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/brand_onboarding/domain/brand_repository.dart';
import 'package:cora/features/brand_onboarding/domain/campaign_repository.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/discovery/domain/reward_proposal.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:cora/features/interests/domain/compare_result.dart';
import 'package:cora/features/interests/domain/interest_card.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/interests/presentation/pages/compare_page.dart';
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../brand_onboarding/fake_brand_repository.dart';
import '../brand_onboarding/fake_campaign_repository.dart';
import '../discovery/fake_discovery_repository.dart';
import '../server_config/fake_server_config_repository.dart';
import 'fake_interests_repository.dart';

/// 04를 `/brand/interests/compare?a=c1&b=c2`에 올린다. 04가 여는 경로는 위치 글자만 보이는 빈 화면이고 위치를
/// 기록한다. 그 아래에 03 자리 화면이 있어 뒤로 가기가 돌아갈 곳이 있다.
Future<List<String>> _pump(
  WidgetTester tester,
  FakeInterestsRepository repo, {
  ThemeData? theme,
  FakeDiscoveryRepository? discovery,
}) async {
  useCanvasPhone(tester);
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: AppRoutes.brandInterests,
    routes: [
      GoRoute(
        path: AppRoutes.brandInterests,
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push(AppRoutes.brandCompare('c1', 'c2')),
              child: const Text('open compare'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.brandComparePattern,
        builder: (context, state) => ComparePage(
          a: state.uri.queryParameters['a']!,
          b: state.uri.queryParameters['b']!,
        ),
      ),
      GoRoute(
        path: '/collaborations/:id/terms',
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: '/brand/coming-soon/:title',
        builder: (context, state) => stub(state),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        interestsRepositoryProvider.overrideWithValue(repo),
        // 보상 제안 흐름(F1, F2)이 읽고 보내는 저장소.
        discoveryRepositoryProvider.overrideWithValue(
          discovery ?? FakeDiscoveryRepository(),
        ),
        campaignRepositoryProvider.overrideWithValue(
          FakeCampaignRepository(active: defaultCampaign),
        ),
        brandRepositoryProvider.overrideWithValue(
          FakeBrandRepository(profile: defaultBrandProfile),
        ),
        serverConfigRepositoryProvider.overrideWithValue(
          FakeServerConfigRepository(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open compare'));
  await tester.pumpAndSettle();
  return opened;
}

/// 캔버스 Compare의 견본: 서윤(서로 관심)과 민(응답 대기). 다른 줄은 현금 고정비, 사용권, 촬영 가능일, 얼굴 출연.
FakeInterestsRepository _canvas() => FakeInterestsRepository(
  compareResult: CompareResult(
    sides: [
      compareSide(
        'c1',
        name: '서윤의 작은 취향',
        shortName: '서윤',
        state: InterestState.mutual,
        fee: 300000,
        startDate: DateTime(2026, 11, 16),
        faceOk: false,
      ),
      compareSide(
        'c2',
        name: '민의 옷장 기록',
        shortName: '민',
        fee: 350000,
        usage: BrandUsageRights.adsToo,
        faceOk: true,
      ),
    ],
    differs: {
      CompareRow.fee,
      CompareRow.usage,
      CompareRow.start,
      CompareRow.face,
    },
  ),
);

Finder _dots() => find.bySemanticsLabel('조건이 달라요');

void main() {
  setUpAll(loadAppFonts);

  testWidgets('compare shows the seven rows with the canvas labels', (
    tester,
  ) async {
    await _pump(tester, _canvas());

    expect(find.text('후보 비교'), findsOneWidget);
    for (final label in [
      '결과물',
      '혜택',
      '현금 고정비',
      '성과 상한',
      '사용권',
      '촬영 가능일',
      '얼굴 출연',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('서로 관심'), findsOneWidget);
    expect(find.text('민의 옷장 기록'), findsOneWidget);
    expect(find.text('응답 대기'), findsOneWidget);
    // 결과물과 혜택과 성과 상한은 두 후보가 같다.
    expect(find.text('릴스 1편 · 30초'), findsNWidgets(2));
    expect(find.text('제품 제공'), findsNWidgets(2));
    expect(find.text('없음'), findsWidgets);
    expect(find.text('30만 원'), findsOneWidget);
    expect(find.text('35만 원'), findsOneWidget);
    expect(find.text('브랜드 계정 재게시'), findsOneWidget);
    expect(find.text('재게시 + 광고'), findsOneWidget);
    expect(find.text('11월 16일 이후'), findsOneWidget);
    expect(find.text('일정 협의'), findsOneWidget);
    expect(
      find.text('같은 결과물 기준으로 맞췄어요. 점 표시는 조건이 다른 항목이에요. 팔로워 수는 비교하지 않아요.'),
      findsOneWidget,
    );
  });

  testWidgets('compare marks only the differing rows with a dot', (
    tester,
  ) async {
    await _pump(tester, _canvas());

    expect(_dots(), findsNWidgets(4));
    // 점이 붙은 줄은 두 값이 굵다(700), 아닌 줄은 보통(400)이다.
    FontWeight? weightOf(String text) =>
        tester.widget<Text>(find.text(text).first).style?.fontWeight;
    expect(weightOf('30만 원'), FontWeight.w700);
    expect(weightOf('35만 원'), FontWeight.w700);
    expect(weightOf('브랜드 계정 재게시'), FontWeight.w700);
    expect(weightOf('릴스 1편 · 30초'), FontWeight.w400);
    expect(weightOf('제품 제공'), FontWeight.w400);
  });

  testWidgets('compare shows no dots when nothing differs', (tester) async {
    final repo = FakeInterestsRepository(
      compareResult: CompareResult(
        sides: [compareSide('c1'), compareSide('c2')],
        differs: const {},
      ),
    );
    await _pump(tester, repo);

    expect(_dots(), findsNothing);
  });

  testWidgets('compare shows no follower counts', (tester) async {
    await _pump(tester, _canvas());

    // 안내 문구 하나뿐이다.
    expect(find.textContaining('팔로워'), findsOneWidget);
  });

  testWidgets('compare falls back to the fee band and the cap labels', (
    tester,
  ) async {
    final repo = FakeInterestsRepository(
      compareResult: CompareResult(
        sides: [
          compareSide('c1', feeBand: FeeBand.w300k, perfCap: 60000),
          compareSide(
            'c2',
            feeBand: FeeBand.w400k,
            productProvided: false,
            usage: BrandUsageRights.none,
          ),
        ],
        differs: const {CompareRow.fee},
      ),
    );
    await _pump(tester, repo);

    // 정해진 금액이 없으면 희망 제작비 구간이다.
    expect(find.text('30만 원대'), findsOneWidget);
    expect(find.text('40만 원대'), findsOneWidget);
    expect(find.text('6만 원'), findsOneWidget);
    expect(find.text('사용 안 함'), findsOneWidget);
    expect(find.text('없음'), findsWidgets);
  });

  testWidgets('compare offers to propose to a waiting candidate and to view a '
      'mutual one', (tester) async {
    final opened = await _pump(tester, _canvas());

    expect(find.text('민에게 제안'), findsOneWidget);
    expect(find.text('서윤의 제안 보기'), findsOneWidget);

    await tester.tap(find.text('서윤의 제안 보기'));
    await tester.pumpAndSettle();
    expect(opened, ['/collaborations/collab-c1/terms']);
  });

  testWidgets('the mutual candidate has the strong button on the right', (
    tester,
  ) async {
    await _pump(tester, _canvas());

    final quiet = tester.getCenter(find.text('민에게 제안'));
    final strong = tester.getCenter(find.text('서윤의 제안 보기'));
    expect(strong.dx, greaterThan(quiet.dx));
    // 강조 버튼의 폭이 1.6배다(캔버스 flex 1 : 1.6).
    final quietBox = find.ancestor(
      of: find.text('민에게 제안'),
      matching: find.byType(DecoratedBox),
    );
    final strongBox = find.ancestor(
      of: find.text('서윤의 제안 보기'),
      matching: find.byType(DecoratedBox),
    );
    expect(
      tester.getSize(strongBox.first).width /
          tester.getSize(quietBox.first).width,
      closeTo(1.6, 0.01),
    );
  });

  testWidgets('proposing from compare sends a like with the proposal', (
    tester,
  ) async {
    final discovery = FakeDiscoveryRepository();
    final repo = _canvas();
    await _pump(tester, repo, discovery: discovery);

    await tester.tap(find.text('민에게 제안'));
    await tester.pumpAndSettle();

    // F1: 내가 이미 만든 제안(35만 원, 제품 제공)에서 시작하고, 성과 추가는 꺼져 있다.
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('현금 고정비'), findsOneWidget);
    expect(find.text('350,000원'), findsOneWidget);
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();

    // F2: 받는 사람은 후보, 모집 줄은 브랜드와 캠페인 한 줄이다.
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('민의 옷장 기록'), findsWidgets);
    expect(find.text('느린 결 · 나만의 아침 루틴 속 작은 포인트'), findsOneWidget);
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    final sent = discovery.decisions.single;
    expect(sent.target, DiscoveryTarget.creator('c2'));
    expect(sent.outcome, SwipeOutcome.like);
    expect(
      sent.proposal,
      const RewardProposal(fee: 350000, productProvided: true),
    );
    // 흐름이 닫히고 04에 보냈다는 안내가 뜬 채 표를 다시 읽는다.
    expect(find.text('1 / 2'), findsNothing);
    expect(find.text('민의 옷장 기록에게 제안을 보냈어요. 상대도 고르면 알려드려요.'), findsOneWidget);
    expect(repo.compared, hasLength(2));
  });

  testWidgets('reopening a saved proposal keeps its rate and cap', (
    tester,
  ) async {
    final discovery = FakeDiscoveryRepository();
    final repo = FakeInterestsRepository(
      compareResult: CompareResult(
        sides: [
          compareSide('c1', name: '서윤의 작은 취향', shortName: '서윤'),
          // 단가 3,000원, 상한 90,000원으로 보낸 제안(기본 단가 2,000원과 다르다).
          compareSide(
            'c2',
            name: '민의 옷장 기록',
            shortName: '민',
            fee: 350000,
            perfRate: 3000,
            perfCap: 90000,
          ),
        ],
        differs: const {},
      ),
    );
    await _pump(tester, repo, discovery: discovery);

    await tester.tap(find.text('민에게 제안'));
    await tester.pumpAndSettle();
    expect(find.text('1,000회당 3,000원'), findsOneWidget);
    expect(find.text('최대 90,000원'), findsOneWidget);
    // 제작비만 고쳐 다시 보내도 저장된 단가가 그대로 간다.
    await tester.tap(find.text('50만 원'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(
      discovery.decisions.single.proposal,
      const RewardProposal(
        fee: 500000,
        productProvided: true,
        performance: (ratePer1000: 3000, cap: 90000),
      ),
    );
  });

  testWidgets('the proposal starts from the campaign when none was made yet', (
    tester,
  ) async {
    final repo = FakeInterestsRepository(
      compareResult: CompareResult(
        sides: [
          compareSide('c1', name: '서윤의 작은 취향', shortName: '서윤'),
          compareSide('c2', name: '민의 옷장 기록', shortName: '민'),
        ],
        differs: const {},
      ),
    );
    await _pump(tester, repo);

    await tester.tap(find.text('민에게 제안'));
    await tester.pumpAndSettle();

    // 캠페인의 제작비 30만 원과 제품 제공에서 시작한다.
    expect(find.text('300,000원'), findsOneWidget);
    expect(find.text('제품 제공'), findsOneWidget);
  });

  testWidgets('a failed proposal stays on the review screen with the message', (
    tester,
  ) async {
    final discovery = FakeDiscoveryRepository()..failDecide = true;
    await _pump(tester, _canvas(), discovery: discovery);

    await tester.tap(find.text('민에게 제안'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('잠시 문제가 생겼어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.textContaining('제안을 보냈어요'), findsNothing);
  });

  testWidgets('a proposal that makes an instant mutual interest says so', (
    tester,
  ) async {
    // 상대가 이미 관심을 보낸 후보라 이 제안으로 바로 서로 관심이 닿는다.
    final discovery = FakeDiscoveryRepository()..matchOn.add('c2');
    final repo = _canvas();
    await _pump(tester, repo, discovery: discovery);

    await tester.tap(find.text('민에게 제안'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('민의 옷장 기록과 서로 관심이 닿았어요.'), findsOneWidget);
    expect(find.textContaining('상대도 고르면'), findsNothing);
    // 표를 다시 읽는다.
    expect(repo.compared, hasLength(2));
  });

  testWidgets('with the same state on both sides the left candidate gets the '
      'strong button', (tester) async {
    final repo = FakeInterestsRepository(
      compareResult: CompareResult(
        sides: [
          compareSide('c1', name: '서윤의 작은 취향', shortName: '서윤'),
          compareSide('c2', name: '민의 옷장 기록', shortName: '민'),
        ],
        differs: const {},
      ),
    );
    await _pump(tester, repo);

    // 서로 관심이 아닌 둘이다. 왼쪽 후보(서윤)의 버튼이 오른쪽의 강조 버튼이다.
    final left = tester.getCenter(find.text('민에게 제안'));
    final right = tester.getCenter(find.text('서윤에게 제안'));
    expect(right.dx, greaterThan(left.dx));
  });

  testWidgets('when only the right candidate is mutual its button is strong '
      'and stays on the right', (tester) async {
    final repo = FakeInterestsRepository(
      compareResult: CompareResult(
        sides: [
          compareSide('c1', name: '민의 옷장 기록', shortName: '민'),
          compareSide(
            'c2',
            name: '서윤의 작은 취향',
            shortName: '서윤',
            state: InterestState.mutual,
          ),
        ],
        differs: const {},
      ),
    );
    await _pump(tester, repo);

    expect(
      tester.getCenter(find.text('서윤의 제안 보기')).dx,
      greaterThan(tester.getCenter(find.text('민에게 제안')).dx),
    );
  });

  testWidgets('the back button returns to the interests screen', (
    tester,
  ) async {
    await _pump(tester, _canvas());

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(find.text('open compare'), findsOneWidget);
  });

  testWidgets('a failed read can be retried', (tester) async {
    final repo = _canvas()..failCompare = true;
    await _pump(tester, repo);

    expect(find.text('후보 비교를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('후보 비교'), findsOneWidget);

    repo.failCompare = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('릴스 1편 · 30초'), findsNWidgets(2));
    expect(repo.compared, hasLength(2));
  });

  testWidgets('asks the repository for the two ids in the route order', (
    tester,
  ) async {
    final repo = _canvas();
    await _pump(tester, repo);

    expect(repo.compared, [(a: 'c1', b: 'c2')]);
  });

  testWidgets('the dark theme uses the canvas dark colors for the table', (
    tester,
  ) async {
    await _pump(tester, _canvas(), theme: coraDarkTheme);

    // 캔버스 DarkCompare: 줄 구분선 #2A2D33, 라벨 #A0A4AD, 왼쪽 버튼 바탕 #2A2D33.
    expect(CoraColors.dark.line, const Color(0xFF2A2D33));
    expect(CoraColors.dark.textSecondary, const Color(0xFFA0A4AD));
    expect(CoraColors.dark.subtleAction, const Color(0xFF2A2D33));
    final label = tester.widget<Text>(find.text('결과물'));
    expect(label.style?.color, CoraColors.dark.textSecondary);
    // 점은 캔버스 그대로 두 모드가 같은 #17181C다.
    expect(CoraColors.dark.compareDot, const Color(0xFF17181C));
    expect(CoraColors.light.compareDot, const Color(0xFF17181C));
  });
}
