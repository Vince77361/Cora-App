import 'package:cora/features/auth/data/first_run_marker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_secure_key_value_store.dart';

/// 손으로 쓴 가짜 표시. 첫 실행 여부를 정하고 표시를 남겼는지 본다.
class _FakeFirstRunMarker implements FirstRunMarker {
  _FakeFirstRunMarker({required this.first});

  bool first;
  Object? markError;

  @override
  Future<bool> isFirstRun() async => first;

  @override
  Future<void> markRan() async {
    final error = markError;
    if (error != null) throw error;
    first = false;
  }
}

const _keys = [
  'sb-proj-auth-token',
  'cora.gotrue.supabase.auth.token-code-verifier',
];

void main() {
  late FakeSecureKeyValueStore store;

  setUp(() {
    store = FakeSecureKeyValueStore()
      ..values['sb-proj-auth-token'] = '{"access_token":"a"}'
      ..values['cora.gotrue.supabase.auth.token-code-verifier'] = 'verifier'
      ..values['other'] = 'keep';
  });

  test('clears the stored session on the first run after install', () async {
    final marker = _FakeFirstRunMarker(first: true);

    await clearSessionOnFirstRun(marker: marker, store: store, keys: _keys);

    expect(store.values, {'other': 'keep'});
    expect(marker.first, isFalse);
  });

  test('keeps the session on later runs', () async {
    final marker = _FakeFirstRunMarker(first: false);

    await clearSessionOnFirstRun(marker: marker, store: store, keys: _keys);

    expect(store.values.keys, containsAll(_keys));
  });

  test('starts the app even when clearing the keychain throws', () async {
    final marker = _FakeFirstRunMarker(first: true);
    store.deleteError = StateError('keychain locked');

    await clearSessionOnFirstRun(marker: marker, store: store, keys: _keys);

    // 지우기가 실패했으니 표시를 남기지 않아 다음 실행에서 다시 시도한다.
    expect(marker.first, isTrue);
  });

  test(
    'starts the app even when the marker cannot be read or written',
    () async {
      final marker = _FakeFirstRunMarker(first: true)
        ..markError = StateError('disk full');

      await clearSessionOnFirstRun(marker: marker, store: store, keys: _keys);

      expect(store.values, {'other': 'keep'});
    },
  );

  group('SharedPreferencesFirstRunMarker', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is the first run until markRan is called', () async {
      const marker = SharedPreferencesFirstRunMarker();

      expect(await marker.isFirstRun(), isTrue);
      await marker.markRan();
      expect(await marker.isFirstRun(), isFalse);
    });
  });
}
