import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/store_onboarding/domain/content_draft_repository_provider.dart';
import 'package:cora/features/store_onboarding/domain/store_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_photos.dart';
import 'fake_content_draft_repository.dart';
import 'fake_store_repository.dart';

/// 로그인한 사용자 `user-1`과 가짜 저장소로 만든 컨테이너. 위젯 없이 ViewModel만 본다.
ProviderContainer storeContainer({
  FakeStoreRepository? stores,
  FakeContentDraftRepository? drafts,
  FakePhotoPicker? picker,
  FakePhotoUploader? uploader,
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      storeRepositoryProvider.overrideWithValue(
        stores ?? FakeStoreRepository(),
      ),
      contentDraftRepositoryProvider.overrideWithValue(
        drafts ?? FakeContentDraftRepository(),
      ),
      photoPickerProvider.overrideWithValue(picker ?? FakePhotoPicker()),
      photoUploaderProvider.overrideWithValue(uploader ?? FakePhotoUploader()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}
