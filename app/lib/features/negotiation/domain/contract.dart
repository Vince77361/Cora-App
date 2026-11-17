import '../../payment/domain/payment_quote.dart';
import 'terms_version.dart';

/// 계약의 진행. 서버의 `ContractProgress`와 같다.
enum ContractStatus {
  /// 양쪽이 같은 판본을 확인하기 전이라 미리 보기만 된다.
  notReady,

  /// 합의됨, 크리에이터가 동의하기 전.
  awaitingCreator,

  /// 크리에이터가 동의했고 브랜드가 동의(결제)하기 전.
  awaitingBrand,

  /// 브랜드가 결제창을 연 지 60분 안.
  paying,

  /// 결제가 승인돼 체결됐다.
  concluded,
}

/// 계약(D4)이 그리는 것. 서버의 `ContractModel`과 같고, 앱은 다시 계산하지 않는다.
class Contract {
  const Contract({
    required this.status,
    required this.brandName,
    required this.creatorName,
    required this.terms,
    required this.myConsentTexts,
    required this.voidedNotice,
    this.quote,
    this.creatorConsentedAt,
    this.brandConsentedAt,
    this.concludedAt,
  });

  final ContractStatus status;
  final String brandName;
  final String creatorName;

  /// 계약이 담은 판본(계약 행이 있으면 동의할 때 만든 사본, 없으면 최신 판본). 없으면 null이다.
  final TermsVersion? terms;

  /// 내 쪽 확인란 세 줄. 동의할 때 이 문구를 그대로 보낸다. 계약할 수 없는 상태면 비어 있다.
  final List<String> myConsentTexts;

  /// 내 동의가 새 판본으로 취소됐고 새 계약이 아직 없다. 서버에는 읽음 표시가 없다.
  final bool voidedNotice;

  /// 브랜드에게만, 크리에이터가 동의한 뒤 결제 전에 보이는 결제 견적(서버가 계약 사본에서 계산한 값).
  final PaymentQuote? quote;

  final DateTime? creatorConsentedAt;
  final DateTime? brandConsentedAt;

  /// 결제가 승인돼 체결된 시각.
  final DateTime? concludedAt;

  int? get version => terms?.version;

  bool get concluded => status == ContractStatus.concluded;
}
