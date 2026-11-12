# cora_api.api.NotificationSettingsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getNotificationSettings**](NotificationSettingsApi.md#getnotificationsettings) | **GET** /me/notification-settings | 
[**putNotificationSettings**](NotificationSettingsApi.md#putnotificationsettings) | **PUT** /me/notification-settings | 


# **getNotificationSettings**
> NotificationSettingsModel getNotificationSettings()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationSettingsApi();

try {
    final result = api_instance.getNotificationSettings();
    print(result);
} catch (e) {
    print('Exception when calling NotificationSettingsApi->getNotificationSettings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**NotificationSettingsModel**](NotificationSettingsModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putNotificationSettings**
> NotificationSettingsModel putNotificationSettings(updateNotificationSettingsDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationSettingsApi();
final updateNotificationSettingsDto = UpdateNotificationSettingsDto(); // UpdateNotificationSettingsDto | 

try {
    final result = api_instance.putNotificationSettings(updateNotificationSettingsDto);
    print(result);
} catch (e) {
    print('Exception when calling NotificationSettingsApi->putNotificationSettings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateNotificationSettingsDto** | [**UpdateNotificationSettingsDto**](UpdateNotificationSettingsDto.md)|  | 

### Return type

[**NotificationSettingsModel**](NotificationSettingsModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

