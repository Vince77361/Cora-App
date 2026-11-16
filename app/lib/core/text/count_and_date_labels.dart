/// 정수를 세 자리마다 쉼표로 끊는다(`1,234,567`). 음수는 앞에 `-`를 붙인다.
String withCommas(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// 시작 가능일 글. `11월 16일 이후`.
String afterDateLabel(DateTime date) => '${date.month}월 ${date.day}일 이후';
