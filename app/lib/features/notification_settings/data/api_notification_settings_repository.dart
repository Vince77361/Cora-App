import 'package:cora_api/api.dart' as api;

import '../domain/notification_settings.dart';
import '../domain/notification_settings_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 알림 설정을 읽고 저장한다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiNotificationSettingsRepository
    implements NotificationSettingsRepository {
  ApiNotificationSettingsRepository(api.ApiClient client)
    : _api = api.NotificationSettingsApi(client);

  final api.NotificationSettingsApi _api;

  @override
  Future<NotificationSettings> fetch() => _guard(() async {
    final m = await _api.getNotificationSettings();
    if (m == null) throw const NotificationSettingsFailure();
    return _fromModel(m);
  });

  @override
  Future<NotificationSettings> save(NotificationSettings settings) =>
      _guard(() async {
        final m = await _api.putNotificationSettings(
          api.UpdateNotificationSettingsDto(
            messages: settings.messages,
            mutualInterest: settings.mutualInterest,
            offers: settings.offers,
            quietHours: _wireQuiet(settings.quietHours),
            recommendations: settings.recommendations,
            settlement: settings.settlement,
          ),
        );
        if (m == null) throw const NotificationSettingsFailure();
        return _fromModel(m);
      });

  static api.QuietHours _wireQuiet(QuietHours q) => switch (q) {
    QuietHours.off => api.QuietHours.OFF,
    QuietHours.night => api.QuietHours.NIGHT,
    QuietHours.weekend => api.QuietHours.WEEKEND,
  };

  static NotificationSettings _fromModel(api.NotificationSettingsModel m) =>
      NotificationSettings(
        mutualInterest: m.mutualInterest,
        offers: m.offers,
        messages: m.messages,
        settlement: m.settlement,
        recommendations: m.recommendations,
        quietHours: switch (m.quietHours) {
          api.QuietHours.OFF => QuietHours.off,
          api.QuietHours.NIGHT => QuietHours.night,
          api.QuietHours.WEEKEND => QuietHours.weekend,
        },
      );

  /// 어떤 실패든 [NotificationSettingsFailure] 하나로 모은다. 서버 문구는 화면에 쓰지 않는다.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on NotificationSettingsFailure {
      rethrow;
    } catch (_) {
      throw const NotificationSettingsFailure();
    }
  }
}
