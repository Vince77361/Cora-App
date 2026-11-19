import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/chat/domain/chat_repository.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/interests/presentation/pages/interests_page.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, ViewPay;
import 'package:cora/features/received_proposals/domain/received_proposals_repository.dart';
import 'package:cora/features/received_proposals/presentation/pages/inquiry_sheet.dart';
import 'package:cora/features/received_proposals/presentation/pages/received_proposal_page.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../chat/chat_fixtures.dart';
import '../discovery/fake_discovery_repository.dart';
import '../interests/fake_interests_repository.dart';
import 'fake_received_proposals_repository.dart';

typedef _Env = ({
  FakeReceivedProposalsRepository proposals,
  FakeDiscoveryRepository discovery,
  FakeInterestsRepository interests,
  FakeChatRepository chat,
  List<String> opened,
  GoRouter router,
});

/// 03(크리에이터)을 시작 화면으로 올리고 그 위에 10을 연다. 10이 가는 다른 화면은 위치 글자만 보이는 빈 화면이고
/// 위치를 기록한다.
Future<_Env> _pump(
  WidgetTester tester, {
  FakeReceivedProposalsRepository? proposals,
  FakeDiscoveryRepository? discovery,
  FakeInterestsRepository? interests,
  FakeChatRepository? chat,
  ThemeData? theme,
  String start = AppRoutes.creatorInterests,
}) async {
  useCanvasPhone(tester);
  final proposalsRepo = proposals ?? FakeReceivedProposalsRepository();
  final discoveryRepo = discovery ?? FakeDiscoveryRepository();
  final interestsRepo = interests ?? FakeInterestsRepository();
  final chatRepo = chat ?? FakeChatRepository();
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: AppRoutes.creator,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.creatorInterests,
        builder: (context, state) => InterestsPage(
          isBrand: false,
          matchId: state.uri.queryParameters[AppRoutes.matchParam],
        ),
      ),
      GoRoute(
        path: AppRoutes.creatorReceivedProposalPattern,
        builder: (context, state) => ReceivedProposalPage(
          campaignId: state.pathParameters['campaignId']!,
        ),
      ),
      GoRoute(
        path: '/collaborations/:id/terms',
        builder: (context, state) => stub(state),
      ),
      GoRoute(path: '/chats/:id', builder: (context, state) => stub(state)),
      GoRoute(
        path: '/creator/coming-soon/:title',
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
      overrides: [
        receivedProposalsRepositoryProvider.overrideWithValue(proposalsRepo),
        discoveryRepositoryProvider.overrideWithValue(discoveryRepo),
        interestsRepositoryProvider.overrideWithValue(interestsRepo),
        chatRepositoryProvider.overrideWithValue(chatRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    proposals: proposalsRepo,
    discovery: discoveryRepo,
    interests: interestsRepo,
    chat: chatRepo,
    opened: opened,
    router: router,
  );
}

/// 03에서 첫 카드를 눌러 10을 연다.
Future<void> _openFromList(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(RegExp('에 제안했어요')).first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('03 top group', () {
    testWidgets('shows received proposals above the creator interests', (
      tester,
    ) async {
      final proposals = FakeReceivedProposalsRepository(
        proposals: [
          receivedProposal(),
          receivedProposal(
            campaignId: 'c2',
            brandName: '한그릇',
            contentTitle: null,
          ),
        ],
      );
      await _pump(tester, proposals: proposals);

      expect(find.text('받은 제안 2'), findsOneWidget);
      expect(find.text('모아 스튜디오'), findsOneWidget);
      // 좁은 카드에서 낱말 가운데가 끊기지 않게 문장을 두 줄로 미리 나눈다.
      expect(find.text('내 콘텐츠 「매일 손이 가는 물건들」에'), findsOneWidget);
      expect(find.text('제안했어요'), findsOneWidget);
      expect(find.text('한그릇'), findsOneWidget);
      // 콘텐츠 사본이 없으면 프로필에 한 제안이다.
      expect(find.text('내 프로필에 제안했어요'), findsOneWidget);
      // 묶음이 탭 위에 있다.
      expect(
        tester.getTopLeft(find.text('받은 제안 2')).dy,
        lessThan(tester.getTopLeft(find.text('저장 0')).dy),
      );
    });

    testWidgets('shows nothing when there are no received proposals', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.textContaining('받은 제안'), findsNothing);
    });

    testWidgets('keeps the list when the proposals cannot be read', (
      tester,
    ) async {
      await _pump(
        tester,
        proposals: FakeReceivedProposalsRepository()..failFetch = true,
      );

      expect(find.textContaining('받은 제안'), findsNothing);
      expect(find.text('저장함'), findsOneWidget);
    });

    testWidgets('a long content title stays on one line with an ellipsis and '
        'keeps the verb whole', (tester) async {
      await _pump(
        tester,
        proposals: FakeReceivedProposalsRepository(
          proposals: [
            receivedProposal(contentTitle: '아침마다 손이 가는 작고 오래된 물건들의 이야기 모음집'),
          ],
        ),
      );

      expect(find.text('제안했어요'), findsOneWidget);
      expect(
        tester.getSize(find.textContaining('아침마다 손이 가는')).height,
        lessThan(20),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a card opens the proposal', (tester) async {
      await _pump(
        tester,
        proposals: FakeReceivedProposalsRepository(
          proposals: [receivedProposal()],
        ),
      );

      await _openFromList(tester);

      expect(find.text('브랜드가 좋아한 점'), findsOneWidget);
    });
  });

  group('10 received proposal', () {
    Future<_Env> open(
      WidgetTester tester, {
      List<dynamic>? proposals,
      FakeDiscoveryRepository? discovery,
      FakeInterestsRepository? interests,
      FakeChatRepository? chat,
      FakeReceivedProposalsRepository? repo,
      ThemeData? theme,
    }) async {
      final env = await _pump(
        tester,
        proposals:
            repo ??
            FakeReceivedProposalsRepository(
              proposals: [receivedProposal(), ...?proposals?.cast()],
            ),
        discovery: discovery,
        interests: interests,
        chat: chat,
        theme: theme,
      );
      await _openFromList(tester);
      return env;
    }

    testWidgets('shows the copied content title and the brand note', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('받은 제안'), findsOneWidget);
      expect(find.text('모아 스튜디오'), findsWidgets);
      expect(find.text('내 콘텐츠 「매일 손이 가는 물건들」에 제안했어요'), findsWidgets);
      expect(find.text('브랜드가 좋아한 점'), findsOneWidget);
      expect(
        find.text('실제로 사용하는 장면이 좋았어요. 새 주얼리도 서윤님의 일상 안에서 소개하고 싶어요.'),
        findsOneWidget,
      );
      expect(find.text('30만 원 + 제품'), findsOneWidget);
      expect(find.text('릴스 1편'), findsOneWidget);
      expect(find.text('관심 보내기'), findsOneWidget);
      expect(find.text('조건부터 질문하기'), findsOneWidget);
      expect(find.text('내가 만들고 싶은 콘텐츠를 한 줄로'), findsOneWidget);
    });

    testWidgets('shows the performance add-on and drops the product when '
        'the brand did not offer one', (tester) async {
      await open(
        tester,
        repo: FakeReceivedProposalsRepository(
          proposals: [
            receivedProposal(
              fee: 350000,
              format: ContentFormat.cardNews,
              productProvided: false,
              performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
            ),
          ],
        ),
      );

      expect(find.text('35만 원 + 성과 추가'), findsOneWidget);
      expect(find.text('카드뉴스 1편'), findsOneWidget);
    });

    testWidgets('has no note bubble when the brand only attached terms', (
      tester,
    ) async {
      await open(
        tester,
        repo: FakeReceivedProposalsRepository(
          proposals: [receivedProposal(note: null)],
        ),
      );

      expect(find.text('브랜드가 좋아한 점'), findsNothing);
      expect(find.text('30만 원 + 제품'), findsOneWidget);
    });

    testWidgets('closes with the close button', (tester) async {
      await open(tester);

      await tester.tap(find.bySemanticsLabel('닫기'));
      await tester.pumpAndSettle();

      expect(find.text('브랜드가 좋아한 점'), findsNothing);
      expect(find.text('저장함'), findsOneWidget);
    });

    testWidgets('sending interest carries my one line as the note', (
      tester,
    ) async {
      final env = await open(tester);

      await tester.enterText(find.byType(TextField), '  손목 위 시계 아침 루틴  ');
      await tester.tap(find.text('관심 보내기'));
      await tester.pumpAndSettle();

      final sent = env.discovery.decisions.single;
      expect(sent.target.id, 'c1');
      expect(sent.outcome, SwipeOutcome.like);
      expect(sent.note, '손목 위 시계 아침 루틴');
      // 서로 관심이 아직 아니면 03으로 돌아와 알린다.
      expect(find.text('브랜드가 좋아한 점'), findsNothing);
      expect(find.text('하트를 보냈어요. 브랜드도 고르면 알려드려요.'), findsOneWidget);
    });

    testWidgets('the arrow sends the same interest and an empty line sends '
        'no note', (tester) async {
      final env = await open(tester);

      await tester.tap(find.bySemanticsLabel('아이디어 보내기'));
      await tester.pumpAndSettle();

      expect(env.discovery.decisions.single.note, isNull);
    });

    testWidgets('limits the line to 40 characters', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), '가' * 60);
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text.length, 40);
    });

    testWidgets('a mutual like from the proposal opens the match sheet', (
      tester,
    ) async {
      final discovery = FakeDiscoveryRepository()..matchOn.add('c1');
      final interests = FakeInterestsRepository()..match = matchInfo();
      final env = await open(
        tester,
        discovery: discovery,
        interests: interests,
      );
      // 서버는 관심을 받은 캠페인을 받은 제안에서 뺀다.
      env.proposals.proposals = [];

      await tester.tap(find.text('관심 보내기'));
      await tester.pumpAndSettle();

      expect(interests.matchesFetched, ['collab-c1']);
      expect(find.text('서로를 골랐어요.'), findsOneWidget);
      expect(find.text('브랜드가 좋아한 점'), findsNothing);
      // 시트 뒤의 03은 옛 묶음을 쥐고 있지 않다.
      expect(find.text('받은 제안 1'), findsNothing);
      // 03을 한 장 더 쌓지 않고 아래의 03이 시트를 연다.
      expect(
        env.router.routerDelegate.currentConfiguration.matches,
        hasLength(1),
      );
      await tester.tap(find.bySemanticsLabel('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('저장함'), findsOneWidget);
      expect(
        env.router.routerDelegate.currentConfiguration.matches,
        hasLength(1),
      );
    });

    testWidgets('a mutual like on a proposal opened without a screen below '
        'goes to the screen that opens the match sheet', (tester) async {
      final discovery = FakeDiscoveryRepository()..matchOn.add('c1');
      final interests = FakeInterestsRepository()..match = matchInfo();
      await _pump(
        tester,
        proposals: FakeReceivedProposalsRepository(
          proposals: [receivedProposal()],
        ),
        discovery: discovery,
        interests: interests,
        start: AppRoutes.creatorReceivedProposal('c1'),
      );

      await tester.tap(find.text('관심 보내기'));
      await tester.pumpAndSettle();

      expect(find.text('서로를 골랐어요.'), findsOneWidget);
    });

    testWidgets('keeps the proposal and says so when sending interest '
        'fails', (tester) async {
      final discovery = FakeDiscoveryRepository()..failDecide = true;
      await open(tester, discovery: discovery);

      await tester.tap(find.text('관심 보내기'));
      await tester.pumpAndSettle();

      expect(find.text('관심을 보내지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('브랜드가 좋아한 점'), findsOneWidget);
    });

    testWidgets('asking first requires a message and confirms', (tester) async {
      final env = await open(tester);

      await tester.enterText(find.byType(TextField), '릴스 한 편으로 해도 될까요');
      await tester.tap(find.text('조건부터 질문하기'));
      await tester.pumpAndSettle();
      expect(find.text('브랜드에게 물어볼 내용을 적어 주세요'), findsOneWidget);

      // 비어 있으면 보내지 않는다.
      await tester.tap(find.text('질문 보내기'));
      await tester.pumpAndSettle();
      expect(env.proposals.inquiries, isEmpty);

      await tester.enterText(
        find.byKey(InquirySheet.fieldKey),
        '  제품은 언제 받을 수 있나요?  ',
      );
      await tester.pump();
      await tester.tap(find.text('질문 보내기'));
      await tester.pumpAndSettle();

      final inquiry = env.proposals.inquiries.single;
      expect(inquiry.campaignId, 'c1');
      expect(inquiry.message, '제품은 언제 받을 수 있나요?');
      // 10의 한 줄도 같이 보낸다.
      expect(inquiry.contentLine, '릴스 한 편으로 해도 될까요');
      // 시트와 10이 닫히고 03이 안내한다. 질문한 캠페인은 목록에서 빠진다.
      expect(find.text('브랜드에게 물어볼 내용을 적어 주세요'), findsNothing);
      expect(find.text('브랜드가 좋아한 점'), findsNothing);
      expect(find.text('질문을 보냈어요. 브랜드가 수락하면 대화가 열려요.'), findsOneWidget);
      expect(find.text('받은 제안 1'), findsNothing);
    });

    testWidgets('asking again says the campaign was already asked', (
      tester,
    ) async {
      final repo = FakeReceivedProposalsRepository(
        proposals: [receivedProposal()],
      )..inquiryFailure = const ReceivedProposalsFailure.conflict();
      await open(tester, repo: repo);

      await tester.tap(find.text('조건부터 질문하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(InquirySheet.fieldKey), '질문이에요');
      await tester.pump();
      await tester.tap(find.text('질문 보내기'));
      await tester.pumpAndSettle();

      expect(find.text('이미 이 캠페인에 질문했어요.'), findsOneWidget);
      // 시트는 열려 있다.
      expect(find.text('브랜드에게 물어볼 내용을 적어 주세요'), findsOneWidget);
    });

    testWidgets('a failed question keeps the text and can be sent again', (
      tester,
    ) async {
      final repo = FakeReceivedProposalsRepository(
        proposals: [receivedProposal()],
      )..inquiryFailure = const ReceivedProposalsFailure.failed();
      await open(tester, repo: repo);

      await tester.tap(find.text('조건부터 질문하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(InquirySheet.fieldKey), '질문이에요');
      await tester.pump();
      await tester.tap(find.text('질문 보내기'));
      await tester.pumpAndSettle();
      expect(find.text('질문을 보내지 못했어요. 다시 시도해 주세요.'), findsOneWidget);

      repo.inquiryFailure = null;
      await tester.tap(find.text('질문 보내기'));
      await tester.pumpAndSettle();
      expect(repo.inquiries.single.message, '질문이에요');
    });

    testWidgets('closing the question sheet sends nothing', (tester) async {
      final env = await open(tester);

      await tester.tap(find.text('조건부터 질문하기'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();

      expect(env.proposals.inquiries, isEmpty);
      expect(find.text('브랜드가 좋아한 점'), findsOneWidget);
    });

    testWidgets('opened without the list shows the shared gone state', (
      tester,
    ) async {
      await _pump(
        tester,
        proposals: FakeReceivedProposalsRepository(),
        start: AppRoutes.creatorReceivedProposal('c9'),
      );

      expect(find.text('더 볼 수 없는 제안이에요'), findsOneWidget);
    });

    testWidgets('shows the shared failure state and retries', (tester) async {
      final repo = FakeReceivedProposalsRepository(
        proposals: [receivedProposal()],
      )..failFetch = true;
      await _pump(
        tester,
        proposals: repo,
        start: AppRoutes.creatorReceivedProposal('c1'),
      );

      expect(find.text('받은 제안을 불러오지 못했어요'), findsOneWidget);
      repo.failFetch = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('브랜드가 좋아한 점'), findsOneWidget);
    });

    testWidgets('renders in the dark theme and with large text without '
        'overflow', (tester) async {
      useSmallPhoneWithLargeText(tester);
      final env = (
        repo: FakeReceivedProposalsRepository(
          proposals: [
            receivedProposal(
              performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
            ),
          ],
        ),
      );
      final router = GoRouter(
        initialLocation: '/p',
        routes: [
          GoRoute(
            path: '/p',
            builder: (context, state) =>
                const ReceivedProposalPage(campaignId: 'c1'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receivedProposalsRepositoryProvider.overrideWithValue(env.repo),
          ],
          child: MaterialApp.router(routerConfig: router, theme: coraDarkTheme),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('브랜드가 좋아한 점'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
