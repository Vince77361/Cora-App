# cora_api.model.ProposalModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**brandName** | **String** |  | 
**brandPhotoUrl** | **String** |  | 
**campaignId** | **String** |  | 
**contentPhotoUrl** | **String** |  | 
**contentTitle** | **String** |  | 
**fee** | **int** | 제안이 붙어 있으면 제안의 제작비, 없으면 캠페인의 제작비. | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**note** | **String** | 브랜드가 붙인 글(좋아한 점). 조건 제안만 붙었으면 null. | 
**performance** | [**ProposalPerformanceModel**](ProposalPerformanceModel.md) | 제안에 붙은 성과 추가. 없으면 null. | 
**productProvided** | **bool** | 제안이 붙어 있으면 제안의 값, 없으면 캠페인의 값. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


