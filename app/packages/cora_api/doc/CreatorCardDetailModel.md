# cora_api.model.CreatorCardDetailModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**creatorId** | **String** |  | 
**displayName** | **String** |  | 
**feeBand** | [**FeeBand**](FeeBand.md) |  | 
**headline** | **String** |  | 
**instagramHandle** | **String** |  | 
**myDecision** | [**SavedDecision**](SavedDecision.md) | 내가 저장한 결정(관심 또는 보류). 결정하지 않았으면 null. 넘긴 카드는 상세가 404라서 PASS는 나오지 않는다. | 
**photoUrl** | **String** |  | 
**reasons** | [**List<MatchReason>**](MatchReason.md) | 크리에이터의 협업 원칙과 겹치는 규칙. 많을수록 잘 맞는다. | [default to const []]
**tags** | **List<String>** |  | [default to const []]
**theyLikedMe** | **bool** | 항상 false. 상대가 먼저 관심을 보냈는지는 미리 알려 주지 않고, 순서에만 쓴다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


