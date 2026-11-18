# cora_api.model.FeaturedPostInputDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**caption** | **Object** | 한 줄 설명. 사진첩 게시물은 필수. | [optional] 
**id** | **String** | 내 대표 게시물의 ID. 이것만 보내면 기존 게시물을 그대로 두고 이 차례에 놓는다. | [optional] 
**instagramMediaId** | **Object** |  | [optional] 
**kind** | [**FeaturedPostKind**](FeaturedPostKind.md) |  | [optional] 
**mediaPath** | **String** | 올린 파일의 경로. 사진첩은 POST /uploads/photos(FEATURED_POST)가 준 경로, 인스타그램은 가져오기가 준 경로. | [optional] 
**source_** | [**FeaturedPostSource**](FeaturedPostSource.md) |  | [optional] 
**thumbnailPath** | **Object** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


