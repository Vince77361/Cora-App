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

/// tests for ContractsApi
void main() {
  // final instance = ContractsApi();

  group('tests for ContractsApi', () {
    // 크리에이터가 계약에 동의한다(브랜드보다 먼저). 협업이 합의(AGREED) 상태이고 termsVersion이 최신일 때만: 최신이 아니면 409 STALE_VERSION(latestVersion), 그 밖의 상태는 409 CONFLICT, 확인한 문구가 서버의 문구와 다르면 400. 같은 판본에 다시 동의하면 바뀌는 것 없이 같은 계약을 돌려준다.
    //
    //Future<ContractModel> consentContractAsCreator(String id, CreatorConsentDto creatorConsentDto) async
    test('test consentContractAsCreator', () async {
      // TODO
    });

    // 계약 화면(당사자만). 양쪽이 같은 판본을 확인하기 전(NOT_READY)에는 최신 판본과 문구를 미리 보기로 준다. 브랜드에게는 동의하면 결제할 금액(quote)이 함께 간다.
    //
    //Future<ContractModel> getContract(String id) async
    test('test getContract', () async {
      // TODO
    });
  });
}
