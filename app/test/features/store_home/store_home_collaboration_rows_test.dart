import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/view_report/domain/view_report.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/offers/domain/offer_view.dart';
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora/features/store_home/presentation/store_home_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../payment/fake_payment_repository.dart';
import 'fake_store_home_repository.dart';
import 'store_home_harness.dart';

Collaboration _owned(
  String id, {
  CollaborationStage stage = CollaborationStage.funded,
  StepKey now = StepKey.visit,
  DateTime? countingEndsAt,
  CollaborationSettlement? settlement,
  ViewReportStatus? viewReportStatus,
}) => collaboration(
  id: id,
  storeName: '하루 한 컵',
  role: CollaborationRole.commissioner,
  stage: stage,
  now: now,
  countingEndsAt: countingEndsAt,
  settlement: settlement,
  viewReportStatus: viewReportStatus,
  currentViews: 4320,
  expectedRefund: 56800,
);

FakeStoreHomeRepository _home(List<({String id, String name})> rows) =>
    FakeStoreHomeRepository(
      sent: [
        for (final row in rows)
          sentOffer(
            id: 'offer-${row.id}',
            name: row.name,
            view: OfferView.accepted,
            collaborationId: row.id,
            paymentDaysLeft: 3,
          ),
      ],
    );

Future<void> _openSent(WidgetTester tester, int count) async {
  await tester.tap(find.text('보낸 오퍼 $count'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('describes each paid collaboration on the sent offers row', (
    tester,
  ) async {
    final repo = FakeCollaborationRepository(
      active: [
        _owned('col-funded'),
        _owned(
          'col-counting',
          stage: CollaborationStage.counting,
          now: StepKey.settle,
          countingEndsAt: DateTime.utc(2026, 11, 18, 12),
        ),
      ],
      done: [
        _owned(
          'col-settled',
          stage: CollaborationStage.settled,
          settlement: const CollaborationSettlement(
            finalViews: 4320,
            payoutAmount: 43200,
            refundAmount: 56800,
          ),
        ),
      ],
    );
    await pumpStoreHome(
      tester,
      clock: FakeClock(),
      home: _home([
        (id: 'col-funded', name: '하루 한 컵'),
        (id: 'col-counting', name: '성수 한 끼'),
        (id: 'col-settled', name: '면치기 일기'),
      ]),
      overrides: [collaborationRepositoryProvider.overrideWithValue(repo)],
    );
    await _openSent(tester, 3);

    expect(find.text('결제했어요, 방문을 기다려요'), findsOneWidget);
    expect(find.text('집계 중 · 7일 남음'), findsOneWidget);
    expect(find.text('끝났어요 · 56,800원 환급'), findsOneWidget);
    // 결제가 끝난 줄에는 결제하기도, 수락함 문구도 없다.
    expect(find.text('결제하기'), findsNothing);
    expect(find.textContaining('결제를 기다려요'), findsNothing);
  });

  testWidgets('opens the collaboration from the sent offers row', (
    tester,
  ) async {
    final repo = FakeCollaborationRepository(active: [_owned('col-funded')]);
    await pumpStoreHome(
      tester,
      home: _home([(id: 'col-funded', name: '하루 한 컵')]),
      overrides: [collaborationRepositoryProvider.overrideWithValue(repo)],
    );
    await _openSent(tester, 1);

    await tester.tap(find.text('결제했어요, 방문을 기다려요'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeCollaboration('col-funded'));
    expect(find.text('하루 한 컵과의 협업'), findsOneWidget);
  });

  testWidgets('keeps the pay button on an offer that is not paid yet', (
    tester,
  ) async {
    final repo = FakeCollaborationRepository(
      active: [
        _owned(
          'col-wait',
          stage: CollaborationStage.awaitingPayment,
          now: StepKey.paid,
        ),
      ],
    );
    await pumpStoreHome(
      tester,
      home: _home([(id: 'col-wait', name: '하루 한 컵')]),
      overrides: [
        collaborationRepositoryProvider.overrideWithValue(repo),
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
      ],
    );
    await _openSent(tester, 1);

    expect(find.text('수락함, 결제를 기다려요 · 3일 남음'), findsOneWidget);
    await tester.tap(find.text('결제하기'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storePay('col-wait'));
  });

  testWidgets(
    'still shows the sent offers when collaborations cannot be read',
    (tester) async {
      final repo = FakeCollaborationRepository()..failFetch = true;
      await pumpStoreHome(
        tester,
        home: _home([(id: 'col-funded', name: '하루 한 컵')]),
        overrides: [collaborationRepositoryProvider.overrideWithValue(repo)],
      );
      await _openSent(tester, 1);

      expect(find.text('하루 한 컵'), findsOneWidget);
      expect(find.text('수락함, 결제를 기다려요 · 3일 남음'), findsOneWidget);
    },
  );

  test('requires the clock when a collaboration is passed', () {
    final offer = sentOffer(view: OfferView.accepted, collaborationId: 'c');

    // 앱 시계 대신 `DateTime.now()`로 남은 날짜를 세지 않는다.
    expect(
      () => sentOfferMeta(offer, collaboration: _owned('c')),
      throwsAssertionError,
    );
    expect(sentOfferMeta(offer), '수락함, 결제를 기다려요');
  });

  test('describes the progress of a paid collaboration', () {
    final now = DateTime.utc(2026, 11, 11, 12);
    final offer = sentOffer(view: OfferView.accepted, collaborationId: 'c');

    expect(
      sentOfferMeta(offer, collaboration: _owned('c'), now: now),
      '결제했어요, 방문을 기다려요',
    );
    expect(
      sentOfferMeta(
        offer,
        collaboration: _owned(
          'c',
          stage: CollaborationStage.counting,
          now: StepKey.settle,
          countingEndsAt: DateTime.utc(2026, 11, 14, 12),
        ),
        now: now,
      ),
      '집계 중 · 3일 남음',
    );
    expect(
      sentOfferMeta(
        offer,
        collaboration: _owned(
          'c',
          stage: CollaborationStage.settled,
          settlement: const CollaborationSettlement(
            finalViews: 0,
            payoutAmount: 0,
            refundAmount: 100000,
          ),
        ),
        now: now,
      ),
      '끝났어요 · 100,000원 환급',
    );
    expect(sentOfferAction(offer, collaboration: _owned('c')), isNull);
  });

  test(
    'does not count days left while the view report awaits confirmation',
    () {
      final offer = sentOffer(view: OfferView.accepted, collaborationId: 'c');

      expect(
        sentOfferMeta(
          offer,
          collaboration: _owned(
            'c',
            stage: CollaborationStage.counting,
            now: StepKey.settle,
            countingEndsAt: DateTime.utc(2026, 11, 14, 12),
            viewReportStatus: ViewReportStatus.unconfirmed,
          ),
          now: DateTime.utc(2026, 11, 15, 12),
        ),
        '집계를 확인하고 있어요',
      );
    },
  );
}
