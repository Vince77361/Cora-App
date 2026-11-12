import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/collaboration/presentation/mail_launcher.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/pump_cora_app.dart';
import '../store_browse/creator_app_harness.dart';
import 'fake_collaboration_repository.dart';

/// 메일 앱 열기를 기록만 한다.
class FakeMailLauncher implements MailLauncher {
  final composed = <({String? to, String subject})>[];
  bool opens = true;

  @override
  Future<bool> compose({String? to, required String subject}) async {
    composed.add((to: to, subject: subject));
    return opens;
  }
}

/// 로그인한 크리에이터로 앱을 띄우고 협업 [id]의 A7을 연다.
Future<void> pumpCollaboration(
  WidgetTester tester, {
  required FakeCollaborationRepository repo,
  String id = 'c0ffee11-aaaa-bbbb-cccc-000000000001',
  FakeClock? clock,
  FakeMailLauncher? mail,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
  bool open = true,
}) async {
  await pumpCreatorApp(
    tester,
    smallPhoneLargeText: smallPhoneLargeText,
    clock: clock,
    collaborations: repo,
    mail: mail,
    overrides: overrides,
  );
  if (!open) return;
  routerOf(tester).push(AppRoutes.creatorCollaboration(id));
  await tester.pumpAndSettle();
}
