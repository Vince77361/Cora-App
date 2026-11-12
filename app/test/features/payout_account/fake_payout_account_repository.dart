import 'package:cora/features/payout_account/domain/payout_account.dart';
import 'package:cora/features/payout_account/domain/payout_account_repository.dart';

const sampleBanks = [
  Bank(code: '004', name: '국민', fullName: '국민은행'),
  Bank(code: '088', name: '신한', fullName: '신한은행'),
  Bank(code: '020', name: '우리', fullName: '우리은행'),
];

/// 손으로 쓴 가짜 지급 계좌 저장소. 저장하면 뒤 4자리만 남긴다(서버처럼).
class FakePayoutAccountRepository implements PayoutAccountRepository {
  FakePayoutAccountRepository({this.account});

  PayoutAccount? account;

  /// 설정하면 저장이 이 오류로 실패한다(키가 없는 개발 서버의 500은 문구 없는 실패다).
  PayoutAccountFailure? failSave;
  bool failFetch = false;

  final saved =
      <({String bankCode, String accountNumber, String holderName})>[];

  @override
  Future<PayoutAccount?> fetch() async {
    if (failFetch) throw const PayoutAccountFailure();
    return account;
  }

  @override
  Future<List<Bank>> banks() async => sampleBanks;

  @override
  Future<PayoutAccount> save({
    required String bankCode,
    required String accountNumber,
    required String holderName,
  }) async {
    final error = failSave;
    if (error != null) throw error;
    saved.add((
      bankCode: bankCode,
      accountNumber: accountNumber,
      holderName: holderName,
    ));
    final bank = sampleBanks.firstWhere((b) => b.code == bankCode);
    return account = PayoutAccount(
      bankCode: bankCode,
      bankFullName: bank.fullName,
      accountLast4: accountNumber.substring(accountNumber.length - 4),
      holderName: holderName,
    );
  }
}
