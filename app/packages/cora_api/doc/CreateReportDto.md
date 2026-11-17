# cora_api.model.CreateReportDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**detail** | **String** | 자세한 내용(선택, 500자까지). | [optional] 
**reason** | [**ReportReason**](ReportReason.md) | SPAM 광고·스팸, ABUSE 부적절한 말, FRAUD 사기 의심, OTHER 기타. | 
**targetId** | **String** | 사용자 또는 대화방의 id. 내 방이나 그 상대가 아니면 404다(형식이 틀려도 같다). | 
**targetKind** | [**ReportTargetKind**](ReportTargetKind.md) | USER는 내가 참가한 방의 상대, CONVERSATION은 내가 참가한 방이다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


