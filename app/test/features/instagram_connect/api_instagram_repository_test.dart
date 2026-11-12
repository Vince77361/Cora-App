import 'dart:convert';

import 'package:cora/features/instagram_connect/data/api_instagram_repository.dart';
import 'package:cora/features/instagram_connect/domain/instagram_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiInstagramRepository _repo(FakeHttpClient fake) => ApiInstagramRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

void main() {
  test('fetch maps the connection and returns null on 404', () async {
    final ok = FakeHttpClient()
      ..body = jsonEncode({'handle': 'haru_cup', 'followers': 1200});
    final connection = await _repo(ok).fetch();
    expect(ok.requests.single.url.path, '/instagram/connection');
    expect((connection!.handle, connection.followers), ('haru_cup', 1200));

    final none = FakeHttpClient()
      ..statusCode = 404
      ..body = jsonEncode({
        'error': {
          'code': 'NOT_FOUND',
          'message': '연결된 인스타그램 계정이 없어요.',
          'details': null,
        },
      });
    expect(await _repo(none).fetch(), isNull);
  });

  test('begin returns the address to open', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({'connectUrl': 'https://api.instagram.test/x'});

    expect(await _repo(fake).begin(), 'https://api.instagram.test/x');
    expect(fake.requests.single.url.path, '/instagram/connect');
  });

  test('complete sends the code (the handle in a dev build)', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({'handle': 'haru_cup', 'followers': null});

    final connection = await _repo(fake).complete('haru_cup');

    final request = fake.requests.single as dynamic;
    expect(request.url.path, '/instagram/connect/complete');
    expect(jsonDecode(request.body as String), {'code': 'haru_cup'});
    expect(connection.handle, 'haru_cup');
    expect(connection.followers, isNull);
  });

  test('keeps the message of a 4xx but not of a 5xx', () async {
    final rejected = FakeHttpClient()
      ..statusCode = 409
      ..body = jsonEncode({
        'error': {
          'code': 'CONFLICT',
          'message': '이미 다른 계정에 연결된 인스타그램 아이디예요.',
          'details': null,
        },
      });
    await expectLater(
      _repo(rejected).complete('taken'),
      throwsA(
        isA<InstagramFailure>().having(
          (e) => e.message,
          'message',
          '이미 다른 계정에 연결된 인스타그램 아이디예요.',
        ),
      ),
    );

    final broken = FakeHttpClient()
      ..statusCode = 500
      ..body = jsonEncode({
        'error': {'code': 'INTERNAL', 'message': 'boom', 'details': null},
      });
    await expectLater(
      _repo(broken).complete('x'),
      throwsA(
        isA<InstagramFailure>().having((e) => e.message, 'message', isNull),
      ),
    );
  });
}
