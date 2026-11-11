# cora_api.api.PaymentsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createPayment**](PaymentsApi.md#createpayment) | **POST** /collaborations/{id}/payments | 
[**getPayment**](PaymentsApi.md#getpayment) | **GET** /payments/{id} | 
[**getPaymentQuote**](PaymentsApi.md#getpaymentquote) | **GET** /collaborations/{id}/payment-quote | 


# **createPayment**
> PaymentCreatedModel createPayment(id, createPaymentDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PaymentsApi();
final id = id_example; // String | 
final createPaymentDto = CreatePaymentDto(); // CreatePaymentDto | 

try {
    final result = api_instance.createPayment(id, createPaymentDto);
    print(result);
} catch (e) {
    print('Exception when calling PaymentsApi->createPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **createPaymentDto** | [**CreatePaymentDto**](CreatePaymentDto.md)|  | 

### Return type

[**PaymentCreatedModel**](PaymentCreatedModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPayment**
> PaymentStatusModel getPayment(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PaymentsApi();
final id = id_example; // String | 

try {
    final result = api_instance.getPayment(id);
    print(result);
} catch (e) {
    print('Exception when calling PaymentsApi->getPayment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**PaymentStatusModel**](PaymentStatusModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPaymentQuote**
> PaymentQuoteModel getPaymentQuote(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PaymentsApi();
final id = id_example; // String | 

try {
    final result = api_instance.getPaymentQuote(id);
    print(result);
} catch (e) {
    print('Exception when calling PaymentsApi->getPaymentQuote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**PaymentQuoteModel**](PaymentQuoteModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

