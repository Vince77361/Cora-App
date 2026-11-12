import '../../../core/time/kst.dart';

// 알림함(E3)의 화면 문구와 시각 표시.

abstract final class NotificationTexts {
  static const title = '알림';
  static const settings = '알림 설정';
  static const tabList = '알림 분류';
  static const readAll = '모두 읽음으로 표시';
  static const unread = '읽지 않음';

  /// 캔버스에 없는 상태의 문구.
  static const empty = '아직 알림이 없어요.';
  static const loadFailed = '알림을 불러오지 못했어요.';
  static const moreFailed = '알림을 더 불러오지 못했어요.';
  static const readFailed = '읽음으로 바꾸지 못했어요.';

  /// 종 아이콘의 읽을 이름. 새 알림이 있으면 개수를 함께 읽는다.
  static String bell(int unread) => unread > 0 ? '알림, 새 알림 $unread개' : '알림';
}

/// 알림이 온 때를 한국 시간으로 말한다. [now]와 [at] 모두 한국 시간의 날짜로 센다.
///
/// 1분 안은 `방금`, 같은 날 1시간 안은 `{n}분 전`, 같은 날은 `{n}시간 전`, 전날은 `어제`, 그 전은
/// `{M}월 {D}일`, 해가 다르면 `{YYYY}년 {M}월 {D}일`이다(설계 E3). 분·시간은 날이 바뀌면 세지 않아서
/// 밤 11시 50분의 알림이 자정 지나 보면 `어제`다.
String relativeTimeLabel(DateTime now, DateTime at) {
  final elapsed = now.difference(at);
  // 시계가 어긋나 미래로 찍힌 알림도 방금으로 둔다.
  if (elapsed < const Duration(minutes: 1)) return '방금';

  final nowKst = toKst(now);
  final atKst = toKst(at);
  final days = DateTime.utc(
    nowKst.year,
    nowKst.month,
    nowKst.day,
  ).difference(DateTime.utc(atKst.year, atKst.month, atKst.day)).inDays;
  if (days <= 0) {
    return elapsed < const Duration(hours: 1)
        ? '${elapsed.inMinutes}분 전'
        : '${elapsed.inHours}시간 전';
  }
  if (days == 1) return '어제';
  if (atKst.year == nowKst.year) return '${atKst.month}월 ${atKst.day}일';
  return '${atKst.year}년 ${atKst.month}월 ${atKst.day}일';
}
