# cora_api.model.StoreCreatorCardModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**contentFocus** | **String** | 콘텐츠 분야(크리에이터가 쓴 글). 없으면 null. | 
**creatorId** | **String** |  | 
**displayName** | **String** |  | 
**followers** | **int** | 연결한 인스타그램 계정의 팔로워 수. 연결이 없으면 null. | 
**headline** | **String** | 1번 대표 게시물의 한 줄. | 
**photoUrl** | **String** | 1번 대표 게시물의 그림. | 
**posts** | [**List<FeaturedPostModel>**](FeaturedPostModel.md) | 대표 게시물(1~4개, 차례대로). | [default to const []]
**tags** | **List<String>** | 협업 원칙의 꼬리표. 협업 원칙이 없으면 빈 목록. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


