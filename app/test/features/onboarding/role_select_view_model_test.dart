import 'dart:async';

import 'package:cora/features/auth/domain/auth_repository_provider.dart';
import 'package:cora/features/auth/domain/auth_session.dart';
import 'package:cora/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:cora/features/onboarding/domain/me_repository.dart';
import 'package:cora/features/onboarding/domain/me_repository_provider.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/onboarding/presentation/viewmodels/me_view_model.dart';
import 'package:cora/features/onboarding/presentation/viewmodels/role_select_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/fake_auth_repository.dart';
import 'fake_me_repository.dart';

/// 로그인된 상태의 컨테이너. 라우터가 하듯 로그인 상태와 내 정보를 계속 구독해 두고,
/// 로그인 상태가 정해진 뒤에 돌려준다(구독이 없으면 스트림 provider는 멈춰 있다).
Future<ProviderContainer> _signedIn(
  FakeMeRepository me, {
  FakeAuthRepository? auth,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      ),
      meRepositoryProvider.overrideWithValue(me),
    ],
  );
  addTearDown(container.dispose);
  container.listen(authViewModelProvider, (_, _) {});
  container.listen(meViewModelProvider, (_, _) {});
  await container.read(authViewModelProvider.future);
  return container;
}

void main() {
  test(
    'starts with the store role selected when the user has no role',
    () async {
      final container = await _signedIn(FakeMeRepository());

      final state = await container.read(roleSelectViewModelProvider.future);

      expect(state.selected, UserRole.store);
      expect(state.me.role, isNull);
      expect(state.saving, isFalse);
      expect(state.saveFailed, isFalse);
    },
  );

  test('starts with the saved role selected', () async {
    final container = await _signedIn(FakeMeRepository(role: UserRole.brand));

    final state = await container.read(roleSelectViewModelProvider.future);

    expect(state.selected, UserRole.brand);
  });

  test('select changes only the selection', () async {
    final fake = FakeMeRepository();
    final container = await _signedIn(fake);
    await container.read(roleSelectViewModelProvider.future);

    container
        .read(roleSelectViewModelProvider.notifier)
        .select(UserRole.creator);

    expect(
      container.read(roleSelectViewModelProvider).requireValue.selected,
      UserRole.creator,
    );
    expect(fake.updateCalls, 0);
  });

  test('confirm saves the selected role', () async {
    final fake = FakeMeRepository();
    final container = await _signedIn(fake);
    final vm = container.read(roleSelectViewModelProvider.notifier);
    await container.read(roleSelectViewModelProvider.future);

    vm.select(UserRole.creator);
    await vm.confirm();

    expect(fake.savedRole, UserRole.creator);
    final state = container.read(roleSelectViewModelProvider).requireValue;
    expect(state.me.role, UserRole.creator);
    expect(state.saving, isFalse);
    expect(state.saveFailed, isFalse);
    // 라우터가 보는 내 정보도 새 역할로 바뀐다.
    expect(
      container.read(meViewModelProvider).requireValue!.role,
      UserRole.creator,
    );
  });

  test(
    'confirm keeps the selection and reports an error when saving fails',
    () async {
      final fake = FakeMeRepository()..failSave = true;
      final container = await _signedIn(fake);
      final vm = container.read(roleSelectViewModelProvider.notifier);
      await container.read(roleSelectViewModelProvider.future);

      vm.select(UserRole.brand);
      await vm.confirm();

      final state = container.read(roleSelectViewModelProvider).requireValue;
      expect(state.selected, UserRole.brand);
      expect(state.saving, isFalse);
      expect(state.saveFailed, isTrue);
      expect(container.read(meViewModelProvider).requireValue!.role, isNull);

      // 다시 고르면 오류 표시가 사라지고, 다시 눌러 저장할 수 있다.
      vm.select(UserRole.store);
      expect(
        container.read(roleSelectViewModelProvider).requireValue.saveFailed,
        isFalse,
      );
      fake.failSave = false;
      await vm.confirm();
      expect(fake.savedRole, UserRole.store);
    },
  );

  test('confirm ignores a second press while saving', () async {
    final fake = FakeMeRepository()..holdSave = Completer<void>();
    final container = await _signedIn(fake);
    final vm = container.read(roleSelectViewModelProvider.notifier);
    await container.read(roleSelectViewModelProvider.future);

    final first = vm.confirm();
    final second = vm.confirm();
    expect(
      container.read(roleSelectViewModelProvider).requireValue.saving,
      isTrue,
    );
    // 저장 중에는 선택도 바뀌지 않는다.
    vm.select(UserRole.creator);
    fake.holdSave!.complete();
    await Future.wait([first, second]);

    expect(fake.updateCalls, 1);
    expect(fake.savedRole, UserRole.store);
  });

  test('reports an error when /me cannot be loaded', () async {
    final fake = FakeMeRepository()..failFetch = true;
    final container = await _signedIn(fake);

    await expectLater(
      container.read(roleSelectViewModelProvider.future),
      throwsA(isA<MeFailure>()),
    );
    expect(container.read(roleSelectViewModelProvider).hasError, isTrue);
  });

  test('the router and the screen share one /me request', () async {
    final fake = FakeMeRepository()..holdFetch = Completer<void>();
    final container = await _signedIn(fake);

    // 라우터가 먼저 구독하고, 그 사이 화면의 ViewModel도 값을 기다린다.
    final routerView = container.listen(meViewModelProvider, (_, _) {});
    final screen = container.read(roleSelectViewModelProvider.future);
    expect(routerView.read().isLoading, isTrue);
    fake.holdFetch!.complete();
    await screen;

    expect(fake.fetchCalls, 1);
  });

  test(
    'refetches /me for the next user and not for a signed-out app',
    () async {
      final fake = FakeMeRepository();
      final auth = FakeAuthRepository(
        session: FakeAuthRepository.signedInSession,
      );
      final container = await _signedIn(fake, auth: auth);
      container.listen(meViewModelProvider, (_, _) {});
      await container.read(meViewModelProvider.future);
      expect(fake.fetchCalls, 1);

      // 같은 사용자의 토큰 갱신은 다시 부르지 않는다.
      auth.setSession(
        const AuthSession(userId: 'user-1', accessToken: 'token-2'),
      );
      await Future<void>.delayed(Duration.zero);
      await container.read(meViewModelProvider.future);
      expect(fake.fetchCalls, 1);

      auth.endSession();
      await Future<void>.delayed(Duration.zero);
      expect(await container.read(meViewModelProvider.future), isNull);
      expect(fake.fetchCalls, 1);

      auth.setSession(
        const AuthSession(userId: 'user-2', accessToken: 'token-3'),
      );
      await Future<void>.delayed(Duration.zero);
      await container.read(meViewModelProvider.future);
      expect(fake.fetchCalls, 2);
    },
  );

  test(
    'never draws the previous user when /me fails for the next user',
    () async {
      // 이전 사용자는 브랜드 역할을 저장해 두었다.
      final fake = FakeMeRepository(role: UserRole.brand);
      final auth = FakeAuthRepository(
        session: FakeAuthRepository.signedInSession,
      );
      final container = await _signedIn(fake, auth: auth);
      expect(
        (await container.read(meViewModelProvider.future))!.role,
        UserRole.brand,
      );

      // 다른 사용자로 바뀌었고 이번에는 내 정보를 불러오지 못한다.
      fake.failFetch = true;
      auth.setSession(
        const AuthSession(userId: 'user-2', accessToken: 'token-2'),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(meViewModelProvider).hasError, isTrue);

      await expectLater(
        container.read(roleSelectViewModelProvider.future),
        throwsA(isA<MeFailure>()),
      );
    },
  );
}
