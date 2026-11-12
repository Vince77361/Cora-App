import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../collaboration/collaboration_harness.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../store_browse/creator_app_harness.dart';
import 'fake_received_offers_repository.dart';

Future<void> _openActiveTab(
  WidgetTester tester,
  FakeCollaborationRepository collaborations,
) async {
  await pumpCollaboration(
    tester,
    repo: collaborations,
    clock: FakeClock(),
    open: false,
  );
  await tester.tap(find.text('협업'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('진행 중'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('lists active collaborations on the in-progress tab', (
    tester,
  ) async {
    final collaborations = FakeCollaborationRepository(
      active: [
        collaboration(
          id: 'a1111111-0000-0000-0000-000000000001',
          storeName: '하루 한 컵',
          stage: CollaborationStage.awaitingPayment,
          now: StepKey.paid,
        ),
        collaboration(),
        collaboration(
          id: 'b2222222-0000-0000-0000-000000000002',
          storeName: '달빛 베이커리',
          stage: CollaborationStage.counting,
          now: StepKey.settle,
          earnedSoFar: 0,
          currentViews: 0,
          countingEndsAt: DateTime.utc(2026, 11, 18, 12),
        ),
      ],
    );
    await _openActiveTab(tester, collaborations);

    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('결제를 기다리고 있어요'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsOneWidget);
    expect(find.text('방문하고 촬영해 주세요 · 11월 23일까지'), findsOneWidget);
    expect(find.text('달빛 베이커리'), findsOneWidget);
    expect(find.text('집계 중 · 7일 남음'), findsOneWidget);
  });

  testWidgets('opens the collaboration screen from a row', (tester) async {
    final collaborations = FakeCollaborationRepository(
      active: [collaboration()],
    );
    await _openActiveTab(tester, collaborations);

    await tester.tap(find.text('한그릇 라멘'));
    await tester.pumpAndSettle();

    expect(
      topPath(tester),
      AppRoutes.creatorCollaboration('c0ffee11-aaaa-bbbb-cccc-000000000001'),
    );
    expect(find.text('한그릇 라멘 협업'), findsOneWidget);
  });

  testWidgets('shows the empty message when nothing is in progress', (
    tester,
  ) async {
    await _openActiveTab(tester, FakeCollaborationRepository());

    expect(find.text('아직 진행 중인 협업이 없어요.'), findsOneWidget);
  });

  testWidgets('shows the collaboration after accepting an offer', (
    tester,
  ) async {
    final collaborations = FakeCollaborationRepository();
    final offers = FakeReceivedOffersRepository(
      newOffers: [receivedOffer(id: 'o1')],
    );
    await pumpCreatorApp(
      tester,
      offers: offers,
      collaborations: collaborations,
    );
    await tester.tap(find.text('협업'));
    await tester.pumpAndSettle();

    // 수락하면 서버가 협업을 만든다.
    collaborations.active = [
      collaboration(
        stage: CollaborationStage.awaitingPayment,
        now: StepKey.paid,
      ),
    ];
    await tester.tap(find.text('수락하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('결제를 기다리고 있어요'), findsOneWidget);
  });
}
