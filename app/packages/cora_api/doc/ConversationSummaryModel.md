# cora_api.model.ConversationSummaryModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**contextLabel** | **String** | 캠페인 한 줄 또는 가게 이름. | 
**counterpart** | [**ConversationCounterpartModel**](ConversationCounterpartModel.md) |  | 
**id** | **String** |  | 
**kind** | [**CollaborationKind**](CollaborationKind.md) |  | 
**lastMessage** | [**ConversationLastMessageModel**](ConversationLastMessageModel.md) |  | 
**muted** | **bool** | 이 방의 알림을 꺼 두었으면 true. | 
**section** | [**ConversationSection**](ConversationSection.md) | REQUEST: 내가 답해야 하는 메시지 요청(목록 맨 위에 모인다). 그 밖은 NORMAL. | 
**status** | [**ConversationStatus**](ConversationStatus.md) |  | 
**unreadCount** | **int** | 내 읽은 번호 뒤에 상대나 안내로 온 메시지의 수. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


