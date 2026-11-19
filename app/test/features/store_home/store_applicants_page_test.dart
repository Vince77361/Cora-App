import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/core/ui/cora_step_header.dart';
import 'package:cora/features/offers/presentation/pages/send_offer_page.dart';
import 'package:cora/features/store_home/presentation/pages/store_applicants_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_store_home_repository.dart';
import 'store_home_harness.dart';

Future<void> _openApplicants(WidgetTester tester) async {
  routerOf(tester).push(AppRoutes.storeApplicants);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('lists applicants with 오퍼 보내기', (tester) async {
    await pumpStoreHome(tester);
    await _openApplicants(tester);

    expect(find.byType(StoreApplicantsPage), findsOneWidget);
    expect(find.text('지원자 보기'), findsOneWidget);
    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('리빙 릴스, 오늘 지원'), findsOneWidget);
    expect(find.text('맛집 릴스, 어제 지원'), findsOneWidget);
    expect(find.text('라멘 리뷰, 2일 전 지원'), findsOneWidget);
    expect(find.text('오퍼 보내기'), findsNWidgets(3));
    // 사진이 없으면 이름의 첫 글자.
    expect(find.text('성'), findsOneWidget);
    expect(find.text('면'), findsOneWidget);
  });

  testWidgets('opens the offer form for the tapped applicant', (tester) async {
    await pumpStoreHome(tester);
    await _openApplicants(tester);

    await tester.tap(find.text('오퍼 보내기').at(1));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeOfferNew('c2'));
    expect(find.byType(SendOfferPage), findsOneWidget);
  });

  testWidgets('shows the shared empty state when nobody applied', (
    tester,
  ) async {
    await pumpStoreHome(tester, home: FakeStoreHomeRepository());
    await _openApplicants(tester);

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('아직 지원한 크리에이터가 없어요.'), findsOneWidget);
    expect(find.text('가게가 공개되면 지원이 도착해요.'), findsOneWidget);
  });

  testWidgets('goes back to the home', (tester) async {
    await pumpStoreHome(tester);
    await _openApplicants(tester);

    await tester.tap(find.byType(CoraBackButton));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.store);
  });
}
