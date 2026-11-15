import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 보안 저장소(iOS Keychain, Android Keystore로 암호화한 저장소)의 경계.
///
/// 플러그인 타입을 이 파일 밖으로 내보내지 않으려고 만든 작은 인터페이스다. 세션 저장
/// 어댑터는 이것만 알고, 테스트는 플랫폼 채널 없이 손으로 쓴 가짜를 끼운다.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// [FlutterSecureStorage]로 만든 실제 구현.
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore([
    this._storage = const FlutterSecureStorage(
      // 기본값(unlocked)은 기기가 잠겨 있으면 읽지 못한다. 앱이 백그라운드에서 깨어나
      // 토큰을 갱신하려 할 때 막히지 않도록 "처음 한 번 잠금을 푼 뒤"부터 읽을 수 있게 한다.
      // `_this_device`라서 암호화 백업·기기 이전으로 다른 기기에 옮겨 가지 않는다(리프레시
      // 토큰이 복원본으로 새는 길을 막는 것이고, 기기를 바꾸면 다시 로그인한다). 소유자
      // 결정 15. 등급을 바꿔도 플러그인이 읽기·지우기 때 다른 등급의 항목까지 찾으므로 이전
      // 등급으로 저장된 세션도 그대로 읽힌다.
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
