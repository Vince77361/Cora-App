import 'package:cora/features/notifications/domain/app_notification.dart';
import 'package:cora/features/notifications/domain/notification_repository.dart';

/// 손으로 쓴 가짜 알림 저장소. 서버처럼 탭으로 거르고, 쪽마다 [pageSize]줄씩 돌려준다.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({
    List<AppNotification> items = const [],
    this.pageSize = 30,
  }) : items = [...items];

  final List<AppNotification> items;
  final int pageSize;

  bool failFetch = false;
  bool failRead = false;
  bool failReadAll = false;

  /// 두 번째 쪽부터만 실패한다(더 불러오기 실패 흉내).
  bool failMore = false;

  final fetched = <({NotificationTabFilter tab, String? cursor})>[];
  final readIds = <String>[];
  int readAllCalls = 0;

  @override
  Future<NotificationPage> fetch(
    NotificationTabFilter tab, {
    String? cursor,
  }) async {
    fetched.add((tab: tab, cursor: cursor));
    if (failFetch || (failMore && cursor != null)) {
      throw const NotificationFailure();
    }
    final rows = [
      for (final n in items)
        if (tab == NotificationTabFilter.all || n.tab.name == tab.name) n,
    ];
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, rows.length);
    return (
      items: rows.sublist(start, end),
      nextCursor: end < rows.length ? '$end' : null,
    );
  }

  @override
  Future<int> unreadCount() async => items.where((n) => !n.read).length;

  @override
  Future<void> read(String id) async {
    if (failRead) throw const NotificationFailure();
    readIds.add(id);
    final i = items.indexWhere((n) => n.id == id);
    if (i >= 0) items[i] = items[i].copyWith(read: true);
  }

  @override
  Future<void> readAll() async {
    if (failReadAll) throw const NotificationFailure();
    readAllCalls++;
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(read: true);
    }
  }
}

/// 캔버스 NNotify의 다섯 줄. 시각은 [now]를 기준으로 방금, 12분 전, 1시간 전, 어제, 11월 9일이다.
List<AppNotification> canvasNotifications(DateTime now) => [
  AppNotification(
    id: 'n1',
    tab: NotificationTab.matching,
    text: '서윤의 작은 취향과 서로 관심이 닿았어요.',
    actorName: '서윤의 작은 취향',
    actorPhotoUrl: 'https://example.test/a.jpg',
    targetKind: 'MATCH',
    targetId: 'm1',
    createdAt: now.subtract(const Duration(seconds: 20)),
    read: false,
  ),
  AppNotification(
    id: 'n2',
    tab: NotificationTab.collaboration,
    text: '모아 스튜디오가 조건 버전 2를 확인했어요.',
    actorName: '모아 스튜디오',
    actorPhotoUrl: 'https://example.test/b.jpg',
    targetKind: 'COLLABORATION',
    targetId: 'c-77',
    createdAt: now.subtract(const Duration(minutes: 12)),
    read: false,
  ),
  AppNotification(
    id: 'n3',
    tab: NotificationTab.matching,
    text: '한그릇 라멘이 릴스 1편 오퍼를 보냈어요.',
    actorName: '한그릇 라멘',
    actorPhotoUrl: 'https://example.test/c.jpg',
    targetKind: 'OFFER_INBOX',
    createdAt: now.subtract(const Duration(hours: 1)),
    read: true,
  ),
  AppNotification(
    id: 'n4',
    tab: NotificationTab.settlement,
    text: '정산 43,200원이 다음 주 수요일에 들어와요.',
    glyph: NotificationGlyph.won,
    actorName: '한그릇 라멘',
    targetKind: 'WALLET',
    createdAt: now.subtract(const Duration(days: 1)),
    read: true,
  ),
  AppNotification(
    id: 'n5',
    tab: NotificationTab.collaboration,
    text: '초안 0:12 구간에 댓글이 달렸어요.',
    glyph: NotificationGlyph.pen,
    actorName: '모아 스튜디오',
    targetKind: 'COLLABORATION',
    targetId: 'c-77',
    createdAt: now.subtract(const Duration(days: 2)),
    read: true,
  ),
];
