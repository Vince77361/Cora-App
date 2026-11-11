import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 서버의 401 응답 본문(공통 오류 형식).
const unauthenticatedBody =
    '{"error":{"code":"UNAUTHENTICATED","message":"로그인이 필요해요.","details":null}}';

/// 손으로 쓴 가짜 HTTP 클라이언트. 받은 요청을 모으고 정해 둔 상태 코드로 답한다.
class FakeHttpClient extends http.BaseClient {
  int statusCode = 200;
  String body = '{"id":"user-1","role":null}';

  /// 설정하면 요청마다 이 함수가 돌려주는 상태 코드로 답한다([statusCode]보다 우선).
  int Function(http.BaseRequest request)? respond;

  /// 설정하면 답하기 전에 이 Completer가 끝날 때까지 기다린다(동시 요청 흉내).
  Completer<void>? gate;

  /// 답하기 직전에 부른다(요청이 날아가는 사이 세션이 바뀌는 상황 흉내).
  void Function()? beforeRespond;

  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final wait = gate;
    if (wait != null) await wait.future;
    beforeRespond?.call();
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      respond?.call(request) ?? statusCode,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}
