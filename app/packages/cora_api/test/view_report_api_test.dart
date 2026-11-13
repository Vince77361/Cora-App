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

/// tests for ViewReportApi
void main() {
  // final instance = ViewReportApi();

  group('tests for ViewReportApi', () {
    // 맡긴 쪽이 \"자료 확인했어요\"를 누른다. 확인되면 정산이 이어진다. 확인할 수 없는 상태면 409, 크리에이터는 403.
    //
    //Future<ViewReportModel> confirmViewReport(String id) async
    test('test confirmViewReport', () async {
      // TODO
    });

    // 조회 자료에 이의를 제기한다(당사자 누구나, 확인 전인 계산에 한 사람이 한 번). 돈은 그대로 보관되고 운영팀이 처리한다. 낼 수 없는 상태면 409.
    //
    //Future<ViewReportModel> disputeViewReport(String id, DisputeViewReportDto disputeViewReportDto) async
    test('test disputeViewReport', () async {
      // TODO
    });

    // 조회 자료 확인(F4). 당사자만 읽는다. 조회수 수당이 없거나 링크 제출 전이면 404.
    //
    //Future<ViewReportModel> getViewReport(String id) async
    test('test getViewReport', () async {
      // TODO
    });

    // 조회수를 읽지 못했을 때 크리에이터가 인사이트 캡처와 조회수를 낸다. 크리에이터만, 캡처가 요청된 때 한 번. 받을 수 없는 상태면 409, 내 파일이 아니면 403.
    //
    //Future<ViewReportModel> submitViewEvidence(String id, SubmitViewEvidenceDto submitViewEvidenceDto) async
    test('test submitViewEvidence', () async {
      // TODO
    });
  });
}
