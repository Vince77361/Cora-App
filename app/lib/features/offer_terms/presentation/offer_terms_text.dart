import '../domain/offer_terms.dart';

// 오퍼 조건을 화면에 보이는 문구로 바꾸는 순수 함수들. 기본 조건 화면, 오퍼 보내기(A5),
// 오퍼 목록이 같은 문구를 쓰도록 한곳에 둔다.

/// 식사권을 따로 정하지 않았을 때의 이름과 금액(서버 기본값과 같다).
const defaultVoucherName = '2인 식사권';
const defaultVoucherValue = 40000;

/// 조회수당 지급의 단가와 상한(원). 서버가 정하는 값이고, 아직 서버 값을 받기 전 화면
/// (고르는 중인 조건)이 같은 문구를 보이도록 같은 값을 둔다.
const perViewAmountWon = 10;
const perViewCapWon = 100000;

/// 식사권 금액으로 받을 수 있는 범위(서버 검증과 같다).
const voucherValueMin = 1000;
const voucherValueMax = 1000000;

/// 식사권 이름의 최대 글자 수(서버 검증과 같다).
const voucherNameMaxLength = 20;

/// 금액을 캔버스 문구로. 만 원 단위로 딱 떨어지면 `4만 원`, 아니면 `11,000원`.
String won(int amount) {
  if (amount >= 10000 && amount % 10000 == 0) return '${amount ~/ 10000}만 원';
  return '${_withCommas(amount)}원';
}

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

/// 확인 단계의 콘텐츠 줄. 오퍼 하나에 콘텐츠는 한 편이다.
String contentLine(ContentFormat format) => '${formatLabel(format)} 1편';

String rewardTitle(RewardType type) => switch (type) {
  RewardType.voucher => '식사권 제공',
  RewardType.perView => '조회수당 지급',
  RewardType.both => '식사권 + 조회수',
};

/// 조회수당 지급 한 줄. `조회 1회당 10원, 최대 10만 원`.
String _perViewLine(int amount, int cap) =>
    '조회 1회당 ${won(amount)}, 최대 ${won(cap)}';

/// 보상 카드 아래 설명. 식사권이 들어간 카드는 지금 고른 식사권 이름과 금액을 보인다.
String rewardSubtitle(OfferTermsInput input) => switch (input.rewardType) {
  RewardType.voucher =>
    '${input.voucherName ?? defaultVoucherName}, '
        '약 ${won(input.voucherValue ?? defaultVoucherValue)} 상당',
  RewardType.perView => _perViewLine(perViewAmountWon, perViewCapWon),
  RewardType.both => '식사 후 올리고, 조회수만큼 더 받아요',
};

String _summary(
  RewardType type,
  String? voucherName,
  int? voucherValue,
  int? perViewAmount,
  int? perViewCap,
) {
  final voucher =
      '${voucherName ?? defaultVoucherName} '
      '(약 ${won(voucherValue ?? defaultVoucherValue)})';
  final perView = _perViewLine(
    perViewAmount ?? perViewAmountWon,
    perViewCap ?? perViewCapWon,
  );
  return switch (type) {
    RewardType.voucher => voucher,
    RewardType.perView => perView,
    // 둘 다일 때는 식사권 이름만 윗줄에 두고 그 아래 줄에 조회수당을 잇는다.
    RewardType.both => '${voucherName ?? defaultVoucherName}\n+ $perView',
  };
}

/// 서버가 확정한 조건의 보상 요약(확인 단계, 오퍼 상세). 둘 다면 두 줄이다.
String rewardSummary(OfferTerms terms) => _summary(
  terms.rewardType,
  terms.voucherName,
  terms.voucherValue,
  terms.perViewAmount,
  terms.perViewCap,
);

/// 아직 보내기 전 고른 값의 보상 요약. [rewardSummary]와 같은 문구다.
String rewardSummaryOfInput(OfferTermsInput input) => _summary(
  input.rewardType,
  input.voucherName,
  input.voucherValue,
  null,
  null,
);

/// 목록 카드의 한 줄 요약. `2인 식사권 + 조회수당`.
String rewardHeadline(OfferTerms terms) {
  final name = terms.voucherName ?? defaultVoucherName;
  return switch (terms.rewardType) {
    RewardType.voucher => name,
    RewardType.perView => '조회수당',
    RewardType.both => '$name + 조회수당',
  };
}
