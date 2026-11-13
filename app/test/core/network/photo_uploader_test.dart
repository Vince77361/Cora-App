import 'dart:convert';
import 'dart:typed_data';

import 'package:cora/core/network/photo_uploader.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

const _issued =
    '{"path":"creators/u1/abc.jpg","uploadUrl":"https://storage.example.test/upload?token=t"}';

ApiPhotoUploader _uploader(FakeHttpClient fake) => ApiPhotoUploader(
  uploads: api.UploadsApi(
    api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
  ),
  httpClient: fake,
);

void main() {
  test('rejects a photo over 5MB before calling the server', () async {
    final fake = FakeHttpClient()..body = _issued;
    final bytes = Uint8List(5 * 1024 * 1024 + 1);

    await expectLater(
      _uploader(fake).upload(
        purpose: PhotoPurpose.creatorPhoto,
        bytes: bytes,
        contentType: 'image/jpeg',
      ),
      throwsA(isA<PhotoTooLargeException>()),
    );
    expect(fake.requests, isEmpty);
  });

  test('accepts exactly 5MB', () async {
    final fake = FakeHttpClient()..body = _issued;
    final path = await _uploader(fake).upload(
      purpose: PhotoPurpose.creatorPhoto,
      bytes: Uint8List(5 * 1024 * 1024),
      contentType: 'image/jpeg',
    );
    expect(path, 'creators/u1/abc.jpg');
  });

  test('asks for the view evidence purpose and PUTs before returning', () async {
    final fake = FakeHttpClient()
      ..body =
          '{"path":"evidence/u1/abc.png","uploadUrl":"https://storage.example.test/upload?token=t"}';

    final path = await _uploader(fake).upload(
      purpose: PhotoPurpose.viewEvidence,
      bytes: Uint8List.fromList([1, 2]),
      contentType: 'image/png',
    );

    expect(path, 'evidence/u1/abc.png');
    expect(jsonDecode((fake.requests[0] as http.Request).body), {
      'contentType': 'image/png',
      'purpose': 'VIEW_EVIDENCE',
      'sizeBytes': 2,
    });
    expect((fake.requests[1] as http.Request).method, 'PUT');
  });

  test(
    'asks for an address, PUTs the bytes with the content type, returns the path',
    () async {
      final fake = FakeHttpClient()..body = _issued;
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final path = await _uploader(fake).upload(
        purpose: PhotoPurpose.storeCover,
        bytes: bytes,
        contentType: 'image/png',
      );

      expect(path, 'creators/u1/abc.jpg');
      expect(fake.requests, hasLength(2));
      final issue = fake.requests[0] as http.Request;
      expect(issue.method, 'POST');
      expect(issue.url.path, '/uploads/photos');
      expect(jsonDecode(issue.body), {
        'contentType': 'image/png',
        'purpose': 'STORE_COVER',
        'sizeBytes': 4,
      });
      final put = fake.requests[1] as http.Request;
      expect(put.method, 'PUT');
      expect(put.url.toString(), 'https://storage.example.test/upload?token=t');
      expect(put.headers['Content-Type'], 'image/png');
      expect(put.bodyBytes, bytes);
    },
  );

  test('maps a creator photo to the CREATOR_PHOTO purpose', () async {
    final fake = FakeHttpClient()..body = _issued;
    await _uploader(fake).upload(
      purpose: PhotoPurpose.creatorPhoto,
      bytes: Uint8List(3),
      contentType: 'image/jpeg',
    );
    final issue = fake.requests[0] as http.Request;
    expect(jsonDecode(issue.body)['purpose'], 'CREATOR_PHOTO');
  });

  test(
    'fails with a rate-limited error when the server says too many uploads',
    () async {
      final fake = FakeHttpClient()
        ..statusCode = 429
        ..body =
            '{"error":{"code":"RATE_LIMITED","message":"x","details":null}}';
      await expectLater(
        _uploader(fake).upload(
          purpose: PhotoPurpose.creatorPhoto,
          bytes: Uint8List(3),
          contentType: 'image/jpeg',
        ),
        throwsA(
          isA<PhotoUploadException>().having(
            (e) => e.isRateLimited,
            'isRateLimited',
            isTrue,
          ),
        ),
      );
    },
  );

  test('fails when the storage PUT is refused', () async {
    final fake = FakeHttpClient()
      ..body = _issued
      ..respond = (request) => request.method == 'PUT' ? 403 : 200;
    await expectLater(
      _uploader(fake).upload(
        purpose: PhotoPurpose.creatorPhoto,
        bytes: Uint8List(3),
        contentType: 'image/jpeg',
      ),
      throwsA(isA<PhotoUploadException>()),
    );
  });

  test(
    'rejects a content type the server does not accept without calling it',
    () async {
      final fake = FakeHttpClient()..body = _issued;
      await expectLater(
        _uploader(fake).upload(
          purpose: PhotoPurpose.creatorPhoto,
          bytes: Uint8List(3),
          contentType: 'image/gif',
        ),
        throwsA(isA<PhotoUploadException>()),
      );
      expect(fake.requests, isEmpty);
    },
  );

  test('photoUploaderProvider throws until it is overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(photoUploaderProvider), throwsA(anything));
  });
}
