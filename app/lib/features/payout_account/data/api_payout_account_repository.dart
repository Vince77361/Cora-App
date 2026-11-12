import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../domain/payout_account.dart';
import '../domain/payout_account_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 지급 계좌를 읽고 등록한다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiPayoutAccountRepository implements PayoutAccountRepository {
  ApiPayoutAccountRepository(api.ApiClient client)
    : _accounts = api.PayoutAccountsApi(client);

  final api.PayoutAccountsApi _accounts;

  @override
  Future<PayoutAccount?> fetch() async {
    try {
      final m = await _accounts.getPayoutAccount();
      return m == null ? null : _fromModel(m);
    } catch (error) {
      // 등록한 계좌가 없으면 서버가 404로 답한다. 실패가 아니라 "없음"이다.
      if (ApiError.from(error).isNotFound) return null;
      throw _failure(error);
    }
  }

  @override
  Future<List<Bank>> banks() async {
    try {
      final rows = await _accounts.listBanks();
      if (rows == null) throw const PayoutAccountFailure();
      return [
        for (final m in rows)
          Bank(code: m.code, name: m.name, fullName: m.fullName),
      ];
    } on PayoutAccountFailure {
      rethrow;
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<PayoutAccount> save({
    required String bankCode,
    required String accountNumber,
    required String holderName,
  }) async {
    try {
      final code = api.UpsertPayoutAccountDtoBankCodeEnum.values
          .where((e) => e.toString() == bankCode)
          .firstOrNull;
      if (code == null) {
        throw const PayoutAccountFailure(message: '지원하지 않는 은행이에요.');
      }
      final m = await _accounts.upsertPayoutAccount(
        api.UpsertPayoutAccountDto(
          accountNumber: accountNumber,
          bankCode: code,
          holderName: holderName,
        ),
      );
      if (m == null) throw const PayoutAccountFailure();
      return _fromModel(m);
    } on PayoutAccountFailure {
      rethrow;
    } catch (error) {
      throw _failure(error);
    }
  }

  /// 서버 문구는 4xx일 때만 담는다. 5xx 본문(예: 암호화 키가 없다는 안내)은 화면에 보이지 않는다.
  static PayoutAccountFailure _failure(Object error) {
    final e = ApiError.from(error);
    final status = e.status;
    return PayoutAccountFailure(
      message: status != null && status >= 400 && status < 500
          ? e.message
          : null,
    );
  }

  static PayoutAccount _fromModel(api.PayoutAccountModel m) => PayoutAccount(
    bankCode: m.bankCode,
    bankFullName: m.bankFullName,
    accountLast4: m.accountLast4,
    holderName: m.holderName,
  );
}
