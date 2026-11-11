import 'package:flutter/services.dart';

/// 앱의 Noto Sans KR을 테스트에 올린다. 기본 테스트 글꼴(Ahem)은 모든 글자가 한 칸(1em)이라
/// 줄바꿈이 실제와 달라지므로, 글자 너비가 중요한 배치 테스트에서만 부른다.
Future<void> loadAppFonts() async {
  final loader = FontLoader('NotoSansKR');
  for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$weight.otf'));
  }
  await loader.load();
}
