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

// tests for ContractModel
void main() {
  // final instance = ContractModel();

  group('test ContractModel', () {
    // 결제가 승인돼 체결될 때 채워진다.
    // DateTime brandConsentedAt
    test('to test the property `brandConsentedAt`', () async {
      // TODO
    });

    // String brandName
    test('to test the property `brandName`', () async {
      // TODO
    });

    // DateTime concludedAt
    test('to test the property `concludedAt`', () async {
      // TODO
    });

    // DateTime creatorConsentedAt
    test('to test the property `creatorConsentedAt`', () async {
      // TODO
    });

    // String creatorName
    test('to test the property `creatorName`', () async {
      // TODO
    });

    // 내 쪽 확인란 세 줄. 동의할 때 이 문구를 그대로 보낸다(다르면 400). 계약할 수 없는 상태면 빈 배열.
    // List<String> myConsentTexts (default value: const [])
    test('to test the property `myConsentTexts`', () async {
      // TODO
    });

    // 브랜드에게만, 동의하면 결제할 금액(크리에이터 동의 뒤 결제 전). 서버가 계약 사본에서 계산한 값이다.
    // PaymentQuoteModel quote
    test('to test the property `quote`', () async {
      // TODO
    });

    // NOT_READY = 양쪽이 같은 판본을 확인하기 전(미리 보기), AWAITING_CREATOR = 합의됨·크리에이터 동의 전, AWAITING_BRAND = 크리에이터 동의 뒤·브랜드 동의(결제) 전, PAYING = 브랜드가 결제 중(결제창을 연 지 60분 안), CONCLUDED = 결제가 승인돼 체결됨.
    // ContractStatus status
    test('to test the property `status`', () async {
      // TODO
    });

    // 조건. 계약 행이 있으면 동의할 때 만든 사본이고, 없으면 최신 판본(미리 보기)이다.
    // TermsVersionModel terms
    test('to test the property `terms`', () async {
      // TODO
    });

    // 계약이 담은(미리 보기면 최신) 판본 번호. 판본이 없으면 null.
    // int termsVersion
    test('to test the property `termsVersion`', () async {
      // TODO
    });

    // 내 동의가 새 판본으로 취소됐고 새 계약이 아직 없다(앱이 \"조건이 바뀌어 동의가 취소됐어요.\" 띠를 보여 준다).
    // bool voidedNotice
    test('to test the property `voidedNotice`', () async {
      // TODO
    });
  });
}
