import 'package:cora/features/auth/domain/auth_repository_provider.dart';
import 'package:cora/features/auth/domain/auth_session.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';

/// 구독한 뒤에 바뀐 사용자 ID를 차례대로 모은다(구독은 스트림을 계속 읽게 하는 역할도 한다).
List<String?> _record(ProviderContainer container) {
  final values = <String?>[];
  container.listen<String?>(
    currentUserIdProvider,
    (_, next) => values.add(next),
  );
  return values;
}

void main() {
  test('is null before sign in and the user id after', () async {
    final fake = FakeAuthRepository();
    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    final values = _record(container);
    await pumpEventQueue();

    expect(container.read(currentUserIdProvider), isNull);

    await fake.signInWithKakao();
    await pumpEventQueue();

    expect(
      container.read(currentUserIdProvider),
      FakeAuthRepository.signedInSession.userId,
    );
    expect(values, [FakeAuthRepository.signedInSession.userId]);
  });

  test('is the stored user id when the app starts signed in', () async {
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(session: FakeAuthRepository.signedInSession),
        ),
      ],
    );
    _record(container);
    await pumpEventQueue();

    expect(
      container.read(currentUserIdProvider),
      FakeAuthRepository.signedInSession.userId,
    );
  });

  test('is null again after sign out', () async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    final values = _record(container);
    await pumpEventQueue();

    await fake.signOut();
    await pumpEventQueue();

    expect(container.read(currentUserIdProvider), isNull);
    expect(values.last, isNull);
  });

  test('does not notify when only the token is refreshed', () async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    final values = _record(container);
    await pumpEventQueue();
    values.clear();

    fake.setSession(
      const AuthSession(userId: 'user-1', accessToken: 'token-2'),
    );
    await pumpEventQueue();

    expect(values, isEmpty);
  });

  test('follows a switch to another account', () async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    final values = _record(container);
    await pumpEventQueue();
    values.clear();

    fake.setSession(
      const AuthSession(userId: 'user-2', accessToken: 'token-9'),
    );
    await pumpEventQueue();

    expect(values, ['user-2']);
  });
}
