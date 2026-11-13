import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/collaboration/presentation/link_launcher.dart';
import 'package:cora/features/view_report/domain/view_report_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../collaboration/store_collaboration_harness.dart'
    show FakeLinkLauncher;
import '../store_browse/creator_app_harness.dart';
import '../store_home/store_home_harness.dart';
import 'fake_view_report_repository.dart';

const reportCollaborationId = 'c0ffee11-aaaa-bbbb-cccc-000000000004';

/// 로그인한 크리에이터로 앱을 띄우고 협업의 성과 확인(F4)을 연다.
Future<void> pumpCreatorReport(
  WidgetTester tester, {
  FakeViewReportRepository? reports,
  FakeCollaborationRepository? collaborations,
  FakeLinkLauncher? links,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
}) async {
  await pumpCreatorApp(
    tester,
    smallPhoneLargeText: smallPhoneLargeText,
    collaborations: collaborations,
    overrides: [
      viewReportRepositoryProvider.overrideWithValue(
        reports ?? FakeViewReportRepository(),
      ),
      if (links != null) externalLinkLauncherProvider.overrideWithValue(links),
      ...overrides,
    ],
  );
  routerOf(tester).push(AppRoutes.creatorViewReport(reportCollaborationId));
  await tester.pumpAndSettle();
}

/// 로그인한 사장님으로 앱을 띄우고 협업의 성과 확인(F4)을 연다.
Future<void> pumpOwnerReport(
  WidgetTester tester, {
  FakeViewReportRepository? reports,
  FakeCollaborationRepository? collaborations,
  FakeLinkLauncher? links,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
}) async {
  await pumpStoreHome(
    tester,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [
      viewReportRepositoryProvider.overrideWithValue(
        reports ?? FakeViewReportRepository(),
      ),
      collaborationRepositoryProvider.overrideWithValue(
        collaborations ?? FakeCollaborationRepository(),
      ),
      if (links != null) externalLinkLauncherProvider.overrideWithValue(links),
      ...overrides,
    ],
  );
  routerOf(tester).push(AppRoutes.storeViewReport(reportCollaborationId));
  await tester.pumpAndSettle();
}
