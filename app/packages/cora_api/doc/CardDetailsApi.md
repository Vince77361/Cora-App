# cora_api.api.CardDetailsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getCampaignDetail**](CardDetailsApi.md#getcampaigndetail) | **GET** /campaigns/{id}/detail | 캠페인 상세(크리에이터). 보이지 않거나 내가 넘긴 캠페인은 404, 예산은 담지 않는다.
[**getCreatorCard**](CardDetailsApi.md#getcreatorcard) | **GET** /creators/{id}/card | 크리에이터 카드 상세(브랜드). 보이지 않거나 내가 넘긴 크리에이터는 404.


# **getCampaignDetail**
> CampaignDetailModel getCampaignDetail(id)

캠페인 상세(크리에이터). 보이지 않거나 내가 넘긴 캠페인은 404, 예산은 담지 않는다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CardDetailsApi();
final id = id_example; // String | 

try {
    final result = api_instance.getCampaignDetail(id);
    print(result);
} catch (e) {
    print('Exception when calling CardDetailsApi->getCampaignDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**CampaignDetailModel**](CampaignDetailModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCreatorCard**
> CreatorCardDetailModel getCreatorCard(id)

크리에이터 카드 상세(브랜드). 보이지 않거나 내가 넘긴 크리에이터는 404.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CardDetailsApi();
final id = id_example; // String | 

try {
    final result = api_instance.getCreatorCard(id);
    print(result);
} catch (e) {
    print('Exception when calling CardDetailsApi->getCreatorCard: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**CreatorCardDetailModel**](CreatorCardDetailModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

