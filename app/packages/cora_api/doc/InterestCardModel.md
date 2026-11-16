# cora_api.model.InterestCardModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**collaborationId** | **String** | 서로 관심이면 그 협업의 id. | 
**feeBand** | [**FeeBand**](FeeBand.md) | 브랜드가 볼 때 그 크리에이터의 희망 제작비 구간. 크리에이터가 볼 때는 null. | 
**feeLabel** | **int** | 카드 아래 글의 금액. 서로 관심이면 최신 판본의 제작비, 아니면 브랜드는 내가 만든 제안의 금액(없으면 null이고 앱이 feeBand를 보여 준다), 크리에이터는 캠페인의 제작비. | 
**hasProposal** | **bool** | 내가 보낸 관심에 제안(제작비, 혜택, 성과 추가)이 붙어 있다. 브랜드만 true일 수 있다. | 
**headline** | **String** | 크리에이터 카드의 한 줄 또는 캠페인 한 줄. | 
**name** | **String** | 크리에이터의 활동 이름 또는 브랜드 이름. | 
**photoUrl** | **String** |  | 
**shortName** | **String** | \"{X}의 …\" 꼴이면 X, 아니면 이름 전체. 04의 버튼에 쓴다. | 
**startFrom** | [**DateTime**](DateTime.md) | 서로 관심일 때만 최신 판본의 제작 시작. 아니면 null(일정 협의). | 
**state** | [**InterestState**](InterestState.md) |  | 
**targetId** | **String** |  | 
**targetKind** | [**SwipeTargetKind**](SwipeTargetKind.md) | 브랜드는 CREATOR, 크리에이터는 CAMPAIGN. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


