import 'dart:async';

import 'package:cora_api/api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/auth_repository_provider.dart';
import '../config/app_config_provider.dart';

/// 실제로 요청을 보내는 HTTP 클라이언트. 테스트가 가짜로 바꿔 끼운다.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// NestJS API 클라이언트(OpenAPI에서 생성).
///
/// - 요청마다 그 순간의 유효한 토큰을 `Authorization: Bearer`로 붙인다. 토큰을 한 번 읽어
///   넣어 두면 갱신된 뒤에도 옛 토큰을 보내게 되고, 만료된 토큰은 먼저 갱신한다.
/// - 서버가 지금 세션의 토큰에 401로 답하면 로그아웃한다. 세션이 끝나면 라우터가 로그인
///   화면으로 보낸다.
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final auth = ref.watch(authRepositoryProvider);
  return ApiClient(
    basePath: config.apiBaseUrl,
    authentication: _SessionBearerAuth(auth),
  )..client = _SignOutOnUnauthorizedClient(ref.watch(httpClientProvider), auth);
});

/// 요청을 보낼 때마다 유효한 토큰을 받아 붙인다.
class _SessionBearerAuth implements Authentication {
  _SessionBearerAuth(this._auth);

  final AuthRepository _auth;

  @override
  Future<void> applyToParams(
    List<QueryParam> queryParams,
    Map<String, String> headerParams,
  ) async {
    // 만료된 토큰이면 갱신이 끝난 뒤의 토큰을 받는다. 만료 토큰을 보내 401을 받고 멀쩡한
    // 세션을 로그아웃하는 일을 막는다.
    final token = await _auth.validAccessToken();
    if (token != null && token.isNotEmpty) {
      headerParams['Authorization'] = 'Bearer $token';
    }
  }
}

/// 401 응답을 보면 로그아웃하는 HTTP 클라이언트 감싸개.
class _SignOutOnUnauthorizedClient extends http.BaseClient {
  _SignOutOnUnauthorizedClient(this._inner, this._auth);

  final http.Client _inner;
  final AuthRepository _auth;

  /// 진행 중인 로그아웃. 동시에 온 401이 로그아웃을 여러 번 부르지 않게 한다.
  Future<void>? _signingOut;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401) {
      // 기기의 세션은 signOut이 부르는 즉시 지워지고(SDK가 서버 요청보다 먼저 지운다) 라우터가
      // 로그인 화면으로 보낸다. 서버 쪽 무효화 왕복은 기다리지 않는다. 호출한 쪽이 401을
      // 다루는 동안 세션은 이미 정리되어 있고, 느린 네트워크가 오류 표시를 붙잡지도 않는다.
      _signOutIfCurrent(request.headers['Authorization']);
    }
    return response;
  }

  void _signOutIfCurrent(String? sentAuthorization) {
    // 진행 중인 로그아웃이 있으면 동시에 온 401이 또 부르지 않는다.
    if (_signingOut != null) return;
    final token = _auth.currentSession?.accessToken;
    // 요청을 보낸 뒤 세션이 바뀌었으면(토큰 갱신, 로그아웃, 다른 계정으로 로그인) 이 401은
    // 지난 토큰에 대한 답이다. 지금 세션은 멀쩡하므로 끊지 않는다.
    if (token == null || sentAuthorization != 'Bearer $token') return;
    _signingOut = _signOut().whenComplete(() => _signingOut = null);
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      // 로그아웃이 실패해도 원래의 401 응답은 그대로 호출한 쪽에 돌려준다.
      if (kDebugMode) debugPrint('[auth] 401 뒤 로그아웃 실패: ${error.runtimeType}');
    }
  }
}
