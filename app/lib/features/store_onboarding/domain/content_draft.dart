/// AI가 쓴 초안의 종류. 화면 탭 순서(카드뉴스, 릴스 대본, 블로그 글)와 같다.
enum ContentDraftKind {
  cardNews('카드뉴스'),
  reelsScript('릴스 대본'),
  blog('블로그 글');

  const ContentDraftKind(this.tabLabel);

  final String tabLabel;
}

/// 초안 안의 장면(슬라이드) 하나.
class DraftScene {
  const DraftScene({
    required this.label,
    required this.text,
    required this.usesPhoto,
  });

  /// 슬라이드 위 작은 글자(`1`, `장면 1`, `제목`).
  final String label;

  /// 슬라이드 아래 큰 글자. 줄바꿈이 들어 있을 수 있다.
  final String text;

  /// 사장님의 대표 사진을 깔고 보여 주는 장면인지.
  final bool usesPhoto;
}

class ContentDraft {
  const ContentDraft({
    required this.kind,
    required this.bodyLabel,
    required this.body,
    required this.scenes,
    required this.regenerationsLeftToday,
  });

  final ContentDraftKind kind;

  /// 본문 위의 이름(`본문`, `촬영 순서`, `도입부`).
  final String bodyLabel;
  final String body;
  final List<DraftScene> scenes;

  /// 오늘 이 종류를 더 다시 만들 수 있는 횟수.
  final int regenerationsLeftToday;

  /// 오늘 남은 횟수만 바꾼 사본(서버가 한도를 넘었다고 답했을 때).
  ContentDraft withRegenerationsLeft(int count) => ContentDraft(
    kind: kind,
    bodyLabel: bodyLabel,
    body: body,
    scenes: scenes,
    regenerationsLeftToday: count,
  );
}
