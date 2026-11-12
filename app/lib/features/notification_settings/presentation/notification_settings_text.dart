import '../domain/notification_settings.dart';

// 알림 설정(E5)의 화면 문구.

class NotificationSettingsTexts {
  static const title = '알림';
  static const heading = '꼭 필요한 알림만\n받을 수 있어요.';
  static const quietTitle = '방해 금지 시간';

  /// 캔버스에 없는 상태의 문구.
  static const loadFailed = '알림 설정을 불러오지 못했어요.';
  static const saveFailed = '설정을 저장하지 못했어요.';

  /// 스위치의 이름과 설명(설계 2장 표).
  static const switches = <NotificationSwitch, (String, String)>{
    NotificationSwitch.mutualInterest: ('서로 관심', '상대도 관심을 표시하면 알려줘요'),
    NotificationSwitch.offers: ('새 오퍼와 제안', '가게나 브랜드가 오퍼를 보냈을 때'),
    NotificationSwitch.messages: ('대화 메시지', '진행 중인 협업의 새 메시지'),
    NotificationSwitch.settlement: ('정산', '지급 예정, 지급 완료'),
    NotificationSwitch.recommendations: ('추천 소식', '새로 올라온 캠페인과 크리에이터'),
  };

  static const quietOptions = <QuietHours, String>{
    QuietHours.off: '끄기',
    QuietHours.night: '밤 10시 – 아침 8시',
    QuietHours.weekend: '주말',
  };
}
