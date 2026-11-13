# cora_api.api.CreatorsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createMyCreatorSeries**](CreatorsApi.md#createmycreatorseries) | **POST** /creators/me/series | 
[**getMyCreatorProfile**](CreatorsApi.md#getmycreatorprofile) | **GET** /creators/me | 
[**listMyCreatorSeries**](CreatorsApi.md#listmycreatorseries) | **GET** /creators/me/series | 
[**upsertMyCreatorProfile**](CreatorsApi.md#upsertmycreatorprofile) | **PUT** /creators/me | 


# **createMyCreatorSeries**
> CreatorSeriesModel createMyCreatorSeries(createCreatorSeriesDto)



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
final createCreatorSeriesDto = CreateCreatorSeriesDto(); // CreateCreatorSeriesDto | 

try {
    final result = api_instance.createMyCreatorSeries(createCreatorSeriesDto);
    print(result);
} catch (e) {
    print('Exception when calling CreatorsApi->createMyCreatorSeries: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createCreatorSeriesDto** | [**CreateCreatorSeriesDto**](CreateCreatorSeriesDto.md)|  | 

### Return type

[**CreatorSeriesModel**](CreatorSeriesModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

# **listMyCreatorSeries**
> List<CreatorSeriesModel> listMyCreatorSeries()



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
    final result = api_instance.listMyCreatorSeries();
    print(result);
} catch (e) {
    print('Exception when calling CreatorsApi->listMyCreatorSeries: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<CreatorSeriesModel>**](CreatorSeriesModel.md)

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

