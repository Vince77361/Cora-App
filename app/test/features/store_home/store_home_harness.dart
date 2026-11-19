import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora/core/time/clock.dart';
import 'package:cora/features/applicant_picks/domain/applicant_picks_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/store_home/domain/store_home_repository.dart';
import 'package:cora/features/store_onboarding/domain/content_draft_repository_provider.dart';
import 'package:cora/features/store_onboarding/domain/store_repository_provider.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/fake_photos.dart';
import '../../support/pump_cora_app.dart';
import '../applicant_picks/fake_applicant_picks_repository.dart';
import '../auth/fake_auth_repository.dart';
import '../onboarding/fake_me_repository.dart';
import '../store_onboarding/fake_content_draft_repository.dart';
import '../store_onboarding/fake_store_repository.dart';
import 'fake_store_home_repository.dart';

/// 캔버스 M19G4의 모집 조건: `식사권 2인 + 조회수 수당`, `1,000회당 2,000원, 최대 60,000원`.
const sampleRecruitTerms = OfferTerms(
  format: ContentFormat.reels,
  reward: Reward(
    voucher: Voucher(name: '식사권', value: 40000, people: 2),
    viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
  ),
);

/// 공개된 한그릇 라멘의 사장님으로 실제 [CoraApp]을 띄운다. 첫 화면은 사장님 홈(`/store`)이다.
Future<void> pumpStoreHome(
  WidgetTester tester, {
  FakeStoreHomeRepository? home,
  FakeApplicantPicksRepository? picks,
  FakeStoreRepository? stores,
  FakeClock? clock,
  FakeContentDraftRepository? drafts,
  bool smallPhoneLargeText = false,
  CoraEnv env = CoraEnv.dev,
  List<Override> overrides = const [],
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    usePhone(tester);
  }
  await pumpCoraApp(
    tester,
    auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    me: FakeMeRepository(role: UserRole.store),
    env: env,
    overrides: [
      storeRepositoryProvider.overrideWithValue(
        stores ??
            FakeStoreRepository(
              store: sampleStore(
                status: StoreStatus.published,
                step: StoreOnboardingStep.done,
                defaultTerms: sampleRecruitTerms,
              ),
            ),
      ),
      storeHomeRepositoryProvider.overrideWithValue(
        home ?? FakeStoreHomeRepository(applicants: sampleApplicants()),
      ),
      // 홈의 `추천 3명`. 지원자 세 명이 있는 홈의 기본은 지원자 중에서 뽑은 세 명이다(다른 하네스가 같은
      // provider를 직접 바꿔 끼우면 그쪽을 쓴다).
      if (picks != null ||
          !overrides.any((o) => o.origin == applicantPicksRepositoryProvider))
        applicantPicksRepositoryProvider.overrideWithValue(
          picks ??
              FakeApplicantPicksRepository(
                picks: sampleAppliedPicks(),
                totalNew: 3,
              ),
        ),
      contentDraftRepositoryProvider.overrideWithValue(
        drafts ?? FakeContentDraftRepository(),
      ),
      photoPickerProvider.overrideWithValue(FakePhotoPicker()),
      photoUploaderProvider.overrideWithValue(FakePhotoUploader()),
      clockProvider.overrideWithValue(clock ?? FakeClock()),
      ...overrides,
    ],
  );
}

/// 쌓인 화면 가운데 맨 위 화면의 경로.
String topPath(WidgetTester tester) =>
    routerOf(tester).routerDelegate.currentConfiguration.last.matchedLocation;
