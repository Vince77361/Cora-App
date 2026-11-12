//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:cora_api/api.dart';
import 'package:test/test.dart';

// tests for WalletEntryModel
void main() {
  // final instance = WalletEntryModel();

  group('test WalletEntryModel', () {
    // 금액(원). 식사권 줄은 null.
    // int amount
    test('to test the property `amount`', () async {
      // TODO
    });

    // 줄의 기준 시각. 지급 예정은 정산 시각, 지급 완료는 송금 시각, 보관 중은 보관 시작.
    // DateTime at
    test('to test the property `at`', () async {
      // TODO
    });

    // String collaborationId
    test('to test the property `collaborationId`', () async {
      // TODO
    });

    // 크리에이터에게는 가게 이름. 읽을 수 없으면 \"가게\"(브랜드 계약은 \"브랜드\").
    // String counterpartName
    test('to test the property `counterpartName`', () async {
      // TODO
    });

    // ContentFormat format
    test('to test the property `format`', () async {
      // TODO
    });

    // PAYOUT_SCHEDULED: 정산이 확정되고 송금 전, PAYOUT_DONE: 송금 끝, PAYOUT_FAILED: 송금 실패(운영팀이 확인), HELD: Cora가 보관 중, VOUCHER: 식사권.
    // WalletEntryKind kind
    test('to test the property `kind`', () async {
      // TODO
    });

    // 콘텐츠 편 수. 오퍼는 지금 한 편이다.
    // int pieces
    test('to test the property `pieces`', () async {
      // TODO
    });

    // CollaborationStage stage
    test('to test the property `stage`', () async {
      // TODO
    });

    // 정산에 쓴 최종 조회수. 지급 줄에서만 값이 있다.
    // int views
    test('to test the property `views`', () async {
      // TODO
    });

    // 식사권 이름. 식사권 줄에서만 값이 있다.
    // String voucherName
    test('to test the property `voucherName`', () async {
      // TODO
    });

    // 링크를 제출해 식사권을 쓴 것으로 보면 true. 식사권 줄에서만 값이 있다.
    // bool voucherUsed
    test('to test the property `voucherUsed`', () async {
      // TODO
    });
  });
}
