# cora_api.model.MessageModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**card** | [**MessageCardModel**](MessageCardModel.md) |  | 
**clientId** | **String** | 앱이 보낸 중복 방지 값. 내가 보낸 메시지에만 있다. | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**id** | **String** |  | 
**kind** | [**MessageKind**](MessageKind.md) |  | 
**mine** | **bool** | 내가 보낸 메시지이면 true. 안내 줄은 false. | 
**seq** | **int** | 방 안의 번호(1부터, 빠짐없이 늘어난다). | 
**text** | **String** | 글 메시지의 글, 안내 줄은 읽는 사람에 맞춰 서버가 만든 문구. 콘텐츠 카드는 null. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


