import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/domain/offer_terms.dart';
import '../domain/payment_quote.dart';
import '../domain/payment_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 결제 견적을 읽고 결제를 시작하고 상태를 묻는다.
/// 생성된 타입은 이 파일 밖으로 내보내지 않는다.
class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(api.ApiClient client)
    : _payments = api.PaymentsApi(client);

  final api.PaymentsApi _payments;

  @override
  Future<PaymentQuote> fetchQuote(String collaborationId) => _guard(() async {
    final m = await _payments.getPaymentQuote(collaborationId);
    if (m == null) throw const PaymentFailure();
    final voucherName = m.voucherName;
    final voucherValue = m.voucherValue;
    return PaymentQuote(
      creatorName: m.creatorName,
      creatorPhotoUrl: m.creatorPhotoUrl,
      format: switch (m.format) {
        api.ContentFormat.SHORTS => ContentFormat.shorts,
        api.ContentFormat.REELS => ContentFormat.reels,
        api.ContentFormat.CARD_NEWS => ContentFormat.cardNews,
        _ => ContentFormat.blog,
      },
      pieces: m.pieces,
      voucher: voucherName == null || voucherValue == null
          ? null
          : Voucher(
              name: voucherName,
              value: voucherValue,
              people: m.voucherPeople,
            ),
      fixedCash: m.fixedCash,
      viewPayCap: m.perViewCap,
      escrow: m.escrow,
      fee: m.fee,
      total: m.total,
    );
  });

  @override
  Future<({String paymentId, String checkoutUrl})> create(
    String collaborationId,
    PaymentMethod method,
  ) => _guard(() async {
    final m = await _payments.createPayment(
      collaborationId,
      api.CreatePaymentDto(
        method: switch (method) {
          PaymentMethod.card => api.PaymentMethod.CARD,
          PaymentMethod.transfer => api.PaymentMethod.TRANSFER,
          PaymentMethod.easyPay => api.PaymentMethod.EASY_PAY,
        },
      ),
    );
    if (m == null) throw const PaymentFailure();
    return (paymentId: m.paymentId, checkoutUrl: m.checkoutUrl);
  });

  @override
  Future<PaymentStatus> fetchStatus(String paymentId) => _guard(() async {
    final m = await _payments.getPayment(paymentId);
    if (m == null) throw const PaymentFailure();
    return switch (m.status) {
      api.PaymentStatus.APPROVED => PaymentStatus.approved,
      api.PaymentStatus.FAILED => PaymentStatus.failed,
      api.PaymentStatus.CANCELLED => PaymentStatus.cancelled,
      _ => PaymentStatus.pending,
    };
  });

  /// 어떤 실패든 [PaymentFailure] 하나로 모은다. 서버 오류 본문과 예외 메시지는 버린다.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PaymentFailure {
      rethrow;
    } catch (error) {
      throw PaymentFailure(conflict: ApiError.from(error).isConflict);
    }
  }
}
