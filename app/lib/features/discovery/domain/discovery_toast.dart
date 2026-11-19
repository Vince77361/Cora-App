import 'discovery_target.dart';

/// 카드 위 알림의 종류. 브랜드 01과 사장님 둘러보기가 같이 쓴다.
enum DiscoveryToastKind { pass, like, hold, match, notice }

/// 카드 위에 3초 뜨는 알림 문구 하나. [serial]이 바뀌면 새 알림이다(3초를 다시 센다).
class DiscoveryToast {
  const DiscoveryToast({
    required this.kind,
    required this.serial,
    this.name,
    this.collaborationId,
    this.target,
    this.message,
  });

  final DiscoveryToastKind kind;
  final int serial;

  /// 서로 관심이 닿은 상대의 이름(`match`).
  final String? name;

  /// 서로 관심이 닿아 생긴 협업(`match`).
  final String? collaborationId;

  /// 넘긴 대상(`pass`). `이유 남기기`가 이 대상에 이유를 남긴다.
  final DiscoveryTarget? target;

  /// 안내 문구(`notice`).
  final String? message;
}
