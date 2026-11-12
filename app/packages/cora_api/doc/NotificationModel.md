# cora_api.model.NotificationModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**actor** | [**NotificationActorModel**](NotificationActorModel.md) |  | 
**createdAt** | [**DateTime**](DateTime.md) | 만든 시각(ISO 8601). | 
**glyph** | [**NotificationGlyph**](NotificationGlyph.md) | 글자 그림. 정산은 WON(₩), 없으면 상대 사진. | 
**id** | **String** |  | 
**read** | **bool** |  | 
**tab** | [**NotificationTab**](NotificationTab.md) |  | 
**target** | [**NotificationTargetModel**](NotificationTargetModel.md) |  | 
**text** | **String** | 종류와 값으로 만든 문구(카탈로그의 render). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


