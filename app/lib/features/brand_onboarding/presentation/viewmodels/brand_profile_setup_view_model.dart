import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/photo_picker.dart';
import '../../../../core/network/photo_uploader.dart';
import '../../../store_onboarding/domain/my_store.dart' show IndustryCategory;
import '../../domain/brand_repository.dart';

/// 화면을 떠나면 입력도 버린다.
final brandProfileSetupViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      BrandProfileSetupViewModel,
      BrandProfileSetupState
    >(BrandProfileSetupViewModel.new);

/// 화면이 보여 줄 오류. 문구는 화면이 정한다.
enum BrandProfileSetupError {
  /// 고른 사진이 5MB를 넘는다.
  photoTooLarge,

  /// 사진 올리기나 프로필 저장이 실패했다.
  saveFailed,

  /// 사진 올리기 주소를 한 시간에 30번 넘게 받으려 했다.
  rateLimited,
}

/// 브랜드 프로필 화면의 상태. 입력 칸의 값은 모두 여기 둔다.
class BrandProfileSetupState {
  const BrandProfileSetupState({
    this.name = '',
    this.tagline = '',
    this.industry,
    this.photo,
    this.saving = false,
    this.error,
  });

  final String name;
  final String tagline;

  /// 고른 업종. 아직 안 골랐으면 null.
  final IndustryCategory? industry;

  /// 고른 사진. 저장할 때 올린다.
  final PickedPhoto? photo;
  final bool saving;
  final BrandProfileSetupError? error;

  /// 이름과 업종이 있어야 `다음`을 켠다. 저장 중에는 다시 누르지 못한다.
  bool get canSubmit => name.trim().isNotEmpty && industry != null && !saving;

  BrandProfileSetupState copyWith({
    String? name,
    String? tagline,
    IndustryCategory? industry,
    PickedPhoto? photo,
    bool clearPhoto = false,
    bool? saving,
    BrandProfileSetupError? error,
    bool clearError = false,
  }) => BrandProfileSetupState(
    name: name ?? this.name,
    tagline: tagline ?? this.tagline,
    industry: industry ?? this.industry,
    photo: clearPhoto ? null : (photo ?? this.photo),
    saving: saving ?? this.saving,
    error: clearError ? null : (error ?? this.error),
  );
}

class BrandProfileSetupViewModel extends AsyncNotifier<BrandProfileSetupState> {
  @override
  FutureOr<BrandProfileSetupState> build() => const BrandProfileSetupState();

  // 입력을 고치면 지난 오류 안내는 지운다.
  void _edit(BrandProfileSetupState Function(BrandProfileSetupState) f) {
    final current = state.value;
    if (current == null || current.saving) return;
    state = AsyncData(f(current).copyWith(clearError: true));
  }

  void setName(String v) => _edit((s) => s.copyWith(name: v));
  void setTagline(String v) => _edit((s) => s.copyWith(tagline: v));
  void setIndustry(IndustryCategory v) => _edit((s) => s.copyWith(industry: v));

  /// 보관함에서 사진을 고른다. 5MB를 넘으면 쓰지 않고 안내한다. 고르지 않고 닫으면 그대로 둔다.
  Future<void> pickPhoto() async {
    final current = state.value;
    if (current == null || current.saving) return;
    final picked = await ref.read(photoPickerProvider).pick();
    if (!ref.mounted || picked == null) return;
    final latest = state.value ?? current;
    if (picked.bytes.length > maxPhotoBytes) {
      state = AsyncData(
        latest
            .copyWith(clearPhoto: true)
            .copyWith(error: BrandProfileSetupError.photoTooLarge),
      );
      return;
    }
    state = AsyncData(latest.copyWith(photo: picked, clearError: true));
  }

  /// 사진을 올리고 프로필을 저장한다. 저장되면 true. 실패하면 입력을 그대로 두고 false.
  Future<bool> submit() async {
    final current = state.value;
    if (current == null || !current.canSubmit) return false;
    state = AsyncData(current.copyWith(saving: true, clearError: true));
    try {
      final photo = current.photo;
      final photoPath = photo == null
          ? null
          : await ref
                .read(photoUploaderProvider)
                .upload(
                  purpose: PhotoPurpose.brandPhoto,
                  bytes: photo.bytes,
                  contentType: photo.contentType,
                );
      await ref
          .read(brandRepositoryProvider)
          .save(
            name: current.name.trim(),
            industry: current.industry!,
            tagline: _blankToNull(current.tagline),
            // 고르지 않았으면 서버에 저장된 사진을 그대로 둔다(저장소가 지키는 규칙).
            photoPath: photoPath,
          );
      if (!ref.mounted) return true;
      state = AsyncData(current.copyWith(saving: false, clearError: true));
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      state = AsyncData(
        current.copyWith(saving: false, error: _errorFor(error)),
      );
      return false;
    }
  }

  static BrandProfileSetupError _errorFor(Object error) => switch (error) {
    PhotoTooLargeException() => BrandProfileSetupError.photoTooLarge,
    PhotoUploadException(isRateLimited: true) =>
      BrandProfileSetupError.rateLimited,
    _ => BrandProfileSetupError.saveFailed,
  };

  static String? _blankToNull(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
