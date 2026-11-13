import '../../offer_terms/domain/offer_terms.dart';

/// 제안의 두 당사자. 서버의 `OfferParty`와 같다.
enum ProposalParty { store, creator }

/// 판본에 사본으로 남은 시리즈. 이름·형식·설명만 있고 고른 시리즈의 id는 없다.
class OfferVersionSeries {
  const OfferVersionSeries({this.name, this.format, this.note});

  final String? name;
  final ContentFormat? format;
  final String? note;
}

/// 제안의 판본 하나. 판본은 만들기만 하고 고치지 않는다. 크리에이터가 쓴 판본에는 아이디어·표현 원칙·
/// 시리즈가 붙을 수 있다.
class OfferVersion {
  const OfferVersion({
    required this.number,
    required this.authorParty,
    required this.terms,
    this.idea,
    this.principles = const [],
    this.series,
  });

  final int number;
  final ProposalParty authorParty;
  final OfferTerms terms;
  final String? idea;
  final List<String> principles;
  final OfferVersionSeries? series;
}
