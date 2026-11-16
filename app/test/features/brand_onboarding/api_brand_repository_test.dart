import 'dart:convert';

import 'package:cora/features/brand_onboarding/data/api_brand_repository.dart';
import 'package:cora/features/brand_onboarding/domain/brand_profile.dart';
import 'package:cora/features/brand_onboarding/domain/brand_repository.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiBrandRepository _repo(FakeHttpClient fake) => ApiBrandRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

Map<String, Object?> _wire({String? photoUrl}) => {
  'userId': 'user-1',
  'name': '느린 결',
  'tagline': '일상의 주얼리',
  'industry': 'ACCESSORY',
  'photoUrl': photoUrl,
};

void main() {
  test('fetch maps every field', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode(_wire(photoUrl: 'https://x/y.jpg'));

    final profile = await _repo(fake).fetchMine();

    expect(fake.requests.single.url.path, '/brands/me');
    expect(
      profile,
      const BrandProfile(
        name: '느린 결',
        tagline: '일상의 주얼리',
        industry: IndustryCategory.accessory,
        photoUrl: 'https://x/y.jpg',
      ),
    );
  });

  test('fetch returns null when no profile exists (404)', () async {
    final fake = FakeHttpClient()
      ..statusCode = 404
      ..body = jsonEncode({
        'error': {'code': 'NOT_FOUND', 'message': '없어요.', 'details': null},
      });

    expect(await _repo(fake).fetchMine(), isNull);
  });

  test('fetch throws a failure on a server error', () async {
    final fake = FakeHttpClient()..statusCode = 500;

    await expectLater(_repo(fake).fetchMine(), throwsA(isA<BrandFailure>()));
  });

  test(
    'save with a new photo sends that path without reading the profile',
    () async {
      final fake = FakeHttpClient()..body = jsonEncode(_wire());

      await _repo(fake).save(
        name: '느린 결',
        industry: IndustryCategory.accessory,
        tagline: '일상의 주얼리',
        photoPath: 'brands/user-1/new.jpg',
      );

      final request = fake.requests.single as http.Request;
      expect(request.method, 'PUT');
      expect(request.url.path, '/brands/me');
      expect(jsonDecode(request.body), {
        'name': '느린 결',
        'tagline': '일상의 주얼리',
        'industry': 'ACCESSORY',
        'photoPath': 'brands/user-1/new.jpg',
      });
    },
  );

  test(
    'save without a photo resends the stored photo path (full replace)',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode(
          _wire(
            photoUrl:
                'https://x.supabase.co/storage/v1/object/public/photos/brands/user-1/old.jpg?t=1',
          ),
        );

      await _repo(
        fake,
      ).save(name: '느린 결', industry: IndustryCategory.accessory);

      expect(fake.requests.map((r) => r.method), ['GET', 'PUT']);
      final put = fake.requests.last as http.Request;
      expect(jsonDecode(put.body)['photoPath'], 'brands/user-1/old.jpg');
    },
  );

  test(
    'save without a photo keeps it empty when the profile has none or does not exist',
    () async {
      final fake = FakeHttpClient()..body = jsonEncode(_wire());

      await _repo(
        fake,
      ).save(name: '느린 결', industry: IndustryCategory.accessory);

      final put = fake.requests.last as http.Request;
      expect(jsonDecode(put.body)['photoPath'], isNull);

      final fresh = FakeHttpClient()
        ..respond = ((r) => r.method == 'GET' ? 404 : 200)
        ..body = jsonEncode(_wire());
      await _repo(
        fresh,
      ).save(name: '느린 결', industry: IndustryCategory.accessory);
      expect(fresh.requests.map((r) => r.method), ['GET', 'PUT']);
    },
  );

  test(
    'save refuses to guess when the stored photo path cannot be recovered',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode(_wire(photoUrl: 'https://elsewhere/photo.jpg'));

      await expectLater(
        _repo(fake).save(name: '느린 결', industry: IndustryCategory.accessory),
        throwsA(isA<BrandFailure>()),
      );
      expect(fake.requests.where((r) => r.method == 'PUT'), isEmpty);
    },
  );

  test('every industry maps both ways', () async {
    for (final industry in IndustryCategory.values) {
      final fake = FakeHttpClient();
      final repo = _repo(fake);
      fake.body = jsonEncode(_wire());
      await repo.save(
        name: 'a',
        industry: industry,
        photoPath: 'brands/user-1/p.jpg',
      );
      final sent = jsonDecode((fake.requests.single as http.Request).body);
      fake.body = jsonEncode({..._wire(), 'industry': sent['industry']});
      expect((await repo.fetchMine())!.industry, industry);
    }
  });
}
