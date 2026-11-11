import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'payment_quote.dart';

/// 결제 수단. 화면의 `카드`, `계좌이체`, `간편결제`다.
enum PaymentMethod { card, transfer, easyPay }

/// 결제 상태. 완료 여부는 결제창의 결과가 아니라 서버가 PG에서 받은 통지로 정해진다.
enum PaymentStatus { pending, approved, failed, cancelled }

/// 결제 화면이 서버와 주고받는 포트: 견적, 결제 시작, 결제 상태.
abstract class PaymentRepository {
  /// 서버가 협업의 확정 조건에서 계산한 결제 견적. 결제를 기다리는 협업이 아니면
  /// [PaymentFailure.conflict].
  Future<PaymentQuote> fetchQuote(String collaborationId);

  /// 결제를 시작하고 앱이 열 결제창 주소를 받는다. 결제를 기다리는 협업이 아니거나 기한이
  /// 지났으면 [PaymentFailure.conflict].
  Future<({String paymentId, String checkoutUrl})> create(
    String collaborationId,
    PaymentMethod method,
  );

  /// 결제창이 닫힌 뒤 서버에 지금 상태를 묻는다.
  Future<PaymentStatus> fetchStatus(String paymentId);
}

/// 서버에 닿지 못했거나 서버가 거절했다. 서버 응답의 문구는 담지 않는다.
class PaymentFailure implements Exception {
  const PaymentFailure({this.conflict = false});

  /// 서버가 409로 답했다(결제할 수 있는 협업이 아니거나 기한이 지났다).
  final bool conflict;

  @override
  String toString() => 'PaymentFailure(conflict: $conflict)';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) =>
      throw UnimplementedError('paymentRepositoryProvider must be overridden'),
);
