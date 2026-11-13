import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/applicant_picks/domain/applicant_picks_repository.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/trial_compare/domain/trial_info.dart';
import 'package:cora/features/trial_compare/domain/trial_compare_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_cora_app.dart';
import '../applicant_picks/fake_applicant_picks_repository.dart';
import '../store_home/fake_store_home_repository.dart';
import '../store_home/store_home_harness.dart';
import '../store_onboarding/fake_store_repository.dart';
import 'fake_trial_compare_repository.dart';

/// 공개된 한그릇 라멘의 사장님이 체험단 계약 정보를 넣어 둔 상태의 가게. 종료일이 가까워 홈에 비교 줄이 뜬다.
FakeStoreRepository storeWithTrial({
  TrialBannerKind? banner = TrialBannerKind.compare,
  TrialInfo? info,
}) => FakeStoreRepository(
  store: sampleStore(
    status: StoreStatus.published,
    step: StoreOnboardingStep.done,
    trialInfo:
        info ??
        TrialInfo(
          monthlyFee: 300000,
          endsOn: DateTime(2026, 12, 10),
          postCount: 9,
        ),
    trialBanner: banner,
  ),
);

/// 로그인한 사장님으로 앱을 띄우고 지난 3개월 비교(G3)를 연다.
Future<FakeTrialCompareRepository> pumpTrialCompare(
  WidgetTester tester, {
  FakeTrialCompareRepository? trial,
  FakeStoreRepository? stores,
  FakeStoreHomeRepository? home,
  FakeApplicantPicksRepository? picks,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
  bool open = true,
}) async {
  final storeRepo = stores ?? storeWithTrial();
  final repo = trial ?? FakeTrialCompareRepository(stores: storeRepo);
  await pumpStoreHome(
    tester,
    stores: storeRepo,
    home: home,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [
      trialCompareRepositoryProvider.overrideWithValue(repo),
      applicantPicksRepositoryProvider.overrideWithValue(
        picks ?? FakeApplicantPicksRepository(),
      ),
      ...overrides,
    ],
  );
  if (open) {
    routerOf(tester).push(AppRoutes.storeTrialCompare);
    await tester.pumpAndSettle();
  }
  return repo;
}
