import '../../offer_terms/domain/offer_terms.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';

// F6 크리에이터 역제안의 문구를 만드는 순수 함수들. 금액 식은 `offer_terms` 도메인의 것을 그대로 쓴다.

/// 가게 조건 요약 끝에 붙는 한 마디. 내 희망 보상의 최대 현금 부담([myBurden])이 가게 조건의 것([storeBurden])을
/// 넘지 않으면 `추가 부담 없음`, 넘으면 차액을 `가게 부담 +30,000원`으로 보인다.
String extraBurdenLabel(int storeBurden, int myBurden) =>
    myBurden <= storeBurden
    ? '추가 부담 없음'
    : '가게 부담 +${wonExact(myBurden - storeBurden)}';

/// `희망 보상` 칸의 값. 있는 요소를 짧게 ` + `로 잇는다. `식사권 + 3만 원`, `식사권 + 조회수 수당`.
/// 요소가 하나도 없으면 `없음`.
String hopeRewardSummary(Reward reward) {
  final parts = [
    if (reward.voucher != null) '식사권',
    if (reward.fixedCash > 0) won(reward.fixedCash),
    if (reward.viewPay != null) '조회수 수당',
  ];
  return parts.isEmpty ? '없음' : parts.join(' + ');
}

/// 머리 아래 가게 카드의 둘째 줄. `성수동 · 방문 1회 · 오후 3시 – 5시 촬영 가능`. 없는 값은 뺀다.
String storeCardSubtitle({String? neighborhood, String? bestShootingTime}) {
  final place = (neighborhood ?? '').trim();
  final time = (bestShootingTime ?? '').trim();
  return [
    if (place.isNotEmpty) place,
    '방문 1회',
    if (time.isNotEmpty) '$time 촬영 가능',
  ].join(' · ');
}

/// `가게 조건: 식사권 40,000원 · 2인 + 1,000회당 2,000원, 1인 최대 60,000원 · 추가 부담 없음`.
/// 가게 조건의 요소를 ` + `로 잇고 끝에 [extraBurdenLabel]을 붙인다.
String storeConditionLine(OfferTerms store, int myBurden) {
  final reward = store.reward;
  final parts = [
    if (reward.voucher != null) benefitLine(reward.voucher!),
    if (reward.fixedCash > 0) '고정 현금 ${wonExact(reward.fixedCash)}',
    if (reward.viewPay != null)
      '${rateLabel(reward.viewPay!.ratePerThousand)}, 1인 ${capLabel(reward.viewPay!.cap)}',
  ];
  final body = parts.isEmpty ? '없음' : parts.join(' + ');
  return '가게 조건: $body · ${extraBurdenLabel(reward.maxCashBurden, myBurden)}';
}

/// 시리즈 카드의 둘째 줄. 설명이 없으면 형식 이름을 보인다.
String seriesSubtitle(String? note, ContentFormat format) {
  final trimmed = (note ?? '').trim();
  return trimmed.isEmpty ? formatLabel(format) : trimmed;
}

/// 표현 원칙 꼬리표의 모양. `#얼굴출연없음`.
String principleTag(String principle) => '#$principle';

/// `표현 원칙` 칸의 값. `#얼굴출연없음 #손만나옴`. 없으면 `없음`.
String principlesLabel(List<String> principles) =>
    principles.isEmpty ? '없음' : principles.map(principleTag).join(' ');

/// 입력한 꼬리표를 저장하는 모양으로 다듬는다. 앞의 `#`과 공백을 없앤다. 비면 null.
String? normalizePrinciple(String input) {
  final cleaned = input.replaceAll('#', '').replaceAll(RegExp(r'\s+'), '');
  return cleaned.isEmpty ? null : cleaned;
}
