import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/photo_picker.dart';
import '../../../../core/network/photo_uploader.dart';
import '../../domain/my_store.dart';
import '../../domain/store_repository.dart';
import 'my_store_view_model.dart';

/// 가게 정보 고치기 화면의 상태. 화면을 떠나면 고치던 값도 버린다(저장하지 않은 채 닫으면 취소).
final storeEditViewModelProvider =
    AsyncNotifierProvider.autoDispose<StoreEditViewModel, StoreEditState>(
      StoreEditViewModel.new,
      retry: (_, _) => null,
    );

/// 글자로 고치는 항목들.
enum StoreTextField {
  name,
  category,
  neighborhood,
  regionSigungu,
  signatureMenu,
  hours,
  seats,
  bestShootingTime,
  intro,
}

/// 사진을 바꾸다 막힌 이유.
enum StorePhotoProblem { tooLarge, failed }

class StoreEditState {
  const StoreEditState({
    required this.values,
    required this.industry,
    required this.regionSido,
    required this.coverPhotoUrl,
    this.coverPreview,
    this.coverPhotoPath,
    this.uploadingPhoto = false,
    this.photoProblem,
    this.saving = false,
    this.saveFailed = false,
  });

  final Map<StoreTextField, String> values;
  final IndustryCategory industry;
  final String? regionSido;

  /// 지금 가게의 대표 사진 주소.
  final String? coverPhotoUrl;

  /// 방금 고른 사진(저장 전). 올리기가 끝나면 주소 대신 이것을 보여 준다.
  final Uint8List? coverPreview;

  /// 방금 올린 사진의 저장 위치. 저장할 때 서버에 보낸다.
  final String? coverPhotoPath;
  final bool uploadingPhoto;
  final StorePhotoProblem? photoProblem;
  final bool saving;
  final bool saveFailed;

  String valueOf(StoreTextField field) => values[field] ?? '';

  /// 가게 이름은 필수라 비어 있으면 저장할 수 없다.
  bool get canSave =>
      valueOf(StoreTextField.name).trim().isNotEmpty &&
      !saving &&
      !uploadingPhoto;

  StoreEditState copyWith({
    Map<StoreTextField, String>? values,
    IndustryCategory? industry,
    String? Function()? regionSido,
    Uint8List? coverPreview,
    String? coverPhotoPath,
    bool? uploadingPhoto,
    StorePhotoProblem? Function()? photoProblem,
    bool? saving,
    bool? saveFailed,
  }) => StoreEditState(
    values: values ?? this.values,
    industry: industry ?? this.industry,
    regionSido: regionSido == null ? this.regionSido : regionSido(),
    coverPhotoUrl: coverPhotoUrl,
    coverPreview: coverPreview ?? this.coverPreview,
    coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
    uploadingPhoto: uploadingPhoto ?? this.uploadingPhoto,
    photoProblem: photoProblem == null ? this.photoProblem : photoProblem(),
    saving: saving ?? this.saving,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}

class StoreEditViewModel extends AsyncNotifier<StoreEditState> {
  @override
  Future<StoreEditState> build() async {
    final store = await ref.read(myStoreViewModelProvider.future);
    // 가게가 없으면 이 화면에 올 수 없다(링크 입력이 가게를 만든다).
    if (store == null) throw const StoreFailure();
    return StoreEditState(
      values: {
        StoreTextField.name: store.name ?? '',
        StoreTextField.category: store.category ?? '',
        StoreTextField.neighborhood: store.neighborhood ?? '',
        StoreTextField.regionSigungu: store.regionSigungu ?? '',
        StoreTextField.signatureMenu: store.signatureMenu ?? '',
        StoreTextField.hours: store.hours ?? '',
        StoreTextField.seats: store.seats ?? '',
        StoreTextField.bestShootingTime: store.bestShootingTime ?? '',
        StoreTextField.intro: store.intro ?? '',
      },
      industry: store.industry,
      regionSido: store.regionSido,
      coverPhotoUrl: store.coverPhotoUrl,
    );
  }

  void setText(StoreTextField field, String text) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        values: {...current.values, field: text},
        saveFailed: false,
      ),
    );
  }

  void setIndustry(IndustryCategory industry) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(industry: industry));
  }

  void setRegionSido(String sido) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(regionSido: () => sido));
  }

  /// 사진 보관함에서 한 장 골라 올린다. 올린 위치는 [save]가 서버에 보낸다.
  Future<void> changePhoto() async {
    final current = state.value;
    if (current == null || current.uploadingPhoto) return;
    final picked = await ref.read(photoPickerProvider).pick();
    if (picked == null || !ref.mounted) return;
    state = AsyncData(
      current.copyWith(uploadingPhoto: true, photoProblem: () => null),
    );
    try {
      final path = await ref
          .read(photoUploaderProvider)
          .upload(
            purpose: PhotoPurpose.storeCover,
            bytes: picked.bytes,
            contentType: picked.contentType,
          );
      if (!ref.mounted) return;
      state = AsyncData(
        (state.value ?? current).copyWith(
          uploadingPhoto: false,
          coverPreview: picked.bytes,
          coverPhotoPath: path,
        ),
      );
    } on PhotoTooLargeException {
      _photoFailed(StorePhotoProblem.tooLarge);
    } on PhotoUploadException {
      _photoFailed(StorePhotoProblem.failed);
    }
  }

  void _photoFailed(StorePhotoProblem problem) {
    if (!ref.mounted) return;
    state = AsyncData(
      state.value!.copyWith(uploadingPhoto: false, photoProblem: () => problem),
    );
  }

  /// 고친 값을 저장한다. 성공하면 true. 실패하면 화면에 남아 값을 그대로 두고 [StoreEditState.saveFailed]가 켜진다.
  Future<bool> save() async {
    final current = state.value;
    if (current == null || !current.canSave) return false;
    state = AsyncData(current.copyWith(saving: true, saveFailed: false));
    try {
      await ref
          .read(myStoreViewModelProvider.notifier)
          .saveEdit(
            StoreEdit(
              name: current.valueOf(StoreTextField.name).trim(),
              category: current.valueOf(StoreTextField.category).trim(),
              industry: current.industry,
              neighborhood: current.valueOf(StoreTextField.neighborhood).trim(),
              regionSido: current.regionSido,
              regionSigungu: current
                  .valueOf(StoreTextField.regionSigungu)
                  .trim(),
              signatureMenu: current
                  .valueOf(StoreTextField.signatureMenu)
                  .trim(),
              hours: current.valueOf(StoreTextField.hours).trim(),
              seats: current.valueOf(StoreTextField.seats).trim(),
              bestShootingTime: current
                  .valueOf(StoreTextField.bestShootingTime)
                  .trim(),
              intro: current.valueOf(StoreTextField.intro).trim(),
              coverPhotoPath: current.coverPhotoPath,
            ),
          );
      return true;
    } on StoreFailure {
      if (ref.mounted) {
        state = AsyncData(
          (state.value ?? current).copyWith(saving: false, saveFailed: true),
        );
      }
      return false;
    }
  }
}
