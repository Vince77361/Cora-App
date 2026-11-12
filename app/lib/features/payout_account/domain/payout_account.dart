/// 은행 하나. 고르는 목록에는 [name](`국민`), 계좌 화면에는 [fullName](`국민은행`)을 쓴다.
class Bank {
  const Bank({required this.code, required this.name, required this.fullName});

  /// 금융결제원 은행 코드(세 자리).
  final String code;
  final String name;
  final String fullName;
}

/// 등록한 지급 계좌. 전체 번호는 서버가 응답에 싣지 않는다.
class PayoutAccount {
  const PayoutAccount({
    required this.bankCode,
    required this.bankFullName,
    required this.accountLast4,
    required this.holderName,
  });

  final String bankCode;
  final String bankFullName;
  final String accountLast4;
  final String holderName;

  /// 화면에 보이는 모양: `국민은행 ****12`. 서버는 뒤 4자리를 주지만 화면은 뒤 2자리만 보인다.
  String get maskedLabel {
    final tail = accountLast4.length <= 2
        ? accountLast4
        : accountLast4.substring(accountLast4.length - 2);
    return '$bankFullName ****$tail';
  }
}
