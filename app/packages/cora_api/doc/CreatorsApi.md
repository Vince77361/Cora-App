# cora_api.api.CreatorsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMyCreatorProfile**](CreatorsApi.md#getmycreatorprofile) | **GET** /creators/me | 
[**upsertMyCreatorProfile**](CreatorsApi.md#upsertmycreatorprofile) | **PUT** /creators/me | 


# **getMyCreatorProfile**
> CreatorProfileModel getMyCreatorProfile()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CreatorsApi();

try {
    final result = api_instance.getMyCreatorProfile();
    print(result);
} catch (e) {
    print('Exception when calling CreatorsApi->getMyCreatorProfile: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CreatorProfileModel**](CreatorProfileModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **upsertMyCreatorProfile**
> CreatorProfileModel upsertMyCreatorProfile(upsertCreatorProfileDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CreatorsApi();
final upsertCreatorProfileDto = UpsertCreatorProfileDto(); // UpsertCreatorProfileDto | 

try {
    final result = api_instance.upsertMyCreatorProfile(upsertCreatorProfileDto);
    print(result);
} catch (e) {
    print('Exception when calling CreatorsApi->upsertMyCreatorProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **upsertCreatorProfileDto** | [**UpsertCreatorProfileDto**](UpsertCreatorProfileDto.md)|  | 

### Return type

[**CreatorProfileModel**](CreatorProfileModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

