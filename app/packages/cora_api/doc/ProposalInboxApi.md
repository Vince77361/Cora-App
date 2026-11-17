# cora_api.api.ProposalInboxApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listTermsProposalInbox**](ProposalInboxApi.md#listtermsproposalinbox) | **GET** /terms/proposal-inbox | 제안함의 브랜드 계약 줄(브랜드와 크리에이터 모두). 내가 당사자인 협업만, 내가 응답할 차례 → 상대 대기 → 끝남 순이고 같은 묶음에서는 최근 순이다. 계약 이후와 요청 거절·차단으로 끝난 협업은 없다.


# **listTermsProposalInbox**
> List<ProposalInboxRowModel> listTermsProposalInbox()

제안함의 브랜드 계약 줄(브랜드와 크리에이터 모두). 내가 당사자인 협업만, 내가 응답할 차례 → 상대 대기 → 끝남 순이고 같은 묶음에서는 최근 순이다. 계약 이후와 요청 거절·차단으로 끝난 협업은 없다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ProposalInboxApi();

try {
    final result = api_instance.listTermsProposalInbox();
    print(result);
} catch (e) {
    print('Exception when calling ProposalInboxApi->listTermsProposalInbox: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<ProposalInboxRowModel>**](ProposalInboxRowModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

