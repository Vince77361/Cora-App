import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/wallet/domain/wallet.dart';
import 'package:cora/features/wallet/domain/wallet_repository.dart';

/// 손으로 쓴 가짜 정산 저장소.
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository({Wallet? wallet}) : wallet = wallet ?? emptyWallet;

  Wallet wallet;
  bool failFetch = false;
  int fetchCalls = 0;

  @override
  Future<Wallet> fetch() async {
    fetchCalls++;
    if (failFetch) throw const WalletFailure();
    return wallet;
  }
}

const emptyWallet = Wallet(entries: [], heldAmount: 0, receivedThisMonth: 0);

const canvasAccount = WalletAccount(
  bankFullName: '국민은행',
  accountLast4: '0112',
  holderName: '민서연',
);

/// 캔버스 NWallet의 숫자와 네 줄. 지급일은 11월 18일 수요일 10:00(한국 시간).
final canvasWallet = Wallet(
  account: canvasAccount,
  nextPayout: NextPayout(date: DateTime.utc(2026, 11, 18, 1), amount: 43200),
  receivedThisMonth: 350000,
  heldAmount: 100000,
  entries: [
    WalletEntry(
      collaborationId: 'c1',
      counterpartName: '한그릇 라멘',
      format: ContentFormat.reels,
      pieces: 1,
      kind: WalletEntryKind.payoutScheduled,
      at: DateTime.utc(2026, 11, 11, 3),
      amount: 43200,
      views: 4320,
    ),
    WalletEntry(
      collaborationId: 'c1',
      counterpartName: '한그릇 라멘',
      format: ContentFormat.reels,
      pieces: 1,
      kind: WalletEntryKind.voucher,
      at: DateTime.utc(2026, 11, 11, 3),
      voucherName: '2인 식사권',
      voucherUsed: true,
    ),
    WalletEntry(
      collaborationId: 'c2',
      counterpartName: '모아 스튜디오',
      format: ContentFormat.reels,
      pieces: 1,
      kind: WalletEntryKind.payoutDone,
      // 11월 2일 10:00(한국 시간).
      at: DateTime.utc(2026, 11, 2, 1),
      amount: 350000,
    ),
    WalletEntry(
      collaborationId: 'c3',
      counterpartName: '하루 한 컵',
      format: ContentFormat.cardNews,
      pieces: 1,
      kind: WalletEntryKind.held,
      at: DateTime.utc(2026, 11, 1, 1),
      amount: 100000,
      published: true,
    ),
  ],
);
