import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/negotiation/domain/terms_version.dart';
import 'package:cora/features/negotiation/presentation/pages/agreement_page.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, ViewPay;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../chat/chat_fixtures.dart' show FakeRealtimeConnection;
import '../collaboration/fake_collaboration_repository.dart';
import 'brand_collaboration_harness.dart';
import 'fake_negotiation_repository.dart';

const _id = brandCollabId;
const _room = 'room-12';

/// 캔버스 12의 견본: 버전 2를 내가(크리에이터) 냈고(`나 · 확인함`), 브랜드는 아직이다. 제작비 300,000원 → 350,000원,
/// 제작 시작 11월 16일 → 11월 23일.
TermsHistory canvasHistory({
  bool brandConfirmed = false,
  bool creatorConfirmed = true,
  TermsProposer v2By = TermsProposer.creator,
  ViewPay? performance,
  List<TermsField> changed = const [TermsField.fee, TermsField.startDate],
  int fee = 350000,
}) => termsHistory([
  termsVersion(
    version: 2,
    fee: fee,
    startDate: DateTime(2026, 11, 23),
    performance: performance,
    previousMaxCash: 300000,
    changedFields: changed,
    proposedBy: v2By,
    brandConfirmed: brandConfirmed,
    creatorConfirmed: creatorConfirmed,
  ),
  termsVersion(version: 1, fee: 300000, proposedBy: TermsProposer.system),
]);

