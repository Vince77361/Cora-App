/// 알림 설정(E5)의 스위치 다섯. 위에서 아래 순서 그대로다.
enum NotificationSwitch {
  mutualInterest,
  offers,
  messages,
  settlement,
  recommendations,
}

/// 방해 금지 시간. 밤은 22:00~08:00, 주말은 토 00:00~월 00:00(한국 시간)이고 계산은 서버가 한다.
enum QuietHours { off, night, weekend }

/// 내 알림 설정. 계정 하나에 하나다(역할마다 따로 두지 않는다). 처음 값(네 스위치 켜짐, 추천 소식 꺼짐,
/// 방해 금지 밤)은 서버가 정해 보낸다.
class NotificationSettings {
  const NotificationSettings({
    required this.mutualInterest,
    required this.offers,
    required this.messages,
    required this.settlement,
    required this.recommendations,
    required this.quietHours,
  });

  final bool mutualInterest;
  final bool offers;
  final bool messages;
  final bool settlement;
  final bool recommendations;
  final QuietHours quietHours;

  bool isOn(NotificationSwitch s) => switch (s) {
    NotificationSwitch.mutualInterest => mutualInterest,
    NotificationSwitch.offers => offers,
    NotificationSwitch.messages => messages,
    NotificationSwitch.settlement => settlement,
    NotificationSwitch.recommendations => recommendations,
  };

  NotificationSettings withSwitch(NotificationSwitch s, bool on) =>
      NotificationSettings(
        mutualInterest: s == NotificationSwitch.mutualInterest
            ? on
            : mutualInterest,
        offers: s == NotificationSwitch.offers ? on : offers,
        messages: s == NotificationSwitch.messages ? on : messages,
        settlement: s == NotificationSwitch.settlement ? on : settlement,
        recommendations: s == NotificationSwitch.recommendations
            ? on
            : recommendations,
        quietHours: quietHours,
      );

  NotificationSettings withQuietHours(QuietHours value) => NotificationSettings(
    mutualInterest: mutualInterest,
    offers: offers,
    messages: messages,
    settlement: settlement,
    recommendations: recommendations,
    quietHours: value,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      other.mutualInterest == mutualInterest &&
      other.offers == offers &&
      other.messages == messages &&
      other.settlement == settlement &&
      other.recommendations == recommendations &&
      other.quietHours == quietHours;

  @override
  int get hashCode => Object.hash(
    mutualInterest,
    offers,
    messages,
    settlement,
    recommendations,
    quietHours,
  );
}
