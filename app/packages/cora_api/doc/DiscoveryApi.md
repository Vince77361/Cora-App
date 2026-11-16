# cora_api.api.DiscoveryApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**putDecision**](DiscoveryApi.md#putdecision) | **PUT** /discovery/decisions | 관심·넘김·보류를 저장한다. 반대쪽도 관심이면 서로 관심(협업과 조건 버전 1)이 만들어진다.
[**putPassReason**](DiscoveryApi.md#putpassreason) | **PUT** /discovery/decisions/pass-reason | 넘긴 카드에 이유를 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.
[**putStorePass**](DiscoveryApi.md#putstorepass) | **PUT** /discovery/store-passes/{storeId} | 가게 카드를 넘긴다(가게 카드의 관심은 지원 API로 보낸다).
[**undoLastDecision**](DiscoveryApi.md#undolastdecision) | **DELETE** /discovery/decisions/last | 오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다.


# **putDecision**
> DecisionResultModel putDecision(putDecisionDto)

관심·넘김·보류를 저장한다. 반대쪽도 관심이면 서로 관심(협업과 조건 버전 1)이 만들어진다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final putDecisionDto = PutDecisionDto(); // PutDecisionDto | 

try {
    final result = api_instance.putDecision(putDecisionDto);
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->putDecision: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **putDecisionDto** | [**PutDecisionDto**](PutDecisionDto.md)|  | 

### Return type

[**DecisionResultModel**](DecisionResultModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putPassReason**
> putPassReason(passReasonDto)

넘긴 카드에 이유를 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final passReasonDto = PassReasonDto(); // PassReasonDto | 

try {
    api_instance.putPassReason(passReasonDto);
} catch (e) {
    print('Exception when calling DiscoveryApi->putPassReason: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **passReasonDto** | [**PassReasonDto**](PassReasonDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putStorePass**
> putStorePass(storeId)

가게 카드를 넘긴다(가게 카드의 관심은 지원 API로 보낸다).

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final storeId = storeId_example; // String | 

try {
    api_instance.putStorePass(storeId);
} catch (e) {
    print('Exception when calling DiscoveryApi->putStorePass: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **storeId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **undoLastDecision**
> UndoneDecisionModel undoLastDecision()

오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();

try {
    final result = api_instance.undoLastDecision();
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->undoLastDecision: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UndoneDecisionModel**](UndoneDecisionModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

