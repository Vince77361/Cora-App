/// 이상형 월드컵의 문구. 캔버스 M19G3Banner·Count·Match·Result 글자 그대로이고, 아래 "캔버스 밖"으로 표시한 것만
/// 캔버스에 없어 설계 4.4의 문구를 쓴다.
abstract final class WorldCupText {
  static const title = '이상형 월드컵';

  // 저장함 배너
  static String bannerDescription(int saved) => '저장한 $saved명 중 한 명을 골라요';
  static const bannerStart = '월드컵 하기';

  // 몇 강으로
  static const countTitle = '몇 강으로 할까요?';
  static String countDescription(int saved) =>
      '저장한 $saved명 중에서 골라요. 우승한 분께 바로 제안할 수 있어요.';
  static const semifinal = '4강';
  static const semifinalSub = '4명이 겨뤄요';
  static const quarterfinal = '8강';
  static const quarterfinalSub = '8명이 겨뤄요';
  static const begin = '시작하기';
  static const close = '닫기';

  // 대결
  static const quit = '그만하기';
  static const matchHint = '더 마음에 드는 분을 골라요.';
  static String savedNth(int n) => '저장 $n번째';
  static const pick = '이거보다 좋아';
  static const vs = 'VS';

  /// 카드 전체의 접근성 이름. 캔버스 `aria-label`이 `{이름} 고르기`다.
  static String pickLabel(String name) => '$name 고르기';

  // 결과
  static const champion = '이상형 1위';
  static const semifinalists = '4강까지 올랐던 후보';
  static const again = '다시 하기';
  static const propose = '제안하기';
}
