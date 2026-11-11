# cora_api.api.InstagramApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**beginInstagramConnect**](InstagramApi.md#begininstagramconnect) | **POST** /instagram/connect | 
[**completeInstagramConnect**](InstagramApi.md#completeinstagramconnect) | **POST** /instagram/connect/complete | 
[**disconnectInstagram**](InstagramApi.md#disconnectinstagram) | **DELETE** /instagram/connection | 
[**getInstagramConnection**](InstagramApi.md#getinstagramconnection) | **GET** /instagram/connection | 


# **beginInstagramConnect**
> InstagramConnectUrlModel beginInstagramConnect()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = InstagramApi();

try {
    final result = api_instance.beginInstagramConnect();
    print(result);
} catch (e) {
    print('Exception when calling InstagramApi->beginInstagramConnect: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**InstagramConnectUrlModel**](InstagramConnectUrlModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **completeInstagramConnect**
> InstagramConnectionModel completeInstagramConnect(completeInstagramConnectDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = InstagramApi();
final completeInstagramConnectDto = CompleteInstagramConnectDto(); // CompleteInstagramConnectDto | 

try {
    final result = api_instance.completeInstagramConnect(completeInstagramConnectDto);
    print(result);
} catch (e) {
    print('Exception when calling InstagramApi->completeInstagramConnect: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **completeInstagramConnectDto** | [**CompleteInstagramConnectDto**](CompleteInstagramConnectDto.md)|  | 

### Return type

[**InstagramConnectionModel**](InstagramConnectionModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **disconnectInstagram**
> disconnectInstagram()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = InstagramApi();

try {
    api_instance.disconnectInstagram();
} catch (e) {
    print('Exception when calling InstagramApi->disconnectInstagram: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getInstagramConnection**
> InstagramConnectionModel getInstagramConnection()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = InstagramApi();

try {
    final result = api_instance.getInstagramConnection();
    print(result);
} catch (e) {
    print('Exception when calling InstagramApi->getInstagramConnection: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**InstagramConnectionModel**](InstagramConnectionModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

