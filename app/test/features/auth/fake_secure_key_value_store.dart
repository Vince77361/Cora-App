import 'package:cora/features/auth/data/secure_key_value_store.dart';

/// 손으로 쓴 가짜 보안 저장소. 메모리에 담고, 읽기를 실패시킬 수 있다.
class FakeSecureKeyValueStore implements SecureKeyValueStore {
  final values = <String, String>{};

  /// null이 아니면 읽기가 이 오류를 던진다(잠긴 키체인 흉내).
  Object? readError;

  /// null이 아니면 지우기가 이 오류를 던진다.
  Object? deleteError;

  @override
  Future<String?> read(String key) async {
    final error = readError;
    if (error != null) throw error;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async {
    final error = deleteError;
    if (error != null) throw error;
    values.remove(key);
  }
}
