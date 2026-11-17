import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/proposals/domain/offer_version.dart';
import 'package:cora/features/proposals/domain/proposal.dart';
import 'package:cora/features/proposals/domain/proposal_repository.dart';
import 'package:cora/features/proposals/presentation/pages/proposals_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../proposals/fake_proposal_repository.dart';
import 'fake_negotiation_repository.dart';

/// 브랜드는 오퍼 제안함(`GET /offers/proposals`, 브랜드에게는 403)을 부르면 안 된다.
class _NoOffersRepository extends FakeProposalRepository {
  @override
  Future<List<ProposalRow>> fetch(ProposalTab tab) =>
      throw StateError('a brand must not read the store offers');
}

/// F3를 [party]의 길에 올린다. 줄이 여는 곳은 위치만 적는 빈 화면이고 그 위치를 기록한다.
Future<List<String>> _pump(
  WidgetTester tester, {
  required ProposalParty party,
  FakeNegotiationRepository? negotiation,
  ProposalRepository? offers,
  ThemeData? theme,
  bool smallPhoneLargeText = false,
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    useCanvasPhone(tester);
  }
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.path);
    return Scaffold(body: Text('opened ${state.uri.path}'));
  }

  final brand = party == ProposalParty.brand;
  final router = GoRouter(
    initialLocation: brand
        ? AppRoutes.brandProposals
        : AppRoutes.creatorProposals,
    routes: [
      GoRoute(
        path: AppRoutes.brandProposals,
        builder: (context, state) => ProposalsPage(party: party),
      ),
      GoRoute(
        path: AppRoutes.creatorProposals,
        builder: (context, state) => ProposalsPage(party: party),
      ),
      GoRoute(
        path: AppRoutes.creatorProposalPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.collaborationAgreementPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.collaborationContractPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.creatorCollaborationPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.brandCollaborations,
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
        negotiationRepositoryProvider.overrideWithValue(
          negotiation ?? FakeNegotiationRepository(),
        ),
        proposalRepositoryProvider.overrideWithValue(
          offers ?? (brand ? _NoOffersRepository() : FakeProposalRepository()),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

FakeNegotiationRepository _inbox() => FakeNegotiationRepository()
  ..inbox = [
    brandContractRow(collaborationId: 'c-turn', name: '모아 스튜디오'),
    brandContractRow(
      collaborationId: 'c-counter',
      name: '하루 한 잔',
      version: 2,
      counter: true,
    ),
    brandContractRow(
      collaborationId: 'c-wait',
      name: '오롯 베이커리',
      group: ProposalGroup.waiting,
      format: ContentFormat.cardNews,
      pieces: 2,
    ),
    brandContractRow(
      collaborationId: 'c-agreed',
      name: '단정 서점',
      group: ProposalGroup.ended,
      version: 3,
      endKind: ProposalEndKind.agreed,
    ),
    brandContractRow(
      collaborationId: 'c-mine-budget',
      name: '나무 공방',
      group: ProposalGroup.ended,
      endKind: ProposalEndKind.ended,
      myDropReason: DropReason.budget,
    ),
    brandContractRow(
      collaborationId: 'c-theirs',
      name: '봄날 꽃집',
      group: ProposalGroup.ended,
      endKind: ProposalEndKind.ended,
    ),
  ];

void main() {
  setUpAll(loadAppFonts);

  testWidgets('lists brand contract rows by turn and opens the agreement', (
    tester,
  ) async {
    final opened = await _pump(
      tester,
      party: ProposalParty.brand,
      negotiation: _inbox(),
    );

    expect(find.text('제안함'), findsOneWidget);
    expect(find.text('진행 중 3'), findsOneWidget);
    expect(find.text('종료 3'), findsOneWidget);
    expect(find.text('내가 응답할 차례'), findsOneWidget);
    expect(find.text('상대 대기'), findsOneWidget);
    expect(find.text('판본 1 · 릴스 1편'), findsOneWidget);
    expect(find.text('판본 1 · 카드뉴스 2편'), findsOneWidget);
    expect(find.text('응답하기'), findsNWidgets(2));
    expect(find.text('대기'), findsOneWidget);
    // 응답할 차례 묶음이 대기 묶음보다 위에 있다.
    expect(
      tester.getTopLeft(find.text('내가 응답할 차례')).dy,
      lessThan(tester.getTopLeft(find.text('상대 대기')).dy),
    );

    await tester.tap(find.text('모아 스튜디오'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.collaborationAgreement('c-turn'));
  });

  testWidgets(
    'a waiting row opens the agreement too and has no deadline tail',
    (tester) async {
      final opened = await _pump(
        tester,
        party: ProposalParty.brand,
        negotiation: _inbox(),
      );

      expect(find.textContaining('안에 답이 와요'), findsNothing);
      await tester.tap(find.text('오롯 베이커리'));
      await tester.pumpAndSettle();
      expect(opened.last, AppRoutes.collaborationAgreement('c-wait'));
    },
  );

  testWidgets(
    'marks a version written by the other side as a counter-proposal',
    (tester) async {
      await _pump(tester, party: ProposalParty.brand, negotiation: _inbox());

      expect(find.text('역제안 · 판본 2 · 릴스 1편'), findsOneWidget);
    },
  );

  testWidgets('an agreed row moves to the closed tab and opens the contract', (
    tester,
  ) async {
    final opened = await _pump(
      tester,
      party: ProposalParty.brand,
      negotiation: _inbox(),
    );

    expect(find.text('단정 서점'), findsNothing);
    await tester.tap(find.text('종료 3'));
    await tester.pumpAndSettle();
    expect(find.text('합의 완료 · 계약으로 이동'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);

    await tester.tap(find.text('단정 서점'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.collaborationContract('c-agreed'));
  });

  testWidgets('shows the drop reason only on my own closed row', (
    tester,
  ) async {
    final opened = await _pump(
      tester,
      party: ProposalParty.brand,
      negotiation: _inbox(),
    );
    await tester.tap(find.text('종료 3'));
    await tester.pumpAndSettle();

    // 내가 그만둔 줄은 이유를, 상대가 그만둔 줄은 이유 없이 `협의 종료`만 보인다.
    expect(find.text('예산이 맞지 않아 종료'), findsOneWidget);
    expect(find.text('협의 종료'), findsOneWidget);

    // 끝난 줄을 눌러도 12가 읽기만으로 열린다.
    await tester.tap(find.text('봄날 꽃집'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.collaborationAgreement('c-theirs'));
  });

  testWidgets('words each drop reason the way the canvas does', (tester) async {
    final negotiation = FakeNegotiationRepository()
      ..inbox = [
        for (final (i, reason) in DropReason.values.indexed)
          brandContractRow(
            collaborationId: 'c$i',
            name: '브랜드 $i',
            group: ProposalGroup.ended,
            endKind: ProposalEndKind.ended,
            myDropReason: reason,
          ),
      ];
    await _pump(tester, party: ProposalParty.brand, negotiation: negotiation);
    await tester.tap(find.text('종료 4'));
    await tester.pumpAndSettle();

    expect(find.text('일정이 맞지 않아 종료'), findsOneWidget);
    expect(find.text('예산이 맞지 않아 종료'), findsOneWidget);
    expect(find.text('방향이 달라 종료'), findsOneWidget);
    // 이유를 `기타`로 그만두면 이유 없이 `종료`만 적는다. 묶음 이름 하나, 알약 넷, 그 줄의 설명 하나다.
    expect(find.text('종료'), findsNWidgets(6));
  });

  testWidgets('a brand sees only contract rows and never reads store offers', (
    tester,
  ) async {
    final negotiation = _inbox();
    await _pump(tester, party: ProposalParty.brand, negotiation: negotiation);

    expect(negotiation.inboxCalls, greaterThan(0));
    expect(find.byType(CoraStateView), findsNothing);
  });

  testWidgets('a creator sees store offers and brand contracts in one inbox', (
    tester,
  ) async {
    final offers = FakeProposalRepository(
      active: [
        proposalRow(offerId: 'o1', name: '하루 한 컵'),
        proposalRow(
          offerId: 'o2',
          name: '민의 옷장 기록',
          group: ProposalGroup.waiting,
          counter: false,
          version: 1,
          daysLeft: 2,
        ),
      ],
      ended: [
        proposalRow(
          offerId: 'oe',
          name: '서윤의 작은 취향',
          group: ProposalGroup.ended,
          endKind: ProposalEndKind.expired,
        ),
      ],
    );
    final opened = await _pump(
      tester,
      party: ProposalParty.creator,
      negotiation: _inbox(),
      offers: offers,
    );

    // 오퍼 둘 + 브랜드 셋, 종료는 오퍼 하나 + 브랜드 셋.
    expect(find.text('진행 중 5'), findsOneWidget);
    expect(find.text('종료 4'), findsOneWidget);
    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('모아 스튜디오'), findsOneWidget);
    // 가게 오퍼의 기한 꼬리는 그대로고 브랜드 줄에는 없다(오퍼 하나에만 있다).
    expect(find.textContaining('안에 답이 와요'), findsOneWidget);

    await tester.tap(find.text('하루 한 컵'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.creatorProposal('o1'));
    _router(tester).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('모아 스튜디오'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.collaborationAgreement('c-turn'));
  });

  testWidgets('shows the empty state for a brand with no contract rows', (
    tester,
  ) async {
    await _pump(tester, party: ProposalParty.brand);

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('아직 받은 제안이 없어요'), findsOneWidget);
    expect(find.text('크리에이터에게 오퍼를 보내면 여기에 모여요.'), findsNothing);
    expect(find.text('진행 중 0'), findsOneWidget);

    await tester.tap(find.text('종료 0'));
    await tester.pumpAndSettle();
    expect(find.text('아직 끝난 제안이 없어요'), findsOneWidget);
  });

  testWidgets('shows the failed state and retries', (tester) async {
    final negotiation = _inbox()..failInbox = true;
    await _pump(tester, party: ProposalParty.brand, negotiation: negotiation);

    expect(find.text('제안함을 불러오지 못했어요.'), findsOneWidget);
    expect(find.byType(CoraStateView), findsOneWidget);

    negotiation.failInbox = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('진행 중 3'), findsOneWidget);
  });

  testWidgets('a creator whose inbox call fails sees the failed state', (
    tester,
  ) async {
    final negotiation = _inbox()..failInbox = true;
    await _pump(tester, party: ProposalParty.creator, negotiation: negotiation);

    expect(find.text('제안함을 불러오지 못했어요.'), findsOneWidget);
  });

  testWidgets('uses the canvas colors in light mode', (tester) async {
    await _pump(tester, party: ProposalParty.brand, negotiation: _inbox());
    final c = CoraColors.light;

    Finder box(Color color) => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == color,
    );

    // 줄 셋과 탭 알약이 `surface`, 응답하기 알약 둘 + 묶음 점이 라임, 상대 대기 점은 흐린 회색이다.
    expect(box(c.surface), findsNWidgets(4));
    expect(box(c.accent), findsNWidgets(3));
    expect(box(c.iconMuted), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _pump(
      tester,
      party: ProposalParty.brand,
      negotiation: _inbox(),
      smallPhoneLargeText: true,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('종료 3'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

GoRouter _router(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(ProposalsPage, skipOffstage: false)),
);
