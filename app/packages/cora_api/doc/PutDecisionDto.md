# cora_api.model.PutDecisionDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**decision** | [**SwipeDecisionKind**](SwipeDecisionKind.md) |  | 
**note** | **Object** | LIKE에 붙이는 글. 크리에이터는 40자(조건 버전의 제목), 브랜드는 100자(좋아한 점). | [optional] 
**proposal** | [**BrandProposalDto**](BrandProposalDto.md) | 브랜드의 LIKE에만 붙인다(크리에이터가 보내면 400). 이미 LIKE인 결정에 다시 보내면 값만 덮어쓴다. | [optional] 
**targetId** | **String** | 크리에이터(사용자) 또는 캠페인의 id. | 
**targetKind** | [**DecisionTargetKind**](DecisionTargetKind.md) | 브랜드는 CREATOR만, 크리에이터는 CAMPAIGN만 보낸다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


