import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/photo_picker.dart';
import '../../../../core/network/photo_uploader.dart';
import '../../domain/view_report_repository.dart';
import 'view_report_view_model.dart';

/// 서버가 받는 조회수의 상한(`api`의 캡처 제출 검증). 이보다 큰 수는 앱이 먼저 막는다.
const maxEvidenceViews = 1000000000;

enum ViewEvidenceError { photoTooLarge, rateLimited, viewsTooLarge, failed }

class ViewEvidenceState {
  const ViewEvidenceState({
    this.photo,
    this.busy = false,
    this.error,
    this.message,
  });

  final PickedPhoto? photo;

  /// 올리고 제출하는 중. 그동안은 다시 누르지 못한다.
  final bool busy;
  final ViewEvidenceError? error;

  /// 서버가 보낸 문구(4xx일 때만). 있으면 [error]보다 먼저 보인다.
  final String? message;

  ViewEvidenceState copyWith({
    PickedPhoto? photo,
    bool clearPhoto = false,
    bool? busy,
    ViewEvidenceError? error,
    String? message,
    bool clearError = false,
  }) => ViewEvidenceState(
    photo: clearPhoto ? null : (photo ?? this.photo),
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
    message: clearError ? null : (message ?? this.message),
  );
}

/// 조회수 캡처 올리기. 사진을 고르고, 사진을 저장소에 올린 **뒤에만** 서버에 제출한다(올린 파일이 없으면
/// 서버가 거절하므로, 올리기가 실패하면 제출하지 않고 오류를 보인다). 협업마다 하나이고 화면을 떠나면
/// 버린다.
final viewEvidenceViewModelProvider = NotifierProvider.autoDispose
    .family<ViewEvidenceViewModel, ViewEvidenceState, String>(
      ViewEvidenceViewModel.new,
    );

class ViewEvidenceViewModel extends Notifier<ViewEvidenceState> {
  ViewEvidenceViewModel(this.collaborationId);

  final String collaborationId;

  @override
  ViewEvidenceState build() => const ViewEvidenceState();

  /// 보관함에서 사진을 고른다. 5MB를 넘으면 쓰지 않고 안내한다. 고르지 않고 닫으면 그대로 둔다.
  Future<void> pickPhoto() async {
    if (state.busy) return;
    final picked = await ref.read(photoPickerProvider).pick();
    if (!ref.mounted || picked == null) return;
    if (picked.bytes.length > maxPhotoBytes) {
      state = state.copyWith(
        clearPhoto: true,
        error: ViewEvidenceError.photoTooLarge,
      );
      return;
    }
    state = state.copyWith(photo: picked, clearError: true);
  }

  /// 올리고 제출한다. 성공하면 true(F4가 새 상태로 바뀐다). 실패하면 입력을 그대로 두고 false.
  Future<bool> submit(int views) async {
    final photo = state.photo;
    if (photo == null || state.busy) return false;
    // 다시 해도 같은 결과라 `다시 시도`가 아니라 이유를 보인다.
    if (views < 0 || views > maxEvidenceViews) {
      state = state.copyWith(error: ViewEvidenceError.viewsTooLarge);
      return false;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final path = await ref
          .read(photoUploaderProvider)
          .upload(
            purpose: PhotoPurpose.viewEvidence,
            bytes: photo.bytes,
            contentType: photo.contentType,
          );
      final next = await ref
          .read(viewReportRepositoryProvider)
          .submitEvidence(collaborationId, path, views);
      if (!ref.mounted) return true;
      ref
          .read(viewReportViewModelProvider(collaborationId).notifier)
          .apply(next);
      state = state.copyWith(busy: false);
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        busy: false,
        error: switch (error) {
          PhotoTooLargeException() => ViewEvidenceError.photoTooLarge,
          PhotoUploadException(isRateLimited: true) =>
            ViewEvidenceError.rateLimited,
          _ => ViewEvidenceError.failed,
        },
        message: error is ViewReportFailure && (error.message ?? '').isNotEmpty
            ? error.message
            : null,
      );
      return false;
    }
  }
}
