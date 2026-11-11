import 'dart:async';

import 'package:cora/features/auth/domain/auth_repository.dart';
import 'package:cora/features/auth/domain/auth_repository_provider.dart';
import 'package:cora/features/auth/presentation/viewmodels/dev_login_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fake;
  late ProviderContainer container;

  setUp(() {
    fake = FakeAuthRepository();
    container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    // autoDispose라 듣는 쪽이 없으면 사라진다. 화면처럼 계속 듣는다.
    container.listen(devLoginViewModelProvider, (_, _) {});
  });

  DevLoginViewModel vm() => container.read(devLoginViewModelProvider.notifier);

  test('signIn passes the credentials to the repository', () async {
    await vm().signIn(email: 'dev@example.com', password: 'secret1');

    expect(fake.signInCalls, 1);
    expect(fake.lastEmail, 'dev@example.com');
    expect(fake.lastPassword, 'secret1');
    expect(fake.currentSession, FakeAuthRepository.signedInSession);
  });

  test('keeps a failed sign in as an AsyncError', () async {
    fake.signInError = const AuthFailure('invalid_credentials');

    await vm().signIn(email: 'dev@example.com', password: 'wrong');

    final state = container.read(devLoginViewModelProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<AuthFailure>());
  });

  test('signUp creates the account through the repository', () async {
    await vm().signUp(email: 'new@example.com', password: 'secret1');

    expect(fake.signUpCalls, 1);
    expect(fake.currentSession, FakeAuthRepository.signedInSession);
  });

  test('ignores a second submit while the first is running', () async {
    fake.holdSignIn = Completer<void>();

    final first = vm().signIn(email: 'dev@example.com', password: 'secret1');
    await vm().signIn(email: 'dev@example.com', password: 'secret1');
    await vm().signUp(email: 'dev@example.com', password: 'secret1');
    fake.holdSignIn!.complete();
    await first;

    expect(fake.signInCalls, 1);
    expect(fake.signUpCalls, 0);
  });
}
