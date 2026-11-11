# cora_api.api.UploadsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createPhotoUpload**](UploadsApi.md#createphotoupload) | **POST** /uploads/photos | 


# **createPhotoUpload**
> PhotoUploadModel createPhotoUpload(createPhotoUploadDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UploadsApi();
final createPhotoUploadDto = CreatePhotoUploadDto(); // CreatePhotoUploadDto | 

try {
    final result = api_instance.createPhotoUpload(createPhotoUploadDto);
    print(result);
} catch (e) {
    print('Exception when calling UploadsApi->createPhotoUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createPhotoUploadDto** | [**CreatePhotoUploadDto**](CreatePhotoUploadDto.md)|  | 

### Return type

[**PhotoUploadModel**](PhotoUploadModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

