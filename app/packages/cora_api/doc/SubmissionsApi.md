# cora_api.api.SubmissionsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**submitContentLink**](SubmissionsApi.md#submitcontentlink) | **POST** /collaborations/{id}/submission | 


# **submitContentLink**
> CollaborationModel submitContentLink(id, submitContentDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SubmissionsApi();
final id = id_example; // String | 
final submitContentDto = SubmitContentDto(); // SubmitContentDto | 

try {
    final result = api_instance.submitContentLink(id, submitContentDto);
    print(result);
} catch (e) {
    print('Exception when calling SubmissionsApi->submitContentLink: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **submitContentDto** | [**SubmitContentDto**](SubmitContentDto.md)|  | 

### Return type

[**CollaborationModel**](CollaborationModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

