# cora_api.model.InstagramPostModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**caption** | **String** | 게시물 글 전체. | 
**durationSec** | **int** | 영상 길이(초). 사진이거나 모르면 null. 60초를 넘으면 가져올 수 없다. | 
**id** | **String** | 인스타그램 게시물 ID. | 
**kind** | [**FeaturedPostKind**](FeaturedPostKind.md) |  | 
**sizeBytes** | **int** | 영상 파일 크기(바이트). 사진이거나 모르면 null. 100MB를 넘으면 가져올 수 없다. | 
**thumbnailUrl** | **String** | 격자에 보일 그림의 주소. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


