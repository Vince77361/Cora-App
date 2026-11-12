import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'payout_account.dart';

/// 지급받을 계좌를 읽고 등록하는 포트.
abstract class PayoutAccountRepository {
  /// 등록한 계좌. 없으면 null.
  Future<PayoutAccount?> fetch();

  Future<List<Bank>> banks();

  /// 계좌를 등록하거나 바꾼다. 계좌번호는 숫자만(10~14자리)이다.
  Future<PayoutAccount> save({
    required String bankCode,
    required String accountNumber,
    required String holderName,
  });
}

/// 서버에 닿지 못했거나 서버가 거절했다. [message]는 서버가 화면에 그대로 보이라고 보낸 문구(4xx일
/// 때만)이고, 서버 내부 오류나 연결 문제는 null이라 화면이 일반 문구를 쓴다.
class PayoutAccountFailure implements Exception {
  const PayoutAccountFailure({this.message});

  final String? message;

  @override
  String toString() => 'PayoutAccountFailure()';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final payoutAccountRepositoryProvider = Provider<PayoutAccountRepository>(
  (ref) => throw UnimplementedError(
    'payoutAccountRepositoryProvider must be overridden',
  ),
);
