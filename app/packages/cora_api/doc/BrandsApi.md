# cora_api.api.BrandsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMyBrand**](BrandsApi.md#getmybrand) | **GET** /brands/me | 
[**upsertMyBrand**](BrandsApi.md#upsertmybrand) | **PUT** /brands/me | 


# **getMyBrand**
> BrandProfileModel getMyBrand()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BrandsApi();

try {
    final result = api_instance.getMyBrand();
    print(result);
} catch (e) {
    print('Exception when calling BrandsApi->getMyBrand: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BrandProfileModel**](BrandProfileModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **upsertMyBrand**
> BrandProfileModel upsertMyBrand(upsertBrandProfileDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = BrandsApi();
final upsertBrandProfileDto = UpsertBrandProfileDto(); // UpsertBrandProfileDto | 

try {
    final result = api_instance.upsertMyBrand(upsertBrandProfileDto);
    print(result);
} catch (e) {
    print('Exception when calling BrandsApi->upsertMyBrand: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **upsertBrandProfileDto** | [**UpsertBrandProfileDto**](UpsertBrandProfileDto.md)|  | 

### Return type

[**BrandProfileModel**](BrandProfileModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

