import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// 기기에서 고른 사진 한 장.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.contentType});

  final Uint8List bytes;

  /// `image/jpeg`, `image/png`, `image/heic`.
  final String contentType;
}

/// 사진 보관함에서 사진을 한 장 고르는 포트. 화면이 `image_picker`를 직접 쓰지 않게 한다.
abstract class PhotoPicker {
  /// 고르지 않고 닫으면 null. 사진의 긴 변이 [maxSide]를 넘으면 그 길이로 줄이고 품질 [quality](0~100)로 다시 담는다.
  /// 대표 게시물은 서버 한도(5MB)를 넘지 않게 긴 변 2048, 품질 85를 준다. 값을 주지 않으면 줄이지 않는다
  /// (프로필 사진처럼 5MB 초과를 화면이 안내하는 곳이 지금처럼 동작하도록).
  Future<PickedPhoto?> pick({int? maxSide, int? quality});
}

/// 기본은 실제 보관함이다. 테스트가 가짜로 바꿔 끼운다.
final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ImagePickerPhotoPicker(),
);

class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedPhoto?> pick({int? maxSide, int? quality}) async {
    // 값을 주지 않으면 크기를 줄이지 않는다. 5MB를 넘는 사진은 올리기 전에 화면이 안내한다.
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxSide?.toDouble(),
      maxHeight: maxSide?.toDouble(),
      imageQuality: quality,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedPhoto(bytes: bytes, contentType: _contentTypeOf(file));
  }

  /// 기기가 알려 주는 형식이 없으면 파일 이름의 확장자로 짐작한다.
  static String _contentTypeOf(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.isNotEmpty) return mime;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.heic') || name.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }
}
