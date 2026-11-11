import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cora_api/api.dart';
import 'package:http/http.dart' as http;

/// 서버가 오류 응답에 담는 코드(`api/src/common/errors/app-error.ts`의 `ErrorCode`)와 앱이
/// 더하는 값. 서버 목록과 어긋나면 안 되므로 서버 쪽을 바꾸면 여기도 함께 바꾼다.
abstract final class ApiErrorCode {
  static const validationFailed = 'VALIDATION_FAILED';
  static const unauthenticated = 'UNAUTHENTICATED';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const conflict = 'CONFLICT';
  static const rateLimited = 'RATE_LIMITED';
  static const internal = 'INTERNAL';

  /// 서버가 보낸 코드가 아니라 앱이 정한다: 응답을 받지 못한 연결 문제(끊김, 시간 초과).
  static const network = 'NETWORK';

  /// 서버가 보낸 코드가 아니라 앱이 정한다: 위 어디에도 맞지 않는 실패.
  static const unknown = 'UNKNOWN';

  static const _server = {
    validationFailed,
    unauthenticated,
    forbidden,
    notFound,
    conflict,
    rateLimited,
    internal,
  };
}

/// 서버 오류 응답(또는 연결 실패)을 화면이 분기하기 쉬운 값으로 푼 것.
///
/// 서버는 모든 오류를 `{"error": {"code", "message", "details"}}`로 보낸다. 생성된 클라이언트는
/// 실패하면 `ApiException`을 던지고 `message`에 응답 본문 문자열을 넣는다.
class ApiError {
  const ApiError({this.status, required this.code, this.message});

  /// 오류를 해석한다. 던져진 값이 무엇이든 던지지 않고 [ApiError]를 돌려준다.
  factory ApiError.from(Object error) {
    if (error is ApiException) return _fromApiException(error);
    if (_isNetworkFailure(error)) {
      return const ApiError(code: ApiErrorCode.network);
    }
    return const ApiError(code: ApiErrorCode.unknown);
  }

  /// HTTP 상태. 응답을 받지 못했으면 null.
  final int? status;

  /// [ApiErrorCode]의 값.
  final String code;

  /// 서버가 화면에 보여 주라고 보낸 문구. 본문이 서버 형식이 아니면 null.
  final String? message;

  bool get isConflict => code == ApiErrorCode.conflict;
  bool get isRateLimited => code == ApiErrorCode.rateLimited;
  bool get isNotFound => code == ApiErrorCode.notFound;
  bool get isNetwork => code == ApiErrorCode.network;

  // message는 사용자 문구라 개인정보가 섞일 수 있어 로그에 남지 않게 뺀다.
  @override
  String toString() => 'ApiError(status: $status, code: $code)';
}

ApiError _fromApiException(ApiException exception) {
  // 서버의 응답으로 만든 ApiException에는 원인 예외가 없다. 원인이 붙어 있으면 생성된
  // 클라이언트가 요청 중 실패를 상태 400으로 감싼 것이라(소켓 끊김, 시간 초과 등), 서버가
  // 보낸 400(VALIDATION_FAILED)과 섞이지 않게 먼저 가른다.
  final inner = exception.innerException;
  if (inner != null) {
    return ApiError(
      code: _isNetworkFailure(inner)
          ? ApiErrorCode.network
          : ApiErrorCode.unknown,
    );
  }
  final status = exception.code;
  if (status == 0) return const ApiError(code: ApiErrorCode.network);

  final body = _serverBody(exception.message);
  return ApiError(
    status: status,
    code: body?.code ?? _codeForStatus(status),
    message: body?.message,
  );
}

bool _isNetworkFailure(Object error) =>
    error is SocketException ||
    error is TimeoutException ||
    error is http.ClientException ||
    // TlsException 등 입출력 계열 실패.
    error is IOException;

({String code, String? message})? _serverBody(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final error = decoded['error'];
    if (error is! Map) return null;
    final code = error['code'];
    // 모르는 코드는 믿지 않고 상태 코드로 판단한다(서버가 코드를 늘렸는데 앱이 아직 모를 때).
    if (code is! String || !ApiErrorCode._server.contains(code)) return null;
    final message = error['message'];
    return (code: code, message: message is String ? message : null);
  } on FormatException {
    return null;
  }
}

String _codeForStatus(int status) => switch (status) {
  400 => ApiErrorCode.validationFailed,
  401 => ApiErrorCode.unauthenticated,
  403 => ApiErrorCode.forbidden,
  404 => ApiErrorCode.notFound,
  409 => ApiErrorCode.conflict,
  429 => ApiErrorCode.rateLimited,
  _ => ApiErrorCode.unknown,
};
