import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/photo_picker.dart';
import '../../../../core/network/photo_uploader.dart';
import '../../domain/creator_profile_repository.dart';

/// 화면을 떠나면 입력도 버린다.
final creatorProfileSetupViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      CreatorProfileSetupViewModel,
      CreatorProfileSetupState
    >(CreatorProfileSetupViewModel.new);

/// 화면이 보여 줄 오류. 문구는 화면이 정한다.
enum CreatorProfileSetupError {
  /// 고른 사진이 5MB를 넘는다.
  photoTooLarge,

  /// 사진 올리기나 프로필 저장이 실패했다.
  saveFailed,

  /// 사진 올리기 주소를 한 시간에 30번 넘게 받으려 했다.
  rateLimited,
}

/// 크리에이터 최소 프로필 화면의 상태. 입력 칸의 값은 모두 여기 둔다.
class CreatorProfileSetupState {
  const CreatorProfileSetupState({
    this.displayName = '',
    this.contentFocus = '',
    this.instagramHandle = '',
    this.cardHeadline = '',
    this.regionSido,
    this.regionSigungu = '',
    this.photo,
    this.cardPhoto,
    this.saving = false,
    this.error,
  });

  final String displayName;
  final String contentFocus;
  final String instagramHandle;

  /// 브랜드가 보는 카드의 `대표 콘텐츠 한 줄`(최대 40자).
  final String cardHeadline;

  /// 고른 시·도. 아직 안 골랐으면 null.
  final String? regionSido;
  final String regionSigungu;

  /// 고른 사진. 저장할 때 올린다.
  final PickedPhoto? photo;

  /// 브랜드가 보는 카드의 `대표 사진`. 저장할 때 올린다.
  final PickedPhoto? cardPhoto;
  final bool saving;
  final CreatorProfileSetupError? error;

  /// 활동 이름과 시·도가 있어야 시작할 수 있다. 저장 중에는 다시 누르지 못한다.
  bool get canSubmit =>
      displayName.trim().isNotEmpty && regionSido != null && !saving;

  CreatorProfileSetupState copyWith({
    String? displayName,
    String? contentFocus,
    String? instagramHandle,
    String? cardHeadline,
    String? regionSido,
    String? regionSigungu,
    PickedPhoto? photo,
    bool clearPhoto = false,
    PickedPhoto? cardPhoto,
    bool clearCardPhoto = false,
    bool? saving,
    CreatorProfileSetupError? error,
    bool clearError = false,
  }) => CreatorProfileSetupState(
    displayName: displayName ?? this.displayName,
    contentFocus: contentFocus ?? this.contentFocus,
    instagramHandle: instagramHandle ?? this.instagramHandle,
    cardHeadline: cardHeadline ?? this.cardHeadline,
    regionSido: regionSido ?? this.regionSido,
    regionSigungu: regionSigungu ?? this.regionSigungu,
    photo: clearPhoto ? null : (photo ?? this.photo),
    cardPhoto: clearCardPhoto ? null : (cardPhoto ?? this.cardPhoto),
    saving: saving ?? this.saving,
    error: clearError ? null : (error ?? this.error),
  );
}

class CreatorProfileSetupViewModel
    extends AsyncNotifier<CreatorProfileSetupState> {
  @override
  FutureOr<CreatorProfileSetupState> build() =>
      const CreatorProfileSetupState();

  // 입력을 고치면 지난 오류 안내는 지운다.
  void _edit(CreatorProfileSetupState Function(CreatorProfileSetupState) f) {
    final current = state.value;
    if (current == null || current.saving) return;
    state = AsyncData(f(current).copyWith(clearError: true));
  }

  void setDisplayName(String v) => _edit((s) => s.copyWith(displayName: v));
  void setContentFocus(String v) => _edit((s) => s.copyWith(contentFocus: v));
  void setInstagramHandle(String v) =>
      _edit((s) => s.copyWith(instagramHandle: v));
  void setCardHeadline(String v) => _edit((s) => s.copyWith(cardHeadline: v));
  void setRegionSido(String v) => _edit((s) => s.copyWith(regionSido: v));
  void setRegionSigungu(String v) => _edit((s) => s.copyWith(regionSigungu: v));

  /// 보관함에서 사진을 고른다. 5MB를 넘으면 쓰지 않고 안내한다. 고르지 않고 닫으면 그대로 둔다.
  Future<void> pickPhoto() => _pick(card: false);

  /// 브랜드가 보는 카드의 `대표 사진`을 고른다. 규칙은 [pickPhoto]와 같다.
  Future<void> pickCardPhoto() => _pick(card: true);

  Future<void> _pick({required bool card}) async {
    final current = state.value;
    if (current == null || current.saving) return;
    final picked = await ref.read(photoPickerProvider).pick();
    if (!ref.mounted || picked == null) return;
    final latest = state.value ?? current;
    if (picked.bytes.length > maxPhotoBytes) {
      state = AsyncData(
        (card
                ? latest.copyWith(clearCardPhoto: true)
                : latest.copyWith(clearPhoto: true))
            .copyWith(error: CreatorProfileSetupError.photoTooLarge),
      );
      return;
    }
    state = AsyncData(
      (card
              ? latest.copyWith(cardPhoto: picked)
              : latest.copyWith(photo: picked))
          .copyWith(clearError: true),
    );
  }

  /// 사진을 올리고 프로필을 저장한다. 저장되면 true. 실패하면 입력을 그대로 두고 false.
  Future<bool> submit() async {
    final current = state.value;
    if (current == null || !current.canSubmit) return false;
    state = AsyncData(current.copyWith(saving: true, clearError: true));
    try {
      final photoPath = await _upload(current.photo, PhotoPurpose.creatorPhoto);
      final cardPhotoPath = await _upload(
        current.cardPhoto,
        PhotoPurpose.creatorCard,
      );
      await ref
          .read(creatorProfileRepositoryProvider)
          .save(
            displayName: current.displayName.trim(),
            regionSido: current.regionSido!,
            regionSigungu: _blankToNull(current.regionSigungu),
            contentFocus: _blankToNull(current.contentFocus),
            instagramHandle: _blankToNull(current.instagramHandle),
            photoPath: photoPath,
            // 비워 두면 서버에 저장된 카드 값을 그대로 둔다(저장소가 지키는 규칙).
            cardHeadline: _blankToNull(current.cardHeadline),
            cardPhotoPath: cardPhotoPath,
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

  Future<String?> _upload(PickedPhoto? photo, PhotoPurpose purpose) async {
    if (photo == null) return null;
    return ref
        .read(photoUploaderProvider)
        .upload(
          purpose: purpose,
          bytes: photo.bytes,
          contentType: photo.contentType,
        );
  }

  static CreatorProfileSetupError _errorFor(Object error) => switch (error) {
    PhotoTooLargeException() => CreatorProfileSetupError.photoTooLarge,
    PhotoUploadException(isRateLimited: true) =>
      CreatorProfileSetupError.rateLimited,
    _ => CreatorProfileSetupError.saveFailed,
  };

  static String? _blankToNull(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
