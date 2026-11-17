# cora_api.model.SendMessageDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**clientId** | **String** | 앱이 만든 중복 방지 값. 같은 값으로 다시 보내면 새 메시지를 만들지 않고 첫 메시지를 돌려준다. | 
**kind** | [**SendableMessageKind**](SendableMessageKind.md) | CONTENT_CARD는 크리에이터만 보낼 수 있다. | 
**text** | **String** | 글 메시지의 글(1~1000자). 콘텐츠 카드에는 쓰지 않는다. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


