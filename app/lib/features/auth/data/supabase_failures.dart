import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException, AuthUnknownException;

import '../domain/auth_repository.dart';

/// SDK와 네트워크 오류를 도메인 [AuthFailure]로 바꾼다. 이 경계 밖으로는 SDK 타입이 나가지
/// 않는다. 오류 메시지에는 이메일·전화번호가 섞일 수 있으므로 담지 않고 코드만 남긴다.
AuthFailure toAuthFailure(Object error) {
  if (error is AuthFailure) return error;
  if (error is AuthRetryableFetchException) return const AuthFailure.network();
  if (error is AuthUnknownException &&
      _isConnectionProblem(error.originalError)) {
    return const AuthFailure.network();
  }
  if (_isConnectionProblem(error)) return const AuthFailure.network();
  if (error is AuthException) {
    return AuthFailure.unknown(error.code ?? error.statusCode ?? 'auth_error');
  }
  return AuthFailure.unknown('unexpected_${error.runtimeType}');
}

bool _isConnectionProblem(Object error) =>
    error is SocketException ||
    error is http.ClientException ||
    error is TimeoutException;
