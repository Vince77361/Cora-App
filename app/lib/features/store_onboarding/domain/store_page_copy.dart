import 'my_store.dart';

/// 가게 페이지(A3)의 꼬리표·손님 문구·모집 한 줄 규칙. 서버의 `STORE_PAGE_POLICY`와 같은 값이다
/// (이 값들은 `GET /config`에 없어 앱에도 적는다. 서버가 어기면 거절하므로 앱은 미리 알리는 용도다).
abstract final class StorePageCopy {
  static const tagsMax = 5;
  static const tagLength = 10;
  static const phrasesMax = 3;
  static const phraseLength = 20;
  static const recruitLineMax = 40;

  static const publicPageNote = '공개 페이지에는 크리에이터 지원하기 버튼이 보여요.';

  /// 소개 상자의 내용(NStorePage): `#꼬리표 … · 손님들이 자주 한 말: “…”, “…”. 공개 페이지에는 …`.
  /// 꼬리표와 자주 한 말이 둘 다 없으면 마지막 문장만 남는다.
  static String introLine(MyStore store) {
    final parts = <String>[
      if (store.tags.isNotEmpty) formatTags(store.tags),
      if (store.customerPhrases.isNotEmpty)
        '손님들이 자주 한 말: ${store.customerPhrases.map((p) => '“$p”').join(', ')}',
    ];
    return parts.isEmpty
        ? publicPageNote
        : '${parts.join(' · ')}. $publicPageNote';
  }

  /// `진한국물`, `바좌석` → `#진한국물 #바좌석`.
  static String formatTags(List<String> tags) =>
      tags.map((t) => '#$t').join(' ');

  /// 띄어쓰기나 쉼표로 나눈 글을 꼬리표로. `#`은 떼고 빈 것과 겹치는 것은 합친다.
  static List<String> parseTags(String input) {
    final seen = <String>{};
    return [
      for (final raw in input.split(RegExp(r'[\s,]+')))
        if (raw.replaceFirst(RegExp(r'^#+'), '').isNotEmpty &&
            seen.add(raw.replaceFirst(RegExp(r'^#+'), '')))
          raw.replaceFirst(RegExp(r'^#+'), ''),
    ];
  }

  /// 한 줄에 하나씩 쓴 글을 손님 문구로. 빈 줄은 버린다.
  static List<String> parsePhrases(String input) => [
    for (final line in input.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];

  static String formatPhrases(List<String> phrases) => phrases.join('\n');

  static bool tagsValid(List<String> tags) =>
      tags.length <= tagsMax && tags.every((t) => t.length <= tagLength);

  static bool phrasesValid(List<String> phrases) =>
      phrases.length <= phrasesMax &&
      phrases.every((p) => p.length <= phraseLength);
}
