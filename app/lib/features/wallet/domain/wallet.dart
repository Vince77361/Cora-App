import '../../offer_terms/domain/offer_terms.dart';

/// 정산 내역(E7) 한 줄의 종류. 서버의 `WalletEntryKind`와 일대일이다.
enum WalletEntryKind {
  /// 정산이 확정되고 송금 전.
  payoutScheduled,

  /// 송금이 끝났다.
  payoutDone,

  /// 송금이 실패해 운영팀이 확인 중이다.
  payoutFailed,

  /// Cora가 보관 중이다.
  held,

  /// 식사권.
  voucher,
}

/// 정산 내역의 한 줄. 문구는 앱이 만들고(`wallet_text.dart`) 서버는 값만 보낸다.
class WalletEntry {
  const WalletEntry({
    required this.collaborationId,
    required this.counterpartName,
    required this.format,
    required this.pieces,
    required this.kind,
    required this.at,
    this.amount,
    this.views,
    this.voucherName,
    this.voucherUsed,
    this.published = false,
  });

  final String collaborationId;

  /// 가게 이름(브랜드 계약은 브랜드 이름).
  final String counterpartName;
  final ContentFormat format;

  /// 콘텐츠 편 수.
  final int pieces;
  final WalletEntryKind kind;

  /// 줄의 기준 시각. 지급 완료의 "{M}월 {D}일 지급"이 이 값을 한국 시간으로 센다.
  final DateTime at;

  /// 금액(원). 식사권 줄은 null.
  final int? amount;

  /// 정산에 쓴 최종 조회수. 조회수당 지급 줄에서만 있다.
  final int? views;

  final String? voucherName;

  /// 링크를 제출해 식사권을 쓴 것으로 보면 true.
  final bool? voucherUsed;

  /// 브랜드 계약이 게시 단계(`PUBLISHED`)라 게시 확인을 기다리는 중이다.
  final bool published;
}

/// 등록한 지급 계좌. 서버는 뒤 4자리만 준다.
class WalletAccount {
  const WalletAccount({
    required this.bankFullName,
    required this.accountLast4,
    required this.holderName,
  });

  final String bankFullName;
  final String accountLast4;
  final String holderName;
}

/// 가장 이른 지급 예정일과 그날 나갈 금액의 합.
class NextPayout {
  const NextPayout({required this.date, required this.amount});

  /// 지급이 나가는 시각(한국 시간 수요일 10:00). 화면은 한국 시간의 날짜로만 쓴다.
  final DateTime date;
  final int amount;
}

/// 정산 화면(E7)의 데이터. 앱은 계산하지 않고 서버가 장부에서 계산한 값을 그대로 보인다.
class Wallet {
  const Wallet({
    required this.entries,
    required this.heldAmount,
    required this.receivedThisMonth,
    this.account,
    this.nextPayout,
  });

  /// 등록 전이면 null.
  final WalletAccount? account;

  /// 지급 예정이 없으면 null.
  final NextPayout? nextPayout;
  final int receivedThisMonth;
  final int heldAmount;

  /// 기준 시각 최신순.
  final List<WalletEntry> entries;
}
