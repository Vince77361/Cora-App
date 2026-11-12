import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../store_home/store_home_harness.dart';
import 'collaboration_harness.dart' show FakeMailLauncher;
import 'fake_collaboration_repository.dart';
import 'store_collaboration_harness.dart';

const _id = storeCollaborationId;
const _url = 'https://www.instagram.com/reel/abc';

/// 사장님 쪽 협업. 상대는 크리에이터의 활동 이름이다.
Collaboration _owned({
  CollaborationStage stage = CollaborationStage.funded,
  StepKey now = StepKey.visit,
  String? submittedUrl,
  int? currentViews,
  int? expectedRefund,
  DateTime? countingEndsAt,
  bool canRequestCancel = false,
  CancelRequest? cancelRequest,
  CollaborationSettlement? settlement,
  List<CollaborationStep>? steps,
}) => collaboration(
  id: _id,
  storeName: '하루 한 컵',
  role: CollaborationRole.commissioner,
  stage: stage,
  now: now,
  steps: steps,
  submittedUrl: submittedUrl,
  currentViews: currentViews,
  expectedRefund: expectedRefund,
  countingEndsAt: countingEndsAt,
  canRequestCancel: canRequestCancel,
  cancelRequest: cancelRequest,
  settlement: settlement,
);

Collaboration _counting() => _owned(
  stage: CollaborationStage.counting,
  now: StepKey.settle,
  submittedUrl: _url,
  currentViews: 4320,
  expectedRefund: 56800,
  countingEndsAt: DateTime.utc(2026, 11, 18, 12),
);

