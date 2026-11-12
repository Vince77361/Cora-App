import 'dart:async';

import 'package:cora/features/notification_settings/domain/notification_settings.dart';
import 'package:cora/features/notification_settings/domain/notification_settings_repository.dart';

/// 서버가 처음 주는 값: 네 스위치 켜짐, 추천 소식 꺼짐, 방해 금지 밤.
const defaultSettings = NotificationSettings(
  mutualInterest: true,
  offers: true,
  messages: true,
  settlement: true,
  recommendations: false,
  quietHours: QuietHours.night,
);

/// 손으로 쓴 가짜 알림 설정 저장소. 저장하면 받은 값을 그대로 돌려준다(서버처럼).
class FakeNotificationSettingsRepository
    implements NotificationSettingsRepository {
  FakeNotificationSettingsRepository({NotificationSettings? settings})
    : settings = settings ?? defaultSettings;

  NotificationSettings settings;

  bool failFetch = false;
  bool failSave = false;

  /// 설정하면 저장이 이 Completer가 끝날 때까지 기다린다(저장이 느린 서버 흉내).
  Completer<void>? saveGate;

  final saved = <NotificationSettings>[];
  int fetchCalls = 0;

  @override
  Future<NotificationSettings> fetch() async {
    fetchCalls++;
    if (failFetch) throw const NotificationSettingsFailure();
    return settings;
  }

  @override
  Future<NotificationSettings> save(NotificationSettings next) async {
    final gate = saveGate;
    if (gate != null) await gate.future;
    if (failSave) throw const NotificationSettingsFailure();
    saved.add(next);
    return settings = next;
  }
}
