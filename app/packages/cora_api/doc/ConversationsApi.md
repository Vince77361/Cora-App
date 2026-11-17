# cora_api.api.ConversationsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptMessageRequest**](ConversationsApi.md#acceptmessagerequest) | **POST** /conversations/{id}/request/accept | 메시지 요청을 수락해 대화를 연다. 받은 사람만. 협업은 INQUIRY에 남고, 요청을 보낸 사람에게 알린다.
[**declineMessageRequest**](ConversationsApi.md#declinemessagerequest) | **POST** /conversations/{id}/request/decline | 메시지 요청을 거절한다. 받은 사람만. 협업은 끝나 같은 캠페인으로 다시 요청할 수 없고, 상대에게 알리지 않는다.
[**getConversation**](ConversationsApi.md#getconversation) | **GET** /conversations/{id} | 방 머리: 상대, 협업 단계, 조건, 내가 할 수 있는 일.
[**listConversations**](ConversationsApi.md#listconversations) | **GET** /conversations | 내 대화 목록. 답해야 하는 메시지 요청이 먼저, 다음은 마지막 메시지가 최근인 순. 내가 거절한 요청은 빠진다.
[**listMessages**](ConversationsApi.md#listmessages) | **GET** /conversations/{id}/messages | 메시지를 번호 오름차순으로. afterSeq(빠진 번호 받기)나 beforeSeq(위로 넘기기)를 주고, 둘 다 없으면 마지막 50개.
[**markConversationRead**](ConversationsApi.md#markconversationread) | **POST** /conversations/{id}/read | 여기까지 읽었다고 알린다. 읽은 번호는 줄어들지 않는다.
[**sendMessage**](ConversationsApi.md#sendmessage) | **POST** /conversations/{id}/messages | 글이나 콘텐츠 카드를 보낸다. 같은 clientId로 다시 보내면 첫 메시지를 돌려준다. 열린 방에만 보낼 수 있다.
[**setConversationMuted**](ConversationsApi.md#setconversationmuted) | **PUT** /conversations/{id}/mute | 이 방의 알림을 끄거나 켠다.


# **acceptMessageRequest**
> ConversationDetailModel acceptMessageRequest(id)

메시지 요청을 수락해 대화를 연다. 받은 사람만. 협업은 INQUIRY에 남고, 요청을 보낸 사람에게 알린다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConversationsApi();
final id = id_example; // String | 

try {
    final result = api_instance.acceptMessageRequest(id);
    print(result);
} catch (e) {
    print('Exception when calling ConversationsApi->acceptMessageRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ConversationDetailModel**](ConversationDetailModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **declineMessageRequest**
> declineMessageRequest(id)

메시지 요청을 거절한다. 받은 사람만. 협업은 끝나 같은 캠페인으로 다시 요청할 수 없고, 상대에게 알리지 않는다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConversationsApi();
final id = id_example; // String | 

try {
    api_instance.declineMessageRequest(id);
} catch (e) {
    print('Exception when calling ConversationsApi->declineMessageRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getConversation**
> ConversationDetailModel getConversation(id)

방 머리: 상대, 협업 단계, 조건, 내가 할 수 있는 일.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConversationsApi();
final id = id_example; // String | 

try {
    final result = api_instance.getConversation(id);
    print(result);
} catch (e) {
    print('Exception when calling ConversationsApi->getConversation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ConversationDetailModel**](ConversationDetailModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listConversations**
> List<ConversationSummaryModel> listConversations()

내 대화 목록. 답해야 하는 메시지 요청이 먼저, 다음은 마지막 메시지가 최근인 순. 내가 거절한 요청은 빠진다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConversationsApi();

try {
    final result = api_instance.listConversations();
    print(result);
} catch (e) {
    print('Exception when calling ConversationsApi->listConversations: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<ConversationSummaryModel>**](ConversationSummaryModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMessages**
> List<MessageModel> listMessages(id, afterSeq, beforeSeq, limit)

메시지를 번호 오름차순으로. afterSeq(빠진 번호 받기)나 beforeSeq(위로 넘기기)를 주고, 둘 다 없으면 마지막 50개.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConversationsApi();
final id = id_example; // String | 
final afterSeq = 56; // int | 이 번호보다 큰 메시지(빠진 번호를 받을 때).
final beforeSeq = 56; // int | 이 번호보다 작은 메시지(위로 넘겨 볼 때).
final limit = 56; // int | 

try {
    final result = api_instance.listMessages(id, afterSeq, beforeSeq, limit);
    print(result);
} catch (e) {
    print('Exception when calling ConversationsApi->listMessages: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **afterSeq** | **int**| 이 번호보다 큰 메시지(빠진 번호를 받을 때). | [optional] 
 **beforeSeq** | **int**| 이 번호보다 작은 메시지(위로 넘겨 볼 때). | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**List<MessageModel>**](MessageModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markConversationRead**
> markConversationRead(id, markReadDto)

여기까지 읽었다고 알린다. 읽은 번호는 줄어들지 않는다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConversationsApi();
final id = id_example; // String | 
final markReadDto = MarkReadDto(); // MarkReadDto | 

try {
    api_instance.markConversationRead(id, markReadDto);
} catch (e) {
    print('Exception when calling ConversationsApi->markConversationRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **markReadDto** | [**MarkReadDto**](MarkReadDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendMessage**
> MessageModel sendMessage(id, sendMessageDto)

글이나 콘텐츠 카드를 보낸다. 같은 clientId로 다시 보내면 첫 메시지를 돌려준다. 열린 방에만 보낼 수 있다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConversationsApi();
final id = id_example; // String | 
final sendMessageDto = SendMessageDto(); // SendMessageDto | 

try {
    final result = api_instance.sendMessage(id, sendMessageDto);
    print(result);
} catch (e) {
    print('Exception when calling ConversationsApi->sendMessage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **sendMessageDto** | [**SendMessageDto**](SendMessageDto.md)|  | 

### Return type

[**MessageModel**](MessageModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setConversationMuted**
> MutedModel setConversationMuted(id, setMutedDto)

이 방의 알림을 끄거나 켠다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConversationsApi();
final id = id_example; // String | 
final setMutedDto = SetMutedDto(); // SetMutedDto | 

try {
    final result = api_instance.setConversationMuted(id, setMutedDto);
    print(result);
} catch (e) {
    print('Exception when calling ConversationsApi->setConversationMuted: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **setMutedDto** | [**SetMutedDto**](SetMutedDto.md)|  | 

### Return type

[**MutedModel**](MutedModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

