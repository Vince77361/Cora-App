# cora_api.model.UpsertCreatorProfileDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**cardHeadline** | **String** | 브랜드가 보는 카드의 한 줄. 이 요청은 전체 교체라서 비우거나 빠뜨리면 지운다. | [optional] 
**cardPhotoPath** | **String** | 브랜드가 보는 카드의 사진 경로. 이 요청은 전체 교체라서 비우거나 빠뜨리면 지운다. | [optional] 
**contentFocus** | **String** |  | [optional] 
**displayName** | **String** |  | 
**instagramHandle** | **String** | 영문, 숫자, 점, 밑줄. 앞의 @ 하나는 떼고 저장한다. | [optional] 
**photoPath** | **String** |  | [optional] 
**regionSido** | **String** | 시·도 고정 목록(SIDO_LIST) 중 하나. | 
**regionSigungu** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


