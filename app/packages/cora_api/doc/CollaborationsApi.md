# cora_api.api.CollaborationsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptCollaborationCancel**](CollaborationsApi.md#acceptcollaborationcancel) | **POST** /collaborations/{id}/cancel-requests/{requestId}/accept | 크리에이터가 사장님의 취소 요청에 동의한다(직접 그만두는 것과 같은 처리).
[**cancelCollaboration**](CollaborationsApi.md#cancelcollaboration) | **POST** /collaborations/{id}/cancel | 크리에이터가 링크를 제출하기 전에 협업을 그만둔다(수수료까지 전액 환급).
[**getCollaboration**](CollaborationsApi.md#getcollaboration) | **GET** /collaborations/{id} | 
[**listCollaborations**](CollaborationsApi.md#listcollaborations) | **GET** /collaborations | 
[**requestCollaborationCancel**](CollaborationsApi.md#requestcollaborationcancel) | **POST** /collaborations/{id}/cancel-requests | 사장님이 취소를 요청한다. 3일 안에 답이 없으면 사라진다.


# **acceptCollaborationCancel**
> CollaborationModel acceptCollaborationCancel(id, requestId)

크리에이터가 사장님의 취소 요청에 동의한다(직접 그만두는 것과 같은 처리).

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CollaborationsApi();
final id = id_example; // String | 
final requestId = requestId_example; // String | 

try {
    final result = api_instance.acceptCollaborationCancel(id, requestId);
    print(result);
} catch (e) {
    print('Exception when calling CollaborationsApi->acceptCollaborationCancel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **requestId** | **String**|  | 

### Return type

[**CollaborationModel**](CollaborationModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cancelCollaboration**
> CollaborationModel cancelCollaboration(id)

크리에이터가 링크를 제출하기 전에 협업을 그만둔다(수수료까지 전액 환급).

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CollaborationsApi();
final id = id_example; // String | 

try {
    final result = api_instance.cancelCollaboration(id);
    print(result);
} catch (e) {
    print('Exception when calling CollaborationsApi->cancelCollaboration: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**CollaborationModel**](CollaborationModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCollaboration**
> CollaborationModel getCollaboration(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CollaborationsApi();
final id = id_example; // String | 

try {
    final result = api_instance.getCollaboration(id);
    print(result);
} catch (e) {
    print('Exception when calling CollaborationsApi->getCollaboration: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**CollaborationModel**](CollaborationModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listCollaborations**
> List<CollaborationModel> listCollaborations(scope)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CollaborationsApi();
final scope = ; // CollaborationScope | active: 진행 중(결제 대기·보관 중·집계 중·멈춤 등). done: 끝난 협업(정산 완료·환급·취소·중단). 최근 것부터.

try {
    final result = api_instance.listCollaborations(scope);
    print(result);
} catch (e) {
    print('Exception when calling CollaborationsApi->listCollaborations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | [**CollaborationScope**](.md)| active: 진행 중(결제 대기·보관 중·집계 중·멈춤 등). done: 끝난 협업(정산 완료·환급·취소·중단). 최근 것부터. | 

### Return type

[**List<CollaborationModel>**](CollaborationModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestCollaborationCancel**
> CollaborationModel requestCollaborationCancel(id)

사장님이 취소를 요청한다. 3일 안에 답이 없으면 사라진다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CollaborationsApi();
final id = id_example; // String | 

try {
    final result = api_instance.requestCollaborationCancel(id);
    print(result);
} catch (e) {
    print('Exception when calling CollaborationsApi->requestCollaborationCancel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**CollaborationModel**](CollaborationModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

