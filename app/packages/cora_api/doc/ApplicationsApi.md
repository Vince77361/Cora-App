# cora_api.api.ApplicationsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**applyToStore**](ApplicationsApi.md#applytostore) | **POST** /stores/{id}/applications | 
[**cancelMyApplication**](ApplicationsApi.md#cancelmyapplication) | **DELETE** /stores/{id}/applications/mine | 
[**listMyStoreApplicants**](ApplicationsApi.md#listmystoreapplicants) | **GET** /stores/me/applications | 
[**listRecommendedApplicants**](ApplicationsApi.md#listrecommendedapplicants) | **GET** /stores/me/applications/recommended | 
[**skipRecommendedApplicant**](ApplicationsApi.md#skiprecommendedapplicant) | **POST** /stores/me/applications/{id}/skip | 


# **applyToStore**
> ApplicationModel applyToStore(id, applyDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final id = id_example; // String | 
final applyDto = ApplyDto(); // ApplyDto | 

try {
    final result = api_instance.applyToStore(id, applyDto);
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->applyToStore: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **applyDto** | [**ApplyDto**](ApplyDto.md)|  | 

### Return type

[**ApplicationModel**](ApplicationModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cancelMyApplication**
> cancelMyApplication(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final id = id_example; // String | 

try {
    api_instance.cancelMyApplication(id);
} catch (e) {
    print('Exception when calling ApplicationsApi->cancelMyApplication: $e\n');
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

# **listMyStoreApplicants**
> List<ApplicantModel> listMyStoreApplicants()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();

try {
    final result = api_instance.listMyStoreApplicants();
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->listMyStoreApplicants: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<ApplicantModel>**](ApplicantModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRecommendedApplicants**
> RecommendedApplicantsModel listRecommendedApplicants()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();

try {
    final result = api_instance.listRecommendedApplicants();
    print(result);
} catch (e) {
    print('Exception when calling ApplicationsApi->listRecommendedApplicants: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**RecommendedApplicantsModel**](RecommendedApplicantsModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **skipRecommendedApplicant**
> skipRecommendedApplicant(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ApplicationsApi();
final id = id_example; // String | 

try {
    api_instance.skipRecommendedApplicant(id);
} catch (e) {
    print('Exception when calling ApplicationsApi->skipRecommendedApplicant: $e\n');
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