/// 12를 `/collaborations/:id/agreement`에 올린다. 12가 여는 경로(수정 제안, 계약, 인스타그램 연동)는 위치 글자만 보이는
/// 빈 화면이고 위치를 기록한다.
Future<List<String>> _pump(
  WidgetTester tester,
  FakeNegotiationRepository repo, {
  CollaborationRole role = CollaborationRole.creator,
  int? doneCount = 2,
  ThemeData? theme,
  bool smallPhoneLargeText = false,
  FakeRealtimeConnection? realtime,
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
    initialLocation: AppRoutes.collaborationAgreement(_id),
    routes: [
      GoRoute(
        path: AppRoutes.collaborationAgreementPattern,
        builder: (context, state) =>
            AgreementPage(collaborationId: state.pathParameters['id']!),
      ),
      for (final path in [
        AppRoutes.collaborationTermsProposePattern,
        AppRoutes.collaborationContractPattern,
        AppRoutes.creatorInstagram,
        AppRoutes.chats,
      ])
        GoRoute(path: path, builder: (context, state) => stub(state)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        negotiationRepositoryProvider.overrideWithValue(repo),
        realtimeConnectionProvider.overrideWithValue(
          realtime ?? FakeRealtimeConnection(),
        ),
        collaborationRepositoryProvider.overrideWithValue(
          FakeCollaborationRepository(
            active: [
              brandCollab(
                role: role,
                doneCount: doneCount ?? 0,
                withProgress: doneCount != null,
                conversationId: _room,
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
  return opened;
}

/// 갈라진 글자(`취소선 값` + `에서 변경`)를 한 줄로 합쳐 찾는다.
Finder _rich(String text) => find.text(text, findRichText: true);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the canvas state: version, status, both confirm marks, '
      'max cash change and the history', (tester) async {
    await _pump(tester, FakeNegotiationRepository(history: canvasHistory()));

    expect(find.text('조건 합의'), findsOneWidget);
    expect(find.text('버전 2'), findsNWidgets(2)); // 머리 상자와 변경 기록
    expect(find.text('브랜드 확인 대기 중'), findsOneWidget);
    expect(find.text('나 · 확인함'), findsOneWidget);
    expect(find.text('브랜드 · 대기'), findsOneWidget);
    expect(find.text('최대 현금 부담'), findsOneWidget);
    expect(find.text('300,000원 → 350,000원'), findsOneWidget);
    expect(find.text('대화에서 정한 조건'), findsOneWidget);
    expect(find.text('초록색은 이번 버전에서 바뀐 조건이에요.'), findsOneWidget);
    expect(find.text('변경 기록'), findsOneWidget);
    expect(find.text('버전 1'), findsOneWidget);
    expect(find.text('브랜드의 최초 제안'), findsOneWidget);
    expect(find.text('내가 제작비·일정 수정 제안'), findsOneWidget);
    expect(find.text('수정 제안'), findsOneWidget);
    expect(find.text('계약서 미리 보기'), findsOneWidget);
    expect(
      find.text('버전 1에 했던 수락은 버전 2에 적용되지 않아요. 합의 기록과 최종 계약 체결은 별도예요.'),
      findsOneWidget,
    );
    // 내가 이미 확인한 판본이라 `이 버전 수락`은 없다.
    expect(find.text('이 버전 수락'), findsNothing);
  });

  testWidgets('highlights only the fields changed in the latest version', (
    tester,
  ) async {
    await _pump(tester, FakeNegotiationRepository(history: canvasHistory()));

    // 바뀐 칸: 새 값 아래 `{이전 값}에서 변경`
    expect(find.text('350,000원'), findsOneWidget);
    expect(_rich('300,000원에서 변경'), findsOneWidget);
    expect(find.text('11월 23일'), findsOneWidget);
    expect(_rich('11월 16일에서 변경'), findsOneWidget);
    // 안 바뀐 칸에는 `에서 변경`이 없다
    expect(find.textContaining('에서 변경', findRichText: true), findsNWidgets(2));
    expect(find.text('릴스 1편'), findsOneWidget);
    expect(find.text('포함'), findsOneWidget);
    expect(find.text('기획안 기준 1회'), findsOneWidget);
    expect(find.text('브랜드 계정 재게시만'), findsOneWidget);
    expect(find.text('게시 후 7일 이내'), findsOneWidget);
    expect(find.text('광고 표시'), findsOneWidget);
    expect(find.text('영상·게시물에 명확히'), findsOneWidget);

    final c = coraLightTheme.extension<CoraColors>()!;
    Color color(String text) => tester
        .widget<RichText>(find.text(text, findRichText: true))
        .text
        .style!
        .color!;
    // 바뀐 칸 이름은 `text`, 안 바뀐 칸 이름은 `textSecondary`(캔버스)
    expect(color('제작비'), c.text);
    expect(color('제작 시작'), c.text);
    expect(color('제작물'), c.textSecondary);
    expect(color('지급 조건'), c.textSecondary);
    // 바뀐 값은 18/700, 안 바뀐 값은 16/500
    TextStyle style(String text) => tester
        .widget<RichText>(find.text(text, findRichText: true))
        .text
        .style!;
    expect(style('350,000원').fontSize, 18);
    expect(style('350,000원').fontWeight, FontWeight.w700);
    expect(style('릴스 1편').fontSize, 16);
    expect(style('릴스 1편').fontWeight, FontWeight.w500);
  });

  testWidgets('hides the performance row when there is none and it did not '
      'change, and shows it when it is on or changed', (tester) async {
    await _pump(tester, FakeNegotiationRepository(history: canvasHistory()));
    expect(find.text('성과 추가'), findsNothing);

    await _pump(
      tester,
      FakeNegotiationRepository(
        history: canvasHistory(
          performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
      ),
    );
    expect(find.text('성과 추가'), findsOneWidget);
    expect(find.text('1,000회당 2,000원 · 최대 60,000원'), findsOneWidget);

    // 이번 판본에서 껐다: 줄이 남고 이전 값이 취소선으로 보인다.
    await _pump(
      tester,
      FakeNegotiationRepository(
        history: termsHistory([
          termsVersion(
            version: 2,
            changedFields: const [TermsField.performance],
            proposedBy: TermsProposer.creator,
            creatorConfirmed: true,
          ),
          termsVersion(
            version: 1,
            performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
          ),
        ]),
      ),
    );
    expect(find.text('성과 추가'), findsOneWidget);
    expect(find.text('없음'), findsOneWidget);
    expect(_rich('1,000회당 2,000원 · 최대 60,000원에서 변경'), findsOneWidget);
  });

  testWidgets('shows a title row only when the title changed', (tester) async {
    await _pump(tester, FakeNegotiationRepository(history: canvasHistory()));
    expect(find.text('콘텐츠 제목'), findsNothing);

    await _pump(
      tester,
      FakeNegotiationRepository(
        history: termsHistory([
          termsVersion(
            version: 2,
            title: '새 제목',
            changedFields: const [TermsField.title],
            proposedBy: TermsProposer.brand,
            brandConfirmed: true,
          ),
          termsVersion(version: 1),
        ]),
      ),
      role: CollaborationRole.commissioner,
    );
    expect(find.text('콘텐츠 제목'), findsOneWidget);
    expect(find.text('새 제목'), findsOneWidget);
    expect(find.text('내가 콘텐츠 제목 수정 제안'), findsOneWidget);
  });

  testWidgets('offers accept and propose when I have not confirmed the latest '
      'version', (tester) async {
    final opened = await _pump(
      tester,
      FakeNegotiationRepository(
        history: canvasHistory(
          creatorConfirmed: false,
          brandConfirmed: true,
          v2By: TermsProposer.brand,
        ),
      )..iAmBrand = false,
    );

    expect(find.text('크리에이터 확인 대기 중'), findsOneWidget);
    expect(find.text('나 · 대기'), findsOneWidget);
    expect(find.text('브랜드 · 확인함'), findsOneWidget);
    expect(find.text('이 버전 수락'), findsOneWidget);
    expect(find.text('수정 제안'), findsOneWidget);
    expect(find.text('계약서 미리 보기'), findsOneWidget);

    await tester.tap(find.text('수정 제안'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.collaborationTermsPropose(_id));
  });

  testWidgets('accepting the version flips to agreed and offers to go to the '
      'contract', (tester) async {
    final repo = FakeNegotiationRepository(
      history: canvasHistory(
        creatorConfirmed: false,
        brandConfirmed: true,
        v2By: TermsProposer.brand,
      ),
    )..iAmBrand = false;
    final opened = await _pump(tester, repo);

    await tester.tap(find.text('이 버전 수락'));
    await tester.pumpAndSettle();

    expect(repo.confirmed.single.version, 2);
    expect(find.text('합의됨'), findsOneWidget);
    expect(find.text('나 · 확인함'), findsOneWidget);
    expect(find.text('이 버전 수락'), findsNothing);
    expect(find.text('계약서 미리 보기'), findsNothing);
    expect(find.text('계약하러 가기'), findsOneWidget);

    await tester.tap(find.text('계약하러 가기'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.collaborationContract(_id));
  });

  testWidgets('shows the stale version state when the accepted version is no '
      'longer the latest, and its button reads 12 again', (tester) async {
    final repo =
        FakeNegotiationRepository(
            history: canvasHistory(
              creatorConfirmed: false,
              brandConfirmed: true,
              v2By: TermsProposer.brand,
            ),
          )
          ..iAmBrand = false
          ..confirmFailure = const NegotiationStale(3);
    // 상대가 낸 판본 3(내가 아직 확인하지 않은 것).
    final v3 = termsHistory([
      termsVersion(
        version: 3,
        fee: 400000,
        previousMaxCash: 350000,
        changedFields: const [TermsField.fee],
        proposedBy: TermsProposer.brand,
        brandConfirmed: true,
      ),
      ...canvasHistory().versions,
    ]);
    repo.confirmFailure = const NegotiationStale(3);
    await _pump(tester, repo);
    repo.history = v3;

    await tester.tap(find.text('이 버전 수락'));
    await tester.pumpAndSettle();

    expect(find.text('이전 판본이라 수락할 수 없어요'), findsOneWidget);
    expect(find.text('상대가 판본 3을 보냈어요. 바뀐 조건을 확인한 뒤 수락해 주세요.'), findsOneWidget);
    expect(find.text('이 버전 수락'), findsNothing);

    await tester.tap(find.text('판본 3 보기'));
    await tester.pumpAndSettle();

    expect(find.text('이전 판본이라 수락할 수 없어요'), findsNothing);
    expect(find.text('버전 3'), findsNWidgets(2));
    expect(find.text('400,000원'), findsNWidgets(1));
    expect(find.text('350,000원 → 400,000원'), findsOneWidget);
    expect(find.text('이 버전 수락'), findsOneWidget);
  });

  testWidgets('a failed reload from the stale state shows the load failure and '
      'can retry', (tester) async {
    final repo =
        FakeNegotiationRepository(
            history: canvasHistory(
              creatorConfirmed: false,
              brandConfirmed: true,
              v2By: TermsProposer.brand,
            ),
          )
          ..iAmBrand = false
          ..confirmFailure = const NegotiationStale(3);
    await _pump(tester, repo);
    await tester.tap(find.text('이 버전 수락'));
    await tester.pumpAndSettle();
    repo.failFetch = true;

    await tester.tap(find.text('판본 3 보기'));
    await tester.pumpAndSettle();

    expect(find.text('조건을 불러오지 못했어요'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('조건 합의'), findsOneWidget);
    expect(find.text('이전 판본이라 수락할 수 없어요'), findsNothing);
  });

  testWidgets('asks the creator to link instagram before accepting a '
      'performance bonus', (tester) async {
    final repo = FakeNegotiationRepository(
      history: canvasHistory(
        creatorConfirmed: false,
        brandConfirmed: true,
        v2By: TermsProposer.brand,
        performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
      ),
      latest: termsLatest(
        terms: termsVersion(
          version: 2,
          performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
        needsInstagram: true,
      ),
    )..iAmBrand = false;
    final opened = await _pump(tester, repo);

    expect(find.text('인스타그램을 연동하면 수락할 수 있어요'), findsOneWidget);
    expect(find.text('연동하기'), findsOneWidget);
    expect(find.text('이 버전 수락'), findsNothing);

    await tester.tap(find.text('연동하기'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.creatorInstagram);
  });

  testWidgets('a performance bonus on a shorts version needs no instagram', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository(
      history: termsHistory([
        termsVersion(
          version: 2,
          format: ContentFormat.shorts,
          performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
          proposedBy: TermsProposer.brand,
          brandConfirmed: true,
          changedFields: const [TermsField.performance],
        ),
        termsVersion(version: 1),
      ]),
    )..iAmBrand = false;
    await _pump(tester, repo);

    expect(find.text('이 버전 수락'), findsOneWidget);
    expect(find.text('연동하기'), findsNothing);
  });

  testWidgets('shows the server message when the accept is rejected', (
    tester,
  ) async {
    final repo =
        FakeNegotiationRepository(
            history: canvasHistory(
              creatorConfirmed: false,
              brandConfirmed: true,
              v2By: TermsProposer.brand,
            ),
          )
          ..iAmBrand = false
          ..confirmFailure = const NegotiationRejected(
            '인스타그램을 연동해야 성과 추가를 수락할 수 있어요.',
          );
    await _pump(tester, repo);

    await tester.tap(find.text('이 버전 수락'));
    await tester.pumpAndSettle();

    expect(find.text('인스타그램을 연동해야 성과 추가를 수락할 수 있어요.'), findsOneWidget);
    expect(find.text('이 버전 수락'), findsOneWidget);
  });

  testWidgets('after the contract the conditions cannot be changed', (
    tester,
  ) async {
    final opened = await _pump(
      tester,
      FakeNegotiationRepository(
        history: canvasHistory(brandConfirmed: true, creatorConfirmed: true),
      ),
      doneCount: 3,
    );

    expect(find.text('합의됨'), findsOneWidget);
    expect(find.text('계약서 보기'), findsOneWidget);
    expect(find.text('계약한 뒤에는 조건을 바꿀 수 없어요.'), findsOneWidget);
    expect(find.text('수정 제안'), findsNothing);
    expect(find.text('이 버전 수락'), findsNothing);
    expect(find.bySemanticsLabel('더보기'), findsNothing);

    await tester.tap(find.text('계약서 보기'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.collaborationContract(_id));
  });

  testWidgets('after the negotiation ended it says so and offers no action', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeNegotiationRepository(history: canvasHistory()),
      doneCount: null,
    );

    expect(find.text('협의가 끝난 조건이에요.'), findsOneWidget);
    expect(find.text('수정 제안'), findsNothing);
    expect(find.text('이 버전 수락'), findsNothing);
    expect(find.text('계약서 미리 보기'), findsNothing);
    expect(find.text('계약서 보기'), findsNothing);
    expect(find.bySemanticsLabel('더보기'), findsNothing);
  });

  testWidgets('the menu drops the negotiation through the shared sheet', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository(history: canvasHistory());
    await _pump(tester, repo);

    await tester.tap(find.bySemanticsLabel('더보기'));
    await tester.pumpAndSettle();
    expect(find.text('협의 그만두기'), findsOneWidget);

    await tester.tap(find.text('협의 그만두기'));
    await tester.pumpAndSettle();
    expect(find.text('협의를 그만둘까요?'), findsOneWidget);

    await tester.tap(find.text('예산이 맞지 않아요'));
    await tester.pump();
    await tester.tap(find.text('그만두기'));
    await tester.pumpAndSettle();

    expect(repo.dropped.single.reason, DropReason.budget);
  });

  testWidgets('a rejected drop keeps the sheet open with the server message', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository(history: canvasHistory())
      ..dropFailure = const NegotiationRejected('결제가 진행 중이라 그만둘 수 없어요.');
    await _pump(tester, repo);

    await tester.tap(find.bySemanticsLabel('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('협의 그만두기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('기타'));
    await tester.pump();
    await tester.tap(find.text('그만두기'));
    await tester.pumpAndSettle();

    expect(find.text('결제가 진행 중이라 그만둘 수 없어요.'), findsOneWidget);
    expect(find.text('협의를 그만둘까요?'), findsOneWidget);
  });

  testWidgets('a load failure shows the shared failure state and retries', (
    tester,
  ) async {
    final repo = FakeNegotiationRepository(history: canvasHistory())
      ..failFetch = true;
    await _pump(tester, repo);

    expect(find.text('조건을 불러오지 못했어요'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('버전 2'), findsNWidgets(2));
  });

  testWidgets('the edit button is off while a brand payment locks the terms', (
    tester,
  ) async {
    final opened = await _pump(
      tester,
      FakeNegotiationRepository(
        history: termsHistory(canvasHistory().versions, editable: false),
      ),
    );

    await tester.tap(find.text('수정 제안'));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
  });

  testWidgets('light canvas values: boxes, buttons and the check mark', (
    tester,
  ) async {
    await _pump(tester, FakeNegotiationRepository(history: canvasHistory()));
    final c = coraLightTheme.extension<CoraColors>()!;

    // 머리 상자 `합의 상태`: 모서리 16, surface
    final status = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('브랜드 확인 대기 중'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final box = status.decoration as BoxDecoration;
    expect(box.color, c.surface);
    expect(box.borderRadius, BorderRadius.circular(16));
    // 확인 표시 칸: 라이트 rgba(255,255,255,0.7)
    final cell = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('나 · 확인함'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((cell.decoration as BoxDecoration).color, const Color(0xB3FFFFFF));
    // 버튼 높이 52, `계약서 미리 보기`는 accent
    expect(
      tester.getSize(find.text('수정 제안').hitTestable()).height,
      lessThan(52),
    );
    final primary = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('계약서 미리 보기'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((primary.decoration as BoxDecoration).color, c.accent);
    expect(primary.constraints?.maxHeight, 52);
  });

  testWidgets('dark canvas values: surface boxes and the faint cell', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeNegotiationRepository(history: canvasHistory()),
      theme: coraDarkTheme,
    );

    final cell = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('나 · 확인함'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((cell.decoration as BoxDecoration).color, const Color(0x0FFFFFFF));
    final status = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('브랜드 확인 대기 중'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((status.decoration as BoxDecoration).color, const Color(0xFF1C1E22));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor ??
          Theme.of(
            tester.element(find.byType(Scaffold)),
          ).scaffoldBackgroundColor,
      const Color(0xFF0F1012),
    );
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _pump(
      tester,
      FakeNegotiationRepository(
        history: canvasHistory(
          creatorConfirmed: false,
          brandConfirmed: true,
          v2By: TermsProposer.brand,
          performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
      )..iAmBrand = false,
      smallPhoneLargeText: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('수정 제안'), findsOneWidget);
  });

  group('realtime refresh', () {
    FakeNegotiationRepository waiting() => FakeNegotiationRepository(
      history: canvasHistory(
        creatorConfirmed: false,
        brandConfirmed: true,
        v2By: TermsProposer.brand,
      ),
    )..iAmBrand = false;

    testWidgets('reloads when the room of this collaboration says the terms '
        'changed', (tester) async {
      final realtime = FakeRealtimeConnection();
      final repo = waiting();
      await _pump(tester, repo, realtime: realtime);
      expect(find.text('버전 2'), findsNWidgets(2));
      final reads = repo.historyCalls;

      // 상대가 판본 3을 냈다.
      repo.history = termsHistory([
        termsVersion(
          version: 3,
          fee: 400000,
          previousMaxCash: 350000,
          changedFields: const [TermsField.fee],
          proposedBy: TermsProposer.brand,
          brandConfirmed: true,
        ),
        ...repo.history.versions,
      ]);
      realtime.emit(
        const ConversationUpdated(
          conversationId: _room,
          reason: ConversationUpdateReason.terms,
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.historyCalls, greaterThan(reads));
      expect(find.text('350,000원 → 400,000원'), findsOneWidget);
      expect(find.text('이전 판본이라 수락할 수 없어요'), findsNothing);
    });

    testWidgets('ignores another room and read-only updates', (tester) async {
      final realtime = FakeRealtimeConnection();
      final repo = waiting();
      await _pump(tester, repo, realtime: realtime);
      final reads = repo.historyCalls;

      realtime
        ..emit(
          const ConversationUpdated(
            conversationId: 'other-room',
            reason: ConversationUpdateReason.terms,
          ),
        )
        ..emit(
          const ConversationUpdated(
            conversationId: _room,
            reason: ConversationUpdateReason.read,
          ),
        );
      await tester.pumpAndSettle();

      expect(repo.historyCalls, reads);
    });

    testWidgets('reloads after a reconnect and keeps the screen when the read '
        'fails', (tester) async {
      final realtime = FakeRealtimeConnection();
      final repo = waiting();
      await _pump(tester, repo, realtime: realtime);
      final reads = repo.historyCalls;

      realtime.emitReconnected();
      await tester.pumpAndSettle();
      expect(repo.historyCalls, greaterThan(reads));

      repo.failFetch = true;
      realtime.emit(
        const ConversationUpdated(
          conversationId: _room,
          reason: ConversationUpdateReason.status,
        ),
      );
      await tester.pumpAndSettle();

      // 못 읽어도 화면과 안내는 그대로다.
      expect(find.text('버전 2'), findsNWidgets(2));
      expect(find.text('처리하지 못했어요. 다시 시도해 주세요.'), findsNothing);
    });
  });

  testWidgets('keeps the confirm mark on one line in the narrow cell', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeNegotiationRepository(
        history: canvasHistory(creatorConfirmed: true, brandConfirmed: false),
      )..iAmBrand = false,
      role: CollaborationRole.commissioner,
    );

    final line = find.text('크리에이터 · 확인함');
    expect(line, findsOneWidget);
    // 14px 글자 한 줄(줄 높이 1.448)이다.
    expect(tester.getSize(line).height, lessThan(14 * 1.448 * 1.5));
  });
}
