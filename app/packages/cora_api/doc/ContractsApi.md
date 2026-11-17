# cora_api.api.ContractsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**consentContractAsBrand**](ContractsApi.md#consentcontractasbrand) | **POST** /collaborations/{id}/contract/brand-consent | 브랜드가 계약에 동의하면서 결제를 시작한다. 크리에이터가 동의하기 전에는 409. 결제 금액은 계약 사본(최대 현금 부담 + 수수료)에서만 계산한다. 결제가 승인되는 순간 계약이 체결된다(CONTRACTED).
[**consentContractAsCreator**](ContractsApi.md#consentcontractascreator) | **POST** /collaborations/{id}/contract/creator-consent | 크리에이터가 계약에 동의한다(브랜드보다 먼저). 협업이 합의(AGREED) 상태이고 termsVersion이 최신일 때만: 최신이 아니면 409 STALE_VERSION(latestVersion), 그 밖의 상태는 409 CONFLICT, 확인한 문구가 서버의 문구와 다르면 400. 같은 판본에 다시 동의하면 바뀌는 것 없이 같은 계약을 돌려준다.
[**getContract**](ContractsApi.md#getcontract) | **GET** /collaborations/{id}/contract | 계약 화면(당사자만). 양쪽이 같은 판본을 확인하기 전(NOT_READY)에는 최신 판본과 문구를 미리 보기로 준다. 브랜드에게는 동의하면 결제할 금액(quote)이 함께 간다.


# **consentContractAsBrand**
> PaymentCreatedModel consentContractAsBrand(id, brandConsentDto)

브랜드가 계약에 동의하면서 결제를 시작한다. 크리에이터가 동의하기 전에는 409. 결제 금액은 계약 사본(최대 현금 부담 + 수수료)에서만 계산한다. 결제가 승인되는 순간 계약이 체결된다(CONTRACTED).

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContractsApi();
final id = id_example; // String | 
final brandConsentDto = BrandConsentDto(); // BrandConsentDto | 

try {
    final result = api_instance.consentContractAsBrand(id, brandConsentDto);
    print(result);
} catch (e) {
    print('Exception when calling ContractsApi->consentContractAsBrand: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **brandConsentDto** | [**BrandConsentDto**](BrandConsentDto.md)|  | 

### Return type

[**PaymentCreatedModel**](PaymentCreatedModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **consentContractAsCreator**
> ContractModel consentContractAsCreator(id, creatorConsentDto)

크리에이터가 계약에 동의한다(브랜드보다 먼저). 협업이 합의(AGREED) 상태이고 termsVersion이 최신일 때만: 최신이 아니면 409 STALE_VERSION(latestVersion), 그 밖의 상태는 409 CONFLICT, 확인한 문구가 서버의 문구와 다르면 400. 같은 판본에 다시 동의하면 바뀌는 것 없이 같은 계약을 돌려준다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContractsApi();
final id = id_example; // String | 
final creatorConsentDto = CreatorConsentDto(); // CreatorConsentDto | 

try {
    final result = api_instance.consentContractAsCreator(id, creatorConsentDto);
    print(result);
} catch (e) {
    print('Exception when calling ContractsApi->consentContractAsCreator: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **creatorConsentDto** | [**CreatorConsentDto**](CreatorConsentDto.md)|  | 

### Return type

[**ContractModel**](ContractModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getContract**
> ContractModel getContract(id)

계약 화면(당사자만). 양쪽이 같은 판본을 확인하기 전(NOT_READY)에는 최신 판본과 문구를 미리 보기로 준다. 브랜드에게는 동의하면 결제할 금액(quote)이 함께 간다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContractsApi();
final id = id_example; // String | 

try {
    final result = api_instance.getContract(id);
    print(result);
} catch (e) {
    print('Exception when calling ContractsApi->getContract: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ContractModel**](ContractModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

