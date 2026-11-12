/// 알림이 속한 탭. 서버의 `NotificationTab`과 일대일이다(생성된 타입은 data 계층 밖으로 내보내지 않는다).
enum NotificationTab { matching, collaboration, settlement }

/// 알림함 위의 탭. `all`이 아니면 그 탭의 알림만 서버가 보낸다.
enum NotificationTabFilter { all, matching, collaboration, settlement }

/// 줄 왼쪽 원에 사진 대신 그리는 글자. 정산은 `₩`, 기획·초안은 `✎`다.
enum NotificationGlyph { won, pen }

/// 알림함의 한 줄(E3). 문구는 서버가 종류와 값으로 만들어 보낸 그대로 쓴다.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.tab,
    required this.text,
    required this.targetKind,
    required this.createdAt,
    required this.read,
    this.glyph,
    this.actorName = '',
    this.actorPhotoUrl,
    this.targetId,
  });

  final String id;
  final NotificationTab tab;
  final String text;

  /// 글자 그림. 없으면 상대 사진(사진이 없으면 이름 첫 글자).
  final NotificationGlyph? glyph;

  /// 알림을 만들 때 저장한 상대의 이름 사본과 사진 주소.
  final String actorName;
  final String? actorPhotoUrl;

  /// 누르면 가는 곳. 서버가 앱 주소를 모르게 종류와 ID로만 내려 주고 앱이 화면으로 바꾼다.
  final String targetKind;
  final String? targetId;

  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    tab: tab,
    text: text,
    glyph: glyph,
    actorName: actorName,
    actorPhotoUrl: actorPhotoUrl,
    targetKind: targetKind,
    targetId: targetId,
    createdAt: createdAt,
    read: read ?? this.read,
  );
}
