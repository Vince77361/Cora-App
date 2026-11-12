import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/collaboration/presentation/link_launcher.dart';
import 'package:cora/features/collaboration/presentation/mail_launcher.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/pump_cora_app.dart';
import '../store_home/store_home_harness.dart';
import 'collaboration_harness.dart' show FakeMailLauncher;
import 'fake_collaboration_repository.dart';

/// 바깥 브라우저 열기를 기록만 한다.
class FakeLinkLauncher implements ExternalLinkLauncher {
  final opened = <Uri>[];
  bool opens = true;

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return opens;
  }
}

const storeCollaborationId = 'c0ffee11-aaaa-bbbb-cccc-000000000002';

/// 로그인한 사장님으로 앱을 띄우고 협업 [id]의 사장님 진행 화면을 연다.
Future<void> pumpStoreCollaboration(
  WidgetTester tester, {
  required FakeCollaborationRepository repo,
  String id = storeCollaborationId,
  FakeClock? clock,
  FakeMailLauncher? mail,
  FakeLinkLauncher? links,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
}) async {
  await pumpStoreHome(
    tester,
    clock: clock,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [
      collaborationRepositoryProvider.overrideWithValue(repo),
      if (mail != null) mailLauncherProvider.overrideWithValue(mail),
      if (links != null) externalLinkLauncherProvider.overrideWithValue(links),
      ...overrides,
    ],
  );
  routerOf(tester).push(AppRoutes.storeCollaboration(id));
  await tester.pumpAndSettle();
}
