# cora_api.api.StoreInsightsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMyStoreTrialComparison**](StoreInsightsApi.md#getmystoretrialcomparison) | **GET** /stores/me/trial-comparison | 체험단 재계약 전 비교(G3). 체험단 계약 정보가 없으면 404다.


# **getMyStoreTrialComparison**
> TrialComparisonModel getMyStoreTrialComparison()

체험단 재계약 전 비교(G3). 체험단 계약 정보가 없으면 404다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StoreInsightsApi();

try {
    final result = api_instance.getMyStoreTrialComparison();
    print(result);
} catch (e) {
    print('Exception when calling StoreInsightsApi->getMyStoreTrialComparison: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**TrialComparisonModel**](TrialComparisonModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

