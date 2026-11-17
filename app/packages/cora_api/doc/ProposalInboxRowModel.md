# cora_api.model.ProposalInboxRowModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**collaborationId** | **String** |  | 
**counter** | **bool** | 상대가 쓴 최신 판본이 번호 2 이상이면 true(역제안). | 
**counterpart** | [**ProposalCounterpartModel**](ProposalCounterpartModel.md) |  | 
**endKind** | [**ProposalEndKind**](ProposalEndKind.md) | 끝난 제안(ENDED)의 갈래. AGREED: 합의 완료, ENDED: 사유를 골라 끝냄, EXPIRED: 기한이 지나 끝남. 그 밖에는 null. | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**group** | [**ProposalGroup**](ProposalGroup.md) | MY_TURN: 내가 응답할 차례. WAITING: 상대 대기. ENDED: 끝난 제안. | 
**kind** | **String** |  | 
**myDropReason** | [**DropReasonChoice**](DropReasonChoice.md) | 그만두는 이유. 서버에만 남고 상대에게는 알리지 않는다(상대는 \"이번에는 함께하기 어렵대요.\"만 본다). | 
**pieces** | **int** |  | 
**updatedAt** | [**DateTime**](DateTime.md) | 최신 판본의 확인이나 협업 상태가 마지막으로 바뀐 시각. | 
**version** | **int** | 최신 판본의 번호. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


