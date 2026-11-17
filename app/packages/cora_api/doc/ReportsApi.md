# cora_api.api.ReportsApi

## Load the API package
```dart
import 'package:cora_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createReport**](ReportsApi.md#createreport) | **POST** /reports | 내가 참가한 방이나 그 상대를 신고한다. 운영자에게 메일이 간다. 돈이 보관 중인 협업이면 그 협업이 멈춘다.


# **createReport**
> ReportCreatedModel createReport(createReportDto)

내가 참가한 방이나 그 상대를 신고한다. 운영자에게 메일이 간다. 돈이 보관 중인 협업이면 그 협업이 멈춘다.

### Example
```dart
import 'package:cora_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ReportsApi();
final createReportDto = CreateReportDto(); // CreateReportDto | 

try {
    final result = api_instance.createReport(createReportDto);
    print(result);
} catch (e) {
    print('Exception when calling ReportsApi->createReport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createReportDto** | [**CreateReportDto**](CreateReportDto.md)|  | 

### Return type

[**ReportCreatedModel**](ReportCreatedModel.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

