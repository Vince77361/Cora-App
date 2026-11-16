# cora_api.api.PrinciplesApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMyPrinciples**](PrinciplesApi.md#getmyprinciples) | **GET** /creators/me/principles | 
[**upsertMyPrinciples**](PrinciplesApi.md#upsertmyprinciples) | **PUT** /creators/me/principles | 


# **getMyPrinciples**
> PrinciplesModel getMyPrinciples()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PrinciplesApi();

try {
    final result = api_instance.getMyPrinciples();
    print(result);
} catch (e) {
    print('Exception when calling PrinciplesApi->getMyPrinciples: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PrinciplesModel**](PrinciplesModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **upsertMyPrinciples**
> PrinciplesModel upsertMyPrinciples(upsertPrinciplesDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PrinciplesApi();
final upsertPrinciplesDto = UpsertPrinciplesDto(); // UpsertPrinciplesDto | 

try {
    final result = api_instance.upsertMyPrinciples(upsertPrinciplesDto);
    print(result);
} catch (e) {
    print('Exception when calling PrinciplesApi->upsertMyPrinciples: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **upsertPrinciplesDto** | [**UpsertPrinciplesDto**](UpsertPrinciplesDto.md)|  | 

### Return type

[**PrinciplesModel**](PrinciplesModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

