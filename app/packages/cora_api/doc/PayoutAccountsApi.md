# cora_api.api.PayoutAccountsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getPayoutAccount**](PayoutAccountsApi.md#getpayoutaccount) | **GET** /payout-account | 
[**listBanks**](PayoutAccountsApi.md#listbanks) | **GET** /payout-account/banks | 
[**upsertPayoutAccount**](PayoutAccountsApi.md#upsertpayoutaccount) | **PUT** /payout-account | 


# **getPayoutAccount**
> PayoutAccountModel getPayoutAccount()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PayoutAccountsApi();

try {
    final result = api_instance.getPayoutAccount();
    print(result);
} catch (e) {
    print('Exception when calling PayoutAccountsApi->getPayoutAccount: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PayoutAccountModel**](PayoutAccountModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listBanks**
> List<BankModel> listBanks()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PayoutAccountsApi();

try {
    final result = api_instance.listBanks();
    print(result);
} catch (e) {
    print('Exception when calling PayoutAccountsApi->listBanks: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<BankModel>**](BankModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **upsertPayoutAccount**
> PayoutAccountModel upsertPayoutAccount(upsertPayoutAccountDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PayoutAccountsApi();
final upsertPayoutAccountDto = UpsertPayoutAccountDto(); // UpsertPayoutAccountDto | 

try {
    final result = api_instance.upsertPayoutAccount(upsertPayoutAccountDto);
    print(result);
} catch (e) {
    print('Exception when calling PayoutAccountsApi->upsertPayoutAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **upsertPayoutAccountDto** | [**UpsertPayoutAccountDto**](UpsertPayoutAccountDto.md)|  | 

### Return type

[**PayoutAccountModel**](PayoutAccountModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

