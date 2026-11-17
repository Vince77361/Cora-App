import 'package:flutter/painting.dart';

/// 메시지 요청(11, Chat·DarkChat)의 값 중 라이트·다크가 같은 것. 모드마다 다른 색은 `CoraColors`에 있다.
abstract final class CoraChatTokens {
  /// 사진이 없거나 불러오는 동안 사진 자리의 바탕 `#2E5B43`.
  static const heroPlaceholder = Color(0xFF2E5B43);

  /// 사진 아래 200에 깔리는 덮개: 위 투명 → 아래 `rgba(15,16,18,0.7)`.
  static const heroScrim = [Color(0x000F1012), Color(0xB30F1012)];

  /// 사진 위 `메시지 요청`·캠페인 한 줄의 글자색 `rgba(255,255,255,0.85)`.
  static const heroLabel = Color(0xD9FFFFFF);

  /// D3 대화방의 콘텐츠 카드 사진이 뜨기 전·없을 때의 바탕 `#E8DDCB`. 라이트·다크가 같다.
  static const cardPhotoPlaceholder = Color(0xFFE8DDCB);

  /// D3 대화 관리 시트 뒤를 덮는 `rgba(15,16,18,0.4)`. 라이트·다크가 같다.
  static const menuScrim = Color(0x660F1012);

  /// D3 대화방의 알림(SnackBar)이 화면 아래에서 떨어지는 거리. 입력 줄(보내기 버튼) 위에 뜨게 한다. 캔버스 밖 값이다.
  static const toastBottomMargin = 96.0;
}
