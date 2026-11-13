# cora_api.api.StoreResultApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getStoreResult**](StoreResultApi.md#getstoreresult) | **GET** /collaborations/{id}/result | 사장님의 7일 결과(G1). 끝난 협업의 지급·환불과 평소 조회수 대비 배수를 돌려준다.


# **getStoreResult**
> StoreResultModel getStoreResult(id)

사장님의 7일 결과(G1). 끝난 협업의 지급·환불과 평소 조회수 대비 배수를 돌려준다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoreResultApi();
final id = id_example; // String | 

try {
    final result = api_instance.getStoreResult(id);
    print(result);
} catch (e) {
    print('Exception when calling StoreResultApi->getStoreResult: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**StoreResultModel**](StoreResultModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

