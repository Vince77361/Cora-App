import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show GotrueAsyncStorage, LocalStorage;

import 'secure_key_value_store.dart';

/// 로그인 세션(액세스·리프레시 토큰)을 보안 저장소에 두는 [LocalStorage].
///
/// supabase_flutter의 기본 저장소는 SharedPreferences(iOS는 NSUserDefaults)라서 토큰이
/// 평문 설정 파일에 남는다. 보안 기준이 모바일 credential은 Keychain/Keystore에 두라고
/// 하므로 같은 계약을 보안 저장소 위에 구현한다.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage({
    required this._store,
    required this.persistSessionKey,
  });

  final SecureKeyValueStore _store;

  /// 세션을 담는 키. SDK 기본값(`sb-<프로젝트>-auth-token`)과 같은 모양으로 넘긴다.
  final String persistSessionKey;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  /// 읽기에 실패하면 저장된 세션이 없는 것으로 본다. SDK는 이 호출을 감싸지 않아서 던지면
  /// 앱이 시작하지 못하는데, 세션을 못 읽을 때 로그아웃 상태로 시작하는 쪽이 안전하다
  /// (키체인은 재부팅 뒤 첫 잠금 해제 전에 읽히지 않을 수 있다). 저장된 값은 지우지 않는다.
  @override
  Future<String?> accessToken() async {
    try {
      return await _store.read(persistSessionKey);
    } catch (error) {
      if (kDebugMode) debugPrint('[auth] 세션 읽기 실패: ${error.runtimeType}');
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(persistSessionKey, persistSessionString);

  @override
  Future<void> removePersistedSession() => _store.delete(persistSessionKey);
}

/// PKCE 로그인 중간값(code verifier)을 보안 저장소에 두는 [GotrueAsyncStorage].
///
/// 지금은 가짜 인증(이메일 로그인)만 쓰지만 카카오·네이버 OAuth가 붙으면 이 값이 생긴다. 그때 기본
/// 저장소(평문 설정)로 새지 않도록 미리 같은 곳에 둔다.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  const SecureGotrueAsyncStorage({required this._store});

  final SecureKeyValueStore _store;

  /// 세션 키와 겹치지 않게 접두어를 붙인다.
  static String _scoped(String key) => 'cora.gotrue.$key';

  @override
  Future<String?> getItem({required String key}) => _store.read(_scoped(key));

  @override
  Future<void> setItem({required String key, required String value}) =>
      _store.write(_scoped(key), value);

  @override
  Future<void> removeItem({required String key}) => _store.delete(_scoped(key));
}
