# cora_api.model.CollaborationModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**brandProgress** | [**BrandProgressModel**](BrandProgressModel.md) | 브랜드 계약의 여섯 단계 진행. 멈춘 협업은 멈추기 전 단계로 읽는다. 가게 오퍼이거나 진행 표에 없는 단계(INQUIRY, DROPPED)면 null. | 
**campaign** | [**CollaborationCampaignModel**](CollaborationCampaignModel.md) | 브랜드 계약이 나온 캠페인. 가게 오퍼이거나 캠페인을 읽을 수 없으면 null. | 
**campaignBudgetLeft** | [**CampaignBudgetLeftModel**](CampaignBudgetLeftModel.md) | 남은 캠페인 예산. 그 캠페인의 브랜드에게만 채우고 크리에이터와 가게 오퍼에는 null. | 
**canCancel** | **bool** | 크리에이터가 지금 협업을 그만둘 수 있으면 true(링크를 제출하기 전). | 
**canRequestCancel** | **bool** | 사장님이 지금 취소 요청을 보낼 수 있으면 true. | 
**cancelRequest** | [**CancelRequestModel**](CancelRequestModel.md) | 답을 기다리는 취소 요청. | 
**contractStatus** | [**ContractProgress**](ContractProgress.md) | NONE: 계약 동의 전, AWAITING_BRAND: 크리에이터가 동의해 브랜드 결제 대기, CONCLUDED: 체결. | 
**conversationId** | **String** | 이 협업의 대화방. 방이 없으면 null. | 
**counterpart** | [**CollaborationCounterpartModel**](CollaborationCounterpartModel.md) |  | 
**countingEndsAt** | [**DateTime**](DateTime.md) | 조회수 집계가 끝나는 시각(제출 뒤 7일). | 
**currentViews** | **int** | 가장 최근에 읽은 조회수. 아직 읽은 값이 없으면 null. | 
**earnedSoFar** | **int** | 지금까지 받을 금액(원). 집계 중일 때 크리에이터에게만 숫자다. | 
**escrowAmount** | **int** | 결제할 때 에스크로에 맡긴 금액(원). 협업이 끝날 때까지 그대로이고, 결제 전이거나 식사권만 있으면 0. | 
**expectedRefund** | **int** | 예상 환급액(원). 집계 중일 때 사장님에게만 숫자다. | 
**extraRevisionsAllowed** | **int** | 브랜드가 더 허용한 수정 횟수. 기본 0. | 
**id** | **String** |  | 
**kind** | [**CollaborationKind**](CollaborationKind.md) |  | 
**nextAction** | [**CollaborationNextAction**](CollaborationNextAction.md) | 지금 내가 할 일. RESPOND_TERMS: 최신 조건 판본을 아직 확인하지 않음, SIGN_CONTRACT: 양쪽이 합의해 계약할 차례. 그 밖은 null. | 
**payoutScheduledFor** | [**DateTime**](DateTime.md) | 지급이 PENDING이고 계좌가 있을 때 송금할 지급일. 크리에이터에게만. | 
**payoutStatus** | [**PayoutStatus**](PayoutStatus.md) | NONE: 줄 돈이 없음(정산 전이거나 0원), NEEDS_ACCOUNT: 지급 계좌 등록이 필요함(크리에이터에게만), PENDING: 지급일을 기다림, DONE: 지급됨, FAILED: 송금 실패(운영팀이 확인). | 
**role** | [**CollaborationRole**](CollaborationRole.md) | 내 쪽. COMMISSIONER는 맡긴 쪽(사장님·브랜드), CREATOR는 크리에이터. | 
**securedAmount** | **int** | 이번 협업의 확보액(원) = 최신 조건 판본의 최대 현금 부담. 가게 오퍼이거나 판본이 없으면 null. | 
**settlement** | [**CollaborationSettlementModel**](CollaborationSettlementModel.md) | 정산이 확정된 뒤의 결과. 정산 전이거나(조회 자료 확인 전 포함) 식사권만 있으면 null. | 
**stage** | [**CollaborationStage**](CollaborationStage.md) |  | 
**steps** | [**List<CollaborationStepModel>**](CollaborationStepModel.md) | 가게 오퍼의 다섯 단계. 브랜드 계약은 빈 배열이고 brandProgress가 대신한다. | [default to const []]
**store** | [**StoreSummaryModel**](StoreSummaryModel.md) | 가게 오퍼의 가게. 브랜드 계약이거나 가게를 읽을 수 없으면 null. | 
**submitDueAt** | [**DateTime**](DateTime.md) | 링크 제출 기한(결제 뒤 14일). | 
**submittedUrl** | **String** |  | 
**terms** | [**OfferTermsModel**](OfferTermsModel.md) | 수락할 때의 조건(사본). 가게 오퍼에만 있고 브랜드 계약은 null이다(브랜드 계약의 조건은 조건 판본이 담는다). | 
**title** | **String** | 브랜드 계약의 제목(최신 조건 판본의 제목). 가게 오퍼이거나 판본이 없으면 null. | 
**viewReportStatus** | [**CollaborationViewReportStatus**](CollaborationViewReportStatus.md) | 조회 자료 확인 단계. NONE: 조회수 수당이 없거나 링크 제출 전, COUNTING: 집계 중, UNCONFIRMED: 계산이 나와 확인을 기다림, CONFIRMED: 확인됨, DISPUTED: 이의 중. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


