import 'package:cora/features/offers/data/api_received_offers_repository.dart';
import 'package:cora/features/offers/domain/received_offers_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiReceivedOffersRepository _repo(FakeHttpClient fake) =>
    ApiReceivedOffersRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

String _error(String code, String details) =>
    '{"error":{"code":"$code","message":"x","details":$details}}';

void main() {
  test('sends the version number when accepting', () async {
    final fake = FakeHttpClient()..body = '{}';

    // 응답 본문은 이 테스트가 보는 것이 아니라서 읽지 못해도 요청만 확인한다.
    await _repo(fake).accept('o1', 3).catchError((_) {});

    final request = fake.requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/offers/o1/accept');
    expect((request as http.Request).body, contains('"version":3'));
  });

  test('carries the latest version of a stale accept', () async {
    final fake = FakeHttpClient()
      ..statusCode = 409
      ..body = _error('STALE_VERSION', '{"latestVersion":4}');

    await expectLater(
      _repo(fake).accept('o1', 2),
      throwsA(
        isA<ReceivedOffersFailure>()
            .having((f) => f.staleVersion, 'staleVersion', 4)
            .having((f) => f.conflict, 'conflict', isFalse),
      ),
    );
  });

  test(
    'treats a stale accept without a number like an already handled offer',
    () async {
      final fake = FakeHttpClient()
        ..statusCode = 409
        ..body = _error('STALE_VERSION', 'null');

      await expectLater(
        _repo(fake).accept('o1', 2),
        throwsA(
          isA<ReceivedOffersFailure>()
              .having((f) => f.staleVersion, 'staleVersion', isNull)
              .having((f) => f.conflict, 'conflict', isTrue),
        ),
      );
    },
  );
}
