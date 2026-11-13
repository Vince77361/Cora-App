import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/proposals/domain/proposal.dart';
import 'package:cora/features/proposals/domain/proposal_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../proposals/fake_proposal_repository.dart';
import '../store_browse/creator_app_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the creator opens the proposal box from the in-progress tab', (
    tester,
  ) async {
    await pumpCreatorApp(
      tester,
      overrides: [
        proposalRepositoryProvider.overrideWithValue(
          FakeProposalRepository(
            active: [
              proposalRow(offerId: 'a1'),
              proposalRow(offerId: 'a2', name: '한그릇 라멘'),
              proposalRow(
                offerId: 'a3',
                group: ProposalGroup.waiting,
                counter: false,
              ),
            ],
          ),
        ),
      ],
    );
    await tester.tap(find.text('협업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('진행 중'));
    await tester.pumpAndSettle();

    // 줄 오른쪽에 내가 응답할 차례의 수가 있다.
    expect(find.text('제안함'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('제안함'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.creatorProposals);
    expect(find.text('진행 중 3'), findsOneWidget);
  });
}
