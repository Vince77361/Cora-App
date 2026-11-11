# cora_api.api.ContentDraftsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listMyContentDrafts**](ContentDraftsApi.md#listmycontentdrafts) | **GET** /stores/me/content-drafts | 
[**regenerateMyContentDraft**](ContentDraftsApi.md#regeneratemycontentdraft) | **POST** /stores/me/content-drafts/{kind}/regenerate | 


# **listMyContentDrafts**
> List<ContentDraftModel> listMyContentDrafts()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContentDraftsApi();

try {
    final result = api_instance.listMyContentDrafts();
    print(result);
} catch (e) {
    print('Exception when calling ContentDraftsApi->listMyContentDrafts: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<ContentDraftModel>**](ContentDraftModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **regenerateMyContentDraft**
> ContentDraftModel regenerateMyContentDraft(kind)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ContentDraftsApi();
final kind = ; // ContentDraftKind | 

try {
    final result = api_instance.regenerateMyContentDraft(kind);
    print(result);
} catch (e) {
    print('Exception when calling ContentDraftsApi->regenerateMyContentDraft: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **kind** | [**ContentDraftKind**](.md)|  | 

### Return type

[**ContentDraftModel**](ContentDraftModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

