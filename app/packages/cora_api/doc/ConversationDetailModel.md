# cora_api.model.ConversationDetailModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**blockedByMe** | **bool** | 내가 이 상대를 차단했으면 true. | 
**campaignTerms** | [**CampaignTermsModel**](CampaignTermsModel.md) | 서로 관심 전(INQUIRY)의 캠페인 조건. 그 밖은 null. | 
**canDrop** | **bool** | 협의를 그만둘 수 있는 단계이면 true. | 
**canLikeCampaign** | **bool** | 서로 관심 전, 크리에이터가 캠페인에 관심을 보낼 수 있으면 true. | 
**canProposeTerms** | **bool** | 조건 수정 제안을 보낼 수 있는 단계이면 true. | 
**canSend** | **bool** | 지금 글을 보낼 수 있으면 true(방이 열려 있다). | 
**canSendContentCard** | **bool** | 크리에이터가 콘텐츠 카드를 보낼 수 있으면 true(카드가 있다). | 
**collaborationId** | **String** |  | 
**contextLabel** | **String** | 캠페인 한 줄 또는 가게 이름. | 
**contractStatus** | [**ContractProgress**](ContractProgress.md) | NONE: 계약 동의 전, AWAITING_BRAND: 크리에이터가 동의해 브랜드 결제 대기, CONCLUDED: 체결. | 
**counterpart** | [**ConversationCounterpartModel**](ConversationCounterpartModel.md) |  | 
**id** | **String** |  | 
**kind** | [**CollaborationKind**](CollaborationKind.md) |  | 
**lastMessage** | [**ConversationLastMessageModel**](ConversationLastMessageModel.md) |  | 
**lastReadSeq** | **int** |  | 
**lastSeq** | **int** |  | 
**muted** | **bool** | 이 방의 알림을 꺼 두었으면 true. | 
**myRole** | [**CollaborationRole**](CollaborationRole.md) | 내 쪽. COMMISSIONER는 맡긴 쪽(사장님·브랜드), CREATOR는 크리에이터. | 
**requestedByMe** | **bool** | 내가 먼저 보낸 메시지 요청이면 true. | 
**section** | [**ConversationSection**](ConversationSection.md) | REQUEST: 내가 답해야 하는 메시지 요청(목록 맨 위에 모인다). 그 밖은 NORMAL. | 
**stage** | [**CollaborationStage**](CollaborationStage.md) |  | 
**status** | [**ConversationStatus**](ConversationStatus.md) |  | 
**storeTerms** | [**OfferTermsModel**](OfferTermsModel.md) | 가게 오퍼의 수락된 판본의 조건(사본). 브랜드 계약은 null. | 
**terms** | [**TermsVersionModel**](TermsVersionModel.md) | 브랜드 계약의 최신 조건 버전. 아직 없으면 null. | 
**unreadCount** | **int** | 내 읽은 번호 뒤에 상대나 안내로 온 메시지의 수. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