FakeCollaborationRepository _repo(Collaboration c) =>
    FakeCollaborationRepository(active: [c]);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows held amount, views and expected refund', (tester) async {
    await pumpStoreCollaboration(tester, repo: _repo(_counting()));

    expect(topPath(tester), AppRoutes.storeCollaboration(_id));
    expect(find.text('하루 한 컵과의 협업'), findsOneWidget);
    expect(find.text('보관 중인 금액'), findsOneWidget);
    expect(find.text('100,000원'), findsOneWidget);
    expect(find.text('현재 조회수'), findsOneWidget);
    expect(find.text('4,320회'), findsOneWidget);
    expect(find.text('예상 환급액'), findsOneWidget);
    expect(find.text('56,800원'), findsOneWidget);
    expect(find.text('크리에이터가 링크를 제출하면 집계가 시작돼요.'), findsNothing);
    expect(find.text('문의하기'), findsOneWidget);
  });

  testWidgets('uses the right particle for the activity name', (tester) async {
    final c = collaboration(
      id: _id,
      storeName: '서아',
      role: CollaborationRole.commissioner,
    );
    await pumpStoreCollaboration(tester, repo: _repo(c));

    expect(find.text('서아와의 협업'), findsOneWidget);
  });

  testWidgets('explains that counting starts after the link is submitted', (
    tester,
  ) async {
    await pumpStoreCollaboration(tester, repo: _repo(_owned()));

    expect(find.text('보관 중인 금액'), findsOneWidget);
    expect(find.text('100,000원'), findsOneWidget);
    expect(find.text('크리에이터가 링크를 제출하면 집계가 시작돼요.'), findsOneWidget);
    expect(find.text('현재 조회수'), findsNothing);
    expect(find.text('올라온 콘텐츠 보기'), findsNothing);
  });

  testWidgets('does not say money is held before the store has paid', (
    tester,
  ) async {
    // 서버의 보관액은 결제 전에 0이고, 조회수당 조건은 그대로 있다.
    final c = collaboration(
      id: _id,
      storeName: '하루 한 컵',
      role: CollaborationRole.commissioner,
      stage: CollaborationStage.awaitingPayment,
      now: StepKey.paid,
      escrowAmount: 0,
    );
    await pumpStoreCollaboration(tester, repo: _repo(c));

    expect(find.text('보관 중인 금액'), findsNothing);
    expect(find.text('0원'), findsNothing);
    expect(find.text('결제를 기다리고 있어요'), findsOneWidget);
    // 상한은 조건에서 읽는다.
    expect(find.text('최대 10만 원'), findsOneWidget);
  });

  testWidgets(
    'shows the voucher instead of a held amount without a reward per view',
    (tester) async {
      final c = collaboration(
        id: _id,
        storeName: '하루 한 컵',
        role: CollaborationRole.commissioner,
        escrowAmount: 0,
        terms: const OfferTerms(
          format: ContentFormat.shorts,
          rewardType: RewardType.voucher,
          voucherName: '빵 세트',
          voucherValue: 30000,
        ),
      );
      await pumpStoreCollaboration(tester, repo: _repo(c));

      expect(find.text('보관 중인 금액'), findsNothing);
      expect(find.text('빵 세트'), findsOneWidget);
      expect(find.text('0원'), findsNothing);
      expect(find.text('크리에이터가 링크를 제출하면 집계가 시작돼요.'), findsNothing);
      expect(find.textContaining('최대'), findsNothing);
    },
  );

  testWidgets('names the steps in the owner words', (tester) async {
    await pumpStoreCollaboration(tester, repo: _repo(_owned()));

    for (final text in [
      '오퍼 수락됨',
      '결제 완료',
      '크리에이터 방문·촬영',
      '콘텐츠 게시',
      '11월 23일까지',
      '7일 집계 후 정산',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('오퍼 수락'), findsNothing);
    expect(find.text('가게 결제 완료'), findsNothing);
  });

  testWidgets('opens the submitted content link', (tester) async {
    final links = FakeLinkLauncher();
    await pumpStoreCollaboration(
      tester,
      repo: _repo(_counting()),
      links: links,
    );

    await tester.tap(find.text('올라온 콘텐츠 보기'));
    await tester.pumpAndSettle();

    expect(links.opened, [Uri.parse(_url)]);
  });

  testWidgets('says so when the content link cannot be opened', (tester) async {
    final links = FakeLinkLauncher()..opens = false;
    await pumpStoreCollaboration(
      tester,
      repo: _repo(_counting()),
      links: links,
    );

    await tester.tap(find.text('올라온 콘텐츠 보기'));
    await tester.pumpAndSettle();

    expect(find.text('링크를 열지 못했어요.'), findsOneWidget);
  });

  testWidgets('does not open a link that is not http', (tester) async {
    final links = FakeLinkLauncher();
    final c = _owned(
      stage: CollaborationStage.counting,
      now: StepKey.settle,
      submittedUrl: 'javascript:alert(1)',
      currentViews: 1,
      expectedRefund: 1,
    );
    await pumpStoreCollaboration(tester, repo: _repo(c), links: links);

    await tester.tap(find.text('올라온 콘텐츠 보기'));
    await tester.pumpAndSettle();

    expect(links.opened, isEmpty);
    expect(find.text('링크를 열지 못했어요.'), findsOneWidget);
  });

  testWidgets(
    'sends a cancel request after confirmation and shows the banner',
    (tester) async {
      final repo = _repo(_owned(canRequestCancel: true));
      await pumpStoreCollaboration(tester, repo: repo);

      expect(find.text('취소 요청을 보냈어요. 3일 안에 답이 없으면 요청이 사라져요.'), findsNothing);
      await tester.tap(find.bySemanticsLabel('더보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('협업 취소 요청'));
      await tester.pumpAndSettle();

      expect(find.text('크리에이터가 동의하면 취소되고 결제 금액을 모두 돌려받아요.'), findsOneWidget);
      expect(repo.cancelRequested, isEmpty);

      // 닫으면 아무것도 보내지 않는다.
      await tester.tap(find.text('그대로 두기'));
      await tester.pumpAndSettle();
      expect(repo.cancelRequested, isEmpty);

      await tester.tap(find.bySemanticsLabel('더보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('협업 취소 요청'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('요청하기'));
      await tester.pumpAndSettle();

      expect(repo.cancelRequested, [_id]);
      expect(topPath(tester), AppRoutes.storeCollaboration(_id));
      expect(find.text('취소 요청을 보냈어요. 3일 안에 답이 없으면 요청이 사라져요.'), findsOneWidget);
      // 요청이 걸려 있는 동안에는 다시 요청할 수 없다.
      expect(find.bySemanticsLabel('더보기'), findsNothing);
    },
  );

  testWidgets('shows the banner while a request of mine is pending', (
    tester,
  ) async {
    final c = _owned(
      cancelRequest: CancelRequest(
        id: 'req-1',
        expiresAt: DateTime.utc(2026, 11, 14, 12),
        requestedByMe: true,
      ),
    );
    await pumpStoreCollaboration(tester, repo: _repo(c));

    expect(find.text('취소 요청을 보냈어요. 3일 안에 답이 없으면 요청이 사라져요.'), findsOneWidget);
    expect(find.bySemanticsLabel('더보기'), findsNothing);
  });

  testWidgets('hides the cancel request menu once counting has started', (
    tester,
  ) async {
    await pumpStoreCollaboration(tester, repo: _repo(_counting()));

    expect(find.bySemanticsLabel('더보기'), findsNothing);
  });

  testWidgets('shows the server message when the request is refused', (
    tester,
  ) async {
    final repo = _repo(_owned(canRequestCancel: true))
      ..failAction = const CollaborationFailure(
        conflict: true,
        message: '지금은 취소를 요청할 수 없는 협업이에요.',
      );
    await pumpStoreCollaboration(tester, repo: repo);

    await tester.tap(find.bySemanticsLabel('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('협업 취소 요청'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('요청하기'));
    await tester.pumpAndSettle();

    expect(find.text('지금은 취소를 요청할 수 없는 협업이에요.'), findsOneWidget);
    expect(find.text('취소 요청을 보냈어요. 3일 안에 답이 없으면 요청이 사라져요.'), findsNothing);
    expect(topPath(tester), AppRoutes.storeCollaboration(_id));
  });

  testWidgets('shows the final payout and refund when settled', (tester) async {
    final c = _owned(
      stage: CollaborationStage.settled,
      steps: [
        for (final key in StepKey.values)
          CollaborationStep(key: key, state: StepState.done),
      ],
      submittedUrl: _url,
      settlement: const CollaborationSettlement(
        finalViews: 4320,
        payoutAmount: 43200,
        refundAmount: 56800,
      ),
    );
    await pumpStoreCollaboration(tester, repo: _repo(c));

    expect(find.text('정산이 끝났어요.'), findsOneWidget);
    expect(find.text('지급 43,200원 · 환급 56,800원'), findsOneWidget);
    expect(find.text('보관 중인 금액'), findsNothing);
    expect(find.text('올라온 콘텐츠 보기'), findsOneWidget);
    expect(find.bySemanticsLabel('더보기'), findsNothing);
  });

  testWidgets('opens the mail composer with the operator address', (
    tester,
  ) async {
    final mail = FakeMailLauncher();
    await pumpStoreCollaboration(tester, repo: _repo(_owned()), mail: mail);

    await tester.tap(find.text('문의하기'));
    await tester.pumpAndSettle();

    expect(mail.composed.single.subject, '[Cora] 협업 c0ffee11 문의');
    expect(mail.composed.single.to, isNull);
  });

  testWidgets('shows an error with retry when loading fails', (tester) async {
    final repo = _repo(_owned())..failFetch = true;
    await pumpStoreCollaboration(tester, repo: repo);

    expect(find.text('협업을 불러오지 못했어요.'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('하루 한 컵과의 협업'), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    final c = _owned(
      stage: CollaborationStage.counting,
      now: StepKey.settle,
      submittedUrl: _url,
      currentViews: 4320,
      expectedRefund: 56800,
      countingEndsAt: DateTime.utc(2026, 11, 18, 12),
      cancelRequest: CancelRequest(
        id: 'req-1',
        expiresAt: DateTime.utc(2026, 11, 14, 12),
        requestedByMe: true,
      ),
    );
    await pumpStoreCollaboration(
      tester,
      repo: _repo(c),
      smallPhoneLargeText: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('올라온 콘텐츠 보기'), findsOneWidget);
  });
}
