import '../../offer_terms/domain/offer_terms.dart';

/// 크리에이터가 자기 프로필에 만들어 둔 시리즈(예: `한 그릇 일기`). 제안에 고르면 이름·형식·설명이 그
/// 판본에 사본으로 남는다. 최대 [maxCount]개다.
class CreatorSeries {
  const CreatorSeries({
    required this.id,
    required this.name,
    required this.format,
    this.note,
  });

  /// 한 사람이 만들 수 있는 시리즈 수(서버 한도와 같다). 넘으면 `시리즈 추가`를 숨긴다.
  static const maxCount = 5;

  /// 이름과 설명의 최대 글자 수(서버 검증과 같다).
  static const nameMaxLength = 20;
  static const noteMaxLength = 20;

  final String id;
  final String name;
  final ContentFormat format;

  /// 한 줄 설명(예: `30초 릴스 · 손 중심`). 없을 수 있다.
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is CreatorSeries &&
      other.id == id &&
      other.name == name &&
      other.format == format &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, name, format, note);
}

/// 크리에이터가 가게에 내는 제안 한 건. 조건([terms])은 F1·F2가 고른 값이고, 나머지는 F6에서 쓴 것이다.
class CounterProposal {
  const CounterProposal({
    required this.terms,
    this.seriesId,
    this.idea = '',
    this.principles = const [],
  });

  /// 아이디어의 최대 글자 수, 표현 원칙(꼬리표)의 최대 개수와 꼬리표 하나의 최대 글자 수(서버 검증과 같다).
  static const ideaMaxLength = 200;
  static const principlesMax = 3;
  static const principleMaxLength = 10;

  final OfferTerms terms;

  /// 고른 시리즈. 시리즈 없이 형식만 고르면 null이다.
  final String? seriesId;
  final String idea;
  final List<String> principles;
}
