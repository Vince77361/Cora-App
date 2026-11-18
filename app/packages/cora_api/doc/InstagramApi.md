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
[**importInstagramPosts**](InstagramApi.md#importinstagramposts) | **POST** /instagram/posts/import | 고른 게시물의 파일을 서버로 복사하고 대표 게시물 초안을 돌려준다(저장은 PUT /creators/me/featured-posts)
[**listInstagramPosts**](InstagramApi.md#listinstagramposts) | **GET** /instagram/posts | 연동한 인스타그램 계정의 게시물 목록(연동이 없으면 404)


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

# **importInstagramPosts**
> List<FeaturedPostDraftModel> importInstagramPosts(importInstagramPostsDto)

고른 게시물의 파일을 서버로 복사하고 대표 게시물 초안을 돌려준다(저장은 PUT /creators/me/featured-posts)

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
final importInstagramPostsDto = ImportInstagramPostsDto(); // ImportInstagramPostsDto | 

try {
    final result = api_instance.importInstagramPosts(importInstagramPostsDto);
    print(result);
} catch (e) {
    print('Exception when calling InstagramApi->importInstagramPosts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **importInstagramPostsDto** | [**ImportInstagramPostsDto**](ImportInstagramPostsDto.md)|  | 

### Return type

[**List<FeaturedPostDraftModel>**](FeaturedPostDraftModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listInstagramPosts**
> List<InstagramPostModel> listInstagramPosts()

연동한 인스타그램 계정의 게시물 목록(연동이 없으면 404)

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
    final result = api_instance.listInstagramPosts();
    print(result);
} catch (e) {
    print('Exception when calling InstagramApi->listInstagramPosts: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<InstagramPostModel>**](InstagramPostModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

