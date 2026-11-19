/// 월드컵의 한 단계. 8강은 네 번, 4강은 두 번, 결승은 한 번 겨룬다.
enum WorldCupRound {
  quarterfinal('8강', 4),
  semifinal('4강', 2),
  finalRound('결승', 1);

  const WorldCupRound(this.title, this.matches);

  /// 단계 이름(`8강`, `4강`, `결승`).
  final String title;

  /// 이 단계에서 겨루는 횟수.
  final int matches;

  /// 단계 글자: `8강 · 1 / 4`, `4강 · 1 / 2`, `결승 · 1 / 1`(결승은 캔버스 밖). [matchNumber]는 1부터다.
  String label(int matchNumber) => '$title · $matchNumber / $matches';
}
