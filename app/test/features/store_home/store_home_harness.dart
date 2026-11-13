import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora/core/time/clock.dart';
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
import '../auth/fake_auth_repository.dart';
import '../onboarding/fake_me_repository.dart';
import '../store_onboarding/fake_content_draft_repository.dart';
import '../store_onboarding/fake_store_repository.dart';
import 'fake_store_home_repository.dart';

/// 공개된 한그릇 라멘의 사장님으로 실제 [CoraApp]을 띄운다. 첫 화면은 사장님 홈(`/store`)이다.
Future<void> pumpStoreHome(
  WidgetTester tester, {
  FakeStoreHomeRepository? home,
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
              ),
            ),
      ),
      storeHomeRepositoryProvider.overrideWithValue(
        home ?? FakeStoreHomeRepository(applicants: sampleApplicants()),
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
