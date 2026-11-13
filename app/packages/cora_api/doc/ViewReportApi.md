# cora_api.api.ViewReportApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**confirmViewReport**](ViewReportApi.md#confirmviewreport) | **POST** /collaborations/{id}/view-report/confirm | 맡긴 쪽이 \"자료 확인했어요\"를 누른다. 확인되면 정산이 이어진다. 확인할 수 없는 상태면 409, 크리에이터는 403.
[**disputeViewReport**](ViewReportApi.md#disputeviewreport) | **POST** /collaborations/{id}/view-report/dispute | 조회 자료에 이의를 제기한다(당사자 누구나, 확인 전인 계산에 한 사람이 한 번). 돈은 그대로 보관되고 운영팀이 처리한다. 낼 수 없는 상태면 409.
[**getViewReport**](ViewReportApi.md#getviewreport) | **GET** /collaborations/{id}/view-report | 조회 자료 확인(F4). 당사자만 읽는다. 조회수 수당이 없거나 링크 제출 전이면 404.
[**submitViewEvidence**](ViewReportApi.md#submitviewevidence) | **POST** /collaborations/{id}/view-evidence | 조회수를 읽지 못했을 때 크리에이터가 인사이트 캡처와 조회수를 낸다. 크리에이터만, 캡처가 요청된 때 한 번. 받을 수 없는 상태면 409, 내 파일이 아니면 403.


# **confirmViewReport**
> ViewReportModel confirmViewReport(id)

맡긴 쪽이 \"자료 확인했어요\"를 누른다. 확인되면 정산이 이어진다. 확인할 수 없는 상태면 409, 크리에이터는 403.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ViewReportApi();
final id = id_example; // String | 

try {
    final result = api_instance.confirmViewReport(id);
    print(result);
} catch (e) {
    print('Exception when calling ViewReportApi->confirmViewReport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ViewReportModel**](ViewReportModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **disputeViewReport**
> ViewReportModel disputeViewReport(id, disputeViewReportDto)

조회 자료에 이의를 제기한다(당사자 누구나, 확인 전인 계산에 한 사람이 한 번). 돈은 그대로 보관되고 운영팀이 처리한다. 낼 수 없는 상태면 409.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ViewReportApi();
final id = id_example; // String | 
final disputeViewReportDto = DisputeViewReportDto(); // DisputeViewReportDto | 

try {
    final result = api_instance.disputeViewReport(id, disputeViewReportDto);
    print(result);
} catch (e) {
    print('Exception when calling ViewReportApi->disputeViewReport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **disputeViewReportDto** | [**DisputeViewReportDto**](DisputeViewReportDto.md)|  | 

### Return type

[**ViewReportModel**](ViewReportModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getViewReport**
> ViewReportModel getViewReport(id)

조회 자료 확인(F4). 당사자만 읽는다. 조회수 수당이 없거나 링크 제출 전이면 404.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ViewReportApi();
final id = id_example; // String | 

try {
    final result = api_instance.getViewReport(id);
    print(result);
} catch (e) {
    print('Exception when calling ViewReportApi->getViewReport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ViewReportModel**](ViewReportModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitViewEvidence**
> ViewReportModel submitViewEvidence(id, submitViewEvidenceDto)

조회수를 읽지 못했을 때 크리에이터가 인사이트 캡처와 조회수를 낸다. 크리에이터만, 캡처가 요청된 때 한 번. 받을 수 없는 상태면 409, 내 파일이 아니면 403.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ViewReportApi();
final id = id_example; // String | 
final submitViewEvidenceDto = SubmitViewEvidenceDto(); // SubmitViewEvidenceDto | 

try {
    final result = api_instance.submitViewEvidence(id, submitViewEvidenceDto);
    print(result);
} catch (e) {
    print('Exception when calling ViewReportApi->submitViewEvidence: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **submitViewEvidenceDto** | [**SubmitViewEvidenceDto**](SubmitViewEvidenceDto.md)|  | 

### Return type

[**ViewReportModel**](ViewReportModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

