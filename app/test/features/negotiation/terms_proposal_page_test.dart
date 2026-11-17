import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/time/clock.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/negotiation/domain/terms_version.dart';
import 'package:cora/features/negotiation/presentation/pages/terms_proposal_page.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, ViewPay;
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../server_config/fake_server_config_repository.dart';
import 'fake_negotiation_repository.dart';

const _id = 'c0ffee11-aaaa-bbbb-cccc-000000000009';
const _performance = ViewPay(ratePerThousand: 2000, cap: 60000);

/// 판본 2(제작비 300,000원, 제품 제공, 성과 추가 켜짐, 릴스 1편)를 바탕으로 고친다.
FakeNegotiationRepository _repo({
  ViewPay? performance = _performance,
  ContentFormat format = ContentFormat.reels,
  DateTime? startDate,
}) => FakeNegotiationRepository(
  latest: termsLatest(
    terms: termsVersion(
      version: 2,
      title: '출근 전 30초, 오늘의 손목 루틴',
      fee: 300000,
      performance: performance,
      format: format,
      startDate: startDate ?? DateTime(2026, 11, 20),
      proposedBy: TermsProposer.brand,
      brandConfirmed: true,
    ),
  ),
);

/// 수정 제안을 연다. [fromAgreement]면 12 자리의 화면에서 `push`한 것처럼 열어, 보낸 뒤 돌아가는 곳을 본다. 12와 계약
/// 경로는 위치 글자만 보이는 빈 화면이고 위치를 기록한다.
Future<List<String>> _pump(
  WidgetTester tester,
  FakeNegotiationRepository repo, {
  bool fromAgreement = false,
  ThemeData? theme,
  bool smallPhoneLargeText = false,
  FakeServerConfigRepository? config,
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
    initialLocation: fromAgreement
        ? '/start'
        : AppRoutes.collaborationTermsPropose(_id),
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push(
                AppRoutes.collaborationTermsPropose(_id),
                extra: AppRoutes.fromAgreement,
              ),
              child: const Text('open proposal'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.collaborationTermsProposePattern,
        builder: (context, state) => TermsProposalPage(
          collaborationId: state.pathParameters['id']!,
          fromAgreement: state.extra == AppRoutes.fromAgreement,
        ),
      ),
      GoRoute(
        path: AppRoutes.collaborationAgreementPattern,
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
        negotiationRepositoryProvider.overrideWithValue(repo),
        serverConfigRepositoryProvider.overrideWithValue(
          config ?? FakeServerConfigRepository(),
        ),
        // 2026-11-18 오전(한국 시간)
        clockProvider.overrideWithValue(
          FakeClock()..current = DateTime.utc(2026, 11, 18, 1),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (fromAgreement) {
    await tester.tap(find.text('open proposal'));
    await tester.pumpAndSettle();
  }
  return opened;
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await _scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// 보내기 버튼이 켜져 있는지(눌리는지).
bool _sendEnabled(WidgetTester tester) =>
    tester
        .widget<CoraPrimaryButton>(
          find.widgetWithText(CoraPrimaryButton, '제안 보내기'),
        )
        .onPressed !=
    null;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the base version, the nine fields and the fixed ad mark', (
    tester,
  ) async {
    await _pump(tester, _repo());

    expect(find.text('조건 수정 제안'), findsOneWidget);
    expect(find.text('버전 2를 바탕으로 고쳐요.'), findsOneWidget);
    expect(find.text('콘텐츠 제목'), findsWidgets);
    expect(find.text('출근 전 30초, 오늘의 손목 루틴'), findsOneWidget);
    // F1의 보상 편집 위젯(브랜드 이름)
    for (final text in ['혜택', '제품 제공', '현금 고정비', '성과 추가']) {
      await _scrollTo(tester, find.text(text));
      expect(find.text(text), findsOneWidget, reason: text);
    }
    // 최대 현금 부담 = 제작비 + 성과 추가 상한
    await _scrollTo(tester, find.text('최대 현금 부담'));
    expect(find.text('360,000원'), findsOneWidget);
    for (final text in ['제작물', '제작 시작', '수정 범위', '활용 권한', '지급 조건']) {
      await _scrollTo(tester, find.text(text).first);
      expect(find.text(text), findsWidgets, reason: text);
    }
    await _scrollTo(tester, find.text('영상·게시물에 명확히'));
    expect(find.text('광고 표시'), findsOneWidget);
    expect(find.text('영상·게시물에 명확히'), findsOneWidget);
    expect(find.text('제안 보내기'), findsOneWidget);
  });

  testWidgets('send proposal is disabled until a field changes', (
    tester,
  ) async {
    await _pump(tester, _repo());

    expect(_sendEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), '새 제목');
    await tester.pumpAndSettle();

    expect(_sendEnabled(tester), isTrue);

    // 원래 값으로 되돌리면 다시 꺼진다.
    await tester.enterText(find.byType(TextField), '출근 전 30초, 오늘의 손목 루틴');
    await tester.pumpAndSettle();

    expect(_sendEnabled(tester), isFalse);
  });

  testWidgets('a title-only edit keeps the performance bonus on and sends all '
      'nine fields filled from the latest version', (tester) async {
    final repo = _repo();
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), '  새 제목  ');
    await tester.pumpAndSettle();
    await _tap(tester, '제안 보내기');

    final sent = repo.proposed.single;
    expect(sent.id, _id);
    expect(sent.baseVersion, 2);
    final c = sent.changes;
    expect(c.title, '새 제목');
    expect(c.fee, 300000);
    expect(c.productProvided, isTrue);
    expect(c.performance, _performance);
    expect(c.startDate, DateTime(2026, 11, 20));
    expect(c.format, ContentFormat.reels);
    expect(c.pieces, 1);
    expect(c.revisionScope, RevisionScope.guideOnce);
    expect(c.usageRights, BrandUsageRights.repostOnly);
    expect(c.payoutDays, 7);
  });

  testWidgets('turning the format to a blog post switches the performance '
      'bonus off and says why', (tester) async {
    final repo = _repo();
    await _pump(tester, repo);

    await _tap(tester, '블로그 글');

    await _scrollTo(tester, find.text('블로그 글은 조회수를 셀 수 없어요.'));
    expect(find.text('블로그 글은 조회수를 셀 수 없어요.'), findsOneWidget);
    // 성과 추가 상한이 빠져 최대 현금 부담은 제작비만이다.
    await _scrollTo(tester, find.text('최대 현금 부담'));
    expect(find.text('300,000원'), findsOneWidget);
    // 바뀐 항목에 점과 이름이 붙는다.
    expect(find.text('성과 추가'), findsWidgets);
    expect(find.bySemanticsLabel('바뀐 항목'), findsWidgets);

    await _tap(tester, '제안 보내기');

    final c = repo.proposed.single.changes;
    expect(c.format, ContentFormat.blog);
    expect(c.performance, isNull);
  });

  testWidgets('changing the fee through the shared reward widget updates the '
      'max cash and the change dot', (tester) async {
    final repo = _repo(performance: null);
    await _pump(tester, repo);
    await _scrollTo(tester, find.text('최대 현금 부담'));
    expect(find.text('300,000원'), findsOneWidget);

    await _tap(tester, '50만 원');

    await _scrollTo(tester, find.text('최대 현금 부담'));
    expect(find.text('500,000원'), findsOneWidget);
    expect(find.text('제작비'), findsOneWidget); // 바뀐 항목 줄의 이름
    expect(find.bySemanticsLabel('바뀐 항목'), findsOneWidget);

    await _tap(tester, '제안 보내기');
    expect(repo.proposed.single.changes.fee, 500000);
    expect(repo.proposed.single.changes.performance, isNull);
  });

  testWidgets('the other fields are picked from their choices', (tester) async {
    final repo = _repo();
    await _pump(tester, repo);

    await _tap(tester, '2편');
    await _tap(tester, '초안 기준 2회');
    await _tap(tester, '광고 소재로도 사용');
    await _tap(tester, '게시 후 14일 이내');
    await _tap(tester, '제안 보내기');

    final c = repo.proposed.single.changes;
    expect(c.pieces, 2);
    expect(c.revisionScope, RevisionScope.draftTwice);
    expect(c.usageRights, BrandUsageRights.adsToo);
    expect(c.payoutDays, 14);
    // 안 건드린 값은 최신 판본 그대로다.
    expect(c.fee, 300000);
    expect(c.performance, _performance);
  });

  testWidgets('picking a start date marks it changed and sends the date', (
    tester,
  ) async {
    final repo = _repo();
    await _pump(tester, repo);

    await _tap(tester, '11월 20일');
    // 오늘(11월 18일)부터 고른다. 지난 날은 없다.
    expect(find.text('11월 18일 (수)'), findsOneWidget);
    expect(find.text('11월 17일 (화)'), findsNothing);
    await tester.tap(find.text('11월 23일 (월)'));
    await tester.pumpAndSettle();

    expect(find.text('11월 23일'), findsOneWidget);
    await _tap(tester, '제안 보내기');
    expect(repo.proposed.single.changes.startDate, DateTime(2026, 11, 23));
  });

  testWidgets('a sent proposal returns to 12 with the new version in a toast', (
    tester,
  ) async {
    final repo = _repo();
    final opened = await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), '새 제목');
    await tester.pumpAndSettle();
    await _tap(tester, '제안 보내기');

    expect(find.text('조건 버전 3을 제안했어요.'), findsOneWidget);
    expect(opened.last, AppRoutes.collaborationAgreement(_id));
  });

  testWidgets('a proposal opened from 12 goes back to it instead of stacking '
      'another', (tester) async {
    final repo = _repo();
    await _pump(tester, repo, fromAgreement: true);

    await tester.enterText(find.byType(TextField), '새 제목');
    await tester.pumpAndSettle();
    await _tap(tester, '제안 보내기');

    expect(find.text('조건 버전 3을 제안했어요.'), findsOneWidget);
    expect(find.text('open proposal'), findsOneWidget);
    expect(find.text('조건 수정 제안'), findsNothing);
  });

  testWidgets('a conflicting proposal reloads the latest version', (
    tester,
  ) async {
    final repo = _repo()..proposeFailure = const NegotiationStale(3);
    final opened = await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), '새 제목');
    await tester.pumpAndSettle();
    await _tap(tester, '제안 보내기');

    // 수락이 아니라서 F8 화면이 아니라 이 안내를 보인다.
    expect(find.text('상대가 먼저 새 조건을 제안했어요. 최신 조건을 확인해 주세요.'), findsOneWidget);
    expect(find.text('이전 판본이라 수락할 수 없어요'), findsNothing);
    expect(opened.last, AppRoutes.collaborationAgreement(_id));
  });

  testWidgets('another rejection shows the server message and keeps the '
      'edits', (tester) async {
    final repo = _repo()
      ..proposeFailure = const NegotiationRejected('결제가 진행 중이라 조건을 바꿀 수 없어요.');
    final opened = await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), '새 제목');
    await tester.pumpAndSettle();
    await _tap(tester, '제안 보내기');

    expect(find.text('결제가 진행 중이라 조건을 바꿀 수 없어요.'), findsOneWidget);
    expect(find.text('새 제목'), findsOneWidget);
    expect(opened, isEmpty);
    expect(_sendEnabled(tester), isTrue);
  });

  testWidgets('a plain failure shows the generic message', (tester) async {
    final repo = _repo()..proposeFailure = const NegotiationFailure();
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), '새 제목');
    await tester.pumpAndSettle();
    await _tap(tester, '제안 보내기');

    expect(find.text('제안을 보내지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('a load failure shows the shared failure state and retries', (
    tester,
  ) async {
    final repo = _repo()..failFetch = true;
    await _pump(tester, repo);

    expect(find.text('조건을 불러오지 못했어요'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('버전 2를 바탕으로 고쳐요.'), findsOneWidget);
  });

  testWidgets('dark theme shows the same screen', (tester) async {
    await _pump(tester, _repo(), theme: coraDarkTheme);

    expect(find.text('버전 2를 바탕으로 고쳐요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _pump(tester, _repo(), smallPhoneLargeText: true);

    expect(tester.takeException(), isNull);
    expect(find.text('제안 보내기'), findsOneWidget);
  });

  testWidgets('shows the measurement period equal to the payout term', (
    tester,
  ) async {
    await _pump(tester, _repo());

    await _scrollTo(tester, find.text('게시 후 7일'));
    expect(find.text('게시 후 7일'), findsOneWidget);

    await _tap(tester, '게시 후 14일 이내');

    await _scrollTo(tester, find.text('게시 후 14일'));
    expect(find.text('게시 후 14일'), findsOneWidget);
    expect(find.text('게시 후 7일'), findsNothing);
  });

  testWidgets('a blank title is not a change and cannot be sent', (
    tester,
  ) async {
    await _pump(tester, _repo());

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();

    expect(_sendEnabled(tester), isFalse);
    expect(find.bySemanticsLabel('바뀐 항목'), findsNothing);

    // 다른 항목을 바꿔도 제목이 비어 있으면 보낼 수 없다.
    await _tap(tester, '2편');
    expect(_sendEnabled(tester), isFalse);
  });

  testWidgets('the start date has one label, not two', (tester) async {
    await _pump(tester, _repo());

    await _scrollTo(tester, find.text('날짜 고르기'));
    expect(find.text('제작 시작'), findsOneWidget);
    expect(find.text('날짜 고르기'), findsOneWidget);
  });
}
