import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/applicant_picks/domain/applicant_picks_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_cora_app.dart';
import '../store_home/fake_store_home_repository.dart';
import '../store_home/store_home_harness.dart';
import 'fake_applicant_picks_repository.dart';

/// 로그인한 사장님으로 앱을 띄우고 지원자 추천(G2)을 연다.
Future<void> pumpApplicantPicks(
  WidgetTester tester, {
  FakeApplicantPicksRepository? picks,
  FakeStoreHomeRepository? home,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
}) async {
  await pumpStoreHome(
    tester,
    home: home,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [
      applicantPicksRepositoryProvider.overrideWithValue(
        picks ?? FakeApplicantPicksRepository(),
      ),
      ...overrides,
    ],
  );
  routerOf(tester).push(AppRoutes.storeApplicantPicks);
  await tester.pumpAndSettle();
}
