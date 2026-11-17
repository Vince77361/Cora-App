# cora_api.api.BlocksApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**blockConversationMember**](BlocksApi.md#blockconversationmember) | **POST** /conversations/{id}/block | 이 방의 상대를 차단한다. 두 사람 사이의 모든 방이 닫히고 계약 전 협업이 끝난다. 상대에게는 알리지 않는다.


# **blockConversationMember**
> ConversationDetailModel blockConversationMember(id)

이 방의 상대를 차단한다. 두 사람 사이의 모든 방이 닫히고 계약 전 협업이 끝난다. 상대에게는 알리지 않는다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BlocksApi();
final id = id_example; // String | 

try {
    final result = api_instance.blockConversationMember(id);
    print(result);
} catch (e) {
    print('Exception when calling BlocksApi->blockConversationMember: $e\n');
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

