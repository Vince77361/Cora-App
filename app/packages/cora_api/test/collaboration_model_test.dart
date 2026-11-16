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
    // 브랜드 계약의 여섯 단계 진행. 멈춘 협업은 멈추기 전 단계로 읽는다. 가게 오퍼이거나 진행 표에 없는 단계(INQUIRY, DROPPED)면 null.
    // BrandProgressModel brandProgress
    test('to test the property `brandProgress`', () async {
      // TODO
    });

    // 브랜드 계약이 나온 캠페인. 가게 오퍼이거나 캠페인을 읽을 수 없으면 null.
    // CollaborationCampaignModel campaign
    test('to test the property `campaign`', () async {
      // TODO
    });

    // 남은 캠페인 예산. 그 캠페인의 브랜드에게만 채우고 크리에이터와 가게 오퍼에는 null.
    // CampaignBudgetLeftModel campaignBudgetLeft
    test('to test the property `campaignBudgetLeft`', () async {
      // TODO
    });

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

    // 지금 내가 할 일. RESPOND_TERMS: 최신 조건 판본을 아직 확인하지 않음, SIGN_CONTRACT: 양쪽이 합의해 계약할 차례. 그 밖은 null.
    // CollaborationNextAction nextAction
    test('to test the property `nextAction`', () async {
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

    // 이번 협업의 확보액(원) = 최신 조건 판본의 최대 현금 부담. 가게 오퍼이거나 판본이 없으면 null.
    // int securedAmount
    test('to test the property `securedAmount`', () async {
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

    // 가게 오퍼의 다섯 단계. 브랜드 계약은 빈 배열이고 brandProgress가 대신한다.
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

    // 수락할 때의 조건(사본). 가게 오퍼에만 있고 브랜드 계약은 null이다(브랜드 계약의 조건은 조건 판본이 담는다).
    // OfferTermsModel terms
    test('to test the property `terms`', () async {
      // TODO
    });

    // 브랜드 계약의 제목(최신 조건 판본의 제목). 가게 오퍼이거나 판본이 없으면 null.
    // String title
    test('to test the property `title`', () async {
      // TODO
    });

    // 조회 자료 확인 단계. NONE: 조회수 수당이 없거나 링크 제출 전, COUNTING: 집계 중, UNCONFIRMED: 계산이 나와 확인을 기다림, CONFIRMED: 확인됨, DISPUTED: 이의 중.
    // CollaborationViewReportStatus viewReportStatus
    test('to test the property `viewReportStatus`', () async {
      // TODO
    });
  });
}
