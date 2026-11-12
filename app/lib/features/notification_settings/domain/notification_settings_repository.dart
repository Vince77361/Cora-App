import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_settings.dart';

/// 알림 설정을 읽고 저장하는 포트.
abstract class NotificationSettingsRepository {
  Future<NotificationSettings> fetch();

  /// 설정 전체를 저장하고 서버가 저장한 값을 돌려준다(서버 API가 `PUT` 전체 교체다).
  Future<NotificationSettings> save(NotificationSettings settings);
}

/// 서버에 닿지 못했거나 서버가 거절했다. 화면은 일반 문구를 쓴다.
class NotificationSettingsFailure implements Exception {
  const NotificationSettingsFailure();

  @override
  String toString() => 'NotificationSettingsFailure()';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>(
      (ref) => throw UnimplementedError(
        'notificationSettingsRepositoryProvider must be overridden',
      ),
    );
