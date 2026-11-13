import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/collaboration/presentation/link_launcher.dart';
import 'package:cora/features/store_result/domain/store_result_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../collaboration/store_collaboration_harness.dart'
    show FakeLinkLauncher;
import '../store_home/store_home_harness.dart';
import 'fake_store_result_repository.dart';

const storeResultCollaborationId = 'c0ffee11-aaaa-bbbb-cccc-000000000003';

/// 로그인한 사장님으로 앱을 띄우고 협업의 7일 결과(G1)를 연다.
Future<void> pumpStoreResult(
  WidgetTester tester, {
  FakeStoreResultRepository? results,
  FakeCollaborationRepository? collaborations,
  FakeLinkLauncher? links,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
}) async {
  await pumpStoreHome(
    tester,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [
      storeResultRepositoryProvider.overrideWithValue(
        results ?? FakeStoreResultRepository(),
      ),
      collaborationRepositoryProvider.overrideWithValue(
        collaborations ?? FakeCollaborationRepository(),
      ),
      if (links != null) externalLinkLauncherProvider.overrideWithValue(links),
      ...overrides,
    ],
  );
  routerOf(tester).push(AppRoutes.storeResult(storeResultCollaborationId));
  await tester.pumpAndSettle();
}
