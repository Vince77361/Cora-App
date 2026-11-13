# cora_api.model.CollaborationModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**canCancel** | **bool** | 크리에이터가 지금 협업을 그만둘 수 있으면 true(링크를 제출하기 전). | 
**canRequestCancel** | **bool** | 사장님이 지금 취소 요청을 보낼 수 있으면 true. | 
**cancelRequest** | [**CancelRequestModel**](CancelRequestModel.md) | 답을 기다리는 취소 요청. | 
**counterpart** | [**CollaborationCounterpartModel**](CollaborationCounterpartModel.md) |  | 
**countingEndsAt** | [**DateTime**](DateTime.md) | 조회수 집계가 끝나는 시각(제출 뒤 7일). | 
**currentViews** | **int** | 가장 최근에 읽은 조회수. 아직 읽은 값이 없으면 null. | 
**earnedSoFar** | **int** | 지금까지 받을 금액(원). 집계 중일 때 크리에이터에게만 숫자다. | 
**escrowAmount** | **int** | 결제할 때 에스크로에 맡긴 금액(원). 협업이 끝날 때까지 그대로이고, 결제 전이거나 식사권만 있으면 0. | 
**expectedRefund** | **int** | 예상 환급액(원). 집계 중일 때 사장님에게만 숫자다. | 
**id** | **String** |  | 
**kind** | [**CollaborationKind**](CollaborationKind.md) |  | 
**payoutScheduledFor** | [**DateTime**](DateTime.md) | 지급이 PENDING이고 계좌가 있을 때 송금할 지급일. 크리에이터에게만. | 
**payoutStatus** | [**PayoutStatus**](PayoutStatus.md) | NONE: 줄 돈이 없음(정산 전이거나 0원), NEEDS_ACCOUNT: 지급 계좌 등록이 필요함(크리에이터에게만), PENDING: 지급일을 기다림, DONE: 지급됨, FAILED: 송금 실패(운영팀이 확인). | 
**role** | [**CollaborationRole**](CollaborationRole.md) | 내 쪽. COMMISSIONER는 맡긴 쪽(사장님·브랜드), CREATOR는 크리에이터. | 
**settlement** | [**CollaborationSettlementModel**](CollaborationSettlementModel.md) | 정산이 확정된 뒤의 결과. 정산 전이거나(조회 자료 확인 전 포함) 식사권만 있으면 null. | 
**stage** | [**CollaborationStage**](CollaborationStage.md) |  | 
**steps** | [**List<CollaborationStepModel>**](CollaborationStepModel.md) |  | [default to const []]
**store** | [**StoreSummaryModel**](StoreSummaryModel.md) | 가게 오퍼의 가게. 브랜드 계약이거나 가게를 읽을 수 없으면 null. | 
**submitDueAt** | [**DateTime**](DateTime.md) | 링크 제출 기한(결제 뒤 14일). | 
**submittedUrl** | **String** |  | 
**terms** | [**OfferTermsModel**](OfferTermsModel.md) | 수락할 때의 조건(사본). | 
**viewReportStatus** | [**CollaborationViewReportStatus**](CollaborationViewReportStatus.md) | 조회 자료 확인 단계. NONE: 조회수 수당이 없거나 링크 제출 전, COUNTING: 집계 중, UNCONFIRMED: 계산이 나와 확인을 기다림, CONFIRMED: 확인됨, DISPUTED: 이의 중. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


