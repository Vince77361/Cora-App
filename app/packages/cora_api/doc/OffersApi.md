# cora_api.api.OffersApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptOffer**](OffersApi.md#acceptoffer) | **POST** /offers/{id}/accept | 
[**cancelOffer**](OffersApi.md#canceloffer) | **POST** /offers/{id}/cancel | 
[**declineOffer**](OffersApi.md#declineoffer) | **POST** /offers/{id}/decline | 
[**endOffer**](OffersApi.md#endoffer) | **POST** /offers/{id}/end | 
[**getMyStoreSummary**](OffersApi.md#getmystoresummary) | **GET** /stores/me/summary | 
[**listReceivedOffers**](OffersApi.md#listreceivedoffers) | **GET** /offers/received | 
[**listSentOffers**](OffersApi.md#listsentoffers) | **GET** /offers/sent | 
[**proposeOfferVersion**](OffersApi.md#proposeofferversion) | **POST** /offers/{id}/versions | 
[**proposeToStore**](OffersApi.md#proposetostore) | **POST** /stores/{id}/proposals | 
[**sendOffer**](OffersApi.md#sendoffer) | **POST** /offers | 
[**undoDeclineOffer**](OffersApi.md#undodeclineoffer) | **POST** /offers/{id}/undo-decline | 


# **acceptOffer**
> ReceivedOfferModel acceptOffer(id, acceptOfferDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();
final id = id_example; // String | 
final acceptOfferDto = AcceptOfferDto(); // AcceptOfferDto | 

try {
    final result = api_instance.acceptOffer(id, acceptOfferDto);
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->acceptOffer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **acceptOfferDto** | [**AcceptOfferDto**](AcceptOfferDto.md)|  | 

### Return type

[**ReceivedOfferModel**](ReceivedOfferModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cancelOffer**
> SentOfferModel cancelOffer(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();
final id = id_example; // String | 

try {
    final result = api_instance.cancelOffer(id);
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->cancelOffer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**SentOfferModel**](SentOfferModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **declineOffer**
> ReceivedOfferModel declineOffer(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();
final id = id_example; // String | 

try {
    final result = api_instance.declineOffer(id);
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->declineOffer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ReceivedOfferModel**](ReceivedOfferModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **endOffer**
> EndedOfferModel endOffer(id, endOfferDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();
final id = id_example; // String | 
final endOfferDto = EndOfferDto(); // EndOfferDto | 

try {
    final result = api_instance.endOffer(id, endOfferDto);
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->endOffer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **endOfferDto** | [**EndOfferDto**](EndOfferDto.md)|  | 

### Return type

[**EndedOfferModel**](EndedOfferModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyStoreSummary**
> StoreHomeSummaryModel getMyStoreSummary()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();

try {
    final result = api_instance.getMyStoreSummary();
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->getMyStoreSummary: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**StoreHomeSummaryModel**](StoreHomeSummaryModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listReceivedOffers**
> List<ReceivedOfferModel> listReceivedOffers(tab)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();
final tab = ; // ReceivedOfferTab | new: 답을 기다리는 오퍼와 방금 거절해 되돌릴 수 있는 오퍼.

try {
    final result = api_instance.listReceivedOffers(tab);
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->listReceivedOffers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tab** | [**ReceivedOfferTab**](.md)| new: 답을 기다리는 오퍼와 방금 거절해 되돌릴 수 있는 오퍼. | 

### Return type

[**List<ReceivedOfferModel>**](ReceivedOfferModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSentOffers**
> List<SentOfferModel> listSentOffers()



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();

try {
    final result = api_instance.listSentOffers();
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->listSentOffers: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<SentOfferModel>**](SentOfferModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **proposeOfferVersion**
> OfferVersionModel proposeOfferVersion(id, proposeVersionDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();
final id = id_example; // String | 
final proposeVersionDto = ProposeVersionDto(); // ProposeVersionDto | 

try {
    final result = api_instance.proposeOfferVersion(id, proposeVersionDto);
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->proposeOfferVersion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **proposeVersionDto** | [**ProposeVersionDto**](ProposeVersionDto.md)|  | 

### Return type

[**OfferVersionModel**](OfferVersionModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **proposeToStore**
> StoreProposalResultModel proposeToStore(id, storeProposalDto)



크리에이터가 가게 페이지에서 내 방식으로 제안한다. 열린 오퍼가 없으면 새 오퍼(판본 1은 가게의 모집 조건, 판본 2가 이 제안)를 만들고, 내 차례인 열린 오퍼가 있으면 다음 판본을 낸다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();
final id = id_example; // String | 
final storeProposalDto = StoreProposalDto(); // StoreProposalDto | 

try {
    final result = api_instance.proposeToStore(id, storeProposalDto);
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->proposeToStore: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **storeProposalDto** | [**StoreProposalDto**](StoreProposalDto.md)|  | 

### Return type

[**StoreProposalResultModel**](StoreProposalResultModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendOffer**
> SentOfferModel sendOffer(sendOfferDto)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();
final sendOfferDto = SendOfferDto(); // SendOfferDto | 

try {
    final result = api_instance.sendOffer(sendOfferDto);
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->sendOffer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sendOfferDto** | [**SendOfferDto**](SendOfferDto.md)|  | 

### Return type

[**SentOfferModel**](SentOfferModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **undoDeclineOffer**
> ReceivedOfferModel undoDeclineOffer(id)



### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = OffersApi();
final id = id_example; // String | 

try {
    final result = api_instance.undoDeclineOffer(id);
    print(result);
} catch (e) {
    print('Exception when calling OffersApi->undoDeclineOffer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ReceivedOfferModel**](ReceivedOfferModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

