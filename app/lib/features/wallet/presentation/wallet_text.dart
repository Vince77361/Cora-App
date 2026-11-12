import '../../../core/time/kst.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/wallet.dart';

// 정산(E7)의 화면 문구. 모두 순수 함수라 시계나 위젯 없이 시험한다.

abstract final class WalletTexts {
  static const title = '정산';
  static const changeAccount = '계좌 변경';
  static const receivedThisMonth = '이번 달 받은 금액';
  static const held = 'Cora가 보관 중';
  static const history = '내역';

  /// 캔버스에 없는 상태의 문구.
  static const noNextPayout = '다음 지급 예정 없음';
  static const noAmount = '0원';
  static const registerAccountPrompt = '지급받을 계좌를 등록해 주세요.';
  static const registerAccount = '계좌 등록';
  static const empty = '아직 내역이 없어요.';
  static const loadFailed = '정산 내역을 불러오지 못했어요.';
  static const payoutFailedState = '지급 확인 중';

  static String nextPayout(DateTime date) => '다음 지급 예정 · ${paydayLabel(date)}';
}

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 지급일 표시: `11월 18일 수요일`. 한국 시간의 날짜와 요일로 센다.
String paydayLabel(DateTime at) {
  final kst = toKst(at);
  return '${kst.month}월 ${kst.day}일 ${_weekdays[kst.weekday - 1]}요일';
}

/// 줄 제목: `{상대} · {형식} {편 수}편`.
String entryTitle(WalletEntry e) =>
    '${e.counterpartName} · ${formatLabel(e.format)} ${e.pieces}편';

/// 줄 설명. 없으면 null(그 줄에는 설명 줄을 그리지 않는다).
///
/// 지급 예정은 `조회수 {n}회분`, 지급 완료는 `{M}월 {D}일 지급`, 브랜드 계약이 게시 단계이면 보관
/// 줄이 `게시 확인 중`, 식사권은 식사권 이름이다. 고정 제작비 지급 예정과 그 밖의 보관 줄은 캔버스에
/// 설명이 없어 비운다.
String? entrySubtitle(WalletEntry e) => switch (e.kind) {
  WalletEntryKind.payoutScheduled || WalletEntryKind.payoutFailed =>
    e.views == null ? null : '조회수 ${_withCommas(e.views!)}회분',
  WalletEntryKind.payoutDone => '${kstMonthDay(e.at)} 지급',
  WalletEntryKind.held => e.published ? '게시 확인 중' : null,
  WalletEntryKind.voucher => e.voucherName,
};

/// 줄 오른쪽 금액: `43,200원`, 식사권은 `식사권`.
String entryAmount(WalletEntry e) =>
    e.amount == null ? '식사권' : wonExact(e.amount!);

/// 줄 오른쪽 상태. 식사권은 링크를 냈으면 `사용 완료`, 아니면 `방문 때 사용`이다.
String entryState(WalletEntry e) => switch (e.kind) {
  WalletEntryKind.payoutScheduled => '지급 예정',
  WalletEntryKind.payoutDone => '지급 완료',
  WalletEntryKind.payoutFailed => WalletTexts.payoutFailedState,
  WalletEntryKind.held => '보관 중',
  WalletEntryKind.voucher => e.voucherUsed == true ? '사용 완료' : '방문 때 사용',
};

/// 계좌 줄: `국민은행 ****12`. 서버는 뒤 4자리를 주지만 화면은 뒤 2자리만 보인다.
String accountLabel(WalletAccount account) {
  final last = account.accountLast4;
  final tail = last.length <= 2 ? last : last.substring(last.length - 2);
  return '${account.bankFullName} ****$tail';
}

String _withCommas(int n) {
  final digits = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
