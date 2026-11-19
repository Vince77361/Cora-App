import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/world_cup/presentation/pages/world_cup_match_page.dart';
import 'package:cora/features/world_cup/presentation/widgets/world_cup_card.dart';
import 'package:cora/features/world_cup/presentation/world_cup_flow.dart';
import 'package:cora/features/world_cup/presentation/pages/world_cup_result_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_home/store_home_harness.dart';
import 'world_cup_fixtures.dart';

/// 월드컵 경로는 대진 정보(`extra`)가 있어야 열린다. 앱 알림이나 옛 링크가 정보 없이 열면 빈 화면 대신 첫 화면으로
/// 간다(시험용 경로가 아니라 실제 라우터로 본다).
void main() {
  setUpAll(loadAppFonts);

  for (final path in [AppRoutes.worldCupMatch, AppRoutes.worldCupResult]) {
    testWidgets('opening $path without its game goes to the first screen', (
      tester,
    ) async {
      await pumpStoreHome(tester);
      expect(currentPath(tester), AppRoutes.store);

      routerOf(tester).push(path);
      await tester.pumpAndSettle();

      expect(currentPath(tester), AppRoutes.store);
      expect(find.byType(WorldCupMatchPage), findsNothing);
      expect(find.byType(WorldCupResultPage), findsNothing);
    });
  }

  testWidgets('the real route keeps showing the final while it leaves for the '
      'result, and a second tap does not open the result twice', (
    tester,
  ) async {
    await pumpStoreHome(tester);
    routerOf(tester).push(
      AppRoutes.worldCupMatch,
      extra: WorldCupMatchArgs(
        saved: wcCandidates(4),
        size: 4,
        onPropose: ProposeLog().call,
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(WorldCupCard).first);
      await tester.pumpAndSettle();
    }
    expect(find.text('결승 · 1 / 1'), findsOneWidget);

    await tester.tap(find.byType(WorldCupCard).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // 결과 화면이 올라오는 동안에도 나가는 대결 화면은 비지 않는다.
    expect(find.text('VS'), findsOneWidget);
    expect(find.text('결승 · 1 / 1'), findsOneWidget);

    // 나가는 동안 다시 눌러도 결과가 두 번 열리지 않는다.
    await tester.tap(find.byType(WorldCupCard).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('이상형 1위'), findsOneWidget);
    routerOf(tester).pop();
    await tester.pumpAndSettle();
    expect(find.byType(WorldCupResultPage), findsNothing);
    expect(find.byType(WorldCupMatchPage), findsNothing);
  });
}
