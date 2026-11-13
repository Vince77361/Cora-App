import 'dart:async';
import 'dart:typed_data';

import 'package:cora_api/api.dart' as api;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'api_error.dart';

/// 사진이 쓰이는 곳. 서버가 올릴 폴더(`stores/…`, `creators/…`)를 이것으로 정한다. [viewEvidence]는 조회수
/// 캡처로, 공개 저장소가 아니라 비공개 저장소에 올라간다(서버가 정한다).
enum PhotoPurpose { storeCover, creatorPhoto, viewEvidence }

/// 서버가 받는 사진 한 장의 최대 크기(`api/src/uploads/photo-rules.ts`의 `MAX_PHOTO_BYTES`).
const maxPhotoBytes = 5 * 1024 * 1024;

/// 5MB를 넘는 사진. 서버에 묻기 전에 앱이 먼저 막는다.
class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException();

  @override
  String toString() => 'PhotoTooLargeException';
}

/// 사진을 올리지 못했다. 서버 응답 본문이나 주소는 담지 않는다(주소에 올리기 토큰이 들어 있다).
class PhotoUploadException implements Exception {
  const PhotoUploadException({this.isRateLimited = false});

  /// 업로드 주소를 한 시간에 30번 넘게 받으려 했다(429).
  final bool isRateLimited;

  @override
  String toString() => 'PhotoUploadException(rateLimited: $isRateLimited)';
}

/// 사진을 서버 저장소에 올리고, 저장된 위치(`path`)를 돌려준다. 그 `path`를 가게·프로필 저장
/// 요청에 담는다.
abstract class PhotoUploader {
  /// 5MB를 넘으면 서버에 묻지 않고 [PhotoTooLargeException]. 그 밖의 실패는 [PhotoUploadException].
  Future<String> upload({
    required PhotoPurpose purpose,
    required Uint8List bytes,
    required String contentType,
  });
}

/// 기본값은 일부러 던진다. main.dart가 [ApiPhotoUploader]로, 테스트가 가짜로 바꿔 끼운다.
final photoUploaderProvider = Provider<PhotoUploader>(
  (ref) => throw UnimplementedError('photoUploaderProvider must be overridden'),
);

/// 서버에서 올릴 주소(`createPhotoUpload`)를 받고, 그 주소로 파일을 직접 PUT 한다. 파일이 앱
/// 서버를 거치지 않는다.
class ApiPhotoUploader implements PhotoUploader {
  ApiPhotoUploader({
    required this.uploads,
    required this.httpClient,
    this.putTimeout = const Duration(seconds: 60),
  });

  final api.UploadsApi uploads;
  final http.Client httpClient;

  /// 사진을 보내는 데 주는 시간. 일반 API 요청(15초)보다 길다. 5MB를 느린 망에서 보낼 수 있다.
  final Duration putTimeout;

  @override
  Future<String> upload({
    required PhotoPurpose purpose,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.length > maxPhotoBytes) throw const PhotoTooLargeException();
    final wireType = _contentTypes[contentType];
    // 서버가 받지 않는 형식은 묻지 않고 막는다(서버도 같은 목록으로 거른다).
    if (wireType == null) throw const PhotoUploadException();

    final api.PhotoUploadModel? issued;
    try {
      issued = await uploads.createPhotoUpload(
        api.CreatePhotoUploadDto(
          contentType: wireType,
          purpose: switch (purpose) {
            PhotoPurpose.storeCover =>
              api.CreatePhotoUploadDtoPurposeEnum.STORE_COVER,
            PhotoPurpose.creatorPhoto =>
              api.CreatePhotoUploadDtoPurposeEnum.CREATOR_PHOTO,
            PhotoPurpose.viewEvidence =>
              api.CreatePhotoUploadDtoPurposeEnum.VIEW_EVIDENCE,
          },
          sizeBytes: bytes.length,
        ),
      );
    } catch (error) {
      throw PhotoUploadException(
        isRateLimited: ApiError.from(error).isRateLimited,
      );
    }
    if (issued == null) throw const PhotoUploadException();

    try {
      final response = await httpClient
          .put(
            Uri.parse(issued.uploadUrl),
            headers: {'Content-Type': contentType},
            body: bytes,
          )
          .timeout(putTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const PhotoUploadException();
      }
    } on PhotoUploadException {
      rethrow;
    } catch (_) {
      // 연결 끊김, 시간 초과, 잘못된 주소. 오류 객체에 올리기 주소(토큰 포함)가 들어 있을 수
      // 있어 그대로 넘기지 않는다.
      throw const PhotoUploadException();
    }
    return issued.path;
  }

  static const _contentTypes = {
    'image/jpeg': api.CreatePhotoUploadDtoContentTypeEnum.imageSlashJpeg,
    'image/png': api.CreatePhotoUploadDtoContentTypeEnum.imageSlashPng,
    'image/heic': api.CreatePhotoUploadDtoContentTypeEnum.imageSlashHeic,
  };
}
