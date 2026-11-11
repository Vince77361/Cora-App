import 'package:cora/features/onboarding/data/api_me_repository.dart';
import 'package:cora/features/onboarding/domain/me.dart';
import 'package:cora/features/onboarding/domain/me_repository.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiMeRepository _repo(FakeHttpClient http) => ApiMeRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = http,
);

String _body(http.BaseRequest request) => (request as http.Request).body;

void main() {
  test('fetchMe maps a user without a role to a null role', () async {
    final fake = FakeHttpClient()..body = '{"id":"user-1","role":null}';

    final me = await _repo(fake).fetchMe();

    expect(me, const Me(id: 'user-1', role: null));
    expect(fake.requests.single.method, 'GET');
    expect(fake.requests.single.url.path, '/me');
  });

  test('fetchMe maps every server role to the domain role', () async {
    for (final (wire, role) in [
      ('STORE', UserRole.store),
      ('BRAND', UserRole.brand),
      ('CREATOR', UserRole.creator),
    ]) {
      final fake = FakeHttpClient()..body = '{"id":"user-1","role":"$wire"}';
      expect(await _repo(fake).fetchMe(), Me(id: 'user-1', role: role));
    }
  });

  test(
    'updateRole sends the role the server expects and maps the answer',
    () async {
      final fake = FakeHttpClient()..body = '{"id":"user-1","role":"CREATOR"}';

      final me = await _repo(fake).updateRole(UserRole.creator);

      expect(me, const Me(id: 'user-1', role: UserRole.creator));
      final request = fake.requests.single;
      expect(request.method, 'PATCH');
      expect(request.url.path, '/me/role');
      expect(_body(request), contains('"role":"CREATOR"'));
    },
  );

  test(
    'a server error becomes a MeFailure without the server message',
    () async {
      final fake = FakeHttpClient()
        ..statusCode = 500
        ..body = '{"error":{"code":"INTERNAL","message":"secret detail"}}';

      await expectLater(
        _repo(fake).fetchMe(),
        throwsA(
          isA<MeFailure>().having(
            (e) => e.toString(),
            'toString',
            isNot(contains('secret detail')),
          ),
        ),
      );
      await expectLater(
        _repo(fake).updateRole(UserRole.store),
        throwsA(isA<MeFailure>()),
      );
    },
  );

  test(
    'an empty answer is treated as a failure, not as a missing user',
    () async {
      final fake = FakeHttpClient()
        ..statusCode = 204
        ..body = '';

      await expectLater(_repo(fake).fetchMe(), throwsA(isA<MeFailure>()));
      await expectLater(
        _repo(fake).updateRole(UserRole.brand),
        throwsA(isA<MeFailure>()),
      );
    },
  );

  test('a connection error becomes a MeFailure', () async {
    final fake = FakeHttpClient()..respond = (_) => throw const _Unreachable();

    await expectLater(_repo(fake).fetchMe(), throwsA(isA<MeFailure>()));
  });
}

class _Unreachable implements Exception {
  const _Unreachable();
}
