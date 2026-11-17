import 'dart:async';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/negotiation/domain/contract.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/negotiation/presentation/pages/contract_page.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart' show ViewPay;
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora/features/payment/presentation/checkout_launcher.dart';
import 'package:cora/features/payment/presentation/viewmodels/payment_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../chat/chat_fixtures.dart' show FakeRealtimeConnection;
import '../collaboration/fake_collaboration_repository.dart';
import '../payment/fake_payment_repository.dart';
import 'brand_collaboration_harness.dart';
import 'fake_negotiation_repository.dart';

const _id = brandCollabId;
const _room = 'room-d4';

const _fastPolling = PaymentPolling(
  interval: Duration(milliseconds: 10),
  attempts: 3,
);

class _Harness {
  _Harness({
    required this.repo,
    required this.payments,
    required this.launcher,
    required this.realtime,
    required this.router,
    required this.opened,
  });

  final FakeNegotiationRepository repo;
  final FakePaymentRepository payments;
  final FakeCheckoutLauncher launcher;
  final FakeRealtimeConnection realtime;
  final GoRouter router;
  final List<String> opened;
}

/// D4를 `/collaborations/:id/contract`에 올린다. D4가 여는 경로(12, 07)는 위치 글자만 보이는 빈 화면이고 위치를
/// 기록한다. `/elsewhere`는 D4를 떠났다 다시 올 때 쓴다.
Future<_Harness> _pump(
  WidgetTester tester,
  FakeNegotiationRepository repo, {
  CollaborationRole role = CollaborationRole.creator,
  FakePaymentRepository? payments,
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
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: AppRoutes.collaborationContract(_id),
    routes: [
      GoRoute(
        path: AppRoutes.collaborationContractPattern,
        builder: (context, state) =>
            ContractPage(collaborationId: state.pathParameters['id']!),
      ),
      for (final path in [
        AppRoutes.collaborationAgreementPattern,
        AppRoutes.collaborationProgressPattern,
        '/elsewhere',
      ])
        GoRoute(path: path, builder: (context, state) => stub(state)),
    ],
  );
  addTearDown(router.dispose);
  final realtime = FakeRealtimeConnection();
  final launcher = FakeCheckoutLauncher();
  final pay = payments ?? FakePaymentRepository();
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        negotiationRepositoryProvider.overrideWithValue(repo),
        realtimeConnectionProvider.overrideWithValue(realtime),
        paymentRepositoryProvider.overrideWithValue(pay),
        checkoutLauncherProvider.overrideWithValue(launcher),
        paymentPollingProvider.overrideWithValue(_fastPolling),
        collaborationRepositoryProvider.overrideWithValue(
          FakeCollaborationRepository(
            active: [brandCollab(role: role, conversationId: _room)],
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
  return _Harness(
    repo: repo,
    payments: pay,
    launcher: launcher,
    realtime: realtime,
    router: router,
    opened: opened,
  );
}

/// 확인란 줄을 차례로 켠다.
Future<void> _checkAll(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    // 결제 상자가 있으면 확인란이 화면 아래로 밀려 있다.
    await tester.ensureVisible(find.text(label));
    await tester.pump();
    await tester.tap(find.text(label));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// 아래 버튼이 `동의하고 계약하기`이고 켜져 있다. 꺼진 자리는 같은 글이어도 `false`다.
bool _consentOn(WidgetTester tester) {
  final button = find.widgetWithText(CoraPrimaryButton, '동의하고 계약하기');
  return button.evaluate().isNotEmpty &&
      tester.widget<CoraPrimaryButton>(button).onPressed != null;
}

const _creatorTexts = [
  '합의한 조건 버전 2를 확인했어요',
  '광고 표시 의무를 지킬게요',
  '콘텐츠는 브랜드 계정 재게시에만 쓰여요',
];
const _brandTexts = [
  '합의한 조건 버전 2를 확인했어요',
  '광고 표시를 요청할게요',
  '콘텐츠는 브랜드 계정 재게시에만 쓰여요',
];

final _withPerformance = termsVersion(
  version: 2,
  fee: 350000,
  startDate: DateTime(2026, 11, 23),
  performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
  brandConfirmed: true,
  creatorConfirmed: true,
);

void main() {
  setUpAll(loadAppFonts);

  group('creator', () {
    testWidgets('the consent button turns on only after all three boxes', (
      tester,
    ) async {
      final h = await _pump(tester, FakeNegotiationRepository());

      expect(find.text('협업 계약'), findsOneWidget);
      expect(find.textContaining('합의한 버전 2로'), findsOneWidget);
      expect(find.text('양쪽이 모두 동의하면 계약이 체결되고 제작이 시작돼요.'), findsOneWidget);
      // 캔버스의 요약 칸.
      expect(find.text('서윤의 작은 취향'), findsOneWidget);
      expect(find.text('모아 스튜디오'), findsOneWidget);
      expect(find.text('릴스 1편'), findsOneWidget);
      expect(find.text('350,000원 + 제품'), findsOneWidget);
      expect(find.text('11월 23일'), findsOneWidget);
      expect(find.text('게시 후 7일 이내'), findsOneWidget);
      // 성과 추가가 없으면 두 줄이 없다.
      expect(find.text('성과 추가'), findsNothing);
      expect(find.text('최대 현금 부담'), findsNothing);

      expect(find.text('모두 확인하면 계약할 수 있어요'), findsOneWidget);
      expect(_consentOn(tester), isFalse);

      await tester.tap(find.text(_creatorTexts[0]));
      await tester.tap(find.text(_creatorTexts[1]));
      await tester.pumpAndSettle();
      // 둘만 확인했을 때는 그대로 꺼져 있다.
      expect(find.text('모두 확인하면 계약할 수 있어요'), findsOneWidget);

      await tester.tap(find.text(_creatorTexts[2]));
      await tester.pumpAndSettle();
      expect(find.text('모두 확인하면 계약할 수 있어요'), findsNothing);
      expect(_consentOn(tester), isTrue);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();
      expect(h.repo.creatorConsents, hasLength(1));
      expect(h.repo.creatorConsents.single.version, 2);
      // 서버가 준 문구를 그대로 보낸다.
      expect(h.repo.creatorConsents.single.accepted, _creatorTexts);
    });

    testWidgets('turning a box off turns the button off again', (tester) async {
      await _pump(tester, FakeNegotiationRepository());
      await _checkAll(tester, _creatorTexts);
      expect(_consentOn(tester), isTrue);

      await tester.tap(find.text(_creatorTexts[1]));
      await tester.pumpAndSettle();

      expect(_consentOn(tester), isFalse);
      expect(find.text('모두 확인하면 계약할 수 있어요'), findsOneWidget);
    });

    testWidgets('the creator waits for the brand after consenting', (
      tester,
    ) async {
      final h = await _pump(tester, FakeNegotiationRepository());
      await _checkAll(tester, _creatorTexts);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(
        find.text('브랜드 동의를 기다리고 있어요. 계약서는 체결 후 보관함에 저장돼요.'),
        findsOneWidget,
      );
      // 버튼은 꺼져 있고, 한 번 더 보내지 못한다.
      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();
      expect(h.repo.creatorConsents, hasLength(1));
      // 결제 상자는 크리에이터에게 없다.
      expect(find.text('동의하면 결제할 금액'), findsNothing);
    });

    testWidgets('shows the second box in the creator wording', (tester) async {
      await _pump(tester, FakeNegotiationRepository());

      expect(find.text('광고 표시 의무를 지킬게요'), findsOneWidget);
      expect(find.text('광고 표시를 요청할게요'), findsNothing);
    });

    testWidgets('shows the stale version state when consenting to an older '
        'version', (tester) async {
      final repo = FakeNegotiationRepository()
        ..creatorConsentFailure = const NegotiationStale(3);
      final h = await _pump(tester, repo);
      await _checkAll(tester, _creatorTexts);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(find.text('이전 판본이라 수락할 수 없어요'), findsOneWidget);
      expect(
        find.text('상대가 판본 3을 보냈어요. 바뀐 조건을 확인한 뒤 수락해 주세요.'),
        findsOneWidget,
      );
      expect(find.text('협업 계약'), findsOneWidget);

      // F8의 버튼은 12로 간다(Q17).
      await tester.tap(find.text('판본 3 보기'));
      await tester.pumpAndSettle();
      expect(h.opened.last, AppRoutes.collaborationAgreement(_id));
    });

    testWidgets('a rejected consent shows the server wording and keeps the '
        'boxes', (tester) async {
      final repo = FakeNegotiationRepository()
        ..creatorConsentFailure = const NegotiationRejected(
          '지금은 계약에 동의할 수 없어요.',
        );
      await _pump(tester, repo);
      await _checkAll(tester, _creatorTexts);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(find.text('지금은 계약에 동의할 수 없어요.'), findsOneWidget);
      expect(_consentOn(tester), isTrue);
    });

    testWidgets('a failure shows the general wording', (tester) async {
      final repo = FakeNegotiationRepository()
        ..creatorConsentFailure = const NegotiationFailure();
      await _pump(tester, repo);
      await _checkAll(tester, _creatorTexts);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(find.text('처리하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(_consentOn(tester), isTrue);
    });

    testWidgets('shows the performance bonus and the max cash in the summary', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(terms: _withPerformance),
      );

      expect(find.text('성과 추가'), findsOneWidget);
      expect(find.text('1,000회당 2,000원 · 최대 60,000원'), findsOneWidget);
      expect(find.text('최대 현금 부담'), findsOneWidget);
      expect(find.text('410,000원'), findsOneWidget);
    });

    testWidgets('a preview before agreement keeps the boxes off and says why', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(status: ContractStatus.notReady),
      );

      expect(find.text('양쪽이 같은 버전을 확인하면 계약할 수 있어요.'), findsOneWidget);
      // 확인란이 보이지만 누를 수 없다.
      await tester.tap(find.text(_creatorTexts[0]));
      await tester.pumpAndSettle();
      expect(_consentOn(tester), isFalse);
      expect(h.repo.creatorConsents, isEmpty);
      expect(find.text('동의하고 계약하기'), findsOneWidget);
    });

    testWidgets('shows the voided banner once after the terms changed', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(voidedNotice: true),
      );

      expect(find.text('조건이 바뀌어 동의가 취소됐어요. 새 조건을 확인해 주세요.'), findsOneWidget);

      // 떠났다 같은 판본의 계약으로 다시 오면 띠는 이미 본 것이라 없다.
      h.router.go('/elsewhere');
      await tester.pumpAndSettle();
      h.router.go(AppRoutes.collaborationContract(_id));
      await tester.pumpAndSettle();

      expect(find.text('협업 계약'), findsOneWidget);
      expect(find.text('조건이 바뀌어 동의가 취소됐어요. 새 조건을 확인해 주세요.'), findsNothing);
    });

    testWidgets('a new version brings the banner back and clears the boxes', (
      tester,
    ) async {
      final repo = FakeNegotiationRepository()
        ..contract = sampleContract(voidedNotice: true);
      final h = await _pump(tester, repo);
      await _checkAll(tester, _creatorTexts);
      expect(_consentOn(tester), isTrue);

      // 상대가 새 판본(3)을 내 협의가 다시 열리고 확인란 문구가 달라진다.
      repo.contract = sampleContract(
        status: ContractStatus.notReady,
        terms: termsVersion(version: 3, fee: 400000),
        voidedNotice: true,
      );
      h.realtime.emit(
        const ConversationUpdated(
          conversationId: _room,
          reason: ConversationUpdateReason.terms,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('합의한 버전 3으로'), findsOneWidget);
      expect(_consentOn(tester), isFalse);
      expect(find.text('양쪽이 같은 버전을 확인하면 계약할 수 있어요.'), findsOneWidget);
    });

    testWidgets('reads again when the brand concludes the contract', (
      tester,
    ) async {
      final repo = FakeNegotiationRepository()
        ..contract = sampleContract(status: ContractStatus.awaitingBrand);
      final h = await _pump(tester, repo);
      expect(
        find.text('브랜드 동의를 기다리고 있어요. 계약서는 체결 후 보관함에 저장돼요.'),
        findsOneWidget,
      );

      repo.contract = sampleContract(status: ContractStatus.concluded);
      h.realtime.emit(
        const ConversationUpdated(
          conversationId: _room,
          reason: ConversationUpdateReason.status,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('계약이 체결됐어요.'), findsOneWidget);
      expect(find.text('11월 23일 체결'), findsOneWidget);
    });
  });

  group('brand', () {
    testWidgets('shows the brand wording on the second box', (tester) async {
      await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(
            status: ContractStatus.awaitingBrand,
            brand: true,
          ),
        role: CollaborationRole.commissioner,
      );

      expect(find.text('광고 표시를 요청할게요'), findsOneWidget);
      expect(find.text('광고 표시 의무를 지킬게요'), findsNothing);
    });

    testWidgets('waits for the creator before the brand can consent', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(
            status: ContractStatus.awaitingCreator,
            brand: true,
          ),
        role: CollaborationRole.commissioner,
      );

      expect(find.text('크리에이터의 동의를 기다리고 있어요.'), findsOneWidget);
      expect(find.text('동의하면 결제할 금액'), findsNothing);
      await tester.tap(find.text(_brandTexts[0]));
      await tester.pumpAndSettle();
      expect(_consentOn(tester), isFalse);
      expect(h.repo.brandConsents, isEmpty);
    });

    testWidgets('the brand pays the fee plus the service fee and sees the '
        'contract concluded', (tester) async {
      final repo = FakeNegotiationRepository()
        ..contract = sampleContract(
          status: ContractStatus.awaitingBrand,
          brand: true,
        );
      final h = await _pump(
        tester,
        repo,
        role: CollaborationRole.commissioner,
        payments: FakePaymentRepository(statuses: [PaymentStatus.approved]),
      );

      // 결제 상자(서버 견적).
      expect(find.text('제작비'), findsNWidgets(2)); // 요약 칸과 결제 상자
      expect(find.text('350,000원'), findsNWidgets(1));
      expect(find.text('서비스 수수료'), findsOneWidget);
      expect(find.text('35,000원'), findsOneWidget);
      expect(find.text('동의하면 결제할 금액'), findsOneWidget);
      expect(find.text('385,000원'), findsOneWidget);
      expect(find.text('카드'), findsOneWidget);
      expect(find.text('계좌이체'), findsOneWidget);
      expect(find.text('간편결제'), findsOneWidget);
      expect(
        find.text('결제 금액은 Cora가 보관하다가, 콘텐츠가 게시되고 7일째에 크리에이터에게 지급해요.'),
        findsOneWidget,
      );
      expect(find.textContaining('성과 추가는 조회수만큼'), findsNothing);

      await tester.tap(find.text('계좌이체'));
      await tester.pumpAndSettle();
      await _checkAll(tester, _brandTexts);

      // 결제창이 닫히면 서버가 체결한 것으로 바뀐다.
      h.launcher.onOpen = () {
        repo.contract = sampleContract(
          status: ContractStatus.concluded,
          brand: true,
        );
      };
      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(h.repo.brandConsents, hasLength(1));
      expect(h.repo.brandConsents.single.accepted, _brandTexts);
      expect(h.repo.brandConsents.single.method, PaymentMethod.transfer);
      expect(h.launcher.opened.single.amount, 385000);
      expect(find.text('계약이 체결됐어요.'), findsOneWidget);
      expect(find.text('11월 23일 체결'), findsOneWidget);
      // 체결되면 결제 상자와 확인란은 사라진다.
      expect(find.text('동의하면 결제할 금액'), findsNothing);
      expect(find.text(_brandTexts[1]), findsNothing);

      await tester.tap(find.text('협업 진행 보기'));
      await tester.pumpAndSettle();
      expect(h.opened.last, AppRoutes.collaborationProgress(_id));
    });

    testWidgets('shows the performance bonus and the max cash in the summary '
        'and the payment box', (tester) async {
      await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(
            status: ContractStatus.awaitingBrand,
            brand: true,
            terms: _withPerformance,
          ),
        role: CollaborationRole.commissioner,
      );

      // 요약: 두 줄이 더해진다.
      expect(find.text('1,000회당 2,000원 · 최대 60,000원'), findsOneWidget);
      expect(find.text('최대 현금 부담'), findsOneWidget);
      expect(find.text('410,000원'), findsOneWidget);
      // 결제 상자: 제작비 아래 성과 추가(최대), 수수료, 합계.
      expect(find.text('성과 추가 (최대)'), findsOneWidget);
      expect(find.text('60,000원'), findsOneWidget);
      expect(find.text('41,000원'), findsOneWidget);
      expect(find.text('451,000원'), findsOneWidget);
      expect(
        find.text(
          '결제 금액은 Cora가 보관하다가, 콘텐츠가 게시되고 7일째에 크리에이터에게 지급해요. '
          '성과 추가는 조회수만큼 지급하고, 남으면 집계 후 환불해요.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the server quote as is, even while paying', (
      tester,
    ) async {
      // 앱은 다시 계산하지 않는다: 결제 행의 실제 금액이 내려오면 그 값을 그대로 보인다.
      await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(
            status: ContractStatus.paying,
            brand: true,
            quote: contractQuote(fee: 12345),
          ),
        role: CollaborationRole.commissioner,
      );

      expect(find.text('12,345원'), findsOneWidget);
      expect(find.text('362,345원'), findsOneWidget);
      expect(find.text('385,000원'), findsNothing);
    });

    testWidgets('a failed payment keeps the contract unsigned with a retry '
        'message', (tester) async {
      final repo = FakeNegotiationRepository()
        ..contract = sampleContract(
          status: ContractStatus.awaitingBrand,
          brand: true,
        );
      final h = await _pump(
        tester,
        repo,
        role: CollaborationRole.commissioner,
        payments: FakePaymentRepository(
          statuses: [PaymentStatus.failed, PaymentStatus.approved],
        ),
      );
      await _checkAll(tester, _brandTexts);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(find.text('결제가 완료되지 않았어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('계약이 체결됐어요.'), findsNothing);
      // 확인란과 결제 상자가 그대로라 바로 다시 시도할 수 있다.
      expect(find.text('동의하면 결제할 금액'), findsOneWidget);
      expect(_consentOn(tester), isTrue);

      h.launcher.onOpen = () {
        repo.contract = sampleContract(
          status: ContractStatus.concluded,
          brand: true,
        );
      };
      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(h.repo.brandConsents, hasLength(2));
      expect(find.text('계약이 체결됐어요.'), findsOneWidget);
      expect(find.text('결제가 완료되지 않았어요. 다시 시도해 주세요.'), findsNothing);
    });

    testWidgets('a payment that never settles stays retryable', (tester) async {
      final h = await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(
            status: ContractStatus.awaitingBrand,
            brand: true,
          ),
        role: CollaborationRole.commissioner,
        payments: FakePaymentRepository(),
      );
      await _checkAll(tester, _brandTexts);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(h.payments.statusCalls, 3);
      expect(find.text('결제가 완료되지 않았어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(_consentOn(tester), isTrue);
    });

    testWidgets('shows a checking state while the payment is confirmed', (
      tester,
    ) async {
      final payments = FakePaymentRepository()..holdStatus = Completer<void>();
      await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(
            status: ContractStatus.awaitingBrand,
            brand: true,
          ),
        role: CollaborationRole.commissioner,
        payments: payments,
      );
      await _checkAll(tester, _brandTexts);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('결제를 확인하고 있어요'), findsOneWidget);
      expect(find.bySemanticsLabel('결제를 확인하고 있어요'), findsOneWidget);

      payments.holdStatus!.complete();
      await tester.pumpAndSettle();
      expect(find.text('결제를 확인하고 있어요'), findsNothing);
    });

    testWidgets('a checkout that cannot open leaves things retryable', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(
            status: ContractStatus.awaitingBrand,
            brand: true,
          ),
        role: CollaborationRole.commissioner,
      );
      h.launcher.failWith = StateError('no checkout');
      await _checkAll(tester, _brandTexts);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(find.text('결제를 시작하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(_consentOn(tester), isTrue);
    });

    testWidgets('shows the stale version state when the brand consents to an '
        'older version', (tester) async {
      final repo = FakeNegotiationRepository()
        ..contract = sampleContract(
          status: ContractStatus.awaitingBrand,
          brand: true,
        )
        ..brandConsentFailure = const NegotiationStale(4);
      final h = await _pump(tester, repo, role: CollaborationRole.commissioner);
      await _checkAll(tester, _brandTexts);

      await tester.tap(find.text('동의하고 계약하기'));
      await tester.pumpAndSettle();

      expect(find.text('이전 판본이라 수락할 수 없어요'), findsOneWidget);
      expect(h.launcher.opened, isEmpty);
      await tester.tap(find.text('판본 4 보기'));
      await tester.pumpAndSettle();
      expect(h.opened.last, AppRoutes.collaborationAgreement(_id));
    });
  });

  group('layout', () {
    testWidgets('does not overflow at 1.3x text scale', (tester) async {
      await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(
            status: ContractStatus.awaitingBrand,
            brand: true,
            terms: _withPerformance,
          ),
        role: CollaborationRole.commissioner,
        smallPhoneLargeText: true,
      );
      expect(tester.takeException(), isNull);

      // 끝까지 내려도 넘치지 않는다.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow for a creator at 1.3x text scale', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeNegotiationRepository()
          ..contract = sampleContract(terms: _withPerformance),
        smallPhoneLargeText: true,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the canvas box colors in light and dark', (tester) async {
      // 켜진 확인란: 라이트 라임 #C6FF3D, 다크 #F2F3F5(DarkNContract). 꺼진 칸은 `line`이다.
      Future<void> check(ThemeData theme, Color on, Color off) async {
        await _pump(tester, FakeNegotiationRepository(), theme: theme);
        await tester.tap(find.text(_creatorTexts[0]));
        await tester.pumpAndSettle();
        Iterable<Color?> boxColors() => tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((w) => w.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.borderRadius == BorderRadius.circular(8))
            .map((d) => d.color);
        expect(boxColors().where((c) => c == on), hasLength(1));
        expect(boxColors().where((c) => c == off), hasLength(2));
      }

      await check(
        coraLightTheme,
        const Color(0xFFC6FF3D),
        CoraColors.light.line,
      );
      await check(coraDarkTheme, const Color(0xFFF2F3F5), CoraColors.dark.line);
    });
  });

  group('loading', () {
    testWidgets('shows a retry when the contract cannot be read', (
      tester,
    ) async {
      final repo = FakeNegotiationRepository()..failContract = true;
      await _pump(tester, repo);

      expect(find.text('계약을 불러오지 못했어요'), findsOneWidget);
      repo.failContract = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.textContaining('합의한 버전 2로'), findsOneWidget);
    });
  });
}
