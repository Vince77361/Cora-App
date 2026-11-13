import 'dart:async';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/payment/domain/payment_quote.dart';
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora/features/payment/presentation/checkout_launcher.dart';

/// 캔버스 A8의 견본 견적: 릴스 1편, 식사권 40,000원 · 2인, 조회수 수당 상한 6만 원, 수수료 6천 원(10%).
/// 보관액은 최대 현금 부담(고정 현금 + 상한)이고 합계는 거기에 수수료를 더한 값이다.
PaymentQuote sampleQuote({
  String creatorName = '하루 한 컵',
  Voucher? voucher = const Voucher(name: '식사권', value: 40000, people: 2),
  int fixedCash = 0,
  int? viewPayCap = 60000,
}) {
  final escrow = fixedCash + (viewPayCap ?? 0);
  final fee = feeAmount(escrow, 10);
  return PaymentQuote(
    creatorName: creatorName,
    creatorPhotoUrl: null,
    format: ContentFormat.reels,
    pieces: 1,
    voucher: voucher,
    fixedCash: fixedCash,
    viewPayCap: viewPayCap,
    escrow: escrow,
    fee: fee,
    total: escrow + fee,
  );
}

/// 손으로 쓴 가짜 결제 저장소. 결제 상태는 [statuses]를 차례로 돌려주고, 다 쓰면 마지막 값을 반복한다.
class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository({
    PaymentQuote? quote,
    this.statuses = const [PaymentStatus.pending],
  }) : quote = quote ?? sampleQuote();

  PaymentQuote quote;
  List<PaymentStatus> statuses;

  bool failQuote = false;
  bool conflictOnQuote = false;
  bool failCreate = false;
  bool conflictOnCreate = false;

  /// 설정하면 [fetchStatus]가 이 Completer가 끝날 때까지 기다린다(확인 중 화면을 보려고).
  Completer<void>? holdStatus;

  int quoteCalls = 0;
  int statusCalls = 0;
  final created = <({String collaborationId, PaymentMethod method})>[];

  @override
  Future<PaymentQuote> fetchQuote(String collaborationId) async {
    quoteCalls++;
    if (conflictOnQuote) throw const PaymentFailure(conflict: true);
    if (failQuote) throw const PaymentFailure();
    return quote;
  }

  @override
  Future<({String paymentId, String checkoutUrl})> create(
    String collaborationId,
    PaymentMethod method,
  ) async {
    if (conflictOnCreate) throw const PaymentFailure(conflict: true);
    if (failCreate) throw const PaymentFailure();
    created.add((collaborationId: collaborationId, method: method));
    return (
      paymentId: 'pay-1',
      checkoutUrl: 'cora-dev://fake-pay?paymentId=pay-1',
    );
  }

  @override
  Future<PaymentStatus> fetchStatus(String paymentId) async {
    await holdStatus?.future;
    final index = statusCalls < statuses.length
        ? statusCalls
        : statuses.length - 1;
    statusCalls++;
    return statuses[index];
  }
}

/// 손으로 쓴 가짜 결제창 열기. 열린 주소를 기록하고, [onOpen]으로 창 안에서 일어난 일을 흉내 낸다.
/// 기본은 아무 결과 없이 바로 닫힌다.
class FakeCheckoutLauncher implements CheckoutLauncher {
  final opened = <({String url, int? amount})>[];
  void Function()? onOpen;
  Object? failWith;

  @override
  Future<void> open(String checkoutUrl, {int? amount}) async {
    opened.add((url: checkoutUrl, amount: amount));
    final error = failWith;
    if (error != null) throw error;
    onOpen?.call();
  }
}
