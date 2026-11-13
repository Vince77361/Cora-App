import '../domain/offer_terms.dart';

// 오퍼 조건을 화면에 보이는 문구로 바꾸는 순수 함수들. 모집 조건·오퍼 보내기, 보상·예산 설정(F1),
// 보내기 전 검토(F2), 오퍼 목록이 같은 문구를 쓰도록 한곳에 둔다.

/// 식사권 이름의 최대 글자 수(서버 검증과 같다).
const voucherNameMaxLength = 20;

/// 금액을 캔버스 문구로. 만 원 단위로 딱 떨어지면 `4만 원`, 아니면 `11,000원`.
String won(int amount) {
  if (amount >= 10000 && amount % 10000 == 0) return '${amount ~/ 10000}만 원';
  return '${_withCommas(amount)}원';
}

/// 금액을 쉼표로만 끊어서(`100,000원`). 결제 화면은 만 원 단위로 줄이지 않고 정확한 금액을 보인다.
String wonExact(int amount) => '${_withCommas(amount)}원';

String _withCommas(int amount) {
  final digits = amount.abs().toString();
  final out = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

String formatLabel(ContentFormat format) => switch (format) {
  ContentFormat.shorts => '쇼츠',
  ContentFormat.reels => '릴스',
  ContentFormat.cardNews => '카드뉴스',
  ContentFormat.blog => '블로그 글',
};

String formatSubtitle(ContentFormat format) => switch (format) {
  ContentFormat.shorts => '유튜브 60초',
  ContentFormat.reels => '인스타그램 30초',
  ContentFormat.cardNews => '인스타그램 3–5장',
  ContentFormat.blog => '사진 포함 후기',
};

/// 콘텐츠 줄. 오퍼 하나에 콘텐츠는 한 편이다.
String contentLine(ContentFormat format) => '${formatLabel(format)} 1편';

/// F2 `결과물` 줄. `릴스 1편 · 30초 안팎`.
String deliverableLine(ContentFormat format, int pieces) {
  final detail = switch (format) {
    ContentFormat.shorts => '60초 안팎',
    ContentFormat.reels => '30초 안팎',
    ContentFormat.cardNews => '3–5장',
    ContentFormat.blog => '사진 포함 후기',
  };
  return '${formatLabel(format)} $pieces편 · $detail';
}

/// 제공 혜택 한 줄. `식사권 40,000원 · 2인`(인원을 모르면 `식사권 40,000원`).
String benefitLine(Voucher voucher) {
  final people = voucher.people;
  final base = '${voucher.name} ${wonExact(voucher.value)}';
  return people == null ? base : '$base · $people인';
}

/// 받은 오퍼 제목에 쓰는 짧은 혜택. `식사권 2인`(인원을 모르면 이름만).
String benefitShort(Voucher voucher) {
  final people = voucher.people;
  return people == null ? voucher.name : '${voucher.name} $people인';
}

/// 고정 현금 값. `없음` / `30,000원`.
String fixedCashLabel(int amount) => amount == 0 ? '없음' : wonExact(amount);

/// 고정 현금 알약. `없음` / `3만 원`.
String fixedCashChip(int amount) => amount == 0 ? '없음' : won(amount);

/// 조회수 수당 단가. `1,000회당 2,000원`.
String rateLabel(int ratePerThousand) => '1,000회당 ${wonExact(ratePerThousand)}';

/// 조회수 수당 상한. `최대 60,000원`.
String capLabel(int cap) => '최대 ${wonExact(cap)}';

/// 조회수 수당 한 줄. `1,000회당 2,000원 · 1인 최대 60,000원`.
String viewPayLine(ViewPay viewPay) =>
    '${rateLabel(viewPay.ratePerThousand)} · 1인 ${capLabel(viewPay.cap)}';

/// 쉼표로 이은 조회수 수당. `1,000회당 2,000원, 최대 60,000원`.
String viewPayLineComma(ViewPay viewPay) =>
    '${rateLabel(viewPay.ratePerThousand)}, ${capLabel(viewPay.cap)}';

String usageRightsLabel(UsageRights rights) => switch (rights) {
  UsageRights.storeRepost3m => '가게 계정 재게시 3개월',
  UsageRights.storeRepost6m => '가게 계정 재게시 6개월',
  UsageRights.none => '사용 안 함',
};

/// 목록 카드의 한 줄 요약. 있는 요소를 ` + `로 잇는다.
/// `식사권 40,000원 · 2인 + 고정 현금 30,000원 + 조회수 수당`. 요소가 하나도 없으면 `없음`.
String rewardHeadline(Reward reward) {
  final parts = [
    if (reward.voucher != null) benefitLine(reward.voucher!),
    if (reward.fixedCash > 0) '고정 현금 ${wonExact(reward.fixedCash)}',
    if (reward.viewPay != null) '조회수 수당',
  ];
  return parts.isEmpty ? '없음' : parts.join(' + ');
}

/// 오퍼 보내기 확인 단계의 보상 칸. 요소마다 한 줄이고 둘째 줄부터 `+`로 잇는다.
/// `식사권 40,000원 · 2인\n+ 1,000회당 2,000원, 최대 60,000원`. 요소가 하나도 없으면 `없음`.
String rewardConfirmText(Reward reward) {
  final parts = [
    if (reward.voucher != null) benefitLine(reward.voucher!),
    if (reward.fixedCash > 0) '고정 현금 ${wonExact(reward.fixedCash)}',
    if (reward.viewPay != null) viewPayLineComma(reward.viewPay!),
  ];
  if (parts.isEmpty) return '없음';
  return [parts.first, for (final part in parts.skip(1)) '+ $part'].join('\n');
}

/// 확정된 조건의 보상 요약(오퍼 상세, 취소 확인). 있는 요소마다 한 줄이다.
String rewardSummary(OfferTerms terms) {
  final reward = terms.reward;
  final lines = [
    if (reward.voucher != null) benefitLine(reward.voucher!),
    if (reward.fixedCash > 0) '고정 현금 ${wonExact(reward.fixedCash)}',
    if (reward.viewPay != null) '조회수 수당 ${viewPayLineComma(reward.viewPay!)}',
  ];
  return lines.isEmpty ? '없음' : lines.join('\n');
}

/// 이용료 금액만. `6,000원`. 최대 현금 부담이 0원이면 이용료가 없어 빈 글자다.
String feeAmountLabel(int maxCashBurden, int feeRate) =>
    maxCashBurden == 0 ? '' : wonExact(feeAmount(maxCashBurden, feeRate));

/// 이용료 안내 한 문장. `이용료 6,000원은 별도예요.` 최대 현금 부담이 0원이면 빈 글자다.
String feeNote(int maxCashBurden, int feeRate) => maxCashBurden == 0
    ? ''
    : '이용료 ${feeAmountLabel(maxCashBurden, feeRate)}은 별도예요.';

/// `판본 1로`, `판본 3으로`. 번호를 한글로 읽은 마지막 소리가 받침 없음이나 ㄹ이면 `로`, 그 밖이면 `으로`다.
/// 공용 조사 도우미에 `로/으로` 짝이 없어(ㄹ 받침이 예외다) 여기서 정한다. 판본은 열 개까지다.
String versionWithRo(int number) {
  const roDigits = {1, 2, 4, 5, 7, 8, 9};
  final particle = roDigits.contains(number % 10) ? '로' : '으로';
  return '판본 $number$particle';
}
