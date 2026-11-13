# cora_api.api.ProposalsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getProposal**](ProposalsApi.md#getproposal) | **GET** /offers/{id} | 
[**listProposals**](ProposalsApi.md#listproposals) | **GET** /offers/proposals | 


# **getProposal**
> ProposalDetailModel getProposal(id)



제안 상세. 당사자만 볼 수 있고 남의 제안은 404다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ProposalsApi();
final id = id_example; // String | 

try {
    final result = api_instance.getProposal(id);
    print(result);
} catch (e) {
    print('Exception when calling ProposalsApi->getProposal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ProposalDetailModel**](ProposalDetailModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listProposals**
> List<ProposalRowModel> listProposals(tab)



제안함(F3). 사장님은 내 가게의 오퍼, 크리에이터는 내가 받은·보낸 오퍼. 내가 응답할 차례 → 상대 대기 순, 같은 묶음에서는 최근 판본 순.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ProposalsApi();
final tab = ; // ProposalTab | active: 내가 응답할 차례와 상대를 기다리는 제안. ended: 합의, 종료, 기한이 지난 제안.

try {
    final result = api_instance.listProposals(tab);
    print(result);
} catch (e) {
    print('Exception when calling ProposalsApi->listProposals: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tab** | [**ProposalTab**](.md)| active: 내가 응답할 차례와 상대를 기다리는 제안. ended: 합의, 종료, 기한이 지난 제안. | 

### Return type

[**List<ProposalRowModel>**](ProposalRowModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

