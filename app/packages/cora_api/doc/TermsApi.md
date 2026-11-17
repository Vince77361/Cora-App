# cora_api.api.TermsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**confirmTerms**](TermsApi.md#confirmterms) | **POST** /collaborations/{id}/terms/{version}/confirm | 이 판본 수락. 최신이 아니면 409 STALE_VERSION(본문에 latestVersion), 성과 추가가 있는데 인스타그램 연동이 없으면 크리에이터는 409.
[**getLatestTerms**](TermsApi.md#getlatestterms) | **GET** /collaborations/{id}/terms/latest | 브랜드 계약의 가장 최근 조건 판본(당사자만).
[**listTermsVersions**](TermsApi.md#listtermsversions) | **GET** /collaborations/{id}/terms | 조건 판본 이력(당사자만). 최신이 먼저이고 판본마다 바뀐 항목을 담는다. agreement는 최신 판본의 확인 상태, editable은 지금 수정 제안을 낼 수 있는가.
[**proposeReward**](TermsApi.md#proposereward) | **POST** /collaborations/{id}/terms | 새 판본을 낸다(조건 수정 제안). 빠진 항목은 직전 판본에서 옮기고 성과 추가는 null이면 끈다. 낸 쪽은 확인함이고 단계는 협의가 되며 크리에이터의 계약 동의는 취소된다. 최신 판본이 아니면 409 STALE_VERSION, 브랜드 결제가 진행 중이면 409, 바뀐 것이 없으면 400.


# **confirmTerms**
> TermsVersionModel confirmTerms(id, version)

이 판본 수락. 최신이 아니면 409 STALE_VERSION(본문에 latestVersion), 성과 추가가 있는데 인스타그램 연동이 없으면 크리에이터는 409.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TermsApi();
final id = id_example; // String | 
final version = 8.14; // num | 

try {
    final result = api_instance.confirmTerms(id, version);
    print(result);
} catch (e) {
    print('Exception when calling TermsApi->confirmTerms: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **version** | **num**|  | 

### Return type

[**TermsVersionModel**](TermsVersionModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLatestTerms**
> TermsLatestModel getLatestTerms(id)

브랜드 계약의 가장 최근 조건 판본(당사자만).

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TermsApi();
final id = id_example; // String | 

try {
    final result = api_instance.getLatestTerms(id);
    print(result);
} catch (e) {
    print('Exception when calling TermsApi->getLatestTerms: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**TermsLatestModel**](TermsLatestModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listTermsVersions**
> TermsHistoryModel listTermsVersions(id)

조건 판본 이력(당사자만). 최신이 먼저이고 판본마다 바뀐 항목을 담는다. agreement는 최신 판본의 확인 상태, editable은 지금 수정 제안을 낼 수 있는가.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TermsApi();
final id = id_example; // String | 

try {
    final result = api_instance.listTermsVersions(id);
    print(result);
} catch (e) {
    print('Exception when calling TermsApi->listTermsVersions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**TermsHistoryModel**](TermsHistoryModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **proposeReward**
> TermsVersionModel proposeReward(id, proposeRewardDto)

새 판본을 낸다(조건 수정 제안). 빠진 항목은 직전 판본에서 옮기고 성과 추가는 null이면 끈다. 낸 쪽은 확인함이고 단계는 협의가 되며 크리에이터의 계약 동의는 취소된다. 최신 판본이 아니면 409 STALE_VERSION, 브랜드 결제가 진행 중이면 409, 바뀐 것이 없으면 400.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TermsApi();
final id = id_example; // String | 
final proposeRewardDto = ProposeRewardDto(); // ProposeRewardDto | 

try {
    final result = api_instance.proposeReward(id, proposeRewardDto);
    print(result);
} catch (e) {
    print('Exception when calling TermsApi->proposeReward: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **proposeRewardDto** | [**ProposeRewardDto**](ProposeRewardDto.md)|  | 

### Return type

[**TermsVersionModel**](TermsVersionModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

