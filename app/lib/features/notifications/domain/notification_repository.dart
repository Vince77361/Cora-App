import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_notification.dart';

/// 알림함 한 쪽. [nextCursor]가 null이면 마지막 쪽이다.
typedef NotificationPage = ({List<AppNotification> items, String? nextCursor});

/// 알림을 읽고 읽음으로 바꾸는 포트.
abstract class NotificationRepository {
  /// [tab]의 알림을 최근 것부터 한 쪽(서버가 정한 줄 수) 읽는다. 다음 쪽은 [cursor]에 이전 쪽의
  /// `nextCursor`를 그대로 넣는다.
  Future<NotificationPage> fetch(NotificationTabFilter tab, {String? cursor});

  /// 읽지 않은 알림 수(탭과 상관없이 지금 역할의 것 전부).
  Future<int> unreadCount();

  /// 알림 하나를 읽음으로 바꾼다.
  Future<void> read(String id);

  /// 지금 역할의 알림을 모두 읽음으로 바꾼다.
  Future<void> readAll();
}

/// 서버에 닿지 못했거나 서버가 거절했다. 화면은 일반 문구를 쓴다.
class NotificationFailure implements Exception {
  const NotificationFailure();

  @override
  String toString() => 'NotificationFailure()';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => throw UnimplementedError(
    'notificationRepositoryProvider must be overridden',
  ),
);
