# cora_api.model.ProposalDetailModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**changed** | **List<String>** | 앞 판본과 달라진 항목(FORMAT, VOUCHER, FIXED_CASH, VIEW_PAY, USAGE_RIGHTS, IDEA, PRINCIPLES, SERIES). 화면이 보여 주는 순서다. | [default to const []]
**collaborationId** | **String** |  | 
**counterpart** | [**ProposalPersonModel**](ProposalPersonModel.md) | 상대. 사장님에게는 크리에이터, 크리에이터에게는 가게의 사장님이다(이름과 사진은 가게의 것). | 
**endKind** | [**ProposalEndKind**](ProposalEndKind.md) |  | 
**endReason** | [**OfferEndReason**](OfferEndReason.md) |  | 
**expiresAt** | [**DateTime**](DateTime.md) | 응답 기한(ISO 8601). | 
**feeRate** | **int** | 결제 때 더해지는 수수료율(%). | 
**group** | [**ProposalGroup**](ProposalGroup.md) |  | 
**latest** | [**OfferVersionModel**](OfferVersionModel.md) |  | 
**myParty** | [**OfferParty**](OfferParty.md) | 이 제안에서 나는 어느 쪽인가. | 
**needsInstagram** | **bool** | 답을 기다리는 제안이고 조회수 수당이 켜져 있는데 크리에이터가 인스타그램을 연동하지 않았으면 true. | 
**offerId** | **String** |  | 
**previous** | [**OfferVersionModel**](OfferVersionModel.md) | 바로 앞 판본. 첫 판본이면 null. | 
**status** | [**OfferView**](OfferView.md) | 내가 보는 상태. 크리에이터가 방금 거절해 되돌릴 수 있는 동안 사장님에게는 WAITING이다. | 
**store** | [**ProposalStoreModel**](ProposalStoreModel.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


