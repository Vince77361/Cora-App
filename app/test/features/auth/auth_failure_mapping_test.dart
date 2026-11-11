import 'dart:async';
import 'dart:io';

import 'package:cora/features/auth/data/supabase_failures.dart';
import 'package:cora/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthApiException,
        AuthException,
        AuthRetryableFetchException,
        AuthUnknownException;

void main() {
  test('an AuthFailure passes through unchanged', () {
    const failure = AuthFailure.invalidCode();

    expect(identical(toAuthFailure(failure), failure), isTrue);
  });

  test('connection problems become network', () {
    final errors = <Object>[
      AuthRetryableFetchException(message: 'x'),
      const SocketException('offline'),
      http.ClientException('offline'),
      TimeoutException('slow'),
      AuthUnknownException(
        message: 'x',
        originalError: const SocketException('offline'),
      ),
    ];
    for (final error in errors) {
      expect(
        toAuthFailure(error).kind,
        AuthFailureKind.network,
        reason: '$error',
      );
    }
  });

  test('an API error keeps only its code', () {
    final failure = toAuthFailure(
      const AuthApiException(
        'Invalid login credentials for someone@example.com',
        statusCode: '400',
        code: 'invalid_credentials',
      ),
    );

    expect(failure.kind, AuthFailureKind.unknown);
    expect(failure.code, 'invalid_credentials');
    expect(failure.toString(), isNot(contains('someone')));
  });

  test('an unrecognised error becomes unknown without its message', () {
    final failure = toAuthFailure(const AuthException('secret message'));
    expect(failure.kind, AuthFailureKind.unknown);

    final other = toAuthFailure(StateError('secret message'));
    expect(other.kind, AuthFailureKind.unknown);
    expect(other.toString(), isNot(contains('secret')));
  });
}
