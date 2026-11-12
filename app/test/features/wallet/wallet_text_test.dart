import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/wallet/domain/wallet.dart';
import 'package:cora/features/wallet/presentation/wallet_text.dart';
import 'package:flutter_test/flutter_test.dart';

WalletEntry _entry(
  WalletEntryKind kind, {
  String name = '한그릇 라멘',
  ContentFormat format = ContentFormat.reels,
  int? amount,
  int? views,
  String? voucherName,
  bool? voucherUsed,
  bool published = false,
  DateTime? at,
}) => WalletEntry(
  collaborationId: 'c',
  counterpartName: name,
  format: format,
  pieces: 1,
  kind: kind,
  at: at ?? DateTime.utc(2026, 11, 11),
  amount: amount,
  views: views,
  voucherName: voucherName,
  voucherUsed: voucherUsed,
  published: published,
);

void main() {
  test('formats the payday as month, day and weekday', () {
    // 11월 18일 수요일 10:00(한국 시간) = 01:00 UTC.
    expect(paydayLabel(DateTime.utc(2026, 11, 18, 1)), '11월 18일 수요일');
    expect(paydayLabel(DateTime.utc(2026, 11, 25, 1)), '11월 25일 수요일');
    // 한국 시간으로 세므로 UTC로는 전날 16시인 수요일 새벽도 수요일이다.
    expect(paydayLabel(DateTime.utc(2026, 11, 17, 16)), '11월 18일 수요일');
    expect(paydayLabel(DateTime.utc(2026, 11, 15, 15)), '11월 16일 월요일');
    expect(paydayLabel(DateTime.utc(2026, 11, 22, 1)), '11월 22일 일요일');
  });

  test('builds the entry title from counterpart, format and pieces', () {
    expect(entryTitle(_entry(WalletEntryKind.held)), '한그릇 라멘 · 릴스 1편');
    expect(
      entryTitle(
        _entry(
          WalletEntryKind.held,
          name: '하루 한 컵',
          format: ContentFormat.cardNews,
        ),
      ),
      '하루 한 컵 · 카드뉴스 1편',
    );
  });

  test('builds the entry subtitle for each kind', () {
    expect(
      entrySubtitle(_entry(WalletEntryKind.payoutScheduled, views: 4320)),
      '조회수 4,320회분',
    );
    // 고정 제작비 지급은 조회수가 없어 설명이 없다.
    expect(entrySubtitle(_entry(WalletEntryKind.payoutScheduled)), isNull);
    // 송금 시각 11월 2일 10:00(한국 시간).
    expect(
      entrySubtitle(
        _entry(WalletEntryKind.payoutDone, at: DateTime.utc(2026, 11, 2, 1)),
      ),
      '11월 2일 지급',
    );
    expect(
      entrySubtitle(_entry(WalletEntryKind.held, published: true)),
      '게시 확인 중',
    );
    expect(entrySubtitle(_entry(WalletEntryKind.held)), isNull);
    expect(
      entrySubtitle(_entry(WalletEntryKind.voucher, voucherName: '2인 식사권')),
      '2인 식사권',
    );
  });

  test('builds the entry amount and state', () {
    expect(
      entryAmount(_entry(WalletEntryKind.payoutScheduled, amount: 43200)),
      '43,200원',
    );
    expect(
      entryAmount(_entry(WalletEntryKind.payoutDone, amount: 350000)),
      '350,000원',
    );
    expect(entryAmount(_entry(WalletEntryKind.voucher)), '식사권');

    expect(entryState(_entry(WalletEntryKind.payoutScheduled)), '지급 예정');
    expect(entryState(_entry(WalletEntryKind.payoutDone)), '지급 완료');
    expect(entryState(_entry(WalletEntryKind.payoutFailed)), '지급 확인 중');
    expect(entryState(_entry(WalletEntryKind.held)), '보관 중');
    expect(
      entryState(_entry(WalletEntryKind.voucher, voucherUsed: true)),
      '사용 완료',
    );
    expect(
      entryState(_entry(WalletEntryKind.voucher, voucherUsed: false)),
      '방문 때 사용',
    );
  });

  test('shows the bank full name and the last two digits of the account', () {
    expect(
      accountLabel(
        const WalletAccount(
          bankFullName: '국민은행',
          accountLast4: '0112',
          holderName: '민서연',
        ),
      ),
      '국민은행 ****12',
    );
  });
}
