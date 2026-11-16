# cora_api.api.RecommendationsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listCampaignRecommendations**](RecommendationsApi.md#listcampaignrecommendations) | **GET** /recommendations/campaigns | 크리에이터의 오늘 캠페인·가게 추천
[**listCreatorRecommendations**](RecommendationsApi.md#listcreatorrecommendations) | **GET** /recommendations/creators | 브랜드의 오늘 크리에이터 추천(진행 중인 캠페인 필요)
[**listPreviewCards**](RecommendationsApi.md#listpreviewcards) | **GET** /recommendations/preview | 역할이 없는 사용자의 둘러보기 카드(읽기 전용)


# **listCampaignRecommendations**
> CampaignRecommendationsModel listCampaignRecommendations()

크리에이터의 오늘 캠페인·가게 추천

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RecommendationsApi();

try {
    final result = api_instance.listCampaignRecommendations();
    print(result);
} catch (e) {
    print('Exception when calling RecommendationsApi->listCampaignRecommendations: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CampaignRecommendationsModel**](CampaignRecommendationsModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listCreatorRecommendations**
> CreatorRecommendationsModel listCreatorRecommendations()

브랜드의 오늘 크리에이터 추천(진행 중인 캠페인 필요)

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RecommendationsApi();

try {
    final result = api_instance.listCreatorRecommendations();
    print(result);
} catch (e) {
    print('Exception when calling RecommendationsApi->listCreatorRecommendations: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CreatorRecommendationsModel**](CreatorRecommendationsModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPreviewCards**
> PreviewCardsModel listPreviewCards()

역할이 없는 사용자의 둘러보기 카드(읽기 전용)

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = RecommendationsApi();

try {
    final result = api_instance.listPreviewCards();
    print(result);
} catch (e) {
    print('Exception when calling RecommendationsApi->listPreviewCards: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PreviewCardsModel**](PreviewCardsModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

