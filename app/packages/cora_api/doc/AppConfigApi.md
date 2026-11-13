# cora_api.api.AppConfigApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAppConfig**](AppConfigApi.md#getappconfig) | **GET** /config | 


# **getAppConfig**
> AppConfigModel getAppConfig()



### Example
```dart
import 'package:cora_api/api.dart';

final api_instance = AppConfigApi();

try {
    final result = api_instance.getAppConfig();
    print(result);
} catch (e) {
    print('Exception when calling AppConfigApi->getAppConfig: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AppConfigModel**](AppConfigModel.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

