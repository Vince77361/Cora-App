import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:cora/features/store_onboarding/domain/content_draft_repository_provider.dart';
import 'package:cora/features/store_onboarding/domain/store_repository_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../server_config/fake_server_config_repository.dart';
import '../onboarding/fake_me_repository.dart';
import 'fake_content_draft_repository.dart';
import 'fake_store_repository.dart';

/// 로그인한 가게 사장님으로 실제 [CoraApp]을 띄운다. 첫 화면은 진입 규칙이 고른다(가게가 없으면
/// 링크 입력, 등록 중이면 저장된 단계, 공개됐으면 사장님 홈).
Future<void> pumpStoreApp(
  WidgetTester tester, {
  FakeStoreRepository? stores,
  FakeContentDraftRepository? drafts,
  FakeServerConfigRepository? config,
  FakePhotoPicker? picker,
  FakePhotoUploader? uploader,
}) async {
  usePhone(tester);
  await pumpCoraApp(
    tester,
    auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    me: FakeMeRepository(role: UserRole.store),
    overrides: [
      storeRepositoryProvider.overrideWithValue(
        stores ?? FakeStoreRepository(),
      ),
      contentDraftRepositoryProvider.overrideWithValue(
        drafts ?? FakeContentDraftRepository(),
      ),
      if (config != null)
        serverConfigRepositoryProvider.overrideWithValue(config),
      photoPickerProvider.overrideWithValue(picker ?? FakePhotoPicker()),
      photoUploaderProvider.overrideWithValue(uploader ?? FakePhotoUploader()),
    ],
  );
}

/// 쌓인 화면 가운데 맨 위 화면의 경로. `push`한 화면은 `currentPath`(아래 화면의 주소)에 나오지
/// 않으므로 이것으로 본다.
String topPath(WidgetTester tester) =>
    routerOf(tester).routerDelegate.currentConfiguration.last.matchedLocation;
