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

/// tests for DiscoveryApi
void main() {
  // final instance = DiscoveryApi();

  group('tests for DiscoveryApi', () {
    // 후보 비교(브랜드). 이 캠페인에서 내가 저장한 두 크리에이터를 같은 결과물 기준으로 견주고 다른 줄을 알려 준다. 팔로워 수는 없다.
    //
    //Future<CompareModel> compareCandidates(String a, String b) async
    test('test compareCandidates', () async {
      // TODO
    });

    // \"조건부터 질문하기\": 서로 관심을 만들지 않고 브랜드에게 메시지 요청을 보낸다. 협업(INQUIRY)과 메시지 요청 방과 첫 메시지가 한 번에 만들어진다.
    //
    //Future<InquiryResultModel> createInquiry(String campaignId, InquiryDto inquiryDto) async
    test('test createInquiry', () async {
      // TODO
    });

    // 하트·저장 목록. 내가 하트를 보냈거나 저장한 것만 나온다(넘긴 것은 어디에도 나오지 않는다).
    //
    //Future<List<InterestCardModel>> listInterests({ InterestTab tab }) async
    test('test listInterests', () async {
      // TODO
    });

    // 크리에이터가 받은 제안: 글이나 조건 제안이 붙은 브랜드의 하트 가운데 아직 결정하지 않은 것.
    //
    //Future<List<ProposalModel>> listReceivedProposals() async
    test('test listReceivedProposals', () async {
      // TODO
    });

    // 하트(LIKE)·넘김(PASS)·저장(HOLD)을 저장한다. 브랜드·크리에이터는 반대쪽도 하트면 서로 관심(협업과 조건 버전 1)이 만들어진다. 사장님은 크리에이터에게만(campaign 없음) 결정하며 협업을 만들지 않는다.
    //
    //Future<DecisionResultModel> putDecision(PutDecisionDto putDecisionDto) async
    test('test putDecision', () async {
      // TODO
    });

    // 넘긴 카드에 이유를 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.
    //
    //Future putPassReason(PassReasonDto passReasonDto) async
    test('test putPassReason', () async {
      // TODO
    });

    // 가게 카드를 넘긴다(가게 카드의 하트는 지원 API로 보낸다).
    //
    //Future putStorePass(String storeId) async
    test('test putStorePass', () async {
      // TODO
    });

    // 오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다. 서로 관심이 된 결정(사장님은 하트를 보낸 크리에이터가 그 가게에 지원해 있을 때)은 409다.
    //
    //Future<UndoneDecisionModel> undoLastDecision() async
    test('test undoLastDecision', () async {
      // TODO
    });
  });
}
