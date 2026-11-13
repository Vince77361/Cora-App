# cora_api.model.ProposalRowModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**collaborationId** | **String** | 합의해 만들어진 협업의 id. 합의 전이면 null. | 
**counter** | **bool** | 상대가 쓴 최신 판본이 번호 2 이상이면 true(역제안). | 
**counterpart** | [**ProposalCounterpartModel**](ProposalCounterpartModel.md) |  | 
**daysLeft** | **int** | 상대 대기(WAITING)일 때 남은 응답 기한(올림). 하루가 안 남았으면 0. 그 밖에는 null. | 
**endKind** | [**ProposalEndKind**](ProposalEndKind.md) | 끝난 제안(ENDED)의 갈래. AGREED: 합의 완료, ENDED: 사유를 골라 끝냄, EXPIRED: 기한이 지나 끝남. 그 밖에는 null. | 
**endReason** | [**OfferEndReason**](OfferEndReason.md) | 끝낸 쪽이 고른 사유. 사유 없이 끝났으면 null. | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**group** | [**ProposalGroup**](ProposalGroup.md) | MY_TURN: 내가 응답할 차례. WAITING: 상대 대기. ENDED: 끝난 제안. | 
**offerId** | **String** |  | 
**pieces** | **int** |  | 
**version** | **int** | 최신 판본의 번호. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


