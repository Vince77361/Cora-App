# cora_api.api.CampaignsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**closeCampaign**](CampaignsApi.md#closecampaign) | **POST** /campaigns/{id}/close | 
[**createCampaign**](CampaignsApi.md#createcampaign) | **POST** /campaigns | 
[**getMyActiveCampaign**](CampaignsApi.md#getmyactivecampaign) | **GET** /campaigns/mine/active | 
[**updateCampaign**](CampaignsApi.md#updatecampaign) | **PATCH** /campaigns/{id} | 


# **closeCampaign**
> CampaignModel closeCampaign(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CampaignsApi();
final id = id_example; // String | 

try {
    final result = api_instance.closeCampaign(id);
    print(result);
} catch (e) {
    print('Exception when calling CampaignsApi->closeCampaign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**CampaignModel**](CampaignModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createCampaign**
> CampaignModel createCampaign(createCampaignDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CampaignsApi();
final createCampaignDto = CreateCampaignDto(); // CreateCampaignDto | 

try {
    final result = api_instance.createCampaign(createCampaignDto);
    print(result);
} catch (e) {
    print('Exception when calling CampaignsApi->createCampaign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createCampaignDto** | [**CreateCampaignDto**](CreateCampaignDto.md)|  | 

### Return type

[**CampaignModel**](CampaignModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyActiveCampaign**
> CampaignModel getMyActiveCampaign()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CampaignsApi();

try {
    final result = api_instance.getMyActiveCampaign();
    print(result);
} catch (e) {
    print('Exception when calling CampaignsApi->getMyActiveCampaign: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CampaignModel**](CampaignModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateCampaign**
> CampaignModel updateCampaign(id, updateCampaignDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CampaignsApi();
final id = id_example; // String | 
final updateCampaignDto = UpdateCampaignDto(); // UpdateCampaignDto | 

try {
    final result = api_instance.updateCampaign(id, updateCampaignDto);
    print(result);
} catch (e) {
    print('Exception when calling CampaignsApi->updateCampaign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateCampaignDto** | [**UpdateCampaignDto**](UpdateCampaignDto.md)|  | 

### Return type

[**CampaignModel**](CampaignModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

