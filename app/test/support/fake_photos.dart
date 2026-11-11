import 'dart:async';
import 'dart:typed_data';

import 'package:cora/core/media/photo_picker.dart';
import 'package:cora/core/network/photo_uploader.dart';

/// 손으로 쓴 가짜 사진 고르기. [next]를 돌려주고, null이면 고르지 않고 닫은 것이다.
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({this.next});

  PickedPhoto? next;
  int pickCalls = 0;

  @override
  Future<PickedPhoto?> pick() async {
    pickCalls++;
    return next;
  }
}

/// 손으로 쓴 가짜 사진 올리기. 실제 구현처럼 5MB 넘는 사진은 먼저 거절한다.
class FakePhotoUploader implements PhotoUploader {
  /// 올리기에 성공하면 돌려줄 저장 위치.
  String path = 'creators/user-1/photo.jpg';

  /// true이면 [upload]가 [PhotoUploadException]을 던진다.
  bool fail = false;

  /// 설정하면 [upload]가 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? hold;

  int uploadCalls = 0;
  PhotoPurpose? lastPurpose;
  Uint8List? lastBytes;
  String? lastContentType;

  @override
  Future<String> upload({
    required PhotoPurpose purpose,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.length > maxPhotoBytes) throw const PhotoTooLargeException();
    uploadCalls++;
    lastPurpose = purpose;
    lastBytes = bytes;
    lastContentType = contentType;
    final wait = hold;
    if (wait != null) await wait.future;
    if (fail) throw const PhotoUploadException();
    return path;
  }
}
