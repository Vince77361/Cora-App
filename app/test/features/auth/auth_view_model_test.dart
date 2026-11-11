import 'package:cora/features/auth/domain/auth_repository_provider.dart';
import 'package:cora/features/auth/domain/auth_session.dart';
import 'package:cora/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';

ProviderContainer _container(FakeAuthRepository fake) => ProviderContainer.test(
  overrides: [authRepositoryProvider.overrideWithValue(fake)],
);

/// 받은 세션 값을 차례대로 모은다(로딩 상태는 빼고).
List<AuthSession?> _record(ProviderContainer container) {
  final values = <AuthSession?>[];
  container.listen<AsyncValue<AuthSession?>>(authViewModelProvider, (_, next) {
    if (next.hasValue) values.add(next.value);
  }, fireImmediately: true);
  return values;
}

void main() {
  test('emits null then a session after sign in', () async {
    final fake = FakeAuthRepository();
    final container = _container(fake);
    final values = _record(container);

    expect(await container.read(authViewModelProvider.future), isNull);

    await fake.signInWithKakao();
    await pumpEventQueue();

    expect(values, [null, FakeAuthRepository.signedInSession]);
  });

  test('starts with the stored session without passing through null', () async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    final container = _container(fake);
    final values = _record(container);

    await container.read(authViewModelProvider.future);
    await pumpEventQueue();

    expect(values, [FakeAuthRepository.signedInSession]);
  });

  test('follows a refreshed token', () async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    final container = _container(fake);
    final values = _record(container);
    await container.read(authViewModelProvider.future);

    const refreshed = AuthSession(userId: 'user-1', accessToken: 'token-2');
    fake.setSession(refreshed);
    await pumpEventQueue();

    expect(values.last, refreshed);
  });

  test('signOut ends the session', () async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    final container = _container(fake);
    final values = _record(container);
    await container.read(authViewModelProvider.future);

    await container.read(authViewModelProvider.notifier).signOut();
    await pumpEventQueue();

    expect(fake.signOutCalls, 1);
    expect(values.last, isNull);
  });

  test('a session never prints its access token', () {
    expect(
      FakeAuthRepository.signedInSession.toString(),
      isNot(contains('token-1')),
    );
  });
}
