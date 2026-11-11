import 'dart:async';

import 'package:cora/core/network/timeout_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

void main() {
  test('the request timeout is 15 seconds', () {
    expect(apiRequestTimeout, const Duration(seconds: 15));
  });

  testWidgets('fails with a TimeoutException when nothing answers', (
    tester,
  ) async {
    // 끝나지 않는 연결: gate를 끝내지 않는다.
    final inner = FakeHttpClient()..gate = Completer<void>();
    final client = TimeoutHttpClient(inner);

    final result = expectLater(
      client.send(http.Request('GET', Uri.parse('http://127.0.0.1:3000/me'))),
      throwsA(isA<TimeoutException>()),
    );
    await tester.pump(apiRequestTimeout - const Duration(seconds: 1));
    expect(inner.requests, hasLength(1));
    await tester.pump(const Duration(seconds: 1));

    await result;
  });

  testWidgets('passes a prompt response through untouched', (tester) async {
    final client = TimeoutHttpClient(FakeHttpClient());

    final response = await client.send(
      http.Request('GET', Uri.parse('http://127.0.0.1:3000/me')),
    );

    expect(response.statusCode, 200);
  });
}
