import 'dart:async';

import 'package:http/http.dart' as http;

/// 요청 하나가 응답을 기다리는 최대 시간.
///
/// `http.Client`에는 기본 제한이 없어서, TCP는 맺어졌는데 응답이 없는 연결(약한 셀 신호,
/// 멈춘 서버)에서는 요청이 끝나지 않는다. 그러면 첫 화면이 빈 채로 남고 "다시 시도"도 뜨지 않는다.
const apiRequestTimeout = Duration(seconds: 15);

/// 응답이 [timeout] 안에 오지 않으면 [TimeoutException]으로 실패시키는 HTTP 클라이언트 감싸개.
///
/// API 요청과 Supabase 요청이 같은 제한을 쓰도록 둘 다 이것으로 감싼다. 던지는 오류는
/// 호출한 쪽이 연결 문제로 다룬다(생성된 API 클라이언트는 `ApiException`으로, gotrue는
/// `AuthRetryableFetchException`으로 바꾼다).
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient(this._inner, {this.timeout = apiRequestTimeout});

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(timeout);

  @override
  void close() => _inner.close();
}
