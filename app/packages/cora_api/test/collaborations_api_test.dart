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

/// tests for CollaborationsApi
void main() {
  // final instance = CollaborationsApi();

  group('tests for CollaborationsApi', () {
    // 크리에이터가 사장님의 취소 요청에 동의한다(직접 그만두는 것과 같은 처리).
    //
    //Future<CollaborationModel> acceptCollaborationCancel(String id, String requestId) async
    test('test acceptCollaborationCancel', () async {
      // TODO
    });

    // 크리에이터가 링크를 제출하기 전에 협업을 그만둔다(수수료까지 전액 환급).
    //
    //Future<CollaborationModel> cancelCollaboration(String id) async
    test('test cancelCollaboration', () async {
      // TODO
    });

    // 계약 전 협의를 그만둔다(당사자만). 이유는 상대에게 알리지 않는다. 계약 전 단계가 아니거나 브랜드가 결제를 진행 중이면 409.
    //
    //Future<CollaborationModel> dropCollaboration(String id, DropCollaborationDto dropCollaborationDto) async
    test('test dropCollaboration', () async {
      // TODO
    });

    //
    //
    //Future<CollaborationModel> getCollaboration(String id) async
    test('test getCollaboration', () async {
      // TODO
    });

    //
    //
    //Future<List<CollaborationModel>> listCollaborations(CollaborationScope scope) async
    test('test listCollaborations', () async {
      // TODO
    });

    // 사장님이 취소를 요청한다. 3일 안에 답이 없으면 사라진다.
    //
    //Future<CollaborationModel> requestCollaborationCancel(String id) async
    test('test requestCollaborationCancel', () async {
      // TODO
    });
  });
}
