import 'package:cora_api/api.dart' as api;

import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 알림함을 읽고 읽음으로 바꾼다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(api.ApiClient client)
    : _api = api.NotificationsApi(client);

  final api.NotificationsApi _api;

  @override
  Future<NotificationPage> fetch(NotificationTabFilter tab, {String? cursor}) =>
      _guard(() async {
        final page = await _api.listNotifications(
          tab: _wireTab(tab),
          cursor: cursor,
        );
        if (page == null) throw const NotificationFailure();
        return (
          items: [for (final m in page.items) _fromModel(m)],
          nextCursor: page.nextCursor,
        );
      });

  @override
  Future<int> unreadCount() => _guard(() async {
    final m = await _api.countUnreadNotifications();
    if (m == null) throw const NotificationFailure();
    return m.count.toInt();
  });

  @override
  Future<void> read(String id) => _guard(() => _api.readNotification(id));

  @override
  Future<void> readAll() => _guard(() => _api.readAllNotifications());

  static api.NotificationTabFilter _wireTab(NotificationTabFilter tab) =>
      switch (tab) {
        NotificationTabFilter.all => api.NotificationTabFilter.ALL,
        NotificationTabFilter.matching => api.NotificationTabFilter.MATCHING,
        NotificationTabFilter.collaboration =>
          api.NotificationTabFilter.COLLABORATION,
        NotificationTabFilter.settlement =>
          api.NotificationTabFilter.SETTLEMENT,
      };

  static AppNotification _fromModel(api.NotificationModel m) => AppNotification(
    id: m.id,
    tab: switch (m.tab) {
      api.NotificationTab.MATCHING => NotificationTab.matching,
      api.NotificationTab.COLLABORATION => NotificationTab.collaboration,
      api.NotificationTab.SETTLEMENT => NotificationTab.settlement,
    },
    text: m.text,
    glyph: switch (m.glyph) {
      api.NotificationGlyph.WON => NotificationGlyph.won,
      api.NotificationGlyph.PEN => NotificationGlyph.pen,
      null => null,
    },
    actorName: m.actor?.name ?? '',
    actorPhotoUrl: m.actor?.photoUrl,
    targetKind: m.target.kind,
    targetId: m.target.id,
    createdAt: m.createdAt,
    read: m.read,
  );

  /// 어떤 실패든 [NotificationFailure] 하나로 모은다. 서버 문구는 화면에 쓰지 않는다.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on NotificationFailure {
      rethrow;
    } catch (_) {
      throw const NotificationFailure();
    }
  }
}
