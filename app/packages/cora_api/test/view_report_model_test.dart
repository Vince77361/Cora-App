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

// tests for ViewReportModel
void main() {
  // final instance = ViewReportModel();

  group('test ViewReportModel', () {
    // 계산. 집계 중에는 null이다.
    // ViewReportCalcModel calc
    test('to test the property `calc`', () async {
      // TODO
    });

    // 내가 지금 \"자료 확인했어요\"를 누를 수 있으면 true(맡긴 쪽, 확인 전, 연결 계정 자료일 때만).
    // bool canConfirm
    test('to test the property `canConfirm`', () async {
      // TODO
    });

    // 내가 지금 이의를 제기할 수 있으면 true.
    // bool canDispute
    test('to test the property `canDispute`', () async {
      // TODO
    });

    // 내가 지금 캡처 자료를 올릴 수 있으면 true.
    // bool canUploadEvidence
    test('to test the property `canUploadEvidence`', () async {
      // TODO
    });

    // 확인 전일 때 자동으로 확인되는 시각.
    // DateTime confirmDueAt
    test('to test the property `confirmDueAt`', () async {
      // TODO
    });

    // 올라온 캡처 자료. 없으면 null.
    // ViewReportEvidenceModel evidence
    test('to test the property `evidence`', () async {
      // TODO
    });

    // 집계가 끝나는 시각.
    // DateTime periodEnd
    test('to test the property `periodEnd`', () async {
      // TODO
    });

    // 집계 시작(링크 제출 시각).
    // DateTime periodStart
    test('to test the property `periodStart`', () async {
      // TODO
    });

    // 크리에이터가 낸 게시 링크.
    // String postUrl
    test('to test the property `postUrl`', () async {
      // TODO
    });

    // CONNECTED_ACCOUNT: 연결한 인스타그램 계정에서 읽음, CAPTURE_PENDING: 캡처 자료(확인 전), CAPTURE_CONFIRMED: 캡처 자료(확정됨).
    // ViewReportSource source_
    test('to test the property `source_`', () async {
      // TODO
    });

    // COUNTING: 집계 중(계산 없음), UNCONFIRMED: 계산이 나왔고 확인을 기다림, CONFIRMED: 확인되어 정산됨, DISPUTED: 이의가 걸려 돈이 그대로 보관됨.
    // ViewReportStatus status
    test('to test the property `status`', () async {
      // TODO
    });

    // 조회수. 집계 중에는 그날까지 읽은 값(없으면 null), 계산이 나온 뒤에는 정산에 쓰는 값.
    // int views
    test('to test the property `views`', () async {
      // TODO
    });
  });
}
