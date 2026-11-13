import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/photo_picker.dart';
import '../../../../core/network/photo_uploader.dart';
import '../../domain/my_store.dart';
import '../../domain/store_repository.dart';
import '../../domain/store_repository_provider.dart';
import 'my_store_view_model.dart';
import 'store_edit_view_model.dart' show StorePhotoProblem;

/// 직접 입력 화면(F7)의 상태. 화면을 떠나면 입력도 버린다.
final storeManualViewModelProvider =
    AsyncNotifierProvider.autoDispose<StoreManualViewModel, StoreManualState>(
      StoreManualViewModel.new,
      retry: (_, _) => null,
    );

/// 만들기가 막힌 이유.
enum StoreManualProblem {
  /// 서버에 닿지 못했거나 서버가 거절했다.
  failed,

  /// 이미 공개한 가게는 다시 만들 수 없다(409).
  alreadyPublished,
}

class StoreManualState {
  const StoreManualState({
    this.name = '',
    this.branches = const [],
    this.branchesFor = '',
    this.selectedBranch = 0,
    this.signatureMenu = '',
    this.coverPreview,
    this.coverPhotoPath,
    this.uploadingPhoto = false,
    this.photoProblem,
    this.creating = false,
    this.problem,
  });

  final String name;

  /// 서버가 [branchesFor]라는 이름으로 찾아 준 같은 이름의 가게들.
  final List<StoreBranch> branches;
  final String branchesFor;
  final int selectedBranch;
  final String signatureMenu;

  /// 방금 고른 사진(올리기가 끝나면 이것을 보여 준다)과 올린 저장 위치.
  final Uint8List? coverPreview;
  final String? coverPhotoPath;
  final bool uploadingPhoto;
  final StorePhotoProblem? photoProblem;
  final bool creating;
  final StoreManualProblem? problem;

  /// 지점 줄은 같은 이름의 가게가 둘 이상일 때만 보인다.
  bool get showsBranches => branches.length >= 2;

  /// 만들 때 보내는 지점. 줄이 보이고 그 이름이 지금 이름과 같을 때만 있다(이름을 고치는 중이면
  /// 옛 이름의 지점일 수 있어 보내지 않는다).
  StoreBranch? get chosenBranch => showsBranches && branchesFor == name.trim()
      ? branches[selectedBranch]
      : null;

  /// 가게 이름만 필수다.
  bool get canCreate => name.trim().isNotEmpty && !creating && !uploadingPhoto;

  StoreManualState copyWith({
    String? name,
    List<StoreBranch>? branches,
    String? branchesFor,
    int? selectedBranch,
    String? signatureMenu,
    Uint8List? coverPreview,
    String? coverPhotoPath,
    bool? uploadingPhoto,
    StorePhotoProblem? Function()? photoProblem,
    bool? creating,
    StoreManualProblem? Function()? problem,
  }) => StoreManualState(
    name: name ?? this.name,
    branches: branches ?? this.branches,
    branchesFor: branchesFor ?? this.branchesFor,
    selectedBranch: selectedBranch ?? this.selectedBranch,
    signatureMenu: signatureMenu ?? this.signatureMenu,
    coverPreview: coverPreview ?? this.coverPreview,
    coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
    uploadingPhoto: uploadingPhoto ?? this.uploadingPhoto,
    photoProblem: photoProblem == null ? this.photoProblem : photoProblem(),
    creating: creating ?? this.creating,
    problem: problem == null ? this.problem : problem(),
  );
}

class StoreManualViewModel extends AsyncNotifier<StoreManualState> {
  /// 이름 입력을 멈춘 뒤 이만큼 기다렸다가 같은 이름의 가게를 찾는다.
  static const lookupDelay = Duration(milliseconds: 500);

  Timer? _lookup;
  int _lookups = 0;

  @override
  Future<StoreManualState> build() async {
    ref.onDispose(() => _lookup?.cancel());
    return const StoreManualState();
  }

  void setName(String text) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(name: text, problem: () => null));
    _lookup?.cancel();
    final name = text.trim();
    if (name.isEmpty) {
      // 이름을 다 지우면 옛 지점도 의미가 없다.
      state = AsyncData(
        state.requireValue.copyWith(branches: const [], branchesFor: ''),
      );
      return;
    }
    _lookup = Timer(lookupDelay, () => _findBranches(name));
  }

  Future<void> _findBranches(String name) async {
    final id = ++_lookups;
    List<StoreBranch> found;
    try {
      found = await ref.read(storeRepositoryProvider).findBranches(name);
    } on StoreFailure {
      // 못 찾아도 등록은 계속할 수 있다. 지점 줄만 없다.
      found = const [];
    }
    // 그 사이에 이름을 또 고쳤으면 이 결과는 버린다.
    if (!ref.mounted || id != _lookups) return;
    final current = state.value;
    if (current == null || current.name.trim() != name) return;
    state = AsyncData(
      current.copyWith(branches: found, branchesFor: name, selectedBranch: 0),
    );
  }

  void selectBranch(int index) {
    final current = state.value;
    if (current == null || index < 0 || index >= current.branches.length) {
      return;
    }
    state = AsyncData(current.copyWith(selectedBranch: index));
  }

  void setSignatureMenu(String text) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(signatureMenu: text, problem: () => null),
    );
  }

  /// 사진 보관함에서 한 장 골라 올린다(5MB 이하). 올린 위치는 [create]가 서버에 보낸다.
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

  /// 입력으로 등록 중인 가게를 만든다. 성공하면 true. 실패하면 입력을 그대로 두고
  /// [StoreManualState.problem]이 켜진다.
  Future<bool> create() async {
    final current = state.value;
    if (current == null || !current.canCreate) return false;
    state = AsyncData(current.copyWith(creating: true, problem: () => null));
    final menu = current.signatureMenu.trim();
    try {
      await ref
          .read(myStoreViewModelProvider.notifier)
          .createManually(
            ManualStore(
              name: current.name.trim(),
              branch: current.chosenBranch,
              signatureMenu: menu.isEmpty ? null : menu,
              coverPhotoPath: current.coverPhotoPath,
            ),
          );
      if (ref.mounted) {
        state = AsyncData(state.requireValue.copyWith(creating: false));
      }
      return true;
    } on StoreFailure catch (error) {
      if (ref.mounted) {
        state = AsyncData(
          (state.value ?? current).copyWith(
            creating: false,
            problem: () => error.isConflict
                ? StoreManualProblem.alreadyPublished
                : StoreManualProblem.failed,
          ),
        );
      }
      return false;
    }
  }
}
