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

// tests for ProposalRowModel
void main() {
  // final instance = ProposalRowModel();

  group('test ProposalRowModel', () {
    // 합의해 만들어진 협업의 id. 합의 전이면 null.
    // String collaborationId
    test('to test the property `collaborationId`', () async {
      // TODO
    });

    // 상대가 쓴 최신 판본이 번호 2 이상이면 true(역제안).
    // bool counter
    test('to test the property `counter`', () async {
      // TODO
    });

    // ProposalCounterpartModel counterpart
    test('to test the property `counterpart`', () async {
      // TODO
    });

    // 상대 대기(WAITING)일 때 남은 응답 기한(올림). 하루가 안 남았으면 0. 그 밖에는 null.
    // int daysLeft
    test('to test the property `daysLeft`', () async {
      // TODO
    });

    // 끝난 제안(ENDED)의 갈래. AGREED: 합의 완료, ENDED: 사유를 골라 끝냄, EXPIRED: 기한이 지나 끝남. 그 밖에는 null.
    // ProposalEndKind endKind
    test('to test the property `endKind`', () async {
      // TODO
    });

    // 끝낸 쪽이 고른 사유. 사유 없이 끝났으면 null.
    // OfferEndReason endReason
    test('to test the property `endReason`', () async {
      // TODO
    });

    // ContentFormat format
    test('to test the property `format`', () async {
      // TODO
    });

    // MY_TURN: 내가 응답할 차례. WAITING: 상대 대기. ENDED: 끝난 제안.
    // ProposalGroup group
    test('to test the property `group`', () async {
      // TODO
    });

    // String offerId
    test('to test the property `offerId`', () async {
      // TODO
    });

    // int pieces
    test('to test the property `pieces`', () async {
      // TODO
    });

    // 최신 판본의 번호.
    // int version
    test('to test the property `version`', () async {
      // TODO
    });
  });
}
