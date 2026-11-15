import 'dart:async';
import 'dart:convert';

import 'package:cora/core/time/clock.dart';
import 'package:cora/features/auth/data/fake_sign_in_adapter.dart';
import 'package:cora/features/auth/data/secure_session_storage.dart'
    show SecureGotrueAsyncStorage;
import 'package:cora/features/auth/data/supabase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show GoTrueClient;

import '../../../support/fake_http_client.dart';
import '../fake_secure_key_value_store.dart';

class _FixedClock implements Clock {
  _FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

String _b64(Map<String, Object?> json) =>
    base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

/// `exp`가 들어 있는 가짜 JWT. SDK는 만료 시각을 이 `exp`에서 읽는다.
String _jwt({required DateTime exp}) =>
    '${_b64({'alg': 'none'})}.${_b64({'sub': 'user-1', 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.sig';

String _sessionBody(String accessToken) =>
    '{"access_token":"$accessToken","token_type":"bearer","expires_in":20,'
    '"refresh_token":"refresh-1","user":{"id":"user-1","aud":"authenticated",'
    '"app_metadata":{},"user_metadata":{},"created_at":"2026-01-01T00:00:00Z"}}';

/// 갱신이 서버 오류로 실패한 채, 토큰이 SDK의 여유 시간(30초) 안에만 든 세션을 만든다.
/// SDK는 서버 오류를 재시도(백오프)하므로 가짜 시간을 흘려 그 기다림을 건너뛴다.
Future<
  ({
    SupabaseAuthRepository repository,
    _FixedClock clock,
    DateTime exp,
    String token,
  })
>
_setUp(WidgetTester tester) async {
  final http = FakeHttpClient();
  final auth = GoTrueClient(
    url: 'https://example.supabase.co/auth/v1',
    httpClient: http,
    asyncStorage: SecureGotrueAsyncStorage(store: FakeSecureKeyValueStore()),
    autoRefreshToken: false,
  );
  // SDK는 만료 30초 전부터 "만료"로 보므로, 20초 뒤에 끝나는 토큰은 SDK 눈에는 만료됐지만
  // 실제로는 아직 쓸 수 있다.
  final now = DateTime.now();
  final exp = now.add(const Duration(seconds: 20));
  final token = _jwt(exp: exp);
  http.body = _sessionBody(token);
  await auth.signInWithPassword(email: 'a@example.com', password: 'secret1');
  final clock = _FixedClock(now);
  // 이제부터 갱신 요청은 서버 오류로 실패한다.
  http
    ..statusCode = 500
    ..body = '{"message":"down"}';
  return (
    repository: SupabaseAuthRepository(
      auth,
      signInAdapter: FakeSignInAdapter.supabase(auth),
      clock: clock,
    ),
    clock: clock,
    exp: exp,
    token: token,
  );
}

Future<String?> _validToken(
  WidgetTester tester,
  SupabaseAuthRepository repository,
) async {
  String? result;
  var done = false;
  unawaited(
    repository.validAccessToken().then((token) {
      result = token;
      done = true;
    }),
  );
  for (var i = 0; i < 60 && !done; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  expect(done, isTrue);
  return result;
}

void main() {
  testWidgets('returns the current token when refresh fails but the token has '
      'not really expired', (tester) async {
    final s = await _setUp(tester);

    expect(await _validToken(tester, s.repository), s.token);
  });

  testWidgets('returns null when refresh fails and the token is past its exp', (
    tester,
  ) async {
    final s = await _setUp(tester);
    s.clock.value = s.exp.add(const Duration(seconds: 1));

    expect(await _validToken(tester, s.repository), isNull);
  });
}
