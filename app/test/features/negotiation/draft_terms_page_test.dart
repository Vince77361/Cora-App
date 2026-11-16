import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/discovery/domain/discovery_card.dart'
    show MatchReason;
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/onboarding/domain/me_repository_provider.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/negotiation/presentation/viewmodels/brand_collaborations_view_model.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/negotiation/domain/terms_version.dart';
import 'package:cora/features/negotiation/presentation/pages/draft_terms_page.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart' show ViewPay;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../onboarding/fake_me_repository.dart';
import 'fake_negotiation_repository.dart';

const _id = 'c0ffee11-aaaa-bbbb-cccc-000000000001';

/// 06을 `/collaborations/:id/terms`에 올린다. 06이 여는 경로(07, 준비 중 화면, 인스타그램 연동)는 위치 글자만
/// 보이는 빈 화면이고 위치를 기록한다. [fromProgress]면 07 자리의 화면에서 06을 `push`한 것처럼 연다.
Future<List<String>> _pump(
  WidgetTester tester,
  FakeNegotiationRepository repo, {
  CollaborationRole role = CollaborationRole.commissioner,
  ThemeData? theme,
  bool fromProgress = false,
  bool smallPhoneLargeText = false,
  FakeCollaborationRepository? collaborations,
  FakeMeRepository? me,
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    useCanvasPhone(tester);
  }
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: fromProgress
        ? '/start'
        : AppRoutes.collaborationTerms(_id),
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push(
                AppRoutes.collaborationTerms(_id),
                extra: AppRoutes.fromProgress,
              ),
              child: const Text('open terms'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.collaborationTermsPattern,
        builder: (context, state) => DraftTermsPage(
          collaborationId: state.pathParameters['id']!,
          fromProgress: state.extra == AppRoutes.fromProgress,
        ),
      ),
      GoRoute(
        path: AppRoutes.collaborationProgressPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: '/brand/coming-soon/:title',
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: '/creator/coming-soon/:title',
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.creatorInstagram,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.brandCollaborations,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.creatorOffers,
        builder: (context, state) => stub(state),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        if (me != null) meRepositoryProvider.overrideWithValue(me),
        negotiationRepositoryProvider.overrideWithValue(repo),
        collaborationRepositoryProvider.overrideWithValue(
          collaborations ??
              FakeCollaborationRepository(
                active: [
                  collaboration(
                    id: _id,
                    kind: CollaborationKind.brandContract,
                    role: role,
                    storeName: '서윤의 작은 취향',
                  ),
                ],
              ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (fromProgress) {
    await tester.tap(find.text('open terms'));
    await tester.pumpAndSettle();
  }
  return opened;
}

/// 화면 아래에 있는 묶음 제목을 보이게 한 뒤 누른다(내용이 한 화면보다 길다).
Future<void> _tapGroup(WidgetTester tester, String title) async {
  await tester.ensureVisible(find.text(title));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('terms shows the received-proposal header with the version and '
      'my-turn badge', (tester) async {
    await _pump(tester, FakeNegotiationRepository());

    expect(find.text('받은 제안 · 판본 1'), findsOneWidget);
    expect(find.text('내가 응답할 차례'), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('출근 전 30초, 오늘의 손목 루틴'), findsOneWidget);
    expect(find.text('릴스 1편'), findsOneWidget);
    expect(find.text('11월 16일 이후'), findsOneWidget);
  });

  testWidgets(
    'terms shows the three reward cells and the maximum cash burden',
    (tester) async {
      await _pump(tester, FakeNegotiationRepository());

      expect(find.text('현금 고정비'), findsOneWidget);
      expect(find.text('30만 원'), findsOneWidget);
      expect(find.text('혜택'), findsOneWidget);
      expect(find.text('제품 제공'), findsOneWidget);
      expect(find.text('성과 추가'), findsOneWidget);
      expect(find.text('없음'), findsOneWidget);
      expect(
        find.text('수락하면 이 판본 조건으로 계약 준비를 시작해요. 최대 현금 부담 30만 원.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a performance add-on shows its cap and the refund note', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository(
      latest: termsLatest(
        terms: termsVersion(
          fee: 300000,
          productProvided: false,
          performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
      ),
    );
    await _pump(tester, repo);

    expect(find.text('최대 6만 원'), findsOneWidget);
    expect(find.text('없음'), findsOneWidget); // 혜택
    expect(
      find.text(
        '수락하면 이 판본 조건으로 계약 준비를 시작해요. 최대 현금 부담 36만 원. '
        '성과 추가는 조회수만큼, 남으면 환불해요.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('terms shows the notice and four groups', (tester) async {
    await _pump(tester, FakeNegotiationRepository());

    expect(find.text('얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.'), findsOneWidget);
    for (final title in ['추천된 이유', '수정과 촬영', '콘텐츠 활용', '지급과 광고 표시']) {
      expect(find.text(title), findsOneWidget);
    }
    // 요약: 첫 이유, 수정 범위, 활용 권한, 지급 라벨(추천된 이유는 펼쳐져 있어 이유가 줄에도 한 번 더 나온다)
    expect(find.text('분야가 맞아요'), findsNWidgets(2));
    // 수정과 촬영·지급의 요약은 캔버스 글자(`… 수정`, `… 지급`)다. 안쪽 줄 값에는 접미사가 없다.
    expect(find.text('기획안 기준 1회 수정'), findsOneWidget);
    expect(find.text('브랜드 계정 재게시만'), findsOneWidget);
    expect(find.text('최종 게시 후 7일 이내 지급'), findsOneWidget);
    expect(find.text('기획안 기준 1회'), findsNothing);
    expect(find.text('최종 게시 후 7일 이내'), findsNothing);
    expect(find.text('잘 맞는 점'), findsOneWidget);
    expect(find.text('주요 분야'), findsOneWidget);
    expect(find.text('리빙·소품, 패션'), findsOneWidget);
    expect(find.text('팔로워'), findsOneWidget);
    expect(find.text('8,200명'), findsOneWidget);
    expect(find.text('추가 촬영'), findsNothing);
  });

  testWidgets('tapping a group opens it and closes the one that was open', (
    tester,
  ) async {
    await _pump(tester, FakeNegotiationRepository());

    await _tapGroup(tester, '콘텐츠 활용');

    expect(find.text('재게시'), findsOneWidget);
    expect(find.text('브랜드 계정만'), findsOneWidget);
    expect(find.text('광고 활용'), findsOneWidget);
    expect(find.text('별도 협의'), findsOneWidget);
    expect(find.text('잘 맞는 점'), findsNothing);

    await _tapGroup(tester, '지급과 광고 표시');

    expect(find.text('지급 시점'), findsOneWidget);
    expect(find.text('최종 게시 후 7일 이내'), findsOneWidget); // 안쪽 줄
    expect(find.text('광고 표시'), findsOneWidget);
    expect(find.text('게시물·영상에 명확히'), findsOneWidget);
    expect(find.text('재게시'), findsNothing);
  });

  testWidgets('the group rows follow the terms: edit scope and ads use', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository(
      latest: termsLatest(
        terms: termsVersion(
          revisionScope: RevisionScope.draftTwice,
          usageRights: BrandUsageRights.adsToo,
        ),
      ),
    );
    await _pump(tester, repo);

    await _tapGroup(tester, '수정과 촬영');
    expect(find.text('초안 기준 2회 수정'), findsOneWidget); // 요약
    expect(find.text('초안 기준 2회'), findsOneWidget); // 안쪽 줄
    expect(find.text('추가 촬영'), findsOneWidget);

    await _tapGroup(tester, '콘텐츠 활용');
    expect(find.text('광고 소재로도 사용'), findsOneWidget);
    expect(find.text('포함'), findsOneWidget);
  });

  testWidgets(
    'without followers the row is hidden, and without any reason, field or '
    'followers the whole group is',
    (tester) async {
      await _pump(
        tester,
        FakeNegotiationRepository(latest: termsLatest(followers: null)),
      );
      expect(find.text('추천된 이유'), findsOneWidget);
      expect(find.text('잘 맞는 점'), findsOneWidget);
      expect(find.text('팔로워'), findsNothing);

      await _pump(
        tester,
        FakeNegotiationRepository(
          latest: termsLatest(
            followers: null,
            reasons: const <MatchReason>[],
            fields: const [],
          ),
        ),
      );
      expect(find.text('추천된 이유'), findsNothing);
      expect(find.text('수정과 촬영'), findsOneWidget);
    },
  );

  testWidgets('the main fields line is hidden when the list is empty', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeNegotiationRepository(latest: termsLatest(fields: const [])),
    );

    expect(find.text('잘 맞는 점'), findsOneWidget);
    expect(find.text('주요 분야'), findsNothing);
    expect(find.text('팔로워'), findsOneWidget);
  });

  testWidgets('with only fields the group stays and summarizes the fields', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeNegotiationRepository(
        latest: termsLatest(followers: null, reasons: const <MatchReason>[]),
      ),
    );

    expect(find.text('추천된 이유'), findsOneWidget);
    expect(find.text('주요 분야'), findsOneWidget);
    expect(find.text('리빙·소품, 패션'), findsNWidgets(2)); // 요약과 줄
  });

  testWidgets('without a notice the notice box is not drawn', (tester) async {
    await _pump(
      tester,
      FakeNegotiationRepository(latest: termsLatest(notice: null)),
    );

    expect(find.text('얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.'), findsNothing);
    expect(find.text('추천된 이유'), findsOneWidget);
  });

  testWidgets('accepting the version sends its number and goes to the '
      'progress screen', (tester) async {
    final repo = FakeNegotiationRepository(
      latest: termsLatest(terms: termsVersion(version: 3)),
    );
    final opened = await _pump(tester, repo);

    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();

    expect(repo.confirmed, [(id: _id, version: 3)]);
    expect(opened.last, AppRoutes.collaborationProgress(_id));
  });

  testWidgets('accepting from the progress screen goes back to it instead of '
      'stacking another one', (tester) async {
    final repo = FakeNegotiationRepository();
    final opened = await _pump(tester, repo, fromProgress: true);

    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();

    expect(repo.confirmed, hasLength(1));
    expect(find.text('open terms'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('the accept button waits once I have accepted', (tester) async {
    final repo = FakeNegotiationRepository(
      latest: termsLatest(
        myTurn: false,
        terms: termsVersion(
          version: 2,
          creatorConfirmed: true,
          proposedBy: TermsProposer.creator,
        ),
      ),
    );
    await _pump(tester, repo);

    expect(find.text('받은 제안 · 판본 2'), findsOneWidget);
    expect(find.text('상대 대기'), findsOneWidget);
    expect(find.text('내가 응답할 차례'), findsNothing);
    expect(find.text('이 판본 수락'), findsNothing);
    expect(find.text('상대의 응답을 기다리고 있어요'), findsOneWidget);
    await tester.tap(find.text('상대의 응답을 기다리고 있어요'));
    await tester.pumpAndSettle();
    expect(repo.confirmed, isEmpty);
    // 조건 수정 제안은 남는다.
    expect(find.text('조건 수정 제안'), findsOneWidget);
  });

  testWidgets('a version I proposed reads as a sent proposal', (tester) async {
    final repo = FakeNegotiationRepository(
      latest: termsLatest(
        mine: true,
        myTurn: false,
        terms: termsVersion(
          version: 2,
          brandConfirmed: true,
          proposedBy: TermsProposer.brand,
        ),
      ),
    );
    await _pump(tester, repo);

    expect(find.text('보낸 제안 · 판본 2'), findsOneWidget);
    expect(find.text('상대 대기'), findsOneWidget);
  });

  testWidgets('an agreed version shows the agreement and no accept button', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository(
      latest: termsLatest(
        myTurn: false,
        terms: termsVersion(brandConfirmed: true, creatorConfirmed: true),
      ),
    );
    await _pump(tester, repo);

    expect(find.text('합의한 조건 · 판본 1'), findsOneWidget);
    expect(find.text('합의 완료'), findsOneWidget);
    expect(find.text('이 판본 수락'), findsNothing);
    expect(find.text('상대의 응답을 기다리고 있어요'), findsNothing);
    expect(find.text('조건 수정 제안'), findsOneWidget);
  });

  testWidgets('a stale version shows the shared older-version state and '
      'reloads the latest', (tester) async {
    final repo = FakeNegotiationRepository()
      ..confirmFailure = const NegotiationStale(2)
      ..newerLatest = termsLatest(
        terms: termsVersion(version: 2, fee: 350000, maxCash: 350000),
      );
    await _pump(tester, repo);

    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();

    expect(find.text('이전 판본이라 수락할 수 없어요'), findsOneWidget);
    expect(find.text('상대가 판본 2를 보냈어요. 바뀐 조건을 확인한 뒤 수락해 주세요.'), findsOneWidget);
    expect(find.text('이 판본 수락'), findsNothing);

    await tester.tap(find.text('판본 2 보기'));
    await tester.pumpAndSettle();

    expect(find.text('이전 판본이라 수락할 수 없어요'), findsNothing);
    expect(find.text('받은 제안 · 판본 2'), findsOneWidget);
    expect(find.text('35만 원'), findsOneWidget);
    expect(find.text('이 판본 수락'), findsOneWidget);
  });

  testWidgets('a stale answer without a latest number reads it again', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository()
      ..confirmFailure = const NegotiationStale(null)
      ..newerLatest = termsLatest(terms: termsVersion(version: 4));
    await _pump(tester, repo);

    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();

    expect(find.text('판본 4 보기'), findsOneWidget);
  });

  testWidgets('a creator without instagram sees the connect prompt instead of '
      'accept', (tester) async {
    final repo = FakeNegotiationRepository(
      latest: termsLatest(needsInstagram: true),
    );
    final opened = await _pump(tester, repo, role: CollaborationRole.creator);

    expect(find.text('인스타그램을 연동하면 수락할 수 있어요'), findsOneWidget);
    expect(find.text('연동하기'), findsOneWidget);
    expect(find.text('이 판본 수락'), findsNothing);

    await tester.tap(find.text('연동하기'));
    await tester.pumpAndSettle();

    expect(opened.last, AppRoutes.creatorInstagram);
    expect(repo.confirmed, isEmpty);
  });

  testWidgets('coming back from the instagram connection reads the version '
      'again', (tester) async {
    final repo = FakeNegotiationRepository(
      latest: termsLatest(needsInstagram: true),
    );
    await _pump(tester, repo, role: CollaborationRole.creator);
    final before = repo.fetchCalls;

    repo.latest = termsLatest();
    await tester.tap(find.text('연동하기'));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.pop();
    await tester.pumpAndSettle();

    expect(repo.fetchCalls, greaterThan(before));
    expect(find.text('이 판본 수락'), findsOneWidget);
    expect(find.text('인스타그램을 연동하면 수락할 수 있어요'), findsNothing);
  });

  testWidgets('a server refusal shows its message and keeps the button', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository()
      ..confirmFailure = const NegotiationRejected('인스타그램을 연동하면 수락할 수 있어요.');
    await _pump(tester, repo);

    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();

    expect(find.text('인스타그램을 연동하면 수락할 수 있어요.'), findsOneWidget);
    expect(find.text('이 판본 수락'), findsOneWidget);
  });

  testWidgets('any other failure shows the general message', (tester) async {
    final repo = FakeNegotiationRepository()
      ..confirmFailure = const NegotiationFailure();
    await _pump(tester, repo);

    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();

    expect(find.text('처리하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('the modify button opens the placeholder of the viewer role', (
    tester,
  ) async {
    final opened = await _pump(tester, FakeNegotiationRepository());

    await tester.tap(find.text('조건 수정 제안'));
    await tester.pumpAndSettle();

    expect(opened.last, AppRoutes.brandComingSoon('조건 수정 제안'));

    final creatorOpened = await _pump(
      tester,
      FakeNegotiationRepository(),
      role: CollaborationRole.creator,
    );
    await tester.tap(find.text('조건 수정 제안'));
    await tester.pumpAndSettle();

    expect(creatorOpened.last, AppRoutes.creatorComingSoon('조건 수정 제안'));
  });

  testWidgets('a load failure shows the shared failure state and retries', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository()..failFetch = true;
    await _pump(tester, repo);

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('조건을 불러오지 못했어요'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('받은 제안 · 판본 1'), findsOneWidget);
  });

  testWidgets('back from a deep link goes to the collaboration tab of the '
      'role', (tester) async {
    final opened = await _pump(tester, FakeNegotiationRepository());

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(opened.last, AppRoutes.brandCollaborations);
  });

  testWidgets('back from a deep link before the collaboration is read goes to '
      'the creator collaboration tab for a creator', (tester) async {
    final opened = await _pump(
      tester,
      FakeNegotiationRepository()..failFetch = true,
      me: FakeMeRepository(role: UserRole.creator),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(opened.last, AppRoutes.creatorOffers);
  });

  testWidgets('a failed reload from the older-version card shows the load '
      'failure and can retry', (tester) async {
    final repo = FakeNegotiationRepository()
      ..confirmFailure = const NegotiationStale(2)
      ..newerLatest = termsLatest(terms: termsVersion(version: 2));
    await _pump(tester, repo);
    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();
    expect(find.text('판본 2 보기'), findsOneWidget);

    repo.failFetch = true;
    await tester.tap(find.text('판본 2 보기'));
    await tester.pumpAndSettle();

    expect(find.text('조건을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('이전 판본이라 수락할 수 없어요'), findsNothing);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('받은 제안 · 판본 2'), findsOneWidget);
    expect(find.text('이 판본 수락'), findsOneWidget);
  });

  testWidgets('accepting makes the brand collaboration list read again', (
    tester,
  ) async {
    final collaborations = FakeCollaborationRepository(
      active: [
        collaboration(
          id: _id,
          kind: CollaborationKind.brandContract,
          storeName: '서윤의 작은 취향',
        ),
      ],
    );
    await _pump(
      tester,
      FakeNegotiationRepository(),
      collaborations: collaborations,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DraftTermsPage)),
    );
    container.listen(brandCollaborationsViewModelProvider, (_, _) {});
    await container.read(brandCollaborationsViewModelProvider.future);
    final before = collaborations.fetchActiveCalls;

    await tester.tap(find.text('이 판본 수락'));
    await tester.pumpAndSettle();
    await container.read(brandCollaborationsViewModelProvider.future);

    expect(collaborations.fetchActiveCalls, greaterThan(before));
  });

  testWidgets('the dark theme uses the dark canvas colors', (tester) async {
    await _pump(tester, FakeNegotiationRepository(), theme: coraDarkTheme);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final colors = CoraColors.dark;
    expect(
      tester
          .widget<DecoratedBox>(
            find
                .ancestor(
                  of: find.text('내가 응답할 차례'),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration,
      isA<BoxDecoration>().having((d) => d.color, 'color', colors.accent),
    );
    expect(scaffold.backgroundColor ?? colors.background, colors.background);
    final cell = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('현금 고정비'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((cell.decoration as BoxDecoration).color, const Color(0xFF1C1E22));
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _pump(
      tester,
      FakeNegotiationRepository(latest: termsLatest(needsInstagram: true)),
      smallPhoneLargeText: true,
      role: CollaborationRole.creator,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('연동하기'), findsOneWidget);
  });
}
