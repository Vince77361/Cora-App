import 'dart:async';
import 'dart:io';

import 'package:cora/core/network/api_error.dart';
import 'package:cora_api/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// 서버 필터(`all-exceptions.filter.ts`)가 보내는 오류 본문과 같은 모양.
String _body(String code, String message, {Object? details}) =>
    '{"error":{"code":"$code","message":"$message","details":${details ?? 'null'}}}';

void main() {
  group('server error bodies', () {
    test('reads CONFLICT and its message from a 409 body', () {
      final error = ApiError.from(
        ApiException(409, _body('CONFLICT', '이미 처리된 요청이에요.')),
      );

      expect(error.status, 409);
      expect(error.code, ApiErrorCode.conflict);
      expect(error.message, '이미 처리된 요청이에요.');
      expect(error.isConflict, isTrue);
      expect(error.isRateLimited, isFalse);
      expect(error.isNotFound, isFalse);
      expect(error.isNetwork, isFalse);
    });

    test('reads the latest version of a STALE_VERSION body', () {
      final error = ApiError.from(
        ApiException(
          409,
          _body('STALE_VERSION', '이전 판본이에요.', details: '{"latestVersion":3}'),
        ),
      );

      expect(error.isStaleVersion, isTrue);
      expect(error.isConflict, isFalse);
      expect(error.latestVersion, 3);
    });

    test('has no latest version for other errors or a missing number', () {
      expect(
        ApiError.from(ApiException(409, _body('CONFLICT', 'x'))).latestVersion,
        isNull,
      );
      expect(
        ApiError.from(
          ApiException(409, _body('STALE_VERSION', 'x', details: '{}')),
        ).latestVersion,
        isNull,
      );
    });

    test('reads RATE_LIMITED from a 429 body', () {
      final error = ApiError.from(
        ApiException(429, _body('RATE_LIMITED', '잠시 뒤에 다시 시도해 주세요.')),
      );

      expect(error.status, 429);
      expect(error.code, ApiErrorCode.rateLimited);
      expect(error.message, '잠시 뒤에 다시 시도해 주세요.');
      expect(error.isRateLimited, isTrue);
    });

    test(
      'reads STALE_VERSION from a 409 body and keeps it apart from CONFLICT',
      () {
        final error = ApiError.from(
          ApiException(409, _body('STALE_VERSION', '이전 판본이라 수락할 수 없어요.')),
        );

        expect(error.status, 409);
        expect(error.code, ApiErrorCode.staleVersion);
        expect(error.message, '이전 판본이라 수락할 수 없어요.');
        expect(error.isStaleVersion, isTrue);
        expect(error.isConflict, isFalse);
      },
    );

    test('reads every server error code', () {
      const expected = {
        'VALIDATION_FAILED': (400, ApiErrorCode.validationFailed),
        'UNAUTHENTICATED': (401, ApiErrorCode.unauthenticated),
        'FORBIDDEN': (403, ApiErrorCode.forbidden),
        'NOT_FOUND': (404, ApiErrorCode.notFound),
        'CONFLICT': (409, ApiErrorCode.conflict),
        'INTERNAL': (500, ApiErrorCode.internal),
      };
      for (final entry in expected.entries) {
        final (status, code) = entry.value;
        final error = ApiError.from(
          ApiException(status, _body(entry.key, '문구')),
        );
        expect(error.code, code, reason: entry.key);
      }
    });

    test('keeps a 404 body message and reports isNotFound', () {
      final error = ApiError.from(
        ApiException(404, _body('NOT_FOUND', '찾을 수 없어요.')),
      );

      expect(error.isNotFound, isTrue);
      expect(error.message, '찾을 수 없어요.');
    });

    test('ignores details when reading the code', () {
      final error = ApiError.from(
        ApiException(
          400,
          _body('VALIDATION_FAILED', '값이 올바르지 않아요.', details: '["a"]'),
        ),
      );

      expect(error.code, ApiErrorCode.validationFailed);
    });
  });

  group('bodies that are not the server format', () {
    test('falls back to CONFLICT from a 409 with a non JSON body', () {
      final error = ApiError.from(ApiException(409, 'upstream says no'));

      expect(error.status, 409);
      expect(error.code, ApiErrorCode.conflict);
      expect(error.message, isNull);
      expect(error.isConflict, isTrue);
    });

    test('falls back to the status when the JSON has a different shape', () {
      final error = ApiError.from(ApiException(404, '{"message":"nope"}'));

      expect(error.code, ApiErrorCode.notFound);
      expect(error.message, isNull);
    });

    test('falls back to the status when the error code is not known', () {
      final error = ApiError.from(
        ApiException(409, _body('SOMETHING_NEW', '새 코드')),
      );

      expect(error.code, ApiErrorCode.conflict);
    });

    test('falls back to the status when the body is missing', () {
      final error = ApiError.from(ApiException(429, null));

      expect(error.code, ApiErrorCode.rateLimited);
      expect(error.isRateLimited, isTrue);
    });

    test('maps each status to its code', () {
      const expected = {
        400: ApiErrorCode.validationFailed,
        401: ApiErrorCode.unauthenticated,
        403: ApiErrorCode.forbidden,
        404: ApiErrorCode.notFound,
        409: ApiErrorCode.conflict,
        429: ApiErrorCode.rateLimited,
        500: ApiErrorCode.unknown,
        502: ApiErrorCode.unknown,
      };
      for (final entry in expected.entries) {
        expect(
          ApiError.from(ApiException(entry.key, 'x')).code,
          entry.value,
          reason: '${entry.key}',
        );
      }
    });
  });

  group('network failures', () {
    // 생성된 클라이언트는 연결 실패를 상태 400의 ApiException으로 감싸 던진다. 서버가 보낸
    // 400(VALIDATION_FAILED)과 구분되는 점은 원인 예외(innerException)가 붙어 있다는 것이다.
    test('treats a wrapped SocketException as NETWORK', () {
      final error = ApiError.from(
        ApiException.withInner(
          400,
          'Socket operation failed: GET /me',
          const SocketException('offline'),
          StackTrace.empty,
        ),
      );

      expect(error.code, ApiErrorCode.network);
      expect(error.isNetwork, isTrue);
      expect(error.isConflict, isFalse);
    });

    test('treats a wrapped TimeoutException as NETWORK', () {
      final error = ApiError.from(
        ApiException.withInner(
          400,
          'Exception occurred: GET /me',
          TimeoutException('too slow'),
          StackTrace.empty,
        ),
      );

      expect(error.code, ApiErrorCode.network);
    });

    test('treats a wrapped http ClientException as NETWORK', () {
      final error = ApiError.from(
        ApiException.withInner(
          400,
          'HTTP connection failed: GET /me',
          http.ClientException('closed'),
          StackTrace.empty,
        ),
      );

      expect(error.code, ApiErrorCode.network);
    });

    test('treats bare network exceptions as NETWORK', () {
      expect(
        ApiError.from(const SocketException('offline')).code,
        ApiErrorCode.network,
      );
      expect(
        ApiError.from(TimeoutException('too slow')).code,
        ApiErrorCode.network,
      );
      expect(
        ApiError.from(http.ClientException('closed')).code,
        ApiErrorCode.network,
      );
    });

    test('treats an ApiException with status 0 as NETWORK', () {
      expect(ApiError.from(ApiException(0, 'x')).code, ApiErrorCode.network);
    });

    test('keeps a status 400 server body as VALIDATION_FAILED', () {
      final error = ApiError.from(
        ApiException(400, _body('VALIDATION_FAILED', '값이 올바르지 않아요.')),
      );

      expect(error.code, ApiErrorCode.validationFailed);
      expect(error.isNetwork, isFalse);
    });
  });

  group('unknown failures', () {
    test('maps an unknown exception to UNKNOWN', () {
      final error = ApiError.from(StateError('boom'));

      expect(error.code, ApiErrorCode.unknown);
      expect(error.status, isNull);
      expect(error.message, isNull);
    });

    test('maps a deserialization failure to UNKNOWN', () {
      final error = ApiError.from(
        ApiException.withInner(
          500,
          'Exception during deserialization.',
          const FormatException('bad'),
          StackTrace.empty,
        ),
      );

      expect(error.code, ApiErrorCode.unknown);
    });

    test('does not print the message in toString', () {
      final error = ApiError.from(
        ApiException(409, _body('CONFLICT', '010-0000-0001')),
      );

      expect(error.toString(), isNot(contains('010-0000-0001')));
    });
  });
}
