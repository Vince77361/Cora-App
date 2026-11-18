# cora_api.api.DiscoveryApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**compareCandidates**](DiscoveryApi.md#comparecandidates) | **GET** /discovery/compare | 후보 비교(브랜드). 이 캠페인에서 내가 저장한 두 크리에이터를 같은 결과물 기준으로 견주고 다른 줄을 알려 준다. 팔로워 수는 없다.
[**createInquiry**](DiscoveryApi.md#createinquiry) | **POST** /discovery/received-proposals/{campaignId}/inquiry | \"조건부터 질문하기\": 서로 관심을 만들지 않고 브랜드에게 메시지 요청을 보낸다. 협업(INQUIRY)과 메시지 요청 방과 첫 메시지가 한 번에 만들어진다.
[**listInterests**](DiscoveryApi.md#listinterests) | **GET** /discovery/interests | 하트·저장 목록. 내가 하트를 보냈거나 저장한 것만 나온다(넘긴 것은 어디에도 나오지 않는다).
[**listReceivedProposals**](DiscoveryApi.md#listreceivedproposals) | **GET** /discovery/received-proposals | 크리에이터가 받은 제안: 글이나 조건 제안이 붙은 브랜드의 하트 가운데 아직 결정하지 않은 것.
[**listStoreInterests**](DiscoveryApi.md#liststoreinterests) | **GET** /discovery/store-interests | 사장님 저장함: tab=saved는 내가 저장한 크리에이터, tab=sent는 내가 하트를 보낸 크리에이터(서로 관심 표지 포함). 가게 계정만 쓴다. 보낸 제안은 GET /offers/proposals를 쓴다.
[**putDecision**](DiscoveryApi.md#putdecision) | **PUT** /discovery/decisions | 하트(LIKE)·넘김(PASS)·저장(HOLD)을 저장한다. 브랜드·크리에이터는 반대쪽도 하트면 서로 관심(협업과 조건 버전 1)이 만들어진다. 사장님은 크리에이터에게만(campaign 없음) 결정하며 협업을 만들지 않는다.
[**putPassReason**](DiscoveryApi.md#putpassreason) | **PUT** /discovery/decisions/pass-reason | 넘긴 카드에 이유를 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.
[**putStorePass**](DiscoveryApi.md#putstorepass) | **PUT** /discovery/store-passes/{storeId} | 가게 카드를 넘긴다(가게 카드의 하트는 지원 API로 보낸다).
[**undoLastDecision**](DiscoveryApi.md#undolastdecision) | **DELETE** /discovery/decisions/last | 오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다. 서로 관심이 된 결정(사장님은 하트를 보낸 크리에이터가 그 가게에 지원해 있을 때)은 409다.


# **compareCandidates**
> CompareModel compareCandidates(a, b)

후보 비교(브랜드). 이 캠페인에서 내가 저장한 두 크리에이터를 같은 결과물 기준으로 견주고 다른 줄을 알려 준다. 팔로워 수는 없다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final a = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 비교할 크리에이터 한 명.
final b = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 비교할 다른 크리에이터.

try {
    final result = api_instance.compareCandidates(a, b);
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->compareCandidates: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **a** | **String**| 비교할 크리에이터 한 명. | 
 **b** | **String**| 비교할 다른 크리에이터. | 

### Return type

[**CompareModel**](CompareModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createInquiry**
> InquiryResultModel createInquiry(campaignId, inquiryDto)

\"조건부터 질문하기\": 서로 관심을 만들지 않고 브랜드에게 메시지 요청을 보낸다. 협업(INQUIRY)과 메시지 요청 방과 첫 메시지가 한 번에 만들어진다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final campaignId = campaignId_example; // String | 
final inquiryDto = InquiryDto(); // InquiryDto | 

try {
    final result = api_instance.createInquiry(campaignId, inquiryDto);
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->createInquiry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **campaignId** | **String**|  | 
 **inquiryDto** | [**InquiryDto**](InquiryDto.md)|  | 

### Return type

[**InquiryResultModel**](InquiryResultModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listInterests**
> List<InterestCardModel> listInterests(tab)

하트·저장 목록. 내가 하트를 보냈거나 저장한 것만 나온다(넘긴 것은 어디에도 나오지 않는다).

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final tab = ; // InterestTab | saved(기본) = 내 하트 + 저장, mutual = 서로 관심, sent = 보낸 관심(응답 대기), held = 저장.

try {
    final result = api_instance.listInterests(tab);
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->listInterests: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tab** | [**InterestTab**](.md)| saved(기본) = 내 하트 + 저장, mutual = 서로 관심, sent = 보낸 관심(응답 대기), held = 저장. | [optional] 

### Return type

[**List<InterestCardModel>**](InterestCardModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listReceivedProposals**
> List<ProposalModel> listReceivedProposals()

크리에이터가 받은 제안: 글이나 조건 제안이 붙은 브랜드의 하트 가운데 아직 결정하지 않은 것.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();

try {
    final result = api_instance.listReceivedProposals();
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->listReceivedProposals: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<ProposalModel>**](ProposalModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listStoreInterests**
> List<StoreInterestCardModel> listStoreInterests(tab)

사장님 저장함: tab=saved는 내가 저장한 크리에이터, tab=sent는 내가 하트를 보낸 크리에이터(서로 관심 표지 포함). 가게 계정만 쓴다. 보낸 제안은 GET /offers/proposals를 쓴다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final tab = ; // StoreInterestTab | saved(기본) = 내가 저장한 크리에이터, sent = 내가 하트를 보낸 크리에이터.

try {
    final result = api_instance.listStoreInterests(tab);
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->listStoreInterests: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tab** | [**StoreInterestTab**](.md)| saved(기본) = 내가 저장한 크리에이터, sent = 내가 하트를 보낸 크리에이터. | [optional] 

### Return type

[**List<StoreInterestCardModel>**](StoreInterestCardModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putDecision**
> DecisionResultModel putDecision(putDecisionDto)

하트(LIKE)·넘김(PASS)·저장(HOLD)을 저장한다. 브랜드·크리에이터는 반대쪽도 하트면 서로 관심(협업과 조건 버전 1)이 만들어진다. 사장님은 크리에이터에게만(campaign 없음) 결정하며 협업을 만들지 않는다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final putDecisionDto = PutDecisionDto(); // PutDecisionDto | 

try {
    final result = api_instance.putDecision(putDecisionDto);
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->putDecision: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **putDecisionDto** | [**PutDecisionDto**](PutDecisionDto.md)|  | 

### Return type

[**DecisionResultModel**](DecisionResultModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putPassReason**
> putPassReason(passReasonDto)

넘긴 카드에 이유를 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final passReasonDto = PassReasonDto(); // PassReasonDto | 

try {
    api_instance.putPassReason(passReasonDto);
} catch (e) {
    print('Exception when calling DiscoveryApi->putPassReason: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **passReasonDto** | [**PassReasonDto**](PassReasonDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putStorePass**
> putStorePass(storeId)

가게 카드를 넘긴다(가게 카드의 하트는 지원 API로 보낸다).

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();
final storeId = storeId_example; // String | 

try {
    api_instance.putStorePass(storeId);
} catch (e) {
    print('Exception when calling DiscoveryApi->putStorePass: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **storeId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **undoLastDecision**
> UndoneDecisionModel undoLastDecision()

오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다. 서로 관심이 된 결정(사장님은 하트를 보낸 크리에이터가 그 가게에 지원해 있을 때)은 409다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = DiscoveryApi();

try {
    final result = api_instance.undoLastDecision();
    print(result);
} catch (e) {
    print('Exception when calling DiscoveryApi->undoLastDecision: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UndoneDecisionModel**](UndoneDecisionModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

