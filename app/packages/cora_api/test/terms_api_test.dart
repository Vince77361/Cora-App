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

    // 돈과 혜택만 바꿔 새 판본을 낸다(나머지 항목은 직전 판본에서 옮긴다). 낸 쪽은 확인함이고 단계는 협의가 된다. 최신 판본이 아니면 409 STALE_VERSION, 바뀐 것이 없으면 400.
    //
    //Future<TermsVersionModel> proposeReward(String id, ProposeRewardDto proposeRewardDto) async
    test('test proposeReward', () async {
      // TODO
    });
  });
}
