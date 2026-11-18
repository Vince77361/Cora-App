import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cora_api/api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 서버가 오류 응답에 담는 코드(`api/src/common/errors/app-error.ts`의 `ErrorCode`)와 앱이
/// 더하는 값. 서버 목록과 어긋나면 안 되므로 서버 쪽을 바꾸면 여기도 함께 바꾼다.
abstract final class ApiErrorCode {
  static const validationFailed = 'VALIDATION_FAILED';
  static const unauthenticated = 'UNAUTHENTICATED';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const conflict = 'CONFLICT';
  static const staleVersion = 'STALE_VERSION';
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
    staleVersion,
    rateLimited,
    internal,
  };
}

/// 서버가 `details.reason`에 담는 이유 표지(`api/src/payments/payments.service.ts`의 `PAYMENT_IN_PROGRESS_REASON`).
abstract final class ApiErrorReason {
  static const paymentInProgress = 'PAYMENT_IN_PROGRESS';
}

/// 서버 오류 응답(또는 연결 실패)을 화면이 분기하기 쉬운 값으로 푼 것.
///
/// 서버는 모든 오류를 `{"error": {"code", "message", "details", "requestId"}}`로 보낸다. 생성된 클라이언트는
/// 실패하면 `ApiException`을 던지고 `message`에 응답 본문 문자열을 넣는다.
class ApiError {
  const ApiError({
    this.status,
    required this.code,
    this.message,
    this.latestVersion,
    this.reason,
    this.requestId,
  });

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

  /// 수락하려던 판본이 최신이 아닐 때(`STALE_VERSION`) 서버가 `details.latestVersion`에 담아 보낸 최신
  /// 판본 번호. 그 밖의 오류에는 null이다.
  final int? latestVersion;

  /// 같은 코드(409 `CONFLICT`)의 오류를 화면이 가를 수 있게 서버가 `details.reason`에 담아 보낸 이유 표지. 없으면 null.
  final String? reason;

  /// 서버가 오류 본문에 담아 보낸 요청 ID(응답 헤더 `X-Request-Id`와 같은 값). 서버 로그와 이어 볼 때만 쓰므로
  /// 화면에는 보이지 않고 디버그 로그에만 남는다. 본문에 없거나 모양이 다르면 null.
  final String? requestId;

  bool get isConflict => code == ApiErrorCode.conflict;

  /// 결제가 이미 진행 중이라 새 결제를 만들 수 없다(409). 결제창을 연 지 60분 안이다.
  bool get isPaymentInProgress =>
      isConflict && reason == ApiErrorReason.paymentInProgress;

  /// 수락하려는 판본이 최신이 아니다(409). 최신 번호는 [latestVersion]에 있다.
  bool get isStaleVersion => code == ApiErrorCode.staleVersion;
  bool get isRateLimited => code == ApiErrorCode.rateLimited;
  bool get isNotFound => code == ApiErrorCode.notFound;
  bool get isNetwork => code == ApiErrorCode.network;

  // message는 사용자 문구라 개인정보가 섞일 수 있어 로그에 남지 않게 뺀다.
  @override
  String toString() =>
      'ApiError(status: $status, code: $code${requestId == null ? '' : ', requestId: $requestId'})';
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
  final error = ApiError(
    status: status,
    code: body?.code ?? _codeForStatus(status),
    message: body?.message,
    latestVersion: body?.latestVersion,
    reason: body?.reason,
    requestId: body?.requestId,
  );
  // 사용자에게는 보이지 않는다. 개발 중 서버 로그와 이어 보려고 디버그 빌드에서만 남긴다.
  if (kDebugMode && error.requestId != null) {
    debugPrint(
      '[api] 오류 응답 requestId=${error.requestId} 상태=$status 코드=${error.code}',
    );
  }
  return error;
}

final _requestIdPattern = RegExp(r'^[A-Za-z0-9-]{8,64}$');

bool _isNetworkFailure(Object error) =>
    error is SocketException ||
    error is TimeoutException ||
    error is http.ClientException ||
    // TlsException 등 입출력 계열 실패.
    error is IOException;

({
  String code,
  String? message,
  int? latestVersion,
  String? reason,
  String? requestId,
})?
_serverBody(String? raw) {
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
    final details = error['details'];
    final latest = details is Map ? details['latestVersion'] : null;
    final reason = details is Map ? details['reason'] : null;
    final requestId = error['requestId'];
    return (
      code: code,
      message: message is String ? message : null,
      latestVersion: code == ApiErrorCode.staleVersion && latest is int
          ? latest
          : null,
      reason: reason is String ? reason : null,
      // 서버가 정한 모양(영문·숫자·-, 8~64자)만 믿는다. 로그에 이상한 값이 들어가지 않게.
      requestId: requestId is String && _requestIdPattern.hasMatch(requestId)
          ? requestId
          : null,
    );
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
