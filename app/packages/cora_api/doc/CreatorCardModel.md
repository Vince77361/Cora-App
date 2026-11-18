# cora_api.model.CreatorCardModel

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
**photoUrl** | **String** |  | 
**posts** | [**List<FeaturedPostModel>**](FeaturedPostModel.md) | 대표 게시물(최대 4개, 차례대로). 없으면 빈 목록이고 이때 photoUrl이 프로필 사진이다. | [default to const []]
**reasons** | [**List<MatchReason>**](MatchReason.md) | 크리에이터의 협업 원칙과 겹치는 규칙. 많을수록 잘 맞는다. | [default to const []]
**tags** | **List<String>** |  | [default to const []]
**theyLikedMe** | **bool** | 항상 false. 상대가 먼저 관심을 보냈는지는 미리 알려 주지 않고, 순서에만 쓴다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


