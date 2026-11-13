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

// tests for CollaborationModel
void main() {
  // final instance = CollaborationModel();

  group('test CollaborationModel', () {
    // 크리에이터가 지금 협업을 그만둘 수 있으면 true(링크를 제출하기 전).
    // bool canCancel
    test('to test the property `canCancel`', () async {
      // TODO
    });

    // 사장님이 지금 취소 요청을 보낼 수 있으면 true.
    // bool canRequestCancel
    test('to test the property `canRequestCancel`', () async {
      // TODO
    });

    // 답을 기다리는 취소 요청.
    // CancelRequestModel cancelRequest
    test('to test the property `cancelRequest`', () async {
      // TODO
    });

    // CollaborationCounterpartModel counterpart
    test('to test the property `counterpart`', () async {
      // TODO
    });

    // 조회수 집계가 끝나는 시각(제출 뒤 7일).
    // DateTime countingEndsAt
    test('to test the property `countingEndsAt`', () async {
      // TODO
    });

    // 가장 최근에 읽은 조회수. 아직 읽은 값이 없으면 null.
    // int currentViews
    test('to test the property `currentViews`', () async {
      // TODO
    });

    // 지금까지 받을 금액(원). 집계 중일 때 크리에이터에게만 숫자다.
    // int earnedSoFar
    test('to test the property `earnedSoFar`', () async {
      // TODO
    });

    // 결제할 때 에스크로에 맡긴 금액(원). 협업이 끝날 때까지 그대로이고, 결제 전이거나 식사권만 있으면 0.
    // int escrowAmount
    test('to test the property `escrowAmount`', () async {
      // TODO
    });

    // 예상 환급액(원). 집계 중일 때 사장님에게만 숫자다.
    // int expectedRefund
    test('to test the property `expectedRefund`', () async {
      // TODO
    });

    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // CollaborationKind kind
    test('to test the property `kind`', () async {
      // TODO
    });

    // 지급이 PENDING이고 계좌가 있을 때 송금할 지급일. 크리에이터에게만.
    // DateTime payoutScheduledFor
    test('to test the property `payoutScheduledFor`', () async {
      // TODO
    });

    // NONE: 줄 돈이 없음(정산 전이거나 0원), NEEDS_ACCOUNT: 지급 계좌 등록이 필요함(크리에이터에게만), PENDING: 지급일을 기다림, DONE: 지급됨, FAILED: 송금 실패(운영팀이 확인).
    // PayoutStatus payoutStatus
    test('to test the property `payoutStatus`', () async {
      // TODO
    });

    // 내 쪽. COMMISSIONER는 맡긴 쪽(사장님·브랜드), CREATOR는 크리에이터.
    // CollaborationRole role
    test('to test the property `role`', () async {
      // TODO
    });

    // 정산이 확정된 뒤의 결과. 정산 전이거나(조회 자료 확인 전 포함) 식사권만 있으면 null.
    // CollaborationSettlementModel settlement
    test('to test the property `settlement`', () async {
      // TODO
    });

    // CollaborationStage stage
    test('to test the property `stage`', () async {
      // TODO
    });

    // List<CollaborationStepModel> steps (default value: const [])
    test('to test the property `steps`', () async {
      // TODO
    });

    // 가게 오퍼의 가게. 브랜드 계약이거나 가게를 읽을 수 없으면 null.
    // StoreSummaryModel store
    test('to test the property `store`', () async {
      // TODO
    });

    // 링크 제출 기한(결제 뒤 14일).
    // DateTime submitDueAt
    test('to test the property `submitDueAt`', () async {
      // TODO
    });

    // String submittedUrl
    test('to test the property `submittedUrl`', () async {
      // TODO
    });

    // 수락할 때의 조건(사본).
    // OfferTermsModel terms
    test('to test the property `terms`', () async {
      // TODO
    });

    // 조회 자료 확인 단계. NONE: 조회수 수당이 없거나 링크 제출 전, COUNTING: 집계 중, UNCONFIRMED: 계산이 나와 확인을 기다림, CONFIRMED: 확인됨, DISPUTED: 이의 중.
    // CollaborationViewReportStatus viewReportStatus
    test('to test the property `viewReportStatus`', () async {
      // TODO
    });
  });
}
