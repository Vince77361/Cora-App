# cora_api.api.StoresApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**advanceMyStoreOnboarding**](StoresApi.md#advancemystoreonboarding) | **POST** /stores/me/onboarding-step | 
[**analyzeMyStoreLinks**](StoresApi.md#analyzemystorelinks) | **POST** /stores/me/analyze | 
[**getMyStore**](StoresApi.md#getmystore) | **GET** /stores/me | 
[**getPublishedStore**](StoresApi.md#getpublishedstore) | **GET** /stores/{id} | 
[**listPublishedStores**](StoresApi.md#listpublishedstores) | **GET** /stores | 
[**publishMyStore**](StoresApi.md#publishmystore) | **POST** /stores/me/publish | 
[**setMyStoreDefaultTerms**](StoresApi.md#setmystoredefaultterms) | **PUT** /stores/me/default-terms | 
[**updateMyStore**](StoresApi.md#updatemystore) | **PATCH** /stores/me | 


# **advanceMyStoreOnboarding**
> MyStoreModel advanceMyStoreOnboarding(advanceOnboardingDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoresApi();
final advanceOnboardingDto = AdvanceOnboardingDto(); // AdvanceOnboardingDto | 

try {
    final result = api_instance.advanceMyStoreOnboarding(advanceOnboardingDto);
    print(result);
} catch (e) {
    print('Exception when calling StoresApi->advanceMyStoreOnboarding: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **advanceOnboardingDto** | [**AdvanceOnboardingDto**](AdvanceOnboardingDto.md)|  | 

### Return type

[**MyStoreModel**](MyStoreModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **analyzeMyStoreLinks**
> AnalyzeStoreLinksResultModel analyzeMyStoreLinks(analyzeLinksDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoresApi();
final analyzeLinksDto = AnalyzeLinksDto(); // AnalyzeLinksDto | 

try {
    final result = api_instance.analyzeMyStoreLinks(analyzeLinksDto);
    print(result);
} catch (e) {
    print('Exception when calling StoresApi->analyzeMyStoreLinks: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **analyzeLinksDto** | [**AnalyzeLinksDto**](AnalyzeLinksDto.md)|  | 

### Return type

[**AnalyzeStoreLinksResultModel**](AnalyzeStoreLinksResultModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyStore**
> MyStoreModel getMyStore()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoresApi();

try {
    final result = api_instance.getMyStore();
    print(result);
} catch (e) {
    print('Exception when calling StoresApi->getMyStore: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MyStoreModel**](MyStoreModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublishedStore**
> StoreDetailModel getPublishedStore(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoresApi();
final id = id_example; // String | 

try {
    final result = api_instance.getPublishedStore(id);
    print(result);
} catch (e) {
    print('Exception when calling StoresApi->getPublishedStore: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**StoreDetailModel**](StoreDetailModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPublishedStores**
> List<StoreSummaryModel> listPublishedStores()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoresApi();

try {
    final result = api_instance.listPublishedStores();
    print(result);
} catch (e) {
    print('Exception when calling StoresApi->listPublishedStores: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<StoreSummaryModel>**](StoreSummaryModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publishMyStore**
> MyStoreModel publishMyStore()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoresApi();

try {
    final result = api_instance.publishMyStore();
    print(result);
} catch (e) {
    print('Exception when calling StoresApi->publishMyStore: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MyStoreModel**](MyStoreModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setMyStoreDefaultTerms**
> MyStoreModel setMyStoreDefaultTerms(setDefaultTermsDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoresApi();
final setDefaultTermsDto = SetDefaultTermsDto(); // SetDefaultTermsDto | 

try {
    final result = api_instance.setMyStoreDefaultTerms(setDefaultTermsDto);
    print(result);
} catch (e) {
    print('Exception when calling StoresApi->setMyStoreDefaultTerms: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **setDefaultTermsDto** | [**SetDefaultTermsDto**](SetDefaultTermsDto.md)|  | 

### Return type

[**MyStoreModel**](MyStoreModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMyStore**
> MyStoreModel updateMyStore(updateStoreDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoresApi();
final updateStoreDto = UpdateStoreDto(); // UpdateStoreDto | 

try {
    final result = api_instance.updateMyStore(updateStoreDto);
    print(result);
} catch (e) {
    print('Exception when calling StoresApi->updateMyStore: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateStoreDto** | [**UpdateStoreDto**](UpdateStoreDto.md)|  | 

### Return type

[**MyStoreModel**](MyStoreModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

