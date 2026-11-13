import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/proposals/domain/proposal_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../proposals/fake_proposal_repository.dart';
import 'fake_store_home_repository.dart';
import 'store_home_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('store home stops asking for my answer after I reply', (
    tester,
  ) async {
    final home = FakeStoreHomeRepository(
      sent: [sentOffer(id: 'p1', name: '하루 한 컵', myTurn: true, version: 2)],
    );
    final repo = FakeProposalRepository(details: {'p1': proposalDetail()});
    repo.afterChange = (_) =>
        home.sentOffers = [sentOffer(id: 'p1', name: '하루 한 컵', version: 3)];
    await pumpStoreHome(
      tester,
      home: home,
      overrides: [proposalRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.tap(find.text('보낸 오퍼 1'));
    await tester.pumpAndSettle();
    expect(find.text('역제안이 왔어요'), findsOneWidget);

    await tester.tap(find.text('응답하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('고쳐서 다시 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storeProposals);

    routerOf(tester).go(AppRoutes.store);
    await tester.pumpAndSettle();
    await tester.tap(find.text('보낸 오퍼 1'));
    await tester.pumpAndSettle();
    expect(find.text('답을 기다려요'), findsOneWidget);
    expect(find.text('역제안이 왔어요'), findsNothing);
  });
}
