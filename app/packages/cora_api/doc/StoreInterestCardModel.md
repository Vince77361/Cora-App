# cora_api.model.StoreInterestCardModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**contentFocus** | **String** | 분야. | 
**creatorId** | **String** |  | 
**followers** | **int** | 인스타그램 팔로워 수. 연동하지 않았으면 null. | 
**headline** | **String** | 대표 게시물 1번의 한 줄. 게시물이 없거나 한 줄이 비었으면 null. 이상형 월드컵 카드가 쓴다. | 
**mutual** | **bool** | 서로 관심: 내가 하트를 보냈고 그 크리에이터가 이 가게에 살아 있는 지원(APPLIED·OFFERED)을 가졌다. 저장 탭에서는 늘 false다. | 
**name** | **String** | 크리에이터의 활동 이름. | 
**photoUrl** | **String** |  | 
**representativePhotoUrl** | **String** | 대표 게시물 1번의 사진(영상이면 썸네일). 없으면 null. photoUrl(프로필 사진)과 다르다. | 
**shortName** | **String** | \"{X}의 …\" 꼴이면 X, 아니면 이름 전체. 버튼 글자에 쓴다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


