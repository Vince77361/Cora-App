import 'package:cora_api/api.dart' as api;

import '../../offer_terms/domain/offer_terms.dart';
import '../domain/wallet.dart';
import '../domain/wallet_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 정산 현황을 읽는다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiWalletRepository implements WalletRepository {
  ApiWalletRepository(api.ApiClient client) : _api = api.WalletApi(client);

  final api.WalletApi _api;

  @override
  Future<Wallet> fetch() async {
    try {
      final m = await _api.getWallet();
      if (m == null) throw const WalletFailure();
      return _fromModel(m);
    } on WalletFailure {
      rethrow;
    } catch (_) {
      throw const WalletFailure();
    }
  }

  static Wallet _fromModel(api.WalletModel m) => Wallet(
    account: m.account == null
        ? null
        : WalletAccount(
            bankFullName: m.account!.bankFullName,
            accountLast4: m.account!.accountLast4,
            holderName: m.account!.holderName,
          ),
    nextPayout: _nextPayout(m.nextPayout),
    receivedThisMonth: m.receivedThisMonth,
    heldAmount: m.heldAmount,
    entries: [for (final e in m.entries) _entry(e)],
  );

  /// 서버는 지급일을 한국 시간 `YYYY-MM-DD`로 준다. 지급은 그날 10:00(한국 시간)에 나가므로 그
  /// 시각(UTC 01:00)으로 바꿔 둔다. 화면이 시간대를 다시 한국으로 옮겨도 같은 날이다.
  static NextPayout? _nextPayout(api.WalletNextPayoutModel? m) {
    if (m == null) return null;
    final parts = m.date.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final mo = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || mo == null || d == null) return null;
    return NextPayout(date: DateTime.utc(y, mo, d, 1), amount: m.amount);
  }

  static WalletEntry _entry(api.WalletEntryModel e) => WalletEntry(
    collaborationId: e.collaborationId,
    counterpartName: e.counterpartName,
    format: switch (e.format) {
      api.ContentFormat.SHORTS => ContentFormat.shorts,
      api.ContentFormat.REELS => ContentFormat.reels,
      api.ContentFormat.CARD_NEWS => ContentFormat.cardNews,
      _ => ContentFormat.blog,
    },
    pieces: e.pieces,
    kind: switch (e.kind) {
      api.WalletEntryKind.PAYOUT_SCHEDULED => WalletEntryKind.payoutScheduled,
      api.WalletEntryKind.PAYOUT_DONE => WalletEntryKind.payoutDone,
      api.WalletEntryKind.PAYOUT_FAILED => WalletEntryKind.payoutFailed,
      api.WalletEntryKind.HELD => WalletEntryKind.held,
      _ => WalletEntryKind.voucher,
    },
    at: e.at,
    amount: e.amount,
    views: e.views,
    voucherName: e.voucherName,
    voucherUsed: e.voucherUsed,
    published: e.stage == api.CollaborationStage.PUBLISHED,
  );
}
