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

/// tests for TermsApi
void main() {
  // final instance = TermsApi();

  group('tests for TermsApi', () {
    // 이 판본 수락. 최신이 아니면 409 STALE_VERSION(본문에 latestVersion), 성과 추가가 있는데 인스타그램 연동이 없으면 크리에이터는 409.
    //
    //Future<TermsVersionModel> confirmTerms(String id, num version) async
    test('test confirmTerms', () async {
      // TODO
    });

    // 브랜드 계약의 가장 최근 조건 판본(당사자만).
    //
    //Future<TermsLatestModel> getLatestTerms(String id) async
    test('test getLatestTerms', () async {
      // TODO
    });

    // 조건 판본 이력(당사자만). 최신이 먼저이고 판본마다 바뀐 항목을 담는다. agreement는 최신 판본의 확인 상태, editable은 지금 수정 제안을 낼 수 있는가.
    //
    //Future<TermsHistoryModel> listTermsVersions(String id) async
    test('test listTermsVersions', () async {
      // TODO
    });

    // 새 판본을 낸다(조건 수정 제안). 빠진 항목은 직전 판본에서 옮기고 성과 추가는 null이면 끈다. 낸 쪽은 확인함이고 단계는 협의가 되며 크리에이터의 계약 동의는 취소된다. 최신 판본이 아니면 409 STALE_VERSION, 브랜드 결제가 진행 중이면 409, 바뀐 것이 없으면 400.
    //
    //Future<TermsVersionModel> proposeReward(String id, ProposeRewardDto proposeRewardDto) async
    test('test proposeReward', () async {
      // TODO
    });
  });
}
