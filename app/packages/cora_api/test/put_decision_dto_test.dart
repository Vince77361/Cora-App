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

// tests for PutDecisionDto
void main() {
  // final instance = PutDecisionDto();

  group('test PutDecisionDto', () {
    // SwipeDecisionKind decision
    test('to test the property `decision`', () async {
      // TODO
    });

    // LIKE에 붙이는 글. 크리에이터는 40자(조건 버전의 제목), 브랜드는 100자(좋아한 점).
    // String note
    test('to test the property `note`', () async {
      // TODO
    });

    // 브랜드의 LIKE에만 붙인다(크리에이터가 보내면 400). 이미 LIKE인 결정에 다시 보내면 값만 덮어쓴다.
    // BrandProposalDto proposal
    test('to test the property `proposal`', () async {
      // TODO
    });

    // 크리에이터(사용자) 또는 캠페인의 id.
    // String targetId
    test('to test the property `targetId`', () async {
      // TODO
    });

    // 브랜드는 CREATOR만, 크리에이터는 CAMPAIGN만 보낸다.
    // DecisionTargetKind targetKind
    test('to test the property `targetKind`', () async {
      // TODO
    });
  });
}
