import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_key_value_store.dart';

/// 앱을 설치한 뒤 처음 켠 것인지 기억하는 표시.
///
/// iOS의 키체인은 앱을 지워도 남는다. 그래서 지웠다 다시 깐 앱이 옛 로그인 세션을 이어받아
/// 로그인 화면 없이 열릴 수 있다. 앱을 지우면 함께 지워지는 저장소에 표시를 남겨서, 표시가
/// 없으면 "새로 설치한 것"으로 보고 키체인의 세션을 비운다.
abstract class FirstRunMarker {
  Future<bool> isFirstRun();

  Future<void> markRan();
}

/// `shared_preferences`로 만든 실제 구현. 앱 데이터와 함께 지워진다.
class SharedPreferencesFirstRunMarker implements FirstRunMarker {
  const SharedPreferencesFirstRunMarker();

  static const _key = 'cora.hasRunBefore';

  @override
  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  @override
  Future<void> markRan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

/// 첫 실행이면 [keys]의 세션 값(세션과 PKCE 값)을 지우고 표시를 남긴다.
///
/// `Supabase.initialize`가 세션을 읽기 전에 불러야 한다. 어떤 단계가 실패해도 던지지 않고
/// 디버그 로그만 남긴다. 키체인이 잠겨 지우지 못했다면 표시를 남기지 않아 다음 실행에서
/// 다시 시도한다. 이 정리 때문에 앱이 켜지지 못하는 것이 옛 세션이 남는 것보다 나쁘다.
Future<void> clearSessionOnFirstRun({
  required FirstRunMarker marker,
  required SecureKeyValueStore store,
  required Iterable<String> keys,
}) async {
  try {
    if (!await marker.isFirstRun()) return;
    for (final key in keys) {
      await store.delete(key);
    }
    await marker.markRan();
  } catch (error) {
    // 값(토큰)은 로그에 남기지 않고 오류의 종류만 남긴다.
    if (kDebugMode) debugPrint('[auth] 첫 실행 세션 정리 실패: ${error.runtimeType}');
  }
}
